#!/usr/bin/perl



###################
# mini webserver to test the pages for miniSPS
#
# to (re-)start the mini webserver enter:
#   clear; ps | grep perl | perl -pe '$_=~s/ +/ /g' | cut -d " " -f2 | xargs -I PS sh -c 'echo PS && kill PS'; ./simpleHttpServer.pl
#######



my $getValueLeadingChar = "X";



{
    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Data::Dumper;
    use POSIX;

#    my $htmlSourceFolder = "./html";
#    my $htmlSourceFolder = "./html/compressed";
    my $htmlSourceFolder = "./html/gzipped";

    # supported requests
    my %dispatch = (
        '^\/$'              => \&resp_root,
        '^\/.*\.html$'      => \&resp_html,
        '^\/.*\.ico$'       => \&resp_ico,
        '^\/.*\.jpg$'       => \&resp_jpg,
        '^\/.*\.gif$'       => \&resp_gif,
        '^\/.*\.png$'       => \&resp_png,
        '^\/.*\.js$'        => \&resp_js,
        '^\/.*\.css$'       => \&resp_css,
        '/getvalue.html'    => \&resp_getvalue,         # this will win since first string compare is done before regexes have been checked!
        '/setvalue.html'    => \&resp_setvalue,         # this will win since first string compare is done before regexes have been checked!
        # ...
    );

    my $headerFile = "./src/htmlEnums.h";
    open(my $fileHandle, "< $headerFile") or die("Cannot open header file [$headerFile]: $!");
    my $content = join("", <$fileHandle>);
    close($fileHandle);
    $content =~ s/.*enum *{ *[\x0A\x0D]+//s;    # remove stuff up to "enum {"
    $content =~ s/};.*//s;                      # remove stuff after end of enum "}"
    $content =~ s/^ *\/\/.*[\x0A\x0D]+//gm;     # remove all comments
    $content =~ s/^ *[\x0A\x0D]+//gm;           # remove "empty" lines
    $content =~ s/^ +//gm;                      # remove leading blanks
    $content =~ s/,.*//gm;                      # remove trailing commas
    my @content = split("[\x0A\x0D]+", $content);                # used to convert number indices
    print(STDERR "read enums from header file:\n".Dumper(@content));

    # handle received request
    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        # get requested path
        my $path = $cgi->path_info();

        print(STDERR "#################################\n");
        print(STDERR "request: $path\n");

        # path should be contained in %dispatch
        my $handler = $dispatch{$path};

        if (ref($handler) eq "CODE") {
            # path found in %dispatch
            $handler->($cgi);
        }
        else {
            # maybe there is a regex in %dispatch that matches the request
            foreach my $key (keys(%dispatch)) {
                if ($path =~ /$key/) {
                    # path found in %dispatch
                    $handler = $dispatch{$key};
                    last;
                }
            }

            if (ref($handler) eq "CODE") {
                # path found in %dispatch
                $handler->($cgi);
            }
            else {
                # path NOT found in %dispatch
                print "HTTP/1.0 404 Not found\r\n";
                print $cgi->header,
                      $cgi->start_html('Not found'),
                      $cgi->h1('Not found'),
                      $cgi->end_html;
                print(STDERR "not found\n");
            }
        }
    }



    # some sample values
    my %data = (
        "__SYSTEM_VERSION__"                                => "0.1b (2022-01-02 17:15:30)",
        "__SYSTEM_CPU_CORE__"                               => "espressif xyz",
        "__SYSTEM_HEAP_FREE__"                              => 230,
        "__SYSTEM_HEAP_NEVER_USED__"                        => 112,
        "__SYSTEM_FLASH_USED__"                             => 1207,
        "__SYSTEM_FLASH_SIZE__"                             => 4096,
        "__SYSTEM_RAM_SIZE__"                               => 512,
        "__SYSTEM_DATE__"                                   => sub {return strftime("%Y-%m-%d", localtime(time))},
        "__SYSTEM_TIME__"                                   => sub {return strftime("%H:%M", localtime(time))},
        "__SYSTEM_DISPLAY_TIMEOUT__"                        => 5,

        "__SYSTEM_NTP_ENABLED__"                            => 1,
        "__SYSTEM_TIME_ZONE__"                              => "GMT+1GMT,M3.5.0/02,M10.5.0/03",            # valid time zone strings for NTP servers see e.g. here: https://github.com/nayarsystems/posix_tz_db/blob/master/zones.csv

        "__WIFI_SSID__"                                     => [ 1, "local wifi", "neighbor" ],
        "__WIFI_PASSPHRASE__"                               => "w8fv0s98df0f9jc80wse98d9s8jt0vt98sd0cfj",
        "__WIFI_HOSTNAME__"                                 => "miniSPS",
        "__WIFI_IP__"                                       => [ 1, "192.168.168.24", "192.168.168.25" ],
        "__WIFI_GATEWAY__"                                  => "192.168.168.254",
        "__WIFI_SUBNET__"                                   => "255.255.255.0",
        "__WIFI_MANUAL_IP__"                                => "192.168.177.3",
        "__WIFI_MANUAL_GATEWAY__"                           => "192.168.177.1",
        "__WIFI_MANUAL_SUBNET__"                            => "255.255.255.0",
        "__WIFI_MAC__"                                      => "32:42:16:42:A2:FF",
        "__WIFI_STRENGTH__"                                 => [ 1, "-73", "-50", "-64"],
        "__WIFI_ENABLED__"                                  => [ 1, 0, 1],
        "__WIFI_TX_POWER__"                                 => 27,
        "__WIFI_AVAILABLE_SSIDS__"                          => [ 1, [ 2, "aaa", "neighbor", "local wifi" ], [ 1, "aaa", "neighbor", "local wifi" ] ],       # inner index (2) is the selected element!

        "__ACCESS_POINT_IP__"                               => "192.168.4.1",
        "__ACCESS_POINT_SUBNET__"                           => "255.255.255.0",
        "__ACCESS_POINT_SSID__"                             => "foobar",
        "__ACCESS_POINT_MAC__"                              => "12:42:F2:34:19:A3",
        "__ACCESS_POINT_CONNECTED_STATIONS__"               => [ 1, "1", "3", "2", "5", "3" ],
        "__ACCESS_POINT_ENABLED__"                          => [ 1, 0, 1],
        "__ACCESS_POINT_ALWAYS_ON__"                        => [ 1, 0, 0, 1],
    );



    # print a file to STDOUT (so it will be sent by web server to requesting client)
    sub printFile($) {
        my ($fileName) = @_;

        print(STDERR "send: $fileName\n");

        my $compressed = 0;

        my $contentEncoding = "";

        $fileName = $htmlSourceFolder."/".$fileName;
        if (-e $fileName.".gz") {
            $fileName .= ".gz";
            $compressed = 1;
        }

        if (open(my $fileHandle, "< $fileName")) {
            if ($compressed) {
                print("Content-Encoding: gzip\n");
            }
            print("\n");                                        # <---- this empty line is necessary (two \n\n separate the header from the content)!!!!
            print(<$fileHandle>);
            close($fileHandle);
        }
        else {
            print(STDERR "Couldn't open file: $!");
        }
    }



    # print HTTP header to STDOUT (so it will be sent by web server to requesting client)
    sub printHeader($) {
        my ($contentType) = @_;

        print("HTTP/1.1 200 OK\n");
        print("Content-Type: $contentType; charset=ISO-8859-1\n");
    }


    sub printPostAnswer() {
        print("HTTP/1.1 201 Created\n\n");
    }



    # print html-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_html {
        my $cgi  = shift;   # CGI.pm object
        my $additional = shift;
        return if !ref $cgi;

        my $file = (defined($additional) ? $additional : $cgi->path_info());
        $file =~ s/^\///;                   # remove leading slash

        print(STDERR "html: $file\n");

        printHeader("text/html");
        printFile($file);
    }



    sub resp_root {
        my $cgi  = shift;   # CGI.pm object
        print(STDERR "redirect to index.html\n");
        resp_html($cgi, "/index.html");
    }



    # print js-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_js {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("text/javascript");
        printFile($file);
    }



    # print css-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_css {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("text/css");
        printFile($file);
    }



    # print ico-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_ico {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("image/x-icon");
        printFile($file);
    }



    # print ico-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_jpg {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("image/jpeg");
        printFile($file);
    }



    # print ico-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_gif {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("image/gif");
        printFile($file);
    }



    # print ico-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_png {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("image/png");
        printFile($file);
    }


    sub resp_setvalue {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $param = $cgi->param('POSTDATA');

        print(STDERR "received: $param\n");

#        printPostAnswer();
    }


    sub resp_getvalue {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        #print STDERR Dumper $cgi;
        #print STDERR Dumper $cgi->param;

        my $response = "";
        my @parameters;
        if (defined($cgi->param('keywords'))) {
            @parameters = ($cgi->param('keywords'));
        }
        else {
            @parameters = $cgi->param;
        }
        foreach my $initialParam (@parameters) {
            my $param;

            # a number indice has to be converted (in case gzip files are used instead of unpacked ones...)
            if ($initialParam =~ /^$getValueLeadingChar(\d+)$/) {
                $param = $content[$1];
                print(STDERR "convert number indice: [$initialParam] -> [$param]\n");
            }
            else {
                $param = $initialParam;
            }

            my $DUMP = ($param eq "__WIFI_SCAN_SSID__") || 1;

            my $listFound = 0;

            my $data = "";
            if (defined($data{$param})) {
                $data = $data{$param};

                if (ref($data) eq "ARRAY") {
                    #print STDERR Dumper($data, $param) if ($DUMP);
                    my $index = $$data[0];
                    $$data[0]++;
                    if ($$data[0] >= int(@{$data})) {
                        $$data[0] = 1;       # switch back to first value
                    }

                    $data = $$data[$index];
                    if (ref($data) eq "ARRAY") {
                        # array containing an array e.g. to handle list elements
                        my @temp = @{$data};
                        my $selected = shift(@temp);
                        #print STDERR Dumper("SPLIT: ", @temp);
                        $data = '[ ' . $selected. ', "' . join('", "', @temp) . '" ]';
                        $listFound = 1;
                    }
                }
                elsif (ref($data) eq "CODE") {
                    $data = $data->();
                }
            }
            else {
                $data = "UNDEF";
            }

        
            $data = ((($data =~ /^\d+$/) || $listFound) ? "$data" : "\"$data\"");
            $initialParam = "\"$initialParam\"";

            $response .= ", "       if (length($response));
            $response .= "$initialParam : $data";
        }

        $response = "{ ".$response." }\n";

        print(STDERR "sent: $response");

        printHeader("application/json");
        print("\n");
        print($response);
    }



#    sub resp_hello {
#        my $cgi  = shift;   # CGI.pm object
#        return if !ref $cgi;
#
#        my $who = $cgi->param('name');
#
#        print "HTTP/1.0 200 OK\r\n";
#        print $cgi->header,
#              $cgi->start_html("Hello"),
#              $cgi->h1("Hello $who!"),
#              $cgi->end_html;
#    }
}



# start the server on port 8080
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";



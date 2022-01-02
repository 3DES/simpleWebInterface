#!/usr/bin/perl



###################
# mini webserver to test the pages for miniSPS
#
# to (re-)start the mini webserver enter:
#   clear; ps | grep perl | perl -pe '$_=~s/ +/ /g' | cut -d " " -f2 | xargs -I PS sh -c 'echo PS && kill PS'; ./simpleHttpServer.pl
#######



{
    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Data::Dumper;



    # supported requests
    my %dispatch = (
        '^\/$'              => \&resp_root,
        '^\/.*\.html$'      => \&resp_html,
        '^\/.*\.ico$'       => \&resp_ico,
        '^\/.*\.jpg$'       => \&resp_jpg,
        '^\/.*\.png$'       => \&resp_png,
        '^\/.*\.js$'        => \&resp_js,
        '^\/.*\.css$'       => \&resp_css,
        '/getvalue.html'    => \&resp_getvalue,         # this will win since first string compare is done before regexes have been checked!
        # ...
    );


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
        "status"        => "OK",
        "temperature"   => "4.5",
        "time"          => [ 1, "12:34:19", "12:34:21" ],       # element [0] is used as index and must start with 1!, any following elements will be used to handle requests
        "date"          => "2021-12-31",
    );



    # print a file to STDOUT (so it will be sent by web server to requesting client)
    sub printFile($) {
        my ($fileName) = @_;

        print(STDERR "send: $fileName\n");

        if (open(my $fileHandle, "< ./$fileName")) {
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
        print("\n");                                        # <---- this empty line is necessary!!!!
    }



    # print html-file to STDOUT (so it will be sent by web server to requesting client)
    sub resp_html {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("text/html");
        printFile($file);
    }



    sub resp_root {
        my $cgi  = shift;   # CGI.pm object
        
        resp_html(@_);
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
    sub resp_png {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = $cgi->path_info();
        $file =~ s/^\///;                   # remove leading slash

        printHeader("image/png");
        printFile($file);
    }



    sub resp_getvalue {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $param = $cgi->param('keywords');

        my $data = "";
        if (defined($data{$param})) {
            $data = $data{$param};

            if (ref($data) eq "ARRAY") {
                my $index = $$data[0];
                $$data[0]++;
                if ($$data[0] >= int(@{$data})) {
                    $$data[0] = 1;       # switch back to first value
                }

                $data = $$data[$index];
            }
        }
        else {
            $data = "UNDEF";
        }

        print(STDERR "sent: $param = $data\n");

        printHeader("application/json");
        print("{\"$param\" : \"$data\" }\n");
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



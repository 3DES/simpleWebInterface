#!/usr/bin/perl
{
    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Data::Dumper;



    # supported requests
    my %dispatch = (
        '/'              => \&resp_index,
        '/index.html'    => \&resp_index,
        '/getvalue.html' => \&resp_getvalue,
        '/hello.html'    => \&resp_hello,
        '/jslib.js'      => \&resp_jslib,
        # ...
    );



    # some sample values
    my %data = (
        "status"        => "OK",
        "temperature"   => "4.5",
        "time"          => [ 1, "12:34:19", "12:34:21" ],
        "date"          => "2021-12-31",
    );



    sub printFile($) {
        my ($fileName) = @_;

        if (open(my $fileHandle, "< ./$fileName")) {
            print(<$fileHandle>);
            close($fileHandle);
        }
        else {
            print(STDERR "Couldn't open file: $!");
        }
    }



    sub printHeader($) {
        my ($contentType) = @_;

        print("HTTP/1.1 200 OK\n");
        print("Content-Type: $contentType; charset=ISO-8859-1\n");
        print("\n");                                        # <---- this empty line is necessary!!!!
    }



    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        my $path = $cgi->path_info();

        print(STDERR "request: $path\n");

        my $handler = $dispatch{$path};

        if (ref($handler) eq "CODE") {
            $handler->($cgi);
        } else {
            print "HTTP/1.0 404 Not found\r\n";
            print $cgi->header,
                  $cgi->start_html('Not found'),
                  $cgi->h1('Not found'),
                  $cgi->end_html;
        }
    }



    sub resp_index {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = "index.html";

        print(STDERR "$file\n");

        printHeader("text/html");
        printFile($file);
    }
    


    sub resp_jslib {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $file = "jslib.js";

        printHeader("text/javascript");
        printFile($file);
    }



    sub resp_getvalue {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $param = $cgi->param('keywords');

        my $data = "";
        if (defined($data{$param})) {
            $data = $data{$param};
            print(STDERR Dumper($data));
            if (ref($data) eq "ARRAY") {
                my $index = $$data[0];
                $$data[0]++;
                if ($$data[0] >= int(@{$data})) {
                    $$data[0] = 1;       # switch back to first value
                }
                print(STDERR Dumper($data));
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



    sub resp_hello {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $who = $cgi->param('name');

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header,
              $cgi->start_html("Hello"),
              $cgi->h1("Hello $who!"),
              $cgi->end_html;
    }
}



# start the server on port 8080
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";



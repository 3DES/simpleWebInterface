#!/usr/bin/perl
{
    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Data::Dumper;

    my %dispatch = (
        '/hello'         => \&resp_hello,
        '/1.html'        => \&resp_1,
        '/getvalue.html' => \&resp_getvalue,
        # ...
    );

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

    sub resp_1 {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $who = $cgi->param('name');

        print(STDERR "1.html\n");

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header;

        if (open(my $fileHandle, "< ./1.html")) {
            my @stuff = <$fileHandle>;

            foreach my $line (@stuff) {
                print($line);
                #print(STDERR $line);
            }

            close($fileHandle);
        }
        else {
            print("Couldn't open file: $!");
        }

        print $cgi->end_html;
    }

    %data = (
        "status"        => "OK",
        "temperature"   => "4.5°C",
        "time"          => "12:34:19",
    );

    sub resp_getvalue {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $param = $cgi->param('keywords');

        my $data = defined($data{$param}) ? $data{$param} : "UNDEF";

        print(STDERR "sent: $param = $data\n");

        print("HTTP/1.1 200 OK\n");
        print("Content-Type: application/json\n");
        print("\n");                                        # <---- this empty line is necessary!!!!
        print("{\"$param\" : \"$data\" }\n");
    }
}

# start the server on port 8080
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";


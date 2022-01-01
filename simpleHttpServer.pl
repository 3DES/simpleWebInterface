#!/usr/bin/perl
{
    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);

    my %dispatch = (
        '/hello'  => \&resp_hello,
        '/foobar' => \&resp_foobar,
        '/status' => \&resp_status,
        # ...
    );

    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        my $path = $cgi->path_info();
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

    sub resp_foobar {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        my $who = $cgi->param('name');

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header;

        if (open(my $fileHandle, "< D:/temp/1.html")) {
            my @stuff = <$fileHandle>;

            foreach my $line (@stuff) {
                print($line);
                print(STDERR $line);
            }

            close($fileHandle);
        }
        else {
            print("Couldn't open file: $!");
        }

        print $cgi->end_html;
    }

    sub resp_status {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        print("HTTP/1.1 200 OK\n");
        print("Content-Type: application/json\n");
        print("\n");                                        # <---- this empty line is necessary!!!!
        print("{\"asdf\" : 33 }\n");
    }
}

# start the server on port 8080
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";


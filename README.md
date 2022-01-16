This is a simple web interface for embedded controllers.

Most of the work is done by the java script part.

index.html gives a default index page (initially made for miniSPS but can easily be changed to fit your needs).
Each sub page mostly contains a json structure "blocks" that provides everything that is necessary for that sub page.
Pages can be testet with included small perl web server.
If eth. looks fine go through the build steps described below, to get small compressed C code converted html pages that can be included into your own source.



build steps:
1) HTML sources should be put into html folder
    index.html is the entry page as usual for web sites
    each sub page has to provide:
        - provide a constant json structure "blocks" containing all data to be shown
        - provide a method "function repaint()"
        - call its own repain() during page load
    [send] and [cancel] buttons will automatically be provided if there is at least one none-readonly element defined in "blocks"
    for more information please have a short look into one of the demo pages, e.g. overview.html
    that's all and you will get a fully interactive web page that can automatically refresh data if set and even upload changed settings if needed
    
2) new defines should be put into src/htmlDefines.h

3) ./pre-compress.sh   should be executed to get smaller sources (~ 20%-30% smaller as with gzip only)
        - download and install nodejs
        - npm install html-minifier -g
        - npm install uglify-js -g
        (- npm install csso     # currently not used!)

4) python3.6 ./html2gzipc.py should be executed to get the files gzipped and converted into C sources
    ./html                  contains all web site sources (html, js, css, jpg, ...)
    ./html/compressed       files after sources have been pre-compressed
    ./html/gzipped          files after sources have been gzipped (in html2gzipc.py you can choose if you want to use the source files or the pre-compressed ones <precompressFiles>!)
    ./src                   contains then header file htmlDefines.h
    ./src/html              contains the gzipped files converted into C sources

5) web sites can be tested with included little webserver simpleHttpServer.pl (you can choose which sources should be used <$htmlSourceFolder>)
    some packages from CPAN will be necessary for execution, download and install them with
        cpan install <package>
    for example if you get told that "HTTP/Server/Simple/CGI" is missing please enter
        cpan install HTTP::Server::Simple::CGI

6) html2gzipc.py is compatible with platformio and can be used there during build time by adding this line to your platformio.ini file:
    extra_scripts = pre:scripts/html2gzipc.py
    parameters can be given via build_flags = -D<key>=<value>
    !!! But currently the easiest way would be creating the web page inside the library folder and copy /src + /src/html over into target project



All of this has been tested under cygwin but should probably also work with Linux.

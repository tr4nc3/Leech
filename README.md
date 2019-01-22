# Leech
This tool performs a recursive directory lookup given a directory listing.  The goal is to make sure that the files on the file system are not anonymously (or with a cookie) are not downloadable.  

Output:
downloadable-files.log: a list of files that are downloadable
activity.log: if --verbose flag is given, then log each request and the http response code
access-denied.log: URL requests that resulted in a 403

Caveats:
If the web server generates a generic 200 OK HTTP status code for each request, then this will cause a lot of heartburn since the crawler will think every single file is downloadable

TODO:
To automatically detect 200 OK generic responses and take some action, if the web server behaves this way.

``usage: leech.pl [--help] [--proxy proxy:port] [--port port] {--url URL} {--type 1|2|3|4} {--fname filename} [--cookie "cookie_val"] [--basic username:password ] [--swiggler] [--verbose]``

         --help : prints what you are looking at now
         --url : url to send requests to
         --proxy : proxy used (SSLeay in CryptSSLeay is buggy with a proxy)
         --type :  1 = Windows dir /s
                   2 = Windows dir /B /S
                   3 = Linux ls -R
                   4 = Linux Recursive directory with full path on same line
         --root : Format is /directory you want prepended before using the path
         --ssl : Force ssl
         --cookie : The cookie value to be used with each request for authenticated downloading
         --verbose : Show verbose output
         --swiggler : an option that doesn't do much
         --fname : file name that contains the directory listing for the web server filesystem
         --ntlm : NTLM authentication credentials in the form domain\username:password
         --basic : Basic authentication credentials in the form username:password
      Example 1:  $0 --proxy http://localhost:8080/ --url http://site.com --port 80 --type 1
          --fname dirlisting.txt --ssl --root /admin/test/  --cookie "JSESSIONID=nj33ks"
      Example 2:  $0 --url site.com:80 --type 1 --fname dirlisting.txt --swiggler
      Example 3:  $0 --url https://site.com:8080 --type 3 --fname lsalr.txt --verbose

# Leech
This tool performs a recursive directory lookup given a directory listing

``usage: leech.pl [--help] [--proxy proxy:port] [--port port] {--url URL} {--type 1|2|3|4} {--fname filename}
       [--cookie "cookie_val"] [--basic username:password ] [--swiggler] [--verbose]
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
      Example 3:  $0 --url https://site.com:8080 --type 3 --fname lsalr.txt --verbose``

#!/usr/bin/perl
# Copyright(R) Rajat Swarup 2007
# Mail suggestions or bugs to rajats@gmail.com
# Leech - Loops thru Extraneous files in wEbroot and fetCHes them
# Leech requires a recursive directory listing of the web server or application server filesystem
# Given the URL, Port, any proxy servers required, Leech recursively tries to download the files.
# It creates a log file called "downloadable-files.log" that lists the files that were downloaded.
# Leech v1.3

# TODO
# =====
# 1. Pretty reporting
# 2. Reverse directory traversal
# 3. Nikto support
# 4. AI support
# 5. Proxy authentication support
# 6. NTLM authentication support

# Functionality that will not be implemented in future versions
# =============================================================
# 1. NTLM support - proxy can be used for workaround + dependence on more perl modules is required to implement this

# Bug Fixes in this release
# =========================
# 1. URL support
# 2. wget support with the use of a proxy had bugs
# 3. Folder naming scheme needed some tweaking
# 4. Activity logging

# Added features
# ==============
# 1. Basic authentication support

require LWP::UserAgent;
require HTTP::Request;
use HTTP::Cookies;

use MIME::Base64;
use Getopt::Std;
use Getopt::Long;
use dirparser;
use lsparser;
use separator;
use Cwd;

$character = '';
$ua = LWP::UserAgent->new(env_proxy => 1,
                          keep_alive => 1,
                          timeout => 30,
                          requests_redirectable => [],
                         );
$ua->timeout(10);
$ua->agent('Mozilla/5.0');
&process_commandline();

sub process_commandline
{
  my $proxy = '';
  my $url = '';
  my $help;
  my $port = 0;
  my $type = 0;
  my $root;
  my $ssl = 0;
  my $fname = "";
  my $prefix;
  my $verbose;
  my $swiggler;
  my $cookie;
  my $ntlm;
  my $basic;

  my $hostname;

  $result = GetOptions("proxy:s" => \$proxy,
                       "port=i" => \$port,
                       "url=s" => \$url,
                       "type=i" => \$type,
                       "root:s" => \$root,
                       "ssl" => \$ssl,
                       "fname=s" => \$fname,
                       "help!" => \$help,
                       "verbose!"=>\$verbose,
                       "swiggler!"=>\$swiggler,
                       "cookie:s"=>\$cookie,
                       "ntlm:s"=>\$ntlm,
                       "basic:s"=>\$basic );
  # print STDOUT $help," - ",$proxy," - ",$port," - ",$url;
  if (  ($help == 1) || ($url eq '') || ($type == 0 ))    # print help and do nothing else
  {
    print <<END;
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM   ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   MMMMMMMMMM
MMMMMMMMM   MMMMMMMMO8EEMMMMMMO8bEMMMMMMO8bEOMMMM   MWQMMMMMMM
MMMMMMMMM   MMMMMMM.     #MMM.     WMMM:     iMM2      ,MMMMMM
MMMMMMMM   IMMMMMM   z.  .MM   o.   MM   :i   MM        MMMMMM
MMMMMMMM   MMMMMM.  2MW  .M,  1MO   Mi  UMMSOMMM   MS  oMMMMMM
MMMMMMMM  iMMMMMO        EM        IM   MMMMMMM7  EM   MMMMMMM
MMMMMMM   .1c;7ME  vMMMMMM#  iMMMMMMO  .MM  :MM   MM  .MMMMMMM
MMMMMMM        MO   t.  0MM   t.  9MM   .   :MO   M;  bMMMMMMM
MMMMMM        BMM;    .#MMMc     WMMM7    .#MMi  2M   MMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

usage: leech.pl [--help] [--proxy proxy:port] [--port port] {--url URL} {--type 1|2|3|4} {--fname filename}
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
      Example 3:  $0 --url https://site.com:8080 --type 3 --fname lsalr.txt --verbose
END
    exit;
  }
  else # a proper input is supplied with essential fields provided
  {
    if ( $ssl != 1 )
    {
      $isssl = 0;
      if ( $url =~ /http:/ )
      {
        $prefix = "";
      }
      else
      {
        if ( $url =~ /https:/ )
        {
          $prefix = "";
        }
        else
        {
          $prefix = "";
        }
      }
    }
    if ( $port == 0 ) # port is not defined
    {
      if ( $url =~ /https:/ )  # default port for https -> 443
      {
        if ( $url =~ /https:\/\/[a-zA-Z0-9\.\-]*:[0-9]*/ )
        {
          @parts_of_url = split (/:/,$url);
          $port = $parts_of_url[2];
          $url = $parts_of_url[0].":".$parts_of_url[1];
          $prefix = "";
        }
        else
        {
          $port = 443;
          $isssl = 1;
          $prefix = "";
        }
      }
      else
      {
        if ( $url =~ /http:/ )
        {
          if ( $ssl == 1 )
          {
            print "Did you make a mistake? --ssl and an http URL? Interesting!\n";
            print "Either remove http prefix or remove the --ssl flag\n";
            print "Report bugs to rajats\@gmail.com";
            exit;
          }
          if ( $url =~ /http:\/\/[a-z0-9A-Z\.\-]*:[0-9]*/ )
          { # http://test-ing.test:394
             @parts_of_url = split (/:/,$url);
             $port = $parts_of_url[2];
             $url = $parts_of_url[0].":".$parts_of_url[1];
             $prefix = "";
          }
          else
          {
            $port = 80;  # default port for http -> 80
            $prefix = "";
          }
        }
        else
        { # $url does neither contains http nor https; so now use ssl flag to decide the port and prefix
          if ($ssl == 1)
          {
            @parts_of_url = split(/:/,$url);
            $prefix = "https://";
            $array_size = @parts_of_url;
            if ($array_size >= 2)
            {
              $port = $parts_of_url[1];
              $url = $parts_of_url[0];
            }
            else
            {
              $port= 443;
            }
          }
          else
          {
            @parts_of_url = split(/:/,$url);
            $prefix = "http://";
            $array_size = @parts_of_url;
            if ($array_size >= 2)
            {
              $port = $parts_of_url[1];
              $url = $parts_of_url[0];
            }
            else
            {
              $port= 80;
            }
          }
        }
      }
    }
    else # if port number was supplied
    {
      if ( $ssl == 1 ) # ssl flag set and port number was supplied
      {  #--ssl --url blah   ; then force SSL https://bla
        if ( $url =~ /http:/ )  # and the url did not begin with https
        {
          print "Did you make a mistake? --ssl and an http URL? Interesting!\n";
          print "Either remove http prefix or remove the --ssl flag\n";
          print "Report bugs to rajats\@gmail.com";
          exit;
        }
        else   # --ssl --url http://blah --> did you make a mistake?
        {
          if ( $url =~ /https:/ )
          {
            $prefix = "";
          }
          else
          {
            $prefix = "https://";
          }
        }
      }
      else # if ssl flag is not set and port number is supplied
      {
        if ($url =~ /https:/)
        {
          $prefix = "";
          #print $prefix."\n";
        }
        else
        {
          if ($url =~ /http:/)
          {
            $prefix = "";
          }
          else
          { #ssl flag is not set and url is just the hostname; so use default http
            $prefix = "http://";
          }
        }
      }
    }

    # Check to see if NTLM or basic authentication is required.
    #if ( $ntlm ne '' )
    #{
    #  $ntlm =~ s/\\/\\\\/; # Replace the first \ with \\ ... no validations please
    #  ($username,$password) = split (/:/,$ntlm);
    #  $urlstr = $prefix.$url;
    #  @tempStr = split (/:/,$urlstr);
    #  $hostname = $tempStr[1];
    #  $hostname =~ s/\/\///;
      #print "hostname : ".$hostname.":".$port."\n";
    #  $ua->credentials($hostname.":".$port, '', $username, $password);
      #exit;
    #}

    #figure out the OS to find the filename delimiter
    my $OS = '';
    my $delimiter = '';
    unless ($OS)
    {
      unless ($OS = $^O)
      {
        require Config;
        $OS = $Config::Config{'osname'};
      }
    }
    if    ($OS=~/Win/i)     { $OS = 'WINDOWS'; $delimiter = '\\\\';}
    elsif ($OS=~/vms/i)     { $OS = 'VMS'; $delimiter = '/';}
    elsif ($OS=~/^MacOS$/i) { $OS = 'MACINTOSH'; $delimiter = '/';}
    elsif ($OS=~/os2/i)     { $OS = 'OS2'; $delimiter = '/';}
    else  { $OS = 'UNIX'; $delimiter = '/';}

    my @timenow = localtime(time);
    my @modhostname = split(/[:\/]/,$url);
    $hostname = join('_',@modhostname);
    my $foldername = sprintf ("%02d%02d%02d-%s-%d",$timenow[2],$timenow[1],$timenow[0],$hostname,$port);
    #my $foldername = join("",$timenow[2],$timenow[1],$timenow[0],"-",$hostname,"-",$port);
    mkdir ($foldername,0755) || die "Could not create directory $foldername";
    if ($type == 1)
    {
      dirparser::dir_parser($fname,"$foldername/test-temp.log");
    }
    elsif ( $type == 2 )
    {
      dirparser::dir_parser_b($fname,"$foldername/test-temp.log");
    }
    elsif ( $type == 3 )
    {
      lsparser::ls_parser($fname,"$foldername/test-temp.log");
    }
    elsif ( $type == 4 )
    {
      lsparser::ls_parser($fname,"$foldername/test-temp.log");
    }
    else
    {
      die "--type value can only be from 1 to 4.  Find out your file type."
    }
    if ( $root ne '' )
    {
      #remove leading and trailing slashes
      $root =~ s/^[\/]+//;
      $root =~ s/[\/]+$//;
    }
    separator::separator("$foldername/test-temp.log","$foldername/test-temp2.log");
    # print "Proxy: ".$proxy." url : ".$url." port : ".$port." type = ".$type." file : ".$fname."Prefix : ".$prefix."\n";
    open RECURSIVE_PATHS, "< $foldername/test-temp2.log" or die "Could not open $foldername/test-temp2.log";
    open DOWNLOAD_LOG,"> $foldername/downloadable-files.log" or die "Cannot create file $foldername/downloadable-files.log!\n";
    open PRESENT_BUT_NO_ACCESS,"> $foldername/access-denied.log" or die "Cannot create file $foldername/access-denied.log!\n";
    open ACTIVITY_LOG,"> $foldername/activity.log" or die "Cannot create file $foldername/activity.log!\n";

    # basic authentication block
    if ($basic ne '')
    {
      $encodedstr = encode_base64($basic,"");
      $ua->default_header("Authorization"=>"Basic ".$encodedstr);
    }
    # wget switches
    my $wgetswitch='';
    #system("rm -f dload.log");
    my $statuscode;
    my $count = 0; # no_of_requests
    my $dloadedcount = 0;
    my $count403s = 0;
    my $cookie_jar = HTTP::Cookies->new();

    if ($proxy ne '')
    {
      if ( $url =~ /https:/ )
      {
        $savedproxy = $ENV{'https_proxy'};
        $ENV{'https_proxy'}=$proxy;
      }
      else
      {
        $savedproxy = $ENV{'https_proxy'};
        $ENV{'http_proxy'}=$proxy;
      }
    }
    # ---- setting wget switches
    if ($cookie ne '')
    {
      $wgetswitch .= " --header=$cookie ";
      #$ua->cookie_jar( $cookie_jar );
    }
    if ($path =~ /https:/)
    {
      $wgetswitch .= " --no-check-certificate ";
    }
    if ($basic ne '')
    {
      chomp($encodedstr);
      #print "base64 : ".$encodedstr."\n";
      $wgetswitch .= " --header=\"Authorization: Basic ".$encodedstr."\" ";
    }
    if ($proxy ne '')
    {
      $wgetswitch .= " --proxy ";
    }
    # ---- end of wget switches

    while (<RECURSIVE_PATHS>)
    {
      $count++;
      if ($root ne '')
      {
        #print $prefix.$url.":".$port."/".$root."/".$_."\n";
        $statuscode = &sendHttpReq($prefix.$url.":".$port."/".$root."/".$_,$proxy,$cookie);
      }
      else
      {
        #print $prefix.$url.":".$port."/".$_."\n";
        $statuscode = &sendHttpReq($prefix.$url.":".$port."/".$_,$proxy,$cookie);
      }
      if ($verbose)
      {
        print $statuscode." : ".$path;
        print ACTIVITY_LOG $statuscode." : ".$path."\n";
      }

      if ($statuscode == 200 || $statuscode  == 403)
      {
        if ($statuscode  == 200)
        {
          print DOWNLOAD_LOG $path;
          $dloadedcount++;
        }
        elsif ($statuscode == 403)
        {
          print PRESENT_BUT_NO_ACCESS $path;
          $count403s++;
        }
        if ($statuscode == 200)
        {
          $currdir = getcwd();
          if ($OS == 'WINDOWS')
          {
            $currdir =~ s/\\/\\\\/g;
          }
          #@params = ("wget",$wgetswitch,$path,"-a $foldername\dload.log","-P $foldername");
          #chomp($path);
          $cmd  = $currdir."/wget $wgetswitch $path -a ".$currdir.$delimiter.$foldername.$delimiter."dload.log -P ".$currdir.$delimiter.$foldername;
          #print $cmd."\n";
          system($cmd);
          #if ($? == 0)
          #{
          #  print "execution worked $?\n";
          #}
          #elsif ($? && 127 )
          #{
          #  print "error encountered $?\n";
          #}
          #else
          #{
          #  printf("code = %d\n",$?>>8);
          #}
        }
      }
      else
      {  # if other codes occur -> 500, 404 etc. Do nothing or customize
      }
      if ($verbose == 0 && $swiggler == 1)
      {
        &swiggler($count);
      }
    } # end of while
    close DOWNLOAD_LOG;
    close PRESENT_BUT_NO_ACCESS;
    close RECURSIVE_PATHS;
    close ACTIVITY_LOG;
    print "Summary:\n-------\nTotal files downloaded = $dloadedcount\nTotal requests made = $count\n";
    print "All downloaded files are saved to $foldername/downloads.\n";
    print "The files that Leech downloaded are listed in $foldername/downloaded-files.log.\n"  ;
    if ($proxy ne '')
    {
      if ( $url =~ /https:/ )
      {
        $ENV{'https_proxy'} = $savedproxy;
      }
      else
      {
        $ENV{'https_proxy'} = $savedproxy ;
      }
    }
  }  # end of else
}


sub sendHttpReq
{
#  $ua = LWP::UserAgent->new(env_proxy => 1,
#                            keep_alive => 1,
#                            timeout => 30,
#                            requests_redirectable => [],
#                           );
#  $ua->timeout(10);
#  $ua->agent('Mozilla/5.0');
  if ($_[2] ne '')
  {
    # print $_[2]."\n";
    $ua->default_header("Cookie"=> $_[2]);
  }
  $path = $_[0];
  $proxy = $_[1];
  $cookieval = $_[2];
  if ($proxy ne '')
  {
    #print $proxy;
    my $proxypref = '';
    if ($proxy !~ /http/)
    {
      $proxypref = "http://";
    }
    if ($url !~ /https:/)
    {
      $ua->proxy('http',$proxypref.$proxy);
    }
    else
    {
      $ua->proxy('https',$proxypref.$proxy);
    }
  }
  #print $path."\n";

  my $response = $ua->head( $path );
  return $response->code;
}



sub swiggler
{
  $counter = $_[0];
  $character = '';
  if ($counter%4 == 0)
  {
    $character = '-';
  }
  elsif ($counter%4 == 1)
  {
    $character = '\\';
  }
  elsif ($counter%4 == 2)
  {
    $character = '|';
  }
  elsif ($counter%4 == 3)
  {
    $character = '/';
  }
  print
  $character."\n";
  system("clear");
}

sub nikto_cloner
{

}

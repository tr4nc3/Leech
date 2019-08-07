package separator;

sub separator
{
  $filename = $_[0];
  open(SOURCE, "< $filename")
    or die "Could not open $filename\n";
  open DEST,"> $_[1]" or die "Could not open $_[1]\n";
  while ($line = <SOURCE>)
  {
     chop($line);
     my @dirs = split(/\\/,$line);
     my $no_of_dirs =  @dirs;
     #print $no_of_dirs;
     for ($i = 1 ; $i < $no_of_dirs ; $i++ )
     {
       for ($j = $i ; $j < $no_of_dirs; $j++ )
       {
         print DEST $dirs[$j];
         if ($j < $no_of_dirs - 1)
         {
           print DEST "\/";
         }
       }  #end of for
       print DEST "\n";
     }
  }
  close SOURCE;
  close DEST;

}

1;
package dirparser;

sub dir_parser
{
        $filename = $_[0];
	open SOURCE, "< $filename" or die "Could not open $filename\n";
        open DEST, "> $_[1]" or die "Could not open $_[1]\n";
	while ($line = <SOURCE>)
	{
		if ($line =~ /Directory/)
		{
			# print $line;
			$line =~ s/[a-zA-Z\s]+://;
			chomp $line;
			$dir = $line;
			# print $line . $dir . "\n";
		}
		else
		{
			if ($line =~ /\<DIR\>/ || $line =~ /File\(s\)/ || $line =~ /^\s$/ || $line =~ /Total\sFiles\sListed\:/ ||
				$line =~ /Dir\(s\)/ || $line =~ /Volume/)
			{ # do nothing
			}
			else
			{
				@component = split (/\s/,$line);
				$path = "$dir" . "\\" .  $component[$#component];
				print DEST $path . "\n";
			}

		}
	} # end of while
	close SOURCE;
	close DEST;

}

sub dir_parser_b
{
        $filename = $_[0];
	open SOURCE, "< $filename" or die "Could not open $filename\n";
        open DEST, "> $_[1]" or die "Could not open $_[1]\n";
	while ($line = <SOURCE>)
	{
          chomp $line;
          $line =~ s/^[A-Z]\://g ;
          print DEST $line."\n";
	} # end of while
	close SOURCE;
	close DEST;
}

1;
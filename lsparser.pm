package lsparser;

sub ls_parser
{
	$file = $_[0];
	open SOURCE, "< $file" or die "Could not open the $file";
        open DEST,"> $_[1]" or die "Could not open $_[1]\n";
	while ($line = <SOURCE>) 
	{
		if ($line =~ /\:$/)
		{
			$line =~ s/\:$//;
			chomp $line;
			$dir = $line;
			$dir =~ s/\//\\/g;

		}
		else
		{
			if ($line =~ /total\s[0-9]+/)
			{ # do nothing
			}
			else
			{
				if ($line =~ /^\s$/)
				{ # do nothing
				}
				else
				{
					@component = split (/\s/,$line);
					if ($line =~ /->/)
					{
						$path = "$dir" . "\\" . $component[$#component - 2];
					}
					else
					{
						$path = "$dir"."\\".$component[$#component];
					}
					print DEST $path . "\n";
				}
			}
		}
	}
	close SOURCE;
	close DEST;
}

1;
#!/usr/bin/perl -w
#_wadinfo.pl:0.7:1017789431:pod,tkb,pb

# script to walk a directory tree, look for/at wadfiles, then get their
# information, output to stdout/file

# %z is a hash that holds everything.  This makes it easy to pass it by
# reference in and out of functions.  Makes things nice and clean
#
# This file is POD documented.  Use any of the following to extract the
# documentation:
#
# pod2text filename.pl | less
# pod2man filename.pl | nroff -man - | less
# man -t ./filename.1 | mpage -2 | lpr -Pprinter
# pod2html filename.pl > filename.html; lynx filename.html

=pod

=head1 NAME

wadinfo.pl - Examine a Doom Patch WAD file, see what levels are contained in it

=head1 SYNOPSIS

B<wadinfo> [B<-h>] [B<-d>] [B<-d>] [B<-f> /path/to/wads] [B<-l> filename.txt] [B<-o> filename.wl]

=head1 DESCRIPTION

I<wadinfo> goes through a list of Doom Patch WAD files, extracts the levels
contained in the PWAD files, then writes the full paths of the WAD and the
levels contained in the wad to a file or to B<STDOUT>.

=cut

# turn on strict-ness
use strict;
use Getopt::Std;

# un-buffer output
$| = 1;

# globals
my (%z, @filelist, @bytes, $x, $y, %opts, $out, $date, $VERSION);

# set the version
$VERSION = "0.7";

# get the name of the program
my @programname = split("/", $0);
$z{p_n} = $programname[-1];

# check the command line for options
# 'd' and 'D' take no arguments, and 'f' and 'l' take filenames
&getopts("cdDf:l:o:", \%opts);

# are we debugging?
$z{DEBUG} = $ENV{DEBUG};
if ( exists $opts{d} ) {
	# for debugging
	$z{DEBUG} = 1;	
} elsif ( exists $opts{D} ) {
	# really noisy
	$z{DEBUG} = 2;	
} # if ( exists $opts{d} )

# make sure we were passed a path to search for WAD files
# or a file with wadfile names in it
if ( exists $opts{f} ) {
	# call system(find $path) to get a list of MP3's		
	print STDERR $z{p_n} . ": Executing system(find) on $opts{f}...\n";
	@filelist = `find $opts{f} -iname \"*.wad\" -print`;
} elsif ( exists $opts{l} ) {
	# or open the passed in list of files
	open (WADLIST, $opts{l}) || die $z{p_n} . ": Can't open file list: $!";
	@filelist = <WADLIST>;
	close (WADLIST);
} else {
    print "\n" . $z{p_n} . "v". $VERSION . " (c) 2002 Brian Manning\n";
	print "* Generates a list of WAD files, and their contents (levels)\n";
    print "\nUsage:\n";
    print $z{p_n} . " [-d|-D] [-f|-l <file>] [-o <file>]\n";
	print "\nRequired parameters (only one of the following)\n";
	print "-f: system(find) *.wad on <parameter> (Case insensitive)\n";
    print "-l: read the file <parameter>, which should be a list of WAD " .
            "files,\n    one file per line\n";
	print "\nOptional parameters (one or more of the following)\n";
	print "-d: run in debug mode.  Also set by calling 'DEBUG=1 $z{p_n}'\n";
    print "-D: extra noisy debug mode. You probably don't want this\n";
	print "-c: Show a PWAD counter as the program runs\n";
	print "-o: output file. If no file is specified, defaults to STDOUT \n";
	print "\n";

    exit 1;
} # if ( exists $opts{} )
 
# see where we are writing the output to
# make sure the output file can be written to
if ( exists $opts{o} ) {
	open(OUTFILE, ">$opts{o}") || 
		die "Sorry, can't open file $opts{o} for writing";
	$out = *OUTFILE;
	# open the file to write to here
} else {
	# set the output to STDOUT
	$out = *STDOUT;
} # if ( exists $opts{o} )

=pod

=head1 OPTIONS

=over 5

=item B<-h> help 

Prints script options

=item B<-d> debug 

Prints mild debugging information to B<STDERR>

=item B<-D> extra noisy debug

You most likely don't want this option

=item B<-c> show a PWAD counter

Shows a valid PWAD counter as it's working through a list of files

=item B<-f> find files

Generates a list of WAD files using the system's I<find(1L)> command, using the
directory that is passed in on the command line as the starting point

=item B<-l> reads files from a list

Reads a list of WAD files contained in the file passed in on the command line,
then outputs a list of WAD files and levels 

=item B<-o> output file.  If no output file is specified, defaults to B<STDOUT>

Writes the output of I<wadinfo> to a file.  It's recommended that you name the
file with an extension of either B<'.wl'> or B<'.txt'>.  If this option is not
given, the file is written to B<STDOUT>

=back 

=cut

######################
# Begin main program #
######################

# set up the counters
$z{total_files} = 0; # set a line counter 
$z{start_time} = time; # set the overall start time 

# create the file header
print $out "# This is an automagically generated WAD information file\n";
print $out "#_wadinfo.pl:" . $VERSION . ":$z{start_time}\n";
print $out "# You can hack this up, but it's a good idea not to change any\n";
print $out "# formatting, as it will probably render the file unusable.\n";
print $out "# Comments may be added to the file by creating a line starting\n";
print $out "# the '#' hash character.  Please do not change the first line\n";
print $out "# of this file.  The format of the file is as follows:\n";
print $out "# /path/to/a/wad/file.wad:E?M? E?M?  -or-\n";
print $out "# /path/to/a/wad/file.wad:MAP?? MAP??\n";
print $out "# If you are adding lines by hand, please follow this format,\n";
print $out "# otherwise tkBoom will not use the wad list file.\n";

# create a hash for storing things while we walk the WAD list
my (%walk, $file);
# read in each line of the list of files, then run it against the database
foreach $file (@filelist) {
    # remove the EOL
    chomp($file);
    # get the filename
    my @parts = split('/', $file);
    # get the number of elements in the @parts array
    my $maxparts = @parts;
    # {wadfile} is the last member of the @parts array
    $walk{wadfile} = $parts[$maxparts - 1];
    # check to see if it's a PWAD
	# open the file
	open(WADFILE, "<$file")  || die $z{p_n} . ": Can't open WAD file: $!";
	# get the size of the file, for the WAD directory walking loop later on
	$walk{filesize} = (stat($file))[7];
	print $out $z{p_n} . ": filesize is " . $walk{filesize} . "\n" 
		if ( defined $z{DEBUG} && $z{DEBUG} > 1);
	# assign the file offset 
	$walk{offset} = 0;
	# what byte group we are looking at
    $walk{description} = "WAD ID";
	# size of the byte group
    $walk{readsize} = 12;
	# get the first 12 bytes of the file
	@bytes = &ReadFile(\%z, \%walk, *WADFILE);
	# put together the first 4 bytes into a string	
	for ($x = 0; $x <= 3; $x++) {
		$walk{wadtype} .= chr(hex($bytes[$x]));
	} # for ($x = 0; $x >= 3; $x++)
	# check the first 4 bytes for the string 'PWAD'
	if ( $walk{wadtype} eq 'IWAD' ) {
		print $out $file . ": IWAD found\n" if $z{DEBUG};
	} elsif ( $walk{wadtype} ne 'PWAD' ) {
		print $out $file . ": Unknown file type\n" if $z{DEBUG};
	} else {
		# get the last 4 bytes for the offset, and re-assemble them in the
		# correct order, convert to decimal, and store in $offset
	    my $offset = "";
		for (my $y = 11; $y >= 8; $y--) {
			$offset .= $bytes[$y];
			#print "y is $y, offset is $offset\n" if $z{DEBUG};
		} # for ($y = $length; $y >= $length - 5; $y--)
		print $out $z{p_n} . ": offset is $offset, hex(offset) is " . 
				hex($offset) . "\n" if ( defined $z{DEBUG} && $z{DEBUG} > 1);
		# set the starting offset (convert from hex)
	    $walk{offset} = hex($offset);	
	    # now read the directory entries
		# all of the directory entries are 16 bytes in size
	    $walk{readsize} = 16;
		# loop thru the rest of the file one directory entry at a time, and look
		# for an 'M?P' string or a 'E?M' string starting at offset byte 8 of
		# the read block of data
		my ($string, $tmp, $dircount, $printfile);
		$dircount = $printfile = 0;
	    while ($walk{offset} < $walk{filesize}) {
			@bytes = &ReadFile(\%z, \%walk, *WADFILE);
			for ($tmp = 8; $tmp <= 15; $tmp++) {
				if ( chr(hex($bytes[$tmp])) =~ /\w/  ) {
					$string = $string . chr(hex($bytes[$tmp]));
				} # if ( chr(hex($bytes[$tmp]) =~ /\w/ )
			} #for (my $tmp = 8; $tmp = 15; $tmp++)			
			# this should catch M?P or E?M strings
			
			if ( (defined $string) &&
					($string =~ /^MAP\d\d/ || $string =~ /^E\dM\d/ ) ) {
				# trim the ends of the (valid) strings to remove excess chars
				if ( $string =~ /^MAP\d\d/ ) {
					$string = substr($string, 0, 5);
				} elsif ( $string =~ /^E\dM\d/ ) {
					$string = substr($string, 0, 4);
				} # if ( $string =~ /^MAP\d\d/ )
				if ( $printfile == 0 && $z{DEBUG} ) {
					if ( $z{total_files} > 0 ) { print $out "\n";}
					print $out $z{p_n} . ": " . $file . " - PWAD found\n";
					print $out $z{p_n} . ": Levels: ";
					$printfile = 1;
				} elsif ( $printfile == 0 ) {
					if ( $z{total_files} > 0 ) { print $out "\n";}
					print $out $file . "=";
					if ( exists $opts{c} ) {
						print STDERR "Found $z{total_files} valid WAD files\r";
					} # if ( defined $opt{c} )
					$printfile = 1;
				} # if ( $z{DEBUG} )	
				# output the actual bytes
				print $out $string . " ";
				print $out "\n".$z{p_n}.": found $string, " . 
						"offset is $walk{offset}\n"
					if ( defined $z{DEBUG} && $z{DEBUG} > 1);
			} # big if block 
			$string = "";
			$dircount++;
			$walk{offset} += 16; # add 16 to go to the next entry
			#if ($dircount == 20 && $z{DEBUG}) {exit 1;}
	    } # while ($walk{offset} < $walk{filesize})
		# a last newline behind the list of levels
		#print "\n";	
	} #  elsif ( $walk{wadtype} ne 'PWAD'
    # update the total files checked
	$z{total_files}++;
	if ($z{total_files} == 20  && $z{DEBUG}) {exit 1;}
	#if ($z{total_files} == 20 ) {exit 1;}
	# zero out the wadtype 
	$walk{wadtype} = "";
} # foreach $file (@filelist)

# add an extra newline for the end
print $out "\n";

# tell'em how we did...
$z{total_time} = time - $z{start_time};
$z{total_min} = $z{total_time} / 60;
if ( $z{DEBUG} ) {
	print $out $z{p_n} . ": Checked " . $z{total_files} . " WAD files in " . 
		$z{total_time} . " seconds, or " . $z{total_min} . " minutes.\n";
} # if ( $z{DEBUG} )

# check to see if there was an output filehandle opened, and close it
if ( exists $opts{o} ) {
	close($out);
} # if ( exists $opts{o} ) 

if ( exists $opts{c} ) {
	# print a \n to STDERR so the command line doesn't overwrite the WAD count
	print STDERR "\n";
} # if ( exists $opts{c} ) 

exit 0;

############
# ReadFile #
############
sub ReadFile {
	my $z = $_[0];
	my $ptr = $_[1];
	my $filehandle = $_[2];
	my ($wadid, @return);
	# read in the first $readsize, $readoffset bytes
	print $$z{p_n} . ": readsize is " . $$ptr{readsize} .  " and offset is " .  			$$ptr{offset} .  "\n" if ( defined $z{DEBUG} && $z{DEBUG} > 1);
	seek($filehandle, $$ptr{offset}, 0); # seek from BOF
	read($filehandle, $wadid, $$ptr{readsize}) || 
		die $$z{p_n} . ": Can't read " . $$ptr{description} . ": $!";
	# now walk thru the requested bytes, converting to hex
	for (my $x = 0; $x <= $$ptr{readsize}; $x++) {
		#if ($x > $$ptr{readsize}) {die "$x - " . $$ptr{readsize}};
		#if ( defined substr($wadid, $x, 1) ) {
		# this next part is coughing up major errors.  Apparently, there are
		# bad WAD files out there, as there's not always valid directory
		# entries at the end of the WAD (16 byte blocks with a descripton of
		# the lump and an offset from the start of the WAD file to the
		# beginning of the lump).  So this next line is here to check to make
		# sure a valid block of data was read, and if not, to not do the loop
		# that translates the values from binary to hex strings
		#
		# If the length of the offset is greater than the length of the
		# $wadid string, then don't do the conversion to hex
		if ( length($wadid) == $$ptr{readsize} )  {
			push(@return, sprintf("%lx", ord(substr($wadid, $x, 1))));
		} else {
			push(@return, "f");	
		#	die "x $x / readsize " . $$ptr{readsize} . " / length "
		#		. length($wadid);
		} # if ( length($wadid) == $$ptr{readsize} ) 
	} # for ($x = 0; $x != 12; $x++)
	# print and return the put-together string
    print $$z{p_n} . ": returning @return\n" 
		if ( defined $z{DEBUG} && $z{DEBUG} > 1);
    return @return;
} # sub ReadFile

=pod

=head1 EXAMPLES

=over 5

=item wadinfo.pl -c -l wadlist.txt -o wadlist.wl

Will generate a list of WADs based on the list of files in I<wadlist.txt>, and
output the list into I<wadlist.wl> in a format that L<tkBoom> will be able to
parse.  A counter is shown on the screen, showing how many valid WADs have been
found.

=item wadinfo.pl -f /path/to/wad/files -o wadlist.wl

Will call system("find /path/to/wad/files -iname *.wad -print") to generate a list of WAD files.  This could take some time to run, so it's not recommended if you are using it from another program like L<tkBoom>.

=item wadinfo.pl -l wadlist.txt > wadlist.wl

Uses the WAD files contained in I<wadlist.txt> to generate a list of WAD files
and levels, and writes the output to B<STDOUT>.

=item wadinfo -d -l wadlist.txt -o wadlist.wl

Reads from wadlist.txt, writes to wadlist.wl, and shows debugging info on
B<STDERR> as it's running.

=head1 NOTES

The output of the script will be a listing of PWAD files, along with the levels
contained in each PWAD file.  The format is /path/to/pwad.wad=WADLVL.  You
can safely put comments into the file by using the shell/perl comment character
'B<#>' at the beginning of the line.  Any line commented will be ignored by any
script/program that reads the output file.  Any comments placed into the file
will be lost if the file is re-generated.

=head1 VERSION 

See the beginning of this file for the current version and date.

=head1 AUTHOR

Brian Manning

=cut

###############
# end of line #
###############

#!/usr/bin/perl -w

# demo script for reading Doom PWAD files, and getting useful info out of them
# convert from hex to decimal with "echo $((0x453c58))"

# turn on strictness
use strict;

# short command line options
use Getopt::Std;

# get the file from the command line
my %opts; # command line options
my %z; # main config/variable hash
my $OUT; # where to print output to

# go get the command line args
&getopts("dDFf:", \%opts);

# -d debug
# -D extra debug (noisy)
# -F force read, ignore problem wadfiles (slower)
# -f file to read

# check if we're debugging
if ( exists $opts{d} ) { 
	$z{DEBUG} = "1";
	# send output to STDERR
	$OUT = *STDERR;
} else {
	# send output to STDOUT
	$OUT = *STDOUT;
} # if ( exists $opts{d} )

# open the file
warn "Opening $opts{f}\n " if $z{DEBUG};
open(FH, "<$opts{f}") || die "Can't open $opts{f}; $!";

# read the WAD type
read(FH, my $return, 4) || die "can't read $opts{f} : $!";
warn "returning '$return'" if $z{DEBUG};

# if it's a PWAD, then read the directory offset
if ( $return eq 'PWAD' ) {
	# put the filepointer to the correct byte
	seek(FH, 8, 0) || die "can't seek directory, $!";
	# read the 4 byte directory offset pointer
	read (FH, $return, 4);

	# convert it to MSB and print it
	my $wadptr = &ReverseConvert($return);
	warn "Directory starts at 0x" . $wadptr if $z{DEBUG};

	# walk each directory entry, looking for E?M? or MAP??
	# first, convert the hex value to decimal
	$wadptr = hex($wadptr);
	
	warn "Directory starts at $wadptr" if $z{DEBUG};

	# seek the next directory entry first before we loop
	# add 8 to the master directory pointer, so we hit the lumpname instead of
	# the lump location
	seek(FH, $wadptr + 8, 0) || die "can't seek $wadptr, $!";

	# a valid wadfile flag
	my $valid = 0;
	
	# then walk the file until EOF
	do {
		my $x = 0;
		if ( read (FH, $return, 8) == 0 ) { die "oops.  read past EOF"; }		
		#print STDERR "\n$wadptr: $return\n";
		if ( $return =~ /^E\dM\d.*/ || $return =~ /^MAP\d\d.*/ ) { 
			# remove non-alphanumeric characters
			$return =~ s/\W+//;			
			if ( $z{DEBUG} || exists $opts{F} ) {
				# print out the wadptr offset
				print $OUT "\n$wadptr : $return";
			} else {
				# print the value returned by the read() call
				print $OUT $return . " " ; 			
			} # if ( $z{DEBUG} )
			# set the valid wad flag
			$valid = 1;
			# since we found a valid level lump, skip ahead 10 more lumps to
			# get somewhere near the next valid level header
			if ( ! exists $opts{F} ) {
				$wadptr += 160;
			} else {
				# oops, {F}orce is set, so only increment by 16 bytes
				 $wadptr += 16;
			} # if ( ! exists $opts{F} )
		} elsif ( ! $valid && ! $opts{F} )  {
			# it's not a valid wad, and we don't have {F}orce turned on
			die "Sorry, $opts{f}\n is not a valid wadfile";
		} else {
			# we didn't find a mapname, so only go to the next lump
			# add 16 to get the next lump entry
			$wadptr += 16;	
			if ( exists $opts{F} || $z{DEBUG} ) {
				print $OUT " $return";
			} # if ( exists $opts{F} )
		} # if ( $return =~ /^M\dE\d/ || $return =~ /^MAP\d\d/ )
		
		# now seek to the next lump
		seek(FH, $wadptr + 8, 0) || die "can't seek $wadptr, $!";
	} while ( ! eof(FH) ); # we hit EOF
} # if ( $return eq 'PWAD' ) {

# close the filehandle, we're done reading
close (FH);

# exit with no errors
print $OUT "\n";
exit 0;

### Begin Functions ###

sub ReverseConvert {
	my ( $wadptr, $bytecount );
	# now convert the offset to a MSB value from a LSB value
	for ($bytecount = 4; $bytecount >= 0; $bytecount--) {
		$wadptr .= sprintf("%lx", ord(substr($_[0], $bytecount, 1)));
	}
	# return the reversed value
	return $wadptr;
} # sub ReverseConvert

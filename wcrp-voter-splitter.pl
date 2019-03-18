#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# wcrp-voter-splitter
#
#
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#use strict;
use warnings;
$| = 1;
use File::Basename;
use DBI;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use Time::Piece;
use Math::Round;

no warnings "uninitialized";


=head1 Function
=over
=head2 Overview
	This program will split large csv files into smaller ones
		a) no restrictions
		b)
	Input: any csv file with headers
	       
	Output: one or more smaller csv file
	parms:
	'infile=s'     => \$inputFile,
	'outfile=s'    => \$outputFile,
	'maxlines=s'   => \$maxLines,
	'maxfiles=n'   => \$maxFiles,
	'help!'        => \$helpReq,
	
=cut

my $records;
my $inputFile = "../prod-in1/base.csv";    

my $fileName         = "";

my $outputFile        = "../prod-in1/";
my $outputFileh;

my $printFile        = "print-.txt";
my $printFileh;


my $helpReq            = 0;
my $maxLines           = 25000;
my $maxFiles           = 30;
my $fileCount          = 0;
my $csvHeadings        = "";
my @csvHeadings;
my $line1Read    = '';
my $linesRead    = 0;
my $printData;
my $linesWritten = 0;

#
# main program controller
#
sub main {
	#Open file for messages and errors
	open( $printFileh, ">$printFile" )
	  or die "Unable to open PRINT: $printFile Reason: $!";

	# Parse any parameters
	GetOptions(
		'infile=s'     => \$inputFile,
		'outfile=s'    => \$outputFile,
		'maxlines=n'   => \$maxLines,
		'maxfiles=n'   => \$maxFiles,
		'help!'        => \$helpReq,

	) or die "Incorrect usage! \n";
	if ($helpReq) {
		print "Come on, it's really not that hard. \n";
	}
	else {
		printLine ("My inputfile is: $inputFile. \n");
	}
	unless ( open( INPUT, $inputFile ) ) {
		printLine ("Unable to open INPUT: $inputFile Reason: $! \n");
		die;
	}

	# pick out the heading line and hold it and remove end character
	$csvHeadings = <INPUT>;
	
	# headings in an array to modify
	# @csvHeadings will be used to create the files
    @csvHeadings = split( /\s*,\s*/, $csvHeadings );

	#
	# Initialize process loop and open first output
  $linesRead = $maxLines;

  NEW:
	while ( $line1Read = <INPUT> ) {
		if ($linesRead >= $maxLines) {
			if ($fileCount == $maxFiles) {
				printLine("Max Files created - $maxFiles \n");
				goto EXIT;
			}
      preparefile();
      $linesRead = 0;
		}
		$linesRead++;
		$linesIncRead++;
		if ($linesIncRead == 1000) {
			printLine ("$linesRead lines processed \n");
			$linesIncRead = 0; 
		}
		
		# replace commas from in between double quotes with a space
		$line1Read =~ s/(?:\G(?!\A)|[^"]*")[^",]*\K(?:,|"(*SKIP)(*FAIL))/ /g;

	  print $outputFileh $line1Read;
	
		$linesWritten++;
		#
		# For now this is the in-elegant way I detect completion
	}
		if ( eof(INPUT) ) {
			goto EXIT;
		}
		next;
	}
	#
	#goto NEW;

#
# call main program controller
main();
#
# Common Exit
EXIT:

printLine ("<===> Completed splitting of: $inputFile \n");
printLine ("<===> Total Records Read: $linesRead \n");
printLine ("<===> Total Records written: $linesWritten \n");

close(INPUT);
close($outputFileh);
close($printFileh);
exit;

#
# Print report line
#
sub printLine  {
	my $datestring = localtime();
	($printData) = @_;
	print $printFileh $datestring . ' ' . $printData;
	print $datestring . ' ' . $printData;
}


#
# open and prime next file
#
sub preparefile {
    my ($filename, $path, $type) = fileparse($inputFile, qr/\.[^.]*/);
    $fileCount = $fileCount+1;
    my $outputFile = $filename . '-' . $fileCount . $type;
	  printLine ("New output file: $outputFile \n");
	  open( $outputFileh, ">$outputFile" )
	    or die "Unable to open output: $outputFile Reason: $! \n";
	  print $outputFileh $csvHeadings;
}
use strict;
use Useful;

# Copyright: Judita Preiss
# Date of creation: 2 September 2011

use XML::RSS::Parser::Lite;
use LWP::UserAgent;

# Description
#
# A re-implementation of an RSS fetching tool. Relies on being given a
# list of RSS feeds (possibly generated by find_feed_lists.pl or
# manually constructed). Employs the Perl XML::RSS module, however,
# this requires a call to an external program to ensure that this
# highly sensitive module does not crash the entire program.

# Installation
#
# Modify the $DATA path below to link to a data location. The program
# expects to already have "rss_souce" and "rss_downloads" directories
# in place in that location. The rss_source directory should contain
# the various RSS feed links, the rss_downloads will contain the
# resulting downloaded files.

# Execution
#
# The program is set up to carry out one iteration of the program by
# default. It will pass through all given RSS links. To carry out
# multiple downloads, two options present themselves:
#
# 1) set up the program to repeat (e.g., every 10 mins) via crontab
# 2) a wrapper script to repeat the program's execution (and thus set
#    it to be permanently executed, just return to the start of the RSS
#    links list)

# Output
#
# By default the output (to STDERR) gives information regarding the
# success / failure of the download of each page. A failure is broken
# down into the two possibilities. Warnings are produced if the page
# could not be downloaded.

# Dependencies
#
# Program: rss_parse.pl
# Module: Useful.pm
# Perl module: LWP::UserAgent
# Perl module: XML::RSS::Parser::Lite;

# Unix-only
#
# Should the program be executed on a Unix machine, it may be faster
# to use the Unix only commands rather than their Perl implementation.

my $DATA = $ENV{HOME} . "/projects/accurat/data";

if(scalar(@ARGV) == 1){
    $DATA = $ARGV[0];
}

my $SOURCE = $DATA . "/rss_source/";
my $DOWNLOAD = $DATA . "/rss_downloads/";

(-e $SOURCE) or die "The program assumes that $SOURCE directory exists.\n";

if(!(-e $DOWNLOAD)){
    mkdir($DOWNLOAD, 0777) or die "Can't mkdir $DOWNLOAD: $!\n";
# Unix-only    (system("mkdir $DOWNLOAD") == 0) or die
# Unix-only         "Can't create $DOWNLOAD dir: $!\n";    
}

my $TEMP = "rss_parse_error-" . $$;
my $MAX_FILENAME_LENGTH = 250;

my $timestamp = construct_timestamp();

my $var;

sub construct_timestamp(){
    my ($timestamp, @time);

    @time = localtime(time);
    $timestamp = (1900 + $time[5]) . sprintf("%02d", ($time[4] + 1)) . sprintf("%02d", $time[3]) . sprintf("%02d", $time[2]) . sprintf("%02d", $time[1]) . sprintf("%02d", $time[0]);

# Unix-only my $timestamp = `date +%Y%m%d%H%M%S`;
# Unix-only chomp($timestamp);

    return $timestamp;
}

sub construct_filename {
    my ($url);

    (scalar(@_) == 1) or die "construct_filename: url\n";
    $url = $_[0];

    $url =~ s/:/X/g;
    $url =~ s/\//Y/g;
    $url =~ s/\./Z/g;
    $url =~ s/&/W/g;
    $url =~ s/\?/V/g;
    $url =~ s/ /U/g;

    return $url;
}

sub redefine_only {
    my ($file, $line);

    (scalar(@_) == 1) or die "redefine_only: file\n";
    $file = $_[0];

    # There should be either no errors or possibly warnings about
    # redefined subroutines (if cpan was run into a local copy)

    open(INPUT, $file) or die "Can't open: $file\n";

    while($line = <INPUT>){

	chomp($line);

	if(($line !~ /^[\s]*$/) && ($line !~ /Subroutine.*redefined/)){
	    close(INPUT);
	    return 1;
	}
    }
    
    close(INPUT);

    return 0;
}

sub read_urls {
    my ($command, $country, $dir, $file, $filename, $html, $line, $status);

    (scalar(@_) == 1) or die "read_urls: file\n";
    $file = $_[0];

    ($file =~ /rss_([^_]+)\.txt$/) or die
	"Cannot extract country from rss source name: $file\n";
    $country = $1;

    open(INPUT, $file) or die "Can't open $file: $!\n";

    while($line = <INPUT>){

	chomp($line);

	my $rss = new XML::RSS::Parser::Lite;

	$html = get_url($line);

	if((defined($html)) && ($html ne "")){
	    $dir = $DOWNLOAD . $country;
	    $filename = $dir . "/" .  construct_filename($line) . "-" .
		$timestamp . ".rdf";

	    if(length($filename) < $MAX_FILENAME_LENGTH){

		print STDERR "RSS parsing -- $line -- ";

		$command = "$^X rss_parse.pl url \"$line\" >$TEMP 2>&1";
# Unix-only		$line = `$command`;
# Unix-only		$status = $?;

		$status = system($command);

		if(($status == 0) &&
		   ((-z $TEMP) || (redefine_only($TEMP) == 0))){

		    $rss->parse($html);

		    print STDERR "success (" . $rss->count() . " items).\n";
	    
		    if($rss->count() > 0){

			if(!(-e $dir)){
			    mkdir($dir, 0777) or die
				"Can't mkdir $dir: $!\n";

# Unix-only		    $command = "mkdir $dir";
# Unix-only		    (system($command) == 0) or die
# Unix-only			"Couldn't run: $command\n";
			}

			open(OUTPUT, ">" . $filename) or die
			    "Can't open $filename: $!\n";
			print OUTPUT "$html";
			close(OUTPUT);
		    }
		}
		elsif($status != 0){
		    print STDERR "failure to execute rss_parse.\n";
		}
		elsif(!(-z $TEMP)){
		    print STDERR "failure (errors indicated in parsing).\n";
		}
	    }
	}
    }

    close(INPUT);
}

sub process_rsss(){
    my ($file, @files, $line, $path);

# Unix-only    $line = `ls $SOURCE`;
# Unix-only    ($? == 0) or die "Can't ls $SOURCE: $!\n";
# Unix-only    @files = split(/\n/, $line);

    @files = list_directory_contents($SOURCE);

    foreach $file (@files){
	$path = $SOURCE . $file;
	read_urls($path);
    }
}

sub tidy_up(){
    
    if(-e $TEMP){
	unlink $TEMP;
    }
}

process_rsss();
tidy_up();

# Debug option (to evaluate only one file -- need to comment out process_rsss)
# $INPUT = $SOURCE . "rss_Deu.txt";
# read_urls($INPUT);
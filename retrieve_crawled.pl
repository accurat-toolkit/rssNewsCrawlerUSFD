use strict;
use Useful;
use Crawler;

# Copyright: Judita Preiss
# Date of creation: 11 September 2011

# Description
#
# This program runs the crawler over a given list of CRAWL feeds, it
# is effectively just a wrapper script.

# Installation
#
# The hard coded $DATA variable contains the link to the output
# directory. An argument given to the program will override this (this
# must be a full path). The program expects to already have a
# "url_souce" directory (and will create a "url_downloads" directory
# if that one does not exist) in place in that location. The
# url_source directory should contain the various URL seed links, the
# url_downloads will contain the resulting downloaded files.

# Execution
#
# The program is set up to go through all the links in the url_source
# files (the naming format for these is expected to conform), and
# carry out a full crawl as permitted by any robot.txt files. To carry
# out repeated crawls, two options present themselves:
#
# 1) set up the program to repeat (e.g., every 10 mins) via crontab
# 2) a wrapper script to repeat the program's execution (and thus set
#    it to be permanently executed, just return to the start of the RSS
#    links list)

# Dependencies
#
# Module: Crawler.pm
# Module: Useful.pm
# Perl module: LWP::RobotUA
# Perl module: HTML::LinkExtractor
# Perl module: Digest::MD5
# Perl module: File::Copy

my $DATA = $ENV{HOME} . "/projects/accurat/data";

if(scalar(@ARGV) == 1){
    $DATA = $ARGV[0];
}

my $SOURCE = $DATA . "/url_source/";
my $DOWNLOAD = $DATA . "/url_downloads/";

(-e $SOURCE) or die "This program assumes that $SOURCE exists.\n";

if(!(-e $DOWNLOAD)){
    mkdir($DOWNLOAD, 0777) or die "Can't mkdir $DOWNLOAD: $!\n";
# Unix-only    (system("mkdir $DOWNLOAD") == 0) or die "Can't create $DOWNLOAD dir: $!\n";
}

sub read_urls {
    my ($command, $file, $language, $line);

    (scalar(@_) == 1) or die "read_urls: file\n";
    $file = $_[0];

    open(INPUT, $file) or die "Can't open $file: $!\n";

    ($file =~ /^.+_(.+)\.txt$/) or die
	"Can't retrieve language from file: $file\n";
    $language = "\L$1";

    while($line = <INPUT>){

	chomp($line);
	run_single_crawl($DOWNLOAD, $line, $language);

# Unix-only	$command = "crawler.pl $DOWNLOAD \"$line\" $language";
# Unix-only	(system($command) == 0) or die "Can't run $command\n";
    }

    close(INPUT);
}

sub process_urls(){
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

process_urls();

# Debug option (to evaluate only one file -- need to comment out process_urls)
# $INPUT = $SOURCE . "url_UK.txt";
# read_urls($INPUT);

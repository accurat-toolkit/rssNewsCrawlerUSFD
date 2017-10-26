package Crawler;
require Exporter;

# Copyright: Judita Preiss
# Date of creation: 3 September 2011

use LWP::RobotUA;
use HTML::LinkExtractor;
use Digest::MD5;
use File::Copy;
use Useful;

# Unix-only
#
# Should the program be executed on a Unix machine, it may be faster
# to use the Unix only commands rather than their Perl implementation.

our @ISA = qw(Exporter);
our @EXPORT = qw(run_single_crawl);
our $VERSION = 1.0;

# Global variables
#
# Ensure that the filename is unique but does not exceed OS limits

my $MAX_FILENAME_LENGTH = 250;

sub construct_filename {
    my ($timestamp, $url);

    (scalar(@_) == 2) or die "construct_filename: url timestamp\n";
    $url = $_[0];
    $timestamp = $_[1];

    # Remove any control characters from URL

    $url =~ s/[[:cntrl:]]//g;

    # Replace any characters which would cause problems in filenames

    $url =~ s/:/X/g;
    $url =~ s/\//Y/g;
    $url =~ s/\./Z/g;
    $url =~ s/&/W/g;
    $url =~ s/\?/V/g;
    $url =~ s/ /U/g;

    # Add timestamp

    $url .= "-" . $timestamp;

    return $url;
}

sub get_allowed_url {
    my ($filename, $html, $response, $ua, $url);

    (scalar(@_) == 1) or die "get_allowed_url: url\n";
    $url = $_[0];

    $ua = LWP::RobotUA->new('my-robot/0.1', 'me@foo.com');
    $ua->delay(0.5); # One hit every half a minute

    $response = $ua->get($url);

    if((!($response->header(Client_Aborted))) && ($response->is_success)){
        $html = ${$response}{"_content"};
    }
    else{
        warn "WARNING: Couldn't get $url: " . $response->status_line . "\n";
        undef $html;
    }

    return $html;
}

sub suitable_url {
    my ($url);

    (scalar(@_) == 1) or die "suitable_url: url\n";
    $url = $_[0];

    # Only URLS commencing with "http:" are considered suitable

    if($url =~ /^http:/){
	return 0;
    }

    return 1;
}

sub add_new_links {
    my (@array, %done, $html, $link, $links, $new);

    (scalar(@_) == 3) or die "add_new_links: html array done\n";
    $html = $_[0];
    @array = @{$_[1]};
    %done = %{$_[2]};

    $links = new HTML::LinkExtractor();
    $links->parse(\$html);

    foreach $link (@{$links->links}){

	if(defined($$link{href})){
	    $new = $$link{href};

	    if((!(defined($done{$new}))) && (suitable_url($new) == 0)){
		push @array, $new;
	    }
	}
    }

    return @array;
}

sub md5sum {
    my ($file, $md5);

    (scalar(@_) == 1) or die "md5sum: file\n";
    $file = $_[0];

    open(INPUT, $file) or die "Can't open $file: $!\n";
    binmode(INPUT);
    $md5 = Digest::MD5->new->addfile(*INPUT)->hexdigest;
    close(INPUT);

    return $md5;
}

sub save_html {
    my ($data, $existing, $html, $timestamp, $url);
    my ($command, $file, $filename, $path, $sum);

    (scalar(@_) == 5) or die
	"save_html: html url data existing timestamp\n";
    $html = $_[0];
    $url = $_[1];
    $data = $_[2];
    $existing = $_[3];
    $timestamp = $_[4];

    $file = construct_filename($url, $timestamp);
    $filename = $file;
    $path = $data . "/" . $file;

    print STDERR "Saving: $path\n";

    if(length($path) > $MAX_FILENAME_LENGTH){
	print STDERR "Drop (length): $path\n";
	# Early return
	return;
    }

    open(OUTPUT, ">" . $filename) or die "Can't open $filename: $!\n";
    print OUTPUT $html;
    close(OUTPUT);

    (-e $filename) or die "Didn't create $filename\n";

    $sum = md5sum($filename);

# Unix-only    $sum = `md5sum $filename`;
# Unix-only    chomp($sum);

    if(!defined(${$existing}{$sum})){

	move($filename, $path) or die "Couldn't move $filename to $path\n";

# Unix-only	$command = "mv $filename $path";
# Unix-only	(system($command) == 0) or die "Can't run $command\n";

	${$existing}{$sum} = $path;
    }
    else{
	unlink $filename;
    }
}

sub crawl_away {
    my (@array, $data, $existing, $timestamp);
    my (%done, $html, $url);

    (scalar(@_) == 4) or die "crawl_away: array data existing timestamp\n";
    @array = @{$_[0]};
    $data = $_[1];
    $existing = $_[2];
    $timestamp = $_[3];

    %done = ();

    do {

	$url = pop @array;

	print STDERR "Candidate: $url\n";

	if(!(defined($done{$url}))){

	    $done{$url} = 1;

	    $html = get_allowed_url($url);

	    print STDERR "Retrieved: $url\n";

	    if(defined($html)){
		save_html($html, $url, $data, $existing, $timestamp);
		@array = add_new_links($html, \@array, \%done);
	    }
	}
	else{
	    print STDERR "Already done $url\n";
	}

	print STDERR "Remaining " . scalar(@array) . " links.\n";

    } while(scalar(@array) > 0);
}

sub read_existing_pages {
    my ($data, $existing);
    my ($file, @files, $line, $path);

    (scalar(@_) == 2) or die "read_existing_pages: data existing\n";
    $data = $_[0];
    $existing = $_[1];

    @files = list_directory_contents($data);

    foreach $file (@files){

	$path = $data . "/" . $file;
	$line = md5sum($path);

# Unix-only:	$line = `md5sum $path`;
# Unix-only:	($? == 0) or die "Can't work out md5sum $path\n";
# Unix-only:	chomp($line);

	${$existing}{$line} = $path;
    }
}

sub run_single_crawl {
    my ($data, $language, $path, $url);
    my (@time, $timestamp);
    my (%existing, @orls);

    (scalar(@_) == 3) or die "run_single_crawl: path url language\n";
    $path = $_[0];
    $url = $_[1];
    $language = $_[2];

    push @urls, $url;

    $data = $path . $language;
    if(!(-e $data)){
	mkdir($data, 0777) or die "Can't mkdir $data: $!\n";
# Unix-only: (system("mkdir $data") == 0) or die "Can't mkdir $data: $!\n";
    }

# Unix-only: my $timestamp = `date +%Y%m%d%H%M%S`;
# Unix-only: chomp($timestamp);

    @time = localtime(time);
    $timestamp = (1900 + $time[5]) . sprintf("%02d", ($time[4] + 1)) . sprintf("%02d", $time[3]) . sprintf("%02d", $time[2]) . sprintf("%02d", $time[1]) . sprintf("%02d", $time[0]);

    %existing = ();

    print STDERR "Reading existing links (to avoid duplication) ... ";
    read_existing_pages($data, \%existing);
    print STDERR "done.\n";

    print STDERR "Crawling starting from $url ...\n";
    crawl_away(\@urls, $data, \%existing, $timestamp);
    print STDERR "done.\n";
}

1;

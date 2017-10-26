package Useful;
require Exporter;

# Copyright: Judita Preiss
# Date of creation: 3 August 2011

# This module contains functions used frequently throughout the
# Accurat project.

our @ISA = qw(Exporter);
our @EXPORT = qw(get_url remove_multiple_spaces execute_command is_member list_directory_contents);
our $VERSION = 1.0;

sub get_url {
    my ($response, $ua, $url);

    (scalar(@_) == 1) or die "get_url: url\n";
    $url = $_[0];

    $ua = LWP::UserAgent->new(env_proxy => 1,
                              keep_alive => 1,
                              timeout => 100,
                              max_size => 500000,
                              );

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

sub remove_multiple_spaces {
    my ($line);

    (scalar(@_) == 1) or die "remove_multiple_spaces: line\n";
    $line = $_[0];

    while($line =~ /^[\s]+(.+)$/){
	$line = $1;
    }

    while($line =~ /^(.+)[\s]+$/){
	$line = $1;
    }

    while($line =~ /^(.+)[\s]+[\s](.+)$/){
	$line = $1 . " " . $2;
    }

    return $line;
}

sub execute_command {
    my ($command, $debug);

    (scalar(@_) == 2) or die "execute_command: command debug\n";
    $command = $_[0];
    $debug = $_[1];

    if($debug == 0){
	print STDERR "$command\n";
    }
    else{
	(system($command) == 0) or die "Couldn't run: $command\n";
    }
}

sub is_member {
    my ($elt, @array, $member);

    (scalar(@_) == 2) or die "is_member: member array\n";
    $member = $_[0];
    @array = @{$_[1]};

    foreach $elt (@array){

        if($elt eq $member){
            return 0;
        }
    }

    return 1;
}

sub list_directory_contents {
    my ($dir, @files);

    (scalar(@_) == 1) or die "list_directory_contents: dir\n";
    $dir = $_[0];

    if(-f $dir){
	return $dir;
    }

    (-e $dir) or die "The directory $dir does not exist.\n";

    opendir(DIR, $dir) or die "Can't opendir $dir: $!\n";
#    @files = readdir(DIR);
    @files = grep { (!/^\./) } readdir(DIR);
    closedir DIR;

# Unix-only:    $line = `ls $DATA`;
# Unix-only:    ($? == 0) or die "Can't ls $DATA: $!\n";
# Unix-only    @files = split(/\n/, $line);

    return @files;
}

1;

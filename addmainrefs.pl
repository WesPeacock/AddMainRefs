#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark lx] [--eolrep #] [--reptag __hash__] [--debug] [file.sfm]\n";
=pod
This script finds all complex forms in an SFM file and adds main reference markers to their entries.

The ini file should have a section like this:
[AddMainRefs]
semarks=se,sec,sei
mainrefmark=mn

=cut
use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);


use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "AddMainRefs"), # section of ini file to use

	'logfile:s'   => \(my $logfilename = "$scriptname.log"), # log filename
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "lx"), # record marker, default lx
	'eolrep:s' => \(my $eolrep = "#"), # character used to replace EOL
	'reptag:s' => \(my $reptag = "__hash__"), # tag to use in place of the EOL replacement character
	# e.g., an alternative is --eolrep % --reptag __percent__

	# Be aware # is the bash comment character, so quote it if you want to specify it.
	#	Better yet, just don't specify it -- it's the default.
	'debug'       => \my $debug,
	) or die $USAGE;
say STDERR "eolrep:$eolrep" if $debug;
say STDERR "reptag:$reptag" if $debug;

# check your options and assign their information to variables here
$recmark =~ s/[\\ ]//g; # no backslashes or spaces in record marker
say STDERR "recmark:$recmark" if $debug;

# if you have set the $inifilename & $inisection in the options, you only need to set the parameter variables according to the parameter names
# =pod
use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $semarks = $config->{"$inisection"}->{semarks};
say STDERR "semarks after cleanup:$semarks" if $debug;
for ($semarks) {
	# remove backslashes and spaces from the SFMs in the INI file
	say STDERR $_ if $debug;
	$semarks =~ s/\\//g;
	$semarks =~ s/ //g;
	$semarks =~ s/\,*$//; # no trailing commas
	$semarks =~ s/\,/\|/g;  # use bars for or'ing
	}
my $srchsemarks = qr/$semarks/;
say STDERR "semarks RE: $semarks" if $debug;

my $mainrefmark = $config->{"$inisection"}->{mainrefmark};
say STDERR "mainrefmark: $mainrefmark" if $debug;

my $hmmark = $config->{"$inisection"}->{homographmark};
say STDERR "hmmark:$hmmark" if $debug;
# =cut

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;
my $line = ""; # accumulated SFM record
my $crlf;
while (<>) {
	$crlf = $MATCH if  s/\R//g;
	s/$eolrep/$reptag/g;
	$_ .= "$eolrep";
	if (/^\\$recmark /) {
		$line =~ s/$eolrep$/$crlf/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;
print STDERR Dumper @opledfile_in if $debug;

my $sizeopl = scalar @opledfile_in;
say STDERR "size opl:", $sizeopl if $debug;

my %oplineno  ; # build a hash of line numbers of lex/homographs
for (my $oplindex=0; $oplindex < $sizeopl; $oplindex++) {
	my $key = getkey($opledfile_in[$oplindex], $recmark, $hmmark);
	$oplineno{$key}= $oplindex;
	}

for my $oplline (@opledfile_in) {
	my $lexeme = getkey($oplline, $recmark, $hmmark);
	say STDERR "Lexeme:$lexeme in record $oplline" if $debug;
	while  ($oplline =~ m/(\\($srchsemarks) ([^$eolrep]+))/g) {
		my $subentry = $3;
		say STDERR "Found subentry :$subentry" if $debug;
		if (exists $oplineno{$subentry}) {
			say STDERR "Hash lookup :$oplineno{$subentry}" if $debug;
			my $subrec = $opledfile_in[$oplineno{$subentry}];
			say STDERR "Found subentry entry:$subrec" if $debug;
			next if $subrec =~ m/\\$mainrefmark $lexeme$eolrep/;
			$subrec =~ s/^(\\$recmark [^$eolrep]+($eolrep)+(\\$hmmark [^$eolrep]+($eolrep)+)*)/$1\\$mainrefmark $lexeme$eolrep/;
			$opledfile_in[$oplineno{$subentry}] = $subrec;
			}
		}
	}

print STDERR Dumper %oplineno  if $debug;

for my $oplline (@opledfile_in) {
# Insert code here to perform on each opl'ed line.
# Note that a next command will prevent the line from printing

say STDERR "oplline:", Dumper($oplline) if $debug;
#de_opl this line
	for ($oplline) {
		s/$eolrep/\n/g;
		s/$reptag/$eolrep/g;
		print;
		}
	}

sub getkey{
my ($record,  $recmark, $hmmark) = @_;
=pod
say STDERR "oplline:$record" if $debug;
say STDERR "lx:$recmark" if $debug;
say STDERR "hm:$hmmark" if $debug;
=cut
return 0 if $record !~ m/^\\$recmark\ ([^$eolrep]*)/;
my $buildkey = $1;
say STDERR "lexeme:$buildkey" if $debug;
if ($record =~ m/\\$hmmark\ ([^$eolrep]*)/) {
	$buildkey = $buildkey . $1;
	say STDERR "lex+hm:$buildkey" if $debug;
	}
return $buildkey;
}
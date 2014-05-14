#!/usr/bin/perl -w
########################################################################
# File:     duplicate-isbns.pl
# Purpose:  Check for duplicate ISBNs
# Method: 
# Copyright (C) 2014 Geoff Sinclair, Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author: Geoff Sinclair, Andrew Nisbet
# Date:   May 14, 2014
# Rev:    0.1 - developed at Day of Coding COSUGI Conference, Detroit MI.
########################################################################

use strict;
use vars qw/ %opt /;
use Getopt::Std;
use MARC::Batch;
use Business::ISBN;

#######################################################
# Edit to reflect the appropriate values for the load #
#######################################################
my $filename = 'modified-samp.mrc';

############
# End edit #
############

my %isbn_uids;
my %problem_isbn;
my %skip_isbn;
my %titles;
my @fields;
my $isbn;
my $isbn_object;
my $ctr;
my $id_ctr = 0;
my $skip_ctr = 0;
my $uid;
my $isbn_problem_flagged;
my $isbn_problem_ctr = 0;
my $title;
my $matchField = '001';
my $VERSION = 0.1;

# Prints usage message then exits.
# param:
# return:
sub usage
{
    print STDERR << "EOF";

Check for duplicate ISBNs. Outputs to stdout in the following format
 ISBN|cat_key1|cat_key2|...|cat_keyN|
or 
 9780873521352|u17768|u13239|
 9780873521352|u17768-Victorian novels in serial|u13239-Explanation-based neural network learning|

usage: $0 [-tx] [-f MARC match field] [-i input file]

 -a                    : Output all ISBNs (both unique and duplicate).
 -f [MARC match field] : This field uniquely identifies the title (default 001).
 -i [MARC file]        : The MARC file to be processed (required).
 -s [skip file]        : Skip the ISBNs listed in [skip file] (one per line).
 -t                    : Include titles on output.
 -x                    : This (help) message.

example:
 $0 -i"file.mrc"
 $0 -f"900" -i"file.mrc" -s"already_checked.txt" -t -a

 Version: $VERSION
EOF
    exit;
}
# Flush output
$| = 1;

# Kicks off the setting of various switches.
# param:
# return:
sub init
{
    my $opt_string = 'af:i:s:tx';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ($opt{'x'});
	if ($opt{'i'})
	{
		$filename = $opt{'i'};
	}
	else
	{
		print STDERR "**Error: please specify the MARC input file.\n";
		usage();
	}
	if ($opt{'s'})
	{
		my $skipFile = $opt{'s'};
		open(ISBN_IGNORE, "<$skipFile") or die "Couldn't find the skip file '$skipFile'. $!\n";
		while (<ISBN_IGNORE>) {
			my $curLine = $_;
			chomp($curLine);
			$skip_isbn{$curLine} = 1;
		}
		close ISBN_IGNORE;
	}
	if ($opt{'f'})
	{
		$matchField = $opt{'f'};
	}
}


init();
my $outfile = $filename;
$outfile =~ s/\.mrc$//;
my $log = $outfile . "_problems.txt";
open(LOG, "> $log") or die $!;

## create a MARC::Batch object.
my $batch = MARC::Batch->new('USMARC', $filename);

print LOG "Processing records...\n";

while (my $record = $batch->next()) {
	
	$ctr++;
	$title = $record->title();
	if ($matchField eq '001')
	{
		eval{$uid = $record->field('001')->{'_data'}};
		if ($@) 
		{
			die "**Error: record $ctr, doesn't contain field $matchField: '$title'\n";
		}
	}
	else
	{
		eval{$uid = $record->field($matchField)->subfield('a')};
		if ($@) 
		{
			die "**Error: record $ctr, doesn't contain field $matchField: '$title'\n";
		}
	}
	$uid =~ s/\s+$//;
	$titles{$uid} = $title;
	
	## get all the 020 fields (list context).
	@fields = $record->field('020');
	
	if (@fields) {
		## examine each 020 field and print it out.
		foreach my $field (@fields) {
			eval{$isbn = $field->subfield('a')};
			next if ($@ or ($isbn eq "")); # Go get the next one no sub field 'a' or it's empty.
			$isbn =~ s/\s.*$//; # strip anything after the number ends
			if ($skip_isbn{$isbn}) {
				print LOG "Skipping ISBN $isbn\n";
				next;
			}
			insert_pointer($isbn,$uid);
			$isbn_object = Business::ISBN->new($isbn);
			if (defined($isbn_object)) {
				if (! $isbn_object->is_valid) {
					print LOG "Invalid ISBN:\t$isbn\t$title\t$uid\n";
				}
			}
		}
	} else {
		print LOG "No ISBN at record $ctr: " . $record->field('245')->subfield('a') . "\n";
		$id_ctr++;
	}
	$isbn_problem_flagged = 0;
}

foreach $isbn (keys %isbn_uids) {
	my @temp_uids = @{$isbn_uids{$isbn}};
	if ($opt{'a'} or scalar(@temp_uids) > 1) 
	{
		print LOG "Duplicate ISBN:\t$isbn";
		print "$isbn";
		foreach $uid (@temp_uids) {
			if ($opt{'t'})
			{
				print LOG "\t$titles{$uid}\t$uid";
				print "\|$titles{$uid}\|$uid";
			}
			else
			{
				print LOG "\t$uid";
				print "\|$uid";
			}
		} 
		print LOG "\n";
		print "\n";
	}
}

print LOG "Processed $ctr records.\n";
$ctr = 0;

print LOG "Skipped $skip_ctr ISBNs identified in file ".$opt{'s'}."\n" if ($opt{'s'});

sub insert_pointer {
	my ($isbn,$uid) = @_;
	
	$isbn =~ s/-//g;
	$isbn =~ s/x/X/g;
#	print "$isbn\t$uid\n";
	push(@{$isbn_uids{$isbn}}, $uid);
	return 0;
}
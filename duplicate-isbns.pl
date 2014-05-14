# duplicate-isbns.pl
#
# Check for duplicate ISBNs

use MARC::Batch;
use Business::ISBN;
use strict;

#######################################################
# Edit to reflect the appropriate values for the load #
#######################################################
my $filename = 'modified-samp.mrc';
my $isbn_skip_file = 'skip_isbns.txt';

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

# Flush output
$| = 1;

open(ISBN_IGNORE , $isbn_skip_file) or die $!;
while (<ISBN_IGNORE>) {
	my $curLine = $_;
	chomp($curLine);
	$skip_isbn{$curLine} = 1;
}
close ISBN_IGNORE;

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
	
#	my $t001 = $record->field('001');
#	my $uid = $t001->{'_data'};

	$uid = $record->field('900')->subfield('a');
	$uid =~ s/\s+$//;
	
	$titles{$uid} = $title;
	
	## get all the 020 fields (list context).
	@fields = $record->field('020');
	
	if (@fields) {
		## examine each 020 field and print it out.
		foreach my $field (@fields) {
			$isbn = (defined($field->subfield('a'))) ? $field->subfield('a') : $field->subfield('z');
			$isbn =~ s/\s.*$//; # strip anything after the number ends
			if ($skip_isbn{$isbn}) {
				print LOG "Skipping ISBN $isbn\n";
				next;
			}
			insert_pointer($isbn,$uid);
			$isbn_object = Business::ISBN->new($isbn);
			if (defined($isbn_object)) {
				if ($isbn_object->is_valid) {
#						my $isbn10 = $isbn_object->as_isbn10;
#						$problems += insert_pointer($isbn10->as_string, $uid);
#						my $isbn13 = $isbn_object->as_isbn13;
#						$problems += insert_pointer($isbn13->as_string, $uid);
				} else {
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
	if (scalar(@temp_uids) > 1 ) {
		print LOG "Duplicate ISBN:\t$isbn";
		print "$isbn";
		foreach $uid (@temp_uids) {
			print LOG "\t$titles{$uid}\t$uid";
			print "\|$titles{$uid}\|$uid";
		} 
		print LOG "\n";
		print "\n";
	}
}

print LOG "Processed $ctr records.\n";
$ctr = 0;

print LOG "Skipped $skip_ctr ISBNs identified in file $isbn_skip_file.\n";

sub insert_pointer {
	my ($isbn,$uid) = @_;
	
	$isbn =~ s/-//g;
	$isbn =~ s/x/X/g;
#	print "$isbn\t$uid\n";
	push(@{$isbn_uids{$isbn}}, $uid);
	return 0;
}
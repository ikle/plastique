#
# CVS Row
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package CVS::Row;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	row_alloc
	row_load
	row_save
	row_report
	row_update
);

use File::Basename	qw (dirname);
use File::Path		qw (mkpath);

#
# Creates a row with `cols' columns filled with the default value.
#
sub row_alloc ($$) {
	my ($cols, $default) = @_;
	my @row = ($default) x $cols;

	return \@row;
}

#
# Loads a row from the specified CSV file. If the file cannot be opened,
# returns an new row.
#
sub row_load ($$$) {
	my ($cols, $path, $default) = @_;
	my @row;
	my $i = 0;

	open my $csv, '<', "$path.csv" or return row_alloc ($cols, $default);

	for my $line (<$csv>) {
		chomp $line;

		die "E: Too many rows in $path.csv\n" if $i > 1;

		@row = split (',', $line);

		die "E: Too few fields in row $i of $path.csv\n"  if scalar @row < $cols;
		die "E: Too many fields in row $i of $path.csv\n" if scalar @row > $cols;

		++$i;
        }

	die "E: Too few rows in $path.csv\n" if $i < 1;
	return \@row;
}

#
# Saves the row to the specified file.
#
sub row_save ($$) {
	my ($row, $path) = @_;

	mkpath (dirname ($path));

	open my $csv, '>', "$path.csv" or die "E: Cannot write to $path.csv\n";

	print $csv join (',', @{$row}) . "\n";
}

#
# Generates and prints a report of the row its coverage.
#
sub row_report ($$;$$) {
	my ($row, $default, $prefix, $suffix) = @_;
	my $cols = scalar @{$row};
	my $fill = 0;

	print $prefix if defined $prefix;

	print join ("\t", @{$row}) . "\n";

	for (my $i = 0; $i < $cols; ++$i) {
		++$fill if $row->[$i] ne $default;
	}

	print "\ncoverage = $fill / $cols\n";
	print $suffix if defined $suffix;
}

#
# Check if two rows have equal sizes
#
sub row_size_check ($$$) {
	my ($row, $other, $name) = @_;
	my $cols = scalar @{$row};

	die "E: Too few columns in new $name\n"  if scalar @{$other} < $cols;
	die "E: Too many columns in new $name\n" if scalar @{$other} > $cols;
}

#
# Updates row with another one
#
sub row_update ($$$$) {
	my ($row, $other, $default, $name) = @_;

	row_size_check ($row, $other, $name);

	my $cols = scalar @{$row};

	for (my $col = 0; $col < $cols; ++$col) {
		my $old = $row->[$col];
		my $new = $other->[$col];

		next if ($new eq $default or $old eq $new);

		die "E: Mapping conflict for $name at $col\n"
		unless ($old eq $default);

		$row->[$col] = $new;
	}
}

1;

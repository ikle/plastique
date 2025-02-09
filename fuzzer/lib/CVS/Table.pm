#
# CVS Table
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package CVS::Table;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	table_alloc
	table_load
	table_save
	table_report
);

#
# Creates a table of `cols' columns and `rows' rows filled with the
# default value.
#
sub table_alloc ($$$) {
	my ($cols, $rows, $default) = @_;
	my @row = ($default) x $cols;
	my @table;

	for (my $i = 0; $i < $rows; ++$i) {
		@table[$i] = [@row];
	}

	return \@table;
}

#
# Loads a table from the specified CSV file. If the file cannot be opened,
# returns an new table.
#
sub table_load ($$$$) {
	my ($cols, $rows, $path, $default) = @_;
	my @table;
	my $i = 0;

	open my $csv, '<', "$path.csv" or return table_alloc ($cols, $rows, $default);

	for my $line (<$csv>) {
		chomp $line;

		die "E: Too many rows in $path.csv\n" if $i == $rows;

		my @row = split (',', $line);

		die "E: Too few fields in row $i of $path.csv\n"  if scalar @row < $cols;
		die "E: Too many fields in row $i of $path.csv\n" if scalar @row > $cols;

		@table[$i] = [@row];
		++$i;
        }

	return \@table;
}

#
# Saves the table to the specified file.
#
sub table_save ($$) {
	my ($table, $path) = @_;
	my $rows = scalar @{$table};

	open my $csv, '>', "$path.csv" or die "E: Cannot write to $path.csv\n";

	for (my $i = 0; $i < $rows; ++$i) {
		print $csv join (',', @{$table->[$i]}) . "\n";
	}
}

#
# Generates and prints a report of the table its coverage.
#
sub table_report ($$;$$) {
	my ($table, $default, $prefix, $suffix) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};
	my $fill = 0;

	print $prefix if defined $prefix;

	for (my $i = 0; $i < $rows; ++$i) {
		print join ("\t", @{$table->[$i]}) . "\n";
	}

	for (my $i = 0; $i < $rows; ++$i) {
		for (my $j = 0; $j < $cols; ++$j) {
			++$fill if $table->[$i][$j] ne $default;
		}
	}

	print "\ncoverage = $fill / " . ($rows * $cols) . "\n";
	print $suffix if defined $suffix;
}

1;

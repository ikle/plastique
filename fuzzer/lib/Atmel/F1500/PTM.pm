#
# Product Term Position Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::PTM;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	ptm_read_jed
	ptm_alloc
	ptm_load
	ptm_save
	ptm_report
	ptm_update
);

#
# Reads PT position mapping
#
# Returns a mapping from a MC number to a mapping from PT number to the
# address in JEDEC file
#
sub ptm_read_jed ($) {
	my ($name) = @_;
	my %data;

	open my $jed, '<', "$name.jed" or die "E: Cannot open $name.jed\n";

	while (my $line = <$jed>) {
		my $address;

		if ($line =~ /^L(\d+)\r\n$/) {
			$address = int ($1 + 0);

			$line = <$jed>;
			next unless defined $line;
			next unless $line =~ /^[01]{16}\r\n$/;

			$line = <$jed>;
			next unless defined $line;
			next unless $line =~ /^[01]{40}\r\n$/;

			$line = <$jed>;
			next unless defined $line;
			next unless $line =~ /^[01]{40}\*  NOTE PT (\d+) of MC (\d+) \*/;

			$data{$2}{$1} = $address;
		}
	}

	return \%data;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the
# default value (hyphen -- unknown position).
#
sub ptm_alloc ($$) {
	my ($cols, $rows) = @_;
	my @row;
	my @table;

	for (my $i = 0; $i < $cols; ++$i) {
		@row[$i] = '-';
	}

	for (my $i = 0; $i < $rows; ++$i) {
		@table[$i] = [@row];
	}

	return \@table;
}

#
# Loads PT position map from the specified CSV file. If the file cannot be
# opened, returns an empty map.
#
sub ptm_load ($$$) {
	my ($cols, $rows, $name) = @_;
	my @table;
	my $i = 0;

	open my $csv, '<', "$name.csv" or return ptm_alloc ($cols, $rows);

	for my $line (<$csv>) {
		chomp $line;

		die "E: Too many rows in $name.csv\n" if $i == $rows;

		my @row = split (',', $line);

		die "E: Too few fields in row $i of $name.csv\n"  if scalar @row < $cols;
		die "E: Too many fields in row $i of $name.csv\n" if scalar @row > $cols;

		@table[$i] = [@row];
		++$i;
        }

	return \@table;
}

#
# Saves the PT position map to the specified file.
#
sub ptm_save ($$) {
	my ($table, $name) = @_;
	my $rows = scalar @{$table};

	open my $csv, '>', "$name.csv" or die "E: Cannot write to $name.csv\n";

	for (my $i = 0; $i < $rows; ++$i) {
		print $csv join (',', @{$table->[$i]}) . "\n";
	}
}

#
# Generates and prints a report of the known PT position map and its
# coverage.
#
sub ptm_report ($;$$) {
	my ($table, $prefix, $suffix) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};
	my $fill = 0;

	print $prefix if defined $prefix;

	for (my $i = 0; $i < $rows; ++$i) {
		print join ("\t", @{$table->[$i]}) . "\n";
	}

	for (my $i = 0; $i < $rows; ++$i) {
		for (my $j = 0; $j < $cols; ++$j) {
			++$fill if $table->[$i][$j] ne '-';
		}
	}

	print "\ncoverage = $fill / " . ($rows * $cols) . "\n";
	print $suffix if defined $suffix;
}

#
# Updates PT position mapping
#
sub ptm_update ($$) {
	my ($table, $jed) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};

	for my $mc (keys %{$jed}) {
		die "E: To few rows in PT mapping\n" if ($mc - 1) > $rows;

		for my $pt (keys %{$jed->{$mc}}) {
			die "E: To few columns in PT mapping\n" if ($pt - 1) > $cols;

			my $old = $table->[$mc - 1][$pt - 1];
			my $new = $jed->{$mc}{$pt};

			next if ($new eq '-' or $old eq $new);

			die "E: Mapping conflict for PT $pt of MC $mc\n"
			unless ($old eq '-');

			$table->[$mc - 1][$pt - 1] = $new;
		}
	}
}

1;

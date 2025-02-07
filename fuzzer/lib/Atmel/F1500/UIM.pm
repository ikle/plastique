#
# Module to work with Atmel ATF1500 family UIMs
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::UIM;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	uim_read_jed
	uim_alloc
	uim_load
	uim_save
	uim_report
	uim_update
);

#
# Returns map from jed config for single mux to column number
#
# We assume that the value in JED consists of `cols' bits, the active
# column is marked with zero, all others with one.
#
# Note, this is a private function used by uim_read_jed.
#
sub uim_make_umap ($) {
	my ($cols) = @_;
	my %umap;

	for (my $i = 0; $i < $cols; ++$i) {
		my $key = '';

		for (my $j = 0; $j < $cols; ++$j) {
			$key .= $j == $i ? '0' : '1';
		}

		$umap{$key} = $i;	# print "$key => $i\n";
	}

	return %umap;
}

#
# Reads UIMs configuration
#
# Returns a mapping from a LAB name to a mapping from the UIM output index
# to the active UIM column number for the given output.
#
sub uim_read_jed ($$$) {
	my ($cols, $rows, $name) = @_;
	my %umap = uim_make_umap ($cols);
	my %data;

	open my $jed, '<', "$name.jed" or die "E: Cannot open $name.jed\n";

	for my $line (<$jed>) {
		if ($line =~ /L\d+\s([01]{5})\s*\*\s*NOTE Mux-(\d+) of block ([A-Z])/) {
			my ($map, $mux, $lab) = ($1, $2, $3);

			die "E: Mux $mux not in table\n" if $mux >= $rows;

			$data{$lab}{$mux} = $umap{$map} if defined $umap{$map};
		}
	}

	return \%data;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the default
# value (hyphen -- unknown connection).
#
sub uim_alloc ($$) {
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
# Loads UIM table from the specified CSV file. If the file cannot be
# opened, returns an empty table.
#
sub uim_load ($$$) {
	my ($cols, $rows, $name) = @_;
	my @table;
	my $i = 0;

	open my $csv, '<', "$name.csv" or return uim_alloc ($cols, $rows);

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
# Saves the UIM table to the specified file.
#
sub uim_save ($$) {
	my ($table, $name) = @_;
	my $rows = scalar @{$table};

	open my $csv, '>', "$name.csv" or die "E: Cannot write to $name.csv\n";

	for (my $i = 0; $i < $rows; ++$i) {
		print $csv join (',', @{$table->[$i]}) . "\n";
	}
}

#
# Generates and prints a report of the known UIM configuration and its
# coverage.
#
sub uim_report ($) {
	my ($table) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};
	my $fill = 0;

	for (my $i = 0; $i < $rows; ++$i) {
		print join ("\t", @{$table->[$i]}) . "\n";
	}

	for (my $i = 0; $i < $rows; ++$i) {
		for (my $j = 0; $j < $cols; ++$j) {
			++$fill if $table->[$i][$j] ne '-';
		}
	}

	print "\ncoverage = $fill / " . ($rows * $cols) . "\n";
}

#
# Parses fitter report and updates UIM table
#
sub uim_update ($$$) {
	my ($table, $name, $jed) = @_;
	my $lab;

	open my $fit, '<', "$name.fit" or die "E: Cannot open $name.fit\n";

	for my $line (<$fit>) {
		if ($line =~ /: MUX (\d+)\s+Ref\s+\(([^)]+)/) {
			my ($mux, $name, $i) = ($1, $2, undef);

			$name = "F$1" if $name =~ /^[A-Z](\d+)fb$/;
			$name = "P$1" if $name =~ /^[A-Z](\d+)p$/;

			die "E: Mux $mux without LAB\n" unless defined $lab;

			$i = $jed->{$lab}{$mux};

			die "E: Mux $mux without column\n" unless defined $i;

			my $old = $table->[$mux][$i];

			die "E: Mapping conflict for mux $mux at $i column\n"
			unless ($old eq '-' or $old eq $name);

			$table->[$mux][$i] = $name;
		}
		elsif ($line =~ /^Multiplexer assignment for block ([A-Z])/) {
			$lab = $1;
		}
	}
}

1;

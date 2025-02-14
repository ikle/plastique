#
# Macro Cell Position Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::MCM;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	mcm_read_jed
	mcm_alloc
	mcm_load
	mcm_save
	mcm_report
	mcm_update
);

use CVS::Table;

#
# Reads MC position mapping
#
# Returns a mapping from a LAB name to a mapping from switch pair name to
# the address in JEDEC file
#
sub mcm_read_jed ($) {
	my ($path) = @_;
	my %data;

	open my $jed, '<', "$path.jed" or die "E: Cannot open $path.jed\n";

	for my $line (<$jed>) {
		if ($line =~ /^L(\d+) [01]+\*\s*NOTE S(\d+)\s*,\s*S(\d+)\s+of block ([A-Z])/) {
			$data{$4}{"S$2,S$3"} = $1;
		}
	}

	return \%data;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the
# default value (hyphen -- unknown position).
#
sub mcm_alloc ($$) {
	my ($cols, $rows) = @_;

	return table_alloc ($cols, $rows, '-');
}

#
# Loads MC position map from the specified CSV file. If the file cannot be
# opened, returns an empty map.
#
sub mcm_load ($$$) {
	my ($cols, $rows, $path) = @_;

	return table_load ($cols, $rows, $path, '-');
}

#
# Saves the MC position map to the specified file.
#
sub mcm_save ($$) {
	my ($table, $path) = @_;

	return table_save ($table, $path);
}

#
# Generates and prints a report of the known MC position map and its
# coverage.
#
sub mcm_report ($;$$) {
	my ($table, $prefix, $suffix) = @_;

	return table_report ($table, '-', $prefix, $suffix);
}

#
# Updates MC position mapping
#
sub mcm_update ($$) {
	my ($table, $jed) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};

	my %map = (
		'S16,S12' => 0,
		'S14,S11' => 1,
		'S9,S6'   => 2,
		'S13,S10' => 3,
		'S20,S18' => 4,
		'S8,S21'  => 5,
		'S7,S19'  => 6,
		'S22,S5'  => 7,
		'S23,S4'  => 8,
		'S3,S15'  => 9,
		'S0,S1'   => 10,
		'S17,S2'  => 11,
	);

	for my $lab (keys %{$jed}) {
		my $i = ord ($lab) - ord ('A');

		die "E: To few rows in MC position mapping\n" if $i >= $rows;

		for my $spair (keys %{$jed->{$lab}}) {
			my $sp = $map{$spair};

			die "E: Unknown switch pair $spair\n" unless defined $sp;
			die "E: To few columns in MC position mapping\n" if $sp >= $cols;

			my $old = $table->[$i][$sp];
			my $new = $jed->{$lab}{$spair};

			next if ($new eq '-' or $old eq $new);

			die "E: MC mapping conflict for LAB $lab, pair $spair\n"
			unless ($old eq '-');

			$table->[$i][$sp] = $new;
		}
	}
}

1;

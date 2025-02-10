#
# Macro Cell Configuration Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::MCC;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	mcc_read_jed
	mcc_read_conf
	mcc_alloc
	mcc_load
	mcc_save
	mcc_report
	mcc_update
);

use CVS::Table;

#
# Reads MC configuration mapping
#
# Returns a mapping from a LAB name to a mapping from switch pair nunber
# to the configuration bit-string in JEDEC file
#
sub mcc_read_jed ($) {
	my ($name) = @_;
	my %data;

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

	open my $jed, '<', "$name.jed" or die "E: Cannot open $name.jed\n";

	for my $line (<$jed>) {
		if ($line =~ /^L\d+ ([01]+)\*\s*NOTE S(\d+)\s*,\s*S(\d+)\s+of block ([A-Z])/) {
			my $spair = "S$2,S$3";
			my $sp    = $map{$spair};

			die "E: Unknown switch pair $spair\n" unless defined $sp;

			$data{$4}{$sp} = $1;
		}
	}

	return \%data;
}

#
# Reads a single LAB configuration table
#
sub mcc_read_conf ($$$$) {
	my ($cols, $rows, $path, $lab) = @_;

	my $conf = table_alloc ($cols, $rows, 0);  # todo: get default from jed
	my $jed  = mcc_read_jed ($path);

	return undef unless defined $jed->{$lab};

	for (my $col = 0; $col < $cols; ++$col) {
		next unless defined $jed->{$lab}{$col};

		my @vec = split (//, $jed->{$lab}{$col});

		die "E: Wrong size of LAB $lab MC Config $col\n"
		unless scalar @vec == $rows;

		for (my $row = 0; $row < $rows; ++$row) {
			$conf->[$row][$col] = 1 if $vec[$row] != 0;
		}
	}

	return $conf;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the
# default value (hyphen -- unknown position).
#
sub mcc_alloc ($$) {
	my ($cols, $rows) = @_;

	return table_alloc ($cols, $rows, '-');
}

#
# Loads MC configuration map from the specified CSV file. If the file
# cannot be opened, returns an empty map.
#
sub mcc_load ($$$) {
	my ($cols, $rows, $path) = @_;

	return table_load ($cols, $rows, $path, '-');
}

#
# Saves the MC configuration map to the specified file.
#
sub mcc_save ($$) {
	my ($table, $path) = @_;

	return table_save ($table, $path);
}

#
# Generates and prints a report of the known MC configuration map and its
# coverage.
#
sub mcc_report ($;$$) {
	my ($table, $prefix, $suffix) = @_;

	return table_report ($table, '-', $prefix, $suffix);
}

#
# Updates MC configuration mapping
#
sub mcc_update ($$) {
	my ($table, $other) = @_;

	return table_update ($table, $other, '-', 'MC Config');
}

1;

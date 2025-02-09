#
# UIM Position Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::PIM;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	pim_read_jed
	pim_alloc
	pim_load
	pim_save
	pim_report
	pim_update
);

use CVS::Table;

#
# Reads UIM position mapping
#
# Returns a mapping from a LAB name to a mapping from mux number to the
# address in JEDEC file
#
sub pim_read_jed ($) {
	my ($name) = @_;
	my %data;

	open my $jed, '<', "$name.jed" or die "E: Cannot open $name.jed\n";

	while (my $line = <$jed>) {
		my $address;

		if ($line =~ /L(\d+)\s+([01]+)\s*\*\s*NOTE Mux-(\d+) of block ([A-Z])/) {
			my ($address, $map, $mux, $lab) = ($1, $2, $3, $4);

			$data{$lab}{$mux} = $address;
		}
	}

	return \%data;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the
# default value (hyphen -- unknown position).
#
sub pim_alloc ($$) {
	my ($cols, $rows) = @_;

	return table_alloc ($cols, $rows, '-');
}

#
# Loads UIMposition map from the specified CSV file. If the file cannot be
# opened, returns an empty map.
#
sub pim_load ($$$) {
	my ($cols, $rows, $path) = @_;

	return table_load ($cols, $rows, $path, '-');
}

#
# Saves the UIM position map to the specified file.
#
sub pim_save ($$) {
	my ($table, $path) = @_;

	return table_save ($table, $path);
}

#
# Generates and prints a report of the known UIM position map and its
# coverage.
#
sub pim_report ($;$$) {
	my ($table, $prefix, $suffix) = @_;

	return table_report ($table, '-', $prefix, $suffix);
}

#
# Updates UIM position mapping
#
sub pim_update ($$) {
	my ($table, $jed) = @_;
	my $rows = scalar @{$table};
	my $cols = scalar @{$table->[0]};

	for my $lab (keys %{$jed}) {
		my $i = ord ($lab) - ord ('A');

		die "E: Unknown LAB $lab\n" if $i < 0 or $i >= $cols;

		for my $mux (keys %{$jed->{$lab}}) {
			die "E: To few rows in UIM mapping\n" if $mux >= $rows;

			my $old = $table->[$mux][$i];
			my $new = $jed->{$lab}{$mux};

			next if ($new eq '-' or $old eq $new);

			die "E: Mapping conflict for Mux $mux of LAB $lab\n"
			unless ($old eq '-');

			$table->[$mux][$i] = $new;
		}
	}
}

1;

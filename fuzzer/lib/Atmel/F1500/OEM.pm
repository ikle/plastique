#
# Global Output Enable Position Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::OEM;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	oem_read_jed
	oem_alloc
	oem_load
	oem_save
	oem_report
	oem_update
);

use CVS::Row;

#
# Reads GOE position mapping
#
# Returns a mapping from a GOE index to the address in JEDEC file
#
sub oem_read_jed ($) {
	my ($path) = @_;
	my ($cols, $addr);
	my %data;

	open my $jed, '<', "$path.jed" or die "E: Cannot open $path.jed\n";

	while (my $line = <$jed>) {
		if ($line =~ /^NOTE\s+(\d+)\s+global OE/) {
			$cols = int ($1);
		}

		next unless defined $cols;

		if ($line =~ /^L(\d+)/) {
			$addr = int ($1 + 0);
		}

		next unless defined $addr;

		if ($line =~ /^([01]+)/) {
			$data{$cols - 1} = $addr;
			$addr += length ($1);
			$cols -= 1;

			last if $cols <= 0;
		}
	}

	return \%data;
}

#
# Creates a row with `cols' columns filled with the default value
# (hyphen -- unknown position).
#
sub oem_alloc ($) {
	my ($cols) = @_;

	return row_alloc ($cols, '-');
}

#
# Loads GOE position map from the specified CSV file. If the file cannot be
# opened, returns an empty map.
#
sub oem_load ($$) {
	my ($cols, $path) = @_;

	return row_load ($cols, $path, '-');
}

#
# Saves the GOE position map to the specified file.
#
sub oem_save ($$) {
	my ($row, $path) = @_;

	return row_save ($row, $path);
}

#
# Generates and prints a report of the known GOE position map and its
# coverage.
#
sub oem_report ($;$$) {
	my ($row, $prefix, $suffix) = @_;

	return row_report ($row, '-', $prefix, $suffix);
}

#
# Updates MC position mapping
#
sub oem_update ($$) {
	my ($row, $jed) = @_;
	my $cols = scalar @{$row};

	for my $i (keys %{$jed}) {
		die "E: To few columns in GOE position mapping\n" if $i >= $cols;

		my $old = $row->[$i];
		my $new = $jed->{$i};

		next if ($new eq '-' or $old eq $new);

		die "E: GOE position mapping conflict for GOE$i\n"
		unless ($old eq '-');

		$row->[$i] = $new;
	}
}

1;

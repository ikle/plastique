#
# Global Output Enable Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::OEC;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	oec_read_jed
	oec_alloc
	oec_load
	oec_save
	oec_report
	oec_update
);

use CVS::Table;

#
# Returns map from jed config for single mux to column number
#
# We assume that the value in JED consists of `cols' bits, the active
# column is marked with zero, all others with one.
#
# Note, this is a private function used by oec_read_jed.
#
sub oec_make_umap ($) {
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
# Reads GOE configuration
#
# Returns a mapping the GOE index to the active GOE column number for
# the given output.
#
sub oec_read_jed ($$$) {
	my ($cols, $rows, $path) = @_;
	my %umap = oec_make_umap ($cols);
	my ($i, $addr);
	my %data;

	open my $jed, '<', "$path.jed" or die "E: Cannot open $path.jed\n";

	while (my $line = <$jed>) {
		if ($line =~ /^NOTE\s+(\d+)\s+global OE/) {
			$i = int ($1);
			die "E: To few GOEs ($i)\n"  if $i < $rows;
			die "E: To many GOEs ($i)\n" if $i > $rows;
		}

		next unless defined $i;

		if ($line =~ /^L(\d+)/) {
			$addr = int ($1 + 0);
		}

		next unless defined $addr;

		if ($line =~ /^([01]+)/) {
			$data{$i - 1} = $umap{$1} if defined $umap{$1};
			$i -= 1;

			last if $i <= 0;
		}
	}

	return \%data;
}

#
# Creates a table of `cols' columns and `rows' rows filled with the default
# value (hyphen -- unknown connection).
#
sub oec_alloc ($$) {
	my ($cols, $rows) = @_;

	return table_alloc ($cols, $rows, '-');
}

#
# Loads GOE table from the specified CSV file. If the file cannot be
# opened, returns an empty table.
#
sub oec_load ($$$) {
	my ($cols, $rows, $path) = @_;

	return table_load ($cols, $rows, $path, '-');
}

#
# Saves the GOE table to the specified file.
#
sub oec_save ($$) {
	my ($table, $path) = @_;

	return table_save ($table, $path);
}

#
# Generates and prints a report of the known GOE configuration and its
# coverage.
#
sub oec_report ($;$$) {
	my ($table, $prefix, $suffix) = @_;

	return table_report ($table, '-', $prefix, $suffix);
}

#
# Parses fitter report and updates GOE table
#
sub oec_update ($$$) {
	my ($table, $path, $jed) = @_;
	my %fb;
	my %pin;

	open my $fit, '<', "$path.fit" or die "E: Cannot open $path.fit\n";

	for my $line (<$fit>) {
		if ($line =~ /^Com_Ctrl_(\d+) assigned to node (\d+)/) {
			$fb{$1} = 'F' . int ($2 - 600) if $2 > 600;
		}

		if ($line =~ /^P(\d+).OE = Com_Ctrl_(\d+).Q;/) {
			$pin{$1} = $fb{$2} if defined $fb{$2};
		}
		elsif ($line =~ /^P(\d+).OE = (\w+\d*);/) {
			$pin{$1} = $2;
		}

		if ($line =~ /^MC(\d+)\s+\d+\s+OE(\d+)\s+/) {
			my ($out, $goe) = ($1, $2);

			die "E: Undefined GOE $goe source\n" unless defined $pin{$out};

			my $i = $jed->{$goe};

			die "E: GOE $goe without column\n" unless defined $i;

			my $old = $table->[$goe][$i];
			my $new = $pin{$out};

			die "E: Mapping conflict for GOE $goe at $i column\n"
			unless ($old eq '-' or $old eq $new);

			$table->[$goe][$i] = $new;
		}
	}
}

1;

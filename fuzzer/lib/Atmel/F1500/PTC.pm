#
# Product Term Configuration Mapping for Atmel ATF1500 family
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::PTC;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	ptc_read_jed
	ptc_alloc
	ptc_load
	ptc_save
	ptc_report
	ptc_update
);

#
# Reads PTs configuration
#
# Returns a mapping from a MC number to a mapping from PT number to the
# string of configuration bits
#
sub ptc_read_jed ($) {
	my ($name) = @_;
	my %data;

	open my $jed, '<', "$name.jed" or die "E: Cannot open $name.jed\n";

	while (my $line = <$jed>) {
		my $vec;

		if ($line =~ /^([01]{16})\r\n$/) {
			$vec = $1;

			$line = <$jed>;
			next unless defined $line;
			next unless $line =~ /^([01]{40})\r\n$/;

			$vec .= $1;

			$line = <$jed>;
			next unless defined $line;
			next unless $line =~ /^([01]{40})\*  NOTE PT (\d+) of MC (\d+) \*/;

			$data{$3}{$2} = $vec . $1;
		}
	}

	return \%data;
}

#
# Creates a raw of `cols' columns filled with the default value (hyphen --
# unknown connection).
#
sub ptc_alloc ($) {
	my ($cols) = @_;
	my @row = ('-') x $cols;

	return \@row;
}

#
# Loads PT map from the specified CSV file. If the file cannot be opened,
# returns an empty map.
#
sub ptc_load ($$) {
	my ($cols, $name) = @_;
	my @raw;

	open my $csv, '<', "$name.csv" or return ptc_alloc ($cols);

	my $line = <$csv>;

	chomp $line;

	my @row = split (',', $line);

	die "E: Too few fields in row of $name.csv\n"  if scalar @row < $cols;
	die "E: Too many fields in row of $name.csv\n" if scalar @row > $cols;

	return \@row;
}

#
# Saves the PT map to the specified file.
#
sub ptc_save ($$) {
	my ($row, $name) = @_;

	open my $csv, '>', "$name.csv" or die "E: Cannot write to $name.csv\n";

	print $csv join (',', @{$row}) . "\n";
}

#
# Generates and prints a report of the known PT configuration and its
# coverage.
#
sub ptc_report ($;$$) {
	my ($row, $prefix, $suffix) = @_;
	my $cols = scalar @{$row};
	my $fill = 0;

	print $prefix if defined $prefix;

	for (my $i = 0; $i < $cols; ++$i) {
		++$fill if $row->[$i] ne '-';

		print "$row->[$i]" . (($i & 7) == 7 ? "\n" : "\t");
	}

	print "\ncoverage = $fill / $cols\n";
	print $suffix if defined $suffix;
}

#
# Updates PT map
#
sub ptc_update ($$) {
	my ($row, $other) = @_;
	my $cols = scalar @{$row};

	die "E: Too few fields in new PT mapping\n"  if scalar @{$other} < $cols;
	die "E: Too many fields in new PT mapping\n" if scalar @{$other} > $cols;

	for (my $i = 0; $i < $cols; ++$i) {
		my ($old, $new) = ($row->[$i], $other->[$i]);

		next if ($new eq '-' or $old eq $new);

		die "E: Mapping conflict for PT at $i column\n"
		unless ($old eq '-');

		$row->[$i] = $new;
	}
}

1;

#
# MAP Fuzzer
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package MAP::Fuzzer;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	make_bit_map
);

use CVS::Table;

#
# Run samples and generate positive or negative map
#
sub make_bit_samples ($$) {
	my ($o, $invert) = @_;
	my $order = $o->{order};
	my $cb    = $o->{cb};
	my $cols  = $o->{cols};
	my $rows  = $o->{rows};
	my $conf  = table_alloc ($cols, $rows, 0);

	for (my $i = 0; $i < $order; ++$i) {
		my $st = $cb->($o, $i, $invert);

		return undef unless defined $st;

		for (my $col = 0; $col < $cols; ++$col) {
			for (my $row = 0; $row < $rows; ++$row) {
				$conf->[$row][$col] += $st->[$row][$col] << $i;
			}
		}
	}

	return $conf;
}

#
# Calculate mapping for `count' bits from input table (cols, rows) to
# output table of same size
#
# my %conf = (
#	'cb'	=> \&get_sample,	# sample table generator	(req)
#	'name'	=> 'FAST',		# prefix name of source bits	(req)
#	'cols'	=> 12,			# output table column count	(req)
#	'rows'	=> 32,			# output table row count	(req)
#	'count'	=> 16,			# number of source bits		(req)
#	'order'	=> 5,			# ceil (log2 (count - 1)) + 1	(req)
#	...				# call back options
# );
#
sub make_bit_map ($) {
	my ($o) = @_;
	my $pos = make_bit_samples ($o, 0);
	my $neg = make_bit_samples ($o, 1);

	return undef unless defined $pos and defined $neg;

	my $cols  = $o->{cols};
	my $rows  = $o->{rows};
	my $map   = table_alloc ($cols, $rows, '-');
	my $count = $o->{count};
	my $mask  = ~(~0 << $o->{order});
	my $name  = $o->{name};

	for (my $row = 0; $row < $rows; ++$row) {
		for (my $col = 0; $col < $cols; ++$col) {
			my $P = $pos->[$row][$col];
			my $N = $neg->[$row][$col];

			next unless ($P & $mask) == (~$N & $mask);

			$map->[$row][$col] = ($N < $count) ? "!${name}$N" : "${name}$P";
		}
	}

	return $map;
}

1;

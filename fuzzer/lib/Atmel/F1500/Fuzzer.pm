#
# ATF1500 Family Fuzzer Helpers
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::Fuzzer;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	make_bit_map
	pin_opt_sample
);

use File::Basename	qw (dirname);
use File::Copy		qw (copy);
use File::Path		qw (mkpath);

use Atmel::F1500::MCC;
use Atmel::F1500::Tools;
use MAP::Fuzzer;

#
# Generate and compile pin option test
#
sub make_opt_sample ($$$$) {
	my ($o, $path, $index, $invert) = @_;

	mkpath (dirname ($path));
	copy ($o->{head}, "$path.pld") or die "E: Cannot copy base\n";

	open my $test, '>>', "$path.pld" or die "E: Cannot open test file\n";

	my $count = $o->{count};
	my $lab   = $o->{lab};
	my $dev   = $o->{dev};
	my $opt   = $o->{opt};

	my $base  = (ord ($lab) - ord ('A')) * $count + 1;
	my $mask  = (1 << $index);
	my @a;

	for (my $i = 0; $i < $count; ++$i) {
		my $n = $base + $i;

		push (@a, "P$n") if (($i & $mask) != 0 xor $invert);
	}

	return compile ($path, $dev, '-strategy', $opt, '=', 'off') if scalar @a == 0;
	return compile ($path, $dev, '-strategy', $opt, '=', @a);
}

#
# Generate pin option sample
#
# my %conf = (
#	'path'	=> 'work/test',		# test files prefix
#	'head'	=> "$0-base.pld",	# PLD file base part
#	'dev'	=> 'P1502C44',		# target device for fitter
#	'opt'	=> 'output_fast',	# fitter option
#	'lab'	=> 'A',			# LAB name to test
#);
#
sub pin_opt_sample ($$$) {
	my ($o, $index, $invert) = @_;
	my $path = $o->{path};
	my $cols = $o->{cols};
	my $rows = $o->{rows};
	my $lab  = $o->{lab};

	return undef unless make_opt_sample ($o, $path, $index, $invert);
	return mcc_read_conf ($cols, $rows, $path, $lab);
}

1;

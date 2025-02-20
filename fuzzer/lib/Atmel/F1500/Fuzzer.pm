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
	make_base
	make_bit_map
	pin_opt_sample
	make_test_sample
);

use File::Basename	qw (dirname);
use File::Copy		qw (copy);
use File::Path		qw (mkpath);

use Atmel::F1500::MCC;
use Atmel::F1500::Tools;
use MAP::Fuzzer;

#
# Make PLD base, return opened file
#
sub make_base ($$) {
	my ($path, $head) = @_;

	mkpath (dirname ($path));
	copy ($head, "$path.pld") or die "E: Cannot copy $head to $path.pld\n";

	open my $test, '>>', "$path.pld" or die "E: Cannot open $path.pld file\n";

	return $test;
}

#
# Generate and compile pin option test
#
sub make_opt_sample ($$$$) {
	my ($o, $path, $pos, $neg) = @_;
	my $start = defined $o->{start} ? $o->{start} : 0;
	my $count = $o->{count};
	my $lab   = $o->{lab};
	my $dev   = $o->{dev};
	my $opt   = $o->{opt};

	my $test  = make_base ($path, $o->{head});
	my $base  = (ord ($lab) - ord ('A')) * $count + 1;

	my @a = map { 'P' . ($base + $_) } grep { $_ >= $start } @{$pos};

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
	my ($o, $pos, $neg) = @_;
	my $path = $o->{path};
	my $cols = $o->{cols};
	my $rows = $o->{rows};
	my $lab  = $o->{lab};

	return undef unless make_opt_sample ($o, $path, $pos, $neg);
	return mcc_read_conf ($cols, $rows, $path, $lab);
}

#
# Generate and compile test sample
#
sub make_test_sample ($$$) {
	my ($o, $pos, $neg) = @_;
	my $path = $o->{path};
	my $dev  = $o->{dev};
	my $cols = $o->{cols};
	my $rows = $o->{rows};
	my $lab  = $o->{lab};

	my $test = make_base ($path, $o->{head});

	if (defined $o->{pins}) {
		print $test "\n/* pin mapping */\n\n";

		print $test "$_\n" for @{$o->{pins}};
	}

	if (defined $o->{base}) {
		print $test "\n/* base expressions */\n\n";

		print $test "$_\n" for @{$o->{base}};
	}

	if (defined $o->{on}) {
		print $test "\n/* on expressions */\n\n";

		for my $i (@{$pos}) {
			my ($n, $m) = (1 + $i, 17 + $i);

			for my $line (@{$o->{on}}) {
				my $s = $line;

				$s =~ s/\{n\}/$n/g;
				$s =~ s/\{m\}/$m/g;

				print $test "$s\n";
			}
		}
	}

	if (defined $o->{off}) {
		print $test "\n/* off expressions */\n\n";

		for my $i (@{$neg}) {
			my ($n, $m) = (1 + $i, 17 + $i);

			for my $line (@{$o->{off}}) {
				my $s = $line;

				$s =~ s/\{n\}/$n/g;
				$s =~ s/\{m\}/$m/g;

				print $test "$s\n";
			}
		}
	}

	return undef unless compile ($path, $dev, '-strategy', 'Optimize', 'off');
	return mcc_read_conf ($cols, $rows, $path, $lab);
}

1;

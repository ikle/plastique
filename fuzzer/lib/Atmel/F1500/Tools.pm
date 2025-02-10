#
# Atmel ATF1500 family Tools
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1500::Tools;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

our @EXPORT = qw (
	compile
	cupl
	fit
);

sub cupl ($) {
	my ($path) = @_;

	unlink ("$path.tt2");
	system ('cupl', '-jx', '-m0', "$path.pld");

	return -e "$path.tt2";
}

sub fit ($$;@) {
	my ($path, $device, @opts) = @_;
	my $fitter;

	$fitter = 'fit1502' if $device =~ /^P1502/;
	$fitter = 'fit1504' if $device =~ /^P1504/;
	$fitter = 'fit1508' if $device =~ /^P1508/;

	die "E: Unknown device type $device\n" unless defined $fitter;

	unlink ("$path.jed");
	system ($fitter, "$path.tt2", '-cupl', '-device', $device, @opts);

	return -e "$path.jed";
}

sub compile ($$;@) {
	my ($path, $device, @opts) = @_;

	return 0 if -e "$path.pld" and not cupl ($path);

	return fit ($path, $device, @opts);
}

1;

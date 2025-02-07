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

sub cupl ($$) {
	my ($root, $name) = @_;

	my $cmd = "cupl -jx -m0 $name.pld";

	unlink ("$root/$name.tt2");
	system ("(cd $root && $cmd)");

	return -e "$root/$name.tt2";
}

sub fit ($$$) {
	my ($root, $name, $device) = @_;
	my $fitter;

	$fitter = 'fit1502' if $device =~ /^P1502/;
	$fitter = 'fit1504' if $device =~ /^P1504/;
	$fitter = 'fit1508' if $device =~ /^P1508/;

	die "E: Unknown device type $device\n" unless defined $fitter;

	my $cmd = "$fitter $name.tt2 -cupl -device $device";

	unlink ("$root/$name.jed");
	system ("(cd $root && $cmd)");

	return -e "$root/$name.jed";
}

sub compile ($$$) {
	my ($root, $name, $device) = @_;

	return 0 if -e "$root/$name.pld" and not cupl ($root, $name);

	return fit ($root, $name, $device);
}

1;

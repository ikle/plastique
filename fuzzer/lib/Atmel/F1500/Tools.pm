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

use File::Basename	qw (basename dirname);

sub cupl ($) {
	my ($path) = @_;
	my ($root, $name) = (dirname ($path), basename ($path));

	my $cmd = "cupl -jx -m0 $name.pld";

	unlink ("$path.tt2");
	system ("(cd $root && $cmd)");

	return -e "$path.tt2";
}

sub fit ($$) {
	my ($path, $device) = @_;
	my ($root, $name) = (dirname ($path), basename ($path));

	my $fitter;

	$fitter = 'fit1502' if $device =~ /^P1502/;
	$fitter = 'fit1504' if $device =~ /^P1504/;
	$fitter = 'fit1508' if $device =~ /^P1508/;

	die "E: Unknown device type $device\n" unless defined $fitter;

	my $cmd = "$fitter $name.tt2 -cupl -device $device";

	unlink ("$path.jed");
	system ("(cd $root && $cmd)");

	return -e "$path.jed";
}

sub compile ($$) {
	my ($path, $device) = @_;

	return 0 if -e "$path.pld" and not cupl ($path);

	return fit ($path, $device);
}

1;

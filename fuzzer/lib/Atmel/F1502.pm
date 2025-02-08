#
# Atmel ATF1502 helpers
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

package Atmel::F1502;

use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);

use Atmel::F1500::PTC;
use Atmel::F1500::PTM;
use Atmel::F1500::Tools;
use Atmel::F1500::UIM;

our @EXPORT = qw (
	ptc_read_jed

	compile

	f1502_alloc
	f1502_load
	f1502_save
	f1502_report
	f1502_update
);

sub f1502_alloc () {
	my %o;

	$o{'ptc'} = ptc_alloc (96);
	$o{'ptm'} = ptm_alloc (5, 32);
	$o{'uim'} = uim_alloc (5, 40);

	return \%o;
}

sub f1502_load ($) {
	my ($db) = @_;
	my %o;

	$o{'ptc'} = ptc_load (96,    "$db/atmel/f1502/ptc");
	$o{'ptm'} = ptm_load (5, 32, "$db/atmel/f1502/ptm");
	$o{'uim'} = uim_load (5, 40, "$db/atmel/f1502/uim");

	return \%o;
}

sub f1502_save ($$) {
	my ($o, $db) = @_;

	ptc_save ($o->{'ptc'}, "$db/atmel/f1502/ptc");
	ptm_save ($o->{'ptm'}, "$db/atmel/f1502/ptm");
	uim_save ($o->{'uim'}, "$db/atmel/f1502/uim");
}

sub f1502_report ($) {
	my ($o) = @_;

	ptc_report ($o->{'ptc'}, "# PT Configuration\n\n", "\n");
	ptm_report ($o->{'ptm'}, "# PT Position Mapping\n\n", "\n");
	uim_report ($o->{'uim'}, "# UIM Mapping\n\n");
}

sub f1502_update ($$) {
	my ($o, $path) = @_;

	ptm_update ($o->{'ptm'},        ptm_read_jed (       $path));
	uim_update ($o->{'uim'}, $path, uim_read_jed (5, 40, $path));
}

1;

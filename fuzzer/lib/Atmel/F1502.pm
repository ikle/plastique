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

use Atmel::F1500::MCM;
use Atmel::F1500::PIM;
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

	$o{'pim'} = pim_alloc (2, 40);
	$o{'ptm'} = ptm_alloc (5, 32);
	$o{'mcm'} = ptm_alloc (12, 2);

	$o{'ptc'} = ptc_alloc (96);
	$o{'uim'} = uim_alloc (5, 40);

	return \%o;
}

sub f1502_load ($) {
	my ($db) = @_;
	my %o;

	$o{'pim'} = pim_load (2, 40, "$db/atmel/f1502/pim");
	$o{'ptm'} = ptm_load (5, 32, "$db/atmel/f1502/ptm");
	$o{'mcm'} = mcm_load (12, 2, "$db/atmel/f1502/mcm");

	$o{'ptc'} = ptc_load (96,    "$db/atmel/f1502/ptc");
	$o{'uim'} = uim_load (5, 40, "$db/atmel/f1502/uim");

	return \%o;
}

sub f1502_save ($$) {
	my ($o, $db) = @_;

	pim_save ($o->{'pim'}, "$db/atmel/f1502/pim");
	ptm_save ($o->{'ptm'}, "$db/atmel/f1502/ptm");
	mcm_save ($o->{'mcm'}, "$db/atmel/f1502/mcm");

	ptc_save ($o->{'ptc'}, "$db/atmel/f1502/ptc");
	uim_save ($o->{'uim'}, "$db/atmel/f1502/uim");
}

sub f1502_report ($) {
	my ($o) = @_;

	pim_report ($o->{'pim'}, "# UIM Position Mapping\n\n", "\n");
	ptm_report ($o->{'ptm'}, "# PT Position Mapping\n\n", "\n");
	mcm_report ($o->{'mcm'}, "# MC Position Mapping\n\n", "\n");

	ptc_report ($o->{'ptc'}, "# PT Configuration\n\n", "\n");
	uim_report ($o->{'uim'}, "# UIM Mapping\n\n");
}

sub f1502_update ($$) {
	my ($o, $path) = @_;

	pim_update ($o->{'pim'},        pim_read_jed (       $path));
	ptm_update ($o->{'ptm'},        ptm_read_jed (       $path));
	mcm_update ($o->{'mcm'},        mcm_read_jed (       $path));

	uim_update ($o->{'uim'}, $path, uim_read_jed (5, 40, $path));
}

1;

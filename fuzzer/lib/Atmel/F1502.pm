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

use Atmel::F1500::Fuzzer;
use Atmel::F1500::MCC;
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
	f1502_mcc_search
);

sub f1502_alloc () {
	my %o;

	$o{'pim'} = pim_alloc (2, 40);
	$o{'ptm'} = ptm_alloc (5, 32);
	$o{'mcm'} = ptm_alloc (12, 2);

	$o{'ptc'} = ptc_alloc (96);
	$o{'mcc'} = mcc_alloc (12, 32);
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
	$o{'mcc'} = mcc_load (12, 32,"$db/atmel/f1502/mcc");
	$o{'uim'} = uim_load (5, 40, "$db/atmel/f1502/uim");

	return \%o;
}

sub f1502_save ($$) {
	my ($o, $db) = @_;

	pim_save ($o->{'pim'}, "$db/atmel/f1502/pim");
	ptm_save ($o->{'ptm'}, "$db/atmel/f1502/ptm");
	mcm_save ($o->{'mcm'}, "$db/atmel/f1502/mcm");

	ptc_save ($o->{'ptc'}, "$db/atmel/f1502/ptc");
	mcc_save ($o->{'mcc'}, "$db/atmel/f1502/mcc");
	uim_save ($o->{'uim'}, "$db/atmel/f1502/uim");
}

sub f1502_report ($) {
	my ($o) = @_;

	pim_report ($o->{'pim'}, "# UIM Position Mapping\n\n", "\n");
	ptm_report ($o->{'ptm'}, "# PT Position Mapping\n\n", "\n");
	mcm_report ($o->{'mcm'}, "# MC Position Mapping\n\n", "\n");

	ptc_report ($o->{'ptc'}, "# PT Configuration\n\n", "\n");
	mcc_report ($o->{'mcc'}, "# MC Configuration\n\n", "\n");
	uim_report ($o->{'uim'}, "# UIM Mapping\n\n");
}

sub f1502_update ($$) {
	my ($o, $path) = @_;

	pim_update ($o->{'pim'},        pim_read_jed (       $path));
	ptm_update ($o->{'ptm'},        ptm_read_jed (       $path));
	mcm_update ($o->{'mcm'},        mcm_read_jed (       $path));

	uim_update ($o->{'uim'}, $path, uim_read_jed (5, 40, $path));
}

sub make_mcc_sample ($$$) {
	my ($o, $pos, $neg) = @_;
	my $mcc = make_test_sample ($o, $pos, $neg);

	return undef unless defined $mcc;

	f1502_update ($o->{conf}, $o->{path});
	return $mcc;
}

my @C44 = (
	'Property Atmel {JTAG off};',
	"Pin [44, 43, 1, 2] = [OE1, GCK1, GCLR, GCK2];\t/* Input-only pins\t*/",
	"Pin [4..9,   11..14, 16..21] = [P1..P16];\t/* MC1..MC16  I/O pins\t*/",
	"Pin [41..36, 34..31, 29..24] = [P17..P32];\t/* MC17..MC32 I/O pins\t*/",
);

my @C44_fb = (
	'Property Atmel {JTAG off};',
	"Pin [44, 43, 1, 2] = [OE1, GCK1, GCLR, GCK2];\t/* Input-only pins\t*/",
	"Pin [4..9,   11..14, 16..21] = [P1..P16];\t/* MC1..MC16  I/O pins\t*/",
	"Pin [41..36, 34..31, 29..24] = [P17..P32];\t/* MC17..MC32 I/O pins\t*/",
	"Pinnode [601..632] = [F1..F32];\t\t\t/* MC1..MC32 Feedbacks\t*/",
);

sub f1502_pins_expand ($) {
	my ($c) = @_;

	return unless defined $c->{pins} and ref ($c->{pins}) eq '';

	$c->{pins} = \@C44	if $c->{pins} eq 'C44';
	$c->{pins} = \@C44_fb	if $c->{pins} eq 'C44-fb';
}

sub f1502_mcc_search ($$) {
	my ($o, $c) = @_;

	$c->{cb}    = \&make_mcc_sample unless defined $o->{cb};
	$c->{cols}  = 12;
	$c->{rows}  = 32;
	$c->{count} = 16 unless defined $o->{count};
	$c->{order} = 5  unless defined $o->{order};

	$c->{path}  = 'work/test'   unless defined $o->{path};
	$c->{head}  = "$0-base.pld" unless defined $o->{head};
	$c->{dev}   = 'P1502C44'    unless defined $o->{dev};
	$c->{conf}  = $o;

	f1502_pins_expand ($c);
	return make_bit_map ($c);
}

1;

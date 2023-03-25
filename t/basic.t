#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Tk;
use Tk::LayerEditor;
use Tk::LayerEditorToplevel;

my $top = eval { new MainWindow };
plan skip_all => "cannot create main window: $@" if !$top;
plan 'no_plan';
$top->geometry('+10+10'); # for twm

my $f = $top->LayerEditor->pack;
isa_ok $f, 'Tk::LayerEditor';

my $f2 = $top->LayerEditorToplevel;
isa_ok $f2, 'Tk::LayerEditorToplevel';

__END__

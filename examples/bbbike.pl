#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: bbbike.pl,v 1.2 2000/02/14 23:30:56 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk 800.016; # canvas with dash patches
use Tk::LayerEditor;
use Tk::Pixmap;
use FindBin;

$top = new MainWindow;
$c = $top->Canvas(-width => 300,
		  -height => 300)->pack(-fill => "both", -expand => 1);

my(@tags) = ('red', 'green', 'blue');

$ubahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/ubahn.xpm");
$sbahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/sbahn.xpm");
$rbahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/rbahn.xpm");

foreach my $type (0 .. 2) {
    foreach my $lines (1 .. 100) {
	my($x1,$y1,$x2,$y2) = (int(rand(300)),
			       int(rand(300)),
			       int(rand(300)),
			       int(rand(300)),);
	$c->createLine($x1,$y1,$x2,$y2,
		       -width => 3,
		       -fill => $tags[$type], -tags => $tags[$type]);
    }
}

$u_visible = $s_visible = $r_visible = 1;

my @elem = (
	    {'Image'   => $ubahn_photo,
	     'Text'    => 'U-Bahn',
	     'Visible' => $u_visible,
	     'Data'    => 'blue',
	    },
	    {'Image'   => $sbahn_photo,
	     'Text'    => 'S-Bahn',
	     'Visible' => $s_visible,
	     'Data'    => 'green',
	    },
	    {'Image'   => $rbahn_photo,
	     'Text'    => 'Regionabahn',
	     'Visible' => $r_visible,
	     'Data'    => 'red',
	    },
	   );

my(@stack_order) = ('blue', 'green', 'red');

sub restack {
    my(@tags) = @_;
    foreach my $tag (reverse @tags) {
	$c->raise($tag);
    }
}

restack(@stack_order);

my $le = $top->LayerEditorToplevel
    (-title => 'Layer-Editor',

     -orderchange => sub {
	 my $items = $_[1];
	 restack( map { $_->{Data} } @$items );
     },

     -visibilitychange => sub { 
	 my($w, $data, $visible) = @_;
	 $c->itemconfigure($data, -state => ($visible ? 'normal' : 'hidden'));
     },

     -transient => $top,
    );
$le->add(@elem);

MainLoop;

__END__

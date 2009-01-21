#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: bbbike.pl,v 1.4 2009/01/21 21:57:15 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use strict;

use Tk 800.016; # canvas with dash patches
use Tk::LayerEditorToplevel;
use Tk::Pixmap;
use FindBin;

my $top = new MainWindow;
my $c = $top->Canvas(-width => 300,
		     -height => 300)->pack(-fill => "both", -expand => 1);

my(@tags) = ('red', 'green', 'blue', 'brown');

my $ubahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/ubahn.xpm");
my $sbahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/sbahn.xpm");
my $rbahn_photo = $top->Pixmap(-file => "$FindBin::RealBin/rbahn.xpm");
my $ampel_photo = $top->Pixmap(-file => "$FindBin::RealBin/ampel_klein.xpm");

foreach my $tag (@tags) {
    foreach my $lines (1 .. 300/@tags) {
	my($x1,$y1,$x2,$y2) = (int(rand(300)),
			       int(rand(300)),
			       int(rand(300)),
			       int(rand(300)),);
	$c->createLine($x1,$y1,$x2,$y2,
		       -width => 3,
		       -fill => $tag, -tags => $tag);
    }
}

my $u_visible = my $s_visible = my $r_visible = 1;

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
	    {'Image'   => $ampel_photo,
	     'Text'    => 'Ampeln',
	     'Visible' => $r_visible,
	     'Data'    => 'brown',
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

# -*- perl -*-

#
# $Id: LayerEditor.pm,v 1.3 1999/06/29 00:10:17 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

# XXX zentrieren der Icons
# XXX bar etwas weiter nach unten versetzen
# XXX autoscroll, falls die liste zu groß wird
# XXX binding für rechte maustaste
# XXX evtl. OK/Apply/Cancel entfernen. Bzw. höchstens Close lassen
# XXX veröffentlichen???
# XXX Visible an Tie::* hängen, damit es auch funktioniert, wenn ich
#     von außen die Visibility ändere
#     Oder eine Methode dafür einführen.

package Tk::LayerEditor;

use strict;
use vars qw($VERSION @ISA $layereye);

use Tk::Toplevel;
use Tk::DragDrop;
use Tk::DropSite;

@ISA = qw(Tk::Toplevel);
Construct Tk::Widget 'LayerEditor';
$VERSION = '0.01';

sub Populate {
    my($w, $args) = @_;
    $w->SUPER::Populate($args);
    $w->title('Layer-Editor');
    
    my $c = $w->Scrolled('Canvas', -scrollbars => 'osoe',
			 -relief => 'sunken',
			 -bd => 2,
			 -width => "4c",
			 -height => "6c",
			)->pack(-expand => 1, -fill => 'both');
    $c->afterIdle(sub { $c->configure(-background => 'white') });
    $w->Advertise('canvas' => $c);

    $layereye = $w->Photo(-file => Tk::findINC("Tk", "layereye.gif"))
      unless defined $layereye;

    my $dnd_source;
    $dnd_source = $c->DragDrop
      (-event => '<B1-Motion>',
       -sitetypes => ['Local'],
       -startcommand => sub { StartDrag($dnd_source, $w) },
#       -handlers => [[sub { warn "@_" }], [-type => 'FILE_NAME', [sub { warn "@_" }]]]
      );
    $c->DropSite(-droptypes => ['Local'],
		 -dropcommand => [sub { Drop($w, @_) }],
		 -motioncommand => [ sub { Motion($w, @_) }]);

    $c->bind('layeronoff', '<ButtonPress-1>' => sub { toggle_visibility($w) });

    my $f = $w->Component('Frame' => 'buttons'
			 )->pack(-fill => 'x');
    $f->Button(-command => [$w, 'OK'],
	       -text => 'OK')->pack(-side => 'left',
				    -expand => 1,
				    -fill => 'x'
				   );
    $f->Button(-command => [$w, 'Apply'],
	       -text => 'Übernehmen')->pack(-side => 'left',
				       -expand => 1,
				       -fill => 'x');
    $f->Button(-command => [$w, 'Cancel'],
	       -text => 'Abbrechen')->pack(-side => 'left',
					-expand => 1,
					-fill => 'x');
    $w->ConfigSpecs
      (
       -visibilitychange  => ['CALLBACK',undef,undef,undef],
       -orderchange       => ['CALLBACK',undef,undef,undef],
       -transient         => ['METHOD',undef,undef,undef],
      );
}

sub transient {
    my($w) = shift;
    my $ret;
    if (@_) {
	if ($_[0]) {
	    $ret = $w->SUPER::transient($_[0]);
	} else {
	    $ret = $w->SUPER::transient;
	}
    }
    $ret;
}

sub reorder {
    my($w, $elem, $newpos) = @_;
    my $swap_elem = $w->{Items}[$elem];
    splice @{$w->{Items}}, $elem, 1;
    if ($elem < $newpos) {
	$newpos--;
    }
    splice @{$w->{Items}}, $newpos, 0, $swap_elem;
    $w->add(@{$w->{Items}});
    $w->Callback(-orderchange);
}

sub add {
    my($w, @elem) = @_;
    my $x = $layereye->width + 4;
    my $layereye_height = $layereye->height;
    my $y = 2;
    my $max_width = 0;
    my $c = $w->Subwidget('canvas');
    $c = $c->Subwidget('canvas');
    $c->delete('all');
    my @y;
    my @p;
    my $i = 0;
    foreach my $e (@elem) {
	my $p = $e->{'Photo'};
	push @y, $y;
	push @p, $p;
	my $onid = $c->createImage
	  (2, $y,
	   -image => $layereye, -anchor => 'nw',
	   -tags => ['layeronoff', "layeronoff-$i", "layeron-$i"]);
	my $offid = $c->createRectangle
	  (2, $y, 2+$layereye->width, $y+$layereye_height,
	   -outline => 'white',
	   -fill => 'white',
	   -tags => ['layeronoff', "layeronoff-$i", "layeroff-$i"]);
	if ($e->{Visible}) {
	    $c->raise($onid, $offid);
	} else {
	    $c->raise($offid, $onid);
	}
	$c->createImage($x, $y,
			-image => $p, -anchor => 'nw',
			-tags => ['layeritem', "layeritem-$i"]);
	$y += _max($p->height, $layereye_height) + 2*2;
	if ($p->width > $max_width) {
	    $max_width = $p->width;
	}
	$i++;
    }
    push @y, $y;
    $max_width += $x + 6; # extra border

    $i = 0;
    my $txt_width = 0;
    foreach my $e (@elem) {
	my $l = $e->{'Text'};
	my $id = $c->createText($max_width, $y[$i],
				-text => $l, -anchor => 'nw',
				-tags => ['layeritem', "layeritem-$i"]);
	my $this_width = $c->fontMeasure($c->itemcget($id, -font), $l);
	if ($this_width > $txt_width) {
	    $txt_width = $this_width;
	}
	$i++;
    }
    $max_width = $max_width + $txt_width + 2;
    $c->configure(-scrollregion => [0,0,$max_width,$y]);
#XXX    $c->bind('layeritem', '<ButtonPress-1>' => [\&MoveLayer, $c]);
    $w->{'ItemsY'} = \@y;
    $w->{'ItemsPhoto'} = \@p;
    $w->{'Items'} = \@elem;
}


sub OK {
    my $w = shift;
    warn "$w OK";
}

sub Apply {
    my $w = shift;
    warn "$w apply";
}

sub Cancel {
    my $w = shift;
    warn "$w Cancel";
}

sub StartDrag {
    my $token = shift;
    my $top = shift;
    my $w = $token->parent;
    delete $token->{'XY'};
    my $e = $w->XEvent;
    my $X = $e->X;
    my $Y = $e->Y;
    my(@t) = $w->gettags('current');
    return 1 if (!@t || $t[0] ne 'layeritem' || $t[1] !~ /^layeritem-(\d+)/);
    my $inx = $1;
    $top->{'DragItem'} = $inx;
    $token->configure(-image => $top->{'ItemsPhoto'}[$inx]);
    $w->{'Dragging'} = $token;
    $token->MoveToplevelWindow($X,$Y);
    $token->raise;
    $token->deiconify;
    $token->FindSite($X,$Y);
}

sub Motion {
    my $top = shift;
    my($x, $y) = @_;
    my $c = $top->Subwidget('canvas');
    my $inx = get_item($c, $x, $y);
    return unless defined $inx;
    my $y_ref = $top->{ItemsY};
    my $line_pos;
    if (($y_ref->[$inx+1]-$y_ref->[$inx])/2+$y_ref->[$inx] > $y) {
	$line_pos = $y_ref->[$inx];
	$top->{After} = $inx;
    } else {
	$line_pos = $y_ref->[$inx+1];
	$top->{After} = $inx+1;
    }
    $c->delete('bar');
    $c->createLine(0,$line_pos, 100, $line_pos, -tags => 'bar');
    
}

sub Drop {
    my $top = shift;
    warn "@_";
    my($x, $y) = ($_[1], $_[2]);
    my $c = $top->Subwidget('canvas');
    my $inx = get_item($c, $x, $y);
    if (!defined $inx) {
	$inx = $top->{After};
    }
    $c->delete('bar');
    $top->reorder($top->{'DragItem'},$inx);
    
}

sub get_item {
    my($c, $x, $y, $itemname) = @_;
    $itemname = "layeritem" unless defined $itemname;
    my $id = $c->find('closest', $x, $y);
    return unless defined $id; # XXX or ''
    my(@tags) = $c->gettags($id);
    return unless (@tags && $tags[0] eq $itemname &&
		   $tags[1] =~ /^$itemname-(\d+)/);
    my $inx = $1;
    return $inx;
}

sub toggle_visibility {
    my $w = shift;
    my $c = $w->Subwidget('canvas')->Subwidget('canvas');
    my $e = $c->XEvent;
    my($x, $y) = ($e->x, $e->y);
    my($idx) = get_item($c, $x, $y, 'layeronoff');
    return if !defined $idx;
    if ($w->{Items}[$idx]{'Visible'}) {
	$c->raise("layeroff-$idx", "layeron-$idx")
    } else {
	$c->raise("layeron-$idx", "layeroff-$idx")
    }
    $w->{Items}[$idx]{'Visible'} = !$w->{Items}[$idx]{'Visible'};
    $w->Callback(-visibilitychange,
		 $w->{Items}[$idx]{'Def'},
		 $w->{Items}[$idx]{'Visible'});
}

sub _max { ($_[0] > $_[1] ? $_[0] : $_[1]) }

sub get_order {
    my $w = shift;
    my @res;
    foreach (@{$w->{Items}}) {
	push @res, $_->{Def};
    }
    @res;
}

1;

__END__

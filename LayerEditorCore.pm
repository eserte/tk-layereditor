# -*- perl -*-

#
# $Id: LayerEditorCore.pm,v 1.1 2000/02/14 23:24:45 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999, 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Tk::LayerEditorCore;

use strict;
use vars qw($layereye);

#use Tk::Toplevel;
use Tk::DragDrop;
use Tk::DropSite;

#@ISA = qw(Tk::Toplevel);
#Construct Tk::Widget 'LayerEditor';
#$VERSION = '0.03';

sub CommonPopulate {
    my($w, $args) = @_;

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
      );
    $dnd_source->bind('<Any-KeyPress>' => [sub { Done($w) }]);

    $c->DropSite(-droptypes => ['Local'],
		 -dropcommand => [sub { Drop($w, @_) }],
		 -motioncommand => [ sub { Motion($w, @_) }]);

    $c->bind('layeronoff', '<ButtonPress-1>' => sub { toggle_visibility($w) });
#XXX    $c->Tk::bind('<B1-Motion>' => sub { $w->check_autoscroll });

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
    $w->Callback(-orderchange => $w, $w->{Items});
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
	my $p = $e->{'Image'};
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
	my $p_height = 0;
	my $p_width = 0;
	if ($p) {
	    $c->createImage($x, $y,
			    -image => $p, -anchor => 'nw',
			    -tags => ['layeritem', "layeritem-$i"]);
	    $p_height = $p->height;
	    $p_width = $p->width;
	}
	$y += _max($p_height, $layereye_height) + 2*2;
	if ($p_width > $max_width) {
	    $max_width = $p_width;
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
	my $this_width;
	eval {
	    $this_width = $c->fontMeasure($c->itemcget($id, -font), $l);
	};
	if ($@ || !defined $this_width) { # for 402.xxx compatibility
	    $this_width = 12;
	}
	if ($this_width > $txt_width) {
	    $txt_width = $this_width;
	}
	$i++;
    }
    $max_width = $max_width + $txt_width + 2;
    $c->configure(-scrollregion => [0,0,$max_width,$y]);
#XXX what's that?    $c->bind('layeritem', '<ButtonPress-1>' => [\&MoveLayer, $c]);
    $w->{'ItemsY'} = \@y;
    $w->{'ItemsImage'} = \@p;
    $w->{'Items'} = \@elem;
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
    if ($top->{'ItemsImage'}[$inx]) {
	$token->configure(-image => $top->{'ItemsImage'}[$inx]);
    } else {
	$token->configure(-text => $top->{Items}[$inx]->{Text});
    }
    $w->{'Dragging'} = $token;
    $token->MoveToplevelWindow($X,$Y);
    $token->raise;
    $token->deiconify;
    $token->FindSite($X,$Y,$e);
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
    $c->createLine(0, $line_pos-2, 100, $line_pos-2, -tags => 'bar');
}

sub Drop {
    my $top = shift;
    #XXX warn "@_";
    my($x, $y) = ($_[1], $_[2]);
    my $c = $top->Subwidget('canvas');
    my $inx = get_item($c, $x, $y);
    $inx = $top->{After};
    $c->delete('bar');
    $top->reorder($top->{'DragItem'},$inx);
}

# cleanup after cancelling a drag/drop command
sub Done {
    my $top = shift;
    my $c = $top->Subwidget('canvas');
    $c->delete('bar');
}

sub get_item {
    my($c, $x, $y, $itemname) = @_;
    $itemname = "layeritem" unless defined $itemname;
    my $id = $c->find('closest', $x, $y);
    return unless defined $id;
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
		 $w,
		 $w->{Items}[$idx]{'Data'},
		 $w->{Items}[$idx]{'Visible'});
}

# XXX implement!
#  sub check_autoscroll {
#      my $w = shift;

#      $w->{Autoscroll} = $w->repeat(20, sub {
#  				      my $e = $w->XEvent;
#  				      warn $e->x, " " ,$e->y; 
#  				  });

#      if ($w->{Autoscroll}) {
#  	$w->{Autoscroll}->cancel;
#  	undef $w->{Autoscroll};
#      }

#  }

sub _max { ($_[0] > $_[1] ? $_[0] : $_[1]) }

1;

__END__

=head1 NAME

Tk::LayerEditorCore - internal module for LayerEditor and LayerEditorToplevel

=head1 SYNOPSIS

  use Tk;
  use Tk::LayerEditor;
  use Tk::LayerEditorToplevel;

=head1 DESCRIPTION

This is only an internal module used by Tk::LayerEditor and
Tk::LayerEditorToplevel.

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

=head1 COPYRIGHT

Copyright (c) 1999, 2000 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Tk::Canvas(3), Tk::LayerEditor(3), Tk::LayerEditorToplevel(3).

=cut


# -*- perl -*-

BEGIN { $| = 1; print "1..4\n"; }

use Tk;

eval { require Tk::LayerEditor };
if ($@) {
    print "not ok 1\n";
} else {
    print "ok 1\n";
}

eval { require Tk::LayerEditorToplevel };
if ($@) {
    print "not ok 2\n";
} else {
    print "ok 2\n";
}


my $top = new MainWindow;
eval { $top->geometry('+10+10'); };

my $f = $top->LayerEditor->pack;
if (!$f) {
    print "not ok 3\n";
} else {
    print "ok 3\n";
}

my $f2 = $top->LayerEditorToplevel;
if (!$f2) {
    print "not ok 4\n";
} else {
    print "ok 4\n";
}


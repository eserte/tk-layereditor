use Tk::MMutil;
use Tk::Config;

Tk::MMutil::TkExtMakefile(
    'NAME'	   => 'Tk::LayerEditor',
    'VERSION_FROM' => 'LayerEditor.pm',
    'PM'           => {'LayerEditor.pm' => '$(INST_LIBDIR)/LayerEditor.pm',
		       'layereye.gif'   => '$(INST_LIBDIR)/layereye.gif',
		      },
);

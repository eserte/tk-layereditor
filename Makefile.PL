use Tk::MMutil;
use Tk::Config;

Tk::MMutil::TkExtMakefile(
    'NAME'	   => 'Tk::LayerEditor',
    'VERSION_FROM' => 'LayerEditorCore.pm',
    'PM'           =>
       {'LayerEditor.pm' => '$(INST_LIBDIR)/LayerEditor.pm',
	'LayerEditorCore.pm' => '$(INST_LIBDIR)/LayerEditorCore.pm',
	'LayerEditorToplevel.pm' => '$(INST_LIBDIR)/LayerEditorToplevel.pm',
	'layereye.gif'   => '$(INST_LIBDIR)/layereye.gif',
       },
);

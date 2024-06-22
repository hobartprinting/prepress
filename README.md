# Prepress
Note: The BSD-3 clause only applies to the files prepress-main.tcl, prepress-printers.tcl, and files in msgs directory. TCL/TK, Ghostscript, Imagemagick, Tablelist all have their own copywrites.

Utility to help fine tune, convert, measure coverage, or inspect files that will be sent to a press or printer.

This is a tcl/tk script that steers ghostscript and imagemagick to help prepare files for print.
It could be defined as a command or action center.

If installing on Windows: ghostscipt, imagemagick and the TCL environment must be installed. If possible potrace.

Links to TCL/TK https://www.magicsplat.com https://www.magicsplat.com/tcl-installer/

Link to Ghostscript https://www.ghostscript.com/releases/index.html  (download Ghostscript - 64 bit if possible)

Link to Imagemagick https://imagemagick.org/index.php
Link to potrace https://potrace.sourceforge.net/#downloading

On all window installs make sure that they are all in the Path in Environmental Settings.
Example:
For windows add to Path variables - Example:  C:\Program Files\gs\gs9.23\bin;C:\Program Files\gs\gs9.23\lib

To set vairable in Windows:
Control Panel → System and Security → System → Advanced System Settings → computer name, domain and workgroup settings → Advanced → Environment Variables
To test: in cmd shell type 'where potrace' or 'where gswin64c'

To run prepress download released files, place prepress folder in directory, then open cmd shell; change to correct directory; and type 'tclsh prepress-main.tcl
Another idea is to create a batch file to double click and lanunch.

On Windows you can also open the magicsplat Tk GUI console and then open the source file from there 'prepress-main.tcl'

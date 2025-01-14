# Prepress
Note: The BSD-3 clause only applies to the files prepress-main.tcl, prepress-printers.tcl, and file en_US.msg in msgs directory. TCL/TK, Ghostscript, Imagemagick, Tablelist all have their own copywrites.

Utility to help fine tune, convert, measure coverage, or inspect files that will be sent to a press or printer.

This is a tcl/tk script that steers ghostscript and imagemagick to help prepare files for print.
This application/script is an action center that makes it easy to use opensource commands without escaping as when using a shell.
The actions (or commands) that we use in print production are in the application already.

Link to Ghostscript https://www.ghostscript.com/releases/index.html  (download Ghostscript - 64 bit if possible)
Link to Imagemagick https://imagemagick.org/index.php
Link to potrace https://potrace.sourceforge.net/#downloading

# WINDOWS
A tcl/tk needs to be downloaded if not present. My favorite for windows install to tcl/tk is magicsplat.
It comes with the full environment with many extensions.

Link to TCL/TK https://www.magicsplat.com/tcl-installer/  (see download link)
If you have windows7 or greater; get the latest version of tcl - tcl-9.01 x64 , get x86 fpr 32 bit.

Make sure on that the installs of ghostscript and Imagemagick are in the Path in Environmental Settings after installing.
Example:
Path variables -  C:\Program Files\gs\gs9.23\bin;C:\Program Files\gs\gs9.23\lib

To set Path variables in Windows:
Control Panel → System and Security → System → Advanced System Settings → computer name, domain and workgroup settings → Advanced → Environment Variables
To test: in cmd shell type 'where potrace' or 'where gswin64c' or 'where magick' - leave out the quotes

To run prepress; download the released zip and unzip, place prepress folder in directory (I use Documents directory). 
Open cmd ; change cd to correct directory;  Once in prepress directory type 'tclsh prepress-main.tcl - thats it.
Another idea is to create a windows batch file and double click to launch application (script).

Another way: Open magicsplat Tk GUI console; then from the menu "File->Source' chose 'prepress-main.tcl'

# MacOS


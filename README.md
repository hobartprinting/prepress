# Prepress
Note: The BSD-3 clause only applies to the files prepress-main.tcl, prepress-printers.tcl, and file en_US.msg in msgs directory. TCL/TK, Ghostscript, Imagemagick, Tablelist all have their own copywrites.

Utility to help fine tune, convert, measure coverage, or inspect files that will be sent to a press or printer.

**Basic requirements**
1. tcl/tk run time 
   - running the script/app
2. Ghostscript
   - used in rastering  pdf,ps,eps to grayscale tiff separations in c m y k and spot color.
   - used in converting postscript to pdf
   - used in converting pdf to postscript
   - used in converting pdf to grayscale pdf
   - used in determining cmyk Ink Coverage of pdf or ps files
     - and applying the coverage to a printer profile to calculate costs, or volume of ink
3. Imagemagick

Optional
4. java 8 or above - used for inspection of pdf's using pdfbox
5. potrace - for creating vectors
A tcl/tk needs to be downloaded if not present. My favorite for windows tcl/tk is magicsplat.

This application/script makes it easy to use opensource commands without escaping as when using a shell.
By having a GUI and file dialogs it is much faster to use than using the command line.
The actions (or commands) that we use in print production are in the application already.

Link to Imagemagick https://imagemagick.org/index.php

Link to potrace https://potrace.sourceforge.net/#downloading

## WINDOWS INSTALL

It comes with the full environment with many extensions.

Link to TCL/TK https://www.magicsplat.com/tcl-installer/  (see download link)
If you have windows7 or greater; get the latest version of tcl - tcl-9.01 x64 or get x86 for 32 bit windows.
This has also been tested on 8.6 versions of tcl/tk .

Make sure on that the installs of ghostscript and Imagemagick are in the Path in Environmental Settings after installing.
Example:
Path variables -  C:\Program Files\gs\gs9.23\bin;C:\Program Files\gs\gs9.23\lib

01-15-2025  
**Ghostscript** 
Releases https://www.ghostscript.com/releases/index.html  (download Ghostscript - 64 bit if possible)
Click on link that says Ghostscript - https://www.ghostscript.com/releases/gsdnld.html
After the install restart Windows. The Path to ghostscript should have been added during the install.
To test open cmd (command) shell and type : where gswin64c -if installed it will show the path.
If you have 32 bit system the type : where gswin32c

I you must set Path variables in Windows:
Control Panel → System and Security → System → Advanced System Settings → computer name, domain and workgroup settings → Advanced → Environment Variables

### Prepress
Download the released zip and unzip, place prepress folder in directory (I use Documents/scripts directory). 
**To Run:**
Open cmd (command); cd to correct directory;  Once in prepress directory type 'tclsh prepress-main.tcl - thats it.

A windows batch file is included, double click.

Another way: Open magicsplat Tk GUI console; then from the menu "File->Source' chose 'prepress-main.tcl'

# MacOS


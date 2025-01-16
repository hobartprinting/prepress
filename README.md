# Prepress
Note: The BSD-3 clause only applies to the files prepress-main.tcl, prepress-printers.tcl, and file en_US.msg in msgs directory. 

TCL/TK, Ghostscript, Imagemagick, Java have their own copyrights.

This script/app is a utility to help fine tune, convert, measure coverage, or inspect files that will be sent to a press or printer.
This scirpt/app is using opensource solutions.
When the script is first launched it checks the presence for the open source tools such as ghostscript or imagemagick and if not present disables the menu items that need them.
Therefore not all of the below requirements need to be present.



This application/script makes it easy to use opensource commands without escaping as when using a shell.
By having a GUI and file dialogs it is much faster to use than using the command line.
The actions (or commands) that we use in print production are in the application already.
  
**Requirements**
1. tcl/tk runtime
   - Run time for the prepress script
     - source code https://www.tcl-lang.org/software/tcltk/download.html
   - Windows: tclkit.exe runtime is included in download
     - **Or download** https://www.magicsplat.com/tcl-installer/
     - tclkit.exe (ver 8.6.12 amd64) runs perfectly but the fonts are not as sharp
     - http://kitcreator.rkeene.org/kitcreator  to create your own tclkit
   - MacOS: tclkit-reene-mac runtime included in downloadhttps://macports.org
     - tclkit-reene-mac (ver 8.6.10 amd64) runs perfectly
       - **Or download** from MacPorts https://macports.org
         - If macports not install then choose from site the correct install
         - Then if command line tools not already install them
         - test by open terminal and type gcc - if not install will get an alert box
          - to install
            - in terminal type
            - xcode-select --install
            - Click “Install” to download and install Xcode Command Line Tools.
            - xcodebuild -license  (then agree to the license)
         - In terminal use sudo and be ready to type in your admin password
         - https://ports.macports.org/port/tcl/
           - sudo port install tcl
         - https://ports.macports.org/port/tk/
           - sudo port install tk +quartz
         - https://ports.macports.org/port/tcllib/
           - sudo port install tcllib
         - https://ports.macports.org/port/tklib/
           - sudo port install tklib
   - Linux, unix, or bsd use standard app ports or compile from source
2. Ghostscript
   - used in rastering pdf,ps,eps to grayscale tiff separations in c m y k and spot color.
   - used with imagemagick in coverting an image to a pdf retaining its dpi and color model
   - used in converting postscript to pdf
   - used in converting pdf to a postscript
   - used in converting pdf to a grayscale pdf
   - used in determining cmyk Ink Coverage of a pdf or ps file
     - the prepress script applies the resulting coverage to the default printer profile to calculate costs, or even volume of ink used
     - **ghostscript is all that is needed when using the Ink Coverage portion using just the cmyk coverage part**
       - imagemagick is needed to measure cmyk that can measure spot
   - **Install**
   	 - Windows
   	   - https://www.ghostscript.com/releases/gsdnld.html
   	     - after install restart windows
   	     - to test open cmd.exe and type where.exe gswin64c 
   	       - it will show the install path
   	 - MacOS 
   	   - https://ports.macports.org/port/ghostscript/
   	     - sudo port install ghostscript
   	     - Or **upgrade** existing version
   	       - sudo port selfupdate && sudo port upgrade ghostscript
   	       - to test open terminal and type which gs
   	         - it will show the install path
3. Imagemagick
   - used with ghostscript in coverting an image into a pdf and retaining its dpi and color model
   - used in all image operations
   - used identify for giving statistics on images, pdfs, ps files
   - used in finding mediabox in ink coverage operation if it is present, otherwise using regex to find
   - used in creating **pbm files** which potrace can use to create vector file
   - used to create strokes in images , especially type that is thin and needs swelled.
     - **Install**
       - Windows
         - https://imagemagick.org/script/download.php
       - MacOS - MacPorts.org
         - https://ports.macports.org/port/ImageMagick7/
           - sudo port install ImageMagick7 
4. java version 8 or above
   - used for inspection of pdf's using pdfbox (https://www.apache.org/licenses/)
   - pdfbox is included in the lib directory of this app (https://pdfbox.apache.org/)
5. potrace 
   - used in the creation of vectors from a bitmap (pbm files)
5. pdfbox - shows the cropbox, mediabox and trimbox data





Link to potrace https://potrace.sourceforge.net/#downloading

## WINDOWS INSTALL

It comes with the full environment with many extensions.

A tcl/tk needs to be downloaded if not present. My favorite for windows tcl/tk is magicsplat.
Link to TCL/TK download: https://www.magicsplat.com/tcl-installer/  (see download link)
If you have windows7 or greater; get the latest version of tcl - tcl-9.01 x64 or get x86 for 32 bit windows.
This script/app has also been tested on 8.6 versions of tcl/tk .

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


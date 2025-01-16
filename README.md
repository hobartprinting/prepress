# Introduction
Note: The BSD-3 clause applies to the files prepress-main.tcl, prepress-printers.tcl, and file en_US.msg in msgs directory. 

TCL/TK, Ghostscript, Imagemagick, Java, and PdfBox have their own copyrights.

This script/app is a utility to help fine tune, convert, measure coverage, or inspect files that will be sent to a press or printer.

This scirpt/app uses opensource solutions.\
When the script is first launched it checks the presence for the open source tools such as ghostscript or imagemagick and if not present disables the menu items that need them.
Therefore not all of the below requirements need to be present. 
**To make the best use of our prepress workflow we recommend at having ghostscript and imagemagick installed.**

This application/script makes it easy to use opensource commands without escaping as when one would have to do using a shell such as mac terminal or bash.\
By having a GUI and file dialogs it is much faster and easier to use cli commands than using the 'shell' or likes of 'cmd.exe' .

The actions (or commands) that 'prepress' executes are the ones that we most use in our print production workflows.\
**Examples**
 - soft proofing: receiving a pdf; rasterizing it; creating a cmyk color model tiff file; wrapping the tiff into a pdf by using 'image to pdf' in menu.
   This is a 2 step process and in in future will add process to 1 menu item.
 - receive a pdf: rasterizing it; creating separate grayscale tiff files; swell the type or art work if too thin. 
   If necessary: copy and paste using gimp to achieve the right balance in type and logo's by leaving area's original alone.
 - grayscale a pdf file
 - batch processing image files: downsizing while retain original color model; choose directory and all images are rescaled and put in a new directory.

# Prepress
Download the released zip and unzip, place prepress folder in directory (I use Documents/scripts directory). 

**Requirements**
1. tcl/tk runtime
   - **Windows: tclkit.exe runtime is included in download No further action required in step 1**\
     <ins>Double click file **startPrepressTclKit.bat**</ins>
     - note: tclkit.exe (ver 8.6.12 amd64) runs perfectly but the fonts are not as sharp as magicsplat's install
     - Or http://kitcreator.rkeene.org/kitcreator  to create your own tclkit
     - Or download for system wide tcl/tk  https://www.magicsplat.com/tcl-installer/ \
       <ins>Double click file **startPrepressTclSystem.bat**</ins>
   - **MacOS: Use tclkit-mac runtime included in download - No further action required in step 1**
     <ins>Double click file **prepress.command**</ins>\
     Or <ins>Double click file **prepress**</ins> If the file extension is hidden\
     For the above to work however you must open **terminal** and cd into prepress directory and type **chmod +x ./prepress.command**    
   - tclkit-mac (ver 8.6.10 amd64) runs perfectly
   - **Or download** from MacPorts https://macports.org
     - If macports not install then choose from site the correct install
     - Then if **command line tools** not already install them
       - test by open terminal and type **gcc** - if not install will get an alert box
         - to install
            - in terminal type
            - xcode-select --install
            - Click “Install” to download and install Xcode Command Line Tools.
            - xcodebuild -license  (then agree to the license)
     - After macports installed and the command line tools are installed follow below. \
       Note: if you already have tcl installed then it would be (sudo port upgrade tcl)
         - https://ports.macports.org/port/tcl/
           - sudo port install tcl
         - https://ports.macports.org/port/tk/
           - sudo port install tk +quartz
         - https://ports.macports.org/port/tcllib/
           - sudo port install tcllib
         - https://ports.macports.org/port/tklib/
           - sudo port install tklib
   - Linux, unix, or bsd use standard package managers to set up tcl/tk ports or compile from source below
     - make sure that tcl, Tk, tklib, and tclLib are all installed
   - tcl/tk source code (if you are up to it) - **source can be compiled to most operating systems**
     - source code https://www.tcl-lang.org/software/tcltk/download.html
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
   - used in the creation of vectors from a bitmap (.pbm files) \
     potrace: https://potrace.sourceforge.net/#downloading
5. pdfbox - shows the cropbox, mediabox and trimbox data


* Windows Note:
Make sure on that the installs of ghostscript and Imagemagick are in the Path in Environmental Settings after installing.
Example:
Path variables -  C:\Program Files\gs\gs9.23\bin;C:\Program Files\gs\gs9.23\lib \
I you must set Path variables in Windows: \
Control Panel → System and Security → System → Advanced System Settings → computer name, domain and workgroup settings → Advanced → Environment Variables





#!/usr/bin/env tclsh 
###!/usr/bin/env wish
# Copyright 2008 Randall J Hobart
# Prepress-1.0.0  
#   Java Version -began: 2008
#   Objective-C Version: 2008
#	Tcl.Tk Version began: 12-27-2019
# 	Main Features: 
#		Measuring ink coverage based on print/art size
#		Applying those measurements with the expected consumable costs of the printing machine
#		Resulting in a Total Cost to print a File
#		Including of consumables, wear and tear of machine parts as in drums, fusers, waste	containers, jets			
#	Added features include:
#		Move code to include windows, linux, mac - tcl.tk
#		Prepress actions to help manipulate pdfs, ps, and eps files used to help create files according to printer specs
#		Add cost for number of copies
#       Predict amount of consumables used using dollar amounts, and estimating volume of ink used
#   Problems with Paths:
#   	Ghostscript cannot process on mac a path with double quotes "
#   	Tried escaping the " with \" and did not solve the problem
#   	Solutions: rename path - take out "
#		Using exec from tcl you don't need the path escaped as in a shell
#   Links on using ghostscript
#       http://linux-commands-examples.com/ghostscript
#		https://ghostscript.readthedocs.io/en/gs10.02.1/Devices.html   - added 12-11-2024
#		https://ghostscript.readthedocs.io/en/latest/Devices.html
#       https://ghostscript.com/docs/9.54.0/Devices.htm
#		https://ghostscript.com/docs/9.54.0/Use.htm
#		https://github.com/ArtifexSoftware/ghostpdl-downloads/releases?page=6
#		included with ghostscript - pdf2ps, ps2epsi, pdf2dsc, ps2ascii, ps2ps, ps2ps2
#       	For windows add to Path variables - Example:  C:\Program Files\gs\gs9.23\bin;C:\Program Files\gs\gs9.23\lib
#	        	Control Panel → System and Security → System → Advanced System Settings → computer name, domain and workgroup settings → Advanced → Environment Variables
#                              set GS to the version needed - such as gswin64c or gswin32c
#   Links on using ImageMagick
#		https://www.imagemagick.org/script/resources.php
#		https://imagemagick.org/script/formats.php
#       https://www.imagemagick.org/Usage/morphology/#difference
#       https://blog.jiayu.co/2019/05/edge-detection-with-imagemagick/
#       https://www.imagemagick.org/Usage/transform/#edge
#       https://www.imagemagick.org/Usage/morphology/#edge
#		https://www.imagemagick.org/Usage/transform/
#	Links on poppler operations - which include pdfinfo used for information of pdf such as artbox and bleedbox
#		https://www.prepressure.com/pdf/basics/page-boxes
#		https://www.cyberciti.biz/faq/linux-unix-view-technical-details-of-pdf/    - this as instructions on how to use
#		http://www.xpdfreader.com/download.html  - note - this has window version
#		https://poppler.freedesktop.org/
#		https://poppler.freedesktop.org/api/glib/
#	tcl/tk links
#		https://www.tutorialspoint.com/tcl-tk/tcl_tk_quick_guide.htm
#		https://wiki.tcl-lang.org/page/exec
#       https://wiki.tcl-lang.org/page/Actions
#		https://www.tcl.tk/man/tcl8.5/tutorial/Tcl26.htm  - Running other programs from TCL using exec and open
#	    https://www.magicsplat.com/blog/
#		https://www.magicsplat.com/index.html
#		https://www.magicsplat.com/software/
#		https://www.magicsplat.com/tcl-installer/
#		https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/
#	pdftotext and utilities - links - another way to get pdftotext and 
#		https://www.xpdfreader.com/download.html - another way to get pdftotext
#       mac http://poppler.freedesktop.org
# Main file used june 17 , 2022
#   Added potrace and convert image to .pbm 12-21-2022
#   https://potrace.sourceforge.net/faq.html
#   02-24-2023 - Start date: To insure windows compatible - have options as lists instead of 1 long command.
#                          : Make sure commands are all found and naming is consistant within this script
#                          : Such as gs command in a variable which in windows can be gswin64c as a value ,, etc...
#                          : Such as to change every instance that "exec {*}$cmd >>& /dev/tty " is used and to change to
#                              set cmd $convert (as an example)
#	                           set cmd_options [list $filename -negate $outputFile]    
#	                           if {[catch {exec $convert {*}$cmd_options} result]} {    ......etc (example)
# Ghostscript versions
# 	Windows Vista 9.10   2013 - mostly compatable - separates; cmyk coverage not available
#                        20
#   Windows 10 -  9.16   2015 - mostly compatable -cmyk coverage not available
#   Snow Leopard  9.21   2017 - compatable - throws error but completes the task on device tiffsep, inkcoverage works
#											Files can be opened directly in photoshop or gimp - and gs can work with the files
#                 10.02  2023-09-13 - using macports - downloaded and compiled successful
#   Monterey      9.56.1 2022 - compatible
#	              9.06 was a bug that left out tiffsep1 https://gs-bugs.ghostscript.narkive.com/0tAuTQi8/bug-693502-new-tiffsep1-on-mac-os-x
# Imagemagick versions
# 	Windows Vista    v 6.5.4-9 2009 will not use newer formating - can use identify on pdf all - verbose
#							This works: set identify_options [list -format {%[fx:h]} $filename-default.ps]
#   Windows 10       v 7.1.0-56 Q16-HDRI - compatable All
#   Snow Leopard     v 6.9.9.6-6 2016 - not compatable with identify in formating or ps or pdf
#				     v 6.9.11 2021 - macports - successful - all compatible
#   Montery          v 6.9.11-60 Q16 arm 2021 - successful - all
#	Ventura-morpheus v 6.9.10-78 Q16 x86_64 2019-12-17 - formatting bounding-box fails
# Changes
# 
# Send to printers - started 12-12-2024
# Purpose:
# 		  Send a file to a printer or print server
#		  Get a list of active printers on system
#		  Put printers into a list in which user can choose the default printer to send the file
#		  Allow user to choose the file using gui dialog box
#         This will allow file to be sent straight to printer without being reinterpreted by an application
#		  	Normally files are opened by an application then printed through that application.
#			In which the file could and most likely be reinterpreted
#				Which would mean the original file may have been changed - perhaps the colormodel,  or even the pixel value
# 	Use Cups for mac or linux and use Windows cmds for windows
# 	https://stuff.mit.edu/afs/athena/astaff/project/opssrc/cups/cups-1.4.4/doc/help/options.html
#	https://www.cups.org/doc/options.html
#	If cups installed then below has webpage for instructions locally
# 	http://localhost:631/help/options.html?TOPIC=Getting+Started&QUERY
# Example:
# 	lpstat -p -d
# 	printer Brother_HL_L2360D_series is idle.  enabled since Thu Dec 12 15:14:51 2024
# 	printer EnPress is idle.  enabled since Wed Sep  4 15:21:16 2024
# 	printer IQueImpress is idle.  enabled since Mon Mar 18 19:17:42 2024
# 	printer IQueue_Server is idle.  enabled since Fri Dec 13 16:17:39 2024
# 	system default destination: IQueue_Server

package require Tk
package require msgcat

# load message catalogs - Do this at bottom of script - after initParams before creategui
#msgcat::mclocale en_US
#msgcat::mcload [file join [file dirname [info script]] msgs]

#ttk::style theme use classic
## Global Vars
# ghostscript

set gs "gs" ; # for mac, bsd, and linux name stays the same; on windows gs will have name of exe
set pdf2ps "pdf2ps"
set ps2pdf "ps2pdf"

# imagemagick after version 6 still can use convert if legacy tools where installed
#             also windows will use exe name
#	          WINDOWS: Have make sure path variable set to base directory of installation
#             If version 7 and above us installed will use magick command but using convert var and composite will be a command option
#             Version 7 example: magick ..... or magick composite -etc .. 
#			  Version 6 example: convert .... or use composite .....
set convert "convert" ; # So this var could be 'convert' ver 6 or 'magick' ver 7 - depending on the version
set composite "composite" ; # new (version 6 of IM) - separate command ver 6 - option version 7
set identify "identify" ; # part of IM - imagemagick - separate command version6 - option version 7

set b_magick_7 "" ; # "true" or "false" a string
set b_magick_6 "" ; # "true" or "false" a string
set b_magick ""   ; # "true" or "false" a string
set potrace "potrace" ; #mac and linux

set pdfinfo "pdfinfo" ; # part of poppler utilites

# dpi used in creating separated tiffs
set dpi 1200 ; # default, but user preference will take over
set cache_path "" ; #path to cashe directory - will take out
# array of globals : globalparms 
array set globalparms {} ; # on start proc initParms is called
set LINE "********************************\n"
# set dict_parms [dict create] ; # instead of making global just create dict  \ 
								 # for storing and saving to disk\
								 # and then putting values back into the globalparms
#END Global Vars for the prepress portion 
								 
########## Vars for inkcoverage - shared between 2 top level windows
set printer_copies 1 ; # passed to dialog box and back to proc for num of copies to calculate costs
set printsize_dlg 0x0  ; # dummy value will change from the showPagesizeDlg , if cancel will remain 0x0
set printer_default "none" ; # selected default printer
set dict_printers {} ; # a nested dictionary of printers - value -> dict
### END vars pertaining to inkcoverage

## GUI ##
proc creategui {} {
	#wm title . "PrePressActions"
	wm title . [msgcat::mc title] ; # PrePressActions
	
	# put a text box in the window and add scrollbars
	text .txt -wrap none -xscroll {.h set} -yscroll {.v set}
	scrollbar .v -orient vertical -command {.txt yview}
	scrollbar .h -orient horizontal -command {.txt xview}
	.txt configure -tabs {1c}
	
	#layout
	grid .txt .v -sticky nsew	
	grid .h -sticky nsew
	
	# tell text widget to take all of the extra room
	grid rowconfigure . .txt -weight 1
	grid columnconfigure . .txt -weight 1
	
	# turn off tear off menus
	option add *TearOff off
	
	#create toplevel menubar
	. configure -menu .mbar
	menu .mbar
	
	# add File pulldown menu to menubar
	.mbar add cascade -label [msgcat::mc m_File] -menu .mbar.files -underline 0 ; #File
	menu .mbar.files
	.mbar.files add command -label [msgcat::mc "m_clearLog"]  \
		-command "clearLog"
	.mbar.files add command -label [msgcat::mc "m_WrapLines"] \
		-command {.txt configure -wrap word; wrapLinesDisable; unwrapLinesEnable }
	.mbar.files add command -label [msgcat::mc "m_UnWrapLines"] -state disable \
		-command {.txt configure -wrap none; unwrapLinesDisable; wrapLinesEnable }
	.mbar.files add command -label [msgcat::mc "m_quit"] \
		-command "quit"
	
	# add Convert pulldown menu to menubar
	.mbar add cascade -label {ConvertFile} -menu .mbar.convert -underline 0	
	menu .mbar.convert
	.mbar.convert add command -label [msgcat::mc "m_showDpiDialog"] \
		-underline 0 \
		-command "showDpiDialog"
	.mbar.convert add command -label [msgcat::mc "m_openPDFtoTiff"] \
		-underline 0 \
		-command "openPDFtoTiff"	
	.mbar.convert add separator
	.mbar.convert add command -label [msgcat::mc "m_openImagetoMono"] \
		-underline 0 \
		-command "openImagetoMono"	
	.mbar.convert add command -label [msgcat::mc "m_openTIFFandInvert"] \
		-underline 0 \
		-command "openTIFFandInvert"
	.mbar.convert add separator
	.mbar.convert add command -label [msgcat::mc "m_showSwellDialog"] \
		-underline 0 \
		-command "showSwellDialog"
	.mbar.convert add command -label [msgcat::mc "m_openTIFFandSwell"] \
		-underline 0 \
		-command "openTIFFandSwell"
	.mbar.convert add separator
	.mbar.convert add command -label [msgcat::mc "m_openImageFlipHorizontal"] \
		-command "openImageFlipHorizontal"		
	.mbar.convert add command -label [msgcat::mc "m_openImageFlipVertical"] \
		-command "openImageFlipVertical"	
	.mbar.convert add separator
	.mbar.convert add command -label [msgcat::mc "m_showBatchDialog"] \
		-command "showBatchDialog"
	.mbar.convert add command -label [msgcat::mc "m_openDirBatchScaleImgs"] \
		-command "openDirBatchScaleImgs"
	.mbar.convert add separator	
	.mbar.convert add command -label [msgcat::mc "m_openImageCreatePDF"] \
		-command "openImageCreatePDF"		
	.mbar.convert add command -label [msgcat::mc "m_openPSCreatePDF"] \
		-command "openPSCreatePDF"		
	.mbar.convert add command -label [msgcat::mc "m_openPDFCreatePS"] \
		-command "openPDFCreatePS"
	.mbar.convert add command -label [msgcat::mc "m_openPDFCreateGrayscalePDF"] \
		-command "openPDFCreateGrayscalePDF"	
	
	.mbar add cascade -label [msgcat::mc "m_Identify"] -menu .mbar.identify -underline 0
	menu .mbar.identify
	.mbar.identify add command -label [msgcat::mc "m_openImagePdfEpsInfoAll"] \
		-command "openImagePdfEpsInfoAll"
	.mbar.identify add command -label [msgcat::mc "m_openImagePdfEpsInfoSummary"] \
		-command "openImagePdfEpsInfoSummary"
	.mbar.identify add command -label [msgcat::mc "m_openPdfPsPdfinfo"] \
		-command "openPdfPsPdfinfo"
	.mbar.identify add command -label [msgcat::mc "m_openPdfBoxJar"] \
		-command "openPdfBoxJar"
	
	# menus for special potrace - 
	#if {(($::tcl_platform(user) eq "morpheus") && ($::tcl_platform(os) eq "Darwin"))} {
		.mbar add cascade -label [msgcat::mc "m_Vector"] -menu .mbar.vector -underline 0
		menu .mbar.vector
		.mbar.vector add command -label [msgcat::mc "m_openBitmapPBMCreatePS"] \
			-command "openBitmapPBMCreatePS"
		.mbar.vector add separator
		.mbar.vector add command -label [msgcat::mc "m_openImageCreatePBM"] \
			-command "openImageCreatePBM"
	#}
	
	# Menu Items for Coverage
	.mbar add cascade -label [msgcat::mc "m_Inkcoverage"] -menu .mbar.coverage -underline 0
	menu .mbar.coverage
	.mbar.coverage add command -label [msgcat::mc "m_measureCMYK"] \
		-command "measureCMYK"
	.mbar.coverage add command -label [msgcat::mc "m_measureCMYKspot"] \
		-command "measureCMYKspot"
	.mbar.coverage add separator
	.mbar.coverage add command -label [msgcat::mc "m_printerProfilesWin"] \
		-command "printerProfilesWin"
	
	# Menu Items for Help
	.mbar add cascade -label [msgcat::mc "m_Help"] -menu .mbar.help -underline 0
	menu .mbar.help
	.mbar.help add command -label [msgcat::mc "m_help"] \
		-command "help"
	
	# bind short cut keys
	#bind . <Control-x> {quit}
	#bind . <Command-x> {quit}
	
	#configure text widget and bind directory with hyperlink
	.txt tag configure dirHyperlink -foreground blue -underline true
	.txt tag bind dirHyperlink <Enter> {.txt configure -cursor center_ptr}
	.txt tag bind dirHyperlink <Leave> {.txt configure -cursor xterm}
	.txt tag bind dirHyperlink <Button-1> {clickLinkdirHyperlink %x %y}
	# other tags
	.txt tag configure procColor -foreground {dark red}
	.txt tag configure lineColor -foreground {dark green}
	.txt tag configure errorColor -foreground {red}
	# https://www.tcl.tk/man/tcl8.4/TkCmd/font.html#M26
	# got this from the demo's
	.txt tag configure verybig -font {Helvetica 24  bold}
	
	#window manager
	wm protocol . WM_DELETE_WINDOW {
		# called when closing window but does not exit the app
		# call quit to exit and save options before exit
		quit
	}
		
	#set the default cache directory which is location of the script
	#set script_name [ file normalize $::argv0]
	#set script_dir [file dir $script_name]
	#set cache_path "$script_dir[file separator].cache"
	# if dir exists will do nothing else creates the dir
	#file mkdir $cache_path
	
	#Need to determine if this is the first time setting up program
	#if it is then needs to check the Settings
	#may by pass this check and use saved settings
	puts "checkEnvSettings"
	checkEnvSettings
	puts "checkEnvSettings has finished"
}
# text widget events
proc clickLinkdirHyperlink {xpos ypos} {
	#puts "dirHyperlink pressed"
	#puts "@$xpos @$ypos"
	set i [.txt index @$xpos,$ypos]
	set range [.txt tag prevrange dirHyperlink $i]
	set url [eval .txt get $range]
	StartFileBrowser $url
}
# keep all globals in a single array
proc initParams {} {
	# all these init setting will reset if the init file exists, 
	# if init file does not exist these are the defaults
	
	global globalparms
	set globalparms(first_time) "true" ; # first time launching the application
	set globalparms(dpi) 1200 ; # for creating tiff files from PDF
	set globalparms(dpi_batch) 144 ; # for creating batch scaling of images
	set globalparms(pixel_w_batch) 1000 ; # for creating batch scaling of images
	set globalparms(quality_batch) 100 ; # for creating batch scaling of images if jpg
	set globalparms(set_swell) 1 ; # swell settings from 1 to 4 using diamond kernel
	set globalparms(defaultprinter) "none" ; #for keeping track of the default printer selected for inkcoverage operations
	set globalparms(locale) "en_US"
	# below will not be changed by the app. Above options are saved as options by the app
	set globalparms(cache_path) "$::env(HOME)[file separator].prepress_action_cache"
	set globalparms(gs_location_file) "gs_location.txt" ; # ghostscirpt
	set globalparms(convert_location_file) "convert_location.txt" ; # imagemagick
	set globalparms(composite_location_file) "composite_location_file.txt" ; # imagemagick
	set globalparms(pdf2ps_location_file) "pdf2ps_location_file.txt" ; # from ghostscript (pdf2ps)
	set globalparms(ps2pdf_location_file) "ps2pdf_location_file.txt" ; # from ghostscript (ps2pdf)
	set globalparms(potrace_location_file) "potrace_location_file.txt" ; # from Potrace http://www.icosasoft.ca/
	set globalparms(pdfinfo_location_file) "pdfinfo_location_file.txt" ; # from poppler http://poppler.freedesktop.org
	set globalparms(prepress_parms_file) "prepress_parms.txt" ; # file that contains all globalparms array - for saving this array settings
	set globalparms(printers_inkcoverage) "printers_inkcoverage.txt" ; #file that contains all the printers for inkcoverage operations
	
	## initialize a set of demo printers to start. This can be overwritten on the save file
	# First create a printer, then add to the global dict that contains all the printers
	######## kind should be 1 of these 3 options: "Color Toner" "Mono Toner" "Ink Jet" #####################
	global dict_printers ; #will store all printers to be used in the inkcoverage portion
	
	#Example EN/PRESS
	set printerColorLaser [dict create \
		"printer" "demoColorLaser" \
		"description" "Demo of a color toner based printer" \
		"kind" "Color Toner" \
		"cyan_toner_unit" 187.00 \
		"cyan_toner_yield" 34000 \
		"cyan_toner_percent" 5 \
		"magenta_toner_unit" 187.00 \
		"magenta_toner_yield" 34000 \
		"magenta_toner_percent" 5 \
		"yellow_toner_unit" 187.00 \
		"yellow_toner_yield" 34000 \
		"yellow_toner_percent" 5 \
		"black_toner_unit" 92 \
		"black_toner_yield" 43000 \
		"black_toner_percent" 5 \
		"spot_toner_unit" 0 \
		"spot_toner_yield" 0 \
		"spot_toner_percent" 0 \
		"cyan_drum_unit" 396.00 \
		"cyan_drum_yield" 120000 \
		"cyan_drum_percent" 5 \
		"magenta_drum_unit" 396.00 \
		"magenta_drum_yield" 120000 \
		"magenta_drum_percent" 5 \
		"yellow_drum_unit" 396.00 \
		"yellow_drum_yield" 120000 \
		"yellow_drum_percent" 5 \
		"black_drum_unit" 396.00 \
		"black_drum_yield" 120000 \
		"black_drum_percent" 5 \
		"spot_drum_unit" 0 \
		"spot_drum_yield" 0 \
		"spot_drum_percent" 0 \
		"transfer_belt_unit" 468.00 \
		"transfer_belt_yield" 200000 \
		"transfer_belt_percent" 0 \
		"fuser_unit" 589 \
		"fuser_yield" 160000 \
		"fuser_percent" 0 \
		"waste_unit" 0 \
		"waste_yield" 0 \
		"waste_percent" 0 ]
		
		#Example Brother model we have
		set printerMonoLaser [dict create \
			"printer" "demoMonoLaser" \
			"description" "Demo Printer: the toner, drum, belt all in one cartridge" \
			"kind" "Mono Toner" \
			"black_toner_unit" 60.00 \
			"black_toner_yield" 2500 \
			"black_toner_percent" 5 \
			"black_drum_unit" 0 \
			"black_drum_yield" 0 \
			"black_drum_percent" 0 \
			"transfer_belt_unit" 0 \
			"transfer_belt_yield" 0 \
			"transfer_belt_percent" 0 \
			"fuser_unit" 0 \
			"fuser_yield" 0 \
			"fuser_percent" 0 \
			"waste_unit" 0 \
			"waste_yield" 0 \
			"waste_percent" 0 ]
			
		#Example Canon Pixma G3270 GI-21 blk 135ml color 70ml
		set printerInkJet [dict create \
			"printer" "demoInkJet" \
			"description" "Demo Ink Jet printer" \
			"kind" "Ink Jet" \
			"cyan_unit" 13.00 \
			"cyan_yield" 2566 \
			"cyan_percent" 5 \
			"magenta_unit" 13.00 \
			"magenta_yield" 2566 \
			"magenta_percent" 5 \
			"yellow_unit" 13.00 \
			"yellow_yield" 2566 \
			"yellow_percent" 5 \
			"black_unit" 17.99 \
			"black_yield" 6000 \
			"black_percent" 5 \
			"spot_unit" 0 \
			"spot_yield" 0 \
			"spot_percent" 0 ]
			
		dict append dict_printers 1 $printerColorLaser
		dict append dict_printers 2 $printerMonoLaser
		dict append dict_printers 3 $printerInkJet		
		#puts "init: $dict_printers"
}
# check if ghostscript, imagemagick and utilities are prescent
proc checkEnvSettings {} {
	global globalparms
	global dict_printers ; # the printers used for inkcoverage
	global gs
	global convert
	global composite
	global identify
	global potrace
	global pdfinfo
	global b_magick_7
	global b_magick_6
	global b_magick
	set platform ""
	# if dir exists will do nothing else creates the dir
	if {[catch {file mkdir $globalparms(cache_path)} result]} {
		puts "Error: $result"
	}
	
	# need to check in a initiation file and if it exists before going on
	# if exists initialize the globalparms array - which would overwrite the initParms from the beginning
	set parmsFile $globalparms(cache_path)[file separator]$globalparms(prepress_parms_file)
	if {[file exists $parmsFile]} {
		# open the file then read in the parms then return
		set channel [open $parmsFile r]
		set dict_parms [read $channel]
		close $channel
		# where item is the returned key
		foreach item [dict keys $dict_parms] {
			# where value is the data returned using key , which is in var item
			set value [dict get $dict_parms $item]
			#puts "key: $item  value: $value"
			set globalparms($item) $value
		}
		set globalparms(first_time) "false"
	}
	##### this ends overwriting the globalparms array
	
	# need to open the printers file for the inkcoverage if it exist
	# will overwrite the initial dict of printers which will be ok
	#   If they where deleted then they will not be precent since this file will be used and the
	#   initial dict of printers are replaced.
	set printersFile $globalparms(cache_path)[file separator]$globalparms(printers_inkcoverage)
	if {[file exists $printersFile]} {
		set channel [open $printersFile r]
		fconfigure $channel -translation lf -encoding utf-8
		set dict_printers [read $channel]
		close $channel
	}
	
	# find tcl version
	.txt insert end "Tclversion: [info patchlevel] Encoding: [encoding system]\n"
	
	# windows fails with the "which" command line app - "where" works for windows
	# windows may need to be manually setup for command line apps
	# WINDOWS ENVIR
	if { $::tcl_platform(platform) eq "windows" } {
		set platform "Windows"
		.txt insert end "starting checkEnvSettings " procColor
		.txt insert end "for $platform\n"
		
		##################### need to find the gs exec #############################
		set gs_location $globalparms(cache_path)[file separator]$globalparms(gs_location_file)
		set cmd_gs "where gswin64c"
		set cmd_gs_error "false"
		if {[catch {exec {*}$cmd_gs > $gs_location} result]} {
			.txt insert end "Error --- at finding $cmd_gs: $result\n"
			set cmd_gs_error "true"
		} else {
			if {[file exists $gs_location]} {
				set channel [open $gs_location r]
				set where_gs [read $channel]
				close $channel
				#puts $where_gs
				if {[string match *gswin64c* "$where_gs"] } {
					.txt insert end "Ghostscript- present. Path: $where_gs" ; # has \n from file read
					set gs "gswin64c"
				} else {
					# means that they could have the 32 bit gs installed or nothing installed
					set cmd_gs_error "true"
				}
			} ; #end of file exists	
		} ; # end of exec catch statement - finding windows gswin64c location 
		if {$cmd_gs_error eq "true"} {
			set cmd_gs "where gswin32c"
			if {[catch {exec {*}$cmd_gs > $gs_location} result]} {
				.txt insert end "Error gswin32c: $result\n"
				set cmd_gs_error "true"
			} else {
				if {[file exists $gs_location]} {
					set channel [open $gs_location r]
					set where_gs [read $channel]
					close $channel
					
					if {[string match *gswin32c* "$where_gs"]} {
						.txt insert end "Ghostscript present. Path: $where_gs" ; # has \n from file read
						set gs "gswin32c"
						set cmd_gs_error false
					} else {
						.txt insert end "Ghostscript not found\n"
						set cmd_gs_error true
						
					}
				}
			} ; # end of gswin32c catch else
		} ; # end of finding if we have gswin32c
		# Ghostscript not available
		# Are disabling all items from menu that are related to gs and utilities such as ps2pdf, pdf2ps
		if {$cmd_gs_error eq "true"} {
			.txt insert end "Ghostscript not installed or not found\n"
			ghostscriptDisable "$platform"
		} else {
			# gs is installed on windows
			set cmd "$gs"
			set cmd_options "-v"
			if {[catch {exec $cmd {*}$cmd_options} result]} {
				.txt insert end "\tError: $result\n"
			} else {
				set i 0
				set lines [split $result "\n"]
				foreach line $lines {
					if {$i eq 0} {
						.txt insert end "\tGhostscript version: $line\n"
					}
					if {$i > 0} {
						.txt insert end "\t$line\n"
					}
					incr i
					
				}
			}
		}
		
		################### need to find the pdf2ps - these just show presence of ps2pdf WINDOWS ##########################
		if {0} {
		set cmd_pdf2ps "where pdf2ps"
		set cmd_pdf2ps_error "false"
		set location_pdf2ps $globalparms(cache_path)[file separator]$globalparms(pdf2ps_location_file)
		set location_pdf2ps [file nativename $location_pdf2ps]
		if {[catch {exec {*}$cmd_pdf2ps > $location_pdf2ps} result]} {
			.txt insert end "\tError at finding $cmd_pdf2ps: $result\n"
			set cmd_pdf2ps_error "true"
		} else {
			if {[file exists $location_pdf2ps]} {
				set channel [open $location_pdf2ps]
				set where_pdf2ps [read $channel]
				close $channel
				puts $where_pdf2ps
				
				if { [string match *pdf2ps* "$where_pdf2ps"] } {
					.txt insert end "\tpdf2ps present Path: $where_pdf2ps"  ; #line from file has \n already
					#set pdf2ps "pdf2ps" ; #same on all plateforms, already defined beginning of script
				} else {
					.txt insert end "\tpdf2ps not found\n"
					set cmd_pdf2ps_error "true"
				}
			} else {
				.txt insert end "\tpdf2ps not found\n"
				set cmd_pdf2ps_error "true"
			}
		}
		} ; #dead code - not using pdf2ps
		
		################ find ps2pdf - these just show presence of ps2pdf WINDOWS ########################################
		if {0} {
		set cmd_ps2pdf "where ps2pdf"
		set cmd_ps2pdf_error "false"
		set location_ps2pdf $globalparms(cache_path)[file separator]$globalparms(ps2pdf_location_file)
		set location_ps2pdf [file nativename $location_ps2pdf]
		if {[catch {exec {*}$cmd_ps2pdf > $location_ps2pdf} result]} {
			.txt insert end "\tError finding $cmd_ps2pdf: $result\n"
			set cmd_ps2pdf_error "true"
		} else {
			if {[file exists $location_ps2pdf]} {
				set channel [open $location_ps2pdf]
				set where_ps2pdf_data [read $channel]
				close $channel
				puts $where_ps2pdf_data
				
				if {[string match *ps2pdf* "where_ps2pdf_data"]} {
					.txt insert end "\tps2pdf present Path: $where_ps2pdf_data" ; # line from file has the \n
				} else {
					.txt insert end "\tps2pdf not found"
					set cmd_ps2pdf_error "true"
				}
			}
		}
		} ; # dead code not using ps2pdf
		
		##### need to get imagemagick to work on windows, try magick instead of convert WINDOWS #################################
		##### windows already has a convert command for the filesystem 
		##### and version 7 uses magick and unless you click to install legacy you will not have convert, composite, etc...
		##### to be safe we will just use as like: magick convert or magick composite
		##### find if version 7 or 6 - version 7 uses magick instead of convert
		
		# Below a temp solution for windows
		# find the magick version number, if it is 6 use convert, if 7 use magick
		# find version 7 then version 6
		set b_magick_7 "false"
		set b_magick_6 "false"
		set b_magick "false"
		set tempFile "$globalparms(cache_path)[file separator]magic-version.txt"
		#set convert "magick -version"
		set cmd_options [list -version]
		
		set cmd_version_min7 "magick -version"
		# if using version 6 copy convert.exe and change name to convert6.exe then copy back into dir
		set cmd_version_6 "convert6" ; # checking for convert however windows has a system convert command
		
		if {[catch {exec $cmd_version_6 {*}$cmd_options > $tempFile} result]} {
			set b_magick_6 "false"
			#.txt insert end "ImageMagick 6: $result\n"
		} else {
			#.txt insert end "$result" ; #when successful there is no value in result
			.txt insert end "ImageMagick present: \n"
			#find the version of composite
			set convert "convert6"
			set b_magick_6 "true"
			set b_magick "true"
			if {[file exists "$tempFile"]} {			
				set fp [open "$tempFile" r] 
				while { [gets $fp data] >= 0 } {
					.txt insert end "\t$data\n"
				}
				close $fp
			}
			if {[file exists "$tempFile"]} {
				#file delete -force "$tempFile"
			}
		}
		if {$b_magick eq "false"} {		
			#set cmd_options [list -version]
			if {[catch {exec {*}$cmd_version_min7 > $tempFile} result]} {
				set b_magick_7 "false"
				#.txt insert end "magick_7 not detected: $result"
			} else {
				set b_magick "true"
				set b_magick_7 "true"
				set b_magick_6 "false"
				set convert "magick"
				#set composite "magick composite"
				#set identify "magick identify"
				 
				.txt insert end "ImageMagick present: \n"
				set fp [open "$tempFile" r]
				while {[gets $fp data] >= 0 } {
					.txt insert end "\t$data\n"
				}
				close $fp
			}
		}
		######################################################## WINDOWS #####
		# the above is the check for the version of ImageMagick
		# and the setting of global convert var defined at beginning of the script
		# At this point in script for windows the convert var has been defined correctly
		# Now we are setting up the location file
		if {$b_magick eq "true"} {
			set convert_location $globalparms(cache_path)[file separator]$globalparms(convert_location_file)
			if {[catch {exec {*}"where $convert" > $convert_location} result]} { 
				.txt insert end "\tmagick location error: $result"
			} else {
				if { [file exists $convert_location] } {
					set channel [open $convert_location r]
					set where_magick [read $channel]
					close $channel
					.txt insert end "\t$convert present. Path: $where_magick" ; # has \n from file read
				} else {
					.txt insert end "\tFailed to get the path to the location of magick.\n"
				}	
			}
		} else {
			.txt insert end "ImageMagick is not installed.\n"
			set b_magick "false"
		}
		## TODO - what if imageMagick is not installed? WINDOWS #################################
		## Make the menu items disabled - Windows       #################################
		if {$b_magick eq "false"} {
			imageMagickDisable $platform
		}
		
		#dead code
		if {0} {
		set cmd_me "where me"
		set cmd_me_error "false"
		set me_tmpfile "me_tmpfile.txt"
		set location_me $globalparms(cache_path)[file separator]$me_tmpfile
		if {[catch {exec {*}$cmd_me > $location_me} result]} {
			.txt insert end "Could not find $cmd_me\n"
			.txt insert end "Result for cmd me: $result\n"
		} else {
			
		}
		} ; # end dead code
		
		set potrace "potrace"
		set cmd_potrace "where potrace"
		
		set potrace_location $globalparms(cache_path)[file separator]$globalparms(potrace_location_file)
		if {[catch {exec {*}$cmd_potrace > $potrace_location} result]} {
			.txt insert end "potrace not found: $result\n"
			.txt insert end "\tpotrace link: https://potrace.sourceforge.net\n"
			potraceDisable $platform
		} else {
			if { [file exists $potrace_location] } {
				set channel [open $potrace_location r]
				set where_potrace [read $channel]
				close $channel
				.txt insert end "potrace present. Path: $where_potrace" ; # has \n from file read
			} else {
				.txt insert end "potrace: Failed to get path or location.\n"
			}
		}
		
		
		## pdfinfo WINDOWS
		set pdfinfo "pdfinfo"
		set cmd_pdfinfo "where pdfinfo"
		set pdfinfo_found "true"
		set pdfinfo_location $globalparms(cache_path)[file separator]$globalparms(pdfinfo_location_file)
		if {[catch {exec {*}$cmd_pdfinfo > $potrace_location} result]} {
			.txt insert end "pdfinfo not found: $result\n"
			set pdfinfo_found "false"
			.txt insert end "\tpdfinfo is part of the poppler utilities: http://poppler.freedesktop.org\n"
			.txt insert end "\thttps://www.xpdfreader.com/download.html - another way to get poppler utilities\n"
		} else {
			if { [file exists $pdfinfo_location] } {
				set channel [open $pdfinfo_location r]
				set where_pdfinfo [read $channel]
				close $channel
				.txt insert end "pdfinfo present. Path $where_pdfinfo" ; # has \n from file read
			} else {
				
				set pdfinfo_found "false"
			}
		}
		if {$pdfinfo_found eq "false"} {
			popplerDisable $platform
		}
		
		## java
		if {[catch {exec {*}"where java"} result]} {
			.txt insert end "java not present. $result\n"
			.txt insert end "\t Cannot run PdfBox\n"
			pdfBoxJarDisable $platform
		} else {
			.txt insert end "java present. Path: $result\n"
			puts "result of 'where java' : $result"
			if {[catch {exec {*}"java --version"} result2]} {
				.txt insert end "java version not found : $result2\n"
			} else {
				.txt insert end "\tVersion: "
				set i 0
				foreach item $result2 {
					if {$i eq 1} {
						set num [split $item "."]
						#puts [lindex $num 0]
						if { [lindex $num 0] > 7 } {		
							#.txt insert end "[lindex $num 0]\n"
							.txt insert end "$item\n"
						} else {
							.txt insert end "$item - Need version 8 or greater to run pdfbox.pdf"
							pdfBoxJarDisable $platform
						}
					}
					incr i
				}
				set lines [split $result2 "\n"]
				foreach line $lines {
					.txt insert end "\t$line\n"
				}
			}
		}
		
		#puts "MAGIC_HOME - \%MAGIC_HOME\%"
		#set cmd_magick_error false
		#set location_convert $
	} else { 
		##################################################################################
		######### HERE linux,unix should operate the same as mac #########################################
		set platform "macOS/Unix"
		.txt insert end "starting checkEnvSettings " procColor
		.txt insert end "for $platform\n"
		
		#make sure dir exists , if exists nothing will happen
		file mkdir $globalparms(cache_path)
		
		#dead code for testing : note , replace 0 with 1 to test
		if {0} {
		set cmd_me "which me"
		set cmd_me_error "false"
		set me_tmpfile "me_tmpfile.txt"
		set location_me $globalparms(cache_path)[file separator]$me_tmpfile
		if {[catch {exec {*}$cmd_me > $location_me} result]} {
			.txt insert end "Could not find $cmd_me\n"
			.txt insert end "Result for cmd me: $result\n" ; # caught 
		} else {
			puts "Not in catch clause on which me" ; # the else did not fire
		}
		} ; # end dead code
		
		########## find gs location MAC or LINUX ############################
		set cmd_gs "which gs"
		set cmd_gs_error "false"
		set gs_location $globalparms(cache_path)[file separator]$globalparms(gs_location_file)
		if {[catch {exec {*}$cmd_gs > $gs_location} result]} {
			#puts $result
			.txt insert end "Error: $result\n"
			set cmd_gs_error "true"
		} else {
			if {[file exists $gs_location]} {
				set channel [open $gs_location r]
				set which_gs [read $channel]
				close $channel
				#puts $which_gs
				if { [string length $which_gs] > 1 } {
					#puts "gs is present"
					.txt insert end "Ghostscript 'gs' present. Path: $which_gs" ; # has \n from file read
				} else {
					.txt insert end "Ghostscript 'gs' cannot be found\n"
					set cmd_gs_error "true"
					
				}
			}
		} ; # end of catch statement - finding gs location
		
		if {$cmd_gs_error eq "true"} {
			ghostscriptDisable "macOS-linux"
		} else {
			if {[catch {exec {*}"gs -v"} result]} {
				.txt insert end "Ghostscript version: Failed\n"
			} else {
				set i 0
				set lines [split $result "\n"]
				#puts "gs: $result"
				foreach line $lines {
					if {$i eq 0} {
						.txt insert end "\tGhostscript version: $line\n"
					}
					if {$i > 0} {
						.txt insert end "\t$line\n"
					}
					incr i
					
				}
				
				if {0} {
				if {[llength $lines] > 0} {
					.txt insert end "\tGhostscript version: [lindex $lines 0]\n"
				}	
				if {[llength $lines] > 0} {
					.txt insert end "\tGhostscript version: [lindex $lines 1]\n"
				}	
				} ; #  dead code
			}
		}
					
		# find pdf2ps
		if {0} {
		set cmd_pdf2ps "which pdf2ps"
		set pdf2ps_location $globalparms(cache_path)[file separator]$globalparms(pdf2ps_location_file)
		if {[catch {exec {*}$cmd_pdf2ps > $pdf2ps_location} result]} {
			.txt insert end "\tpdf2ps not found: Error: $result\n"
		} else {
			
			if {[file exists $pdf2ps_location]} {
				set channel [open $pdf2ps_location]
				set which_pdf2ps [read $channel]
				close $channel
				if {[string length $which_pdf2ps] > 1 } {
					.txt insert end "\t'pdf2ps' present. Path: $which_pdf2ps" 
				} else {
					.txt insert end "\t'pdf2ps' cannot be found.\n"
					
				}
			}
		} 
		} ; # no longer needing pdf2ps
		
		# find ps2pdf
		if {0} {
		set cmd_ps2pdf "which ps2pdf"
		set ps2pdf_location $globalparms(cache_path)[file separator]$globalparms(ps2pdf_location_file)
		if {[catch {exec {*}$cmd_ps2pdf > $ps2pdf_location} result]} {
			.txt insert end "\tps2pdf not found: Error: $result"
		} else {
			if {[file exists $ps2pdf_location]} {
				set channel [open $ps2pdf_location]
				set which_ps2pdf [read $channel]
				close $channel
				if {[string length $which_ps2pdf] > 1 } {
					.txt insert end "\t'ps2pdf' present. Path: $which_ps2pdf" 
				} else {
					.txt insert end "\t'ps2pdf' cannot be found.\n"
				}
			}
		} 
		} ; # dead code not using ps2pdf
		
		########################## magick  - MAC UNIX LINUX ########################
		# find ImageMagick - version 6 uses "convert" command. version 7 uses "magick" command
		# find convert location
		set b_magick_6 "false"
		set b_magick_7 "false"
		set b_magick "false"
		set tempFile "$globalparms(cache_path)[file separator]magic-version.txt"
		
		set cmd_version_min7 "magick -version"  ; # versions 7 or greater uses magick as the command
		set cmd_version_6 "convert -version"    ; # versions 6 or lower uses convert as the command
		
		# New code for finding version of magick
		if {[catch {exec {*}$cmd_version_6 > $tempFile} result]} {
			set b_magick_6 "false"
		} else {
			.txt insert end "ImageMagick present: \n"
			set convert "convert"
			set b_magick "true"
			set b_magick_6 "true"
			if {[file exists "$tempFile"]} {
				set fp [open "$tempFile" r]
				while { [gets $fp data] >= 0 } { 
					.txt insert end "\t$data\n"
				}
				close $fp	
			}
		}
		if {$b_magick eq "false"} {
			if {[catch {exec {*}$cmd_version_min7 > $tempFile} result]} {
				set b_magick_7 "false"
			} else {
				set b_magick_7 "true"
				set b_magick "true"
				set convert "magick"
				.txt insert end "Image-magick present: \n"
				if {[file exists "$tempFile"]} {
					set fp [open "$tempFile" r]
					while { [gets $fp data] >= 0 } {					
						.txt insert end "\t$data\n"
					}
					close $fp
				}
			}
		}
		
		## ImageMagick is installed ; find out where UNIX
		if {$b_magick eq "true"} {
			set cmd_convert "which $convert" ; # $convert if ver 6 is convert if ver 7 is magick
			
			set convert_location $globalparms(cache_path)[file separator]$globalparms(convert_location_file)
			if {[catch {exec {*}$cmd_convert > $convert_location} result]} {	
				.txt insert end "\nError finding path to imagemagick: $result\n"
			} else {
				if {[file exists $convert_location]} {
					set channel [open $convert_location r]
					set which_convert_data [read $channel]
					close $channel
					if { [string length $which_convert_data] > 1 } {
						.txt insert end "\tPath: $which_convert_data" ; # read file which has /n
					} else {
						.txt insert end "\tError: could not read path to $convert\n"
					}
				}
			}
		} else {
			# if here , means ImageMagick not present
			.txt insert end "ImageMagick not present\n"
			imageMagickDisable $platform
		}
		
		
		# find composite location same on both version 6 and 7 UNIX
		set cmd_composite "which composite"
		set composite_location $globalparms(cache_path)[file separator]$globalparms(composite_location_file)
		if {[catch {exec {*}$cmd_composite > $composite_location} result]} {
			.txt insert end "\tError: $result"
		} else {
			if {[file exists $composite_location]} {
				set channel [open $composite_location]
				set which_composite [read $channel]
				close $channel
				if {[string length $which_composite] > 1 } {
					.txt insert end "\t'composite' present. Path: $which_composite" 
				} else {
					# in verison 7 it is magick composite -gravity center smile.gif rose: rose-over.png
					# .txt insert end "\t'composite' cannot be found.\n"
				}
			}
		} ; # end of catch - finding comosite location
		
		# Special
		#if { (($::tcl_platform(user) eq "morpheus") && ($::tcl_platform(os) eq "Darwin")) } {
			puts "passed..."
			puts $::tcl_platform(user)
			set cmd_potrace "which potrace"
			set potrace_location $globalparms(cache_path)[file separator]$globalparms(potrace_location_file)
			if {[catch {exec {*}$cmd_potrace > $potrace_location} result]} {
				.txt insert end "potrace not present: Error: $result\n"
				.txt insert end "\tpotrace link: https://potrace.sourceforge.net\n"
				potraceDisable $platform
			} else {
				if {[file exists $potrace_location]} {
					set channel [open $potrace_location]
					set which_potrace [read $channel]
					close $channel
					if {[string length $which_potrace] > 1 } {
						.txt insert end "potrace present. Path: $which_potrace" 
					} else {
						.txt insert end "potrace cannot be found.\n"
						.txt insert end "\tmenu item: Vectorize .pbm file ... has been disabled"												
					}
				}
			} ; # end of catch - finding potrace location
			##### A TEST pretend that it is not there - BELOW WORKED https://wiki.tcl-lang.org/page/Actions
			#.mbar.vector entryconfigure "Vectorize .pbm file ..." -state disabled
		#} ; # end of if - for special me
		
		# find potrace location UNIX
		#set cmd_potrace "which potrace"
		#set potrace_location $globalparms(cache_path)[file separator]$globalparms(potrace_location_file)
		#if {[catch {exec {*}$cmd_potrace > $potrace_location} result]} {
		#	.txt insert end "Error: $result"
		#} else {
		#	if {[file exists $potrace_location]} {
		#		set channel [open $potrace_location]
		#		set which_potrace [read $channel]
		#		close $channel
		#		if {[string length $which_potrace] > 1 } {
		#			.txt insert end "Imagemagick 'potrace' present. Path: $which_potrace" 
		#		} else {
		#			.txt insert end "Imagemagick 'potrace' cannot be found.\n"
		#		}
		#	}
		#} ; # end of catch - finding potrace location
		## pdfinfo
		set pdfinfo "pdfinfo"
		set cmd_pdfinfo "which pdfinfo"
		set pdfinfo_found "true"
		set pdfinfo_location $globalparms(cache_path)[file separator]$globalparms(pdfinfo_location_file)
		if {[catch {exec {*}$cmd_pdfinfo > $pdfinfo_location} result]} {
			.txt insert end "pdfinfo not found: $result\n"
			set potrace_found "false"
		} else {
			if { [file exists $pdfinfo_location] } {
				set channel [open $pdfinfo_location r]
				set where_pdfinfo [read $channel]
				close $channel
				.txt insert end "pdfinfo present. Path: $where_pdfinfo" ; # has \n from file read
			} else {
				set pdfinfo_found "false"
			}
		}
		if {$pdfinfo_found eq "false"} {
			popplerDisable $platform
			.txt insert end "\tpdfinfo: failed to get path or location. Not installed.\n"
			.txt insert end "\tpdfinfo: utilities from poppler; http://poppler.freedesktop.org\n"
		}
		
		## java
		if {[catch {exec {*}"which java"} result]} {
			.txt insert end "java not present. $result\n"
			.txt insert end "\t Cannot run PdfBox\n"
			pdfBoxJarDisable $platform
		} else {
			.txt insert end "java present. Path: $result\n"
			if {[catch {exec {*}"java --version"} result]} {
				.txt insert end "java version not found : $result\n"
			} else {
				.txt insert end "\tVersion: "
				set i 0
				foreach item $result {
					if {$i eq 1} {
						set num [split $item "."]
						#puts [lindex $num 0]
						if { [lindex $num 0] > 7 } {		
							#.txt insert end "[lindex $num 0]\n"
							.txt insert end "$item\n"
						} else {
							.txt insert end "$item - Need version 8 or greater to run pdfbox.pdf"
							pdfBoxJarDisable $platform
						}
					}
					incr i
				}
				set lines [split $result "\n"]
				foreach line $lines {
					.txt insert end "\t$line\n"
				}
				
				
				if {0} {
				if {[llength $lines > 0]} {
					.txt insert end "\t[lindex $lines 0]"
				}
				if {[llength $lines > 1]} {
					.txt insert end "\t[lindex $lines 1]"
				}
				if {[llength $lines > 2]} {
					.txt insert end "\t[lindex $lines 2]"
				}
				} ; #dead code
			}
		}
		
	} ; # end fo else - must be unix - or mac
	
	# if there is an int file then load it from disk
	set dict_parms [dict create]
	#set channel [open $parmsFile w]
	foreach {name value} [array get globalparms] {
		puts "Global Parms: $name : $value"
		dict set dict_parms $name $value 
	}
	set channel [open $parmsFile w]
	puts $channel $dict_parms
	close $channel
	
	# END of Common to all
	
}
# Purpose: To disable menu items if commands cannot be found on system
#			Ghostscript, Imagemagick, potrace and utilities
#			proc ghostscriptDisable, imageMagickDisable, potraceDisable
# Purpose2: to enable or disable menu items such as to wrap or unwrap text - toggle the states
## DISABLE MENUS
proc ghostscriptDisable {varOS} {
	.mbar.convert entryconfigure [msgcat::mc "m_openPDFtoTiff"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openImageCreatePDF"] -state disable ; # this proc needs both gs and magick
	.mbar.convert entryconfigure [msgcat::mc "m_openPSCreatePDF"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openPDFCreatePS"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openPDFCreateGrayscalePDF"] -state disable
	.mbar.identify entryconfigure [msgcat::mc "m_openImagePdfEpsInfoSummary"] -state disable
	.mbar.identify entryconfigure [msgcat::mc "m_openImagePdfEpsInfoAll"] -state disable
	.mbar entryconfigure [msgcat::mc "m_Inkcoverage"] -state disable
	puts "OS: $varOS : Ghostscript not present"
} 
proc imageMagickDisable {varOS} {
	.mbar.convert entryconfigure [msgcat::mc "m_openImagetoMono"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openTIFFandInvert"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openTIFFandSwell"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openImageFlipHorizontal"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openImageFlipVertical"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openDirBatchScaleImgs"] -state disable
	.mbar.convert entryconfigure [msgcat::mc "m_openImageCreatePDF"] -state disable ; # this proc needs both gs and magick
	.mbar.identify entryconfigure [msgcat::mc "m_openImagePdfEpsInfoAll"] -state disable
	.mbar.identify entryconfigure [msgcat::mc "m_openImagePdfEpsInfoSummary"] -state disable
	.mbar.vector entryconfigure [msgcat::mc "m_openImageCreatePBM"] -state disable
	.mbar.vector entryconfigure [msgcat::mc "m_openBitmapPBMCreatePS"] -state disable ; # this proc needs both potrace and magick
	puts "OS: $varOS : ImageMagick not present"
}
proc potraceDisable {varOS} {
	.mbar.vector entryconfigure [msgcat::mc "m_openBitmapPBMCreatePS"] -state disable ; # this proc needs both potrace and magick
	puts "OS: $varOS : potrace not present"
}
proc popplerDisable {varOS} {
	.mbar.identify entryconfigure [msgcat::mc "m_openPdfPsPdfinfo"] -state disable
	puts "OS: $varOS : pdfinfo not present"
}
proc pdfBoxJarDisable {varOS} {
	.mbar.identify entryconfigure [msgcat::mc "m_openPdfBoxJar"] -state disable
	puts "OS: $varOS : pdfbox.jar or java 8 or above not present"
}
proc wrapLinesDisable {} {
	.mbar.files entryconfigure [msgcat::mc "m_WrapLines"] -state disable
}
proc wrapLinesEnable {} {
	.mbar.files entryconfigure [msgcat::mc "m_WrapLines"] -state normal
}
proc unwrapLinesDisable {} {
	.mbar.files entryconfigure [msgcat::mc "m_UnWrapLines"] -state disable
}
proc unwrapLinesEnable {} {
	.mbar.files entryconfigure [msgcat::mc "m_UnWrapLines"] -state normal
}

# Purpose: Menu command and when app quits
proc quit {} {
	# save options and defaults
	global globalparms
	
	set parmsFile $globalparms(cache_path)[file separator]$globalparms(prepress_parms_file)
	set dict_parms [dict create]
	foreach {name value} [array get globalparms] {
		puts "Global Parms: $name : $value"
		dict set dict_parms $name $value 
	}
	set channel [open $parmsFile w]
	puts $channel $dict_parms
	close $channel
	
	exit
}

# WINDOWS ready
# Purpose: Menu command
# Ghostscript command
# Fixed for windows 2-26-23, 8-2-23 and tested
proc openPDFtoTiff {} {
	#open a message box for the dpi
	global LINE
	global gs
	global dpi
	global globalparms
	#set reply [tk_dialog .dlg_dpi "Current dpi Setting" "Current DPI is set to: $dpi \n Proceed? " \
	#	questhead 0 Yes No ]
	#if {$reply eq "1"} {return}
	#.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openPDFtoTiff" procColor
	.txt insert end "\n"
	.txt insert end "This will separate pdf, eps, or ps into cmyk plus spot \n\stand create 4 separated tiff grayscale files\n"
	.txt insert end "If the file is a rgb color model, it will converted to cmyk and separated.\n"
	.txt insert end "The original file will be left unchanged.\n"
	.txt insert end "The resolution will be based on global dpi settings\n"
	.txt insert end "For line art 1200 dpi is preferred.\n"
	.txt insert end "This is especially true for type and the making printing plates.\n"
	.txt insert end "Current DPI set to: $globalparms(dpi). \n"
	
	set message "Current DPI set to: $globalparms(dpi) \n Proceed with PDF to tiff separations?"
	set reply [tk_messageBox -parent . -message $message \
		 -icon question -type yesno]
	if {$reply eq "no"} {
		.txt insert end "This action has been canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set types {
		{Files {.pdf .eps .ps}}
		{PDF .pdf}
		{EPS .eps}
		{PS .ps}	
	}
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "proc canceled...\n"
		.txt insert end "$LINE" lineColor
		return
	}
	
	.txt insert end "Opened: $filename\n"
	
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension or dir
	set filedir [file dir $filename] ;                   #returns the path without the tailing /
	set fullpathdir_sep "$filedir[file separator]$fileroot-separated-tiffs" ; # need and new dir to contain all created files
	set fullpathdir_sep [file nativename $fullpathdir_sep]
	# make sure the directory exists or create one
	if {![file isdirectory $fullpathdir_sep]} {
		file mkdir $fullpathdir_sep
	}
	
	########## discovered that using exec from tcl you don't need the path escaped as in a shell
	#set escaped_outputFile [escapePath "$fullpathdir_sep[file separator]$fileroot-p%03d-gs.tiff"] ; #escapes spaces in path and filename
	# make an outputFile for testing not escaped
	set outputFile "$fullpathdir_sep[file separator]$fileroot-p%03d-gs.tiff"
	set outputFile [file nativename $outputFile] ; # normalize using windows and not escaped
	
	###set escaped_filename [escapePath $filename] ;         # escaped path and filename of file to be separated NOT USING
	set filename [file nativename $filename] ;   # normalize using windows and not escaped
	
	######## tested on windows
	########for windows had to change out  >>& /dev/tty
	set cmd1_options [list -dNOSAFER -dNOPAUSE -sDEVICE=tiffsep -r$globalparms(dpi) -sOutputFile=$outputFile $filename -c quit]
	.txt insert end "Command executed: $gs\n"
	.txt insert end "Options: $cmd1_options\n"
	if {[catch {exec $gs {*}$cmd1_options} result]} {
		.txt insert end "Error: $result\n" errorColor
		.txt insert end "$LINE" lineColor
		#return
	} else {
		.txt insert end "Result: $result\n"
	}
	# make a temp directory without file name that is native to os
	set filedirNormalized [file nativename $filedir]
	.txt insert end "Directory Opened: "
	.txt insert end "$filedirNormalized" dirHyperlink
	.txt insert end "\n"
	.txt insert end "Directory Created: "
	.txt insert end "$fullpathdir_sep" dirHyperlink
	.txt insert end "\n"
	.txt insert end "Files Created:\n"
	# for gui try sending info to file - works
	# exec {*}$cmd1 >>& ~/.convert-output.txt
	
	# need to rename files to make them cmd line safe for imagemagick
	# take out spaces and ( !
	#set files [glob -nocomplain -dir $fullpathdir_sep *(*]
	set files [glob -nocomplain -dir $fullpathdir_sep *gs*]
	foreach f $files {
		# need to separate dir from the filename
		# rename the file not the directory
		set newfile_root [file rootname [file tail $f]] ; #returns file no extension or dir
		set newfile_ext [file extension $f]
		set newfiledir [file dir $f]
		
		#     - done so don't have file ending like myfile-yellow-.tiff
		#     instead will be like myfile-yellow.tiff
		#     2-19-17 Popple
		set newfilename_root [string map -nocase {
		">" "-"
		"<" "-"
		"(" "-"
		")" ""
		"=" "-"
		"?" "-"
		"'" ""
		"!" ""
		":" "-"
		"," ""
		"'" ""
		"&lsquo;" ""
		" " "-"
		} $newfile_root]

		set newfilename "$newfiledir[file separator]$newfilename_root$newfile_ext"	
			
		if {[file exists $newfilename]} {
			# some files such test-p100-gs.tiff will be overwritten so delete them rename
			#file delete -force $newfilename
			#note: did not have to delete to rename , using force did it
			#      this must be the 2nd time to separate the file because the new name is already there
			#      Need to overwrite this file with the newest one
			file rename -force $f $newfilename
			#.txt insert end "Renamed file to: $newfilename_root$newfile_ext\n"
		} else {
			# it is a new name - and has not been renamed yet
			# the var f would be the name generated the first time by ghostscript
			file rename -force $f $newfilename
			#.txt insert end "\nRenamed file that did not exist?: $newfilename_root$newfile_ext\n\n"
		}
	} ; #end foreach for files and making filenames compatible with imagemagick
		
	# older ghostscript versions will create .tif files and not .tiff files
	# under linux cannot see all the files unless selected under file types
	# so make all the file extensions .tiff
	set files [glob -nocomplain -dir $fullpathdir_sep *.tif*]
	set i 0 ;  # helper to get out of loop
	foreach f $files {
		# need to separate dir from the filename
		# rename the file not the directory
		set newfile_root [file rootname [file tail $f]] ; #returns file no extension or dir
		set newfile_ext [file extension $f]
		set newfiledir [file dir $f]
		set change_ext ""
		set changedfilename ""
		
		# change the .tif extension to .tiff
		if { [string match $newfile_ext ".tif" ] } {
			set change_ext ".tiff"
			incr i
		}
		if { [string match $change_ext ".tiff"] } {
			# resemble the full path and filename
			set changedfilename "$newfiledir[file separator]$newfile_root$change_ext"
			#puts $changedfilename
			if { $i eq 1 } { .txt insert end "Renaming Files from .tif to .tiff:\n" }
			# rename file with new extension
			file rename -force $f $changedfilename
			.txt insert end "$changedfilename\n"
		}		
	}
	#need sorted file names returned to display in the text widget
	#glob returns a list
	set files [glob -nocomplain -dir $fullpathdir_sep *-gs*]
	set sortedfiles [lsort -increasing $files]
	foreach f $sortedfiles {
		set newfile_root [file rootname [file tail $f]] ; #returns file no extension or dir
		set newfile_ext [file extension $f]
		set filename "$newfile_root$newfile_ext"
		.txt insert end "$filename\n"
		
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "\n"
}
# Convert the tiff to mono .pbm file to create bilevel 1 bit file
# Then convert that .pbm file back to tiff
# menu command
# imagemagick command convert
# added png, jpeg, jpg on 4/21/22
# changed/tested for windows - using tcl List in the command options - 2/27/23
# mark openImageMono {}
proc openImagetoMono {} {
	global LINE
	global globalparms
	global convert
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
		{pgm .pgm}
		{ppm .ppm}
	}
	.txt insert end $LINE lineColor
	.txt insert end "proc: openImagetoMono" procColor
	.txt insert end "\n"
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "proc canceled...\n"
		.txt insert end "$LINE" lineColor
		return
	} ; #When cancel is pressed
	set filename [file nativename $filename] ; #for windows especially over the network
	.txt insert end "Opened $filename for covert to mono...\n"
	set fileroot [file rootname [file tail $filename]]; #returns file no extension or dir
	set filedir [file dir $filename] ;                  #returns path without trailing /
	set outputFilePBM "$filename-bit.pbm"
	
	# because of IM 7 the input file needs to be before the options and switches
	#set cmd "convert -density $globalparms(dpi) -threshold 50% $escaped_filename $escaped_outputFile"
	set cmd_options [list $filename -density $globalparms(dpi) -threshold 50% -compress none $outputFilePBM]
	.txt insert end "cmd: $convert\n"
	.txt insert end "options: $cmd_options\n"
	if {[catch {exec $convert {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "mono tiff file not created\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "File created: [file tail $outputFilePBM]\n"
	}
	
	# Create mono tiff from pbm
	#set outFileTIFF "$filedir[file separator]$fileroot-bit.tiff"
	set outFileTIFF "$outputFilePBM.tiff"
	
	update idletasks
	
	set cmd_options [list $outputFilePBM -units PixelsPerInch -density $globalparms(dpi) $outFileTIFF]
	.txt insert end "2nd cmd: $convert\n"
	.txt insert end "2nd options: $cmd_options\n"
	
	if {[catch {exec $convert {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "File created: [file tail $outFileTIFF]\n"
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	#set cmd2 "convert -units PixelsPerInch -density $globalparms(dpi) $escaped_outputFile $escaped_filename_tiff"	
	#exec {*}$cmd2 >>& /dev/tty
}
# menu command WINDOWS READY
# imagemagick command convert
# added png, jpeg, jpg on 4-21-22
# windows compatible 8-16-23
proc openTIFFandInvert {} {
	#invert image
	global LINE
	global globalparms
	global convert
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
	}
	.txt insert end $LINE lineColor
	.txt insert end "proc: openTIFFandInvert" procColor
	.txt insert end "\n"
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return} ; #When cancel is pressed
	set filename [file nativename $filename] ; #for windows especially over the network
	.txt insert end "Opened $filename for covert to invert image...\n"

	set fileroot [file rootname [file tail $filename]]; #returns file no extension or dir
	set filedir [file dir $filename] ;                  #returns path without trailing /
	set outputFile "$filedir[file separator]$fileroot-inverted.tiff" ; # New output file

	#set cmd "convert -negate $escaped_filename $escaped_outputFile"
	#set cmd_options [list -negate $filename $outputFile]
	set cmd $convert
	set cmd_options [list $filename -negate $outputFile]  ; #changed for windows and the use of magick in version 7
	.txt insert end "cmd: $cmd\n"
	.txt insert end "options: $cmd_options\n"
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "inverted tiff file not created\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
}
# menu command - WINDOWS READY
# Find the Edge and swell inside and out of the edge - 1 pix is 1 on each side
# mac linux: cmd convert, composite
# fix for windows 8-2-23 use command options with the command and put in globals
# 	take out >>& because windows does not understand it and use list command
#   put in more image formats
#	take out the escaping of paths since tcl does not need them , the unix shell does
# Use this instead of convert -edge 1 (8/16/23)
#	set cmd_options [list $filename -morphology Edge Diamond -negate $outputFile]
#   Diamond - kernel is a square (2 times radius plus 1) containing the diamond shape. https://www.imagemagick.org/Usage/morphology/#diamond
#             Example : (default is 1 and the smallest size of all kernels - 1px each side of edge)
#                        for r in 1 2 3 4; do
#                           magick pixel.gif -morphology Dilate Diamond:$r -scale 800% k_diamond:$r.gif
#                        done
# Imagemagick
proc openTIFFandSwell {} {
	global LINE
	global globalparms
	global convert
	global composite
	global b_magick_6
	set types {
		{Files {.tiff .tiff .png .jpeg .jpg .pgm .ppm}}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{jpeg .jpeg}
		{jpg .jpg}
		{pgm .pgm}
		{ppm .ppm}	
	}
	.txt insert end $LINE lineColor
	.txt insert end "proc: openTIFFandSwell" procColor
	.txt insert end "\n"
	.txt insert end "This proc will swell edges for tiff, png, jpeg, pgm, and ppm formats\n"
	.txt insert end "   A setting of 1 is the smallest swell, and takes the least time to process.\n"
	.txt insert end "   The higher the swell setting the longer it takes to process the image.\n"
	
	set msg "The stroke on the swell is set to $globalparms(set_swell).\n \
			Is this Ok?"
	set reply [tk_messageBox -parent . -message $msg -icon question -type yesno]
	#set reply [tk_messageBox -parent . -message $msg -type yesno]
	if {$reply eq "no"} {
		.txt insert end "This action has been canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return}
	set filename [file nativename $filename] ; #for windows especially over the network
	.txt insert end "Opened: [file tail $filename] for convert to edge detection and swell...\n"
	
	set fileroot [file rootname [file tail $filename]]; #returns file no extension or dir
	set filedir [file dir $filename] ;                  #returns path without trailing /
	#set escaped_outputFile [escapePath "$filedir[file separator]$fileroot-swell.png"] ; #escape spaces in path and filename
	#set escaped_filename [escapePath $filename] ; # escaped path and filename
	#set escaped_compositeFile [escapePath "$filedir[file separator]$fileroot-swell-comp.tiff"]
	#set cmd "convert $escaped_filename \( +clone -negate \) -edge 1 -compose add -composite -negate $escaped_outputFile"
	set outputFile "$filedir[file separator]$fileroot-swell.png"
	set compositeFile "$filedir[file separator]$fileroot-swell-comp.tiff"
	set cmd $convert
	#set cmd_options [list $filename ( +clone -negate ) -edge 1 -compose add -composite -negate $outputFile] ; #works on mac not pc magick 7
	#set cmd_options [list $filename -canny 0x1x10%+30% -negate $outputFile] ; #new - fair job
	#set cmd_options [list $filename -negate -edge 2 -negate $outputFile] ; #finds edge but no swell
	# The "-morphology" operator (basic methods) and the initial set of kernels was added to ImageMagick version 6.5.9-0 by myself, while I was on a vacation in China. December 2009 to January 2010.
	set cmd_options [list $filename -morphology Edge Diamond:$globalparms(set_swell) -negate $outputFile] ; # new ; best; https://www.imagemagick.org/Usage/morphology/#edge
	# changing the morphology to allow for 4 settings of thickness
	#set cmd_options [list $filename -morphology Dilate Diamond:$globalparms(set_swell) $outputFile]
	.txt insert end "cmd: $cmd\n"
	.txt insert end "cmd_options: $cmd_options\n"
	.txt insert end "expression: inputfile -morphology Dialage Diamond:$globalparms(set_swell) outputfile\n"
	update idletasks
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		#.txt insert end "Intermediate png file not created\n"
		.txt insert end "Directory: "
		.txt insert end "$filedir" dirHyperlink
		.txt insert end "\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "Intermediate File created: [file tail $outputFile]\n"
		# .txt insert end "\n$result\n\n" ; # Nothing in result if successful
	}
	#update idletasks
	#exec {*}$cmd >>& /dev/tty

	#composite the outline png with the original file
	if {$b_magick_6 eq "true"} {
		set cmd2 "$composite"
		set cmd2_options [list $outputFile -compose Multiply -gravity center $filename $compositeFile]
		set expression "outputfile-from-previous -compose Multiply -gravity center origfile outputCompositefile\n"
	} else {
		# it is version 7 : composite is now an option and not a separate command
		set cmd2 "$convert"
		set cmd2_options [list $composite $outputFile -compose Multiply -gravity center $filename $compositeFile]
		set expression "$composite outputfile-from-previous -compose Multiply -gravity center origfile outputCompositefile\n"
	}
	
	#set cmd2_options [list -compose Multiply -gravity center $outputFile $filename $compositeFile] ; #orig
	#set cmd2 "composite -compose Multiply -gravity center $escaped_outputFile $escaped_filename $escaped_compositeFile"
	.txt insert end "cmd2: $cmd2\n"
	.txt insert end "cmd2_options: $cmd2_options\n"
	.txt insert end "expression: $expression\n"
	if {[catch {exec $cmd2 {*}$cmd2_options} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "Composite file not created\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "Composite File created: [file tail $compositeFile]\n"
		
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	#update idletasks
	#exec {*}$cmd2 >>& /dev/tty
	
}
# menu command
# Flip Image Horizontal Direction
# mac linux: cmd convert
# Imagemagick - WINDOWS ready 8/22/23
proc openImageFlipHorizontal {} {
	global LINE
	global globalparms
	global convert
	set types {
		{Files {.tiff .tif .png .gif .jpeg .jpg}}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{GIF .gif}
		{JPEG .jpeg}
		{JPG .jpg}
	}
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return}
	set filename [file nativename $filename] ; #for windows especially over the network
	.txt insert end "Opened $filename\n\t to flip image in Horizontal Direction...\n"
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension of dir
	set fileext [file extension [file tail $filename]] ; #returns file extension
	set filedir [file dir $filename] ;                   #returns path without trailing /
	#set escaped_outputFile [escapePath "$filedir[file separator]$fileroot-horz$fileext"] ; #escape spaces in dir and filename
	#set escaped_filename [escapePath $filename] ; # escape spaces in dir and filename
	set outputFile "$filedir[file separator]$fileroot-horz$fileext"
	
	set cmd "$convert"
	set cmd_options [list $filename -flop $outputFile]
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "File not created\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"
		.txt insert end "Directory: "
		.txt insert end "$filedir" dirHyperlink
		.txt insert end "\n"
		.txt insert end "$LINE" lineColor
	}
	
	#set cmd "convert -flop $escaped_filename $escaped_outputFile"
	#.txt insert end "cmd: $cmd \n"
	#.txt insert end "New File: [file rootname [file tail $escaped_outputFile]][file extension [file tail $escaped_outputFile]]\n" 
	#exec {*}$cmd >>& /dev/tty
	
}
# menu command
# Flip the image vertical - not rotate
# mac linux: cmd convert
# Imagemagick - Windows ready 8/22/23
proc openImageFlipVertical {} {
	global convert
	global globalparms
	global LINE
	set types {
		{Files {.tiff .tif .png .gif .jpeg .jpg}}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{GIF .gif}
		{JPEG .jpeg}
		{JPG .jpg}
	}
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return} ; #When Cancel is pressed
	set filename [file nativename $filename] ; #for windows especially over the network
	.txt insert end "Opened $filename\n\t to flip image in Vertical Direction...\n"
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension of dir
	set fileext [file extension [file tail $filename]] ; #returns file extension
	set filedir [file dir $filename] ;                   #returns path without trailing /
	#set escaped_outputFile [escapePath "$filedir[file separator]$fileroot-vert$fileext"] ; #escape spaces
	#set escaped_filename [escapePath $filename] ; # escape dir and filename
	set outputFile "$filedir[file separator]$fileroot-vert$fileext"
	set cmd "$convert"
	set cmd_options [list $filename -flip $outputFile]
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "File not created\n"
		.txt insert end "$LINE" lineColor
		return
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"	
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	#set cmd "convert -flip $escaped_filename $escaped_outputFile"
	#.txt insert end "cmd: $cmd \n"
	#.txt insert end "New File: [file rootname [file tail $escaped_outputFile]][file extension [file tail $escaped_outputFile]]\n" 
	#exec {*}$cmd >>& /dev/tty
}
# Open Directory and batch scale - 
# 11-3-23 Fixed network path windows [file nativename $filename]
# Imagemagick convert Windows Ready 8/22/23
proc openDirBatchScaleImgs {} {
	global globalparms
	global convert
	global LINE
	set msg "Current settings:\n \
		DPI: $globalparms(dpi_batch)\n \
		Pixel Max length: $globalparms(pixel_w_batch)\n \
		Quality (jpg only): $globalparms(quality_batch)"
		
	.txt insert end $LINE lineColor
	.txt insert end "proc: openDirBatchScaleImgs" procColor
	.txt insert end "\n"
	
	set reply [tk_messageBox -parent . -message $msg \
				   -icon question -type yesno]
	if {$reply eq "no"} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	
	set dirname [tk_chooseDirectory]
	if {$dirname eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	
	set dirname [file nativename $dirname] ; # make sure windows over a network works
	
	#need new directory called resized
	set pathResizedDir "$dirname[file separator]resized"
	# check if dir exists or create one
	if {![file isdirectory $pathResizedDir]} {
		file mkdir $pathResizedDir
	}
	# go through dir looking for images to scale
	set files [glob -dir $dirname *.*]
	foreach f $files {
		# check file extensions
		
		set ext_orig [file extension [file tail "$f"]] ; #returns file extension
		set ext_orig_lcase ""
		set ext_orig_lcase [string map -nocase {jpeg jpg tiff tif png png} $ext_orig]
		
		if {$ext_orig_lcase eq ".jpg"} {
			set root_filename [file rootname [file tail $f]] ; #returns file no extension or dir
			set output_path_filename "$pathResizedDir[file separator]$root_filename.jpg"
			#set escaped_output_path_filename [escapePath $output_path_filename] ; # file to be created
			#set escaped_orig_path_filename [escapePath $f] ; # file to be scaled
			set orig_path_filename "$f"
			set cmd "$convert"
			set cmd_options [list $orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) -quality $globalparms(quality_batch) $output_path_filename]
			if {[catch {exec $cmd {*}$cmd_options} result]} {
				.txt insert end "Error: $result\n"	
			} else {
				.txt insert end "File created: [file tail $output_path_filename]\n"	
			}
			
			#set cmd "convert $escaped_orig_path_filename -resize 1200x1200 -density 300 -quality 100 $escaped_output_path_filename"
			#set cmd "convert $escaped_orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) -quality $globalparms(quality_batch) $escaped_output_path_filename"
			#exec {*}$cmd >>& /dev/tty 
		}
		if {$ext_orig_lcase eq ".tif"} {
			set root_filename [file rootname [file tail $f]] ; #returns file no extension or dir
			set output_path_filename "$pathResizedDir[file separator]$root_filename.tiff"
			#set escaped_output_path_filename [escapePath $output_path_filename] ; # file to be created
			#set escaped_orig_path_filename [escapePath $f] ; # file to be scaled
			set orig_path_filename "$f"
			
			set cmd "$convert"
			set cmd_options [list $orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) -quality $globalparms(quality_batch) $output_path_filename]
			if {[catch {exec $cmd {*}$cmd_options} result]} {
				.txt insert end "Error: $result\n"	
			} else {
				.txt insert end "File created: [file tail $output_path_filename]\n"	
			}
			
			#set cmd "convert $escaped_orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) -quality $globalparms(quality_batch) $escaped_output_path_filename"
			#exec {*}$cmd >>& /dev/tty
		}
		if {$ext_orig_lcase eq ".png"} {
			set root_filename [file rootname [file tail $f]] ; #returns file no extension or dir
			set output_path_filename "$pathResizedDir[file separator]$root_filename.png"
			#set escaped_output_path_filename [escapePath $output_path_filename] ; # file to be created
			#set escaped_orig_path_filename [escapePath $f] ; # file to be scaled
			set orig_path_filename "$f" 
			
			set cmd "$convert"
			set cmd_options [list $orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) -quality $globalparms(quality_batch) $output_path_filename]
			if {[catch {exec $cmd {*}$cmd_options} result]} {
				.txt insert end "Error: $result\n"	
			} else {
				.txt insert end "File created: [file tail $output_path_filename]\n"	
			}
			
			#set cmd "convert $escaped_orig_path_filename -resize $globalparms(pixel_w_batch)x$globalparms(pixel_w_batch) -density $globalparms(dpi_batch) $escaped_output_path_filename"
			#exec {*}$cmd >>& /dev/tty
		}
		
	} ; # end of foreach
	.txt insert end "Directory Originals: "
	.txt insert end "$dirname" dirHyperlink
	.txt insert end "\n"
	.txt insert end "Directory Resized: "
	.txt insert end "$pathResizedDir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
}
# Open Image and create PDF - WINDOWS ready
# Creates image to PDF version 1.3 using imagemagick
# Use ghostscript to convert version 1.3 to 1.4 pdf
# Ghostscript for pdf gs
proc openImageCreatePDF {} {
	global gs
	global convert
	global LINE
	set types {
		{Files {.tiff .tif .png .gif .jpeg .jpg}}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{GIF .gif}
		{JPEG .jpeg}
		{JPG .jpg}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openImageCreatePDF\n" procColor
	.txt insert end "This action will convert an image into a pdf and then convert that pdf to a 1.4 pdf version\n"
	.txt insert end "There are certain RIPS that need 1.4 version of the pdf in order to render correctly.\n"
	.txt insert end "Especially platemakers that output plates for the offset or film for the letterpress.\n\n"
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set filename [file nativename $filename] ; # for windows over the network
	.txt insert end "Opened [file tail $filename] to convert to PDF...\n"
	 
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension of dir
	set fileext [file extension [file tail $filename]] ; #returns file extension - however don't need since changing to pdf
	set filedir [file dir $filename] ;                   #returns path without trailing /
	#set escaped_outputFile [escapePath "$filedir[file separator]$fileroot.pdf"] ; #escape spaces
	#set escaped_filename [escapePath $filename] ; # escape dir and filename
	set outputFile "$filedir[file separator]$fileroot.pdf"
	set outputFile [file nativename $outputFile] ; # normalize using windows and not excaped
	
	#imagemagick convert - Problem with updated imagemagick which automatically creates pdf which is not 1.4
	# since dealing with images imagemagick works, later will covert the pdf to the 1.4 version
	# 
	#set cmd "convert $escaped_filename -quality 100 $escaped_outputFile"
	#.txt insert end "cmd: $cmd \n"
	#.txt insert end "New File: [file rootname [file tail $escaped_outputFile]][file extension [file tail $escaped_outputFile]]\n"
	update idletasks
	set cmd "$convert"
	
	set cmd_options [list $filename -flatten -quality 100 $outputFile] ; # flatten added 11-1-23
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"
	}
	#exec {*}$cmd >>& /dev/tty
	
	# Problem with updated imagemagick which automatically creates 1.3 pdf which Xante Impressia will not accept
	# Need to make the pdf 1.3 to 1.4 compatable
	.txt insert end "Create a PDF version 1.4 \n"
	set ver1_4PDFFile "$filedir[file separator]$fileroot-ver1_4.pdf"
	set cmd2 "$gs"
	#set cmd2_options [list -sDEVICE=pdfwrite -sPAPERSIZE=letter -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $ver1_4PDFFile $outputFile]	
	#set cmd2_options [list -sDEVICE=pdfwrite -dEPSCrop -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $ver1_4PDFFile $outputFile]
	set cmd2_options [list -sDEVICE=pdfwrite -dPDFX -sColorConversionStrategy=CMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $ver1_4PDFFile $outputFile]
	if {[catch {exec $cmd2 {*}$cmd2_options} result]} {
		.txt insert end "Pdf version 4 not created\n"
		.txt insert end "Error: $result\n"	
	} else {
		#.txt insert end "gs result: $result\n" ; # gs does not give any feed back on this step
		.txt insert end "File created: [file tail $ver1_4PDFFile]\n"
	}
	.txt insert end "Directory containing files: \n"
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	#set cmdPdf "$gs -sDEVICE=pdfwrite -sPAPERSIZE=letter -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $escaped_ver1_4_PDFFile $escaped_outputFile"
	#set cmdPdf "gs -sDEVICE=pdfwrite -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $escaped_ver1_4_PDFFile $escaped_outputFile"
	#exec {*}$cmdPdf >>& /dev/tty
	#.txt insert end $cmdPdf
	
	#####below old code did not work even on macOS
	# try gs to convert to pdf - did not work with .tiff image files.
	# may work with eps, ps files
	# https://www.ghostscript.com/doc/current/Use.htm#PDF
	#set cmd "gs -sDEVICE=pdfwrite -o gs-$escaped_outputFile $escaped_filename -c"
	#exec {*}$cmd >>& /dev/tty
	#.txt insert end "cmd: $cmd \n"
	
}
# openPSCreatePDF - WINDOWS READY
# Arg none
# Returns none
# Will open PS files and create high resolution PDF
proc openPSCreatePDF {} {
	global gs
	global ps2pdf
	global LINE
	set types {
		{PS .ps}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "procPSCreatePDF\n" procColor
	set introVar "Opens a postscript file (.ps) and creates a 1.4 version PDF file\n"
	.txt insert end $introVar
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set filename [file nativename $filename] ; # for windows over the network
	.txt insert end "Opened [file tail $filename] for converting PS to PDF...\n"

	set fileroot [file rootname [file tail $filename]] ; #return file no extension of dir
	set filedir [file dir $filename] ; #returns the path without the tailing /
	set outputFile "$filedir[file separator]$fileroot.pdf" 
	set outputFile [file nativename $outputFile]
	
	#Worked on mac very well - below - but not on windows
	#set cmd "$ps2pdf"	
	#set cmd_options [list -dEPSCrop -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $filename $outputFile]
	
	#test - cropped it wrong 
	#set cmd "$ps2pdf"
	#set cmd_options [list $filename $outputFile]
	
	set cmd "$gs"
	set cmd_options [list -o $outputFile -sDEVICE=pdfwrite -sProcessColorModel=DeviceCMYK -dCompatibilityLevel=1.4 -dEPSCrop -f $filename]
	
	#below worked on mac but not windows
	#set cmd_options [list -sPAPERSIZE=letter -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $filename $outputFile]
	
	#set cmd_options [list -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $filename $outputFile]
	#set cmd_options [list $filename $outputFile]
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	# try new procedure for pdf output
	#set cmd "ps2pdf -sPAPERSIZE=letter -dMaxSubsetPct=100 -dCompatibilityLevel=1.3 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $escaped_filename $escaped_outputFile"
	
	## this was used successfully
	#set cmd "ps2pdf -sPAPERSIZE=letter -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $escaped_filename $escaped_outputFile"
	# test
	#set cmd "$gs -sDEVICE=pdfwrite -sPAPERSIZE=letter -dProcessColorModel=/DeviceCMYK -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dSubsetFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode -o $escaped_filename $escaped_outputFile"
	#.txt insert end "cmd: $cmd\n"
	#exec {*}$cmd >>& /dev/tty
	
}

# openPDFCreatePS
# Created 12-28-19
# Arg none
# Returns none WINDOWS ready 8/23/23
# Will open PDF file and create PS
# uses ghostscript pdf2ps in lib
proc openPDFCreatePS {} {
	global LINE
	#global pdf2ps
	global gs
	set types {
		{PDF .pdf}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openPDFCreatePS\n" procColor
	set introVar "Opens PDF file and creates a postscript (PS) file.\n"
	.txt insert end $introVar
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set filename [file nativename $filename] ; # for windows over the network
	.txt insert end "Open [file tail $filename] for converting PDF to PS...\n"

	set fileroot [file rootname [file tail $filename]] ; #return file no extension of dir
	set filedir [file dir $filename] ; #returns the path without the tailing /
	set outputFile "$filedir[file separator]$fileroot-pdf.ps"
	set outputFile [file nativename $outputFile] ; # normalize using windows and not excaped
	
	#set escaped_outputFile [escapePath $outputFile]
	#set escaped_filename [escapePath $filename] ; #escaped path and filename
	
	#set cmd "$pdf2ps"
	#set cmd_options [list $filename $outputFile]
	
	set cmd "$gs"
	set cmd_options [list -o $outputFile -sDEVICE=ps2write -sProcessColorModel=DeviceCMYK -dEPSCrop -f $filename]
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "File created: [file tail $outputFile]\n"
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	#set cmd "pdf2ps $escaped_filename $escaped_outputFile"
	#.txt insert end "cmd: $cmd\n"
	
	#exec {*}$cmd >>& /dev/tty
}

# 2-26-23 put options into a list and surround by catch statement
# Windows Ready
proc openPDFCreateGrayscalePDF {} {
	global gs
	global LINE
	set types {
		{Files {.pdf .ps}}
		{PDF .pdf}
		{PS .ps}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openPDFCreateGrayscalePDF\n" procColor
	set introVar "Opens a ps or pdf file and converts that file the grayscale color model\n"
	.txt insert end $introVar
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set filename [file nativename $filename] ; # for windows over the network
	.txt insert end "Open [file tail $filename] for converting PDF to Grayscale PDF...\n"
	
	set fileroot [file rootname [file tail $filename]] ; #return file no extension of dir
	set filedir [file dir $filename] ; #returns the path without the tailing /
	set escaped_outputFile [escapePath "$filedir[file separator]$fileroot-grayscale.pdf"] ; #escapes spaces in path and filename
	set escaped_filename [escapePath $filename] ; #escaped path and filename
	set outputFile "$filedir[file separator]$fileroot-grayscale.pdf"
	set outputFile [file nativename $outputFile] ; # normalize using windows and not excaped
	
	set cmd "$gs"
	set cmd_options [list -o $outputFile -sDEVICE=pdfwrite -sColorConversionStrategy=Gray -sProcessColorModel=DeviceGray -f $filename]
	#set cmd_options "-o $outputFile -sDEVICE=pdfwrite -sColorConversionStrategy=Gray -sProcessColorModel=DeviceGray $filename"
	
	### note: Had to escape the file names in order for this to work consistently ?????? #########
	#set cmd_options "-o $escaped_outputFile -sDEVICE=pdfwrite -sColorConversionStrategy=Gray -sProcessColorModel=DeviceGray $escaped_filename"
	.txt insert end "cmd: $gs\n"
	.txt insert end "options: $cmd_options\n"
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "Result of gs: $result\n" 
		.txt insert end "File created: [file tail $outputFile]\n" 
	}
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	#set cmd "ps2pdf -sPAPERSIZE=letter -dProcessColorModel=/DeviceGray -dMaxSubsetPct=100 -dCompatibilityLevel=1.4 -dSubsetFonts=true -dEmbedAllFonts=true -dAutoFilterColorImages=false -dAutoFilterGrayImages=true -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode -dMonoImageFilter=/FlateEncode $escaped_filename $escaped_outputFile"
	#update on XQuartz 2.8.2 (xorg-server 1.20.14) came up after this command run
	#set cmd "gs -dQUITE sDevice=pdfwrite -sProcessColorModel=DeviceGray -sColorCoversionStrategy=Gray -dOverrideICC -sOutputFile=$escaped_outputFile $escaped_filename"
	
	#### This was latest used before putting options in a list
	#set cmd "gs -o $escaped_outputFile -sDEVICE=pdfwrite -sColorConversionStrategy=Gray -sProcessColorModel=DeviceGray $escaped_filename"
	#.txt insert end "cmd: $cmd\n"
	
	#exec {*}$cmd >>& /dev/tty
	
}

# Windows ready
# 2/27/23 show all information
proc openImagePdfEpsInfoAll {} {
	global convert
	global identify
	global b_magick_6
	global LINE
	set types {
		{Files {.pdf .ps .eps .tiff .tif .png .jpeg .jpg .heic .raw}}
		{PDF .pdf}
		{PS .ps}
		{EPS .eps}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{JPEG .jpeg}
		{JPG .jpg}
		{HEIC .heic}
		{RAW .raw}
	}
	.txt insert end "$LINE"
	.txt insert end "proc openImagePdfEpsInfoAll\n"
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "canceled\n"
		.txt insert end "$LINE"
		return 
	}
	set filename [file nativename $filename] ; # for windows over the network
	puts "Command openImagePdfEpsInfoAll: $convert"
	if {$b_magick_6 eq "true"} {
		set cmd "$identify"
		#set cmd_options [list $filename -verbose info:]
		set cmd_options [list -verbose $filename]
	} else {
		#under 7 magick replaces the command convert
		#set cmd_options [list $identify $filename -verbose info:]
		set cmd "$convert"  ; # which is cmd magick under 7
		set cmd_options [list $identify -verbose $filename]
	}
	#puts "Cmd_options : $cmd_options"
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "$LINE"
	} else {
		.txt insert end "$result\n"
		.txt insert end "$LINE"
	}
	
}

#Windows Ready
proc openImagePdfEpsInfoSummary {} {
	global convert
	global identify
	global LINE
	global b_magick_6
	set types {
		{Files {.pdf .ps .eps .tiff .tif .png .jpeg .jpg .heic .raw}}
		{PDF .pdf}
		{PS .ps}
		{EPS .eps}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{JPEG .jpeg}
		{JPG .jpg}
		{HEIC .heic}
		{RAW .raw}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openImagePdfEpsInfoSummary\n" procColor
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "canceled\n"
		.txt insert end "$LINE" lineColor
		return 
	}
	set filename [file nativename $filename] ; # for windows over the network
	
	#set cmd_options [list $filename -verbose "info: | head"]
	if {$b_magick_6 eq "true"} {
		set cmd "$identify"
		set cmd_options [list -format {Basename: %[basename]\n bit-depth: %[bit-depth]\n\
								   Page Geometry: %[page]\n Print Size: %[printsize.x]x%[printsize.y]\n\
								   Resolution: %[resolution.x] x %[resolution.x]\n\
								   Units: %[units]\n\
								   Bounding Box: %[bounding-box] Color Channels: %[channels]\n\
								   ColorSpace: %[colorspace]\n\
								   Type: %[type]\n\
								   Depth: %[depth]\n\
								   Gamma: %[gamma]\n\
								   Colors: %[colors]\n\
								   Scene: %[scene]\n\
								   ***************\n } $filename]
	} else {
		set cmd "$convert" ; # which for 7 magick is used as command and identify is used as an option
		set cmd_options [list $identify -format {Basename: %[basename]\n bit-depth: %[bit-depth]\n\
								   Page Geometry: %[page]\n Print Size: %[printsize.x]x%[printsize.y]\n\
								   Resolution: %[resolution.x] x %[resolution.x]\n\
								   Units: %[units]\n\
								   Bounding Box: %[bounding-box] Color Channels: %[channels]\n\
								   ColorSpace: %[colorspace]\n\
								   Type: %[type]\n\
								   Depth: %[depth]\n\
								   Gamma: %[gamma]\n\
								   Colors: %[colors]\n\
								   Scene: %[scene]\n\
								   ***************\n } $filename]
	}
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "$LINE" lineColor
	} else {
		.txt insert end "$result\n"
		.txt insert end "$LINE"
	}
	
	# set cmd_options [list $identify -verbose $filename info:] ; # does not work under windows magick 7 - info:
	# get all information and get just the properties.
	if {0} {
	if {$b_magick_6 eq "true"} {
		set cmd "$identify"
		set cmd_options [list -verbose $filename info:]
	} else {
		set cmd "$convert" ; # which under 7 is magick with identify as option
		set cmd_options [list $identify -verbose $filename info:]
	}
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "$LINE"
	} else {
		
		set fp [open "$filename-temp.txt" w+]
		puts $fp "$result"
		close $fp
		set fp [open "$filename-temp.txt" r]
		set success "false"
		while { [gets $fp data] >= 0 } {
			
			if { [string match *Profile* "$data"] } {
				set success "true"
			}
			if { [string match *Properties* "$data"] } {
				set success "true"
			}
			if { [string match *Artifact* "$data"] } {
				set success "true"
			}
			if { $success == "true" } {
				.txt insert end "$data\n"
			}
		}
		close $fp
		if { [file exists "$filename-temp.txt"] } {
			file delete -force "$filename-temp.txt"
		}
		
		.txt insert end "$LINE" lineColor
	}
	} ; #not working
	
	#not working
	if {0} {
	set cmd_options [list $filename \
					-print {Properties\n%[*]}]
									
	if {[catch {exec $convert {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "$LINE"
	} else {
		.txt insert end "$result\n"
		.txt insert end "$LINE"
	}
	} ;#end not working
}

# part of poppler operations - 8/28/23
# https://www.prepressure.com/pdf/basics/page-boxes
# https://www.cyberciti.biz/faq/linux-unix-view-technical-details-of-pdf/
#
# http://www.xpdfreader.com/download.html  - note - this has window version
# 
proc openPdfPsPdfinfo {} {
	global pdfinfo
	global LINE
	set types {
		{PDF .pdf}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openPdfPsPdfinfo\n" procColor
	.txt insert end "This uses pdfinfo : To find Media Sizes on pdf files\n"
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "canceled\n"
		.txt insert end "$LINE" lineColor
		return 
	}
	set filename [file nativename $filename] ; # for windows over the network
	
	set cmd "$pdfinfo"
	set cmd_options [list -box $filename]
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "$LINE" lineColor
	} else {
		.txt insert end "$result\n"
	}
	
	.txt insert end "$LINE" lineColor
}

# opens pdf file using pdfbox.jar
# https://pdfbox.apache.org/
# java 8 or higher must be present
# PDFBOX
proc openPdfBoxJar {} {
	global LINE
	global script_path
	# the menu item would be disabled if java 8 was not present
	set types {
		{PDF .pdf}
	}
	
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openPdfBoxJar\n" procColor
	.txt insert end "This will open a PDF file for inspection using pdfbox.jar using java\n"
	.txt insert end "https://www.apache.org/licenses/LICENSE-2.0\n" ; # dirHyperlink
	.txt insert end "https://pdfbox.apache.org/\n" ; # dirHyperlink
	
	set filename [tk_getOpenFile -filetypes $types]
	
	if {$filename eq ""} {
		.txt insert end "canceled\n"
		.txt insert end "$LINE" lineColor
		return 
	}
	set filename [file nativename $filename] ; # for windows over the network
	
	set cmd "java"
	set cmd_options [list -jar "$script_path/lib/pdfbox.jar" debug $filename]
	# use of & operator to separate from the gui so it can continue
	if {[catch {exec $cmd {*}$cmd_options &} result]} {
		.txt insert end "Error: $result\n"
	} else {
		#.txt insert end "$result\n"
		
		.txt insert end "Opened file: [file tail $filename]\n"
		.txt insert end "Directory: "
		.txt insert end "[file dir $filename]" dirHyperlink
		
		.txt insert end "\n"
	}
	
	.txt insert end "$LINE" lineColor
	
}

# part of protrace operations
# openBitmapPBMCreatePS - Tested on Windows and Mac OK - Feb 25, 2023
# changed 10-30-23 to allow magick 7 or 6 to work
# Below opens a bitmap (grayscale).pbm file and creates a vector
# Input can be PBM, PGM, PPM, or BMP
# To scale an eps,ps,pdf use
#   https://stackoverflow.com/questions/12675371/how-to-set-custom-page-size-with-ghostscript
#   geometry 6800 / 1200 = 5.67 * 72 = 408 points (the geometry are points which are a ratio of 1:1 with pixels of the pbm image resolution created using dpi 1200)
# THIS gs -o scaled.pdf -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=408 -dDEVICEHEIGHTPOINTS=408 -dEPSFitPage -f input.ps
proc openBitmapPBMCreatePS {} {
	set types {
		{Files {.pbm .pgm .ppm .bmp}}
		{PBM .pbm}
		{PGM .pgm}
		{PPM .ppm}
		{BMP .bmp}
	}
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return} ; #When cancel is pressed
	
	global b_magick_6
	global potrace
	global identify
	global convert
	global globalparms
	global gs
	global LINE
	set success "true"
	
	set filename [file nativename $filename] ; # for windows over the network
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension or dir
	set filedir [file dir $filename] ;                  #returns path without trailing /
	set fileOnly [file tail $filename] ;  #returns ?
	# set escaped_outputFile [escapePath "$filedir[file separator]$fileroot.pbm"] ; #escape spaces in path and filename
	###set escaped_filename [escapePath $filename] ; # escaped path and filename - NOT USING
	set help "\nThe scaled version of the vector was produced in a pdf format and was created by using the global dpi setting saved.\n "
	set help "$help The previous PBM file created by PrePressActions had used this global dpi setting.\n "
	set help "$help A txt file was saved next to the PBM file created that lists the dpi used\n"
	set help "$help  If the global dpi changed since the PBM was created then change\n    the dpi back in order to get the correct scaled size.\n\n"
	.txt insert end "\n"
	
	.txt insert end "*********openBitmapPBMCreatePS************\n" lineColor
	.txt insert end $help
	.txt insert end "Opened $fileOnly for potrace to create a ps vector...\n"
	.txt insert end "Creates 6 files - 2 settings and in 3 formats - ps and eps\n"
	.txt insert end "1 setting is sharp, the other setting with smoother curves\n"
	.txt insert end "Directory Opened: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	
	# using switch -p will result in filename.ps
	#set cmd "potrace -p $escaped_filename"
	#.txt insert end "$cmd\n"
	#exec {*}$cmd >>& /dev/tty
	
	# EPS file is created
	set cmd_options [list -o $filename-default.eps $filename]
	#set cmd "potrace -o $escaped_filename-default.eps $escaped_filename"
	.txt insert end "Command executed: $potrace\n"
	# .txt insert end "cmd_options: $cmd_options\n"
	if {[catch {exec $potrace {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		set success "false"
	} else {
		# .txt insert end "Result: $result\n"
		.txt insert end "File Created: $fileroot-default.eps\n"
	}
	#.txt insert end "identify of new file created: \n"
	#if { $success eq "true" } {
	#	set identify_options [list $filename-default.eps]
	#	if {[catch {exec $identify {*}$identify_options} result]} {
	#		.txt insert end "Error: $result\n"
	#	} else {
	#		.txt insert end "Result: $result\n"
	#	}
	#}
	
	#create PS file (postscript)
	set cmd_options [list -c -o $filename-default.ps $filename]
	if {[catch {exec $potrace {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
		set success "false"
	} else {
		# .txt insert end "Result: $result\n"
		.txt insert end "File Created: $fileroot-default.ps\n"
	}
	#.txt insert end "identify of new file created: \n"
	#if { $success eq "true" } {
	#	set identify_options [list $filename-default.ps]
	#	if {[catch {exec $identify {*}$identify_options} result]} {
	#		.txt insert end "Error: $result\n"
	#	} else {
	#		.txt insert end "Result: $result\n"
	#	}
	#}
	
	#get the size in points using identify to use in scaling a pdf vector to the origninal size
	set width ""
	set height ""
	if {$success eq "true"} {
		if {$b_magick_6 eq "true"} {
			set cmd "$identify"
			set identify_options [list -format {%[fx:w]} $filename-default.ps]
		} else {
			set cmd "$convert" ; # convert var is magick commanand for 7 using identify as an option
			set identify_options [list $identify -format {%[fx:w]} $filename-default.ps]
		}
		
		#set identify_options [list -format {%[fx:w]} $filename-default.ps]
		if {[catch {exec $cmd {*}$identify_options} result]} {
			#error
			.txt insert end "Identify result error: $result\n"
			set success "false"
		} else {
			.txt insert end "Result Width: $result "
			set width $result
			#set numChars [string length $result]
			#set width [string range $result 0 $numChars-2]
			set width [ expr int(($width/$globalparms(dpi).0) * 72) ]
			.txt insert end " New width: $width "
		}
		
		if {$b_magick_6 eq "true"} {
			set identify_options [list -format {%[fx:h]} $filename-default.ps]
		} else {
			set identify_options [list $identify -format {%[fx:h]} $filename-default.ps]
		}
		
		if {[catch {exec $cmd {*}$identify_options} result]} {
			#error
			.txt insert end "Identify result error: $result\n"
			set success "false"
		} else {
			.txt insert end "Result Height: $result - "
			set height $result
			#set numChars [string length $result]
			#set height [string range $result 0 $numChars-2]
			set height [ expr int(($height/$globalparms(dpi).0) * 72) ]
			.txt insert end "New height $height (all sizes in points)\n"
		}
	}
	# provide another way to perhaps to get the width and height in case -format does not work on earlier versions 10-30-23
	if {$success eq "false"} {
		
	}
	#create pdf scaled to original size using the ps file created earlier
	set cmd_options [list -o $filename-default-scaled.pdf -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=$width -dDEVICEHEIGHTPOINTS=$height -dEPSFitPage -f $filename-default.ps]
	if {$success eq "true"} {
		if {[catch {exec $gs {*}$cmd_options} result]} {
			.txt insert end "Error scaling: $result\n"
		} else {
			.txt insert end "File created: $fileroot-default-scaled.pdf\n"
		}
	}
	
	#create more rounded edges - changed alphamax from 1.234 to 1.334 and take out --longcurve , add -O .4 (opttolerance)
	set cmd_options [list --alphamax 4.334 --turdsize 2 --turnpolicy black --opttolerance 42.0 -o $filename-round.ps $filename]
	if { $success eq "true" } {
		if {[catch {exec $potrace {*}$cmd_options} result]} {
			.txt insert end "Error $result\n"
			set success "false"
		} else {
			.txt insert end "File Created: $fileroot-round.ps\n"
		}
	}
	
	#create pdf scaled to original size using the ps file created earlier
	set cmd_options [list -o $filename-round-scaled.pdf -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=$width -dDEVICEHEIGHTPOINTS=$height -dEPSFitPage -f $filename-round.ps]
	if { $success eq "true" } {
		if {[catch {exec $gs {*}$cmd_options} result]} {
			.txt insert end "Error scaling: $result\n"
			set success "false"
		} else {
			.txt insert end "File created: $fileroot-round-scaled.pdf\n"
		}
	}
	
	
	.txt insert end "$LINE" lineColor
	
	##OLD - will not work in windows due to the pipe to /dev/tty
	##set cmd "potrace -o $escaped_filename-default.ps $escaped_filename"
	##.txt insert end "$cmd\n"
	##exec {*}$cmd >>& /dev/tty
	# reset cmd and apply filter rounded Edges
	##set cmd "potrace --alphamax 1.334 --turdsize 2 --longcurve --turnpolicy black -o $escaped_filename-round.eps $escaped_filename"
	##.txt insert end "$cmd\n"
	##exec {*}$cmd >>& /dev/tty
	##set cmd "potrace --alphamax 1.334 --turdsize 2 --longcurve --turnpolicy black -o $escaped_filename-round.ps $escaped_filename"
	##.txt insert end "$cmd\n"
	##exec {*}$cmd >>& /dev/tty
	# reset cmd and apply filter sharp Edges
	##set cmd "potrace --alphamax 0.334 --turdsize 2 --longcurve --turnpolicy black -o $escaped_filename-sharp.eps $escaped_filename"
	##.txt insert end "$cmd\n"
	##exec {*}$cmd >>& /dev/tty
	##set cmd "potrace --alphamax 0.334 --turdsize 2 --longcurve --turnpolicy black -o $escaped_filename-sharp.ps $escaped_filename"
	##.txt insert end "$cmd\n"
	##exec {*}$cmd >>& /dev/tty
}

# part of protrace operations https://wiki.tcl-lang.org/page/exec
# openImageCreatePBM - Tested on Mac and Windows ver 6 and 7 - OK Feb 25, 2023
# Arg none
# Returns none
# Will open Image file and create Bitmap grayscale .pbm file
#      .pbm files do not retain dpi or metadata
#      when coverting cannot give it a density or resolution
#      if you give it a 1200 dpi file high rez then the result will be high rez
# potrace will be able to create an outline this file format
proc openImageCreatePBM {} {
	global globalparms
	global convert
	global identify
	global b_magick_6
	global LINE
	set types {
		{Files {.tiff .tif .png .jpeg .jpg}}
		{TIFF .tiff}
		{TIF .tif}
		{PNG .png}
		{JPEG .jpeg}
		{JPG .jpg}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc openImageCreatePBM\n" procColor
	.txt insert end "This operation will open an image file and create a Bitmap .pbm file using threshold of 50%\n"
	.txt insert end "The created file will be a grayscale with pixels either 100% black or 100% white.\n"
	.txt insert end "Note: .pbm files do not retain dpi settings or have any metadata stored.\n "
	.txt insert end "    The opened file will use the global dpi settings : $globalparms(dpi)\n"
	.txt insert end "    When creating line art 1200 dpi is the recommended setting\n"
	.txt insert end "potrace will be able this file format to create a vector file \n"
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {return} ; #When cancel is pressed
	set filename [file nativename $filename] ; # for windows over the network
	
	.txt insert end "Opened $filename for covert to mono...\n"
	
	set fileroot [file rootname [file tail $filename]]; #returns file no extension or dir
	set filedir [file dir $filename] ;                  #returns path without trailing /
	set outputfile "$filedir[file separator]$fileroot.pbm"
	set outputFileDPI "$filedir[file separator]$fileroot-txt.txt"
	
	# changed 10-30-23
	if {$b_magick_6 eq "true"} {
		set cmd "$identify"
		set cmdListDPI [list -units PixelsPerInch -format {%[resolution.x] x %[resolution.y] %[units]} $filename]
	} else {
		set cmd "$convert" ; # which for 7 uses magick with identify as an option
		set cmdListDPI [list $identify -units PixelsPerInch -format {%[resolution.x] x %[resolution.y] %[units]} $filename]
	}
	#set cmdListDPI [list -units PixelsPerInch -format {%[resolution.x] x %[resolution.y] %[units]} $filename]
	
	#need try statement in exec
	
	if {[catch {exec $cmd {*}$cmdListDPI > $outputFileDPI} result]} {
		.txt insert end "Error: $result\n"
		.txt insert end "DPI of the file opened could not be read.\n"
	} else {
		#get the info
		if {[file exists $outputFileDPI]} {
			set chan [open $outputFileDPI r]
			set data [read $chan]
			close $chan
			.txt insert end "File opened DPI info: $data\n"
			#file delete -force $escaped_outputFile_DPI
		}
	}
	#set cmd "convert -density $globalparms(dpi) -threshold 50% $escaped_filename $outputfile"
	#.txt insert end "cmd: $cmd\n"
	update idletasks
	
	#set cmd_options [list -density $globalparms(dpi) -threshold 50% $filename $outputfile]
	set cmd_options [list $filename -density $globalparms(dpi) -threshold 50% $outputfile]
	if {[catch {exec $convert {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"
	} else {
		#.txt insert end "$result\n"
		.txt insert end "File created: $fileroot.pbm\n"
	}
	
	.txt insert end "Directory: "
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n$LINE" lineColor
}

# menu command
# mac linux gs, windows ?
# added 12-18-19, revised 11-16-22, 11-22-23, 12-19-23
# https://www.prepressure.com/pdf/basics/page-boxes
# printsize var to be set in inches - ex. 8.5x11
# note: a new dir (in cache_path) created and coverage files put there.
# upon finish reading of coverage files they are deleted.
# the directory is deleted at end of proc - so watch out for return if errors - be sure to delete dir
# grey = 0.3*red + 0.59*green + 0.11*blue. https://rdrr.io/cran/DescTools/man/ColToGrey.html
# RED=30%, GREEN=59% and BLUE=11% https://www.gimp.org/tutorials/Color2BW/
# https://cmyktool.com/cmyk-to-grayscale-image-converter/ Grayscale value = (0.299 * C) + (0.587 * M) + (0.114 * Y) + (0 * K)
# https://stackoverflow.com/questions/15026409/grayscale-cmyk-pixel
# calculation used: 
#	set standardPage [expr 8.5 * 11]
#	set pdfPagesize [expr $width * $height]
#	set scalefactor [expr $pdfPagesize / $standardPage]
#	set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
#	set total_cost_black [expr ($black_total * $sqinch) * $scalefactor]
# for consumables with no percent coverage
#	set sqinch [expr $unit/$yield.0 * $printer_copies] ; # manufacture is based on 8.5x11
#	set total_transfer_unit [expr $sqinch * $scalefactor]
proc measureCMYK {} {
	global gs
	global LINE
	global identify ; # an IM command
	global convert ; # if version 7 should be magick as the command and not convert as in version 6
	global b_magick
	global b_magick_6
	global b_magick_7
	global dict_printers ; # dict of printers
	global globalparms ; # to find cache path, and default printer
	global printsize_dlg ; # incase MediaBox not found can set page size from dialog box 
	global printer_copies ; # default is 1 but set from dialog
	#global printsize
	set types {
		{Files {.ps .pdf}}
		{PS .ps}
		{PDF .pdf}
	}
	.txt insert end "$LINE" lineColor
	.txt insert end "proc measureCMYK\n" procColor
	.txt insert end "Measure the cmyk coverage of a pdf or ps file\n"
	# https://wiki.tcl-lang.org/page/emoji+with+Tcl%2FTk+8.6
	# unicode smiley face - this is called a surrogate pair - 
	#   tcl versions 8.6 and 8.7 surrogates work but will not work in 9.0
	# .txt insert end "\uD83D\uDE00 "
	# https://core.tcl-lang.org/tips/doc/trunk/tip/600.md
	#    use the emoji directly by keyboard or menu options
	if { $::tcl_platform(platform) eq "windows" } {
	
	} else {
		.txt insert end "🔬" verybig
		.txt insert end \n
	}
	
	# if a printer is set as default it will be the number id of the printer and never the name of the printer
	# even if the printer is named none ;  'none' is applied by the script and not the user
	if {$globalparms(defaultprinter) eq "none"} {
		set msg "Could not find default printer\nPlease go to InkCoverage->Add Printer Profiles and select the printer. \
				Do you wish to continue without calculating the cost to print?"
		set reply [tk_messageBox -parent . -message $msg -icon question -type yesno]
		if {$reply eq "no"} {
			.txt insert end "Operation canceled\n"
			.txt insert end "$LINE" lineColor
			return	
		} else {
			.txt insert end "Operation to continue without calculating the costs\n"
		}
	} else {
		# there is a default printer so get the # of copies
		#upvar used another proc to change the status value
		global status
		set status "before"
		showNumCopiesDlg status ; # will set global printer_copies
		#puts "status after dlg: $status"
		if {$status ne "true"} {
			.txt insert end "Operation canceled\n" 
			.txt insert end "$LINE" lineColor
			return		
		}
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert end "Canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	set filename [file nativename $filename] ; # for windows over the network
	.txt insert end "Opened $filename for cmyk coverage ...\n"
	
	set fileroot [file rootname [file tail $filename]] ; #returns file no extension or dir
	set filedir [file dir $filename] ;                   #returns the path without the tailing /
	# change to or make new dir for the cmyk.txt files
	# are going to change to the cache directory for the coverage files
	set today [clock format [clock seconds] -format %Y-%m-%d_%H-%M-%S]
	set fullpathdir_cmyk [file nativename "$globalparms(cache_path)[file separator]$today-measureCMYK"] ; # a new dir to contain results and files
	# make sure the directory exists or create one
	if {![file isdirectory $fullpathdir_cmyk]} {
		file mkdir $fullpathdir_cmyk
	}
	
	set outputFile "$fullpathdir_cmyk[file separator]$today-p%03d-cmyk-gs.txt" ; # try without escaping - had error of finding files double escapes present ???
	set outputFile [file nativename $outputFile] ; # normalize using windows and not excaped
	
	set cmd "$gs"
	#set cmd_options [list -dNOSAFER -dNOPAUSE -o $outputFile -sDEVICE=ink_cov -f $filename]
	# try 11-1-23 test
	set cmd_options [list -o $outputFile -dNOSAFER -dNOPAUSE -sDEVICE=ink_cov -f $filename]
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
		.txt insert end "$LINE" lineColor
		set reply [tk_messageBox -parent . -message "Error in ghostscript\n" -icon warning -type ok]
		##########return ; #after testing rest of procedure make sure this return in uncommented
	} else {
		#.txt insert end "File created: [file tail $outputFile]\n"
		.txt insert end "Results: $result\n"
	}
	#.txt insert end "cmd: $cmd\n"
	.txt insert end "$LINE" lineColor
	
	
	############## try identify - in tests - has not failed yet on valid pdf files 11-21-23 ; bounding box not using
	## fails on IM version 6.5.4-9 2009-08-04 - does not throw error on below formatting but does not give results
	set result ""
	set local_b_IM 0
	if {$b_magick_6 eq "true"} {
		set cmd2 "$identify"  ; # NO Crop Box: %[crop-box]
		set cmd2_options [list -format { Page Geometry: %[page]\n Print Size: %[printsize.x]x%[printsize.y]\n\
										Resolution: %[resolution.x] x %[resolution.x]\n\
										Bounding Box: %[bounding-box] \
										*************\n } $filename]
		if {[catch {exec $cmd2 {*}$cmd2_options} result]} {
			.txt insert end "Error: $result\n"	
			.txt insert end "$LINE" lineColor
		} else {
			#.txt insert end "$result"
			#.txt insert end "$LINE"
			set local_b_IM 1
		} 
	} elseif {$b_magick_7 eq "true"} {
		set cmd2 "$convert"  ; # the command will be magick with identify as an option ; NO Crop Box: %[crop-box]
		set cmd2_options [list $identify -format { Page Geometry: %[page]\n Print Size: %[printsize.x]x%[printsize.y]\n\
										Resolution: %[resolution.x] x %[resolution.x]\n\
										Bounding Box: %[bounding-box] \
										*************\n } $filename]
		if {[catch {exec $cmd2 {*}$cmd2_options} result]} {
			.txt insert end "Error: $result\n"	
			.txt insert end "$LINE" lineColor
		} else {
			#.txt insert end "$result"
			#.txt insert end "$LINE"
			set local_b_IM 1
		} 
	}
	
	####### width height - setting the printsize using result var - if there is IM installed
	set width 0
	set height 0
	if {$local_b_IM ne 0} {
		# get only the first page to use as the page size
		set start [string first "Print Size: " $result]
		set end [string first "Resolution" $result]
		set printsize [string range $result $start+12 $end-3] ; # end-2 so as to include the end of line char '\n'
		
		puts "$printsize - from IM"
		#print all pages
		foreach line [split $result \n] {
			.txt insert end $line\n
		}
		#need to validate the print size - then create a width and height var
		#if this fails we will try the below to find width and height as if IM not installed.
		if {$printsize ne "x"} {
			set list_size [split $printsize x]
			puts $list_size
			set width [lindex $list_size 0]
			set height [lindex $list_size 1]	
		} else {
			set local_b_IM 0	; # meaning false
		}
	} 
	if {$local_b_IM eq 1} {
		.txt insert end "Only the first page is used for the Print Size: $printsize inches\n"
	}
	
	### Using regexp if imagemagick not installed or the version does not support the format call
	####### sometimes generates runtime error: inappropriate device for ioctl reading ; on the [gets $fp data]
	### error is caught by using below:
	### answer by schelte to try: while { [catch {gets $fp data} result ] == 0 && $result >= 0 } 
	# Old code: while { [gets $fp data] >= 0 }
	#### if MediaBox exists use that for calculating the page geometry
	### 8.5x11 eq 0,0,612,792 if 1,2,613,794 then subtract 613-1 and 794-2 for page geometry
	### Then divide by 72 for inches (default is 72 points per inch)
	
	#if here then IM not installed or failed
	if {$local_b_IM eq 0} {
		set mediabox 0
		set cropbox 0
		if [ catch {set fp [open "$filename" r] } result ] {
			puts "error: $result"
		} else {
			set result ""
			while { [catch {gets $fp data} result ] == 0 && $result >= 0 } {
				if { [string match -nocase {*Box*} "$data"] } {
					set mediabox 0
					regexp {MediaBox\[(.*?)\]} "$data" mediabox
					if {$mediabox ne 0} {
						puts "MediaBox: $mediabox"
						break
					} else {
						regexp {MediaBox \[(.*?)\]} "$data" mediabox
						if {$mediabox ne 0} {
							puts "MediaBox: $mediabox"
							break
						}
					}
					set cropbox 0
					regexp {CropBox\[(.*?)\]} "$data" cropbox
					if {$cropbox ne 0} {
						puts "CropBox: $cropbox"
						break
					} else {
						regexp {CropBox \[(.*?)\]} "$data" cropbox
						if {$cropbox ne 0} {
							puts "CropBox: $cropbox"
							break
						}
					}
				}
			}
			close $fp
			#puts "the result of regexp $result"
			#set box "no media or crop box found"
			if {$mediabox ne 0} {
				.txt insert end "From regexp MediaBox: $mediabox\n"
				set start [string first "\[" $mediabox ]
				set end [string first "\]" $mediabox ]
				set box [string range $mediabox $start+1 $end-1]
				set box [string trim $box]
				set list_box [split $box " "]
				puts $list_box
				if {[llength $list_box] == 4} {
					set x1 [expr round([lindex $list_box 0])]
					set y1 [expr round([lindex $list_box 1])]
					set x2 [expr round([lindex $list_box 2])]
					set y2 [expr round([lindex $list_box 3])]
					puts "$x1 $y1 $x2 $y2"
					set result ""
					if {[catch {expr ($x2-$x1)/72.0} result]} {
						set width 0 ; #error occured
					} else {
						set width $result
					}
					set result ""
					if {[catch {expr ($y2-$y1)/72.0} result]} {
						set height 0 ; #error occured
					} else {
						set height $result
					}
					#puts "from mediabox search results: $width\x$height"

				}			
			} elseif {$cropbox ne 0} {
				.txt insert end "From regexp CropBox: $crop\n"
			
			} else {
				.txt insert end "From regexp: MediaBox or CropBox could not be found\n"
			}
			.txt insert end "Print Size: $width\x$height\n"
		} 
		 # end of open filename to search through file for MediaBox or CropBox
	} 
	 # end of if local_b_IM eq 0
	
	#test if height and width exist
	puts "Width: $width x Height $height"
	
	#open and read the generated cmyk txt files.
	set files [ glob -nocomplain -dir $fullpathdir_cmyk *-cmyk-gs.txt* ]
	set files [lsort $files]
	set i 0 ; #helper change 1st line read from rest of lines, and lower in code to iterate if more than 0 lines
	set coverage {} ;  #list of lines
	foreach f $files {
		#read files and put into a list
		set chan [open $f r]
		set line [read $chan]
		close $chan
		if { $i > 0 } {
			set line [string trim $line]
			set full [string map -nocase {
			"   " "/"
			"  " "/"
			" " "/"
			} $line ]
			set $full [string trim $full]
			#puts "full2: $full"
			set tmp [split $full /]
			set tmp2 [lrange $tmp 0 3]
			#set coverage [concat $coverage $tmp2]
			lappend coverage {*}$tmp2
			incr i
		} else {
			set line [string trim $line]
			set full [string map -nocase {
			"   " "/"
			"  " "/"
			" " "/"
			} $line ]
			
			set tmp [split $full /]
			set coverage [lrange $tmp 0 3] ; #first line in list
			
			incr i
		}
		# delete the file once it has been read and numbers are put into a list
		if {[file isfile $f]} {
			file delete -force $f
		}
	}
	
	#puts $coverage
	
	############# all the files have been read
	set cyan_total 0
	set magenta_total 0
	set yellow_total 0
	set black_total 0
	set pages_total 0
	if {$i eq 0} {
		.txt insert end {no coverage files created for cmyk inkcoverage}
		.txt insert end "\n"
	} else {
		.txt insert end "Below are coverage info formatted to allow easy copy and paste into a spreadsheet.\n \
						 All data separated by 1 space\n \
						 If needed, remember to use shift to continue coping.\n"
		.txt insert end "**************\n" lineColor
		.txt insert end "cmyk Coverage $i pages.\n"
		.txt insert end "Page Cyan Magenta Yellow Black\n"
		set color_element 0
		for { set x 0 } {$x < $i} {incr x} {
			set cyan [lindex $coverage $color_element]
			incr color_element
			set magenta [lindex $coverage $color_element]
			incr color_element
			set yellow [lindex $coverage $color_element]
			incr color_element
			set black [lindex $coverage $color_element]
			incr color_element
			
			.txt insert end "[expr $x + 1] "
			.txt insert end "$cyan "
			.txt insert end "$magenta "
			.txt insert end "$yellow "
			.txt insert end "$black\n"
			
			set cyan_total [expr $cyan_total + $cyan]
			set magenta_total [expr $magenta_total + $magenta]
			set yellow_total [expr $yellow_total + $yellow]
			set black_total [expr $black_total + $black]
			set pages_total $i
			#.txt insert end "**************\n" lineColor
		}
		
	}
	#puts "total pages: $pages_total"
	#set cyan_total [expr double(round(100000*$cyan_total)) / 100000]
	#set magenta_total [expr double(round(100000*$magenta_total)) / 100000]
	#set yellow_total [expr double(round(100000*$yellow_total)) / 100000]
	#set black_total [expr double(round(100000*$black_total)) / 100000]
	
	.txt insert end "-------------------------------------------------------------------------\n" 
	.txt insert end "-Totals(per copy) cyan: [format %.4f $cyan_total] magenta: [format %.4f $magenta_total] yellow: [format %.4f $yellow_total] black: [format %.4f $black_total]\n"
	if {$width eq 0 || $height eq 0} {
		# dialog with option to manually put in the page size
		set printsize_dlg 0x0
		showPagesizeDlg ; # will set printsize_dlg in this dialogbox
		puts "after showPagesizeDlg: $printsize_dlg"
		if {$printsize_dlg ne "0x0"} {
			set lsize [split $printsize_dlg x]
			set width [lindex $lsize 0]
			set height [lindex $lsize 1]
			.txt insert end "Print Size set to: $printsize_dlg\n"
		}
	}
	############################## Do Calculations Summary ############################################# marked
	if {$width > 0 || $height > 0} {
		set sq_in_page [expr $width * $height]
		set total_sq_in [expr $sq_in_page * $pages_total]
		.txt insert end "Total square inch per 1 copy: $total_sq_in\n"
		set total_cmyk_coverage [expr ($cyan_total + $magenta_total + $yellow_total + $black_total) ]
		.txt insert end "Total CMYK coverage per 1 copy: $total_cmyk_coverage\n"
		set average_cmyk_coverage [expr $total_cmyk_coverage / $pages_total]
		set total_grayscale_coverage $black_total
		set average_grayscale_coverage [expr $black_total / $pages_total]
		.txt insert end "Average Page CMYK coverage per copy: $average_cmyk_coverage\n"
		.txt insert end "Average Grayscale per copy (If pdf is grayscale): $average_grayscale_coverage\n"
		.txt insert end "$LINE" lineColor
		
		# ABOVE IS THE COVERAGE - BELOW APPLY PRINTER COSTS TO THE COVERAGES ABOVE
		
		# apply printer default profile and calculate cost to print - need to catch getting the printer - may not exist
		if [ catch {set printer [dict get $dict_printers $globalparms(defaultprinter)]} result] {
			# there are no printers named 'none' so this will 'trip the catch' statement and if here an error occured
			# no need for messageBox since the was asked in the beginning and user proceeded anyway
			set msg "Default Printer cannot be found!\n Select Printer from Printer Profiles."
			set reply [tk_messageBox -parent . -message $msg -icon warning -type ok]
			
			.txt insert end "Could not find default printer... Exit calculations\n"
			
			#clean up
			if {[file isdirectory $fullpathdir_cmyk]} {
					file delete -force $fullpathdir_cmyk
				}
			set globalparms(defaultprinter) "none"
			.txt insert end "$LINE" lineColor		
			return
		} 
		set printer_name [dict get $printer printer]
		set desc [dict get $printer description]
		set printer_kind [dict get $printer kind]
		.txt insert end "Calculate Print Cost\n" procColor
		.txt insert end "SUMMARY\n" procColor
		.txt insert end "File Name: [file tail $filename]\n"
		.txt insert end "Printer Profile Name: $printer_name\n"
		.txt insert end "Printer Description: $desc\n"
		.txt insert end "Kind of Printer: $printer_kind\n\n"
		.txt insert end "Total Copies: $printer_copies\n"
		
		set standardPage [expr 8.5 * 11]
		set pdfPagesize [expr $width * $height]
		set scalefactor [expr $pdfPagesize / $standardPage]
		if {$printer_kind eq "Color Toner"} {	
		
			### sqinch is the cost to print per 1 square inch
			set unit [dict get $printer cyan_toner_unit]
			set yield [dict get $printer cyan_toner_yield]
			set percent [dict get $printer cyan_toner_percent]
			set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double and not an integer		
			set total_cost_cyan [expr ($cyan_total * $sqinch) * $scalefactor]
			#set f_total_cost_cyan [format %.6f $total_cost_cyan]
			.txt insert end "Total Cyan Toner:    [format %.6f $total_cost_cyan]\n"
			
			set unit [dict get $printer magenta_toner_unit]
			set yield [dict get $printer magenta_toner_yield]
			set percent [dict get $printer magenta_toner_percent]
			set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
			set total_cost_magenta [expr ($magenta_total * $sqinch) * $scalefactor]
			.txt insert end "Total Magenta Toner: [format %.6f $total_cost_magenta]\n"
			
			set unit [dict get $printer yellow_toner_unit]
			set yield [dict get $printer yellow_toner_yield]
			set percent [dict get $printer yellow_toner_percent]
			set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
			set total_cost_yellow [expr ($yellow_total * $sqinch) * $scalefactor]
			.txt insert end "Total Yellow Toner:  [format %.6f $total_cost_yellow]\n"
			
			set unit [dict get $printer black_toner_unit]
			set yield [dict get $printer black_toner_yield]
			set percent [dict get $printer black_toner_percent]
			set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; puts "from black sqinch: $sqinch yield.0 equal: $yield.0"
			set total_cost_black [expr ($black_total * $sqinch) * $scalefactor]
			.txt insert end "Total Black Toner:   [format %.6f $total_cost_black]\n"
			
			# in case a drum happens to be with the toner, also 0 accepted in percent to calculate by number of letter sheets
			set unit [dict get $printer cyan_drum_unit]
			set yield [dict get $printer cyan_drum_yield]
			set percent [dict get $printer cyan_drum_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_drum_cyan [expr ($cyan_total * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_drum_cyan [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Cyan Drum:     [format %.6f $total_drum_cyan]\n"
			} else {
				set total_drum_cyan 0.0
			}
			
			set unit [dict get $printer magenta_drum_unit]
			set yield [dict get $printer magenta_drum_yield]
			set percent [dict get $printer magenta_drum_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_drum_magenta [expr ($magenta_total * $sqinch) * $scalefactor]	
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_drum_magenta [expr $sqinch * $scalefactor]	
				}
				.txt insert end "Total Magenta Drum:  [format %.6f $total_drum_magenta]\n"
			} else {
				set total_drum_magenta 0.0
			}
			
			set unit [dict get $printer yellow_drum_unit]
			set yield [dict get $printer yellow_drum_yield]
			set percent [dict get $printer yellow_drum_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_drum_yellow [expr ($yellow_total * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_drum_yellow [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Yellow Drum:   [format %.6f $total_drum_yellow]\n"
			} else {
				set total_drum_yellow 0.0	
			}
			
			set unit [dict get $printer black_drum_unit]
			set yield [dict get $printer black_drum_yield]
			set percent [dict get $printer black_drum_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_drum_black [expr ($black_total * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_drum_black [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Black Drum:    [format %.6f $total_drum_black]\n"	
			} else {
				set total_drum_black 0.0	
			}		
			
			# check to see if using a transfer belt - value will be 0 if not using
			set unit [dict get $printer transfer_belt_unit]
			set yield [dict get $printer transfer_belt_yield]
			set percent [dict get $printer transfer_belt_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					# get total coverage usage
					set total_transfer_unit [expr ($average_cmyk_coverage * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies] ; # manufacture is based on 8.5x11
					set total_transfer_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Transfer Belt: [format %.6f $total_transfer_unit]\n"
			} else {
				set total_transfer_unit 0.0
			}
			
			# check to see if using fuser
			set unit [dict get $printer fuser_unit]
			set yield [dict get $printer fuser_yield]
			set percent [dict get $printer fuser_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					# get total coverage usage
					set total_fuser_unit [expr ($average_cmyk_coverage * $sqinch) * $scalefactor]
					#set total_fuser_unit [expr double(round(1000000*($total_cmyk_coverage * $sqinch))) / 1000000]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies ] ; # manufacture is based on 8.5x11
					set total_fuser_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Fuser:         [format %.6f $total_fuser_unit]\n"
			} else {
				set total_fuser_unit 0.0	
			}
			
			# check to see if using waste unit
			set unit [dict get $printer waste_unit]
			set yield [dict get $printer waste_yield]
			set percent [dict get $printer waste_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					# get total coverage usage
					set total_waste_unit [expr ($average_cmyk_coverage * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies] ; # manufacture is based on 8.5x11
					set total_waste_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Waste Unit:    [format %.6f $total_waste_unit]\n"
			} else {
				set total_waste_unit 0.0
			}
			# add up total costs
			set total_cmyk_costs [expr $total_cost_cyan + $total_cost_magenta + $total_cost_yellow + $total_cost_black \
									+ $total_drum_cyan + $total_drum_magenta + $total_drum_yellow + $total_drum_black \
									+ $total_transfer_unit + $total_fuser_unit + $total_waste_unit]
			
			.txt insert end "-------------------------------\n"
			.txt insert end "Total Cost:          [format %.6f $total_cmyk_costs]\n\n"
			
		} elseif {$printer_kind eq "Ink Jet"} {
			
			### sqinch is the cost to print per 1 square inch
			set unit [dict get $printer cyan_unit]
			set yield [dict get $printer cyan_yield]
			set percent [dict get $printer cyan_percent]
			if {$unit > 0 && $yield > 0 && $percent > 0} {
				set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double	
				set total_cost_cyan [expr ($cyan_total * $sqinch) * $scalefactor]
				.txt insert end "Total Cyan Ink:      [format %.6f $total_cost_cyan]\n"
			} else {
				set total_cost_cyan 0.0
			}
			
			set unit [dict get $printer magenta_unit]
			set yield [dict get $printer magenta_yield]
			set percent [dict get $printer magenta_percent]
			if {$unit > 0 && $yield > 0 && $percent > 0} {
				set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double	
				set total_cost_magenta [expr ($magenta_total * $sqinch) * $scalefactor]
				.txt insert end "Total Magenta Ink:   [format %.6f $total_cost_magenta]\n"
			} else {
				set total_cost_magenta 0.0
			}
			
			set unit [dict get $printer yellow_unit]
			set yield [dict get $printer yellow_yield]
			set percent [dict get $printer yellow_percent]
			if {$unit > 0 && $yield > 0 && $percent > 0} {
				set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double	
				set total_cost_yellow [expr ($yellow_total * $sqinch) * $scalefactor]
				.txt insert end "Total Yellow Ink:    [format %.6f $total_cost_yellow]\n"
			} else {
				set total_cost_yellow 0.0
			}
			
			set unit [dict get $printer black_unit]
			set yield [dict get $printer black_yield]
			set percent [dict get $printer black_percent]
			if {$unit > 0 && $yield > 0 && $percent > 0} {
				set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double	
				set total_cost_black [expr ($black_total * $sqinch) * $scalefactor]
				.txt insert end "Total Black Ink:     [format %.6f $total_cost_black]\n"
			} else {
				set total_cost_black 0.0
			}
			
			######## Here we need to implement a spot color - From the menu item will have spot set to true ## marked
			
			#### end spot
			
			set total_ink_costs [expr $total_cost_cyan + $total_cost_magenta + $total_cost_yellow + $total_cost_black]
			.txt insert end "-------------------------------\n"
			.txt insert end "Total Cost:          [format %.6f $total_ink_costs]\n\n"
			
			
		} elseif {$printer_kind eq "Mono Toner"} {
			set unit [dict get $printer black_toner_unit]
			set yield [dict get $printer black_toner_yield]
			set percent [dict get $printer black_toner_percent]
			if {$unit > 0 && $yield > 0 && $percent > 0} {
				set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies] ; # $yield.0 force the results to be a double	
				set total_cost_black [expr ($black_total * $sqinch) * $scalefactor]
				.txt insert end "Total Black Toner:   [format %.6f $total_cost_black]\n"
			} else {
				set total_cost_black 0.0
			}
			
			set unit [dict get $printer black_drum_unit]
			set yield [dict get $printer black_drum_yield]
			set percent [dict get $printer black_drum_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_drum_black [expr ($black_total * $sqinch) * $scalefactor]	
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies] ; # manufacture is based on 8.5x11
					set total_drum_black [expr $sqinch * $scalefactor]
				}	
				.txt insert end "Total Black Drum:    [format %.6f $total_drum_black]\n"
			} else {
				set total_drum_black 0.0
			}
			
			set unit [dict get $printer transfer_belt_unit]
			set yield [dict get $printer transfer_belt_yield]
			set percent [dict get $printer transfer_belt_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_transfer_unit [expr ($average_grayscale_coverage * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr $unit/$yield.0 * $printer_copies] ; # manufacture is based on 8.5x11
					set total_transfer_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Transfer Belt: [format %.6f $total_transfer_unit]\n"
			} else {
				set total_transfer_unit 0.0
			}
			
			set unit [dict get $printer fuser_unit]
			set yield [dict get $printer fuser_yield]
			set percent [dict get $printer fuser_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_fuser_unit [expr ($average_grayscale_coverage * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_fuser_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Fuser:         [format %.6f $total_fuser_unit]\n"
			} else {
				set total_fuser_unit 0.0
			}
			
			# check if using waste unit
			set unit [dict get $printer waste_unit]
			set yield [dict get $printer waste_yield]
			set percent [dict get $printer waste_percent]
			if {$unit > 0 && $yield > 0} {
				if {$percent > 0} {
					set sqinch [expr (($unit/$yield.0)/$percent) * $printer_copies]
					set total_waste_unit [expr ($average_grayscale_coverage * $sqinch) * $scalefactor]
				} else {
					set sqinch [expr ($unit/$yield.0) * $printer_copies]
					set total_waste_unit [expr $sqinch * $scalefactor]
				}
				.txt insert end "Total Waste Unit:    [format %.6f $total_waste_unit]\n"
			} else {
				set total_waste_unit 0.0
			}
			
			### there can not be spot using mono
			
			###### add up the total mono costs
			set total_mono_costs [expr $total_cost_black + $total_drum_black + $total_transfer_unit  \
									+ $total_fuser_unit + $total_waste_unit]	
			.txt insert end "-------------------------------\n"
			.txt insert end "Total Cost:          [format %.6f $total_mono_costs]\n\n"

			
		} else {
			.text insert end "Error: Printer Kind not found\n"
		}
		
	} else {
		.txt insert end "If the width or height is 0 the page size is not known.\n 
		.txt insert end "$LINE" lineColor
	}
	
	.txt insert end "$LINE" lineColor
	# now delete directory
	if {[file isdirectory $fullpathdir_cmyk]} {
		file delete -force $fullpathdir_cmyk
	}
}

# menu command
proc measureCMYKspot {} {
	# not implemented yet
	set types {
		{Files {.ps .pdf}}
		{PS .ps}
		{PDF .pdf}
	}
	
	set msg "This action has not been implemented yet"
	set result [tk_messageBox -parent . -message $msg -type ok]
	return
}
# menu command
# added 06-23-18
proc clearLog {} {
	.txt delete 0.0 end
}

# Purpose: utility - not using - tcl exec does not use escapes like the shell
# Returns string
proc escapePath {varPath} {
	set output {}
	set catstr ""
	foreach char [split $varPath ""] {
		lappend output [scan $char %c]
		if {[string is space $char]} {
			#puts "space found" ; #testing
			set catstr [string cat $catstr "\\" $char]
		} else {
			set catstr [string cat $catstr $char]
		}
	}
	#puts $output ; #testing
	#puts $catstr ; #testing
	return $catstr
}


# Toolbox Open Folder - any platform
# Paul Obermeier - https://groups.google.com/forum/#!topic/comp.lang.tcl/tMu5e4fFg80
# Changed to support opening from directory
proc StartFileBrowser { dir } {
	if { $::tcl_platform(platform) eq "windows" } {
		set browserProg "explorer"
	} elseif { $::tcl_platform(os) eq "Linux" } {
		set browserProg "konqueror"
	} elseif { $::tcl_platform(os) eq "Darwin" } {
		set browserProg "open"
	} elseif { $::tcl_platform(os) eq "SunOS" } {
		set browserProg "filemgr -d"
	} elseif { [string match "IRIX*" $::tcl_platform(os)] } {
		set browserProg "fm"
	} else {
		set browserProg "xterm -e ls"
	}
	puts $browserProg
	if { [file isdirectory $dir] } {
		#puts "here"
		eval exec $browserProg [list [file nativename $dir]] & 
		#puts "$browserProg [list [file nativename $dir]] &"
		set lstDir [list [file nativename $dir]]
		#puts $lstDir
	}
}
#### DpiDialog for PDF to tiff conversion ###############################
proc setDpiDialog {dpi_dlg} {
	global globalparms
	upvar $dpi_dlg value
	
	if {[string is integer -strict $value]} {
		if {(($value > 3) && ($value < 9601))} {
			set globalparms(dpi) $value
		}
	}
	unset value
	destroy .dpiDialog 	
}
proc cancelDpiDialog {} {
	destroy .dpiDialog
}
proc showDpiDialog {} {
	global globalparms
	global dpi_dlg
	set dpi_dlg $globalparms(dpi)
	#puts "from dlg dpi_dlg: $dpi_dlg"
	
	toplevel .dpiDialog
	wm withdraw .dpiDialog
	
	ttk::frame .dpiDialog.f -relief flat
	ttk::labelframe .dpiDialog.f.change -text "DPI in creating .tiff files from PDF"
	ttk::label .dpiDialog.f.change.lbdpi -text "DPI : "
	ttk::entry .dpiDialog.f.change.dpi -textvariable dpi_dlg
	
	
	grid config .dpiDialog.f.change.lbdpi \
		-column 0 -row 0 -sticky e
	grid config .dpiDialog.f.change.dpi \
		-column 1 -row 0 -sticky e
	
	pack .dpiDialog.f.change -padx 5 -pady 5
	
	#action buttons
	ttk::frame .dpiDialog.f.buttons -relief flat
	ttk::button .dpiDialog.f.buttons.ok -text "Change DPI" \
		-command {setDpiDialog dpi_dlg}
	ttk::button .dpiDialog.f.buttons.cancel -text "Cancel" \
		-command {cancelDpiDialog}		
	# arrange
	pack .dpiDialog.f.buttons.ok -side left
	pack .dpiDialog.f.buttons.cancel -side right
	pack .dpiDialog.f.buttons -padx 5 -pady 5
	pack .dpiDialog.f
	
	#window manager
	wm title .dpiDialog "DPI"
	wm protocol .dpiDialog WM_DELETE_WINDOW {
		.dpiDialog.f.buttons.cancel invoke
	}
	wm transient .dpiDialog .
	::tk::PlaceWindow .dpiDialog widget .
	# display dialog
	wm deiconify .dpiDialog
	
	# make it modal
	catch {tk visibility .dpiDialog}
	focus .dpiDialog.f.change.dpi
	catch {grab set .dpiDialog}
	catch {tkwait window .dpiDialog}
}
######################################## End of dpiDialog

######### batchDialog ##################################################
proc batchDialogOK {dpi_dlg pixel_dlg quality_dlg} {
	global globalparms
	upvar $dpi_dlg dpi_value
	upvar $pixel_dlg pixel_value
	upvar $quality_dlg quality_value

	if {[string is integer -strict $dpi_value]} {
		if {$dpi_value < 1} {
			set dpi_value 1
		}
	}
	if {[string is integer -strict $dpi_value]} {
		if {(($dpi_value > 0) && ($dpi_value < 4801))} {
			set globalparms(dpi_batch) $dpi_value
		}
	}
	if {[string is integer -strict $pixel_value]} {
		if {$pixel_value > 1} {
			set globalparms(pixel_w_batch) $pixel_value
		}
	}
	if {[string is integer -strict $quality_value]} {
		if {(($quality_value > 49) && ($quality_value < 101))} {
			set globalparms(quality_batch) $quality_value
		}
	}
	unset dpi_value
	unset pixel_value
	unset quality_value
	
	destroy .batchDialog
}
proc batchDialogCancel {} {
	destroy .batchDialog
}
# show BatchDialog
proc showBatchDialog {} {
	global globalparms
	global dpi_dlg
	global pixel_dlg
	global quality_dlg
	
	toplevel .batchDialog
	wm withdraw .batchDialog

	#set vars for dialog
	set dpi_dlg $globalparms(dpi_batch)
	set pixel_dlg $globalparms(pixel_w_batch)
	set quality_dlg $globalparms(quality_batch)
	set msg "Settings for Batch Scaling of Images\nIf Quality is not between 50-100: 100 is used \n \
					   Quality is used in jpg images only\nImage types: tiff jpg png"
	
	ttk::frame .batchDialog.f -relief flat
	ttk::labelframe .batchDialog.f.lf -text $msg ; # labelframe which contains below
	ttk::label .batchDialog.f.lf.lbdpi -text "DPI: Max 4800 "
	ttk::entry .batchDialog.f.lf.dpi -textvariable dpi_dlg
	ttk::label .batchDialog.f.lf.lbpixel -text "Pixels Max height or width "
	ttk::entry .batchDialog.f.lf.pixel -textvariable pixel_dlg
	ttk::label .batchDialog.f.lf.lbquality -text "Quality between 50-100 "
	ttk::entry .batchDialog.f.lf.quality -textvariable quality_dlg
	
	grid config .batchDialog.f.lf.lbdpi \
		-column 0 -row 0 -sticky e
	grid config .batchDialog.f.lf.dpi \
		-column 1 -row 0 -sticky e
	grid config .batchDialog.f.lf.lbpixel \
		-column 0 -row 1 -sticky e
	grid config .batchDialog.f.lf.pixel \
		-column 1 -row 1 -sticky e
	grid config .batchDialog.f.lf.lbquality \
		-column 0 -row 2 -sticky e
	grid config .batchDialog.f.lf.quality \
		-column 1 -row 2 -sticky e

	pack .batchDialog.f.lf -padx 5 -pady 5

	# action buttons
	ttk::frame .batchDialog.fbut -relief flat
	ttk::button .batchDialog.fbut.ok -text "Ok" \
		-command "batchDialogOK dpi_dlg pixel_dlg quality_dlg"
	ttk::button .batchDialog.fbut.cancel -text "Cancel" \
		-command "batchDialogCancel"
	#arrange buttons
	pack .batchDialog.fbut.ok -side left
	pack .batchDialog.fbut.cancel -side right
	pack .batchDialog.fbut -side bottom -padx 5 -pady 5
	pack .batchDialog.f
	
	#window manager
	wm title .batchDialog "Settings"
	wm protocol .batchDialog WM_DELETE_WINDOW {
		.batchDialog.fbut.cancel invoke
	}
	wm transient .batchDialog .
	::tk::PlaceWindow .batchDialog widget .
	# display
	wm deiconify .batchDialog
	
}
######### END batchDialog ########

######### BEGIN SWELL DIALOG #########
# cancel swellDialog
proc swellDialogCancel {} {
	destroy .swellDialog
}
# ok swellDialog
proc swellDialogOK {swell_dlg} {
	global globalparms
	upvar $swell_dlg swell_value
	
	#if {[string is integer -strict $swell_value]} {
	#	if {$swell_value < 1} {
	#		set $swell_value 1
	#	}
	#}
	if {[string is integer -strict $swell_value]} {
		if {(($swell_value > 0) && ($swell_value < 21))} {
			set globalparms(set_swell) $swell_value
		} else {
			set msg "Value needs to be a whole number between 1-20"
			set reply [tk_messageBox -parent .swellDialog -message $msg \
				-icon warning -type ok]
			return
		}
	} else {
		set msg "Value needs to be a whole number between 1-20"
		set reply [tk_messageBox -parent .swellDialog -message $msg \
			-icon warning -type ok]
		return
	}
	
	unset swell_value
	
	destroy .swellDialog
}

# show SwellDialog
proc showSwellDialog {} {
	global globalparms
	global swell_dlg ; # this is a value held by the entry widget
	
	#set value for the entry field 
	set swell_dlg $globalparms(set_swell)
	
	toplevel .swellDialog
	wm withdraw .swellDialog
	update idletasks
	
	#set vars for dialog
	set swell $globalparms(set_swell)
	set msg "This setting sets the thickness of the swell, 1 is the default. \n \
			 The number should be whole number and the larger the swell \n \
			 the longer it takes to process. \n \
			 Max thickness is 20."
			 
	ttk::frame .swellDialog.f -relief flat
	ttk::labelframe .swellDialog.f.lf -text $msg
	ttk::label .swellDialog.f.lf.lbswell -text "Swell Value "
	ttk::entry .swellDialog.f.lf.swell -textvariable swell_dlg
	
	grid config .swellDialog.f.lf.lbswell \
		-column 0 -row 0 -sticky e
	grid config .swellDialog.f.lf.swell \
		-column 1 -row 0 -sticky e
	
	pack .swellDialog.f.lf -padx 5 -pady 5
	
	#action buttons
	ttk::frame .swellDialog.fbtn -relief flat
	ttk::button .swellDialog.fbtn.ok -text "Ok" \
		-command "swellDialogOK swell_dlg"
	ttk::button .swellDialog.fbtn.cancel -text "Cancel" \
		-command "swellDialogCancel"
		
	#arrange buttons
	pack .swellDialog.fbtn.ok -side left
	pack .swellDialog.fbtn.cancel -side right
	pack .swellDialog.fbtn -side bottom -padx 5 -pady 5
	pack .swellDialog.f
	
	#window manager
	wm title .swellDialog "Stroke settings"
	wm protocol .swellDialog WM_DELETE_WINDOW {
		.swellDialog.fbtn.cancel invoke
	}
	wm transient .swellDialog .
	#::tk::PlaceWindow .swellDialog . # this places it in center of screen
	::tk::PlaceWindow .swellDialog widget .
	#::tk::PlaceWindow .swellDialog widget .
	#wm transient .swellDialog [winfo toplevel [winfo parent .swellDialog]]
	wm deiconify .swellDialog
	
	#make it modal - works as above but not modal
	# we need to really make this modal
	catch {tk visibility .swellDialog}
	focus .swellDialog.f.lf.swell
	catch {grab set .swellDialog}
	catch {tkwait window .swellDialog}
	
}

######### END SWELL DIALOG ##########
######### NUMBER COPIES DIALOG #######
proc numCopiesDlgCancel {status} {
	global printer_copies
	set printer_copies 1
	
	destroy .numcopiesDlg
}
proc numCopiesDlgOk {status} {
	variable num_copies
	global printer_copies ; # app level
	
	
	if {[string is integer -strict $num_copies]} {
		if {$num_copies > 0} {
			set printer_copies $num_copies
		} else {
			set printer_copies 1
		}
	} else {
		set msg "Please enter valid number"
		set reply [tk_messageBox -parent .numcopiesDlg -message $msg -icon warning -type ok]
		return
	}
	upvar $status status_alis
	set status_alis "true"
	#set status "true"
	
	destroy .numcopiesDlg

}
proc showNumCopiesDlg {status} {
	if {[catch {toplevel .numcopiesDlg } result]} {
		puts $result
		.txt insert end "Error: $result\n"
		.txt insert end "$LINE" lineColor
		return
	}
	wm title .numcopiesDlg {Number of Copies}
	#wm withdraw .numcopiesDlg
	
	global printer_copies ; #from main app
	variable num_copies ; # for internal dialog
	set num_copies 1
	
	set printer_copies 1 ; # the global app var
	
	ttk::frame .numcopiesDlg.f -relief flat
	ttk::labelframe .numcopiesDlg.f.lf -text "Number of copies"
	ttk::label .numcopiesDlg.f.lf.lbCopies -text "Enter Copies :"
	ttk::entry .numcopiesDlg.f.lf.copies -textvariable num_copies -width 10
	
	grid config .numcopiesDlg.f.lf.lbCopies \
		-column 0 -row 0 -sticky w
	grid config .numcopiesDlg.f.lf.copies \
		-column 1 -row 0 -sticky w
	pack .numcopiesDlg.f.lf -padx 5 -pady 5
	
	#buttons
	ttk::frame .numcopiesDlg.fbtn -relief flat
	ttk::button .numcopiesDlg.fbtn.ok -text "Ok" \
		-command "numCopiesDlgOk status"
	ttk::button .numcopiesDlg.fbtn.cancel -text "Cancel" \
		-command "numCopiesDlgCancel status"
		
	#arrange buttons
	pack .numcopiesDlg.fbtn.ok -side left
	pack .numcopiesDlg.fbtn.cancel -side right
	pack .numcopiesDlg.fbtn -side bottom -side bottom -padx 5 -pady 5
	pack .numcopiesDlg.f
	
	#window manage
	wm protocol .numcopiesDlg WM_DELETE_WINDOW {
		.numcopiesDlg.fbtn.cancel invoke
	}
	wm transient .numcopiesDlg .
	::tk::PlaceWindow .numcopiesDlg widget .
	wm deiconify .numcopiesDlg
	
	#make it modal
	catch {tk visibility .numcopiesDlg}
	focus .numcopiesDlg.f.lf.copies
	catch {grab set .numcopiesDlg}
	catch {tkwait window .numcopiesDlg}
	
}
######## END NUMBER COPIES DIALOG ######
######### PAGE SIZE DIALOG ####### marked
###to manually put in page size if MediaBox not found ###
proc pagesizeDlgCancel {} {
	global printsize_dlg
	set printsize_dlg 0x0
	destroy .pagesizeDlg
}
proc pagesizeDlgOk {} {
	# return a string like 8.5x11 - will be split after retuning value
	global pagewidth
	global pageheight
	global printsize_dlg
	
	if {[string is double -strict $pagewidth]} {
		if {$pagewidth eq 0} {
			set msg "Enter a page width larger than 0"
			set reply [tk_messageBox -parent .pagesizeDlg -message $msg -icon warning -type ok]
			return
		}
	} else {
		set msg "Enter a page width with a valid number"
		set reply [tk_messageBox -parent .pagesizeDlg -message $msg -icon warning -type ok]
		return	
	}
	if {[string is double -strict $pageheight]} {
		if {$pageheight eq 0} {
			set msg "Enter a page width larger than 0"
			set reply [tk_messageBox -parent .pagesizeDlg -message $msg -icon warning -type ok]
			return
		}
	} else {
		set msg "Enter a page width with a valid number"
		set reply [tk_messageBox -parent .pagesizeDlg -message $msg -icon warning -type ok]
		return	
	}
	#upvar printsize printsize_v
	set printsize_dlg "$pagewidth\x$pageheight"
	destroy .pagesizeDlg
	
}
proc showPagesizeDlg {} {
	global pagewidth
	global pageheight
	
	toplevel .pagesizeDlg
	wm withdraw .pagesizeDlg
	
	set pagewidth 0
	set pageheight 0
	set msg "Could not find page size from the pdf.\n \
			If you know the size of the page to be printed\n \
			enter below and press Ok"
	
	ttk::frame .pagesizeDlg.f -relief flat
	ttk::labelframe .pagesizeDlg.f.lf -text $msg
	ttk::label .pagesizeDlg.f.lf.lbwidth -text "Width"
	ttk::label .pagesizeDlg.f.lf.lbheight -text "Height"
	ttk::entry .pagesizeDlg.f.lf.width -textvariable pagewidth -width 8
	ttk::entry .pagesizeDlg.f.lf.height -textvariable pageheight -width 8
	
	grid config .pagesizeDlg.f.lf.lbwidth \
		-column 0 -row 0 -sticky w
	grid config .pagesizeDlg.f.lf.lbheight \
		-column 1 -row 0 -sticky w
	grid config .pagesizeDlg.f.lf.width \
		-column 0 -row 1 -sticky w
	grid config .pagesizeDlg.f.lf.height \
		-column 1 -row 1 -sticky w
		
	pack .pagesizeDlg.f.lf -padx 5 -pady 5
	
	#action buttons
	ttk::frame .pagesizeDlg.fbtn -relief flat
	ttk::button .pagesizeDlg.fbtn.ok -text "Ok" \
		-command "pagesizeDlgOk" 
	ttk::button .pagesizeDlg.fbtn.cancel -text "Cancel" \
		-command "pagesizeDlgCancel"
		
	#arrange buttons
	pack .pagesizeDlg.fbtn.ok -side left
	pack .pagesizeDlg.fbtn.cancel -side right
	pack .pagesizeDlg.fbtn -side bottom -padx 5 -pady 5
	pack .pagesizeDlg.f
	
	#window mangage
	wm title .pagesizeDlg "Page Size"
	wm protocol .pagesizeDlg WM_DELETE_WINDOW {
		.pagesizeDlg.fbtn.cancel invoke
	}
	wm transient .pagesizeDlg .
	::tk::PlaceWindow .pagesizeDlg widget .
	wm deiconify .pagesizeDlg
	
	#make it modal - works as above but not modal
	#below makes it modal
	catch {tk visibility .pagesizeDlg}
	focus .pagesizeDlg.f.lf.width
	catch {grab set .pagesizeDlg}
	catch {tkwait window .pagesizeDlg}
	
}
######## END SIZE DIALOG ########

proc printerProfilesWin {} {
	global script_path
	source "$script_path/prepress-printers.tcl"
	
}

set script_path [ file dirname [ file normalize [ info script ] ] ]
puts "script_path: $script_path"
lappend auto_path "$script_path/lib/"
#lappend auto_path "$script_path/lib/tablelist"

#lappend auto_path "$script_path/lib/sqlite3"

initParams
# load message catalogs
msgcat::mclocale $globalparms(locale)
msgcat::mcload [file join [file dirname [info script]] msgs]
creategui

#puts $auto_path


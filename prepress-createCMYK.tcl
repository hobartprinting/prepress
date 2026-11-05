## source file created 11-3-2026
## PrePress Copyright 2008 Randall J Hobart
## createCMYKdlg
# filename prepress-createCMYK.tcl

# Find the file that represents the cyan channel
proc find_c_File {} {
	global c_file_full
	global c_file ; # just then name without the path
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert "Find cyan file canceled\n"
		return
	}
	set filename [file nativename $filename] ; # for windows over network
	set c_file [file tail $filename]
	set c_file_full $filename
	.txt insert end "full path to cyan file: $c_file_full\n"
	
}
# Find the file that represents the magenta channel
proc find_m_File {} {
	global m_file_full
	global m_file
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert "Find magenta file canceled\n"
		return
	}
	set filename [file nativename $filename] ; # for windows over network
	set m_file [file tail $filename]
	set m_file_full $filename
	.txt insert end "full path to magenta file: $m_file_full\n"
}
# Find the file that represents the yellow channel
proc find_y_File {} {
	global y_file_full
	global y_file
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert "Find yellow file canceled\n"
		return
	}
	set filename [file nativename $filename] ; # for windows over network
	set y_file [file tail $filename]
	set y_file_full $filename
	.txt insert end "full path to yellow file: $y_file_full\n"
}
# Find the file that represents the black channel
proc find_k_File {} {
	global k_file_full
	global k_file
	set types {
		{TIFF .tiff}
		{TIF .tif}
		{png .png}
		{jpeg .jpeg}
		{jpg .jpg}
	}
	
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename eq ""} {
		.txt insert "Find black file canceled\n"
		return
	}
	set filename [file nativename $filename] ; # for windows over network
	set k_file [file tail $filename]
	set k_file_full $filename
	.txt insert end "full path to black file: $k_file_full\n"
}

proc cmykDlgOK {} {
	global c_file_full
	global m_file_full
	global y_file_full
	global k_file_full
	global convert
	global LINE
	set errorsum ""
	
	if {$c_file_full eq "false"} {
		set errorsum "$errorsum Please find cyan file\n"		
	}
	if {$m_file_full eq "false"} {
		set errorsum "$errorsum Please find magenta file\n"
	}
	if {$y_file_full eq "false"} {
		set errorsum "$errorsum Please find yellow file\n"
	}
	if {$k_file_full eq "false"} {
		set errorsum "$errorsum Please find black file\n"
	}
	# check for errors
	if {[string length $errorsum] ne 0} {
		set reply [tk_messageBox -parent .cmykDlg -message $errorsum -icon warning -type ok]
		return	
	}
	set fileroot [file rootname [file tail $c_file_full]] ; #returns file with no extension or directory
	set filedir [file dir $c_file_full] ; # returns directory
	set newroot [string map -nocase {"cyan" ""} $fileroot]
	set newpartfile "-CMYK.tiff"
	set newfilename "$filedir[file separator]$newroot$newpartfile"
	#create the cmyk tiff file
	set cmd_options [list $c_file_full $m_file_full $y_file_full $k_file_full -set colorspace CMYK -negate -combine $newfilename]
	set cmd "$convert"
	
	if {[catch {exec $cmd {*}$cmd_options} result]} {
		.txt insert end "Error: $result\n"	
	} else {
		.txt insert end "File created: [file tail $newfilename]\n"
		
	}
	.txt insert end "Directory containing files: \n"
	.txt insert end "$filedir" dirHyperlink
	.txt insert end "\n"
	.txt insert end "$LINE" lineColor
	
	destroy .cmykDlg
}
proc cmykDlgCancel {} {
	global LINE
	
	.txt insert end "Canceled\n"
	.txt insert end "$LINE" lineColor
	destroy .cmykDlg
}
proc showCMYKdlg {} {
	global c_file ; # this is value needed by the entry widget for cyan
	global m_file ; # value
	global y_file ; # value
	global k_file ; # value
	
	# for the full paths
	global c_file_full ; set c_file_full "false"
	global m_file_full ; set m_file_full "false"
	global y_file_full ; set y_file_full "false"
	global k_file_full ; set k_file_full "false"
	
	global LINE
	
	.txt insert end $LINE lineColor
	
	.txt insert end "proc: showCMYKdlg\n" procColor
	.txt insert end "Purpose: Select 4 grayscale images and create 1 CMYK image tiff"
	
	
	toplevel .cmykDlg
	wm withdraw .cmykDlg
	
	set msg "Select a grayscale image for each color channel\n"
	ttk::frame .cmykDlg.fr -relief flat
	ttk::labelframe .cmykDlg.fr.lbfr -text $msg
	
	ttk::label .cmykDlg.fr.lbfr.lbcyan -text "cyan file"
	ttk::entry .cmykDlg.fr.lbfr.cyan -textvariable c_file -width 40 ; # -state disabled
	
	ttk::label .cmykDlg.fr.lbfr.lbmagenta -text "magenta file"
	ttk::entry .cmykDlg.fr.lbfr.magenta -textvariable m_file -width 40
	
	ttk::label .cmykDlg.fr.lbfr.lbyellow -text "yellow file"
	ttk::entry .cmykDlg.fr.lbfr.yellow -textvariable y_file -width 40
	
	ttk::label .cmykDlg.fr.lbfr.lbblack -text "black file"
	ttk::entry .cmykDlg.fr.lbfr.black -textvariable k_file -width 40
	
	ttk::button .cmykDlg.fr.lbfr.getfile_c -text "find cyan file" \
		-command "find_c_File"
	ttk::button .cmykDlg.fr.lbfr.getfile_m -text "find magenta file" \
		-command "find_m_File"
	ttk::button .cmykDlg.fr.lbfr.getfile_y -text "find yellow file" \
		-command "find_y_File"
	ttk::button .cmykDlg.fr.lbfr.getfile_k -text "find black file" \
		-command "find_k_File"
		
	grid config .cmykDlg.fr.lbfr.getfile_c \
		-column 0 -row 0 -sticky e
	grid config .cmykDlg.fr.lbfr.lbcyan \
		-column 1 -row 0 -sticky e
	grid config .cmykDlg.fr.lbfr.cyan \
		-column 2 -row 0 -sticky e
		
	grid config .cmykDlg.fr.lbfr.getfile_m \
		-column 0 -row 1 -sticky e
	grid config .cmykDlg.fr.lbfr.lbmagenta \
		-column 1 -row 1 -sticky e
	grid config .cmykDlg.fr.lbfr.magenta \
		-column 2 -row 1 -sticky e
		
	grid config .cmykDlg.fr.lbfr.getfile_y \
		-column 0 -row 2 -sticky e
	grid config .cmykDlg.fr.lbfr.lbyellow \
		-column 1 -row 2 -sticky e
	grid config .cmykDlg.fr.lbfr.yellow \
		-column 2 -row 2 -sticky e
		
	grid config .cmykDlg.fr.lbfr.getfile_k \
		-column 0 -row 3 -sticky e
	grid config .cmykDlg.fr.lbfr.lbblack \
		-column 1 -row 3 -sticky e
	grid config .cmykDlg.fr.lbfr.black \
		-column 2 -row 3 -sticky e
		
	pack .cmykDlg.fr.lbfr -padx 5 -pady 5
	pack .cmykDlg.fr
	
	#action buttons
	ttk::frame .cmykDlg.fbut -relief flat
	ttk::button .cmykDlg.fbut.ok -text "Ok" \
		-command "cmykDlgOK"
	ttk::button .cmykDlg.fbut.cancel -text "Cancel" \
		-command "cmykDlgCancel"
	# arrange buttons
	pack .cmykDlg.fbut.ok -side left
	pack .cmykDlg.fbut.cancel -side right
	pack .cmykDlg.fbut -side bottom -padx 5 -pady 5
	pack .cmykDlg.fbut
	
	#window manager
	wm title .cmykDlg "Create CMYK File"
	wm protocol .cmykDlg WM_DELETE_WINDOW {
		.cmykDlg.fbut.cancel invoke
	}
	wm transient .cmykDlg .
	::tk::PlaceWindow .cmykDlg widget .
	
	#display
	wm deiconify .cmykDlg
	
	#make mobal
	catch {tk visibility .cmykDlg}
	focus .cmykDlg.fr.lbfr.getfile_c
	catch {grab set .cmykDlg}
	catch {tkwait window .cmykDlg}
	
}


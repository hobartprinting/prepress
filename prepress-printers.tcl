#!/usr/bin/env tclsh 
## Printer Profile window
## Filename: prepress-printers.tcl
## Examples of tablelist
## https://www.mrc-lmb.cam.ac.uk/harry/imosflm/ver721/downloads/imosflm/lib/tablelist3.7/doc/tablelist.html
## https://www.nemethi.de/tablelist/tablelist.html
## https://core.tcl-lang.org/tklib/raw/modules/tablelist/doc/tablelist.html?name=bc8f7e18bc065afb5f0dd7c3283a8ed07a7c798a#ex_browse
## https://stackoverflow.com/questions/33610524/command-whenever-an-item-in-a-tablelist-is-selected-in-tcl#33637784

package require Tk
package require tablelist_tile
#package require sqlite3
#load ./lib/sqlite3/sqlite3
puts "script_path: $script_path"
#load $script_path/lib/sqlite3/sqlite3

global globalparms ; # from main app
global dict_printers ; #from main app
global LINE
global printer_default
global rowSelected

######### Concepts ##############
#	uses dict_printers from the main program starting point - window .  ; # the . is the main toplevel window
#		this files main window is .printers
#		dict_printers is a nested dictionary of a dictionary of printer - dict_printers -> {integer} {dictprinter}
#	3 modal dialogs - 1 for each of the different kinds of printers - "Color Toner" "Mono Toner" "Ink Jet"
#	.printers.colorlaserDlg 
#		# mode has value "NEW" or "EDIT" - selected_printer value is 0 in new mode and the selected integer value in EDIT mode
#		proc name: proc showColorLaserDlg {mode selected_printer}
#		proc name: proc colorLaserOk {mode selected_printer}
#		proc name: proc colorLaserCancel {}
#	.printers.monolaserDlg
#		# mode has value "NEW" or "EDIT" - selected_printer value is 0 in new mode and the selected integer value in EDIT mode
#		proc name: proc showMonoLaserDlg {mode selected_printer}
#		proc name: proc monoLaserOk {mode selected_printer}
#		proc name: proc monoLaserCancel {}

set rowSelected "none"

# toplevel .printers -width 640 -height 400
if {[catch {toplevel .printers } result]} {
	puts $result
	.txt insert end "Info: $result\n"
	.txt insert end "$LINE" lineColor
	wm attributes .printers -topmost true
	wm attributes .printers -topmost false
	return
}
wm title .printers {Printer Profiles}

option add *Tablelist.stripeBackground gray93
option add *Tablelist.labelCommand tablelist::sortByColumn
option add *Menu.tearOff 0 ; # ignored by mac

# toplevel .printers -width 600 -height 400 -background silver
#ttk::frame .printers.fProfiles -relief flat
#ttk::labelframe .printers.lbf -text "Printer Profiles" ; # -width 50 ; # no -padx or -pady options
tablelist::tablelist .printers.table \
	-columns {0 "id" left 0 "Printer" left 0 "Kind" left 0 "Description" left}  \
	-stretch all -background white \
	-xscroll {.printers.h set} -yscroll {.printers.v set}	
scrollbar .printers.v -orient vertical   -command {.printers.table yview}
scrollbar .printers.h -orient horizontal -command {.printers.table xview}

.printers.table columnconfigure 0 -hide yes
.printers.table configure -showseparators yes
#.printers.table columnconfigure 0 -name Printer
# bind 
bind .printers.table <<TablelistSelect>> [list printerSelected %W]
bind .printers.table <<TablelistColumnSorted>> [list rowMoved %W]
grid .printers.table .printers.v -sticky nsew
grid .printers.h -sticky nsew

# Tell the tablelist widget to take all the extra room
grid rowconfigure    .printers .printers.table -weight 1
grid columnconfigure .printers .printers.table -weight 1

#fill the table with printer profiles
set row 0
foreach key_of_dicts [dict keys $dict_printers] {
	#puts "key for table:  $key_of_dicts ------"
	set theprinter [dict get $dict_printers $key_of_dicts]
	set printername [dict get $theprinter printer]
	set kind [dict get $theprinter kind]
	set desc [dict get $theprinter description]
	#puts "in list are $key_of_dicts $kind $desc"
	#check for a prev selected default printer
	if {$globalparms(defaultprinter) eq $key_of_dicts} {
		set printername "*$printername"
	}
	.printers.table insert end [list "$key_of_dicts" "$printername" "$kind" "$desc"]
	if {$globalparms(defaultprinter) eq $key_of_dicts} {
		.printers.table rowconfigure $row -fg red
	}
	incr row
}

#ttk::labelframe .printers.fbuttons -text "Profiles"  ; # no -padx or -pady commands

# create label for the buttons to be contained in
ttk::label .printers.lb -text ""  ; # no -padx or -pady commands
ttk::button .printers.lb.newProfile -text "New" -command { showNewProfileDialog }
ttk::button .printers.lb.editProfile -text "Edit" -command { editProfile }
ttk::button .printers.lb.deleteProfile -text "Delete" -command {deleteProfile}
ttk::button .printers.lb.defaultProfile -text "*Default" -command {defaultProfile}
ttk::button .printers.lb.exportProfile -text "Export" -command {exportProfile}
ttk::button .printers.lb.importProfile -text "Import" -command {importProfile}

grid config .printers.lb.newProfile -column 0 -row 0 
grid config .printers.lb.editProfile -column 1 -row 0
grid config .printers.lb.deleteProfile -column 2 -row 0
grid config .printers.lb.defaultProfile -column 3 -row 0	
grid config .printers.lb.exportProfile -column 4 -row 0
grid config .printers.lb.importProfile -column 5 -row 0

grid .printers.lb -sticky w

#add a popup menu
#create popupmenu - mac right mouse button is 2; win/unix right button is 3
global mp ; # WOW on a toplevel window such as .name this must be declared global, on . did not
set mp [menu .printers.popupMenu]
$mp add command -label "New Printer Profile..." -command {showNewProfileDialog}
$mp add command -label "Edit Selected Profile..." -command {editProfile}
$mp add separator
$mp add command -label "Delete Selected Profile..." -command {deleteProfile}
$mp add separator
$mp add command -label "Default Profile" -command {defaultProfile}
#puts $mp
if {[tk windowingsystem] == "aqua"} {
	bind .printers <ButtonPress-2> {tk_popup $mp %X %Y}
	bind .printers <Control-ButtonPress-1> {tk_popup $mp %X %Y}
} else {
	bind .printers <ButtonPress-3> {tk_popup $mp %X %Y}
}



proc printerSelected {w} {
	global rowSelected
	set rowSelected [$w curselection]
	#test
	puts "rowSelected $rowSelected"
	set printerId [.printers.table getcells $rowSelected,0]
	set aprinter [.printers.table getcells $rowSelected,1]
	set kind [.printers.table getcells $rowSelected,2]
	set desc [.printers.table getcells $rowSelected,3]
	puts "printer: $printerId | $aprinter | $kind | $desc"
}
proc rowMoved {w} {
	global rowSelected
	if {[$w curselection] ne ""} {
		set rowSelected [$w curselection]
	} else {
		set rowSelected [$w curselection]
	}	
	#puts "rowmoved: $w"
	#puts "rowmoved current selection:[$w curselection]"
	#puts "rowSelected $rowSelected"
}
#This would be from the button New
#Find out which kind
proc newProfile {} {
	showNewProfile ; # this will show a modal dialog with 3 options
}

proc editProfile {} {
	global rowSelected

	if {$rowSelected ne "none"} {		
		set id [.printers.table getcells $rowSelected,0]
		set kind [.printers.table getcells $rowSelected,2]
		if {$kind eq "Color Toner"} {
			showColorLaserDlg "EDIT" $id
			puts "the kind $kind"
		} elseif {$kind eq "Mono Toner"} {
			showMonoLaserDlg "EDIT" $id
		} elseif {$kind eq "Ink Jet"} {
			showInkJetDlg "EDIT" $id
		} else {
			set reply [tk_messageBox -parent .printers -message "Error: Could not find the KIND of profile" -icon warning -type ok]	
		}
	} else {
		#message box
		set reply [tk_messageBox -parent .printers -message "Please select or reselect a row to edit" -icon warning -type ok]
		
	}
}
proc deleteProfile {} {
	global rowSelected
	global dict_printers
	global globalparms
	if {$rowSelected ne "none"} {
		set id [.printers.table getcells $rowSelected,0]
		set printername [.printers.table getcells $rowSelected,1]
		set printerkind [.printers.table getcells $rowSelected,2]
		set printerdesc [.printers.table getcells $rowSelected,3]
		set msg "This will delete the selected printer \n \
					$printername\n \
					$printerkind\n \
					$printerdesc\n \
					Are you sure?"
		set reply [tk_messageBox -parent .printers -message $msg -icon question -type yesno]
		if {$reply eq "yes"} {
			.printers.table delete $rowSelected ; # the selected row
			set rowSelected "none"
			dict unset dict_printers $id ; # not the row number
			if {$globalparms(defaultprinter) eq $id} {
				set globalparms(defaultprinter) "none"
			}
			savePrinters ; # will save the dict_printers to disk
		}
	} else {
		set reply [tk_messageBox -parent .printers -message "Please select or reselect a row to edit" -icon warning -type ok]
	}
	#find the selected row and get some info
	
	
}
proc defaultProfile {} {
	global globalparms
	global rowSelected
	global dict_printers
	puts "from defaultProfile"
	puts "global default printer: $globalparms(defaultprinter)"
	if {$rowSelected ne "none"} {
		set id_sel [.printers.table getcells $rowSelected,0]
		set theprinter_sel [.printers.table getcells $rowSelected,1]
		set thekind_sel [.printers.table getcells $rowSelected,2]
		set thedesc_sel [.printers.table getcells $rowSelected,3]
		puts "id_sel $id_sel"
		if {$globalparms(defaultprinter) eq "none"} {
			.printers.table rowconfigure $rowSelected -fg red
			set theprinter_sel "*$theprinter_sel"
			puts "printer sel: $theprinter_sel"
			.printers.table rowconfigure $rowSelected -text [list $id_sel $theprinter_sel $thekind_sel $thedesc_sel]
			set globalparms(defaultprinter) $id_sel
		} else {
			# there was a prev default printer - change it back to normal
			if {$id_sel eq $globalparms(defaultprinter)} {
				puts "already default printer"
				set reply [tk_messageBox -parent .printers -message "Printer is already the default printer." -icon warning -type ok]
				return
			}
			set row 0
			while {$row < [.printers.table size]} {
				set theid [.printers.table getcells $row,0]
				if {$globalparms(defaultprinter) eq $theid} {
					set default_printer [.printers.table getcells $row,1]
					set clean_default_printer [string map -nocase {"*" ""} $default_printer]
					set default_kind [.printers.table getcells $row,2]
					set default_desc [.printers.table getcells $row,3]
					.printers.table rowconfigure $row -fg black
					.printers.table rowconfigure $row -text [list $theid $clean_default_printer $default_kind $default_desc]
				}	
				incr row								
			}
			# out of the while loop - the prev default is normal in the table now
			#	set a new default printer based on the selected row 
			# Below is a repeat of the above if the global defaultprinter eq 'none' 
			.printers.table rowconfigure $rowSelected -fg red
			set theprinter_sel "*$theprinter_sel"
			.printers.table rowconfigure $rowSelected -text [list $id_sel $theprinter_sel $thekind_sel $thedesc_sel]
			set globalparms(defaultprinter) $id_sel
		}		
	} else {
		set reply [tk_messageBox -parent .printers -message "Please select or reselect a row for defaultprinter" -icon warning -type ok]
	}
}
proc exportProfile {} {
	global rowSelected
	global dict_printers
	
	if {$rowSelected ne "none"} {
		set id_sel [.printers.table getcells $rowSelected,0]
		set theprinter [dict get $dict_printers $id_sel]
		#next save the printer - get the name of the printer and that will be the filename
		set printer_name [dict get $theprinter printer]
		
		set thefile "$printer_name.profile"
		set types { {{Profile Files} {.cov}} }
		set filename [tk_getSaveFile -filetypes $types -initialfile $thefile]
		if {$filename ne ""} {
			puts "file to save: $filename"
			set channel [open $filename w]
			fconfigure $channel -translation lf -encoding utf-8
			puts $channel $theprinter
			close $channel
		}
	} else {
		set reply [tk_messageBox -parent .printers -message "Please select or reselect a row for exporting" -icon warning -type ok]
	}
}
proc importProfile {} {
	global dict_printers
	
	set types { {{Profile Files} {.cov}} }
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename ne ""} {
		set channel [open $filename r]
		fconfigure $channel -translation lf -encoding utf-8
		set printer [read $channel]
		close $channel
	} else {
		return
	}
	#a small validation of the opened file
	puts "dict size of printer: [dict size $printer]"
	set kind [dict get $printer kind]
	if {$kind eq "Color Toner" || $kind eq "Mono Toner" || $kind eq "Ink Jet"} {} else {
		set reply [tk_messageBox -parent .printers -message "Error: Could not find the KIND of profile" -icon warning -type ok]	
		return
	}
	
	if {[dict size $dict_printers] eq 0} {
		dict append $dict_printers 1 $printer
		.printers.table insert end [list 1 [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
	} else {
		#add it after the last id ; it does not matter if there is another printer by the same name
		set index 0
		foreach key_of_dicts [dict keys $dict_printers] {
			# get the largest key - note key numbers on this dict are integer
			if {$index < $key_of_dicts} {
				set index $key_of_dicts
			}			
		}
		incr index
		dict append dict_printers $index $printer
		.printers.table insert end [list $index [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
	}
	savePrinters
}
proc savePrinters {} {
	global globalparms
	global dict_printers
	set printersFile $globalparms(cache_path)[file separator]$globalparms(printers_inkcoverage)
	set channel [open $printersFile w]
	fconfigure $channel -translation lf -encoding utf-8
	puts $channel $dict_printers
	close $channel
}
proc openPrinters {} {
	global globalparms
	global dict_printers
	set printersFile $globalparms(cache_path)[file separator]$globalparms(printers_inkcoverage)
	if {[file exists $printersFile]} {
		set channel [open $printersFile r]
		fconfigure $channel -translation lf -encoding utf-8
		set dict_printers [read $channel]
		close $channel
	}
}


puts "from printers:  $globalparms(dpi)"

#### All Dlg's below here #####

#################### New or Edit Mono Laser Profile Dlg ##############################
#### mode will be "NEW" or "EDIT" ; selected_printer will be 0 for none or the index of the dictionary to be edited
proc inkJetOk {mode selected_printer} {
	global globalparms ; #need this to make sure the default printer is still indicated by * and red type
	global dict_printers
	set errorsum ""
	
	global inkjet_printer_name ; global inkjet_desc; #global inkjet_kind
	global inkjet_cyan_unit; global inkjet_cyan_yield; global inkjet_cyan_percent
	global inkjet_magenta_unit; global inkjet_magenta_yield; global inkjet_magenta_percent
	global inkjet_yellow_unit; global inkjet_yellow_yield; global inkjet_yellow_percent
	global inkjet_black_unit; global inkjet_black_yield; global inkjet_black_percent
	global inkjet_spot_unit; global inkjet_spot_yield; global inkjet_spot_percent
	
	#validate entries
	## printer name
	if {[string length $inkjet_printer_name] > 3} {} else {set errorsum "$errorsum Error: Printer Name needs min 4 characters\n"}
	
	# ink cyan
	if {[string is double -strict $inkjet_cyan_unit]} {
		if {$inkjet_cyan_unit eq 0 || $inkjet_cyan_unit < 0} {
			set errorsum "$errorsum Error: Cyan ink cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Cyan ink cost\n" }
	if {[string is double -strict $inkjet_cyan_yield]} {
		if {$inkjet_cyan_yield eq 0 || $inkjet_cyan_yield < 0} {
			set errorsum "$errorsum Error: Cyan ink yield cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Cyan ink yield\n" }
	if {[string is double -strict $inkjet_cyan_percent]} {
		if {$inkjet_cyan_percent eq 0 || $inkjet_cyan_percent < 0} {
			set errorsum "$errorsum Error: Cyan percent coverage cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Cyan percent coverage\n" }
	
	# ink magenta
	if {[string is double -strict $inkjet_magenta_unit]} {
		if {$inkjet_magenta_unit eq 0 || $inkjet_magenta_unit < 0} {
			set errorsum "$errorsum Error: Magenta ink cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Magenta ink cost\n" }
	if {[string is double -strict $inkjet_magenta_yield]} {
		if {$inkjet_magenta_yield eq 0 || $inkjet_magenta_yield < 0} {
			set errorsum "$errorsum Error: Magenta ink yield cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Magenta ink yield\n" }
	if {[string is double -strict $inkjet_cyan_percent]} {
		if {$inkjet_magenta_percent eq 0 || $inkjet_magenta_percent < 0} {
			set errorsum "$errorsum Error: Magenta percent coverage cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Magenta percent coverage\n" }
	
	# ink yellow
	if {[string is double -strict $inkjet_yellow_unit]} {
		if {$inkjet_yellow_unit eq 0 || $inkjet_yellow_unit < 0} {
			set errorsum "$errorsum Error: Yellow ink cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Yellow ink cost\n" }
	if {[string is double -strict $inkjet_yellow_yield]} {
		if {$inkjet_yellow_yield eq 0 || $inkjet_yellow_yield < 0} {
			set errorsum "$errorsum Error: Yellow ink yield cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Yellow ink yield\n" }
	if {[string is double -strict $inkjet_yellow_percent]} {
		if {$inkjet_yellow_percent eq 0 || $inkjet_yellow_percent < 0} {
			set errorsum "$errorsum Error: Yellow percent coverage cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Yellow percent coverage\n" }
	
	# ink black
	if {[string is double -strict $inkjet_black_unit]} {
		if {$inkjet_black_unit eq 0 || $inkjet_black_unit < 0} {
			set errorsum "$errorsum Error: Black ink cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black ink cost\n" }
	if {[string is double -strict $inkjet_black_yield]} {
		if {$inkjet_black_yield eq 0 || $inkjet_black_yield < 0} {
			set errorsum "$errorsum Error: Black ink yield cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black ink yield\n" }
	if {[string is double -strict $inkjet_black_percent]} {
		if {$inkjet_black_percent eq 0 || $inkjet_black_percent < 0} {
			set errorsum "$errorsum Error: Black percent coverage cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black percent coverage\n" }
	
	# ink spot
	if {[string is double -strict $inkjet_spot_unit]} {
		if {$inkjet_spot_unit eq 0} {} ; #can be 0
		if {$inkjet_spot_unit < 0} {set errorsum "$errorsum Error: Spot ink cost cannot negative\n\tEnter 0 if not using\n"}		
	} else { set errorsum "$errorsum Error: Spot ink cost\n" }
	
	if {[string is double -strict $inkjet_spot_yield]} {
		if {$inkjet_spot_yield < 0} {set errorsum "$errorsum Error: Spot ink yield cannot be negative\n\tEnter 0 if not using\n"}		
	} else { set errorsum "$errorsum Error: Spot ink yield\n" }
	
	if {[string is double -strict $inkjet_spot_percent]} {
		if {$inkjet_spot_percent < 0} {set errorsum "$errorsum Error: Spot percent coverage cannot negative\n\tEnter 0 if not using\n"}	
	} else { set errorsum "$errorsum Error: Spot percent coverage\n" }
	
	#check for errors
	if {[string length $errorsum] ne 0} {
		# An error occurred.
		set reply [tk_messageBox -parent .printers.inkjetDlg -message $errorsum -icon warning -type ok]
		return
	}
	
	set printer [dict create \
		"printer" $inkjet_printer_name \
		"description" $inkjet_desc \
		"kind" "Ink Jet" \
		"cyan_unit" $inkjet_cyan_unit \
		"cyan_yield" $inkjet_cyan_yield \
		"cyan_percent" $inkjet_cyan_percent \
		"magenta_unit" $inkjet_magenta_unit \
		"magenta_yield" $inkjet_magenta_yield \
		"magenta_percent" $inkjet_magenta_percent \
		"yellow_unit" $inkjet_yellow_unit \
		"yellow_yield" $inkjet_yellow_yield \
		"yellow_percent" $inkjet_yellow_percent \
		"black_unit" $inkjet_black_unit \
		"black_yield" $inkjet_black_yield \
		"black_percent" $inkjet_black_percent \
		"spot_unit" $inkjet_spot_unit \
		"spot_yield" $inkjet_spot_yield \
		"spot_percent" $inkjet_spot_percent ]
	
	if {$mode eq "NEW"} {
		#dict append dict_printers $printer_name $printer
		if {[dict size $dict_printers] eq 0} {
			puts "dict size of dict_printers: [dict size $dict_printers]"
			dict append dict_printers 1 $printer
			.printers.table insert end [list 1 [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
		} else {
			puts "dict size of dict_printers is: [dict size $dict_printers]"
			set index 0
			foreach key_of_dicts [dict keys $dict_printers] {
				# get the largest key - note key numbers on this dict are integer
				if {$index < $key_of_dicts} {
					set index $key_of_dicts
				}			
			}
			incr index
			dict append dict_printers $index $printer
			.printers.table insert end [list $index [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
			puts "From inkJetOk: dict size of dict_printers now is: [dict size $dict_printers]"
			#puts "print dict: $dict_printers"
		}
	} else {
		#edit mode
		puts "edit mode selected printer index $selected_printer"
		dict unset dict_printers $selected_printer
		dict append dict_printers $selected_printer $printer
		set dict_printers [lsort -integer -index 0 -increasing -stride 2 $dict_printers]
		#dict update dict_printers $selected_printer $printer
		set id $selected_printer
		set theprinter [dict get $printer printer]
		set thekind [dict get $printer kind]
		set thedesc [dict get $printer description]
		if {$id eq $globalparms(defaultprinter)} {
			set theprinter "*$theprinter"
			.printers.table rowconfigure $::rowSelected -text [list $id $theprinter $thekind $thedesc]
			.printers.table rowconfigure $::rowSelected -fg red
		} else {
			.printers.table rowconfigure $::rowSelected -text [list $id $theprinter $thekind $thedesc]
		}
		
		puts "from edit size of dict: [dict size $dict_printers]"
		#puts "from edit then ok: $dict_printers"
	}
	savePrinters
	destroy .printers.inkjetDlg
}
proc inkJetCancel {} {
	destroy .printers.inkjetDlg
}
proc showInkJetDlg {mode selected_printer} {
	#global globalparms
	global dict_printers ; # need this var when in edit mode
	
	# these vars are for the values in the entry fields that must be passed globally to other procs such as ok proc then 
	# 	validated and put into dict_printers
	global inkjet_printer_name ; global inkjet_desc; #global inkjet_kind
	global inkjet_cyan_unit; global inkjet_cyan_yield; global inkjet_cyan_percent
	global inkjet_magenta_unit; global inkjet_magenta_yield; global inkjet_magenta_percent
	global inkjet_yellow_unit; global inkjet_yellow_yield; global inkjet_yellow_percent
	global inkjet_black_unit; global inkjet_black_yield; global inkjet_black_percent
	global inkjet_spot_unit; global inkjet_spot_yield; global inkjet_spot_percent
	
	# create the window
	toplevel .printers.inkjetDlg
	wm withdraw .printers.inkjetDlg
	
	# set default values for the vars in this dialog
	if {$mode eq "NEW"} {
		set inkjet_printer_name "Untitled"
		set inkjet_desc ""
		# kind will be set in the proc inkJetOk
		set inkjet_cyan_unit ""
		set inkjet_cyan_yield ""
		set inkjet_cyan_percent 5
		set inkjet_magenta_unit ""
		set inkjet_magenta_yield ""
		set inkjet_magenta_percent 5
		set inkjet_yellow_unit ""
		set inkjet_yellow_yield ""
		set inkjet_yellow_percent 5
		set inkjet_black_unit ""
		set inkjet_black_yield ""
		set inkjet_black_percent 5
		set inkjet_spot_unit 0
		set inkjet_spot_yield 0
		set inkjet_spot_percent 0
	} else {
		#edit mode
		set theprinter [dict get $dict_printers $selected_printer]
		set inkjet_printer_name [dict get $theprinter printer]
		set inkjet_desc [dict get $theprinter description]
		set inkjet_cyan_unit [dict get $theprinter cyan_unit]
		set inkjet_cyan_yield [dict get $theprinter cyan_yield]
		set inkjet_cyan_percent [dict get $theprinter cyan_percent]
		set inkjet_magenta_unit [dict get $theprinter magenta_unit]
		set inkjet_magenta_yield [dict get $theprinter magenta_yield]
		set inkjet_magenta_percent [dict get $theprinter magenta_percent]
		set inkjet_yellow_unit [dict get $theprinter yellow_unit]
		set inkjet_yellow_yield [dict get $theprinter yellow_yield]
		set inkjet_yellow_percent [dict get $theprinter yellow_percent]
		set inkjet_black_unit [dict get $theprinter black_unit]
		set inkjet_black_yield [dict get $theprinter black_yield]
		set inkjet_black_percent [dict get $theprinter black_percent]
		set inkjet_spot_unit [dict get $theprinter spot_unit]
		set inkjet_spot_yield [dict get $theprinter spot_yield]
		set inkjet_spot_percent [dict get $theprinter spot_percent]
	}
	
	ttk::frame .printers.inkjetDlg.fr -relief flat
	ttk::labelframe .printers.inkjetDlg.fr.lbfr -text "Coverage Entries based on Letter/A4"
	
	ttk::label .printers.inkjetDlg.fr.lbfr.lbprinter -text "*Printer Name"
	ttk::entry .printers.inkjetDlg.fr.lbfr.printer -textvariable inkjet_printer_name -width 24
	ttk::label .printers.inkjetDlg.fr.lbfr.lbdescription -text "Description"
	ttk::entry .printers.inkjetDlg.fr.lbfr.description -textvariable inkjet_desc -width 24
	
	#labels - top column
	ttk::label .printers.inkjetDlg.fr.lbfr.lbconsumable -text "Consumables"
	ttk::label .printers.inkjetDlg.fr.lbfr.lbcosts -text "Unit Costs"
	ttk::label .printers.inkjetDlg.fr.lbfr.lbyield -text "Page Yields"
	ttk::label .printers.inkjetDlg.fr.lbfr.lbpercent -text "Percent Coverage"
	
	#color inks cyan
	ttk::label .printers.inkjetDlg.fr.lbfr.lbcyan_unit -text "*Cyan Ink"
	ttk::entry .printers.inkjetDlg.fr.lbfr.cyan_unit -textvariable inkjet_cyan_unit -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.cyan_yield -textvariable inkjet_cyan_yield -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.cyan_percent -textvariable inkjet_cyan_percent -width 12
	
	#color inks magenta
	ttk::label .printers.inkjetDlg.fr.lbfr.lbmagenta_unit -text "*Magenta Ink"
	ttk::entry .printers.inkjetDlg.fr.lbfr.magenta_unit -textvariable inkjet_magenta_unit -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.magenta_yield -textvariable inkjet_magenta_yield -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.magenta_percent -textvariable inkjet_magenta_percent -width 12
	
	#color inks yellow
	ttk::label .printers.inkjetDlg.fr.lbfr.lbyellow_unit -text "*Yellow Ink"
	ttk::entry .printers.inkjetDlg.fr.lbfr.yellow_unit -textvariable inkjet_yellow_unit -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.yellow_yield -textvariable inkjet_yellow_yield -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.yellow_percent -textvariable inkjet_yellow_percent -width 12
	
	#color inks black
	ttk::label .printers.inkjetDlg.fr.lbfr.lbblack_unit -text "*Black Ink"
	ttk::entry .printers.inkjetDlg.fr.lbfr.black_unit -textvariable inkjet_black_unit -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.black_yield -textvariable inkjet_black_yield -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.black_percent -textvariable inkjet_black_percent -width 12
	
	#color inks spot
	ttk::label .printers.inkjetDlg.fr.lbfr.lbspot_unit -text "Spot Ink"
	ttk::entry .printers.inkjetDlg.fr.lbfr.spot_unit -textvariable inkjet_spot_unit -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.spot_yield -textvariable inkjet_spot_yield -width 12
	ttk::entry .printers.inkjetDlg.fr.lbfr.spot_percent -textvariable inkjet_spot_percent -width 12
	
	ttk::label .printers.inkjetDlg.fr.lbfr.info -text "* Are required fields"
	
	#printer name and description
	grid config .printers.inkjetDlg.fr.lbfr.lbprinter \
		-column 0 -row 0 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.printer \
		-column 1 -row 0 -columnspan 3 -sticky we
	grid config .printers.inkjetDlg.fr.lbfr.lbdescription \
		-column 0 -row 1 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.description \
		-column 1 -row 1 -columnspan 3 -sticky we
		
	# consumables - these top columns are labels
	grid config .printers.inkjetDlg.fr.lbfr.lbconsumable \
		-column 0 -row 2 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.lbcosts \
		-column 1 -row 2 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.lbyield \
		-column 2 -row 2 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.lbpercent \
		-column 3 -row 2 -sticky w
	
	# ink cyan
	grid config .printers.inkjetDlg.fr.lbfr.lbcyan_unit \
		-column 0 -row 3 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.cyan_unit \
		-column 1 -row 3 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.cyan_yield	\
		-column 2 -row 3 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.cyan_percent \
		-column 3 -row 3 -sticky w
		
	# ink magenta
	grid config .printers.inkjetDlg.fr.lbfr.lbmagenta_unit \
		-column 0 -row 4 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.magenta_unit \
		-column 1 -row 4 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.magenta_yield \
		-column 2 -row 4 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.magenta_percent \
		-column 3 -row 4 -sticky w
		
	# ink yellow
	grid config .printers.inkjetDlg.fr.lbfr.lbyellow_unit \
		-column 0 -row 5 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.yellow_unit \
		-column 1 -row 5 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.yellow_yield \
		-column 2 -row 5 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.yellow_percent \
		-column 3 -row 5 -sticky w
		
	# ink black
	grid config .printers.inkjetDlg.fr.lbfr.lbblack_unit \
		-column 0 -row 6 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.black_unit \
		-column 1 -row 6 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.black_yield \
		-column 2 -row 6 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.black_percent \
		-column 3 -row 6 -sticky w
	
	# ink spot
	grid config .printers.inkjetDlg.fr.lbfr.lbspot_unit \
		-column 0 -row 7 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.spot_unit \
		-column 1 -row 7 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.spot_yield \
		-column 2 -row 7 -sticky w
	grid config .printers.inkjetDlg.fr.lbfr.spot_percent \
		-column 3 -row 7 -sticky w
	
	pack .printers.inkjetDlg.fr.lbfr -padx 10 -pady 5
	
	#buttons
	ttk::frame .printers.inkjetDlg.frbuttons
	ttk::labelframe .printers.inkjetDlg.frbuttons.lbfrbuttons
	ttk::button .printers.inkjetDlg.frbuttons.lbfrbuttons.ok -text "Ok" \
		-command "inkJetOk $mode $selected_printer"
	ttk::button .printers.inkjetDlg.frbuttons.lbfrbuttons.cancel -text "Cancel" \
		-command "inkJetCancel"
		
	#buttons place
	pack .printers.inkjetDlg.frbuttons.lbfrbuttons.ok -side left
	pack .printers.inkjetDlg.frbuttons.lbfrbuttons.cancel -side right
	pack .printers.inkjetDlg.frbuttons.lbfrbuttons -padx 5 -pady 5
	
	#pack both frames
	pack .printers.inkjetDlg.fr ; #frame with printers and all consumbables
	pack .printers.inkjetDlg.frbuttons ; # frame that contains the buttons
	
	# after the inside of window created
	# Window manager
	if {$mode eq "NEW"} {
		wm title .printers.inkjetDlg "New Ink Jet Profile"
	} else {
		wm title .printers.inkjetDlg "Edit Ink Jet Profile"
	}
	
	# make sure when window close it is destroyed
	wm protocol .printers.inkjetDlg WM_DELETE_WINDOW {
		.printers.inkjetDlg.frbuttons.lbfrbuttons.cancel invoke
	}
	
	wm transient .printers.inkjetDlg .printers
	#display
	wm deiconify .printers.inkjetDlg
	
	#make it modal
	catch {tk visibility .printers.inkjetDlg}
	focus .printers.inkjetDlg.fr.lbfr.printer
	catch {grab set .printers.inkjetDlg}
	catch {tkwait window .printers.inkjetDlg}
	
}
proc monoLaserOk {mode selected_printer} {
	#put into dictionary
	global globalparms ; #need this to make sure the default printer is still indicated by * and red type
	global dict_printers
	set errorsum ""
	
	global mono_printer_name ;global mono_desc ;global mono_kind
	global mono_black_toner_unit ;global mono_black_toner_yield ;global mono_black_toner_percent
	global mono_black_drum_unit ;global mono_black_drum_yield ;global mono_black_drum_percent
	global mono_transfer_belt_unit ;global mono_transfer_belt_yield ; global mono_transfer_belt_percent
	global mono_fuser_unit ;global mono_fuser_yield ;global mono_fuser_percent
	global mono_waste_unit ;global mono_waste_yield ;global mono_waste_percent
	
	#validate entries
	## printer name
	if {[string length $mono_printer_name] > 3} {} else {set errorsum "$errorsum Error: Printer Name needs min 4 characters\n"}
	
	## toner
	if {[string is double -strict $mono_black_toner_unit]} {
		if {$mono_black_toner_unit eq 0 || $mono_black_toner_unit < 0} {
			set errorsum "$errorsum Error: Black toner cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black toner cost\n" }
	if {[string is double -strict $mono_black_toner_yield]} {
		if {$mono_black_toner_yield eq 0 || $mono_black_toner_yield < 0} {
			set errorsum "$errorsum Error: Black toner yield cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black toner yield\n" }
	if {[string is double -strict $mono_black_toner_percent]} {
		if {$mono_black_toner_percent eq 0 || $mono_black_toner_percent < 0} {
			set errorsum "$errorsum Error: Black toner percent cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Black toner percent\n" }
	
	### NOTICE Below can have 0 as valid entry
	
	### black drum (-strict will make sure value is a number but 0 is a number)
	if {[string is double -strict $mono_black_drum_unit]} {
		if {$mono_black_drum_unit eq 0} {} ; # 0 indicates that this unit will not be used in calculations or costs
		if {$mono_black_drum_unit < 0} {set errorsum "$errorsum Error: Black Drum cost cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Black drum cost not a valid number.\n\tEnter 0 if not using.\n"} ; # was an alpha character
	if {[string is double -strict $mono_black_drum_yield]} {
		if {$mono_black_drum_yield < 0} {set errorsum "$errorsum Error: Black Drum page yield cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Black drum page yield not a valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $mono_black_drum_percent]} {
		if {$mono_black_drum_percent < 0} {set errorsum "$errorsum Error: Black Drum page coverage percent cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Black drum page coverage percent not a valid number.\n\tEnter 0 if not using.\n"}
	
	### transfer belt
	if {[string is double -strict $mono_transfer_belt_unit]} {
		if {$mono_transfer_belt_unit eq 0} {} ; # 0 indicates that this unit will not be used in calculations or costs
		if {$mono_transfer_belt_unit < 0} {set errorsum "$errorsum Error: Transfer Belt cost cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Transfer Belt cost not a valid number.\n\tEnter 0 if not using.\n"} ; # was an alpha character
	if {[string is double -strict $mono_transfer_belt_yield]} {
		if {$mono_transfer_belt_yield < 0} {set errorsum "$errorsum Error: Transfer Belt page yield cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Transfer Belt page yield not a valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $mono_transfer_belt_percent]} {
		if {$mono_transfer_belt_percent < 0} {set errorsum "$errorsum Error: Transfer Belt page coverage percent cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Transfer Belt page coverage percent not a valid number.\n\tEnter 0 if not using.\n"}	
	
	### Waste box
	if {[string is double -strict $mono_waste_unit]} {
		if {$mono_waste_unit eq 0} {} ; # 0 indicates that this unit will not be used in calculations or costs
		if {$mono_waste_unit < 0} {set errorsum "$errorsum Error: Waste box cost cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Waste box cost not a valid number.\n\tEnter 0 if not using.\n"} ; # was an alpha character
	if {[string is double -strict $mono_waste_yield]} {
		if {$mono_waste_yield < 0} {set errorsum "$errorsum Error: Waste Box page yield cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Waste Box page yield not a valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $mono_waste_percent]} {
		if {$mono_waste_percent < 0} {set errorsum "$errorsum Error: Waste Box page coverage percent cannot be negative\n\tEnter 0 if not using.\n"}	
	} else {set errorsum "$errorsum Error: Waste Box page coverage percent not a valid number.\n\tEnter 0 if not using.\n"}	
	
	#check for errors
	if {[string length $errorsum] ne 0} {
		# An error occurred.
		set reply [tk_messageBox -parent .printers.monolaserDlg -message $errorsum -icon warning -type ok]
		return
	}
	
	set printer [dict create \
		"printer" $mono_printer_name \
		"description" $mono_desc \
		"kind" "Mono Toner" \
		"black_toner_unit" $mono_black_toner_unit \
		"black_toner_yield" $mono_black_toner_yield \
		"black_toner_percent" $mono_black_toner_percent \
		"black_drum_unit" $mono_black_drum_unit \
		"black_drum_yield" $mono_black_drum_yield \
		"black_drum_percent" $mono_black_drum_percent \
		"transfer_belt_unit" $mono_transfer_belt_unit \
		"transfer_belt_yield" $mono_transfer_belt_yield \
		"transfer_belt_percent" $mono_transfer_belt_percent \
		"fuser_unit" $mono_fuser_unit \
		"fuser_yield" $mono_fuser_yield \
		"fuser_percent" $mono_fuser_percent \
		"waste_unit" $mono_waste_unit \
		"waste_yield" $mono_waste_yield \
		"waste_percent" $mono_waste_percent ]	
	
	if {$mode eq "NEW"} {
		#dict append dict_printers $printer_name $printer
		if {[dict size $dict_printers] eq 0} {
			puts "dict size of dict_printers: [dict size $dict_printers]"
			dict append dict_printers 1 $printer
			.printers.table insert end [list 1 [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
		} else {
			puts "dict size of dict_printers is: [dict size $dict_printers]"
			set index 0
			foreach key_of_dicts [dict keys $dict_printers] {
				# get the largest key - note key numbers on this dict are integer
				if {$index < $key_of_dicts} {
					set index $key_of_dicts
				}			
			}
			incr index
			dict append dict_printers $index $printer
			.printers.table insert end [list $index [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
			puts "From monoLaserOk: dict size of dict_printers now is: [dict size $dict_printers]"
			#puts "print dict: $dict_printers"
		}
	} else {
		#edit mode
		puts "edit mode selected printer index $selected_printer"
		dict unset dict_printers $selected_printer
		dict append dict_printers $selected_printer $printer
		set dict_printers [lsort -integer -index 0 -increasing -stride 2 $dict_printers]
		#dict update dict_printers $selected_printer $printer
		set id $selected_printer
		set theprinter [dict get $printer printer]
		set thekind [dict get $printer kind]
		set thedesc [dict get $printer description]
		if {$id eq $globalparms(defaultprinter)} {
			set theprinter "*$theprinter"
			.printers.table rowconfigure $::rowSelected -text [list $id $theprinter $thekind $thedesc]
			.printers.table rowconfigure $::rowSelected -fg red
		} else {
			.printers.table rowconfigure $::rowSelected -text [list $id $theprinter $thekind $thedesc]
		}
		
		puts "from edit size of dict: [dict size $dict_printers]"
		puts "from edit then ok: $dict_printers"
	}
	savePrinters
	destroy .printers.monolaserDlg
}
proc monoLaserCancel {} {
	destroy .printers.monolaserDlg
}
proc showMonoLaserDlg {mode selected_printer} {
	global globalparms ; # app level
	global dict_printers ; # app level
	
	global mono_printer_name ;global mono_desc ; #global mono_kind
	global mono_black_toner_unit ;global mono_black_toner_yield ;global mono_black_toner_percent
	global mono_black_drum_unit ;global mono_black_drum_yield ;global mono_black_drum_percent
	global mono_transfer_belt_unit ;global mono_transfer_belt_yield ; global mono_transfer_belt_percent
	global mono_fuser_unit ;global mono_fuser_yield ;global mono_fuser_percent
	global mono_waste_unit ;global mono_waste_yield ;global mono_waste_percent
	
	toplevel .printers.monolaserDlg
	wm withdraw .printers.monolaserDlg
	
	# create the inside of the window
	# set default vars for this dlg
	if {$mode eq "NEW"} {
		set mono_printer_name "Untitled"
		set mono_desc ""
		# key 'kind' set value 'Mono Toner' in proc monoLaserOk
		set mono_black_toner_unit ""
		set mono_black_toner_yield ""
		set mono_black_toner_percent 5
		set mono_black_drum_unit 0
		set mono_black_drum_yield 0
		set mono_black_drum_percent 0
		set mono_transfer_belt_unit 0
		set mono_transfer_belt_yield 0
		set mono_transfer_belt_percent 0
		set mono_fuser_unit 0
		set mono_fuser_yield 0
		set mono_fuser_percent 0
		set mono_waste_unit 0
		set mono_waste_yield 0
		set mono_waste_percent 0
	} else {
		#edit mode
		set theprinter [dict get $dict_printers $selected_printer]
		set mono_printer_name [dict get $theprinter printer]
		set mono_desc [dict get $theprinter description]
		# key 'kind' has its value 'Mono Toner' already from dict - does not need changed
		set mono_black_toner_unit [dict get $theprinter black_toner_unit]
		set mono_black_toner_yield [dict get $theprinter black_toner_yield]
		set mono_black_toner_percent [dict get $theprinter black_toner_percent]
		set mono_black_drum_unit [dict get $theprinter black_drum_unit]
		set mono_black_drum_yield [dict get $theprinter black_drum_yield]
		set mono_black_drum_percent [dict get $theprinter black_drum_percent]
		set mono_transfer_belt_unit [dict get $theprinter transfer_belt_unit]
		set mono_transfer_belt_yield [dict get $theprinter transfer_belt_yield]
		set mono_transfer_belt_percent [dict get $theprinter transfer_belt_percent]
		set mono_fuser_unit [dict get $theprinter fuser_unit]
		set mono_fuser_yield [dict get $theprinter fuser_yield]
		set mono_fuser_percent [dict get $theprinter fuser_percent]
		set mono_waste_unit [dict get $theprinter waste_unit]
		set mono_waste_yield [dict get $theprinter waste_yield]
		set mono_waste_percent [dict get $theprinter waste_percent]
	}
	
	ttk::frame .printers.monolaserDlg.fr -relief flat
	ttk::labelframe .printers.monolaserDlg.fr.lbfr -text "Coverage Entries based on Letter/A4"
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbprinter -text "*Printer Name"
	ttk::entry .printers.monolaserDlg.fr.lbfr.printer -textvariable mono_printer_name -width 24
	ttk::label .printers.monolaserDlg.fr.lbfr.lbdescription -text "Description"
	ttk::entry .printers.monolaserDlg.fr.lbfr.description -textvariable mono_desc -width 24
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbconsumable -text "Consumables"
	ttk::label .printers.monolaserDlg.fr.lbfr.lbcosts -text "Unit Cost"
	ttk::label .printers.monolaserDlg.fr.lbfr.lbyield -text "Page Yields"
	ttk::label .printers.monolaserDlg.fr.lbfr.lbpercent -text "Percent Coverage"
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbblack_toner_unit -text "*Black Toner"
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_toner_unit -textvariable mono_black_toner_unit -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_toner_yield -textvariable mono_black_toner_yield -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_toner_percent -textvariable mono_black_toner_percent -width 12
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbblank -text ""
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbblack_drum_unit -text "Black Drum"
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_drum_unit -textvariable mono_black_drum_unit -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_drum_yield -textvariable mono_black_drum_yield -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.black_drum_percent -textvariable mono_black_drum_percent -width 12
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbtransfer_belt -text "Transer Belt"
	ttk::entry .printers.monolaserDlg.fr.lbfr.transfer_belt_unit -textvariable mono_transfer_belt_unit -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.transfer_belt_yield -textvariable mono_transfer_belt_yield -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.transfer_belt_percent -textvariable mono_transfer_belt_percent -width 12
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbfuser_unit -text "Fuser"
	ttk::entry .printers.monolaserDlg.fr.lbfr.fuser_unit -textvariable mono_fuser_unit -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.fuser_yield -textvariable mono_fuser_yield -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.fuser_percent -textvariable mono_fuser_percent -width 12
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbwaste_unit -text "Waste"
	ttk::entry .printers.monolaserDlg.fr.lbfr.waste_unit -textvariable mono_waste_unit -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.waste_yield -textvariable mono_waste_yield -width 12
	ttk::entry .printers.monolaserDlg.fr.lbfr.waste_percent -textvariable mono_waste_percent -width 12
	
	ttk::label .printers.monolaserDlg.fr.lbfr.lbinfo -text "* Are required fields."
	
	# printer profile - printer name and description - 2 widgets across horizontal
	grid config .printers.monolaserDlg.fr.lbfr.lbprinter \
		-column 0 -row 0 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.printer \
		-column 1 -row 0 -columnspan 3 -sticky we
	grid config .printers.monolaserDlg.fr.lbfr.lbdescription \
		-column 0 -row 1 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.description \
		-column 1 -row 1 -columnspan 3 -sticky we
	
	# consumables - top columns that are labels	
	grid config .printers.monolaserDlg.fr.lbfr.lbconsumable \
		-column 0 -row 2 -sticky ew
	grid config .printers.monolaserDlg.fr.lbfr.lbcosts \
		-column 1 -row 2 -sticky ew
	grid config .printers.monolaserDlg.fr.lbfr.lbyield \
		-column 2 -row 2 -sticky ew
	grid config .printers.monolaserDlg.fr.lbfr.lbpercent \
		-column 3 -row 2 -sticky ew
		
	# consumables enteries
	######## toner
	grid config .printers.monolaserDlg.fr.lbfr.lbblack_toner_unit \
		-column 0 -row 3 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_toner_unit \
		-column 1 -row 3 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_toner_yield \
		-column 2 -row 3 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_toner_percent \
		-column 3 -row 3 -sticky w
	########### drum
	grid config .printers.monolaserDlg.fr.lbfr.lbblack_drum_unit \
		-column 0 -row 4 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_drum_unit \
		-column 1 -row 4 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_drum_yield \
		-column 2 -row 4 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.black_drum_percent \
		-column 3 -row 4 -sticky w
	######## transfer belt
	grid config .printers.monolaserDlg.fr.lbfr.lbtransfer_belt \
		-column 0 -row 5 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.transfer_belt_unit \
		-column 1 -row 5 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.transfer_belt_yield \
		-column 2 -row 5 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.transfer_belt_percent \
		-column 3 -row 5 -sticky w
	######## fuser
	grid config .printers.monolaserDlg.fr.lbfr.lbfuser_unit \
		-column 0 -row 6 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.fuser_unit \
		-column 1 -row 6 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.fuser_yield \
		-column 2 -row 6 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.fuser_percent \
		-column 3 -row 6 -sticky w
	######## waste 
	grid config .printers.monolaserDlg.fr.lbfr.lbwaste_unit \
		-column 0 -row 7 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.waste_unit \
		-column 1 -row 7 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.waste_yield \
		-column 2 -row 7 -sticky w
	grid config .printers.monolaserDlg.fr.lbfr.waste_percent \
		-column 3 -row 7 -sticky w
	###### *note
	grid config .printers.monolaserDlg.fr.lbfr.lbinfo \
		-column 0 -row 8 -columnspan 4 -sticky w
	
	#pack printer and all consumables below line
	pack .printers.monolaserDlg.fr.lbfr -padx 10 -pady 10
	
	# buttons
	ttk::frame .printers.monolaserDlg.frbuttons
	ttk::labelframe .printers.monolaserDlg.frbuttons.lbfbuttons
	ttk::button .printers.monolaserDlg.frbuttons.lbfbuttons.ok -text "Ok" \
		-command "monoLaserOk $mode $selected_printer"
	ttk::button .printers.monolaserDlg.frbuttons.lbfbuttons.cancel -text "Cancel" \
		-command "monoLaserCancel"
		
	# buttons place
	pack .printers.monolaserDlg.frbuttons.lbfbuttons.ok -side left
	pack .printers.monolaserDlg.frbuttons.lbfbuttons.cancel -side right
	pack .printers.monolaserDlg.frbuttons.lbfbuttons -padx 5 -pady 5
	
	pack .printers.monolaserDlg.fr ; # frame containing all printer info and consumables
	pack .printers.monolaserDlg.frbuttons ; # frame containing the buttons
	
	# after inside of window created 
	# Window manager
	if {$mode eq "NEW"} {
		wm title .printers.monolaserDlg "New Mono Laser Profile"
	} else {
		wm title .printers.monolaserDlg "Edit Mono Laser Profile"
	}
	
	wm protocol .printers.monolaserDlg WM_DELETE_WINDOW {
		.printers.monolaserDlg.frbuttons.lbfbuttons.cancel invoke
	}
	
	wm transient .printers.monolaserDlg .printers
	#display
	wm deiconify .printers.monolaserDlg
	
	#make it modal
	catch {tk visibility .printers.monolaserDlg}
	focus .printers.monolaserDlg.fr.lbfr.printer
	catch {grab set .printers.monolaserDlg}
	catch {tkwait window .printers.monolaserDlg}
}

#################### New or Edit Color Laser Profile Dlg #################################
#### mode will be "NEW" or "EDIT" selected_printer will be 0 for none or the index of the dictionary to be edited
#### the key 'kind' will have value set in this proc to 'Color Toner'
proc colorLaserOk {mode selected_printer} {
	#code here, put in dictonary
	global dict_printers
	set errorsum ""
	variable printer_name ;variable printer_description
	variable cyan_cost_toner ;variable cyan_yield_toner ;variable cyan_percent_toner
	variable magenta_cost_toner ;variable magenta_yield_toner ;variable magenta_percent_toner
	variable yellow_cost_toner ;variable yellow_yield_toner ;variable yellow_percent_toner
	variable black_cost_toner ;variable black_yield_toner ;variable black_percent_toner
	variable spot_cost_toner ;variable spot_yield_toner ;variable spot_percent_toner
	variable cyan_cost_drum ;variable cyan_yield_drum ;variable cyan_percent_drum
	variable magenta_cost_drum ;variable magenta_yield_drum ;variable magenta_percent_drum
	variable yellow_cost_drum ;variable yellow_yield_drum ;variable yellow_percent_drum
	variable black_cost_drum ;variable black_yield_drum ;variable black_percent_drum
	variable spot_cost_drum ;variable spot_yield_drum ;variable spot_percent_drum
	variable transfer_cost ;variable transfer_yield ;variable transfer_percent
	variable fuser_cost ;variable fuser_yield ;variable fuser_percent
	variable waste_cost ;variable waste_yield ;variable waste_percent
	
	# First validate entries
	if {[string length $printer_name] > 3} {} else {set errorsum "$errorsum Error: Printer Name needs min 4 characters\n"}
	if {[string is double -strict $cyan_cost_toner]} {
		if {$cyan_cost_toner eq 0 || $cyan_cost_toner < 0} {
			set errorsum "$errorsum Error: Cyan toner cost cannot be 0 or less\n"
		}
	} else { set errorsum "$errorsum Error: Cyan toner cost\n" }
	if {[string is double -strict $cyan_yield_toner]} {
		if {$cyan_yield_toner eq 0 || $cyan_yield_toner < 0} {
			set errorsum "$errorsum Error: Cyan page yields cannot be 0 or less\n"	
		}	
	} else {set errorsum "$errorsum  Error: Cyan page yields.\n"}
	if {[string is double -strict $cyan_percent_toner]} {
		if {$cyan_percent_toner eq 0 || $cyan_percent_toner < 0} {
			set errorsum "$errorsum Error: Cyan toner percent cannot be 0 or less\n"	
		}
	} else {set errorsum "$errorsum  Error: Cyan toner percent\n"}
	if {[string is double -strict $magenta_cost_toner]} {
		if {$magenta_cost_toner eq 0 || $magenta_cost_toner < 0} {
			set errorsum "$errorsum Error: Magenta toner cost cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Magenta toner cost\n"}
	if {[string is double -strict $magenta_yield_toner]} {
		if {$magenta_yield_toner eq 0 || $magenta_yield_toner < 0} {
			set errorsum "$errorsum Error: Magenta page yields cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Magenta page yields.\n"}
	if {[string is double -strict $magenta_percent_toner]} {
		if {$magenta_percent_toner eq 0 || $magenta_percent_toner < 0} {
			set errorsum "$errorsum Error: Magenta toner percent cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Magenta toner percent\n"}
	if {[string is double -strict $yellow_cost_toner]} {
		if {$yellow_cost_toner eq 0 || $yellow_cost_toner < 0} {
			set errorsum "$errorsum Error: Yellow toner cost cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Yellow toner cost\n"}
	if {[string is double -strict $yellow_yield_toner]} {
		if {$yellow_yield_toner eq 0 || $yellow_yield_toner < 0} {
			set errorsum "$errorsum Error: Yellow page yields cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Yellow toner yield\n"}
	if {[string is double -strict $yellow_percent_toner]} {
		if {$yellow_percent_toner eq 0 || $yellow_percent_toner < 0} {
			set errorsum "$errorsum Error: Yellow toner percent cannot be 0 or less\n"
		}		
	} else {set errorsum "$errorsum Error: Yellow toner percent\n"}
	if {[string is double -strict $black_cost_toner]} {
		if {$black_cost_toner eq 0 || $black_cost_toner < 0} {
			set errorsum "$errorsum Error: Black toner cost cannot be 0 or less\n"
		}
	} else {set errorsum "$errorsum Error: Black toner cost\n"}
	if {[string is double -strict $black_yield_toner]} {
		if {$black_yield_toner eq 0 || $black_yield_toner < 0} {
			set errorsum "$errorsum Error: Black page yields cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Black toner yield\n"}
	if {[string is double -strict $black_percent_toner]} {
		if {$black_percent_toner eq 0 || $black_percent_toner < 0} {
			set errorsum "$errorsum Error: Black toner percent cannot be 0 or less\n"
		}	
	} else {set errorsum "$errorsum Error: Black toner percent\n"}
	
	#spot toner - notice that below here we can have 0 as a valid entry. 0 means we are not going to use
	if {[string is double -strict $spot_cost_toner]} {
		if {$spot_cost_toner eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$spot_cost_toner < 0} {set errorsum "$errorsum Error: Spot toner cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Spot toner cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $spot_yield_toner]} {
		if {$spot_yield_toner < 0} {set errorsum "$errorsum Error: Spot yield cannot be negative\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Spot yield not valid number.\n\tEnter 0 if not using.\n" }		
	if {[string is double -strict $spot_percent_toner]} {
		if {$spot_percent_toner < 0} {set errorsum "$errorsum Error: Spot percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Spot percent not valid number.\n\tEnter 0 if not using.\n"}
			
	#drum section CYAN 0 valid
	if {[string is double -strict $cyan_cost_drum]} {
		if {$cyan_cost_drum eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$cyan_cost_drum < 0} {set errorsum "$errorsum Error: Cyan drum cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Cyan drum cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $cyan_yield_drum]} {
		if {$cyan_yield_drum < 0} {set errorsum "$errorsum Error: Cyan drum yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Cyan drum yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $cyan_percent_drum]} {
		if {$cyan_percent_drum < 0} {set errorsum "$errorsum Error: Cyan drum percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Cyan drum percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#drum section MAGENTA
	if {[string is double -strict $magenta_cost_drum]} {
		if {$magenta_cost_drum eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$magenta_cost_drum < 0} {set errorsum "$errorsum Error: Magenta drum cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Magenta drum cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $magenta_yield_drum]} {
		if {$magenta_yield_drum < 0} {set errorsum "$errorsum Error: Magenta drum yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Magenta drum yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $magenta_percent_drum]} {
		if {$magenta_percent_drum < 0} {set errorsum "$errorsum Error: Magenta drum percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Magenta drum percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#drum section YELLOW
	if {[string is double -strict $yellow_cost_drum]} {
		if {$yellow_cost_drum eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$yellow_cost_drum < 0} {set errorsum "$errorsum Error: Yellow drum cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Yellow drum cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $yellow_yield_drum]} {
		if {$yellow_yield_drum < 0} {set errorsum "$errorsum Error: Yellow drum yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Yellow drum yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $yellow_percent_drum]} {
		if {$yellow_percent_drum < 0} {set errorsum "$errorsum Error: Yellow drum percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Yellow drum percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#drum section BLACK
	if {[string is double -strict $black_cost_drum]} {
		if {$black_cost_drum eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$black_cost_drum < 0} {set errorsum "$errorsum Error: Black drum cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Black drum cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $black_yield_drum]} {
		if {$black_yield_drum < 0} {set errorsum "$errorsum Error: Black drum yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Black drum yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $black_percent_drum]} {
		if {$black_percent_drum < 0} {set errorsum "$errorsum Error: Black drum percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Black drum percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#drum section SPOT
	if {[string is double -strict $spot_cost_drum]} {
		if {$spot_cost_drum eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$spot_cost_drum < 0} {set errorsum "$errorsum Error: Spot drum cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Spot drum cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $spot_yield_drum]} {
		if {$spot_yield_drum < 0} {set errorsum "$errorsum Error: Spot drum yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Spot drum yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $spot_percent_drum]} {
		if {$spot_percent_drum < 0} {set errorsum "$errorsum Error: Spot drum percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Spot drum percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#Transfer 0 valid
	if {[string is double -strict $transfer_cost]} {
		if {$transfer_cost eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$transfer_cost < 0} {set errorsum "$errorsum Error: Transfer Belt cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Transfer Belt cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $transfer_yield]} {
		if {$transfer_yield < 0} {set errorsum "$errorsum Error: Transfer Belt yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Transfer Belt yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $transfer_percent]} {
		if {$transfer_percent < 0} {set errorsum "$errorsum Error: Transfer Belt percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Transfer Belt percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#Fuser 0 is valid
	if {[string is double -strict $fuser_cost]} {
		if {$fuser_cost eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$fuser_cost < 0} {set errorsum "$errorsum Error: Fuser cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Fuser cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $fuser_yield]} {
		if {$fuser_yield < 0} {set errorsum "$errorsum Error: Fuser yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Fuser yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $fuser_percent]} {
		if {$fuser_percent < 0} {set errorsum "$errorsum Error: Fuser percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Fuser percent not valid number.\n\tEnter 0 if not using.\n"}
	
	#Waste 0 is valid
	if {[string is double -strict $waste_cost]} {
		if {$waste_cost eq 0} {} ; # 0 in acceptable means that it will not be used
		if {$waste_cost < 0} {set errorsum "$errorsum Error: Waste cost cannot be negative.\n\tEnter 0 if not using.\n" }
	} else {set errorsum "$errorsum Error: Waste cost not valid number.\n\tEnter 0 if not using.\n"}
	if {[string is double -strict $waste_yield]} {
		if {$waste_yield < 0} {set errorsum "$errorsum Error: Waste yield cannot be negative.\n\tEnter 0 if not using.\n" }
	} else { set errorsum "$errorsum Error: Waste yield not valid number.\n\tEnter 0 if not using.\n" }
	if {[string is double -strict $waste_percent]} {
		if {$waste_percent < 0} {set errorsum "$errorsum Error: Waste percent cannot be negative\n\tEnter 0 if not using.\n"}
	} else {set errorsum "$errorsum Error: Waste percent not valid number.\n\tEnter 0 if not using.\n"}
		
	# Check for Errors
	if {[string length $errorsum] ne 0} {
		# An error occurred.
		set reply [tk_messageBox -parent .printers.colorlaserDlg -message $errorsum -icon warning -type ok]
		return
	}
	
	#create a printer dictionary then append it to the master dictionary of printers.
	set printer [dict create \
		"printer" $printer_name \
		"description" $printer_description \
		"kind" "Color Toner" \
		"cyan_toner_unit" $cyan_cost_toner \
		"cyan_toner_yield" $cyan_yield_toner \
		"cyan_toner_percent" $cyan_percent_toner \
		"magenta_toner_unit" $magenta_cost_toner \
		"magenta_toner_yield" $magenta_yield_toner \
		"magenta_toner_percent" $magenta_percent_toner \
		"yellow_toner_unit" $yellow_cost_toner \
		"yellow_toner_yield" $yellow_yield_toner \
		"yellow_toner_percent" $yellow_percent_toner \
		"black_toner_unit" $black_cost_toner \
		"black_toner_yield" $black_yield_toner \
		"black_toner_percent" $black_percent_toner \
		"spot_toner_unit" $spot_cost_toner \
		"spot_toner_yield" $spot_yield_toner \
		"spot_toner_percent" $spot_percent_toner \
		"cyan_drum_unit" $cyan_cost_drum \
		"cyan_drum_yield" $cyan_yield_drum \
		"cyan_drum_percent" $cyan_percent_drum \
		"magenta_drum_unit" $magenta_cost_drum \
		"magenta_drum_yield" $magenta_yield_drum \
		"magenta_drum_percent" $magenta_percent_drum \
		"yellow_drum_unit" $yellow_cost_drum \
		"yellow_drum_yield" $yellow_yield_drum \
		"yellow_drum_percent" $yellow_percent_drum \
		"black_drum_unit" $black_cost_drum \
		"black_drum_yield" $black_yield_drum \
		"black_drum_percent" $black_percent_drum \
		"spot_drum_unit" $spot_cost_drum \
		"spot_drum_yield" $spot_yield_drum \
		"spot_drum_percent" $spot_percent_drum \
		"transfer_belt_unit" $transfer_cost \
		"transfer_belt_yield" $transfer_yield \
		"transfer_belt_percent" $transfer_percent \
		"fuser_unit" $fuser_cost \
		"fuser_yield" $fuser_yield \
		"fuser_percent" $fuser_percent \
		"waste_unit" $waste_cost \
		"waste_yield" $waste_yield \
		"waste_percent" $waste_percent ]
	
	if {$mode eq "NEW"} {
		#dict append dict_printers $printer_name $printer
		if {[dict size $dict_printers] eq 0} {
			puts "dict size of dict_printers: [dict size $dict_printers]"
			dict append dict_printers 1 $printer
			.printers.table insert end [list 1 [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
		} else {
			puts "dict size of dict_printers is: [dict size $dict_printers]"
			set index 0
			foreach key_of_dicts [dict keys $dict_printers] {
				# get the largest key - note key numbers on this dict are integer
				if {$index < $key_of_dicts} {
					set index $key_of_dicts
				}			
			}
			incr index
			dict append dict_printers $index $printer
			.printers.table insert end [list $index [dict get $printer printer] [dict get $printer kind] [dict get $printer description]]
			puts "From colorLaserOk: dict size of dict_printers now is: [dict size $dict_printers]"
			#puts "print dict: $dict_printers"
		}
	} else {
		#edit mode
		puts "edit mode selected printer index $selected_printer"
		dict unset dict_printers $selected_printer
		dict append dict_printers $selected_printer $printer
		set dict_printers [lsort -integer -index 0 -increasing -stride 2 $dict_printers]
		#dict update dict_printers $selected_printer $printer
		set id $selected_printer
		set theprinter [dict get $printer printer]
		set thekind [dict get $printer kind]
		set thedesc [dict get $printer description]
		.printers.table rowconfigure $::rowSelected -text [list $id $theprinter $thekind $thedesc]
		puts "from edit size of dict: [dict size $dict_printers]"
		puts "from edit then ok: $dict_printers"
	}
	#puts "Errors: $errorsum"
	#puts $printer_name_colorlaser
	savePrinters
	
	destroy .printers.colorlaserDlg
}
proc colorLaserCancel {} {
	destroy .printers.colorlaserDlg
}
proc showColorLaserDlg {mode selected_printer} {
	# cmyk
	global globalparms ; # application level 
	global dict_printers ; # app level
	
	global printer_name ; # value for the New Printer Profile Name
	global printer_description
	global cyan_cost_toner ; # value of cyan toner
	global cyan_yield_toner
	global cyan_percent_toner
	global magenta_cost_toner ; # value of magenta toner
	global magenta_yield_toner
	global magenta_percent_toner
	global yellow_cost_toner ; # value of yellow toner
	global yellow_yield_toner
	global yellow_percent_toner	
	global black_cost_toner ; # value of black toner
	global black_yield_toner
	global black_percent_toner
	global spot_cost_toner ; # value of spot toner
	global spot_yield_toner
	global spot_percent_toner
	global cyan_cost_drum ; ######## value of cyan drum
	global cyan_yield_drum
	global cyan_percent_drum
	global yellow_cost_drum ; # value of yellow drum
	global yellow_yield_drum
	global yellow_percent_drum
	global magenta_cost_drum ; # value of magenta drum
	global magenta_yield_drum
	global magenta_percent_drum
	global black_cost_drum ; # value of black drum
	global black_yield_drum
	global black_percent_drum
	global spot_cost_drum ; # value of spot drum
	global spot_yield_drum
	global spot_percent_drum
	global transfer_cost ; # start of other consumables
	global transfer_yield
	global transfer_percent
	global fuser_cost
	global fuser_yield
	global fuser_percent
	global waste_cost
	global waste_yield
	global waste_percent
	
	toplevel .printers.colorlaserDlg
	wm withdraw .printers.colorlaserDlg
	
	#vars for dlg
	if {$mode eq "NEW"} {
		set printer_name "Untitled"
		set printer_description ""
	
		set cyan_cost_toner ""
		set cyan_yield_toner ""
		set cyan_percent_toner 5
		set magenta_cost_toner ""
		set magenta_yield_toner ""
		set magenta_percent_toner 5
		set yellow_cost_toner ""
		set yellow_yield_toner ""
		set yellow_percent_toner 5
		set black_cost_toner ""
		set black_yield_toner ""
		set black_percent_toner 5
		set spot_cost_toner 0
		set spot_yield_toner 0
		set spot_percent_toner 5
	
		set cyan_cost_drum 0
		set cyan_yield_drum 0
		set cyan_percent_drum 0
		set magenta_cost_drum 0
		set magenta_yield_drum 0
		set magenta_percent_drum 0
		set yellow_cost_drum 0
		set yellow_yield_drum 0
		set yellow_percent_drum 0
		set black_cost_drum 0
		set black_yield_drum 0
		set black_percent_drum 0
		set spot_cost_drum 0
		set spot_yield_drum 0
		set spot_percent_drum 0
	
		set transfer_cost 0
		set transfer_yield 0
		set transfer_percent 0
		set fuser_cost 0
		set fuser_yield 0
		set fuser_percent 0
		set waste_cost 0
		set waste_yield 0
		set waste_percent 0
	} else {
		# edit mode - the id of the selected printer
		set theprinter [dict get $dict_printers $selected_printer]
		puts [dict get $theprinter printer]
		set printer_name [dict get $theprinter printer]
		set printer_description [dict get $theprinter description]
		set cyan_cost_toner [dict get $theprinter cyan_toner_unit]
		set cyan_yield_toner [dict get $theprinter cyan_toner_yield]
		set cyan_percent_toner [dict get $theprinter cyan_toner_percent]
		set magenta_cost_toner [dict get $theprinter magenta_toner_unit]
		set magenta_yield_toner [dict get $theprinter magenta_toner_yield]
		set magenta_percent_toner [dict get $theprinter magenta_toner_percent]
		set yellow_cost_toner [dict get $theprinter yellow_toner_unit]
		set yellow_yield_toner [dict get $theprinter yellow_toner_yield]
		set yellow_percent_toner [dict get $theprinter yellow_toner_percent]
		set black_cost_toner [dict get $theprinter black_toner_unit]
		set black_yield_toner [dict get $theprinter black_toner_yield]
		set black_percent_toner [dict get $theprinter black_toner_percent]
		set spot_cost_toner [dict get $theprinter spot_toner_unit]
		set spot_yield_toner [dict get $theprinter spot_toner_yield]
		set spot_percent_toner [dict get $theprinter spot_toner_percent]
	
		set cyan_cost_drum [dict get $theprinter cyan_drum_unit]
		set cyan_yield_drum [dict get $theprinter cyan_drum_yield]
		set cyan_percent_drum [dict get $theprinter cyan_drum_percent]
		set magenta_cost_drum [dict get $theprinter magenta_drum_unit]
		set magenta_yield_drum [dict get $theprinter magenta_drum_yield]
		set magenta_percent_drum [dict get $theprinter magenta_drum_percent]
		set yellow_cost_drum [dict get $theprinter yellow_drum_unit]
		set yellow_yield_drum [dict get $theprinter yellow_drum_yield]
		set yellow_percent_drum [dict get $theprinter yellow_drum_percent]
		set black_cost_drum [dict get $theprinter black_drum_unit]
		set black_yield_drum [dict get $theprinter black_drum_yield]
		set black_percent_drum [dict get $theprinter black_drum_percent]
		set spot_cost_drum [dict get $theprinter spot_drum_unit]
		set spot_yield_drum [dict get $theprinter spot_drum_yield]
		set spot_percent_drum [dict get $theprinter spot_drum_percent]
	
		set transfer_cost [dict get $theprinter transfer_belt_unit]
		set transfer_yield [dict get $theprinter transfer_belt_yield]
		set transfer_percent [dict get $theprinter transfer_belt_percent]
		set fuser_cost [dict get $theprinter fuser_unit]
		set fuser_yield [dict get $theprinter fuser_yield]
		set fuser_percent [dict get $theprinter fuser_percent]
		set waste_cost [dict get $theprinter waste_unit]
		set waste_yield [dict get $theprinter waste_yield]
		set waste_percent [dict get $theprinter waste_percent] 
	}
	
	ttk::frame .printers.colorlaserDlg.fName -relief flat
	ttk::labelframe .printers.colorlaserDlg.fName.lf -text "Coverage Entries based on Letter/A4"
	
	ttk::label .printers.colorlaserDlg.fName.lf.lbprinter -text "*Printer Name" 
	ttk::entry .printers.colorlaserDlg.fName.lf.printer -textvariable printer_name -width 24
	ttk::label .printers.colorlaserDlg.fName.lf.lbdescription -text "Description"
	ttk::entry .printers.colorlaserDlg.fName.lf.description -textvariable printer_description -width 24
	
	ttk::label .printers.colorlaserDlg.fName.lf.lconsumable -text "Consumables"
	ttk::label .printers.colorlaserDlg.fName.lf.lcosts -text "Unit Cost" 
	ttk::label .printers.colorlaserDlg.fName.lf.lyield -text "Page Yields" 
	ttk::label .printers.colorlaserDlg.fName.lf.lpercent -text "Percent Coverage" 
	
	ttk::label .printers.colorlaserDlg.fName.lf.lcyan_cartridge -text "*Cyan Toner"
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_cost -textvariable cyan_cost_toner -width 12 ; # change
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_yield -textvariable cyan_yield_toner -width 12 ; # change
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_percent -textvariable cyan_percent_toner -width 12 ; # change
	ttk::label .printers.colorlaserDlg.fName.lf.lmagenta_cartridge -text "*Magenta Toner"
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_cost -textvariable magenta_cost_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_yield -textvariable magenta_yield_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_percent -textvariable magenta_percent_toner -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lyellow_cartridge -text "*Yellow Toner"
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_cost -textvariable yellow_cost_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_yield -textvariable yellow_yield_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_percent -textvariable yellow_percent_toner -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lblack_cartridge -text "*Black Toner"
	ttk::entry .printers.colorlaserDlg.fName.lf.black_cost -textvariable black_cost_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.black_yield -textvariable black_yield_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.black_percent -textvariable black_percent_toner -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lspot_cartridge -text "Spot Toner"
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_cost -textvariable spot_cost_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_yield -textvariable spot_yield_toner -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_percent -textvariable spot_percent_toner -width 12
	
	ttk::label .printers.colorlaserDlg.fName.lf.lblank -text ""
	
	ttk::label .printers.colorlaserDlg.fName.lf.lcyan_cartridgeDrum -text "Cyan Drum"
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_costDrum -textvariable cyan_cost_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_yieldDrum -textvariable cyan_yield_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.cyan_percentDrum -textvariable cyan_percent_drum -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lmagenta_cartridgeDrum -text "Magenta Drum"
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_costDrum -textvariable magenta_cost_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_yieldDrum -textvariable magenta_yield_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.magenta_percentDrum -textvariable magenta_percent_drum -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lyellow_cartridgeDrum -text "Yellow Drum"
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_costDrum -textvariable yellow_cost_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_yieldDrum -textvariable yellow_yield_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.yellow_percentDrum -textvariable yellow_percent_drum -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lblack_cartridgeDrum -text "Black Drum"
	ttk::entry .printers.colorlaserDlg.fName.lf.black_costDrum -textvariable black_cost_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.black_yieldDrum -textvariable black_yield_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.black_percentDrum -textvariable black_percent_drum -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lspot_cartridgeDrum -text "Spot Drum"
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_costDrum -textvariable spot_cost_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_yieldDrum -textvariable spot_yield_drum -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.spot_percentDrum -textvariable spot_percent_drum -width 12
	
	ttk::label .printers.colorlaserDlg.fName.lf.lblank2 -text ""
	
	ttk::label .printers.colorlaserDlg.fName.lf.lcartridgeTransfer -text "Transfer Belt"
	ttk::entry .printers.colorlaserDlg.fName.lf.transferCost -textvariable transfer_cost -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.transferYield -textvariable transfer_yield -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.transferPercent -textvariable transfer_percent -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lcartridgeFuser -text "Fuser"
	ttk::entry .printers.colorlaserDlg.fName.lf.fuserCost -textvariable fuser_cost -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.fuserYield -textvariable fuser_yield -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.fuserPercent -textvariable fuser_percent -width 12
	ttk::label .printers.colorlaserDlg.fName.lf.lcartridgeWaste -text "Waste"
	ttk::entry .printers.colorlaserDlg.fName.lf.wasteCost -textvariable waste_cost -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.wasteYield -textvariable waste_yield -width 12
	ttk::entry .printers.colorlaserDlg.fName.lf.wastePercent -textvariable waste_percent -width 12
	
	ttk::label .printers.colorlaserDlg.fName.lf.info -text "* Are required fields."
	
	# printer profile - printer name and description - 2 widgets across horizontal
	grid config .printers.colorlaserDlg.fName.lf.lbprinter \
		-column 0 -row 0 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.printer \
		-column 1 -row 0 -columnspan 3 -sticky we
	grid config .printers.colorlaserDlg.fName.lf.lbdescription \
		-column 0 -row 1 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.description \
		-column 1 -row 1 -columnspan 3 -sticky we	
	
	# consumables - Top columns that are labels
	grid config .printers.colorlaserDlg.fName.lf.lconsumable \
		-column 0 -row 2 -sticky ew
	grid config .printers.colorlaserDlg.fName.lf.lcosts \
		-column 1 -row 2 -sticky ew 
	grid config .printers.colorlaserDlg.fName.lf.lyield \
		-column 2 -row 2 -sticky ew
	grid config .printers.colorlaserDlg.fName.lf.lpercent \
		-column 3 -row 2 -sticky ew
	
	#consumables entries	
	grid config .printers.colorlaserDlg.fName.lf.lcyan_cartridge \
		-column 0 -row 3 -sticky w 
	grid config .printers.colorlaserDlg.fName.lf.cyan_cost \
		-column 1 -row 3 -sticky w 
	grid config .printers.colorlaserDlg.fName.lf.cyan_yield \
		-column 2 -row 3 -sticky w 
	grid config .printers.colorlaserDlg.fName.lf.cyan_percent \
		-column 3 -row 3 -sticky w 
	grid config .printers.colorlaserDlg.fName.lf.lmagenta_cartridge \
		-column 0 -row 4 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_cost \
		-column 1 -row 4 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_yield \
		-column 2 -row 4 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_percent \
		-column 3 -row 4 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lyellow_cartridge \
		-column 0 -row 5 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_cost \
		-column 1 -row 5 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_yield \
		-column 2 -row 5 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_percent \
		-column 3 -row 5 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lblack_cartridge \
		-column 0 -row 6 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_cost \
		-column 1 -row 6 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_yield \
		-column 2 -row 6 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_percent \
		-column 3 -row 6 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lspot_cartridge \
		-column 0 -row 7 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_cost \
		-column 1 -row 7 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_yield \
		-column 2 -row 7 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_percent \
		-column 3 -row 7 -sticky w
		
	grid config .printers.colorlaserDlg.fName.lf.lblank \
		-column 0 -row 8 -sticky nsew -columnspan 4
		
	grid config .printers.colorlaserDlg.fName.lf.lcyan_cartridgeDrum \
		-column 0 -row 9 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.cyan_costDrum \
		-column 1 -row 9 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.cyan_yieldDrum \
		-column 2 -row 9 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.cyan_percentDrum \
		-column 3 -row 9 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lmagenta_cartridgeDrum \
		-column 0 -row 10 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_costDrum \
		-column 1 -row 10 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_yieldDrum \
		-column 2 -row 10 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.magenta_percentDrum \
		-column 3 -row 10 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lyellow_cartridgeDrum \
		-column 0 -row 11 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_costDrum \
		-column 1 -row 11 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_yieldDrum \
		-column 2 -row 11 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.yellow_percentDrum \
		-column 3 -row 11 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lblack_cartridgeDrum \
		-column 0 -row 12 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_costDrum \
		-column 1 -row 12 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_yieldDrum \
		-column 2 -row 12 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.black_percentDrum \
		-column 3 -row 12 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lspot_cartridgeDrum \
		-column 0 -row 13 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_costDrum \
		-column 1 -row 13 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_yieldDrum \
		-column 2 -row 13 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.spot_percentDrum \
		-column 3 -row 13 -sticky w
		
	grid config .printers.colorlaserDlg.fName.lf.lblank2 \
		-column 0 -row 14 -sticky nsew -columnspan 4
	
	grid config .printers.colorlaserDlg.fName.lf.lcartridgeTransfer \
		-column 0 -row 15 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.transferCost \
		-column 1 -row 15 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.transferYield \
		-column 2 -row 15 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.transferPercent \
		-column 3 -row 15 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lcartridgeFuser \
		-column 0 -row 16 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.fuserCost \
		-column 1 -row 16 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.fuserYield \
		-column 2 -row 16 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.fuserPercent \
		-column 3 -row 16 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.lcartridgeWaste \
		-column 0 -row 17 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.wasteCost \
		-column 1 -row 17 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.wasteYield \
		-column 2 -row 17 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.wastePercent \
		-column 3 -row 17 -sticky w
	grid config .printers.colorlaserDlg.fName.lf.info \
		-column 0 -row 18 -columnspan 4 -sticky w
	
	pack .printers.colorlaserDlg.fName.lf -padx 10 -pady 10

	# buttons
	ttk::frame .printers.colorlaserDlg.f
	ttk::labelframe .printers.colorlaserDlg.f.lfbuttons
	ttk::button .printers.colorlaserDlg.f.lfbuttons.ok -text "Ok" \
		-command "colorLaserOk $mode $selected_printer"
	ttk::button .printers.colorlaserDlg.f.lfbuttons.cancel -text "Cancel" \
		-command "colorLaserCancel"
	
	# buttons
	pack .printers.colorlaserDlg.f.lfbuttons.ok -side left
	pack .printers.colorlaserDlg.f.lfbuttons.cancel -side right
	pack .printers.colorlaserDlg.f.lfbuttons -padx 5 -pady 5
	
	pack .printers.colorlaserDlg.fName ; # name of printer and all consumables
	pack .printers.colorlaserDlg.f ; # buttons
	
	#window manager
	if {$mode eq "NEW"} {
		wm title .printers.colorlaserDlg "New Color Laser Profile"
	} else {
		wm title .printers.colorlaserDlg "Edit Color Laser Profile"
	}
	wm protocol .printers.colorlaserDlg WM_DELETE_WINDOW {
		.printers.colorlaserDlg.f.lfbuttons.cancel invoke
	}
	wm transient .printers.colorlaserDlg .printers
	#display
	wm deiconify .printers.colorlaserDlg
	
	#make it modal
	catch {tk visibility .printers.colorlaserDlg}
	focus .printers.colorlaserDlg.fName.lf.printer
	catch {grab set .printers.colorlaserDlg}
	catch {tkwait window .printers.colorlaserDlg}
	
	#puts "from showColorLaserDlg"
}
########### END -- New or Edit Color Laser Profile Dlg ##############

########## BEGIN - New Profile Dialog ####################
###### 1 of 3 different kinds of printer profiles to be selected
proc newProfileDialogOK {} {
	global var_kind
	puts "from radiobuttons: $var_kind"	
	
	# since this is a new entry - value of selected printer 0
	set selected_printer 0
	
	destroy .printers.newProfileDialog
	if {$var_kind eq "Color Toner"} {
		# below proc needs 2 values
		showColorLaserDlg "NEW" $selected_printer
	} elseif {$var_kind eq "Mono Toner"} {
		 
		showMonoLaserDlg "NEW" $selected_printer
	} elseif {$var_kind eq "Ink Jet"} {
		#in future will open Ink Jet Dialog
		showInkJetDlg "NEW" $selected_printer
	}
	
}
proc newProfileDialogCancel {} {

	destroy .printers.newProfileDialog
}
proc showNewProfileDialog {} {
	
	toplevel .printers.newProfileDialog
	wm withdraw .printers.newProfileDialog
	#see if we can center it over parent
	
	
	global var_kind
	set var_kind {Color Toner}
	#set up vars for dialog
	ttk::labelframe .printers.newProfileDialog.lf -text "Choose the KIND of Profile"
	ttk::radiobutton .printers.newProfileDialog.lf.colorlaser -text "Color Toner" -variable var_kind -value {Color Toner} -state selected
	ttk::radiobutton .printers.newProfileDialog.lf.monolaser -text "Mono Toner" -variable var_kind -value {Mono Toner}
	ttk::radiobutton .printers.newProfileDialog.lf.inkjet -text "Ink Jet" -variable var_kind -value {Ink Jet}
	
	grid .printers.newProfileDialog.lf.colorlaser -sticky ew
	grid .printers.newProfileDialog.lf.monolaser -sticky ew
	grid .printers.newProfileDialog.lf.inkjet -sticky ew
	
	grid .printers.newProfileDialog.lf -padx 10 -pady 10
	
	#buttons
	ttk::label .printers.newProfileDialog.lb
	ttk::button .printers.newProfileDialog.lb.btOK -text "Ok" -command "newProfileDialogOK"
	ttk::button .printers.newProfileDialog.lb.btCancel -text "Cancel" -command "newProfileDialogCancel"
	
	pack .printers.newProfileDialog.lb.btOK -side left
	pack .printers.newProfileDialog.lb.btCancel -side left
	#pack .printers.newProfileDialog.lb -padx 5 -pady 5
	
	grid .printers.newProfileDialog.lb -padx 5 -pady 5
	
	#pack .printers.newProfileDialog.lf
	#pack .printers.newProfileDialog.lb
	
	######## window manager STUFF ##################
	wm title .printers.newProfileDialog "New Printer Profile"
	wm protocol .printers.newProfileDialog WM_DELETE_WINDOW {
		.printers.newProfileDialog.lb.btCancel invoke
	}
	wm transient .printers.newProfileDialog .printers
	#display
	wm deiconify .printers.newProfileDialog
	
	#make it modal
	catch {tk visibility .printers.newProfileDialog}
	focus .printers.newProfileDialog.lf.colorlaser
	catch {grab set .printers.newProfileDialog}
	catch {tkwait window .printers.newProfileDialog}
}

# if the printer profiles have been saved this will open the file and replace the initial demo printers
openPrinters ; # this will replace the initial demo printes and create a whole new dict_printers
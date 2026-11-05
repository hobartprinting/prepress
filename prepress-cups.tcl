## source file started 1/26/26
## Copyright 2008 Randall J Hobart
## Cups window
## 
# filename prepress-cups.tcl


package require tablelist_tile

global globalparms 
global dict_cupscmd
global LINE

global cupsRowSelected
set cupsRowSelected "none"


###### Concepts #######
# run CUPS printer commands
# check for commands that are not CUPS related and cancel them.

if {[catch {toplevel .cups} result]} {
	puts $result
	.txt insert end "Info: $result\n"
	.txt insert end "$LINE" lineColor
	wm attributes .cups -topmost true
	return
}

wm title .cups {CUPS Printer Commands}

option add *Tablelist.stripBackground gray93
option add *Tablelist.labelCommand tablelist::sortByColumn
option add *Menu.tearOff 0 ; # ignored by mac

tablelist::tablelist .cups.table \
	-columns {0 "id" left 0 "Name" left 0 "Command" left 0 "Options" left 0 "FileTypes" left} \
	-stretch all -background white \
	-xscroll {.cups.h set} -yscroll {.cups.v set} 
scrollbar .cups.v -orient vertical -command {.cups.table yview}
scrollbar .cups.h -orient horizontal -command {.cups.table xview}

.cups.table columnconfigure 0 -hide yes
.cups.table configure -showseparators yes
bind .cups.table <<TablelistSelect>> [list cupsSelected %W]
bind .cups.table <<TablelistColumnSorted>> [list cupsRowMoved %W]

grid .cups.table .cups.v -sticky nsew
grid .cups.h -sticky nsew
# tell tablelist widget take all the extra room
grid rowconfigure    .cups .cups.table -weight 1
grid columnconfigure .cups .cups.table -weight 1

#fill table with cups commands
#set row 0
foreach key_of_dicts [dict keys $dict_cupscmd] {
	set cmd [dict get $dict_cupscmd $key_of_dicts]
	set cmd_name [dict get $cmd name]
	set cmd_cmd [dict get $cmd cmd]
	set cmd_options [dict get $cmd options]
	set cmd_filetypes [dict get $cmd filetypes]
	.cups.table insert end [list "$key_of_dicts" "$cmd_name" "$cmd_cmd" "$cmd_options" "$cmd_filetypes"]
	puts "cmd_name-: $cmd_name"
}

# create label that the buttons will be put in
ttk::label .cups.lb -text "" ; #no -padx or -pady Commands
ttk::button .cups.lb.exeCUPS -text "*Execute cmd* " -command { exeCUPS }
ttk::button .cups.lb.newCUPScmd -text "New cmd" -command { newCUPScmd }
ttk::button .cups.lb.editCUPScmd -text "Edit cmd" -command { editCUPScmd }
ttk::button .cups.lb.deleteCUPScmd -text "Delete cmd" -command { deleteCUPScmd }
ttk::button .cups.lb.exportCUPScmd -text "Export cmd" -command { exportCUPScmd }
ttk::button .cups.lb.importCUPScmd -text "Import cmd" -command { importCUPScmd }
ttk::label .cups.lb.lblank -text "*********"

grid config .cups.lb.exeCUPS -column 0 -row 0
grid config .cups.lb.newCUPScmd -column 1 -row 0
grid config .cups.lb.editCUPScmd -column 2 -row 0
grid config .cups.lb.deleteCUPScmd -column 3 -row 0
grid config .cups.lb.exportCUPScmd -column 4 -row 0
grid config .cups.lb.importCUPScmd -column 5 -row 0
grid config .cups.lb.lblank -column 6 -row 0

grid .cups.lb -sticky w

# add popup menu that match button commands
#create popupmenu - mac right mouse button is 2; win/unix right button is 3
global mp ; # WOW on a toplevel window such as .name this must be declared global
set mp [menu .cups.popupMenu]
$mp add command -label "*Execute cmd*" -command {exeCUPS}
$mp add separator
$mp add command -label "New cmd..." -command {newCUPScmd}
$mp add command -label "Edit cmd..." -command {editCUPScmd}
$mp add command -label "Delete cmd" -command {deleteCUPScmd}
$mp add separator
$mp add command -label "Export cmd..." -command {exportCUPScmd}
$mp add command -label "Import cmd..." -command {importCUPScmd}
if {[tk windowingsystem] == "aqua"} {
	bind .cups <ButtonPress-2> {tk_popup $mp %X %Y}
	bind .cups <Control-ButtonPress-1> {tk_popup $mp %X %Y}
} else {
	bind .cups <ButtonPress-3> {tk_popup $mp %X %Y}
}

# make invisable
wm protocol .cups WM_DELETE_WINDOW {
	wm withdraw .cups
}

proc cupsSelected {w} {
	global cupsRowSelected
	set cupsRowSelected [$w curselection]
	puts $cupsRowSelected
}
# happens when the table is sorted
proc cupsRowMoved {w} {
	global cupsRowSelected	
	if {[$w curselection] ne ""} {
		set cupsRowSelected [$w curselection]
	} else {
		set cupsRowSelected [$w curselection]
	}	
	puts $cupsRowSelected
}
# button commands
proc exeCUPS {} {
	global cupsRowSelected
	global LINE
	set b_filetypes false
	set errorsum ""
	
	if {$cupsRowSelected eq "none"} {
		set reply [tk_messageBox -parent .cups -message "Error: Select row before executing a command" -icon warning -type ok]	
		return
	}
	set name [.cups.table getcells $cupsRowSelected,1]
	set cmd [.cups.table getcells $cupsRowSelected,2]
	set options [.cups.table getcells $cupsRowSelected,3]
	set filetypes [.cups.table getcells $cupsRowSelected,4]
	
	#double check the command name in case file was tampered with
	if {[string length $cmd] > 1} {
		switch $cmd {
			lp {}
			lpr {}
			lpstat {}
			lpoptions {}
			cancel {}
			lprm {}
			lpq {}
			lpstat {}
			default {
				set errorsum "$errorsum Error: Please enter a correct CUPS command \n \
					Valid commands: lp, lpr, lpstat, lpoptions, cancel, lprm, lpq, lpstat"	
			}
		}
	} else {
		set errorsum "$errorsum Error: Please enter a CUPS command \n \
			Valid commands: lp, lpr, lpstat, lpoptions, cancel, lprm, lpq, lpstat"
	}
	
	if {[string length $errorsum] ne 0} {
		set reply [tk_messageBox -parent .cups.cmdDlg -message $errorsum -icon warning -type ok]
		return
	}
	
	if {[string length $filetypes] eq 0} {
		set $filetypes "none"
		set b_filetypes = "false" 
	}
	
	if {$filetypes ne "none"} {
		set b_filetypes true
		
		set l_types [split $filetypes ,]
		set l_types_all [list]
		foreach t $l_types {
			lappend l_types_all "$t .$t"
		}
		set types $l_types_all
	
		puts $types
	}
	.txt insert end $LINE lineColor
	.txt insert end "\n"
	.txt insert end "proc exeCUPS" procColor
	.txt insert end "\n"
	.txt insert end "Execute Name: $name\n"
	.txt insert end "Command Name $cmd\n"
	
	if {[string length $options] ne 0} {
		.txt insert end "options: $options\n"
		#this needs moved after the file is found
		#then measured for size, then filled out --- later maybe
		if {[lsearch -exact $options "media=Custom"] ne -1} {
			set pos [lsearch -exact $options "media=Custom"]	
		}
	}
	
	if {$filetypes ne "none"} {
		.txt insert end "filetypes: $types\n"
	}
	
	if {$b_filetypes eq "true"} {
		set filename [tk_getOpenFile -filetypes $types]
		if {$filename eq ""} {
			.txt insert end "proc canceled...\n"
			.txt insert end "$LINE" lineColor
			.txt insert end "\n"
			return
		} else {
			### Below created error when sending using lpr
			#set filename [escapePath $filename]
			#set cmd_options [list "$options"]
			#################
			set cmd_options $options
			lappend cmd_options $filename
			.txt insert end "cmd_options: $cmd_options\n"
			#puts "cmd_options: $cmd_options"
			if {[catch {exec $cmd {*}$cmd_options} result]} {
				.txt insert end "Error: $result" errorColor
				.txt insert end "\n"

				.txt insert end "File : [file tail $filename]\n"
				.txt insert end "Directory: "
				.txt insert end "[file dir $filename]" dirHyperlink
				.txt insert end "\n"
			} else {
				#success
				.txt insert end "File sent... [file tail $filename]\n"
				#.txt insert end "Result: $result\n" ; # is empty on sucess
				.txt insert end "Directory: "
				.txt insert end "[file dir $filename]" dirHyperlink
				.txt insert end "\n"
			}
		}
	} else {
		# the command does not need a file 
		# therefore information is sent to console
		if {[catch {exec $cmd {*}$options} result]} {
			.txt insert end "Error: $result\n"
		} else {
			.txt insert end "Success:\n$result\n"
		}
	}
	.txt insert end "http://localhost:631/help/options.html" dirHyperlink
	.txt insert end "\n"
	
	.txt insert end "$LINE" lineColor
	
	
}
proc newCUPScmd {} {
	showCupsDlg NEW id_none
}
proc editCUPScmd {} {
	global cupsRowSelected
	
	if {$cupsRowSelected eq "none"} {
		set reply [tk_messageBox -parent .cups -message "Please select or reselect a row to edit" -icon warning -type ok]
	} else {
		# 0 for column 0 which is hidden from the table
		set id [.cups.table getcells $cupsRowSelected,0]
		showCupsDlg EDIT $id
	}
	
}
proc deleteCUPScmd {} {
	global cupsRowSelected
	global dict_cupscmd
	global LINE
	
	if {$cupsRowSelected ne "none"} {
		set id [.cups.table getcells $cupsRowSelected,0]
		set cmdname [.cups.table getcells $cupsRowSelected,1]
		set msg "This will delete the selected command \n \
			$cmdname\n \
			Are you for certain?"
		set reply [tk_messageBox -parent .cups.table -message $msg -icon question -type yesno]
		if {$reply eq "yes"} {
			.cups.table delete $cupsRowSelected ; #delete selected row
			set $cupsRowSelected "none"
			dict unset dict_cupscmd $id ; #delete using id
			saveCups
		}
	} else {
		set reply [tk_messageBox -parent .cups.table -message "Please select row to delete" -icon warning -type ok]
	}
	saveCups
}
proc exportCUPScmd {} {
	global cupsRowSelected
	global dict_cupscmd
	global LINE
	
	.txt insert end "$LINE" lineColor
	.txt insert end "proc exportCUPScmd" procColor
	.txt insert end "\n"
	
	if {$cupsRowSelected ne "none"} {
		set id [.cups.table getcells $cupsRowSelected,0]
		puts "from export id is: $id"
		set thecupscmd [dict get $dict_cupscmd $id]
		#save under the name of command
		set cupsname [dict get $thecupscmd name]
		set thefile "$cupsname"
		set types { {{CUPS Files} {.cups}} }
		set filename [tk_getSaveFile -filetypes $types -initialfile $thefile]
		if {$filename ne ""} {
			set channel [open $filename w]
			fconfigure $channel -translation lf -encoding utf-8
			puts $channel $thecupscmd
			close $channel
			#success
			.txt insert end "File created... $thefile.cups\n"
			#.txt insert end "Result: $result\n" ; # is empty on sucess
			.txt insert end "Directory: "
			.txt insert end "[file dir $filename]" dirHyperlink
			.txt insert end "\n"
			
		} else {
			.txt insert end "Cancelled\n"
			.txt insert end "$LINE" lineColor
			
		}
	} else {
		set reply [tk_messageBox -parent .cups -message "Error: Select row before exporting command" -icon warning -type ok]
	}
	.txt insert end "$LINE" lineColor
}
proc importCUPScmd {} {
	global cupsRowSelected
	global dict_cupscmd
	global LINE
	
	.txt insert end "$LINE" lineColor
	.txt insert end "proc importCUPScmd" procColor
	.txt insert end "\n"
	
	set types { {{CUPS Files} {.cups}} }
	set filename [tk_getOpenFile -filetypes $types]
	if {$filename ne ""} {
		set channel [open $filename r]
		fconfigure $channel -translation lf -encoding utf-8
		set command [read $channel]
		close $channel
	} else {
		#operation canceled
		.txt insert end "import canceled\n"
		.txt insert end "$LINE" lineColor
		return
	}
	
	# small validation
	set numkeys 0
	foreach key [dict keys $command] {
		incr numkeys	
	}
	if {$numkeys eq 4} {
	
	} else {
		set msg "File was corrupt. Import canceled"
		.txt insert end "$msg\n"
		.txt insert end "keys: $numkeys\n"
		.txt insert end "$LINE" lineColor
		
		set reply [tk_messageBox -parent .cups -message $msg -icon warning -type ok]
		return
	}
	if {[dict size $dict_cupscmd] eq 0} {
		dict append $dict_cupscmd 1 $command
		.cups.table insert end [list 1 [dict get $command name] [dict get $command cmd] [dict get $command options] [dict get $command filetypes]]
	} else {
		# find a new id
		set index 0
		foreach key [dict keys $dict_cupscmd] {
			#get largest key
			if {$index < $key} {
				set index $key
			}
		}
		incr index
		dict append dict_cupscmd $index $command
		.cups.table insert end [list $index [dict get $command name] [dict get $command cmd] [dict get $command options] [dict get $command filetypes]]
		
		.txt insert end "File: [file tail $filename] has been imported.\n"
		.txt insert end "Directory: "
		.txt insert end "[file dir $filename]" dirHyperlink
		.txt insert end "\n"
		.txt insert end "$LINE" lineColor
	}
	saveCups
	
}
proc saveCups {} {
	global globalparms
	global dict_cupscmd
	
	set cupsfilename $globalparms(cache_path)[file separator]$globalparms(cups_commands)
	set channel [open $cupsfilename w]
	fconfigure $channel -translation lf -encoding utf-8
	puts $channel $dict_cupscmd
	close $channel
	
}

#################### begin modal dialog ####################
proc cancelCupsDlg {} {
	destroy .cups.cmdDlg
}
#will not use 'id' if mode is NEW
proc okCupsDlg {mode id} {
	global cupsRowSelected
	global dict_cupscmd
	set errorsum ""
	
	#vars for dialog
	global cups_cmd_name ; global cups_cmd_cmd  
	global cups_cmd_options ; global cups_cmd_filetypes
	
	set cups_cmd_name [string trim $cups_cmd_name]
	set cups_cmd_cmd [string trim $cups_cmd_cmd]
	set cups_cmd_options [string trim $cups_cmd_options]
	set cups_cmd_filetypes [string trim $cups_cmd_filetypes]
	
	puts "from okCupsDlg: mode is $mode and selrow is $cupsRowSelected command is $cups_cmd_cmd"
	
	## check the text fields for errors
	
	if {[string length $cups_cmd_name] > 0 } {
	} else {
		set errorsum "$errorsum Error: Please enter a name or small description for this command\n"	
	}
	
	#supported cmds: lp, lpr, lpstat, lpoptions, cancel, lprm, lpq, lpstat
	if {[string length $cups_cmd_cmd] > 1 } {
		switch $cups_cmd_cmd {
			lp {}
			lpr {}
			lpstat {}
			lpoptions {} 
			cancel {}
			lprm {}
			lpq {}
			lpstat {}
			default {
				set errorsum "$errorsum Error: Please enter a correct CUPS command \n \
					Valid commands: lp, lpr, lpstat, lpoptions, cancel, lprm, lpq, lpstat"	
			}
		}
	} else {
		set errorsum "$errorsum Error: Please enter a CUPS command \n \
			Valid commands: lp, lpr, lpstat, lpoptions, cancel, lprm, lpq, lpstat"	
	} 
	
	# options will not check for errors or length since some commands have no options
	
	# filetypes will not be validated
	if {[string length $cups_cmd_filetypes] eq 0} {
		set cups_cmd_filetypes "none"	
	}
	
	#puts [string length $cups_cmd_filetypes]
	#check for entry errors
	if {[string length $errorsum] ne 0} {
		set reply [tk_messageBox -parent .cups.cmdDlg -message $errorsum -icon warning -type ok]
		return
	}
	
	## end checking errors
	#puts "filetypes $cups_cmd_filetypes"
	set cmd [dict create \
		"name" $cups_cmd_name \
		"cmd" $cups_cmd_cmd \
		"options" $cups_cmd_options \
		"filetypes" $cups_cmd_filetypes]
	
	#will not use id for NEW
	if {$mode eq "NEW"} {
		if {[dict size $dict_cupscmd] eq 0} {
			dict append dict_cupscmd 1 $cmd
			.cups.table insert end [list 1 [dict get $cmd name] [dict get $cmd cmd] [dict get $cmd options] [dict get $cmd filetypes]]	
		} else {
			# get the largest key number
			set index 0
			foreach key_of_dicts [dict keys $dict_cupscmd] {
				# get the largest key - note key numbers on this dict are integer
				if {$index < $key_of_dicts} {
					set index $key_of_dicts
				}
			}
			incr index
			dict append dict_cupscmd $index $cmd
			.cups.table insert end [list $index [dict get $cmd name] [dict get $cmd cmd] [dict get $cmd options] [dict get $cmd filetypes]]	
		}
	} else {
		# must be EDIT
		dict unset dict_cupscmd $id
		dict append dict_cupscmd $id $cmd
		set dict_cupscmd [lsort -integer -index 0 -increasing -stride 2 $dict_cupscmd]
		#.cups.table rowconfigure $::rowSelected -text [list $id [dict get $cmd name] [dict get $cmd cmd] [dict get $cmd options] [dict get $cmd filetypes] ]
		.cups.table rowconfigure $cupsRowSelected -text [list $id [dict get $cmd name] [dict get $cmd cmd] [dict get $cmd options] [dict get $cmd filetypes] ]
	}
	saveCups
	destroy .cups.cmdDlg
}

# global var cupsRowSelected tested before this is called by editCUPScmd proc
proc showCupsDlg {mode id} {
	global dict_cupscmd
	global cupsRowSelected
	#vars for dialog
	global cups_cmd_name ; global cups_cmd_cmd  
	global cups_cmd_options ; global cups_cmd_filetypes
	
	puts "mode: $mode id: $id"
	#create toplevel
	toplevel .cups.cmdDlg
	wm withdraw .cups.cmdDlg
	
	if { $mode eq "NEW" } {
		set cups_cmd_name "Untitled"
		set cups_cmd_cmd ""
		set cups_cmd_options ""
		set cups_cmd_filetypes ""
	} else {
		#edit mode - no need to check
		# the_cmd_dict is the nested dict
		set the_cmd_dict [dict get $dict_cupscmd $id]
		set cups_cmd_name [dict get $the_cmd_dict "name"]
		set cups_cmd_cmd [dict get $the_cmd_dict "cmd"]
		set cups_cmd_options [dict get $the_cmd_dict "options"]
		set cups_cmd_filetypes [dict get $the_cmd_dict "filetypes"]
	}
	
	ttk::frame .cups.cmdDlg.fr -relief flat
	ttk::labelframe .cups.cmdDlg.fr.lbfr -text "CUPS command entries"
	
	ttk::label .cups.cmdDlg.fr.lbfr.lbname -text "Name/Description"
	ttk::entry .cups.cmdDlg.fr.lbfr.name -textvariable cups_cmd_name -width 24
	ttk::label .cups.cmdDlg.fr.lbfr.lbcmd -text "CUPS Command"
	ttk::entry .cups.cmdDlg.fr.lbfr.cmd -textvariable cups_cmd_cmd -width 12
	ttk::label .cups.cmdDlg.fr.lbfr.lboptions -text "CUPS options"
	ttk::entry .cups.cmdDlg.fr.lbfr.options -textvariable cups_cmd_options -width 54
	ttk::label .cups.cmdDlg.fr.lbfr.lbfiletypes -text "Filetypes to send"
	ttk::entry .cups.cmdDlg.fr.lbfr.filetypes -textvariable cups_cmd_filetypes -width 12
	
	ttk::label .cups.cmdDlg.fr.lbfr.lbhint -text "For Filetypes Use commas to separate. ex: ps,pdf"
	
	grid config .cups.cmdDlg.fr.lbfr.lbname \
		-column 0 -row 0 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.name \
		-column 1 -row 0 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.lbcmd \
		-column 0 -row 1 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.cmd \
		-column 1 -row 1 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.lboptions \
		-column 0 -row 2 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.options \
		-column 1 -row 2 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.lbfiletypes \
		-column 0 -row 3 -sticky w
	grid config .cups.cmdDlg.fr.lbfr.filetypes \
		-column 1 -row 3 -sticky w
		
	grid config .cups.cmdDlg.fr.lbfr.lbhint \
		-columnspan 2 -column 0 -row 4 -sticky w
	
	pack .cups.cmdDlg.fr.lbfr -padx 10 -pady 5
	
	#buttons
	ttk::frame .cups.cmdDlg.frBtns
	ttk::labelframe .cups.cmdDlg.frBtns.lbfrBtns
	ttk::button .cups.cmdDlg.frBtns.lbfrBtns.ok -text "Ok" \
		-command "okCupsDlg $mode $id"
	ttk::button .cups.cmdDlg.frBtns.lbfrBtns.cancel -text "Cancel" \
		-command "cancelCupsDlg"
		
	#buttons place
	pack .cups.cmdDlg.frBtns.lbfrBtns.ok -side left
	pack .cups.cmdDlg.frBtns.lbfrBtns.cancel -side right
	pack .cups.cmdDlg.frBtns.lbfrBtns -padx 5 -pady 5
	
	#pack both frames
	pack .cups.cmdDlg.fr ; #frame with all labels and their entries
	pack .cups.cmdDlg.frBtns ; #frame with buttons
	
	#after window constructed
	#window manager
	if {$mode eq "NEW"} {
		wm title .cups.cmdDlg "New CUPS Command"
	} else {
		wm title .cups.cmdDlg "Edit CUPS Command"
	}
	
	wm protocol .cups.cmdDlg WM_DELETE_WINDOW {
		.cups.cmdDlg.frBtns.lbfrBtns.cancel invoke
	}
	
	wm transient .cups.cmdDlg .cups
	#display
	wm deiconify .cups.cmdDlg
	
	#make it modal
	catch {tk visibility .cups.cmdDlg}
	focus .cups.cmdDlg.fr.lbfr.name
	catch {grab set .cups.cmdDlg}
	catch {tkwait window .cups.cmdDlg}
	
}

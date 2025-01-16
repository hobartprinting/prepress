#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tclsh $DIR/prepress-main.tcl
exit 0 
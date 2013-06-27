#!/bin/sh

# $Id: generate_recipe.sh,v 1.8 2009-07-31 23:47:23 brian Exp $
# Copyright (c)2010 by Brian Manning
# script to set up the GTK environment in order to run updated GTK libs

# external programs used
TRUE=$(which true)
GETOPT=$(which getopt)
MV=$(which mv)
CAT=$(which cat)
RM=$(which rm)
MKTEMP=$(which mktemp)
UNAME=$(which uname)
PERL=$(which perl)
SCRIPTNAME=$(basename $0)

# script variables
EXIT_STATUS=0 # unless something happens, exit with 0 status
COMPACT=0 # 0 = default, 1 = compact; mutually exclusive with LARGER/SPLASH
LARGER=0 # 0 = default, 1 = larger; mutually exclusive with COMPACT/SPLASH
SPLASH=0 # 0 = default, 1 = splash; mutually exclusive with LARCER/COMPACT
KEEP_TEMP=0 # 0 = delete $TEMP_DIR, 1 = keep $TEMP_DIR
CPPFLAGS=-I/usr/local/include
LDFLAGS=-L/usr/local/lib
LD_LIBRARY_PATH=/usr/local/lib
PKG_CONFIG_PATH=/usr/local/lib
# for compact/larger
CONFIGURE_IMG="../docs/pix/configure.16x16.png"
# for compact
MAYHEM_SMALL="../docs/pix/mayhem-logo.neon.orange-300x72.jpg"
# for larger
MAYHEM_TOP="../docs/pix/mayhem-logo.text.neon.orange-300x75.jpg"
MAYHEM_LEFT="../docs/pix/mohawkb-skinny-150x234.jpg"
# for splashscreen
MAYHEM_SPLASH="../docs/pix/mayhem-logo.neon.orange-500x109.jpg"

### FUNCTIONS ###
# check the status of the last run command; run a shell if it's anything but 0
cmd_status () {
    COMMAND=$1
    STATUS=$2
    if [ $STATUS -ne 0 ]; then
        echo "Command '${COMMAND}' failed with status code: ${STATUS}"
        exit 1
    fi
} # cmd_status

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
OSDETECT=$($UNAME -s)
if [ ${OSDETECT} == "Darwin" ]; then
    # this is the BSD part
    echo "WARNING: BSD OS Detected; long switches will not work here..."
    TEMP=$(/usr/bin/getopt hvckls $*)
elif [ ${OSDETECT} == "Linux" ]; then
    # and this is the GNU part
    TEMP=$(/usr/bin/getopt -o hvckls \
	    --long help,verbose,compact,keep,larger,splash \
        -n '$SCRIPTNAME' -- "$@")
else
    echo "Error: Unknown OS Type.  I don't know how to call"
    echo "'getopts' correctly for this operating system.  Exiting..."
    exit 1
fi

# if getopts exited with an error code, then exit the script
#if [ $? -ne 0 -o $# -eq 0 ] ; then
if [ $? != 0 ] ; then
	echo "Run '${SCRIPTNAME} --help' to see script options" >&2
	exit 1
fi

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$TEMP"

# set a counter for how many times getopts is run; if the loop counter gets too
# big, that means there was a problem with the getopts call; exit before you
# run into an endless loop
ERRORLOOP=1

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while true ; do
	case "$1" in
		-h|--help) # show the script options
		cat <<-EOF

	${SCRIPTNAME} [options]

	SCRIPT OPTIONS
    -h|--help           Displays this help message
    -v|--verbose        Nice pretty output messages
    -c|--compact        Run the compact layout
    -l|--larger         Run the larger layout
    -s|--splash         Run the splash screen
    -k|--keep           Keep any temporary files that were created
    NOTE: Long switches do not work with BSD systems (GNU extension)

    EXAMPLE USAGE:

    ${SCRIPTNAME} --compact --keep

EOF
		exit 0;;
        -v|--verbose) # output pretty messages
            VERBOSE=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 1
            ;;
        -c|--compact)
            COMPACT=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 1
            ;;
        -l|--larger)
            LARGER=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 1
            ;;
        -s|--splash)
            SPLASH=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 1
            ;;
        -k|--keep)
            KEEP_TEMP=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 1
            ;;
		--) shift
            break
            ;;
	esac
    # exit if we loop across getopts too many times
    ERRORLOOP=$(($ERRORLOOP + 1))
    if [ $ERRORLOOP -gt 4 ]; then
        echo "ERROR: too many getopts passes;" >&2
        echo "Maybe you have a getopt option with no branch?" >&2
        exit 1
    fi # if [ $ERROR_LOOP -gt 3 ];
done

### MAIN SCRIPT ###

    # check for multiple main switch options
    if [ $COMPACT -eq 1 ]; then
        if [ $LARGER -eq 1 -o $SPLASH -eq 1 ]; then EXIT_STATUS=1; fi
    elif [ $LARGER -eq 1 ]; then
        if [ $COMPACT -eq 1 -o $SPLASH -eq 1 ]; then EXIT_STATUS=1; fi
    elif [ $LARGER -eq 1 ]; then
        if [ $COMPACT -eq 1 -o $SPLASH -eq 1 ]; then EXIT_STATUS=1; fi
    fi
    # now check to see if exit status was set
    if [ $EXIT_STATUS -eq 1 ]; then
        echo "ERROR: Specify only one dialog to display"
        echo "Run '${SCRIPTNAME} --help' to see script options"
        exit 1
    fi # if [ $COMPACT -eq $LARGER ]; then


    TEMP_DIR=$(mktemp -d /tmp/run_gtk.XXXXXX)

    if [ ! -e $CONFIGURE_IMG ]; then
        echo "$CONFIGURE_IMG can't be copied"
        exit 1
    fi
    cp $CONFIGURE_IMG $TEMP_DIR

    # set up either the compact or larger files
    if [ $COMPACT -eq 1 ]; then
        if [ ! -e $MAYHEM_SMALL ]; then
            echo "mayhem-logo (300x72) can't be copied"
            exit 1
        fi
        cp $MAYHEM_SMALL $TEMP_DIR
        cat layout_demo.pl mayhem_compact_layout.glade > $TEMP_DIR/run.pl
    elif [ $LARGER -eq 1 ]; then
        if [ ! -e $MAYHEM_TOP ]; then
            echo "$MAYHEM_TOP can't be copied to temp dir"
            exit 1
        fi
        if [ ! -e $MAYHEM_LEFT ]; then
            echo "$MAYHEM_LEFT can't be copied to temp dir"
            exit 1
        fi
        cp $MAYHEM_TOP $TEMP_DIR
        cp $MAYHEM_LEFT $TEMP_DIR
        cat layout_demo.pl mayhem_larger_layout.glade > $TEMP_DIR/run.pl
    elif [ $SPLASH -eq 1 ]; then
        if [ ! -e $MAYHEM_SPLASH ]; then
            echo "$MAYHEM_SPLASH can't be copied to temp dir"
            exit 1
        fi
        cp $MAYHEM_SPLASH $TEMP_DIR
        cat layout_demo.pl mayhem_splashscreen.glade > $TEMP_DIR/run.pl

    else
        echo "ERROR: Can't decide which dialog to show; Pass in "
        echo "one of the dialog switches to show that dialog."
        echo "Run '${SCRIPTNAME} --help' to see script options"
        exit 1
    fi # if [ $COMPACT -eq 1 ]; then

    cd $TEMP_DIR
    $PERL run.pl

    if [ $KEEP_TEMP -eq 0 ]; then
        $RM -rf $TEMP_DIR
    else
        echo "Temp directory $TEMP_DIR was not deleted;"
        echo "Please delete it when you are done with it"
    fi

    # exit with the happy
    exit 0

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 dated June, 1991.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program;  if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111, USA.

# vi: set filetype=sh sw=4 ts=4:
# eof

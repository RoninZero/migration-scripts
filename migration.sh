#!/bin/sh

# migration script
# Built 11.16.11 DMK
# Ver 0.10
##############################################################################
# Revision History
# 11.16.11      DMK     Initial Version
# 04.07.14      DMK     Modified to work at NCCS
#
##############################################################################
# TODO
# - Add email subject "tag" variable for filtering ie. [MIGR]
#############################################################################

# Variables Setup
SRC=""               # source location for migration
DEST=""                 # destination location for migration
KEY="nokey"		# key for log file names (project basename)
TIMESTAMP="000"         # timestamp
MAILTO="user@domain.com"              # who to send notificatione mails to
OUTPATH="/tmp/migration"	# Path for find files and diff files
# debug variable
DEBUG=0                 # set to 1, -D on command line, will enable debug options

usage() {
cat << EOF

usage $0 options

This is a script that is called by the master-migrate.sh script

OPTIONS:
   -h   Show this message
   -k   key for log file names (project basename)
   -s   source directory to migrate from
   -d   destination directory to migrate to
   -m   mailto email address for notifications
   -t   timestamp used for log file names
   -o   output directory for log files
EOF
}

# uid check if not root (uid 0) then exit
# check to make sure this works with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!" 1>&2
   exit 1
fi

# get command line options
while getopts "hk:s:d:m:t:o:D" OPTION
do
   case $OPTION in
      h)
         usage
         exit 1
         ;;
      k)
         KEY=$OPTARG
         ;;
      s)
         SRC=$OPTARG
         ;;
      d)
         DEST=$OPTARG
         ;;
      m)
         MAILTO=$OPTARG
         ;;
      t)
         TIMESTAMP=$OPTARG
         ;;
      o)
         OUTPATH=$OPTARG
         ;;
      D)
         DEBUG=1
         ;;
      ?)
         usage
         exit 1
         ;;
   esac
done
#set -x

# Converts Seconds into H:MM:SS format
# Takes $1 Number of Seconds returns String H:MM:SS
ConvertSeconds ()
{
# Initialize the variables
        HOURS=0
        MINS=0
        SECS=$1

        if [ $SECS -ge 3600 ]
        then
                HOURS=$(( $SECS / 3600 ))
                SECS=$(( $SECS % 3600 ))
        fi

        if [ $SECS -ge 60 ]
        then
                MINS=$(( $SECS / 60 ))
                SECS=$(( $SECS % 60 ))
        fi

# Zero Pad 1-9 for Minutes and Seconds
        if [[ $MINS -lt 10 && $MINS -ge 0 ]]
        then
                MINS="0$MINS"
        fi

        if [[ $SECS -lt 10 && $SECS -ge 0 ]]
        then
                SECS="0$SECS"
        fi
echo "$HOURS:$MINS:$SECS"
}



# ------- Main -------

#set -x
REPORT="$OUTPATH/$KEY-$TIMESTAMP-report.txt"
echo "Starting migration of $SRC to $DEST..."
STARTTIME=$(date +%s)
echo "Final Migration Report for $KEY" > $REPORT
echo "-------------------------------" >> $REPORT
echo "             Source Path: $SRC" >> $REPORT
echo "        Destination Path: $DEST" >> $REPORT
echo "Migration for $KEY has started." | mutt -s "Migration Status: $KEY started" $MAILTO
(/usr/bin/rsync -auvv $SRC $DEST; echo $?) 2>$OUTPATH/$KEY-$TIMESTAMP-rsync.err > $OUTPATH/$KEY-$TIMESTAMP-rsync.out
ENDTIME=$(date +%s)
ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
RUNTIME=$(ConvertSeconds $ELAPSEDTIME)
echo -e "\n\n       Migration runtime: $RUNTIME" >> $REPORT
echo "Migration for $KEY has ended." | mutt -s "Migration Status: $KEY done" $MAILTO
exit 0

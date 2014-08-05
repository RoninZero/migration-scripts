#!/bin/sh

# master migration script
# Built 11.16.11 DMK
# Ver 0.10
##############################################################################
# Revision History
# 11.16.11      DMK     Initial Version
# 04.07.14      DMK     Modified to work at NCCS
#
##############################################################################
# TODO
# - Add emailing for each rsync completion
# - Add emailing for each comparison completion along with line counts from
#   diff file
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

This is a script that is called by the master-migrate.sh script for generating
file listings and generating a diff file comparing the source to the
destination to check for missing files

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

# source and dest file list generation script
Lister()
{
   # Initialize the variables
   # $1 = dir, $2 = key, $3 = $TIMESTAMP, $4 = SOURCE|DEST

   cd $1
   /usr/bin/find . > $OUTPATH/$2-$3-find-$4.out
   sort $OUTPATH/$2-$3-find-$4.out > $OUTPATH/$2-$3-find-$4.sorted

   echo "$2-$3-find-$4.sorted"
}


# comparison of source and dest filelists
# Compares source and dest, creates diff file, returns count of missing files
Compare()
{
   # Initialize the variables
   # $1 = $SOURCEFILE, $2 = $DESTFILE, $3 = $KEY, $4 = $TIMESTAMP
   /usr/bin/comm -23 $OUTPATH/$1 $OUTPATH/$2 > $OUTPATH/$3-$4-diff.out
   /usr/bin/wc -l $OUTPATH/$3-$4-diff.out | /bin/awk {'print$1'}

}

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
REPORT="$OUTPATH/$KEY-$TIMESTAMP-report.txt"
# Source file processing
STARTTIME=$(date +%s)
SRCFILE=$(Lister $SRC $KEY $TIMESTAMP "SRC")
echo "Listing for $KEY source has ended." | mutt -s "Migration Status: $KEY source listing done" $MAILTO
ENDTIME=$(date +%s)
ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
RUNTIME=$(ConvertSeconds $ELAPSEDTIME)
echo "     Source Listing time: $RUNTIME" >> $REPORT


# Destination file processing
STARTTIME=$(date +%s)
DESTFILE=$(Lister $DEST $KEY $TIMESTAMP "DEST")
echo "Listing for $KEY destination has ended." | mutt -s "Migration Status: $KEY destination listing done" $MAILTO
ENDTIME=$(date +%s)
ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
RUNTIME=$(ConvertSeconds $ELAPSEDTIME)
echo "Destination Listing time: $RUNTIME" >> $REPORT


# Comparing source and destination files
STARTTIME=$(date +%s)
DIFFCOUNT=$(Compare $SRCFILE $DESTFILE $KEY $TIMESTAMP)
ENDTIME=$(date +%s)
ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
RUNTIME=$(ConvertSeconds $ELAPSEDTIME)
echo "         Comparison time: $RUNTIME" >> $REPORT

[ $DEBUG -eq 1 ] && echo "DiffCount:$DIFFCOUNT"
if [[ $DIFFCOUNT -gt 0 ]] ; then
   echo -e "Comparison of $SRCFILE and $DESTFILE complete.\n$DIFFCOUNT files were different.\n\nPlease check the attached file for the file differences." | mutt -s "Migration Status: $KEY comparison done" -a $OUTPATH/$KEY-$TIMESTAMP-diff.out $MAILTO
   echo -e "There were differences in the file counts!\n\nPlease check $OUTPATH/$KEY-$TIMESTAMP-diff.out for the differences." >> $REPORT
else
   echo -e "Comparison of $SRCFILE and $DESTFILE complete.\n$DIFFCOUNT files were different." | mutt -s "Migration Status: $KEY comparison done" $MAILTO
fi

# Mail final report
#cat $REPORT | mutt -s "Final Migration Report: $KEY" $MAILTO
mutt -s "Final Migration Report: $KEY" -a $REPORT $MAILTO

exit 0

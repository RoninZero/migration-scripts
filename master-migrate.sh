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
SOURCE=""               # source location for migration
DEST=""                 # destination location for migration
NAME="noname"		# name of the migration for final email report
THREADS=4               # number of rsyncs to run simultaneously, default=4
FILELIST="NOTSET"       # colon delimited input file containing KEY SRC DEST (one per line)
MAILTO="user@domain.com"              # who to send notificatione mails to
OUTPATH="/tmp/migration"	# Path for find files and diff files
BINPATH="/path/to/migration-scripts/" # Path to helper scripts
# debug variable
DEBUG=0                 # set to 1, -D on command line, will enable debug options

usage() {
cat << EOF

usage $0 options

This is a script to help automate projects/directory migrations with basic file listing error checking

OPTIONS:
   -h   Show this message
   -f   space delimited file containing KEY SRC DEST (one per line, with trailing slashes)
   -t   number of threads (number of rsyncs to run at once)
   -n   name of the migration for final email notification of completion

EOF
}

# uid check if not root (uid 0) then exit
# check to make sure this works with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!" 1>&2
   exit 1
fi

# get command line options
while getopts "hm:n::t:f:D" OPTION
do
   case $OPTION in
      h)
         usage
         exit 1
         ;;
      m)
         MAILTO=$OPTARG
         ;;
      n)
         NAME=$OPTARG
         ;;
      f)
         FILELIST=$OPTARG
         ;;
      t)
         THREADS=$OPTARG
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

# ------- Main -------

# check for empty filelist and exit
[ $FILELIST == "NOTSET" ] && echo "You must supply a input file!" && exit 1


#set -x
#export OUTPATH for subshell to see it
export OUTPATH
# xargs used to control number of "threads" or maximum rsync jobs
#/usr/bin/xargs -I'{}' -a$FILELIST -P$THREADS /bin/sh -c ' \
#	TIMESTAMP=`date +%Y%m%d-%H%M%S` ;\
#	KEY=`echo {}|/bin/awk ' { print \$1 } '` ;\
#	SRC=`echo {}|/bin/awk ' { print \$2 } '` ;\
#	DEST=`echo {}|/bin/awk '{ print \$3 } '` ;\
#	echo /local/projects/IT/scripts/migration/migrate.sh -k $KEY -s $SRC -d $DEST -t $TIMESTAMP -o $OUTPATH ;\
#	echo /local/projects/IT/scripts/migration/gendiffs.sh -k $KEY -s $SRC -d $DEST -t $TIMESTAMP -o $OUTPATH &'

# xargs used to control number of "threads" or maximum rsync jobs
while read LINE; do
	TIMESTAMP=`date +%Y%m%d-%H%M%S`
	KEY=`echo $LINE | /bin/awk ' { print \$1 } '`
	SRC=`echo $LINE | /bin/awk ' { print \$2 } '`
	DEST=`echo $LINE | /bin/awk '{ print \$3 } '`
	echo "-k $KEY -s $SRC -d $DEST -t $TIMESTAMP -o $OUTPATH"
done < "$FILELIST" | /usr/bin/xargs -I{} -P$THREADS sh -c '\
	/path/to/migration-scripts/migrate.sh {} ;\
	/path/to/migration-scripts/gendiffs.sh {} & '

echo "Final Migration: $NAME is completed." | mutt -s "Final Migration: $NAME completed" $MAILTO

exit 0

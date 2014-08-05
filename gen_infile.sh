#!/bin/sh
#set -x

#NB_DIRECTORIES="/directory/to/file/containing/user/data_directory_listing"
DEST_BASE_DIR="/CHANGE/THIS"
usage() {
    echo "Please run with a username"
    exit 1
}

if [ $1"x" == "x" ]; then
	usage;
fi

USERNAME=$1
#BASE_DIR=`grep $USERNAME $NB_DIRECTORIES | cut -d":" -f2`
SRC_BASE_DIR=`grep $USERNAME $NB_DIRECTORIES | cut -d":" -f2`
VALID_USER=`echo $?`
#echo "USERNAME=$USERNAME="
#echo "VALID_USER=$VALID_USER"

# for i in `ls -1 `; do echo username-$i /SRC_BASE_DIR/username/$i/ /DEST_BASE_DIR/username/$i/; done
for DIR in `ls -1 $SRC_BASE_DIR`
do
	echo $USERNAME-$DIR-1 $SRC_BASE_DIR/$DIR/ $DEST_BASE_DIR/$USERNAME/$DIR/
done


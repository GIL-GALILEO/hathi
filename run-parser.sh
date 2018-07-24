#!/bin/sh 
BASE=/apps/gpoimport/ftp
CMD=/home/alma/bin/hathi/hathi-marc-parser.rb
#DIRECTORIES="atlm"
DIRECTORIES="abac asu atlm augusta ccga clayton csu dalton ega ftv gasou gcsu ggc ghc gordon gptc gsu gsw ksu mga savst sgsc uga ung vsu westga"
for DIR in $DIRECTORIES
do
   echo "press enter to run Hathi parse script for $DIR. "s" to skip.  (ctrl-c to quit)"
   read CHOICE
   if [ "$CHOICE" != "s" ];
   then 
     cd $BASE/$DIR/hathi
   
     FI_LIST=`ls Hathi*_new`
     for FI in $FI_LIST
     do
        ls -alh $FI
        DATE="$(date +'%Y%m%d')"
        EXTENSION=".tsv"
        case "$FI" in
          *Multi*  ) 
                     FTYPE="_multi-part_"
                     FNAME=$DIR$FTYPE$DATE$EXTENSION
                     echo "Writing $FNAME for $DIR"
                     $CMD $FI $FNAME
                     ;;
          *Serials*) 
                     FTYPE="_serials_"
                     FNAME=$DIR$FTYPE$DATE$EXTENSION
                     echo "Writing $FNAME for $DIR"
                     $CMD $FI $FNAME
                     ;;
          *Single* ) 
                     FTYPE="_single-part_"
                     FNAME=$DIR$FTYPE$DATE$EXTENSION
                     echo "Writing $FNAME for $DIR"
                     $CMD $FI $FNAME
                     ;;
          *        ) break ;;
        esac
     done
     echo "* * * * * * *"
   fi
done
exit

#!/bin/sh

# sh script to run SDOSS-HFC tracking software.
# X.Bonnin, 03-MAR-2014

if [ -z "$SDOSS_HFC_DIR" ]
then
	echo "$SDOSS_HFC_DIR must be defined!"
fi

EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_tracking.py

STARTTIME=2012-02-01T00:00:00
ENDTIME=2012-02-01T22:00:00

CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_tracking.config
OUTPUT_DIR=$SDOSS_HFC_DIR/products

echo 'Starting sdoss_hfc_tracking.py'

python $EXE $CONFIG_FILE -s $STARTTIME -e $ENDTIME \
            -o $OUTPUT_DIR \
            -V

echo 'Done'
exit 0

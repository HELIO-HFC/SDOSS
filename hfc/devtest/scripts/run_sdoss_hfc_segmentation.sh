#!/bin/sh

# sh script to run SDOSS-HFC segmentation wrapper software.
# X.Bonnin, 03-MAR-2014

if [ -z "$SDOSS_HFC_DIR" ]
then
	echo "$SDOSS_HFC_DIR must be defined!"
fi

EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_segmentation.py

STARTTIME=2012-02-01T00:00:00
ENDTIME=2012-02-01T04:00:00
CADENCE=7200
PJOBS=3

CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_segmentation.config
DATA_DIR=$SDOSS_HFC_DIR/data
OUTPUT_DIR=$SDOSS_HFC_DIR/products
SDOSS_IDL_BIN=$SDOSS_HFC_DIR/bin/sdoss_hfc_processing.sav

echo 'Starting sdoss_hfc_segmentation.py'

python $EXE $CONFIG_FILE -s $STARTTIME -e $ENDTIME \
            -o $OUTPUT_DIR -d $DATA_DIR \
            -c $CADENCE -j $PJOBS -V -Q

echo 'Done'
exit 0

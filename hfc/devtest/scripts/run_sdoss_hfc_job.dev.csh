#!/bin/csh

# csh script to run SDOSS-HFC wrapper software.
# X.Bonnin, 03-MAR-2014

if (! -d $SDOSS_HFC_DIR) then
	echo "$SDOSS_HFC_DIR must be defined first!"
	exit 1
endif

runssw

set EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_processing.py

set STARTTIME=2012-02-01T00:00:00
set ENDTIME=2012-02-01T04:00:00
set CADENCE=7200
set NPROC=3

set CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_processing.config
set DATA_DIR=$SDOSS_HOME_DIR/data
set OUTPUT_DIR=$SDOSS_HOME_DIR/products
set SDOSS_IDL_BIN=$SDOSS_HFC_DIR/bin/sdoss_hfc_processing.sav

echo 'Starting sdoss_hfc_processing.py'

python $EXE $CONFIG_FILE -s $STARTTIME -e $ENDTIME \
            -o $OUTPUT_DIR -d $DATA_DIR \
            -c $CADENCE -n $NPROC -V -Q 

echo 'Done'
exit 0

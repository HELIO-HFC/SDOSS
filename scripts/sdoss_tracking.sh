#!/bin/sh

##Set main paths
SRC_DIR=/obs/helio/hfc/frc/sdoss 
WORK_DIR=/travail/helio/hfc/frc/sdoss
PRODUCT_DIR=$SRC_DIR/products
DATA_DIR=ftp://ftpbass2000.obspm.fr/pub/helio/sdoss

SCRIPT=$SRC_DIR/lib/python/hfc/sdoss_hfc_tracking.py

##Append sdoss python modules' path to $PYTHONPATH
PYTHONPATH=$PYTHONPATH:$SRC_DIR/lib/python/hfc
PYTHONPATH=$PYTHONPATH:$SRC_DIR/lib/python/net
PYTHONPATH=$PYTHONPATH:$SRC_DIR/lib/python/extra
PYTHONPATH=$PYTHONPATH:$SRC_DIR/src
export PYTHONPATH

#Input arguments
STARTTIME='2011-08-01T00:00:00'
ENDTIME='2011-08-31T00:00:00'
#STARTTIME=`date --date '20 days ago' '+%Y-%m-%dT%H:%M:%S'`
#ENDTIME=`date --date '2 days ago' '+%Y-%m-%dT%H:%M:%S'`
CONFIG_FILE=$SRC_DIR/config/sdoss_tracking.config
HISTORY_FILE=$PRODUCT_DIR/sdoss_tracking.history

echo "Inputs arguments are:"
echo "STARTTIME="$STARTTIME
echo "ENDTIME="$ENDTIME
echo "HISTORY_FILE="$HISTORY_FILE

ARGS="-h "$HISTORY_FILE" -d "$DATA_DIR" -s "$STARTTIME" -e "$ENDTIME" -o "$PRODUCT_DIR" "$CONFIG_FILE
OPTS="-V -R"

echo "Running "$SCRIPT"...  ("`date`")"
echo "time python "$SCRIPT $OPTS $ARGS
time python $SCRIPT $OPTS $ARGS
echo "Running "$SCRIPT"...done  ("`date`")"




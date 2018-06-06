#!/bin/bash
#SBATCH --job-name=sdoss_hfc_seg
#SBATCH --nodes=1 --ntasks-per-node=16
#SBATCH --time=1439
#SBATCH --partition=medium
#SBATCH --mem=32gb
#SBATCH --output=/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_seg%j.prod.out
#SBATCH --mail-user=christian.renie@obspm.fr
#SBATCH --mail-type=ALL

##Set paths
source /obs/helio/hfc/frc/sdoss/hfc/prod/sdoss_hfc_env_setup.prod.sh

OUTPUT_DIR=/data/helio/hfc/frc/sdoss
DATA_DIR=/poubelle/helio/hfc/frc/sdoss/data

EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_processing.py

CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_segmentation.config
BIN_FILE=$SDOSS_HFC_DIR/bin/sdoss_hfc_processing.sav

#Input arguments
PJOBS=3
CADENCE=7200
STARTTIME=`date '+%Y-%m-%dT00:00:00' --date "2 months ago"`
#ENDTIME=`date '+%Y-%m-%dT%H:%M:%S'`
#STARTTIME=2017-08-01T00:00:00
#ENDTIME=2017-10-10T23:59:59
ENDTIME=`date '+%Y-%m-%dT%H:%M:%S' --date "1 days ago"`

HISTORY_FILE=$OUTPUT_DIR/sdoss_hfc_seg.prod.history

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
#LOG_FILE="/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_seg$SLURM_JOB_ID.prod.out"
LOG_FILE="/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_seg$STARTTIME.prod.out"
echo "Starting sdoss_hfc_seg job #$SLURM_JOB_ID on "$CURRTIME
echo "Opening log file: $LOG_FILE"

CMD="$EXE -R -V -Q -c $CADENCE \
     -j $PJOBS -s $STARTTIME -e $ENDTIME \
     -d $DATA_DIR -o $OUTPUT_DIR \
     -h $HISTORY_FILE -b $BIN_FILE \
	$CONFIG_FILE"

echo "python "$CMD
time python $CMD

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
echo "Job $SLURM_JOB_ID done on "$CURRTIME

exit 0

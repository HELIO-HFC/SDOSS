#!/bin/bash
#SBATCH --job-name=sdoss_hfc_job
#SBATCH --nodes=1 --ntasks-per-node=16
#SBATCH --time=60
#SBATCH --partition=short 
#SBATCH --mem=24gb 
#SBATCH --output=/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_job%j.dev.out
#SBATCH --mail-user=xavier.bonnin@obspm.fr
#SBATCH --mail-type=ALL

##Set paths
source /obs/helio/hfc/frc/sdoss/hfc/setup/sdoss_hfc_env_setup.dev.sh

EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_processing.py

OUTPUT_DIR=/data/helio/hfc/frc/sdoss
DATA_DIR=/poubelle/helio/hfc/frc/sdoss/data

PROCE=$SDOSS_HFC_DIR/src/sdoss_hfc_processing.py
TRACK=$SDOSS_HFC_DIR/src/sdoss_hfc_tracking.py

CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_processing.config
BIN_FILE=$SDOSS_HFC_DIR/bin/sdoss_hfc_processing.sav

#Input arguments
NPROC=4
CADENCE=7200
#STARTTIME=`date '+%Y-%m-%d' --date "2 months ago"`
STARTTIME=2012-01-02T00:00:00
ENDTIME=2012-01-02T23:59:59
#ENDTIME=`date '+%Y-%m-%d' --date "1 days ago"`

HISTORY_FILE=$OUTPUT_DIR/sdoss_hfc_job$SLURM_JOB_ID.dev.history

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
LOG_FILE="/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_job$SLURM_JOB_ID.dev.out"
echo "Starting sdoss_hfc_job #$SLURM_JOB_ID on "$CURRTIME
echo "Opening log file: $LOG_FILE"

CMD="$EXE -R -V -Q -c $CADENCE \
     -n $NPROC -s $STARTTIME -e $ENDTIME \
     -d $DATA_DIR -o $OUTPUT_DIR \
     -h $HISTORY_FILE -b $BIN_FILE \
	$CONFIG_FILE" 

echo "python "$CMD
time python $CMD

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
echo "Job $SLURM_JOB_ID done on "$CURRTIME

exit 0



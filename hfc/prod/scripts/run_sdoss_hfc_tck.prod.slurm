#!/bin/bash
#SBATCH --job-name=sdoss_hfc_tck
#SBATCH --nodes=1 --ntasks-per-node=16
#SBATCH --time=1439
#SBATCH --partition=medium
#SBATCH --mem=1gb
#SBATCH --output=/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_tck%j.prod.out
#SBATCH --mail-user=christian.renie@obspm.fr
#SBATCH --mail-type=ALL

##Set paths
source /obs/helio/hfc/frc/sdoss/hfc/prod/sdoss_hfc_env_setup.prod.sh

OUTPUT_DIR=/data/helio/hfc/frc/sdoss
DATA_DIR=/poubelle/helio/hfc/frc/sdoss/data

EXE=$SDOSS_HFC_DIR/src/sdoss_hfc_tracking.py
CONFIG_FILE=$SDOSS_HFC_DIR/config/sdoss_hfc_tracking.config
LOG_FILE="/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_tck$SLURM_JOB_ID.prod.out"

#Input arguments
STARTTIME=`date '+%Y-%m-%dT%H:%M:%S' --date "2 months ago"`
#ENDTIME=`date '+%Y-%m-%dT%H:%M:%S' --date "2 days ago"`
#STARTTIME=2018-05-09T00:00:00
#ENDTIME=2018-05-22T23:59:59
ENDTIME=`date '+%Y-%m-%dT%H:%M:%S' --date "1 days ago"`

HISTORY_FILE=$OUTPUT_DIR/sdoss_hfc_tck.prod.history

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
LOG_FILE="/poubelle/helio/hfc/frc/sdoss/logs/sdoss_hfc_tck$SLURM_JOB_ID.prod.out"
echo "Starting sdoss_hfc_tck job #$SLURM_JOB_ID on "$CURRTIME
echo "Opening log file: $LOG_FILE"


CMD="$EXE -V  \
     -s $STARTTIME -e $ENDTIME \
     -o $OUTPUT_DIR \
     -h $HISTORY_FILE  \
	$CONFIG_FILE"

echo "python "$CMD
time python $CMD

CURRTIME=`date +%Y-%m-%d' '%H:%M:%S`
echo "Job $SLURM_JOB_ID done on "$CURRTIME

exit 0

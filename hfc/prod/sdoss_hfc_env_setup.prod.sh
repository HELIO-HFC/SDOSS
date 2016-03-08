#! /bin/sh

# Script to load environment variables 
# required by SDOSS for HFC.
#
# SDOSS_HOME_DIR must be edited by hand! 
#
# To load this script:
# >source sdoss_hfc_env_setup.sh
#
# X.Bonnin, 14-JAN-2014

SDOSS_HOME_DIR=/obs/helio/hfc/frc/sdoss
export SDOSS_HOME_DIR

SDOSS_HFC_DIR=$SDOSS_HOME_DIR/hfc/prod
export SDOSS_HFC_DIR

# Append python library path to $PYTHONPATH
PYTHONPATH=$PYTHONPATH:$SDOSS_HFC_DIR/src
PYTHONPATH=$PYTHONPATH:$SDOSS_HFC_DIR/scripts
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/lib/python/net
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/lib/python/extra
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/src
export PYTHONPATH

# Append idl library path to $IDL_PATH
IDL_PATH=$IDL_PATH:+$SDOSS_HOME_DIR/src
IDL_PATH=$IDL_PATH:+$SDOSS_HOME_DIR/lib/idl
IDL_PATH=$IDL_PATH:+$SDOSS_HFC_DIR/src
IDL_PATH=$IDL_PATH:+$SDOSS_HFC_DIR/scripts
export IDL_PATH

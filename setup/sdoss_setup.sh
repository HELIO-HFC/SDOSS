#! /bin/sh

# Script to load environment variables 
# required by SDOSS.
# Must be placed in the sdoss/setup sub-directory. 
#
# To load this script:
# >source sdoss_setup.csh
#
# X.Bonnin, 20-JUN-2013

CURRENT_DIR=`pwd`

ARGS=${BASH_SOURCE[0]}
cd `dirname $ARGS`/..
export SDOSS_HOME_DIR=`pwd`
cd $CURRENT_DIR

# Append python library path to $PYTHONPATH
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/lib/python/hfc
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/lib/python/net
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/lib/python/extra
PYTHONPATH=$PYTHONPATH:$SDOSS_HOME_DIR/src
export PYTHONPATH

# Append idl library path to $IDL_PATH
IDL_PATH=$IDL_PATH:+$RABAT3_HOME_DIR/src
IDL_PATH=$IDL_PATH:+$RABAT3_HOME_DIR/lib/idl
export IDL_PATH
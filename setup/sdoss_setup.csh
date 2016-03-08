#! /bin/csh
#
# Script to load environment variables 
# required by SDOSS.
# Must be placed in the sdoss/setup sub-directory. 
#
# To load this script:
# >source sdoss_setup.csh
#
# X.Bonnin, 20-JUN-2013

# Define sdoss home directory
setenv SDOSS_HOME_DIR /obs/helio/hfc/frc/sdoss


# Append python library path to $PYTHONPATH
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/lib/python/extra
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/lib/python/net
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/lib/python/hfc
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/src

# Append idl library path to $IDL_PATH
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HOME_DIR/src
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HOME_DIR/lib/idl/hfc

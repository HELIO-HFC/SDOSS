#! /bin/csh
#
# Script to load environment variables 
# required by SDOSS for HFC (dev. version).
#
# SDOSS_HOME_DIR must be edited by hand!
#
# To load this script:
# >source sdoss_hfc_env_setup.dev.csh
#
# X.Bonnin, 20-FEB-2014

# Define sdoss home directory
#setenv SDOSS_HOME_DIR /obs/helio/hfc/frc/sdoss
setenv SDOSS_HOME_DIR $HOME/Work/Projects/HELIO/Services/HFC/devtest/Features/Codes/sdoss # X.Bonnin path

# Define sdoss home directory
setenv SDOSS_HFC_DIR $SDOSS_HOME_DIR/hfc/devtest

# Append python library path to $PYTHONPATH
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/lib/python/extra
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/lib/python/net
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HFC_DIR/src
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HFC_DIR/scripts
setenv PYTHONPATH "$PYTHONPATH":$SDOSS_HOME_DIR/src

# Append idl library path to $IDL_PATH
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HOME_DIR/src
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HOME_DIR/lib/idl
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HFC_DIR/src
setenv IDL_PATH "$IDL_PATH":+$SDOSS_HFC_DIR/scripts

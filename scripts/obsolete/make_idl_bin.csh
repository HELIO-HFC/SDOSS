#!/bin/csh

# Produce IDL runtime binary files called by the sdoss program.
# Usage : csh make_idl_bin.csh 
# X.Bonnin, 20-11-2012

source /obs/helio/hfc/frc/sdoss/setup/sdoss_setup.csh
runssw

sswidl -e @$SDOSS_HOME_DIR/lib/idl/batch/make_sdoss_bin.batch

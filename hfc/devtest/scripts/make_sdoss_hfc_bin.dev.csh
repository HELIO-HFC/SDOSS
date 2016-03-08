#!/bin/csh 

# csh script to make an IDL XDR binary file
# of the sdoss_hfc_processing.pro routine,
# to be called from a command line using the
# IDL runtime mode.
# The binary file is self-consistent, containing all of the 
# compiled routines required to run sdoss_hfc_processing.pro.
# X.Bonnin, 03-MAR-2014

source ../../setup/sdoss_hfc_env_setup.dev.csh

runssw

sswidl -e @make_sdoss_hfc_bin.batch.pro


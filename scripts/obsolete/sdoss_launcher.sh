#! /bin/sh -f

# Script file to run sdoss code calling sdoss_launcher.sav from idl

#Directory definitions
SRC_DIR=/obs/helio/hfc/frc/sdoss
BIN_DIR=$SRC_DIR/lib/idl/bin
DATA_DIR=$SRC_DIR/data
PRODUCT_DIR=$SRC_DIR/products

#SDOSS IDL runtime binary file
SDOSS_BIN=$BIN_DIR/sdoss_processing.sav

#Input argument definitions
FNC=$DATA_DIR/hmi.ic_45s.2011.05.01_00:00:00_TAI.continuum.fits
FNM=$DATA_DIR/hmi.m_45s.2011.05.01_00:00:00_TAI.magnetogram.fits
FEAT_PIX="9"
ARGS=$FNC" "$FNM" data_dir="$DATA_DIR" output_dir="$PRODUCT_DIR" feat_min_pix="$FEAT_PIX" /CSV /LOG /QUICKLOOK /VERBOSE"

echo "run "$SDOSS_BIN"... ("`date`")"
sleep 5's'
#time /usr/bin/env idl -queue -rt=$SDOSS_BIN -args $ARGS
echo "run "$SDOSS_BIN"...done ("`date`")"
#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Contains global variables for sdoss_hfc programs.
@author: X.Bonnin (LESIA, CNRS)
"""

import socket
import os
from datetime import datetime, timedelta
import logging

global HOSTNAME, IDL_EXE_PATH, \
    JSOC_URL, VSO_URL, \
    CURRENT_PATH, TODAY, \
    INPUT_TFORMAT, JSOC_TFORMAT, FILE_TFORMAT, \
    COMP_TFORMAT, STARTTIME, ENDTIME, \
    CADENCE, OUTPUT_DIRECTORY, DATA_DIRECTORY, \
    SDOSS_IDL_BIN, PJOBS, HISTORY_FILE, \
    LOGGER, FTP_URL, LOG, TRACKFIELDS


# Current hostname
HOSTNAME = socket.gethostname()

# IDL application local path
IDL_EXE_PATH = "/usr/local/bin/idl"
#IDL_EXE_PATH = "/Applications/exelis/idl/bin/idl"

# jsoc/cgi server url of show_info function
JSOC_URL = "http://jsoc.stanford.edu/cgi-bin/ajax/show_info"

# VSO server url
#VSO_URL = "http://vso2.tuc.noao.edu"
VSO_URL = "http://netdrms01.nispdc.nso.edu"

# HFC ftp server url for tracking
#FTP_URL = "ftp://ftpbass2000.obspm.fr/pub/helio/sdoss"
FTP_URL = "ftp://ftpbass2000.obspm.fr/pub/helio/hfc/obsparis/frc/sdoss/results"

# Path definition
CURRENT_PATH = os.getcwd()

# Time inputs
TODAY = datetime.today()
INPUT_TFORMAT = '%Y-%m-%dT%H:%M:%S'
JSOC_TFORMAT = '%Y.%m.%d_%H:%M:%S'
COMP_TFORMAT = '%Y%m%d%H%M%S'
FILE_TFORMAT = "%Y%m%dT%H%M%S"

# Default values of input arguments
STARTTIME = (TODAY - timedelta(days=10)).strftime(INPUT_TFORMAT)
ENDTIME = TODAY.strftime(INPUT_TFORMAT)
CADENCE = 45
OUTPUT_DIRECTORY = os.path.join(CURRENT_PATH, "../products")
DATA_DIRECTORY = os.path.join(CURRENT_PATH, "../data")
SDOSS_IDL_BIN = os.path.join(CURRENT_PATH, "../bin/sdoss_hfc_processing.sav")
PJOBS = 1

TRACKFIELDS = ["ID_SUNSPOT", "TRACK_ID", "DATE_OBS",
               "FEAT_X_PIX", "FEAT_Y_PIX",
               "PHENOM", "REF_FEAT", "LVL_TRUST",
               "FEAT_FILENAME",
               "RUN_DATE"]

# history filename
HISTORY_FILE = os.path.join(
    OUTPUT_DIRECTORY,
    "sdoss_hfc_processing.%s.history" % (
        TODAY.strftime(COMP_TFORMAT)))

# Create logger for sdoss_hfc
LOGGER = "sdoss_hfc"
LOG = logging.getLogger(LOGGER)

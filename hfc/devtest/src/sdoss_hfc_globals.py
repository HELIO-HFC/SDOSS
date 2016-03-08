#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Contains global variables for sdoss_hfc programs.
@author: X.Bonnin (LESIA, CNRS)
"""

import socket
import os
from datetime import datetime, timedelta

global HOSTNAME, IDL_EXE_PATH, \
        JSOC_URL, VSO_URL, \
        CURRENT_PATH, TODAY, \
        INPUT_TIMEFORMAT, JSOC_TIMEFORMAT, \
        COMP_TIMEFORMAT, STARTTIME, ENDTIME, \
        CADENCE, OUTPUT_DIRECTORY, DATA_DIRECTORY, \
        SDOSS_IDL_BIN, NPROCESSINGS, \
        LOGGER

# Current hostname 
HOSTNAME = socket.gethostname()

# IDL application local path
IDL_EXE_PATH = "/usr/local/bin/idl"
#IDL_EXE_PATH = "/Applications/exelis/idl/bin/idl"

# jsoc/cgi server url of show_info function
JSOC_URL = "http://jsoc.stanford.edu/cgi-bin/ajax/show_info"

# VSO server url
VSO_URL="http://vso2.tuc.noao.edu"

# Path definition
CURRENT_PATH = os.getcwd()

# Time inputs
TODAY = datetime.today()
INPUT_TIMEFORMAT = '%Y-%m-%dT%H:%M:%S'
JSOC_TIMEFORMAT = '%Y.%m.%d_%H:%M:%S' 
COMP_TIMEFORMAT = '%Y%m%d%H%M%S' 

# Default values of input arguments
STARTTIME = (TODAY - timedelta(days=10)).strftime(INPUT_TIMEFORMAT) #starttime
ENDTIME = TODAY.strftime(INPUT_TIMEFORMAT) #endtime
CADENCE = 45 #cadence in sec (if cadence <= 45 --> cadence = 45)
OUTPUT_DIRECTORY = os.path.join(CURRENT_PATH,"../products") #output directory
DATA_DIRECTORY = os.path.join(CURRENT_PATH,"../data") #data directory
SDOSS_IDL_BIN = os.path.join(CURRENT_PATH,"../bin/sdoss_hfc_processing.sav") #Local sdoss idl (runtime) binary file
NPROCESSINGS = 1 #number of parallelized processings

LOGGER = "sdoss_hfc_processing" 

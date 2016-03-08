#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Download a list of HMI files for a given timerange.
@author: X.Bonnin (LESIA, CNRS)
"""

import os
import sys
import socket
import subprocess
import urllib2
import argparse
from datetime import datetime, timedelta
import time

__version__ = "1.0"
#__license__ = ""
__author__ = "Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "21-FEB-2014"


#### Global variables ####

LAUNCH_TIME = time.time()

HOSTNAME = socket.gethostname()

# jsoc/cgi server url of show_info function
JSOC_URL = "http://jsoc.stanford.edu/cgi-bin/ajax/show_info"

# VSO server url
VSO_URL = "http://vso2.tuc.noao.edu"

# Path definition
CURRENT_DIR = os.getcwd()

# Time inputs
TODAY = datetime.today()
INPUT_TIMEFORMAT = '%Y-%m-%dT%H:%M:%S'
JSOC_TIMEFORMAT = '%Y.%m.%d_%H:%M:%S'

# Default input arguments
NEAR_DATE=TODAY.strftime(INPUT_TIMEFORMAT)


def get(ds, near_date=NEAR_DATE, starttime=None,
        endtime=None, cadence=None, target_dir=CURRENT_DIR):

    print "To be continued"

if (__name__ == "__main__"):

    parser = argparse.ArgumentParser(
        description="Script to download SDO/HMI files.",
        add_help=True, conflict_handler='resolve')

    parser.add_argument('dataset', nargs=1,
                        help="Specify HMI dataset (Ic or M)")
    parser.add_argument('-n', '--near_date', nargs='?',
                        default=NEAR_DATE,
                        help="Date and time for which a file must download.")
    parser.add_argument('-s', '--starttime', nargs='?',
                        default=None,
                        help="First date and time")
    parser.add_argument('-e', '--endtime', nargs='?',
                        default=None,
                        help="Last date and time")
    parser.add_argument('-c', '--cadence', nargs='?',
                        default=None, type=int,
                        help="Cadence of observations in seconds")
    parser.add_argument('-t', '--target_dir', nargs='?',
                        default=CURRENT_DIR,
                        help="Directory where data files will be saved")

    args = parser.parse_args()
    ds = args.__dict__.pop('dataset')[0]

    get(ds, **args.__dict__)

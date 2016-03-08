#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Wrapper to run the sdoss recognition code in the HFC framework.
@author: X.Bonnin (LESIA, CNRS)
"""

import os
import sys
import socket
import threading
import subprocess
import urllib2
import argparse
import csv
from datetime import datetime, timedelta
import time
import logging

try:
    from MyToolkit import setup_logging, add_quote, download_file
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tMyToolkit module is required!")

# Import sdoss hfc global variables
try:
    from sdoss_hfc_globals import *
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tsdoss_hfc_globals module is required!")

# Import sdoss hfc methods 
try:
    from sdoss_hfc_methods import *
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tsdoss_hfc_methods module is required!")

# Import sdoss hfc classes
try:
    from sdoss_hfc_classes import *
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tsdoss_hfc_classes module is required!")

__version__ = "1.1"
#__license__ = ""
__author__ ="Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__="xavier.bonnin@obspm.fr"
__date__="21-FEB-2014"

VERSION = __version__

LAUNCH_TIME = time.time()

def main():

    parser = argparse.ArgumentParser(description="Program to run sdoss code.",
                     add_help=True,conflict_handler='resolve')
    parser.add_argument('config_file',
                nargs=1,help="SDOSS HFC configuration file")
    parser.add_argument('-s','--starttime',nargs='?', 
                default=STARTTIME,
                help="start date and time [default="+
                STARTTIME+"]")
    parser.add_argument('-e','--endtime',nargs='?',
                default=ENDTIME,
                help="end date and time [default="+
                ENDTIME+"]")
    parser.add_argument('-c','--cadence',nargs='?',default=CADENCE,type=int,
                help="cadence of observations in seconds [default="+str(CADENCE)+"]")           
    parser.add_argument('-o','--output_directory',nargs='?',
                default=OUTPUT_DIRECTORY,
                help="output directory [default="+OUTPUT_DIRECTORY+"]")
    parser.add_argument('-d','--data_directory',nargs='?',
                default=DATA_DIRECTORY,
                help="data directory [default="+DATA_DIRECTORY+"]")
    parser.add_argument('-b','--sdoss_idl_bin',nargs='?',
                default=SDOSS_IDL_BIN,
                help="sdoss idl binary file [default="+SDOSS_IDL_BIN+"]")   
    parser.add_argument('-n','--nprocessings',nargs='?',
                default=NPROCESSINGS, type=int,
                help="number of parallelized processings [default="+str(NPROCESSINGS)+"]")
    parser.add_argument('-q','--sqlite_file',nargs='?',default=None,
                help="path to the sdoss SQLite database file")
    parser.add_argument('-l','--log_file',nargs='?',default=None,
                help="Log file.")
    parser.add_argument('-Q','--Quicklook',action='store_true',
                help="save quick-look images")
    parser.add_argument('-R','--Remove_data',action='store_true',
                help="remove data files after processing.")
    parser.add_argument('-V','--Verbose',action='store_true',
                help="verbose mode")
    parser.add_argument('--version',action='store_true',
                help="Print software version and exit")

    Namespace = parser.parse_args()

    if (Namespace.version):
        print 'SDOSS Version: %s (%s)' % (VERSION,__date__)
        sys.exit()

    config_file = Namespace.config_file[0]
    starttime = datetime.strptime(Namespace.starttime,INPUT_TIMEFORMAT)
    endtime = datetime.strptime(Namespace.endtime,INPUT_TIMEFORMAT)
    cadence = Namespace.cadence
    output_directory = Namespace.output_directory
    sdoss_idl_bin = Namespace.sdoss_idl_bin
    data_directory = Namespace.data_directory
    nprocessings = Namespace.nprocessings
    sqlite_file = Namespace.sqlite_file
    log_file = Namespace.log_file
    quicklook = Namespace.Quicklook
    remove = Namespace.Remove_data
    verbose = Namespace.Verbose

    # Setup the logging
    setup_logging(filename=log_file,quiet = False, verbose = verbose)   

    # Create a logger
    global LOG 
    LOG=logging.getLogger(LOGGER)
    LOG.info("Starting sdoss_hfc_processing.py on "+HOSTNAME+" ("+TODAY.strftime(INPUT_TIMEFORMAT)+")")

    if not (os.path.isfile(config_file)):
        LOG.error("%s does not exist!",config_file)

    # Check SSW_ONTOLOGY environment variable existence
    if not (os.environ.has_key("SSW_ONTOLOGY")):
        LOG.error("$SSW_ONTOLOGY environment variable must be defined!")
        sys.exit(1) 
        
    sdoss_jobs = setup_job(starttime,endtime,
                            sqlite_file=sqlite_file,
                            cadence=cadence)
    
    sys.exit("Ajouter le threading directement dans setup_job")

    if (len(sdoss_jobs) == 0):
        LOG.warning("No sdoss job to process, exit!")
        sys.exit(0)

    #Initialize sdoss job threads for the unprocessed files
    threadList = []
    for current_job in sdoss_jobs:
        threadList.append(run_sdoss(current_job,config_file, 
                            output_directory=output_directory,
                            data_directory=data_directory,
                            sdoss_idl_bin=sdoss_idl_bin,
                            quicklook=quicklook,
                            remove_data=remove,
                            verbose=verbose))

    nthread = len(threadList) 
    if (nthread == 0):
        LOG.warning("Empty processing list!")
        sys.exit(1)
    
    # Run sdoss processings
    LOG.info("Running %i sdoss jobs...",nthread)
    running = []
    npending = nthread 
    for current_thread in threadList:
        if (len(running) < nprocessings):
            current_thread.start()
            running.append(current_thread)
            npending-=1
            LOG.info("Job [#%i] has started. (%s)",current_thread.thread_id, str(datetime.today()))
            LOG.info("%i/%i current running/pending job(s).",len(running),npending)
            time.sleep(3)           
        
        i=0
        while(len(running) >= nprocessings):
            if (running[i].terminated):
                if (running[i].success):
                    with (open(history_file,'a')) as fw:
                        fw.write(running[i].fileid[0]+"\n")
                    LOG.info("Job [#%i] has terminated correctly. (%s)" \
                                 ,running[i].thread_id, \
                                 str(datetime.today()))
                else:
                    LOG.error("Job [#%i] has failed! (%s)" \
                                  ,running[i].thread_id, \
                                  str(datetime.today()))
                running.remove(running[i])
            i=(i+1)%nprocessings

    LOG.info("Running %i sdoss jobs...done",nthread)
    LOG.info("Total elapsed time: %f min.",(time.time() - LAUNCH_TIME)/60.0)


if (__name__ == "__main__"):
    main()

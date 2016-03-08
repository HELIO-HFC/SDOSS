#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Module containing methods for sdoss_hfc_processing.py script.
@author: X.Bonnin (LESIA, CNRS)
"""

__version__ = "1.1"
#__license__ = ""
__author__ ="Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__="xavier.bonnin@obspm.fr"
__date__="21-FEB-2014"

import os
import sys
import urllib2
import logging

try:
    from MyToolkit import setup_logging, add_quote, download_file, sqlite_get
except:
    sys.exit ("Import failed in module sdoss_hfc_methods:\n\tMyToolkit module is required!")

# Import sdoss hfc global variables
try:
    from sdoss_hfc_globals import *
except:
    sys.exit ("Import failed in module sdoss_hfc_methods:\n\tsdoss_hfc_globals module is required!")

# Import sdoss hfc classes 
try:
    from sdoss_hfc_classes import sdoss_job
except:
    sys.exit ("Import failed in module sdoss_hfc_methods:\n\tsdoss_hfc_methods module is required!")

LOG=logging.getLogger(LOGGER)

# Method to setup a sdoss job
def setup_job(starttime,endtime,sqlite_file=None,cadence=CADENCE):

    """Method to instanciate a sdoss job"""

   # Get list of HMI Ic T_REC_index and T_REC to process between starttime and endtime
    ic_index, ic_dates = query_jsoc("hmi.ic_45s",starttime,endtime,cadence=cadence)
    if (len(ic_index) == 0):
        LOG.warning("Empty hmi file set!")
        sys.exit(1)
    else:
        LOG.info("%i record(s) returned.",len(ic_index))

    nfile = len(ic_index)
    if (nfile == 0):
        LOG.warning("Empty data set!")
        sys.exit(0)

    LOG.info("%i hmi [Ic,M] fileset(s) to process.",nfile)

    # Generate the vso url of hmi files
    ic_url = get_vso_url("hmi__Ic_45s",ic_index) 
    m_url = get_vso_url("hmi__M_45s",ic_index)

    if (sqlite_file is not None) and not (os.path.isfile(sqlite_file)):
        LOG.error("No sqlite file found at the following location: \n\t %s",sqlite_file)
        sys.exit(1)
    else:
        LOG.info("Querying the sqlite file: %s",sqlite_file)

    joblist=list() ; nok=0
    for i,ic_url_i in enumerate(ic_url):
        cmd_i="SELECT ID FROM HISTORY WHERE (FILEID=\"%s\") AND (IC_URL=\"%s\")" % (str(ic_index[i]),ic_url_i)
        resp_i=sqlite_get(sqlite_file,cmd_i)
        if (resp_i):
            LOG.info("Dataset #%s on %s has been already processed",str(ic_index[i]),str(ic_dates[i]))
            continue
            nok+=1

        setid=i-nok
        joblist.append(sdoss_job(setid,urls=[ic_url_i,m_url[i]],
                                    dates=[ic_dates[i],ic_dates[i]],
                                    index=[ic_index[i],ic_index[i]]))
        LOG.info("Dataset #%s on %s has been appended for processing",str(ic_index[i]),str(ic_dates[i]))

    return joblist


# Module used in Python 2.6 to compute datetime.total_seconds() module operation.
def total_sec(td):
    return (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10**6) / 10**6


# Module to get the list of hmi files indexes from JSOC 
def query_jsoc(ds,starttime,endtime,cadence=None):   

    LOG.info("Retrieving "+ds+" data list from jsoc server between "+ \
                starttime.strftime(INPUT_TIMEFORMAT)+" and "+ \
                endtime.strftime(INPUT_TIMEFORMAT)+" ...")
    if (cadence is not None): 
        LOG.info("Cadence is %i sec.",cadence)

    # Define starttime and endtime (in jsoc cgi time format)
    stime = starttime - timedelta(seconds=20) #starttime - 20 sec.
    etime = endtime + timedelta(seconds=20) #endtime + 20 sec.
    stime = stime.strftime(JSOC_TIMEFORMAT)
    etime = etime.strftime(JSOC_TIMEFORMAT)
    
    # Load date set information from jsoc

    
    # Build url 
    url = JSOC_URL + "?ds="+ds+"["+stime+"-"+etime
    if (cadence is not None): url+="@%is" % (cadence)
    url+="]&key=T_REC_index%2CT_REC"
    LOG.info("Reaching --> "+url)
    # Get T_REC_index and T_REC list
    f = urllib2.urlopen(url)

    T_REC_index=[] ; T_REC=[]
    for row in f.read().split("\n")[1:-1]:
        if (row):
            rs = row.split()
            T_REC_index.append(rs[0])
            T_REC.append(datetime.strptime(rs[1],JSOC_TIMEFORMAT+"_TAI"))
            
    return T_REC_index, T_REC


# Module to find in a first list of dates, the ones that are
# nearest to the dates provided in a second reference list.
# Module returns the subscripts of closest dates of the first list.
def find_nearest(input_datetime,ref_datetime,dt_max=-1):

    if (len(input_datetime) == 0) or \
        (len(ref_datetime) == 0):
        return []
    
    subscripts = [] ; 
    for ref_date in ref_datetime:
        dt=[]
        for in_date in input_datetime:
            dt.append(abs(total_sec(ref_date - in_date)))
        if (float(min(dt)) > float(dt_max)):
            subscripts.append(-1)   
        else:
            subscripts.append(list(dt).index(min(dt)))
    
    return subscripts

# Module to generate the url of data set in vso server.
def get_vso_url(ds,t_rec_index,rice=True):

    url = VSO_URL + "/cgi-bin/drms_test/drms_export.cgi?series="+ds
    if (rice): url+=";compress=rice"

    urlList=[]
    for current_index in t_rec_index:
        record = str(current_index)+"-"+str(current_index)
        current_url = url+";record="+record
        urlList.append(current_url)

    return urlList


def check_history(history_file,urlList):

    if not (os.path.isfile(history_file)):
        LOG.warning(history_file+" does not exist!")
        return []

    # Read checklist file
    fr = open(history_file,'r')
    fileList = fr.read().split("\n")
    fr.close()

    processed = []
    for current_url in urlList:
        if (current_url in fileList):
            LOG.info(current_url+" already processed.")
            processed.append(current_url)
        else:
            LOG.info(current_url+" not processed.")
            
    return processed


#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Simple API to query the JSOC ajax server.
Visit http://jsoc.stanford.edu/jsocwiki/AjaxJsocConnect for more explanations.
@author: X.Bonnin (LESIA, CNRS)
"""

import os, sys, socket
import threading, subprocess
import urllib2
import argparse, csv
from datetime import datetime, timedelta
import time
import logging

from MyToolkit import download_file


__version__ = "1.0"
#__license__ = ""
__author__ = "Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "21-FEB-2014"

# Global variables

# Path and URL definitions
JSOC_URL = "http://jsoc.stanford.edu/cgi-bin/ajax/"
CURRENT_DIR = os.getcwd()

# Time
TODAY = datetime.today()
INPUT_TIMEFORMAT="%Y-%m-%dT%H:%M:%S"
JSOC_TIMEFORMAT = '%Y.%m.%d_%H:%M:%S'

# Default input arguments
# Current date and time
NEAR_DATE=TODAY.strftime(INPUT_TIMEFORMAT)
# Max span duration in sec.
SPAN_DURATION=3600
# Retrieving method
METHOD="url"
#Time out in sec.
TIMEOUT=18000
# OUTPUT JSOC SERVER RESPONSE FORMAT
FORMAT="json"
# Protocol
PROTOCOL="fits"
# Time to wait in seconds before sending a exp_status request
WAIT=30

class jsoc():

    def __init__(self,dataseries,near_date=NEAR_DATE,
                starttime=None,endtime=None,
                cadence=None,span_duration=None,
                verbose=False):

        self.ds=dataseries
        self.tr=""
        self.near_date=near_date
        self.starttime=starttime
        self.endtime=endtime
        self.cadence=cadence
        self.span_duration=span_duration
        self.fetch_resp=None
        self.status_resp=None
        self.requestid=None
        self.url=""
        self.verbose=verbose

        if (starttime is not None) and (endtime is not None):
            tstart=starttime.strftime(JSOC_TIMEFORMAT)
            tend=endtime.strftime(JSOC_TIMEFORMAT)
            self.tr+="[%s-%s" % (tstart,tend)
        elif (starttime is not None) and (endtime is None):
            tstart=starttime.strftime(JSOC_TIMEFORMAT)  
            if (span_duration is None): self.span_duration=SPAN_DURATION
            self.tr+="[%s/%i" % (tstart,span_duration) 
        elif (starttime is None) and (endtime is not None):
            if (span_duration is None): self.span_duration=SPAN_DURATION
            tend=(endtime - timedelta(seconds=span_duration)).strftime(JSOC_TIMEFORMAT)     
            self.tr+="[%s/%i" % (tend,span_duration)        
        else:
            ndate=near_date.strftime(JSOC_TIMEFORMAT)
            self.tr+="[%s" % (ndate)
            if (span_duration is not None):
                self.tr+="/%is" %(span_duration)
        if (cadence is not None):
            self.tr+="@%is" % (cadence)
        if (self.tr.startswith("[")): self.tr+="]"

    def parse_json(self,resp):
        fetch_resp={}
        items=resp[1:-1].split(",")
        for item in items:
            it=item.split(":")
            if (len(it) != 2): 
                print "Error in jsoc_fetch response!"
                print "Query was: %s" % (self.url)
                print "Returned response: %s" % (resp)
                return None
            fetch_resp[it[0][1:-1]]="".join(it[1].split("\""))
        return fetch_resp


    def build_show_info(self,key=None):

        url = JSOC_URL + "show_info?ds=%s" % (self.ds)
        if (len(self.tr) >=0 ):
            url+=self.tr
        if (key is not None):
            url+="&key=%s" % ("%2C".join(key)) 

        self.url=url
        return url


    def show_info(self,key=None,output_dir=None):
        url=self.build_show_info(key=key)

        get_stream=False
        if (output_dir is None): 
            get_stream=True
        if (self.verbose): print "Fetching %s" %(url)
        target=download_file(url,target_directory=output_dir,
                get_stream=get_stream)
        return target


    def build_fetch(self,operation,
                    protocol=None,method=None,
                    requestid=None,format=None):
        url = JSOC_URL + "jsoc_fetch?op=%s" % (operation)

        if (operation == "exp_status") and (requestid is not None):
            url+="&requestid=%s" % (requestid)
        else:
            url+="&ds=%s" % (self.ds)
            if (len(self.tr) >=0 ): url+=self.tr

        if (method is not None): url+="&method=%s" % (method)
        if (protocol is not None): url+="&protocol=%s" % (protocol)
        if (format is not None): url+="&format=%s" % (format)

        self.url=url
        return url


    def fetch(self,operation,
                protocol=None,method=None,
                requestid=None,format=None):

        url=self.build_fetch(operation,
                            protocol=protocol,
                            method=method,
                            requestid=requestid,
                            format=format)
        if (self.verbose): print "Fetching %s" %(url)
        resp=download_file(url,get_stream=True)
        if not (resp.startswith("{")):
            print "Empty jsoc_fetch response!"
            print "Query was: %s" % (url)
            return None
        else:
            fetch_resp=self.parse_json(resp)
           
        self.fetch_resp=fetch_resp
        return fetch_resp

    def get_fits(self,output_dir=CURRENT_DIR,timeout=TIMEOUT,wait=WAIT):

        fetch_resp=self.fetch("exp_request",protocol=PROTOCOL,method=METHOD)
        if (fetch_resp is None): sys.exit(0)
        time.sleep(10)
        t0=time.time() ; requestid=self.fetch_resp["requestid"]
        remaining_sec=timeout - int(time.time() - t0)
        while (remaining_sec >= 0):
            if (self.verbose): print "%s    (remaining time: %i sec.)" % (self.fetch_resp,remaining_sec)
            fetch_resp=self.fetch("exp_status",requestid=requestid,format=FORMAT)
            if (fetch_resp is None): 
                print "Fetching error!"
                break
            status=int(fetch_resp['status'])
            if (status >= 3): 
                print "Status error: %i" % (status)
                break
            if (status == 0): 
                if (self.verbose): print "Processing is finished."
                break
            time.sleep(wait)
            remaining_sec=remaining_sec=timeout - int(time.time() - t0)


            print "Terminer recuperation des urls et des fichiers (mettre une url_only en option"

if (__name__ == "__main__"):
    parser = argparse.ArgumentParser(description="Script to query the JSOC AJAX server.",
                                    add_help=True,conflict_handler='resolve')
    parser.add_argument('dataseries',nargs=1,help="JSOC dataseries")
    parser.add_argument('-n','--near_date',nargs='?', 
                        default=NEAR_DATE,help="Date and time")
    parser.add_argument('-s','--starttime',nargs='?', 
                        default=None,help="Start date and time")
    parser.add_argument('-e','--endtime',nargs='?', 
                        default=None,help="End date and time")
    parser.add_argument('-c','--cadence',nargs='?',default=None,
                        type=int, help="Cadence is seconds")
    parser.add_argument('-d','--span_duration',nargs='?', type=int, 
                        default=None,help="Span duration in seconds")
    parser.add_argument('-o','--output_dir',nargs='?',
                        default=None,help="Target directory for downloaded files.")
    parser.add_argument('-S','--SHOW_INFO',action='store_true',
                        help="Perform show_info request for dataseries")
    parser.add_argument('-V','--VERBOSE',action='store_true',
                        help="Verbose mode")

    args=parser.parse_args()
    ds=args.dataseries[0]
    near_date=datetime.strptime(args.near_date,INPUT_TIMEFORMAT)
    starttime=args.starttime
    endtime=args.endtime
    cadence=args.cadence
    span_duration=args.span_duration
    output_dir=args.output_dir
    show_info=args.SHOW_INFO
    verbose=args.VERBOSE

    if (starttime is not None): starttime=datetime.strptime(starttime,INPUT_TIMEFORMAT)
    if (endtime is not None): endtime=datetime.strptime(endtime,INPUT_TIMEFORMAT)


    jsoc=jsoc(ds,near_date=near_date,starttime=starttime,
                endtime=endtime,cadence=cadence,
                span_duration=span_duration,
                verbose=verbose)

    if (args.SHOW_INFO):
        key=["T_REC_index","T_REC"]
        print jsoc.show_info(key=key,output_dir=output_dir)
    else:
        target=jsoc.get_fits(output_dir=output_dir)


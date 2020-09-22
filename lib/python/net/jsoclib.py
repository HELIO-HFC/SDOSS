#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Simple API to query the JSOC ajax server.
Visit http://jsoc.stanford.edu/jsocwiki/AjaxJsocConnect for more explanations.
@author: X.Bonnin (LESIA, CNRS)
"""

from MyToolkit import download_file
import argparse
import csv
from datetime import datetime
from datetime import timedelta
import logging
import os
import socket
import subprocess
import sys
import threading
import time
import urllib2
import json


__version__ = "1.0"
#__license__ = ""
__author__ = "Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "21-FEB-2014"

# Global variables

# Path and URL definitions
JSOC_MAINURL = "http://jsoc.stanford.edu"
JSOC2_MAINURL = "http://jsoc2.stanford.edu"
JSOC_URL = "http://jsoc.stanford.edu/cgi-bin/ajax/"
JSOC2_URL = "http://jsoc2.stanford.edu/cgi-bin/ajax/"
CURRENT_DIR = os.getcwd()

# Time
TODAY = datetime.today()
INPUT_TIMEFORMAT = "%Y-%m-%dT%H:%M:%S"
JSOC_TIMEFORMAT = '%Y.%m.%d_%H:%M:%S'

# Default input arguments
# Current date and time
NEAR_DATE = TODAY.strftime(INPUT_TIMEFORMAT)
# Max span duration in sec.
SPAN_DURATION = 3600
# Retrieving method
METHOD = "url"
#Time out in sec.
TIMEOUT = 120
# OUTPUT JSOC SERVER RESPONSE FORMAT
FORMAT = "json"
# Protocol
PROTOCOL = "fits"
# Time to wait in seconds before sending a exp_status request
WAIT = 10

class jsoc():

    def __init__(self, dataseries, realtime=False, near_date=NEAR_DATE,
                 starttime=None, endtime=None,
                 cadence=None, span_duration=None,
                 verbose=False,notify=None):

        self.ds = dataseries
        self.realtime = realtime
        self.tr = ""
        self.near_date = near_date
        self.starttime = starttime
        self.endtime = endtime
        self.cadence = cadence
        self.span_duration = span_duration
        self.fetch_resp = None
        self.status_resp = None
        self.requestid = None
        self.url = ""
        self.verbose = verbose
        self.notify = notify

        if (starttime is not None) and (endtime is not None):
            tstart = starttime.strftime(JSOC_TIMEFORMAT)
            tend = endtime.strftime(JSOC_TIMEFORMAT)
            if (tstart == tend):
                self.tr += "[%s_TAI" % (tstart)
            else:
                self.tr += "[%s-%s" % (tstart, tend)
        elif (starttime is not None) and (endtime is None):
            tstart = starttime.strftime(JSOC_TIMEFORMAT)  
            if (span_duration is None): self.span_duration = SPAN_DURATION
            self.tr += "[%s/%i" % (tstart, span_duration) 
        elif (starttime is None) and (endtime is not None):
            if (span_duration is None): self.span_duration = SPAN_DURATION
            tend = (endtime - timedelta(seconds=span_duration)).strftime(JSOC_TIMEFORMAT)     
            self.tr += "[%s/%i" % (tend, span_duration)        
        else:
            ndate = near_date.strftime(JSOC_TIMEFORMAT)
            self.tr += "[%s" % (ndate)
            if (span_duration is not None):
                self.tr += "/%is" % (span_duration)
        if (cadence is not None):
            self.tr += "@%is" % (cadence)
        if (self.tr.startswith("[")): self.tr += "]"

    def parse_json(self, resp):
        try:
            json_object = json.loads(resp)
        except ValueError as e:
            if (self.verbose): print "Error %s %s" % (e, resp)
            return None
        return json_object


    def build_show_info(self, key=None):

        if self.realtime:
            url = JSOC2_URL + "show_info?ds=%s" % (self.ds)
        else:
            url = JSOC_URL + "show_info?ds=%s" % (self.ds)
        if (len(self.tr) >= 0):
            url += self.tr
        if (key is not None):
            url += "&key=%s" % ("%2C".join(key)) 

        self.url = url
        return url


    def show_info(self, key=None, output_dir=None):
        url = self.build_show_info(key=key)

        get_stream = False
        if (output_dir is None): 
            get_stream = True
        if (self.verbose): print "Fetching %s" % (url)
        if self.realtime:
            target = download_file(url, target_directory=output_dir,
                               get_stream=get_stream, user='hmiteam', passwd='hmiteam')
        else:
            target = download_file(url, target_directory=output_dir,
                               get_stream=get_stream)
        return target


    def build_fetch(self, operation,
                    protocol=None, method=None,
                    requestid=None, format=None):

        if self.realtime:
            url = JSOC2_URL + "jsoc_fetch?op=%s" % (operation)
        else:
            url = JSOC_URL + "jsoc_fetch?op=%s" % (operation)


        if (operation == "exp_status") and (requestid is not None):
            url += "&requestid=%s" % (requestid)
        else:
            url += "&ds=%s" % (self.ds)
            if (len(self.tr) >= 0): url += self.tr

        if (method is not None): url += "&method=%s" % (method)
        if (protocol is not None): url += "&protocol=%s" % (protocol)
        if (format is not None): url += "&format=%s" % (format)
        url += "&notify=%s" % (self.notify)
        self.url = url
        return url


    def fetch(self, operation,
              protocol=None, method=None,
              requestid=None, format=None):

        url = self.build_fetch(operation,
                               protocol=protocol,
                               method=method,
                               requestid=requestid,
                               format=format)
        print "Fetching %s" % (url)
        if self.realtime:
            resp = download_file(url, get_stream=True, user='hmiteam', passwd='hmiteam')
        else:
            resp = download_file(url, get_stream=True)
        if not (resp.startswith("{")):
            print "Empty jsoc_fetch response!"
            print "Query was: %s" % (url)
            return None
        else:
            fetch_resp = self.parse_json(resp)
           
        self.fetch_resp = fetch_resp
        return fetch_resp

    def get_fits(self, output_dir=CURRENT_DIR, timeout=TIMEOUT, wait=WAIT):

        res = ''
        fetch_resp = self.fetch("exp_request", protocol=PROTOCOL, method=METHOD)
        if (fetch_resp is None): sys.exit(0)
        if (fetch_resp['status'] == 0):
            #downloading file from info given in the response
            data = fetch_resp['data'][0]
            filename = data['record']
            filename = filename.replace('][2]{', '.')
            filename = filename.replace('[', '.')
            filename = filename.replace('}', '')
#            filename = filename.replace(':', '_')
            filename = filename+'.fits'
            if self.realtime:
                download_url = 'http://jsoc2.stanford.edu'+data['filename']
                res = download_file(download_url, target_directory=output_dir, filename=filename, user='hmiteam', passwd='hmiteam')
            else:
                download_url = 'http://jsoc.stanford.edu'+data['filename']
                res = download_file(download_url, target_directory=output_dir, filename=filename)

            if (self.verbose): print "Downloading %s to %s ..." % (download_url, output_dir+filename)

        else:      
            try:
                requestid = fetch_resp['requestid']
            except KeyError:
                print "Error: no JSOC request ID: %s" % (self.fetch_resp)
                return ''
            
            t0 = time.time();
            remaining_sec = timeout - int(time.time() - t0)
            time.sleep(3)
            while (remaining_sec >= 0):                
                fetch_resp = self.fetch("exp_status", requestid=requestid, format=FORMAT)
                if (self.verbose): print "%s    (remaining time: %i sec.)" % (self.fetch_resp, remaining_sec)                
                if (fetch_resp is None): 
                    print "Fetching status error!"
                    res = ''
                    break
                try:
                    status = int(fetch_resp['status'])
                except KeyError:
                    print "Error: no status in response: %s" % (self.fetch_resp)
                    res = ''
                    break
                if (status == 0):
                    try:
                        size = int(fetch_resp['size'])
                    except KeyError:
                        print "Error: no size in response: %s" % (self.fetch_resp)
                        res = ''
                        break 
                    if (size > 0):                    
                        data = fetch_resp['data'][0]
                        filename = data['record']
                        filename = filename.replace('][2]', '')
                        filename = filename.replace('[', '.')
                        tmp = data['filename'].split('.')
                        filename = filename+'.'+tmp[3]+'.fits'
                        if self.realtime:
                            download_url = 'http://jsoc2.stanford.edu'+fetch_resp['dir']+'/'+data['filename']
                            res = download_file(download_url, target_directory=output_dir, filename=filename, user='hmiteam', passwd='hmiteam')
                        else:
                            download_url = 'http://jsoc.stanford.edu'+fetch_resp['dir']+'/'+data['filename']
                            res = download_file(download_url, target_directory=output_dir, filename=filename)
                        if (self.verbose): print "Downloading %s to %s ..." % (download_url, output_dir+filename)

                    else:
                        res = ''
                    break
                else:
                    print "Status: %i for %s" % (status, requestid)
                time.sleep(WAIT)
                remaining_sec = remaining_sec = timeout - int(time.time() - t0)
            return res

# python jsoclib.py hmi.Ic_45s_nrt -nrt -s 2020-09-06T00:00:01 -e 2020-09-06T06:00:00 -c 7200  -V -S
if (__name__ == "__main__"):
    parser = argparse.ArgumentParser(description="Script to query the JSOC AJAX server.",
                                     add_help=True, conflict_handler='resolve')
    parser.add_argument('dataseries', nargs=1, help="JSOC dataseries")
    parser.add_argument('-nrt', '--realtime', nargs='?', help="Use real time server jsoc2")
    parser.add_argument('-n', '--near_date', nargs='?', 
                        default=NEAR_DATE, help="Date and time")
    parser.add_argument('-s', '--starttime', nargs='?', 
                        default=None, help="Start date and time")
    parser.add_argument('-e', '--endtime', nargs='?', 
                        default=None, help="End date and time")
    parser.add_argument('-c', '--cadence', nargs='?', default=None,
                        type=int, help="Cadence is seconds")
    parser.add_argument('-d', '--span_duration', nargs='?', type=int, 
                        default=None, help="Span duration in seconds")
    parser.add_argument('-o', '--output_dir', nargs='?',
                        default=None, help="Target directory for downloaded files.")
    parser.add_argument('-S', '--SHOW_INFO', action='store_true',
                        help="Perform show_info request for dataseries")
    parser.add_argument('-V', '--VERBOSE', action='store_true',
                        help="Verbose mode")
    parser.add_argument('-n', '--notify', nargs='?', 
                        default=None, help="Email to notify")

    args = parser.parse_args()
    ds = args.dataseries[0]
    realtime = args.realtime
    near_date = datetime.strptime(args.near_date, INPUT_TIMEFORMAT)
    starttime = args.starttime
    endtime = args.endtime
    cadence = args.cadence
    span_duration = args.span_duration
    output_dir = args.output_dir
    show_info = args.SHOW_INFO
    verbose = args.VERBOSE
    notify = args.notify

    if (starttime is not None): starttime = datetime.strptime(starttime, INPUT_TIMEFORMAT)
    if (endtime is not None): endtime = datetime.strptime(endtime, INPUT_TIMEFORMAT)


    jsoc = jsoc(ds, realtime=True, near_date=near_date, starttime=starttime,
                endtime=endtime, cadence=cadence,
                span_duration=span_duration,
                verbose=verbose, notify='christian.renie@obspm.fr')

    if (args.SHOW_INFO):
        info = jsoc.show_info(key=["T_REC_index", "T_REC"])
        ic_index=[] ; ic_dates=[]
        for row in info.split("\n")[1:-1]:
            if (row):
                rs = row.split()
                ic_index.append(rs[0])
                ic_dates.append(datetime.strptime(rs[1],'%Y.%m.%d_%H:%M:%S'+"_TAI"))
        print ic_index, ic_dates
    else:
        target=jsoc.get_fits(output_dir='.')
        if (target):
            print "%s downloaded" % target
        else:
            print "Error downloading %s" % target

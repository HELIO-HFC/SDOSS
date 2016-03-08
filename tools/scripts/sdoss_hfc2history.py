#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Script to retrieve from HFC the list of processed SDOSS data.
URL of the processed data are returned in a ascii file, which can
be used as an input history file for the SDOSS-HFC wrapper software.
@author: X.Bonnin (LESIA, CNRS)
"""

import os
import sys
import argparse
import time
from datetime import datetime

# Import sdoss hfc global variables
try:
    import stiltslib
except:
    sys.exit ("Import failed in module sdoss_hfc2history :\n\tstiltslib module is required!")

__version__ = "1.0"
#__license__ = ""
__author__ ="Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__="xavier.bonnin@obspm.fr"
__date__="21-FEB-2014"

SERVER_URL="voparis-helio.obspm.fr"
SERVER_PORT=8080
DB_HOST="helio-fc1.obspm.fr"
DB_PORT=3306
SCHEMA="hfc1test"
USER="guest"
PASSWORD="guest"

TODAY=datetime.today()
CPT_TIMEFORMAT="%Y%m%dT%H%M%S"

HISTORY_FILE ="sdoss_%s_%s.history" % ("@".join([SCHEMA,DB_HOST]),TODAY.strftime(CPT_TIMEFORMAT))

def sdoss_hfc2history(schema,host,server,
                      user=USER,password=PASSWORD,port=SERVER_PORT,
                      output_filename=HISTORY_FILE,verbose=True):

    hfc = stiltslib.connect(schema,host,server,
                            server_port=port,
                            user=user,passwd=passwd)

    query = "SELECT DISTINCT URL FROM VIEW_SP_HQI WHERE (CODE=\"SDOSS\")"
    resp = hfc.query(query, ofmt='csv',VERBOSE=verbose)
    resp = resp.split("\n")[2:-3]
    if (resp):
        if (verbose): print "%i row(s) returned" % len(resp)
        fw=open(output_filename,'w')
        for row in resp: fw.write(row[1:-1]+"\n")
        fw.close()
        if (verbose): print "%s saved" % output_filename
    else:
        if (verbose): print "Empty set."


if (__name__ == "__main__"):

    parser = argparse.ArgumentParser(add_help=True,conflict_handler='resolve',
                                    description="script to create a sdoss history file containing" \
                                        +"the hmi urls of data files processed in the HFC.")
    parser.add_argument("schema",nargs=1,help="Schema name of the HFC database to query.")
    parser.add_argument("-h","--host",nargs='?',default=DB_HOST,
                        help="Name of the database host [default="+DB_HOST+"].")
    parser.add_argument("-u","--user",nargs='?',default=USER,
                        help="Name of the user account [default="+USER+"].")
    parser.add_argument("-p","--password",nargs='?',default=PASSWORD,
                        help="Password of the user account [default="+PASSWORD+"].")
    parser.add_argument("-o","--output_filename",nargs='?',default=HISTORY_FILE,
                        help="Name of the output file [default="+HISTORY_FILE+"].")
    parser.add_argument("-V","--Verbose",action='store_true',
                        help="verbose mode.")    
    args = parser.parse_args()
    db = args.schema[0]
    host = args.host
    user = args.user
    passwd = args.password
    outfile=args.output_filename
    verbose=args.Verbose

    sdoss_hfc2history(db,host,SERVER_URL,user=user,password=passwd,
                      output_filename=outfile,verbose=verbose)

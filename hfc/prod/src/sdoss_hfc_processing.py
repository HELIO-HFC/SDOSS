#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Wrapper to run the sdoss recognition code in the HFC framework.
@author: X.Bonnin (LESIA, CNRS)
"""

import os
import sys
import threading
import subprocess
import urllib2
import argparse
from datetime import datetime, timedelta
import time

try:
    from MyToolkit import setup_logging, download_file
except:
    sys.exit("Import failed in module sdoss_hfc_processing :\
              \n\tMyToolkit module is required!")

try:
    from jsoclib import jsoc
except:
    sys.exit("Import failed in module sdoss_hfc_processing :\
              \n\tjsoclib module is required!")


# Import sdoss hfc global variables
try:
    from sdoss_hfc_globals import HOSTNAME, INPUT_TFORMAT, \
        TODAY, PJOBS, SDOSS_IDL_BIN, LOG, IDL_EXE_PATH, \
        STARTTIME, ENDTIME, CADENCE, HISTORY_FILE,\
        OUTPUT_DIRECTORY, DATA_DIRECTORY, JSOC_URL, VSO_URL, JSOC_TFORMAT
except:
    sys.exit("Import failed in module sdoss_hfc_processing :\
             \n\tsdoss_hfc_globals module is required!")

__version__ = "1.0"
#__license__ = ""
__author__ = "Xavier Bonnin (LESIA, CNRS)"
#__credit__=[""]
#__maintainer__=""
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "21-FEB-2014"

VERSION = __version__

LAUNCH_TIME = time.time()


def main():

    parser = argparse.ArgumentParser(description="Program to run sdoss code.",
                                     add_help=True, conflict_handler='resolve')
    parser.add_argument('config_file', nargs=1,
                        help="SDOSS HFC configuration file")
    parser.add_argument('-s', '--starttime', nargs='?',
                        default=STARTTIME,
                        help="start date and time [default=" +
                        STARTTIME + "]")
    parser.add_argument('-e', '--endtime', nargs='?',
                        default=ENDTIME,
                        help="end date and time [default=" +
                        ENDTIME + "]")
    parser.add_argument('-c', '--cadence', nargs='?',
                        default=CADENCE, type=int,
                        help="cadence of observations in seconds [default="
                        + str(CADENCE) + "]")
    parser.add_argument('-o', '--output_directory', nargs='?',
                        default=OUTPUT_DIRECTORY,
                        help="output directory [default="
                        + OUTPUT_DIRECTORY + "]")
    parser.add_argument('-d', '--data_directory', nargs='?',
                        default=DATA_DIRECTORY,
                        help="data directory [default="
                        + DATA_DIRECTORY + "]")
    parser.add_argument('-b', '--sdoss_idl_bin', nargs='?',
                        default=SDOSS_IDL_BIN,
                        help="sdoss idl binary file [default="
                        + SDOSS_IDL_BIN + "]")
    parser.add_argument('-j', '--pjobs', nargs='?',
                        default=PJOBS, type=int,
                        help="number of parallelized jobs [default="
                        + str(PJOBS) + "]")
    parser.add_argument('-h', '--history_file', nargs='?',
                        default=HISTORY_FILE,
                        help="path to the sdoss history file [default=" +
                        HISTORY_FILE + "]")
    parser.add_argument('-l', '--log_file', nargs='?',
                        default=None,
                        help="Log file.")
    parser.add_argument('-Q', '--Quicklook', action='store_true',
                        help="save quick-look images")
    parser.add_argument('-R', '--Remove_data', action='store_true',
                        help="remove data files after processing.")
    parser.add_argument('-V', '--Verbose', action='store_true',
                        help="verbose mode")

    Namespace = parser.parse_args()
    config_file = Namespace.config_file[0]
    starttime = datetime.strptime(Namespace.starttime, INPUT_TFORMAT)
    endtime = datetime.strptime(Namespace.endtime, INPUT_TFORMAT)
    cadence = Namespace.cadence
    output_directory = Namespace.output_directory
    sdoss_idl_bin = Namespace.sdoss_idl_bin
    data_directory = Namespace.data_directory
    pjobs = Namespace.pjobs
    history_file = Namespace.history_file
    log_file = Namespace.log_file
    quicklook = Namespace.Quicklook
    remove = Namespace.Remove_data
    verbose = Namespace.Verbose

    # Setup the logging
    setup_logging(filename=log_file, quiet=False, verbose=verbose)

    # Create a logger
    LOG.info("Starting sdoss_hfc_processing.py on %s (%s)",
             HOSTNAME, TODAY.strftime(INPUT_TFORMAT))

    if not (os.path.isfile(config_file)):
        LOG.error("Config file %s does not exist!", config_file)

    # Check SSW_ONTOLOGY environment variable existence
    if not ("SSW_ONTOLOGY" in os.environ):
        print "$SSW_ONTOLOGY environment variable must be defined!"
        sys.exit(1)

    # Get list of HMI Ic T_REC_index and T_REC
    # to process between starttime and endtime
    #ds = "hmi.ic_45s"
    #ic_index, ic_dates = query_jsoc(ds, starttime, endtime, cadence=cadence)
    ds = "hmi.Ic_45s_nrt"
    jsocLink = jsoc(ds, realtime=True, starttime=starttime,
                endtime=endtime, cadence=cadence,
                verbose=verbose, notify='christian.renie@obspm.fr')
    info = jsocLink.show_info(key=["T_REC_index", "T_REC"])
    ic_index=[] ; ic_dates=[]
    for row in info.split("\n")[1:-1]:
        if (row):
            rs = row.split()
            ic_index.append(rs[0])
            ic_dates.append(datetime.strptime(rs[1],JSOC_TFORMAT+"_TAI"))
    if (len(ic_index) == 0):
        LOG.warning("Empty hmi file set!")
        sys.exit(1)
    else:
        LOG.info("%i record(s) returned.", len(ic_index))

    # If not full cadence, extract images every cadence seconds.
    if (cadence > 45):
        LOG.info("Process a set of files every %i sec.", cadence)
    #     # Generage dates vector
    #     dateList = [starttime]
    #     while (max(dateList) < endtime):
    #         dateList.append(max(dateList) + timedelta(seconds=cadence))
    #     ic_indices = find_closest(ic_dates,dateList,dt_max=45.0)

    #     new_ic_dates = [] ; new_ic_index = []
    #     for i,current_ind in enumerate(ic_indices):
    #         if (current_ind == -1): continue
    #         new_ic_dates.append(ic_dates[current_ind])
    #         new_ic_index.append(ic_index[current_ind])
    #     ic_dates = list(new_ic_dates) ; ic_index = list(new_ic_index)
    #     del new_ic_dates ; del new_ic_index

    nfile = len(ic_index)
    if (nfile == 0):
        LOG.warning("Empty data set!")
        sys.exit(0)

    #LOG.info("%i hmi [Ic,M] fileset(s) to process.",nfile)

    # Generate the vso url of hmi files
    ds = "hmi__Ic_45s"
    ic_url = get_vso_url(ds, ic_index)
    ds = "hmi__M_45s"
    m_url = get_vso_url(ds, ic_index)

    # Check if data files have been already processed or not from history file.
    # If they are, remove them from the list.
    if (os.path.isfile(history_file)):
        iprocessed = check_history(history_file, ic_url)
        ic_url_tmp = list(ic_url)
        ic_dates_tmp = list(ic_dates)
        for i, current_url in enumerate(ic_url_tmp):
            if (i in iprocessed):
                LOG.info("fileid: %s - date/time: %s already processed.",
                         current_url, str(ic_dates_tmp[i]))
                j = ic_url.index(current_url)
                ic_url.pop(j)
                m_url.pop(j)
                ic_dates.pop(j)
            else:
                LOG.info("fileid: %s - date/time: %s not processed.",
                         current_url, str(ic_dates_tmp[i]))
        del ic_url_tmp
        del ic_dates_tmp

    #Initialize sdoss jobs for the unprocessed files
    sdoss_jobs = []
    for i, current_url in enumerate(ic_url):
        #LOG.info("Initializing job [#%i] for date/time %s", i, str(ic_dates[i]))
        sdoss_jobs.append(run_sdoss(
                          i + 1, [current_url, m_url[i]],
                          config_file,
                          date_obs=[ic_dates[i], ic_dates[i]],
                          output_directory=output_directory,
                          data_directory=data_directory,
                          sdoss_idl_bin=sdoss_idl_bin,
                          quicklook=quicklook,
                          remove_data=remove,
                          verbose=verbose))

    njobs = len(sdoss_jobs)
    if (njobs == 0):
        LOG.warning("Empty processing list!")
        sys.exit(1)

    # Run sdoss processings
    LOG.info("%i sdoss job(s) to run...", njobs)
    running = []
    npending = njobs
    for current_job in sdoss_jobs:
        if (len(running) < pjobs):
            current_job.start()
            running.append(current_job)
            npending -= 1
            LOG.info("Job [#%i] has started. (%s)",
                     current_job.thread_id, str(datetime.today()))
            LOG.info("Current running/pending job(s): %i/%i",
                     len(running), npending)
            time.sleep(3)

        i = 0
        while(len(running) >= pjobs):
            if (running[i].terminated):
                if (running[i].success):
                    with (open(history_file, 'a')) as fw:
                        fw.write(running[i].fileid[0] + "\n")
                    LOG.info("Sdoss Job [#%i] has \
                             terminated correctly for date/time %s. (%s)",
                             running[i].thread_id, str(running[i].date_obs[0]),
                             str(datetime.today()))
                else:
                    LOG.error("Sdoss Job [#%i] has \
                              failed for date/time %s! (%s)",
                              running[i].thread_id, str(running[i].date_obs[0]),
                              str(datetime.today()))
                running.remove(running[i])
            i = (i + 1) % pjobs

    LOG.info("Running %i sdoss jobs...done", njobs)
    LOG.info("Total elapsed time: %f min.", (time.time() - LAUNCH_TIME) / 60.0)


def total_sec(td):

    """
    Module used in Python 2.6 to compute
    datetime.total_seconds() module operation.
    """
    return (td.microseconds +
            (td.seconds + td.days * 24 * 3600) * 10 ** 6) / 10 ** 6


def query_jsoc(ds, starttime, endtime, cadence=None):

    """Module to get the list of hmi files indexes from JSOC"""

    LOG.info("Retrieving " + ds + " data list from jsoc server between " +
             starttime.strftime(INPUT_TFORMAT) + " and " +
             endtime.strftime(INPUT_TFORMAT) + " ...")

    # Define starttime and endtime (in jsoc cgi time format)
    stime = starttime - timedelta(seconds=20)  #starttime - 20 sec.
    etime = endtime + timedelta(seconds=20)  #endtime + 20 sec.
    stime = stime.strftime(JSOC_TFORMAT)
    etime = etime.strftime(JSOC_TFORMAT)

    # Load date set information from jsoc


    # Build url
    url = JSOC_URL + "?ds=" + ds + "[" + stime + "-" + etime
    if (cadence is not None): url += "@%is" % (cadence)
    url+="]&key=T_REC_index%2CT_REC"
    LOG.info("Reaching --> "+url)
    # Get T_REC_index and T_REC list
    f = urllib2.urlopen(url)

    T_REC_index=[] ; T_REC=[]
    for row in f.read().split("\n")[1:-1]:
        if (row):
            rs = row.split()
            T_REC_index.append(rs[0])
            T_REC.append(datetime.strptime(rs[1],JSOC_TFORMAT+"_TAI"))

    return T_REC_index, T_REC

# Module to find in a first list of dates, the ones that are
# closest to the dates provided in a second reference list.
# Module returns the subscripts of closest dates of the first list.
def find_closest(input_datetime,ref_datetime,dt_max=-1):

    if (len(input_datetime) == 0) or \
        (len(ref_datetime) == 0):
        return []

    subscripts = []
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

    #url = VSO_URL + "/cgi-bin/drms_test/drms_export.cgi?series="+ds
    url = VSO_URL + "/cgi-bin/netdrms/drms_export.cgi?series="+ds
    if (rice): url+=";compress=rice"

    urlList=[]
    for current_index in t_rec_index:
        record = str(current_index)+"-"+str(current_index)
        current_url = url+";record="+record
        urlList.append(current_url)

    return urlList

def check_history(history_file,urlList):

    if not (os.path.isfile(history_file)):
        LOG.warning("history file "+history_file+" does not exist!")
        return []

    # Read checklist file
    fr = open(history_file,'r')
    fileList = fr.read().split("\n")
    fr.close()

    indices = []
    for i,current_url in enumerate(urlList):
        if (current_url in fileList):
            indices.append(i)

    return indices


# Class to run sdoss (using threading class functionality)
class run_sdoss(threading.Thread):

    def __init__(self,thread_id,fileset,config_file,
                date_obs=[None,None],
                data_directory=DATA_DIRECTORY,
                output_directory=OUTPUT_DIRECTORY,
                quicklook=True,
                remove_data=False,
                verbose=False,
                idl_exe_path=IDL_EXE_PATH,
                sdoss_idl_bin=SDOSS_IDL_BIN):

        threading.Thread.__init__(self)
        self.terminated =False
        self.success=False
        self._stopevent = threading.Event()

        self.thread_id = thread_id
        self.fileset = fileset
        self.fileid = ["",""]
        self.date_obs = date_obs
        self.config_file = config_file
        self.data_directory = data_directory
        self.output_directory = output_directory
        self.quicklook = quicklook
        self.remove_data = remove_data
        self.verbose = verbose

        self.idl_exe_path=idl_exe_path
        self.sdoss_idl_bin=sdoss_idl_bin


    def end(self):
        self.terminated = True
        if (self.remove_data):
            if (os.path.isfile(self.fileset[0])):
                os.remove(self.fileset[0])
                LOG.info(self.fileset[0]+" deleted.")
            if (os.path.isfile(self.fileset[1])):
                os.remove(self.fileset[1])
                LOG.info(self.fileset[1]+" deleted.")


    def stop(self):
        self._stopevent.set()


    def setTerminated(self,terminated):
        self.terminated = terminated


    def run(self):

#        if not (os.path.exists(self.idl_exe_path)):
#            LOG.error("Given path of the IDL executable (%s) does not exist!",self.idl_exe_path)
#            self.end()
#            return False

        if not (os.path.exists(self.sdoss_idl_bin)):
            LOG.error("%s does not exist!",self.sdoss_idl_bin)
            self.end()
            return False

        if (len(self.fileset) != 2):
            log.error("Input fileset must have two elements!")
            self.end()
            return False

        #If input files are urls then download data files.
        if (self.fileset[0].startswith("http:")) or \
            (self.fileset[0].startswith("ftp:")):
            ic_url = self.fileset[0]
            self.fileid[0] = ic_url
            #try to download from jsoc
            LOG.info("Job[#%i] downloading ic_file from JSOC  %s", self.thread_id, self.date_obs[0])
#            j_soc = jsoc("hmi.ic_45s", starttime=self.date_obs[0], endtime=self.date_obs[0], verbose=True, notify='christian.renie@obspm.fr')
            j_soc = jsoc("hmi.Ic_45s_nrt", realtime=True, starttime=self.date_obs[0], endtime=self.date_obs[0], verbose=True, notify='christian.renie@obspm.fr')
            ic_file=j_soc.get_fits(output_dir=self.data_directory)
            if (ic_file):
                LOG.info("Job[#%i]: %s downloaded from JSOC.", self.thread_id, ic_file)
                self.fileset[0] = ic_file
            else:
                LOG.info("Job[#%i]: Downloading from VSO for %s %s...", self.thread_id, self.date_obs[0], ic_url)
                ic_file = download_file(ic_url,
                                    target_directory=self.data_directory,
                                            timeout=60,wait=30,quiet=False)
                if (ic_file):
                    LOG.info("Job[#%i]: %s downloaded from VSO.", self.thread_id, ic_file)
                    self.fileset[0] = ic_file
        else:
            ic_url = None
            ic_file = self.fileset[0]
            self.fileid[0] = ic_file
        if not (os.path.isfile(ic_file)):
            LOG.error("Job[#%i]: ic_file %s does not exist!", self.thread_id, ic_file)
            self.end()
            return False

        if (self.fileset[1].startswith("http:")) or \
            (self.fileset[1].startswith("ftp:")):
            m_url = self.fileset[1]
            self.fileid[1] = m_url
            #try to download from jsoc
            LOG.info("Job[#%i] downloading m_file from JSOC  %s", self.thread_id, self.date_obs[0])
#            j_soc = jsoc("hmi.m_45s", starttime=self.date_obs[0], endtime=self.date_obs[0], verbose=True, notify='christian.renie@obspm.fr')
            j_soc = jsoc("hmi.M_45s_nrt", realtime=True, starttime=self.date_obs[0], endtime=self.date_obs[0], verbose=True, notify='christian.renie@obspm.fr')
            m_file=j_soc.get_fits(output_dir=self.data_directory)
            if (m_file):
                LOG.info("Job[#%i]: %s downloaded from JSOC.", self.thread_id, m_file)
                self.fileset[1] = m_file
            else:
                LOG.info("Job[#%i]: Downloading from VSO for %s %s...", self.thread_id, self.date_obs[0], m_url)
                m_file = download_file(m_url,
                         target_directory=self.data_directory,
                                     timeout=60,wait=30,quiet=False)
                if (m_file):
                    LOG.info("Job[#%i]: %s downloaded from VSO.", self.thread_id, m_file)
                    self.fileset[1] = m_file
        else:
            m_url = None
            m_file = self.fileList[1]
            self.fileid[1] = m_file
        if not (os.path.isfile(m_file)):
            LOG.error("Job[#%i]: m_file %s does not exist!", self.thread_id, m_file)
            self.end()
            return False

        idl_args = [self.config_file,
                    ic_file,m_file,
                    "data_dir="+self.data_directory,
                    "output_dir="+self.output_directory]
        if (ic_url is not None): idl_args.append("fnc_url="+ic_url)
        if (m_url is not None): idl_args.append("fnm_url="+m_url)
        if (self.quicklook): idl_args.append("/QUICKLOOK")
        if (self.verbose): idl_args.append("/VERBOSE")

        #build idl command line
        idl_cmd = [self.idl_exe_path]+["-quiet","-rt="+self.sdoss_idl_bin,"-args"]
        #idl_cmd = [self.idl_exe_path]+["-rt="+self.sdoss_idl_bin,"-args"]
        idl_cmd.extend(idl_args)
        try:
            LOG.info("Executing --> "+ " ".join(idl_cmd))
            idl_process = subprocess.Popen(idl_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            output, errors = idl_process.communicate()
            if idl_process.wait() == 0:
                #LOG.info("Sucessfully ran idl command %s, output: %s, errors: %s",
                #       ' '.join(idl_cmd), str(output), str(errors))
                if (len(errors) == 0): self.success=True
            else:
                LOG.error("Error running idl command %s, output: %s, errors: %s",
                       ' '.join(idl_cmd), str(output), str(errors))
        except OSError as e:
            LOG.error(str(e))
        self.end()
        time.sleep(3)


if (__name__ == "__main__"):
    main()

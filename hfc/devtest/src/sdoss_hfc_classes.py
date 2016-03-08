#!/usr/bin/env python
# -*- coding: ASCII -*-

"""
Module containing classes for sdoss_hfc_processing.py script.
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
import threading
import logging

# Import sdoss hfc global variables
try:
    from sdoss_hfc_globals import *
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tsdoss_hfc_globals module is required!")

# Import sdoss hfc methods variables
try:
    from sdoss_hfc_methods import *
except:
    sys.exit ("Import failed in module sdoss_hfc_processing :\n\tsdoss_hfc_methods module is required!")

LOG=logging.getLogger(LOGGER)


class sdoss_job:

    """A sdoss job class"""

    def __init__(self,setid,
                files=["",""],
                urls=["",""],
                dates=[None,None],
                index=[None,None]):
        self.setid=setid
        self.files=files
        self.urls=urls
        self.dates=dates
        self.index=index


class run_sdoss(threading.Thread):

    """Class to run a sdoss job"""

    def __init__(self,sdoss_job,config_file,
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
    
        self.job = sdoss_job
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
            if (os.path.isfile(self.job.files[0])): 
                os.remove(self.job.files[0])
                LOG.info(self.job.files[0]+" deleted.")
            if (os.path.isfile(self.job.files[1])): 
                os.remove(self.job.files[1])
                LOG.info(self.job.files[1]+" deleted.")


    def stop(self):
        self._stopevent.set()
    

    def setTerminated(self,terminated):
        self.terminated = terminated

                 
    def run(self):
        
        self.rtime=time.time()

        if not (os.path.exists(self.idl_exe_path)):
            LOG.error("Given path of the IDL executable (%s) does not exist!",self.idl_exe_path)
            self.end()
            return False            

        if not (os.path.exists(self.sdoss_idl_bin)):
            LOG.error("%s does not exist!",self.sdoss_idl_bin)
            self.end()
            return False            
        
        if (len(self.job.files) != 2):
            log.error("Input job.files attribute must have two elements!")
            self.end()
            return False

        #If input files are urls then download data files.
        if (self.job.files[0].startswith("http:")) or \
            (self.fileset[0].startswith("ftp:")):
            ic_url = self.fileset[0]
            self.fileid[0] = ic_url
            LOG.info("Downloading %s...",ic_url)
            ic_file = download_file(ic_url,
                            target_directory=self.data_directory,
                            wait=30,quiet=True)
            if (ic_file): 
                LOG.info(ic_file+" downloaded.")
                self.fileset[0] = ic_file
        else:
            ic_url = None
            ic_file = self.fileset[0]
            self.fileid[0] = ic_file
        if not (os.path.isfile(ic_file)):
            LOG.error(ic_file+" does not exist!")
            self.end()
            return False

        if (self.fileset[1].startswith("http:")) or \
            (self.fileset[1].startswith("ftp:")):
            m_url = self.fileset[1]
            self.fileid[1] = m_url
            LOG.info("Downloading %s...",m_url)
            m_file = download_file(m_url,
                         target_directory=self.data_directory,
                         wait=30,quiet=True)
            if (m_file): 
                LOG.info(m_file+" downloaded.")
                self.fileset[1] = m_file
        else:
            m_url = None
            m_file = self.fileList[1]
            self.fileid[1] = m_file
        if not (os.path.isfile(m_file)):
            LOG.error(m_file+" does not exist!")
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
        idl_cmd.extend(idl_args)
        
        LOG.info("Executing --> "+ " ".join(idl_cmd))
        idl_process = subprocess.Popen(idl_cmd, 
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
        output, errors = idl_process.communicate()
        if idl_process.wait() == 0:
            #LOG.info("Sucessfully ran idl command %s, output: %s, errors: %s",
            #       ' '.join(idl_cmd), str(output), str(errors))
            if (len(errors) == 0): self.success=True
        else:
            LOG.error("Error running idl command %s, output: %s, errors: %s",
                   ' '.join(idl_cmd), str(output), str(errors))

        self.end()
        time.sleep(3)

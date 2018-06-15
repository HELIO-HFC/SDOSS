#! /usr/bin/env python
# -*- coding: ASCII -*-

"""
Module to launch Sunspots tracking on SDO/HMI images for the HFC.
"""

import os
import sys
from datetime import datetime, timedelta
import shutil
import argparse
import ftplib
import glob
import numpy as np

# Import MyToolkit methods
try:
    from MyToolkit import indices, setup_logging, \
        read_csv, write_csv, download_file
except:
    sys.exit("Import failed in module sdoss_hfc_traking :\
              \n\tMyToolkit module is required!")

# Import sdoss hfc global variables
try:
    from sdoss_hfc_globals import FTP_URL, \
        INPUT_TFORMAT, STARTTIME, ENDTIME, LOG, \
        CURRENT_PATH, TRACKFIELDS, FILE_TFORMAT, \
        TODAY, HOSTNAME
except:
    sys.exit("Import failed in module sdoss_hfc_tracking : \
              \n\tsdoss_hfc_globals module is required!")

# Import sdoss hfc global variables
try:
    from sdoss_tracking import tracking
except:
    sys.exit("Import failed in module sdoss_hfc_tracking :\
              \n\tsdoss_tracking module is required!")


__version__ = "1.1"
#__license__ = ""
__author__ = "Xavier Bonnin"
#__credit__=[""]
#__maintainer__=""
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "19-JUL-2013"


def parse_configfile(configfile):

    """
    Read sdoss tracking configuration file.
    """

    if not (os.path.isfile(configfile)):
        LOG.error("%s does not exist!", configfile)
        return None

    args = dict()
    try:
        with open(configfile) as f:
            for line in f:
                param = line.strip()
                if (param) and (param[0] != '#'):
                    params = param.split('=', 1)
                    if len(params) > 1:
                        args[params[0].strip()] = params[1].strip()
                    else:
                        args[params[0].strip()] = None
    except IOError, why:
        LOG.error("Error parsing configuration file "
                  + str(configfile) + ": " + str(why))
        return None

    return args


def extract_date(filename):
    date = os.path.basename(filename).split("_")[2]
    return datetime.strptime(date, FILE_TFORMAT)


def get_date_obs(filename):
    init_file = filename.split("_feat.csv")[0] + "_init.csv"
    init_data = read_csv(init_file, quiet=True)
    if (init_data is None):
        LOG.error("Cannot read %s!", init_data)
        sys.exit(1)
    date_obs = init_data[0]['DATE_OBS']
    return datetime.strptime(date_obs, INPUT_TFORMAT)


def get_filelist(starttime, endtime,
                 data_directory=FTP_URL):

    """
    Returns the list of sdoss feat csv files
    for a given time range.
    """

    dsec = timedelta(seconds=6)

    LOG.info("Building fileset from %s...", data_directory)
    if (data_directory.startswith("ftp")):
        ftp_server = data_directory.split("/")[2]

        # Years to cover
        startyear = starttime.year
        endyear = endtime.year
        nyear = endyear - startyear + 1
        yearList = [i + startyear for i in range(nyear)]

        filelist = []
        for current_year in yearList:
            ftp_dir = "/".join(data_directory.split("/")[3:])
            ftp_dir += "/" + str(current_year)
            current_url = "ftp://" + ftp_server + "/" + ftp_dir
            try:
                ftp = ftplib.FTP(ftp_server)
                ftp.login()
                ftp.cwd(ftp_dir)
            except:
                LOG.warning("Can not reach %s!", current_url)
                continue
            else:
                current_filelist = []
                ftp.retrlines('LIST', current_filelist.append)
                ftp.quit()
                for current_file in current_filelist:
                    current_file = current_file.split()[-1]
                    if (current_file.endswith("_feat.csv")):
                        current_path = current_url + "/" + current_file
                        current_date = extract_date(current_path)
                        if (current_date < (starttime - dsec)):
                            continue
                        if (current_date > (endtime + dsec)):
                            continue
                        if (filelist.count(current_path) == 0):
                            filelist.append(current_path)
                            LOG.info("%s added", current_path)
    else:
        filelist = glob.glob(os.path.join(data_directory, "sdoss_*_feat.csv"))

    if (len(filelist) == 0):
        LOG.warning("Empty file list!")
        return []

    return filelist


def read_fileset(fileset):

    """
    Extract required data from the sdoss fileset.
    """

    feat_data = {
        'DATE_OBS': [],
        'FEAT_HG_LONG_DEG': [],
        'FEAT_HG_LAT_DEG': [],
        'FEAT_X_PIX': [],
        'FEAT_Y_PIX': [],
        'FEAT_AREA_DEG2': [],
        'FEAT_FILENAME': []}
    for current_file in fileset:
        current_date = get_date_obs(current_file)
        current_data = read_csv(current_file)
        if (len(current_data) == 0):
            LOG.error("Empty file: %s!", current_file)
            return None
        for cd in current_data:
            feat_data['DATE_OBS'].append(current_date)
            feat_data['FEAT_HG_LONG_DEG'].append(float(cd['FEAT_HG_LONG_DEG']))
            feat_data['FEAT_HG_LAT_DEG'].append(float(cd['FEAT_HG_LAT_DEG']))
            feat_data['FEAT_X_PIX'].append(int(cd['FEAT_X_PIX']))
            feat_data['FEAT_Y_PIX'].append(int(cd['FEAT_Y_PIX']))
            feat_data['FEAT_AREA_DEG2'].append(float(cd['FEAT_AREA_DEG2']))
            feat_data['FEAT_FILENAME'].append(current_file)

    return feat_data


def get_trackfile(fileset, target_directory):

    """
    Copy track files corresponding to the given
    fileset into the target directory.
    """

    LOG.info("Building list of previous track files...")

    if not (os.path.isdir(target_directory)):
        LOG.error("%s does not exist!", target_directory)
        return []

    trackset = []
    for current_file in fileset:
        current_track = current_file.split("_feat.csv")[0] + "_track.csv"
        if ((current_track.startswith("ftp")) or
                (current_track.startwidth("http"))):
            target = download_file(
                current_track,
                target_directory=target_directory,
                tries=1, wait=0, quiet=False)
            if (os.path.isfile(target)):
                trackset.append(target)
        else:
            if (os.path.isfile(current_track)):
                if (target_directory != os.path.dirname(current_track)):
                    shutil.copy(current_track, target_directory)
                trackset.append(target)

    return trackset

def load_trackid(trackset, feat_data, max_track_id):

    """
    Load track ids from list of
    track files, updating if
    feature matching occurs.
    """

    tdset = []
    tid = []
    for current_file in trackset:
        current_data = read_csv(current_file, quiet=True)
        if (current_data is None):
            continue
        for td in current_data:
            tdset.append([datetime.strptime(td['DATE_OBS'], INPUT_TFORMAT),
                          int(td['FEAT_X_PIX']),
                          int(td['FEAT_Y_PIX'])])
            tid.append(np.int64(td['TRACK_ID']))
    if (len(tid) == 0):
        return []
    #max_tid = np.max(tid)
    max_tid = np.max([max_track_id, np.max(tid)])

    track_id = []
    count = 1
    for i, current_date in enumerate(feat_data['DATE_OBS']):
        current_set = [
            current_date,
            feat_data['FEAT_X_PIX'][i],
            feat_data['FEAT_Y_PIX'][i]]

        if (current_set in tdset):
            index = tdset.index(current_set)
            track_id.append(tid[index])
        else:
            track_id.append(max_tid + count)
            count += 1

    return track_id

if (__name__ == "__main__"):
    parser = argparse.ArgumentParser(description="sdoss tracking module",
                                     conflict_handler='resolve',
                                     add_help=True)
    parser.add_argument('config_file', nargs=1,
                        help="Pathname of the configuration file")
    parser.add_argument('-s', '--starttime', nargs='?',
                        default=STARTTIME,
                        help="First date and time to process")
    parser.add_argument('-e', '--endtime', nargs='?',
                        default=ENDTIME,
                        help="Last date and time to process")
    parser.add_argument('-d', '--data_directory', nargs='?',
                        default=FTP_URL,
                        help="Path of the directory containing sdoss files")
    parser.add_argument('-o', '--output_directory', nargs='?',
                        default=CURRENT_PATH,
                        help="Pathname of the directory \
                        where output files are saved")
    parser.add_argument('-l', '--log_file', nargs='?', default=None,
                        help='Pathname of the log file')
    parser.add_argument('-h', '--history_file', nargs='?',
                        default=None,
                        help="Pathname of the history file")
    parser.add_argument('-V', '--Verbose', action='store_true',
                        help="Talkative mode")
    parser.add_argument('-R', '--Restart', action='store_true',
                        help="Restart tracking id to 1")
    args = parser.parse_args()

    config_file = args.config_file[0]
    starttime = datetime.strptime(args.starttime, INPUT_TFORMAT)
    endtime = datetime.strptime(args.endtime, INPUT_TFORMAT)
    data_directory = args.data_directory
    output_directory = args.output_directory
    history_file = args.history_file
    log_file = args.log_file
    verbose = args.Verbose
    restart = args.Restart

    # Setup the logging
    setup_logging(filename=log_file, quiet=False, verbose=verbose)

    LOG.info("Starting sdoss_hfc_tracking.py on %s (%s)",
             HOSTNAME, TODAY.strftime(INPUT_TFORMAT))

    LOG.info("Parsing %s", config_file)
    param = parse_configfile(config_file)
    if (param is None):
        sys.exit(1)

    max_files = int(param['MAX_FILES'])
    dt_max = float(param['DT_MAX'])
    radius = float(param['RADIUS'])
    area_min = float(param['AREA_MIN'])

    LOG.info("MAX_FILES=%i loaded", max_files)
    LOG.info("DT_MAX=%f loaded", dt_max)
    LOG.info("RADIUS=%f loaded", radius)
    LOG.info("AREA_MIN=%f loaded", area_min)

    fileset = get_filelist(starttime, endtime,
                           data_directory=data_directory)
    
    nfile = len(fileset)
    LOG.info("%i files found", nfile)
    if (nfile == 0):
        sys.exit()

    # If they exist, make a copy of track files from previous run
    # into the output directory
    if not (restart):
        trackset = get_trackfile(fileset, output_directory)
    else:
        trackset = []        
    max_track_id = 0    
    if (len(trackset) == 0):
        LOG.warning("No previous track files read!")

    for i in range(nfile - max_files + 1):
        current_fileset = fileset[i:i + max_files]
        feat_data_i = read_fileset(current_fileset)

        current_trackset = [
            os.path.join(
                output_directory,
                os.path.basename(current_file).split("_feat.csv")[0]
                + "_track.csv")
            for current_file in current_fileset]

        prev_track_id = load_trackid(current_trackset, feat_data_i, max_track_id)

        LOG.info("Run tracking for fileset [%i]:", nfile - max_files - i + 1)
        LOG.info("[" + ", ".join(current_fileset) + "]")
        track_id, lvl_trust = tracking(
            feat_data_i['DATE_OBS'],
            feat_data_i['FEAT_X_PIX'],
            feat_data_i['FEAT_Y_PIX'],
            feat_data_i['FEAT_HG_LONG_DEG'],
            feat_data_i['FEAT_HG_LAT_DEG'],
            feat_data_i['FEAT_AREA_DEG2'],
            radius=radius, dt_max=dt_max,
            area_min=area_min, track_id=prev_track_id)
        LOG.info("track_id %s", track_id)
        # keep in memory the max of track_id numbers
        max_track_id = np.max([np.max(track_id), max_track_id])
        LOG.info("max_track_id %i", max_track_id)
        for j, current_file in enumerate(current_fileset):
            ind = indices(feat_data_i['FEAT_FILENAME'], current_file)
            output_data = []
            for k, ci in enumerate(ind):
                output_data.append({'ID_SUNSPOT': k + 1,
                                    'TRACK_ID': track_id[ci],
                                    'DATE_OBS':
                                    feat_data_i['DATE_OBS'][ci].strftime(
                                        INPUT_TFORMAT),
                                    'FEAT_X_PIX':
                                    feat_data_i['FEAT_X_PIX'][ci],
                                    'FEAT_Y_PIX':
                                    feat_data_i['FEAT_Y_PIX'][ci],
                                    'PHENOM': "", 'REF_FEAT': "",
                                    'LVL_TRUST': int(lvl_trust[ci]),
                                    'FEAT_FILENAME': current_file,
                                    'RUN_DATE': TODAY.strftime(INPUT_TFORMAT)
                                    })
            output_file = current_trackset[j]
            if (write_csv(output_data, output_file,
                          fieldnames=TRACKFIELDS, overwrite=True)):
                LOG.info("%s saved", output_file)
                if not (history_file is None):
                    hfiles = []
                    if (os.path.isfile(history_file)):
                        with (open(history_file, 'r')) as fr:
                            hfiles = fr.read().split("\n")
                    if not (os.path.basename(output_file) in hfiles):
                        with (open(history_file, 'a')) as fa:
                            fa.write(os.path.basename(output_file) + "\n")
            else:
                LOG.error("can not save %s!", output_file)
                sys.exit(1)

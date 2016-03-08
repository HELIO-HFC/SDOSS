#! /usr/bin/env python
# -*- coding: latin-1 -*-

"""
Python module to track Sunspots on SDO/HMI images
"""
__version__ = "1.1"
#__license__ = ""
__author__ ="Xavier Bonnin"
#__credit__=[""]
#__maintainer__=""
__email__="xavier.bonnin@obspm.fr"
__date__="19-JUL-2013"

import os, sys, socket
import logging
import numpy as np
from MyToolkit import read_csv, uniq, indices
from ssw import tim2jd

# Logging id
LOGGER="sdoss_tracking"
LOG = logging.getLogger(LOGGER)

def pre_hg_long(lon,lat,day,pre_day):

    """
    Compute predicted solar heliographic longitude (in degrees)
    for a given day, providing the heliographic coordinates (lon,lat)  
    for a second day.
    """

    # Use julian days
    jday=np.sum(tim2jd(day))
    pre_jday=np.sum(tim2jd(pre_day))

    pre_lon=((pre_jday - jday) * 
             (14.48 - 2.16*(np.sin(np.radians(lat))**2)) 
             + lon)

    return pre_lon

def tracking(date_obs,feat_x_pix,feat_y_pix,feat_hg_long_deg,feat_hg_lat_deg,feat_area_deg2,
             radius=5.0,dt_max=86400,area_min=0.0,track_id=None):

    """
    Compute tracking of input features.
    Returns track id and corresponding level of trust.
    """
    
    nfeat=len(date_obs)
    if (track_id is None) or (len(track_id) == 0):
        track_id=np.arange(1,nfeat+1,dtype=np.int64)
    else:
        if (len(track_id) != nfeat):
            LOG.error("track_id has incorrect number of elements!")
            return None
        track_id=np.array(track_id,dtype=np.int64)

    
    nfeat=len(date_obs)
    if (track_id is None) or (len(track_id) == 0):
        track_id=np.arange(1,nfeat+1,dtype=np.int64)
    else:
        if (len(track_id) != nfeat):
            LOG.error("track_id has incorrect number of elements!")
            return None
        track_id=np.array(track_id,dtype=np.int64)

    lvl_trust=np.zeros(nfeat,dtype=np.float) ; processed=[]
    for i,current_date_i in enumerate(date_obs):

        if (feat_area_deg2[i] < area_min): continue
        feat_long_i = feat_hg_long_deg[i]
        feat_lat_i = feat_hg_lat_deg[i]
        lvl_trust_i=0.0 ; count_i=0.0 
        for j,current_date_j in enumerate(date_obs):

            if (feat_area_deg2[j] < area_min): continue
            if (i == j): continue
            if ([i,j] in processed) or ([j,i] in processed): continue
            feat_long_j = feat_hg_long_deg[j]
            feat_lat_j = feat_hg_lat_deg[j]
            pre_long_i = pre_hg_long(feat_long_i,feat_lat_i,current_date_i,current_date_j)

            dist = np.sqrt((feat_long_j - pre_long_i)**2 +(feat_lat_j-feat_lat_i)**2)
            dt_ij=np.abs(np.sum(tim2jd(current_date_i)) - np.sum(tim2jd(current_date_j)))*24*3600 

            if (dist <= radius) and (dt_ij < dt_max):
                cond_k = (track_id == track_id[i]) | (track_id == track_id[j])
                k=np.where(cond_k)
                #k=indices(track_id,track_id[i])
                #k.extend(indices(track_id,track_id[j]))
                #k=uniq(k)
                track_id[k]=np.min(track_id[k]) 
                lvl_trust_i+=0.5*((1.0 - 0.5*(dist/radius)) + (1.0 - 0.5*(dt_ij/dt_max)))
                count_i+=1.0
                processed.append([i,j])

        if (count_i > 0.0): lvl_trust[i]=100.0*(lvl_trust_i/count_i)
            
    return track_id, lvl_trust
                

                

    


    



#!/usr/bin/env python
""" Routines to access a netDRMS system via HTTP and CGI and to fetch
and read data.

These can be used on any Internet connected machine, and fetch data
from a netDRMS site.  You must have Python and optionally pyfits to
read the FITS files.

The default is to use the ROB netDRMS server, but note that another
server may need wrappers for data serving program, as experience shows
the DRMS might not return a correctly formed response.  Server admins
should contact <boyes@sidc.be> for example wrappers.

You can choose not to use a cache, but if you do so remember that each
time you fetch a file it has to be transferred from the server.  On
the ROB cluster the cache is set by default, elsewhere
"/tmp/sdo_cache" is tried but then None is set.

Author  David Boyes <boyes@sidc.be>
"""

""" Notes: 

urllib/cgi module : the urlencode is a bit too enthusiastic, so you
have to tell it not to escape = and &.  Some CGI servers accept
encoded versions, but Python parse() and so on do not.  Or else you
need to read stdin and unquote()....

Localisation information for SDO netDRMS data centre sets globals for:

netdrmsserver
fetch_url
info_url
cacheroot

by exploring the machine we are on.
"""

import httplib, urllib
import tarfile
import shutil
import os
import stat
import re
import glob
import socket

try:
    import pyfits
    hasfits = True
    import copy
except ImportError:
    hasfits = False

#
# Local parameters
#
# Default cache root (series name will be added automatically) outside
# the ROB cluster if available.  If not set to None, and then the
# calling program should have something like sdoget.cacheroot =
# '/tmp/my_sdo_cache' if you want to use another cache.
_def_cache = '/tmp/sdo_cache'

# Some parameters for the site
#
# Clues for ROB intranet
_intranet_dom = 'oma.be'       # if this is domain we are on intranet 
_probe_add = '192.168.144.1'   # FQDN this address for domain
#
# Clues for cluster cache (plus with at site)
_mkey = '/pool'                # mount point
_dkey = 'sdo_exports/pfscache' # visible writeable directory
_fskey = 'lustre'              # file system type
#
# The prefix the server gives the exported files in a tar archive
def _tarpath(series):
    return '/tmp/jsoc/' + series + '.'

# Check if we are in the given domain vs. not in domain or not online 
try:
    _rob_intranet = (socket.getfqdn(_probe_add)[::-1].find(_intranet_dom[::-1]) == 0)
except:
    _rob_intranet = False

# Do we have a plausible ROB type cluster cache
_have_cluster_cache = False
if os.path.ismount(_mkey) and os.access(_mkey + '/' + _dkey, os.W_OK):
    _p = os.popen('df -T ' + _mkey + ' 2>&1')
    for _l in _p:
        if _fskey in _l:
            _have_cluster_cache = True
            break
    _p.close()

if _rob_intranet:
    netdrmsserver = '192.168.144.14'
    fetch_url = '/netdrms/drms_export_cgi'
    info_url = '/netdrms/jsoc_info'
else:
    netdrmsserver = 'sdodata.oma.be'
    fetch_url = '/sdodb/netdrms/drms_export_cgi'
    info_url = '/sdodb/netdrms/jsoc_info'

if _rob_intranet and _have_cluster_cache:
    cacheroot = '/pool/sdo_exports/pfscache'
elif os.access(_def_cache, os.W_OK):
    cacheroot = _def_cache    
else:
    cacheroot = None


class LocalError(Exception):
    """Unrecoverable error not normally handled by calling program"""
    def __init(self,value,message):
        self.value = value
        self.message = message


def _checkdt(s, fmt = "%04d.%02d.%02d_%02d:%02d:%09.6f"):
    """Very relaxed date/time regex based parser.

    Accepts - or . date separators, _ or T date time separators, but
    insists on decimal point in seconds, no suffix and no -ve years.

    Returns a string based on fmt arg (6-tuple)

    Raises ValueError on bad parse."""
    date_re = r'(?P<year>\d{4})[-/.](?P<month>\d{2})[-/.](?P<day>\d{2})(?P<time>\S*)'
    time_re = r'([T_]((?P<hour>\d{2})(:(?P<minute>\d{2})(:(?P<second>\d{2}(\.\d{1,6})?))?)?)?)?(?P<rest>\S*)'
    s = ''.join(s.split())   # must remove whitespace for simple regex
    s = s.rstrip('_TAIZ')
    m = re.match(date_re, s)
    if m:
        date = (int(m.group("year")),int(m.group("month")),int(m.group("day")))
    else:
        raise ValueError
    s = m.group("time")
    if len(s) == 0:
        return fmt%(date + (0,0,0))
    m = re.match(time_re, s)
    if m and (len(m.group("rest")) == 0):
        time = []
        for u in ["hour", "minute", "second"]:
            g = m.group(u)
            if g == None:
                time.append(0)
            else:
                if u =="second":
                    time.append(float(g))
                else:
                    time.append(int(g))
        return fmt%(date + tuple(time))
    else:
        raise ValueError


def _getdata( message):
    """ Use GET to fetch response to a message.
    
    All sorts of things can go wrong, but e.g. a 404 is a correct
    response.  So wrong things that cause an exception really are
    wrong.
    """
    message = urllib.quote(urllib.unquote_plus(message),'&=')  # urlencode adds not understood +'s
    conn = httplib.HTTPConnection(netdrmsserver+':80')
    try:
        conn.request("GET", info_url+'?'+message)
        response = conn.getresponse()
        data = response.read()
    except:                # Catch very bad results
        data = None        # NB 400 messages and such are *not* trapped here
    conn.close()
    return data     # $$ can data be None legit?      


def _header2fn(hdr):
    """Get the first file name from a mime header block.

    Helper fns so fetchfile less prolix
    """
    for h in hdr.headers:
        if h.startswith('Content-Disposition') and ('filename' in h):
            s = h[h.find('filename'):].split('"')
            if len(s) < 3:
                return None
            return s[1]
    return None


class SdoGet:
    """ Get data and information on individual FITS files and from the
    netDRMS on the basis of instrument data series, T_OBS ranges and
    wavelengths if appropriate.
    """
    def __init__(self, s, d=None, wavelength=None, nrecs=1, window='10m'):
        """
        Instantiation args are :
        s - series (required)
        d - date/time start or range
        wavelength - wavelength where appropriate
        nrecs - limit on number of records (defaults to 1, 0 for all)
        window - time window (defaults to 10 minutes)

        If a date/time range is given (two date/times separated by 
        " - ") this takes precedence over the time window.

        The basic function is to get a list of recnums (the serial
        numbers in the system) and online statuses, but to be helpful
        it also gives a list of T_OBS and of suggested file names.  NB
        the suggested file names use the wavelength given here, not
        that in the FITS header.
        """
        self.series = s
        self.wavelength = wavelength
        self.filename = None        # name stem for final file
        self.files = [None]         # list of files filled in by fetch
        self.online = [None]        # online status list
        self.t_obs = [None]         # T_OBS list
        self.dtname = [None]        # made up names
        if d == None:               # that's fine, we just named series
            self.recnum = [None]
            self.statmsg = 'No record(s) selected yet'
        else:
            d = d.split(' - ')
            if len(d) == 1:
                d.append(None)
            dstart = _checkdt(d[0])            
            if d[1] == None:
                q_filter = '[' + dstart + '/' + window + ']'
            else:
                q_filter = '[' + dstart + ' - ' + _checkdt(d[1]) + ']'
            if self.wavelength != None:
                q_filter = q_filter + '[? WAVELNTH = \'' + str(self.wavelength) + '\' ?]'
            self.recnum, self.statmsg = self._firstrecs(q_filter, nmax=nrecs)

    def _firstrecs(self, q_filter, timekey='T_OBS', nmax=1):
        """ Return recnum list for what is hopefully the first
        record(s) in a time range.  Can also return (None, message)
        when recnum not available or raises an exception for a bad
        server error.  Thus you must check for before using the
        recnum.
        """
        self.recnum = [None]
        record_set = self.series + q_filter
        message = urllib.urlencode({'ds': record_set, 'op': 'rs_list', 'n':nmax, 'key': timekey + ',*recnum*,*online*,*sunum*'})
        jd = _getdata(message)         # Both good JSON and error messages 
        try:
            jd = eval(jd)
        except:
            raise LocalError(type(jd), 'Badly formed status info')  # this wrong
        if not (('status' in jd) and jd['status'] == 0 and ('keywords' in jd)):
            return (None, 'No data for given query')
        ols = []
        rns = []
        for kd in jd['keywords']:
            k = kd['name']
            v = kd['values'][0]
            if k == '*online*':
                ols = kd['values']
            if k == '*recnum*':
                rns = kd['values']
            if k == 'T_OBS':
                tobs = kd['values']
        if len(ols) == 0 and len(rns) == 0:
            return (None, 'No record(s) found')
        if len(ols) != len(rns):
            return (None, 'Inconsistent data from query')
        none_ol = True
        for i, ol in enumerate(ols):
            rns[i] = str(rns[i])
            if ol == 'Y':
                none_ol = False
        if none_ol:
            return (None, 'No record(s) currently available')  #  ## try again message?
        self.online = ols
        self.t_obs = tobs
        self.recnum = rns
        if self.wavelength == None:
            format = "%04d%02d%02d_%02d%02d%09.6f"
        else:
            format = "%04d%02d%02d_%02d%02d%09.6f" + '_' + "%04d"%(self.wavelength,)
        self.dtname = map(lambda x :_checkdt(x,format).replace('.',''),self.t_obs)

        return (rns, 'Recnum')

    def _getcache(self):
        """Get the cache dir full name."""
        if not os.access(cacheroot, os.W_OK):
            raise LocalError(cacheroot, 'Given cache root not found or not writable')
        res = cacheroot + '/' + self.series
        if not os.access(res, os.F_OK):
            os.mkdir(res)
            os.chmod(res, stat.S_IRWXU | stat.S_IRWXG | stat.S_IROTH| stat.S_IXOTH)
        if not os.access(res, os.W_OK):
            raise LocalError(res, 'Given cache directory not writable')
        return res

    def _placedata(self, src, namestem, destdir, newname, extn):
        """ Put result in destination and possibly in cache.

        src - tmpname from system
        namestem - probably recnum as string
        destdir - final dir
        newname - evt. rename
        extn - the extn in cache and to keep
        """
        if cacheroot == None:    # then don't care what namestem is
            shutil.move(src, destdir + '/' + newname + '.' + extn)
        else:
            cname = self._getcache() + '/' + namestem + '.' + extn
            shutil.move(src, cname)
            os.chmod(cname, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IWGRP)
            shutil.copy(cname, destdir + '/' + newname + '.' + extn)
            
    def _fetchsinglerecnum(self, newname=None, todir='.', fetch_rn=None, extn_filt = '') :
        """ Fetch a single file.  This will have an assigned name or
        maybe names, so you might want to rename it.

        Most users won't use this, but will probably want just
        fetch().

        Args are the recnum, optional new filename (the system adds an
        extension) and optional directory.  If no new filename is
        given a name based on the recnum is used, which is just the
        name that the server delivers.
        
        The routine sets the status message and returns None or the
        filename stem (i.e. without the extensions which distinguish
        multiple files).  That is is, there may be multiple files, all
        with this name stem plus various extensions.
        """
        # $$ the logic of some of this may be redundant
        if fetch_rn == None:
            fetch_rn = self.recnum[0]
        if fetch_rn == None:
            self.statmsg = 'No recnum given or obtained by query'
            return None
        if newname == None:
            self.filename = fetch_rn
        else:
            self.filename = newname
        # Is it possibly already in cache?
        if cacheroot != None:        # or else no cache
            fnl = glob.glob(self._getcache() + '/' + fetch_rn + '.*')
            if len(fnl) > 0:  # They seem to be in cache
                for fn in fnl:
                    n, extn = os.path.basename(fn).split('.', 1)
                    if extn_filt == '' or extn_filt == extn:
                        shutil.copy(fn, todir + '/' + self.filename + '.' + extn)
                self.statmsg =  'File from cache'
                return self.filename               # i.e. either recnum or arg

        # Not in cache, need to get
        urllib.urlcleanup()
        record_set = self.series + '[:#' + fetch_rn + ']'
        message = urllib.urlencode({'rsquery': record_set,'n':'1'})
        message = urllib.quote(urllib.unquote_plus(message),'&=/')  # urlencode adds not understood +'s
        full_url = 'http://' + netdrmsserver + fetch_url
        try:
            r = urllib.urlretrieve(full_url, data=message)  # file is r[0]
        except:
            self.statmsg = 'No response from server'       # something really odd, not e.g. 404
            return None 
        fetchname = _header2fn(r[1])          # filename from mime header

        if fetchname == None:
            self.statmsg = 'Badly formed server header' 
            return None 
        to_snip = _tarpath(self.series)     # dir in tarfile plus file name
        if fetchname.endswith('.tar'):
            if not tarfile.is_tarfile(r[0]):
                self.statmsg ='Tar file from server unreadable'  
                return None 
            tf = tarfile.open(r[0])
            res = False
            for fn in tf.getnames():
                if fn.startswith(to_snip): # ignore other content
                    tf.extract(fn)
                    rn, extn = fn[len(to_snip):].split('.',1)
                    if rn != fetch_rn:
                        self.statmsg = 'Wrong data files in tar file'
                        return None
                    if extn_filt == '' or extn_filt == extn:
                        self._placedata(fn, fetch_rn, todir, self.filename, extn)
                    res = True
            if not res:
                self.statmsg = 'Could not find data files in tar file'
                return None 
        else:          # plain file, not a tar file
            to_snip = os.path.basename(to_snip)
            if not fetchname.startswith(to_snip):
                self.statmsg = 'Data file name does not match query'  # name looks v. wrong  
                return None 
            rn,extn = fetchname[len(to_snip):].split('.',1)
            if rn != fetch_rn:
                self.statmsg = 'Wrong data file returned'
                return None
            if extn_filt == '' or extn_filt == extn:
                self._placedata(r[0], fetch_rn, todir, self.filename, extn)
        self.statmsg = 'New file from server'
        return self.filename

    def fetch(self, filename=None, todir='.', extn = '', recnum=None):
        """Fetches one or more files on the basis of the lists of
        available serial numbers ("recnum's") and online statuses
        which may have been obtained when the class is instantiated.

        Option arguments allow rename of files (from the assigned name
        based on a serial number), placement of files in a given
        directory, limit to a selected file extension and direct
        selection via the "recnum" serial number.

        Sets the list of the files obtained and returns the
        name of the first file.  That includes the destination directory,
        whereas the list of filenames does not include the directory.

        Just makes repeated calls if need be to fetchsinglerecnum()
        with friendlier args!

        Args :

        filename : string or list.  If string is used as base for a
        generated file name.  If list must match in length the list of
        recnums.

        todir : string for the destination directory

        extn : if given selects the extension for the case where a
        famility of files can be fetched (e.g. image and bad
        pixels). If not given or '' will fetch all family members.

        recnum : string (for single recnum) or list to get recnum(s)
        which need not have been found by an instantiation.  Default
        is to use the attribute found by instantiation.

        Remember that you can always (should you like to live
        dangerously) set the recnum and online attribute lists
        manually before calling.  If you give a recnum list as an
        argument, it will be assumed that all recnums are online.
        """
        if recnum == None:
            rn = self.recnum
            ol = self.online
        else:
            rn = recnum
            ol = []
            if type(recnum) == type(''):  # listify a string
                rn = [rn]
            for r in rn:
                ol.append('Y')   # mark as 'Y' and give it a try
        if rn == None:
            self.statmsg = 'No recnum given or obtained by query'
            return None
        fnres = []
        for i, oli in enumerate(ol):  # ol in case rn given
            rnn = rn[i]
            if oli == 'Y':
                if len(rn) == 1:
                    fnxt = ''
                else:
                    fnxt = '_' + str(i)
                if filename == None:
                    fn = rnn + fnxt
                elif type(filename) == type(''):
                    fn = filename + fnxt
                else:
                    fn = filename[i]
                fnres.append(self._fetchsinglerecnum(fn, todir, rnn, extn_filt=extn))
            else:
                self.statmsg = 'Some record(s) not on server at the moment, try again later'
                fnres.append(None)
        self.files = fnres         
        return todir + '/' + fnres[0] 


def readsdofits(filename, extn = '', dir = ''):
    """If the pyfits library is installed, will return a tuple of a
    keyword dictionary plus a numpy array from an SDO format
    (i.e. Rice compressed or uncompressed) FITS file.

    In fact it just reads the last unit of a 1 or 2 unit file, and
    pyfits can work out if the data is compressed.

    The data is read from a single file with a full name made from the
    two arguments separated by a dot - so the two args are just a
    help, one would do.
    """
    if not hasfits:
        return (None, 'pyfits + numpy required')
    if len(extn) > 0:
        filename = filename + '.' + extn
    if dir != '':
        dir = dir.rstrip('/') + '/'
    # SDO data is in second HDU
    hd = pyfits.open(dir + filename)
    if len(hd) == 2:
        hdun = 1
    elif len(hd) == 1:
        hdun = 0
    else:
        return (None, 'FITS file structure odd') 
    kwds = {}
    # You can do this, but it is still talkative
    #hd[hdun].verify('silentfix')
    for k in hd[hdun].header:
        try:
            kwds[k] = hd[hdun].header[k]
        except ValueError:
            continue
    img = copy.copy(hd[hdun].data)
    hd.close()
    return (kwds, img)



def Main():
    """Display the settings for this location."""
    if _rob_intranet:
        print 'Will connect on ROB intranet using:'
    else:
        print 'Will connect via internet using:'
    print 'Server: ',netdrmsserver
    print 'Fetch command: ',fetch_url
    print 'Query command: ',info_url
    print 'Data cache: ',cacheroot
    if cacheroot == None:
        print 'You might want to make a data cache at ' + _def_cache
    if not hasfits:
        print 'Warning, pyfits and/or numpy not available,\nyou will not be able to read the files you download'

if __name__ == "__main__":
    Main()


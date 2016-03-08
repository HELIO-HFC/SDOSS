pro sdoss_processing, fnc, fnm, feat_data, $ 
                      obs_data=obs_data, $
                      scf=scf, dt_max=dt_max, $
                      feat_min_area=feat_min_area, $
                      max_hg_long=max_hg_long, $
                      output_dir=output_dir, $
                      write_fits=write_fits, $
                      version=version, $
                      nfeat=nfeat, nobs=nobs, $
                      QUICKLOOK=QUICKLOOK,$
                      SNAPSHOT=SNAPSHOT, $
                      VERBOSE=VERBOSE,DEBUG=DEBUG

;+
; NAME:
;   sdoss_processing
;
; PURPOSE:
; 	Running sunspot detection algorithm 
;	  on SDO HMI Ic and M data.
;
; CATEGORY:
;	  Image processing
;
; GROUP:
;	  SDOSS
;
; CALLING SEQUENCE:
;	  sdoss_processing, fnc, fnm
;
; INPUTS:
;   fnc	- list of HMI/Ic file(s).
;   fnm     - list of near close HMI/M file(s). 	
;	
; OPTIONAL INPUTS:
;   scf 	        - Scaling factor (either 1 or 4):
;        	                1 -> normal resolution is used (default)
;               	        4 -> the images are rescaled 4 times down
;                    	             (SOHO/MDI resolution).
; 
;   dt_max        - Maximal time gap between a continuum and magnetogram observation in hours.
;                   Default is 6 hours.
;   write_fits    - Write auxillary fits files:
;                      	1 -> Intensity with limb darkening removed
;                      	2 -> as 1 plus corresponding magnetogram
;                      	3 -> as 2 plus detection results	
;   feat_min_area - Specify the minimal area of features to save in square degrees on the solar surface.
;                   Default is 0.0.
;   max_hg_long   - Maximal absolute heliographic longitude of the detected sunspots in degrees.
;                   Default is 90.0.
;   output_dir    - Folder for writing output files.
;
; KEYWORD PARAMETERS:
;   /DEBUG         - Debug mode.
;	  /VERBOSE       - Talkative mode.
;   /QUICKLOOK     - Write quicklook images in png format.
;   /SNAPSHOT      - Write snapshot images in png format. OBSOLETE
;
; OUTPUTS:
;	  feat_data - Structure containing detected sunspot parameters.	
;
; OPTIONAL OUTPUTS:
;   obs_data - Structure containing information about observation data.
;   Version  - string providing the current software version.
;   nfeat    - Number of sunspot(s) detected.
;   nobs     - Number of observation files processed.
;
; COMMON BLOCKS:		
;	  None.
;	
; SIDE EFFECTS:
;	  None.
;
; RESTRICTIONS/COMMENTS:
;	  The gen, sdo, ontology, and vso SolarSoftWare (SSW) packages must be installed.
;	  SDOSS auxiliary routines must be compiled.
;		
; CALL:
;	  read_sdo
;	  float_qsmedian
;	  wl_detspgs_sdo
;	  sdo_labelcountregion
;	  tim2carr
;   jd2str
;   anytim2jd
;   anytim
;	  arcmin2hel
;	  sdo_pix2hel
;	  sdoss_getbndrct
;	  sdoss_getrasterscan
;	  sdoss_getchaincode
;   sdoss_sunspots__define
;   sdoss_observations__define
;	  tvframe
;	  sdoss_xml
;	  mwritefits
;	  feat_cc_extract
;	  ssw_jsoc_time2data
;
; EXAMPLE:
;	  None.		
;
; MODIFICATION HISTORY:
;	Version 1.00
;		Written by S.Zharkov (MSSL).
;
;	Version 1.01
;		22-JUL-2011, X.Bonnin:	Added /WRITE_CSV keyword, and
;								            updated the header.
;										
;		28-JUL-2011, X.Bonnin:	Added write_png optional input.
;
; Version 1.02
;   27-DEC-2011, X.Bonnin:  Introduced hfc table parameters using structures
;                           loaded by the new routine sdoss_hfc_setup.
;                           They permit to pass code results as output idl arguments 
;                           without having to produce output files.
;	Version 1.03
;		10-JAN-2012, X.Bonnin:	Correction of minor bugs.
;					                  Updated write_png optional input.
; Version 1.04
;   30-JAN-2012, X.Bonnin:  Added feat_min_pix optional keyword. 
;
;	Version 1.05
;		12-APR-2012, X.Bonnin:	Added unprocessed_files optional outputs.
;					                  Renamed /CHECKWAIT to /DEBUG.
;					                  Added /VERBOSE keyword.
;					                  Added _sdo_ substring to the csv output file names.
;					                  Fixed a bug that provides wrong chain codes.
;                           Added command line call functionality.
Version='1.06'
;   19-FEB-2014, X.Bonnin:  Use write_jpeg instead of write_png for quicklook production
;                           (quality is equal to 80).
;                           Replace feat_min_pix by feat_min_area.
;                           Add max_hg_long optional input.
;                           Remove sdoss_hfc_setup call.
;                           Remove /XML, /CSV, and /LOG keywords.
;                           Add feat_data and obs_data output parameters.
;                           Add nfeat and nobs optional output parameters.
;
;-

syst0 = systime(/SEC)
quote = string(39b)
deg2mm = 6.96e8/!radeg

;[1];Initializing program
;[1]:====================
feat_data=0b & obs_data=0b & nfeat=0l & nobs=0l
if (keyword_set(fnc)+keyword_set(fnm) ne 2) then begin
   message,/INFO,'Call is:'
   print,'sdoss_processing, fnc, fnm, feat_data, $'
   print,'                  obs_data=obs_data, scf=scf, $'
   print,'                  dt_max=dt_max, $'
   print,'                  feat_min_area=feat_min_area, $'
   print,'                  output_dir=output_dir, write_fits=write_fits,$'
   print,'                  version=version, nfeat=nfeat, $'
   print,'                  nobs=nobs, $'
   print,'                  /QUICKLOOK,/SNAPSHOT, $'
   print,'                  /DEBUG, /VERBOSE'
   return
endif

;Run date
run_date = (strsplit(anytim(!stime, /ccsds),'.',/EXTRACT))[0]
compact_date = strjoin(strsplit(run_date,'-T:'))

sec2day = 1.0d/(3600.0d*24.0d)
!QUIET = 1

DEBUG = keyword_set(DEBUG)
VERBOSE = keyword_set(VERBOSE)
if (DEBUG) then begin
	!QUIET = 0
	VERBOSE = 1
	message,/INFO,'DEBUG MODE ON!'
	wait,2.0
endif
QLK = keyword_set(QUICKLOOK)
SNP = keyword_set(SNAPSHOT)

outfnroot = 'sdoss_'+strjoin(strsplit(version,'.',/EXTRACT))

if (not keyword_set(output_dir)) then cd,current=outroot else outroot = strtrim(output_dir[0],2) 
outroot = outroot + path_sep()

;Initialize history, processed, and unprocessed outputs 
if (VERBOSE) then print,'sdoss has started on '+run_date
unprocessed = fnc

; rgb vectors to write quicklook images
r = bindgen(256)
g = bindgen(256)
b = bindgen(256)

if not (keyword_set(feat_min_area)) then feat_min_area = 0.0
if not (keyword_set(dt_max)) then dt_max=6.0d
if not (keyword_set(max_hg_long)) then max_hg_long=90.0
if not (keyword_set(scf)) then scf=1 ; Full scale resolution

nfnc = n_elements(fnc)
nfnm = n_elements(fnm)
if (nfnc ne nfnm) then $
	message,'Numbers of input HMI Ic and M files must be the same!'

;[1]:====================


;[2]:Load input structures
;[2]:=====================
;Load Observatory, FRC, Observations, Pre-Process, feature code parameters 
;for current running using dedicated HFC structures
if (VERBOSE) then print,'Initializing output structures...'
feat_data={sdoss_sunspots}
obs_data={sdoss_observations}
obs_data=replicate(obs_data,nfnc)
feat_data=replicate(feat_data,nfnc*1000l)
feat_data.run_date=run_date
if (VERBOSE) then print,'Initializing output structures...done'
;[2]:=====================


;[3]:Loops on each fits files
;[3]:========================
iobs=0l & ifeat=0l
for i=0l, nfnc-1l do begin
  
  istr=strtrim(i+1,2)
  fnc_i = fnc[i] & fnm_i = fnm[i]
	
  ;Reading SDO data files
  tt=systime(/sec)
 
  if (VERBOSE) then print,'['+istr+']: Reading '+fnc_i+'...'
  if (not file_test(fnc_i,/REG)) then message,'['+istr+']: ERROR - '+fnc_i+' fits file does not exist!'

  read_sdo, fnc_i, inc, dac, /UNCOMP_DEL, header=hd
  if (size(inc,/TNAME) ne 'STRUCT') then message,'['+istr+']: ERROR - Can not read '+fnc_i
  if (VERBOSE) then print,'['+istr+']: Reading '+fnc_i+'...done'

  if (VERBOSE) then print,'['+istr+']: Reading '+fnm_i+'...'
  if (not file_test(fnm_i,/REG)) then message,'['+istr+']: ERROR - '+fnm_i+' fits file does not exist!'

  read_sdo, fnm_i, inm, dam, /UNCOMP_DEL, header=hd
  if (size(inm,/TNAME) ne 'STRUCT') then message,'['+istr+']: ERROR - Can not read '+fnm_i
  if (VERBOSE) then print,'['+istr+']: Reading '+fnm_i+'...done'

  ; Checking dates and times of loaded files
  jdc = anytim2jd(inc.date_obs) & jdm = anytim2jd(inm.date_obs)
  if (abs(jdc.int+jdc.frac - (jdm.int+jdm.frac)) gt double(dt_max)/24.0d) then begin
    message,/CONT,'['+istr+']: WARNING - time gap between '+fnc_i+' and '+fnm_i+' observations is too large!'
    continue
  endif
        
  ; Load corresponding fields in the observations structure
  inc_date_obs = (strsplit(inc.date_obs,'.',/EXTRACT))[0]
  inc_date_end = jd2str(jdc.int+jdc.frac+inc.cadence*sec2day,format=1)
  inm_date_obs = (strsplit(inm.date_obs,'.',/EXTRACT))[0]
  inm_date_end = jd2str(jdm.int+jdm.frac+inm.cadence*sec2day,format=1)
  obs_data[iobs].id_observations = [1,2]
  obs_data[iobs].date_obs = [inc_date_obs,inm_date_obs]
  obs_data[iobs].date_end = [inc_date_end,inm_date_end]
  obs_data[iobs].jdint = [jdc.int,jdm.int]
  obs_data[iobs].jdfrac = [jdc.frac,jdm.frac]
  obs_data[iobs].exp_time = [inc.cadence,inm.cadence]
  obs_data[iobs].c_rotation = [inc.car_rot,inm.car_rot]
  obs_data[iobs].bscale = [inc.bscale,inm.bscale]  
  obs_data[iobs].bzero = [inc.bzero,inm.bzero] 
  obs_data[iobs].bitpix = [inc.bitpix,inm.bitpix]
  obs_data[iobs].naxis1 = [inc.naxis1,inm.naxis1]
  obs_data[iobs].naxis2 = [inc.naxis2,inm.naxis2]
  obs_data[iobs].center_x = [inc.crpix1,inm.crpix1]
  obs_data[iobs].center_y = [inc.crpix2,inm.crpix2]
  obs_data[iobs].cdelt1 = [inc.cdelt1,inm.cdelt1]
  obs_data[iobs].cdelt2 = [inc.cdelt2,inm.cdelt2]
  obs_data[iobs].r_sun = [inc.rsun_obs/inc.cdelt1,inm.rsun_obs/inm.cdelt1]
  
  obs_data[iobs].quality = [inc.quality,inm.quality]
  obs_data[iobs].filename = [file_basename(fnc_i),file_basename(fnm_i)]
  obs_data[iobs].data_type = ['IMAGE','IMAGE']
  obs_data[iobs].file_format = ['FITS','FITS']
  fnc_info = file_info(fnc_i) & fnm_info = file_info(fnm_i)
  obs_data[iobs].file_size = [fnc_info.size,fnm_info.size]/1000.0
  obs_data[iobs].comment = [strjoin(inc.comment),strjoin(inm.comment)]
  ; replace the possible semi-commas encountered in the comment field
  ; by commas.
  obs_data[iobs].comment[0] = strjoin(strsplit(obs_data[iobs].comment[0],';',/EXTRACT),',')
  obs_data[iobs].comment[1] = strjoin(strsplit(obs_data[iobs].comment[1],';',/EXTRACT),',')
  obs_data[iobs].loc_filename = [fnc_i,fnm_i] 

  ;'YYYY-MM-DDTHH:NN:SS.SSSZ' --> ;'YYYYMMDDTHHNNSS.SSSZ'
  t_rec = strjoin((strsplit(inc.t_rec,'_',/EXTRACT))[0:1],'T') ;use t_rec for output filename
  cdate = strjoin(strsplit(t_rec,'-:.',/EXTRACT))

  ; ***** do the rotation correction
  dac=rot(dac, -inc.crota2, 1.d/scf, inc.crpix1-1, inc.crpix2-1, cubic=-.5)
  inc.crota2=0
  dam=rot(dam, -inm.crota2, 1.d/scf, inm.crpix1-1, inm.crpix2-1, cubic=-.5)
  inm.crota2=0

  if (VERBOSE) then print, '['+istr+']: Reading data took '+ strtrim(systime(/sec)-tt,2) + ' sec.'	
  
  if (QLK) then begin
    qlk_file = file_basename(obs_data[iobs].filename[0],'.fits')+'.jpg'
    qlk_path = outroot + qlk_file
    if (VERBOSE) then print,'['+istr+']: Writing '+qlk_path
    imc = bytscl(dac,top=255,/NAN)
    write_jpeg,qlk_path,imc,quality=80	
    obs_data[iobs].qclk_fname[0] = qlk_file
 
    qlk_file = file_basename(obs_data[iobs].filename[1],'.fits')+'.jpg'
    qlk_path = outroot + qlk_file
    if (VERBOSE) then print,'['+istr+']: Writing '+qlk_path
    imm = bytscl(dam,top=255,min=-1.e2,max=1.e2,/NAN)
    write_jpeg,qlk_path,imm,quality=80	
    obs_data[iobs].qclk_fname[1] = qlk_file	
  endif
	
  iobs++

  if (VERBOSE) then print,'['+istr+']: Pre-processing images...'
  if scf eq 4 then begin
    xc=fix(inc.crpix1-.5) &  yc=fix(inc.crpix2-.5)
    dac=dac((xc-512):(xc+511), (yc-512):(yc+511))
    dam=dam((xc-512):(xc+511), (yc-512):(yc+511))
    xc=512. & yc=512.
    nx=1024 & ny=1024
  endif else begin
    xc=inc.crpix1/scf-1
    yc=inc.crpix2/scf-1
    nx=inc.naxis1 & ny=inc.naxis2
  endelse
  qsim=float_qsmedian(dac, inc.rsun_obs/inc.CDELT1/scf, xc ,yc) ;Quiet Sun image (QS) + limb darkening
  flatimage = qsim 
  llocs=where(qsim ne 0) 
  if llocs(0) eq -1 then $
    message,'['+istr+']: WARNING - '+file_basename(fnc_i)+' ***** problem computing flat continuum image!'
  flatimage(llocs)=dac(llocs)/qsim(llocs)    	
   
  if (VERBOSE) then begin
    print,'['+istr+']: Pre-processing images...done'
    print,'['+istr+']: Substracting limb darkening took '+strtrim(systime(/sec)-tt,2) + ' sec.'
    print,'['+istr+']: Run the detection...'
  endif
  ; **** determin quiet Sun value
                                
  hh=histogram(flatimage, loc=xx, nbin=10000/scf)
  mm=max(hh(1:*), ii) & qsval=xx(ii(0)+1)
	 
  ; ***** run the detection
  if scf eq 1 then scale=4 
  if scf eq 4 then scale=1
	 
  MAXIMUM_FEATURE_LENGTH_X=300*scale
  MAXIMUM_FEATURE_LENGTH_Y=300*scale
  ss=wl_detspgs_sdo(flatimage, inc.naxis1/scf, inc.naxis2/scf, inc.crpix1/scf-1, inc.crpix2/scf-1, $
                    inc.rsun_obs/inc.CDELT1/scf, qsval, /sbl, /one, scale=scale, error=error)
  if (error) then $
    message, '['+istr+']: ERROR - '+file_basename(fnc_i)+'/'+file_basename(fnm_i)+' ***** problem computing detection!'
   
  if (VERBOSE) then begin
    print,'['+istr+']: Run the detection...done'
    print,'['+istr+']: Running sunspot detection took '+strtrim(systime(/sec)-tt,2)+' sec.'
    print,'['+istr+']: Extracting output parameters...'
  endif
  ; **** now - verification
	 
  sp2=ss ge 1
  spot_image=ss & spot_image(*)=0
   
   
  sdoss_labelcountregion, sp2, n, ploc
  count=0
   
  mgim=dam
  image=flatimage
   
  l0=(tim2carr(inc.date_obs))(0)
	
  if (n eq 0) then begin
    if (VERBOSE) then print,'['+istr+']: No sunspot detected'
    continue
  endif else if (VERBOSE) then print,'['+istr+']: '+strtrim(n,2)+' sunspot(s) detected'

  for j=0, n-1 do begin
    minfluxvalue=abs(min(mgim[*ploc[j]]))
    maxfluxvalue=abs(max(mgim[*ploc[j]])) > minfluxvalue
    locs=*ploc[j]
    irrad=total(image[locs])/(qsval*n_elements(locs))
      
    minir=min(image[locs])
    maxir=max(image[locs])
    meanir=mean(image[locs])
      	
    xp=locs mod nx
    yp=locs / nx
      
    if (max(xp) - min(xp)) ge MAXIMUM_FEATURE_LENGTH_X then continue
    if (max(yp) - min(yp)) ge MAXIMUM_FEATURE_LENGTH_Y then continue
      
    if ((n_elements(locs) le 2) and irrad gt .98) then continue
    if (irrad lt .85)  then begin
     	if (n_elements(locs) lt 10 and $
        (maxfluxvalue lt 75)) then continue $
      else if (maxfluxvalue lt 40) then continue
    endif $
      else if (maxfluxvalue lt 100) then continue   
      
    spot_image[*ploc[j]]=1
    umbra=where(ss(*ploc[j]) eq 2)
    umbraploc=ptr_new(umbra)
    if umbra[0] eq -1 then nu=0 else begin
      pl=*ploc[j]
      temp=bytarr(nx, ny)
      temp[pl[umbra]]=1
      spot_image[pl[umbra]]=2
      uminfluxvalue=abs(min(mgim[pl[umbra]]))
      umaxfluxvalue=abs(max(mgim[pl[umbra]])) > uminfluxvalue
      umeanfluxvalue=mean(mgim[pl[umbra]])
      utotfluxvalue=total(mgim[pl[umbra]])
      uabstotfluxvalue=total(abs(mgim[pl[umbra]]))
      umin_int = min(image[pl[umbra]],max=umax_int)        
      umean_int = mean(image[pl[umbra]])
         
      sdoss_labelcountregion, temp, nu, umbraploc    
    endelse
    mean0=mean(image[*ploc[j]])
      
    ; Gravity center
    gcx=total(image(locs)*(locs mod nx))/total(image(locs))
    gcy=total(image(locs)*(locs / nx))/total(image(locs))
      
    feat_data[ifeat].id_sunspot = ifeat + 1l   
    feat_data[ifeat].observations_id_ic = iobs + 1l
    feat_data[ifeat].observations_id_m = iobs + 1l        
      
    feat_data[ifeat].feat_x_pix = gcx       ;gc_pixx
    feat_data[ifeat].feat_y_pix = gcy       ;gc_pixy
			         
    feat_data[ifeat].feat_x_arcsec=(gcx-xc)*inc.cdelt1*scf       ;gc_arcx
    feat_data[ifeat].feat_y_arcsec=(gcy-yc)*inc.cdelt2*scf       ;gc_arcy
      
    ll=arcmin2hel(feat_data[ifeat].feat_x_arcsec/60, $
                  feat_data[ifeat].feat_y_arcsec/60, $
                  date=inc.date_obs, /soho)
			         
    feat_data[ifeat].feat_hg_long_deg = ll(1)  ;gc_helon
    feat_data[ifeat].feat_hg_lat_deg = ll(0)   ;gc_helat
	         
    ; TEMPORARY: REMOVE DETECTIONS NEAR THE LIMBS
    ; (i.e., helio long > 70 deg).
    if (abs(feat_data[ifeat].feat_hg_long_deg) gt float(max_hg_long)) then begin
      if (DEBUG) then stop,'['+istr+']: Current sunspot position is outside the detection area!'
      ptr_free, umbraploc
      continue
    endif 
	         
    feat_data[ifeat].feat_carr_long_deg=ll(1)+l0      ;gc_carrlonn
    feat_data[ifeat].feat_carr_lat_deg=ll(0)          ;gc_carrlat
    feat_data[ifeat].umbra_number=nu                  ;Number of umbras
    feat_data[ifeat].feat_area_pix=n_elements(locs)   ;ss_area_pix
	         
    ; heliographic ss area and diameter
    yy=sdo_pix2hel(inc.date_obs, locs, xc, yc, $
                   inc.cdelt1*scf, inc.cdelt2*scf, nx, ny, res=.01, area=area, diam=diam)
    feat_data[ifeat].feat_area_deg2=area             ;ss_area_deg2
    feat_data[ifeat].feat_area_mm2=area*(deg2mm)^2   ;ss_area_mm2
    feat_data[ifeat].feat_diam_deg=diam              ;ss_diam_deg
    feat_data[ifeat].feat_diam_mm=diam*(deg2mm)      ;ss_diam_mm
	
    if (feat_data[ifeat].feat_area_deg2 lt feat_min_area) then begin
      if (DEBUG) then stop, '['+istr+']: Current sunspot area is too small: '+$
                            strtrim(feat_data[ifeat].feat_area_deg2,2)+' square degrees, skipping!'
      ptr_free, umbraploc
      continue  
    endif    
      
    ; heliographic umbra area and diameter
    if (nu ne 0) then begin
      feat_data[ifeat].umbra_area_pix=n_elements(umbra) ;umbra_area_pix
      yy=sdo_pix2hel(inc.date_obs, umbra, xc, yc, inc.cdelt1*scf, inc.cdelt2*scf, $
                     nx, ny, res=.01, area=uarea, diam=udiam)
      
      feat_data[ifeat].umbra_area_deg2=uarea                  ;umbra_area_deg2
      feat_data[ifeat].umbra_area_mm2=uarea*(deg2mm)^2        ;umbra_area_mm2
      feat_data[ifeat].umbra_diam_deg=udiam                   ;umbra_diam_deg
      feat_data[ifeat].umbra_diam_mm=udiam*(deg2mm)           ;umbra_diam_mm
    endif                                     
	   
    ; Bounding rectangle in pixel and arcsec
    sdoss_getbndrct, locs, nx, ny, xc, yc, inc.cdelt1*scf, inc.cdelt2*scf, arc=arc, xx=zz
      
    feat_data[ifeat].br_x0_pix=zz[0]
    feat_data[ifeat].br_y0_pix=zz[1]
    feat_data[ifeat].br_x1_pix=zz[0]
    feat_data[ifeat].br_y1_pix=zz[3]     
    feat_data[ifeat].br_x2_pix=zz[2] 
    feat_data[ifeat].br_y2_pix=zz[1] 
    feat_data[ifeat].br_x3_pix=zz[2]   
    feat_data[ifeat].br_y3_pix=zz[3]
    
    feat_data[ifeat].br_x0_arcsec=arc[0]
    feat_data[ifeat].br_y0_arcsec=arc[1]
    feat_data[ifeat].br_x1_arcsec=arc[0]
    feat_data[ifeat].br_y1_arcsec=arc[3]     
    feat_data[ifeat].br_x2_arcsec=arc[2] 
    feat_data[ifeat].br_y2_arcsec=arc[1] 
    feat_data[ifeat].br_x3_arcsec=arc[2]   
    feat_data[ifeat].br_y3_arcsec=arc[3]
    
    ; Bounding rectangle in heliographic and carrington
    ll=arcmin2hel([arc(0),arc(0),arc(2),arc(2)]/60, [arc(1),arc(3),arc(1),arc(3)]/60, date=inc.date_obs, /soho)
  
    ll = reverse(ll,1)
    feat_data[ifeat].br_hg_long0_deg = ll(0,0)
    feat_data[ifeat].br_hg_lat0_deg = ll(1,0)
    feat_data[ifeat].br_hg_long1_deg = ll(0,1)
    feat_data[ifeat].br_hg_lat1_deg = ll(1,1)
    feat_data[ifeat].br_hg_long2_deg = ll(0,2)
    feat_data[ifeat].br_hg_lat2_deg = ll(1,2)
    feat_data[ifeat].br_hg_long3_deg = ll(0,3)
    feat_data[ifeat].br_hg_lat3_deg = ll(1,3)
    ll(0,*) = ll(0,*) + l0
    feat_data[ifeat].br_carr_long0_deg = ll(0,0)
    feat_data[ifeat].br_carr_lat0_deg = ll(1,0)
    feat_data[ifeat].br_carr_long1_deg = ll(0,1)
    feat_data[ifeat].br_carr_lat1_deg = ll(1,1)
    feat_data[ifeat].br_carr_long2_deg = ll(0,2)
    feat_data[ifeat].br_carr_lat2_deg = ll(1,2)
    feat_data[ifeat].br_carr_long3_deg = ll(0,3)
    feat_data[ifeat].br_carr_lat3_deg = ll(1,3) 
	         
    ; Magnetic field Bz values
    
    ; minimum/maximum/mean/tot ss Bz flux
    feat_data[ifeat].feat_min_bz=minfluxvalue
    feat_data[ifeat].feat_max_bz=maxfluxvalue
    feat_data[ifeat].feat_mean_bz=mean(mgim[*ploc[j]]) 
    feat_data[ifeat].feat_tot_bz=total(mgim[*ploc[j]])
    feat_data[ifeat].feat_abs_bz=total(abs(mgim[*ploc[j]]))
                      
    ; minimum/maximum/mean/tot umbral flux
    if nu ne 0 then begin
       feat_data[ifeat].umbra_min_bz=uminfluxvalue 
       feat_data[ifeat].umbra_max_bz=umaxfluxvalue
       feat_data[ifeat].umbra_mean_bz=umeanfluxvalue 
       feat_data[ifeat].umbra_tot_bz=utotfluxvalue
       feat_data[ifeat].umbra_abs_bz=uabstotfluxvalue
       feat_data[ifeat].umbra_min_int=umin_int
       feat_data[ifeat].umbra_max_int=umax_int  
       feat_data[ifeat].umbra_mean_int=umean_int
    endif 
	        
    ; Intensity values
    feat_data[ifeat].feat_min_int=minir                                ;min intensity on pre-processed image
    feat_data[ifeat].feat_max_int=maxir                                ;max intensity on pre-processed image              
    feat_data[ifeat].feat_mean_int=meanir                              ;mean intensity on pre-processed image 
    feat_data[ifeat].feat_mean2qsun=irrad                              ;mean intensity on Quiet Sun ratio 
         
    ; Raster scan
    feat_data[ifeat].rs=sdoss_getrasterscan(zz, nx, ny, locs, umbra, DEBUG=0)
    if (feat_data[ifeat].rs eq '') then message,'['+istr+']: ERROR - Empty raster scan! ('+fnc_i+':'+strtrim(j,2)+')'
    feat_data[ifeat].rs_length = strlen(feat_data[ifeat].rs)                
    
    ; Chain code
    ad=''
    cc_arc_i=sdoss_getchaincode(locs, zz, nx, ny, xc, yc, $
                                inc.cdelt1*scf, inc.cdelt2*scf, cc_pix=cc_pix_i,$
                                ad=ad,DEBUG=0)

    ad = strtrim(ad,2)
    if (ad[0] eq '') then message,'['+istr+']: ERROR - Empty chain code! ('+fnc_i+':'+strtrim(j,2)+')'
    feat_data[ifeat].cc = strjoin(strtrim(ad,2))
    feat_data[ifeat].cc_length = strlen(feat_data[ifeat].cc)
    feat_data[ifeat].cc_x_pix = cc_pix_i(0,0)          ;cc_x_pix
    feat_data[ifeat].cc_y_pix = cc_pix_i(1,0)          ;cc_y_pix              
    feat_data[ifeat].cc_x_arcsec = cc_arc_i(0,0)       ;cc_x_arcsec
    feat_data[ifeat].cc_y_arcsec = cc_arc_i(1,0)       ;cc_x_arcsec

    if (DEBUG) then begin
       print,'['+istr+']: Feature number: '+strtrim(count,2) 
       window,2
       loadct,0,/SILENT
       xr=[gcx-50,gcx+50]
       yr=[gcy-50,gcy+50]
       tvframe, dam[xr[0]:xr[1],yr[0]:yr[1]], /bar, /asp
       contour, spot_image(xr[0]:xr[1],yr[0]:yr[1]), lev=[1, 2], c_th=[3, 2], /ov
       cc = feat_cc_extract(feat_data[ifeat].cc,[feat_data[ifeat].cc_x_pix,feat_data[ifeat].cc_y_pix])
       loadct,39,/SILENT
       oplot,cc[0,*] - (gcx - 50),cc[1,*] - (gcy - 50),color=200,thick=2,line=2
       
       print,feat_data[ifeat].feat_x_pix,feat_data[ifeat].feat_y_pix
       stop,'DEBUG MODE --> STOP ENCOUNTERED'
    endif	      
          
    ifeat++
    ptr_free, umbraploc
  endfor

  if (VERBOSE) then begin
    print,'Extracting output parameters...done'
    print,'running sunspot verification took '+strtrim(systime(/sec)-tt,2)+' sec.'
  endif
   
   ; **** now - write output  
   sp2=spot_image ge 1      
   sdoss_labelcountregion, sp2, n, ploc
   
	
   ; Updated header of corrected fits
   inc1=inc
   inc1.cdelt1=inc.cdelt1*scf & inc1.cdelt2=inc.cdelt2*scf
   inc1.naxis1=inc.naxis1/scf & inc1.naxis2=inc.naxis2/scf
   inc1.crpix1=xc & inc1.crpix2=yc
	
   inm1=inm
   inm1.cdelt1=inm.cdelt1*scf & inm1.cdelt2=inm.cdelt2*scf
   inm1.naxis1=inm.naxis1/scf & inm1.naxis2=inm.naxis2/scf
   inm1.crpix1=xc & inm1.crpix2=yc
   
   fnc_corr = "NULL"
   fnm_corr = "NULL"
   snapshot_fn = "NULL"
   if keyword_set(write_fits) then begin	
      if (VERBOSE) then print,'Writing fits files...'
      fnc_corr = outroot+ strmid(fnc_i, strpos(fnc_i, '/', /reverse_se)+1)+'_corrected_flat.fits'
      mwritefits, outfile=fnc_corr, inc1, flatimage
      if (fix(write_fits) ge 2) then begin
         fnm_corr = outroot+ strmid(fnc_i, strpos(fnc_i, '/', /reverse_se)+1)+'_magnetogram.fits'
         mwritefits, outfile=fnm_corr, inc1, dam
      endif
      if (fix(write_fits) ge 3) then mwritefits, outfile=outroot+ $
         strmid(fnc_i, strpos(fnc_i, '/', /reverse_se)+1) $
         +'_detection_results.fits', inc1, spot_image
      if (VERBOSE) then print,'Writing fits files...done'
   endif
	
   if (SNP) and (ifeat gt 0) then begin 
      snp_file = file_basename(obs_data[iobs-1l].filename[0],'.fits') + $
                 '_sdoss_results.jpg'
      snp_path = outroot + snp_file
      if (VERBOSE) then print,'Writing '+snp_path
      imc_ss = bytscl(spot_image,top=255)
      write_jpeg,snp_path,imc_ss,quality=80
   endif
endfor
if (iobs gt 0l) then obs_data=obs_data[0:iobs-1l]
if (ifeat gt 0l) then feat_data=feat_data[0:ifeat-1l]
nfeat=ifeat & nobs=iobs

print,'Total processing took '+strtrim((systime(/SEC) - syst0)/60.,2)+' min.'
;[3]:========================

END

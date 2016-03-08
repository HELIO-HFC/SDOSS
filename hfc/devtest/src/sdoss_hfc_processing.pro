pro sdoss_hfc_processing, config_file, fnc, fnm, $ 
                          data_dir=data_dir, $
                          fnc_url=fnc_url,fnm_url=fnm_url, $
                          output_dir=output_dir, $
                          QUICKLOOK=QUICKLOOK,$
                          SNAPSHOT=SNAPSHOT, $
                          VERBOSE=VERBOSE,DEBUG=DEBUG

;+
; NAME:
;     sdoss_hfc_processing
;
; PURPOSE:
;     Runs SDOSS detection algorithm 
;     and returns HFC-compliant output parameters
;     into csv format files.
;
; CATEGORY:
;     Image processing
;
; GROUP:
;     SDOSS_HFC
;
; CALLING SEQUENCE:
;     sdoss_hfc_processing, config_file, fnc, fnm
;
; INPUTS:
;     config_file - Path of the SDOSS HFC configuration file.
;     fnc	      - list of HMI/Ic file(s). (Can be URL)
;     fnm         - corresponding list of near close HMI/M file(s). (Can be URL)	
;	
; OPTIONAL INPUTS:
;     data_dir      - Directory of input data files. If paths of input files are
;                     URLs, then data files will be downloaded in the data_dir directory.
;     output_dir    - Directory where the output files will be saved.
;     fnc_url       - List of Ic file URLS to be passed into output csv files.
;     fnm_url       - List of M file URLS to be passed into output csv files.
;
; KEYWORD PARAMETERS:
;     /DEBUG         - Debug mode.
;     /VERBOSE       - Talkative mode.
;     /QUICKLOOK     - Write quicklook images in png format.
;     /SNAPSHOT      - Write snapshot images in png format. OBSOLETE
;
; OUTPUTS:
;     None.	
;
; OPTIONAL OUTPUTS:
;     None.
;
; COMMON BLOCKS:		
;     None.
;	
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS/COMMENTS:
;     The gen, sdo, ontology, and vso SolarSoftWare (SSW) packages must be installed.
;     SDOSS auxiliary routines must be compiled.
;
;     wget command line tool must be installed.
;		
; CALL:
;     sdoss_hfc_parse_config
;     sdoss_hfc_load_meta
;     sdoss_processing
;     hfc_write_csv
;
; EXAMPLE:
;	   None.		
;
; MODIFICATION HISTORY:
Version='1.06'
;     19-FEB-2014, X.Bonnin:    Major updates.
;                               sdoss_hfc_processing routine is now splitted
;                               into two separated routines sdoss_hfc_processing
;                               and sdoss_processing.
;
;-

quote=string(39b)
sep=path_sep()
outfnroot = 'sdoss_'+strjoin(strsplit(version,'.',/EXTRACT))

;[1];Initializing program
;[1]:====================

args = strtrim(command_line_args(),2)

nargs = n_elements(args)
if (nargs gt 2) then begin
   config_file = args[0]
   fnc = args[1]
   fnm = args[2]
   inputpar = ['data_dir','output_dir', $
                'fnc_url','fnm_url']
   inputkey = ['/quicklook', '/snapshot', $
               '/debug','/verbose']
   for i=0l,n_elements(args)-1 do begin
      where_key = (where(strlowcase(args[i]) eq inputkey))[0]
      if (where_key ne -1) then begin
        flag = execute(strmid(inputkey[where_key],1)+'=1')
        continue
      endif
      value = strsplit(args[i],'=',/EXTRACT) & nval_i = n_elements(value)
      if (nval_i eq 2) then begin
        where_par = (where(strlowcase(value[0]) eq inputpar))[0]
        if (where_par ne -1) then $
          flag = execute(value[0]+'='+quote+value[1]+quote)
      endif else if (nval_i gt 2) then begin
        where_par = (where(strlowcase(value[0]) eq inputpar))[0]        
        if (where_par ne -1) then begin
          flag = execute(value[0]+'='+quote+strjoin(value[1:*],'=')+quote)
        endif
      endif
   endfor
   set_plot,'NULL'
endif 

if (keyword_set(fnc)+keyword_set(fnm)+keyword_set(config_file) ne 3) then begin
    message,/INFO,'Call is:'
    print,'sdoss_hfc_processing, config_file, fnc, fnm, $'
    print,'                      output_dir=output_dir, data_dir=data_dir,$'
    print,'                      fnc_url=fnc_url, fnm_url=fnm_url, $'
    print,'                      /QUICKLOOK,/SNAPSHOT, $'
    print,'                      /DEBUG, /VERBOSE'
    return
endif
DEBUG = keyword_set(DEBUG)
VERBOSE = keyword_set(VERBOSE)
QLK = keyword_set(QUICKLOOK)
SNP = keyword_set(SNAPSHOT)

meta_dir=getenv('SDOSS_HFC_DIR')

cd,current=current_dir
if (not keyword_set(data_dir)) then data_dir=current_dir
if (not keyword_set(output_dir)) then output_dir=current_dir

outfnroot = 'sdoss_'+strjoin(strsplit(version,'.',/EXTRACT))

nfnc = n_elements(fnc)
nfnm = n_elements(fnm)
if (nfnc ne nfnm) then $
  message,'Numbers of input HMI Ic and M files must be the same!'
if (VERBOSE) then print,strtrim(nfnc,2)+' set(s) of HMI Ic/M files to process.'
;[1]:====================


;[2]:Load input parameters
;[2]:=====================
if (VERBOSE) then print,'Parsing '+config_file+'...'
if not (file_test(config_file)) then message,config_file+' does not exist!'
config_par=sdoss_hfc_parse_config(config_file)
if (size(config_par,/TNAME) ne 'STRUCT') then message,'Cannot read '+config_file+'!'
scf=config_par.scf
feat_min_area=config_par.feat_min_area
max_hg_long=config_par.max_hg_long
if (VERBOSE) then print,'Parsing '+config_file+'...done'

if (VERBOSE) then print,'Loading frc info metadata...'
frc_file=config_par.frc_info_file
if (meta_dir ne '') then frc_file=meta_dir+sep+'metadata'+sep+file_basename(frc_file)
if not (file_test(frc_file)) then message,frc_file+' does not exist!'
frc_info = sdoss_hfc_load_meta(frc_file,row=config_par.id_frc_info)
if (size(frc_info,/TNAME) ne 'STRUCT') then message,'Cannot read '+frc_file+'!'
if (VERBOSE) then print,'Loading frc info metadata...done'
file_copy,frc_file,output_dir,/REQUIRE_DIR,/OVERWRITE
if (VERBOSE) then print,frc_file+' copied in '+output_dir

if (VERBOSE) then print,'Loading observatory metadata...'
oby_file=config_par.observatory_file
if (meta_dir ne '') then oby_file=meta_dir+sep+'metadata'+sep+file_basename(oby_file)
if not (file_test(oby_file)) then message,oby_file+' does not exist!'
oby_info = sdoss_hfc_load_meta(oby_file,row=config_par.id_observatory) 
if (size(oby_info,/TNAME) ne 'STRUCT') then message,'Cannot read '+oby_file+'!'
if (VERBOSE) then print,'Loading observatory metadata...done'
file_copy,oby_file,output_dir,/REQUIRE_DIR,/OVERWRITE
if (VERBOSE) then print,oby_file+' copied in '+output_dir
;[2]:=====================


;[3]:Run sdoss_processing
;[3]:========================
if not (keyword_set(fnc_url)) then fnc_url=strarr(nfnc)
if not (keyword_set(fnm_url)) then fnm_url=strarr(nfnc)
for i=0l,nfnc-1l do begin

    ii=strtrim(nfnc-i,2)
    fnc_i=fnc[i] & fnm_i=fnm[i]
    if (VERBOSE) then print,'[#'+ii+']: Processing ['+fnc_i+'/'+fnm_i+'] data set...'

    fnc_i=strtrim(fnc[i],2) & fnm_i=strtrim(fnm[i],2)
    fnc_i_items=parse_url(strlowcase(fnc_i)) 
    fnm_i_items=parse_url(strlowcase(fnm_i))

    if (fnc_i_items.scheme eq 'http') or (fnc_i_items.scheme eq 'https') or $
        (fnc_i_items.scheme eq 'ftp') then begin
        if (VERBOSE) then print,'Downloading '+fnc_i+'...'
        spawn,'wget -nv -nc -t 3 -p '+data_dir+' '+quote+fnc_i+quote
        fnc_i_url = fnc_i
        fnc_i = data_dir+path_sep()+file_search(fnc_i)
    endif else fnc_i_url=fnc_url[i]

    if (fnm_i_items.scheme eq 'http') or (fnm_i_items.scheme eq 'https') or $
        (fnm_i_items.scheme eq 'ftp') then begin
        if (VERBOSE) then print,'Downloading '+fnm_i+'...'
        spawn,'wget -nv -nc -t 3 -p '+data_dir+' '+quote+fnm_i+quote
        fnm_i_url = fnm_i
        fnm_i = data_dir+path_sep()+file_basename(fnm_i)
   endif else fnm_i_url=fnm_url[i]
   
   syst0=systime(/SEC)
   if (VERBOSE) then print,'Running sdoss_processing for ['+fnc_i+'/'+fnm_i+'] data set...'

   sdoss_processing,fnc_i,fnm_i,feat_data_i,obs_data=obs_data_i, $
                     scf=scf,feat_min_area=feat_min_area, $
                     max_hg_long=max_hg_long, $
                     output_dir=output_dir, $
                     version=soft_version, $
                     nobs=nobs, nfeat=nfeat, $
                     QUICKLOOK=QLK,SNAPSHOT=SNP, $
                     VERBOSE=VERBOSE
    if (VERBOSE) then print,'Running sdoss_processing for ['+fnc_i+'/'+fnm_i+'] data set...done (took '+strtrim(long((systime(/SEC)-syst0)/60.0),2)+' min.).'

    if (soft_version ne version) then message,'ERROR - Please check software version!'

    if (nobs eq 0) then begin
        if (VERBOSE) then message,/CONT,'WARNING - ['+fnc_i+'/'+fnm_i+'] data set has not been processed correctly!'
        continue
    endif
  
    date_obs_i = strjoin(strsplit(obs_data_i.date_obs[0],'-:',/EXTRACT))
    if (VERBOSE) then print,'Writing output observation data file...'
    obs_data_i.observatory_id=config_par.id_observatory
    obs_data_i.url=[fnc_i_url,fnm_i_url]
    obs_file_i = output_dir+sep+outfnroot+'_'+date_obs_i+'_sdo_init.csv'
    hfc_write_csv,obs_data_i,obs_file_i,separator=';',/DOUBLE_QUOTES
   if not (file_test(obs_file_i)) then message,obs_file_i+' has not been saved correctly!'
   if (VERBOSE) then print,obs_file_i+' saved.'

   if (nfeat eq 0) then begin
      if (VERBOSE) then print,'No sunspot detected for ['+fnc_i+'/'+fnm_i+'] data set.'
      continue
   endif
   if (VERBOSE) then print,'Writing output feature data file...'
   feat_data_i.frc_info_id=config_par.id_frc_info
   feat_data_i.observations_id_ic=obs_data_i.id_observations[0] 
   feat_data_i.observations_id_m=obs_data_i.id_observations[1]
   feat_file_i = output_dir+sep+outfnroot+'_'+date_obs_i+'_sdo_feat.csv'
   hfc_write_csv,feat_data_i,feat_file_i,separator=';',/DOUBLE_QUOTES
   if not (file_test(feat_file_i)) then message,feat_file_i+' has not been saved correctly!'
   if (VERBOSE) then print,feat_file_i+' saved.'


   if (VERBOSE) then print,'[#'+ii+']: Processing ['+fnc_i+'/'+fnm_i+'] data set...done'
endfor
;[3]:========================

END

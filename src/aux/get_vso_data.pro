;+
; NAME:
;		get_vso_data
;
; PURPOSE:
; 		Use SSW routines from VSO package
;		to get data from data providers.
;		
;
; CATEGORY:
;		I/O
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL> get_vso_data,starttime,endtime
;
; INPUTS:
;		starttime - Scalar of string type containing the starting time (in ISO 8601 format) 
;				    of data to donwload.
;		endtime	  - Scalar of string type containing the ending time (in ISO 8601 format) 
;				    of data to download.
;
; OPTIONAL INPUTS:
;		instrument  - Name of the instrument for which data are required
;					  (see vso_search.pro header for more details).
;		physobs     - Name of the physical observation required
;					  (see vso_search.pro header for more details).	
;		sample		- Define the cadence of data (by default highest cadence).
;		provider	- Specify the data provider where data will be downloaded.
;		output_dir	- The full path name of directory where the data will be copied.
;					  Default is the current one.
;		retry		- Number of connection test in case of downloading failure.
;					  Default is 0. 
;		sleep		- Time to wait (in seconds) before retry connection in
;					  case of failure.
;					  Default is 0 seconds.
;					
; KEYWORD PARAMETERS: 
;		/RICE			- See vso_get header.
;		/URL			- See vso_search header.
;		/SILENT		    - Quiet mode.
;		
; OUTPUTS:
;		None.				
;
; OPTIONAL OUTPUTS:
;		meta      - Array of structures containing meta-data.
;		index     - Array of structures containing index of files.
;		filenames - List of files downloaded. 
;		error     - Equal to 1 if an error occurs, 0 otherwise.		
;		
; COMMON BLOCKS:
;		None.		
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS/COMMENTS:
;		The SolarSoft Ware (SSW) with vso, and ontology packages must be installed.
;		An internet access is required to download data.
;
; CALL:
;		vso_search
;		vso_get
;
; EXAMPLE:
;		None.
;		
; MODIFICATION HISTORY:
;		Written by:		X.Bonnin, 10-JUL-2011. 
;
;-

PRO get_vso_data,starttime,endtime,$
					instrument=instrument,$
					physobs=physobs,$
				    sample=sample,$
				    output_dir=output_dir,$
				    retry=retry,sleep=sleep,$
				    provider=provider,email=email,$
				    meta=meta,index=index,$
				    filenames=filenames,error=error,$
				    SILENT=SILENT,RICE=RICE,URL=URL

;[1]:Initializing 
;[1]:============
error = 1
launch_time = systime(/sec)
if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'IDL>get_vso_data,starttime,endtime, $'
	print,'                    sample=sample,$'
	print,'                    instrument=instrument,$'
	print,'                    physobs=physobs,$'
	print,'                    output_dir=output_dir,$'
	print,'                    retry=retry,sleep=sleep,$'
	print,'                    provider=provider,email=email,$'
	print,'                    meta=meta,index=index,$'
	print,'                    filenames=filenames,$' 
	print,'                    error=error,$'
	print,'                    /RICE,/URL,/SILENT'
	return
endif

tstart = strtrim(starttime[0],2)
tend = strtrim(endtime[0],2)
if (~valid_time(tstart)) then message,'Invalid format for the input parameter starttime!'	
if (~valid_time(tend)) then message,'Invalid format for the input parameter endtime!'

cd,current=current_dir
if (~keyword_set(data_dir)) then data_dir = current_dir
if (~keyword_set(output_dir)) then output_dir = current_dir

if (~keyword_set(retry)) then retry = 0
if (~keyword_set(sleep)) then sleep = 0

RICE = keyword_set(RICE)
URL = keyword_set(URL)
SILENT = keyword_set(SILENT)
;[1]:============


;[2]:Retrieving data
;[2]:===============
meta = 0b	
retry_i = 0
while (retry_i le retry) do begin
	if (~SILENT) then print,'Retrieving meta-data information from VSO between '+tstart+' and '+tend+'...'
	
	meta = vso_search(tstart,tend,instr=instrument,$
					  physobs=physobs,sample=sample,$
					  provider=provider,email=email,$
					  URL=URL)
	
	if (size(meta,/TYPE) ne 8) then begin
		if (~SILENT) then message,/CONT,'No data found! ['+strtrim(retry-retry_i,2)+']'
		retry_i++			
	endif else break
	wait,sleep
endwhile
if (retry_i gt retry) then return
nfile = n_elements(meta)
if (~SILENT) then print,strtrim(nfile,2)+' file(s) found.'
if (~SILENT) then print,'Retrieving meta-data information from VSO between '+tstart+' and '+tend+' OK'

;[2]:===============


;[3]:Downloading data
;[3]:================
filenames = ""
retry_i = 0
while (retry_i le retry) do begin
	if (~SILENT) then print,'Downloading file(s)...'
	index   = vso_get(meta,$
				   		out_dir=output_dir,$
				   		filenames=filenames,$
				   		provider=provider,$
				   		RICE=RICE)
	if (strtrim(filenames[0],2) eq "") then begin
		if (~SILENT) then message,/CONT,'No file downloaded! ['+strtrim(retry -retry_i,2)+']'
		retry_i++
	endif else break
	wait,sleep
endwhile
if (retry_i gt retry) then return				
if (~SILENT) then print,'Downloading file(s) OK'
;[3]:=============		

;print,'Program has ended correctly'
;print,'Elapsed time: '+strtrim(systime(/SEC)-launch_time,2)+' sec.'
;print,''
error = 0
END

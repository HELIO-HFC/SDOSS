FUNCTION sdoss_hfc_parse_config,config_file, $
                                error=error, $
                                SILENT=SILENT

;+
; NAME:
;		sdoss_hfc_parse_config
;
; PURPOSE:
; 	Read input parameters written in the
;		configuration file, and update info
;		structures.
;
; CATEGORY:
;		I/O
;
; GROUP:
;		SDOSS_HFC
;
; CALLING SEQUENCE:
;		IDL> config_par = sdoss_hfc_parse_config(config_file)
;
; INPUTS:
;		config_file - Full path name to the configuration file 
;                 containing the input parameters (scalar of string type).
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		/SILENT	- Quiet mode.
;
; OUTPUTS:
;		config_par - Structure containing the input parameters for SDOSS_HFC.
;                See sdoss_hfc_config__define.pro header for the list of
;                fields returned. 
;
; OPTIONAL OUTPUTS:
;		error - Equal to 1 if an error occurs, 0 otherwise.
;
; COMMON BLOCKS:
;		None.
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS/COMMENTS:
;		None. 
;	
; CALL:
;		sdoss_hfc_config__define		
;
; EXAMPLE:
;		None.
;
; MODIFICATION HISTORY:
;		Written by:		X.Bonnin, 19-FEB-2014.
;
;-

error = 1 & config_par=0b
if (n_params() lt 1) then begin
   message,/INFO,'Call is:'
   print,'config_par = sdoss_hfc_parse_config(config_file ,$'
   print,'                                    ,error=error,/SILENT)'
   return,''
endif

SILENT = keyword_set(SILENT)

in_file = strtrim(config_file[0],2)
if (~file_test(in_file)) then message,'ERROR: No input file found!'

config_par = {sdoss_hfc_config}
ntags = n_tags(config_par)
tags=strlowcase(tag_names(config_par))

ntag=0l
openr,lun,in_file,/GET_LUN
while (~eof(lun)) do begin
   data_i = ""
   readf,lun,data_i
   data_i=strtrim(data_i,2)
   if (strmid(data_i,0,1) eq '#') then continue
   data_i = strtrim(strsplit(data_i,'=',/EXTRACT),2)
   if (n_elements(data_i) ne 2) then continue
   tags_i = strlowcase(data_i[0])
   itag = (where(tags_i eq tags))[0]
   if (itag eq -1) then continue
   data_i = data_i[1]
   config_par.(itag) = strsplit(data_i,',',/EXTRACT)
   ntag++
endwhile
close,lun
free_lun,lun
if (ntag eq 0) then return,0

error = 0
return,config_par
END

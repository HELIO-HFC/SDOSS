FUNCTION sdoss_hfc_load_meta,metadata_file, $
                             row=row


;+
; NAME:
;		sdoss_hfc_load_meta
;
; PURPOSE:
; 		Loads HFC meta data
;     in csv format files. 
;              
;
; CATEGORY:
;		I/O
;
; GROUP:
;		SDOSS_HFC
;
; CALLING SEQUENCE:
;		IDL>metadata=sdoss_hfc_load_meta(metadata_file)
;
; INPUTS:
;	   metadata_file - Path and name of the metadata file to read
;	
; OPTIONAL INPUTS:
;		row - Number of the row data to return.
;           If not provided, then return all rows.   
;
; KEYWORD PARAMETERS:
;    None.
;
; OUTPUTS:
;		metadata - Structure containing loaded metadata.
;
; OPTIONAL OUTPUTS:
;		None.
;		
; COMMON BLOCKS:		
;		None.	
;	
; SIDE EFFECTS:
;		None.
;		
; RESTRICTIONS/COMMENTS:
;     None.		
;			
; CALL:
;     None.
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin.			
;				
;-


;[1]:Initialize the program
;[1]:======================
metadata=0b
quote=string(39b)
if not (keyword_set(metadata_file)) then begin
   message,/INFO,'Usage:'
   print,'metadata=sdoss_hfc_load_meta(metadata_file,$'
   print,'                             row_id=row_id)'
   return,0b
endif

if not (file_test(metadata_file)) then $
   message,metadata_file+' does not exist!'

nlines=file_lines(metadata_file)-1

openr,lun,metadata_file,/GET_LUN
header=''
readf,lun,header
tags=strsplit(header,';',/EXTRACT)
ntags=n_elements(tags)
ival=quote+' '+quote
stc='{'+strtrim(tags[0],2)+':'+ival
for i=0,ntags-2 do stc=stc+','+strtrim(tags[i+1],2)+':'+ival
stc=stc+'}'

flag=execute('meta_struct='+stc)
metadata=replicate(meta_struct,nlines)
for i=0,nlines-1 do begin
   row_i=''
   readf,lun,row_i
   row_i=strsplit(row_i,';',/EXTRACT)
   nrow_i=n_elements(row_i)
   if (nrow_i ne ntags) then $
      message,'Number of columns is wrong!'
   for j=0,nrow_i-1 do metadata[i].(j)=row_i[j]
endfor
close,lun
free_lun,lun

if (keyword_set(row)) then begin
   nrow=n_elements(row)
   md=replicate(meta_struct,nrow)
   for i=0,nrow-1 do md[i]=metadata[row[i]-1]
   metadata=md
endif

return,metadata
END

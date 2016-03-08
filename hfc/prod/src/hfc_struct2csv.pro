FUNCTION hfc_struct2csv,struct, $
                        header=header,$
                        separator=separator, $
                        error=error, $
                        QUOTES=QUOTES, $
                        DOUBLE_QUOTES=DOUBLE_QUOTES

;+
; NAME:
;       hfc_struct2csv
;
; PURPOSE:
;       Convert the input structure into
;       a scalar or array of string type,
;       where values are separated using 
;       semi colon (;).
;
; CATEGORY:
;       I/O
;
; GROUP:
;       HFC
;
; CALLING SEQUENCE:
;       IDL>string_out = hfc_struct2csv(struct) 
;
; INPUTS:
;       struct - structure to convert.      
;   
; OPTIONAL INPUTS:
;       separator - Specify a separator character between fields.
;                   Default is ";".
;
; KEYWORD PARAMETERS:
;       /QUOTES         - If set, add quotes to fields which contain one 
;                         or more separator characters.
;       /DOUBLE_QUOTES  - If set, add double quotes to fields which contain one 
;                         or more separator characters.
;
; OUTPUTS:
;       string_out - Scalar or array of string type containing
;                    the structure values separated by semi-colon
;                    characters.
;       
; OPTIONAL OUTPUTS:
;       header - Scalar of string type containing 
;                the name of the input structure tags.
;                (As for string_out, names are separated by semi-colons.)  
;       error  - Equal to 1 if an error occurs, 0 else.
;       
; COMMON BLOCKS:        
;       None.   
;   
; SIDE EFFECTS:
;       None.
;       
; RESTRICTIONS/COMMENTS:
;       None.
;       
; CALL:
;       None.
;
; EXAMPLE:
;       None.       
;
; MODIFICATION HISTORY:
;       Written by X.Bonnin, 28-OCT-2011.
;
;       28-FEB-2014, X.Bonnin:  Add /QUOTES and /DOUBLE_QUOTES
;                               keyword parameters.
;                                   
;-

dqte=string(34b)
qte=string(39b)

error = 1
if (n_params() lt 1) then begin
    message,/INFO,'Call is:'
    print,'string_out = hfc_struct2csv(struct,header=header,separator=separator,error=error, $'
    print,'                            /QUOTES, /DOUBLE_QUOTES)'
    return,'' 
endif
DQUOTES=keyword_set(DOUBLE_QUOTES)
QUOTES=keyword_set(QUOTES)
if (DQUOTES) then QUOTES=0

if not (keyword_set(separator)) then sep = ';' else sep = strtrim(separator[0],2)

header = strjoin(strupcase(tag_names(struct)),sep)

ncol = n_elements(struct[0].(0))
nstc = n_elements(struct)
ntags = n_tags(struct)
tags = tag_names(struct)

nrow = ncol+nstc
string_out = strarr(nrow)
ii=0l
for k=0l,ncol-1l do begin
    for i=0l,nstc-1l do begin
        string_out_i = ''
        for j=0,ntags-1 do begin
            val_i = strtrim(struct[i].(j)[k],2)
            if (val_i eq "") then val_i = "NULL"
            if (strpos(val_i,sep) ne -1) then begin
                case 1 of
                    QUOTES:val_i=qte+val_i+qte
                    DQUOTES:val_i=dqte+val_i+dqte
                    else:
                endcase
            endif
            string_out_i = string_out_i + val_i + sep
        endfor
        string_out[ii] = strmid(string_out_i,0,strlen(string_out_i)-1)
        ii++
    endfor
endfor

error = 0
return,string_out
END
;+
; NAME:
;		feat_cc_extract
;
; PURPOSE:
; 		Create a structure from its chaincode.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>Result = feat_cc_extract(chain,pos)
;
; INPUTS:
;		chain	- chaincode.
;		pos		- position of the first pixel.
;	
; OPTIONAL INPUTS:
;		None.
; KEYWORD PARAMETERS:
;		None.
; OUTPUTS:
;		structure - array which contains the structure coordinates. 		
;
; OPTIONAL OUTPUTS:
;		None.
; COMMON BLOCKS:
;		None.
; SIDE EFFECTS:
;		None.
; RESTRICTIONS:
;		None.
; CALL:
;		feat_cc_convert		
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by:		Morgan Fouesneau, Maud Galametz, François Gonon, Antonin Maire, 01-JUN-2006.
;
;		10-JUN-2010,    X.Bonnin:	Increased the character number readable in chain parameter by 
;								    the procedure reads (300->strlen(chain)).
;								    Added a test on the chain parameter size.
;		23-JUN-2010,    X.Bonnin:	Removed taille input parameter. 
;								    The chain length is directly computed from strlen(chain)
;		07-JUN-2011,    X.Bonnin:   create_structure was renamed to feat_cc_extract
;		
;-

FUNCTION feat_cc_extract, chain, position_init

if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'Results = feat_cc_extract(chain,position_init)'
	return,0.
endif

;Get the chain parameter size
taille = strlen(strtrim(chain,2))

; reading the chaincode into an array
chain_array=bytarr(taille)		; begin from 0 to taille-1 
reads, chain, chain_array, format='('+strtrim(taille,2)+'(I1))'

; transcription chaincode to coord. in an array
structure=fltarr(2,taille+1)
structure(*,0)=position_init
for i=0,taille-1 do begin
	structure(*,i+1)=structure(*,i)+feat_cc_convert(chain_array(i))
endfor

return, structure

END
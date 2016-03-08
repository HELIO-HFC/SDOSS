;+
; NAME:
;		feat_cc_convert
;
; PURPOSE:
; 		Converts a chain code into its corresponding vector direction.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>direction = feat_cc_convert(chain_num)
;
; INPUTS:
;		chain_num	- chaincode. 
;	
; OPTIONAL INPUTS:
;		None.
; KEYWORD PARAMETERS:
;		None.
; OUTPUTS:
;		direction - Corresponding vector direction. 		
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
;		None.
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by:		Morgan Fouesneau, Maud Galametz, François Gonon, Antonin Maire, 01-JUN-2006.
;
;		03-JUN-2010, X.Bonnin:	Added 'else:return,[0,0]' case.
;		07-JUN-2011, X.Bonnin:	conv_chain was renamed to feat_cc_convert.
;-


FUNCTION feat_cc_convert, chain_num

if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'direction = feat_cc_convert(chain_num)'
	return,[0,0]
endif

case chain_num of
	0: direction=[-1,0]
	1: direction=[-1,-1]
	2: direction=[0,-1]
	3: direction=[1,-1]
	4: direction=[1,0]
	5: direction=[1,1]
	6: direction=[0,1]
	7: direction=[-1,1]
	else:return,[0,0]
endcase
	
return, direction
END

FUNCTION feat_rs_extract,rs,br,pixval=pixval,$
			       CODE=CODE,error=error

;+
; NAME:
;		feat_rs_extract
;
; PURPOSE:
; 		Return a 2d sub-array containing 
;		the pixels values of the input raster scan.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>map = feat_rs_extract(rs,br)
;
; INPUTS:
;		rs	- Scalar of string type containing the raster scan.
;		br  - 4 elements vector [X0,Y0,X3,Y3] specifying the pixel coordinates 
;			  of the lower left [X0,Y0] and upper right [X3,Y3] corners of the
;			  feature bounding rectangle
;			  
; OPTIONAL INPUTS:
;		pixval - Scalar of integer type specifying the value of pixels
;				 to extract from the raster scan.
;	
;
; KEYWORD PARAMETERS:
;		/CODE	- Usinge RLE convention. 
;
; OUTPUTS:
;		map	- 2d sub-array containing the raster scan pixels' values.		
;
; OPTIONAL OUTPUTS:
;		pixval    - Vector containing the raster scan pixel value(s).
;		error     - Equal to 1 if an error occurs, 0 else.
;
; COMMON BLOCKS:
;		None.
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS:
;		None.
;
; CALL:
;		None.		
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by:		X.Bonnin, 08-JUN-2011.
;		23-MAY-2011, X.Bonnin:	Add /CODE optional keyword.
;							    Output is now a 2d array containing 
;								pixels with raster scan values. 
;

error = 1
if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'pixels = feat_rs_extract(rs,br,pixval=pixval,error=error,/CODE)'
	return,0
endif

CODE = keyword_set(CODE)

if (n_elements(br) ne 4) then begin
	message,/INFO,'input argument br must a 4 elements vector!'
	return,0
endif

rscan = strtrim(rs[0],2)
if (CODE) then begin
	rscan = strsplit(rscan,'.:',/EXTRACT)
	new_rscan = '' & value = -1
	for i=0l,n_elements(rscan)-1l do begin
		npix = long(strmid(rscan[i],1))
		value_i = strmid(rscan[i],0,1)
		value = [value,value_i]
		new_rscan = new_rscan + strjoin(value_i + strarr(npix))
	endfor
	if (n_elements(value) gt 1) then value = value[1:*] else return,-1
	pixval = value[uniq(value,sort(value))]
	rscan = new_rscan
	new_rscan = 0b
endif

; reading the raster scan into a vector
n = strlen(rscan)
map=intarr(n)		; begin from 0 to taille-1 
reads, rscan, map, format='('+strtrim(n,2)+'(I1))'

;Numbers of pixels along X (nX) and Y (nY) axis in the bounding rectangle
nX = br[2] - br[0] + 1
nY = br[3] - br[1] + 1
map = reform(map,nX,nY)

error = 0
return,map
END

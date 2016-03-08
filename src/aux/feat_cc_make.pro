;+
; NAME:
;		feat_cc_make
;
; PURPOSE:
; 		Make the chain code of a closed contour 
;		in the input binary mask.
;
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>chaincode = feat_cc_make(mask)
;
; INPUTS:
;		mask	- 2d array containing the contour for which the chain
;				  code is produced.
;	
; OPTIONAL INPUTS:
;		End_pix - Vector containing the position [X,Y] in pixel
;			   	   at which the computation must be stopped.
;			   	   (by default, the computation stops when the 
;			    	   first pixel is encountered).
;		npix	- Number of pixels of the contour.
;				  (If the number of iterations exceeds this value,
;				   then returns an error.)
;
; KEYWORD PARAMETERS:
;		None.
;
; OUTPUTS:
;		chaincode - scalar of string type containing the chain code. 		
;
; OPTIONAL OUTPUTS:
;		Start_pix - Returns a vector with the position [X,Y] of the
;				    starting pixel.
;		X         - Vector containing the chain code pixels coordinates along X-axis.
;		Y         - Vector containing the chain code pixels coordinates along Y-axis. 
;		Error	  - Equal to 1 if an error occurs, 0 else.
;		
; COMMON BLOCKS:
;		None.
; SIDE EFFECTS:
;		None.
; RESTRICTIONS:
;		None.
; CALL:
;		None.	
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by:		X.bonnin, 18-MAY-2011.
;		30-JUN-2011,    X.Bonnin:	Added optional input npix and 
;								    optional output error. 
;
;-

FUNCTION feat_cc_make, mask,$
				       end_pix=end_pix,$
				       start_pix=start_pix,$
				       X=X,Y=Y,$
				       npix=npix,error=error
				  
error = 1
if (~keyword_set(mask)) then begin
	message,/INFO,'Call is:'
	print,'chaincode = feat_cc_make(mask,end_pix=end_pix,start_pix=start_pix,$'
	print,'                         X=X,Y=Y,npix=npix,error=error)'
	return,''
endif

n = size(mask,/DIM)
if (n_elements(n) ne 2) then begin
	message,'mask input parameter must have 2D dimensions!'
	return,''
endif
nx = n[0] & ny = n[1]

;Chain code information
Vx0 = [-1L,-1L,0L,+1L,+1,+1L,0L,-1L]
Vy0 = [0L,+1L,+1L,+1L,0L,-1L,-1L,-1L]
Vcc = transpose([[Vx0],[Vy0]])
chain0 = [0,7,6,5,4,3,2,1]
ncc = 8

;Create a binary mask of the 2D contour
msk = fix(mask ne 0)

;Look for the starting pixel 
;(must be the uppermost,leftmost one)
w1 = where(msk ne 0)
if (w1[0] eq -1) then return,''
ipix = array_indices(msk,w1)
ipix = ipix[*,sort(ipix[0,*])]
Y0 = max(ipix[1,*],ix) 
X0 = ipix[0,ix]

start_pix = [X0,Y0]

if (~keyword_set(end_pix)) then begin
	X1 = X0
	Y1 = Y0
endif else begin
	X1 = end_pix[0]
	Y1 = end_pix[1]
endelse


;Initialize output variables
ccode = '' & chain = chain0
Vx = reform(Vcc[0,*]) & Vy = reform(Vcc[1,*])
	
;Generate chain code
Niter = 0L
bi = -1L & bj = -1L
while (bi ne x1) or (bj ne y1) do begin
	;Initialize chain code
	if (bi eq -1L) and (bj eq -1L) then begin
		bi = x0
		bj = y0
		X = X0 
		Y = Y0
	endif

	;Search the first pixel msk[ci,cj]=1 in 8-neighbors of msk[bi,bj] pixel
	pix = 0 & j = -1L
	while pix ne 1 do begin
		j = j + 1L
		if (j eq ncc) then break
		ci = bi + Vx[j] & cj = bj + Vy[j]
		if (ci lt 0L) or (ci gt nx-1L) then continue
		if (cj lt 0L) or (cj gt ny-1L) then continue
		pix = msk[ci,cj]
	endwhile
	if (pix ne 1) then break
	
	;Store the pixel msk[ci,cj]=1	
	ccode = ccode+strtrim(chain[j],2)
	X = [X,ci] & Y = [Y,cj]


	;Shift direction and chain code vectors to start with the (background) point immediately preceding msk[ci,cj]=1 
	ci0 = bi + Vx[j-1] & cj0 = bj + Vy[j-1]
	i0 = where(Vx0 eq (ci0-ci) and Vy0 eq (cj-cj0))
	Vx = shift(Vx0,i0) & Vy = shift(Vy0,i0)
	chain = shift(chain0,i0)

	;... And centered next sequence on this new pixel
	bi = ci & bj = cj	

	Niter = Niter + 1L
	if (keyword_set(Npix)) then if (Niter gt Npix) then return,''
endwhile
chaincode = strtrim(ccode,2)

error = 0
return,chaincode
END
FUNCTION sdoss_getchaincode, locs, xx, nx, ny, xc, yc, cdx, cdy, $
							 cc_pix=cc_pix, ad=ad, DEBUG=DEBUG

;+
; NAME:
;		sdoss_getchaincode
;
; PURPOSE:
; 		This routine generates the chain code of the current detected sunspot.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		SDOSS
;
; CALLING SEQUENCE:
;		cc_arc = sdoss_getchaincode( locs, xx, nx, ny, xc, yc, cdx, cdy)
;
; INPUTS:
;		locs - Pixels of the current sunspot.
;		xx   - Bounding rectangle of the current sunspot
;			   [xmin,ymin,xmax,ymax].
;		nx   - Number of pixels along X axis in image.
;		ny   - Number of pixels along Y axis in image.
;		xc	 - X coordinate of the Sun center in pixel.
;		yc   - Y coordinate of the Sun center in pixel.
;		cdx  - Spatial scale along X axis (in arcsec/pix).
;		cdy  - Spatial scale along Y axis (in arcsec/pix).
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		/DEBUG	- Debug mode. 	
;
; OUTPUTS:
;		cc_arc  - Coordinates of the chain code pixels (in arcsec) 	
;
; OPTIONAL OUTPUTS:
;		cc_pix	- Coordinates of the chain code in pixels
;		ad		- Scalar of string type containing the chain code.
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
;		get_chaincode
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by S.Zharkov (MSSL).
;
;		18-JUL-2011, X.Bonnin:	Added ad optional output parameter.
;		
;
;-

;self->getbndrct, x0, y0, x1, y1, arc=arc

x0=xx(0) & y0=xx(1) & x1=xx(2) & y1=xx(3)

dlt=5
nx0=x1-x0+1
ny0=y1-y0+1

nx1=nx0+2*dlt
ny1=ny0+2*dlt

imb=bytarr(nx, ny)
imb[locs]=1

imc=imb[x0:x1, y0:y1]
imc1=imb[x0-dlt : x1+dlt, y0-dlt : y1+dlt]

in=size(imc1)
nx0=in(1) & ny0=in(2)

imc=imc1 & imc(*)=0

;imc2=congrid(imc1, nx0*2, ny0*2)
get_chaincode, imc1, ccode=ccode, ad=ad

;ad = feat_cc_make(imc1,start_pix=start_pix,X=X,Y=Y)
;ccode = lonarr(2,n_elements(X))
;ccode(0,*) = X & ccode(1,*) = Y

nl=n_elements(ccode(0, *))
code = ccode

cc_pix = lonarr(2, nl)
cc_pix(0,*)=ccode(0, *)-dlt+x0
cc_pix(1,*)=ccode(1, *)-dlt+y0

cc_arc=dblarr(2, nl)
cc_arc(0, *)=(cc_pix(0,*)-xc)*cdx;/2
cc_arc(1, *)=(cc_pix(1,*)-yc)*cdy;/2

if keyword_set(DEBUG) then begin
	xmin = min(cc_arc(0,*),max=xmax)
	ymin = min(cc_arc(1,*),max=ymax)
	loadct,0,/SILENT
	tvframe, imc1, /bar, $
		xr=[xmin-(dlt)*cdx, xmax+(dlt+1/2.)*cdx], $
    	yr=[ymin-(dlt)*cdy, ymax+(dlt+1/2.)*cdy]
    loadct,39,/SILENT
  	oplot, cc_arc(0, *), cc_arc(1, *), col=100, th=2
  	stop
endif

return, cc_arc
END

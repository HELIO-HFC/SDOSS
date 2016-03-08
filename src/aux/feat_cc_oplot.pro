;+
;NAME:
;		feat_cc_oplot
;
;PURPOSE:
;		Overplot features on an image, using their chain code.
;
;CALLING SEQUENCE:
;		IDL>feat_cc_oplot,cc,cc_x_pix,cc_y_pix
;
;INPUTS:
;		cc       - Scalar or vector of string type containing the chain code(s).
;		cc_x_pix - Scalar or vector of long type containing the first coding position(s) (in pixels) 
;				   of the chain code(s) along the X axis.
;		cc_y_pix - Scalar or vector of long type containing the first coding position(s) (in pixels) 
;				   of the chain code(s) along the Y axis.
;
;OPTIONAL INPUTS:
;		cdelt1 - Scalar containing the spatial scale along X axis. 
;		cdelt2 - Scalar containing the spatial scale along Y axis.
;		crpix1 - Scalar containing the image center along X axis (in pixels).
;		crpix2 - Scalar containing the image center along Y axis (in pixels).
;		thick  - Scalar containing the value of the thickness to plot.
;		color  - Scalar or vector containing the color index(es) of overplotted feature(s).
;
;KEYWORD PARAMETERS:
;		None.
;
;OUTPUTS:
;		None.
;
;OPTIONAL OUTPUTS:
;		None.
;
;RESTRICTIONS/COMMENTS:
;		None.
;
;CALL:
;		feat_cc_extract
;
;EXAMPLES:
;		None.
;
;HISTORY:
;		Written by:		X.Bonnin, 09-JUL-2010.
;
;-

PRO feat_cc_oplot,cc,cc_x_pix,cc_y_pix,$
				  cdelt1=cdelt1,cdelt2=cdelt2,$
				  crpix1=crpix1,crpix2=crpix2,$
				  color=color,thick=thick,_EXTRA=EXTRA


;[1]:Initialize the input parameters
;[1]:===============================
;On_error,2
if (n_params() lt 3) then begin
	message,/INFO,'Call is:'
	print,'hfc_oplot_feat,cc,cc_x_pix,cc_y_pix,$'
	print,'               cdelt1=cdelt1,cdelt2=cdelt2,$'
	print,'               crpix1=crpix1,crpix2=crpix2,$'
	print,'               color=color,thick=thick,_EXTRA=EXTRA'
	return
endif

nfeat = n_elements(cc)

if (~keyword_set(cdelt1)) then cdelt1 = 1
if (~keyword_set(cdelt2)) then cdelt2 = 1
if (~keyword_set(crpix1)) then crpix1 = 0
if (~keyword_set(crpix2)) then crpix2 = 0
if (keyword_set(color)) then col = fix(color) + intarr(nfeat)

;overplots in the current Window
wid = !D.window
if (!D.NAME ne 'PS') then begin
	if (wid eq -1) then message,'No window open!' else wset,wid
endif
;[1]:===============================

;[2];Overplot features
;[2];=======================				
for i=0L,nfeat-1L do begin
	if (strlen(strtrim(cc[i],2)) eq 0) then continue
	cc_i = feat_cc_extract(cc[i],[cc_x_pix[i],cc_y_pix[i]]) 
	X_i = cdelt1[0]*(reform(cc_i[0,*]) - crpix1[0])
	Y_i = cdelt2[0]*(reform(cc_i[1,*]) - crpix2[0])
	if (keyword_set(col)) then col_i = col[i]
	Xmin = min(X_i,max=Xmax,/NAN)
	Ymin = min(Y_i,max=Ymax,/NAN)
	if (Xmax le !X.crange[0]) or (Xmin ge !X.crange[1]) then continue
	if (Ymax le !Y.crange[0]) or (Ymin ge !Y.crange[1]) then continue
			
	oplot,X_i,Y_i,color=col_i,thick=thick,_EXTRA=EXTRA
endfor
;[2];=======================

END
function WL_DetSpGS_sdo, image, nx, ny, xc, yc, Radius, qsint, $
				no_show=no_show, threshold=threshold, cent=cent, scale=scale, $
				nogs=nogs, sbl=sbl, one=one, display=display, show=show, $
                error=error

;	PROCEDURE:
;		detecting and analyzing/classifying sunspots for MDI
;		white light dopplergrums combined with magnetograms
;
;
;	INPUTS:
;		image		a preprocessed (flat) 'white light' image
;					(SOHO/MDI continuum IntensityGram)
;		nx, ny		image size parameters
;		xc, yc		Solar disk centre pixel coordinates
;		Radius		Solar disk radius
;
;	KEYWORDS:
;
;		/no_show	do not display results
;		/nogs		do not use gaussian smoothing prior to edge
;					detection
;		/sbl		use Sobel edge detection
;					(as opposed to morphological gradient)
;
;   OPTIONAL OUTPUTS:
;       error       Equal to 1 if an error occurs, 0 otherwise.
;
;	OPTIONAL PARAMETERS:
;
;		threshold
;		cent
;
;   MODIFICATION HISTORY:
;       Written by S.Zharkov.
;
;       06-JAN-2012, X.Bonnin: Added error optional output.
;
;

error=1

sbl=1
;if not keyword_set(fn) then WL_ReadInData, image, nx, ny, xc, yc, Radius, qsint, imdi, bimdi, wls, mdate $
; else WL_ReadInData, image, nx, ny, xc, yc, Radius, qsint, imdi, bimdi, wls, mdate, fn=fn
image1=image
XSIZE=800
YSIZE=600


binary=WL_Morphological4_sdo(alog(image+qsint), xc, yc, Radius, $
			threshold=threshold, cent=cent,  /sbl, edges=edges, show=show, scale=scale, qsint=alog(2*qsint),$
            error=error_bin)
if (error_bin) then return,0
;stop


WL_AnalyseBinary_sdo, image/qsint, binary, n, plocs, moms

binx=binary

imageResult=intarr(nx, ny)
imageResult2=intarr(nx, ny)
for i=0, n-1 do begin
	WL_RegProcess_sdo, image/qsint, *plocs[i], moms[i, *], qsint/qsint, imageResult, imageResult2, error=error_i;, /display
    if (error_i) then return,0
endfor

lres=where(imageResult ne 0)
lres2=where(imageResult2 ne 0)

binary=bytarr(nx, ny)
if keyword_set(one) then binary(lres)=1 else $
			if lres2[0] ne -1 then binary(lres2)=1



imageumbra=WL_DetectUmbra_sdo (image/qsint, binary, imdi, bimdi, nx, ny, qsint/qsint, scale=scale)

;stop
lumb=where(imageumbra ne 0)
image_copy=image
;image_copy[lres]=0;max(image)
image_copy[lres]=image[lres]*2

image_copy2=image
if lres2[0] ne -1 then begin
	image_copy2[lres2]=image[lres2]*2
	image_copy2[lres2]=max(image)
endif
if lumb[0] ne -1 then image_copy2[lumb]=min(image)

;stop


if not keyword_set(no_show) then begin

	;	window, 13, xs=nx, ys=ny;, title='Detected Sunspots'
	;	tvscl, image_copy2

	;	window, 21, xs=nx, ys=ny;, title='Magnetogram with Sunspots superimposed'
	;	tvscl, image_copy

		xxx=imageumbra+binary

		N=500
			for i=0, N-1 do begin
				xi=xc+Radius*cos((2*!pi/N)*i)
				yi=yc+Radius*sin((2*!pi/N)*i)

				xxx[fix(xi+.5), fix(yi+.5)]=max(xxx)
			end
;		window, 23, xs=XSIZE, ys=YSIZE ;; xs=nx, ys=ny;, title='Umbras'
;		tvframe, xxx, /asp
		;tvscl, xxx


;stop
endif
detected=imageumbra+binary

error = 0
image=image1
return, detected
end


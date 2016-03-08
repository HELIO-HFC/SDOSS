;========================================================================================

function WL_Morphological4_sdo, CleanedImage, xc, yc, R, scale=scale, $
				threshold=threshold, cent=cent, sbl=sbl, edges=edges, show=show, qsint=qsint, $
                error=error, VERBOSE=VERBOSE

if not keyword_set(qsint) then qsint=getquietsunint(cleanedimage)
if not keyword_set(scale) then scale=4
error = 1
sbl=1
;	**********************************
;		 MORPHOLOGICAL METHOD
;	**********************************


; FUNCTION
;		from CleanedImage the regions with sunspots are found
;
;	INPUT
;			CleanedImage		white light 'flat' image
;			xc, yc, R			disk centre coordinates and radius
;
;	OUTPUT
;			binary2				binary image with ROI marked
;
;   MODIFICATION HISTORY:
;       Written by S.Zharkov.
;
;       06-JAN-2012, X.Bonnin: Added error optional output.
;							   Added /VERBOSE optional keyword.
;
;




;***********************************
;
;	Define inside the disk pixels
;

VERBOSE = keyword_set(VERBOSE)

roffset=15*scale
			info=size(CleanedImage)
			pix_x=findgen(info[1])-xc
			pix_y=findgen(info[2])-yc

      xa=pix_x#(pix_y*0+1)
      ya=(pix_x*0+1)#pix_y

	;		inDiskMask=bytarr(info[1], info[2])
	;		l0=where(CleanedImage eq 0, complement=lc0)
	;		x0=double(lc0 mod info[1]) - xc
	;		y0=double(lc0 / info[1]) -yc
			
			dist2=(xa*xa+ya*ya)

			insideDisk=where(dist2 lt (R-roffset)*(R-roffset), comp=offlimbplus)
            if (offlimbplus[0] eq -1) then return,0
	;		inDiskMask[insideDisk]=1
	;		OffLimbPlus=where(inDiskMask eq 0)
		;	stop


;============================================================


info=size(CleanedImage)
nx=info[1]


areapix=!pi*R*R

median_BoxSize=scale*3


      edgemap=alog(1.d-10+sobel(cleanedimage))
      edgemap(offlimbplus)=min(edgemap)
      edgemap=edgemap-min(edgemap)
      
      hh=histogram(edgemap, loc=xx, nbin=nx*5)
      mv=max(hh(1:*), loc) & vv=xx(loc(0)+1)
      
    
			threshold=vv
			binxxx=edgemap gt threshold

			count=0
			thrx=threshold

			tmp=label_region(median(edgemap gt thrx, median_BoxSize), /ulong)
			ncand=max(tmp)
			areacoef=1
			while (ncand gt 200 or areacoef gt 0.7) $
						and count lt 100 do begin

				xim=median(edgemap gt thrx, median_BoxSize)
		;
				xim[OffLimbPLus]=0
		;		stop
				locs=where(xim ne 0, npx)
				areacoef=npx / areapix

				tmp=label_region(xim, /ulong)
				ncand=max(tmp)
				if areacoef gt .5 then thrx=thrx*1.01 else $
					if areacoef gt .1 then thrx=thrx*1.005 $
						else thrx=thrx*1.001
				count=count+1
			end
		;	stop
			if (VERBOSE) then print, 'Determined Threshold:', thrx
			binary=median(edgemap gt thrx, median_BoxSize)
;			stop

			int_thrx=.91
			int_ncand=100l*scale
			count=0
			indisk_locs=where(cleanedimage eq 0)
			while ((int_ncand gt 50*scale) and (count lt 80)) do begin
				int_thrx=int_thrx-.001
				xim2=cleanedimage lt int_thrx*qsint
				xim2[OffLimbPLus]=0
				int_ncand=max(label_region(xim2, /ulong))
				count=count+1
			endwhile
			lowintensitypix=where(xim2 ne 0)
			if lowintensitypix[0] ne -1 then binary[lowintensitypix]=1
	;		stop
			if keyword_set(show) and keyword_set(sbl) then begin
				window, 15, xs=800, ys=600
				tvframe, binary, /bar, /asp
			end
  ;stop
			binary=RemLimbBinary(binary, xc, yc, R-1, nx)
			
if keyword_set(sbl) then begin
	temp00=binary
	temp00=morph_close(binary, replicate(1, 7, 7))
	temp= ((watershed(temp00) gt 1) + temp00) ge 1
	edges=sobel(temp)
	
end


;temporary stuff

im=cleanedimage
im2=cleanedimage
locs2=where(temp ne 0)
if (locs2[0] eq -1) then return,0
locs=where(edges ne 0)
if (locs[0] eq -1) then return,0
im[locs]=max(im)
im2[locs2]=im2[locs2]/2


ex1=edges
N=5000
;for i0=0, N-1 do $
;	ex1[fix(xc+R*sin(i0*2*!pi/N)+.5), $
;		fix(yc+R*cos(i0*2*!pi/N)+.5)]=max(edges)
if keyword_set(show) and keyword_set(sbl) then begin


		window, 10, xs=800, ys=600
		tvframe, binxxx, /bar, /asp

		window, 11, xs=800, ys=600
		tvframe, im2, /bar, /asp

		window, 12, xs=800, ys=600
		tvframe, temp, /bar, /asp

		window, 13, xs=800, ys=600
		tvframe, ex1, /bar, /asp

stop
end

;stop
binary2=temp

binary2=dilate(binary2, replicate(1, scale*7, scale*7))
error = 0
return, binary2


end

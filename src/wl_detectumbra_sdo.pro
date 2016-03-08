function WL_DetectUmbra_sdo, image, binary, imdi, bimdi, nx, ny, qsint, scale=scale

if not keyword_set(scale) then scale=4
LRIM=label_region(binary)
hlrm=histogram(LRIM, reverse_indices=r)

Rnum=n_elements(hlrm)-1
;print, 'Number of Sunspots on the Image:', Rnum


imageUmbra=bytarr(nx, ny)
for i=1, Rnum do begin

	plocs=r(r[i]:r[i+1]-1)
	area=n_elements(plocs)
	
	xpos=plocs mod nx
	ypos=plocs / nx

	xmin=min(xpos)
	xmax=max(xpos)
	ymin=min(ypos)
	ymax=max(ypos)
	nxc=xmax-xmin+1
	nyc=ymax-ymin+1

	sc=10
	imdis1=fltarr(nx, ny)
	imdis1[*, *]=-1
	imdis1[plocs]=image[plocs]
	im_dis=imdis1[xmin:xmax, ymin:ymax]

	if area gt 5 then begin
		bin_umbra=bytarr(nxc, nyc)
		mom=moment(image[plocs], mdev=mdev)
;		print, 'quiet sun int:', qsint
;		print, 'mean:', mom[0]
;		print, 'st dev:', sqrt(mom[1])
;		print, 'mean abs dev:', mdev


		if min(image[plocs]) lt .7*Qsint then begin

				Threshold=mom[0]-.85*sqrt(mom[1]) > .59*Qsint
				xl=where(im_dis ge 0 and im_dis lt Threshold)

				if xl[0] ne -1 then	imageumbra[(xl mod nxc)+xmin, (xl / nxc) + ymin]=1
				endif ;else print, 'No Umbra in this spot'
	endif else begin
			xl=where(image[plocs] lt .6*qsint)
			if xl[0] ne -1 then begin
				imageumbra[plocs[xl]]=1
			;	print, 'Small Sunspot, umbra detected'
			endif
		endelse
;	stop, im_dis
end

;

return, imageumbra
end
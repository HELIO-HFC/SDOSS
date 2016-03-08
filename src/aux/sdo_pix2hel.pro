function sdo_pix2hel, date, locs, xc, yc, cdx, cdy, nx, ny,$
        res=res, image=image, display=display, area=area, diameter=diameter

origin='soho'

; set the desired resolution (degree/pixel)
if not keyword_set(res) then res=.1


if not keyword_set(image) then begin
  image=bytarr(nx, ny)
  image[locs]=1
end

;if keyword_set(area) then begin
  arearr=bytarr(nx, ny)
  arearr[locs]=1
;endif

; calculate feature's pixels coordinates
xp=locs mod nx
yp=locs / nx

; transfer to arcseconds
ax=(xp-xc)*cdx/60.d00
ay=(yp-yc)*cdy/60.d00

clon=tim2carr(date)

case origin of

'soho':   hel1=arcmin2hel(ax, ay, date=date, /soho)
'ground': hel1=arcmin2hel(ax, ay, date=date)

endcase

maxlat= max(hel1[0, *])+1
minlat= min(hel1[0, *])-1
maxlon= max(hel1[1, *])+1+clon[0]
minlon= min(hel1[1, *])-1+clon[0]

xsi=fix((maxlon-minlon)/res+1)+20
ysi=fix((maxlat-minlat)/res+1)+20


helsize=long(xsi)*long(ysi)
helon=dblarr(helsize)
helat=dblarr(helsize)

helarr=dblarr(xsi, ysi)
for i=0l, xsi-1 do begin
  for j=0l, ysi-1 do begin
    helon[j*xsi+i]=minlon+res*(i-10)
    helat[j*xsi+i]=minlat+res*(j-10)
 endfor
endfor


case origin of

'soho':   begin
        arc=hel2arcmin(helat, helon-clon[0], date=date, /soho)
      end
'ground': arc=hel2arcmin(helat, helon-clon[0], date=date)

endcase


xp1=fix(arc[0, *]*60/cdx+xc+.5)
yp1=fix(arc[1, *]*60/cdy+yc+.5)


lat0=helat[0]
lon0=helon[0]

helArarr=dblarr(xsi, ysi)
for i=0l, xsi-1l do begin
   for j=0l, ysi-1l do begin
      helarr[i , j]=image[xp1[j*xsi+i], yp1[j*xsi+i]]
      helArarr[i , j]=arearr[xp1[j*xsi+i], yp1[j*xsi+i]]
   endfor
endfor

arealocs=where(helArarr ne 0)
area=n_elements(arealocs)*res*res

diameter=calcdiam(imb=helarr)*res

if keyword_set(display) then begin
    window, 1, xs=5*xsi, ys=5*ysi
    tvscl, congrid(helarr, 5*xsi, 5*ysi)

    window, 2, xs=5*xsi, ys=5*ysi
    tvscl, congrid(helArarr, 5*xsi, 5*ysi)
endif

return, helarr
end

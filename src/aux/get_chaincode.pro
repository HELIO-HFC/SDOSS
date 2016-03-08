pro get_chaincode, image, ccode=ccode, $
	code_locations=code_locations, imc=imc, $
	ad=ad

locs=where(image ne 0,npix)
if (locs[0] eq -1) then return

in=size(image)
nx=in(1) & ny=in(2)
n = nx*ny
mask=bytarr(nx,ny)
mask[locs]=1b

if n_elements(locs) eq 1 then begin
   ccode=lonarr(2,1)
   ccode(0, *)=locs(0) mod nx
   ccode(1, *)=locs(0) / nx
   return
end

xp=locs mod nx
yp=locs / nx

; ****  find seed
ind=where(yp eq max(yp))
ind2=where(xp(ind) eq min(xp(ind)))

xs=xp(ind(max(ind2)))
ys=yp(ind(max(ind2)))

ccx=xs
ccy=ys

; *** directions array
ndir=8
ardir=intarr(ndir, 2)
ardir(0, *)=[-1, 0]
ardir(1, *)=[-1, 1]
ardir(2, *)=[0, 1]
ardir(3, *)=[1, 1]
ardir(4, *)=[1, 0]
ardir(5, *)=[1, -1]
ardir(6, *)=[0, -1]
ardir(7, *)=[-1, -1]

ccdir=[0,7,6,5,4,3,2,1]

ad=ccdir[0]
loop=1b & count=1l
xpix=ccx & ypix=ccy
while (loop) do begin
   for i=0,ndir-1 do begin
      x = xpix + ardir[i,0]
      y = ypix + ardir[i,1]
      current_ccdir = ccdir[i]
      if (mask[x,y]) then break
   endfor
   if not (mask[x,y]) and (i eq ndir) then return

   ad=[ad,current_ccdir]
   ccx=[ccx,x] & ccy=[ccy,y]
   count++
   if (x eq ccx[0]) and (y eq ccy[0]) then break
   xpix = x & ypix=y

   ; rotate direction vector
   ishift = (where(ccdir eq (current_ccdir+4) mod 8))[0]
   ardir = shift(ardir,[7-ishift,0])
   ccdir = shift(ccdir,7-ishift)   
   if (count ge n) then return
endwhile
ccode=lonarr(2, count)
ccode(0, *)=ccx(*)
ccode(1, *)=ccy(*)

ad = ad[1:count-1]
end

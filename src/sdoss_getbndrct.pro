pro sdoss_getbndrct, locs, nx, ny, xc, yc, cdx, cdy,  arc_arr=arc_arr, xx=xx


xp=locs mod nx
yp=locs / nx

x0=min(xp)
y0=min(yp)

x1=max(xp)
y1=max(yp)

xx=[x0, y0, x1, y1]
arc_arr=dblarr(4)
    
br_arcx0=(x0-xc)*cdx
br_arcx1=(x1-xc)*cdx
br_arcy0=(y0-yc)*cdy
br_arcy1=(y1-yc)*cdy

arc_arr[0]=br_arcx0
arc_arr[1]=br_arcy0
arc_arr[2]=br_arcx1
arc_arr[3]=br_arcy1

end
function Image2Raster, image, CODE=CODE


;+
; NAME:
;		Image2Raster
;
; PURPOSE:
; 		This routine generates the raster scan of the input image.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		Image2Raster, image, /CODE
;
; INPUTS:
;		image - 2d image.
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		/CODE - Use Run-Length Encoding (RLE).
;
; OUTPUTS:
;		str - Raster scan of the input image.	
;
; OPTIONAL OUTPUTS:
;		None.
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
;		None.
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by S.Zharkov (MSSL).
;
;		18-JUL-2011, X.Bonnin:	Use : character at the end of each line scanned.
;
;-


sz = size(image)
if (sz[0] ne 2) then begin
   print,'Input image must have 2 dimensions!'
   return,''
endif
n = sz[4]
nx = sz[1]
;print, 'Straight String Length:', n

str=''

;	straight forward raster
if not keyword_set(code) then $
   for i=0l, n-1 do $
	;	if image[i] eq 0 then str=str+'0' else $
           str=str+trim(string(image[i], /print)) $
else begin

   abs_count=0l
   repeat begin      
      sprtr = '.'
      count=0
      value=image[abs_count]
      while (image[abs_count+count] eq value) do begin
         count++
         if ((abs_count+count) mod nx eq 0) then begin
            sprtr = ':'
            break
         endif
      endwhile
      abs_count=abs_count+count
      str=str+trim(string(value, /print))+$
          trim(string(count, /print))+ sprtr
   endrep until (abs_count ge n)
endelse
cnt=0

return, str
end

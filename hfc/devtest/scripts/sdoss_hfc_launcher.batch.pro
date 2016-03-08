;Sdoss_hfc_launcher.batch
;Idl Batch File To Launch Sdoss_hfc_processing.Pro
;Solarsoftware With Vso, Sdo, And Ontlogy Packages Must Be Loaded.
;
;To Run The Batch File On An Idl Session -> @sdoss_hfc_processing.batch
;
;X.Bonnin, 20-FEB-2014

; Load sdoss home directory
sdoss_hfc_dir = getenv('SDOSS_HFC_DIR')
if (sdoss_hfc_dir eq '') then message,'$SDOSS_HFC_DIR must be defined!'

;Add To !Path Variable Or Compile Extra Idl Routines Required To Run The Code
;pathsep = path_sep(/search_path) 
;!PATH = expand_path('+'+sdoss_dir+'/src') + pathsep + !PATH
;!PATH = expand_path('+'+sdoss_dir+'/lib/idl') + pathsep + !PATH

;Input options
VERBOSE = 1
DEBUG = 0
QCLK=1

;Define files Process
sep = path_sep()
data_dir = sdoss_hfc_dir + sep + 'data'
fnc = data_dir + sep + 'hmi.ic_45s.2012.02.01_00:00:00_TAI.continuum.fits'
fnm = data_dir + sep + 'hmi.m_45s.2012.02.01_00:00:00_TAI.magnetogram.fits'

;fnc = 'http://vso2.tuc.noao.edu/cgi-bin/drms_test/drms_export.cgi?series=hmi__Ic_45s;compress=rice;record=13323040-13323040'
;fnm = 'http://vso2.tuc.noao.edu/cgi-bin/drms_test/drms_export.cgi?series=hmi__M_45s;compress=rice;record=13323040-13323040'

product_dir= sdoss_hfc_dir + sep + 'products'

config_file = sdoss_hfc_dir + sep + 'config/sdoss_hfc_processing.config'

;Compile sdoss routines
@compile_sdoss_hfc.batch.pro
; Run sdoss
sdoss_hfc_processing,config_file, fnc, fnm, $
                     data_dir=data_dir, $
	  	             output_dir=product_dir,$
                     VERBOSE=VERBOSE, $
	                 DEBUG=DEBUG,QUICKLOOK=QCLK

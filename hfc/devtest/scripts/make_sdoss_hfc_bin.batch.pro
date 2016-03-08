;IDL batch file to generate an IDL binary runtime file (.sav)
;to run sdoss_hfc program from a command line or a script.
;sdo, vso, and ontology SSW packages must be loaded before
;running this script.
;X.Bonnin, 28-FEB-2014

sep = path_sep()

sdoss_dir = getenv('SDOSS_HFC_DIR')
if (sdoss_dir eq '') then message,'$SDOSS_HFC_DIR must be defined!'

target_dir=sdoss_dir + sep + 'bin'

@compile_sdoss_hfc.batch

proname= ['sdoss_hfc_processing']
resolve_all, /CONTINUE_ON_ERROR, resolve_procedure=proname
resolve_routine, 'uniq', /COMPILE_FULL_FILE, /IS_FUNCTION
filename = target_dir+sep+'sdoss_hfc_processing.sav'

save, /ROUTINES, filename=filename, $
      description='Runtime IDL program to call sdoss_hfc_processing.pro', $
      /VERBOSE, /EMBEDDED, /COMPRESS
if (file_test(filename)) then print,filename+' saved' $
else message,filename+' cannot be saved!'

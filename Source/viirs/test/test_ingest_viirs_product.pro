FUNCTION TEST_INGEST_VIIRS_PRODUCT
; LIKE A UNIT TEST 

CD, CURRENT=c

VIIRS_TEST_DIR = 'Input/Site_Libya4/VIIRS/Proc_calibration_1/2013/'
ROI = [29.05, 28.05, 23.89, 22.89]
SUCCESS = FALSE

file = 'NPP_VMAE_L1.A2013124.1215.P1_03001.2013125000838.gscs_000500759630.hdf'
file = [FILE, 'NPP_VMAE_L1.A2013125.1200.P1_03001.2013125220629.gscs_000500759630.hdf'] 
file = [FILE, 'NPP_VMAE_L1.A2013126.1140.P1_03001.2013126221618.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013127.1120.P1_03001.2013127211009.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013128.1100.P1_03001.2013129000457.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013128.1105.P1_03001.2013128215457.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013129.1045.P1_03001.2013129221400.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013129.1225.P1_03001.2013129225603.gscs_000500759630.hdf'] 
file = [file, 'NPP_VMAE_L1.A2013177.1045.P1_03001.2013178010518.gscs_000500759606.hdf'] 

;for i_iter=0,size(file, /dimension)[0] do begin ! stupid IDL
length_file_list = size(file, /dimension)

for i_iter=0, length_file_list[0] - 1 do begin
  VIIRS_TEST_FILE = VIIRS_TEST_DIR + file[i_iter]
  SUCCESS = INGEST_VIIRS_PRODUCT(VIIRS_TEST_DIR, ICOORDS=ROI, INPUT_FOLDER = INPUT_DIR,  /VERBOSE)
  IF SUCCESS EQ 1 THEN BEGIN
    PRINT, 'TEST :: ' + file[i_iter] + ' :: PASSED
  ENDIF ELSE BEGIN
    PRINT, 'TEST :: ' + file[i_iter] + ' :: FAILED
    RETURN, 0 
  ENDELSE
ENDFOR
RETURN, 1
END
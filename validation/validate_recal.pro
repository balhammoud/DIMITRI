PRO VALIDATE_recal

case strupcase(!version.os_family) of
'WINDOWS':OUTPUT_FOLDER = 'Z:\DIMITRI_code\DIMITRI_2.0\Output\SIO_20110426_REF_MERIS_2nd_Reprocessing\'
'UNIX':OUTPUT_FOLDER = '/mnt/Demitri/DIMITRI_code/DIMITRI_2.0/Output/SIO_20110426_REF_MERIS_2nd_Reprocessing/'
endcase
 
ic_REGION = 'SIO'
REF_SENSORS = 'MERIS'
REF_PROC_VERS = '2nd_Reprocessing'
CAL_SENSORS = 'MERIS'
CAL_PROC_VERS = '3rd_Reprocessing'
CLOUD_PERCENTAGE = 30.0
ROI_PERCENTAGE = 10.0

RES = DIMITRI_INTERFACE_RECALIBRATION(OUTPUT_FOLDER,IC_REGION,REF_SENSORS,REF_PROC_VERS, $
                     CAL_SENSORS,CAL_PROC_VERS,CLOUD_PERCENTAGE,ROI_PERCENTAGE,/VERBOSE)

print, res

;RES = CONCATENATE_TOA_REFLECTANCE(OUTPUT_FOLDER,IC_REGION,REF_SENSORS,REF_PROC_VERS,/VERBOSE)

END
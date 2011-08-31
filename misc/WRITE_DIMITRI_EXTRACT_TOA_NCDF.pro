;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      WRITE_DIMITRI_EXTRACT_TOA_NCDF    
;* 
;* PURPOSE:
;*      THIS PROGRAM OUTPUTS THE DIMITRI EXTRACTED SENSOR TOA TIME SERIES NETCDF FILE
;*
;* CALLING SEQUENCE:
;*      WRITE_DIMITRI_EXTRACT_TOA_NCDF,NCDF_OUTDATA,NCDF_FILENAME,NPRODS,NBANDS
;* 
;* INPUTS:
;*      NCDF_OUTDATA  - OUTPUT DATA IN THE FORM FROM GET_DIMITRI_EXTRACT_NCDF_STRUCTURE
;*      NCDF_FILENAME - THEFULLY QUALIFIED OUTPUT FILENAME
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      CREATES THE NETCDF FILE DEFINE IN NCDF_FILENAME
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      22 AUG 2011 - C KENT   - DIMITRI-2 V1.0
;*      23 AUG 2011 - C KENT   - REMOVED ALL HARD CODING
;*      30 AUG 2011 - C KENT   - ADDED MANUAL CLOUD SCREENING OUTPUT TO NETCDF
;*
;* VALIDATION HISTORY:
;*      
;*
;**************************************************************************************
;**************************************************************************************

PRO WRITE_DIMITRI_EXTRACT_TOA_NCDF,NCDF_OUTDATA,NCDF_FILENAME,VERBOSE=VERBOSE

  DIM_NCDF = GET_DIMITRI_EXTRACT_TOA_NCDF_NAMES(VERBOSE=VERBOSE)

;--------------------------
; GET SORT INDEX FROM DECIMAL TIME

  IDX     = SORT(NCDF_OUTDATA.VAR_DTIME)
  NPRODS  = N_ELEMENTS(NCDF_OUTDATA.VAR_CLOUD)
  TEMP    = SIZE(NCDF_OUTDATA.VAR_PIX)
  NBANDS  = TEMP[1]

;--------------------------
; CREATE THE NEW NETCDF FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: CREATING NEW NCDF FILE'
  NCID = NCDF_CREATE(NCDF_FILENAME)
 
;--------------------------
; CREATE THE NEW DIMENSIONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING DIMENSIONS'
  DIMPROD = NCDF_DIMDEF(NCID,DIM_NCDF.DIMPROD_STR,NPRODS) 
  DIMBAND = NCDF_DIMDEF(NCID,DIM_NCDF.DIMBAND_STR,NBANDS)
  DIMCHAR = NCDF_DIMDEF(NCID,DIM_NCDF.DIMCHAR_STR,DIM_NCDF.DIMCHAR_VAL)

;--------------------------
; CREATE THE GLOBAL ATTRIBUTES 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING GLOBAL ATTRIBUTES'
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_FNAME_TITLE, NCDF_OUTDATA.ATT_FNAME, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_TOOL_TITLE,  NCDF_OUTDATA.ATT_TOOL, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_CTIME_TITLE, NCDF_OUTDATA.ATT_CTIME, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_MTIME_TITLE, NCDF_OUTDATA.ATT_MTIME, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_SENSOR_TITLE,NCDF_OUTDATA.ATT_SENSOR, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_PROCV_TITLE, NCDF_OUTDATA.ATT_PROCV, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_PRES_TITLE,  NCDF_OUTDATA.ATT_PRES, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_NBANDS_TITLE,NCDF_OUTDATA.ATT_NBANDS, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_NDIRS_TITLE, NCDF_OUTDATA.ATT_NDIRS, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_SITEN_TITLE, NCDF_OUTDATA.ATT_SITEN, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_SITEC_TITLE, NCDF_OUTDATA.ATT_SITEC, /GLOBAL
  NCDF_ATTPUT, NCID, DIM_NCDF.ATT_SITET_TITLE, NCDF_OUTDATA.ATT_SITET, /GLOBAL

;--------------------------
; DEFINE THE NAME/TIME VARIABLES 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING NAME/TIME VARIABLES'
  VID_PN = NCDF_VARDEF(NCID, DIM_NCDF.VAR_PNAME_TITLE, [DIMCHAR,DIMPROD],/CHAR)
  NCDF_ATTPUT, NCID, VID_PN, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_PN, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_PNAME_LONG

  VID_AT = NCDF_VARDEF(NCID, DIM_NCDF.VAR_PTIME_TITLE, [DIMCHAR,DIMPROD], /CHAR)
  NCDF_ATTPUT, NCID, VID_AT, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DATE_TIME
  NCDF_ATTPUT, NCID, VID_AT, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_PTIME_LONG

  VID_DT = NCDF_VARDEF(NCID, DIM_NCDF.VAR_DTIME_TITLE, DIMPROD, /DOUBLE)
  NCDF_ATTPUT, NCID, VID_DT, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEC_TIME
  NCDF_ATTPUT, NCID, VID_DT, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_DTIME_LONG

;--------------------------
; CREATE THE RESULTS VARIABLES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING RESULT VARIABLES'
  VID_PIX = NCDF_VARDEF(NCID, DIM_NCDF.VAR_PIX_TITLE, [DIMBAND,DIMPROD], /SHORT)
  NCDF_ATTPUT, NCID, VID_PIX, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_PIX, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_PIX_LONG

  VID_RHOM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_RHOMU_TITLE, [DIMBAND,DIMPROD], /FLOAT)
  NCDF_ATTPUT, NCID, VID_RHOM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_RHOM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_RHOMU_LONG

  VID_RHOS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_RHOSD_TITLE, [DIMBAND,DIMPROD], /FLOAT)
  NCDF_ATTPUT, NCID, VID_RHOS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_RHOS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_RHOSD_LONG

  VID_CSA = NCDF_VARDEF(NCID, DIM_NCDF.VAR_CLOUD_TITLE_AUT, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_CS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_CS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_CLOUD_LONG_AUT

  VID_CSM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_CLOUD_TITLE_MAN, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_CS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_CS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_CLOUD_LONG_MAN

;--------------------------
; CREATE THE ANGLES VARIABLES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING ANGULAR VARIABLES'
  VID_VZ = NCDF_VARDEF(NCID, DIM_NCDF.VAR_VZA_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_VZ, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEG
  NCDF_ATTPUT, NCID, VID_VZ, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_VZA_LONG

  VID_VA = NCDF_VARDEF(NCID, DIM_NCDF.VAR_VAA_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_VA, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEG
  NCDF_ATTPUT, NCID, VID_VA, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_VAA_LONG

  VID_SZ = NCDF_VARDEF(NCID, DIM_NCDF.VAR_SZA_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_SZ, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEG
  NCDF_ATTPUT, NCID, VID_SZ, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_SZA_LONG

  VID_SA = NCDF_VARDEF(NCID, DIM_NCDF.VAR_SAA_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_SA, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEG
  NCDF_ATTPUT, NCID, VID_SA, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_SAA_LONG

;--------------------------
; CREATE THE AUX DATA VARIABLES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING AUX INFO VARIABLES'
  VID_OM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_OZONEMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_OM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DOBSON
  NCDF_ATTPUT, NCID, VID_OM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_OZONEMU_LONG

  VID_OS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_OZONESD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_OS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_OS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_OZONESD_LONG

  VID_WM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_WVAPMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_WM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_WVAP
  NCDF_ATTPUT, NCID, VID_WM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_WVAPMU_LONG

  VID_WS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_WVAPSD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_WS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_WS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_WVAPSD_LONG

  VID_PM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_PRESSMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_PM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_HPA
  NCDF_ATTPUT, NCID, VID_PM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_PRESSMU_LONG

  VID_PS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_PRESSSD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_PS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_PS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_PRESSSD_LONG

  VID_RM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_RHUMMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_RM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_PCENT
  NCDF_ATTPUT, NCID, VID_RM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_RHUMMU_LONG

  VID_RS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_RHUMSD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_RS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_RS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_RHUMSD_LONG

  VID_ZM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_ZONALMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_ZM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_MS
  NCDF_ATTPUT, NCID, VID_ZM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_ZONALMU_LONG

  VID_ZS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_ZONALSD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_ZS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DL
  NCDF_ATTPUT, NCID, VID_ZS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_ZONALSD_LONG

  VID_MM = NCDF_VARDEF(NCID, DIM_NCDF.VAR_MERIDMU_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_MM, DIM_NCDF.UNITS, DIM_NCDF.UNITS_DEG
  NCDF_ATTPUT, NCID, VID_MM, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_MERIDMU_LONG

  VID_MS = NCDF_VARDEF(NCID, DIM_NCDF.VAR_MERIDSD_TITLE, DIMPROD, /FLOAT)
  NCDF_ATTPUT, NCID, VID_MS, DIM_NCDF.UNITS, DIM_NCDF.UNITS_MS
  NCDF_ATTPUT, NCID, VID_MS, DIM_NCDF.LONG_NAME, DIM_NCDF.VAR_MERIDSD_LONG

;--------------------------
; END DEFINE MODE, CHANGE TO DATA MODE

  NCDF_CONTROL, NCID ,/ENDEF

;--------------------------
; WRITE DATA TO THE DEFINED VARIABLES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: WRITING DATA TO THE VARIABLES'
  NCDF_VARPUT, NCID, VID_PN, NCDF_OUTDATA.VAR_PNAME[IDX]
  NCDF_VARPUT, NCID, VID_AT, NCDF_OUTDATA.VAR_PTIME[IDX]
  NCDF_VARPUT, NCID, VID_DT, NCDF_OUTDATA.VAR_DTIME[IDX]
  NCDF_VARPUT, NCID, VID_PIX, NCDF_OUTDATA.VAR_PIX[*,IDX]
  NCDF_VARPUT, NCID, VID_RHOM, NCDF_OUTDATA.VAR_RHOMU[*,IDX]
  NCDF_VARPUT, NCID, VID_RHOS, NCDF_OUTDATA.VAR_RHOSD[*,IDX]
  NCDF_VARPUT, NCID, VID_CSA, NCDF_OUTDATA.VAR_CLOUD_AUT[IDX]
  NCDF_VARPUT, NCID, VID_CSM, NCDF_OUTDATA.VAR_CLOUD_MAN[IDX]
  NCDF_VARPUT, NCID, VID_VZ, NCDF_OUTDATA.VAR_VZA[IDX]
  NCDF_VARPUT, NCID, VID_VA, NCDF_OUTDATA.VAR_VAA[IDX]
  NCDF_VARPUT, NCID, VID_SZ, NCDF_OUTDATA.VAR_SZA[IDX]
  NCDF_VARPUT, NCID, VID_SA, NCDF_OUTDATA.VAR_SAA[IDX]

  NCDF_VARPUT, NCID, VID_OM, NCDF_OUTDATA.VAR_OZONEMU[IDX]
  NCDF_VARPUT, NCID, VID_OS, NCDF_OUTDATA.VAR_OZONESD[IDX]
  NCDF_VARPUT, NCID, VID_WM, NCDF_OUTDATA.VAR_WVAPMU[IDX]
  NCDF_VARPUT, NCID, VID_WS, NCDF_OUTDATA.VAR_WVAPSD[IDX]
  NCDF_VARPUT, NCID, VID_PM, NCDF_OUTDATA.VAR_PRESSMU[IDX]
  NCDF_VARPUT, NCID, VID_PS, NCDF_OUTDATA.VAR_PRESSSD[IDX]
  NCDF_VARPUT, NCID, VID_RM, NCDF_OUTDATA.VAR_RHUMMU[IDX]
  NCDF_VARPUT, NCID, VID_RS, NCDF_OUTDATA.VAR_RHUMSD[IDX]
  NCDF_VARPUT, NCID, VID_ZM, NCDF_OUTDATA.VAR_ZONALMU[IDX]
  NCDF_VARPUT, NCID, VID_ZS, NCDF_OUTDATA.VAR_ZONALSD[IDX]
  NCDF_VARPUT, NCID, VID_MM, NCDF_OUTDATA.VAR_MERIDMU[IDX]
  NCDF_VARPUT, NCID, VID_MS, NCDF_OUTDATA.VAR_MERIDSD[IDX]

;--------------------------
; CLOSE THE NETCDF FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'WRITE_DIMITRI_EXTRACT_TOA_NCDF: CLOSING THE NETCDF FILE'
  NCDF_CLOSE, NCID

END










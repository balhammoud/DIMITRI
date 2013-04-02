;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      UPDATE_DIMITRI_EXTRACT_TOA_NCDF   
;* 
;* PURPOSE:
;*      THIS FUNCTION OVERWRITES ANY NETCDF VARIABLE WITHIN THE EXTRACTED SENSOR TOA 
;*      TIME SERIES NETCDF FILES, GIVEN THE NEW DATA AND THE VARIABLE NAME
;*
;* CALLING SEQUENCE:
;*      RES = UPDATE_DIMITRI_EXTRACT_TOA_NCDF(NSITE,NSENSOR,NPROCV,VARNAME,VARDATA)
;* 
;* INPUTS:
;*      NSITE   - A STRING SCALAR OF THE VALIDATION SITE
;*      NSENSOR - A STRING SCALAR OF THE SENSOR 
;*      NPROCV  - A STRING SENSOR OF THE PROCESSING VERSION
;*      VARNAME - A STRING SCALAR OF THE VARIABLE NAME TO BE OVERWRITTEN
;*      VARDATA - AN ARRAY UPDATED DATA TO BE USED TO OVERWRITE DATA WITHIN VARNAME
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS    - 0 IS NOMINAL, NEGATIVE INDICATES SOME KIND OF ERROR ENCOUNTERED
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      30 AUG 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION UPDATE_DIMITRI_EXTRACT_TOA_NCDF,NSITE,NSENSOR,NPROCV,VARNAME,VARDATA,VERBOSE=VERBOSE

;---------------------------------
; DEFINE THE TOA NETCDF FILENAME

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: DEFINING NETCDF FILENAME'
  IFOLDER   = GET_DIMITRI_LOCATION('INPUT')
  DL        = GET_DIMITRI_LOCATION('DL')
  NCDF_FILE = IFOLDER+DL+'Site_'+nSITE+DL+nSENSOR+DL+'Proc_'+nPROCV+DL+nSITE+'_'+nSENSOR+'_Proc_'+nPROCV+'.nc'

;---------------------------------
; CHECK THAT THE NCDF FILE EXISTS

  IF NOT FILE_TEST(NCDF_FILE) THEN BEGIN
    PRINT,"UPDATE_DIMITRI_EXTRACT_TOA_NCDF: ERROR, INPUT NCDF DOESN'T EXIST"
    RETURN,-1
  ENDIF

;---------------------------------
; OPEN THE NETCDF FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: OPENING THE NETCDF FILE'  
  NCID = NCDF_OPEN(NCDF_FILE,/WRITE)

;---------------------------------
; GET ID OF THE REQUIRED VARIABLE FOR CHANGING
  
  VID = NCDF_VARID(NCID,VARNAME) 
  IF VID LT 0 THEN BEGIN
    PRINT,"UPDATE_DIMITRI_EXTRACT_TOA_NCDF: ERROR, VARIABLE DOESN'T EXIST"
    RETURN,-2
  ENDIF

;---------------------------------
; GET DATA FROM THE VARIABLE TO BE CHANGED

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: RETRIEVEING DATA FROM NETCDF'  
  NCDF_VARGET, NCID, VID, OLDVAL 

;---------------------------------
; MAKE SURE NEW DATA IS SAME SIZE AS OLD DATA

  IF N_ELEMENTS(OLDVAL) NE N_ELEMENTS(VARDATA) THEN BEGIN
    PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: ERROR, ARRAYS ARE OF DIFFERENT SIZES, CANNOT OVERWRITE'
    RETURN,-3
  ENDIF

;---------------------------------
; WRITE NEW DATA TO VARIABLE AND CHANGE MODIFICATION DATE ATTRIBUTE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: OVERWRITING OLD VARIABLE'  
  NCDF_VARPUT, NCID,VID,VARDATA,OFFSET=0 

  CALDAT, SYSTIME(/UTC,/JULIAN),TMM,TDD,TYY,THR,TMN,TSS
  TYY = STRTRIM(STRING(TYY),2)
  TMM = TMM LT 10 ? '0'+STRTRIM(STRING(TMM),2) : STRTRIM(STRING(TMM),2)
  TDD = TDD LT 10 ? '0'+STRTRIM(STRING(TDD),2) : STRTRIM(STRING(TDD),2)
  THR = THR LT 10 ? '0'+STRTRIM(STRING(THR),2) : STRTRIM(STRING(THR),2)
  TMN = TMN LT 10 ? '0'+STRTRIM(STRING(TMN),2) : STRTRIM(STRING(TMN),2)
  TSS = TSS LT 10 ? '0'+STRTRIM(STRING(TSS,FORMAT='(I)'),2) : STRTRIM(STRING(TSS,FORMAT='(I)'),2)
  MDATE = TYY+TMM+TDD+' '+THR+':'+TMN+':'+TSS
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: OVERWRITING MODIFICATION DATE/TIME'
  NCDF_ATTPUT,NCID , 'modification_time' , MDATE,/GLOBAL 

;---------------------------------
; CLOSE THE NCDF FILE

  NCDF_CLOSE,NCID

;---------------------------------  
; RETURN NOMINAL OUTPUT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'UPDATE_DIMITRI_EXTRACT_TOA_NCDF: UPDATE SUCCESSFUL'
  RETURN,0
  
end
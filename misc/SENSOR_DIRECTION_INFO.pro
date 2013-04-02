;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      SENSOR_DIRECTION_INFO       
;* 
;* PURPOSE:
;*      RETURNS THE NUMBER OF DIRECTIONS FOR A GIVEN SENSOR
;* 
;* CALLING SEQUENCE:
;*      RES = SENSOR_DIRECTION_INFO(SENSOR_BD)      
;* 
;* INPUTS:
;*      SENSOR_BD - A STRING CONTAINING THE NAME OF THE SENSOR OF INTEREST
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      SBI_DIRS - AN INTEGER IF THE NUMBER OF DIRECTIONS
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      31 AUG 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*       
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION SENSOR_DIRECTION_INFO,SENSOR_BD,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SENSOR_DIRECTION_INFO: RETRIEVEING DATA FOR SENSOR - ',SENSOR_BD
   
;------------------------------------
; DEFINE SENSOR FILE

  SBI_FILE = GET_DIMITRI_LOCATION('SENSOR_DATA')  
  RES = FILE_INFO(SBI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    PRINT, 'SENSOR_DIRECTION_INFO: ERROR, SENSOR INFORMATION FILE NOT FOUND'
    RETURN,-1
  ENDIF
  
;------------------------------------
; GET SENSOR DATA TEMPLATE
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SENSOR_DIRECTION_INFO: RETRIEVEING SENSOR DATA TEMPLATE'
  TEMP = GET_DIMITRI_SENSOR_DATA_TEMPLATE(VERBOSE=VERBOSE)

;------------------------------------
; FIND SENSOR MATCH WHITHIN FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SENSOR_DIRECTION_INFO: SEARCHING SENSOR FILE FOR INPUT SENSOR' 
  SBI_DATA = READ_ASCII(SBI_FILE,TEMPLATE=TEMP)
  RES = WHERE(STRMATCH(SBI_DATA.SENSOR_ID,SENSOR_BD) EQ 1)

;------------------------------------
;IF NO MATCH THEN ERROR AND RETURN
  
  IF RES[0] LT 0 THEN BEGIN
    PRINT,'SENSOR_DIRECTION_INFO: ERROR, NO SENSOR MATCH'
    RETURN,-1
  ENDIF
  SBI_DIRS = SBI_DATA.NUM_DIR[RES]

;------------------------------------
; IF AREA REQUIRED THEN SQUARE THE RESOLUTION
  
  RETURN,SBI_DIRS[0]

END
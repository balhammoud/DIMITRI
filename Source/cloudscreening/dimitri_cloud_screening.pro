;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_CLOUD_SCREENING       
;* 
;* PURPOSE:
;*      THIS ROUTINE TAKES ANY INPUT SENSOR L1B TOA REFLECTANCE AND SENDS IT TO THE 
;*      REQUIRED CLOUD SCREENING ALGORITHM. THE PIXEL-BY-PIXEL CLOUD MASK IS RETURNED.
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_CLOUD_SCREENING(SENSOR,SITE_TYPE,TOA_RHO,TOA_GEO,CS_ALGO)    
;* 
;* INPUTS:
;*      SENSOR     - A STRING OF THE INPUT SENSOR      
;*      SITE_TYPE  - A STRING OF THE DIMITRI VALIDATION SITE TYPE (E.G. 'OCEANIC')'
;*      TOA_RHO    - A FLOAT ARRAY CONTAINING THE SENSORS TOA REFLECTANCE (NUM_PIXELS,NUM_BANDS)
;*      TOA_GEO    - A 3 OR 4 ELEMENT ARRAY CONTAINING THE SZA AND VZA VALUES AND EITHER
;*                   RAA OR SAA AND VAA
;*      CS_ALGO    - A STRING OF THE CLOUD SCREENING ALGORITHM NAME 
;*
;* KEYWORDS:
;*      VERBOSE    - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      CLOUD_PERCENTAGE - THE PERCENTAGE CLOUD COVER RETURNED FROM THE REQUESTED SPECTRUM
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      07 APR 2011 - C KENT      - DIMITRI-2 V1.0
;*      02 JAN 2014 - C MAZERAN   - RETURN THE PIXEL-BY-PIXEL CLOUD MASK INSTEAD OF ROI PERCENTAGE
;*
;* VALIDATION HISTORY:
;*      12 APR 2011 - C KENT   - NOMINAL COMPILATION AND OPERATION ON WINDOWS 32BIT 
;*                               IDL 7.1 AND LINUX 64BIT IDL 8.0
;*
;*      31 OCT 2014 - B ALHAMMOUD   - VALIDATION OF THE UPDATED VERSION DIMITRI V3.1 
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_CLOUD_SCREENING,SENSOR,SITE_TYPE,TOA_RHO,TOA_GEO,CS_ALGO,VERBOSE=VERBOSE

;------------------------
; DEFINE CURRENT FUNCTION NAME

  FCT_NAME = "DIMITRI_CLOUD_SCREENING"

;------------------------
; GET SENSOR BANDS AND CS INDEX BANDS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': STARTING CLOUD SCREENING FOR ALGORITHM -',STRUPCASE(CS_ALGO)
    
  SENS_BANDS  = SENSOR_BAND_INFO(SENSOR,VERBOSE=VERBOSE)
  CS_BANDS    = CS_BAND_INFO(CS_ALGO,VERBOSE=VERBOSE)

;------------------------
; COMPUTE NUMBER OF PIXELS AND GET MATCHING SENSOR RHO
  
  NB_PIXELS   = N_ELEMENTS(TOA_RHO[*,0])
  NB_CS_BANDS = N_ELEMENTS(CS_BANDS)
  CS_RHO      = MAKE_ARRAY(NB_PIXELS,NB_CS_BANDS,/FLOAT)
  EXCEPTION_RAISED = 0
  MODISA_FLAG = 0

;------------------------
; ADD MODIS LCCA EXCEPTION

  IF  SENSOR EQ 'MODISA' AND $
      CS_ALGO EQ 'LCCA' THEN BEGIN
    
      CS_BANDS = [12,20,21,18,22]
      CS_FACT  = [1.08,0.92,0.95,0.90,1.]

    FOR CLOUDI=0,NB_CS_BANDS-1 DO CS_RHO[*,CLOUDI] = TOA_RHO[*,CS_BANDS[CLOUDI]]*CS_FACT[CLOUDI]
    EXCEPTION_RAISED = 1
    MODISA_FLAG = 1
  ENDIF
  IF NOT EXCEPTION_RAISED THEN BEGIN 
  FOR CLOUDI=0,NB_CS_BANDS-1 DO BEGIN
    BID = GET_SENSOR_BAND_INDEX(SENSOR,CS_BANDS[CLOUDI])
    IF BID GE 0 THEN CS_RHO[*,CLOUDI] = TOA_RHO[*,BID] ELSE BEGIN
       PRINT, FCT_NAME+': ERROR, REQUIRED WAVELENGTHS NOT FOUND, RETURNING -1.0'
      RETURN,-1.0
    ENDELSE
  ENDFOR
  ENDIF

;------------------------
; CALL THE REQUIRED CLOUD SCREENING ALGORITHM

  CASE STRUPCASE(CS_ALGO) OF 
    'VGT'         : CLOUD_MASK = CLOUD_MODULE_VGT(SITE_TYPE,CS_RHO,VERBOSE=VERBOSE)
    'GLOBCARBON'  : CLOUD_MASK = CLOUD_MODULE_GLOBCARBON(SITE_TYPE,CS_RHO,TOA_GEO,VERBOSE=VERBOSE)
    'GLOBCARBON_P': CLOUD_MASK = CLOUD_MODULE_GLOBCARBON_P(SITE_TYPE,CS_RHO,TOA_GEO,VERBOSE=VERBOSE)
    'LCCA'        : CLOUD_MASK = CLOUD_MODULE_LCCA(CS_RHO,VERBOSE=VERBOSE,MODISA=MODISA_FLAG)
  ENDCASE

;--------------------------
; RETURN THE CLOUD MASK

  RETURN, CLOUD_MASK

END

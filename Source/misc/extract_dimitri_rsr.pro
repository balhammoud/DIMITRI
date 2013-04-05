;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      EXTRACT_DIMITRI_RSR    
;* 
;* PURPOSE:
;*      THIS FUNCTION INTERPOLATES A GIVEN RSR ARRAY TO 0.5NM INTERVALS AND THEN 
;*      EXTRACTS THE DATA TO A PREDEFINED WAVELENGTH RANGE
;*
;* CALLING SEQUENCE:
;*      RES = EXTRACT_DIMITRI_RSR(DATA,WL_ARRAY)
;* 
;* INPUTS:
;*      DATA      - A STRUCTURE CONTAINING .(0): THE DATA WAVELENGTHS, AND 
;*                  .(1): THE DATA TO BE INTERPOLATED
;*      WL_ARRAY  - A FLOAT ARRAY OF THE WAVELENGTHS THE DATA SHOULD BE EXTRACTED FOR 
;*                  (AT AN INTERVAL OF 0.5 NM)
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NEW_RSR   - THE INTERPOLATED DATA AT WAVELENGTHS OF WL_ARRAY
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      30 MAR 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      14 APR 2011 - C KENT   - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                               COMPILATION AND OPERATION 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION EXTRACT_DIMITRI_RSR,DATA,WL_ARRAY,VERBOSE=VERBOSE

;----------------------------
; RETRIEVE RANGE OF DATA PROVIDED

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'EXTRACT_DIMITRI_RSR: COMPUTING LIMITS OF SUPPLIED DATA'
  D_MIN = FIX(MIN(DATA.(0)))
  D_MAX = FIX(MAX(DATA.(0)))
  W_MIN = MIN(WL_ARRAY)
  W_MAX = MAX(WL_ARRAY)

;----------------------------
; COMPUTE NEW WAVELENGTH ARRAY 
; AND INTEPROLATE DATA TO IT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'EXTRACT_DIMITRI_RSR: COMPUTING NEW WAVELENGTH ARRAY'
  NEW_WL    = 0.5*FINDGEN((D_MAX-D_MIN)/0.5)+D_MIN
  NEW_DATA  = INTERPOL(DATA.(1),DATA.(0),NEW_WL)
  NEW_NUM   = N_ELEMENTS(NEW_WL)

  NWL     = N_ELEMENTS(WL_ARRAY)
  NEW_RSR = FLTARR(NWL)

;----------------------------
; CHECK DATA ARRAYS OVERLAP

  IF W_MIN GT D_MAX OR W_MAX LT D_MIN THEN RETURN,NEW_RSR

;----------------------------
; FIND WHERE THE START WL IS IN THE DATA ARRAY

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'EXTRACT_DIMITRI_RSR: LOCATING FIRST COMMON WAVELENGTH'
  FOR I=0,NEW_NUM-1 DO BEGIN
    RES = WHERE(WL_ARRAY EQ NEW_WL[I])
    IF RES[0] GT -1 THEN BEGIN
      SLOC = RES[0]
      SRSR = I
      GOTO, BREAK_LOOP1
    ENDIF
  ENDFOR
  IF I EQ NEW_NUM THEN RETURN,NEW_RSR 
  BREAK_LOOP1:

;----------------------------
; FIND WHERE THE LAST WL IS IN THE DATA ARRAY
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'EXTRACT_DIMITRI_RSR: LOCATING LAST COMMON WAVELENGTH'  
  RES = WHERE(WL_ARRAY EQ NEW_WL[NEW_NUM-1])
  IF RES[0] GT -1 THEN BEGIN
    ERSR = NEW_NUM-1
    ELOC = RES[0]
  ENDIF ELSE BEGIN
    RES = WHERE(NEW_WL EQ WL_ARRAY[NWL-1])
    ERSR = RES[0]
    ELOC = NWL-1
  ENDELSE

;----------------------------
; EXTRACT SECTION OF INTERPOLATED DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'EXTRACT_DIMITRI_RSR: EXTRACTING ALL COMMON WAVELENGTHS'
  NEW_RSR[SLOC:ELOC] = NEW_DATA[SRSR:ERSR]
  RETURN,NEW_RSR
  
END
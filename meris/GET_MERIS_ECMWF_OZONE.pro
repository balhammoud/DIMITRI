;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_MERIS_ECMWF_OZONE       
;* 
;* PURPOSE:
;*      RETURNS THE ECMWF OZONE CENTRATION OF A MERIS IMAGE
;* 
;* CALLING SEQUENCE:
;*      RES = GET_MERIS_ECMWF_OZONE(FILENAME)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR EXTRACTION      
;*
;* KEYWORDS:
;*     ENDIAN_SIZE  - MACHINE ENDIAN SIZE (0: LITTLE, 1: BIG)
;*     VERBOSE      - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*     ECMWF_OZONE   - ECMWF OZONE CONCENTRATION
;*
;* COMMON BLOCKS:
;*     NONE 
;*
;* MODIFICATION HISTORY:
;*     03 JUL 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*     01 DEC 2010 - C KENT   - 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_MERIS_ECMWF_OZONE,FILENAME,ENDIAN_SIZE=ENDIAN_SIZE,VERBOSE=VERBOSE

;------------------------------------------------
; CHECK FILENAME IS NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'MERIS L1B ECMWF OZONE: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF

;------------------------------------------------
; IF ENDIAN SIZE NOT PROVIDED THEN GET VALUE

  IF N_ELEMENTS(ENDIAN_SIZE) EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN BEGIN
      PRINT, 'MERIS L1B ECMWF OZONE: NO ENDIAN SIZE PROVIDED, RETRIEVING...'
      ENDIAN_SIZE = GET_ENDIAN_SIZE(/VERBOSE)
    ENDIF ELSE ENDIAN_SIZE = GET_ENDIAN_SIZE()
  ENDIF

;------------------------------------------------
;DEFINE HEADER VARIABLES

  MPH_SIZE = 1247
  SPH_SIZE = 9942
  FILE_MPH = BYTARR(MPH_SIZE)
  FILE_SPH = BYTARR(SPH_SIZE)

;-----------------------------------------------
; OPEN THE FILE AND EXTRACT HEADER

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: OPENING PRODUCT'
  OPENR,PRD_VIG,FILENAME,/GET_LUN
  READU,PRD_VIG,FILE_MPH
  READU,PRD_VIG,FILE_SPH

;-----------------------------------------------
; RETRIEVE: POSITION OF DSD, TP SUBSAMPLING FREQUENCY,LINE SIZE,TP PER LINE,DSD,OFFSET,DS_SIZE,NUMBER OF RECORDS, RECORD SIZE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: RETRIEVING DSD INFORMATION'
  TP_DSD_POS      = STRPOS(FILE_SPH,'DS_NAME="Tie points ADS              "')
  TP_SFREQ        = STRMID(FILE_SPH, STRPOS(FILE_SPH,'SAMPLES_PER_TIE_PT=+')+20, 3)+0L
  LINE_SIZE       = STRMID(FILE_SPH, STRPOS(FILE_SPH,'LINE_LENGTH=+')+13, 5)+0L
  NB_TP_LINE      = FLOOR(LINE_SIZE/TP_SFREQ)+1
  
  TP_DSD          = STRMID(FILE_SPH, TP_DSD_POS,280)
  TP_OFFSET       = STRMID(TP_DSD, STRPOS(TP_DSD, 'DS_OFFSET=+')+11,20)+0L
  TP_SIZE         = STRMID(TP_DSD, STRPOS(TP_DSD, 'DS_SIZE=+')  +9,20)+0L
  TP_DSR_NUMBER   = STRMID(TP_DSD, STRPOS(TP_DSD, 'NUM_DSR=+')  +9,20)+0L
  TP_DSR_SIZE     = STRMID(TP_DSD, STRPOS(TP_DSD, 'DSR_SIZE=+') +10,20)+0L

;-----------------------------------------
; DEFINE ARRAY AND TEMPORARY TO HOLD DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: DEFINING DATA ARRAYS FOR OUTPUT'
  ECMWF_OZONE = UINTARR(NB_TP_LINE,TP_DSR_NUMBER)
  VIEW_REC = UINTARR(NB_TP_LINE)
  NODATA = BYTARR(3279)
   
;-----------------------------------------
; LOOP OVER EACH RECORD AND EXTRACT ALL ECMWFDATA  
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: STARTING LOOP FOR DATA EXTRACTION'
  FOR VREC=0,TP_DSR_NUMBER-1 DO BEGIN
 
    POINT_LUN,PRD_VIG, TP_OFFSET+VREC*TP_DSR_SIZE
    
    READU,PRD_VIG,NODATA

    READU,PRD_VIG,VIEW_REC
    ECMWF_OZONE[*,VREC] = VIEW_REC
    
  ENDFOR ;END OF LOOP ON ECMWF RECORDS

;----------------------------------------
; SWAP ENDIAN IF NEEDED - MERIS DATA IS BIG ENDIAN
  
    IF ENDIAN_SIZE EQ 0 THEN ECMWF_OZONE = SWAP_ENDIAN(ECMWF_OZONE)
  
;---------------------------------------
; CLOSE THE FILE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: CLOSING PRODUCTS AND RELEASING THE LUN'
  CLOSE, PRD_VIG
  FREE_LUN, PRD_VIG
  
;---------------------------------------
; FIND NUMBER OF PIXELS WITHIN MERIS RADIANCE FRAME

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: RETRIEVE DIMENSIONS OF RADIANCE PRODUCT'
  RD_POS      = STRPOS(FILE_SPH,'DS_NAME="Radiance MDS(1)             "')
  RD_DSD      = STRMID(FILE_SPH, RD_POS,280)
  NB_RD_LINE  = STRMID(RD_DSD, STRPOS(RD_DSD, 'NUM_DSR=+')+9,20)  

;---------------------------------------
; CONVERT VALUES INTO CORRECT UNITS
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: CONVERT VALUES INTO DEGREES'
  ECMWF_OZONE   = FLOAT(ECMWF_OZONE)*0.01
  
;---------------------------------------
; INTERPOLATE VALUES TO RADIANCE GRID

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: REGRID DATA INTO RADIANCE PRODUCT DIMENSIONS'
  ECMWF_OZONE   = CONGRID(ECMWF_OZONE,LINE_SIZE,NB_RD_LINE,/MINUS_ONE,/INTERP)
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MERIS L1B ECMWF OZONE: RETURNING ECMWF OZONE'
  RETURN,ECMWF_OZONE
  
END

;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_MODISA_QUICKLOOK       
;* 
;* PURPOSE:
;*      OUTPUTS A RGB MODISA QUICKLOOK WITH ROI OVERLAY IF REQUESTED
;* 
;* CALLING SEQUENCE:
;*      RES = GET_MODISA_QUICKLOOK(FILENAME)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR QUICKLOOK GENERATION 
;*
;* KEYWORDS:
;*     RGB          -  PROGRAM GENERATES AN RGB COLOUR QUICKLOOK (DEFAULT IS GRAYSCALE)
;*     ROI          -  OVERLAY COORDINATES OF AN ROI IN RED (REQUIRES ICOORDS)
;*     ICOORDS      -  A 4-ELEMENT ARRAY OF ROI GEOLOCATION (N,S,E,W) 
;*     QL_QUALITY   -  QUALITY OF JPEG GENERATED (100 = MAX, 0 = LOWEST)
;*     VERBOSE      - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*     STATUS       - 1: NOMINAL, (-1) OR 0: ERROR
;*     JPESG ARE AUTOMATICALLY SAVED IN FILENAME FOLDER    
;*
;* COMMON BLOCKS:
;*     NONE 
;*
;* MODIFICATION HISTORY:
;*      13 FEB 2002 - M BOUVET - PROTOTYPE DIMITRI VERSION
;*      07 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*      18 MAR 2011 - C KENT   - MODIFIED RGB GENERATION
;*
;* VALIDATION HISTORY:
;*      01 DEC 2010 - C KENT   - WINDOWS 32-BIT MACHINE, COMPILATION SUCCESSFUL. ALL KEYWORD 
;*                               COMBINATIONS TESTED FOR A PRODUCT OVER UYUNI
;*      05 JAN 2011 - C KENT   - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL, 
;*                               NO APPARENT DIFFERENCES WHEN COMPARED TO WINDOWS MACHINE
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_MODISA_QUICKLOOK,FILENAME,RGB=RGB,ROI=ROI,ICOORDS=ICOORDS,QL_QUALITY=QL_QUALITY,VERBOSE=VERBOSE

;------------------------------------------------
; CHECK FILENAME IS NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'MODISA L1B QUICKLOOK: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF

;------------------------------------------------
; SET JPEG QUALITY IF NOT PROVIDED

  IF N_ELEMENTS(QL_QUALITY) EQ 0 THEN QL_QUALITY = 90
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: JPEG QUALITY = ',QL_QUALITY
  
;------------------------------------------------
; CHECK KEYWORD COMBINATIONS

  IF KEYWORD_SET(ROI) AND N_ELEMENTS(ICOORDS) LT 4 THEN BEGIN
    PRINT,'MODISA L1B QUICKLOOK: ERROR, ROI KEYWORD IS SET BUT COORDINATES INCORRECT'
    RETURN,-1
  ENDIF

;------------------------------------------------
; DERIVE THE OUTPUT JPEG FILENAME

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: COMPUTING OUTPUT FILENAME'
  QL_POS = STRPOS(FILENAME,'.',/REVERSE_SEARCH)
  QL_MODISA_JPG = FILENAME
  STRPUT,QL_MODISA_JPG,'_',QL_POS
  QL_MODISA_JPG = STRING(QL_MODISA_JPG+'.jpg')
  ORDER=0

;------------------------------------------------
; GET MODISA L1B RADIANCE DATA AND DERIVE QUICKLOOK IMAGE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: RETRIEVING RADIANCE DATA'  
  IF KEYWORD_SET(RGB) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: RGB JPEG SELECTED'
    QL_DATAR = GET_MODISA_L1B_RADIANCE(FILENAME,0,/RES_250m,/VERBOSE)
    QL_DATAG = GET_MODISA_L1B_RADIANCE(FILENAME,1,/RES_500m,/VERBOSE)
    QL_DATAB = GET_MODISA_L1B_RADIANCE(FILENAME,0,/RES_500m,/VERBOSE)
  ENDIF ELSE BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: GRAYSCALE SELECTED'
    QL_DATAR  = GET_MODISA_L1B_RADIANCE(FILENAME,12,/RES_1KM,/VERBOSE)
  ENDELSE
  
  IF QL_DATAR[0] EQ -1 THEN BEGIN
    PRINT,'MODISA L1B QUICKLOOK: ERROR, PROBLEM ENCOUNTERED DURING L1B RADIANCE RETRIEVAL, CHECK PRODUCTS IS A MODISAS L1B PRODUCT'
    RETURN,-1
  ENDIF

;----------------------------------------------
; RELEASE MEMORY FOR TOA_REFLECTANCE

  QL_TOA_REF = 0
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: GET PRODUCT DIMENSIONS AND DEFINE IMAGE ARRAY'
  QL_DIMS  = SIZE(QL_DATAR)
  QL_IMAGE = BYTARR(3,QL_DIMS[1],QL_DIMS[2])
  
;-----------------------------------------------
; POPULATE THE QUICKLOOK IMAGE ARRAY  

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: ADD RADIANCE DATA TO IMAGE ARRAY CHANNELS'
  IF KEYWORD_SET(RGB) THEN BEGIN 
 
    QL_IMAGE[0,*,*]=BYTSCL(QL_DATAR)
    QL_IMAGE[1,*,*]=BYTSCL(QL_DATAG)
    QL_IMAGE[2,*,*]=BYTSCL(QL_DATAB)
    
;----------------------------------------------
; RELEASE MEMORY FOR GREEN AND BLUE CHANNELS
    
    QL_DATAG = 0
    QL_DATAB = 0
    
  ENDIF ELSE BEGIN
  
    QL_IMAGE[0,*,*]=BYTE(QL_DATAR)
    QL_IMAGE[1,*,*]=BYTE(QL_DATAR)
    QL_IMAGE[2,*,*]=BYTE(QL_DATAR)
 
 
  ENDELSE

 ; QL_IMAGE=BYTSCL(QL_IMAGE,TOP=220)

;---------------------------------------------------
; GET LAT/LON DATA FOR ROI PIXEL INDEX IF REQUESTED

  IF KEYWORD_SET(ROI) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: OVERLAY OF ROI SELECTED'
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: RETRIEVING PRODUCT GEOLOCATION'
    QL_GEO = GET_MODISA_LAT_LON(FILENAME)
     
;---------------------------------------------------
; FIND LOCATION OF ROI

    QL_ROI_IDX = WHERE($
          QL_GEO.LAT LT ICOORDS[0] AND $
          QL_GEO.LAT GT ICOORDS[1] AND $
          QL_GEO.LON LT ICOORDS[2] AND $
          QL_GEO.LON GT ICOORDS[3] )

;---------------------------------------------------
; CONVERT ROI PIXELS TO A LIGHT RED OVERLAY

    IF QL_ROI_IDX[0] GT -1 THEN BEGIN
          IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: MODIFYING RED CHANNEL FOR ROI OVERLAY'
          ;IF KEYWORD_SET(RGB) THEN BEGIN
            ;QL_DATAR = BYTE(QL_DATAR)
            QL_DATAR = QL_IMAGE[0,*,*]
            QL_DATAG = QL_IMAGE[1,*,*]
            QL_DATAB = QL_IMAGE[2,*,*]
          ;ENDIF ELSE QL_DATAR = BYTSCL(QL_DATAR,MAX=TEMP_MAX)
          
          QL_DATAR[QL_ROI_IDX]=250
          QL_DATAG[QL_ROI_IDX]=bytscl(QL_DATAG[QL_ROI_IDX],top=75)
          QL_DATAB[QL_ROI_IDX]=bytscl(QL_DATAb[QL_ROI_IDX],top=75)
          QL_IMAGE[0,*,*] = QL_DATAR
          QL_IMAGE[1,*,*] = QL_DATAG
          QL_IMAGE[2,*,*] = QL_DATAB
          
          
    ENDIF

  IF (QL_GEO.LAT[2,QL_DIMS[2]-3]) GT (QL_GEO.LAT[2,2]) THEN ORDER=1 ELSE ORDER=0

  ENDIF

;---------------------------------------------------
; OUTPUT QUICKLOOK AS JPEG

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'MODISA L1B QUICKLOOK: WRITING IMAGE TO JPEG'
  WRITE_JPEG ,QL_MODISA_JPG,REVERSE(REVERSE(QL_IMAGE,3),2),TRUE=1,ORDER=ORDER
  
;---------------------------------------------------
; RETURN A POSITIVE VALUE INDICATING QL GENERATION OK

  RETURN, 1

END

;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      EXTRACT_DOUBLETS       
;* 
;* PURPOSE:
;*      EXTRACTS DOUBLET DATA FOR TWO SENSORS AND PROCESSING VERSIONS FOR A 
;*      SPECIFIED REGION. THE DATA IS SAVED AS SAV VARIABLES WITHIN THE DEFINED 
;*      OUTPUT FOLDER.
;* 
;* CALLING SEQUENCE:
;*      RES = EXTRACT_DOUBLETS(OUTPUT_FOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,$
;*                             PROC_VER2,CHI_THRESHOLD,DAY_OFFSET,CLOUD_PERCENTAGE,$
;*                             ROI_PERCENTAGE)      
;* 
;* INPUTS:
;*      OUTPUT_FOLDER     - THE FULL PATH OF THE OUTPUT FOLDER  
;*      ED_REGION         - THE VALIDATION SITE NAME E.G. 'Uyuni'
;*      SENSOR1           - THE NAME OF THE 1ST SENSOR FOR DOUBLET EXTRACTION E.G. 'MERIS'
;*      PROC_VER1         - THE PROCESSING VERSION OF THE 1ST SENSOR E.G. '2nd_Processing'
;*      SENSOR2           - THE NAME OF THE 2ND SENSOR FOR DOUBLET EXTRACTION E.G. 'MODISA
;*      PROC_VER2         - THE PROCESSING VERSION OF THE 2ND SENSOR E.G. 'Collection_5'
;*      AMC_THRESHOLD     - THE CHI THRESHOLD VALUE AS RETURNED BY COMPUTE_CHI_THRESHOLD.PRO
;*      DAY_OFFSET        - THE NUMBER OF DAYS DIFFERENCE ALLOWED BETWEEN DOUBLETS E.G 2
;*      CLOUD_PERCENTAGE  - THE PERCENTAGE CLOUD COVER THRESHOLD ALLOWED WITHIN PRODUCTS E.G. 60.0 
;*      ROI_PERCENTAGE    - THE PERCENTAGE ROI COVERAGE ALLOWED WITHIN PRODUCTS E.G. 75.0     
;*      VZA_MIN           - THE MINIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VZA_MAX           - THE MAXIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MIN           - THE MINIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MAX           - THE MAXIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MIN           - THE MINIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MAX           - THE MAXIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MIN           - THE MINIMUM SOLAR AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MAX           - THE MAXIMUM SOLAR AZIMTUH ANGLE ALLOWED FOR AN OBSERVATION
;*
;* KEYWORDS:
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS            - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*                    - M BOUVET  - PROTOTYPE DIMITRI VERSION
;*        14 JAN 2011 - C KENT    - DIMITRI-2 V1.0
;*        17 JAN 2011 - C KENT 	  - ADDED ADDITIONAL VERBOSE COMMENTS
;*        18 JAN 2011 - C KENT    - MINOR CHANGES TO ALLOW COMPILATION, ADDED ED_NO_DATA TO 
;*                                  INDICATE IF NO VALUES BELOW CHI THRESHOLD. CHANGED 
;*                                  OUTPUT FOLDER TO OFOLDER, UPDATED OUTPUT LOG FORMAT
;*        19 JAN 2011 - C KENT    - CHANGED OUTPUT FILENAMES TO INCLUDE THE REGION
;*        20 JAN 2011 - C KENT    - ADDED SEMICOLON SEPERATED CSV FILE, ADDED DOUBLET_EXTRACTION 
;*                                  OUTPUT FOLDER AND PROCESSINF VERSION TO OUTPUT NAMES
;*        08 FEB 2011 - C KENT    - ADDED CHI VALUES TO OUTPUT VARIABLE INSTEAD OF GEOTYPE
;*        22 FEB 2011 - C KENT    - UPDATED ROI PIXEL THRESHOLD TO BE DOUBLE, NOT INTEGER
;*        21 MAR 2011 - C KENT    - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*        29 MAR 2011 - C KENT    - ADDED STANDARD DEVIATION RESULTS TO OUTPUT CSV AND DATA
;*        05 MAY 2011 - C KENT    - ADDED JPEG OUTPUT
;*        30 JUN 2011 - C KENT    - UPDATED CLOUD SCREENING TO CHECK FOR SUSPECT PRODUCTS
;*        02 JUL 2011 - C KENT    - ADDED ABSOLUTE ANGULAR CRITERIA
;*        04 JUL 2011 - C KENT    - UPDATED INPUT SAV'S TO INCLUDE AUX INFO
;*        15 AUG 2011 - C KENT    - CHANGED PIXEL THRESHOLD TO AN INTEGER
;*        25 AUG 2011 - C KENT    - FIXED BUG IN CHI STORAGE WITHIN OUTPUT ARRAY AND CSV
;*        16 SEP 2011 - C KENT    - ADDED TIME OUTPUT TO LOG FILE
;*        19 SEP 2011 - C KENT    - REMOVED MODISA EXCEPTION, ADDED CENTRE WAVELENGTH OUTPUT
;*        20 SEP 2011 - C KENT    - ADDED AMC OUTPUT TO CSV
;*
;* VALIDATION HISTORY:
;*        02 DEC 2010 - C KENT    - WINDOWS 32-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL. 
;*                                  RESULTS NOMINAL FOR AATSR VS ATSR2 OVER UYUNI IN 2003
;*        13 APR 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION AND OPERATION 
;*                                  NOMINAL, TESTED FOR MERIS VS MERIS AND MERIS VS MODIS
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION EXTRACT_DOUBLETS,OFOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,AMC_THRESHOLD,$
                          DAY_OFFSET,CLOUD_PERCENTAGE,ROI_PERCENTAGE,                         $
                          VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX,VERBOSE=VERBOSE

;-----------------------------------------
; CHECKS OFFSET AND PERCENTAGES ARE OK

  DAY_OFFSET        = FIX(DAY_OFFSET)
  CP_LIMIT          = FLOAT(CLOUD_PERCENTAGE)*.01
  RP_LIMIT          = FLOAT(ROI_PERCENTAGE)*.01

  IF  CP_LIMIT  GT 1.0 OR CP_LIMIT  LT 0.0 OR $
      RP_LIMIT  GT 1.0 OR RP_LIMIT  LT 0.0 THEN BEGIN
    PRINT, 'DOUBLET_EXTRACTION: ERROR, CLOUD/ROI PERCENTAGES OUT OF RANGE'
    RETURN,-1
  ENDIF
  
  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT,'DOUBLET_EXTRACTION: REGION = ',ED_REGION,' SENSOR1 = ',SENSOR1,' PROC_VER1 = ',PROC_VER1
    PRINT,'DOUBLET_EXTRACTION: REGION = ',ED_REGION,' SENSOR2 = ',SENSOR2,' PROC_VER2 = ',PROC_VER2
    PRINT,'DOUBLET_EXTRACTION: DAY_OFFSET = ',DAY_OFFSET,' CLOUD % = ',CP_LIMIT,' ROI % = ',RP_LIMIT
  ENDIF

;----------------------------------------- 
; CHECK INPUT SENSORS AND PROC_VERSIONS 

  IF STRCMP(SENSOR1,SENSOR2) EQ 1 AND $
     STRCMP(PROC_VER1,PROC_VER2) EQ 1 THEN BEGIN
    PRINT, 'DOUBLET_EXTRACTION: ERROR, TRYING TO COMPARE THE SAME DATA'
    RETURN,0     
  ENDIF
 
;-----------------------------------------
; GET THE CURRENT LOCATION AND DEFINE INPUT/OUTPUT FILES

  CFIG_DATA     = GET_DIMITRI_CONFIGURATION()
  DL            = GET_DIMITRI_LOCATION('DL')
  MAIN_DIRC     = GET_DIMITRI_LOCATION('DIMITRI')
  SITE_FILE     = GET_DIMITRI_LOCATION('SITE_DATA')
  DB_FILE       = GET_DIMITRI_LOCATION('DATABASE')

  ED_FOLDER     = STRING(OFOLDER+DL+'DOUBLET_EXTRACTION'+DL)
  ED_LOG        = STRING(ED_FOLDER+DL+'DOUBLET_EXTRACTION_LOG.txt')
  S1_IFILE      = STRING(MAIN_DIRC+'Input'+DL+'Site_'+ED_REGION+DL+SENSOR1+DL+'Proc_'+PROC_VER1+DL+SENSOR1+'_TOA_REF.dat')
  S2_IFILE      = STRING(MAIN_DIRC+'Input'+DL+'Site_'+ED_REGION+DL+SENSOR2+DL+'Proc_'+PROC_VER2+DL+SENSOR2+'_TOA_REF.dat')

  S1_OFILE      = STRING(ED_FOLDER+'ED_'+ED_REGION+'_'+SENSOR1+'_'+PROC_VER1+'_'+SENSOR2+'_'+PROC_VER2+'.dat')
  S2_OFILE      = STRING(ED_FOLDER+'ED_'+ED_REGION+'_'+SENSOR2+'_'+PROC_VER2+'_'+SENSOR1+'_'+PROC_VER1+'.dat')
  CSV_OFILE     = STRING(OFOLDER+DL+'ED_'+ED_REGION+'_'+SENSOR1+'_'+PROC_VER1+'_'+SENSOR2+'_'+PROC_VER2+'.csv')

  OUT_PLOT_REF  = STRING(ED_FOLDER+'ED_'+ED_REGION+'_'+SENSOR1+'_'+PROC_VER1+'_'+SENSOR2+'_'+PROC_VER2+'.jpg')
  OUT_PLOT_CAL  = STRING(ED_FOLDER+'ED_'+ED_REGION+'_'+SENSOR2+'_'+PROC_VER2+'_'+SENSOR1+'_'+PROC_VER1+'.jpg')

;--------------------------------
; CREATE DOUBLET EXTRACTION FOLDER IF IT DOESN'T EXIST

  RES = FILE_INFO(ED_FOLDER)
  IF RES.EXISTS NE 1 OR RES.DIRECTORY NE 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,"DIMITRI INTERFACE DOUBLET: DOUBLET FOLDER DOESN'T EXIST, CREATING"
    FILE_MKDIR,ED_FOLDER 
  ENDIF

;-----------------------------------------
; DEFINE SENSOR AND PROC_VERSION ARRAYS

  SENS = [SENSOR1,SENSOR2]
  PVER = [PROC_VER1,PROC_VER2]

;-----------------------------------------
; COMPUTE ROI AREA IN KM^2

  ICOORDS = GET_SITE_COORDINATES(ED_REGION,SITE_FILE,VERBOSE=VERBOSE)
  
  IF ICOORDS[0] EQ -1 THEN BEGIN
    PRINT,'DOUBLET_EXTRACTION: ERROR, REGION COORDINATES NOT FOUND'
    RETURN,-1
  ENDIF
  
  ROI_X     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[0],ICOORDS[3],/DEGREES)
  ROI_Y     = GREAT_CIRCLE_DISTANCE(ICOORDS[0],ICOORDS[2],ICOORDS[1],ICOORDS[2],/DEGREES)
  ROI_AREA  = FLOAT(ROI_X)*FLOAT(ROI_Y)
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: COMPUTED ROI AREA = ',ROI_AREA

;-----------------------------------------
; GET PIXEL AREA RESOLUTIONS OF SENSORS

  SPX_AREA    = MAKE_ARRAY(2,/FLOAT)
  SPX_AREA[0] = SENSOR_PIXEL_SIZE(SENSOR1,/AREA,VERBOSE=VERBOSE)
  SPX_AREA[1] = SENSOR_PIXEL_SIZE(SENSOR2,/AREA,VERBOSE=VERBOSE)

;-----------------------------------------
; DEFINE ROI PIX THRESHOLD FOR EACH SENSOR

  PX_THRESH     = MAKE_ARRAY(2,/INTEGER)
  PX_THRESH[0]  = FLOOR(DOUBLE(RP_LIMIT*ROI_AREA)/DOUBLE(SPX_AREA[0]))
  PX_THRESH[1]  = FLOOR(DOUBLE(RP_LIMIT*ROI_AREA)/DOUBLE(SPX_AREA[1]))
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: COMPUTED PX_THRESHOLDS = ',PX_THRESH

;-----------------------------------------
; RECORD THIS PROCESSING REQUEST IN A LOG

  TMP_DATE = SYSTIME()
  TMP_DATE = STRING(STRMID(TMP_DATE,8,2)+'-'+STRMID(TMP_DATE,4,3)+'-'+STRMID(TMP_DATE,20,4)+' '+strmid(tmp_date,11,8))
  TEMP = FILE_INFO(ED_LOG)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    OPENW, DLOG,ED_LOG,/GET_LUN
    PRINTF,DLOG,'DATE;REGION;SENSOR1;PROC_VER1;SENSOR2;PROC_VER2;AMC_THRESHOLD;DAY_OFFSET_LIMIT;CLOUD_PERCENTAGE;ROI_PERCENTAGE'
  ENDIF ELSE OPENW,DLOG,ED_LOG,/GET_LUN,/APPEND

  PRINTF,DLOG,FORMAT='(6(A,1H;),1(F6.3,1H;),1(I3,1H;),1(F6.3,1H;),1(F6.3))',$
  TMP_DATE,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,AMC_THRESHOLD,DAY_OFFSET,CP_LIMIT,RP_LIMIT

;----------------------------------------
; CLOSE LOG AND RELEASE THE LUN

  FREE_LUN,DLOG

;----------------------------------------
; READ THE DIMITRI DATABASE

  TEMP = FILE_INFO(DB_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, 'DOUBLET_EXTRACTION: ERROR, DIMITRI DATABASE FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: READING DIMITRI DATABASE'
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DB_DATA     = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;----------------------------------------
; RESTORE THE SENSOR TOA DATA

  RESTORE,S1_IFILE
  S1_ADATA = SENSOR_L1B_REF
  RESTORE,S2_IFILE
  S2_ADATA = SENSOR_L1B_REF 
  SENSOR_L1B_REF=0

;----------------------------------------
; LOOP OVER BOTH SENSORS TO EXTRACT DATA 
; WITHIN CLOUD/ROI PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: STARTING LOOP OVER BOTH SENSORS DATA'
  FOR EDS = 0,1 DO BEGIN
  
;----------------------------------------  
; SET ALL DATA VARIABLE  
  
    IF EDS EQ 0 THEN SENSOR_ALL_DATA = S1_ADATA
    IF EDS EQ 1 THEN SENSOR_ALL_DATA = S2_ADATA
  
    RES = WHERE(STRCMP(DB_DATA.REGION,ED_REGION)             EQ 1 AND $
                STRCMP(DB_DATA.SENSOR,SENS[EDS])             EQ 1 AND $
                STRCMP(DB_DATA.PROCESSING_VERSION,PVER[EDS]) EQ 1 AND $
                DB_DATA.NUM_ROI_PX GE PX_THRESH[EDS])            

    IF RES[0] EQ -1 THEN BEGIN
      PRINT, 'DOUBLET_EXTRACTION: ERROR, NO SENSOR DATA FOUND WITHIN PIXEL THRESHOLD'  
      RETURN,0
    ENDIF

;----------------------------------------
; GET A LIST OF DATES IN WHICH DATA IS ALSO 
; WITHIN THE CLOUD PERCENTAGE 

    GD_DATE = 0.0
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: STARTING LOOP OVER GOOD DATES FOR CLOUD PERCENTAGE'  
    FOR I_CS=0,N_ELEMENTS(RES)-1 DO BEGIN
    
      IF DB_DATA.MANUAL_CS[RES[I_CS]] GE 1.0 THEN CONTINUE
      IF DB_DATA.MANUAL_CS[RES[I_CS]] EQ 0.0 THEN BEGIN
        GD_DATE = [GD_DATE,DB_DATA.DECIMAL_YEAR[RES[I_CS]]]
        CONTINUE
      ENDIF  
      
    ;---------------------
    ; IF AUTO_CS IS LESS THAN PERCENTAGE BUT GREATER THAN -1.0 STORE DECIMAL DATE 
      
      IF DB_DATA.AUTO_CS[RES[I_CS]] LE CP_LIMIT AND DB_DATA.AUTO_CS[RES[I_CS]] GT -1.0 THEN $
      GD_DATE = [GD_DATE,DB_DATA.DECIMAL_YEAR[RES[I_CS]]]
    
    ENDFOR;END OF LOOP ON GOOD DATES

    IF N_ELEMENTS(GD_DATE) EQ 1 THEN BEGIN
       PRINT, 'DOUBLET_EXTRACTION: ERROR, NO SENSOR DATA FOUND WITHIN CLOUD THRESHOLD'
       RETURN,0
    ENDIF

;---------------------------------------
; EXTRACT GOOD DECIMAL DATES AND CORRESPONDING 
; INDEX IN ALL DATA VARIABLE    
  
    GD_DATE = GD_DATE[1:N_ELEMENTS(GD_DATE)-1]
    GD_IDX = MAKE_ARRAY(N_ELEMENTS(SENSOR_ALL_DATA[0,*]),/INTEGER,VALUE=0)
    TOL=0.0001
    FOR GD=0,N_ELEMENTS(GD_DATE)-1 DO BEGIN
      RES = WHERE(ABS(SENSOR_ALL_DATA[0,*]-GD_DATE[GD]) LE TOL AND $
                  SENSOR_ALL_DATA[1,*] GT VZA_MIN              AND $
                  SENSOR_ALL_DATA[1,*] LT VZA_MAX              AND $
                  SENSOR_ALL_DATA[2,*] GT VAA_MIN              AND $
                  SENSOR_ALL_DATA[2,*] LT VAA_MAX              AND $                
                  SENSOR_ALL_DATA[3,*] GT SZA_MIN              AND $
                  SENSOR_ALL_DATA[3,*] LT SZA_MAX              AND $
                  SENSOR_ALL_DATA[4,*] GT SAA_MIN              AND $
                  SENSOR_ALL_DATA[4,*] LT SAA_MAX              )                  
                  
      IF RES[0] GT -1 THEN GD_IDX[RES]=1
    ENDFOR ;END OF LOOP ON GOOD DATES TO FIND INDEX IN ALL_DATA ARRAY

;---------------------------------------
; DEFINE FINAL VARIABLES WHICH CONTAIN THE 
; ACCEPTABLE DATA

    RES = WHERE(GD_IDX EQ 1)
    IF RES[0] GT -1 THEN BEGIN
    IF EDS EQ 0 THEN GD_SENSOR1_DATA = SENSOR_ALL_DATA[*,RES]
    IF EDS EQ 1 THEN GD_SENSOR2_DATA = SENSOR_ALL_DATA[*,RES]
    ENDIF ELSE BEGIN
      PRINT, 'DOUBLET_EXTRACTION: ERROR DURING DOUBLET EXTRACTION, NO GOOD DATES FOUND FOR SENSOR ',SENS[EDS]
      RETURN,0
    ENDELSE
  ENDFOR ;END OF LOOP ON SENSOR1 AND SENSOR2 FILTERING
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: COMPLETED LOOP ON GOOD DATES FOR CLOUD TESTING'

;---------------------------------------
; FILTER OUT HIGH SZAS - REMOVED DUE TO ABSOLUTE ANGLE CHECK ON DATA
  
;  GD_SENSOR1_DATA=GD_SENSOR1_DATA[*,WHERE(FLOAT(GD_SENSOR1_DATA[3,*] LT 90.0))]
;  GD_SENSOR2_DATA=GD_SENSOR2_DATA[*,WHERE(FLOAT(GD_SENSOR2_DATA[3,*] LT 90.0))]

;---------------------------------------
; GET SIZE OF GOOD DATASETS
  
  SIZE_S1=SIZE(GD_SENSOR1_DATA)
  SIZE_S2=SIZE(GD_SENSOR2_DATA)
  
;---------------------------------------
; DEFINE THE NUMBER OF BANDS AND OUTPUT VARIABLES 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: DEFINING PARAMETERS AND OUTPUT ARRAYS'
  NUM_NON_REF         = 5+12 ;NUMBER OF VALUES BEFORE REFLECTANCE WITHIN ARRAY
  NUM_BANDS1          = (SIZE_S1[1]-NUM_NON_REF)/2
  NUM_BANDS2          = (SIZE_S2[1]-NUM_NON_REF)/2
  ED_SENSOR1_SENSOR2  = dblARR(2*NUM_BANDS1+NUM_NON_REF+1,SIZE_S1[2])
  ED_SENSOR2_SENSOR1  = dblARR(2*NUM_BANDS2+NUM_NON_REF+1,SIZE_S1[2])

;---------------------------------------
; LOOP OVER EACH DAY RECORD IN SENSOR1 
; AND FIND MATCHES

  ED_NO_DATA = 0
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: STARTING LOOP OVER EACH GOOD DAY IN SENSOR1'
  FOR I_DAY=0L,SIZE_S1[2]-1 DO BEGIN
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: COMPUTING FOR DAY ITERATION = ',I_DAY

;---------------------------------------
; COMPUTE DAY_OFFSET PARAMETER

    CURRENT_DAY=GD_SENSOR1_DATA[0,I_DAY]
    TEMP = FLOAT(FLOOR(CURRENT_DAY))
    IF (TEMP MOD 4) EQ 0 THEN DD=1./366.0 ELSE DD=1./365.0
    DD = DD*DAY_OFFSET

;---------------------------------------
; FIND THE NUMBER OF MATCHING DAYS AND 
; THEIR INDEX IN THE DATA 

    ID_MATCH_DAY = WHERE(ABS(GD_SENSOR2_DATA[0,*]-CURRENT_DAY) LE DD)
    IF ID_MATCH_DAY[0] EQ -1 THEN GOTO,NEXT_DAY
    NB_MATCHING_DATES=N_ELEMENTS(ID_MATCH_DAY)

;---------------------------------------  
; DEFINE VARIABLES TO HOLD THE CHI VALUES
    
    AMC_IDENT = FLTARR(NB_MATCHING_DATES)
    AMC_RECI  = FLTARR(NB_MATCHING_DATES)

;---------------------------------------  
; RETRIEVE CHI VALUES FOR MATCHING DATES
    
    FOR I_MATCH=0, NB_MATCHING_DATES-1 DO BEGIN
    
;-------------------------------
; SORT OUT RAA ANGLES

      AMC_IDENT[I_MATCH]= COMPUTE_AMC(GD_SENSOR1_DATA[3,I_DAY],$
                                      GD_SENSOR1_DATA[1,I_DAY],$
                                      GD_SENSOR1_DATA[2,I_DAY]-GD_SENSOR1_DATA[4,I_DAY],$
                                      GD_SENSOR2_DATA[3,ID_MATCH_DAY[I_MATCH]],$
                                      GD_SENSOR2_DATA[1,ID_MATCH_DAY[I_MATCH]],$
                                      GD_SENSOR2_DATA[2,ID_MATCH_DAY[I_MATCH]]-GD_SENSOR2_DATA[4,ID_MATCH_DAY[I_MATCH]])

      AMC_RECI[I_MATCH] = COMPUTE_AMC(GD_SENSOR1_DATA[3,I_DAY],$
                                      GD_SENSOR1_DATA[1,I_DAY],$
                                      GD_SENSOR1_DATA[2,I_DAY]-GD_SENSOR1_DATA[4,I_DAY],$
                                      GD_SENSOR2_DATA[1,ID_MATCH_DAY[I_MATCH]],$;THESE ARE THE VALUES CHANGED FOR RECIPROCAL ANALYSIS
                                      GD_SENSOR2_DATA[3,ID_MATCH_DAY[I_MATCH]],$;THESE ARE THE VALUES CHANGED FOR RECIPROCAL ANALYSIS
                                      GD_SENSOR2_DATA[2,ID_MATCH_DAY[I_MATCH]]-GD_SENSOR2_DATA[4,ID_MATCH_DAY[I_MATCH]])
  
    ENDFOR;END OF LOOP ON AMC COMPUTATION 

;---------------------------------------
; RETAIN ONLY THE BEST ANGULAR MATCH IF 
; THERE ARE SEVERAL MATCHES
    
    MIN_AMC_IDENT = MIN(AMC_IDENT, I_MATCH_IDENT)
    MIN_AMC_RECI  = MIN(AMC_RECI,  I_MATCH_RECI )

    IF MIN_AMC_IDENT LE MIN_AMC_RECI THEN BEGIN
      AMC=MIN_AMC_IDENT
      I_MATCH=I_MATCH_IDENT
      GEO_TYPE=1
    ENDIF ELSE BEGIN
      AMC=MIN_AMC_RECI
      I_MATCH=I_MATCH_RECI
      GEO_TYPE=-1
    ENDELSE

;---------------------------------------
; ONLY STORE THE DATA IF CHI IS BELOW 
; THRESHOLD VALUE

    IF AMC LT AMC_THRESHOLD THEN BEGIN ;5 FOR ANGLES AND TIME, 12 FOR AUX DATA, NUM BANDS * 2 PLUS CHI
        ED_SENSOR1_SENSOR2[0:NUM_BANDS1+NUM_NON_REF-1,I_DAY]  = GD_SENSOR1_DATA[0:NUM_BANDS1+NUM_NON_REF-1,I_DAY]
        ED_SENSOR1_SENSOR2[2*NUM_BANDS1+NUM_NON_REF,I_DAY]      = AMC 
        TT = NUM_BANDS1+NUM_NON_REF;+1 
        ED_SENSOR1_SENSOR2[TT:TT+NUM_BANDS1-1,I_DAY]          = GD_SENSOR1_DATA[TT:TT+NUM_BANDS1-1,I_DAY]
        
             
        ED_SENSOR2_SENSOR1[0:NUM_BANDS2+NUM_NON_REF-1,I_DAY]  = GD_SENSOR2_DATA[0:NUM_BANDS2+NUM_NON_REF-1,ID_MATCH_DAY[I_MATCH]]
        ED_SENSOR2_SENSOR1[2*NUM_BANDS2+NUM_NON_REF,I_DAY]      = AMC
        TT = NUM_BANDS2+NUM_NON_REF;+1 
        ED_SENSOR2_SENSOR1[TT:TT+NUM_BANDS2-1,I_DAY]          = GD_SENSOR2_DATA[TT:TT+NUM_BANDS2-1,ID_MATCH_DAY[I_MATCH]]
        ED_NO_DATA = 1
    ENDIF
    NEXT_DAY: ;IF NO MATCH WITHIN DAY_OFFSET

  ENDFOR ;END OF LOOP ON SENSOR1 DECIMAL DATE (DAYS)

  IF ED_NO_DATA EQ 0 THEN BEGIN
    PRINT,'DOUBLET_EXTRACTION: ERROR, NO VALUES BELOW AMC THRESHOLD RETRIEVED'
    RETURN,-1
  ENDIF

;----------------------------------------
; SAVE ONLY DATA WHERE MATCHES WERE FOUND

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: SAVING AND RETURNING ONLY THE GOOD DATA'
  ED_SENSOR1_SENSOR2=ED_SENSOR1_SENSOR2[*, WHERE(ED_SENSOR1_SENSOR2[0,*])]
  ED_SENSOR2_SENSOR1=ED_SENSOR2_SENSOR1[*, WHERE(ED_SENSOR2_SENSOR1[0,*])]
  SAVE,ED_SENSOR1_SENSOR2, FILENAME= S1_OFILE
  SAVE,ED_SENSOR2_SENSOR1, FILENAME= S2_OFILE
  
;----------------------------------------
; REFORM THE ARRAYS IF REQUIRED   
  
  IF N_ELEMENTS(ED_SENSOR1_SENSOR2) EQ 2*NUM_BANDS1+NUM_NON_REF+1 THEN BEGIN
    ED_SENSOR1_SENSOR2 = REFORM(ED_SENSOR1_SENSOR2,2*NUM_BANDS1+NUM_NON_REF+1,1)
    ED_SENSOR2_SENSOR1 = REFORM(ED_SENSOR2_SENSOR1,2*NUM_BANDS2+NUM_NON_REF+1,1)
  ENDIF
  
;---------------------------------------- 
; CREATE AN OUTPUT CSV FILE CONTAINING ALL DATA 
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: SAVING DATA AS A CSV FILE'
  NTIME = N_ELEMENTS(ED_SENSOR1_SENSOR2[0,*])
  HEADER = ['REGION','SENSOR','PROCESSING_VERSION','PARAMETER']
  TMP_HD = ['TIME','VZA','VAA','SZA','SAA','OZONE_MU','OZONE_SD','PRESSURE_MU','PRESSURE_SD','HUMIDITY_MU','HUMIDITY_SD', $
            'WIND_ZONAL_MU','WIND_ZONAL_SD','WIND_MERID_MU','WIND_MERID_SD','WVAP_MU','WVAP_SD'                           ]
  
  IF NTIME EQ 1 THEN FORMAT = STRING('(4(A,1H;),1(F20.10))') $
  ELSE FORMAT = STRING('(4(A,1H;),'+STRTRIM(STRING(NTIME-1),2)+'(F20.10,1H;),(F20.10))')
  
  OPENW,OUTF,CSV_OFILE,/GET_LUN
  PRINTF,OUTF,FORMAT=FORMAT,HEADER,ED_SENSOR1_SENSOR2[0,*]

;------------------------------------------------
; SETUP WINDOW PROPERTIES

  MACHINE_WINDOW = !D.NAME
  YMIN = 0.
  YMAX = 1.
  SET_PLOT, 'Z'
  DEVICE, SET_RESOLUTION=[CFIG_DATA.(1)[0],CFIG_DATA.(1)[1]],SET_PIXEL_DEPTH=24
  DEVICE, DECOMPOSED = 0
  ERASE  
  LOADCT, 39
  PLOT_FILES = [OUT_PLOT_REF,OUT_PLOT_CAL]

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DOUBLET_EXTRACTION: STARTING LOOP TO OUTPUT SENSOR DATA TO CSV'  
  FOR EDS=0,1 DO BEGIN
    IF EDS EQ 0 THEN BEGIN
      DATA = ED_SENSOR1_SENSOR2  
      TMP_BANDS = NUM_BANDS1
    ENDIF ELSE BEGIN
      DATA = ED_SENSOR2_SENSOR1
      TMP_BANDS = NUM_BANDS2
    ENDELSE
    MCOUNTER = 0
    SCOUNTER = 0
    LBANDS = STRARR(TMP_BANDS)    
    LCOLOR = INTARR(TMP_BANDS)

    ERASE
    PLOT,DATA[0,*],DATA[1,*],/NODATA,$
      COLOR = 0, BACKGROUND = 255,$
      YTITLE = SENS[EDS]+' DOUBLET TOA REFLECTANCE (DL)',$
      XTITLE = 'DECIMAL YEAR',$
      YRANGE = [YMIN,YMAX],$
      XRANGE = [FLOOR(min(DATA[0,*])),CEIL(max(DATA[0,*]))+1]
      XTICKFORMAT='((F8.3))'

    FOR DBEI=0,2*TMP_BANDS+NUM_NON_REF-1 DO BEGIN
      IF DBEI LE NUM_NON_REF-1 THEN PRINTF,OUTF,FORMAT=FORMAT,ED_REGION,SENS[EDS],PVER[EDS],TMP_HD[DBEI],DATA[DBEI,*] 
      IF (DBEI GT NUM_NON_REF-1) AND (DBEI LE TMP_BANDS+NUM_NON_REF-1) THEN BEGIN
        ;TBAND = CONVERT_INDEX_TO_WAVELENGTH(MCOUNTER,ED_SENS[EDS])
        TBAND = GET_SENSOR_BAND_NAME(SENS[EDS],MCOUNTER)
        IF tband ne 'ERROR' then begin
        PRINTF,OUTF,FORMAT=FORMAT,ED_REGION,SENS[EDS],PVER[EDS],'TOA_REF_'+TBAND,DATA[NUM_NON_REF+MCOUNTER,*] 
        LBANDS[MCOUNTER] = TBAND
        LCOLOR[MCOUNTER] = 250.*MCOUNTER/TMP_BANDS
        TT = WHERE(DATA[NUM_NON_REF+MCOUNTER,*] GT 0.0 AND DATA[NUM_NON_REF+MCOUNTER,*] LT 1.0,TCOUNT)
        IF TCOUNT GT 0 THEN begin
          OPLOT, DATA[0,*],DATA[NUM_NON_REF+MCOUNTER,TT],COLOR = LCOLOR[MCOUNTER]
          XYOUTS,0.88,0.9-0.035*MCOUNTER,'- '+LBANDS[MCOUNTER],COLOR=LCOLOR[mCOUNTER],/normal
      ENDIF
      endif
        MCOUNTER++
      ENDIF
      IF DBEI GT TMP_BANDS+NUM_NON_REF-1 THEN BEGIN
        ;TBAND = CONVERT_INDEX_TO_WAVELENGTH(SCOUNTER,ED_SENS[EDS])
        TBAND = GET_SENSOR_BAND_NAME(SENS[EDS],SCOUNTER)
      if tband ne 'ERROR' then PRINTF,OUTF,FORMAT=FORMAT,ED_REGION,SENS[EDS],PVER[EDS],'TOA_REF_STD_'+TBAND,DATA[NUM_NON_REF+TMP_BANDS+SCOUNTER,*] 
        SCOUNTER++    
      ENDIF
    ENDFOR

   ; LEGEND,LBANDS,COLOR=LCOLOR,/RIGHT

    TEMP = TVRD(TRUE=1)
    WRITE_JPEG,PLOT_FILES[EDS],TEMP,TRUE=1,QUALITY=100
    ERASE

  ENDFOR 
  
;------------------------------------------------ 
; PRINT OUT THE AMC VALUE

  PRINTF,OUTF,FORMAT=FORMAT,ED_REGION,'NULL','NULL','AMC',DATA[N_ELEMENTS(DATA[*,0])-1,*]

;------------------------------------------------ 
; RESET WINDOW PROPERTIES AND CLOSE OUTPUT
  
  SET_PLOT, MACHINE_WINDOW
  FREE_LUN,OUTF
  RETURN,1

END

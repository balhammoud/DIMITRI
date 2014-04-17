;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_NEW_SITE_WD    
;* 
;* PURPOSE:
;*      THE FILE CONTAINS A NUMBER OF PROGRAMS WHICH GENERATE THE NEW SITE CREATION 
;*      MODULE FOR DIMITRI. THE WIDGET ALLOWS USERS TO SELECT A NEW SITE NAME, 
;*      THE SITE TYPE, AND THE SITE'S COORDINATES.
;*
;*      THE PROGRAM CREATES A NEW FOLDER FOR THE SITE AND INCLUDES FOLDERS FOR EVERY 
;*      SENSOR CONFIGURATION CURRENTLY USED IN DIMITRI.
;*
;*      THE WIDGET UTILISES THE FSC_FIELD PR0GRAM WRITTEN BY D. FANNING (WWW.IDLCOYOTE.COM) 
;*
;* CALLING SEQUENCE:
;*      DIMITRI_NEW_SITE_WD      
;* 
;* INPUTS:
;*      
;* KEYWORDS:
;*      GROUP_LEADER - THE ID OF ANOTHER WIDGET TO BE USED AS THE GROUP LEADER
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*      
;* OUTPUTS:
;*      AN INTERACTIVE WIDGET ALLOWING THE ADDITION OF NEW SITES TO DIMITRI 
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*      23 FEB 2010 - C KENT    - DIMITRI-2 V1.0
;*      25 FEB 2010 - C KENT    - ADDED GROUP_LEADER KEYWORD, CHANGED INFO TO NS_INFO 
;*      21 MAR 2011 - C KENT    - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*      06 JUL 2011 - C KENT    - ADDED DATABASE COMMON BLOCK TO DIMITRI HMI
;*
;* VALIDATION HISTORY:
;*      14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                COMPILATION AND OPERATION 
;*
;**************************************************************************************
;**************************************************************************************

PRO NEW_SITE_TYPE_CHANGE,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=NS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------------------
; GET THE TYPE INDEX AND UPDATE DEPENDING 
; ON WHICH BUTTON IS PRESSED

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->CHANGE: UPDATING SITE TYPE INDEX'
  IDX = NS_INFO.TIDX

  CASE ACTION OF
    '>':IDX = IDX+1
    '<':IDX = IDX-1
  ENDCASE

  IF IDX LT 0 THEN IDX = N_ELEMENTS(NS_INFO.TYPES)-1
  IF IDX GE N_ELEMENTS(NS_INFO.TYPES) THEN IDX = 0

;--------------------------------------
; SAVE THE NEW INDEX VALUE, UPDATE THE 
; FIELD AND RETURN TO THE WIDGET

  IF NS_INFO.IVERBOSE EQ 1 THEN $
    PRINT,'DIMITRI_NEW_SITE_WD->CHANGE: UPDATING SITE TYPE AND RETURNING TO THE WIDGET'
  NS_INFO.TIDX=IDX
  NS_INFO.SITE_TYPE->SETPROPERTY, VALUE=NS_INFO.TYPES[IDX]
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=NS_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO NEW_SITE_EVENT_GO,EVENT
  
  COMMON DHMI_DATABASE
  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=NS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------------------
; GET SITE_NAME AND SITE_TYPE VALUES

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: RETRIEVEING SITE NAME AND TYPE VALUES'
  S_NAME = NS_INFO.SITE_NAME->GET_VALUE()
  S_TYPE = NS_INFO.SITE_TYPE->GET_VALUE()

;--------------------------------------
; REPLACE SPACE CHARACTERS WITH UNDERSCORES

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CHECKING NAME FOR SPACES'
  RES = STRSPLIT(S_NAME,' ',/EXTRACT)
  IF N_ELEMENTS(RES) GT 1 THEN BEGIN
    MSG = ['Warning, Site Name Error Indentified:','',$
          'Site Name contains SPACE characters',     $
          'Converting to underscores...']
    TMP = DIALOG_MESSAGE(MSG,/ERROR,/CENTER,TITLE=NS_INFO.MSG_TITLE)
    S_NAME=STRJOIN(RES,'_')
  ENDIF

;--------------------------------------
; GET COORDINATE VALUES

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: RETRIEVEING SITE COORDINATES'
  S_NLAT = NS_INFO.NLAT->GET_VALUE() & S_SLAT = NS_INFO.SLAT->GET_VALUE()
  S_WLON = NS_INFO.WLON->GET_VALUE() & S_ELON = NS_INFO.ELON->GET_VALUE()

  S_NLAT = FLOAT(S_NLAT) & S_SLAT = FLOAT(S_SLAT)
  S_WLON = FLOAT(S_WLON) & S_ELON = FLOAT(S_ELON)

;--------------------------------------
; SET INITIAL ERROR VALUES AS NULL

  LAT_ERR = 0 & LAT_ERROR = ''
  LON_ERR = 0 & LON_ERROR = ''

;--------------------------------------
; CHECK FOR LAT/LON ERRORS

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CHECKING COORDINATE CONSISTENCY'
  IF S_SLAT GT S_NLAT THEN BEGIN
    LAT_ERROR = 'Error: South Lat > North Lat'
    LAT_ERR = 1
  ENDIF 
  IF S_WLON GT S_ELON THEN BEGIN
    LON_ERROR = 'Error: West Lon > East Lon'
    LON_ERR = 1
  ENDIF

;--------------------------------------
; IF ERRORS FOUND THEN REPORT AND CLOSE

  IF LAT_ERR+LON_ERR GT 0 THEN BEGIN
    MSG = ['Warning, Coordinate Error Indentified:','',LAT_ERROR,LON_ERROR]
    RES = DIALOG_MESSAGE(MSG,/ERROR,/CENTER,TITLE=NS_INFO.MSG_TITLE)
    WIDGET_CONTROL, EVENT.TOP, /DESTROY 
    DIMITRI_NEW_SITE_WD
    RETURN
  ENDIF

;--------------------------------------
; CHECK IF THE SITE_NAME ALREADY EXISTS

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CHECKING IF SITE NAME ALREADY EXISTS'
  RES = WHERE(NS_INFO.SITE_DATA.SITE_ID EQ S_NAME,COUNT)
  IF COUNT GT 0 THEN BEGIN
    MSG = ['Warning, Site Name Error Indentified:','','Site Name already registered']
    TMP = DIALOG_MESSAGE(MSG,/ERROR,/CENTER,TITLE=NS_INFO.MSG_TITLE)
    WIDGET_CONTROL, EVENT.TOP, /DESTROY 
    DIMITRI_NEW_SITE_WD
    RETURN
  ENDIF

;--------------------------------------
; CREATE SITE FOLDER

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CREATING SITE FOLDER'  
  SITE_FOLDER = NS_INFO.INFOLDER+'Site_'+S_NAME
  FILE_MKDIR, SITE_FOLDER

;--------------------------------------
; UPDATE SITE INFO FILE

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: UPDATING SITE INFO FILE'  
  OPENW,OUTF,NS_INFO.SITE_FILE,/GET_LUN,/APPEND
  PRINTF,OUTF,FORMAT=NS_INFO.SITE_FORMAT,S_NAME,S_TYPE,S_NLAT,S_SLAT,S_ELON,S_WLON
  FREE_LUN,OUTF

;--------------------------------------
; GET LIST OF SENSOR CONFIGURATIONS 

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: GETTING LIST OF KNOWN SENSOR CONFIGURATIONS'
  TMP_NAMES     = DHMI_DB_DATA.SENSOR+'_'+DHMI_DB_DATA.PROCESSING_VERSION
  TMP_NAMES     = TEMPORARY(TMP_NAMES[UNIQ(TMP_NAMES)])
  UNIQ_SENSORS  = DHMI_DB_DATA.SENSOR[UNIQ(DHMI_DB_DATA.SENSOR)]

;--------------------------------------
; DEFINE ARRAY OF YEARS TO BE CREATED

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: DEFINING NUMBER OF YEARS FOLDERS'
  RES       = SYSTIME()
  FIRSTYEAR = 2002
  THISYEAR  = FIX(STRMID(RES,20,4))
  NYEARS    = (THISYEAR-FIRSTYEAR)+1
  YEARS     = INDGEN(NYEARS)+FIRSTYEAR

;--------------------------------------
; CREATE SENSOR FOLDERS WITHIN SITE FOLDER

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CREATING THE SENSOR FOLDERS WITHIN THE NEW SITE'
  FOR I = 0,N_ELEMENTS(UNIQ_SENSORS)-1 DO FILE_MKDIR,SITE_FOLDER+NS_INFO.DL+UNIQ_SENSORS[I]

;--------------------------------------
; CREATE FOLDERS FOR EACH YEAR WITHIN 
; EACH SENSOR CONFIGURATION

  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->GO: CREATING EACH SENSORS CONFIGURATION'  
  FOR I=0,N_ELEMENTS(TMP_NAMES)-1 DO BEGIN
    TMP  = STRPOS(TMP_NAMES[I],'_')
    SENS = STRMID(TMP_NAMES[I],0,TMP)
    CFIG = 'Proc_'+STRMID(TMP_NAMES[I],TMP+1,STRLEN(TMP_NAMES[I])-TMP)
    TFOL = SITE_FOLDER+NS_INFO.DL+SENS+NS_INFO.DL+CFIG
    FILE_MKDIR, TFOL
    FOR J=0,NYEARS-1 DO FILE_MKDIR,TFOL+NS_INFO.DL+STRTRIM(STRING(YEARS[J]),2)
  ENDFOR
  
;--------------------------------------
; REPORT SITE CREATION COMPLETE  
  
  MSG = ['Successfully Created Site:','',S_NAME]
  TMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER,TITLE=NS_INFO.MSG_TITLE)
  WIDGET_CONTROL, EVENT.TOP, /DESTROY 

END

;**************************************************************************************
;**************************************************************************************

PRO NEW_SITE_EVENT_EXIT,EVENT

;--------------------------------------
; DESTROY THE WIDGET  

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=NS_INFO, /NO_COPY
  IF NS_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_NEW_SITE_WD->EXIT: DESTROYING THE WIDGET'
  WIDGET_CONTROL, EVENT.TOP, /DESTROY 

END

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

PRO DIMITRI_NEW_SITE_WD,VERBOSE=VERBOSE,GROUP_LEADER=GROUP_LEADER

; NOTE, USES D FANNINGS FSC_FIELD.PRO, SEE WWW.IDLCOYOTE.COM FOR MORE DETAILS
  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT, 'DIMITRI_NEW_SITE_WD: STARTING NEW SITE MODULE'
    IVERBOSE=1
  ENDIF ELSE IVERBOSE=0

  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0

;--------------------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  DL = GET_DIMITRI_LOCATION('DL')
  INFOLDER = GET_DIMITRI_LOCATION('INPUT')
  TYPE_FILE = GET_DIMITRI_LOCATION('SITE_TYPES')
  SITE_FILE = GET_DIMITRI_LOCATION('SITE_DATA')

;--------------------------------------
; GET SITE TYPES
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: RETRIEVING SITE TYPES' 
  TEMP  = STRING(READ_BINARY(TYPE_FILE))
  TEMP  = STRSPLIT(TEMP,STRING(STRING(10B)+STRING(13B)),/EXTRACT)
  TYPES = TEMP[1:N_ELEMENTS(TEMP)-1]
  TIDX  = 0 
  
;--------------------------------------
; GET LIST OF REGISTERED SITES
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: RETRIEVING LIST OF REGISTERED SITES' 
  SITE_TEMPLATE = GET_DIMITRI_SITE_DATA_TEMPLATE()     
  SITE_DATA     = READ_ASCII(SITE_FILE,TEMPLATE=SITE_TEMPLATE)

;--------------------------------------
; GET DATABASE DATA

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
  PRINT,'DIMITRI_NEW_SITE_WD: DEFINING FOLDERS AND INPUT FILES' 
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE,/VERBOSE)
  ENDIF ELSE DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)

;--------------------------------------
; DEFINE MESSAGE TITLE AND FORMAT FOR OUTPUT

  MSG_TITLE   = 'DIMITRI V2.0: Site Creator'
  SITE_FORMAT = '(2(A,1H;),3(F15.5,1H;),1(F15.5))'

;------------------------------------ 
; GET THE DISPLAY RESOLUTION FOR WIDGET POSITIONING

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: RETRIEVEING SCREEN DIMENSIONS FOR WIDGET' 
  DIMS  = GET_SCREEN_SIZE()
  IF WIN_FLAG THEN BEGIN
  XSIZE = 420 
  YSIZE = 290
  ENDIF ELSE BEGIN
  XSIZE=500
  YSIZE = 310
  ENDELSE
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

;------------------------------------ 
; DEFINE WIDGET BASES, BUTTONS AND FSC_FIELDS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: DEFINING WIDGET BASES AND BUTTONS' 
  SITE_TLB= WIDGET_BASE(TITLE='DIMITRI 2.0: NEW SITE MODULE',COLUMN=1,      $
                        XOFFSET=XLOC,YOFFSET=YLOC,XSIZE=XSIZE,YSIZE=YSIZE)
  
  TLB_TOP = WIDGET_BASE(SITE_TLB,COLUMN=1,FRAME=1)
  
  TLB_LBL = WIDGET_BASE(TLB_TOP,COLUMN=1) 
  TMP_LBL = WIDGET_LABEL(TLB_LBL,VALUE='SITE INFORMATION :')
  TMP_LBL = WIDGET_LABEL(TLB_LBL,VALUE='')
  
  TLB_DAT1 = WIDGET_BASE(TLB_TOP,ROW=2)
  TMPY     = 32
  TMPX     = 20
  
  ;TLB_DAT2 = WIDGET_BASE(TLB_DAT1,COL=1)
  NAME_ID  = FSC_FIELD(TLB_DAT1, TITLE='Site Name : ', Value='New_Site_Name' , OBJECT=SITE_NAME)
  TMP      = WIDGET_LABEL(TLB_DAT1, VALUE='',  YSIZE=TMPY)   
  TMP      = WIDGET_LABEL(TLB_DAT1, VALUE='',  YSIZE=TMPY)
  
  IF WIN_FLAG THEN TYPE_ID  = FSC_FIELD(TLB_DAT1, TITLE='Site Type  :',Value=TYPES[0]        , OBJECT=SITE_TYPE,/NOEDIT) $
    ELSE TYPE_ID  = FSC_FIELD(TLB_DAT1, TITLE='Site Type : ',Value=TYPES[0]        , OBJECT=SITE_TYPE,/NOEDIT)
    ;TLB_DAT3 = WIDGET_BASE(TLB_DAT1,ROW=2) 
  TMP      = WIDGET_BUTTON(TLB_DAT1,VALUE='<',XSIZE=TMPX,UVALUE= '<',EVENT_PRO='NEW_SITE_TYPE_CHANGE')
  TMP      = WIDGET_BUTTON(TLB_DAT1,VALUE='>',XSIZE=TMPX,UVALUE= '>',EVENT_PRO='NEW_SITE_TYPE_CHANGE')
     
  TMP_LBL  = WIDGET_LABEL(TLB_TOP,  VALUE='',/ALIGN_CENTER)
  TMP_LBL  = WIDGET_LABEL(TLB_TOP,  VALUE='COORDINATES :',/ALIGN_LEFT)

  TLB_COOR = WIDGET_BASE(TLB_TOP,   COLUMN=3)
  TLB_LFT  = WIDGET_BASE(TLB_COOR,  ROW=3)
  TMP      = WIDGET_LABEL(TLB_LFT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  TMP      = WIDGET_LABEL(TLB_LFT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  WLON_ID  = FSC_FIELD(TLB_LFT, TITLE='W. Lon:',VALUE=-180.0,OBJECT=WLON,XSIZE=10)
  TMP      = WIDGET_LABEL(TLB_LFT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  TMP      = WIDGET_LABEL(TLB_LFT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
        
  TLB_MID  = WIDGET_BASE(TLB_COOR,  ROW=3) 
  NLAT_ID  = FSC_FIELD(TLB_MID, TITLE='N. Lat:', VALUE=90.0, OBJECT=NLAT,XSIZE=10)
  TMP      = WIDGET_LABEL(TLB_MID,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  TMP      = WIDGET_LABEL(TLB_MID,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  SLAT_ID  = FSC_FIELD(TLB_MID, TITLE='S. Lat:', VALUE=-90.0,OBJECT=SLAT,XSIZE=10)
 
  TLB_RHT  = WIDGET_BASE(TLB_COOR,  ROW=3) 
  TMP      = WIDGET_LABEL(TLB_RHT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  TMP      = WIDGET_LABEL(TLB_RHT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  ELON_ID  = FSC_FIELD(TLB_RHT, TITLE='E. Lon:', VALUE=180.0,OBJECT=ELON,XSIZE=10)
  TMP      = WIDGET_LABEL(TLB_RHT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  TMP      = WIDGET_LABEL(TLB_RHT,  VALUE='',XSIZE=TMPX,  YSIZE=TMPY)
  
  TLB_BASE = WIDGET_BASE(SITE_TLB,  ROW=1,/ALIGN_RIGHT)
  TMP      = WIDGET_BUTTON(TLB_BASE,VALUE='OK',   XSIZE=70,/ALIGN_CENTER,EVENT_PRO='NEW_SITE_EVENT_GO')
  TMP      = WIDGET_BUTTON(TLB_BASE,VALUE='Exit', XSIZE=70,/ALIGN_CENTER,EVENT_PRO='NEW_SITE_EVENT_EXIT')

;------------------------------------ 
; DEFINE STRUCTURE TO HOLD ALL DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: STORING DATA INTO A STRUCTURE' 
  NS_INFO     = {                              $
              SITE_NAME     : SITE_NAME     ,$
              SITE_TYPE     : SITE_TYPE     ,$
              SITE_DATA     : SITE_DATA     ,$
              MSG_TITLE     : MSG_TITLE     ,$
              INFOLDER      : INFOLDER      ,$
              SITE_FILE     : SITE_FILE     ,$
              SITE_FORMAT   : SITE_FORMAT   ,$
              DL            : DL            ,$
              NLAT          : NLAT          ,$
              SLAT          : SLAT          ,$
              WLON          : WLON          ,$
              ELON          : ELON          ,$
              TYPES         : TYPES         ,$
              IVERBOSE      : IVERBOSE      ,$
              TIDX          : TIDX           $
              }

;------------------------------------ 
; REALISE THE WIDGET AND REGISTER 
; WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_NEW_SITE_WD: REALISING THE WIDGET' 
  IF KEYWORD_SET(GROUP_LEADER) THEN WIDGET_CONTROL, SITE_TLB, /REALIZE, SET_UVALUE=NS_INFO, /NO_COPY,GROUP_LEADER=GROUP_LEADER $
    ELSE WIDGET_CONTROL, SITE_TLB, /REALIZE, SET_UVALUE=NS_INFO, /NO_COPY
  XMANAGER,'NEW_SITE_OBJECT', SITE_TLB
  
END
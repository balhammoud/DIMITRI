;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      COMPUTE_AMC_ROUTINES       
;* 
;* PURPOSE:
;*      THIS FILE CONTAINS ROUTINES REQUIRED FOR COMPUTING THE ANGULAR MATCHING AMC VALUE. 
;*      THE EQUATION FOR AMC CAN BE FOUND IN BOUVET M., INTERCOMPARISON OF IMAGING 
;*      SPECTROMETER OVER THE SALAR DE UYUNI (BOLIVIA), PROCEEDINGS OF THE 2006 
;*      MERIS AATSR VALIDATION TEAM WORKSHOP 
;* 
;* CALLING SEQUENCE:
;*      RES = COMPUTE_AMC(SZA_A,VZA_A,RAA_A,SZA_B,VZA_B,RAA_B)      
;*      RES = COMPUTE_AMC_THRESHOLD(DIFF_SZA,DIFF_VZA,DIFF_RAA)
;* INPUTS:
;*      SZA_A - 1ST VALUE OF SZA (DEGREES)      
;*      VZA_A - 1ST VALUE OF VZA (DEGREES)
;*      RAA_A - 1ST VALUE OF RAA (DEGREES)
;*      SZA_B - 2ND VALUE OF SZA (DEGREES)
;*      VZA_B - 2ND VALUE OF VZA (DEGREES)
;*      RAA_B - 2ND VALUE OF RAA (DEGREES)
;*
;*      DIFF_SZA - THE DIFFERENCE IN SZA (DEGREES)      
;*      DIFF_VZA - THE DIFFERENCE IN VZA (DEGREES)
;*      DIFF_RAA - THE DIFFERENCE IN ABSOLUTE RAA (DEGREES)
;*
;* KEYWORDS:
;*      VERBOSE - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      AMC - THE COMPUTED AMC VALUE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      10 JAN 2011 - C KENT    - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      10 JAN 2011 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1: NOMINAL VALUES FOR 
;*                                MULTIPLE ANGLES INPUT
;*      13 APR 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: NOMINAL COMPILATION 
;*                                AND RESULTS
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION COMPUTE_AMC,SZA_A,VZA_A,RAA_A,SZA_B,VZA_B,RAA_B,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'COMPUTE AMC: STARTING AMC COMPUTATION'
  S1 = (SZA_A-SZA_B)^2
  S2 = (VZA_A-VZA_B)^2
  S3 = (1.0/4.0)*(ABS(RAA_A)-ABS(RAA_B))^2
  AMC = SQRT(S1+S2+S3) 

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'COMPUTE AMC: VALUE = ',AMC
  RETURN,AMC

END

FUNCTION COMPUTE_AMC_THRESHOLD,DIFF_SZA,DIFF_VZA,DIFF_RAA,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'COMPUTE AMC: STARTING AMC THRESHOLD COMPUTATION'
  S1 = DIFF_SZA^2
  S2 = DIFF_VZA^2
  S3 = (1.0/4.0)*DIFF_RAA^2
  AMC = SQRT(S1+S2+S3) 

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'COMPUTE AMC THRESHOLD: VALUE = ',AMC
  RETURN,AMC

END
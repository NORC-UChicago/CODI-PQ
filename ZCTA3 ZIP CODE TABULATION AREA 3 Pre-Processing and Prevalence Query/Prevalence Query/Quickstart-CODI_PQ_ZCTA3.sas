/*******************************************************************************************/
/***PROGRAM: Quickstart-CODI_PQ_ZCTA3.SAS												 ***/
/***VERSION: 1.0 																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC)														 ***/
/***DATE CREATED: 10/15/2019, DATE LAST MOD: 7/24/2020									 ***/
/***INPUT: PREPROCESSED CHILDHOOD and TEEN OBESITY EHR DATA 							 ***/
/***INPUT: AMERICAN COMMUNITY SURVEY (ACS) DATA 										 ***/
/***INPUT: USER SELECTION CRITERIA (SECTIONS 1 THROUGH 4 BELOW), 					     ***/
/***OUTPUT: PREVALENCE ESTIMATES BASED ON SELECTION CRITERIA.							 ***/
/***OBJECTIVE: DATA AND USER SELECTIONS WILL BE USED TO QUERY THE OBESITY DATA. 		 ***/
/***OBJECTIVE: PROGRAM COMPUTES STATISTICAL WEIGHTS, AND GENERATES 					 	 ***/
/***OBJECTIVE: WEIGHTED AND UNWEIGHTED OBESITY PREVALENCE ESTIMATES  					 ***/
/***PREVALENCE ESTIMATES STORE: IN A COMMA SEPERATED VALUE (CSV) FILE					 ***/
/*******************************************************************************************/

/*************************************************************************************************************************************/
/***************************************** -- USER SELECTION CRITERA SECTIONS 1 through 4 -- *****************************************/
/******************* -- PLEASE UPDATE THE BLACK TEXT AFTER THE EQUAL SIGN (ACCEPTED VALUES LISTED IN SAS NOTE) -- ********************/
/*SECTION 1: Folder and file names									  													   		   ***/
/***/ %LET ROOT_PQ		= P:\Example;	/*@Note: base directory (ACCEPTABLE VALUES: computer directory name)		   		   ***/
/***/ %LET PROGS_PQ		= &Root_PQ.\0 SAS Programs\; /*@Note: Location of SAS programs (ACCEPTABLE VALUES: computer directory name)	***/
/***/ %LET PRE_DEST		= CODI_PQ_ZCTA3; /*@Note: Suffix name of pre-processing output folder (ACCEPTABLE VALUES: folder name (no punctuations)) ***/
/***/ %LET EHR_PRE_OUT	= CODI_PQ_ZCTA3; /*@Note: Suffix name of pre-processing output file (ACCEPTABLE VALUES: file name (no punctuations)) ***/
/***/ %LET LOG_NAME		= CODI_ZCTA3_PREVALENCE_QUERY; /*@Note: Name for SAS log storage location            								   ***/

/*SECTION 2: Subset data based on specifications INCLUDING YEAR, GEOGRAPHY, STATE OR STATE/COUNTY CODE							   ***/
/***/ %LET BEG_YEAR		 = 2016; /*@Note: Beginning year of analysis				 (ACCEPTED VALUES: 4-Digit numeric, 2016-2018) ***/
/***/ %LET END_YEAR		 = 2018; /*@Note: End year of analysis 						 (ACCEPTED VALUES: 4-Digit numeric, 2016-2018) ***/
/***/ %LET ALL_STATES	 = N;  	 /*@Note: Include all geographical locations in file?(ACCEPTED VALUES: Y/N)						   ***/
/***/ %LET ALL_AGES		 = Y;	 /*@Note: Include all age ranges? 					 (ACCEPTED VALUES: Y/N) 			 		   ***/
/***/ %LET ALL_SEXES	 = Y;	 /*@Note: Include all sex values? 					 (ACCEPTED VALUES: Y/N) 			 		   ***/
/***/ %LET ALL_RACES	 = Y; 	 /*@Note: Include all race categories? 				 (ACCEPTED VALUES: Y/N)			 			   ***/

/*SECTION 3: Only complete section 3 for any "N" values listed in section 2														   ***/
/*IF ALLGEOGRAPHIES= N THEN SELECT STATE CODES OR STATE AND COUNTY CODES BELOW:													   ***/
	/***  (ACCEPTED VALUES: SINGLE QUOTES SURROUNDING 2 OR 5-Digit CODES w/ "," BETWEEN MULTIPLE SELECTIONS, ) 				  	   ***/
/*IF ALLSTATES = N THEN SELECT ONE OR MORE AGE CATEGORIES BELOW:															   ***/
	/***/ %LET GEO_GROUP  	 = ZCTA3; 	   /*@Note: Level of geography 					(ACCEPTED VALUES: STATE/ZCTA3)		   ***/
	/***/ %LET GEO_LIST	  	 = %STR('39447'); /*@Note: IF GEO_GROUP="STATE" then populate with State FIPS code(s), If GEO_GROUP="ZCTA3" then populate with FIPS State+FIPS County code(s) ***/
/*IF ALL_AGES = N THEN SELECT ONE OR MORE AGE CATEGORIES BELOW:																	   ***/
	/***/ %LET AGE_2_4	  = Y;	 /*@Note: Age Range: 2 to 4 						(ACCEPTED VALUES: Y/N) 			 	   	   ***/
	/***/ %LET AGE_5_9	  = Y;	 /*@Note: Age Range: 5 to 9 						(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET AGE_10_14  = Y;	 /*@Note: Age Range: 10 to 14 						(ACCEPTED VALUES: Y/N) 			 	   	   ***/
	/***/ %LET AGE_15_17  = Y;	 /*@Note: Age Range: 15 to 17 						(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET AGE_18_19  = Y;	 /*@Note: Age Range: 18 to 19 						(ACCEPTED VALUES: Y/N) 			 	       ***/
/*IF ALL_RACES = N THEN SELECT ONE OR MORE RACE BELOW:																			   ***/
	/***/ %LET RACE_WHITE  = Y;	 /*@Note: White 									(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_BLACK  = Y;	 /*@Note: Black/African American 					(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_ASIAN  = Y;	 /*@Note: Asian 									(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_OTHER  = Y;	 /*@Note: Other								 		(ACCEPTED VALUES: Y/N)				       ***/
/*IF ALL_SEXES = N THEN SELECT MALE OR FEMALE BELOW:																			   ***/
	/***/ %LET SEX_MALE	   = Y;	 /*@Note: Sex: Male 								(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET SEX_FEMALE  = Y;	 /*@Note: Sex: Female 								(ACCEPTED VALUES: Y/N) 			 	       ***/

/*SECTION 4: Methodological option selections						  														   	   ***/
	/***/ %LET IMP_RACES = Y; 	 /*@Note: Include imputed race values? 				(ACCEPTED VALUES: Y/N)			 		   ***/
	/***/ %LET AGE_ADJ	 = Y;	 /*@Note: Produce age-adjusted estimates?			(ACCEPTED VALUES: Y/N) 			 	 	   ***/
/*************************************************************************************************************************************/
/***Note: Root directory includes subfolders: 
								"..\0 SAS Programs"
								"..\00 Raw Data" 
								"..\1 Output" and 
								"..\1 Output\SAS LOGS"										   									   ***/
/***NOTE: SAS programs must be stored in the PROGS directory including: 
								Macro1-CODI_PQ.sas, 
								Macro2-CODI_PQ.sas, 
								Macro3-CODI_PQ.sas, 
								Macro4-CODI_PQ.sas, 
								Module1-CODI_PQ.sas, and 
								Module2-CODI_PQ.sas																				   ***/
/***NOTE: query output is stored as a csv file in "..\1 Output" named after a time/date stamp and CODI_Prevalence_Query_Report     ***/
/*************************************************************************************************************************************/
/***STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP*/
/*** DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT    */
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/














/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/***STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP*/
/*** DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT    */
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/











/*@Action: Set SAS options ***/
OPTIONS FULLSTIMER NOFMTERR MLOGIC MPRINT MINOPERATOR SYMBOLGEN COMPRESS=YES;

/*************************************************************************************************************************/
/******************************* -- ADDITIONAL INFORMATION REQUIRED BY PQ MODULE PROGRAMS -- *****************************/
/************************************** -- THIS INFORMATION IS TO REMAIN UNCHANGED -- ************************************/
/*************************************************************************************************************************/
/***/ %LET DateTime		   = %SYSFUNC(Translate(%Quote(%SYSFUNC(COMPBL(%QUOTE(%SYSFUNC(Datetime(),DateAMPM.))))),%Str(___),%Str( ,:))); /*@Note: Date time of SAS run, DO NOT CHANGE ***/
/***/ %LET DateTime2	   = %SYSFUNC(COMPBL(%QUOTE(%SYSFUNC(Today(),Weekdate.) %SYSFUNC(Time(), timeampm.)))); /*@Note: Date and time of run (Report Output) ***/
/***/ %LET FileIN_Name1	   = Pre_Processed_&EHR_PRE_OUT.;  /*@Note: EHR Data file name			   					   ***/
/***/ %LET FileIN_Name2	   = ACS_State_ZCTA3;			   /*@Note: ACS file name					   				   ***/
/***/ %LET FileOUT_Name    = CODI_ZCTA3_Prevalence_Query_Report; /*@Note: Output file name				   				   ***/
/***/ %LET ACS_Module      = Macro1-CODI_PQ_ZCTA3;		   /*@Note: Name of ACS Controls SAS Macro	   				   ***/
/***/ %LET Weight_Module   = Macro2-CODI_PQ_ZCTA3;		   /*@Note: Name of Weighting SAS Macro		   				   ***/
/***/ %LET Suppress_Module = Macro3-CODI_PQ_ZCTA3;		   /*@Note: Name of Output Supression SAS Macro 			   ***/
/***/ %LET Report_Module   = Macro4-CODI_PQ_ZCTA3;		   /*@Note: Name of Report Generation SAS Macro 			   ***/
/***/ %LET Query_Module	   = Module1-CODI_PQ_ZCTA3;		   /*@Note: Name of Query SAS Module		   				   ***/
/***/ %LET Estimate_Module = Module2-CODI_PQ_ZCTA3;		   /*@Note: Name of Estimate SAS Module		   				   ***/
/***/ %Let WGTCELL_MIN	   = 20; 						   /*@Note: Minimum allowed weighting cell count for collapsing weighting characteristics ***/
/*************************************************************************************************************************/

/*@Action: Begin SAS Log output ***/
SYSTASK COMMAND "MKDIR ""&Root_PQ.\1 Output\SAS LOG""" WAIT;
Proc Printto Log="&Root_PQ.\1 Output\SAS LOG\&Log_Name._&DateTime..log" New; Run;

/*@Action: Initialize SAS Libraries ***/
SYSTASK COMMAND "MKDIR ""&Root_PQ.\1 Output""" WAIT;
Libname SASIN "&Root_PQ.\1 Output\Pre_processed_&PRE_DEST." Access=Readonly;

/*@Action: Load SAS macro routines needed by module programs ***/
%Include "&PROGS_PQ.\&ACS_Module..sas" / LRECL = 500; 	   /*@Note: Compute ACS control totals for requested domain ***/
%Include "&PROGS_PQ.\&Weight_Module..sas" / LRECL = 500;   /*@Note: Weighting: Iterative Proportional Weighting (Raking) & Age Adjustment ***/
%Include "&PROGS_PQ.\&Suppress_Module..sas" / LRECL = 500; /*@Note: Supression: Output suppression, following NCHS guidelines ***/
%Include "&PROGS_PQ.\&Report_Module..sas" / LRECL = 500;   /*@Note: Report Generation: Report creation and output module ***/
%Include "&PROGS_PQ.\&Query_Module..sas" / LRECL = 500;    /*@Note: Load Query Module ***/

/*@Action: Load Census 2000 Age Distribution for Age Adjustment ***/
Data Census_2000;
	length Age_Group $7;
	infile datalines delimiter=",";
	input Age_Group $ Pct2000;
datalines;
02 - 04, 0.160511
05 - 09, 0.279658
10 - 14, 0.281581
15 - 17, 0.165920
18 - 19, 0.112330
;
Run;

/*@Action: Create formats for collapsing of groups ***/
Proc Format;
	Value $Age_1_C "02 - 04" = "1"
				   "05 - 09" = "1"
				   other = " "
				   ;
	Value $Age_2_C "10 - 14" = "2"
				   "15 - 17" = "2"
				   other   = " "
				   ;
	Value $Age_3_C "15 - 17" = "3"
				   "18 - 19" = "3"
				   other   = " "
				   ;
	Value $Age_4_C "10 - 14" = "4"
				   "10 - 17" = "4"
				   "15 - 19" = "4"
				   "18 - 19" = "4"
				   other   = " "
				   ;
	Value $Collapse_Age "1"   = "02 - 09"
					    "2"   = "10 - 17"
					    "3"   = "15 - 19"
					    "4"   = "10 - 19"
						other = " "
					    ;
Run;

/*@Note: Literal text will be printed in report***/
Data FIPS_Codes;
	Input Start $ 1-2 Label $ 4-5 Full_Label $ 7-32;
	Datalines;
AL 01 (01) Alabama
AK 02 (02) Alaska
AZ 04 (04) Arizona
AR 05 (05) Arkansas
CA 06 (06) California
CO 08 (08) Colorado
CT 09 (09) Connecticut
DE 10 (10) Delware
DC 11 (11) District of Columbia
FL 12 (12) Florida
GA 13 (13) Georgia
HI 15 (15) Hawaii
ID 16 (16) Idaho
IL 17 (17) Illinois
IN 18 (18) Indiana
IA 19 (19) Iowa
KS 20 (20) Kansas
KY 21 (21) Kentucky
LA 22 (22) Louisiana
ME 23 (23) Maine
MD 24 (24) Maryland
MA 25 (25) Massachusetts
MI 26 (26) Michigan
MN 27 (27) Minnesota
MS 28 (28) Mississippi
MO 29 (29) Missouri
MT 30 (30) Montana
NE 31 (31) Nebraska
NV 32 (32) Nevada
NH 33 (33) New Hampshire
NJ 34 (34) New Jersey
NM 35 (35) New Mexico
NY 36 (36) New York
NC 37 (37) North Carolina
ND 38 (38) North Dakota
OH 39 (39) Ohio
OK 40 (40) Oklahoma
OR 41 (41) Oregon
PA 42 (42) Pennsylvania
RI 44 (44) Rhode Island
SC 45 (45) South Carolina
SD 46 (46) South Dakota
TN 47 (47) Tennessee
TX 48 (48) Texas
UT 49 (49) Utah
VT 50 (50) Vermont
VA 51 (51) Virginia
WA 53 (53) Washington
WV 54 (54) West Virginia
WI 55 (55) Wisconsin
WY 56 (56) Wyoming
;
Run;

/*@Action: Begin algorithm process by progressing to -- Load Query Module ***/
%CODI_PQ_ZCTA3;
/****************************************************************************/

/*@Action Clear temporary work library ***/
Proc Datasets Library=WORK Kill;
Quit;

/*@Action: Halt SAS log output ***/
proc printto;
Run;
/*@Program End ***/

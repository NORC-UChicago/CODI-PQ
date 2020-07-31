/*******************************************************************************************/
/***PROGRAM: QUICKSTART-CODI_PQ.SAS													     ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC)														 ***/
/***DATE CREATED: 07/03/2020; DATE LAST MOD: 07/22/2020 								 ***/
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
/***/ %LET Root_PQ = P:\Example;	/*@Note: base directory (ACCEPTABLE VALUES: computer directory name)		   		   ***/
/***/ %LET PROGS_PQ= &Root_PQ.\0 SAS Programs\; /*@Note: Location of SAS programs (ACCEPTABLE VALUES: computer directory name)	***/
/***/ %LET PRE_DEST= CODI_PQ; /*@Note: Suffix name of pre-processing output folder (ACCEPTABLE VALUES: folder name (no punctuations)) ***/
/***/ %LET EHR_PRE_OUT= CODI_PQ; /*@Note: Suffix name of pre-processing output file (ACCEPTABLE VALUES: file name (no punctuations)) ***/
/***/ %LET LOG_NAME= CODI_PREVALENCE_QUERY; /*@Note: Name for SAS log storage location            								   ***/

/*SECTION 2: Subset data based on specifications INCLUDING YEAR, GEOGRAPHY, STATE OR STATE/COUNTY CODE							   ***/
/***/ %LET BEG_YEAR		 = 2016; /*@Note: Beginning year of analysis				 (ACCEPTED VALUES: 4-Digit numeric, 2016-2019) ***/
/***/ %LET END_YEAR		 = 2019; /*@Note: End year of analysis 						 (ACCEPTED VALUES: 4-Digit numeric, 2016-2019) ***/
/***/ %LET STATE		 = Y;  	 /*@Note: Include all geographical locations in file?(ACCEPTED VALUES: Y/N)						   ***/
/***/ %LET GEO_LIST	  	 = %STR('08'); /*@Note: IF STATE="Y" then populate with State FIPS code(s), otherwise populate with FIPS State+FIPS County code(s) (ACCEPTED VALUES: 2-digit state FIPS or 5-digit state FIPS+county FIPS (Must be surrounded by single quotation and comma delimited)) ***/
/***/ %LET ALL_AGES		 = N;	 /*@Note: Include all age ranges? 					 (ACCEPTED VALUES: Y/N) 			 		   ***/
/***/ %LET ALL_SEXES	 = Y;	 /*@Note: Include all sex values? 					 (ACCEPTED VALUES: Y/N) 			 		   ***/
/***/ %LET ALL_RACES	 = N; 	 /*@Note: Include all race categories? 				 (ACCEPTED VALUES: Y/N)			 			   ***/

/*SECTION 3: Only complete section 3 for any "N" values listed in section 2														   ***/
/*IF ALLGEOGRAPHIES= N THEN SELECT STATE CODES OR STATE AND COUNTY CODES BELOW:													   ***/
	/***  (ACCEPTED VALUES: SINGLE QUOTES SURROUNDING 2 OR 5-Digit CODES w/ "," BETWEEN MULTIPLE SELECTIONS, ) 				   ***/
/*IF ALL_AGES = N THEN SELECT ONE OR MORE AGE CATEGORIES BELOW:																	   ***/
	/***/ %LET AGE_2_4	  = N;	 /*@Note: Age Range: 2 to 4 						(ACCEPTED VALUES: Y/N) 			 	   	   ***/
	/***/ %LET AGE_5_9	  = N;	 /*@Note: Age Range: 5 to 9 						(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET AGE_10_14  = Y;	 /*@Note: Age Range: 10 to 14 						(ACCEPTED VALUES: Y/N) 			 	   	   ***/
	/***/ %LET AGE_15_17  = Y;	 /*@Note: Age Range: 15 to 17 						(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET AGE_18_19  = Y;	 /*@Note: Age Range: 18 to 19 						(ACCEPTED VALUES: Y/N) 			 	       ***/
/*IF ALL_RACES = N THEN SELECT ONE OR MORE RACE BELOW:																			   ***/
	/***/ %LET RACE_WHITE  = Y;	 /*@Note: White 									(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_BLACK  = Y;	 /*@Note: Black/African American 					(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_ASIAN  = N;	 /*@Note: Asian 									(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET RACE_OTHER  = N;	 /*@Note: Other								 		(ACCEPTED VALUES: Y/N)				       ***/
/*IF ALL_SEXES = N THEN SELECT MALE OR FEMALE BELOW:																			   ***/
	/***/ %LET SEX_MALE	   = N;	 /*@Note: Sex: Male 								(ACCEPTED VALUES: Y/N) 			 	       ***/
	/***/ %LET SEX_FEMALE  = N;	 /*@Note: Sex: Female 								(ACCEPTED VALUES: Y/N) 			 	       ***/

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
/***/ %LET FileIN_Name1	   = Pre_Processed_&EHR_PRE_OUT.;  /*@Note: CODI Data file name			   					   ***/
/***/ %LET FileIN_Name2	   = ACS_State_County;			   /*@Note: ACS file name					   				   ***/
/***/ %LET FileOUT_Name    = CODI_Prevalence_Query_Report; /*@Note: Output file name				   				   ***/
/***/ %LET ACS_Module      = Macro1-CODI_PQ;			   /*@Note: Name of ACS Controls SAS Macro	   				   ***/
/***/ %LET Weight_Module   = Macro2-CODI_PQ;			   /*@Note: Name of Weighting SAS Macro		   				   ***/
/***/ %LET Suppress_Module = Macro3-CODI_PQ;			   /*@Note: Name of Output Supression SAS Macro 			   ***/
/***/ %LET Report_Module   = Macro4-CODI_PQ;			   /*@Note: Name of Report Generation SAS Macro 			   ***/
/***/ %LET Query_Module	   = Module1-CODI_PQ;			   /*@Note: Name of Query SAS Module		   				   ***/
/***/ %LET Estimate_Module = Module2-CODI_PQ;			   /*@Note: Name of Estimate SAS Module		   				   ***/
/***/ %Let WGTCELL_MIN	   = 20; 						   /*@Note: Minimum allowed weighting cell count for collapsing weighting characteristics ***/
/*************************************************************************************************************************/

/*@Action: Begin SAS Log output ***/
SYSTASK COMMAND "MKDIR ""&Root_PQ.\1 Output\SAS LOG""" WAIT;
Proc Printto Log="&Root_PQ.\1 Output\SAS LOG\&Log_Name. &DateTime..log" New; Run;

/*@Action: Initialize SAS Libraries ***/
SYSTASK COMMAND "MKDIR ""&Root_PQ.\1 Output""" WAIT;
Libname SASIN "&Root_PQ.\1 Output\Pre_processed_&PRE_DEST." Access=Readonly;
Libname SASOut "&Root_PQ.\1 Output";

/*@Action: Load SAS macro routines needed by module programs ***/
%Include "&PROGS_PQ.\&ACS_Module..sas" / LRECL = 500; 	   /*@Note: Compute ACS control totals for requested domain ***/
%Include "&PROGS_PQ.\&Weight_Module..sas" / LRECL = 500;   /*@Note: Weighting: Iterative Proportional Weighting (Raking) & Age Adjustment ***/
%Include "&PROGS_PQ.\&Suppress_Module..sas" / LRECL = 500; /*@Note: Supression: Output suppression, following NCHS guidelines ***/
%Include "&PROGS_PQ.\&Report_Module..sas" / LRECL = 500;   /*@Note: Report Generation: Report creation and output module ***/
%Include "&PROGS_PQ.\&Query_Module..sas" / LRECL = 500;    /*@Note: Load Query module ***/

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
	/*@Note: Age Categories ***/
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

/*@Action: Begin algorithm process by progressing to -- Load Query Module ***/
%CODI_PQ;
/****************************************************************************/

/*@Action Clear temporary work library ***/
Proc Datasets Library=WORK Kill;
Quit;

/*@Action: Halt SAS log output ***/
proc printto;
Run;
/*@Program End ***/

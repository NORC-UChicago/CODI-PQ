/*****************************************************************************************/
/***PROGRAM: Quickstart-Pre_Processing_CODI_PQ.SAS								  	   ***/
/***VERSION: 1.0																	   ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)						   ***/
/***DATE CREATED: 7/20/2020, DATE LAST MOD: 7/24/2020								   ***/
/***INPUT: American Community Survey COUNTY-level (CSV)		  	 					   ***/
/***INPUT: EHR data file (CSV)		   												   ***/
/***INPUT: EHR data file with condition information (CSV)		   					   ***/
/***OUTPUT: Pre-Processed American Community Survey COUNTY-Level (SAS)				   ***/
/***OUTPUT: Pre-Processed EHR SAS file (SAS)							   			   ***/
/***OBJECTIVE: PREPROCESSES CHILDHOOD and TEEN OBESITY EHR DATA and ACS COUNTY DATA    ***/
/***OBJECTIVE: IMPORT ACS 5-YEAR FILE. APPLY FORMATS, EDITS AND  					   ***/
/***OBJECTIVE: CHECK FOR INCONSISTENCIES/MISSINGNESS. OUTPUT FILE INTO A SAS DATAFILE. ***/
/***OBJECTIVE: REPEATS WITH CODI (EHR) DATA											   ***/
/*****************************************************************************************/

/*************************************************************************************************************************************/
/*********************** -- PREPROCESSING ALGORITHM USER INPUT SECTION (PLEASE COMPLETE SECTIONS 1-3 BELOW)	-- ***********************/
/******************* -- PLEASE UPDATE THE BLACK TEXT AFTER THE EQUAL SIGN  (ACCEPTED VALUES LISTED IN SAS NOTE) -- *******************/
/*************************************************************************************************************************************/
/*SECTION 1: Input Folder and file names																								    ***/
/***/ %LET ROOT_PRE		= P:\Example;			 /*@Note: base directory (ACCEPTABLE VALUES: computer directory name) ***/
/***/ %LET PROGS_PRE	= &Root_PRE.\0 SAS Programs\;/*@Note: where SAS programs are stored (ACCEPTABLE VALUES: computer directory name) ***/
/***/ %LET PRE_DEST		= CODI_PQ;  						 /*@Note: Suffix name for EHR Output folder (ACCEPTABLE VALUES: folder name (no puctuation) 		      ***/
/***/ %LET ACS_FILENAME	= ACS_State_COUNTY;	  				 /*@Note: ACS file name (ACCEPTABLE VALUES: file name, do not include ".csv") ***/
/***/ %LET EHR_FILENAME = Replicated-CODI-bmi-data;   		 /*@Note: EHR file name (ACCEPTABLE VALUES: file name, do not include ".csv") ***/
/***/ %LET LOG_NAME_PRE	= Quickstart_Pre_Processing_CODI_PQ; /*@Note: SAS log file name prefix ACCEPTABLE VALUES: SAS file name (no punctuation) 	   ***/

/*SECTION 2: Beginning and End Year of longitudinal EHR data																			   ***/
/***/ %LET BEGIN_YEAR = 2016; /*@Note: LONGITUDINAL Start year (ACCEPTABLE VALUES: 4-digit numeric year) ***/
/***/ %LET END_YEAR	  = 2019; /*@Note: LONGITUDINAL End year (ACCEPTABLE VALUES: 4-digit numeric year)   ***/

/*SECTION 3: OPTIONAL Output File Name Suffix																							   ***/
/***/ %LET EHR_PRE_Out  = CODI_PQ; /*@Note: EHR output file name (ACCEPTABLE VALUES: SAS file name (no punctuation)		   			***/

/***Note: ROOT_PRE directory includes subfolders: 
								"..\0 SAS Programs"
								"..\00 Raw Data" 
								"..\01 Output" and 
								"..\01 Output\SAS LOGS"										   									 	***/
/***NOTE: SAS programs must be stored in the PROGS_PRE directory including: 
								Module1-Pre_Processing_CODI_PQ.sas
								Module2-Pre_Processing_CODI_PQ.sas
								Module3-Pre_Processing_CODI_PQ.sas		   															***/
/*********************************************************************************************************************************************/
/***STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP*********/
/*** DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT    *********/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/















/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/***STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP*/
/*** DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT 	DO NOT EDIT BEYOND THIS POINT    */
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/
/*************************************************************************************************************************************/















/*@Action: Set SAS options ***/
Options Fullstimer Nofmterr Mlogic Mprint Minoperator SymbolGen Compress=Yes;

/*@Action: Additional information needed by pre-processing algorithm loaded into SAS macro variables ***/
%LET DateTime = %SYSFUNC(Translate(%Quote(%SYSFUNC(COMPBL(%QUOTE(%SYSFUNC(Today(),Weekdate.) %SYSFUNC(Time(), timeampm.))))),%Str(___),%Str( ,:))); /*@Note: Date time of SAS run, DO NOT CHANGE ***/
%LET ACS_PRE_Out  = ACS_State_County;	  	  /*@Note: Census ACS output file name (ACCEPTABLE VALUES: SAS file name (no punctuation) ***/
%LET REG_EST_NAME = Pre_PQ_Reg_Est;			  /*@Note: Regression estimates SAS filename (ACCEPTABLE VALUES: file name, do not include ".sas7bdat") ***/
%LET MODULE1 =Module1-Pre_Processing_CODI_PQ; /*@Note: Module 1 (ACCEPTABLE VALUES: name of SAS program, do not include ".sas") ***/
%LET MODULE2 =Module2-Pre_Processing_CODI_PQ; /*@Note: Module 2 (ACCEPTABLE VALUES: name of SAS program, do not include ".sas") ***/
%LET MODULE3 =Module3-Pre_Processing_CODI_PQ; /*@Note: Module 3 (ACCEPTABLE VALUES: name of SAS program, do not include ".sas") ***/

/*@Action: Check if optional input value was entered missing, if missing set default ***/
%Macro Check_Optional;
	%If "&EHR_PRE_Out." = "" %Then %Let EHR_PRE_Out = CODI_PQ;
%Mend;
%Check_Optional;

/*@Action: Create LOG/PDF output folder and begin SAS log and PDF output ***/
SYSTASK COMMAND "MKDIR ""&ROOT_Pre.\1 Output\SAS LOG""" WAIT;
Proc Printto Log="&ROOT_Pre.\1 Output\SAS LOG\&LOG_NAME_PRE._&DateTime..log" New; Run;

/*@Action: Create and initialize SAS output Destination library ***/
SYSTASK COMMAND "MKDIR ""&ROOT_Pre.\1 Output\Pre_Processed_&Pre_Dest.""" WAIT;
Libname RegEst "&ROOT_Pre.\00 Raw Data" Access=Readonly;
Libname SASOut "&ROOT_Pre.\1 Output\Pre_Processed_&Pre_Dest.";

/*******************************************************************************************************************************************/
/************************************************* -- Import ACS CSV Data File into SAS -- *************************************************/
/************************************************* -- Apply Rename and Collapsing Logic -- *************************************************/
/*******************************************************************************************************************************************/
/*@Action: List of ACS variables needed to compute control totals ***/
%Let ACSOriginal=B01001A_003 B01001A_004 B01001A_005 B01001A_006 B01001A_007 B01001A_018 B01001A_019
B01001A_020 B01001A_021 B01001A_022 B01001B_003 B01001B_004 B01001B_005 B01001B_006 B01001B_007
B01001B_018 B01001B_019 B01001B_020 B01001B_021 B01001B_022 B01001C_003 B01001C_004 B01001C_005
B01001C_006 B01001C_007 B01001C_018 B01001C_019 B01001C_020 B01001C_021 B01001C_022 B01001D_003
B01001D_004 B01001D_005 B01001D_006 B01001D_007 B01001D_018 B01001D_019 B01001D_020 B01001D_021
B01001D_022 B01001E_003 B01001E_004 B01001E_005 B01001E_006 B01001E_007 B01001E_018 B01001E_019
B01001E_020 B01001E_021 B01001E_022 B01001F_003 B01001F_004 B01001F_005 B01001F_006 B01001F_007
B01001F_018 B01001F_019 B01001F_020 B01001F_021 B01001F_022 B01001G_003 B01001G_004 B01001G_005
B01001G_006 B01001G_007 B01001G_018 B01001G_019 B01001G_020 B01001G_021 B01001G_022 B15001_011
B15001_017 B15001_018 B15001_019 B15001_025 B15001_026 B15001_027 B15001_033 B15001_034 B15001_052
B15001_058 B15001_059 B15001_060 B15001_066 B15001_067 B15001_068 B15001_074 B15001_075 B03002_012
B03002_013 B03002_014 B03002_015 B03002_016 B03002_017 B03002_018 B03002_019 B01001A_001 B01001B_001
B01001C_001 B01001D_001 B01001E_001 B01001F_001 B01001G_001;

/*@Action: Final list of ACS variables ***/
%Let ACSNew=TOTAL_ACS_POPULATION AGE_L5_MALE_WHITE AGE_5_9_MALE_WHITE AGE_10_14_MALE_WHITE AGE_15_17_MALE_WHITE
AGE_18_19_MALE_WHITE AGE_L5_FEMALE_WHITE AGE_5_9_FEMALE_WHITE AGE_10_14_FEMALE_WHITE AGE_15_17_FEMALE_WHITE
AGE_18_19_FEMALE_WHITE AGE_L5_MALE_BLACK AGE_5_9_MALE_BLACK AGE_10_14_MALE_BLACK AGE_15_17_MALE_BLACK
AGE_18_19_MALE_BLACK AGE_L5_FEMALE_BLACK AGE_5_9_FEMALE_BLACK AGE_10_14_FEMALE_BLACK AGE_15_17_FEMALE_BLACK
AGE_18_19_FEMALE_BLACK AGE_L5_MALE_ASIAN AGE_5_9_MALE_ASIAN AGE_10_14_MALE_ASIAN AGE_15_17_MALE_ASIAN
AGE_18_19_MALE_ASIAN AGE_L5_FEMALE_ASIAN AGE_5_9_FEMALE_ASIAN AGE_10_14_FEMALE_ASIAN AGE_15_17_FEMALE_ASIAN
AGE_18_19_FEMALE_ASIAN AGE_L5_MALE_OTHER AGE_5_9_MALE_OTHER AGE_10_14_MALE_OTHER AGE_15_17_MALE_OTHER
AGE_18_19_MALE_OTHER AGE_L5_FEMALE_OTHER AGE_5_9_FEMALE_OTHER AGE_10_14_FEMALE_OTHER AGE_15_17_FEMALE_OTHER
AGE_18_19_FEMALE_OTHER AGE_25_64_BACH_GRAD AGE_25_64_BACH_GRAD_GTR20PERC TOTAL_LATIN LATIN_WHITE LATIN_BLACK
LATIN_ASIAN LATIN_OTHER;

/*@Action: Rename statements to rename original ACS variables into standardized names ***/
%Let ACSRename=%Str(B01001A_003=AGE_L5_MALE_WHITE B01001A_004=AGE_5_9_MALE_WHITE B01001A_005=AGE_10_14_MALE_WHITE
B01001A_006=AGE_15_17_MALE_WHITE B01001A_007=AGE_18_19_MALE_WHITE B01001A_018=AGE_L5_FEMALE_WHITE
B01001A_019=AGE_5_9_FEMALE_WHITE B01001A_020=AGE_10_14_FEMALE_WHITE B01001A_021=AGE_15_17_FEMALE_WHITE
B01001A_022=AGE_18_19_FEMALE_WHITE B01001B_003=AGE_L5_MALE_BLACK B01001B_004=AGE_5_9_MALE_BLACK
B01001B_005=AGE_10_14_MALE_BLACK B01001B_006=AGE_15_17_MALE_BLACK B01001B_007=AGE_18_19_MALE_BLACK
B01001B_018=AGE_L5_FEMALE_BLACK B01001B_019=AGE_5_9_FEMALE_BLACK B01001B_020=AGE_10_14_FEMALE_BLACK
B01001B_021=AGE_15_17_FEMALE_BLACK B01001B_022=AGE_18_19_FEMALE_BLACK B01001C_003=AGE_L5_MALE_AIAN
B01001C_004=AGE_5_9_MALE_AIAN B01001C_005=AGE_10_14_MALE_AIAN B01001C_006=AGE_15_17_MALE_AIAN
B01001C_007=AGE_18_19_MALE_AIAN B01001C_018=AGE_L5_FEMALE_AIAN B01001C_019=AGE_5_9_FEMALE_AIAN
B01001C_020=AGE_10_14_FEMALE_AIAN B01001C_021=AGE_15_17_FEMALE_AIAN B01001C_022=AGE_18_19_FEMALE_AIAN
B01001D_003=AGE_L5_MALE_ASIAN B01001D_004=AGE_5_9_MALE_ASIAN B01001D_005=AGE_10_14_MALE_ASIAN
B01001D_006=AGE_15_17_MALE_ASIAN B01001D_007=AGE_18_19_MALE_ASIAN B01001D_018=AGE_L5_FEMALE_ASIAN
B01001D_019=AGE_5_9_FEMALE_ASIAN B01001D_020=AGE_10_14_FEMALE_ASIAN B01001D_021=AGE_15_17_FEMALE_ASIAN
B01001D_022=AGE_18_19_FEMALE_ASIAN B01001E_003=AGE_L5_MALE_NHPI B01001E_004=AGE_5_9_MALE_NHPI
B01001E_005=AGE_10_14_MALE_NHPI B01001E_006=AGE_15_17_MALE_NHPI B01001E_007=AGE_18_19_MALE_NHPI
B01001E_018=AGE_L5_FEMALE_NHPI B01001E_019=AGE_5_9_FEMALE_NHPI B01001E_020=AGE_10_14_FEMALE_NHPI
B01001E_021=AGE_15_17_FEMALE_NHPI B01001E_022=AGE_18_19_FEMALE_NHPI B01001F_003=AGE_L5_MALE_OTHER
B01001F_004=AGE_5_9_MALE_OTHER B01001F_005=AGE_10_14_MALE_OTHER B01001F_006=AGE_15_17_MALE_OTHER
B01001F_007=AGE_18_19_MALE_OTHER B01001F_018=AGE_L5_FEMALE_OTHER B01001F_019=AGE_5_9_FEMALE_OTHER
B01001F_020=AGE_10_14_FEMALE_OTHER B01001F_021=AGE_15_17_FEMALE_OTHER B01001F_022=AGE_18_19_FEMALE_OTHER
B01001G_003=AGE_L5_MALE_GE2R B01001G_004=AGE_5_9_MALE_GE2R B01001G_005=AGE_10_14_MALE_GE2R
B01001G_006=AGE_15_17_MALE_GE2R B01001G_007=AGE_18_19_MALE_GE2R B01001G_018=AGE_L5_FEMALE_GE2R
B01001G_019=AGE_5_9_FEMALE_GE2R B01001G_020=AGE_10_14_FEMALE_GE2R B01001G_021=AGE_15_17_FEMALE_GE2R
B01001G_022=AGE_18_19_FEMALE_GE2R B15001_011=AGE_25_34_MALE_EDUC B15001_017=AGE_25_34_MALE_BACHELOR
B15001_018=AGE_25_34_MALE_GRAD_PROF B15001_019=AGE_35_44_MALE_EDUC B15001_025=AGE_35_44_MALE_BACHELOR
B15001_026=AGE_35_44_MALE_GRAD_PROF B15001_027=AGE_45_64_MALE_EDUC B15001_033=AGE_45_64_MALE_BACHELOR
B15001_034=AGE_45_64_MALE_GRAD_PROF B15001_052=AGE_25_34_FEMALE_EDUC B15001_058=AGE_25_34_FEMALE_BACHELOR
B15001_059=AGE_25_34_FEMALE_GRAD_PROF B15001_060=AGE_35_44_FEMALE_EDUC B15001_066=AGE_35_44_FEMALE_BACHELOR
B15001_067=AGE_35_44_FEMALE_GRAD_PROF B15001_068=AGE_45_64_FEMALE_EDUC B15001_074=AGE_45_64_FEMALE_BACHELOR
B15001_075=AGE_45_64_FEMALE_GRAD_PROF B03002_012=TOTAL_LATIN B03002_013=LATIN_WHITE B03002_014=LATIN_BLACK
B03002_015=LAT_AIAN B03002_016=LAT_ASIAN B03002_017=LAT_NHPI B03002_018=LAT_OTHER B03002_019=LAT_GE2R);

/*@Action: Import ACS CSV file ***/
Proc Import Datafile="&ROOT_Pre.\00 Raw Data\&ACS_FILENAME..csv" DBMS=CSV Out=&ACS_PRE_Out. Replace; Getnames=YES;
Run;

/*@Action: Exclude ACS variables that are not needed to compute controls and apply rename logic ***/
Data SASOut.&ACS_PRE_Out.(Keep=Geography County_FIPS State_FIPS &ACSNew.);
	Retain Geography County_FIPS State_FIPS &ACSNew.;
	Set &ACS_PRE_Out.(Keep=GEOID &ACSOriginal. Rename=(&ACSRename.));
		/*@Action: Extract location information from GEOID, State_FIPS and County_FIPS ***/
		Length Geography $5. State_FIPS $2. County_FIPS $3.;
		Geography = SUBSTR(GEOID, 8, 5);
		State_FIPS = Substr(Geography, 1, 2);
		County_FIPS = Substr(Geography, 3, 3);

		/*@Action: Reset numeric null (.) to zeros (0) ***/
		Array Change _Numeric_; Do over Change; If Change=. Then Change=0; End;

		/*@Action: Compute Total ACS Population ***/
		TOTAL_ACS_POPULATION=B01001A_001+B01001B_001+B01001C_001+B01001D_001+B01001E_001+B01001F_001+B01001G_001;

		/*@Action: Combine specific race categories with others ***/
		/*@Note: NHPI is collapsed into ASIAN ***/
		AGE_L5_MALE_ASIAN=AGE_L5_MALE_ASIAN+AGE_L5_MALE_NHPI;
		AGE_5_9_MALE_ASIAN=AGE_5_9_MALE_ASIAN+AGE_5_9_MALE_NHPI;
		AGE_10_14_MALE_ASIAN=AGE_10_14_MALE_ASIAN+AGE_10_14_MALE_NHPI;
		AGE_15_17_MALE_ASIAN=AGE_15_17_MALE_ASIAN+AGE_15_17_MALE_NHPI;
		AGE_18_19_MALE_ASIAN=AGE_18_19_MALE_ASIAN+AGE_18_19_MALE_NHPI;
		AGE_L5_FEMALE_ASIAN=AGE_L5_FEMALE_ASIAN+AGE_L5_FEMALE_NHPI;
		AGE_5_9_FEMALE_ASIAN=AGE_5_9_FEMALE_ASIAN+AGE_5_9_FEMALE_NHPI;
		AGE_10_14_FEMALE_ASIAN=AGE_10_14_FEMALE_ASIAN+AGE_10_14_FEMALE_NHPI;
		AGE_15_17_FEMALE_ASIAN=AGE_15_17_FEMALE_ASIAN+AGE_15_17_FEMALE_NHPI;
		AGE_18_19_FEMALE_ASIAN=AGE_18_19_FEMALE_ASIAN+AGE_18_19_FEMALE_NHPI;
		LATIN_ASIAN=LAT_ASIAN+LAT_NHPI;

		/*@Note: GE2R and AIAN are collapsed into OTHER ***/
		AGE_L5_MALE_OTHER=AGE_L5_MALE_OTHER+AGE_L5_MALE_GE2R+AGE_L5_MALE_AIAN;
		AGE_5_9_MALE_OTHER=AGE_5_9_MALE_OTHER+AGE_5_9_MALE_GE2R+AGE_5_9_MALE_AIAN;
		AGE_10_14_MALE_OTHER=AGE_10_14_MALE_OTHER+AGE_10_14_MALE_GE2R+AGE_10_14_MALE_AIAN;
		AGE_15_17_MALE_OTHER=AGE_15_17_MALE_OTHER+AGE_15_17_MALE_GE2R+AGE_15_17_MALE_AIAN;
		AGE_18_19_MALE_OTHER=AGE_18_19_MALE_OTHER+AGE_18_19_MALE_GE2R+AGE_18_19_MALE_AIAN;
		AGE_L5_FEMALE_OTHER=AGE_L5_FEMALE_OTHER+AGE_L5_FEMALE_GE2R+AGE_L5_FEMALE_AIAN;
		AGE_5_9_FEMALE_OTHER=AGE_5_9_FEMALE_OTHER+AGE_5_9_FEMALE_GE2R+AGE_5_9_FEMALE_AIAN;
		AGE_10_14_FEMALE_OTHER=AGE_10_14_FEMALE_OTHER+AGE_10_14_FEMALE_GE2R+AGE_10_14_FEMALE_AIAN;
		AGE_15_17_FEMALE_OTHER=AGE_15_17_FEMALE_OTHER+AGE_15_17_FEMALE_GE2R+AGE_15_17_FEMALE_AIAN;
		AGE_18_19_FEMALE_OTHER=AGE_18_19_FEMALE_OTHER+AGE_18_19_FEMALE_GE2R+AGE_18_19_FEMALE_AIAN;
		LATIN_OTHER=LAT_OTHER+LAT_GE2R+LAT_AIAN;

		/*@Note: Compute % of adults aged 25-64 with Education Bachelor+ ***/
		AGE_25_64_BACH_GRAD=Sum(AGE_25_34_MALE_BACHELOR, AGE_25_34_FEMALE_BACHELOR, AGE_35_44_MALE_BACHELOR, AGE_35_44_FEMALE_BACHELOR, AGE_45_64_MALE_BACHELOR, AGE_45_64_FEMALE_BACHELOR, AGE_25_34_MALE_GRAD_PROF, AGE_25_34_FEMALE_GRAD_PROF, AGE_35_44_MALE_GRAD_PROF, AGE_35_44_FEMALE_GRAD_PROF, AGE_45_64_MALE_GRAD_PROF, AGE_45_64_FEMALE_GRAD_PROF)/Sum(AGE_25_34_MALE_EDUC, AGE_25_34_FEMALE_EDUC, AGE_35_44_MALE_EDUC, AGE_35_44_FEMALE_EDUC, AGE_45_64_MALE_EDUC, AGE_45_64_FEMALE_EDUC);
		AGE_25_64_BACH_GRAD_GTR20PERC=(AGE_25_64_BACH_GRAD>0.2);
Run;


/*******************************************************************************************************************************************/
/*************************************************** -- Import EHR Data File into SAS -- ***************************************************/
/********************************** -- Reformat and create variables needed for prevalence estimation -- ***********************************/
/*******************************************************************************************************************************************/
%Macro Import_EHR_Data;
	/*@Action: Create formats for literal text translation ***/
	Proc Format;
		/*@Note: Weight Categories ***/
		Value $WgtCat "Underweight"    = "(1) Underweight (<5th percentile)"
					  "Healthy Weight" = "(2) Healthy Weight (5th to <85th percentile)"
					  "Overweight" 	   = "(3) Overweight (85th to <95th percentile)"
					  "Obese" 	   	   = "(4) Obesity (>95th percentile)"
					  "Severe Obesity" = "(4b) Severe Obesity (>120% of the 95th percentile)"
					  other 		   = " "
					  ;

		/*@Action: Age Categories ***/
		Value Age_R 2 - 4  = "02 - 04"
					5 - 9  = "05 - 09"
				   10 - 14 = "10 - 14"
				   15 - 17 = "15 - 17"
				   18 - 19 = "18 - 19"
				   other   = "Unknown"
				   ;

		Value $Race_R "1002-5" = "Other" /*@Note: Originally, AIAN ***/
					  "2028-9" = "Asian"
					  "2054-5" = "Black"
					  "2076-8" = "Asian" /*@Note: Originally, NHPI ***/
					  "2106-3" = "White"
					  "UNK"    = "Unknown"
					  "ASKU"   = "Unknown"
					  other	   = "Unknown"
					  ;

		Value $Ethnicity_R "2135-2" = "Hispanic or Latino"
						   "2186-5" = "Non-Hispanic or Latino"
						   other 	= "Unknown"
						   ;

		Value $Sex_R "female" = "Female"
					 "male"	  = "Male"
					 other 	  = "Unknown"
					 ;

		Value $FIPS_to_Alpha "01"="AL" "02"="AK" "04"="AZ" "05"="AR" "06"="CA" "08"="CO" "09"="CT" "10"="DE" "11"="DC" "12"="FL"
					  "13"="GA" "15"="HI" "16"="ID" "17"="IL" "18"="IN" "19"="IA" "20"="KS" "21"="KY" "22"="LA" "23"="ME"
					  "24"="MD" "25"="MA" "26"="MI" "27"="MN" "28"="MS" "29"="MO" "30"="MT" "31"="NE" "32"="NV" "33"="NH"
					  "34"="NJ" "35"="NM" "36"="NY" "37"="NC" "38"="ND" "39"="OH" "40"="OK" "41"="OR" "42"="PA" "44"="RI"
					  "45"="SC" "46"="SD" "47"="TN" "48"="TX" "49"="UT" "50"="VT" "51"="VA" "53"="WA" "54"="WV" "55"="WI"
					  "56"="WY" Other="  "
					  ;
			Run;

	/*@Action: FILENAME step to preload input file ***/
	Filename EHR "&ROOT_Pre.\00 Raw Data\&EHR_FILENAME..csv";

	/*@Action: Load import file and convert into SAS dataset 		 ***/
	/*@Note: This file will be copied into output destination folder ***/
	Data Include_EHR(label="&EHR_PRE_Out." Drop=STATE_HOLD COUNTY_HOLD TRACT_HOLD TRACT_PERD RACE_HOLD SEX_HOLD);
		Infile EHR dsd dlm="," lrecl=500 firstobs=2 stopover;

		Attrib DOB			length=4   format=mmddyy10. informat=mmddyy10. label="DOB: Date of birth"
			   SEX			length=$6  format=$6.   label="SEX: Sex"
			   RACE			length=$8  format=$8.   label="RACE: Race"
			   ETHNICITY	length=$6  format=$6.	label="ETHNICITY: Ethnicity"
			   LAT			length=8   format=17.14 label="LAT: Latitude"
			   LNG			length=8   format=18.14 label="LNG: Longitude"
			   STATE_FIPS	length=$2  format=$2.	label="STATE: Patient state"
			   ZIP			length=$5  format=$5.   label="ZIP: Zip Code"
			   CENSUS_TRACT length=$7  format=$7.   label="CENSUS_TRACT: US CENSUS Tract"
			   COUNTY_FIPS	length=$3  format=$3.	label="COUNTY_FIPS: County FIPS Code"
			   %Do I=&Begin_Year. %to &End_Year. %by 1;
				   WEIGHT&I. 	length=$16 format=$16.  label="WEIGHT&I.: Patient Weight (kg) in &I."
				   HEIGHT&I. 	length=$16 format=$16.  label="HEIGHT&I.: Patient Height (cm) in &I."
				   BMI&I.		length=$16 format=$16.  label="BMI&I.: Patient BMI in &I."
				   WTCAT&I.  	length=$14 format=$14.  label="WTCAT&I.: Patient weight category &I."
		   		   AGEYR&I.		length=3   format=3.	label="AGEYR&I.: Patient Age (whole year) in &I."
			   %End;
			   HCLCNT	  length=3   format=4.		  label="HCLCNT: Hypercholesterolemia: Event Count"
			   HCLDATE	  length=$10 format=$10. 	  label="HCLDATE: Hypercholesterolemia: First Event Date"
			   CFCNT	  length=3   format=4.		  label="CFCNT: Cystic-Fibrosis: Event Count"
			   CFDATE	  length=$10 format=$10.	  label="CFDATE: Cystic-Fibrosis: First Event Date"
			   SCDCNT	  length=3   format=4.		  label="SCDCNT: Sickle-Cell: Event Count"
			   SCDDATE	  length=$10 format=$10.	  label="SCDDATE: Sickle-Cell: First Event Date"
			   SBCNT	  length=3   format=4.		  label="SBCNT: Spina-Bifida: Event Count"
			   SBDATE	  length=$10 format=$10.	  label="SBDATE: Spina-Bifida: First Event Date"
			   ASTHMACNT  length=3   format=4.		  label="ASTHMACNT: Asthma: Event Count"
			   ASTHMADATE length=$10 format=$10. 	  label="ASTHMADATE: Asthma: First Event Date"
			   CELIACCNT  length=3   format=4.		  label="CELIACCNT: Celiac: Event Count"
			   CELIACDATE length=$10 format=$10.	  label="CELIACDATE: Celiac: First Event Date"
			   SCZCNT	  length=3   format=4.		  label="SCZCNT: Schizophrenia: Event Count"
			   SCZDATE	  length=$10 format=$10.	  label="SCZDATE: Schizophrenia: First Event Date"
			   ;

		Input DOB
			  SEX
			  RACE
			  ETHNICITY
			  LAT
			  LNG
			  STATE_FIPS
			  ZIP			  
			  CENSUS_TRACT
			  COUNTY_FIPS
			  %Do I=&Begin_Year. %to &End_Year. %by 1;
				  WEIGHT&I.
				  HEIGHT&I.
				  BMI&I.
				  WTCAT&I.
				  AGEYR&I.
			  %End;
			  HCLCNT
			  HCLDATE
			  CFCNT
			  CFDATE
			  SCDCNT
			  SCDDATE
			  SBCNT
			  SBDATE
			  ASTHMACNT
			  ASTHMADATE
			  CELIACCNT
			  CELIACDATE
			  SCZCNT
			  SCZDATE
			  ;

			  	/*@Action: Replace unavailable filler "NI" (Not included?) with character null value ***/
				Array Change _CHAR_; Do over Change; If Change in ("NI") then Change = ""; End;

				/*@Action: Reformat State code to become 2-digits (incl. leadng zeros) ***/
				STATE_HOLD = STATE_FIPS;
				STATE_FIPS = Put(Input(STATE_HOLD, best2.), z2.);

				/*@Action: Reformat County code to become 3-digits (incl. leadng zeros) ***/
				COUNTY_HOLD = COUNTY_FIPS;
				COUNTY_FIPS = Put(Input(COUNTY_HOLD, best3.), z3.);

				/*@Action: Reformat Census Tract to standardized Census format ***/
				TRACT_HOLD = Strip(CENSUS_TRACT);
				TRACT_PERD = Index(TRACT_HOLD, ".");
				If TRACT_PERD>0 then do;
					If Length(Substr(TRACT_HOLD, TRACT_PERD+1)) = 1 then
						CENSUS_TRACT = Put(Input(Substr(TRACT_HOLD, 1, TRACT_PERD-1), best4.), z4.)||"."||Substr(TRACT_HOLD, TRACT_PERD+1, 1)||"0";
							Else CENSUS_TRACT = Put(Input(Substr(TRACT_HOLD, 1, TRACT_PERD-1), best4.), z4.)||"."||Substr(TRACT_HOLD, TRACT_PERD+1);
				End;
				Else CENSUS_TRACT = Put(Input(TRACT_HOLD, best4.), z4.)||"."||"00";

				/*@Action: Reformat Race values to standardized Race values ***/
				/*@Note: When RACE is unknown and Ethnicity indicates Hispanic, update Race to Hispanic ***/
				RACE_HOLD = RACE;
				RACE = Put(RACE_HOLD, $Race_R.);			
				If RACE="Unknown" and Put(ETHNICITY,$Ethnicity_R.)="Hispanic or Latino" Then RACE="Hispanic";

				/*@Action: Reformat Sex values to standardized Sex values ***/
				SEX_HOLD = SEX;
				SEX = Put(SEX_HOLD, $Sex_R.);

				/*@Action: Exclude People outside 2-19 Ages Range ***/
				If 2<=Min(Of AGEYR&Begin_Year.-AGEYR&End_Year.)<=19 or
				   2<=Max(Of AGEYR&Begin_Year.-AGEYR&End_Year.)<=19;
	Run;

	/*@Action: Macro loop to convert weight/height/BMI back to numeric fields ***/
	%Macro Convert;
		%Do I=&Begin_Year. %to &End_Year. %by 1;
			,Input(Weight&I., 18.14) as Weight&I. Format=18.14, Input(Height&I., 18.14) as Height&I. Format=18.14, Input(BMI&I., 18.14) as BMI&I. Format=18.14,
			Put(WTCAT&I., $WgtCat.) as WTCAT&I., AGEYR&I., Put(AGEYR&I., Age_R.) as Age_Categories&I.
		%End;
	%Mend;

	/*@Action: Keep specific set of varibales form Clinical file ***/
	Proc Sql;
		Create table Pre_Processed_&EHR_PRE_Out. as
			Select SEX, RACE, ETHNICITY, LAT, LNG, ZIP, CENSUS_TRACT, CATS(STATE_FIPS, COUNTY_FIPS) AS GEOGRAPHY, STATE_FIPS,
			PUT(STATE_FIPS, $FIPS_to_Alpha.) as STATE_ALPHA, COUNTY_FIPS %Convert,
			HCLCNT, CFCNT, SCDCNT, SBCNT, ASTHMACNT, CELIACCNT, SCZCNT
				From Include_EHR
					Where Calculated GEOGRAPHY in (Select Distinct GEOGRAPHY From SASOut.&ACS_PRE_Out. Where TOTAL_ACS_POPULATION>0);
						Quit;		

	Data Pre_Processed_&EHR_PRE_Out.(Drop=HCLCNT CFCNT SCDCNT SBCNT ASTHMACNT CELIACCNT SCZCNT);
		Length PATID 8.; 
		Set Pre_Processed_&EHR_PRE_Out.;
		Length HCL CF SCD SB ASTHMA CELIAC SCZ 3.;
		Label PATID  = "Unique Patient ID"
			  HCL	 = "Hypercholesterolemia: Flag"
			  CF	 = "Cistic-Fibrosis: Flag"
			  SCD	 = "Sickle-Cell: Flag"
			  SB	 = "Spina-Bifida: Flag"
			  ASTHMA = "Asthma: Flag"
			  CELIAC = "Celiac: Flag"
			  SCZ	 = "Schizophreniz: Flag";

		/*@Action: Create PATID ***/
		PATID = _N_;

		/*@Action: Create condition flags ***/
		If HCLCNT>=0    Then HCL    = HCLCNT>0;    Else HCL=.;
		If CFCNT>=0 	Then CF 	= CFCNT>0;	   Else CF=.;
		If SCDCNT>=0    Then SCD    = SCDCNT>0;    Else SCD=.;
		If SBCNT>=0 	Then SB 	= SBCNT>0;	   Else SB=.;
		If ASTHMACNT>=0 Then ASTHMA = ASTHMACNT>0; Else ASTHMA=.;
		If CELIACCNT>=0 Then CELIAC = CELIACCNT>0; Else CELIAC=.;
		If SCZCNT>=0    Then SCZ    = SCZCNT>0;    Else SCZ=.;

		/*@Action: If age out of scope then null data for that year ***/
		%Do I=&Begin_Year. %to &End_Year. %by 1;
			If ^(2<=AgeYR&I.<=19) Then Do;
				Weight&I.=.;
				Height&I.=.;
				BMI&I.=.;
				WTCAT&I.='';
			End;

			If WTCAT&I.='' Then FLGWGTCAT&I.=0;
				Else FLGWGTCAT&I.=1;
		%End;

		If Sum(Of FLGWGTCAT:)>0;
		Drop FLGWGTCAT:;
	Run;

	/*@Action: Clear out preloaded import file ***/
	Filename EHR Clear;
%Mend;

%Import_EHR_Data;


/**********************************************************************************************************************/
/***************************************** -- Begin Race Imputation Routine -- ****************************************/
/*************************************** -- Module 1: People with Conditions -- ***************************************/
/********************** -- Module 2: People with indicated Hispanic Race, without Conditions -- ***********************/
/**************************************** -- Module 3: All reminaing people -- ****************************************/
/**********************************************************************************************************************/
/*@Action: Prepare Data for Module 3 ***/
Data PreEHR_PQ_Pre;
	Set Pre_Processed_&EHR_PRE_Out.;
		/*@Action: Set variables to most recent encounter, beginning with 2018 ***/
		If WTCAT2018^="" Then do;
			Age_Model=AgeYR2018;
			Height_Model=Height2018;
			State_ZIP_Model=Cats(Put(State_FIPS,$FIPS_to_Alpha.), Substr(ZIP, 1, 3));
			Sex_Model=Sex;
		End;
		Else If WTCAT2017^="" Then do;
			Age_Model=AgeYR2017;
			Height_Model=Height2017;
			State_ZIP_Model=Cats(Put(State_FIPS,$FIPS_to_Alpha.), Substr(ZIP, 1, 3));
			Sex_Model=Sex;
		End;
		Else If WTCAT2016^="" Then do;
			Age_Model=AgeYR2016;
			Height_Model=Height2016;
			State_ZIP_Model=Cats(Put(State_FIPS,$FIPS_to_Alpha.), Substr(ZIP, 1, 3));
			Sex_Model=Sex;
		End;
		Else Delete;

		/*@Action: Hard code ZIP collapse (Module 3) ***/
		If State_ZIP_Model="RI029" Then State_ZIP_Model="RI020";
		If State_ZIP_Model="NH035" Then State_ZIP_Model="NH030";
		If State_ZIP_Model="VT050" Then State_ZIP_Model="VT050";
		If State_ZIP_Model="VT052" Then State_ZIP_Model="VT050";
		If State_ZIP_Model="VT056" Then State_ZIP_Model="VT050";
		If State_ZIP_Model="VT057" Then State_ZIP_Model="VT050";
		If State_ZIP_Model="CT069" Then State_ZIP_Model="CT060";
		If State_ZIP_Model="NJ071" Then State_ZIP_Model="NJ070";
		If State_ZIP_Model="NJ073" Then State_ZIP_Model="NJ070";
		If State_ZIP_Model="NJ075" Then State_ZIP_Model="NJ070";
		If State_ZIP_Model="NJ081" Then State_ZIP_Model="NJ080";
		If State_ZIP_Model="NJ083" Then State_ZIP_Model="NJ080";
		If State_ZIP_Model="NJ084" Then State_ZIP_Model="NJ080";
		If State_ZIP_Model="NJ089" Then State_ZIP_Model="NJ080";
		If State_ZIP_Model="NY101" Then State_ZIP_Model="NY100";
		If State_ZIP_Model="NY108" Then State_ZIP_Model="NY100";
		If State_ZIP_Model="NY111" Then State_ZIP_Model="NY110";
		If State_ZIP_Model="NY116" Then State_ZIP_Model="NY110";
		If State_ZIP_Model="NY135" Then State_ZIP_Model="NY130";
		If State_ZIP_Model="NY139" Then State_ZIP_Model="NY130";
		If State_ZIP_Model="NY149" Then State_ZIP_Model="NY140";
		If State_ZIP_Model="PA158" Then State_ZIP_Model="PA150";
		If State_ZIP_Model="PA162" Then State_ZIP_Model="PA160";
		If State_ZIP_Model="PA169" Then State_ZIP_Model="PA160";
		If State_ZIP_Model="PA185" Then State_ZIP_Model="PA180";
		If State_ZIP_Model="PA188" Then State_ZIP_Model="PA180";
		If State_ZIP_Model="VA246" Then State_ZIP_Model="VA240";
		If State_ZIP_Model="GA312" Then State_ZIP_Model="GA310";
		If State_ZIP_Model="TN422" Then State_ZIP_Model="TN420";
		If State_ZIP_Model="MI499" Then State_ZIP_Model="MI490";
		If State_ZIP_Model="IA513" Then State_ZIP_Model="IA510";
		If State_ZIP_Model="IA528" Then State_ZIP_Model="IA520";
		If State_ZIP_Model="WI532" Then State_ZIP_Model="WI530";
		If State_ZIP_Model="WI534" Then State_ZIP_Model="WI530";
		If State_ZIP_Model="WI537" Then State_ZIP_Model="WI530";
		If State_ZIP_Model="WI538" Then State_ZIP_Model="WI530";
		If State_ZIP_Model="WI541" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI542" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI543" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI544" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI545" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI546" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI547" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI548" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="WI549" Then State_ZIP_Model="WI540";
		If State_ZIP_Model="MN557" Then State_ZIP_Model="MN550";
		If State_ZIP_Model="MN558" Then State_ZIP_Model="MN550";
		If State_ZIP_Model="MN567" Then State_ZIP_Model="MN560";
		If State_ZIP_Model="SD573" Then State_ZIP_Model="SD570";
		If State_ZIP_Model="SD574" Then State_ZIP_Model="SD570";
		If State_ZIP_Model="SD575" Then State_ZIP_Model="SD570";
		If State_ZIP_Model="ND582" Then State_ZIP_Model="ND580";
		If State_ZIP_Model="MT590" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT591" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT594" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT595" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT596" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT597" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT598" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MT599" Then State_ZIP_Model="MT590";
		If State_ZIP_Model="MO636" Then State_ZIP_Model="MO630";
		If State_ZIP_Model="MO637" Then State_ZIP_Model="MO630";
		If State_ZIP_Model="MO638" Then State_ZIP_Model="MO630";
		If State_ZIP_Model="KS666" Then State_ZIP_Model="KS660";
		If State_ZIP_Model="KS667" Then State_ZIP_Model="KS660";
		If State_ZIP_Model="KS668" Then State_ZIP_Model="KS660";
		If State_ZIP_Model="KS670" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS671" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS672" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS673" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS677" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS678" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="KS679" Then State_ZIP_Model="KS670";
		If State_ZIP_Model="NE693" Then State_ZIP_Model="NE690";
		If State_ZIP_Model="LA713" Then State_ZIP_Model="LA710";
		If State_ZIP_Model="AR718" Then State_ZIP_Model="AR710";
		If State_ZIP_Model="OK736" Then State_ZIP_Model="OK730";
		If State_ZIP_Model="OK738" Then State_ZIP_Model="OK730";
		If State_ZIP_Model="OK739" Then State_ZIP_Model="OK730";
		If State_ZIP_Model="OK745" Then State_ZIP_Model="OK740";
		If State_ZIP_Model="OK746" Then State_ZIP_Model="OK740";
		If State_ZIP_Model="OK747" Then State_ZIP_Model="OK740";
		If State_ZIP_Model="TX755" Then State_ZIP_Model="TX750";
		If State_ZIP_Model="TX788" Then State_ZIP_Model="TX780";
		If State_ZIP_Model="CO807" Then State_ZIP_Model="CO800";
		If State_ZIP_Model="CO810" Then State_ZIP_Model="CO810";
		If State_ZIP_Model="WY820" Then State_ZIP_Model="WY820";
		If State_ZIP_Model="WY822" Then State_ZIP_Model="WY820";
		If State_ZIP_Model="WY824" Then State_ZIP_Model="WY820";
		If State_ZIP_Model="WY825" Then State_ZIP_Model="WY820";
		If State_ZIP_Model="WY828" Then State_ZIP_Model="WY820";
		If State_ZIP_Model="ID832" Then State_ZIP_Model="ID830";
		If State_ZIP_Model="ID835" Then State_ZIP_Model="ID830";
		If State_ZIP_Model="AZ859" Then State_ZIP_Model="AZ850";
		If State_ZIP_Model="AZ865" Then State_ZIP_Model="AZ860";
		If State_ZIP_Model="NM873" Then State_ZIP_Model="NM870";
		If State_ZIP_Model="NM877" Then State_ZIP_Model="NM870";
		If State_ZIP_Model="NM883" Then State_ZIP_Model="NM880";
		If State_ZIP_Model="NV895" Then State_ZIP_Model="NV890";
		If State_ZIP_Model="NV897" Then State_ZIP_Model="NV890";
		If State_ZIP_Model="NV898" Then State_ZIP_Model="NV890";
		If State_ZIP_Model="CA903" Then State_ZIP_Model="CA900";
		If State_ZIP_Model="CA905" Then State_ZIP_Model="CA900";
		If State_ZIP_Model="CA943" Then State_ZIP_Model="CA940";
		If State_ZIP_Model="CA944" Then State_ZIP_Model="CA940";
		If State_ZIP_Model="CA946" Then State_ZIP_Model="CA940";
		If State_ZIP_Model="CA947" Then State_ZIP_Model="CA940";
		If State_ZIP_Model="CA948" Then State_ZIP_Model="CA940";
		If State_ZIP_Model="CA961" Then State_ZIP_Model="CA960";
		If State_ZIP_Model="WA988" Then State_ZIP_Model="WA980";
		If State_ZIP_Model="WA994" Then State_ZIP_Model="WA990";
		If State_ZIP_Model="AK998" Then State_ZIP_Model="AK990";
		If State_ZIP_Model="AK999" Then State_ZIP_Model="AK990";

		/*@Action: Recode Race values ***/
		If Race="White" Then Race_Resp=1;
			Else If Race="Black" Then Race_Resp=2;
			Else If Race="Asian" Then Race_Resp=3;
			Else If Race="Other" Then Race_Resp=4;

		/*@Action: Select single condition when more than one present ***/
		Length Condition $6.;
		If SCD=1 Then Condition="SCD";
			Else If CF=1	 Then Condition="CF";
			Else If CELIAC=1 Then Condition="CELIAC";
			Else If ASTHMA=1 Then Condition="ASTHMA";
			Else If SB=1	 Then Condition="SB";
				Run;

/*@Action: Separate File into three pieces to be used in race imputation routine ***/
/*@Note: Module 1 -- Known condition information ***/
Data People_with_Condition;
	Set PreEHR_PQ_Pre;
		if Condition^="" and Race in ("Unknown", "Hispanic");
Run;

/*@Action: Module 2&3 Prep ***/
Proc Sql;
	/*@Note: Module 2 -- Indicated as Hispanic race with no condition information ***/
	Create table People_with_Hispanic as
		Select *
			from PreEHR_PQ_Pre
				Where Race = "Hispanic" and PATID not in (Select distinct PATID from People_with_Condition);

	/*@Note: Module 3 -- All remaining (No conditions and not indicated as Hispanic) ***/
	Create table People_Impute_By_Model as
		Select *
			from PreEHR_PQ_Pre
				Where PATID not in (Select distinct PATID From People_with_Condition) and
					  PATID not in (Select distinct PATID From People_with_Hispanic) and
					  Race = "Unknown";
Quit;

/*@Action: Run each of the Pre-Processing PQ modules ***/
%Include "&PROGS_PRE.\&Module1..sas" /LRECL=500;
%Include "&PROGS_PRE.\&Module2..sas" /LRECL=500;
%Include "&PROGS_PRE.\&Module3..sas" /LRECL=500;

/*@Action: Compile imputed Race values and add to output file ***/
Data Imputed_Race_Values(Keep=PATID Impute_Race);
	Set Imputed_Race_by_Cond Imputed_Race_by_Hisp Imputed_Race_by_Model;
Proc Sort Data=Imputed_Race_Values;
	By PATID;
Proc Sort Data=Pre_Processed_&EHR_PRE_Out.;
	By PATID;
Data SASOut.Pre_Processed_&EHR_PRE_Out.(Drop=Impute_Race);
	Merge Pre_Processed_&EHR_PRE_Out.(in=A) Imputed_Race_Values(in=B);
		By PATID;
			Length Imputed_Race $7.;
			Race_Imputed=0;
			If A and B Then Do;
				Imputed_Race=Impute_Race;
				Race_Imputed=1;
			End;
				Else if A and ^(B) and Race in ("Unknown","Hispanic") Then Imputed_Race="Unknown";
				Else Imputed_Race=Race;
Run;

/*@Action: Clear temporary work library ***/
Proc Datasets Library=WORK Kill Nolist;
Quit;

/*@Action: Cease SAS Log output ***/
Proc Printto;
Run;
/*@PROGRAM END ***/

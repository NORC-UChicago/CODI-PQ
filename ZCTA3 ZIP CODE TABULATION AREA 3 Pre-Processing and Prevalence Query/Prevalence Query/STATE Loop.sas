/*******************************************************************************************/
/***PROGRAM: STATE Loop.SAS												 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/***To run the State loop on the CODI ZCTA Prevalence Query please do the following:	 ***/
/***STEP 1: Update ACS_PRE and PQ_QUICKSTART macro variables							 ***/
/***STEP 2: Set ALL_STATES = N; in the Quickstart-CODI_PQ_ZCTA3.sas file.				 ***/
/***STEP 3: Set GEO_GROUP = STATE; in the Quickstart-CODI_PQ_ZCTA3.sas file.			 ***/
/***STEP 4: Set ALL_STATES = %STR(&ON_DECK.); in the Quickstart-CODI_PQ_ZCTA3.sas file.	 ***/
/*******************************************************************************************/

/*@STEP 1: Update macro variables 																			***/
/***/ %Let ACS_LOC = P:\1 Output\Pre_Processed_CODI_PQ_ZCTA3; /*@Note: File directory of pre preprocessed ACS State ZCTA3 SAS file (ACCEPTED VALUES: File path) ***/
/***/ %Let PQ_QUICKSTART = P:\0 SAS Programs;				  /*@Note: File directory of CODI PQ ZCTA3 Quickstart program (ACCEPTED VALUES: File path) 			***/
/**************************************************************************************************************/

/*******************************************************************************************************************************/
/*******************************************************************************************************************************/
/*** STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP ***/
/*******************************************************************************************************************************/
/*******************************************************************************************************************************/







/*@Action: Load library containing ACS State ZCTA3 SAS file ***/
Libname ACS_PRE "&ACS_LOC." Access=Readonly;

/*@Action: Loop through state level estimates ***/
Proc Sql NOPRINT;
	Select Distinct Substr(Geography, 1, 2) into :ACS_STATE_LIST Separated by " " From ACS_PRE.ACS_STATE_ZCTA3;
Quit;

%Macro Loop_PQ_STATE;
	%Let STATELOOP=1; %Let Scan_STATE=%Scan(&ACS_STATE_LIST., &STATELOOP.);
	%Let On_Deck=%unquote(%str(%'&Scan_STATE.%'));

	%Do %While("&Scan_STATE." NE "");
		%Include "&PQ_QUICKSTART.\Quickstart-CODI_PQ_ZCTA3.sas" / lrecl=500;

		%Let STATELOOP=%Eval(&STATELOOP.+1); %Let Scan_STATE=%Scan(&ACS_STATE_LIST., &STATELOOP.);
		%Let On_Deck=%unquote(%str(%'&Scan_STATE.%'));
	%End;
%Mend;

%Loop_PQ_STATE;
/*@Program End ***/

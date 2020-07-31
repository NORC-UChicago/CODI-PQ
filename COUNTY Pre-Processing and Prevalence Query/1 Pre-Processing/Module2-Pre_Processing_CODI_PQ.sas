/*******************************************************************************************/
/***PROGRAM: Module2-Pre-Processing_CODI_PQ.SAS							 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
/*@Action: Apply rename macro variables to ACS counts and compute cumulative distribution ***/
Data ACS_LATIN_Counts;
	Set SASOut.&ACS_PRE_Out.;
		PERC_LATIN_WHITE=LATIN_WHITE/TOTAL_LATIN;
		PERC_LATIN_BLACK=LATIN_BLACK/TOTAL_LATIN;
		PERC_LATIN_ASIAN=LATIN_ASIAN/TOTAL_LATIN;
		PERC_LATIN_OTHER=LATIN_OTHER/TOTAL_LATIN;
Data ACS_LATIN_Distribution(Keep=Geography Cumulative_:);
	Set ACS_LATIN_Counts;
		Where TOTAL_LATIN>0;
		Cumulative_ACS_ASIAN = PERC_LATIN_ASIAN;
		Cumulative_ACS_BLACK = Cumulative_ACS_ASIAN+PERC_LATIN_BLACK;
		Cumulative_ACS_OTHER = Cumulative_ACS_BLACK+PERC_LATIN_OTHER;
		Cumulative_ACS_WHITE = Cumulative_ACS_OTHER+PERC_LATIN_WHITE;
			Run;

Proc Sql NOPRINT;
	Select Count(Distinct Geography) Into :GEOG_CNT Trimmed From People_with_Hispanic;
	Select Distinct Geography Into :GEOG_LIST Separated by " " From People_with_Hispanic;
		Quit;

/*@Action: Imputation Macro ***/
%Macro Impute_Race_Hispanic;
	Proc Datasets Lib=Work nolist; Delete Imputed_Race_by_Hisp; Quit;

	%Do I=1 %To &GEOG_CNT. %By 1;
		%Let GEOG = %SCAN(&GEOG_LIST., &I.);
		%Let SEED = %EVAL(%SUBSTR(&GEOG.,3,3)+&I.);
		Proc Sql;
			Create table GEOG_&I. as
				Select *, Ranuni(&SEED.) as Randuni
					From People_with_Hispanic
						Where Geography = "&GEOG."
							Order by Geography, PATID;
								Quit;

		Data GEOG_&I._Impute;
			Merge GEOG_&I.(IN=A) ACS_LATIN_Distribution(In=B Where=(Geography="&GEOG."));
				By Geography;
				IF A and B;
					If 		  			 0<=Randuni<=Cumulative_ACS_ASIAN Then Impute_Race = "Asian"; Else
					If Cumulative_ACS_ASIAN<Randuni<=Cumulative_ACS_BLACK Then Impute_Race = "Black"; Else
					If Cumulative_ACS_BLACK<Randuni<=Cumulative_ACS_OTHER Then Impute_Race = "Other"; Else
														 					   Impute_Race = "White";
						Run;

		Proc Append Base=Imputed_Race_by_Hisp Data=GEOG_&I._Impute;
			Run;

		Proc Datasets NOLIST;
			Delete GEOG_&I. GEOG_&I._Impute;
				Quit;
	%End;
%Mend;

%Impute_Race_Hispanic;
/*@PROGRAM END ***/

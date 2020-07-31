/*******************************************************************************************/
/***PROGRAM: Macro1-CODI_PQ.SAS											 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
%Macro Generate_ACS_Controls;
	 /*@Action: ACS Variables needed to compute necessary control totals ***/
	%Let ACSKeep=AGE_L5_MALE_WHITE AGE_5_9_MALE_WHITE AGE_10_14_MALE_WHITE AGE_15_17_MALE_WHITE
	 AGE_18_19_MALE_WHITE AGE_L5_FEMALE_WHITE AGE_5_9_FEMALE_WHITE AGE_10_14_FEMALE_WHITE AGE_15_17_FEMALE_WHITE
	 AGE_18_19_FEMALE_WHITE AGE_L5_MALE_BLACK AGE_5_9_MALE_BLACK AGE_10_14_MALE_BLACK AGE_15_17_MALE_BLACK
	 AGE_18_19_MALE_BLACK AGE_L5_FEMALE_BLACK AGE_5_9_FEMALE_BLACK AGE_10_14_FEMALE_BLACK AGE_15_17_FEMALE_BLACK
	 AGE_18_19_FEMALE_BLACK AGE_L5_MALE_ASIAN AGE_5_9_MALE_ASIAN AGE_10_14_MALE_ASIAN AGE_15_17_MALE_ASIAN
	 AGE_18_19_MALE_ASIAN AGE_L5_FEMALE_ASIAN AGE_5_9_FEMALE_ASIAN AGE_10_14_FEMALE_ASIAN AGE_15_17_FEMALE_ASIAN
	 AGE_18_19_FEMALE_ASIAN AGE_L5_MALE_OTHER AGE_5_9_MALE_OTHER AGE_10_14_MALE_OTHER AGE_15_17_MALE_OTHER
	 AGE_18_19_MALE_OTHER AGE_L5_FEMALE_OTHER AGE_5_9_FEMALE_OTHER AGE_10_14_FEMALE_OTHER AGE_15_17_FEMALE_OTHER
	 AGE_18_19_FEMALE_OTHER AGE_25_64_BACH_GRAD_GTR20PERC;

	 /*@Action: Formats to standardize ACS values to IQVIA values being used ***/
	 Proc Format;
		/*@Note: Age Categories ***/
		Value $Age_ACS "AGE 2 4"   = "02 - 04"
				  	   "AGE 5 9"   = "05 - 09"
				 	   "AGE 10 14" = "10 - 14"
				  	   "AGE 15 17" = "15 - 17"
				  	   "AGE 18 19" = "18 - 19"
				  	   ;
		/*@Note: Sex ***/
		Value $Sex_ACS "MALE"   = "Male"
				  	   "FEMALE" = "Female"
					   ;
		/*@Note: Race ***/
		Value $Race_ACS "WHITE" = "White"
				  	    "BLACK" = "Black"
				 	    "ASIAN" = "Asian"
				  	    "OTHER" = "Other"
				  	    ;
	Run;

	/*@Action: Include on the variables necessary to compute control totals ***/
	Data Census_ACS_Prep;
		Retain Geography &ACSKeep.;
		Set SASIN.&FileIN_Name2.(Keep=Geography &ACSKeep.);
	Run;

	/*@Action: Remove less than 2 y.o. from ACS (<5) counts 							***/
	/*@Note: According to Census 2000 counts, roughly 32.6% should be removed from (<5) ***/
	/*@Action: Begin by loading ACS less than 5 (L5) variables into macro list ***/
	Proc Sql Noprint;
		Select Name into: Age_L5_List Separated by " " From Dictionary.Columns Where Libname="WORK" and Memname="CENSUS_ACS_PREP" and Index(Name, "AGE_L5")=1;
	quit;

	/*@Action: Separate 0 and 1 year olds from less than 5 (L5) age variables ***/
	Data Ages_L5;
		Set Census_ACS_Prep(Keep=Geography &Age_L5_List.);
			/*@Action: Macro to remove 0-1 y.o from each race and sex ACS variable ***/
			%Macro Split_L5(Sex, Race_List);
				%Global KeepList_&Sex.; %Let KeepList_&Sex.=; %Let I=1; %Let Race=%SCAN(&Race_List., &I.);
				
				%DO %WHILE(&Race. NE);
					%Let KeepList_&Sex.=&&&KeepList_&Sex. AGE_2_4_&Sex._&Race.;
					If 0<(AGE_L5_&Sex._&Race.*0.325818)<1 then AGE_0_1_&Sex._&Race. = 1;
						Else AGE_0_1_&Sex._&Race. = ROUND(AGE_L5_&Sex._&Race.*0.325818, 1);
					If 0<(AGE_L5_&Sex._&Race.*0.674182)<1 Then AGE_2_4_&Sex._&Race. = 1;
						Else AGE_2_4_&Sex._&Race. = ROUND(AGE_L5_&Sex._&Race.*0.674182, 1);
					%Let I=%EVAL(&I.+1); %Let Race=%SCAN(&Race_List., &I.);
				%END;
			%Mend;

			%Split_L5(Sex=MALE,   Race_List=WHITE BLACK ASIAN OTHER);
			%Split_L5(Sex=FEMALE, Race_List=WHITE BLACK ASIAN OTHER);

	Data Ages_2_4(Keep=Geography &KeepList_Male. &KeepList_Female.);
		Set Ages_L5;
	Run;

	/*@Action: Merge in new ages range (2-4) and drop L5 variables ***/
	/*@Note: Join key is State+County							   ***/
	Proc Sql NOPRINT;
		Create table Census_ACS_Prep_Final as
			select a.*, b.*
				from Census_ACS_Prep(Drop=&Age_L5_List.) as a left join Ages_2_4 as b
					on a.Geography=b.Geography;

			select name into :ACS_Full_Var separated by " " from Dictionary.Columns where Libname="WORK" and Memname="CENSUS_ACS_PREP_FINAL" and Name not in ("Geography","AGE_25_64_BACH_GRAD_GTR20PERC");
	Quit;

	/*@ACtion: Macro to re-orient table from horizontal to vertical ***/
	%Macro Reorient;
		%Let I=1; %Let Curr=%SCAN(&ACS_Full_Var., &I., " "); %Let Next=%SCAN(&ACS_Full_Var., %EVAL(&I.+1), " ");
		%DO %WHILE(&CURR. NE);
			%If "&Next."^="" %Then %Do;
				select Geography, AGE_25_64_BACH_GRAD_GTR20PERC, "&Curr." as ACS_Var, &Curr. as ACS_Count from Census_ACS_Prep_Final union
			%End;
			%Else %Do;
				select Geography, AGE_25_64_BACH_GRAD_GTR20PERC, "&Curr." as ACS_Var, &Curr. as ACS_Count from Census_ACS_Prep_Final
			%End;
		%Let I=%EVAL(&I.+1); %Let Curr=%SCAN(&ACS_Full_Var., &I., " "); %Let Next=%SCAN(&ACS_Full_Var., %EVAL(&I.+1), " ");
		%End;
	%Mend;

	Proc Sql;
		Create table ACS_Universe_Controls as
			%Reorient;;
	Quit;

	/*Action: Final ACS Control totals ***/
	/*@Note: Full ACS Universe totals ***/
	Data ACS_Controls_Full_Universe;
		Set ACS_Universe_Controls;
			Age_Categories=Put(Strip(Scan(ACS_Var, 1, "_")||" "||Scan(ACS_Var, 2, "_")||" "||Scan(ACS_Var, 3, "_")), $AGE_ACS.);
			Sex=Put(Scan(ACS_Var, 4, "_"), $Sex_ACS.);
			Race=Put(Scan(ACS_Var, 5, "_"), $RACE_ACS.);

	/*@Action: Apply User selection criteria to ACS file ***/
	/*@Note: Supressed race values are excluded 		 ***/
	Data ACS_Controls_User_Universe;
		Set ACS_Controls_Full_Universe;
			Where &Master_Logic.;
	run;

	%If "&Drop_Race."^="" %Then %do;
		Data ACS_Controls_User_Universe;
			Set ACS_Controls_User_Universe;
				Where Race not in (&Drop_Race.);
		Run;
	%end;

	/*@Action: Finish ACS control totals to be used in weighting ***/
	Proc Sql;
		Create table ACS_Age_Controls as
			Select Age_Categories as AGE_Raking, Sum(ACS_Count) as mrgtotal From ACS_Controls_User_Universe Group by Age_Categories;
		Create table ACS_Sex_Controls as
			Select Sex as SEX_Raking, Sum(ACS_Count) as mrgtotal From ACS_Controls_User_Universe Group by Sex;
		Create table ACS_Race_Controls as
			Select Race as RACE_Raking, Sum(ACS_Count) as mrgtotal From ACS_Controls_User_Universe Group by Race;
		Create table ACS_Geo_Controls as
			Select Geography as GEO_Raking, AGE_25_64_BACH_GRAD_GTR20PERC as Educ_Raking, Sum(ACS_Count) as mrgtotal From ACS_Controls_User_Universe Group by GEO_Raking, AGE_25_64_BACH_GRAD_GTR20PERC;
		Create table ACS_Geography_Totals as
			Select Geography, AGE_25_64_BACH_GRAD_GTR20PERC, Sum(ACS_COUNT) as ACS_POP_CNT from ACS_Controls_User_Universe group by Geography, AGE_25_64_BACH_GRAD_GTR20PERC;
	Quit;
%Mend;
/*@Program End ***/

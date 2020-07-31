/*******************************************************************************************/
/***PROGRAM: Module1-CODI_PQ.SAS										 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
%Macro CODI_PQ;
	%Let FailureCode=;
	/*@Action: Load User Input Macro vairables into a macro list ***/
	%Let Age_List  = %STR(AGE_2_4, AGE_5_9, AGE_10_14, AGE_15_17, AGE_18_19);
	%Let Sex_List  = %STR(SEX_MALE, SEX_FEMALE);
	%Let Race_List = %STR(RACE_WHITE, RACE_BLACK, RACE_ASIAN, RACE_OTHER);

	/*@Action: User input QC, default value set to no (N) ***/
	%Macro Selection_Default(Include_All, Var_List);
		/*@Note: If the ALL option is specified, set all macro selections to "Y" ***/
		%IF %SYSFUNC(UPCASE(&Include_All.)) = Y %THEN %DO;
			%Let I=1; %Let User_Input = %SCAN(&Var_List., &I., ",");
			%DO %WHILE(&User_Input. NE);
				%LET &USER_INPUT. = Y;
				%Let I=%EVAL(&I.+1); %Let User_Input = %SCAN(&Var_List., &I., ",");
			%END;
		%END;
		/*@Note: If the ALL option is not specified, check and correct (if invalid) individual macro selections ***/
		%ELSE %DO;
			%Let I=1; %Let User_Input = %SCAN(&Var_List., &I., ",");
			%DO %WHILE(&User_Input. NE);
				%IF %SUBSTR(%SYSFUNC(UPCASE(&&&User_Input.)), 1, 1)^=Y %THEN %LET &USER_INPUT. = N; %ELSE %LET &USER_INPUT. = Y;
				%Let I=%EVAL(&I.+1); %Let User_Input = %SCAN(&Var_List., &I., ",");
			%END;
		%END;
	%Mend;

	/*@Action: Execute USER QC Macro ***/
	%Selection_Default(Include_All=&All_Ages.,  Var_List=&Age_List.);
	%Selection_Default(Include_All=&All_Sexes., Var_List=&Sex_List.);
	%Selection_Default(Include_All=&All_Races., Var_List=&Race_List.);
	/****************************************************************/

	/*@Action: Construct query logic based on user macro input variables ***/
	%Global RACEVAR QUERY_FOOT AGE_FOOT SEX_FOOT RACE_FOOT GEOGRAPHY_FOOT YEAR_FOOT MASTER_LOGIC;
	%Let MASTER_LOGIC=;

	/*@Action Load user macro responses and values needed to select CODI records ***/
	/*@Note: AGE Selection, IF INDIVIDUAL VALUES CHANGE UPDATE AGE_VALUES VARIABLE ***/
	%Let AGE_REQUEST = %Sysfunc(CATS(&AGE_2_4., &AGE_5_9., &AGE_10_14., &AGE_15_17., &AGE_18_19.));
	%Let AGE_VALUES  = %STR(02 - 04,05 - 09,10 - 14,15 - 17,18 - 19);

	/*@Note: SEX Selection, IF INDIVIDUAL VALUES CHANGE UPDATE SEX_VALUES VARIABLE ***/
	%Let SEX_REQUEST = %Sysfunc(CATS(&SEX_MALE., &SEX_FEMALE.));
	%Let SEX_VALUES  = %STR(Male,Female);

	/*@Note: RACE Selection, IF INDIVIDUAL VALUES CHANGE UPDATE RACE_VALUES VARIABLE ***/
	%If &IMP_RACES.=Y %Then %Let RACEVAR=IMPUTED_RACE; %Else %Let RACEVAR=RACE;
	%Let RACE_REQUEST = %Sysfunc(CATS(&RACE_WHITE., &RACE_BLACK., &RACE_ASIAN., &RACE_OTHER.));
	%Let RACE_VALUES = %STR(White,Black,Asian,Other);

	/*@Action: Load selection criteria into SQL query logic ***/
	%Macro Build_Query(Request, Values, Var, Query);
		%If %Sysfunc(COUNTC(&REQUEST., "Y"))>0 %Then %Do;
			%Let BUILD_QUERY=;
			%Let I=1; %Let VALUE = %Scan(&VALUES., &I., ",");
			%Do %While("&VALUE." NE "");
				%If %Substr(&REQUEST., &I., 1) = Y %Then %Do;
					%If "&BUILD_QUERY."="" %Then %Let BUILD_QUERY = %unquote(%str(%'&VALUE.%'));
						%Else %Let BUILD_QUERY = &BUILD_QUERY., %unquote(%str(%'&VALUE.%'));
				%End;
				%Let I = %Eval(&I.+1); %Let VALUE = %Scan(&VALUES., &I., ",");
			%End;

			%Let &Query._FOOT  = %SYSFUNC(Compress(&Query.: (&BUILD_QUERY.), %str(%')));
			%If "&MASTER_LOGIC."="" %Then %Let MASTER_LOGIC = &Var. IN (&BUILD_QUERY.);
				%Else %Let MASTER_LOGIC = &MASTER_LOGIC. AND &Var. IN (&BUILD_QUERY.);
		%End;
		%Else %Let &Query._FOOT  = &Query.: (None Selected);
	%Mend;

	%Build_Query(Request=&AGE_REQUEST.,  Values=&AGE_VALUES.,  Var=AGE_CATEGORIES, Query=AGE);
	%Build_Query(Request=&SEX_REQUEST.,  Values=&SEX_VALUES.,  Var=SEX,			   Query=SEX);
	%Build_Query(Request=&RACE_REQUEST., Values=&RACE_VALUES., Var=RACE,		   Query=RACE);

	/*@Action: Logic for requested GEOGRAPHY ***/
	%If &STATE. NE or &GEO_LIST. NE %Then %Do;
		%If %Sysfunc(UPCASE(&STATE.)) = Y and &Geo_List.='08' %Then %Let GEO_LIST=%STR('08001','08005','08013','08014','08031','08035','08059');

		/*@Action: Query logic for geography ***/
		%If "&MASTER_LOGIC."="" %Then %Let MASTER_LOGIC = GEOGRAPHY IN (&GEO_LIST.);
			%Else %Let MASTER_LOGIC = &MASTER_LOGIC. AND GEOGRAPHY IN (&GEO_LIST.);

		/*@Action: Footnote for geography ***/
		%If %Sysfunc(UPCASE(&GEO_LIST.)) NE %Then %Let GEOGRAPHY_FOOT  = %SYSFUNC(Compress(Geography: (&GEO_LIST.), %Str(%')));
	%End;
	%Else %Let GEOGRAPHY_FOOT = Geography: (None Selected);

	%Let QUERY_FOOT = Query Parameters: AGE RACE SEX GEOGRAPHY YEAR;

	/*@Action: Years requested footnote ***/
	%IF &BEG_YEAR.=&END_YEAR. %Then %Let YEAR_FOOT=Year: &BEG_YEAR.;
		%Else %Let YEAR_FOOT=Years: &BEG_YEAR. - &END_YEAR.;

	/*@Action: Print footnote and query info to log ***/
	%PUT &QUERY_FOOT.;
	%PUT &AGE_FOOT.;
	%PUT &SEX_FOOT.;
	%PUT &RACE_FOOT.;
	%PUT &GEOGRAPHY_FOOT.;
	%PUT &MASTER_LOGIC.;
	%PUT &YEAR_FOOT.;
	/**************************************************/

	/*@Action: Macro to check input values for all "N", for example exclusion of all ages 				   ***/
	/*@Note: The user MUST select at least one level for each SDOH, i.e. at least one "Y" in each category ***/
	%Macro Selection_Fail(Var, Var_List);
		%If (&Var.^=Geography and &Var.^=Year and %Index(&VAR_List., Y)=0) or (&Var.=Geography and &Var_List.=) or (&Var.=Year and (&BEG_YEAR.= or &END_YEAR.=)) %Then %Do;
			%Let Select_Fail=1;
			%Let Fail_List=&Fail_List. &Var.;
		%End;
	%Mend;

	%Let Fail_List=; %Let Select_Fail=0;

	%Selection_Fail(Var=Geography, Var_List=&Geo_List.);
	%Selection_Fail(Var=Age, 	   Var_List=&AGE_2_4. &AGE_5_9. &AGE_10_14. &AGE_15_17. &AGE_18_19.);
	%Selection_Fail(Var=Race, 	   Var_List=&RACE_WHITE. &RACE_BLACK. &RACE_ASIAN. &RACE_OTHER.);
	%Selection_Fail(Var=Sex, 	   Var_List=&SEX_MALE. &SEX_FEMALE.);
	%Selection_Fail(Var=Year, 	   Var_List=&BEG_YEAR. &END_YEAR.);

	%If %Eval(&Select_Fail.=1) %Then %Do;
		%Let FailureCode=1;
		%Goto Exit;
	%End;
	
	/*@Action: Year ***/
	%If not(&BEG_YEAR. in (2016 2017 2018 2019)) or not(&END_YEAR. in (2016 2017 2018 2019)) %Then %Do; 
		%Let FailureCode=2;
		%Goto Exit;
	%End;

	/*@Action: Bad Geo_List ***/
	%If &STATE.=N %Then %Do;
		%Let I=1; %let Scan_Geo=%SCAN(&Geo_List., &I., %STR(,));
		%Do %While(&Scan_Geo. NE);
			%If %Length(&Scan_Geo.)^=7 %Then %Do;
				%Let FailureCode=4;
				%Goto Exit;
			%End;
			%Let I=%Eval(&I.+1); %let Scan_Geo=%SCAN(&Geo_List., &I., %STR(,));
		%End;
	%End;
	/**************************************************/

	/*@Action: Query EHR file based on user selection citeria ***/
	%Global RaceSupress_Foot RaceImpute_Foot ACS_POP_TOT USER_SAMP_TOT; 
	Proc Sql NOPRINT;
		Create table Stacked_Years as
			Select &BEG_YEAR. as Year, PATID,
				COUNTY_FIPS as COUNTY, STATE_FIPS, Geography, Cats(STATE_FIPS, COUNTY_FIPS) as STCNTY,
				Sex, &RACEVAR. as Race, Race_Imputed,
				WTCAT&BEG_YEAR. as Wgt_Cat Label = "Weight Category",
				AgeYR&BEG_YEAR. as Age Label = "Age, In Years", Age_Categories&BEG_YEAR. as Age_Categories
					From SASIN.&FileIN_Name1.
						%IF &BEG_YEAR.^=&END_YEAR. %THEN %DO I=%Eval(&BEG_YEAR.+1) %TO &END_YEAR.;
							Union
								Select &I. as Year, PATID,
									COUNTY_FIPS as COUNTY, STATE_FIPS, Geography, Cats(STATE_FIPS, COUNTY_FIPS) as STCNTY,
									Sex, Put(&RACEVAR., $Race.) as Race, Race_Imputed,
									WTCAT&I. as Wgt_Cat,
									AgeYR&I. as Age, Age_Categories&I. as Age_Categories
										From SASIN.&FileIN_Name1.
						%END;;

		/*@Action: Apply user selection criteria to EHR data file ***/
		Create table User_Select as
			Select *
				From Stacked_Years
					Where &MASTER_LOGIC. and Wgt_Cat is not null
						Order by PATID, Year;

		/*@Action: Check number of records in User_Select, if 0 then algorithm will fail ***/
		Select NOBS into :Queried_Records Trimmed From Dictionary.Tables where Libname='WORK' and Memname='USER_SELECT';
	Quit;

	%If &Queried_Records.=0 %Then %Do;
		%Let FailureCode=5;
		%Goto Exit;
	%End;

	/*@Action: Unduplicate individuals by selecting most recent record based on year ***/
	Data User_Select;
		Set User_Select;
			By PATID;
				If Last.PATID;
	Run;

	/*@Action: Check Survey counts by race and remove race if necessary ***/
	Proc Freq Data=User_Select;
		Table Race / Out=Screen_Race_Counts Noprint;
	Run;

	Proc Sql NOPRINT;
		%Let Drop_Race=;
		Select Distinct cats("'",Race,"'") into :Drop_Race Separated by ',' From Screen_Race_Counts Where Count<20;
		Select Distinct Race into :Present_In_EHR Separated by ' ' From User_Select;

		%If &Race_White.=Y and not(White in (&Present_In_EHR.)) and "&Drop_Race." ne "" %Then %Let Drop_Race=&Drop_Race., 'White';
			%Else %If &Race_White.=Y and not(White in (&Present_In_EHR.)) %Then %Let Drop_Race='White';
		%If &Race_Black.=Y and not(Black in (&Present_In_EHR.)) and "&Drop_Race." ne "" %Then %Let Drop_Race=&Drop_Race., 'Black';
			%Else %If &Race_Black.=Y and not(Black in (&Present_In_EHR.)) %Then %Let Drop_Race='Black';
		%If &Race_Asian.=Y and not(Asian in (&Present_In_EHR.)) and "&Drop_Race." ne "" %Then %Let Drop_Race=&Drop_Race., 'Asian';
			%Else %If &Race_Asian.=Y and not(Asian in (&Present_In_EHR.)) %Then %Let Drop_Race='Asian';
		%If &Race_Other.=Y and not(Other in (&Present_In_EHR.)) and "&Drop_Race." ne "" %Then %Let Drop_Race=&Drop_Race., 'Other';
			%Else %If &Race_Other.=Y and not(Other in (&Present_In_EHR.)) %Then %Let Drop_Race='Other';
	Quit;

	%If "&Drop_Race."^="" %Then %do;
		%let RaceSupress_Foot = RACE Suppressed: (%Sysfunc(compress("&Drop_Race.",%STR(%'%"))));
			Data User_Select;
				Set User_Select;
					Where Race not in (&Drop_Race.);
			Run;
	%end;
	%Else %Let RaceSupress_Foot = RACE Suppressed: (None);

	/*@Action: Check number of records in User_Select, if 0 then algorithm will fail ***/
	Proc Sql Noprint;
		Select NOBS into :Queried_Records_2 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='USER_SELECT';
	Quit;

	%If &Queried_Records_2.=0 %Then %Do;
		%Let FailureCode=5;
		%Goto Exit;
	%End;

	/*@Note: Special Footnote 2, Percentage of CLINCAL records with imputed Race. ***/
	%If &IMP_RACES.=Y %Then %Do;
		Proc Freq Data=User_Select;
			Table Race_Imputed / Out=Freq_Impute_Race Missing List Noprint;
		Data _Null_;
			Set Freq_Impute_Race;
			Where Race_Imputed=1;
				Call Symput("Perc_Imp_Race", Max(Put(Percent, 5.2),0));
		Run;

		%Let RaceImpute_Foot=RACE Imputed: &Perc_Imp_Race.% of race values were imputed. Please be advised, prevalence estimates may incur additional bias with imputed race values. Extreme caution is recommended when the proportion of imputed race values exceeds 40%.;
	%End;
	%Else %Do;
		%Let RaceImpute_Foot=Imputed race: People with unknown race were excluded.;
	%End;

	/*@Action: Census Control totals computation ***/
	/*@Note: This macro is stored in the SAS program named -- ***/
	%Generate_ACS_Controls;

	/*@Action: Create InitWgt (Initial Weight) in the EHR file ***/
	Proc sql Noprint;
		create table USER_W_Census as
			select a.*, b.ACS_POP_CNT, b.AGE_25_64_BACH_GRAD_GTR20PERC
				from User_Select as a Left Join ACS_Geography_Totals as b
					on a.Geography=b.Geography;
	Quit;

	Data Prepped_USER_File(Drop=ACS_POP_CNT);
		Set USER_W_Census;
			/*@Action: Set initial weight to 1 and update to 0 if no ACS population in geography ***/
			Length InitWgt 3.;
				If ACS_POP_CNT in (., 0) Then InitWgt = 0;
					Else InitWgt=1;

				If InitWgt=1;
	Run;

	/*@Action: Load total ACS and CODI counts into macro variables for report output ***/
	Proc sql Noprint;
		Select Sum(ACS_POP_CNT) Into :ACS_POP_TOT Trimmed From ACS_Geography_Totals;
		Select Count(*) Into :USER_SAMP_TOT Trimmed From Prepped_USER_File;
	Quit;

	/*@Action: SAS Macro to collapse sample variable levels based on above format levels (if needed) ***/
	%Let Collapse_Pass = 1;
	Data Prepped_USER_File;
		Set Prepped_USER_File;
			Label Age_Raking   = "Raking: Age"
				  Sex_Raking   = "Raking: Sex"
				  Race_Raking  = "Raking: Race"
				  GEO_Raking   = "Raking: Geography"
				  Educ_Raking  = "Raking: Education"
				  ;
			Orig_Age_Raking   = Age_Categories; 			   Age_Raking   = Age_Categories;
			Orig_Sex_Raking   = Sex;			  			   Sex_Raking   = Sex;
			Orig_Race_Raking  = Race;		  				   Race_Raking  = Race;
			Orig_GEO_Raking   = Geography;			   		   GEO_Raking 	= Geography;
			Orig_Educ_Raking  = AGE_25_64_BACH_GRAD_GTR20PERC; Educ_Raking  = AGE_25_64_BACH_GRAD_GTR20PERC;
	Run;

	/*@action: Collapse Raking Levels (If below threshold (<20)) ***/
	%Macro Setup_Wgt(Collapse_Var, FileIn, FileOut, Var, Num_Lvls, Min_Count);
		%If &Collapse_Var. = Y %Then %Do;
			Data &FileOut.;
				Set &FileIn.;
			Run;

			%If &Var.^=GEO %Then %Do I=1 %To &Num_Lvls.;
				Proc Freq Data=&FileOut. Noprint;
					Table &Var._Raking / out=Sample_Joint(Keep=&Var._Raking Count);
				Proc Freq Data=ACS_&Var._Controls Noprint;
					Table &Var._Raking / out=ACS_Raking_Levels(Keep=&Var._Raking);
				Data Sample_Joint(Keep=&Var._Raking Count Collapse_Flg);
					Merge Sample_Joint ACS_Raking_Levels;
						By &Var._Raking;
							Array Change _NUMERIC_; Do Over Change; If Change=. Then Change=0; End;
							If Count<&Min_Count. Then Collapse_Flg = Put(&Var._Raking, $&Var._&I._C.); Else Collapse_Flg="";
				Run;

				Proc Sql Noprint; Select Count(*) into :Collapse_Flg Trimmed From Sample_Joint Where Collapse_Flg = "&I.";
				Quit;

				%If %Eval(&Collapse_Flg.>0) %Then %Do;
					%Let &Var._Collapse=&Var.;
					Data Sample_Joint_Collapse;
						Set Sample_Joint;
							Collapse_Flg = Put(&Var._Raking, $&Var._&I._C.);
							If Strip(Collapse_Flg)^="" Then New_Level = Put(Collapse_Flg, $Collapse_&Var..);
								Else New_Level = &Var._Raking;
					Proc Sort Data=&FileOut.;
						By &Var._Raking;
					Proc Sort Data=ACS_&Var._Controls;
						By &Var._Raking;
					Data &FileOut.(Rename=(New_Level = &Var._Raking));
						Merge &FileOut.(In=A) Sample_Joint_Collapse(In=B Keep=&Var._Raking New_Level);
							By &Var._Raking;
								If A;
								Drop &Var._Raking;
					Data ACS_&Var._Controls(Rename=(New_Level = &Var._Raking));
						Merge ACS_&Var._Controls(In=A) Sample_Joint_Collapse(In=B Keep=&Var._Raking New_Level);
							By &Var._Raking;
								If A;
								Drop &Var._Raking;
					Run;
				%End;
			%End;
			%Else %Do;
				%Let I=1; %Let Pass=0;
				%Do %Until(&Pass.=1 or &I.>4);
					Proc Freq Data=&FileOut. Noprint;
						Table Educ_Raking*&Var._Raking / out=Sample_Joint(Keep=Educ_Raking &Var._Raking Count);
					Proc Freq Data=ACS_&Var._Controls Noprint;
						Table Educ_Raking*&Var._Raking/ out=ACS_Raking_Levels(Keep=Educ_Raking &Var._Raking);
					Data Sample_Joint(Keep=Educ_Raking &Var._Raking Count) Counts(Keep=Educ_Raking Tot_Educ);
						Merge Sample_Joint ACS_Raking_Levels;
							By Educ_Raking &Var._Raking;
								Array Change _NUMERIC_; Do Over Change; If Change=. Then Change=0; End;
								Output Sample_Joint;
								If First.Educ_Raking Then Tot_Educ=1; Else Tot_Educ+1;
								If Last.Educ_Raking Then Output Counts;
					Data Sample_Joint;
						Merge Sample_Joint Counts;
							By Educ_Raking;
					Proc Sort Data=Sample_Joint;
						By Tot_Educ Educ_Raking Count;
					Data &Var._Collapse;
						Set Sample_Joint End=Last;
							By Tot_Educ;				
								Retain Global_Fail(0);
								Global=_N_;

								If First.Tot_Educ Then Do; EducCnt=1; Fail=0; End;
									Else EducCnt+1;
					
								If Count<&Min_Count. Then do;
									Call Symput("Geo_Collapse", "Geography");
									Global_Fail+1;
									Fail+1;
								End;
								%If &I.=1 %Then %Do;
									If Count<&Min_Count. Then New_Level="EDUC"||Strip(Educ_Raking);
										Else New_Level=&Var._Raking;
									New_Educ=Educ_Raking;
								%End;
								%Else %If &I.=2 %Then %Do;
									If Fail>0 and ^(First.Tot_Educ and Last.Tot_Educ) and EducCnt in (1, 2) Then New_Level="EDUC"||Strip(Educ_Raking);
										Else New_Level=&Var._Raking;
									New_Educ=Educ_Raking;
								%End;

								If Last then Call Symput('Global_Fail',Global_Fail);
					Run;

					%If &I.=3 or &I.=4 %Then %Do;
						Data &Var._Collapse;
							Set &Var._Collapse;
									%If &I.=3 and %Eval(&Global_Fail.>0) %Then %Do;
										If Substr(&Var._Raking, 1, 4)="EDUC" Then New_Level="EDUC9";
											Else New_Level=&Var._Raking;
										New_Educ="9";
									%End;
									%Else %If &I.=4 and %Eval(&Global_Fail.>0) %Then %Do;
										If Global=2 Then New_Level="EDUC9";
											Else New_Level=&Var._Raking;
										New_Educ=Educ_Raking;
									%End;
									%Else %Do;
										New_Level=&Var._Raking;
										New_Educ=Educ_Raking;
									%End;
						Run;
					%End;

					Proc Sort Data=&Var._Collapse(Keep=Educ_Raking &Var._Raking New_Level New_Educ);
						By Educ_Raking &Var._Raking;
					Proc Sort Data=&FileOut.;
						By Educ_Raking &Var._Raking;
					Run;

					Data &FileOut.(Rename=(New_Educ = Educ_Raking New_Level = &Var._Raking));
						Merge &FileOut.(In=A) &Var._Collapse(In=B);
							By Educ_Raking &Var._Raking;
								If A;
								Drop Educ_Raking &Var._Raking;
					Proc Sort Data=ACS_&Var._Controls;
						By Educ_Raking &Var._Raking;
					Data ACS_&Var._Controls(Rename=(New_Educ = Educ_Raking New_Level = &Var._Raking));
						Merge ACS_&Var._Controls(In=A) &Var._Collapse(In=B);
							By Educ_Raking &Var._Raking;
								If A;
								Drop Educ_Raking &Var._Raking;
					Run;

					/*@Action: Update exit criteria ***/
					%If &Global_Fail.=0 %Then %Let Pass=1;			
					%Let I=%Eval(&I.+1);
				%End;
			%End;

			/*@Action: Update the Collapse Pass macro variable, if failed replace 1 with a 0 ***/
			Proc Freq Data=&FileOut. Noprint;
				Table &Var._Raking / out=Collapse_Check(Keep=&Var._Raking Count);
			Run;

			Proc SQL Noprint;
				Select Count(*) into: Collapse_Check_&Var. Trimmed From Collapse_Check Where Count<&Min_Count.;
				%If &&&Collapse_Check_&Var>0 %Then %Let Collapse_Pass=0;
			Quit;
		%End;

		%Else %Do;
			Data &FileOut.;
				Set &FileIn.;
			Run;

			/*@Action: Update the Collapse Pass macro variable, if failed replace 1 with a 0 ***/
			Proc Freq Data=&FileOut. Noprint;
				Table &Var._Raking / out=Collapse_Check(Keep=&Var._Raking Count);
			Run;

			Proc SQL Noprint;
				Select Count(*) into: Collapse_Check_&Var. Trimmed From Collapse_Check Where Count<&Min_Count.;
				%If %Eval(&&&Collapse_Check_&Var>0) %Then %Let Collapse_Pass=0;
			Quit;
		%End;
	%Mend;

	/*@Action: Run collapse macro on each weighting variable ***/
	%Global Collapse_Foot;
	%Let Age_Collapse=; %Let Geo_Collapse=;

	/*@Action: Perform collapsing and/or cell count checks ***/
	%Setup_Wgt(Collapse_Var=Y, FileIn=Prepped_USER_File,  FileOut=PreWgt_USER_File, Var=Age,   Num_Lvls=4, Min_Count=&WGTCELL_MIN.);
	%Setup_Wgt(Collapse_Var=N, FileIn=PreWgt_USER_File,	  FileOut=PreWgt_USER_File, Var=Sex,   Num_Lvls=,  Min_Count=&WGTCELL_MIN.);
/*	%Setup_Wgt(Collapse_Var=N, FileIn=PreWgt_USER_File,	  FileOut=PreWgt_USER_File, Var=Race,  Num_Lvls=,  Min_Count=&WGTCELL_MIN.);*/
	%Setup_Wgt(Collapse_Var=Y, FileIn=PreWgt_USER_File,	  FileOut=PreWgt_USER_File, Var=GEO,   Num_Lvls=,  Min_Count=&WGTCELL_MIN.);

	/*@Action: Update Census controls with new raking levels (post-collapse) ***/
	Proc Sql;
		Create table ACS_Age as
			Select Age_Raking, sum(mrgtotal) as mrgtotal From ACS_Age_Controls Group by Age_Raking;
		Create table ACS_Sex as
			Select Sex_Raking, sum(mrgtotal) as mrgtotal From ACS_Sex_Controls Group by Sex_Raking;
		Create table ACS_Race as
			Select Race_Raking, sum(mrgtotal) as mrgtotal From ACS_Race_Controls Group by Race_Raking;
		Create table ACS_Geo as
			Select GEO_Raking, sum(mrgtotal) as mrgtotal From ACS_Geo_Controls Group by GEO_Raking;
	Quit;

	/*@Action: Load collapsing information into macro variable, output as footnote in report ***/
	%If &Age_Collapse.= and &Geo_Collapse.= %Then %Let Collapse_Foot=Weighting cells were collapsed for: (None);
		%Else %Let Collapse_Foot=Weighting cells were collapsed for: (%SYSFUNC(COMPBL(&Age_Collapse. &Geo_Collapse.)));

	/*********************************************************************************************************************/
	/**************************** -- VALIDATION CHECK TO PROCEED TO PREVALENCE COMPUTATION -- ****************************/
	/********************* -- CHECKING FOR SAMPLE SIZE (POST COLLAPSE) AND CENSUS POPULATION SIZE -- *********************/
	/*********************** -- IF EITHER FAIL THEN DO NOT COMPUTE PREVALENCE, OTHERWISE PROCEED --***********************/
	/*********************************************************************************************************************/
	/*@Action: Pass/Fail based on size of Census Pop and Sample Joint Counts ***/
	%Macro Proceed;
		/*@Action: Selection passes population and sample counts -- Proceed ***/
		%If &Collapse_Pass.=1 %Then %Do;
			/*Action: Perform weighting using raking method on the fllowing SDOH: Geography(State+ZCTA3, Age, Race, Sex) ***/
			/*@Note: Execute Raking macro to perform weighting using ACS as source of control totals 					 ***/
			%RAKING(inds=PreWgt_USER_File, outds=Weighted_USER_File, inwt=InitWgt, freqlist=ACS_Geo ACS_Age ACS_Race ACS_Sex, outwt=RakeWgt, byvar=, varlist=GEO_Raking Age_Raking Race_Raking Sex_Raking, numvar=4, cntotal=, trmprec=1, numiter=50);

			/*@Action: If weighting does not fail (converges) then proceed to prevalence estimation ***/
			%If &Covergence_Pass.=1 %Then %Do;
				/*@Action: Execute Age Adjust Macro to perform age adjustment using Census 2000 ***/
				%IF &AGE_ADJ.=Y %Then %Do;
					%Age_Adjust(Inds=Weighted_USER_File, Outds=Weighted_USER_File, Inwt=RakeWgt, Outwt=AgeAdjWgt, Age_Var=Age_Categories);
				%End;

				/*@Action: Second record with Obesity for weight cateogry is created for children with severe obesity ***/
				/*Note: Obesity is to contain all cases of obesity and severe obesity 								  ***/
				Data Weighted_USER_File;
					Set Weighted_USER_File;
						/*@Action: Create 0/1 flag for crude prevalence estimation ***/
						UndrWgt_Flg=(Wgt_Cat="(1) Underweight (<5th percentile)");
						HlthyWgt_Flg=(Wgt_Cat="(2) Healthy Weight (5th to <85th percentile)");
						OvrWgt_Flg=(Wgt_Cat="(3) Overweight (85th to <95th percentile)");
						Obsty_Flg=(Wgt_Cat="(4) Obesity (>95th percentile)" or Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)");
						SvrObsty_Flg=(Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)");
				Run;

				/*@Note: Prevalence Estimation and Output Routine ***/
				%Include "&PROGS_PQ.\&Estimate_Module..sas" / LRECL = 500;
			%End;
			/*@Action: Raking has failed to converge ***/
			%Else %Do;
				%Generate_Prev_Report(Infile=, Pass=N, FailCode=6);
			%End;
	  	%End;

		/*@Action: Collapsing fails to exceed minimum allowed: Currently set to 20 ***/
		%Else %Do;
			%Generate_Prev_Report(Infile=, Pass=N, FailCode=5);
		%End;
	%Mend;

	/*@Action: Check for empty SAS datasets (i.e. Unknown SAS error) ***/
	Proc Sql Noprint;
		Select NOBS into :Error1 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='PREWGT_USER_FILE';
		Select NOBS into :Error2 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='ACS_GEO';
		Select NOBS into :Error3 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='ACS_AGE';
		Select NOBS into :Error4 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='ACS_RACE';
		Select NOBS into :Error5 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='ACS_SEX';
	Quit;

	%If &Error1.=0 or &Error2.=0 or &Error3.=0 or &Error4.=0 or &Error5.=0 %Then %Do;
		%Let FailureCode=9;
		%Goto Exit;
	%End;
	%Else %Do;
		/*@Action: Execute proceed macro ***/
		%Proceed;
	%End;

	/*@Action: Upon failure, proceed to Exit ***/
	%Exit:
	%If &FailureCode. ne %Then %Do;
		%Generate_Prev_Report(Infile=, Pass=N, FailCode=&FailureCode.);
	%End;
%Mend;
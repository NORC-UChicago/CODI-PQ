/*******************************************************************************************/
/***PROGRAM: Module1-Pre-Processing_CODI_PQ.SAS							 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
/*@Action: CDC Condition Distribution ***/
Data CDC_Condition_Dist;
	Informat Condition $19. Abbreviation $6.;
	Infile datalines DSD;
	Input Condition $ Abbreviation $ Race $ Cumulative;
	Datalines;
Asthma,ASTHMA,Asian,0.0447077641068452
Asthma,ASTHMA,Black,0.237478085742031
Asthma,ASTHMA,Other,0.439596156912258
Asthma,ASTHMA,White,1
Celiac Disease,CELIAC,Asian,0.026312804456386
Celiac Disease,CELIAC,Black,0.100148720403684
Celiac Disease,CELIAC,Other,0.171065104224216
Celiac Disease,CELIAC,White,1
Cystic Fibrosis,CF,Asian,0.00225543900679639
Cystic Fibrosis,CF,Black,0.0364779056905523
Cystic Fibrosis,CF,Other,0.0503384465192975
Cystic Fibrosis,CF,White,1
Sickle Cell Disease,SCD,Asian,0.00424183325179098
Sickle Cell Disease,SCD,Black,0.949171946057059
Sickle Cell Disease,SCD,Other,0.960604230878136
Sickle Cell Disease,SCD,White,1
Spina Bifida,SB,Asian,0.0230656853413716
Spina Bifida,SB,Black,0.156050668815657
Spina Bifida,SB,Other,0.283956859137227
Spina Bifida,SB,White,1
;
Run;

/*@Action: CDC Distribution by Disease ***/
Proc Sort Data=CDC_Condition_Dist;
	By Abbreviation Cumulative;
Run;

Proc Transpose Data=CDC_Condition_Dist Out=CDC_Condition_Dist_2(DROP=_NAME_ Rename=(Abbreviation=Condition)) Prefix=CDC_;
	ID Race;
	Var Cumulative;
	By Abbreviation;
Run;

Proc Sql NOPRINT;
	Select Count(Distinct Condition) Into :Cond_Cnt Trimmed From CDC_Condition_Dist_2;
	Select Condition Into :ABBRV Separated by " " From CDC_Condition_Dist_2;
Quit;

/*************************************************************************************************************/
/**************************************** -- RACE IMPUTATION MACRO -- ****************************************/
/*************************************************************************************************************/
%Macro Impute_Race_Condition(Intake, Seed);
	Proc Datasets Lib=Work nolist; Delete Imputed_Race_by_Cond; Quit;

	%Do I=1 %To &Cond_Cnt. %By 1;
		%Let Condition = %SCAN(&ABBRV., &I.);
		Proc Sql;
			Create table Cond_&I. as
				Select *, Ranuni(%EVAL(&SEED.+&I.)) as Randuni
					From &Intake.
						Where Condition = "&Condition."
							Order by Condition, PATID;
		Quit;

		Data Cond_&I._Impute(Drop=Randuni CDC_:);
			Merge Cond_&I.(In=A) CDC_Condition_Dist_2(Where=(Condition="&Condition."));
				By Condition;
					If A;
					If 		  0<=Randuni<=CDC_Asian Then Impute_Race = "Asian"; Else
					If CDC_Asian<Randuni<=CDC_Black Then Impute_Race = "Black"; Else
					If CDC_Black<Randuni<=CDC_Other Then Impute_Race = "Other"; Else
														 Impute_Race = "White";
		Run;

		Proc Append Base=Imputed_Race_by_Cond Data=Cond_&I._Impute;
		Run;
		Proc Datasets NOLIST;
			Delete Cond_:;
		Quit;
	%End;
%Mend;
/*************************************************************************************************************/

/*************************************************************************************************************/
/**************************************** -- RUN IMPUTATION MACRO -- *****************************************/
/*************************************************************************************************************/
/*@Action: Impute Race for records with a condition and indicated race: unknown/Hispanic ***/
%Impute_Race_Condition(Intake=People_with_Condition, Seed=23);

/*************************************************************************************************************/
/*@PROGRAM END ***/

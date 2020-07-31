/*******************************************************************************************/
/***PROGRAM: Module2-CODI_PQ.SAS										 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
/*@Action: Use weighted USER file to produce prevalence estimates ***/
%Macro Est_Prevalence(Infile, Outfile, Weight, AgeAdj);
	/*@Action: Estimate Crude Rates ***/
	Proc Means Data=&Infile. Noprint;
		Var UndrWgt_Flg;
		Output Out=UndrWgt_Crde Mean=Crude_Prev Stderr=Crude_StdErr;
	Proc Means Data=&Infile. Noprint;
		Var HlthyWgt_Flg;
		Output Out=HlthyWgt_Crde Mean=Crude_Prev Stderr=Crude_StdErr;
	Proc Means Data=&Infile. Noprint;
		Var OvrWgt_Flg;
		Output Out=OvrWgt_Crde Mean=Crude_Prev Stderr=Crude_StdErr;
	Proc Means Data=&Infile. Noprint;
		Var Obsty_Flg;
		Output Out=Obsty_Crde Mean=Crude_Prev Stderr=Crude_StdErr;
	Proc Means Data=&Infile. Noprint;
		Var SvrObsty_Flg;
		Output Out=SvrObsty_Crde Mean=Crude_Prev Stderr=Crude_StdErr;
	Run;

	Data Crude_Prevalence_Estimates(Keep=Wgt_Cat Crude_Prev Crude_StdErr);
		Retain Wgt_Cat Crude_Prev Crude_StdErr;
		Set UndrWgt_Crde(In=A) HlthyWgt_Crde(In=B) OvrWgt_Crde(In=C) Obsty_Crde(In=D) SvrObsty_Crde(In=E);
			Length Wgt_Cat $50.;
			If A Then Wgt_Cat="(1) Underweight (<5th percentile)";
				Else If B Then Wgt_Cat="(2) Healthy Weight (5th to <85th percentile)";
				Else If C Then Wgt_Cat="(3) Overweight (85th to <95th percentile)";
				Else If D Then Wgt_Cat="(4) Obesity (>95th percentile)";
				Else If E Then Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)";
	Run;

	Proc Sql Noprint;
		Select Sum(&Weight.) into :Est_Pop From &Infile.;

		Create table Prevalence_Begin as
			Select Wgt_Cat, Count(*) as Sample_Cnt, Sum(&Weight.) as Est_Pop_Cnt, (Calculated Est_Pop_Cnt/&Est_Pop.) as Est_Prev
				From &Infile.
					Where Wgt_Cat^="(4) Obesity (>95th percentile)"
						Group by Wgt_Cat
							Union
			Select "(4) Obesity (>95th percentile)" as Wgt_Cat, Count(*) as Sample_Cnt, Sum(&Weight.) as Est_Pop_Cnt, (Calculated Est_Pop_Cnt/&Est_Pop.) as Est_Prev
				From &Infile.
					Where Obsty_Flg=1
						Order by Wgt_Cat;
	Quit;

	/*@Action: Estimate the variance for prevalence estimates ***/
	Data _NULL_;
		Set Prevalence_Begin;
			If Wgt_Cat="(1) Underweight (<5th percentile)" Then Call symput("UW_Prev", Max(Est_Prev, .));
				Else If Wgt_Cat="(2) Healthy Weight (5th to <85th percentile)" Then Call symput("HW_Prev", Max(Est_Prev, .));
				Else If Wgt_Cat="(3) Overweight (85th to <95th percentile)" Then Call symput("OW_Prev", Max(Est_Prev, .));
				Else If Wgt_Cat="(4) Obesity (>95th percentile)" Then Call symput("OB_Prev", Max(Est_Prev, .));
				Else If Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)" Then Call symput("SB_Prev", Max(Est_Prev, .));
	Data USER_W_Prevalence;
		Set &Infile.;
			/*@Action: Compute variables needed for variance esimation for each prevalence estimate ***/
			If Wgt_Cat="(1) Underweight (<5th percentile)" Then Z_UnderWeight=(&Weight.*(1-&UW_Prev.))/&Est_Pop.;
				Else Z_UnderWeight=(&Weight.*(0-&UW_Prev.))/&Est_Pop.;
			If Wgt_Cat="(2) Healthy Weight (5th to <85th percentile)" Then Z_HealthyWeight=(&Weight.*(1-&HW_Prev.))/&Est_Pop.;
				Else Z_HealthyWeight=(&Weight.*(0-&HW_Prev.))/&Est_Pop.;
			If Wgt_Cat="(3) Overweight (85th to <95th percentile)" Then Z_OverWeight=(&Weight.*(1-&OW_Prev.))/&Est_Pop.;
				Else Z_OverWeight=(&Weight.*(0-&OW_Prev.))/&Est_Pop.;
			If Wgt_Cat="(4) Obesity (>95th percentile)" or Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)" Then
				Z_Obese=(&Weight.*(1-&OB_Prev.))/&Est_Pop.;
					Else Z_Obese=(&Weight.*(0-&OB_Prev.))/&Est_Pop.;
			If Wgt_Cat="(4b) Severe Obesity (>120% of the 95th percentile)" Then Z_SevereObese=(&Weight.*(1-&SB_Prev.))/&Est_Pop.;
				Else Z_SevereObese=(&Weight.*(0-&SB_Prev.))/&Est_Pop.;
	Proc Sort Data=USER_W_Prevalence;
		By Geography;
			Run;

	Proc Sql;
		Create table USER_Z_Means as
			Select Geography, Avg(Z_UnderWeight) as Avg_Z_UnderWeight,
				Avg(Z_HealthyWeight) as Avg_Z_HealthyWeight, Avg(Z_OverWeight) as Avg_Z_OverWeight,
				Avg(Z_Obese) as Avg_Z_Obese, Avg(Z_SevereObese) as Avg_Z_SevereObese
					From USER_W_Prevalence
						Group by Geography;
	quit;

	Data USER_W_Prevalence;
		Merge USER_W_Prevalence USER_Z_Means;
			By Geography;
				SqDiff_UnderWeight	 = (Z_UnderWeight-Avg_Z_UnderWeight)**2;
				SqDiff_HealthyWeight = (Z_HealthyWeight-Avg_Z_HealthyWeight)**2;
				SqDiff_OverWeight	 = (Z_OverWeight-Avg_Z_OverWeight)**2;
				SqDiff_Obese 		 = (Z_Obese-Avg_Z_Obese)**2;
				SqDiff_SevereObese	 = (Z_SevereObese-Avg_Z_SevereObese)**2;
	Run;

	Proc Sql;
		Create table USER_Prev_Variance as
			Select Geography, (Count(*)/(Count(*)-1)) as Strata_Adj,
				Calculated Strata_Adj*Sum(SqDiff_UnderWeight) as UnderWeight,
				Calculated Strata_Adj*Sum(SqDiff_HealthyWeight) as HealthyWeight,
				Calculated Strata_Adj*Sum(SqDiff_OverWeight) as OverWeight,
				Calculated Strata_Adj*Sum(SqDiff_Obese) as Obese,
				Calculated Strata_Adj*Sum(SqDiff_SevereObese) as SevereObese
					From USER_W_Prevalence
						Group by Geography;

		Create table Variance_Estimates as
			Select "(1) Underweight (<5th percentile)" as Wgt_Cat, Sum(UnderWeight) as Var_Est From USER_Prev_Variance union
			Select "(2) Healthy Weight (5th to <85th percentile)" as Wgt_Cat, Sum(HealthyWeight) as Var_Est From USER_Prev_Variance union
			Select "(3) Overweight (85th to <95th percentile)" as Wgt_Cat, Sum(OverWeight) as Var_Est From USER_Prev_Variance union
			Select "(4) Obesity (>95th percentile)" as Wgt_Cat, Sum(Obese) as Var_Est From USER_Prev_Variance union
			Select "(4b) Severe Obesity (>120% of the 95th percentile)" as Wgt_Cat, Sum(SevereObese) as Var_Est From USER_Prev_Variance;

		%If &AgeAdj.=Y %Then %Do;
			Create table &Outfile. as
				Select a.Wgt_Cat as WtCat, a.Est_Prev*100 as pop_perc_age_adj, Sqrt(b.Var_Est)*100 as std_err_age_adj
						From Prevalence_Begin as a, Variance_Estimates as b
							where a.Wgt_Cat=b.Wgt_Cat
								order by WtCat;
		%End;
		%Else %Do;
			Create table &Outfile. as
				Select a.Wgt_Cat as WtCat, a.Sample_Cnt as Sample_PT, a.Est_Pop_Cnt as Pop_n,
					c.Crude_Prev*100 as Crude_Prev, c.Crude_StdErr*100 as Crude_StdErr,
					a.Est_Prev*100 as Pop_Perc, b.Var_Est, Sqrt(b.Var_Est)*100 as STD_Err
						From Prevalence_Begin as a, Variance_Estimates as b, Crude_Prevalence_Estimates as c
							where a.Wgt_Cat=b.Wgt_Cat and a.Wgt_Cat=c.Wgt_Cat
								order by WtCat;
		%End;
			Quit;
%Mend;

%Macro Run_Est_Prevalence;
	%Est_Prevalence(Infile=Weighted_USER_File, Outfile=USER_Prevalence_Estimates, Weight=RakeWgt, AgeAdj=);

	%If &AGE_ADJ.=Y %Then %Do;
		%Est_Prevalence(Infile=Weighted_USER_File, Outfile=Age_Adjusted_Prevalence, Weight=AgeAdjWgt, AgeAdj=&AGE_ADJ.);

		Data USER_Prevalence_Estimates;
			Merge USER_Prevalence_Estimates Age_Adjusted_Prevalence;
				By WtCat;
					Run;
	%End;
%Mend;

%Run_Est_Prevalence;


%Suppress(fileinest=USER_Prevalence_Estimates, fileinwgt=Weighted_USER_File, fileout=USER_Prevalence_Suppress);

/*@Action: Check for SAS errors ***/
%Macro Check_SAS_Err2;
	Proc Sql NOPRINT;
		Select NOBS into :Error6 Trimmed From Dictionary.Tables where Libname='WORK' and Memname='USER_PREVALENCE_SUPPRESS';
	Quit;

	%IF &Error6.=0 %Then %Do;
		%Let FailureCode=9;
		%Goto Exit;
	%End;
	%Else %Do;
		/*@Action: Execute Generate Report Macro (Success) ***/
		%Generate_Prev_Report(Infile=USER_Prevalence_Suppress, Pass=Y, FailCode=);
	%End;

	%Exit: 
		%If &FailureCode. ne %Then %Do;
			%Generate_Prev_Report(Infile=, Pass=N, FailCode=&FailureCode.);
		%End;
%Mend;

/*@Action: Execute Check SAS error 2 Macro ***/
%Check_SAS_Err2;
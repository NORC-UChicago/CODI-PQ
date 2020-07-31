/*******************************************************************************************/
/***PROGRAM: Macro4-CODI_PQ_ZCTA3.SAS									 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL																 ***/
/*******************************************************************************************/
/*@Action: Macro to compute prevalence estimates ***/
%Macro Generate_Prev_Report(Infile, Pass, FailCode);
	/*@Action: Load Age Adjust Information (If requested) ***/
		%If &AGE_ADJ.=Y %then %do;
			%Let Incld_Age_Adj_P1=, Put(pop_perc_age_adj, 5.2) as AgeAdj_Prev Label="Age-Adjusted Prevalence", Put(std_err_age_adj, 5.2) as AgeAdj_StdErr Label="Age-Adjusted Prevalence Standard Error";
			%Let Incld_Age_Adj_P2=, AgeAdj_Prev, AgeAdj_StdErr;
			%Let Age_Adj_Footnote=AGE adjusted: (Yes);
			%Let Age_Adj_Caveat=Union Select 22 as Order, "The method used to calculate age-adjusted prevalence is documented in the technical documentation." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report;

			%Let Incld_Age_Adj_F1=, AgeAdj_Prev, AgeAdj_StdErr;
			%Let Incld_Age_Adj_F2=, AgeAdj_Prev, AgeAdj_StdErr;
		%End;
		%Else %Do;
			%Let Age_Adj_Footnote=AGE adjusted: (No);
			%Let Age_Adj_Caveat=;
			%Let Incld_Age_Adj_P1=;
			%Let Incld_Age_Adj_P2=;

			%Let Incld_Age_Adj_F1=;
			%Let Incld_Age_Adj_F2=;
		%End;

	/*@Action: Load Dummy table for footnote generation ***/
		Data Null_Prev_Report;
			Length WtCat $300. Samp Pop Crde_Prev Crde_StdErr Wgt_Prev Wgt_StdErr AgeAdj_Prev AgeAdj_StdErr $5.;
			Label WtCat="Weight Category"
				  Samp="Sample"
				  Pop="Population"
				  Crde_Prev="Crude Prevalence"
				  Crde_StdErr="Crude Prevalence Standard Error"
				  Wgt_Prev="Weighted Prevalence"
				  Wgt_StdErr="Weighted Prevalence Standard Error"
				  AgeAdj_Prev="Age-Adjusted Prevalence"
				  AgeAdj_StdErr="Age-Adjusted Prevalence Standard Error";
				  
			WtCat="";
			Samp="";
			Pop="";
			Crde_Prev="";
			Crde_StdErr="";
			Wgt_Prev="";
			Wgt_StdErr="";
			AgeAdj_Prev="";
			AgeAdj_StdErr="";
		Run;

	/*@Action: If algorithm has passed up to this point, begin report generation ***/
	%If &Pass. = Y %Then %Do;
		Proc Sql;
			Create table Prevalence_Report as
				Select 1 as Order, WtCat Label = "Weight Category" Length=300,
					Put(Sample_PT, Comma10.) as Samp Label = "Sample",
					Put(Pop_n, Comma10.) as Pop Label  = "Population",
					Put(Crude_Prev, 5.2) as Crde_Prev Label = "Crude Prevalence",
					Put(Crude_StdErr, 5.2) as Crde_StdErr Label = "Crude Prevalence Standard Error",
					Put(Pop_Perc, 5.2) as Wgt_Prev Label = "Weighted Prevalence",
					Put(STD_Err, 5.2) as Wgt_StdErr Label = "Weighted Prevalence Standard Error"
					&Incld_Age_Adj_P1.
						From &Infile.
							Group By WtCat
								Union
				Select 2 as Order, "Totals:" as WtCat, Put(&USER_SAMP_TOT., Comma10.) as Samp, Put(&ACS_POP_TOT., Comma10.) as Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 3 as Order, "Query Version: IQVIA, 2016-2018" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 4 as Order, "&Query_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 5 as Order, "&Age_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 6 as Order, "&Sex_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 7 as Order, "&Race_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 8 as Order, "&RaceSupress_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 9 as Order, "&RaceImpute_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 10 as Order, "&Geography_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 11 as Order, "&Year_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 12 as Order, "&Collapse_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 13 as Order, "&Age_Adj_Footnote." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 14 as Order, "Error Codes: (&Suppress_Error.)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 15 as Order, "Technical Documentation: See https://github.com/NORC-UChicago/CODI-PQ for more information and full details on data sources and methodologies." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 16 as Order, "Query Date: &DateTime2." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 17 as Order, "Suggested Citation: AEMR-US version 5 OMOP 5 [Aug 2019 Release] accessed through the E360TM Software-as-a-Service (SaaS) Platform. Accessed through prevalence query on &DateTime2." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 18 as Order, "Caveats" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 19 as Order, "Children with either missing or invalid age, sex, height, weight, or geography are not included in counts and prevalence estimates." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 20 as Order, "The method used to calculate the standard errors are documented in the technical documentation." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 21 as Order, "The population estimates are based on age-race-sex-location specific counts from the 2014-2018 American Community Survey Five-year Estimates released by the Census Bureau on December 19, 2019." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report
				&Age_Adj_Caveat.;
		Quit;
	%End;

	%Else %Do;
		%If 		  &Failcode.=1 %Then %Let Fail_Desc=One or more demographic or geographic category has no groups selected. One or more group must be selected in each category. Ensure that each demographic and geographic category has one or more groups selected (e.g., age group, select an age range for inclusion).;
			%Else %If &Failcode.=2 %Then %Let Fail_Desc=Years are out of scope for IQVIA. Acceptable years include 2016, 2017, and 2018 for IQVIA.;
			%Else %If &Failcode.=3 %Then %Let Fail_Desc=Geographic level (GEO_GROUP) has been left blank or has been set to an unacceptable value. To remedy the issue, update the GEO_GROUP variable to either STATE, ZCTA-3, or county.;
			%Else %If &Failcode.=4 %Then %Let Fail_Desc=State and/or ZCTA-3 is incorrectly specified. Review the lists and ensure each value is: Surrounded by quotations, Comma delimited, and/or The correct length (e.g., "08001", "08002", "08003", etc.).;
			%Else %If &Failcode.=5 %Then %Let Fail_Desc=Current selection criteria return an insufficient number of children and teens and do not meet minimum threshold to estimate sample weights. Ensure that selections are correct (e.g., correct list of state codes or ZCTA-3 values) or include additional geographic or demographic categories (e.g., add additional communities or include additional or all races, age groups, sex, etc.).;
			%Else %If &Failcode.=6 %Then %Let Fail_Desc=Iterative proportional fitting weighting routine has failed to converge. Please revise selection criteria and rerun algorithm.;
			%Else 						 %Let Fail_Desc=A SAS error has occurred within the algorithm. Review the SAS log or contact a system administrator for further assistance.;

		%Let RaceSupress_Foot=RACE Suppressed: (Error);
		%If &IMP_RACES.=Y %Then %Let RaceImpute_Foot=RACE Imputed: (Error) of race values were imputed. Please be advised, prevalence estimates may incur additional bias with imputed race values. Extreme caution is recommended when the proportion of imputed race values exceeds 40%.;
			%Else %Let RaceImpute_Foot=Imputed race: People with unknown race were excluded.;
		%Let Collapse_Foot=Weighting cells were collapsed for: (Error);
 
		Proc Sql;
			Create table Prevalence_Report as
				Select 1 as Order, "(1) Underweight (<5th percentile)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F1. From Null_Prev_Report Union
				Select 1 as Order, "(2) Healthy Weight (5th to <85th percentile)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 1 as Order, "(3) Overweight (85th to <95th percentile)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 1 as Order, "(4) Obesity (>95th percentile)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 1 as Order, "(4b) Severe Obesity (>120% of the 95th percentile)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 2 as Order, "Totals:" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 3 as Order, "Dataset: IQVIA, 2016-2018" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 4 as Order, "&Query_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_F2. From Null_Prev_Report Union
				Select 5 as Order, "&Age_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 6 as Order, "&Sex_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 7 as Order, "&Race_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 8 as Order, "&RaceSupress_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 9 as Order, "&RaceImpute_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 10 as Order, "&Geography_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 11 as Order, "&Year_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 12 as Order, "&Collapse_Foot." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 13 as Order, "&Age_Adj_Footnote." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 14 as Order, "Error Codes: (&Fail_Desc.)" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 15 as Order, "Technical Documentation: See https://github.com/NORC-UChicago/CODI-PQ for more information and full details on data sources and methodologies." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 16 as Order, "Query Date: &DateTime2." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 17 as Order, "Suggested Citation: AEMR-US version 5 OMOP 5 [Aug 2019 Release] accessed through the E360TM Software-as-a-Service (SaaS) Platform. Accessed through prevalence query on &DateTime2." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 18 as Order, "Caveats" as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 19 as Order, "Children with either missing or invalid age, sex, height, weight, or geography are not included in counts and prevalence estimates." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 20 as Order, "The method used to calculate the standard errors are documented in the technical documentation." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report Union
				Select 21 as Order, "The population estimates are based on age-race-sex-location specific counts from the 2014-2018 American Community Survey Five-year Estimates released by the Census Bureau on December 19, 2019." as WtCat, Samp, Pop, Crde_Prev, Crde_StdErr, Wgt_Prev, Wgt_StdErr &Incld_Age_Adj_P2. From Null_Prev_Report
				&Age_Adj_Caveat.;
		Quit;
	%End;

	/*@Action: Create CSV output file for prevalence results ***/
	Proc Export Data=Prevalence_report Outfile="&Root_PQ.\1 Output\&FileOUT_Name._&DateTime..csv" label DBMS=CSV Replace;
		Run;
%Mend;

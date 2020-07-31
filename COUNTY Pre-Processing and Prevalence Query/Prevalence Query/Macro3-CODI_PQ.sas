/*******************************************************************************************/
/***PROGRAM: Macro3-CODI_PQ.SAS											 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: DEVI CHELLURI (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
%macro Suppress(fileinest= /*output file with prevelance estimates*/, fileinwgt= /*final weighted file*/, fileout= /*suppression algorithm output*/);

	data est;
		set &fileinest.;
	run;

	data raw;
		set &fileinwgt.;

		array wgt_flg 5 UndrWgt_Flg HlthyWgt_Flg OvrWgt_Flg Obsty_Flg SvrObsty_Flg;
			do i=1 to 5;
				if wgt_flg[i]=0 then wgt_flg[i]=2;
			end;
	run;

	proc freq data=raw;
		table UndrWgt_Flg HlthyWgt_Flg OvrWgt_Flg Obsty_Flg SvrObsty_Flg;
	run;

	%macro asecalc(var=);
		proc freq data=raw;
			table &var./list missing binomial;
				exact binomial;
				output out=&var. Binomial;
		run;
	%mend;

	%asecalc(var=UndrWgt_Flg);
	%asecalc(var=HlthyWgt_Flg);
	%asecalc(var=OvrWgt_Flg);
	%asecalc(var=Obsty_Flg);
	%asecalc(var=SvrObsty_Flg);

	data ASE_file (rename=(e_bin=ASE));
		length wtcat $50.;
		set UndrWgt_Flg (in=a) HlthyWgt_Flg (in=b) OvrWgt_Flg (in=c) Obsty_Flg (in=d) SvrObsty_Flg (in=e);

		if a then
			WtCat="(1) Underweight (<5th percentile)";

		else if b then
			WtCat="(2) Healthy Weight (5th to <85th percentile)";

		else if c then
			WtCat="(3) Overweight (85th to <95th percentile)";

		else if d then
			WtCat="(4) Obesity (>95th percentile)";

		else if e then
			WtCat="(4b) Severe Obesity (>120% of the 95th percentile)";
		keep e_bin wtcat;
	run;

	proc sort data=est;
		by wtcat;
	run;

	proc sort data=ASE_file;
		by wtcat;
	run;

	data est_ase;
		merge est ASE_file;
		by wtcat;
	run;

	data  f1;
		set est_ase;

		/*p and its standard error should be decimal numbers between 0 and 1 ***/
		p=Crude_Prev/100;
		sep=ase;
		q=1-p;
		nsum=sample_pt;

		/* set df to sample(nsum) - 1 ***/
		df_flag=0;
		df=nsum-1;
		/*df=&dfin.;*/

		if df<8 then
			df_flag=1;

		/*Effective sample size: compute n effective ***/
		/*@note: for proportions from vital data files where SE=(p*q)/N, n_eff will equal to N ***/
		if (0<p<1) then n_eff=(p*(1-p))/(sep**2);
			else n_eff=nsum;

		if (n_eff=. or n_eff>nsum) then n_eff=nsum;

		/*Ratio of ts: adjustment to sample size suggested by Korn and Graubard for complex survey data ***/
		/*A two-sided alpha (0.05/2 or 0.025) is used in the equation below: 1-0.025 = 0.975 ***/
		if df > 0 then rat_squ=(tinv(0.975,nsum-1)/tinv(0.975,df))**2;
			else rat_squ=0;

		/*limit case: set to zero, df-adjusted effective sample size (can be no greater than the sample size) ***/
		if p > 0 then n_eff_df=min(nsum,rat_squ*n_eff);
			else n_eff_df=nsum;

		/*limit case: set to sample size, Parameters for beta confidence limits ***/
		x=n_eff_df*p;
		v1=x;
		if (n_eff_df-x+1)<0 then v2=0;
			else v2=n_eff_df-x;
		v3=x+1;
		if (n_eff_df-x)<0 then v4=0;
			else v4=n_eff_df-x;

		/*lower and upper confidence limits for Korn and Graubard interval ***/
		/*Note: Using inverse beta instead of ratio of Fs for numerical efficiency ***/
		/*if (0<p<1), otherwise set lower limit to 0 when p=0 and upper limit to 1 when p=1 ***/
		/*A two-sided alpha (0.05/2 or 0.025) is used in the equations below: 0.025 and 0.975 ***/
		if (v1=0) then kg_l=0;
			else kg_l=betainv(.025,v1,v2);

		if (v4=0) then kg_u=1;
			else kg_u=betainv(.975,v3,v4);

		/*Korn and Graubard CI absolute width ***/
		kg_wdth=kg_u - kg_l;

		/*Korn and Graubard CI relative width for p ***/
		if (p>0) then kg_relw_p=100*(kg_wdth/p);
			else kg_relw_p=.;

		/*Korn and Graubard CI relative width for q ***/
		if (q>0) then kg_relw_q=100*(kg_wdth/q);
			else kg_relw_q=.;

		/*Proportions with CI width <= 0.05 are reliable, unless ***/
		p_reliable=1;

		/*Update P Reliable: Effective sample size is less than 30 ***/
		if n_eff < 30 or nsum < 30 then p_reliable=0;

			/*Absolute CI width is greater than or equal 0.30 ***/
			else if kg_wdth ge 0.30 then p_reliable=0;

			/*Relative CI width is greater than 130% ***/
			else if (kg_relw_p > 130 and kg_wdth > 0.05) then p_reliable=0;

		/*Determine if estimate should be flagged as having an unreliable complement ***/
		if (p_reliable=1) then do;
			/*Complementary proportions are reliable, unless ***/
			q_reliable=1;

			/*Relative CI width is greater than 130% ***/
			if (kg_relw_q > 130 and kg_wdth > 0.05) then q_reliable=0;
		end;

		p_statistical=0;

		if p_reliable=1 then do;
			/*Estimates with df < 8 or percents = 0 or 100 or unreliable complement are flagged for clerical or ADS review ***/
			if df_flag=1 or p=0 or p=1 or q_reliable=0 then p_statistical =1;
		end;

	run;

	proc freq data=f1;
		table p_reliable*q_reliable*p_statistical/list missing;
			run;

	%Global Suppress_Error;
	%Let Suppress_Error=None;
	data &fileout.(keep=wtcat sample_pt pop_n crude_prev crude_stderr pop_perc std_err pop_perc_age_adj std_err_age_adj);
		set f1;

		if p_reliable=0 or q_reliable in (.,0) or p_statistical=1 then do;
			sample_pt=.;
			pop_n=.;
			crude_prev=.;
			crude_stderr=.;
			pop_perc=.;
			std_err=.;
			pop_perc_age_adj=.;
			std_err_age_adj=.;
			call symput("Suppress_Error","One or more rows has suppressed results. Percentages are not available for all results due to suppression constraints.");
		end;
	run;

%mend;


/*******************************************************************************************/
/***PROGRAM: Module3-Pre-Processing_CODI_PQ.SAS							 				 ***/
/***VERSION: 1.0																		 ***/
/***AUTHOR: SCOTT CAMPBELL (NORC at the University of Chicago)							 ***/
/*******************************************************************************************/
/*@Action: Set-up Formats for reference categories used in multinomial logistic model output ***/
Data REF_CATEGORIES;
	Length Start $6. Label $1. FMTNAME $15.;
	INFILE DATALINES DSD;
	INPUT Start $ Label $ FMTNAME $;
	Datalines;
"WY829","0","$STATEZIP_BLACK"
"WY829","0","$STATEZIP_ASIAN"
"WY829","0","$STATEZIP_OTHER"
"Other","-","$STATEZIP_BLACK"
"Other","-","$STATEZIP_ASIAN"
"Other","-","$STATEZIP_OTHER"
"Female","0","$SEX_BLACK"
"Female","0","$SEX_ASIAN"
"Female","0","$SEX_OTHER"
"Other","0","$SEX_BLACK"
"Other","0","$SEX_ASIAN"
"Other","0","$SEX_OTHER"
;
	Run;

Data Model_Output_Format(Keep=Start Label FMTNAME);
	Set REGEST.&Reg_Est_Name.;
		Length Start $6.;
		If Effect="State_ZIP_Model" Then do;
			Start=Strip(State_ZIP_Model);
			Label=Strip(Put(Estimate, 12.8));
			If Race_Resp=2 Then FMTNAME="$STATEZIP_BLACK";
				Else If Race_Resp=3 Then FMTNAME="$STATEZIP_ASIAN";
				Else If Race_Resp=4 Then FMTNAME="$STATEZIP_OTHER";
			Output;
		End;
		Else If Effect="Sex_Model" Then do;
			Start=Strip(Sex_Model);
			Label=Strip(Put(Estimate, 12.8));
			If Race_Resp=2 Then FMTNAME="$SEX_BLACK";
				Else If Race_Resp=3 Then FMTNAME="$SEX_ASIAN";
				Else If Race_Resp=4 Then FMTNAME="$SEX_OTHER";
			Output;
		End;
		Else If Effect="Intercept" Then do;
			If Race_Resp=2 Then Call Symput("Intercept_2", Put(Estimate, 12.8));
				Else if Race_Resp=3 Then Call Symput("Intercept_3", Put(Estimate, 12.8));
				Else if Race_Resp=4 Then Call Symput("Intercept_4", Put(Estimate, 12.8));
		End;
		Else If Effect="Age_Model" Then do;
			If Race_Resp=2 Then Call Symput("Age_2", Put(Estimate, 12.8));
				Else if Race_Resp=3 Then Call Symput("Age_3", Put(Estimate, 12.8));
				Else if Race_Resp=4 Then Call Symput("Age_4", Put(Estimate, 12.8));
		End;
		Else If Effect="Height_Model" Then do;
			If Race_Resp=2 Then Call Symput("Height_2", Put(Estimate, 12.8));
				Else if Race_Resp=3 Then Call Symput("Height_3", Put(Estimate, 12.8));
				Else if Race_Resp=4 Then Call Symput("Height_4", Put(Estimate, 12.8));
		End;
		Else If Effect="Age_Model*Height_Mod" Then do;
			If Race_Resp=2 Then Call Symput("Age_Height_2", Put(Estimate, 12.8));
				Else if Race_Resp=3 Then Call Symput("Age_Height_3", Put(Estimate, 12.8));
				Else if Race_Resp=4 Then Call Symput("Age_Height_4", Put(Estimate, 12.8));
		End;
Data Format_Final;
	Set Model_Output_Format REF_CATEGORIES;
Proc Sort Data=Format_Final(Where=(FMTNAME^=""));
	By FMTNAME START;
Proc Format CNTLIN=Format_Final;
Run;

Data Imputed_Race_by_Model;
	Set People_Impute_By_Model;
		/*@Action: If geography not found in Reg Est file, do not impute ***/
		Where Put(State_ZIP_Model, $STATEZIP_BLACK.)^="-" and Put(State_ZIP_Model, $STATEZIP_ASIAN.)^="-" and Put(State_ZIP_Model, $STATEZIP_OTHER.)^="-";

		/*@Action: Assign random number from uniform distribution ***/
		Randuni = Ranuni(28873);

		/*@Action: Compute XBETA for each race value (excludes reference race, white) ***/
		XBETA_Black=&Intercept_2.+Put(State_ZIP_Model, $STATEZIP_BLACK.)+Put(Sex_Model, $SEX_BLACK.)+(Age_Model*&Age_2.)+(Height_Model*&Height_2.)+(Age_Model*Height_Model*&Age_Height_2.);
		XBETA_Asian=&Intercept_3.+Put(State_ZIP_Model, $STATEZIP_ASIAN.)+Put(Sex_Model, $SEX_ASIAN.)+(Age_Model*&Age_3.)+(Height_Model*&Height_3.)+(Age_Model*Height_Model*&Age_Height_3.);
		XBETA_Other=&Intercept_4.+Put(State_ZIP_Model, $STATEZIP_OTHER.)+Put(Sex_Model, $SEX_OTHER.)+(Age_Model*&Age_4.)+(Height_Model*&Height_4.)+(Age_Model*Height_Model*&Age_Height_4.);
			
		/*@Action: Compute model estimated probabilities for each race (cumulative) ***/
		P_White_Model = 1/(1+Exp(XBETA_Black)+Exp(XBETA_Asian)+Exp(XBETA_Other));
		P_Black_Model = P_White_Model+(Exp(XBETA_Black)/(1+Exp(XBETA_Black)+Exp(XBETA_Asian)+Exp(XBETA_Other)));
		P_Asian_Model = P_Black_Model+(Exp(XBETA_Asian)/(1+Exp(XBETA_Black)+Exp(XBETA_Asian)+Exp(XBETA_Other)));
		P_Other_Model = P_Asian_Model+(Exp(XBETA_Other)/(1+Exp(XBETA_Black)+Exp(XBETA_Asian)+Exp(XBETA_Other)));

		/*@Action: Actual race impuation ***/
		If 		 	  0<=Randuni<=P_White_Model Then Impute_Race = "White"; Else
		If P_White_Model<Randuni<=P_Black_Model Then Impute_Race = "Black"; Else
		If P_Black_Model<Randuni<=P_Asian_Model Then Impute_Race = "Asian"; Else
											 		 Impute_Race = "Other";

		Output;
Run;
/*@Program End***/

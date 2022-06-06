libname yc "C:\Users\yche465\Desktop\AIM 1\Codes\Synthetic Data";

proc import datafile="C:\Users\yche465\Desktop\AIM 1\Codes\Synthetic Data\sample_data.xlsx" 
out=sampledata
replace;
run;

data sampledata2;
set sampledata;
array c{52} T1-T52;
do i=1 to 52;
	c{i}=i;
	end;
run;

*test run GBTM on the original sample testing dataset;
PROC TRAJ DATA=sampledata2 OUTPLOT=OP OUTSTAT=OS OUT=OF OUTEST=OE ITDETAIL;
ID ID; VAR PMC1-PMC52; INDEP T1-T52;
MODEL CNORM; MIN 0;MAX 1; NGROUPS 3; ORDER 3 3 3;
RUN;

%include "C:\Users\yche465\Desktop\AIM 1\Codes\PrEP-Traj-Clustering\Programs\trajplotnew.sas";
%trajplotnew(OP,OS,"PMC vs. Time","CNORM Model","PMC","Time")

******************************************************************************
* Iteratively run GBTM on k=2~5 to assess whether GBTM could identify the correct number of groups
*******************************************************************************;


*Create a macro function for implementing the GBTM procedures (under censored normal distribution) at a pre-specified k value;
%macro Traj(dataset,k);
	*create macro variable for the order parameter;
	data seq;
	do i=1 to &k;
	order=3;
	output;
	end;
	run;

	proc sql noprint;
	select order
	into :orderlist separated by ' '
	from seq; 
	quit;
	
	*Run the finite mixture trajectory model under censored normal distribution;
	PROC TRAJ DATA=&dataset OUTPLOT=OP OUTSTAT=OS OUT=OF OUTEST=OE ITDETAIL;
	    ID ID; VAR PMC1-PMC52; INDEP T1-T52;
	    MODEL CNORM; MIN 0;MAX 1; NGROUPS &k; ORDER &orderlist;
	RUN;
	*output model fitness metrics;
	data modelfit&k;
	retain K _LOGLIK_ _BIC1_ _AIC_;
	set oe;
	K=&k;
	where _TYPE_="PARMS";
	rename _LOGLIK_=LN_LIK _BIC1_=BIC _AIC_=AIC;  
	keep K _LOGLIK_ _BIC1_ _AIC_; 
	run;
%mend;

*Create a macro function to iteratively implement GBTM fitting across various k values and output fit statistics;
%macro rep_traj(data,maxk);
%DO I = 2 %TO &maxk;
 %Traj(&data,&I);
%END;

data modfit;
do i=2 to &maxk;
datname=cat("modelfit",i);
output;
end;
run;

proc sql noprint;
select datname
into :datname separated by ' '
from modfit; 
quit;

data fit;
set &datname;
run;
%mend rep_traj;


*Conduct GBTM fitting for k=2~5; 
%rep_traj(sampledata2,5)

proc print data=fit;
run;

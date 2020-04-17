%macro gettimings (logpath,outpath);
options nodate nonumber;

** Delete the previous version **; 
** Output the list of files to a temporary location **; 
data _null_;
  x "mkdir &logpath";
  x "dir \b &logpath/*_sasgsub.log > &logpath/00_files.txt";
run;
** Initialize the macro variables **;
%let totfile=;
%let totobs=;

** Get the total number of files and file names **; 
data _null_;
	infile "&logpath/00_files.txt" dsd dlm='09'x truncover; 
	input name $200.;
	call symput('totfile',trim(left(put(_n_,8.))));
	call symput('file'||trim(left(put(_n_,8.))),trim(left(name))); 
run;

%macro all_files;
proc sql;
	drop table files;
quit;
%do i=1 %to &totfile; 

	data files_&i.;
		infile "&&file&i" dsd dlm='09'x truncover; 
		input line $200.;
		length filenm $200.; 
		filenm=scan("&&file&i",-1,"/");
		if index(line, 'Job Status:') then time = scan(line,1,"-");
		if index(line, 'Job Status:') then datetime = input(catx(":", catx('',substr(time,9,2),substr(time,5,3),substr(time,length(time)-1)),substr(time,12,8)),datetime.) ;
		if datetime = . then delete;
	run;

	proc append base=files data=files_&i. force;run;
%end;
%mend;
%all_files;

** Final output **; 
ods listing close; 
ods html file="&outpath..html";
title "Summary of Batch Log Durations";
proc sql;
	select filenm, max(datetime) as max format=datetime., min(datetime) as min format=datetime.,
		 max(datetime)-min(datetime) format=time. as duration
	from files
	group by filenm;
quit;
ods listing close; 
%mend gettimings;


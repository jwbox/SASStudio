
PROC FORMAT ;
  VALUE $MISSC
      " " = "Missing"
    other = "Not Missing";
  VALUE MISSN
       .  = "Missing"
    other = "Not Missing";
  VALUE $VTF
    "C" = "Character"
    "N" = "Numeric  " ;
RUN;;


/* Some internal Macros */

%MACRO FREEK;
%DO I = 1 %TO &NCOLS;

PROC SQL;
Create table DT&I as
select "&&V&I" as VARNAME, nmiss(&&V&I) as Missing, n(&&V&I) as Not_Missing,
       "&&L&I" as COLUMN, "&&VT&I" as VTYPE, Calculated Missing + Calculated Not_missing as TOTAL, "&&FM&I" as FORMAT,
       count(distinct(&&V&I)) as Levels
FROM &lib_name..&dataset_name;
QUIT;

%END;
%MEND;

%MACRO LST;
%DO J = 1 %TO &NCOLS;
  DT&J
%END;
%MEND;

%macro missrow;
%do K = 1 %to &ncols;
%if &K = 1 %THEN &&V&K ;
%ELSE , &&V&K;
%END;
%mend;

%macro distinct;
  %do D = 1 %to &NCOLS;
  %IF &D = 1 %THEN %DO ;
   count(distinct(&&v&D)) as &&v&D
  %end;
  %ELSE %DO;
   , count(distinct(&&v&D)) as &&v&D
  %END;
  %END;
  %MEND;

%MACRO FREQOUT;
%DO I = 1 %TO &NCOLS;
%IF &&LV&i > 0 AND &&LV&I< 51 %THEN %DO ;
  TABLE &&V&I;
%END ;
%END ;
%MEND ;

%macro FREQOUT2;
%DO I = 1 %TO &NCOLS;
%IF &&LV&i > 0 AND &&LV&I< 51 %THEN %DO ;
TITLE "Variable: &&V&I" ;

proc sql;
  select &&V&I
        ,count(&&V&I) as Number
        ,(calculated Number)/Total  as percent format = percent7.1
  from
    (Select &&V&I, N(&&V&I) as total from &lib_name..&dataset_name(where = (&&V&I is not missing)) )
    group by &&V&I;
quit;
%END ;
%END ;
TITLE;
%MEND;


/* MAIN MACRO */

%MACRO EDA(lib_name, dataset_name, showfreq=1);

data columns;
set sashelp.vcolumn (where =( libname =upcase( "&lib_name" ) and memname = upcase("&dataset_name" ) ));
  varname = name;
  IF type ^= 'num' then DO ;
    fmt = "$MISSC."; VTYPE = "C" ;format = "Char " ||put(length, 4.);
  END;
  ELSE DO;
     fmt = "MISSN." ; VTYPE= "N" ; if format = '' then format = "Numeric" ;
  END;
  IF LABEL = '' THEN LABEL = NAME;
keep varname fmt LABEL VTYPE varnum format;
run;

PROC SQL NOPRINT ;
SELECT COUNT(*) INTO :NCOLS FROM COLUMNS;
%LET NCOLS = &NCOLS;
SELECT VARNAME INTO :V1 - :V&NCOLS FROM COLUMNS;
SELECT FMT INTO :F1 - :F&NCOLS FROM COLUMNS;
SELECT LABEL INTO :L1 - :L&NCOLS FROM COLUMNS;
SELECT VTYPE INTO :VT1 - :VT&NCOLS FROM COLUMNS;
SELECT FORMAT INTO :FM1 - :FM&NCOLS FROM COLUMNS;
SELECT COUNT(*) INTO :NUMRECS  SEPARATED BY ' ' FROM &LIB_NAME..&DATASET_NAME  ;
QUIT ;


OPTIONS NOCENTER ;

%FREEK ;

DATA MREPORT;
LENGTH  varname $35. format $25. column $80. missing not_missing total 8.;
SET %LST ;
  pct_miss = missing / total;
  pct_not = not_missing / total;
  rename missing = num_missing;
  format pct_miss pct_not percent8.1 vtype $VTF. ;
RUN;

PROC SQL NOPRINT ;
SELECT levels into :LV1 - :LV&NCOLS FROM MREPORT;
QUIT;

ods select none ;
proc means  data=&lib_name..&dataset_name StackODSOutput min median max mean std maxdec = 2 ;
var _NUMERIC_ ;
  ods output summary=tmeans ;
run ;
ods select all ;


PROC SQL ;
CREATE TABLE MREPORT2 AS
SELECT C.varnum,  M. *, T.min,T.median, T.max, T.mean, T.stdDev
FROM MREPORT AS M LEFT JOIN TMEANS AS T ON M.VARNAME = T.Variable
left join columns as C on m.varname = c.varname
order by varnum;
QUIT ;
 

title "Analysis of Values in the &dataset_name Dataset" ;
title2 "Dataset has &NUMRECS records" ;
proc report data = mreport2 spacing = 2 split = '|'  nowindows;
  columns  varnum varname format column levels not_missing num_missing pct_miss min median max mean stdDev ;
  define varnum / order noprint;
  define varname / order order=internal "Variable" left width = 25 ;
  define column / display "Label" left width = 60 flow;
  define levels/ display "Distinct|Values" right width = 9 format =comma9. ;
  define Format / display "Variable|Format" left width = 15;
  define not_missing / display "Number|Present" right format =comma9. ;
  define num_missing / display "Number|Missing" right format =comma9. ;
  define pct_miss / display "Percent|Missing" right ;
  define min / display "Minimum" right ;
  define median / display "Median" right ;
  define max / display "Maximum" right ;
  define mean / display "Mean" right ;
  define stdDev / display "Std" right ;
run;
title;title2 ;


/* Run freqs for any variable with 50 or fewer levels */

%IF &SHOWFREQ = 1 %THEN %DO;

%freqout2;

%END;


/* Cleanup */
proc datasets noprint;
delete %LST  MEAN MEANS MEDIAN tmeans columns MREPORT  mreport2;
run; quit ;

%MEND EDA;


%EDA (JJ,OUTPUT_surveydata);



/* Internal Macro*/


%MACRO DATASETS;

TITLE "Datasets in the &LIBNAME Library";
proc report data = members spacing = 2 split = '|' nowindows;
  columns  memname memtype index;
  DEFINE MEMNAME / DISPLAY "Member Name" width = 32 left;
  DEFINE MEMTYPE / DISPLAY "Member Type" width = 11 left;
  DEFINE INdex / DISPLAY "Index" center width = 5;

  RUN;
TITLE;

%DO I = 1 %TO &NMEM;
title "Columns in &&M&I Dataset";
proc report data = COLUMNS spacing = 2 split = '|' nowindows ;
  columns  VARNUM NAME FORMAT LABEL memname ;
  DEFINE MEMNAME / NOPRINT;
  DEFINE VARNUM / ORDER NOPRINT;
  DEFINE NAME / DISPLAY "Variable" left width = 32;
  DEFINE Format / DISPLAY "Format" left width = 20;
  DEFINE label / DISPLAY "Label" left width = 80 flow;
  where memname = "&&M&I";
  RUN;
%END;
title;
%MEND;

/* Main Macro */

%MACRO LIBEDA(libname);

Data members;
set sashelp.vmember(WHERE=( LIBNAME = UPCASE( "&LIBNAME")));
run;


PROC SQL NOPRINT;
SELECT COUNT(*) INTO :NMEM FROM MEMBERS;
%LET NMEM = &NMEM;
SELECT MEMNAME INTO :M1 - :M&NMEM FROM MEMBERS;
QUIT;

DATA COLUMNS;
SET SASHELP.VCOLUMN (WHERE = (LIBNAME =  UPCASE( "&LIBNAME")));
  IF UPCASE(TYPE) = "NUM" THEN DO;
     if format = '' then format = "Numeric" ;
  END;
  ELSE DO;
     format = "Char " ||put(length, 4.);
  END;

RUN;

%DATASETS ;

%MEND;
%LIBEDA(JJ)

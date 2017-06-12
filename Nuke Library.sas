%MACRO nuke(dir);
  proc datasets lib = &dir kill nolist memtype=data;  quit;
%MEND nuke;

%nuke(work);


%macro nukeds(dsn,lib=work);
  proc datasets lib = &lib;
    delete &dsn;
  quit;
%MEND;

%nukeds(all_claims);

/******************************************************************************\
* $Id:$
*
* Copyright(c) 2014 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
*
* Name: NameAddress.sas
*
* Purpose: Functions that create random names and addresses.  First names depend on gender and decade of birth.
*          Last names depend on ethnicity breakdown.  Can generate residential or commercial address
*
* Authors: Jim Box & Elena Snavely
*
* Support: SAS(r) Solutions OnDemand
*
* Input: See section below for specific inputs for each function
*
* Output: See section below for specific outputs for each function
*
* Parameters: (if applicable)
*
* Dependencies/Assumptions: Uses formats created from name_address_format.sas7bdat
*
* Usage: %logtime(logfile,text=yes,graph=yes)
*
* History:
* 21AUG2014 jimbox Started commenting.

\******************************************************************************/

/*
   Function Name: First_Name  
   Purpose:	Generates a random first name based on the date of birth and gender of the subject
   Inputs:  gender = {gender var} - character field with either an M or F 
            dob = {dob var} - SAS date for the date of birth
   Outputs: Text string of a first name
   Call:     First_name = First_Name(gender,dob);   


   Function Name: Last_Name 
   Purpose:	Generates a random last name, using racial proportions, from the 2010 US Census
   Inputs:  prop_white - proportion of primarily white names (0 - 1)
            prop_black - proportion of primarily black/african american names (0 - 1)
			prop_api - proportion of primarily asian/pacific islander names (0 - 1)
			prop_hispanic - proportion of primarily hispanic names (0 - 1)
   Outputs: Text string of a last name
   Call:     last_name = Last_Name(.5,.2,.1,.2);   


   Function Name: Street_Address 
   Purpose:	Generate a street address.  Uses most common US street addresses.  
   Inputs:  prob_pobox - Probability of returning a PO box instead of a street address
   Outputs: Text string address
   Call:    Address_1 = Street_Address();   
   

   Function Name: Commercial_A2 
   Purpose:	Generates a second address line for a commercial address (e.g. Suite #200)  May also return a floor number format (e.g. "2nd Floor")
            Will not return a value if the first address line is a PO Box.  
   Inputs:  prob_suite - user-provided probability of having any value returned (0-1)
            A1 = {Address One Variable} - pointer to the Add1 line, to determine if it is a PO Box
   Outputs: Text Address line of one of the following formats
            Suite {#}
			{First} Floor
			Floor {#}
   Call:    Address_2 =  Commercial_A2( .5,Address_1) 
   

   
   Function Name: Residential_A2
   Purpose:	Generates a second address line for a personal address (e.g. Apt #200)  Also returns Unit # and uses letters
            Will not return a value if the first address line is a PO Box.  
   Inputs:  prob_apt - user-provided probability of having any value returned (0-1)
            A1 = {Address One Variable} - pointer to the Add1 line, to determine if it is a PO Box
   Outputs: Text Address line of one of the following formats
            Apt or Apt # {#}
			Unit or Unit # {#}
			# {#}
			Some numbers will have a letter appended (e.g. Apt 5A)
			Some values will just be letters (e.g. Unit D)

   Call:    Address_2 =  Residential_A2( .5,Address_1) 
   
*/


/* Read in formats */

%let path = C:\Users\jimbox\Documents\My SAS Files\Names;
libname names "&path";
proc format cntlin = names.name_address_format; run;


/* Compile Functions */

proc fcmp outlib = work.functions.name ;


	function First_Name( gender $, dob) $ ;
	    length first_name $20;
		r = Rand("UNIFORM") ;
        fmt = cats(gender,min(floor(year(dob)/10)*10,2000),"F.");
		first_name = putn(r,fmt);
		return( first_name ) ;
	endsub;


	function Last_Name( prop_white, prop_black, prop_api, prop_hispanic) $ ;
		r = Rand("UNIFORM") ;
		if r < prop_white then lastname = put( ranuni( r ) , WHITEF. ) ;
		else if r < prop_white + prop_black then lastname = put ( ranuni( r ) , BLACKF. ) ;
		else if r < prop_white + prop_black + prop_api then lastname = put ( ranuni( r ) , APIF. ) ;
		else lastname = put ( ranuni( r ) , HISPANICF. ) ;
		return( lastname ) ;
	endsub;


    function Street_Address(prob_pobox) $;
        p_pobox = rand("Uniform") ;
	    length Add1 $30;
	    if p_pobox < (1 - prob_pobox) then 
	    		Add1 = catx(" ",floor(Rand('Beta',1,10)*10000 + 1),put(rand("Uniform"),streetf.));
	     else if p_pobox < (1 - (prob_pobox/2)) then Add1 = catx(" ","P.O. Box",floor(rand("Uniform")*10000 + 1));
	      else Add1 = catx(" ","PO Box",floor(rand("Uniform")*10000 + 1));
	    	
	    return (Add1);
	endsub;


	
	function Commercial_A2( prob_suite,A1 $) $ ;

        IF (RAND("Uniform") < prob_suite)  
            AND (index(UPCASE(A1),"PO BOX") = 0) 
            AND (index(UPCASE(A1),"P.O. BOX") = 0) THEN DO;
           
            length num_c $4  suite $20;
            %* GET THE NUMBER TO USE FOR THE SUITE;
            num = floor(RAND("POISSON",3)*100) + floor(RAND("UNIFORM")*50);
        
            %* CONVERT TO A CHARACTER VALUE WITH THE APPROPRIATE LENGTH;
          if num < 10 then num_c = put(num,1.);
             else if num < 100 then num_c = put(num,2.);
              else if num < 1000 then num_c = put(num,3.);
               else num_c = put(num,4.);
        
             %* APPEND A ROOM TYPE OR ASSIGN A FLOOR VALUE;
            S_type = RAND("UNIFORM");
        
            IF S_type < .35 then SUITE = catx(" ","Suite #", num_c);
        	 else if S_type < .70 then SUITE = catx(" ","Suite", num_c);
        	 else if S_type < .75 then SUITE = catx(" ","Ste. ", num_c);
        	 else if S_type < .77 then SUITE = "First Floor";
        	 else if S_type < .79 then SUITE = "1st Floor";
        	 else if S_type < .81 then SUITE = "Second Floor";
        	 else if S_type < .83 then SUITE = "2nd Floor";
        	 else if S_type < .85 then SUITE = "Third Floor";
        	 else if S_type < .87 then SUITE = "3rd Floor";
        	 else if S_type < .89 then SUITE = "Fourth Floor";
        	 else if S_type < .91 then SUITE = "4th Floor";
        	 else if S_type < .93 then SUITE = "Fifth Floor";
        	 else if S_type < .95 then SUITE = "5th Floor";
        	 else if S_type < .96 then SUITE = "Floor 1";
        	 else if S_type < .97 then SUITE = "Floor 2";
        	 else if S_type < .98 then SUITE = "Floor 3";
        	 else if S_type < .99 then SUITE = "Floor 4";
        	 else SUITE = "Floor 5";
        
            return (suite);
            END;
            
            ELSE return("");
  endsub;	

	function Residential_A2( prob_apt,A1 $) $ ;
	    IF (RAND("Uniform") < prob_apt)  AND (index(upcase(A1),"PO BOX") = 0) AND (index(UPCASE(A1),"P.O. BOX") = 0) THEN DO;
        
        length num_c $4 numb $8 apt $20;
        num = floor(Rand('Beta',1,25)*10000 + 1); 
        if num < 10 then num_c = put(num,1.);
         else if num < 100 then num_c = put(num,2.);
          else if num < 1000 then num_c = put(num,3.);
           else num_c = put(num,4.);
        n_type = RAND("UNIFORM");
        IF n_type < .80 then numB = num_c;
	     else if n_type < .83 AND num < 40 then numb = cats(num_c,"A");
	      else if n_type < .86 AND num < 40 then numb = cats(num_c,"B");
  	      else if n_type < .89 AND num < 40 then numb = cats(num_c,"C");
  	      else if n_type < .92 AND num < 40 then numb = cats(num_c,"D");
          else if n_type < .95 AND num < 40 then numb = cats(num_c,"E");
  	      else if n_type < .98 AND num < 40 then numb = cats(num_c,"F");
	      else if  n_type < .98 then numB = num_c;
	       else if n_type < .985 then numb = "A";
	       else if n_type < .990 then numb = "B";
	       else if n_type < .995 then numb = "C";
	       else  numb = "D";
        
         a_type = RAND("UNIFORM");
        IF a_type < .40 then apt = catx(" ","Apt", numb);
	     else if a_type < .80 then apt = cats("Apt #", numb);
	     else if a_type < .92 then apt = catx(" ","Unit ", numb);
	     else if a_type < .95 then apt = cats("Unit #", numb);
	     else if a_type < .975 then apt = cats("#", numb);
	     else apt = catx(" ","No. ", numb);
        
        return (apt);
        END;
        
        ELSE return("");
  endsub;
  
	
run;

options cmplib=work.functions ;



/*   Example Test Code:  */
   

Data Person_Test;
	do i = 1 to 1000;
		date_of_birth = floor(date()-(Rand('Uniform')*30660));
		if Rand('Uniform') < .5 then Gender = "M";
		else Gender = "F";
		output;
	end;
	format date_of_birth date9.;
	drop i;
run;

  
data person;
length date_of_birth 8. gender $1. first_name $20. middle_initial $1.;
SET PERSON_TEST;
  first_name = strip(first_name(gender,date_of_birth));
  middle_initial = substr(first_name(gender,date_of_birth),1,1);
  last_name = last_name(.5,.2,.1,.2);
  ADDRESS_1 = street_address(.05);
  address_2 = ResIdential_A2(.25,ADDRESS_1);
  Address_3 = Commercial_A2( .5,Address_1) ;
  full_name = catx(" ",first_name,middle_initial||'.',last_name);
  label 
    first_name = "First Name"
	middle_initial = "M.I."
	last_name ="Last Name"
	full_name = "Full Name"
	ADDRESS_1 = "Street Address"
	Address_2 = "Apartment"
	Address_2 = "Suite";
	
run;   






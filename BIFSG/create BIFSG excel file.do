
/*=====================================================================================
Program Author: Shradha Sahani
Start Date: May 6, 2024
Last Updated: June 3, 2024
Program Description: Creating BIFSG excel file for each sheet individually with excel
functions. An Excel file with comments is available to see the explanation of what
each formula is doing and interpret it there, which is easier to undersand than 
via comments in the Stata code.

Note that the code would need adjustments for very large states where the number 
of cleaned street segments is more than what can fit in an Excel sheet.

Input:
	- User choises of $state_abbrev_lower, $state_abbrev_upper, $year, and $demographic_dataset
	- $state_abbrev_upper $demographic_dataset $year Data.xlsx 
	- $state_abbrev_lower street segments clean.dta
	- first name and last name adjusted probabilities, adjusted.

Output:
	- BIFSG_$demographic_dataset_$year_$state.xlsx
=====================================================================================*/
clear 
set more off 

/*=====================================================================================
0: Set the choices and initiate a log
--------------------------------------------------------------------------------------
=======================================================================================*/

//set the choices
global state_abbrev_lower "nc" //change this for the state you are using 
global state_abbrev_upper "NC"
global state_name_upper "NORTH CAROLINA" 
global demographic_dataset "ACS 5Y" // change this depending on whether Census or ACS data is used
global year "2019" //change this depending on the year of Census or ACS data used
global total_rows 10000 // number of cases to input, plus one (NM--16491 PA--62103)
global state_w_agency_demographics "no" //Normally this is "no", but "yes" for NM or other state where you have demographics to use when there is no address or zip code.
global adjustment "yes" // set yes or no for the adjusted vs. unadjusted first name probabilities 

//set the global directory for the project 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata" 

//set the directory to wherever the input files are
global data_dir="$dir\Data Files"

//set the directory and name for the output file
global excel_filename="$dir\BIFSG_${demographic_dataset}_${year}_${state_abbrev_upper}" 


//set the directory for the log file
cd "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\logs"

// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY-NN-DD date("$S_DATE","DMY")
display "$S_DATE" 
display "$out_date" // to check that current date and out_date are the same
capture log close
log using "BIFSG_${demographic_dataset}_${year}_${state_abbrev_upper}_$out_date.log", append

//Set the directory 
cd "$dir" 


/*=====================================================================================
Sheet 1: Input 
--------------------------------------------------------------------------------------
=======================================================================================*/
set obs $total_rows

gen number=_n
gen claim_number="" if _n==1
gen name="" if _n==1
gen res_street_address="" if _n==1
gen city_state_zip="" if _n==1
gen res_city_desc="" if _n==1
gen zip_code_clean=`"=IF(\$J2="", IFERROR(INDEX(claim_zip!\$B:\$B, MATCH(\$B2, claim_zip!\$A:\$A, 0)), ""), IF(ISNUMBER(IF(\$J2<>"", VALUE(LEFT(TEXT(\$J2, 0), 5)), VALUE(RIGHT(\$E2, 5)))), IF(\$J2<>"", VALUE(LEFT(TEXT(\$J2, 0), 5)), VALUE(RIGHT(\$E2, 5))),""))"' if _n==1

gen state_cd=`"=IFERROR(LET(FIRSTPOSTCOMMACHARPOSITION, FIND(",", E2) + 1, TRIM(MID(E2, FIRSTPOSTCOMMACHARPOSITION, MIN(3, IFERROR(FIND(",", E2, FIRSTPOSTCOMMACHARPOSITION)-FIRSTPOSTCOMMACHARPOSITION, 4))))), "")"' if _n==1

gen pd=`"=IF(G2="", INDEX(claim_pd_list!\$B:\$B, MATCH(TEXT(\$B2,0), claim_pd_list!\$A:\$A, 0)), "")"' if _n==1

gen dirty_zip=`""' if _n==1

//exporting file to excel 
export excel using "$excel_filename", sheet("input", replace) firstrow(variables)


/*=====================================================================================
Sheet 2: Output 
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 
set obs $total_rows

gen number=_n

gen claim_number= `"=input!B2"' if _n==1

gen aaan_prob= `"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!B2 * 'p(f|r)_incl_middle'!B2 * race_geo_probabilities!B2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(C$1=\$C$1, 1, 0)), 2)"' if _n==1

gen api_prob= `"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!C2 * 'p(f|r)_incl_middle'!C2 * race_geo_probabilities!C2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(D$1=\$C$1, 1, 0)), 2)"'   if _n==1


gen balck_prob= `"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!D2 * 'p(f|r)_incl_middle'!D2 * race_geo_probabilities!D2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(E$1=\$C$1, 1, 0)), 2)"' if _n==1

gen hisp_prob= `"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!E2 * 'p(f|r)_incl_middle'!E2 * race_geo_probabilities!E2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(F$1=\$C$1, 1, 0)), 2)"' if _n==1

gen white_prob=`"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!F2 * 'p(f|r)_incl_middle'!F2 * race_geo_probabilities!F2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(G$1=\$C$1, 1, 0)), 2)"' if _n==1

gen mixed_prob=`"=ROUND(IF(\$I2<>"Tribal Agency", ('p(r|s)_incl_middle'!G2 * 'p(f|r)_incl_middle'!G2 * race_geo_probabilities!G2) / SUM('p(r|s)_incl_middle'!\$B2 * 'p(f|r)_incl_middle'!\$B2 * race_geo_probabilities!\$B2, 'p(r|s)_incl_middle'!\$C2 * 'p(f|r)_incl_middle'!\$C2 * race_geo_probabilities!\$C2, 'p(r|s)_incl_middle'!\$D2 * 'p(f|r)_incl_middle'!\$D2 * race_geo_probabilities!\$D2, 'p(r|s)_incl_middle'!\$E2 * 'p(f|r)_incl_middle'!\$E2 * race_geo_probabilities!\$E2,'p(r|s)_incl_middle'!\$F2 * 'p(f|r)_incl_middle'!\$F2 * race_geo_probabilities!\$F2,'p(r|s)_incl_middle'!\$G2 * 'p(f|r)_incl_middle'!\$G2 * race_geo_probabilities!\$G2), IF(H$1=\$C$1, 1, 0)), 2)"' if _n==1

gen match_type=`"=IF(AND(ISERROR(FIND("PUEBLO", INDEX(agency_demographics_w_abbrev!B:B, MATCH(input!I2, agency_demographics_w_abbrev!A:A, 0)))), ISERROR(FIND("TRIBAL", INDEX(agency_demographics_w_abbrev!B:B, MATCH(input!I2, agency_demographics_w_abbrev!A:A, 0))))), geo_match!AS2, "Tribal agency")"' if _n==1

gen match_level=`"=IF(I2="Tribal agency", I2, geo_match!AT2)"' if _n==1

gen sum_probabilities=`"=SUM(C2:H2)"' if _n==1

//exporting file to excel 
export excel using "$excel_filename", sheet("output", replace) firstrow(variables)


/*=====================================================================================
Sheet 2: Name Cleaning 
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 
set obs $total_rows

gen number=_n

gen claim_number= `"=input!B2"' if _n==1

//original name
gen original_name=`"=input!C2"' if _n==1

//the first step will be to drop any suffix 
gen name_nosuffix=""
replace name_nosuffix=`"=IF(ISNUMBER(SEARCH(",", C2)), LEFT(C2, SEARCH(",", C2) - 1), C2)"' if _n==1 

//then we will get rid of any extra spaces in the way the names are entered. Specifically, we trim any extra spaces at the beginning or end of the names 
gen name_nospace=`"=TRIM(D2)"' if _n==1 
/*=====================================================================================
Creating a first name column 
--------------------------------------------------------------------------------------
=======================================================================================*/

//creating first name column--need uppercase to match with RAND datasets 
gen first_clean=`"=UPPER(IFERROR(LEFT(E2, FIND(" ",E2) - 1), E2))"' if _n==1  

/*=====================================================================================
Creating a middle name column 
--------------------------------------------------------------------------------------
Note: this will take two steps to get the middle name the way we need it 
=======================================================================================*/
//creating middle name column 
gen middle_name=`"=IFERROR(MID(E2, FIND(" ", E2) + 1, FIND(" ", MID(E2, FIND(" ", E2) + 1, LEN(E2))) - 1), "")"' if _n==1 

//next we only keep complete middle names and drop any initials 
gen middle_clean=`"=UPPER(IF(OR(ISNUMBER(SEARCH(" ", G2)), ISNUMBER(SEARCH(".", G2))), "", G2))"' if _n==1 

/*=====================================================================================
Creating a last name column 
--------------------------------------------------------------------------------------
Note: this will take multiple steps to get the last name the way we need it 
=======================================================================================*/ 

//first we create a column for the first word in a multiple last names 
*Note: this is only for names where the last name is to words separated by a space 
gen last_1_clean=`"=IFERROR(MID(E2,SEARCH(" ",E2,SEARCH(" ",E2)+1)+1,SEARCH(" ",MID(E2,SEARCH(" ",E2,SEARCH(" ",E2)+1)+1,LEN(E2)))-1), "")"' if _n==1

//next we need a last name column that in the last word of any of the names listed 
gen last_2=`"=IFERROR(MID(E2, FIND("@", SUBSTITUTE(E2, " ", "@", LEN(E2)-LEN(SUBSTITUTE(E2, " ", "")))) + 1, LEN(E2)), E2)"' if _n==1 //column I in excel 

//now we need to get rid of the hyphen in any last names 
gen last2a=`"=SUBSTITUTE(J2,"-","")"' if _n==1 

//now we need to concatenate all the last names getting rid of all spaces and hyphens 
*Note: we basically concatenate last_1 and last_2a 
gen last_concat_clean=`"=UPPER(CONCAT(I2,K2))"' if _n==1

//now we need columns for each part of the hyphenated last name separately to match if the concatendated name doesn't work 

gen last_hyphen1_clean=`"=UPPER(IF(ISNUMBER(SEARCH("-", J2)), LEFT(J2, SEARCH("-", J2) - 1), ""))"' if _n==1 

gen last_hyphen2_clean=`"=UPPER(IF(ISNUMBER(SEARCH("-", J2)), MID(J2, SEARCH("-", J2) + 1, LEN(J2) - SEARCH("-", J2)), ""))"' if _n==1

//exporting file to excel
export excel using "$excel_filename", sheet("name cleaning", replace) firstrow(variables)

/*=====================================================================================
Sheet 3: Clean Names
--------------------------------------------------------------------------------------
new sheet with only the text of the cleaned variables to then match
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n

gen claim_number=`"=input!B2"' if _n==1

//recoding columns from previous sheet now to keep only text 
gen first_clean=`"='name cleaning'!F2"' if _n==1 
gen middle_clean=`"='name cleaning'!H2"' if _n==1 
gen last_1_clean=`"='name cleaning'!I2"' if _n==1 
gen last_concat_clean=`"='name cleaning'!L2"' if _n==1 
gen last_hyphen1_clean=`"=UPPER(IF('name cleaning'!M2="", 'name cleaning'!I2, 'name cleaning'!M2))"' if _n==1 
gen last_hyphen2_clean=`"=UPPER(IF(AND('name cleaning'!N2="", NOT('name cleaning'!I2="")), 'name cleaning'!J2, 'name cleaning'!N2))"' if _n==1 

//exporting to the same excel as above but in the next sheet 
export excel using "$excel_filename", sheet("clean names", replace) firstrow(variables)

/*=====================================================================================
Sheet 4: First Name Match
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n

gen claim_number= `"=input!B2"' if _n==1

//first clean--copied from clean names sheet 
gen first_clean=`"=IF(ISBLANK('clean names'!C2), "", 'clean names'!C2)"' if _n==1

//first white 
gen first_white=`"=IFERROR(INDEX('first_name_list_p(f|r)'!B$2:B$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!B$135780)"' if _n==1

//first black 
gen first_black=`"=IFERROR(INDEX('first_name_list_p(f|r)'!C$2:C$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!C$135780)"' if _n==1 

//first hispanic 
gen first_hispanic=`"=IFERROR(INDEX('first_name_list_p(f|r)'!D$2:D$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!D$135780)"' if _n==1 

//first api 
gen first_api=`"=IFERROR(INDEX('first_name_list_p(f|r)'!E$2:E$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!E$135780)"' if _n==1 

//first ameind 
gen first_ameind=`"=IFERROR(INDEX('first_name_list_p(f|r)'!F$2:F$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!F$135780)"' if _n==1

//first_multi 
gen first_multi=`"=IFERROR(INDEX('first_name_list_p(f|r)'!G$2:G$135780, MATCH(\$C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), 'first_name_list_p(f|r)'!G$135780)"' if _n==1

//match---this will tell us if the first name matched the list exactly or was matched to the row for all other names 
gen match=`"=IF(ISNUMBER(MATCH(C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780,0)), "Match", "No Match")"' if _n==1 
**double check if this variable is only for internal file or file going to states as well 

//exporting to excel sheet 
export excel using "$excel_filename", sheet("first name match", replace) firstrow(variables)


/*=====================================================================================
Sheet 5: Middle Name Match
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n

gen claim_number= `"=input!B2"' if _n==1

//middle clean
gen middle_clean=`"=IF(ISBLANK('clean names'!D2), "", 'clean names'!D2)"' if _n==1

//middle white 
gen middle_white=`"=IF(\$C2<>"",IF(\$J2="FIRST MATCH", INDEX('first_name_list_p(f|r)'!B$2:B$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)), IF(\$K2="LAST MATCH", INDEX('surname list'!B$2:B$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))),"")"' if _n==1 

//middle black 
gen middle_black=`"=IF(\$C2<>"",IF(\$J2="FIRST MATCH",INDEX('first_name_list_p(f|r)'!C$2:C$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)),IF(\$K2="LAST MATCH",INDEX('surname list'!C$2:C$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))),"")"' if _n==1 

//middle_hispanic 
gen middle_hispanic=`"=IF(\$C2<>"",IF(\$J2="FIRST MATCH",INDEX('first_name_list_p(f|r)'!D$2:D$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)),IF(\$K2="LAST MATCH",INDEX('surname list'!D$2:D$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))),"")"' if _n==1 

//middle api 
gen middle_api=`"=IF(\$C2<>"",IF(\$J2="FIRST MATCH",INDEX('first_name_list_p(f|r)'!E$2:E$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)),IF(\$K2="LAST MATCH",INDEX('surname list'!E$2:E$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))),"")"' if _n==1 

//middle ameind 
gen middle_ameind=`"=IF(\$C2<>"", IF(\$J2="FIRST MATCH",INDEX('first_name_list_p(f|r)'!F$2:F$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)),IF(\$K2="LAST MATCH", INDEX('surname list'!F$2:F$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))), "")"' if _n==1 

//middle multi 
gen middle_multi=`"=IF(\$C2<>"",IF(\$J2="FIRST MATCH",INDEX('first_name_list_p(f|r)'!G$2:G$135780, MATCH(\$C2, 'first_name_list_p(f|r)'!\$A$2:\$A$135780, 0)),IF(\$K2="LAST MATCH",INDEX('surname list'!G$2:G$355632, MATCH(\$C2, 'surname list'!\$A$2:\$A$355632, 0)))),"")"' if _n==1 

gen first_match=`"=IF(C2="","", IF(ISNUMBER(MATCH(C2,'first_name_list_p(f|r)'!\$A$2:\$A$135780,0)),"FIRST MATCH", "NO MATCH"))"' if _n==1 

gen last_match=`"=IF(C2<>"",IF(J2="NO MATCH",IF(ISNUMBER(MATCH(C2, 'surname list'!\$A$2:\$A$355632, 0)),"LAST MATCH",""),"NO MATCH"),"")"' if _n==1 

//exporting to excel sheet 
export excel using "$excel_filename", sheet("middle name match", replace) firstrow(variables)

/*=====================================================================================
Sheet 6: Last Name Match
--------------------------------------------------------------------------------------
=======================================================================================*/ 

clear 
set obs $total_rows

gen number=_n

gen claim_number= `"=input!B2"' if _n==1

//last concatenated clean 
gen last_concat_clean=`"=IF(ISBLANK('clean names'!F2), "", 'clean names'!F2)"' if _n==1 

//last hyphen1 
gen last_hyphen1_clean=`"=IF(ISBLANK('clean names'!G2), "", 'clean names'!G2)"' if _n==1 

//last hypen2
gen last_hyphen2_clean=`"=IF(ISBLANK('Clean Names'!H2), "", 'Clean Names'!H2)"' if _n==1 

//last concat match 
gen last_concat_match=`"=IF(ISNUMBER(MATCH(C2,'surname list'!\$A$2:\$A$355632, 0)), "Match", "No Match")"' if _n==1 

//last hyphen 1 match 
gen last_hyphen1_match=`"=IF(ISNUMBER(MATCH(D2,'surname list'!\$A$2:\$A$355632, 0)), "Match", "No Match")"' if _n==1 

//last hyphen 2 match 
gen last_hyphen2_match=`"=IF(ISNUMBER(MATCH(E2,'surname list'!\$A$2:\$A$355632, 0)), "Match", "No Match")"' if _n==1 

//last white total
gen last_white_total=`"=IF(\$F2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!B$2:B$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!B$2:B$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!B$355632)))))"' if _n==1 

//last black total
gen last_black_total=`"=IF(\$F2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!C$2:C$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!C$2:C$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!C$355632)))))"' if _n==1 

//last hispanic total
gen last_hispanic_total=`"=IF(\$F2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!D$2:D$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!D$2:D$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!D$355632)))))"' if _n==1 

//last api total
gen last_api_total=`"=IF(\$F2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!E$2:E$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!E$2:E$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!E$355632)))))"' if _n==1 

//last ameind total
gen last_ameind_total=`"=IF(\$F2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!F$2:F$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!F$2:F$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!F$355632)))))"' if _n==1 

//last multi total
gen last_multi_total=`"=IF(\$F2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$G2="Match",\$H2="Match"),AVERAGE(INDEX('surname list'!G$2:G$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),INDEX('surname list'!G$2:G$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0))),IF(\$G2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),IF(\$H2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),IF(AND(\$F2="NO MATCH",\$G2="NO MATCH",\$H2="NO MATCH"),'surname list'!F$355632)))))"' if _n==1 


/*--------------------------------------------------------------------------------------------------------------------------------
Concatenated Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the concatenated name 
---------------------------------------------------------------------------------------------------------------------------------*/

//last_white_concat
gen last_white_concat=`"=IF(\$F2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last black concat 
gen last_black_concat=`"=IF(\$F2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last hisp concat 
gen last_hisp_concat=`"=IF(\$F2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last api concat
gen last_api_concat=`"=IF(\$F2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last ameind concat 
gen last_ameind_concat=`"=IF(\$F2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last multi concat 
gen last_multi_concat=`"=IF(\$F2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$C2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Hyphen 1 Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the first part of a hyphenated name or the first name of two last names 
---------------------------------------------------------------------------------------------------------------------------------*/

//last white hyphen 1 
gen last_white_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last black hyphen1 
gen last_black_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last hispanic hyphen 1 
gen last_hisp_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last api hyphen 1 
gen last_api_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last ameind hyphen 1 
gen last_ameind_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last multi hyphen 1 
gen last_multi_hyphen1=`"=IF(\$G2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$D2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Hyphen 2 Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the first part of a hyphenated name or the second name of two last names 
---------------------------------------------------------------------------------------------------------------------------------*/

//last white hyphen 2 
gen last_white_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!B$2:B$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last black hyphen 2 
gen last_black_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!C$2:C$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last hispanic hyphen 2 
gen last_hisp_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!D$2:D$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last api hyphen 2
gen last_api_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!E$2:E$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last ameind hyphen 2
gen last_ameind_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!F$2:F$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 

//last multi hyphen 2
gen last_multi_hyphen2=`"=IF(\$H2="Match",INDEX('surname list'!G$2:G$355632,MATCH(\$E2,'surname list'!\$A$2:\$A$355632,0)),"")"' if _n==1 


//exporting to excel sheet 
export excel using "$excel_filename", sheet("last name match", replace) firstrow(variables)

/*=====================================================================================
Sheet 7: First Name List p(f|r)
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 

if "$adjustment" == "yes" {
		import excel "$data_dir\first_name_pnamerace.xlsx", sheet("first_adjusted") firstrow
	}

if "$adjustment" == "no" {
		import excel "$data_dir\first_name_pnamerace.xlsx", sheet("first_unadj") firstrow
	}

//exporting to excel sheet 
export excel using "$excel_filename", sheet("first_name_list_p(f|r)", replace) firstrow(variables)

/*=====================================================================================
Sheet 8: Surname list
--------------------------------------------------------------------------------------
=======================================================================================*/  
clear

import excel "$data_dir\name_race_probabilities.xlsx", sheet("race_lastname") firstrow clear

//exporting to excel sheet 
export excel using "$excel_filename", sheet("surname list", replace) firstrow(variables)

/*=====================================================================================
Sheet 9: nat race data
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 

import excel "$data_dir\US Demographics $demographic_dataset $year.xlsx", firstrow
drop state
gen region="United States"
order region, first

//exporting to excel sheet 
export excel using "$excel_filename", sheet("nat_race_data", replace) firstrow(variables)


/*=====================================================================================
Sheet 10: p(f|r)_incl_middle
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n

gen aaan_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!H2,'middle name match'!H2), 'first name match'!H2)"' if _n==1 

gen aipi_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!G2,'middle name match'!G2), 'first name match'!G2)"' if _n==1 

gen blck_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!E2,'middle name match'!E2), 'first name match'!E2)"' if _n==1 

gen hisp_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!F2,'middle name match'!F2), 'first name match'!F2)"' if _n==1 

gen whit_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!D2,'middle name match'!D2), 'first name match'!D2)"' if _n==1 

gen mixd_prob=`"=IF('middle name match'!\$J2="FIRST MATCH", AVERAGE('first name match'!I2,'middle name match'!I2), 'first name match'!I2)"' if _n==1 

//exporting to excel sheet 
export excel using "$excel_filename", sheet("p(f|r)_incl_middle", replace) firstrow(variables)

/*=====================================================================================
Sheet 11: p(r|s)_incl_middle
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n

gen aaan_prob=`"=L2"' if _n==1 

gen aipi_prob=`"=K2"' if _n==1 

gen blck_prob=`"=I2"' if _n==1 

gen hisp_prob=`"=J2"' if _n==1 

gen whit_prob=`"=H2"' if _n==1 

gen mixd_prob=`"=M2"' if _n==1 

gen white=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!I2, 'middle name match'!D2) / COUNT('last name match'!I2, 'middle name match'!D2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!D2, 'last name match'!O2, 'last name match'!U2, 'last name match'!AA2) /COUNT('middle name match'!D2, 'last name match'!O2, 'last name match'!U2, 'last name match'!AA2),""), 'last name match'!I2))"' if _n==1 

gen black=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!J2, 'middle name match'!E2) / COUNT('last name match'!J2, 'middle name match'!E2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!E2, 'last name match'!P2, 'last name match'!V2, 'last name match'!AB2) /COUNT('middle name match'!E2, 'last name match'!P2, 'last name match'!V2, 'last name match'!AB2),""), 'last name match'!J2))"' if _n==1 

gen hisp=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!K2, 'middle name match'!F2) / COUNT('last name match'!K2, 'middle name match'!F2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!F2, 'last name match'!Q2, 'last name match'!W2, 'last name match'!AC2) /COUNT('middle name match'!F2, 'last name match'!Q2, 'last name match'!W2, 'last name match'!AC2),""), 'last name match'!K2))"' if _n==1 

gen aipi=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!L2, 'middle name match'!G2) / COUNT('last name match'!L2, 'middle name match'!G2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!G2, 'last name match'!R2, 'last name match'!X2, 'last name match'!AD2) /COUNT('middle name match'!G2, 'last name match'!R2, 'last name match'!X2, 'last name match'!AD2),""), 'last name match'!L2))"' if _n==1 

gen aaan=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!M2, 'middle name match'!H2) / COUNT('last name match'!M2, 'middle name match'!H2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!H2, 'last name match'!S2, 'last name match'!Y2, 'last name match'!AE2) /COUNT('middle name match'!H2, 'last name match'!S2, 'last name match'!Y2, 'last name match'!AE2),""), 'last name match'!M2))"' if _n==1 

gen mixd=`"=IF(AND('middle name match'!\$K2="LAST MATCH",'last name match'!\$F2="No Match", 'last name match'!\$G2="No Match", 'last name match'!\$H2="No Match"), IFERROR(SUM('last name match'!N2, 'middle name match'!I2) / COUNT('last name match'!N2, 'middle name match'!I2),""),IF('middle name match'!\$K2="LAST MATCH", IFERROR(SUM('middle name match'!I2, 'last name match'!T2, 'last name match'!Z2, 'last name match'!AF2) /COUNT('middle name match'!I2, 'last name match'!T2, 'last name match'!Z2, 'last name match'!AF2),""), 'last name match'!N2))"' if _n==1


//exporting to excel sheet 
export excel using "$excel_filename", sheet("p(r|s)_incl_middle", replace) firstrow(variables)


/*=====================================================================================
Sheet 12: cleaning address
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n
gen claim_number= `"=input!B2"' if _n==1

gen address_1 =`"=TRIM(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(UPPER(input!D2), ",", ""), ".", ""), "", ""))"' if _n==1

gen house_number=`"=LEFT(C2, FIND(" ",C2))"' if _n==1

gen number_clean =`"=TRIM(LEFT(D2, MIN(FIND({"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","-"}, D2&"ABCDEFGHIJKLMNOPQRSTUVWXYZ-"))-1))"' if _n==1

gen street_address=`"=IFERROR(TRIM(RIGHT(SUBSTITUTE(C2,D2,""),LEN(C2)-LEN(D2))),C2)"' if _n==1

gen street_address_word1 =`"=IFERROR(LEFT(F2, FIND(" ", F2)-1), F2)"' if _n==1

gen street_address_word2 =`"=IFERROR(MID(F2, LEN(G2)+2, IF(ISERROR(FIND(" ", F2, LEN(G2)+2)), LEN(F2)-LEN(G2)-1, FIND(" ", F2, LEN(G2)+2)-LEN(G2)-1)),"")"' if _n==1

gen street_address_word3 =`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-2, FIND(" ", F2, (LEN(G2)+LEN(H2))+2)-(LEN(G2)+LEN(H2))-2)),"")"' if _n==1

gen street_address_word4=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2))+2)-(LEN(G2)+LEN(H2)+LEN(I2))-1)),"")"' if _n==1

gen street_address_word5=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2))-1)),"")"' if _n==1

gen street_address_word6=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-LEN(K2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2))-1)),"")"' if _n==1

gen street_address_word7=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-LEN(K2)-LEN(L2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2))-1)),"")"' if _n==1

gen street_address_word8=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-LEN(K2)-LEN(L2)-LEN(M2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2))-1)),"")"' if _n==1

gen street_address_word9=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-LEN(K2)-LEN(L2)-LEN(M2)-LEN(N2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2))-1)),"")"' if _n==1

gen street_address_word10=`"=IFERROR(MID(F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2)+LEN(O2))+2, IF(ISERROR(FIND(" ", F2,  (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2)+LEN(O2))+2)), LEN(F2)-LEN(G2)-LEN(H2)-LEN(I2)-LEN(J2)-LEN(K2)-LEN(L2)-LEN(M2)-LEN(N2)-LEN(O2)-1, FIND(" ", F2, (LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2)+LEN(O2))+2)-(LEN(G2)+LEN(H2)+LEN(I2)+LEN(J2)+LEN(K2)+LEN(L2)+LEN(M2)+LEN(N2)+LEN(O2))-1)),"")"' if _n==1

gen word1_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(G2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(G2)))))))))"' if _n==1

gen word2_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(H2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(H2)))))))))"' if _n==1

gen word3_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(I2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(I2)))))))))"' if _n==1

gen word4_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(J2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(J2)))))))))"' if _n==1

gen word5_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(K2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(K2)))))))))"' if _n==1

gen word6_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(L2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(L2)))))))))"' if _n==1

gen word7_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(M2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(M2)))))))))"' if _n==1

gen word8_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(N2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(N2)))))))))"' if _n==1

gen word9_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(O2),street_abbreviations!\$G$2:\$G$225,0)),TRIM(O2)))))))))"' if _n==1

gen word10_unabbrev=`"=TRIM(IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$A$2:\$A$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$B$2:\$B$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$C$2:\$C$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$D$2:\$D$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$E$2:\$E$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$F$2:\$F$225,0)),IFERROR(INDEX(street_abbreviations!\$A$2:\$A$225,MATCH(TRIM(P2),street_abbreviations!\$G$2:\$G$22,0)),TRIM(P2)))))))))"' if _n==1

gen clean_address1=`"=TRIM(CONCAT(Q2," ",R2," ",S2," ",T2," ",U2," ",V2," ",W2," ",X2," ",Y2," ",Z2," ",))"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("cleaning_address1", replace) firstrow(variables)

/*=====================================================================================
Sheet 13: cleaning address 2 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set obs $total_rows

gen number=_n
gen claim_number= `"=input!B2"' if _n==1

gen number_clean =`"=cleaning_address1!E2"' if _n==1

gen clean_address1=`"=cleaning_address1!AA2"' if _n==1

gen street_address_noline2=`"=IFERROR(TRIM(LEFT(D2, SEARCH(INDEX(line_2_options!\$A$2:\$A$34, MATCH(TRUE, ISNUMBER(SEARCH(line_2_options!\$A$2:\$A$34, D2)), 0)), D2) - 1)), D2)"' if _n==1

gen street_address_last_word=`"=IFERROR(IF(ISNUMBER(FIND(" ", E2)), TRIM(RIGHT(SUBSTITUTE(E2, " ", REPT(" ", LEN(E2))), LEN(E2))), ""), E2)"' if _n==1

gen last_word_number=`"=OR(ISNUMBER(VALUE(LEFT(F2,1))), ISNUMBER(VALUE(RIGHT(F2,1))))"' if _n==1

gen street_name=`"=IF(G2, IFERROR(LEFT(E2,LEN(E2)-LEN(F2)-1),E2),E2)"' if _n==1

gen second_suffix=`"=IFERROR(INDEX(street_abbreviations!\$A$2:\$A$6,MATCH(TRIM(RIGHT(SUBSTITUTE(H2," ",REPT(" ",LEN(H2))),LEN(H2))),street_abbreviations!\$A$2:\$A$6,0)),"")"' if _n==1

gen street_name_nosecondsuffix=`"=IF(I2="",H2, LEFT(H2,LEN(H2)-LEN(I2)-1))"' if _n==1

gen exact_match=`"=IF(OR(TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="ROUTE",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="HIGHWAY",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="US"),CONCAT(J2," ",F2),H2)"' if _n==1

gen exact_match_nospace=`"=SUBSTITUTE(SUBSTITUTE(K2,"-","")," ","")"' if _n==1

gen match_nostreetnum=`"=SUBSTITUTE(SUBSTITUTE(IF(OR(TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="ROUTE",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="HIGHWAY",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="US"),CONCAT(J2," ",F2),H2),"-","")," ","")"' if _n==1

gen match_nosecondsuffix=`"=IF(OR(TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="ROUTE",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="HIGHWAY",TRIM(RIGHT(SUBSTITUTE(J2," ",REPT(" ",LEN(J2))),LEN(J2)))="US"),CONCAT(J2," ",F2),J2)"' if _n==1

gen match_nosecondsuffix_nospace=`"=SUBSTITUTE(SUBSTITUTE(N2,"-","")," ","")"' if _n==1

gen street_suffix=`"=IFERROR(IF(ISNUMBER(FIND(" ", TRIM(IF(RIGHT(J2, 9) = "SOUTHEAST", "SOUTHEAST " & LEFT(J2, LEN(J2) - 9),IF(RIGHT(J2, 9) = "NORTHEAST", "NORTHEAST " & LEFT(J2, LEN(J2) - 9),IF(RIGHT(J2, 9) = "SOUTHWEST", "SOUTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "NORTHWEST", "NORTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 5) = "SOUTH", "SOUTH " & LEFT(J2, LEN(J2) - 5),IF(RIGHT(J2, 4) = "EAST", "EAST " & LEFT(J2, LEN(J2) - 4),  IF(RIGHT(J2, 4) = "WEST", "WEST " & LEFT(J2, LEN(J2) - 4), IF(RIGHT(J2, 5) = "NORTH", "NORTH " & LEFT(J2, LEN(J2) - 5), J2 ) ) ))))))))),TRIM(RIGHT(SUBSTITUTE(TRIM(IF(RIGHT(J2, 9) = "SOUTHEAST", "SOUTHEAST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "NORTHEAST", "NORTHEAST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "SOUTHWEST", "SOUTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "NORTHWEST", "NORTHWEST " & LEFT(J2, LEN(J2) - 9),  IF(RIGHT(J2, 5) = "SOUTH", "SOUTH " & LEFT(J2, LEN(J2) - 5),  IF(RIGHT(J2, 4) = "EAST", "EAST " & LEFT(J2, LEN(J2) - 4),  IF(RIGHT(J2, 4) = "WEST", "WEST " & LEFT(J2, LEN(J2) - 4),IF(RIGHT(J2, 5) = "NORTH", "NORTH " & LEFT(J2, LEN(J2) - 5), J2 ) ) ))))))), " ", REPT(" ", LEN(TRIM(IF(RIGHT(J2, 9) = "SOUTHEAST", "SOUTHEAST " & LEFT(J2, LEN(J2) - 9),IF(RIGHT(J2, 9) = "NORTHEAST", "NORTHEAST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "SOUTHWEST", "SOUTHWEST " & LEFT(J2, LEN(J2) - 9),IF(RIGHT(J2, 9) = "NORTHWEST", "NORTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 5) = "SOUTH", "SOUTH " & LEFT(J2, LEN(J2) - 5), IF(RIGHT(J2, 4) = "EAST", "EAST " & LEFT(J2, LEN(J2) - 4),  IF(RIGHT(J2, 4) = "WEST", "WEST " & LEFT(J2, LEN(J2) - 4), IF(RIGHT(J2, 5) = "NORTH", "NORTH " & LEFT(J2, LEN(J2) - 5),J2))))))) ))))), LEN(TRIM(IF(RIGHT(J2, 9) = "SOUTHEAST", "SOUTHEAST " & LEFT(J2, LEN(J2) - 9),IF(RIGHT(J2, 9) = "NORTHEAST", "NORTHEAST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "SOUTHWEST", "SOUTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 9) = "NORTHWEST", "NORTHWEST " & LEFT(J2, LEN(J2) - 9), IF(RIGHT(J2, 5) = "SOUTH", "SOUTH " & LEFT(J2, LEN(J2) - 5),IF(RIGHT(J2, 4) = "EAST", "EAST " & LEFT(J2, LEN(J2) - 4),  IF(RIGHT(J2, 4) = "WEST", "WEST " & LEFT(J2, LEN(J2) - 4), IF(RIGHT(J2, 5) = "NORTH", "NORTH " & LEFT(J2, LEN(J2) - 5), J2)))))))))))), ""), J2)"' if _n==1

gen match_reduced_name =`"=SUBSTITUTE(SUBSTITUTE(IF(ISNUMBER(MATCH(P2, street_abbreviations!\$A$25:\$A$225, 0)), TRIM(SUBSTITUTE(N2, P2, "")), N2),"-", ""), " ", "")"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("cleaning_address2", replace) firstrow(variables)

/*=====================================================================================
Sheet 14: clean addresses  
--------------------------------------------------------------------------------------
=======================================================================================*/ 

clear 
set obs $total_rows

gen number=_n
gen claim_number= `"=input!B2"' if _n==1

gen res_street_address=`"=input!D2"' if _n==1

gen zip_code=`"=IF(ISBLANK(input!G2), "", input!G2)"' if _n==1
 
gen pd=`"=IF(ISBLANK(input!I2), "", input!I2)"' if _n==1

gen number_clean =`"=IFERROR(VALUE(cleaning_address2!C2), "")"' if _n==1

gen exact_match_nospace=`"=cleaning_address2!L2"' if _n==1

gen match_nosecondsuffix_nospace=`"=cleaning_address2!O2"' if _n==1

gen match_reduced_name =`"=cleaning_address2!Q2"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("clean_addresses", replace) firstrow(variables)


/*=====================================================================================
Sheet 15: Street Abbreviations
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 

import excel "$data_dir\street abbreviations.xlsx", sheet("street_abbreviations") firstrow

export excel using "$excel_filename", sheet("street_abbreviations", replace) firstrow(variables)


/*=====================================================================================
Sheet 16: Line 2 options
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 
set obs $total_rows

gen common_line2_words="APARTMENT" if _n==1
replace common_line2_words="APARTMENTO" if _n==2
replace common_line2_words="APT" if _n==3
replace common_line2_words="APTM" if _n==4
replace common_line2_words="APTO" if _n==5
replace common_line2_words="BASEMENT" if _n==6
replace common_line2_words="BLDG" if _n==7
replace common_line2_words="BSMNT" if _n==8
replace common_line2_words="BUILDING" if _n==9
replace common_line2_words="DEPARTAMENTO" if _n==10
replace common_line2_words="DEPT" if _n==11
replace common_line2_words="DEPTO" if _n==12
replace common_line2_words="FL" if _n==13
replace common_line2_words="FLOOR" if _n==14
replace common_line2_words="FLR" if _n==15
replace common_line2_words="FRONT" if _n==16
replace common_line2_words="LEVEL" if _n==17
replace common_line2_words="LVL" if _n==18
replace common_line2_words="OFC" if _n==19
replace common_line2_words="OFF" if _n==20
replace common_line2_words="OFFICE" if _n==21
replace common_line2_words="P.O. BOX" if _n==22
replace common_line2_words="PENTHOUSE" if _n==23
replace common_line2_words="PNTH" if _n==24
replace common_line2_words="PO BOX" if _n==25
replace common_line2_words="REAR" if _n==26
replace common_line2_words="RM" if _n==27
replace common_line2_words="ROOM" if _n==28
replace common_line2_words="STE" if _n==29
replace common_line2_words="SU" if _n==30
replace common_line2_words="SUITE" if _n==31
replace common_line2_words="UNIT" if _n==32
replace common_line2_words="#" if _n==33

export excel using "$excel_filename", sheet("line_2_options", replace) firstrow(variables)


/*=====================================================================================
Sheet 17: Street Segments
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 


if "$state_abbrev_upper"=="NC" {
	use "$data_dir\\${state_abbrev_lower}_street_segments_clean_for_exporting", clear //file name is different for some reason
}
else {
	use "$data_dir\\${state_abbrev_lower}_${year}_street_segments_clean_for_exporting", clear
}

export excel using "$excel_filename", sheet("street_segments", replace) firstrow(variables)

/*=====================================================================================
Sheet 18: Agency Names (agency_names)
--------------------------------------------------------------------------------------
this section is only for states where individual address data is not useable and we have 
the agency name that the crime was reported to. However, a blank sheet is created otherwise
=======================================================================================*/

clear 

if "$state_w_agency_demographics" == "yes" { //only  import for some states
	import excel "$data_dir\\${state_abbrev_upper} PD names crosswalk_updated.xlsx", sheet("pd_names_crosswalk") firstrow
	drop if match_final=="$state_name_upper" //dropping those PDs whose crosswalk matches them to the state. These cases will be matched to state demographics in geo_match
}
else {
	set obs 1
	set obs $total_rows
	gen number= _n
}
export excel using "$excel_filename", sheet("pd_names_crosswalk", replace) firstrow(variables)

/*=====================================================================================
Sheet 19: Geo match
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 
set obs $total_rows

gen number=_n
gen block_group_match1_via_sgmnt=`"=IF(input!\$G2="","", IFERROR(IFERROR(INDEX(street_segments!H:H, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G) * (MOD(clean_addresses!\$F2, 2) = MOD(street_segments!\$F:\$F, 2)), 0)), INDEX(street_segments!H:H, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G), 0))), ""))"' if _n==1

gen block_group_match2_via_sgmnt=`"=IF(input!\$G2="","", IFERROR(IFERROR(INDEX(street_segments!I:I, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G) * (MOD(clean_addresses!\$F2, 2) = MOD(street_segments!\$F:\$F, 2)), 0)), INDEX(street_segments!I:I, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G), 0))), ""))"' if _n==1

gen block_group_match3_via_sgmnt=`"=IF(input!\$G2="","", IFERROR(IFERROR(INDEX(street_segments!J:J, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G) * (MOD(clean_addresses!\$F2, 2) = MOD(street_segments!\$F:\$F, 2)), 0)), INDEX(street_segments!J:J, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G), 0))), ""))"' if _n==1

gen block_group_match4_via_sgmnt=`"=IF(input!\$G2="","", IFERROR(IFERROR(INDEX(street_segments!K:K, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G) * (MOD(clean_addresses!\$F2, 2) = MOD(street_segments!\$F:\$F, 2)), 0)), INDEX(street_segments!K:K, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2) * (clean_addresses!\$F2 >= street_segments!\$F:\$F) * (clean_addresses!\$F2 <= street_segments!\$G:\$G), 0))), ""))"'  if _n==1

gen block_group_match1_via_st=`"=IF(input!\$G2="","", IF(\$B2<>"", "", IFERROR(INDEX(street_segments!H:H, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),"")))"' if _n==1

gen block_group_match2_via_st=`"=IF(input!\$G2="","", IF(\$B2<>"", "", IFERROR(INDEX(street_segments!I:I, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),"")))"' if _n==1

gen block_group_match3_via_st=`"=IF(input!\$G2="","", IF(\$B2<>"", "", IFERROR(INDEX(street_segments!J:J, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),"")))"' if _n==1

gen block_group_match4_via_st=`"=IF(input!\$G2="","", IF(\$B2<>"", "", IFERROR(INDEX(street_segments!K:K, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),"")))"' if _n==1

gen geodata_to_use_st_mtch=`"=IF(input!\$G2="","", IF(\$B2<>"", "", IFERROR(INDEX(street_segments!P:P, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),"")))"' if _n==1

gen block_group_no2ndsufx_match1=`"=IF(input!\$G2="","", IF(OR(\$B2<>"", \$F2<>""), "", IFERROR(INDEX(street_segments!H:H, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),"")))"'  if _n==1

gen block_group_no2ndsufx_match2=`"=IF(input!\$G2="","", IF(OR(\$B2<>"", \$F2<>""), "", IFERROR(INDEX(street_segments!I:I, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),"")))"' if _n==1

gen block_group_no2ndsufx_match3=`"=IF(input!\$G2="","", IF(OR(\$B2<>"", \$F2<>""), "", IFERROR(INDEX(street_segments!J:J, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),"")))"' if _n==1

gen block_group_no2ndsufx_match4=`"=IF(input!\$G2="","", IF(OR(\$B2<>"", \$F2<>""), "", IFERROR(INDEX(street_segments!K:K, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),"")))"' if _n==1

gen geodata_to_use_no2ndsufx=`"=IF(input!\$G2="","", IF(OR(\$B2<>"", \$F2<>""), "", IFERROR(INDEX(street_segments!P:P, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),"")))"' if _n==1

gen blk_grp_match1_via_reduced_name=`"=IF(input!\$G2="","", IF(OR(\$B2<>"",\$F2<>"", \$K2), "", IFERROR(INDEX(street_segments!H:H, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),"")))"' if _n==1

gen blk_grp_match2_via_reduced_name=`"=IF(input!\$G2="","", IF(OR(\$B2<>"",\$F2<>"", \$K2), "", IFERROR(INDEX(street_segments!I:I, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),"")))"' if _n==1

gen blk_grp_match3_via_reduced_name=`"=IF(input!\$G2="","", IF(OR(\$B2<>"",\$F2<>"", \$K2), "", IFERROR(INDEX(street_segments!J:J, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),"")))"' if _n==1

gen blk_grp_match4_via_reduced_name=`"=IF(input!\$G2="","", IF(OR(\$B2<>"",\$F2<>"", \$K2), "", IFERROR(INDEX(street_segments!K:K, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),"")))"' if _n==1

gen geodata_to_use_for_reduced_name=`"=IF(input!\$G2="","", IF(OR(\$B2<>"",\$F2<>"", \$K2), "", IFERROR(INDEX(street_segments!Q:Q, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),"")))"' if _n==1

gen tract_match1_via_st_name=`"=IF(\$J2<>"tractid","",  IFERROR(INDEX(street_segments!L:L, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),""))"' if _n==1

gen tract_match2_via_st_name=`"=IF(\$J2<>"tractid","",  IFERROR(INDEX(street_segments!M:M, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),""))"' if _n==1

gen tract_match3_via_st_name=`"=IF(\$J2<>"tractid","",  IFERROR(INDEX(street_segments!N:N, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),""))"' if _n==1

gen tract_match4_via_st_name=`"=IF(\$J2<>"tractid","",  IFERROR(INDEX(street_segments!O:O, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$G2), 0)),""))"' if _n==1

gen tract_match1_via_no2nd_sufx=`"=IF(\$O2<>"tractid","",  IFERROR(INDEX(street_segments!L:L, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),""))"' if _n==1

gen tract_match2_via_no2nd_sufx=`"=IF(\$O2<>"tractid","",  IFERROR(INDEX(street_segments!M:M, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),""))"' if _n==1

gen tract_match3_via_no2nd_sufx=`"=IF(\$O2<>"tractid","",  IFERROR(INDEX(street_segments!N:N, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),""))"' if _n==1

gen tract_match4_via_no2nd_sufx=`"=IF(\$O2<>"tractid","",  IFERROR(INDEX(street_segments!O:O, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$D:\$D = clean_addresses!\$H2), 0)),""))"' if _n==1

gen tract_match1_via_red_name=`"=IF(\$T2<>"tractids","",  IFERROR(INDEX(street_segments!L:L, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),""))"' if _n==1

gen tract_match2_via_red_name=`"=IF(\$T2<>"tractids","",  IFERROR(INDEX(street_segments!M:M, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),""))"' if _n==1

gen tract_match3_via_red_name=`"=IF(\$T2<>"tractids","",  IFERROR(INDEX(street_segments!N:N, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),""))"' if _n==1

gen tract_match4_via_red_name=`"=IF(\$T2<>"tractids","",  IFERROR(INDEX(street_segments!O:O, MATCH(1, (street_segments!\$A:\$A = clean_addresses!\$D2) * (street_segments!\$E:\$E = clean_addresses!\$I2), 0)),""))"' if _n==1

gen final_geoid1=`"=IF(\$B2<>"", B2, IF(F2<>"", IF(\$J2="geoid", F2, ""), IF(K2<>"", IF(\$O2="geoid", K2, ""), IF(P2<>"", IF(\$T2="geoid", P2, ""), ""))))"' if _n==1

gen final_geoid2=`"=IF(\$B2<>"", C2, IF(G2<>"", IF(\$J2="geoid", G2, ""), IF(L2<>"", IF(\$O2="geoid", L2, ""), IF(Q2<>"", IF(\$T2="geoid", Q2, ""), ""))))"' if _n==1

gen final_geoid3=`"=IF(\$B2<>"", D2, IF(H2<>"", IF(\$J2="geoid", H2, ""), IF(M2<>"", IF(\$O2="geoid", M2, ""), IF(R2<>"", IF(\$T2="geoid", R2, ""), ""))))"' if _n==1

gen final_geoid4=`"=IF(\$B2<>"", E2, IF(I2<>"", IF(\$J2="geoid", I2, ""), IF(N2<>"", IF(\$O2="geoid", N2, ""), IF(S2<>"", IF(\$T2="geoid", S2, ""), ""))))"' if _n==1

gen final_tract1=`"=IF(U2<>"",U2, IF(Y2<>"", Y2, IF(AC2<>"",AC2,"")))"' if _n==1

gen final_tract2=`"=IF(V2<>"",V2, IF(Z2<>"", Z2, IF(AD2<>"",AD2,"")))"' if _n==1

gen final_tract3=`"=IF(W2<>"",W2, IF(AA2<>"", AA2, IF(AE2<>"",AE2,"")))"' if _n==1

gen final_tract4=`"=IF(X2<>"",X2, IF(AB2<>"", AB2, IF(AF2<>"",AF2,"")))"' if _n==1

gen zip_match=`"=IF(OR(J2="zip", O2="zip", T2="zip", AND(B2="",F2="",K2="", P2="")), clean_addresses!D2,"")"' if _n==1

gen final_agency=`"=IF(input!D2="",IFERROR(INDEX(pd_names_crosswalk!B:B,MATCH(input!I2, pd_names_crosswalk!\$A:\$A, 0)),""),"")"' if _n==1

gen final_state=`"=IF(AND(\$AO2="", \$AP2="",\$B2="", \$F2="", \$K2="", \$P2=""), INDEX(state_abbrev_list!\$A$2:\$A$52, MATCH(input!\$H2, state_abbrev_list!\$B$2:\$B$52, 0)), "")"' if _n==1

gen final_country=`""' if _n==1

gen match_type=`"=IF(\$B2<>"", "Segment", IF(\$F2<>"", "Street name", IF(\$K2<>"", "No 2nd suffix name", IF(\$P2<>"", "Reduced name", IF(\$AO2<>"","Zip", IF(\$AP2<>"","Agency", IF(\$AQ2<>"", "State","No Match")))))))"' if _n==1

gen match_level=`"=IF(\$AG2<>"", "Block group", IF(\$AK2<>"", "Tract", IF(\$AO2<>"","Zip", IF(\$AP2<>"","Agency", IF(\$AQ2<>"", "State","No match")))))"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("geo_match", replace) firstrow(variables)


/*=====================================================================================
Sheet 20: Block group demographics (blk_grp_demographics)
--------------------------------------------------------------------------------------
=======================================================================================*/

clear


if "$state_abbrev_upper"=="NC" {
	import excel "$data_dir\\${state_abbrev_upper} Census Data.xlsx", sheet("block group demographics") firstrow
}
else {
	import excel "$data_dir\\$state_abbrev_upper Demographics $demographic_dataset $year.xlsx", sheet("block group demographics") firstrow
}


export excel using "$excel_filename", sheet("blk_grp_demographics", replace) firstrow(variables)


/*=====================================================================================
Sheet 21: Tract Demographics (tract_demographics)
--------------------------------------------------------------------------------------
=======================================================================================*/ 

clear

if "$state_abbrev_upper"=="NC" {
	import excel "$data_dir\\${state_abbrev_upper} Census Data.xlsx", sheet("tract demographics") firstrow
}
else {
import excel "$data_dir\\$state_abbrev_upper Demographics $demographic_dataset $year.xlsx", sheet("tract demographics") firstrow
}

export excel using "$excel_filename", sheet("tract_demographics", replace) firstrow(variables)


/*=====================================================================================
Sheet 22: Zip Demographics 	(zip_demographics)
--------------------------------------------------------------------------------------
=======================================================================================*/ 

clear

if "$state_abbrev_upper"=="NC" {
	import excel "$data_dir\\${state_abbrev_upper} Census Data.xlsx", sheet("zipcode demographics") firstrow
}
else {
import excel "$data_dir\\$state_abbrev_upper Demographics $demographic_dataset $year.xlsx", sheet("zipcode demographics") firstrow
}

export excel using "$excel_filename", sheet("zip_demographics", replace) firstrow(variables)


/*=====================================================================================
Sheet 23: Agency Demographics w/ Abbreviations (agency_demographics_w_abbrev)
--------------------------------------------------------------------------------------
only use this code for states where individual address data is not useable and we have 
the agency name that the crime was reported to 
=======================================================================================*/
clear 

if "$state_w_agency_demographics" == "yes" {
	import excel "$data_dir\df_agency_acs_jurisdiction_${year}_${state_abbrev_lower}_population.xlsx", sheet("Sheet 1") firstrow
	replace ucr_agency_name = strupper(ucr_agency_name)
	//change percentages to proportion
	foreach var of varlist estimate_am_indian estimate_api estimate_black estimate_multi_racial ///
		estimate_white { // NOTE: check that estimate_api exists, originally it was saved as estimate_appi
		replace `var' = `var' / 100
	}
	//calculate hispanic estimate
	gen estimate_hisp = 1 - estimate_am_indian - estimate_api - estimate_black - ///
		estimate_multi_racial - estimate_white 
	drop ori9
	order estimate_white estimate_multi_racial acs_estimate_total_population, last
}
else {
	set obs 1
	set obs $total_rows
	gen number= _n
}

export excel using "$excel_filename", sheet("agency_demographics_w_abbrev", replace) firstrow(variables)

 /*=====================================================================================
Sheet 24: Out of State Demographics (out_state_demographics)
--------------------------------------------------------------------------------------
only use this sheet if you plan to include cases from out of state in your analysis
=======================================================================================*/
clear 

if "$state_abbrev_upper"=="NC" {
	import excel "$data_dir\\${state_abbrev_upper} Census Data.xlsx", sheet("state demographics") firstrow
}
else {
import excel "$data_dir\\$state_abbrev_upper Demographics $demographic_dataset $year.xlsx", sheet("state demographics") firstrow
}

export excel using "$excel_filename", sheet("out_state_demographics", replace) firstrow(variables)

/*=====================================================================================
Sheet 25: Matched Geo Race Probabilities Demographics (matched_geo_race_probabilities)
--------------------------------------------------------------------------------------
=======================================================================================*/
clear 
set obs $total_rows

gen number=_n

gen aaan_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!B:B, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!B:B, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!B:B, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!B:B, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!B:B, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!B:B, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!B:B, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!B:B, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen aipi_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!C:C, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!C:C, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!C:C, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!C:C, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!C:C, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!C:C, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!C:C, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!C:C, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen blck_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!D:D, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!D:D, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!D:D, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!D:D, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!D:D, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!D:D, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!D:D, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!D:D, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen hisp_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!E:E, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!E:E, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!E:E, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!E:E, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!E:E, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!E:E, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!E:E, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!E:E, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen whit_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!F:F, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!F:F, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!F:F, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!F:F, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!F:F, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!F:F, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!F:F, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!F:F, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen mixd_prob1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!G:G, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!G:G, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!G:G, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!G:G, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!G:G, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!G:G, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!G:G, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!G:G, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen geo_total1=`"=IF(geo_match!\$AT2="Block group", INDEX(blk_grp_demographics!H:H, MATCH(geo_match!\$AG2, blk_grp_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Tract", INDEX(tract_demographics!H:H, MATCH(geo_match!\$AK2, tract_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Zip",INDEX(zip_demographics!H:H, MATCH(geo_match!\$AO2, zip_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Agency", INDEX(agency_demographics_w_abbrev!H:H, MATCH(geo_match!\$AP2,agency_demographics_w_abbrev!\$A:\$A, 0)), IF(geo_match!\$AT2="State", INDEX(out_state_demographics!H:H, MATCH(geo_match!\$AQ2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="Country", INDEX(out_state_demographics!H:H, MATCH(geo_match!\$AR2, out_state_demographics!\$A:\$A, 0)), IF(geo_match!\$AT2="No match", INDEX(out_state_demographics!H:H, MATCH("United States", out_state_demographics!\$A:\$A, 0)), INDEX(out_state_demographics!H:H, MATCH("United States", out_state_demographics!\$A:\$A, 0)))))))))"' if _n==1

gen aaan_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!B:B, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!B:B, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aipi_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!C:C, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!C:C, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen blck_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!D:D, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!D:D, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen hisp_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!E:E, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!E:E, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen whit_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!F:F, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!F:F, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen mixd_prob2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!G:G, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!G:G, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen geo_total2=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!H:H, MATCH(geo_match!\$AH2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!H:H, MATCH(geo_match!\$AL2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aaan_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!B:B, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!B:B, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aipi_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!C:C, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!C:C, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen blck_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!D:D, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!D:D, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen hisp_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!E:E, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!E:E, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen whit_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!F:F, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!F:F, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen mixd_prob3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!G:G, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!G:G, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen geo_total3=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!H:H, MATCH(geo_match!\$AI2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!H:H, MATCH(geo_match!\$AM2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aaan_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!B:B, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!B:B, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aipi_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!C:C, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!C:C, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen blck_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!D:D, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!D:D, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen hisp_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!E:E, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!E:E, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen whit_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!F:F, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!F:F, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen mixd_prob4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!G:G, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!G:G, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen geo_total4=`"=IF(geo_match!\$AT2="Block group", IFERROR(INDEX(blk_grp_demographics!H:H, MATCH(geo_match!\$AJ2, blk_grp_demographics!\$A:\$A, 0)), "."), IF(geo_match!\$AT2="Tract", IFERROR(INDEX(tract_demographics!H:H, MATCH(geo_match!\$AN2, tract_demographics!\$A:\$A, 0)), "."), IF(OR(geo_match!\$AT2="Zip", geo_match!\$AT2="Agency", geo_match!\$AT2="State", geo_match!\$AT2="Country", geo_match!\$AT2="No match"), ".")))"' if _n==1

gen aaan_prob_avg=`"=AVERAGE(B2,I2, P2, W2)"' if _n==1

gen aipi_prob_avg=`"=AVERAGE(C2,J2, Q2, X2)"' if _n==1

gen blck_prob_avg=`"=AVERAGE(D2,K2, R2, Y2)"' if _n==1

gen hisp_prob_avg=`"=AVERAGE(E2,L2, S2, Z2)"' if _n==1

gen whit_prob_avg=`"=AVERAGE(F2,M2, T2, AA2)"' if _n==1

gen mixd_prob_avg=`"=AVERAGE(G2,N2, U2, AB2)"' if _n==1

gen geo_total_avg=`"=AVERAGE(H2,O2, V2, AC2)"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("matched_geo_race_probabilities", replace) firstrow(variables)


/*=====================================================================================
Sheet 26: Race Geo Probabilities Demographics (race_geo_probabilities)
--------------------------------------------------------------------------------------
=======================================================================================*/

clear 
set obs $total_rows

gen number=_n

gen aaan_prob=`"=matched_geo_race_probabilities!B2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!B$3, nat_race_data!B$2)"' if _n==1

gen aipi_prob=`"=matched_geo_race_probabilities!C2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!C$3, nat_race_data!C$2)"' if _n==1

gen blck_prob=`"=matched_geo_race_probabilities!D2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!D$3, nat_race_data!D$2)"' if _n==1

gen hisp_prob=`"=matched_geo_race_probabilities!E2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!E$3, nat_race_data!E$2)"' if _n==1

gen whit_prob=`"=matched_geo_race_probabilities!F2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!F$3, nat_race_data!F$2)"' if _n==1

gen mixd_prob=`"=matched_geo_race_probabilities!G2 * matched_geo_race_probabilities!\$H2 / IF(geo_match!\$AE2="International", nat_race_data!G$3, nat_race_data!G$2)"' if _n==1

//exporting to excel sheet 
export excel using "$excel_filename", sheet("race_geo_probabilities", replace) firstrow(variables)

/*=====================================================================================
Sheet 27: Claim PD List
--------------------------------------------------------------------------------------
=======================================================================================*/

clear 

if "$state_w_agency_demographics" == "yes" { //only  import for some states
	import excel "Excel Files\\${state_abbrev_upper} Claim PD List.xlsx", sheet("NM Claim PD List") firstrow
}
else {
	set obs 1
	set obs $total_rows
	gen number= _n
}
export excel using "$excel_filename", sheet("claim_pd_list", replace) firstrow(variables)

/*=====================================================================================
Sheet 28: State Abbreviation List
--------------------------------------------------------------------------------------
=======================================================================================*/
clear

import excel "Excel Files\state_abbrev_crosswalk.xlsx", firstrow

export excel using "$excel_filename", sheet("state_abbrev_list", replace) firstrow(variables)

/*=====================================================================================
Sheet 29: Claim Zip
--------------------------------------------------------------------------------------
=======================================================================================*/

clear 

if "$state_abbrev_upper" == "NM" { //only  import for a state where you have address data that the state may not have access to
	import excel "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\NM\NM Victims Compensation data\February 2024 submission\victim data entry 2 NO PII.xlsx", sheet("victim data entry 2") firstrow 
	keep Claim VictimZip //Only need the claim number and the zipcode 
	rename Claim claim_number
	drop if VictimZip=="Not Provided" | VictimZip=="unknown" | VictimZip==" "
	replace VictimZip="87107" if VictimZip=="87107-4706"
	rename VictimZip zipcode
	destring zipcode, replace
	drop if zipcode==.
	export excel using "$excel_filename", sheet("claim_zip", replace) firstrow(variables)

}
else {
	set obs 1
	set obs $total_rows
	gen number= _n
}
	export excel using "$excel_filename", sheet("claim_zip", replace) firstrow(variables)

clear
log close
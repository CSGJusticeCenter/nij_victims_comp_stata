/*=====================================================================================
Program Author: Shradha Sahani
Start Date: January 22, 2023
Last Updated: March 7, 2024

Program Description: Creating excel matching sheets for BIFSG 

Objective: Creating code in Stata to export to excel to match first, middle, and last 
names with race probabilities from other datasets 
=====================================================================================*/

clear 
set more off 
set obs 65000 //creating 65000 observations which should be enough for all the claims 

/*if not running from BIFSG project main.do

global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata" // make relative path so others can use these files as well 


cd "$dir" //setting directory 

global data="$dir\Data Files" //directory for data files---update this to correct file locations in data folder 
global excel="$dir\Excel Files" //directory for excel output files 
*/

/*************************************************************************************************************
FIRST NAME MATCHING CODE
--------------------------------------------------------------------------------------------------------------
Creating functions to match first names to first name probabilities 
***************************************************************************************************************/
clear 
set obs 65000 //double check this number to include all claims 

//claim number 
gen claim_number=`"=IF(ISBLANK('Clean Names'!A2), "", 'Clean Names'!A2)"' if _n==1 

//first clean--copied from clean names sheet 
gen first_clean=`"=IF(ISBLANK('Clean Names'!B2), "", 'Clean Names'!B2)"' if _n==1

//first white 
gen first_white=`"=IFERROR(INDEX('First Name List'!B$2:B$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!B$4252)"' if _n==1

//first black 
gen first_black=`"=IFERROR(INDEX('First Name List'!C$2:C$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!C$4252)"' if _n==1 

//first hispanic 
gen first_hispanic=`"=IFERROR(INDEX('First Name List'!D$2:D$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!D$4252)"' if _n==1 

//first api 
gen first_api=`"=IFERROR(INDEX('First Name List'!E$2:E$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!E$4252)"' if _n==1 

//first ameind 
gen first_ameind=`"=IFERROR(INDEX('First Name List'!F$2:F$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!F$4252)"' if _n==1

//first_multi 
gen first_multi=`"=IFERROR(INDEX('First Name List'!G$2:G$4251, MATCH($B2,'First Name List'!$A$2:$A$4251, 0)), 'First Name List'!G$4252)"' if _n==1

//match---this will tell us if the first name matched the list exactly or was matched to the row for all other names 
gen match=`"=IF(ISNUMBER(MATCH(B2, 'First Name List'!$A$2:$A$4251,0)), "Match", "No Match")"' if _n==1 
**double check if this variable is only for internal file or file going to states as well 

//exporting to excel sheet 
export excel using "$excel\BIFSG_name_matching", sheet("First Name Match", replace) firstrow(variables)

/*************************************************************************************************************
MIDDLE NAME MATCHING CODE
--------------------------------------------------------------------------------------------------------------
Creating functions to match middle names to either first or last name probabilities 
1. matching middle names to first name list 
2. if no match, then matching to last name list 
***************************************************************************************************************/
clear 
set obs 65000 //double check this number to include all claims 

//claim number 
gen claim_number=`"=IF(ISBLANK('Clean Names'!A2), "", 'Clean Names'!A2)"' if _n==1 

//middle clean
gen middle_clean=`"=IF(ISBLANK('Clean Names'!B2), "", 'Clean Names'!B2)"' if _n==1

//first_match 
gen first_match=`"=IF(B2="","", IF(ISNUMBER(MATCH(B2,'First Name List'!$A$2:$A$4251,0)),"FIRST MATCH", "NO MATCH"))"' if _n==1 

//last_match 
gen last_match=`"=IF(B2<>"",IF(C2="NO MATCH", IF(ISNUMBER(MATCH(B2, 'Surname List'!$A$2:$A$167409, 0)), "LAST MATCH",""),"NO MATCH"),"")"' if _n==1 

//middle white 
gen middle_white=`"=IF($B2<>"", IF( $C2="FIRST MATCH", INDEX('First Name List'!B$2:B$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)), IF($D2="LAST MATCH", INDEX('Surname List'!B$2:B$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"")"' if _n==1 

//middle black 
gen middle_black=`"=IF($B2<>"", IF($C2="FIRST MATCH", INDEX('First Name List'!C$2:C$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)), IF($D2="LAST MATCH",INDEX('Surname List'!C$2:C$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"")"' if _n==1 

//middle_hispanic 
gen middle_hispanic=`"=IF($B2<>"", IF($C2="FIRST MATCH",INDEX('First Name List'!D$2:D$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)),IF($D2="LAST MATCH", INDEX('Surname List'!D$2:D$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"") "' if _n==1 

//middle api 
gen middle_api=`"=IF($B2<>"", IF($C2="FIRST MATCH", INDEX('First Name List'!E$2:E$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)), IF($D2="LAST MATCH", INDEX('Surname List'!E$2:E$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"")"' if _n==1 

//middle ameind 
gen middle_ameind=`"=IF($B2<>"",IF($C2="FIRST MATCH",INDEX('First Name List'!F$2:F$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)), IF($D2="LAST MATCH", INDEX('Surname List'!F$2:F$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"")"' if _n==1 

//middle multi 
gen middle_multi=`"=IF($B2<>"",IF($C2="FIRST MATCH",INDEX('First Name List'!G$2:G$4252, MATCH($B2, 'First Name List'!$A$2:$A$4251, 0)), IF($D2="LAST MATCH", INDEX('Surname List'!G$2:G$167409, MATCH($B2, 'Surname List'!$A$2:$A$167409, 0)))),"")"' if _n==1 


//exporting to excel sheet 
export excel using "$excel\BIFSG_name_matching", sheet("Middle Name Match", replace) firstrow(variables)

/*************************************************************************************************************
LAST NAME MATCHING CODE
--------------------------------------------------------------------------------------------------------------
1. match concatenated last name 
2. if concatenated does not match then match hyphen 1 and 2 separately and average their probabilities 
***************************************************************************************************************/
clear 
set obs 65000 //double check this number to include all claims 

//claim number 
gen claim_number=`"=IF(ISBLANK('Clean Names'!A2), "", 'Clean Names'!A2)"' if _n==1 

//last concatenated clean 
gen last_concat_clean=`"=IF(ISBLANK('Clean Names'!E2), "", 'Clean Names'!E2)"' if _n==1 

//last hyphen1 
gen last_hyphen1_clean=`"=IF(ISBLANK('Clean Names'!F2), "", 'Clean Names'!F2)"' if _n==1 

//last hypen2
gen last_hyphen2_clean=`"=IF(ISBLANK('Clean Names'!G2), "", 'Clean Names'!G2)"' if _n==1 

//last concat match 
gen last_concat_match=`"=IF(ISNUMBER(MATCH(B2,'Surname List'!$A$2:$A$167409, 0)), "Match", "No Match")"' if _n==1 

//last hyphen 1 match 
gen last_hyphen1_match=`"=IF(ISNUMBER(MATCH(C2,'Surname List'!$A$2:$A$167409, 0)), "Match", "No Match")"' if _n==1 

//last hyphen 2 match 
gen last_hyphen2_match=`"=IF(ISNUMBER(MATCH(D2,'Surname List'!$A$2:$A$167409, 0)), "Match", "No Match")"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Total Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
this includes matching concatenated name first, then hyphen 1 and hyphen 2, and average hyphen1 and last_hyphen2 probabilities
---------------------------------------------------------------------------------------------------------------------------------*/
//last white total
gen last_white=`"=IF($E2="Match",INDEX('Surname List'!B$2:B$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!B$2:B$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!B$2:B$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!B$2:B$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!B$2:B$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

//last black total
gen last_black=`"=IF($E2="Match",INDEX('Surname List'!C$2:C$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!C$2:C$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!C$2:C$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!C$2:C$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!C$2:C$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

//last hispanic total
gen last_hispanic=`"=IF($E2="Match",INDEX('Surname List'!D$2:D$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!D$2:D$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!D$2:D$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!D$2:D$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!D$2:D$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

//last api total
gen last_api=`"=IF($E2="Match",INDEX('Surname List'!E$2:E$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!E$2:E$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!E$2:E$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!E$2:E$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!E$2:E$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

//last ameind total
gen last_ameind=`"=IF($E2="Match",INDEX('Surname List'!F$2:F$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!F$2:F$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!F$2:F$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!F$2:F$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!F$2:F$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

//last multi total
gen last_multi=`"=IF($E2="Match",INDEX('Surname List'!G$2:G$167409,MATCH($B2,'Surname List'!$A$2:$A$167409,0)),IF(AND($F2="Match",$G2="Match"),AVERAGE(INDEX('Surname List'!G$2:G$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),INDEX('Surname List'!G$2:G$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0))),IF($F2="Match",INDEX('Surname List'!G$2:G$167409,MATCH($C2,'Surname List'!$A$2:$A$167409,0)),IF($G2="Match",INDEX('Surname List'!G$2:G$167409,MATCH($D2,'Surname List'!$A$2:$A$167409,0)),IF(AND($E2="NO MATCH",$F2="NO MATCH",$G2="NO MATCH"),"")))))"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Concatenated Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the concatenated name 
---------------------------------------------------------------------------------------------------------------------------------*/

//last_white_concat
gen last_white_concat=`"=IF($F2="Match",INDEX('surname list'!B$2:B$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last black concat 
gen last_black_concat=`"=IF($F2="Match",INDEX('surname list'!C$2:C$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last hisp concat 
gen last_hisp_concat=`"=IF($F2="Match",INDEX('surname list'!D$2:D$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last api concat
gen last_api_concat=`"=IF($F2="Match",INDEX('surname list'!E$2:E$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last ameind concat 
gen last_ameind_concat=`"=IF($F2="Match",INDEX('surname list'!F$2:F$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last multi concat 
gen last_multi_concat=`"=IF($F2="Match",INDEX('surname list'!G$2:G$355632,MATCH($C2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Hyphen 1 Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the first part of a hyphenated name or the first name of two last names 
---------------------------------------------------------------------------------------------------------------------------------*/

//last white hyphen 1 
gen last_white_hyphen1=`"=IF($G2="Match",INDEX('surname list'!B$2:B$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last black hyphen1 
gen last_black_hyphen1=`"=IF($G2="Match",INDEX('surname list'!C$2:C$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last hispanic hyphen 1 
gen last_hisp_hyphen1=`"=IF($G2="Match",INDEX('surname list'!D$2:D$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last api hyphen 1 
gen last_api_hyphen1=`"=IF($G2="Match",INDEX('surname list'!E$2:E$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last ameind hyphen 1 
gen last_ameind_hyphen1=`"=IF($G2="Match",INDEX('surname list'!F$2:F$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last multi hyphen 1 
gen last_multi_hyphen1=`"=IF($G2="Match",INDEX('surname list'!G$2:G$355632,MATCH($D2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

/*--------------------------------------------------------------------------------------------------------------------------------
Hyphen 2 Last Name Probabilities 
----------------------------------------------------------------------------------------------------------------------------------
probabilities for only the first part of a hyphenated name or the second name of two last names 
---------------------------------------------------------------------------------------------------------------------------------*/

//last white hyphen 2 
gen last_white_hyphen2=`"=IF($H2="Match",INDEX('surname list'!B$2:B$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last black hyphen 2 
gen last_black_hyphen2=`"=IF($H2="Match",INDEX('surname list'!C$2:C$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last hispanic hyphen 2 
gen last_hisp_hyphen2=`"=IF($H2="Match",INDEX('surname list'!D$2:D$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last api hyphen 2
gen last_api_hyphen2=`"=IF($H2="Match",INDEX('surname list'!E$2:E$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last ameind hyphen 2
gen last_ameind_hyphen2=`"=IF($H2="Match",INDEX('surname list'!F$2:F$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 

//last multi hyphen 2
gen last_multi_hyphen2=`"=IF($H2="Match",INDEX('surname list'!G$2:G$355632,MATCH($E2,'surname list'!$A$2:$A$355632,0)),"")"' if _n==1 


//exporting to excel sheet 
export excel using "$excel\BIFSG_name_matching", sheet("last name match", replace) firstrow(variables)
 
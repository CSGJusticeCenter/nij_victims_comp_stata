/*=====================================================================================
Program Author: Shradha Sahani
Start Date: December 5, 2023
Last Updated: January 30, 2024

Program Description: CREATING BISG FIRST NAME AND LAST NAME CLEANING FILES

Objective: Creating code in Stata to export to excel for states to clean names and 
match with BIFSG files 
=====================================================================================*/

clear 
set more off 
set obs 65000 //creating 100000 observations which will be enough for all the claims 

/*if not running from BIFSG project main.do

global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata" // make relative path so others can use these files as well 


cd "$dir" //setting directory 

global data="$dir\Data Files" //directory for data files---update this to correct file locations in data folder 
global excel="$dir\Excel Files" //directory for excel output files 
*/

/*********************************************************************************************
Notes:
This file will just write the excel code and create the columns. We will double check in excel 
to make sure it's cleaning everything correctly after this is exported.

Also, the code will only be put into the first row and then in excel it will have to be expanded 
down because otherwise it will keep referencing the same cell in each row and not updating to 
the correct row 
The variables labeled "clean" are the cleaned versions we will be matching using the BIFSG 
> *********************************************************************************************/

/*=====================================================================================
creating a column for name where the states can enter the name of the indivdiual & 
claim number 
--------------------------------------------------------------------------------------
=======================================================================================*/
//claim number 
gen claim_number="" //this will be column A in excel 
tab claim_number 

//original name
gen original_name=" " //this will be column B in excel 
tab original_name 

/*=====================================================================================
First we will clean the original names to make it easier to separate out the names in 
the format we need 
--------------------------------------------------------------------------------------
=======================================================================================*/

//the first step will be to drop any suffix 
gen name_nosuffix=""
replace name_nosuffix=`"=IF(ISNUMBER(SEARCH(",", B2)), LEFT(B2, SEARCH(",", B2) - 1), B2)"' if _n==1 // column C in excel 

//then we will get rid of any extra spaces in the way the names are entered. Specifically, we trim any extra spaces at the beginning or end of the names 
gen name_nospace=`"=TRIM(C2)"' if _n==1 //column D in excel 


/*=====================================================================================
Creating a first name column 
--------------------------------------------------------------------------------------
=======================================================================================*/

//creating first name column--need uppercase to match with RAND datasets 
gen first_clean=""
replace first_clean=`"=UPPER(IFERROR(LEFT(D2, FIND(" ",D2) - 1), D2))"' if _n==1  // column E in excel 


/*=====================================================================================
Creating a middle name column 
--------------------------------------------------------------------------------------
Note: this will take two steps to get the middle name the way we need it 
=======================================================================================*/
//creating middle name column 
gen middle_name=""
replace middle_name=`"=IFERROR(MID(D2, FIND(" ", D2) + 1, FIND(" ", MID(D2, FIND(" ", D2) + 1, LEN(D2))) - 1), "")"' if _n==1 //column F in excel 

//next we only keep complete middle names and drop any initials 
gen middle_clean=""
replace middle_clean=`"=IF(OR(ISNUMBER(SEARCH(" ", F2)), ISNUMBER(SEARCH(".", F2))), "", F2)"' if _n==1 //column G in excel 




/*=====================================================================================
Creating a last name column 
--------------------------------------------------------------------------------------
Note: this will take multiple steps to get the last name the way we need it 
=======================================================================================*/ 

//first we create a column for the first word in a multiple last names 
*Note: this is only for names where the last name is to words separated by a space 
gen last_1_clean=""
replace last_1_clean=`"=IFERROR(MID(D2,SEARCH(" ",D2,SEARCH(" ",D2)+1)+1,SEARCH(" ",MID(D2,SEARCH(" ",D2,SEARCH(" ",D2)+1)+1,LEN(D2)))-1), "")"' if _n==1 //column H in excel 


//next we need a last name column that in the last word of any of the names listed 
gen last_2=""
replace last_2=`"=IFERROR(MID(D2, FIND("@", SUBSTITUTE(D2, " ", "@", LEN(D2)-LEN(SUBSTITUTE(D2, " ", "")))) + 1, LEN(D2)), D2)"' if _n==1 //column I in excel 


//now we need to get rid of the hyphen in any last names 
gen last2a=""
replace last2a=`"=SUBSTITUTE(I2,"-","")"' if _n==1 //column J in excel 

//now we need to concatenate all the last names getting rid of all spaces and hyphens 
*Note: we basically concatenate last_1 and last_2a 
gen last_concat_clean=""
replace last_concat_clean=`"=UPPER(CONCAT(H2,J2))"' if _n==1 //column K in excel 

//now we need columns for each part of the hyphenated last name separately to match if the concatendated name doesn't work 

gen last_hyphen1_clean=""
replace last_hyphen1=`"=UPPER(IF(ISNUMBER(SEARCH("-", I2)), LEFT(I2, SEARCH("-", I2) - 1), ""))"' if _n==1 //column L in excel 


gen last_hyphen2_clean=""
replace last_hyphen2_clean=`"=UPPER(IF(ISNUMBER(SEARCH("-", I2)), MID(I2, SEARCH("-", I2) + 1, LEN(I2) - SEARCH("-", I2)), ""))"' if _n==1 //column M in excel 


//exporting file to excel to make sure it works 
export excel using "$dir\Excel Files\BIFSG_name_matching", sheet("Name Cleaning", replace) firstrow(variables)

/*=====================================================================================
Creating a new sheet with cleaned names as text only and no formula 
--------------------------------------------------------------------------------------
new sheet with only the text of the cleaned variables to then match =======================================================================================*/ 

//variables to keep 
keep claim_number *clean 

//recoding variables now to keep only text 
replace claim_number=`"=VALUETOTEXT('Name Cleaning'!A2)"' if _n==1 
replace first_clean=`"=VALUETOTEXT('Name Cleaning'!E2)"' if _n==1 
replace middle_clean=`"=VALUETOTEXT('Name Cleaning'!F2)"' if _n==1 
replace last_1_clean=`"=VALUETOTEXT('Name Cleaning'!H2)"' if _n==1 
replace last_concat_clean=`"=VALUETOTEXT('Name Cleaning'!K2)"' if _n==1 
replace last_hyphen1_clean=`"=VALUETOTEXT('Name Cleaning'!L2)"' if _n==1 
replace last_hyphen2_clean=`"=VALUETOTEXT('Name Cleaning'!M2)"' if _n==1 

//exporting to the same excel as above but in the next sheet 
export excel using "$excel\BIFSG_name_matching", sheet("Clean Names", replace) firstrow(variables)

//when we complete the match for the last name we will first try to match last_concat_clean. If that doesn't match we will match last_1_clean, last_hyphen1_clean, and last_hyphen2_clean. If multiple of these match we will average the probabilities across these. In cases where there are 3 words in the first name, we will try to match the middle name to a first name first and if it doesn't match we will match it to a last name and average that probability as well 

/*************************************************************************************************************
NEXT STEPS 1/3/24
--------------------------------------------------------------------------------------------------------------
1. create cleaned HMDA first name file to match and export to excel sheet--remember to do weighting/correction
2. create cleaned last name file to merge and export to excel sheet 
3. Write vlookup code in excel to match names and probabilities together 
***************************************************************************************************************/

/*=====================================================================================
First Name HMDA data  
--------------------------------------------------------------------------------------
=======================================================================================*/ 

use 
//exporting file to excel 
export excel using "$excel\BIFSG_name_matching", sheet("First Name List", replace) firstrow(variables)


/*=====================================================================================
Surname File
--------------------------------------------------------------------------------------
=======================================================================================*/ 

use 
//exporting to excel sheet for match 
export excel using "$excel\BIFSG_name_matching", sheet("Surname List", replace) firstrow(variables)


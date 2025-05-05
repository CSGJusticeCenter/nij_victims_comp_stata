/*=====================================================================================
Program Author: Shradha Sahani
Start Date: February 5, 2024
Last Updated: February 8, 2024

Program Description: Building set of name/race probabilities using data from
	1. First Names--Tzoumis (HMDA data) and Roseman et al. (voter registration files)
	2. Last Names--RAND (Census) and Roseman et al. (voter registration files)

Objective: Combining these data sources in Stata and adjusting first name race 
probabilities using correction for national representation. 
=====================================================================================*/

clear 
set more off 

//run this code if not running do file after main.do 

global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata" // make relative path so others can use these files as well 

cd "$dir" //setting directory 
global data="$dir\Data Files" //directory for data files---update this to correct file locations in data folder 
global excel="$dir\Excel Files" //directory for excel output files 

/*=====================================================================================
Create race probabilities for both Census data and Tzoumis data  
--------------------------------------------------------------------------------------
1. creating a file with variables for race probabilities in both National Census and Tzoumis data
	- Tzoumis values created from "checking HMDA demographics with national comparisons.do"
	- US data created from "Census demographic data cleaning.do"
2. saving this file to merge in with the first name files for the race probabilty 
correction 
=======================================================================================*/ 

//starting by creating variables for hmda probabilities that we will use for the adjustment later 
import delimited "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\RAND BISG\HMDA to National Demographics Comparison.csv" 

//keeping only HMDA values (Tzoumis)
drop if data=="US Census 2010" 

foreach var of varlist per* {
		rename `var' `var'_hmda
}

list per* 

//renaming observation to merge 
replace data="race_probabilities"

//saving temporary file so I can merge it back later    
tempfile hmda_race_per
save "`hmda_race_per'"
 
//opening census data for US--2015-2019 ACS
use "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\RAND BISG\US demographics.dta", clear

//renaming variables 
foreach var of varlist per* {
		rename `var' `var'_census
}

//renaming observation to merge 
replace geo="race_probabilities"
rename geo data 

//merging files 
merge 1:1 data using "`hmda_race_per'"

//dropping merge
drop _merge 

//saving this file because we will merge it later with the rest of the data 
save "$data\race_per.dta", replace

/*=====================================================================================
First Name HMDA data  p(r|n)
--------------------------------------------------------------------------------------
1. Import Tzoumis first name file from RAND 
2. Create the race representation factor 
	- this is the correction for the over/underrepresentation of specific races in the
		mortgage dataset (check "simulation of name probability correction.do" for 
		the test of the correction)
	- values created from "checking HMDA demographics with national comparisons.do"
3. Create the adjusted first name probabilities that we will use for our match
=======================================================================================*/ 


/***********************************************************************************
Step 1: Bring in Tzoumis dataset and merge with race representation factor dataset
************************************************************************************/
clear 

//importing first name only file
import sas using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\BISG data\tzioumisfirstnamesarchived.sas7bdat"

//checking for unicode characters 
foreach letter in "á" "é" "í" "ó" "ú" "Á" "É" "Í" "Ó" "Ú" {
	di "`letter'"
	list firstname if strpos(firstname, "`letter'") > 0
}

/***************************************************************************************
Step 2: Create the race representation factor variables 
****************************************************************************************/
append using "$data\race_per.dta" //this is the dataset that has the national demographics and hmda values 

// Creating pop probabilities for each row 
// Pop probabilities are from 2015-2019 ACS census
gen aian_pop_prob = per_ameind_census[_N]
gen aapi_pop_prob = per_api_census[_N]
gen blck_pop_prob = per_black_census[_N]
gen hisp_pop_prob = per_hisp_census[_N]
gen whit_pop_prob = per_white_census[_N]
gen mult_pop_prob = per_multi_census[_N]

//creating sample probabilities for each row 
gen aian_sampl_prob = per_aian_hmda[_N]
gen aapi_sampl_prob = per_aapi_hmda[_N]
gen blck_sampl_prob = per_black_hmda[_N]
gen hisp_sampl_prob = per_hispanic_hmda[_N]
gen whit_sampl_prob = per_white_hmda[_N]
gen mult_sampl_prob = per_multirace_hmda[_N]

//dropping extra row from appended dataset 
drop if data=="race_probabilities" 

// Adjust probabilities to proportion of 1
foreach race in aian aapi blck hisp whit mult {
	di "`race'"
	replace `race'_pop_prob = `race'_pop_prob / 100
	replace `race'_sampl_prob = `race'_sampl_prob / 100
}

// Generate representation factors to generate frequencies in the sample
foreach race in aian aapi blck hisp whit mult {
	gen `race'_repres_factor = `race'_sampl_prob / `race'_pop_prob
	tab `race'_repres_factor
}

//generating new variables for the adjusted probabilities 
foreach var of varlist hispanic nh_white nh_black nh_api nh_ameind nh_multirace {
	gen `var'_adjusted=. 
}

//calculating the adjustment for each race individually 

**white 
replace nh_white_adjusted=nh_white/whit_repres_factor

**black 
replace nh_black_adjusted=nh_black/blck_repres_factor 

**hispanic 
replace hispanic_adjusted=hispanic/hisp_repres_factor

**api 
replace nh_api_adjusted=nh_api/aapi_repres_factor 

**aian 
replace nh_ameind_adjusted=nh_ameind/aian_repres_factor 

**multi 
replace nh_multirace_adjusted=nh_multirace/mult_repres_factor 

//next we have to ensure that the rowtotal of all the race probabilities add up to 1 

*first checking what the rowtotal is 
gen rowtotal=hispanic_adjusted + nh_white_adjusted + nh_black_adjusted + nh_api_adjusted + nh_ameind_adjusted + nh_multirace_adjusted 

**adjusted to add to 1 
foreach var of varlist *adjusted {
	gen `var'_corrected=`var'/rowtotal
}

**checking adjustment 
gen rowtotal2=hispanic_adjusted_corrected + nh_white_adjusted_corrected + nh_black_adjusted_corrected + nh_api_adjusted_corrected + nh_ameind_adjusted_corrected + nh_multirace_adjusted_corrected

sum rowtotal2 //there are still some at .99999 is this a rounding thing? 

**keep new corrected probabilities
keep firstname *corrected 

**renaming variables for ease of interpretation later 
rename hispanic_adjusted_corrected hispanic 
rename nh_white_adjusted_corrected white 
rename nh_black_adjusted_corrected black 
rename nh_api_adjusted_corrected api 
rename nh_ameind_adjusted_corrected  aian 
rename nh_multirace_adjusted_corrected multi

**ordering variables to make excel match easier 
order firstname white black hispanic api aian multi

**save data file to with corrected probabilities 
save "$data\Tzoumis_corrected.dta", replace 

/*=====================================================================================
First Name Voter Registration files 
--------------------------------------------------------------------------------------
1. Import Roseman et al. first name file--the probbaility of race given name 
2. split probabilities for other to create AIAN and multiracial categories--this will 
be a 50/50 split between the two probabilities 
3. Create the race representation factor 
	- this is the correction for the over/underrepresentation of specific races in the
		mortgage dataset (check "simulation of name probability correction.do" for 
		the test of the correction)
	- values created from "checking HMDA demographics with national comparisons.do" for 
Census estimates 
	- population and race % of voter registration data comes from Table 1 
Rosenman et al. (2023)
4. Create the adjusted first name probabilities that we will use for our match
=======================================================================================*/ 
clear 

import delimited "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\BISG data\dataverse_files\first_nameRaceProbs.csv" //probability of race|first name 

//renaming variables 
rename whi white 
rename bla black 
rename his hispanic 
rename asi api //Shradha double check if this includes Hawaiian Pacific Islander 


//creating ameind and other categories using one other category--we decided to split these probabilities in half between the two--this should be the proportion of the US national data each of these races is--NEED TO FIX THIS 
gen ameind=oth/2
gen multi=oth/2 

sum white 

/***************************************************************************************
Step 2: Create the race representation factor variables 
****************************************************************************************/
append using "$data\race_per.dta"

// Creating pop probabilities for each row 
// Pop probabilities are from 2015-2019 ACS
gen aian_pop_prob = per_ameind_census[_N]
gen aapi_pop_prob = per_api_census[_N]
gen blck_pop_prob = per_black_census[_N]
gen hisp_pop_prob = per_hisp_census[_N]
gen whit_pop_prob = per_white_census[_N]
gen mult_pop_prob = per_multi_census[_N]

// Sample probabilities are those from the Voter registration name database (Table 1 Rosenman et al. 2023)
gen aian_sampl_prob = (1.9/2) //dividing other category by 2 
gen aapi_sampl_prob = 1.6
gen blck_sampl_prob = 21.8
gen hisp_sampl_prob = 7.9
gen whit_sampl_prob = 62.8
gen mult_sampl_prob = (1.9/2) //dividing other category by 2 

//dropping extra row from appended dataset 
drop if data=="race_probabilities" 
drop *hmda 


// Adjust probabilities to proportion of 1
foreach race in aian aapi blck hisp whit mult {
	di "`race'"
	replace `race'_pop_prob = `race'_pop_prob / 100
	replace `race'_sampl_prob = `race'_sampl_prob / 100
}

// Generate representation factors to generate frequencies in the sample
foreach race in aian aapi blck hisp whit mult {
	gen `race'_repres_factor = `race'_sampl_prob / `race'_pop_prob
	tab `race'_repres_factor
}

//generating new variables for the adjusted probabilities 
foreach var of varlist white black hispanic api ameind multi {
	gen `var'_adjusted=. 
}

//calculating the adjustment for each race individually 

**white 
replace white_adjusted=white/whit_repres_factor

**black 
replace black_adjusted=black/blck_repres_factor 

**hispanic 
replace hispanic_adjusted=hispanic/hisp_repres_factor

**api 
replace api_adjusted=api/aapi_repres_factor 

**aian 
replace ameind_adjusted=ameind/aian_repres_factor 

**multi 
replace multi_adjusted=multi/mult_repres_factor 

//next we have to ensure that the rowtotal of all the race probabilities add up to 1 

*first checking what the rowtotal is 
gen rowtotal=hispanic_adjusted + white_adjusted + black_adjusted + api_adjusted + ameind_adjusted + multi_adjusted 

**adjusted to add to 1 
foreach var of varlist *adjusted {
	gen `var'_corrected=`var'/rowtotal
}

**checking adjustment 
gen rowtotal2=hispanic_adjusted_corrected + white_adjusted_corrected + black_adjusted_corrected + api_adjusted_corrected + ameind_adjusted_corrected + multi_adjusted_corrected

sum rowtotal2 //there are still some at .99999 is this a rounding thing? 

**keep new corrected probabilities
keep name *corrected 

**renaming variables for ease of interpretation later 
rename hispanic_adjusted_corrected hispanic 
rename white_adjusted_corrected white 
rename black_adjusted_corrected black 
rename api_adjusted_corrected api 
rename ameind_adjusted_corrected aian 
rename multi_adjusted_corrected multi
rename name firstname 

**ordering variables to make excel match easier 
order firstname white black hispanic api aian multi

//saving file 
save "$data\rosenman_first_corrected.dta", replace


//appending these files together ONLY if name doesn't appear in Tzoumis use the name from the voter registration list b/c we are not as confident in the other probabilities--is this correct? 


/*=====================================================================================
Surname File--Census 
--------------------------------------------------------------------------------------
Bringing in RAND surname file to stata 
cleaning if necessary 
exporting to excel sheet to compute matches 
=======================================================================================*/ 
import sas using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\BISG data\surname_yes_2000_2010_final2.sas7bdat", clear

//checking for unicode characters 
foreach letter in "á" "é" "í" "ó" "ú" "Á" "É" "Í" "Ó" "Ú" {
	di "`letter'"
	list NAME if strpos(NAME, "`letter'") > 0
}

//renaming variables 
rename pctw_fin white 
rename pctb_fin black 
rename pctapi_fin api 
rename pctaian_fin aian 
rename pct2r_fin multi 
rename pcth_fin hispanic 
rename NAME lastname

//ordering variables 
order lastname white black hispanic api aian multi  

//we can drop the column 2000 which tells us what year the data was matched from--I need to double check this 
drop _2000

//saving file for census surname data 
save "$data\census_surname.dta", replace 

/*=====================================================================================
Rosenman et al. (2023) Voter Registration Surname File 
--------------------------------------------------------------------------------------
Bringing in Rosenman surname file to stata 
cleaning if necessary 
correction of probabilities 
saving corrected probabilty file 
=======================================================================================*/ 
import delimited "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\BISG data\dataverse_files\last_nameRaceProbs.csv", clear //probability of race|last name 

//renaming variables 
rename whi white 
rename bla black 
rename his hispanic 
rename asi api 

//creating ameind and other categories using one other category--we decided to split these probabilities in half between the two 
gen ameind=oth/2
gen multi=oth/2 

/***************************************************************************************
Step 2: Create the race representation factor variables 
****************************************************************************************/
//appending census race percentages 
append using "$data\race_per.dta"

//dropping hmda race percentages 
drop *hmda 

// Creating pop probabilities for each row 
// Pop probabilities are from 2015-2019 ACS census
gen aian_pop_prob = per_ameind_census[_N]
gen aapi_pop_prob = per_api_census[_N]
gen blck_pop_prob = per_black_census[_N]
gen hisp_pop_prob = per_hisp_census[_N]
gen whit_pop_prob = per_white_census[_N]
gen mult_pop_prob = per_multi_census[_N]

// Sample probabilities are those from the Voter registration name database (Table 1 Rosenman et al. 2023)
gen aian_sampl_prob = (1.9/2) //dividing other category by 2 
gen aapi_sampl_prob = 1.6
gen blck_sampl_prob = 21.8
gen hisp_sampl_prob = 7.9
gen whit_sampl_prob = 62.8
gen mult_sampl_prob = (1.9/2) //dividing other category by 2 

//dropping extra row from appended dataset 
drop if data=="race_probabilities" 

// Adjust probabilities to proportion of 1
foreach race in aian aapi blck hisp whit mult {
	di "`race'"
	replace `race'_pop_prob = `race'_pop_prob / 100
	replace `race'_sampl_prob = `race'_sampl_prob / 100
}

// Generate representation factors to generate frequencies in the sample
foreach race in aian aapi blck hisp whit mult {
	gen `race'_repres_factor = `race'_sampl_prob / `race'_pop_prob
	tab `race'_repres_factor
}

//generating new variables for the adjusted probabilities 
foreach var of varlist white black hispanic api ameind multi {
	gen `var'_adjusted=. 
}

//calculating the adjustment for each race individually 

**white 
replace white_adjusted=white/whit_repres_factor

**black 
replace black_adjusted=black/blck_repres_factor 

**hispanic 
replace hispanic_adjusted=hispanic/hisp_repres_factor

**api 
replace api_adjusted=api/aapi_repres_factor 

**aian 
replace ameind_adjusted=ameind/aian_repres_factor 

**multi 
replace multi_adjusted=multi/mult_repres_factor 

//next we have to ensure that the rowtotal of all the race probabilities add up to 1 

*first checking what the rowtotal is 
gen rowtotal=hispanic_adjusted + white_adjusted + black_adjusted + api_adjusted + ameind_adjusted + multi_adjusted 

**adjusted to add to 1 
foreach var of varlist *adjusted {
	gen `var'_corrected=`var'/rowtotal
}

**checking adjustment 
gen rowtotal2=hispanic_adjusted_corrected + white_adjusted_corrected + black_adjusted_corrected + api_adjusted_corrected + ameind_adjusted_corrected + multi_adjusted_corrected

sum rowtotal2 //there are still some at .99999 this is a rounding thing

**keep new corrected probabilities
keep name *corrected 

**renaming variables for ease of interpretation later 
rename hispanic_adjusted_corrected hispanic 
rename white_adjusted_corrected white 
rename black_adjusted_corrected black 
rename api_adjusted_corrected api 
rename ameind_adjusted_corrected aian 
rename multi_adjusted_corrected multi
rename name lastname 

**ordering variables to make excel match easier 
order lastname white black hispanic api aian multi

**saving file 
save "$data\rosenman_last_corrected.dta", replace 

/**if loop works  
save "$data\"`file'"_corrected.dta", replace
} */

/*=====================================================================================
Creating comprehensive first name list 
--------------------------------------------------------------------------------------
starting with Tzoumis list merge in Rosenman first name files	
	- keep Tzoumis names 
	- if match both files, keep Tzoumis 
	- only keep Rosenman names/probabilities if they are additional to Tzoumis list
=======================================================================================*/ 
use "$data\Tzoumis_corrected.dta", clear  

//renaming variables so after merge we know which ones are tzoumis 
foreach var of varlist white-multi {
	rename `var' Tzoumis_`var'
}

//merging in Rosenman files 
merge 1:1 firstname using "$data\rosenman_first_corrected.dta"

/*
//renaming Rosenman variables 
foreach var of varlist white-multi {
	rename `var' Rosenman_`var'
}

//generating new race probabilities 
foreach race in white black hispanic api aian multi {
	gen `race'=. 
}
*/

//replacing values correctly 
foreach var of varlist white-multi {	
	replace `var'=Tzoumis_`var' if _merge==1 | _merge==3 //if in Tzoumis 
}

//renaming merge to know match dataset 
gen data_source="."  
replace data_source="Tzoumis" if _merge==1 | _merge==3
replace data_source="Rosenman" if _merge==2

//checking all other first names
br if firstname=="ALL OTHER FIRST NAMES" | firstname=="ALL OTHER NAMES" //keeping Tzoumis values 
drop if firstname=="ALL OTHER NAMES"

//moving this to the last line of the list
replace firstname="ZZ-ALL OTHER FIRST NAMES" if firstname=="ALL OTHER FIRST NAMES"
sort firstname 

replace firstname="ALL OTHER FIRST NAMES" if firstname=="ZZ-ALL OTHER FIRST NAMES"

//keeping only variables we need 
keep firstname white-multi data_source 

//saving data 
save "$data\firstname_prob_complete.dta", replace //this is the list we will use to match 

//putting in excel 
export excel using "$data\name_race_probabilities", sheet("race_firstname", replace) firstrow(variables)

use "$data\firstname_prob_complete.dta", clear 
/*=====================================================================================
Creating comprehensive last name list 
--------------------------------------------------------------------------------------
starting with Census list merge in Rosenman last name files	
	- keep Cenus names 
	- if match both files, keep Census 
	- only keep Rosenman names/probabilities if they are additional to Census list
=======================================================================================*/ 
use "$data\census_surname.dta", clear 

//renaming variables so after merge we know which ones are census 
foreach var of varlist white-multi {
	rename `var' census_`var'
}

//merging with Rosenman list 
merge 1:1 lastname using "$data\rosenman_last_corrected.dta"

//replacing probabilities to keep census probabilities for last names. Only using Rosenman probabilities if the name did not exist in the Census
foreach var of varlist white-multi {
replace `var'=census_`var' if _merge==1 | _merge==3 
}

//renaming merge to know match dataset 
gen data_source="."  
replace data_source="Census" if _merge==1 | _merge==3
replace data_source="Rosenman" if _merge==2

//keeping only relevant variables 
keep lastname white-multi data_source 

//moving this to the last line of the list
replace lastname="ZZ-ALL OTHER NAMES" if lastname=="ALL OTHER NAMES"
sort lastname 

replace lastname="ALL OTHER NAMES" if lastname=="ZZ-ALL OTHER NAMES"


//saving data 
save "$data\lastname_prob_complete.dta", replace 

//putting in excel 
export excel using "$data\name_race_probabilities", sheet("race_lastname", replace) firstrow(variables)


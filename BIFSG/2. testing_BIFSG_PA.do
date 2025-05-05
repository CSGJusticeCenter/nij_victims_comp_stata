/*============================================================================================
Program Author: Shradha Sahani 
Start Date: June 26, 2024
Last Updated: June 26, 2024

Program Description: Testing the BIFSG estimates from PA 

Objective: We asked PA to use the BIFSG spreadsheet for all claims where the claimants  
race/ethnicity was missing and also to use it for a random sample of 10,000 claims where 
race/ethnicity were reported. We are now going to test our estimates against this sample of 
claims with reported race/ethnicty. We will test the calibration and discrimination of our 
estimates in PA. 

 

Explanation: 
 (1) calibration---the agreement between a model's predicted outcome and observed 
 outcomes. With a well-calibrated prediction algorithm, the means for the six
 sets of race and ethnicity probabilities closely match the means of the self-reported
 race and ethnicity. We will examine the calibration both overall and within strata
 defined by categories of enrollee characteristics such as age and gender. We will also
 check the calibration by match_level (which geography level was used).
 
 
 (2) discrimination---the ability to differentiate between groups. An algorithm that
 differentiates well will produce a higher probability for individuals who are in 
 a racial and ethnic group than for individuals who are not in that group. We will use
 the C-statistic to test this, which is derived from an area under the curve (AUC) 
 analysis. To do this, we fit six separate logistic regression models--one for each
 racial and ethnic group--in which each dependent variable is a binary indicator for 
 the specific racial/ethnic group versus all other groups and the independent variable
 is the race and ethnicity probability for that group. We can calculate a C-statistic 
 for each racial and ethnic group as well as an overall C-statistic using a weighted 
 average of the group-specific C-statistics where the weights are proportional to the 
 number of enrollees in each group. Recommend assessing discrimination both overall and 
 within strata defined by enrollee age, gender, or other enrollee characteristics. We will 
 also check discrimination by match_level (which geography level was used).
	Acceptable==0.7 
	Strong=0.8
	Excellent>=0.9
	
Input files: 
--PA compensation data raw---$clean\PA_comp_w_census_dummy_for_Shradha_20230915.csv
--PA BIFSG estimates--$raw\Output_RO.xlsx

Output files:
"$analysis\\${state_abbrev}_claims_sample_observed_and_imputed_${adjustment_type}.dta"
This file contains the imputed BIFSG data merged with the self-reported data. 

==============================================================================================*/
clear 
set more off 

// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY-NN-DD date("$S_DATE","DMY")
display "$S_DATE" 
display "$out_date" // to check that current date and out_date are the same
global log_dir "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata\logs"

cap log close
cd "$log_dir"
log using "testing_BIFSG_PA_$out_date.smlc", append

/*=====================================================================================
Define the names of the datasets to use
--------------------------------------------------------------------------------------
=======================================================================================*/ 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data" 

global raw="$dir\Raw\2. Phase 2 State\PA\PA BIFSG" //directory for raw data files
global clean="$dir\Clean\Ad Hoc" //directory for clean data files 
global analysis="$dir\Analysis\Phase 2 State\PA Compensation Data" //directory for analysis data files 


cd "$dir" //setting directory 

//set the choices for state and data type
global state_abbrev "PA"
global adjustment_type "adjusted" // either "adjusted" or "unadjusted"

/*=====================================================================================
Step 1: Merge BIFSG list with claims data
--------------------------------------------------------------------------------------
Notes: We will only keep those claims that had race/ethnicty already reported to run 
diagnostics 
=======================================================================================*/ 


/*=====================================================================================
Merging data for self-reported race and the BIFSG probabilities 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//starting with the raw dataset that has self-reported race 
//import delimited "$clean\PA_comp_w_census_dummy_for_Shradha_20230915.csv"
use "$analysis\\${state_abbrev}_comp_clean.dta"

//generating individual race variables 
//first create a list of the races
global races "api ameind black hisp multi_alone other white"


//recode victim_race to match the same race variable names used in the BIFSG imputed file 
//generating categorial race because we'll need this later 
gen race=""
replace race="ameind" if ameind==1
replace race="api" if api==1
replace race="black" if black==1
replace race="hisp" if hisp==1
replace race="other" if other==1
replace race="white" if white==1
tab race

//checking variables 
sum victim_race ameind-white 



//generating age categories 
gen age_cat=. 
replace age_cat=1 if age<18 
replace age_cat=2 if age>=18 & age<25 
replace age_cat=3 if age>=25 & age<35 
replace age_cat=4 if age>=35 & age<45 
replace age_cat=5 if age>=45 & age<55
replace age_cat=6 if age>=55 & age<65 
replace age_cat=7 if age>=65

//label age categories
label define age 1 "<18" 2 "18-24" 3 "25-34" 4 "35-44" 5 "45-54" 6 "55-64" 7 ">=65"
label values age_cat age

//decode age_cat for later use in loops
decode age_cat, gen(age_cat_str)

//label the variables
label var age "Age at year end"
label var gender "Gender"


//rename other variable 
rename other multi 

// convert to string to ensure a correct match
tostring claim_number, replace

//identify and remove duplicates
duplicates tag claim_number, generate(dup)
drop if dup > 0
drop dup

//save as tempfile to then merge with BIFSG probabilities later 
tempfile reported_race_dataset 
save `reported_race_dataset'

//bringing in BIFSG probabilities
clear

import excel using "$raw\Output_RO.xlsx", firstrow

//rename case_id and convert to string to ensure a correct match
tostring claim_number, replace

//identify and remove duplicates
duplicates tag claim_number, generate(dup)
drop if dup > 0
drop dup

//rename if using the old version of variable names for the probabilities
capture rename aipi_prob api_prob
capture rename aaan_prob ameind_prob
capture rename balck_prob black_prob
capture rename whit_prob white_prob
capture rename mixed_prob multi_prob

//merging with self-reported race data 
merge 1:1 claim_number using "`reported_race_dataset'" 

//label variables
label var api_prob "Est. Asian, Pacific Islander, or Native Hawaiian"
label var ameind_prob "Est.  American Indian or Alaska Native"
label var black_prob "Est. Black or African American"
label var hisp_prob "Est. Hispanic or Latino"
label var white_prob "Est. White"
label var multi_prob "Est. Two or more races (not Hispanic or Latino) or some other race"

//generating indicator for match_level 
encode match_level, gen(match_level_enc)
encode match_type, gen(match_type_enc)

//save merged file
save "$analysis\\${state_abbrev}_claims_sample_observed_and_imputed_${adjustment_type}.dta", replace


/*=====================================================================================
Calibration
--------------------------------------------------------------------------------------
comparing means of self-reported race/ethnicity and race/ethnicity probabilities. These should 
closely match
=======================================================================================*/ 
use "$analysis\\${state_abbrev}_claims_sample_observed_and_imputed_${adjustment_type}.dta", clear


//drop not matched cases
drop if match_level == "No match"

//drop cases with no reported race data, this will drop any observations in the PA claims data that don't have self reported race 
drop if race==""

//BIFSG calculation was only completed on a subset of those claims with reported race so we need to restrict the test to just these claims 
keep if _merge==3 // those that did not match are those that had reported race but were not tested in the BIFSG 

//Note: We asked Robert to use a random sample of 10,000 claims with reported race but the sample size is only 9,352 after dropping those that didn't have reported race and weren't in both the BIFSG imputed dataset and the original dataset 



/******OVERALL CALIBRATION***************/

//create a global for the race variables
global race_vars api ameind black hisp multi white 

noi di as error "Observed and estimated percentages"

//compare means between self-reported and probabilities--check variable names  
noi di as error "Means by race"
foreach var of varlist $race_vars {
	sum `var'
	local `var'_mean : display %5.3f r(mean)
	sum `var'_prob
	local `var'_prob_mean : display %5.3f r(mean)
	noi di as txt "`var' obs. and est. means: " ``var'_mean' " " ``var'_prob_mean'
	*noi di "`var' estimated mean: " ``var'_prob_mean'
}

//Notes: Black is slightly underestimated and White is overestimated (~5/6% differences). The rest are slightly different but ~ <=1% differences in observed and estimated means 

/******SUBGROUP CALIBRATION***************/
*by enrollee characteristics such as age and gender 


//compare means between self-reported and probabilities by gender 
noi di as error "Means by gender and race"
foreach var of varlist $race_vars {
	foreach gender_cat in "Male" "Female" {
		sum `var' if gender == "`gender_cat'"
		local `var'_mean : display %5.3f r(mean)
		sum `var'_prob if gender == "`gender_cat'"
		local `var'_prob_mean : display %5.3f r(mean)
		noi di as txt "`var' `gender_cat' obs. and est. means: " ``var'_mean' " " ``var'_prob_mean'
	}
}

//Notes: Black men are underestimated by ~8% but Black women are underestimated by ~3% . Hispanic men and Women are ~1% overestimated compared to the observed. White men are ~6% overestimated and White females ~2% 

//compare means between self-reported and probabilities by age  
noi di as error "Means by age group and race"
// global list of age groups
global age_groups "<18 18-24 25-34 35-44 45-54 55-64 >=65"
foreach var of varlist $race_vars {
	foreach age_group in $age_groups {
		qui sum `var' if age_cat_str == "`age_group'"
		qui local `var'_mean : display %5.3f r(mean)
		qui sum `var'_prob if age_cat_str == "`age_group'"
		qui local `var'_prob_mean : display %5.3f r(mean)
		noi di as txt "`var' ages `age_group' obs. and est. means: " ``var'_mean' " " ``var'_prob_mean'
	}
}

//Notes: Black people at all ages are underestimated, Whites are overestimated in all age categories except over 65

//compare means by match_level
noi di as error "Means by match level and race"
foreach match_level in "Block group" "No match" "Tract" "Zip" {
	noi di "`match_level'"
	foreach var of varlist $race_vars {
		qui sum `var' if match_level == "`match_level'"
		qui local `var'_mean : display %5.3f r(mean)
		qui sum `var'_prob if match_level == "`match_level'"
		qui local `var'_prob_mean : display %5.3f r(mean)
		noi di as txt "`var' `match_level' match obs. and est. means: " ``var'_mean' " " ``var'_prob_mean'
	}
}

//Notes: all claims were matched at the zip level 
/*=====================================================================================
Discrimination
--------------------------------------------------------------------------------------
logistic regression predicting each of 6 race/ethnicities by p(race)
=======================================================================================*/ 

/******DISCRIMINATION FOR EACH RACE/ETHNICITY CATEGORY AND OVERALL***************/
*overall C-statistic using a weighted average of the group-specific C-statistics where the weights are proportional to the number of enrollees in each group

//Calculate the weight for each group, proportional to the number of enrollees
foreach var of varlist $race_vars {
	gen weight_`var' = .
	egen group_count = count(`var') if `var' == 1
	replace weight_`var' = group_count/_N //total number in each group divided by the total number of observations 
	drop group_count
}

noi di as error "Area under curve"
local weighted_avg_cstat = 0
foreach var of varlist $race_vars {
	//first each race's cstat
	qui logit `var' `var'_prob
	qui lroc // calculates the area under the curve for logistic regressions 
	local `var'_num r(N) //storing number of observations
	local `var'_cstat r(area) //storing auc/cstat--these are the same
	local `var'_cstat_displ : display %5.3f r(area) //storing in displayable format
	noi di as txt "`var' AUC: " ``var'_cstat_displ'
	//now the weighted cstat
	gsort -`var' //sort reversed to capture the weight of the first one
	local weight = weight_`var'[1]
	local weighted_avg_cstat =  r(area) * `weight' + `weighted_avg_cstat'
	//display overall c-statistic 
}
noi di as txt "Weighted average C-statistic: " `weighted_avg_cstat'

/*
api AUC: .954
ameind AUC: .503
black AUC: .956
hisp AUC: .961
multi AUC: .605
white AUC: .953
*/

/******DISCRIMINATION FOR EACH RACE/ETHNICITY CATEGORY WITHIN SUBGROUP***************/

//create a global with the races as strings
global race_strings "api ameind black hisp multi white"

//gender 
noi di as error "Discrimination by race and gender"
foreach race in $race_strings {
	di "`race'" 
	foreach gender in "Male" "Female" {
		qui logit `race' `race'_prob if gender=="`gender'"
		qui lroc 
		qui local cstat_displ : display %5.3f r(area)
		noi di as txt "AUC for `race' and gender `gender': " `cstat_displ'
	}
}

/*
api
AUC for api and gender Male: .97
AUC for api and gender Female: .935
ameind
AUC for ameind and gender Male: .544
AUC for ameind and gender Female: .5
black
AUC for black and gender Male: .955
AUC for black and gender Female: .959
hisp
AUC for hisp and gender Male: .965
AUC for hisp and gender Female: .955
multi
AUC for multi and gender Male: .672
AUC for multi and gender Female: .556
white
AUC for white and gender Male: .954
AUC for white and gender Female: .951
*/


//age
noi di as error "Discrimination by race and age group"
foreach race in $race_strings {
	di "`race'"
	foreach age_group in $age_groups {
		qui capture logit `race' `race'_prob if age_cat_str=="`age_group'" // capture
			// needed because there might not be obs. for <18
		qui capture lroc 
		qui local cstat_displ : display %5.3f r(area)
		noi di as txt "AUC for `race' and age `age_group': " `cstat_displ'
	}
}


/* didn't run this code becasuse everything is matched at the zip code so this should be the same as the overall


//match_level 
noi di as error "Discrimination by match level and race"
foreach match_level in "Block group" "Tract" "Zip" {
	di "`match_level'"
	foreach race in $race_strings {
		capture logit `race' `race'_prob if match_level=="`match_level'" // capture
			// needed because there might not be obs. for some levels
		capture lroc 
		local cstat_displ : display %5.3f r(area)
		noi di as txt "AUC for `race' and match `match_level': " `cstat_displ'
	}
}
*/


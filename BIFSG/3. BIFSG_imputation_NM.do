/*=====================================================================================
Program Author: Shradha Sahani
Start Date: January 2, 2025
Last Updated: January 2, 2025


Program Description: Imputation using BIFSG estimates for NM.   

Input:
	- BIFSG estimates from NM. Files created in testing_BIFSG_NM.do 
	
Output:
	- imputed race data from BIFSG estimates 
=====================================================================================*/

clear 
set more off 

// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY-NN-DD date("$S_DATE","DMY")
display "$S_DATE" 
display "$out_date" // to check that current date and out_date are the same
global log_dir "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata\logs"

cap log close
cd "$log_dir"
log using "imputation_BIFSG_NM_$out_date.smlc", append



/*=====================================================================================
Define the names of the datasets to use
--------------------------------------------------------------------------------------
=======================================================================================*/ 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data" 

global raw="$dir\Raw\2. Phase 2 State\NM\NM BIFSG" //directory for raw data files
global clean="$dir\Clean\Ad Hoc" //directory for clean data files 
global analysis="$dir\Analysis\Phase 2 State\NM Compensation Data" //directory for analysis data files 


cd "$dir" //setting directory 


/*=====================================================================================
Step 1: Importing BIFSG data
--------------------------------------------------------------------------------------
=======================================================================================*/ 


use "$analysis\NM_claims_sample_observed_and_imputed_adjusted.dta"

/*=====================================================================================
Step 1: Imputing race from BIFSG estimates
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//recoding race 
encode race, gen(race_code)
label list 


* Note: Edit the numbers in step (2) 'replace' lines to match the corresponding race
// 1. Set the number of datasets
local num_datasets = 100

// 2. Loop over the number of datasets
forval i = 1/`num_datasets' {
    
    // Generate a random number for each observation (between 0 and 1)
    gen rand = runiform()

    // Create a variable for the imputed race assignment
    gen race_assign = .

    // Assign race based on cumulative probabilities
    replace race_assign = 6 if rand <= white_prob //white
    replace race_assign = 3 if rand > white_prob & rand <= (white_prob + black_prob) //black
    replace race_assign = 4 if rand > (white_prob + black_prob) & rand <= (white_prob + black_prob + hisp_prob) //hispanic
    replace race_assign = 2 if rand > (white_prob + black_prob + hisp_prob) & rand <= (white_prob + black_prob + hisp_prob + api_prob) //api
    replace race_assign = 1 if rand > (white_prob + black_prob + hisp_prob + api_prob) & rand <= (white_prob + black_prob + hisp_prob + api_prob + ameind_prob) //ameind
    replace race_assign = 5 if rand > (white_prob + black_prob + hisp_prob + api_prob + ameind_prob) //other

    // Combine race and imputed race (race_assign) to create race_w_imp
    gen race_w_imp = race_code  // Start by setting race_w_imp to the observed race
    replace race_w_imp = race_assign if missing(race_code)  // Use imputed race only when race is missing

    // Save the dataset for this iteration
    save "$analysis\dataset_`i'.dta", replace

    // Drop the random variable before the next iteration to avoid interference
    drop rand race_assign race_w_imp
}


// 3. Combine the datasets into one stacked dataset
clear
use "$analysis\NM_claims_sample_observed_and_imputed_adjusted.dta", clear //starting with the original dataset and then adding imputed datasets to this 
gen _mi_m = 0  // Create imputation index

local num_datasets = 100

forval i = 1/`num_datasets' {
    append using "$analysis\dataset_`i'.dta"
    replace _mi_m = `i' if missing(_mi_m)
}

tab _mi_m

/*

// 3. Combine the datasets into one stacked dataset
clear
use "$analysis\dataset_1.dta", clear
gen _mi_m = 1  // Create imputation index

local num_datasets = 100

forval i = 2/`num_datasets' {
    append using "$analysis\dataset_`i'.dta"
    replace _mi_m = `i' if missing(_mi_m)
}
*/

// Save the combined dataset
drop _merge 

//label race variable 
label define race_cat 1 "ameind" 2 "api" 3 "black" 4 "hipanic" 5 "other" 6 "white"
label values race_w_imp race_cat 

save "$raw\NM_BIFSG_imputed_data.dta", replace

log close 

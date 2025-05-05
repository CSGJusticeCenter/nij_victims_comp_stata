/*=====================================================================================
Program Author: Shradha Sahani
Start Date: February 11, 2025 
Last Updated: February 11, 2025 


Program Description: Main do file for cleaning compensation data and then conducting the 
BIFSG imputation and following analysis. 

Install these programs if not already installed on your machine. 
//install mivif to check vif statistics after mi estimate 
ssc install mivif
ssc install mimrgns //average marginal effects after multiple imputation 
ssc install misum //summary statistics after mi 
=====================================================================================*/


/*=====================================================================================
Set the choices and start a log
--------------------------------------------------------------------------------------
=======================================================================================*/ 
clear 
set more off 

// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY_NN_DD date("$S_DATE", "DMY")

// Check the dates are correct
display "$S_DATE"
display "$out_date"

// Define the log directory
global log_dir "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\Victim Compensation\logs"
cap log close

// Change to the log directory
cd "$log_dir"
log using "claims_imputed_analysis_$out_date.smcl", append


/*=====================================================================================
Define the names of the datasets to use
--------------------------------------------------------------------------------------
=======================================================================================*/ 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp" 

global data="$dir\data\Raw\2.Phase 2 State" //directory for data files
global PA="$dir\data\Raw\2.Phase 2 State\PA" //directory for PA data files
global NM="$dir\data\Raw\2.Phase 2 State\NM" //directory for NM data files

global analysis="$dir\data\Analysis\Phase 2 State" //directory for analysis files 
global clean="$dir\data\Clean" //directory for clean files 
global code="$dir\code\Victim Compensation"
global raw="$dir\Raw\data\2. Phase 2 State\PA\PA BIFSG" //directory for raw data files
global bifsg="$dir\code\BIFSG\BIFSG Stata"
cd "$dir" //setting directory 


//set the choices for state and 
global state_abbrev "PA" //PA or  NM 

/*=====================================================================================
Cleaning Compensation data 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//this file creates a state_comp_clean file that we will use in the rest of the files. 

do "$code\1. Cleaning $state_abbrev comp data.do"

//CLEANING/PREPPING COUNTY DATA//

/*=====================================================================================
Testing BIFSG estimates 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//this do file tests the BIFSG imputation against the self-reported race/ethnicities in each state 

//we also need to run this again before any of the analysis because it creates the file for the imputation 

do "$bifsg\2. testing_BIFSG_$state_abbrev.do"


/*=====================================================================================
BIFSG imputation 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//this do file executes the imputation using the BIFSG estimates for each state 

do "$bifsg\3. BIFSG_imputation_$state_abbrev.do"

/*=====================================================================================
Cleaning data after imputation 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
do "$code\4. Preparing $state_abbrev comp data after imputation.do"



/*=====================================================================================
State Presentation analysis 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
do "$code\5. ${state_abbrev}_presentation_analysis.do"


/*=====================================================================================
Claims analysis 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

do "claims_analysis_main.do" //make sure the global in this file for the state is turned off if running from this main.do 

do "$code\claims_analysis_${state_abbrev}.do"


/*=====================================================================================
County analysis 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
 
 do "county_analysis_main.do"  //make sure the global in this file for the state is turned off if running from this main.do 
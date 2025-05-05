/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 1, 2024
Last Updated: April 3, 2025


Program Description: Main do file for County level analysis of NM and PA claims data. 
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
log using "county_analysis_$out_date.smcl", append

//set color scheme 
set scheme csgjc_jri_colors


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
global code_directory="$dir\code\Victim Compensation"

cd "$dir" //setting directory 

global state_abbrev "PA" //PA or  NM 


/*=====================================================================================
Cleaning County data 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//cleaning census data on urban population and creating measure to merge with county data 
do "$code\county_urban_pop_cleaning"

do "$code\${state_abbrev}_cleaning_county_data.do"


/*=====================================================================================
County regressions  
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//old version 
//this version is where I tested different models and we made decisions about the final models and inclusion of variables. 
do "$code\county level regressions_${state_abbrev}.do" 

//updated version 
//this version includes the final models with all the assumption checks and regression output exported to word. 
do "$code\county level regressions_${state_abbrev}_updated.do"



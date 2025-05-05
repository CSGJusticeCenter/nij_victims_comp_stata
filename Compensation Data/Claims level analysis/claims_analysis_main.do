/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 28, 2024
Last Updated: February 24, 2025


Program Description: Main file for Claims level analysis of PA data. 

Input:
	- PA claims data imputed and cleaned for imputation 	
	
Output:
	- regressions

	
//install mivif to check vif statistics after mi estimate 
ssc install mivif
ssc install mimrgns //average marginal effects after multiple imputation 
ssc install misum //summary statistics after mi 
ssc install outreg2 
** SEBA: outreg2. Requirements should be listed to be installed.
=====================================================================================*/
ssc install mivif
ssc install mimrgns //average marginal effects after multiple imputation 
ssc install misum //summary statistics after mi 
ssc install outreg2

clear 
set more off 
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
global raw="$dir\Raw\data\2. Phase 2 State\PA\PA BIFSG" //directory for raw data files

cd "$dir" //setting directory 

//don't need this if running from main.do 
global state_abbrev "PA" //PA or  NM 

/*=====================================================================================
Setting Data for multiple imputation 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

do "$code\${state_abbrev}_setting_data_for_analysis.do"

/*=====================================================================================
claims analysis 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//this is the old version of the file where I tested different regressions. There may be some problems running this file so use the updated file instead. I am listing this here for reference. 
//do "$code\claims_analysis_${state_abbrev}.do"

do "$code\claims_analysis_${state_abbrev}_updated.do"




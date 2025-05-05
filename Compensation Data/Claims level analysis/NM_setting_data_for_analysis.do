/*=====================================================================================
Program Author: Shradha Sahani
Start Date: January 2, 2024
Last Updated: January 6, 2024 


Program Description: Claims level analysis of NM data. 

Input:
	- NM claims data 
	- NM neighborhood census data 
	
	
Output:
	- regressions

	
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
log using "NM_setting_data_for_analysis_$out_date.smcl", append



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
global raw="$dir\data\Raw\2. Phase 2 State\NM\NM BIFSG" //directory for raw data files

cd "$dir" //setting directory 


/*========================================================================================
Setting data for multiple imputation 
=========================================================================================*/
use "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_cleanedforanalysis.dta", clear  


duplicates list imp_num claim_number //id duplicates 

//Declare the data as multiply imputed
mi import flong, m(imp_num) id(claim_number)


//Register the imputed variables and the regular (non-imputed) variables
mi register imputed race_w_imp mi_near_prov
mi register regular age crime_homicide crime_sex_assualt pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty approved den_fail_info num_service_providers num_providers_per1000 lost_wages_exp //register regular all variables for analyses that were not imputed--days_decision  amount_paid payment_expense_types

//checking imported mi data 
mi describe 

//other dependent variables 

//summary statistics 
mi rename pct_renter_occupied_housing_unit pct_rent_occ 
mi rename pct_vacant_housing_units pct_vac_hous
mi rename pct_unemployed_over_16 pct_unemployed

//mi xeq: summarize approved den_fail_info ib6.race_w_imp age male crime_homicide crime_sex_assualt pct_vac_hous pct_rent_occ pct_unemployed pct_below_poverty num_service_providers



//major city 
gen large_city=0 
replace large_city=1 if inlist(victim_city, "Farmington", "Rio Rancho", "Santa Fe", "Albuquerque")


//combine api and other and rerun models 
tab race_w_imp, gen(race_)
sum race_* if imp_num==1
gen other_api=0 
replace other_api=1 if race_2==1 | race_5==1


gen mi_near_prov2 = mi_near_prov * mi_near_prov 
gen log_mi_near_prov = log10(mi_near_prov2 + .01) //.01 added to avoid log10(0) missing.
label var log_mi_near_prov "Miles from nearest VSP to victim's zip code logged"
sort _mi_m victim_zip // since we had resorted
// Check if log or square distance is better
corr mi_near_prov2 approved
corr log_mi_near_prov approved // Both are small, but log is better. It also makes more sense, since each additional mile likely has less of an effect than the previous one, but square function would be better if it's more of an effect.


//label variables
label variable age "Age"
label variable male "Male"
label variable crime_homicide "Homicide Victimization"
label variable crime_sex_assualt "Sexual Assault Victimization"
label variable crime_dom_assault "Domestic Violence Victimization"
label variable pct_below_poverty "Neighborhood % below poverty"
label variable mi_near_prov "Distance to Nearest Service Prover (in miles)"

label define race_var 1 "American Indian" 2 "Asian & Pacific Islander" 3 "Black" 4 "Hispanic" 5 "Other" 6 "White"
label values race_w_imp race_var 

label variable race_1 "American Indian"
label variable race_3 "Black"
label variable race_4 "Hispanic"
label variable race_6 "White"
label variable other_api "Asian & Pacific Islander or Other"


save "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_foranalysis_updated.dta", replace  


/****************************************************************************************
Summary Statistics 
=========================================================================================
*****************************************************************************************/
use "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_foranalysis_updated.dta", clear  

//checking race distribution before and after imputation 
	
//race_w_imp 
preserve 
	tab race_w_imp, gen(race_imp_dummy)

	drop ameind api black hisp other white //drop old race vars without imputation 

	rename race_imp_dummy1 ameind 
	rename race_imp_dummy2 api 
	rename race_imp_dummy3 black 
	rename race_imp_dummy4 hispanic 
	rename race_imp_dummy5 other 
	rename race_imp_dummy6 white 

	sum ameind-white if imp_num!=0 //only looking at the summary statistics for the imputated 100 datasets and not including the original one with missing data 
	qui outreg2 using "$analysis\NM Compensation Data\race_distribution_afterimputation_NM.doc", sum (log) keep(ameind-white) replace 
restore 

//data before imputation 
use "$analysis\NM Compensation Data\NM_comp_clean.dta", clear 
    
//approval rate 
sum ameind-other 

qui outreg2 using "$analysis\NM Compensation Data\race_distribution_raw_NM.doc", sum (log) keep(ameind-other) replace 


log close 
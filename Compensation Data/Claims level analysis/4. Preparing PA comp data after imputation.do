/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 28, 2024
Last Updated: october 28, 2024 


Program Description: Cleaning claims data in PA after BIFSG imputation and getting ready
for analysis. 

Input:
	- PA claims data after imputation $analysis\PA Compensation Data\PA_BIFSG_imputed_data.dta
	- BJS Victim Service Providers Data 
		BJS_Victim_service_providers.csv 
		PA_zip_distance_nearest_provider.dta
	
	
Output:
	- cleaned data file 
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
log using "preparing_PA_comp_data_after_impuation_$out_date.smcl", append


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


/*=========================================================================================
Claims level regressions in PA 
=========================================================================================

Models 
	1. DV--Aproval rate, denial outcomes (failure to supply information, time to approval)
		neighborhood variables--disadvantage, urban, number of service providers 
		individual variables--race, age, sex, crime type 
		
		
		IV--structural disadvantage, residential instability, racial 
composition, access to service providers, % foreign born
=========================================================================================*/


/*=========================================================================================
Generating individual level clean data files 
=========================================================================================*/

//PA
use "$analysis\PA Compensation Data\PA_BIFSG_imputed_data.dta", clear


//keeping only PA victims 
keep if victim_state=="PA"




//recoding victim_zip
gen non_numeric = regexm(victim_zip, "[^0-9]") // Identifies non-numeric characters
list victim_zip if non_numeric == 1
replace victim_zip="." if non_numeric==1 
destring victim_zip, replace 

//renaming for mi importing
tab _mi_m
rename _mi_m imp_num 


/* should already be created 
//recoding denial due to failure to supply information 
tab claim_disposition if imp_num==1
gen den_fail_info=0
replace den_fail_info=1 if inlist(claim_disposition, "Failure to supply info. from victim/claimant", "Failure to supply info. from provider", "Failure to supply info from provider", "Failure to supply signature page", "Failure of provider to supply FRE bills") 
label variable den_fail_info "Denial due to failure to provide info."
tab claim_disposition if imp_num==1
tab den_fail_info if imp_num==1 //checking recoding 
*/


//time to decision//
*recoding claim date 
tab claim_date if imp_num==1
gen claim_date2 = date(substr(claim_date, 1, 10), "YMD")
format claim_date2 %td  
tab claim_date2 if imp_num==1, m 

*recoding decision date 
tab original_decision_date if imp_num==1 
gen decision_date = date(substr(original_decision_date, 1, 10), "YMD")
format decision_date %td  
tab decision_date if imp_num==1, m 

//checking claims without a decision date
tab claim_status if decision_date==. & imp_num==1 // 43% are denied claims, 57% are Open-Verification-In-Active (follow up attempts made but no response)
tab claim_disposition if decision_date==. & imp_num==1 // ~64% failure to supply information from provider or victim/claimant 
tab approved if decision_date==. & imp_num==1 // of those that were missing decision date 99.97% were not approved

//checking whether other dates are missing for those missing original decision date 
tab current_decision_date if decision_date==. & imp_num==1 
tab last_date_made_inactive if decision_date==. & imp_num==1 

//checking whether denied claims have a decision date 
tab decision_date if claim_status=="Closed-Determination-Final Decision" & imp_num==1, m //of those that were denied ~82% are missing a decision date 

//since such a high percentage of claims are missing a decision date when they were denied we are not capturing time to decision overall, rather time to approval 

tab claim_status if decision_date!=. & imp_num==1 //88% of claims that have a decision date are OPEN-FINANCIAL-IN-ACTIVE: This status is used when the claim has been paid and there are no active verifications or other payments to be made. This means they were approved. 

//generating number of days to decision  
gen days_decision=decision_date-claim_date2
label variable days_decision "Time to original decision (in days)"
//Note: when we use this dependent variable we should be aware that we are mainly predicting approval decision time. We can also drop denied all other claim_status from the analysis to just focus on time to approval and drop claims that weren't approved. 


//recoding expenses variable 
*total expenses
replace total_bills_expenses="." if total_bills_expenses=="NA"
destring total_bills_expenses, replace 
tab approved if imp_num==1 & total_bills_expenses==. //18% of approved claims are missing expenses 
tab claim_status if imp_num==1 & total_bills_expenses==. & approved==1 //99% of approved claims that are missing total_bills_expenses are open OPEN-FINANCIAL-IN-ACTIVE which means they were paid. 

*amount paid 
replace amount_paid="." if amount_paid=="NA" 
destring amount_paid, replace 
replace amount_paid=amount_paid/1000
label variable amount_paid "Amount paid for each claim (in thousands $)"


tab claim_status if imp_num==1 & amount_paid==. 
tab claim_status if imp_num==1 & amount_paid==. & approved==1
//analysis for amount_paid needs to be restricted to approved claims only 


//destring variables 
foreach var of varlist pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty {
  	replace `var'="." if `var'=="NA"
	destring `var', replace 
}

//save tempfile to merge service provider data
tostring victim_zip, gen(postcode) //needed for merge 
tempfile pa_imputed
save `pa_imputed'

//bringing in data on service providers
import delimited "$clean\BJS Census of Victim Service Providers 2017\BJS_Victim_service_providers.csv", clear 

keep if statea=="PA" 

//collapse for zipcode  count of providers 
collapse (count) su_id, by (postcode)

//merge with cleaned comp data 
merge 1:m postcode using "`pa_imputed'"

tab postcode if _merge==2 & imp_num==1

//replacing 0 service providers for these zip codes since they didn't exist in the BJS service provider data 
rename su_id num_service_providers
replace num_service_providers=0 if _merge==2 

//dropping merge variable 
drop if _merge==1
drop _merge

//number of service providers per capita 
replace total_population="." if total_population=="NA"
destring total_population, replace 

gen num_providers_per1000=(num_service_providers/total_population)*1000

//distance to nearest service provider 
destring postcode, replace
rename postcode zipcode 
merge m:1 zipcode using "$analysis\PA Compensation Data\PA_zip_distance_nearest_provider.dta"

//checking not merged claims 
drop if _merge==2 //these are zipcodes that are in PA but have no claims 

sum zipcode if _merge==1 & imp_num==1 //89 claims do not have a zipcode that matches the list of zip codes from PA in the service provider data. This is a list of all zip codes in PA. So these zip codes should not be in our analysis. So I decide to drop those claims from this analysis. 

drop if _merge==1

//for an analysis that uses distance to closest provider we will lose these 89 claims because there are no service providers 

//summary statistics for variables we need for the analysis 
sum race_w_imp age crime_homicide crime_sex_assault pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty amount_paid approved days_decision den_fail_info num_service_providers if imp_num==1
//are we missing any independent variables--service providers, rural, etc. (check)


//checking missing on variables 
mdesc race_w_imp age crime_homicide crime_sex_assault pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty amount_paid approved days_decision den_fail_info num_service_providers  if imp_num==1


//** In the cleaning files, some zip codes don't have a distance to the closest provider because they didn't have associated coordinates. Most of these are P0 Boxes. If they didn't, we should use the distance to the claimant's zip code. If there are still some missing, we can use the code below to manually replace the zip codes from the two zip codes that don't have a location and have more than half of the missing cases. We can impute from the city for the rest.
** Check the zip codes
tab victim_zip if mi_near_prov == .
** 19037 and 17105 have most of the missing cases. 19037 is a postal office within 19063. 17105 is Harrisburg train station, within 17101. 
sum mi_near_prov if victim_zip == 19063
scalar dist19037 = r(mean)
sum mi_near_prov if victim_zip == 17101
scalar dist17105 = r(mean)
replace mi_near_prov = dist19037 if victim_zip == 19037
replace mi_near_prov = dist17105 if victim_zip == 17105

** Impute for the rest.
gen rand_normal = rnormal() // for all imputations
foreach var of varlist victim_city claimant_city victim_county {
	bysort `var': egen `var'_mi_near_prov_mn = mean(mi_near_prov) 
	bysort `var': egen `var'_mi_near_prov_sd = sd(mi_near_prov) 
	gen `var'_mi_near_prov = `var'_mi_near_prov_mn + `var'_mi_near_prov_sd * rand_normal
	replace mi_near_prov = `var'_mi_near_prov if mi_near_prov == . & imp_num != 0
	drop `var'_mi_near_prov*
}
label var mi_near_prov "Miles from nearest VSP to victim's zip code (or claimant's zip code, or imputed if missing)"



//data has to be saved before mi import 
save "$analysis\PA Compensation Data\PA_BIFSG_imputed_data_cleanedforanalysis.dta", replace 


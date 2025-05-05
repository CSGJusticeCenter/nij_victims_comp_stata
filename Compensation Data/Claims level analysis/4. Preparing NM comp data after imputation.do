/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 28, 2024
Last Updated: october 28, 2024 


Program Description: Cleaning claims data in NM after BIFSG imputation and getting ready
for analysis. 

Input:
	- NM claims data after imputation $analysis\NM Compensation Data\NM_BIFSG_imputed_data.dta
	- BJS Victim Service Providers Data 
		BJS_Victim_service_providers.csv 
		NM_zip_distance_nearest_provider.dta
	- zip code census information 
		zip_codes_data_wide
	
	
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
log using "preparing_NM_comp_data_after_impuation_$out_date.smcl", append


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


/*=========================================================================================
Claims level regressions in NM 
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

//NM
use "$raw\NM_BIFSG_imputed_data.dta", clear


//keeping only NM victims 
keep if victim_state=="NM"

//renaming for mi importing
tab _mi_m
rename _mi_m imp_num 

//rename multi to other so it matches PA for comparison in the analysis 
rename multi other 

//approved claims 
tab resolution_code approved if imp_num==1, m 

//time to decision--figure out which dates to use for this variable 
// is batch_date the decision date? 
**gen days_decision 


//save tempfile to merge service provider data
tostring victim_zip, gen(postcode) //needed for merge 
tempfile nm_imputed
save `nm_imputed'

//bringing in data on service providers
import delimited "$clean\BJS Census of Victim Service Providers 2017\BJS_Victim_service_providers.csv", clear 

keep if statea=="NM" 

//collapse for zipcode  count of providers 
collapse (count) su_id, by (postcode)

//merge with cleaned comp data 
merge 1:m postcode using "`nm_imputed'"

tab postcode if _merge==2 & imp_num==1 //these would be zipcodes that don't exist in the BJS data 

//replacing 0 service providers for these zip codes since they didn't exist in the BJS service provider data 
rename su_id num_service_providers
replace num_service_providers=0 if _merge==2 

//dropping merge variable  
drop if _merge==1
drop _merge

//number of service providers per capita

gen num_providers_per1000=(num_service_providers/total_population)*1000


//distance to nearest service provider 
destring postcode, replace
rename postcode zipcode 
merge m:1 zipcode using "$analysis\NM Compensation Data\NM_zip_distance_nearest_provider.dta"

//checking not merged claims 
drop if _merge==2 //these are zipcodes that are in NM but have no claims 

sum zipcode if _merge==1 & imp_num==1 //131 claims do not have a zipcode that matches the list of zip codes from NM in the service provider data. This is a list of all zip codes in NM. So these zip codes should not be in our analysis. So I decide to drop those claims from this analysis. 

drop if _merge==1

//for an analysis that uses distance to closest provider we will lose these 131 claims because there are no service providers 

//destring variables 
foreach var of varlist pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty {
	replace `var'="." if `var'=="NA" 
	destring `var', replace 
}

//summary statistics for variables we need for the analysis 
sum race_w_imp age crime_homicide crime_sex_assualt pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty approved  num_service_providers if imp_num==1
//are we missing any independent variables--service providers, rural, etc. (check)


//checking missing on variables 
mdesc race_w_imp age crime_homicide crime_sex_assualt pct_vacant_housing_units pct_renter_occupied_housing_unit pct_unemployed_over_16 pct_below_poverty approved  num_service_providers  if imp_num==1


//** In the cleaning files, some zip codes don't have a distance to the closest provider because they didn't have associated coordinates. Most of these are P0 Boxes. If they didn't, we should use the distance to the claimant's zip code. If there are still some missing, we can use the code below to manually replace the zip codes from the two zip codes that don't have a location and have more than half of the missing cases. We can impute from the city for the rest.
** Check the zip codes
tab victim_zip if mi_near_prov == .
**These have the most missing cases. 87125 is a postal office within 87102. 87174 is Harrisburg train station, within 87124. 87198 is a PO boc in 87108. 87504 is a PO Box in 87501. 880202 is a P0 Box in 88201. 
sum mi_near_prov if victim_zip == 87102
scalar dist87102 = r(mean)
sum mi_near_prov if victim_zip == 87124
scalar dist87124 = r(mean)
sum mi_near_prov if victim_zip == 87108
scalar dist87108 = r(mean)
sum mi_near_prov if victim_zip == 87501
scalar dist87501 = r(mean)
sum mi_near_prov if victim_zip == 88201
scalar dist88201 = r(mean)
sum mi_near_prov if victim_zip == 88032
scalar dist88032 = r(mean)
replace mi_near_prov = dist87102 if victim_zip == 87125
replace mi_near_prov = dist87108 if victim_zip == 87174
replace mi_near_prov = dist87124 if victim_zip == 87198
replace mi_near_prov = dist87501 if victim_zip == 87504
replace mi_near_prov = dist88201 if victim_zip == 880202
replace mi_near_prov = dist88032 if victim_zip == 88054

//replace county for those missing county 
replace county="Los Alamos County" if victim_zip==87547

** Impute for the rest.
gen rand_normal = rnormal() // for all imputations
foreach var of varlist major_city county {
	bysort `var': egen `var'_mi_near_prov_mn = mean(mi_near_prov) 
	bysort `var': egen `var'_mi_near_prov_sd = sd(mi_near_prov) 
	gen `var'_mi_near_prov = `var'_mi_near_prov_mn + `var'_mi_near_prov_sd * rand_normal
	replace mi_near_prov = `var'_mi_near_prov if mi_near_prov == . & imp_num != 0 
	drop `var'_mi_near_prov*
}
label var mi_near_prov "Miles from nearest VSP to victim's zip code (or claimant's zip code, or imputed if missing)"

tab victim_zip if mi_near_prov == . & imp_num!=0

//data has to be saved before mi import 
save "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_cleanedforanalysis.dta", replace 

log close
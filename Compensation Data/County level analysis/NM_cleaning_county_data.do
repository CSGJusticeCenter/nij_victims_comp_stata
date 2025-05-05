/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 1, 2024
Last Updated: october 24, 2024 


Program Description: County level analysis of NM and PA claims data for ASC presentation. 

Input:
	- NM claims data 
	
	
Output:
	- regressions

	
ADD do files for programs into description!
need to install xttest3 
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
log using "cleaning NM county data_$out_date.smcl", append


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



/*=========================================================================================
County level regressions in NM 
=========================================================================================

Models 
	1. DV--Application rate 
		IV--structural disadvantage, crime rate, residential instability, racial 
composition, access to service providers, % foreign born
	2. DV--contributory conduct, failure to supply information, time to approval 
=========================================================================================*/

/*=========================================================================================
Generating county level clean data files 
=========================================================================================*/

//NM
//the data does not have an identifier for victim county so we will need to merge this 
import delimited "$dir\data\Clean\Ad Hoc\zip_codes_NM_and_PA.csv", clear 

//rename zipcode for merge 
rename zipcode victim_zip 
tostring victim_zip, replace 

//keep only NM zip codes 
keep if state=="NM"

//Merge with claims data 
merge 1:m victim_zip using "$clean\NM_comp_clean.dta"

//dropping claims outside NM 
drop if victim_state!="NM"

//dropping zipcodes from NM list 
drop if _merge==1

//checking not merged claims 
tab victim_state if _merge==2 
tab victim_city if _merge==2 & victim_state=="NM" 
tab victim_zip if _merge==2 & victim_state=="NM" //upon visually checking some of these zip codes aren't actually in NM 

//NM zip codes are 87001 to 88439 so I will drop any that aren't in between these 
destring victim_zip, replace 
drop if victim_zip<87001
drop if victim_zip>88439 & victim_zip<. //keeping missing zip_codes in case the cities are still in NM but we just don't have NM zip codes 

//checking missing zip codes 
tab victim_city if victim_zip==. 

//cleaning spelling so counties are recognized as the same 
replace county="Dona Ana County" if county=="Doa Ana County" | county=="DoÃ±a Ana County"

//since the merge earlier was using the zip code and these claims are missing zip code we can merge them using the victim city to identify the NM county 
drop _merge 
tempfile nm_comp
save `nm_comp'

//import list of cities and counties 
import delimited "$dir\data\Clean\Ad Hoc\zip_codes_NM_and_PA.csv", clear 

//rename zipcode for merge 
rename major_city victim_city

//keep only NM zip codes 
keep if state=="NM"

//cleaning spelling so counties are recognized as the same 
replace county="Dona Ana County" if county=="Doa Ana County" | county=="DoÃ±a Ana County"


//Merge with claims data 
merge m:m victim_city using "`nm_comp'"

//dropping those from the NM city list 
drop if _merge==1

tab county //some counties are not being recognized as the same name because of typos 
replace county="McKinley County" if county=="Mckinley County" 
tab county

//checking claim_year versus year_entered for missing to decide which year to use 
tab claim_year, m 
tab year_entered, m 

//since claim_number has hyphens creating a new indicator for each claim that we can sum to get total claims for the county 
gen claim=_n 

//collapse data by county year 
collapse (count) claim (sum) ameind-homicide, by (county year_entered)

//save tempfile to merge 
tempfile nm_clean
save `nm_clean'

//bringing in data on service providers
import delimited "$clean\BJS Census of Victim Service Providers 2017\BJS_Victim_service_providers.csv", clear 

keep if statea=="NM" 
replace county="Dona Ana County" if county=="Doña Ana County"

//collapse for county count of providers 
collapse (count) su_id, by (county)

//rename 
rename su_id num_service_providers

//merge with cleaned comp data 
merge 1:m county using "`nm_clean'"

tab county if _merge==2 //some counties have no service providers 

//replacing 0 service providers for these counties since it didn't exist in the BJS service provider data 
replace num_service_providers=0 if _merge==2 

//explore those who were in the BJS county list but not in our data--these counties should have 0 applications in every year then and not dropped from our analysis
replace claim=0 if _merge==1

//dropping merge variable 
drop if year=="." 
drop if county==""
drop _merge


//merging with census data 
rename year_entered year 
destring year, replace 

//rename for merge 
replace county="Doña Ana County" if county=="Dona Ana County"

merge 1:1 county year using "$analysis\NM_cnty_census.dta" 


//exploring those that didn't match 
list county year if _merge==2

//if the county year is only in the census data, I assume that this means there were no claims in that year for that county. So I am replacing the claims data with zero 
foreach var of varlist claim-homicide num_service_providers {
	replace `var'=0 if _merge==2 
}
//this should lead to a balanced panel when running regressions since all counties should be present in every year 
tab county year

//dropping merge variable 
drop _merge


//merging with crime data 

//cleaning county variableto match 
replace county = subinstr(county, " County", "", .)

drop if county==""
drop if year==.

//identify duplicate county years
duplicates report year county 

//save tempfile 
tempfile nm_clean2 
save `nm_clean2'

//importing crime data 
import excel "$clean\Crime\viol_crime_by_county_2015_2019_nm_pa.xlsx", sheet("Sheet1") firstrow clear

//rename for merge 
replace county="Doña Ana" if county=="Dona Ana"

//dropping NM counties
drop if state_name=="Pennsylvania"


//keeping only variable we need 
keep year county overall_reported_crime_rate_per_ homicide_reported_crime_rate_per n_overall_reported n_agencies

//rename variables 
rename overall_reported_crime_rate_per_ viol_crime_per100k 
tab viol_crime_per100k, m 
tab county if viol_crime_per100k=="Inf"
replace viol_crime_per100k="." if viol_crime_per100k=="Inf" //this is Rio Arriba county
tab viol_crime_per100k, m 
destring viol_crime_per100k, replace 
tab viol_crime_per100k, m 

rename homicide_reported_crime_rate_per hom_per100k
destring hom_per100k, replace 

rename n_overall_reported num_viol_crime

//looking at the number of agencies reporting 
tab county year if n_agencies==. //Harding has no agencies in every year and San Juan is missing in 2019.
tab num_viol_crime if n_agencies==. //number of violent crimes is 0 if no reporting agencies instead of missing. 
br county year n_agencies num_viol_crime //looks like Bernalillo county is the only one where a change in agencies reporting shows a larger change in violent crime (this could be ABQ not reporting in some years)

//sorting data 
sort county year

//identify duplicate county years
duplicates report year county 

//cleaning county name for match (these are spelled differently in both datasets so changing it to match spelling)
replace county="McKinley" if county=="Mckinley"


//merge with nm claims data 
merge 1:1 county year using "`nm_clean2'"

tab county if _merge==2 //these counties were not in the crime data were in the application data so we need to recode crime variables to have 0 crimes
list claim num_viol_crime if _merge==2
replace num_viol_crime=0 if _merge==2 //replace 0 violent crimes 
replace viol_crime_per100k=0 if _merge==2

//dropping merge 
drop _merge 

//renaming without the tilda 
replace county="Dona Ana" if county=="Doña Ana"

//replacing missing viol_crime_per100k 
replace viol_crime_per100k=(num_viol_crime/total_population)*100000 if viol_crime_per100k==. //recoding the missing county. Not sure why this value was missing in Andrew's file but I recaculate it. 


//save tempfile
tempfile nm_analysis2
save `nm_analysis2'

//merging % urban variable 
merge 1:1 county year using "$analysis\county_per_urban.dta"

//dropping counties in urban data from PA 
drop if _merge==2 

//checking county years 
tab county year //33 counties in 5 years 



/*========================================================================================
Creating new variables
=========================================================================================*/

//label claim_number 
label var claim "Number of claims"

//label violent crime 
label var num_viol_crime "Number of violent crimes"

//exploring missing 
mdesc claim total_population num_viol_crime //no missing 

//application rate per 10000
gen app_rate=(claim/total_population)*10000

//application rate per crime rate 
gen app_crime_rate=(claim/num_viol_crime)*1000
sum app_crime_rate 
label variable app_crime_rate "Applications per 1,000 violent crimes"
mdesc app_crime_rate //checking missing. There are 7 missing 
list claim num_viol_crime if app_crime_rate==. //the error is dividing by 0 so these are missing since there's no violent crimes 
replace app_crime_rate=0 if claim==0 & num_viol_crime==0 //replacing 0 for those counties with no applications and no crimes 
//2 county years will have missing app_crime_rate

//household income in thousands of dollars
gen med_hh_inc=median_household_income/1000
sum med_hh_inc 

//number service providers per 1000 crimes 
gen providers_per_crime=(num_service_providers/num_viol_crime)*1000
sum providers_per_crime
tab providers_per_crime, m 
label variable providers_per_crime "Providers per 1,000 violent crimes"
mdesc providers_per_crime 
list num_service_providers num_viol_crime if providers_per_crime==. //the error is dividing by 0 so these are missing since there's no violent crimes 
replace providers_per_crime=0 if num_service_providers==0 & num_viol_crime==0 //replacing 0 for no providers and no crimes
//there is still 1 county that will have missing providers per crime because they had providers but no crimes 

//change urban to percent 
replace per_pop_urban_interp=per_pop_urban_interp*100

//calculating % BIPOC 
tab percent_white
gen percent_nonwhite=(100-percent_white) 
tab percent_nonwhite


//label variables 
label var total_population "Total Population"
label var percent_foreign_born "% Foreign Born"
label var percent_black "% Black"
label var percent_hispanic "% Hispanic"
label var providers_per_crime "Providers per 1,000 Violent Crimes"
label var per_pop_urban_interp "% Urban Population"
label var poverty_rate "Poverty Rate"
label variable percent_nonwhite "% BIPOC"

//saving a data file for the county providers per crime rate for use in maps 
preserve 
keep county year providers_per_crime num_service_providers total_population num_viol_crime app_crime_rate
sort county year 
export delimited "$analysis\NM_cnty_formaps.csv", replace 
restore 

//creating lagged compensation variable if needed 
//gen lagged_app_rate = L.app_rate

//new county indicator that is not a string 
encode county, gen(county_cat)


//saving file with cleaned variables 
save "$analysis\NM_county_clean.dta", replace 

log close 
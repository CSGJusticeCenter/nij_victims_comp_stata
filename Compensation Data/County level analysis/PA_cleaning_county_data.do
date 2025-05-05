/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 1, 2024
Last Updated: october 24, 2024 


Program Description: Cleaning claims data to create county level files. 

Input:
	- PA claims data 
	- BJS service provider data 
	- crime data 
	
	
Output:
	- cleaned county level file ready for analysis
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
log using "pa_county_data_cleaning_$out_date.smcl", append

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




/*=========================================================================================
County level regressions in PA 
=========================================================================================

Models 
	1. DV--Application rate 
		IV--structural disadvantage, crime rate, residential instability, racial 
composition, access to service providers, % foreign born, % racial demographics
=========================================================================================*/

/*=========================================================================================
Generating county level clean data files 
=========================================================================================*/
//PA
use "$clean\PA_comp_clean.dta", clear 

//collapse data by county year 
collapse (count) claim_number (sum) victim_ameind-homicide, by (victim_county claim_year)

//generating new variable to match to BJS data 
gen county=victim_county + " County"

//drop if county is out of state 
drop if victim_county=="Out of State" | victim_county=="NA"

//save tempfile to merge 
tempfile pa_clean
save `pa_clean'

//bringing in data on service providers
import delimited "$clean\BJS Census of Victim Service Providers 2017\BJS_Victim_service_providers.csv", clear 

keep if statea=="PA" 


//collapse for county count of providers 
collapse (count) su_id, by (county)

//rename 
rename su_id num_service_providers



//merge with cleaned comp data 
merge 1:m county using "`pa_clean'"

tab county if _merge==2 //cameron county has no service providers 

//replacing 0 service providers for cameron county since it didn't exist in the BJS service provider data 
replace num_service_providers=0 if _merge==2 

//explore those who were in the BJS county list but not in our data--these counties should have 0 applications in every year then and not dropped from our analysis

//dropping merge variable 
drop _merge


//merging with census data 
rename claim_year year 

merge 1:1 county year using "$analysis\PA_cnty_census.dta" 

//exploring those that didn't match 
list county year if _merge==2

//if the county year is only in the census data, I assume that this means there were no claims in that year for that county. So I am replacing the claims data with zero 
foreach var of varlist claim_number-homicide num_service_providers {
	replace `var'=0 if _merge==2 
}
//this should lead to a balanced panel when running regressions since all counties should be present in every year 


//dropping merge variable 
drop _merge


//merging with crime data 

//cleaning county variableto match 
replace county = subinstr(county, " County", "", .)

//save tempfile 
tempfile pa_clean2 
save `pa_clean2'

//importing crime data 
import excel "$clean\Crime\viol_crime_by_county_2015_2019_nm_pa.xlsx", sheet("Sheet1") firstrow clear

//dropping NM counties
drop if state_name=="New Mexico"


//keeping only variable we need 
keep year county overall_reported_crime_rate_per_ homicide_reported_crime_rate_per n_overall_reported

//rename variables 
rename overall_reported_crime_rate_per_ viol_crime_per100k 
replace viol_crime_per100k="." if viol_crime_per100k=="Inf" //this is Philly because it shows 0 population right now. Confirming this with Andrew and we need to replace this with the PD data 
destring viol_crime_per100k, replace 

rename homicide_reported_crime_rate_per hom_per100k
destring hom_per100k, replace 

rename n_overall_reported num_viol_crime

//sorting data 
sort county year

//identify duplicate county years
duplicates report year county 

//cleaning county name for match (these are spelled differently in both datasets so changing it to match spelling)
replace county="McKean" if county=="Mckean"

//merge with pa claims data 
merge 1:1 county year using "`pa_clean2'"

//dropping merge 
drop _merge 

//merge in Philadelphia crime data for 2019!!!!
tempfile pa_analysis
save `pa_analysis'

import delimited "$clean\Crime\pa_philadelphia_crime_incident_2015_to_2019.csv",  clear 

//keeping only 2019 data 
*drop if year!=2019

//collapse for crime counts 
collapse (sum) is_violent is_property, by(city year)

//to merge treat this as Philadelphia county 
rename city county 

rename is_violent num_viol_crime

//merge with the rest of the PA data and replace this as crime for Philadelphia in 2019
merge 1:1 county year using "`pa_analysis'"

//drop marge variable 
drop _merge

//creating violent crime rate with this philadelphia data 
gen viol_rate=(num_viol_crime/total_population)*100000

//replace missing violent crime rate with this number 
replace viol_crime_per100k=viol_rate if county=="Philadelphia"

//changing violent crime rate to per 10000
gen viol_crime_per10k=(viol_crime_per100k/100000)*10000

//save tempfile
tempfile pa_analysis2
save `pa_analysis2'

//merging urban and rural indicators 
/*//import excel "$data\2020_UA_COUNTY.xlsx", sheet("2020_UA_COUNTY") firstrow clear //not working for some reason

import excel "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Raw\2. Phase 2 State\2020_UA_COUNTY.xlsx", sheet("2020_UA_COUNTY") firstrow clear

//keeping only PA data
keep if STATE_NAME=="Pennsylvania"

//rename county name 
rename COUNTY_NAME county

//urban population variables 
sum POPPCT_URB //Percent of the 2020 Census population of the County within Urban blocks

rename POPPCT_URB per_pop_urban 

//keeping only variables we need 
keep county per_pop_urban

//merging with the rest of the data 
merge 1:m county using "`pa_analysis2'"
*/

//merging % urban variable 
merge 1:1 county year using "$analysis\county_per_urban.dta"

//dropping counties in urban data from PA 
drop if _merge==2 


/*========================================================================================
Creating new variables
=========================================================================================*/

//label claim_number 
label var claim_number "Number of claims"
rename claim_number claims 

//label violent crime 
label var num_viol_crime "Number of violent crimes"

//application rate per 10000
gen app_rate=(claims/total_population)*10000

//application rate per crime rate 
gen app_crime_rate=(claims/num_viol_crime)*1000
sum app_crime_rate 
label variable app_crime_rate "Applications per 1,000 violent crimes"
mdesc app_crime_rate //checking missing. There are 0 missing 

//household income in thousands of dollars
gen med_hh_inc=median_household_income/1000
sum med_hh_inc 

//number service providers per 1000 crimes 
gen providers_per_crime=(num_service_providers/num_viol_crime)*1000
sum providers_per_crime
tab providers_per_crime, m 
label variable providers_per_crime "Providers per 1,000 violent crimes"
mdesc providers_per_crime //there are 0 missing 


//change urban to percent 
replace per_pop_urban_interp=per_pop_urban_interp*100

//label variables 
label var total_population "Total Population"
label var percent_foreign_born "% Foreign Born"
label var percent_black "% Black"
label var percent_hispanic "% Hispanic"
label var providers_per_crime "Providers per 1,000 Violent Crimes"
label var per_pop_urban_interp "% Urban Population"
label var poverty_rate "Poverty Rate"

//saving data 
save "$analysis\PA_county_clean.dta", replace 

//saving a data file for the county providers per crime rate for use in maps 
preserve 
keep county year providers_per_crime num_service_providers total_population num_viol_crime app_crime_rate
export delimited "$analysis\PA_cnty_formaps.csv", replace 
restore 

log close

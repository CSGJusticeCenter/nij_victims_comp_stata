/*=====================================================================================
Program Author: Shradha Sahani
Start Date: September 16, 2024
Last Updated: March 10, 2025


Program Description: Cleaning PA city crime data to create a file that has crime rates 
for neighborhoods in the 5 main cities from 2015-2019. 

Input:
	- PA PD data data 
	- PA claims data 
	
Output:
	- cleaned neighborhood level claims file with crime rates 
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
log using "cleaning__city_crime_$out_date.smcl", append

/*=====================================================================================
Define the names of the datasets to use
--------------------------------------------------------------------------------------
=======================================================================================*/ 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp" 

global data="$dir\data\Raw\2.Phase 2 State" //directory for data files
global PA="$dir\data\Raw\2.Phase 2 State\PA" //directory for PA data files
global NM="$dir\data\Raw\2.Phase 2 State\NM" //directory for PA data files

global analysis="$dir\data\Analysis\Phase 2 State" //directory for analysis files 
global clean="$dir\data\Clean" //directory for clean files 

cd "$dir" //setting directory 


/***************************************************************************************
Appending city crime data--PA
=========================================================================================
*****************************************************************************************/

//cleaning allentown file to match the other cities so we can run the loop later
import delimited "$clean\Crime\pa_allentown_violent_crime_incident_2015_to_2019.csv", clear 

rename offense ucr_name 

//this file only has violent crimes 
gen is_violent=1 

//gen city indicator 
gen city="Allentown" 

//string zip 
tostring zip, replace 

//creating year variable 
gen year = real(substr(date, 1, 4))

//export file 
export delimited "$clean\Crime\pa_allentown_crime_incident_2015_to_2019.csv", replace 

//cleaning and collapsing individual city files first 
foreach city in philadelphia scranton pittsburgh reading allentown {

import delimited "$clean\Crime\pa_`city'_crime_incident_2015_to_2019.csv", bindquote(strict) clear 

//homicide indicator 
tab ucr_name 
gen homicide=0 
replace homicide=1 if inlist(ucr_name, "Homicide - Criminal", "Homicide - Justifiable", "Homicide", "Murder", "MURDER/NON-NEGLIGENT MANSLAUGH") 

//generating variable to count for total crimes 
*gen crime=_n

//collapse for zip code level data 
*collapse (sum) homicide is_violent is_property (count) crime (first) city, by(zip)
collapse (sum) homicide is_violent (first) city, by(zip year)

//rename variables 
*rename crime total_crimes 

//dropping those with missing zip code 
cap tostring zip, replace
cap drop if zip=="NA" 

//save tempfile 
tempfile `city'_zip_crime 
save ``city'_zip_crime'

}

//append all files together 
use `philadelphia_zip_crime', clear 

foreach city in scranton pittsburgh reading allentown { 
	 
	append using ``city'_zip_crime'
}

//checking for duplicate zip codes 
duplicates report zip year
duplicates list zip  

duplicates tag zip year, gen(zip_year_dup) //indicator for duplicates 
br if zip_year_dup==1 //19124 zip code is in philadelphia so drop the other one and 15210 is in Pittsburgh so drop the other one 

drop if zip=="19124" & city=="Scranton"
drop if zip=="15210" & city=="Allentown"

//checking zip code year 
tab zip year 
*some zip codes have no crimes in some years so the observation doesn't exist 


//drop 0 zip code 
drop if zip=="0"


//generate observation for missing years
tempfile pa_city_crime 
save `pa_city_crime'

// Step 2: Get all unique ZIP codes
preserve
keep zip city
duplicates drop
tempfile zipcodes
save `zipcodes'
restore

// Step 3: Create a dataset with all years
clear
set obs 5  // Change to the number of years you need
gen year = 2015 + _n - 1  // Adjust this range as needed
tempfile years
save `years'

// Step 4: Create all combinations of ZIP codes and years
use `zipcodes', clear
cross using `years'  // Creates all ZIP-year pairs

//checking all years have 5 observations across all years 
tab zip year
tab zip 


// Step 5: Merge with original dataset
merge 1:1 zip year using `pa_city_crime'

//replace crime=0 if _merge==1 
replace homicide=0 if _merge==1
replace is_violent=0 if _merge==1

//drop merge variable 
drop _merge  

//checking zip 
tab zip

//dropping zips that have less than 5 characters 
drop if strlen(zip) < 5
drop if zip=="185-4"

//save tempfile 
tempfile pa_city_crime_combined
save `pa_city_crime_combined'

//merging with census data for zip code population 

//PA data 

//using census demographic files created for BIFSG 
import excel "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\RAND BISG\PA Census Data.xlsx", sheet("zipcode demographics") firstrow clear

//renaming variables 
rename geo_id zip 
tostring zip, replace 

//merge with crime data
merge 1:m zip using `pa_city_crime_combined'

//dropping those who didn't merge these aren't in PA or are miscoded zip codes 
drop if _merge==1

//checking zip years
tab zip year
tab zip 

//homicide rate 
gen hom_rate=(homicide/tot_pop)*1000
rename hom_rate zip_homicide_rate
label variable zip_homicide_rate "Ngd. Homicide Rate per 1000"

//violent crime rate 
gen viol_rate=(is_violent/tot_pop)*1000
sum viol_rate
rename viol_rate zip_viol_rate
label variable zip_viol_rate "Ngd. Violent Crime Rate per 1000"

//keep only crime variables 
keep zip year zip_viol_rate zip_homicide_rate city homicide is_violent 

//rename and label variables for clarity 
rename homicide zip_homicide 
label variable zip_homicide "# of homicides in the zipcode"

rename is_violent zip_violent 
label variable zip_violent "# of violent crimes in zipcode"

//save file
save "$clean\Crime\pa_city_crime_combined.dta", replace //this file contains all zip code crime data by year in the 5 major cities. 

/*=====================================================================================
Merging with the Claims Data 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//PA
use "$analysis\PA Compensation Data\PA_comp_clean.dta", replace //before imputation 

//keeping data only for the main cities in our analysis 
keep if inlist(victim_city, "Philadelphia", "Pittsburgh", "Reading", "Scranton", "Allentown")

//rename for merge 
rename victim_zip zip 

//destring total population
replace total_population="." if total_population=="NA"
destring total_population, replace 

//browsing variables to look at data 
br claim_number homicide approved victim_city total_population
 
//collapse for zip code level 
collapse (count) claim_number (sum) homicide approved (first) victim_city total_population, by(zip claim_year)

//label variables after collapse
label variable claim_number "Number of claims"
label variable homicide "Number of homicide Applications"
label variable approved "Number of Approved Applications"

//calculate application rate 
gen zip_app_rate=(claim_number/total_population)*1000 

tab zip_app_rate, m 
sum zip_app_rate 
label variable zip_app_rate "Zipcode application rate per 1,000"

//rename year variable for merge 
rename claim_year year 

//merging with city crime data 
merge 1:1 year zip using "$clean\Crime\pa_city_crime_combined.dta", gen(merge2) 


//looking at those that didn't match 
tab zip if merge2==1 // we assume these zip codes had 0 crime since they're not in the crime data 

//recoding no crimes for these zip codes 
foreach var of varlist zip_homicide_rate zip_viol_rate {
	replace `var'=0 if merge2==1
}

//if merge==2 then that zip code didn't have any claims that yaer 
tab victim_city if merge2==2 
replace claim_number=0 if merge2==2
replace victim_city=city if merge2==2
replace zip_app_rate=0 if merge2==2 //these zip codes had no applications

//exploring those zip codes with applications but no crimes 
tab claim_number if zip_viol_rate==0, m 

//dropping merge variable 
drop merge2
 
//dropping unecessary variables 
drop city 

//rename total_population 
rename total_population zip_tot_pop

//we want to make sure all zip codes in the 5 cities are included. Not only zipcodes that are in the claims or crime data. So I merge this with a list of zipcodes in the entire state



//first save file 
tempfile pa_ngd_crime
save `pa_ngd_crime'

//open zip code file 
import delimited "$clean\Ad Hoc\zip_codes_NM_and_PA.csv", clear 

//keep only PA 
keep if state=="PA"

//keeping data only for the main cities in our analysis 
keep if inlist(major_city, "Philadelphia", "Pittsburgh", "Reading", "Scranton", "Allentown")

//keep only list of zipcodes and cities to have a complete list in PA 
keep zipcode major_city 

//for merge 
rename zipcode zip 
tostring zip, replace 

//Creating 5 observations for each zip per year 

// Step 2: Get all unique ZIP codes
preserve
keep zip major_city
duplicates drop
tempfile zipcodes
save `zipcodes'
restore

// Step 3: Create a dataset with all years
clear
set obs 5  // Change to the number of years you need
gen year = 2015 + _n - 1  // Adjust this range as needed
tempfile years
save `years'

// Step 4: Create all combinations of ZIP codes and years
use `zipcodes', clear
cross using `years'  // Creates all ZIP-year pairs

//checking all years have 5 observations across all years 
tab zip year
tab zip 

//merge with claims and crime data to add missing zipcodes in the large cities 
merge m:m zip using `pa_ngd_crime'

//look at those in the data that don't match the larger list of PA zip codes 
tab victim_city if _merge==2
br if _merge==2 
//Decision: Since these zip codes are not considered to be part of the 5 large cities in PA that we are looking at I drop them from the sample. From looking at a couple examples I think there may be some errors in the claims data that inaccurately identify zip codes to the cities. 
drop if _merge==2 

//now looking at those in the master list of PA zip codes that aren't in the claims or crime data 
br if _merge==1

//these zip codes should have no crimes and no applications 
foreach var of varlist claim_number-approved zip_app_rate-zip_viol_rate {
	replace `var'=0 if _merge==1 
}

//checking zip code years 
tab zip //they should all have 5 

//dropping unecessary variables 
drop major_city _merge

//saving file 
save "$analysis\PA Compensation Data\pa_comp_with_ngd_crime.dta", replace 

	
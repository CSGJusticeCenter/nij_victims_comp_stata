/*=====================================================================================
Program Author: Shradha Sahani
Start Date: September 16, 2024
Last Updated: March 27, 2025


Program Description: Cleaning NM city crime data to create a file that has crime rates 
for neighborhoods in the 4 main cities from 2015-2019. 

Input:
	- NM PD data data 
	- NM claims data 
	
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
log using "nm_cleaning__city_crime_$out_date.smcl", append

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
Cleaning city files 
=========================================================================================
Amund cleaned this file from the raw data file but did not fill out the is_violent column 
so I will recode that. 

violent=murder, rape, agg assault, and robbery for violent crime

*****************************************************************************************/
//santa fe 
import delimited "$clean\Crime\nm_santa_fe_crime_incident_2015_to_2019.csv", bindquote(strict)

//looking at ucr categories and recoding the violent ones 
tab ucr_name if inlist(ucr_name, "MANSLAUGHTER", "HOMICIDE", "MURDER")

//homicide indicator 
gen homicide=0 
local homicide MANSLAUGHTER HOMICIDE MURDER
foreach type in `homicide' {
replace homicide=1 if regexm(ucr_name, "`type'")
} 

//robbery indicator 
gen robbery=0 
replace robbery=1 if regexm(ucr_name, "ROBBERY")

//rape 
gen rape=0 
replace rape=1 if regexm(ucr_name, "RAPE")

//aggravated assault 
tab ucr_name if regexm(ucr_name, "AGG")
gen agg_assault=0 

local type "AGG ASLT|AGG ASSAULT|AGGRAVATED ASSAULT|AGGRAVATED ASSLT"

replace agg_assault = 1 if regexm(ucr_name, "`type'")

//gen violent indicator
drop is_violent 
gen is_violent=0  
replace is_violent=1 if robbery==1 | homicide==1 | rape==1 | agg_assault==1 

//add code to save this 
save "$clean\Crime\nm_santa_fe_crime_cleaned.dta", replace 

//farmington 
import delimited "$clean\Crime\nm_farmington_crime_incident_2015_to_2019.csv", bindquote(strict) clear

//looking at ucr categories 
tab ucr_name 

//violent coding 
drop is_violent
gen is_violent=0 
replace is_violent=1 if ucr_name=="Homicide" | ucr_name=="Robbery" 
//because of the way the data is coded these are the only two categories we can use for violent offenses 

//add code to save this 
save "$clean\Crime\nm_farmington_crime_cleaned.dta", replace 

//rio rancho 
import delimited "$clean\Crime\nm_rio_rancho_crime_incident_2015_to_2019.csv", bindquote(strict) clear


//homicide indicator 
gen homicide=0 
local homicide HOMICIDE MURDER
foreach type in `homicide' {
replace homicide=1 if regexm(ucr_name, "`type'")
} 

//robbery indicator 
gen robbery=0 
replace robbery=1 if regexm(ucr_name, "ROBBERY")

//rape 
gen rape=0 
replace rape=1 if regexm(ucr_name, "RAPE")

//aggravated assault 
tab ucr_name if regexm(ucr_name, "AGG")
gen agg_assault=0 

local type "AGG ASLT|AGG ASSAULT|AGGRAVATED ASSAULT|AGGRAVATED ASSLT"

replace agg_assault = 1 if regexm(ucr_name, "`type'")

//gen violent indicator
drop is_violent 
gen is_violent=0  
replace is_violent=1 if robbery==1 | homicide==1 | rape==1 | agg_assault==1 


//add code to save this 
save "$clean\Crime\nm_rio_rancho_crime_cleaned.dta", replace 

//albuquerque
import delimited "$clean\Crime\nm_albuquerque_crime_incident_2015_to_2019.csv", bindquote(strict) clear

//recode violent because rape is missing 
replace is_violent=1 if ucr_name=="Rape" 

save "$clean\Crime\nm_albuquerque_crime_cleaned.dta", replace

/***************************************************************************************
Appending city crime data--NM
=========================================================================================
*****************************************************************************************/

//cleaning and collapsing individual city files first 
foreach city in farmington albuquerque santa_fe rio_rancho {

use "$clean\Crime\nm_`city'_crime_cleaned.dta", clear 

//homicide indicator 
/*
tab ucr_name 
gen homicide=0 
replace homicide=1 if inlist(ucr_name, "Homicide - Criminal", "Homicide - Justifiable", "Homicide", "Murder", "MURDER/NON-NEGLIGENT MANSLAUGH") 
*/

//generating variable to count for total crimes 
*gen crime=_n

//collapse for zip code level data 
collapse (sum) is_violent (first) city, by(zip year)

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
use `farmington_zip_crime', clear 

foreach city in albuquerque santa_fe rio_rancho { 
	 
	append using ``city'_zip_crime'
}

//checking for duplicate zip codes 
duplicates report zip year
duplicates list zip  

duplicates tag zip year, gen(zip_year_dup) //indicator for duplicates 
sort zip year 
br if zip_year_dup>0 //there are a lot of duplicates but we will deal with this later when merging with the list of zip codes in NM to correctly identify the city 
list zip year if zip_year_dup>0


//drop 0 zip code 
drop if zip=="00000"

//identify correct city for duplicates 
tempfile nm_city_crime 
save `nm_city_crime'

//use list of nm zip codes 
import delimited "$clean\Ad Hoc\zip_codes_NM_and_PA.csv", clear 

keep if state=="NM"
//keeping data only for the main cities in our analysis 
keep if inlist(major_city, "Farmington", "Albuquerque", "Santa Fe", "Rio Rancho")

//rename for merge 
rename zipcode zip 
tostring zip, replace 

//merge with crime data 
merge 1:m zip using `nm_city_crime'

//now we only want to keep those zip code observations in the right city 
//first only keep matched zip codes 
keep if _merge==3 

tab zip_year_dup

//if the observations are duplicates then we want to keep the one with the correct city which is major_city
gen city_mismatch=1 if major_city!=city 
replace city_mismatch=0 if  major_city==city
tab zip_year_dup city_mismatch

//keeping only the observations where the city matches 
keep if city_mismatch==0

//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup2) //indicator for duplicates 
tab zip_year_dup2

//we only keep the major_city since that is from the census and from checking a few online these are more accurate 
drop city 

//keeping only data we need 
keep major_city zip state is_violent year

//rename major city 
rename major_city city 

//generate observation for missing years

tempfile nm_city_crime2 
save `nm_city_crime2'

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
merge 1:1 zip year using `nm_city_crime2'

//replace crime=0 if _merge==1 
replace is_violent=0 if _merge==1

//drop merge variable 
drop _merge  

//checking zip 
tab zip

//dropping zips that have less than 5 characters 
drop if strlen(zip) < 5


//save tempfile 
tempfile nm_city_crime_combined
save `nm_city_crime_combined'

//merging with census data for zip code population 

//NM data 

//using census demographic files created for BIFSG 
import excel "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\RAND BISG\NM Census Data.xlsx", sheet("zipcode demographics") firstrow clear

//renaming variables 
rename geo_id zip 
tostring zip, replace 

//merge with crime data
merge 1:m zip using `nm_city_crime_combined'

//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup2) //indicator for duplicates 
tab zip_year_dup2

//dropping those who didn't merge these aren't in NM or are miscoded zip codes 
drop if _merge==1

//checking zip years
tab zip year
tab zip 

//homicide rate 
//gen hom_rate=(homicide/tot_pop)*1000
//rename hom_rate zip_homicide_rate
//label variable zip_homicide_rate "Ngd. Homicide Rate per 1000"

//violent crime rate 
gen viol_rate=(is_violent/tot_pop)*1000
sum viol_rate
rename viol_rate zip_viol_rate
label variable zip_viol_rate "Ngd. Violent Crime Rate per 1000"

//keep only crime variables 
keep zip year zip_viol_rate city is_violent 

//rename and label variables for clarity 
rename is_violent zip_violent 
label variable zip_violent "# of violent crimes in zipcode"

//save file
save "$clean\Crime\nm_city_crime_combined.dta", replace //this file contains all zip code crime data by year in the 5 major cities. 


/*=====================================================================================
Merging with the Claims Data 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//NM
use "$analysis\NM Compensation Data\NM_comp_clean.dta", replace //before imputation 

//keeping data only for the main cities in our analysis 
keep if inlist(victim_city, "Farmington", "Albuquerque", "Santa Fe", "Rio Rancho")

//rename for merge 
rename victim_zip zip 


//browsing variables to look at data 
br claim_number approved victim_city total_population

//creating new claim id to collapse 
gen claim_id=_n 

//collapse for zip code level 
collapse (count) claim_id (sum) approved (first) victim_city total_population, by(zip claim_year)

//label variables after collapse
rename claim_id claim_number
label variable claim_number "Number of claims"
label variable approved "Number of Approved Applications"

//calculate application rate 
gen zip_app_rate=(claim_number/total_population)*1000 

tab zip_app_rate, m 
sum zip_app_rate 
label variable zip_app_rate "Zipcode application rate per 1,000"

//rename year variable for merge 
rename claim_year year 
replace year="." if year=="NA"
destring year, replace 

//changing variable type for merge 
tostring zip, replace 

//merging with city crime data 
merge 1:1 zip year using "$clean\Crime\nm_city_crime_combined.dta", gen(merge2) 

//checking duplicates//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup2) //indicator for duplicates 
tab zip_year_dup2 //no duplicates

//looking at those that didn't match 
tab zip if merge2==1 // we assume these zip codes had 0 crime since they're not in the crime data 

//recoding no crimes for these zip codes 
foreach var of varlist zip_violent zip_viol_rate {
	replace `var'=0 if merge2==1
}

//if merge==2 then that zip code didn't have any claims that yaer 
tab city if merge2==2 
replace claim_number=0 if merge2==2
replace victim_city=city if merge2==2
replace zip_app_rate=0 if merge2==2 //these zip codes had no applications

//exploring those zip codes with applications but no crimes 
tab claim_number if zip_viol_rate==0, m 

//dropping missing zip codes
drop if zip=="." 

//dropping merge variable 
drop merge2
 
//dropping unecessary variables 
drop city 

//rename total_population 
rename total_population zip_tot_pop

//we want to make sure all zip codes in the 5 cities are included. Not only zipcodes that are in the claims or crime data. So I merge this with a list of zipcodes in the entire state
tab zip  year
tab zip 

//look at duplicates because some zips are in here 6 times 
//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup3) //indicator for duplicates 
tab zip_year_dup3 //saying to duplicates 

//keep only years in our analysis 
keep if year>=2015 & year<=2019

//check duplicates again 
//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup4) //indicator for duplicates 
tab zip_year_dup4
tab zip //no more 6 observations for some zips 

//first save file 
tempfile nm_ngd_crime3
save `nm_ngd_crime3'

//open zip code file 
import delimited "$clean\Ad Hoc\zip_codes_NM_and_PA.csv", clear 

//keep only NM 
keep if state=="NM"

//keeping data only for the main cities in our analysis 
keep if inlist(major_city, "Farmington", "Albuquerque", "Santa Fe", "Rio Rancho")

//keep only list of zipcodes and cities to have a complete list in NM 
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
merge m:m zip using `nm_ngd_crime3'

//look at those in the data that don't match the larger list of NM zip codes 
tab victim_city if _merge==2
br if _merge==2 
//Decision: Since these zip codes are not considered to be part of the 4 large cities in NM that we are looking at I drop them from the sample. From looking at a couple examples I think there may be some errors in the claims data that inaccurately identify zip codes to the cities. 
drop if _merge==2 

//now looking at those in the master list of NM zip codes that aren't in the claims or crime data 
br if _merge==1

//these zip codes should have no crimes and no applications 
foreach var of varlist claim_number-approved zip_app_rate-zip_viol_rate {
	replace `var'=0 if _merge==1 
}

//checking zip code years 
tab zip //they should all have 5 


//new duplicate indicator
duplicates tag zip year, gen(zip_year_dup5) //indicator for duplicates 
tab zip_year_dup5 //no duplicates 

//dropping unecessary variables 
drop major_city _merge zip_year_dup*

//saving file 
save "$analysis\NM Compensation Data\nm_comp_with_ngd_crime.dta", replace 


log close 
	
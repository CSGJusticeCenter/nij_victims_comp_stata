/*=====================================================================================
Program Author: Shradha Sahani
Start Date: February 28, 2025
Last Updated:  February 28, 2025

Program Description: Creating county % urban population rates for 2015 to 2019. Since the data
is only available from the Decennial Census for 2010 and 2020, I will use linear 
interpolation to impute the data for the years in between to get county percentages for 2015-2019. 

Input:
	- 2010 Urban population data from the census 
	- 2020 Urban population data from the census 
	
	
Output:
	- data file with % urban for NM and PA counties 2015-2019
====================================================================================*/


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
global raw="$dir\data\Raw\2. Phase 2 State" 
cd "$dir" //setting directory 




/*=====================================================================================
Importing and merging 2010 and 2020 data 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//2010 data 
import excel "$raw\PctUrbanRural_County.xls", sheet("Pct urban by county") firstrow

//keeping onyly PA and NM counties 
keep if STATENAME=="New Mexico" | STATENAME=="Pennsylvania" 

//generating year variable 
gen year="2010" 

//keep only variables needed 
keep STATENAME COUNTYNAME POPPCT_URBAN year 

//rename variables 
rename STATENAME state
rename COUNTYNAME county 

//rescaling percent pop to proportion 
replace POPPCT_URB=POPPCT_URB/100

//tempfile to append 2020 data 
tempfile urban_2010
save `urban_2010'

//import 2020 data 
import excel "$raw\2020_UA_COUNTY.xlsx", sheet("2020_UA_COUNTY") firstrow clear

//keeping onyly PA and NM counties 
keep if STATE_NAME=="New Mexico" | STATE_NAME=="Pennsylvania" 

//generating year variable 
gen year="2020" 

//keep only variables needed 
keep STATE_NAME COUNTY_NAME POPPCT_URB year 

//rename variables 
rename STATE_NAME state 
rename COUNTY_NAME county
rename POPPCT_URB POPPCT_URBAN

//append with 2010 data 
append using `urban_2010'

//urban population variables 
sum POPPCT_URB //Percent of the  Census population of the County within Urban blocks

rename POPPCT_URB per_pop_urban 
label var per_pop_urban "% Urban population"

//renaming without the tilda 
replace county="Dona Ana" if county=="Doña Ana"


//creating values for all years from 2010 to 2019 
//first we need to create additional observations for each county year 
gen n=10 
expand n

//insert the years we need 
destring year, replace 
bysort county (year): replace year = year[_n-1] + 1 if _n > 1
drop if year>2020 

//replace missing urban population for non-census years 
replace per_pop_urban=. if year>2010 & year<2020

//interpolate missing values 
bysort county (year): ipolate per_pop_urban year, gen(per_pop_urban_interp)

//keeping only years we need for the claims analysis 2015-2019
keep if year>=2015 & year<=2019

//keeping only variables we need 
keep county year per_pop_urban_interp

//label variable 
label var per_pop_urban_interp "% urban pop interpolated"

//save file 
save "$analysis\county_per_urban.dta", replace 
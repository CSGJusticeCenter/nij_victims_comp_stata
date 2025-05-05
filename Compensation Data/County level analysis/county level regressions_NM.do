/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 1, 2024
Last Updated: october 24, 2024 


Program Description: County level analysis of NM claims data.
Input:
	- NM claims data 
	
	
Output:
	- regressions

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
use "$analysis\NM_county_clean.dta"

/*=========================================================================================
Testing Models 
=========================================================================================
*/

//installing programs 
do "$dir\code\Victim Compensation\stepwise_regs.do" 
do "$dir\code\Victim Compensation\check_reg_assump.do" //installs check_reg_assump as well

//setting panel data 
xtset county_cat year

//dropping stored estimates if they exist 
cap estimates drop  RE*

//stepwise regression
stepwise_regs app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp, command(xtreg) options(re robust) prefix(RE) 

//checking assumptions
check_reg_assump app_crime_rate percent_renter_occupied, modelname(xtreg)
 

//DECIDING BETWEEN FIXED AND RANDOM EFFECTS//

//fixed effects 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp, fe
estimates store fixed 


//random effects 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp
estimates store random 

//hausman test 
hausman fixed random, sigmamore //findings suggest re 


*testing for homoskedasticity 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp, fe
xttest3 //there is heteroskedasticity so we need robust standard errors and cannot trust the results of the hausman test 


//xtoverid 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp, robust
xtoverid, robust //not significant suggest random effects are appropriate 
xtoverid, cluster(county)

//breusch-pagan lagrange multiplier test 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban_interp, robust
xttest0 //random effects over pooled OLS 


//multicolinearity in the model 
reg app_crime_rate percent_foreign_born percent_black percent_nonwhite percent_hispanic providers_per_crime poverty_rate per_pop_urban_interp total_population, robust
vif 

/*=========================================================================================
Running Regressions Models 
=========================================================================================
*/

//label variables 
label var total_population "Total Population"
label var percent_foreign_born "% Foreign Born"
label var percent_black "% Black"
label var percent_hispanic "% Hispanic"
label var providers_per_crime "Providers per 1,000 Violent Crimes"
label var per_pop_urban_interp "% Urban Population"
label var poverty_rate "Poverty Rate"
label variable percent_nonwhite "% BIPOC"

//percent black 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", replace label title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)


//percent nonwhite 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)


//percent hispanic 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 3) bdec(2) tdec(3) rdec(3) sdec(2)

//all race vars 
xtreg app_crime_rate percent_foreign_born percent_black percent_nonwhite percent_hispanic providers_per_crime poverty_rate per_pop_urban_interp total_population, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 4) bdec(2) tdec(3) rdec(3) sdec(2)

//percent black 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", replace label title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)


//percent nonwhite 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)


//percent hispanic 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 3) bdec(2) tdec(3) rdec(3) sdec(2)

//all race vars 
xtreg app_crime_rate percent_foreign_born percent_black percent_nonwhite percent_hispanic providers_per_crime poverty_rate per_pop_urban_interp total_population, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\NM Compensation Data\NM_cnty_models_$out_date.xls", append label title(model 4) bdec(2) tdec(3) rdec(3) sdec(2)


/*





//FINAL MODEL WITH CLUSTERED STANDARD ERRORS
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
vif //vif statistics are low but correlations are high so check models with and without total population 

xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "$analysis\NM Compensation Data\NM_cnty_models_$out_date.doc", replace title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)

//taking out total population--no change to results 
xtreg app_crime_rate percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "$analysis\NM Compensation Data\NM_cnty_models_$out_date.doc", append title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)

//using median hh income instead of poverty rate 
xtreg app_crime_rate percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc, vce(cluster county)
outreg2 using "$analysis\NM Compensation Data\NM_cnty_models_$out_date.doc", append title(model 3) bdec(2) tdec(3) rdec(3) sdec(2)

//median household income and total population 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc, vce(cluster county)

//median hh income and poverty rate 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc poverty_rate, vce(cluster county)

//descriptives 
sum app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate



//outreg summary statistics 
outreg2 using "$analysis\NM Compensation Data\cnty_descriptives_NM.xls", replace sum(log) keep(app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate) dec(2)  

//
corr percent_foreign_born percent_asian percent_hispanic percent_white percent_black 
reg app_crime_rate total_population percent_foreign_born percent_asian percent_hispanic percent_white percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
vif

//multicolinearity
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate i.county_cat i.year, vce(cluster county)
vif 

//updated models 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)

//all races 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic percent_white percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)


//percent hispanic only 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban poverty_rate, vce(cluster county)

//percent white 
xtreg app_crime_rate total_population percent_foreign_born percent_white providers_per_crime per_pop_urban poverty_rate, vce(cluster county)

//percent non-white 
//WE NEED OTHER FOR NATIVE AMERICAN SINCE THIS IS LARGE IN NM 
gen percent_nonwhite=percent_asian + percent_black + percent_hispanic 
tab percent_nonwhite 



//percent non-white 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban poverty_rate, vce(cluster county)

//removing pop urban 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime poverty_rate, vce(cluster county)
sum app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime poverty_rate




//make sure interpreting random effects correctly//
log close
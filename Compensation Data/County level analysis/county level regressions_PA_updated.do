/*=====================================================================================
Program Author: Shradha Sahani
Start Date: October 1, 2024
Last Updated: october 24, 2024 


Program Description: County level analysis of PA claims data.

Input:
	- cleaned PA county data 
	
Output:
	- regressions 

	
Programs to install:
xttest3 
=====================================================================================*/
ssc install xttest3 

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
log using "county_analysis_updated_$out_date.smcl", append

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
composition, access to service providers, % foreign born
	2. DV--contributory conduct, failure to supply information, time to approval 
=========================================================================================*/


//use data 
use "$analysis\PA_county_clean.dta", clear  

//new county indicator that is not a string 
encode county, gen(county_cat)

//summarising variables 
sum app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_white percent_black percent_asian percent_hispanic viol_crime_per10k hom_per100k num_service_providers med_hh_inc per_pop_urban

//rescaling percent variables 
/*
foreach var of varlist  percent_renter_occupied percent_vacant_units percent_foreign_born percent_white percent_black percent_asian percent_hispanic {
	replace `var'=`var'/100
}
*/

//checking correlations of independent variables
corr total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate
*percent foreign born and percent black is a little higher/ total population is highly correlated with % fb % black and % urban 

//checking correlations with percent foreign born and different races 
corr percent_foreign_born percent_asian percent_hispanic percent_white percent_black //these correlations are all pretty high 

//After making decisions in the previous models, we decided to include only the following variables in the analysis. 
//summary statistics
sum app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate

//outreg summary statistics 
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\cnty_descriptives_PA.xls", replace sum(log) keep(app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate) dec(2)  



/*=========================================================================================
Checking Assumptions
=========================================================================================
*/

//installing programs 
do "$dir\code\Victim Compensation\stepwise_regs.do" 
do "$dir\code\Victim Compensation\check_reg_assump.do" //installs check_reg_assump as well

//setting panel data 
xtset county_cat year

//dropping stored estimates if they exist 
cap estimates drop  RE*

/*these do files were giving an error
//stepwise regression
stepwise_regs app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, command(xtreg) options(re robust) prefix(RE) 

//checking assumptions
check_reg_assump app_crime_rate percent_renter_occupied, modelname(xtreg)
*/  

//DECIDING BETWEEN FIXED AND RANDOM EFFECTS//

//fixed effects 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, fe
estimates store fixed 


//random effects 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate
estimates store random 

//hausman test 
hausman fixed random, sigmamore //findings suggest re 


*testing for homoskedasticity 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, fe
xttest3 //there is heteroskedasticity so we need robust standard errors and cannot trust the results of the hausman test 


//xtoverid 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, robust
xtoverid, robust //not significant suggest random effects are appropriate 
xtoverid, cluster(county)

//breusch-pagan lagrange multiplier test 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, robust
xttest0 //random effects over pooled OLS 


//multicolinearity in the model 
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, robust
vif //vif statistics are pretty low 

//checking for outliers
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate
dfbeta

list _dfbeta_1 _dfbeta_2 _dfbeta_3 _dfbeta_4 _dfbeta_5 _dfbeta_6 if abs(_dfbeta_1) > 2/sqrt(_N) | abs(_dfbeta_2) > 2/sqrt(_N) | abs(_dfbeta_3) > 2/sqrt(_N) | abs(_dfbeta_4) > 2/sqrt(_N) | abs(_dfbeta_5) > 2/sqrt(_N) | abs(_dfbeta_6) > 2/sqrt(_N)

//looking into these observations 
list county year if abs(_dfbeta_1) > 2/sqrt(_N) | abs(_dfbeta_2) > 2/sqrt(_N) | abs(_dfbeta_3) > 2/sqrt(_N) | abs(_dfbeta_4) > 2/sqrt(_N) | abs(_dfbeta_5) > 2/sqrt(_N) | abs(_dfbeta_6) > 2/sqrt(_N)

//I will do a sensitivity analysis with and without these observations to see if the results change 
gen outlier=0
replace outlier=1 if abs(_dfbeta_1) > 2/sqrt(_N) | abs(_dfbeta_2) > 2/sqrt(_N) | abs(_dfbeta_3) > 2/sqrt(_N) | abs(_dfbeta_4) > 2/sqrt(_N) | abs(_dfbeta_5) > 2/sqrt(_N) | abs(_dfbeta_6) > 2/sqrt(_N)
 

//tests for model specification--they will only run with reg and not xtreg 
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
estat ovtest 
linktest  
 
/*=========================================================================================
Running Models 
=========================================================================================*/
 
//MODEL// 
//percent black 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
estimates store pa_county_perblack


//export tables to word 
esttab pa_county_perblack using "${dir}\data\Deliverables\pa_county_regressions.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Longitudinal Linear Random Effects Models Predicting County Application Rates") ///
    mtitle("Model 1") ///
    nonumbers ///
    /*addnotes("Note: )*/ ///
	label replace 
	
	
//Sensivity analysis without outliers 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban_interp poverty_rate if outlier==0, vce(cluster county)
//without the outliers percent foreign born is significant 
//we will need to decide how to discuss this in the paper 


//Because of the colinearity between the race groups we test % Hispanic and % BOPIC as well. This will go in the appendix. 

//percent Hispanic 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
estimates store pa_county_perhispanic 


//checking outliers 
reg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban_interp poverty_rate
dfbeta 

gen outlier_hisp=0
replace outlier_hisp=1 if abs(_dfbeta_7) > 2/sqrt(_N) | abs(_dfbeta_8) > 2/sqrt(_N) | abs(_dfbeta_9) > 2/sqrt(_N) | abs(_dfbeta_10) > 2/sqrt(_N) | abs(_dfbeta_11) > 2/sqrt(_N) | abs(_dfbeta_12) > 2/sqrt(_N)
 
xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban_interp poverty_rate if outlier_hisp==0, vce(cluster county) //no difference in results 

//percent non-white 
gen percent_nonwhite=percent_asian + percent_black + percent_hispanic 
tab percent_nonwhite 
label variable percent_nonwhite "% BIPOC"


xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban_interp poverty_rate, vce(cluster county)
estimates store pa_county_perbipoc

//checking outliers 
reg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban_interp poverty_rate
dfbeta 

gen outlier_bipoc=0
replace outlier_bipoc=1 if abs(_dfbeta_13) > 2/sqrt(_N) | abs(_dfbeta_14) > 2/sqrt(_N) | abs(_dfbeta_15) > 2/sqrt(_N) | abs(_dfbeta_16) > 2/sqrt(_N) | abs(_dfbeta_17) > 2/sqrt(_N) | abs(_dfbeta_18) > 2/sqrt(_N)
 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban_interp poverty_rate if outlier_bipoc==0, vce(cluster county) //no difference in results 



//export tables to word 
esttab pa_county_perhispanic pa_county_perbipoc using "${dir}\data\Deliverables\pa_county_regressions.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Longitudinal Linear Random Effects Models Predicting County Application Rates") ///
    mtitle("Percent Hispanic" "Percent BIPOC") ///
    nonumbers ///
    /*addnotes("Note: )*/ ///
	label append 


//close log 
log close 
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
corr total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate
*percent foreign born and percent black is a little higher/ total population is highly correlated with % fb % black and % urban 

//checking correlations with percent foreign born and different races 
corr percent_foreign_born percent_asian percent_hispanic percent_white percent_black 


//summary statistics
sum app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate

//outreg summary statistics 
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\cnty_descriptives_PA.xls", replace sum(log) keep(app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate) dec(2)  

/*=========================================================================================
Running Models 
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
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, fe
estimates store fixed 


//random effects 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban
estimates store random 

//hausman test 
hausman fixed random, sigmamore //findings suggest re 


*testing for homoskedasticity 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, fe
xttest3 //there is heteroskedasticity so we need robust standard errors and cannot trust the results of the hausman test 


//xtoverid 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, robust
xtoverid, robust //not significant suggest random effects are appropriate 
xtoverid, cluster(county)

//breusch-pagan lagrange multiplier test 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, robust
xttest0 //random effects over pooled OLS 


//multicolinearity in the model 
reg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, robust
vif 

//FINAL MODEL WITH CLUSTERED STANDARD ERRORS
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black num_service_providers med_hh_inc per_pop_urban, vce(cluster county)


outreg2 using "$analysis\PA_cnty_models_$out_date.xls", replace title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)

//testing some interactions--urban and black
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born num_service_providers med_hh_inc c.per_pop_urban##c.percent_black, vce(cluster county) //no evidence of interaction effect

//interaction service providers and urban 
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black  med_hh_inc c.per_pop_urban##c.num_service_providers, vce(cluster county) //no evidence of interaction effect

//urban and disadvantage interaction
xtreg app_crime_rate percent_renter_occupied percent_vacant_units percent_foreign_born percent_black  c.per_pop_urban##c.med_hh_inc num_service_providers, vce(cluster county) //there is an interaction effect
outreg2 using "$analysis\PA_cnty_models_$out_date.xls", append title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)

 

//graphing the interaction for easier interpretation 
margins, at(per_pop_urban=(0(.2)1) med_hh_inc=(0(20)100))
marginsplot, xdimension(per_pop_urban) by(med_hh_inc)
//interpretation-- increasing median HH income and % urban, is associated with higher application per crime rates (less disparity in application and crime rates as HH income increases). THe more affluent a county the less disparity in applications per crime rates (med HH income=disadvantage so higher income means lower disadvantage)



//graphing the interaction for easier interpretation 
margins, at(per_pop_urban=(0(.5)1) med_hh_inc=(0(50)100))
marginsplot, xdimension(per_pop_urban) by(med_hh_inc)

//updated modesl 10/31/24
reg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
vif //vif statistics are low but correlations are high so check models with and without total population 

xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", replace title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)

//taking out total population--no change to results 
xtreg app_crime_rate percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", append title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)

//using median hh income instead of poverty rate 
xtreg app_crime_rate percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", append title(model 3) bdec(2) tdec(3) rdec(3) sdec(2)

//median household income and total population 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc, vce(cluster county)

//median hh income and poverty rate 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban med_hh_inc poverty_rate, vce(cluster county)

//descriptives 
sum app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate



//outreg summary statistics 
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\cnty_descriptives_PA.xls", replace sum(log) keep(app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate) dec(2)  

//
corr percent_foreign_born percent_asian percent_hispanic percent_white percent_black 
reg app_crime_rate total_population percent_foreign_born percent_asian percent_hispanic percent_white percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)


//UPDATED 2/26/25//

//label variables 
label var total_population "Total Population"
label var percent_foreign_born "% Foreign Born"
label var percent_black "% Black"
label var percent_hispanic "% Hispanic"
label var providers_per_crime "Providers per 1,000 Violent Crimes"
label var per_pop_urban "% Urban Population"
label var poverty_rate "Poverty Rate"


//percent non-white 
gen percent_nonwhite=percent_asian + percent_black + percent_hispanic 
tab percent_nonwhite 
label variable percent_nonwhite "% BIPOC"

//outreg summary statistics 
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\cnty_descriptives_PA_$out_date.xls", replace sum(log) keep(app_crime_rate total_population percent_foreign_born percent_black percent_nonwhite percent_hispanic providers_per_crime per_pop_urban poverty_rate) dec(2) label

//percent black 
xtreg app_crime_rate total_population percent_foreign_born percent_black providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", replace label title(model 1) bdec(2) tdec(3) rdec(3) sdec(2)



//margins to visulize data 
margins, at(percent_black=(0(.5)1))

#d ;
marginsplot, 
	title("Predicted Application Rate for County % Black")
	ytitle("Predicted Application Rate")
	xtitle("County Percent Black")
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    name(per_black_margins, replace);
#d cr 

//providers per crime 
margins, at(providers_per_crime=(0(.5)1))
#d ;
marginsplot, 
	title("Predicted Application Rate Based on Providers in the County")
	ytitle("Predicted Application Rate")
	xtitle("Providers per 1,000 violent crimes")
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    name(per_black_margins, replace);
#d cr 


//predicted probabilities

//percent nonwhite 
xtreg app_crime_rate total_population percent_foreign_born percent_nonwhite providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", append label title(model 2) bdec(2) tdec(3) rdec(3) sdec(2)

//margins to visulize data 
margins, at(percent_nonwhite=(0(.5)1))

#d ;
marginsplot, 
	title("Predicted Application Rate for County % Black")
	ytitle("Predicted Application Rate")
	xtitle("County Percent BIPOC")
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    name(per_bipoc_margins, replace);
#d cr 


//percent hispanic 
reg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban poverty_rate
vif 


xtreg app_crime_rate total_population percent_foreign_born percent_hispanic providers_per_crime per_pop_urban poverty_rate, vce(cluster county)
outreg2 using "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\PA Compensation Data\PA_cnty_models_$out_date.xls", append label title(model 3) bdec(2) tdec(3) rdec(3) sdec(2)




//make sure interpreting random effects correctly//
log close
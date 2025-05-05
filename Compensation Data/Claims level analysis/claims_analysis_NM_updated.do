/*=====================================================================================
Program Author: Shradha Sahani
Start Date: January 2, 2025
Last Updated: March 10, 2025


Program Description: Claims level analysis of NM data. 

Input:
	- NM claims data cleaned after imputation and set for analysis 	
	
Output:
	- checking assumptions 
	- regressions

	
//install mivif to check vif statistics after mi estimate 
ssc install mivif
ssc install mimrgns //average marginal effects after multiple imputation 
ssc install misum //summary statistics after mi 
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
log using "claims_imputed_analysis_$out_date.smcl", append


/*=====================================================================================
Define the names of the datasets to use
--------------------------------------------------------------------------------------
=======================================================================================*/ 
global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp" 

global data="$dir\data\Raw\2.Phase 2 State" //directory for data files
global NM="$dir\data\Raw\2.Phase 2 State\NM" //directory for NM data files

global analysis="$dir\data\Analysis\Phase 2 State" //directory for analysis files 
global clean="$dir\data\Clean" //directory for clean files 
global code_directory="$dir\code\Victim Compensation"
global raw="$dir\data\Raw\2. Phase 2 State\NM\NM BIFSG" //directory for raw data files

cd "$dir" //setting directory 


//set macros for what you need this file to do 

global check_assumptions "yes" //no if you don't need to rerun the checks 
global approved_models "yes" //no if you don't need to run approved models 
global lost_wages_modes "yes" //no if you don't need to run lost wages regressions  

/*=========================================================================================
Summary Statistics 
=========================================================================================

Models 
	1. DV--Approval (payment), payments for lost wages)
		neighborhood variables--poverty, number of service providers 
		individual variables--race, age, sex, crime type 
	
=========================================================================================*/
use "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_foranalysis_updated.dta", clear  


//pooled summary statistics 
sum approved lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov 

//to export summary statistics we need dummy variables
tab race_w_imp, gen(race_imp_dummy)

drop ameind api black hisp multi white other //drop old race vars without imputation 

rename race_imp_dummy1 ameind 
rename race_imp_dummy2 api 
rename race_imp_dummy3 black 
rename race_imp_dummy4 hispanic 
rename race_imp_dummy5 other 
rename race_imp_dummy6 white 


//export summary statistics 
preserve 
drop if imp_num==0 //drop dataset with missing race
estpost sum approved lost_wages_exp ameind api black hispanic white other age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov , detail
esttab using "${dir}\data\Deliverables\nm_descriptives.csv", replace cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label csv
restore 

/*=========================================================================================
Claims level regressions in NM 
=========================================================================================

Models 
	1. DV--Approval (payment), payments for lost wages)
		neighborhood variables--poverty, number of service providers 
		individual variables--race, age, sex, crime type 

		
Notes: In previous analyses, claims_analysis_NM.do we ran into problems with other api and 
other separately in the models so we combine them here 
=========================================================================================*/
//xtset with neighborhood panel var 
mi xtset victim_zip //unbalanced panel 


//dropping duplicate applications
drop if denial_reason7==1


//data has to be saved before mi commands can run 
save "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_foranalysis_updated_2.dta", replace


/****************************************************************************************
//Checking assumptions//
Dependent Variable--Approval  
=========================================================================================
We only look at complete applications. 
*****************************************************************************************/
use "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_foranalysis_updated_2.dta", clear

if "$check_assumptions" == "yes" & "$approved_models" =="yes" {


//Checking assumptions//

*multicolinearity 
mi estimate: reg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (den_fail_info==0)
mivif 


//Notes: To check whether the random effects or pooled model is better we can just test dataset at a time because of limitations with multiply imputed data. The limitation is that it could change in the datasets. I run the imputation on more than one, say 10, with a loop, and check xttest0
forvalues i = 1/10 { 
	di "About to check for `i' " 
	preserve // Needed, because mi extract replaces data in memory
	//run comparison on 1st dataset 
	mi extract `i', clear //extract first dataset but does not change the original data 
	di "N for imputed dataset 2: " _N //
	qui xtreg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (den_fail_info==0 & imp_num==`i'), re vce(cluster victim_zip) //random effects //**

	xttest0 //significant which suggests random effects 

	//approved model 
	sum approved if imp_num==`i' //we can use an LPM here because the frequency is higher
	restore //
} 
//significant .0000 for all 10.


//large cities only 
hist approved if large_city==1 & imp_num!=0 //exlcuding missing dataset 
sum approved if large_city==1 & imp_num!=0 //we can use lpm for this since the mean is 0.38 

*multicolinearity 
mi estimate: reg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (large_city==1 & den_fail_info==0)
mivif 


//Notes: To check whether the random effects or pooled model is better we can just test dataset at a time because of limitations with multiply imputed data. The limitation is that it could change in the datasets. I run the imputation on more than one, say 10, with a loop, and check xtset
forvalues i = 1/10 { 
	di "About to check for `i' " 
	preserve // Needed, because mi extract replaces data in memory
	//run comparison on 1st dataset 
	mi extract `i', clear //extract first dataset 
	di "N for imputed dataset 2: " _N //
	qui xtreg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (large_city==1 & den_fail_info==0 & imp_num==`i'), re vce(cluster victim_zip) //random effects //**

	xttest0 //significant which suggests random effects 

	//approved model--we use 
	sum approved if imp_num==`i' //we can use an LPM here because the frequency is higher
	restore //
} 
//

}
//xxtest0 is not significant in any the models for the large cities. So I run pooled models as well in the next set of analyses. 


/****************************************************************************************
//Checking assumptions//
Dependent Variable--Payment for Lost Wages  
=========================================================================================
We only look at approved applications. 
*****************************************************************************************/


if "$check_assumptions" == "yes" & "$lost_wages_modes" =="yes" {

//multicolinearity
mi estimate: reg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1) 
mivif 

//logit vs lpm 
hist lost_wages_exp if (approved==1 &imp_num!=0 )
sum lost_wages_exp if (approved==1 &imp_num!=0 ) //mean is .26 so lpm is okay 

//Notes: To check whether the random effects or pooled model is better we can just test dataset at a time because of limitations with multiply imputed data. The limitation is that it could change in the datasets. I run the imputation on more than one, say 10, with a loop, and check xtset
forvalues i = 1/10 { 
	di "About to check for `i' " 
	preserve // Needed, because mi extract replaces data in memory
	//run comparison on 1st dataset 
	mi extract `i', clear //extract first dataset 
	di "N for imputed dataset 2: " _N //
	qui xtreg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1 & imp_num==`i'), re vce(cluster victim_zip) //random effects //**

	xttest0 //significant which suggests random effects 

	//approved model--we use 
	sum lost_wages_exp if imp_num==`i' //we can use an LPM here because the frequency is higher 
	restore //
} 
//significant .0000 for all 10.


//large cities 

//multicolinearity
mi estimate: reg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1 & large_city==1)
mivif 

//logit vs lpm 
hist lost_wages_exp if (approved==1 & large_city==1 &imp_num!=0 )
sum lost_wages_exp if (approved==1 & large_city==1 &imp_num!=0 ) //mean is .27 so lpm is okay 

//Notes: To check whether the random effects or pooled model is better we can just test dataset at a time because of limitations with multiply imputed data. The limitation is that it could change in the datasets. I run the imputation on more than one, say 10, with a loop, and check xtset
forvalues i = 1/10 { 
	di "About to check for `i' " 
	preserve // Needed, because mi extract replaces data in memory
	//run comparison on 1st dataset 
	mi extract `i', clear //extract first dataset 
	di "N for imputed dataset 2: " _N //
	qui xtreg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1 & large_city==1 & imp_num==`i'), re vce(cluster victim_zip) //random effects //

	xttest0 //significant which suggests random effects 

	//approved model--we use 
	sum lost_wages_exp if imp_num==`i' //we can use an LPM here because the frequency is higher 
	restore //
} 
//significant .0000 for all 10.

}

//xxtest0 is not significant in any of these models. So I run pooled models as well in the next set of analyses. 
/****************************************************************************************
Running regressions 
=========================================================================================
*****************************************************************************************/

/****************************************************************************************
//Running models//
Dependent Variable--Approval  
=========================================================================================
We only look at complete applications. 
*****************************************************************************************/


if "$approved_models" =="yes" {

*MODEL 1a: entire state 
mi estimate, saving("$analysis\NM Compensation Data\approved_model1", replace): xtreg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (den_fail_info==0), re vce(cluster victim_zip) 

*MODEL 1b: large cities only 
//large city//
mi estimate, saving("$analysis\NM Compensation Data\approved_model1b", replace): xtreg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (large_city==1 & den_fail_info==0), re vce(cluster victim_zip) 


//create tables
estimates use "$analysis\NM Compensation Data\approved_model1"
estimates store approved_model1 

estimates use "$analysis\NM Compensation Data\approved_model1b"
estimates store approved_model2

//export tables to word 
esttab approved_model1 approved_model2 using "${dir}\data\Deliverables\nm_regressions_updated.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Random effects Linear Probability Models Predicting Approval") ///
    mtitle("(Entire State)" "(Major Cities Only)") ///
    nonumbers ///
    addnotes("Note: Models only look at complete applications.") ///
	label replace 
	
	
//pooled model for large cities 
mi estimate, saving("$analysis\NM Compensation Data\approved_model1b_pooled", replace): reg approved ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (large_city==1 & den_fail_info==0), cluster (victim_zip) 


estimates use "$analysis\NM Compensation Data\approved_model1b_pooled"
estimates store approved_model2_pooled

//export tables to word 
esttab approved_model2_pooled using "${dir}\data\Deliverables\nm_regressions_updated.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Linear Probability Models Predicting Approval") ///
    mtitle("Major Cities Only Pooled)") ///
    nonumbers ///
    addnotes("Note: Models only look at complete applications.") ///
	label append 
	

}


/****************************************************************************************
//Running Models//
Dependent Variable--Payment for Lost Wages  
=========================================================================================
We only look at approved applications. 
*****************************************************************************************/
 
if "$lost_wages_modes" =="yes" {

*MODEL 2a: 
//entire state//
mi estimate, saving("$analysis\NM Compensation Data\lostwages_model2a", replace): xtreg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1) , re vce(cluster victim_zip) 

*Model 2b: 
//large city//
mi estimate, saving("$analysis\NM Compensation Data\lostwages_model2b", replace): xtreg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1 & large_city==1), re vce(cluster victim_zip)


//create tables
estimates use "$analysis\NM Compensation Data\lostwages_model2a"
estimates store lostwages_model2a 

estimates use "$analysis\NM Compensation Data\lostwages_model2b"
estimates store lostwages_model2b

//export tables to word 
esttab lostwages_model2a lostwages_model2b using "${dir}\data\Deliverables\nm_regressions_updated.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Random effects Linear Probability Models Predicting Payments for Lost Wages") ///
    mtitle("(Entire State)" "(Major Cities Only)") ///
    nonumbers ///
    addnotes("Note: Models only look at approved applications with payments.") ///
	label append 
	
	
//POOLED MODELS 
//entire state//
mi estimate, saving("$analysis\NM Compensation Data\lostwages_model2a_pooled", replace): reg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1), cluster(victim_zip) 

*Model 2b: 
//large city//
mi estimate, saving("$analysis\NM Compensation Data\lostwages_model2b_pooled", replace): reg lost_wages_exp ib6.race_w_imp age male crime_homicide crime_sex_assualt crime_dom_assault pct_below_poverty log_mi_near_prov if (approved==1 & large_city==1), cluster(victim_zip) 


//create tables
estimates use "$analysis\NM Compensation Data\lostwages_model2a_pooled"
estimates store lostwages_model2a_pooled 

estimates use "$analysis\NM Compensation Data\lostwages_model2b_pooled"
estimates store lostwages_model2b_pooled


//export tables to word 
esttab lostwages_model2a_pooled lostwages_model2b_pooled using "${dir}\data\Deliverables\nm_regressions_updated.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N p, fmt(0 3) labels("Observations"  "p({\i F})")) ///
    title("Linear Probability Models Predicting Payments for Lost Wages") ///
    mtitle("(Entire State Pooled)" "(Major Cities Only Pooled)") ///
    nonumbers ///
    addnotes("Note: Models only look at approved applications with payments.") ///
	label append 

}

log close 


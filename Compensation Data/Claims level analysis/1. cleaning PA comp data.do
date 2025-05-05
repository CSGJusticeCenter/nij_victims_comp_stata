/*=====================================================================================
Program Author: Shradha Sahani
Start Date: September 16, 2024
Last Updated: March 13, 2025


Program Description: Cleaning PA claims data 

Input:
	- PA claims data 
	
Output:
	- cleaned data file that we can use for the imputation and for any data analysis. 
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
log using "cleaning_PA_comp_$out_date.smcl", append

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


//using Pennsylvania data 
import delimited "$clean\Ad Hoc\PA_comp_w_census_dummy_for_Shradha_20230915.csv", bindquote(strict) clear


//dropping claims for rape--forensic exams 
tab crime_type_rapeforensicrapeclaim
drop if crime_type_rapeforensicrapeclaim=="1"

/*=====================================================================================
Recoding Race 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
//recode victim_race 
tab victim_race 

gen ameind=0 
replace ameind=1 if victim_race=="American Indian or Alaska Native" 
replace ameind=. if inlist(victim_race, "NA", "Not Known")
tab ameind, m 

gen api=0 
replace api=1 if victim_race=="Asian and Pacific Islander"
replace api=. if inlist(victim_race,"NA", "Not Known")
tab api, m 

gen black=0 
replace black=1 if victim_race=="Black"
replace black=. if inlist(victim_race, "NA", "Not Known")
tab black, m 

gen hisp=0 
replace hisp=1 if victim_race=="Hispanic or Latino"
replace hisp=. if inlist(victim_race, "NA", "Not Known")
tab hisp, m 

gen white=0
replace white=1 if victim_race=="White"
replace white=. if inlist(victim_race, "NA", "Not Known")
tab white, m 

gen other=0
replace other=1 if victim_race=="Other"
replace other=. if inlist(victim_race, "NA", "Not Known")
tab other, m 

/*
//renaming variables to make it clear it's the victim 
foreach var of varlist ameind-other {
	gen victim_`var'=`var'
}
*/

//label the variables
label var api "Asian, Pacific Islander, or Native Hawaiian"
label var ameind "American Indian or Alaska Native"
label var black "Black or African American"
label var hisp "Hispanic or Latino"
label var white "White"
label var other "Two or more races (not Hispanic or Latino) or some other race"


/*=====================================================================================
Recoding variables 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//cleaning victim zip 
gen less_than_5_zip = strlen(victim_zip) < 5
tab less_than_5_zip
replace victim_zip="." if less_than_5_zip==1


//rename & recode variables
rename victim_sex gender
tab gender
replace gender="" if gender=="NA"


replace age_of_victim_at_time_of_crime="" if age_of_victim_at_time_of_crime=="NA"
tab age_of_victim_at_time_of_crime
destring age_of_victim_at_time_of_crime, replace 

rename age_of_victim_at_time_of_crime age 
tab age 
replace age=. if age<0
tab age 
label var age "Age at time of crime"

//cleaning gender variable 
gen male=. 
replace male=1 if gender=="Male"
replace male=0 if gender=="Female"
tab male
label var male "Victim gender"

/*=====================================================================================
Recoding Approval/Denial
--------------------------------------------------------------------------------------
these decisions are based of the classifications recorded in 
"claim outcomes classifications_v1" in the analysis plan folder 
=======================================================================================*/ 

//creating an indicator for approved claims 
tab claim_status

//approved claims 
gen approved=0 
replace approved=1 if inlist(claim_status, "Open-Financial-In-Active", "Closed-Financial-Maximum Compensation", "Open-Determination-Decision Pending", "Open-Supplemental Award-Pending", "Open-Financial-Pending Payment")
replace approved=1 if claim_disposition=="Monetary Maximum Met"
tab approved 
//in pa this means paid 

//denied 
gen denied=0
replace denied=1 if inlist(claim_status,"Closed-Determination-Final Decision")
replace denied=0 if claim_status=="Closed-Determination-Final Decision" & regexm(claim_disposition, "Failure to supply")
replace denied=0 if claim_disposition=="Monetary Maximum Met" & claim_status=="Closed-Determination-Final Decision"
replace denied=0 if claim_disposition=="Other resources available for services provided" &  claim_status=="Closed-Determination-Final Decision"
replace denied=0 if claim_disposition=="Victim/Claimant moved -cannot locate" &  claim_status=="Closed-Determination-Final Decision"
tab denied 

//not paid 
gen not_paid=0 
replace not_paid=1 if approved==0 & denied==0 
tab not_paid

//create categorial variable for application status
gen app_status=. 
replace app_status=1 if approved==1 //paid
replace app_status=2 if not_paid==1 //not paid
replace app_status=3 if denied==1 //denied 
tab app_status, m 

label define app_status_lbl 1 "Paid" 2 "Not Paid" 3 "Denied"
label values app_status app_status_lbl 
label variable app_status "Application Status"

//denial for failure to supply information 
tab claim_disposition
gen den_fail_info= regexm(claim_disposition, "Failure to supply")
tab claim_disposition if den_fail_info==0 //checking variable 

//label variable 
label variable den_fail_info "Denial due to failure to provide info."


//saving file 
tempfile pa_comp_clean 
save `pa_comp_clean'


/*=====================================================================================
Merging with city/zip list 
--------------------------------------------------------------------------------------
The PA claims data doesn't list the city so I am merging the zip codes to a list of 
cities so we have this for any city-level analysis. 
=======================================================================================*/ 
import delimited "$clean\Ad Hoc\zip_codes_NM_and_PA.csv", bindquote(strict) clear 

//keeping only PA cities 
drop if state=="NM"

//keeping only the variables we need 
keep zipcode major_city state

//renaming for merge 
rename zipcode victim_zip 
tostring victim_zip, replace 

//merging with PA comp data 
merge 1:m victim_zip using `pa_comp_clean'

//looking at those in the claims data that did not merge
tab victim_zip if _merge==2 //these are out of state I think 

//those that are only in the zip code data meaning that they had no claims
drop if _merge==1 

//drop merge variable 
drop _merge 

//remaning variable 
rename major_city victim_city 


/*=====================================================================================
Recoding Crime Type
--------------------------------------------------------------------------------------
=======================================================================================*/ 
tab crime_type_homicide 
tab crime_type_homicidedomestic 
tab crime_type_homicidebyvehicle

//homicide indicator 
gen crime_homicide=0
replace crime_homicide=1 if crime_type_homicide=="1" |  crime_type_homicidedomestic=="1" | crime_type_homicidebyvehicle=="1"
replace crime_homicide=. if crime_type_homicide=="NA"
tab crime_homicide, m 
label variable crime_homicide "Application for Homicide Victimization"

//Sexual assault 
gen crime_sex_assault=0 
replace crime_sex_assault=1 if crime_type_sexualassaultnonfamil=="1" | crime_type_sexualassaultfamilydo=="1"
replace crime_sex_assault=. if crime_type_sexualassaultnonfamil=="NA" & crime_type_sexualassaultfamilydo=="NA"
tab crime_sex_assault, m 
label variable crime_sex_assault "Application for Sexual Assault Victimization"

//crime domestic violence 
gen crime_dom_assault=0
replace crime_dom_assault=1 if crime_type_assaultdomestic=="1"
replace crime_dom_assault=. if crime_type_assaultdomestic=="NA"
tab crime_type_assaultdomestic crime_dom_assault, m 
label variable crime_dom_assault "Application for Domestic Violence Victimization"

//checking how many state police or sherriffs offices
preserve
collapse (count) claim_number, by(police_dept_name)

tab claim_number if strpos(police_dept_name, "Sherif") > 0 | strpos(police_dept_name, "State") > 0

tab claim_number if strpos(police_dept_name, "Sherif") == 0 & strpos(police_dept_name, "State") == 0


tab claim_number if strpos(police_dept_name, "State") > 0
restore

/*=====================================================================================
Recoding Payment Expense Types
--------------------------------------------------------------------------------------
Notes: In payment types,  LOE="loss of earnings" is coded as lost wages for any reason. 
=======================================================================================*/ 
tab payment_expense_types
replace payment_expense_types="" if payment_expense_types=="NA"

//creating individual variables for the different expenses 
split payment_expense_types, parse(,) generate(payment_type)

//looking at different payment types 
tab payment_type1 

//creating indicator for lost wages payment 
gen payment_lost_wages = 0

//replacing lost wages=1 if LOE is a payment type in any of the payment type variables 
foreach var of varlist payment_type* {
	replace payment_lost_wages=1 if regexm(`var', "LOE") 
}

replace payment_lost_wages=. if payment_expense_types==""
sum payment_lost_wages if approved==1

///Coding payment types 
//we need to identify all the unique payment types in the data but some are listed as one payment with a dash so we don't want to separate the dash

tab payment_expense_types
tab payment_type1

//variable label and encode and then egen row 

forvalues i=1/12 {
	encode payment_type`i', gen(payment_cat`i') label(payment_cats)
}

levelsof payment_type12
label list payment_cats
local categoriesn=r(k)

forvalues i=1/`categoriesn' {
	gen pay_type`i'=0
	forvalues j=1/12 {
		replace pay_type`i'=1 if payment_cat`j'==`i'
	}
	local cat`i' : label payment_cats `i'
	label var pay_type`i' "`cat`i''"
}

//renaming variables by the group they belong to (medical, funeral, other, counseling)
foreach var of varlist pay_type* {
    local varlabel : variable label `var'

	//medical 
    if strpos("`varlabel'", "Lenses") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Denture") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Glasses") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Hearing Aid") > 0  label variable `var' "Medical-`varlabel'" // hearing aid
    if strpos("`varlabel'", "Medications") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Physical") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Hospital") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Health") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Dental") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Doctor") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Walker") > 0  label variable `var' "Medical-`varlabel'"
    if strpos("`varlabel'", "Wheel Chair") > 0  label variable `var' "Medical-`varlabel'"
        if strpos("`varlabel'", "Ambulance") > 0  label variable `var' "Medical-`varlabel'"

    // Add combinations, e.g., renaming "Memorial" to "Funeral"
    if strpos("`varlabel'", "Memorial") > 0  label variable `var' "Funeral-`varlabel'"
	if strpos("`varlabel'", "Cemetery") > 0  label variable `var' "Funeral-`varlabel'"
    if strpos("`varlabel'", "Clothing for Deceased") > 0  label variable `var' "Funeral-`varlabel'"

	//counseling 
	if strpos("`varlabel'", "Non-traditional Therapy") > 0  label variable `var' "Counseling-`varlabel'"
	if strpos("`varlabel'", "Non-traditional therapy") > 0  label variable `var' "Counseling-`varlabel'"

	//other 
	if strpos("`varlabel'", "Child Care") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Crime-scene Cleanup") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Crime-Scene Cleanup") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Replace Documents") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Miscellaneous") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Replacement Services") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "not") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Tuition") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Reports Purchase") > 0  label variable `var' "Other-`varlabel'"
	if strpos("`varlabel'", "Renovations") > 0  label variable `var' "Other-`varlabel'"

}

//combining variables based on labels 
local maincats Medical Funeral Relocation LOE Loss Attorney Counseling Transportation Other Stolen

foreach cat in `maincats' {
	di as error "`cat'"
	gen `cat'= 0 
	foreach var of varlist pay_type* {
		local varlabel : variable label `var'
		di	"`varlabel'"
		replace `cat'=1 if strpos("`varlabel'","`cat'") > 0 & `var'==1
	}
}

rename Loss loss_support 


//saving file 
save "$analysis\PA Compensation Data\PA_comp_clean.dta", replace 


log close 


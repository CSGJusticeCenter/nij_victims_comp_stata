/*=====================================================================================
Program Author: Shradha Sahani
Start Date: September 16, 2024
Last Updated: September 16, 2024 


Program Description: Cleaning NM claims data 

Input:
	- raw NM claims data 
	
Output:
	- cleaned data file 
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



/*=====================================================================================
Cleaning primary and secondary victims claims 
--------------------------------------------------------------------------------------
NM Data Structure: The structure of the data is different in the old system (Helix, until mid-2018) and CCVC (the new system). In the old system, all claims associated with the same primary victim are listed as one row with a single claim number. In the CCVC system, the secondary claims are listed separately with the same claim number followed by a letter (e.g., 11564648, 11564648a). This would allow us to merge the claims together into one single claim for all claimants associated with the same primary victimization to compare the data between the old and new system. 

In this step we will be keeping only the primary victim claim in the data from CCVC system. This means dropping all the claims that have a letter in them. 
=======================================================================================*/ 

//NM claims data--this file was cleaned by Amund from the raw data
import delimited "$clean\Victim Compensation\victim_claims_NM_updated.csv", bindquote(strict) clear 

//trimming claim_number in case there's extra spaces 
replace claim_number=trim(claim_number)

//identify all claims with a letter that signifies they are secondary victim claims in CCVC. 
gen claim_has_letter = regexm(claim_number, "[A-Za-z]")  // creating an indicator if the claim number has a letter 
tab claim_has_letter, m //131 claims have a letter. Some claims have multiple secondary victims (a, b, c, d suffix on claim_numbers)
list claim_number if claim_has_letter==1 //visually checking these claims 

//generating a new claim_number for these claims 
gen claim_number_noletter=regexr(claim_number, "[A-Za-z]", "") if claim_has_letter==1 
replace claim_number_noletter=claim_number if claim_has_letter!=1 //keep the claim number for all other claims 

duplicates report claim_number_noletter
duplicates tag claim_number_noletter, gen(dup_claim_noletter)
tab dup_claim_noletter
tab claim_has_letter if dup_claim_noletter==0 //there are 14 claims that are identified as secondary victim claims but have no primary victim associated

//since we know these 14 to be secondary victim claims, I will still drop them from the analysis since we are using only primary victim claims 
drop if claim_has_letter==1 //we should be dropping all 131 claims with a letter 

//checking if claim_number and claim_number_noletter are the same as they should be 
gen claim_number_same=1 if claim_number==claim_number_noletter
tab claim_number_same

//dropping additional claim number variables used in this step since we no longer need them 
drop claim_has_letter claim_number_noletter claim_number_same

//saving tempfile for merge in next step 
tempfile nm_comp
save `nm_comp'

/*=====================================================================================
Merging payments data 
--------------------------------------------------------------------------------------
In NM the payments file is separate so I will merge that with the rest of the claims data. 
=======================================================================================*/ 

import delimited "$clean\Victim Compensation\victim_payments_NM_updated.csv", bindquote(strict) varnames(1) clear 

//trimming claim_number in case there's extra spaces 
replace claim_number=trim(claim_number)

//check for claims with letters 
gen claim_has_letter = regexm(claim_number, "[A-Za-z]")  // creating an indicator if the claim number has a letter 
tab claim_has_letter, m //134 claims with letters 

//generating a new claim number without letters that we will merge with the claims data 
gen claim_number_noletter=regexr(claim_number, "[A-Za-z]", "") if claim_has_letter==1 
replace claim_number_noletter=claim_number if claim_has_letter!=1 //keep the claim number for all other claims 

//cleaning variables 
foreach var of varlist lossofwages-legacypayments {
	replace `var'="" if `var'=="NA"
	destring `var', replace 
}

//collapse data to merge all payments associated with a primary victimization into one 
collapse (sum) lossofwages-legacypayments, by (claim_number_noletter)

//renaming variable 
rename claim_number_noletter claim_number 

//merge with claims data 
merge 1:1 claim_number using `nm_comp'

//exploring the claims from the payment file that didn't merge 
tab claim_number if _merge==1 //these don't exist in the claims data. 
br claim_number if _merge==1

//I am dropping these claims because we don't have any claims information for them 
tab _merge 
drop if _merge==1 

//creating a variable for no payment for the claim 
gen no_payment=0 
replace no_payment=1 if _merge==2 //these are claims in the comp data that aren't in the payment data 
tab no_payment

drop _merge


/*=====================================================================================
Recoding zip codes 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
//checking that all claims have been collapsed together by claim number 
duplicates list claim_number //no duplicates 


//cleaning victim zip 
tab victim_zip if strlen(victim_zip) < 5 
gen less_than_5_zip = strlen(victim_zip) < 5
replace less_than_5_zip=. if victim_zip==""
tab less_than_5_zip, m 
replace victim_zip="." if less_than_5_zip==1

//removing hyphenated zip codes 
replace victim_zip = substr(victim_zip, 1, 5) if strpos(victim_zip, "-") > 0

//checking zip codes with more than 5 characters 
tab victim_zip if strlen(victim_zip) > 5

//recoding missing and longer zip codes 
replace victim_zip="." if victim_zip=="Not Provided" | victim_zip=="unknown"
replace victim_zip="." if victim_zip==""
replace victim_zip="87004" if victim_zip=="NM 87004"
replace victim_zip = substr(victim_zip, 1, 5)

//recoding victim_zip
gen non_numeric = regexm(victim_zip, "[^0-9]") // Identifies non-numeric characters
list victim_zip if non_numeric == 1 & victim_zip!="." //no non-numeric characters in zip code now 

//missing victim_zip 
tab victim_zip if victim_zip=="." & victim_state=="NM"


/*=====================================================================================
Recoding Race 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
//recode victim_race 
tab victim_race 

gen ameind=0 
replace ameind=1 if victim_race=="American Indian / Alaska Native" 
replace ameind=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
tab ameind, m 

gen api=0 
replace api=1 if victim_race=="Asian" | victim_race=="Native Hawaiian and other Pacific Islanders"
replace api=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
tab api, m 

gen black=0 
replace black=1 if victim_race=="Black/African American"
replace black=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
tab black, m 

gen hisp=0 
replace hisp=1 if victim_race=="Hispanic or Latino"
replace hisp=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
tab hisp, m 

gen white=0
replace white=1 if victim_race=="White Non-Latino/Caucasian" | victim_race=="Hhite Non-Latino/Caucasian"
replace white=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
tab white, m 

gen other=0
replace other=1 if inlist(victim_race, "Multiple races", "Some other race")
replace other=. if inlist(victim_race, "80", "Unknown", "NA", "Not Reported")
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
Cleaning variables
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//rename & recode variables
rename victim_sex gender
tab gender
replace gender="" if gender=="NA"


replace victim_age="" if victim_age=="NA"
tab victim_age
destring victim_age, replace 
replace victim_age=. if victim_age==710 

rename victim_age age 
tab age 
replace age=. if age<0
tab age 
label var age "Victim age at time of crime"

//cleaning gender variable 
gen male=. 
replace male=1 if gender=="Male"
replace male=0 if gender=="Female"
tab male


//looking at year
tab claim_year //this includes data for the old system in NM 
tab year_entered //for the new system this is the date that we have for the claim so I use this year for this new data 

//generating new year variable 
gen year="."
replace year=claim_year if claim_year=="2015" | claim_year=="2016" | claim_year=="2017" |claim_year=="2018" 
replace year=year_entered if year=="."
tab year

/*=====================================================================================
Recoding Approval/Denial
--------------------------------------------------------------------------------------
=======================================================================================*/ 
//recode resolution_code 
tab resolution_code, m 

gen approved=1 if resolution_code=="AP"
replace approved=0 if resolution_code=="DN"
replace approved=. if resolution_code=="-" | resolution_code=="NA"
tab approved, m 


//denial for failure to supply information 
tab reason_for_denial 
br reason_for_denial ///compare this to list in excel and look at the repeated ones 

//exporting list of denial reasons to excel 
preserve 
tab reason_for_denial, gen(reason_for_denial_)
gen number=_n
collapse (count) number, by(reason_for_denial)
export delimited "$analysis\NM Compensation Data\NM_denial_reasons.csv", replace 
restore 

//indicator for denial for failure to supply information
gen den_fail_info=0 
replace den_fail_info=1 if regexm(reason_for_denial, "Incomplete")
label variable den_fail_info "Denial due to failure to provide info."

//checking to see if all the incomplete applications were recoded correctly 
tab reason_for_denial if den_fail_info==1 

tab reason_for_denial if den_fail_info==0 

//grouping denial reasons to understand common reasons for denial 
levelsof reason_for_denial 
tab reason_for_denial

//classify reasons for denial 
gen reason_for_denial_recoded=reason_for_denial 
replace reason_for_denial_recoded="Contributory" if regexm(reason_for_denial, "Contributory")
replace reason_for_denial_recoded="Crime out of State" if regexm(reason_for_denial, "Out of State")
replace reason_for_denial_recoded="Crime out of State" if regexm(reason_for_denial, "out of State")
replace reason_for_denial_recoded="Failure to report" if regexm(reason_for_denial, "Failure to Report")
replace reason_for_denial_recoded="Failure to report" if regexm(reason_for_denial, "Failed to report")
replace reason_for_denial_recoded="Inactive" if regexm(reason_for_denial, "Inactive")
replace reason_for_denial_recoded="Incomplete" if regexm(reason_for_denial, "Incomplete")
replace reason_for_denial_recoded="No Crime Enumerated" if regexm(reason_for_denial, "No Crime Enumerated")
replace reason_for_denial_recoded="No Police Report" if regexm(reason_for_denial, "No Police Report")
replace reason_for_denial_recoded="Out of Time" if regexm(reason_for_denial, "Out of time")
replace reason_for_denial_recoded="Restricted Payment" if regexm(reason_for_denial, "Restricted Payment")
replace reason_for_denial_recoded="Restricted Payment" if regexm(reason_for_denial, "Restrictive")
replace reason_for_denial_recoded="Unable to Locate" if regexm(reason_for_denial, "Unable to Locate")
replace reason_for_denial_recoded="Unable to Locate" if regexm(reason_for_denial, "Unable To Locate")
replace reason_for_denial_recoded="Unable to Locate" if regexm(reason_for_denial, "Unable to locate")
replace reason_for_denial_recoded="Uncooperative" if regexm(reason_for_denial, "Uncooperative")
replace reason_for_denial_recoded="Victim Incarcerated" if regexm(reason_for_denial, "Incarcerated")
replace reason_for_denial_recoded="Victim Incarcerated" if regexm(reason_for_denial, "incarcerated")
replace reason_for_denial_recoded="Withdrawal" if regexm(reason_for_denial, "Withdrawal")
replace reason_for_denial_recoded="Withdrawal" if regexm(reason_for_denial, "Withdrawl")

replace reason_for_denial_recoded="NA" if reason_for_denial=="-"
replace reason_for_denial_recoded="." if reason_for_denial=="NA"
tab reason_for_denial_recoded

//creating categories we want for the most common denial types 
tab reason_for_denial_recoded, gen(denial_reason)

/*
//contributory 
gen den_contributory=0
replace den_contributory=1 if reason_for_denial_recoded=="Contributory"

//duplicate 
gen den_duplicate=0
replace den_duplicate=1 if reason_for_denial_recoded=="Duplicate Application"

//inactive 
gen den_inactive=0
replace den_inactive=1 if reason_for_denial_recoded=="Inactive"

//no crime enumerated 
gen den_nocrime_enum=0
replace den_nocrime_enum=1 if reason_for_denial_recoded=="No Crime Enumerated"


levelsof reason_for_denial_recoded, local(levels)
foreach l of `levels' {
    local lbl: label reason_for_denial_recoded `l'  // Get label of category `l`
    label var denial_reason`l' "`lbl'"  // Assign label to the new variable
}
*/

foreach var of varlist denial_reason* {  // Replace with your variable names
    local lbl: variable label `var'  // Get current label
    local new_lbl = subinstr("`lbl'", "reason_for_denial_recoded==", "", .)  // Remove text
    label variable `var' "`new_lbl'"  // Apply new label
}

/* attempting to rename variables with variable labels 
foreach var of varlist denial_reason* {
	 local lbl: variable label `var'  // Get current label
		rename `var' "`lbl'"
}

foreach var of varlist denial_reason* {  
    local lbl: variable label `var'  // Get current label
    local newname = subinstr("`lbl'", " ", "_", .)  // Replace spaces with underscores
    local newname = regexr("`newname'", "[^a-zA-Z0-9_]", "")  // Remove special characters
    rename `var' `newname'  // Rename variable
}

foreach var of varlist denial_reason* {  
    local lbl: variable label `var'  // Get current label
    local trimmed_lbl = strtrim("`lbl'")  // Trim spaces
    local newname = subinstr("`trimmed_lbl'", " ", "_", .)  // Replace spaces with underscores
    local newname = regexr("`newname'", "[^a-zA-Z0-9_]", "")  // Remove special characters
    rename `var' `newname'  // Rename variable
}
*/

//
/*=====================================================================================
Recoding Payment Expense Types
--------------------------------------------------------------------------------------

Notes: For the payment variables, missing means that the payment was not made for that 
expense. So we can treat missing as 0 for no payments for that payment type. For any 
analysis using these variables, we will need to restrict to the sample if approved==1 
becauase payments can only be made on approved claims. 

There are these payment types that we will reclassify into the above categories. 

Lost wages==lossofwages
Medical== medicalnothospital  alternativemedicine ambulance dental prescriptions eyeglasses medicalcannabis hospital
Counseling==mentalhealthinpatient mentalhealthoutpatient
Travel== travel 
Funeral== funeralorburial 
Relocation== rentrelocation  depositrelocation
Forensic exam== dvforensicexam childsaforensicexam  childabuseexam 
Loss of Support==lossofsupport  
Property Loss== propertylossreplacement 
Other==crimescenecleanup legacypayments dependentcare
=======================================================================================*/ 

//checking payment type variables
sum lossofwages-legacypayments //these variables sum the dollar amount for each expense. In the next variables I will create dummy variables for each payment type if these were over $0 

//lost wages
gen lost_wages_exp=0
replace lost_wages_exp=1 if lossofwages>0
replace lost_wages_exp=. if lossofwages==.
tab lost_wages_exp, m  
sum lost_wages_exp lossofwages
tab lost_wages approved, m 

//medical expenses 
gen medical_exp = 0  
replace medical_exp=1 if (medicalnothospital > 0 | alternativemedicine > 0 | ambulance > 0 | dental > 0 | prescriptions > 0 | eyeglasses > 0 | medicalcannabis > 0 | hospital > 0)
replace medical_exp=. if (medicalnothospital ==. & alternativemedicine ==. & ambulance ==. & dental ==. & prescriptions ==. & eyeglasses ==. & medicalcannabis ==. & hospital ==.)
sum medical_exp if approved==1

//funeral
gen funeral_exp=0
replace funeral_exp=1 if funeralorburial > 0 
replace funeral_exp=. if funeralorburial == . 

//relocation 
gen relocation_exp=0
replace relocation_exp=1 if (rentrelocation > 0 | depositrelocation > 0)
replace relocation_exp=. if (rentrelocation == .  | depositrelocation == . )

//forensic exam
gen forensic_exam_exp=0 
replace forensic_exam_exp=1 if (dvforensicexam > 0 | childsaforensicexam > 0 |  childabuseexam > 0)
replace forensic_exam_exp=. if (dvforensicexam == . | childsaforensicexam == . |  childabuseexam == .)

//property loss
gen property_exp=0
replace property_exp=1 if propertylossreplacement > 0 
replace property_exp=. if propertylossreplacement == . 

//other 
gen other_exp=0 
replace other_exp=1 if (crimescenecleanup > 0 | legacypayments > 0 |  dependentcare > 0)
replace other_exp=. if (crimescenecleanup == . | legacypayments == . |  dependentcare == .)

//travel 
gen travel_exp=0 
replace travel_exp=1 if travel > 1 
replace travel_exp=. if travel == . 

//loss of support 
gen loss_support_exp=0 
replace loss_support_exp=1 if lossofsupport > 1 
replace loss_support_exp=. if lossofsupport == . 

//counseling 
gen counseling_exp=0
replace counseling_exp=1 if (mentalhealthinpatient > 1 | mentalhealthoutpatient > 1)
replace counseling_exp=. if (mentalhealthinpatient == . | mentalhealthoutpatient == .)

//checking summary statistics 
sum *_exp if approved==1
 
//checking the forensic exam claims if there were other payment types or only payments for exams. 
foreach var of varlist *exp {
	di "`var'"
	sum forensic_exam_exp if `var'==1 
	if r(n)>0 di as error "other payment with forensic claim" 
}

//since these claims have other payments, we do not drop claims for forensic exam payments from this analysis. 

/*=====================================================================================
Recoding Crime Type
--------------------------------------------------------------------------------------
=======================================================================================*/ 
tab crime_type_enumerated

//homicide indicator 
gen crime_homicide=0
replace crime_homicide=1 if inlist(crime_type_enumerated, "Homicide by Vehicle",  "Involuntary Manslaughter", "Murder", "Voluntary Manslaughter")
replace crime_homicide=. if crime_type_enumerated=="NA" | crime_type_enumerated=="Unknown" 
tab crime_homicide, m 

//Sexual assault 
gen crime_sex_assualt=0 
replace crime_sex_assualt=1 if inlist(crime_type_enumerated, "Criminal Sexual Contact of a Minor", "Criminal Sexual Penetration")
replace crime_sex_assualt=. if crime_type_enumerated=="NA" | crime_type_enumerated=="Unknown" 
tab crime_sex_assualt, m 

//crime domestic violence
gen crime_dom_assault=0
replace crime_dom_assault=1 if crime_type=="Domestic abuse (spousal or partner)"
replace crime_dom_assault=. if crime_type_enumerated=="NA" | crime_type_enumerated=="Unknown" 
tab crime_dom_assault, m 



/*=====================================================================================
Claim Year 
--------------------------------------------------------------------------------------
=======================================================================================*/ 

//claim year received is missing 39% 
tab claim_received_date 

//I will use a year indicator based on year_entered since the missingness is a lot lower and this way we don't lose as much of the sample 
tab year_entered
replace year_entered="." if year_entered=="NA"
tab year_entered

/*=====================================================================================
Merging zip code demographics 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
tempfile nm_clean 
save `nm_clean'

//merge zip code data 
import delimited "$clean/Ad Hoc/zip_codes_data_wide.csv", clear 

//save tempfile to merge 
tempfile zip_code_demographics 
save `zip_code_demographics'

//opening claims data again 
use "`nm_clean'", clear 

//destring victim_zip for merge 
destring victim_zip, replace 

//merging with zip code demographics 
merge m:1 victim_zip using "`zip_code_demographics'"

//exploring master observations that didn't merge 
tab victim_state if _merge==1 //1,257 in NM didn't merge 
tab victim_zip if _merge==1 & victim_state=="NM" //there are 315 claims whose zip code does not match one in the census list. Some of these are not actually in NM while others are but are excluded in the census data 

//keeping only the master data and dropping additional zip codes from the census 
drop if _merge==2 

//dropping since it's no longer needed 
drop _merge 

save "$analysis\NM Compensation Data\NM_comp_clean.dta", replace 
log close 

/*=====================================================================================
Program Author: Shradha Sahani
Start Date: March 25, 2025
Last Updated: March 25, 2025


Program Description: Analysis and visualizations using NM comp data for state presentation. 

Input:
	- NM claims data after imputation 
	- NM neighborhood level claims data 
	
Output:
	- graphs for NM state presentation  
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
log using "NM_presentation_visualizations_$out_date.smcl", append

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

//set color scheme for graphs 
set scheme csgjc_jri_colors

/*=====================================================================================
Claimant demographics 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
//pre-imputation 
//use "$analysis\NM Compensation Data\NM_comp_clean.dta", replace //before imputation 

use "$analysis\NM Compensation Data\NM_BIFSG_imputed_data_cleanedforanalysis.dta", clear //post-imputation 



//% missing race 
gen missing_race=0 
replace missing_race=1 if inlist(victim_race, "NA", "Unknown", "80", "Not reported")
tab missing_race if imp_num==0 //11% of claims missing victim race 


//how does missing race vary between the old and new system 
tab missing_race year_entered if imp_num==0, col //only in the new system. This is interesting.


//dropping dataset with missing data for the summary statistics 
drop if imp_num==0 


//label variable
label var age_cat "Victim Age"


//race_w_imp 
tab race_w_imp, gen(race_imp_dummy)

drop ameind api black hisp multi white other //drop old race vars without imputation 

rename race_imp_dummy1 ameind 
rename race_imp_dummy2 api 
rename race_imp_dummy3 black 
rename race_imp_dummy4 hispanic 
rename race_imp_dummy5 other 
rename race_imp_dummy6 white 

//summary statistics overall 
sum ameind api black hispanic other white male age_cat*
//outreg2 using "$analysis\PA Compensation Data\claims demographics.xls", sum(log) lab keep (ameind api black hispanic other white male age_cat*) replace 

//Proportion of different demographics who apply 
#d ;  //this is a stata delimit command that changes the delimiter to a ;. I use this because it makes it easier to have multiple lines of code as a part of one function without adding /// to tell stata to continue to the next line. 
    graph bar /*(percent)*/ ameind-white, // I am getting proportions and not percentages and I don't know why. 
    title("Distribution of Applications by Victim Race", size(4) color(black)) 
	subtitle(2015-2019, color(black))
    ytitle("Proportion of total applications", size (4)) //changing this to proportion since I am not able to get the percent. 
    legend(label(1 "American Indian") 
           label(2 "Asian American and Pacific Islander") 
           label(3 "Black") 
           label(4 "Hispanic")    
           label(5 "Other") 
           label(6 "White") 
           cols(3) size(small)) 
    graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)    
    name(race_app_pa, replace) ;
#d cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/app_per_race.png", replace 

//percent of applications by gender
//label male 
label define male 1 "Male" 0 "Female"
label values male male 

#d ;
graph pie, over(male)
	title("Percent of Applications by Gender of Victim") 
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded
	graphregion(color(white))
	pie(2, color(orange))
	pie(1, color(ltblue))
	legend(position(5) size(4) rows(2) region(lcolor(white)) width(100))
	graphregion(margin(medium))
	name(app_gender, replace);
#d cr 
//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy

gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy
graph export "$analysis/NM Compensation Data/app_per_gender.png", replace 


//applications by age cat
//bar graph for age 
#d ;
graph bar, over(age_cat)
    title("Percent of Applications by Age of Victim", size(4) color(black))
	subtitle(2015-2019, color(black))
	ytitle("Percent of Total Applications")  
	ylabel(,nogrid)
	//xtitle("Victim Age")
	scheme(csgjc_jri_colors)
    graphregion(color(white))
	bargap(30)
	name("app_age", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis/NM Compensation Data/app_per_age.png", replace 



//pie chart for approval 

label define approved 0 "Denied" 1 "Approved"
label values approved approved 

#d ; //this is a stata delimit command that changes the delimiter to a ;. I use this because it makes it easier to have multiple lines of code as a part of one function without adding /// to tell stata to continue to the next line. 
graph pie, over(approved)
	title("Percent of Applications Approved") 
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded
	scheme(s2color)
	graphregion(color(white))
	//pie(1, color(rgb(255, 118, 48)) lcolor(white) lwidth(medium)) /// Orange slice with white border
   //pie(2, color(rgb(63, 149, 176)) lcolor(white) lwidth(medium)) /// Teal slice with white border
	legend(position(5) size(4) rows(2) region(lcolor(white)))
	name(per_approved, replace);
#d cr 

//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy


gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy

graph export "$analysis\NM Compensation Data\applications_approved_nm.png", replace 

//pie chart for approved and paid  

label define no_payment 1 "No Payment" 0 "Payment Made"
label values no_payment no_payment

#d ; //this is a stata delimit command that changes the delimiter to a ;. I use this because it makes it easier to have multiple lines of code as a part of one function without adding /// to tell stata to continue to the next line. 
graph pie if approved==1, over(no_payment)
	title("Percent of Applications Approved with a payment") 
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded
	scheme(s2color)
	graphregion(color(white))
	//pie(1, color(rgb(255, 118, 48)) lcolor(white) lwidth(medium)) /// Orange slice with white border
   //pie(2, color(rgb(63, 149, 176)) lcolor(white) lwidth(medium)) /// Teal slice with white border
	legend(position(5) size(4) rows(2) region(lcolor(white)))
	name(per_approved, replace);
#d cr 

//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy


gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy

graph export "$analysis\NM Compensation Data\applications_paid_nm.png", replace 



//approval percent by age 
sort age_cat
by age_cat: sum approved 

gen claim_id=_n //doing this so I can collapse it more easily in the next step 


//we want the % of applications in each age group that are approved 
preserve 
collapse (sum) approved (count) claim_id, by(age_cat)
gen per_approved=(approved/claim_id)*100

#d ;
graph bar per_approved, over(age_cat)
	title("Percent of Applications Approved by Age of Victim")
	subtitle(2015-2019, color(black))
	//xtitle("Victim Age Categories")
	ytitle("Percent of Applications Approved")  
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    graphregion(color(white))
	bargap(30)
	name("approved_age_pa", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis\NM Compensation Data\approved_age_nm.png", replace 
restore 


//reasons for denial 
tab reason_for_denial if approved==0
tab den_fail_info if approved==0 //only about 6% denied for failure to supply information 
tab reason_for_denial if den_fail_info==1 &  approved==0

//frequencies of different reasons for denial 
sum denial_reason* if approved==0
//more frequent reasons are denial_reason7 denial_reason9 denial_reason12 denial_reason20 

//creating an other denial reason variable 
gen den_other=0
replace den_other=1 if reason_for_denial_recoded!="Duplicate Application" &  reason_for_denial_recoded!="Inactive" & reason_for_denial_recoded!="No Crime Enumerated" &  reason_for_denial_recoded!="Unable to Locate" & reason_for_denial_recoded!="Incomplete"   
replace den_other=1 if reason_for_denial_recoded=="NA" |  reason_for_denial_recoded=="." //missing denial reasons are other 
tab den_other if approved==0, m // 

//look at the other 
tab reason_for_denial_recoded if den_other==1 & approved==0
//we will pull out the most common ones because other is too many above
replace den_other=0 if den_fail_info==1 | denial_reason13==1 | denial_reason21==1 //13=no police report, 21=uncooperative 
tab reason_for_denial_recoded if den_other==1 & approved==0

//create a new reason for denial measure 
gen reason_for_denial2="Other" if den_other==1 | reason_for_denial_recoded=="NA" |  reason_for_denial_recoded=="." 
replace reason_for_denial2="Duplicate Application" if denial_reason7==1
replace reason_for_denial2="Inactive" if denial_reason9==1
replace reason_for_denial2="No Crime Enumerated" if denial_reason12==1
replace reason_for_denial2="Unable to Locate" if denial_reason20==1
replace reason_for_denial2="Incomplete Information" if den_fail_info==1 
replace reason_for_denial2="No Police Report" if denial_reason13==1 
replace reason_for_denial2="Uncooperative" if denial_reason21==1
tab reason_for_denial2, m 
tab reason_for_denial2 if approved==0, m 

//who are the other 
tab reason_for_denial_recoded if den_other==1 & approved==0
tab reason_for_denial_recoded if approved==0

#d ;
    graph bar den_other denial_reason7 denial_reason9 denial_reason12 denial_reason20 den_fail_info denial_reason13 denial_reason21 if approved==0, // I am getting proportions and not percentages and I don't know why. 
    title("Reasons for Denial", size(4) color(black)) 
	subtitle(2015-2019, color(black))
    ytitle("Proportion of Denied Applications", size (4)) //changing this to proportion since I am not able to get the percent. 
    legend(label(1 "Other") 
           label(2 "Duplicate Application") 
           label(3 "Inactive") 
           label(4 "No Crime Enumerated")    
           label(5 "Unable to Locate") 
           label(6 "Incomplete Information") 
		   label(7 "No Police Report") 
		   label(8 "Uncooperative") 
           cols(3) size(vsmall)) 
    graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)    
    name(race_app_pa, replace) ;
#d cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/den_reasons.png", replace 


/*
Notes: what do we want to visualize here? 
~22% unable to locate 
~20% no crime enumerated
~14% duplicate application
ADD MORE/WALK THROUGH THIS LIST ABOVE WITH ROBERT
*/ 

//demographics of those applications denied for unable to locate 
tab race_w_imp if denial_reason20==1 
tab age_cat if denial_reason20==1 
tab male if denial_reason20==1 

//approval rate by race 
foreach var of varlist ameind-white {
	egen `var'_approved=total(`var') if approved==1 //number approved for each race
	egen total_`var'=total(`var') //total number of applications for each race
	gen `var'_app_rate_per1k=(`var'_approved/total_`var')*1000 //approval rate by race 
	gen `var'_app_rate_percent=(`var'_approved/total_`var')*100 //approval rate by race 
	}

//gen claim_state 
gen claim_state="NM"

//collapse data to make it easier to visualize 
preserve 
collapse (count) claim_id (sum) approved (max) *_app_rate_per1k *_app_rate_percent, by(claim_state)

//overall approval rate
gen app_rate_per1k=(approved/claim_id)*1000

//graph percentages 
#delimit ;
graph bar *_app_rate_percent, 
    title("Percent of Applications Approved by Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Total Applications") 
    legend(label(1 "American Indian") 
           label(2 "Asian American and Pacific Islander") 
           label(3 "Black") 
           label(4 "Hispanic") 
           label(5 "Other") 
           label(6 "White") 
           cols(3) size(small)) 
    graphregion(color(white))
	ylabel(0(10)70,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(race_app_percent, replace) ;
#delimit cr 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/approved_race_percent.png", replace 
restore 

//paid rate by race 
foreach var of varlist ameind-white {
	egen `var'_paid=total(`var') if no_payment==0 & approved==1 //number approved for each race & paid
	egen total_`var'_approved=total(`var') if approved==1 //total number of applications for each race approved
	gen `var'_paid_rate_per1k=(`var'_paid/total_`var'_approved)*1000 //approval rate by race 
	gen `var'_paid_rate_percent=(`var'_paid/total_`var'_approved)*100 //approval rate by race 
	}

sum *_paid_rate_percent	
	
//collapse data to make it easier to visualize 
preserve 
collapse (count) claim_id (sum) approved no_payment (max) *_paid_rate_percent, by(claim_state)

//overall approval rate
gen app_rate_per1k=(approved/claim_id)*1000

//graph percentages 
#delimit ;
graph bar *_paid_rate_percent, 
    title("Percent of Applications Paid by Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Approved Applications") 
    legend(label(1 "American Indian") 
           label(2 "Asian American and Pacific Islander") 
           label(3 "Black") 
           label(4 "Hispanic") 
           label(5 "Other") 
           label(6 "White") 
           cols(3) size(small)) 
    graphregion(color(white))
	ylabel(0(10)50,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(race_paid_percent, replace) ;
#delimit cr 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/paid_race_percent.png", replace 
restore 

//indicator if there was a payment 
gen payment=0
replace payment=1 if no_payment==0
replace payment=. if no_payment==. 
tab payment no_payment

//we want the % of applications in each age group that are paid 
preserve 

collapse (sum) payment approved, by(age_cat)

//gen percent paid 
gen per_paid=(payment/approved)*100

#d ;
graph bar per_paid, over(age_cat)
	title("Percent of Applications Paid by Age of Victim")
	subtitle(2015-2019, color(black))
	//xtitle("Victim Age Categories")
	ytitle("Percent of Approved Applications")  
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    graphregion(color(white))
	bargap(30)
	name("approved_age_pa", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis\NM Compensation Data\paid_age_nm.png", replace 
restore 


//payment type graphs 

//payment type categories
sum *_exp if approved==1

//the most commonly reimbursed payment was medical, LOE, Stolen 
graph bar *_exp if approved==1

//I want the % of approved claims that were reimbursed for each expense type 
foreach var of varlist *_exp {
	egen total_`var'=total(`var') if approved==1 
}

//label variables
label var total_medical_exp "Medical"
label var total_funeral_exp "Funeral"
label var total_lost_wages_exp "Lost Wages" 
label var total_counseling_exp "Counseling"
label var total_travel_exp "Travel"
label var total_loss_support_exp "Loss of Support"
label var total_property_exp "Property"
label var total_relocation_exp  "Relocation"
label var total_forensic_exam_exp "Forensic Exam"
label var total_other_exp "Other Expense"



preserve 
collapse (first) total_*_exp (count) claim_id, by(approved) 
drop if approved==0 

foreach var of varlist total_* {
	cap drop per_`var'
	gen per_`var'=(`var'/claim_id)*100
}

//label variables
label var per_total_medical_exp "Medical"
label var per_total_funeral_exp "Funeral"
label var per_total_lost_wages_exp "Lost Wages" 
label var per_total_counseling_exp "Counseling"
label var per_total_travel_exp "Travel"
label var per_total_loss_support_exp "Loss of Support"
label var per_total_property_exp "Property"
label var per_total_relocation_exp  "Relocation"
label var per_total_forensic_exam_exp "Forensic Exam"
label var per_total_other_exp "Other Expense"


sum per_*

#d ;
graph bar per_*, 
	ytitle(Percent of Approved Applications)
	 graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(payment_types, replace);
#d cr 


//graphing the top 5 payments 
#d ;
graph bar per_total_lost_wages_exp per_total_medical_exp per_total_funeral_exp per_total_relocation_exp per_total_counseling_exp , 
	title(Most Commonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Approved Applications)
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Lost Wages"
                 2 "Medical"
                 3 "Funeral"
                 4 "Relocation"
                 5 "Counseling"))
    name(payment_types_highest, replace);
#d cr 
//change color of last bar 
graph export "$analysis/NM Compensation Data/approved_payments_highest.png", replace 

sum per_total_forensic_exam_exp per_total_other_exp per_total_travel_exp per_total_loss_support_exp per_total_property_exp 

//less common payments 
//graphing only the least common payments.
#d ;
graph bar per_total_forensic_exam_exp per_total_other_exp per_total_travel_exp per_total_loss_support_exp per_total_property_exp, 
	title(Least Commmonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Approved Applications)
	graphregion(color(white))
	yscale(range(0 (.5) 1.5))
	ylabel(0(.5)1.5,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Forensic Exam"
                 2 "Other"
                 3 "Travel"
                 4 "Loss of Support"
				 5 "Property"))
    name(payment_types_lowest, replace);
#d cr
graph export "$analysis/NM Compensation Data/approved_payments_lowest.png", replace 

restore 

//do we want to know among those approved when a payment was made what % of payments are of different expenses? 
//I want the % of approved claims that were reimbursed for each expense type 
foreach var of varlist lost_wages_exp medical_exp funeral_exp relocation_exp forensic_exam_exp property_exp other_exp travel_exp loss_support_exp counseling_exp {
	egen total_`var'_paid=total(`var') if approved==1 & no_payment==0
}

//these are the number of each expense paid for those approved and paid 
preserve 
collapse (first) total_*_paid (count) claim_id, by(approved no_payment) 
keep if approved==1 & no_payment==0 


foreach var of varlist total_*_paid {
	cap drop per_`var'
	gen per_`var'=(`var'/claim_id)*100
}

sum per*

//of those paid the higher paid expenses are lost_wages_exp medical_exp funeral_exp relocation_exp 
//graphing these 
#d ;
graph bar per_total_lost_wages_exp per_total_medical_exp per_total_funeral_exp per_total_relocation_exp per_total_counseling_exp , 
	title(Most Commonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Paid Applications)
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Lost Wages"
                 2 "Medical"
                 3 "Funeral"
                 4 "Relocation"
                 5 "Counseling"))
    name(payment_types_highest, replace);
#d cr 
//change color of last bar 
graph export "$analysis/NM Compensation Data/approvedpaid _payments_highest.png", replace 

//less common payments 
//graphing only the least common payments.
#d ;
graph bar per_total_forensic_exam_exp per_total_other_exp per_total_travel_exp per_total_loss_support_exp per_total_property_exp, 
	title(Least Commmonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Paid Applications)
	graphregion(color(white))
	yscale(range(0 (1) 7))
	ylabel(0(1)7,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Forensic Exam"
                 2 "Other"
                 3 "Travel"
                 4 "Loss of Support"
				 5 "Property"))
    name(payment_types_lowest, replace);
#d cr
graph export "$analysis/NM Compensation Data/approvedpaid_payments_lowest.png", replace 

restore 

//loss of earnings by race 
foreach var of varlist ameind-white {
	egen `var'_loe=total(`var') if lost_wages_exp==1 //number loe payments for each race
	egen total_`var'_paid=total(payment) if `var'==1 //number of paid claims for each race 
	gen `var'_loe_rate_percent=(`var'_loe/total_`var'_paid)*100 //percent of paid claims with loe payments 
	}

//checking 
sum lost_wages_exp if ameind==1 & payment==1
sum ameind_loe_rate_percent

//medical claims rate by race 
foreach var of varlist ameind-white {
	egen `var'_medical=total(`var') if medical_exp==1 //number medical payments for each race
	gen `var'_med_rate_percent=(`var'_medical/total_`var'_paid)*100 //percent of paid claims with medical payments 
	}

	
//for graphs we can collapse to make it easier 
preserve 
collapse (max) *med_rate_percent *_loe_rate_percent, by(claim_state)
	
//percent approved by race with Medical expenses 
#delimit ;
graph bar *med_rate_percent, 
    title("Payments for Medical Expenses by Victim Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Paid Applications") 
    legend(label(1 "American Indian") 
           label(2 "Asian American and Pacific Islander") 
           label(3 "Black") 
           label(4 "Hispanic") 
           label(5 "Other") 
           label(6 "White") 
           cols(3) size(small)) 
    graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(race_app_medical_percent, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/paid_race_medicalpayments.png", replace 


//loss of earnings 
#delimit ;
graph bar *loe_rate_percent, 
    title("Payments for Lost Wages by Victim Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Paid Applications") 
    legend(label(1 "American Indian") 
           label(2 "Asian American and Pacific Islander") 
           label(3 "Black") 
           label(4 "Hispanic") 
           label(5 "Other") 
           label(6 "White") 
           cols(3) size(small)) 
    graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(race_app_loe_percent, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/NM Compensation Data/paid_race_loepayments.png", replace 

restore

//claim approval rate overall in these major cities across all 5 years 
preserve 
keep if inlist(victim_city, "Farmington", "Rio Rancho", "Santa Fe", "Albuquerque")
collapse (count) claim_id (sum) approved, by(claim_state)
sum claim_id approved
gen per_approved_largecity=(approved/claim_id)*100
sum per_approved_largecity //62% of claims approved in the large cities 
gen not_approved=claim_id-approved
restore  

 
/****************************************************************************************
Neighborhoods with low application rates
=========================================================================================
application rates for violent crimes 

NM: Farmington, Rio Rancho, Santa Fe, and Albuquerque

Data:  NM claims data for major cities with PD crime data 
*****************************************************************************************/
use "$analysis\NM Compensation Data\nm_comp_with_ngd_crime.dta", clear 

 
//collapse data for 5 years 
collapse (sum) claim_number approved zip_tot_pop zip_violent (first) victim_city, by(zip)
 

//create rates for all 5 years 
gen zip_violent_rate=(zip_violent/zip_tot_pop)*1000
label variable zip_violent_rate "Zipcode violent crime rate per 1,000 people (2015-2019)"

gen zip_app_rate=(claim_number/zip_tot_pop)*1000
replace zip_app_rate=0 if claim_number==0 //zip codes with no claims should have a 0 rate 
label variable zip_app_rate "Zipcode Application rate per 1,000 people (2015-2019)"

gen zip_app_crime_rate=(claim_number/zip_violent)*1000
replace zip_app_crime_rate=0 if claim_number==0 //zip codes with no claims should have a 0 rate 
label variable zip_app_crime_rate "Zipcode Application rate per 1,000 violent crimes (2015-2019)"

//summary statistics 
sum zip_violent_rate zip_app_crime_rate zip_app_rate

//checking the correlation between applications and crimes 
corr zip_app_rate zip_violent_rate 

corr zip_app_crime_rate zip_violent_rate 



//what is the application rate, in the highest crime neighborhoods? 
sort zip_violent_rate
br 


//approval rates 
gen zip_approval_rate=(approved/claim_number)*1000
replace zip_approval_rate=. if claim_number==0
label variable zip_approval_rate "Zipcode approval rate per 1,000 applications"


sum zip_approval_rate

*percentage of applications approved
gen zip_approval_percent=(zip_approval_rate/1000)*100
label variable zip_approval_percent "Zipcode approval rate percent"

sum zip_approval_percent

//neighborhoods with highest and lowest crime rates 
//rank zip codes by neighborhood violent crime rate 
egen rank_zip_viol_rate = rank(zip_violent_rate), unique

//identify lowest crime zip codes that are not 0 
list zip_violent_rate zip_app_crime_rate claim_number if rank_zip_viol_rate <= 7 // 

//adding in number of crimes and number of applications 
list zip zip_violent_rate zip_app_crime_rate zip_violent claim_number if rank_zip_viol_rate <= 7


//top 5 highest zip codes 
list zip zip_violent_rate if rank_zip_viol_rate >= 23 & rank_zip_viol_rate<=27 //these are the highest 5

//adding in number of crimes and number of applications 
list zip zip_violent_rate zip_app_crime_rate zip_violent claim_number if rank_zip_viol_rate >= 23 & rank_zip_viol_rate<=27 //these are the highest 5



//rankings only go to 27 because these are based on the violent crime rate and the rest are missing because their populations are 0 and are PO Box zip codes most likely so it's okay to exclude them. Most of them also have 0 violent crimes. 


//exporting data for the highest and lowest zip codes 
preserve 
gen low_crime=1 if rank_zip_viol_rate <= 7 //lowest 5
gen high_crime=1 if rank_zip_viol_rate >= 23 & rank_zip_viol_rate<=27 //highest 5
keep if low_crime==1 | high_crime==1 

keep zip zip_violent_rate zip_app_crime_rate low_crime high_crime zip_violent claim_number //keeping only variables we need 
sort zip_violent_rate 
order zip zip_violent_rate zip_violent 
export excel "$analysis\NM Compensation Data\high_low_crime_apps.xls", firstrow(variables) replace 
restore 

//the highest application zip codes 
gsort -claim_number
list zip claim_number zip_violent_rate if _n<=5 

log close 

/*=====================================================================================
Program Author: Shradha Sahani
Start Date: March 4, 2025
Last Updated: March 17, 2025


Program Description: Analysis and visualizations using PA comp data for state presentation. 

Input:
	- PA claims data after imputation 
	- PA neighborhood level claims data 
	
Output:
	- graphs for PA state presentation  
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
log using "PA_presentation_visualizations_$out_date.smcl", append

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
//use "$analysis\PA Compensation Data\PA_comp_clean.dta", replace //before imputation 

use "$analysis\PA Compensation Data\PA_BIFSG_imputed_data_cleanedforanalysis.dta", clear //post-imputation 

//dropping dataset with missing data for the summary statistics 
drop if imp_num==0 

//post-imputation 
*use "$analysis\PA Compensation Data\PA_BIFSG_imputed_data_foranalysis.dta", clear  

//descriptive statistics 
sum age male 

//% missing race 
gen missing_race=0 
replace missing_race=1 if inlist(victim_race, "NA", "Not Known")
tab missing_race //43% of claims missing victim race 

//approval rate by age categories 
/*
//generating age categories 
gen age_cat=. 
replace age_cat=1 if age<18 
replace age_cat=2 if age>=18 & age<25 
replace age_cat=3 if age>=25 & age<35 
replace age_cat=4 if age>=35 & age<45 
replace age_cat=5 if age>=45 & age<55
replace age_cat=6 if age>=55 & age<65 
replace age_cat=7 if age>=65

//label age categories
label define age 1 "<18" 2 "18-24" 3 "25-34" 4 "35-44" 5 "45-54" 6 "55-64" 7 ">=65"
label values age_cat age
*/
//label variable
label var age_cat "Victim Age"

//decode age_cat for later use in loops
//decode age_cat, gen(age_cat_str)

//pie chart for approval 
//in PA, they don't call this approval but paid or unpaid so we will use that terminology for the presentation
label define approved 0 "Unpaid" 1 "Paid"
label values approved approved 

#d ; //this is a stata delimit command that changes the delimiter to a ;. I use this because it makes it easier to have multiple lines of code as a part of one function without adding /// to tell stata to continue to the next line. 
graph pie, over(approved)
	title("Percent of Claims Paid") 
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

graph export "$analysis\PA Compensation Data\applications_approved_pa.png", replace 

//pie chart paid, unpaid, denied 
#d ; //this is a stata delimit command that changes the delimiter to a ;. I use this because it makes it easier to have multiple lines of code as a part of one function without adding /// to tell stata to continue to the next line. 
graph pie, over(app_status)
	title("Percent of Claims Paid") 
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded
	scheme(s2color)
	graphregion(color(white))
	//pie(1, color(rgb(255, 118, 48)) lcolor(white) lwidth(medium)) /// Orange slice with white border
   //pie(2, color(rgb(63, 149, 176)) lcolor(white) lwidth(medium)) /// Teal slice with white border
	legend(position(5) size(4) cols(3) region(lcolor(white)))
	name(per_approved, replace);
#d cr 

//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy


gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy

gr_edit plotregion1.pieslices[3].style.editstyle shadestyle(color("dkgreen")) editcopy
gr_edit plotregion1.pieslices[3].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[3].style.editstyle linestyle(width(0.3)) editcopy

graph export "$analysis\PA Compensation Data\applications_appstatus_pa.png", replace 



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
	title("Percent of Claims Paid by Age of Victim")
	subtitle(2015-2019, color(black))
	//xtitle("Victim Age Categories")
	ytitle("Percent of Claims Paid")  
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
    graphregion(color(white))
	bargap(30)
	name("approved_age_pa", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis\PA Compensation Data\approved_age_pa.png", replace 
restore 



//reasons for denial 
tab claim_disposition if approved==0
tab den_fail_info approved, col

label define den_fail 1 "Unpaid for Failure to Supply Information" 0 "Unpaid for Another Reason"
label values den_fail_info den_fail

//graph not approved applications by whether or not they were denied for failure to supply information 
#d ;
graph pie if approved==0, over(den_fail_info)
	title("Reasons Claims are Unpaid", size(4.5) color(black))
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded	
	pie(2, color(orange))
	pie(1, color(ltblue))
	legend(order(1 "Other Reasons" 2 "Failure to Supply Information") position(5) size(4) rows(2) region(lcolor(white)))
	name(den_fail, replace);
#d cr 
//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy


gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy
graph export "$analysis\PA Compensation Data\denial_reasons.png", replace 

//what are the other reasons 
tab claim_disposition if den_fail_info==0 & approved==0 & imp_num==1


//visualizing the different reasons for denial for lack of information 
tab claim_disposition if den_fail_info==1

//generating indicators for failure of provider/employer 
gen failure_provider=0 
replace failure_provider=1 if inlist(claim_disposition, "Failure to supply info. from employer",  "Failure to supply info. from provider")

//failure of victim to supply information 
gen failure_victim=0
replace failure_victim=1 if inlist(claim_disposition, "Failure to supply info. from victim/claimant",  "Failure to supply information", "Failure to provide signature page")
replace failure_victim=. if approved==1 
label define fail_victim 0 "Incomplete info. from provider/employer" 1 "Incomplete info. from victim"
label values failure_victim fail_victim 
label var failure_victim "Unpaid due to victim failure to supply information"

tab failure_provider 
tab failure_victim if approved==0 & den_fail_info==1 

//reason for denial for lack of information 
#d ; 
graph pie if approved==0 & den_fail_info==1 , over(failure_victim)
	title("Source of incomplete information", size(4.5) color(black))
	subtitle(2015-2019, color(black))
	plabel(_all percent, format(%2.0f)  size(*1.5) color(white)) // Percent rounded
	pie(2, color(orange))
	pie(1, color(ltblue))
	legend(position(5) size(4) rows(2) region(lcolor(white)) width(100))
	legend(order(1 "Provider/Employer" 2 "Victim") position(5) size(4) rows(2) region(lcolor(white)))
	graphregion(margin(medium))
	name(den_fail_reasons,replace);
#d cr 
//adjusting pie chart colors
gr_edit plotregion1.pieslices[2].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[2].style.editstyle linestyle(width(0.3)) editcopy


gr_edit plotregion1.pieslices[1].style.editstyle shadestyle(color("63 149 176")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(color("white")) editcopy
gr_edit plotregion1.pieslices[1].style.editstyle linestyle(width(0.3)) editcopy
graph export "$analysis/PA Compensation Data/denial_failure_breakdown.png", replace 

//denial for failure to supply information rate by age 
sort age_cat 
by age_cat: sum den_fail_info if approved==0 

//we want the percent of applications of people in that age category who were denied for failure to supply info. so we collapse the data by age_cat
preserve 
keep if approved==0 //only not approved claims 
collapse (sum) den_fail_info (count) claim_id, by(age_cat)
gen per_den_fail_info=(den_fail_info/claim_id)*100

#d ;
graph bar per_den_fail_info, over(age_cat)
    title("Percent of Claims Unpaid for Inadequate Information by Age of Victim", size(4) color(black))
	subtitle(2015-2019, color(black))
	ytitle("Percent Unpaid for Inadequate Information")  
	ylabel(,nogrid)
	//xtitle("Victim Age")
	scheme(csgjc_jri_colors)
	//bar(1, bcolor(rgb(225, 118, 48)))
    graphregion(color(white))
	name("den_fail_age_pa", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis\PA Compensation Data\den_info_age.png", replace 
restore 



//denial for failure to supply information rate by race 

//race_w_imp 
tab race_w_imp, gen(race_imp_dummy)

drop ameind api black hisp multi white //drop old race vars without imputation 

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
/* pie chart doesn't work for this 

#d ;
graph pie, over(race_w_imp)
	title("Percent of applications by race (2015-2019)") 
	plabel(_all percent, format(%4.1f)  size(*1.5) color(black)) // Percentage with 1 decimal
	scheme(s2color)
	graphregion(color(white)) ;
	//color(blue red); 
#d cr 
*/ 

#d ;
    graph bar /*(percent)*/ ameind-white, // I am getting proportions and not percentages and I don't know why. 
    title("Claims Distribution by Victim Race", size(4) color(black)) 
	subtitle(2015-2019, color(black))
    ytitle("Proportion of Total Claims", size (4)) //changing this to proportion since I am not able to get the percent. 
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
graph export "$analysis/PA Compensation Data/app_per_race.png", replace 

//percent of applications by gender
//label male 
label define male 1 "Male" 0 "Female"
label values male male 

#d ;
graph pie, over(male)
	title("Percent of Claims by Gender of Victim") 
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
graph export "$analysis/PA Compensation Data/app_per_gender.png", replace 

//applications by age cat
//bar graph for age 
#d ;
graph bar, over(age_cat)
    title("Percent of Claims by Age of Victim", size(4) color(black))
	subtitle(2015-2019, color(black))
	ytitle("Percent of Total Claims")  
	ylabel(,nogrid)
	//xtitle("Victim Age")
	scheme(csgjc_jri_colors)
    graphregion(color(white))
	bargap(30)
	name("app_age", replace) ;
#d cr 
gr_edit plotregion1.bars[1].style.editstyle shadestyle(color("225 118 48")) editcopy
gr_edit plotregion1.bars[1].style.editstyle linestyle(color("225 118 48")) editcopy
graph export "$analysis/PA Compensation Data/app_per_age.png", replace 


//denial for failure to supply information rate by race 
foreach var of varlist ameind-white {
	egen `var'_den_fail_info=total(`var') if den_fail_info==1 //number den_fail_info for each race
	egen total_`var'=total(`var') //total number of applications for each race
	gen `var'_denfail_rate_per1k=(`var'_den_fail_info/total_`var')*1000 //den_fail_info rate by race 
gen `var'_denfail_rate_percent=(`var'_den_fail_info/total_`var')*100 //den_fail_info rate by race 

}

//rate of denial for failure to supply information for denied applications only 
foreach var of varlist ameind-white {
	egen total_denied_`var'=total(`var') if approved==0 
	gen `var'_denfail_denied1k=(`var'_den_fail_info/total_denied_`var')*1000
	gen `var'_denfail_denied_percent=(`var'_den_fail_info/total_denied_`var')*100
}

//collapse data to make it easier to visualize 
gen claim_state="PA"
preserve 
collapse (max) *_denfail_denied1k *_denfail_rate_per1k *_denfail_denied_percent *_denfail_rate_percent ,  by(claim_state)

//this is the rate of denial per all applications by race for denied applications only 
#delimit ;
graph bar ameind_denfail_denied1k api_denfail_denied1k black_denfail_denied1k hispanic_denfail_denied1k other_denfail_denied1k white_denfail_denied1k, 
    title("Rates of Unpaid for Inadequate Information by Race of Victim", size(4) color(black)) 
	subtitle(2015-2019, color(black))
    ytitle("Rates of Unpaid for Inadequate Information per 1,000 Denied Claims", size (3)) 
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
    name(race_den_pa2, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/den_fail_race.png", replace 
 
//percent instead of rate 

//this is the rate of denial per all applications by race for denied applications only 
#delimit ;
graph bar *_denfail_denied_percent, 
    title("Percent Unpaid for Failure to Supply Information by Race", size(4) color(black)) 
	subtitle(2015-2019, color(black))
    ytitle("Percent of Unpaid Claims", size (3)) 
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
    name(race_den_percent, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/den_fail_race_percent.png", replace 
restore 


//approval rate by race 
foreach var of varlist ameind-white {
	egen `var'_approved=total(`var') if approved==1 //number approved for each race
	gen `var'_app_rate_per1k=(`var'_approved/total_`var')*1000 //approval rate by race 
	gen `var'_app_rate_percent=(`var'_approved/total_`var')*100 //approval rate by race 
	}

//collapse data to make it easier to visualize 
preserve 
collapse (count) claim_id (sum) approved (max) *_app_rate_per1k *_app_rate_percent, by(claim_state)

//overall approval rate
gen app_rate_per1k=(approved/claim_id)*1000

//graph rates 
#delimit ;
graph bar ameind_app_rate_per1k api_app_rate_per1k black_app_rate_per1k hispanic_app_rate_per1k other_app_rate_per1k white_app_rate_per1k, 
    title("Payment Rates by Race of Victim")
	subtitle(2015-2019, color(black))
    ytitle("Payment Rate per 1,000 Applications") 
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
    name(race_app_rate, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/approved_race_rate.png", replace 

//graph percentages 
#delimit ;
graph bar *_app_rate_percent, 
    title("Percent of Claims Paid by Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Total Claims") 
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
    name(race_app_percent, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/approved_race_percent.png", replace 
restore 

//payment type graphs 

//payment type categories
sum Medical Funeral Relocation LOE loss_support Attorney Counseling Transportation Other Stolen if approved==1

//the most commonly reimbursed payment was medical, LOE, Stolen 
graph bar Medical Funeral Relocation LOE loss_support Attorney Counseling Transportation Other Stolen if approved==1

//I want the % of approved claims that were reimbursed for each expense type 
foreach var of varlist Medical Funeral Relocation LOE loss_support Attorney Counseling Transportation Other Stolen {
	egen total_`var'=total(`var') if approved==1 
}

preserve 
collapse (first) total_Medical-total_Stolen (count) claim_id, by(approved) 
drop if approved==0 

foreach var of varlist total_* {
	cap drop per_`var'
	gen per_`var'=(`var'/claim_id)*100
}

//label variables
label var per_total_Medical "Medical"
label var per_total_Funeral "Funeral"
label var per_total_LOE "Loss of Earnings" 
label var per_total_Counseling "Counseling"
label var per_total_Transportation "Transportation"
label var per_total_Stolen "Stolen Cash Benefits"


sum per_*

#d ;
graph bar per_*, 
	ytitle(Percent of Paid Claims)
	 graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
    name(payment_types, replace);
#d cr 

//graphing only the more common payments. More than 10% of payments 
#d ;
graph bar per_total_Medical per_total_Funeral per_total_LOE per_total_Counseling per_total_Transportation per_total_Stolen, 
	title(Most Commonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Paid Claims)
	graphregion(color(white))
	ylabel(,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Medical"
                 2 "Funeral"
                 3 "Loss of Earnings"
                 4 "Counseling"
                 5 "Transportation"
                 6 "Stolen Cash"))
    name(payment_types_highest, replace);
#d cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/approved_payments_highest.png", replace 

//less common payments 
//graphing only the least common payments. Less than 10% of payments 
#d ;
graph bar per_total_Relocation per_total_loss_support per_total_Attorney per_total_Other, 
	title(Least Commmonly Reimbursed Payments)
	subtitle(2015-2019, color(black))
	ytitle(Percent of Paid Claims)
	graphregion(color(white))
	yscale(range(0 (1) 10))
	ylabel(0(1)10,nogrid)
	scheme(csgjc_jri_colors)
	bargap(30)
	legend(order(1 "Relocation"
                 2 "Loss of Support"
                 3 "Attorney"
                 4 "Other"))
    name(payment_types_lowest, replace);
#d cr
graph export "$analysis/PA Compensation Data/approved_payments_lowest.png", replace 

//less than 10% of approved claims have compensation for loss of support, relocation, attorney 

restore 

//graphing medical, counseling and LOE payment frequencies by race 

//medical claims rate by race 
foreach var of varlist ameind-white {
	egen `var'_medical=total(`var') if Medical==1 //number medical payments for each race
	egen total_`var'_approved=total(approved) if `var'==1 //number of approved claims for each race 
	gen `var'_med_rate_percent=(`var'_medical/total_`var'_approved)*100 //percent of approved claims with medical payments 
	}

//counseling claims rate by race 
foreach var of varlist ameind-white {
	egen `var'_counseling=total(`var') if Counseling==1 //number counseling payments for each race
	gen `var'_counsel_rate_percent=(`var'_counseling/total_`var'_approved)*100 //percent of approved claims with counseling payments for each race 
	}

//checking values 
foreach var of varlist ameind-white {
	sum Counseling if `var'==1 & approved==1
}
	
//loss of earnings by race 
foreach var of varlist ameind-white {
	egen `var'_loe=total(`var') if LOE==1 //number loe payments for each race
	gen `var'_loe_rate_percent=(`var'_loe/total_`var'_approved)*100 //percent of approved claims with loe payments 
	}
	
//checking values 
foreach var of varlist ameind-white {
	di `var'
	sum LOE if `var'==1 & approved==1
}
	
//for graphs we can collapse to make it easier 
preserve 
collapse (max) *med_rate_percent *counsel_rate_percent *_loe_rate_percent, by(claim_state)
	

//percent approved by race with Medical expenses 
#delimit ;
graph bar *med_rate_percent, 
    title("Payments for Medical Expenses by Victim Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Paid Claims") 
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
graph export "$analysis/PA Compensation Data/approved_race_medicalpayments.png", replace 

//counseling 
#delimit ;
graph bar *counsel_rate_percent, 
    title("Payments for Counseling Expenses by Victim Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Paid Claims") 
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
    name(race_app_counsel_percent, replace) ;
#delimit cr 
//change color of last bar 
gr_edit plotregion1.bars[6].style.editstyle shadestyle(color(dkgreen)) editcopy
gr_edit plotregion1.bars[6].style.editstyle linestyle(color(dkgreen)) editcopy
graph export "$analysis/PA Compensation Data/approved_race_counselpayments.png", replace 

//loss of earnings 
#delimit ;
graph bar *loe_rate_percent, 
    title("Payments for Loss of Earnings by Victim Race")
	subtitle(2015-2019, color(black))
    ytitle("Percent of Paid Claims") 
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
graph export "$analysis/PA Compensation Data/approved_race_loepayments.png", replace 

restore 

/*=====================================================================================
County differences in application rates 
--------------------------------------------------------------------------------------
=======================================================================================*/ 
use "$analysis\PA_county_clean.dta", clear

//maybe only do this for 2019 since its the most recent year 

//applications per crime 
sum app_crime_rate if year==2019

//list of highest and lowest crime counties 
sum viol_crime_per100k if year==2019, detail 

*list app_crime_rate if r(99)


/****************************************************************************************
Neighborhoods with low application rates
=========================================================================================
application rates for violent crimes 

PA: Philadelphia, Pittsburgh, Reading, Allentown, Scranton

Data: PA claims data for major cities with PD crime data 
*****************************************************************************************/
use "$analysis\PA Compensation Data\pa_comp_with_ngd_crime.dta", clear

//collapse data for 5 years 
collapse (sum) claim_number homicide approved zip_tot_pop zip_homicide zip_violent (first) victim_city, by(zip)
 
//claim approval rate overall in these major cities across all 5 years 
preserve 
gen state="PA"
collapse (sum) claim_number approved, by(state)
sum claim_number approved
gen per_approved_largecity=(approved/claim_number)*100
sum per_approved_largecity
gen not_approved=claim_number-approved
graph pie approved
restore  
 
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

//visualizing these 
scatter zip_app_rate zip_violent_rate 
scatter zip_app_crime_rate  zip_violent_rate

//identify high crime zipcodes 
sum zip_violent_rate, detail 
list zip if zip_violent_rate>=r(p99)

//two-way line graph 
graph twoway line zip_violent_rate zip_app_rate
graph twoway line zip_violent_rate zip_app_crime_rate

/*
//look at the highest crime zipcodes and check the application rate 
sum zip_violent_rate, detail 
list zip_app_crime_rate if zip_violent_rate>=r(p99) 
list claim_number if zip_violent_rate>=r(p99)  
list zip if zip_violent_rate>=r(p99) 
tab zip if zip_violent_rate>=r(p99) //95 zip codes in the 99th percentile 



sum zip_app_crime_rate if zip_violent_rate>=r(p99) //in the zipcodes with the highest violent crime rates the application is 12/1000 on average. In the top 99th percentile of zipcodes 

sum zip_app_rate if zip_violent_rate>=r(p99) //in the zipcodes with the highest violent crime rates the application is 0....
**are these zip codes downtown with low residents? 

tab victim_city if zip_violent_rate>=r(p99)
*/
//nothing above this is working I don't think it's giving me what I want 

//what is the application rate, in the highest crime neighborhoods? 
sort zip_violent_rate
br 

tab zip zip_violent_rate if zip_violent_rate>=51.78323 & zip_violent_rate<=1612.903 //5 highest zip codes 
tab zip zip_app_rate if zip_violent_rate>=51.78323 & zip_violent_rate<=1612.903
tab zip zip_app_crime_rate if zip_violent_rate>=51.78323 & zip_violent_rate<=1612.903


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

//identify 5 lowest crime zip codes 
list zip_violent_rate zip_app_crime_rate claim_number if rank_zip_viol_rate <= 5 //these are all 0 violent crimes 

list zip zip_violent_rate if rank_zip_viol_rate >= 9 & rank_zip_viol_rate<=13 //these are the lowest 5 that aren't 0

//zip violent crime rate and application per crime rate
list zip zip_violent_rate zip_app_crime_rate if rank_zip_viol_rate >= 9 & rank_zip_viol_rate<=13 //these are the lowest 5 that aren't 0

//adding in number of crimes and number of applications 
list zip zip_violent_rate zip_app_crime_rate zip_violent claim_number if rank_zip_viol_rate >= 9 & rank_zip_viol_rate<=13 //these are the lowest 5 that aren't 0


//top 5 highest zip codes 
list zip zip_violent_rate if rank_zip_viol_rate >= 105 & rank_zip_viol_rate<=109 //these are the highest 5

//zip violent crime rate and application per crime rate
list zip zip_violent_rate zip_app_crime_rate if rank_zip_viol_rate >= 105 & rank_zip_viol_rate<=109 //these are the highest 5

//adding in number of crimes and number of applications 
list zip zip_violent_rate zip_app_crime_rate zip_violent claim_number if rank_zip_viol_rate >= 105 & rank_zip_viol_rate<=109 //these are the highest 5


//exporting data for the highest and lowest zip codes 
preserve 
gen low_crime=1 if rank_zip_viol_rate >= 9 & rank_zip_viol_rate<=13 //lowest 5
gen high_crime=1 if rank_zip_viol_rate >= 105 & rank_zip_viol_rate<=109 //highest 5
keep if low_crime==1 | high_crime==1 

keep zip zip_violent_rate zip_app_crime_rate low_crime high_crime zip_violent claim_number //keeping only variables we need 
sort zip_violent_rate 
order zip zip_violent_rate zip_violent 
export excel "$analysis\PA Compensation Data\high_low_crime_apps.xls", firstrow(variables) replace 
restore 


//highest application zip code 

//ranking zip codes based on the number of applications 
egen rank_zip_claim_number = rank(claim_number), unique

//identify 5 lowest crime zip codes 
list claim_number if rank_zip_claim_number <= 5 //these are all 0 applications 
sort rank_zip_claim_number
br claim_number rank_zip_claim_number


list zip zip_violent_rate zip_violent if rank_zip_claim_number <= 5 //0 crimes 
list zip zip_violent_rate zip_violent if rank_zip_claim_number <= 80 //0 application zip codes 
list zip claim_number zip_violent if rank_zip_claim_number <= 80 //0 application zip codes 

//list of zip codes with 0 applications but more violent crimes 
preserve

//zip codes with no applications 
gen no_app=1 if rank_zip_claim_number <= 80

//5 highest application zip codes 
gen high_app=1 if rank_zip_claim_number >=200 & rank_zip_claim_number <=204

//keeping only the high and low zip codes 
keep if no_app==1 | high_app==1

keep if zip_violent>0 //only keeping those 0 application zip codes with more than 0 applications 

keep zip claim_number zip_violent zip_violent_rate zip_tot_pop no_app high_app //looking to see what the population of these zip codes was 

export excel "$analysis\PA Compensation Data\low_app_zipcodes.xls", firstrow(variables) replace 
restore

//look at places with no applications but people living there 
list zip zip_tot_pop zip_violent zip_violent_rate if rank_zip_claim_number <= 80 



//NOTES: including the highest/lowest crime rate vs. number of crimes changes the ranking because we adjust for population with the rate and not with the raw number 

log close 
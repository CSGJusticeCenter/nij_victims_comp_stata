/****************************************************************************
Project: NIJ Victims Comp
Author: Seba Guzman
Date: 1/29/2025
Updated: 3/3/2025

survey_graphs.do does the following:
	1. Sets up the relevant directories and initiates a log.
	2. Imports the data from the survey and cleans it
	3. Creates graphs showing the percentage of states that have implemented 
	certian policies and practices.

Inputs:
	- survey_clean_sorted.xlsx
	- survey_answers_${longform_qs}_long.xlsx (longform_qs is 26_52_54_56)
	Note: these files have been manually creating by opening the CSV file of the 
	same name in Excel and saving it as XLSX. This is done to prevent mismatch due
	to some cells containing linebreaks.

Output:
	- Several png. graphs stored in {results_directory}
	- log

Requirements:
	- scheme csgjc_jri_colors (available at ~\The Council of State Governments\JC Research - Documents\Division Resources\08_Programming Resources\Visual Style Guidelines\Stata color schemes)
	To set it up, you just need to copy the .scheme file to your personal folder.
***************************************************************************/

/***************************************************************************
1. Setup and logging
***************************************************************************/
macro drop _all // in case running a second time in the same session

// Set up the relevant directories
global project_directory "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp"
global clean_directory "${project_directory}\data\Clean\Survey"
global results_directory "${project_directory}\data\Analysis\Phase 1 National\survey_graphs"
global log_directory "${project_directory}\code\Survey analysis\logs"


// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY-NN-DD date("$S_DATE","DMY")
display "$S_DATE" 
display "$out_date" // to check that current date and out_date are the same
capture log close // close any existing log before logging.
cd "$log_directory" // set the directory
log using "`survey_graphs'$out_date.smcl", append
// Indicate a new log was initiated with the time, to distinguish between multiple 
	// executions in a day.
noi di as error "************************************************************"
noi di as error "Logging initiated at $S_TIME"


// Create a global with the list of questions in long form that will be brought 
	// from a separate file
global longform_q_numbers "26 52 54 56"
// Create a string for the file name to use
local i = 1 // counter
global longform_qs "" //clearing in case it existed.
foreach number in $longform_q_numbers {
	if `i' == 1 global longform_qs_connected "`number'"
	else global longform_qs_connected "${longform_qs_connected}_`number'"
	local i = `i' + 1
}
di "$longform_qs_connected"

// Create a global with the list of longform q numbers to use.
global longform_qs_spaced ""
foreach number in $longform_q_numbers {
	global longform_qs_spaced "${longform_qs_spaced} q`number'"
}
di "$longform_qs_spaced"

// Set up the color scheme
set scheme csgjc_jri_colors
/***************************************************************************
2. Import the data and clean it
***************************************************************************/


clear
cd "$clean_directory"

*******************************
//Import and clean the main file
import excel survey_clean_sorted, clear


// Take labels from the content of the first row and rename the variables 
	// with the number that it starts with, plus a letter if there are more than 
	// one column starting with the same number. Destring and then encode if possible.
local extranumber = 1 // to append when two vars. have the same number
foreach var of varlist _all {
	di "`var'"
	di `var'[1]
	// Extract the name to a local. It can't be more than 80 chars., so if it's 
		// more, we add ... at the end.
	local var_label = substr(`var'[1], 1, 78) // extract 1st 78 chars. 
	// Add ... after the 75th char. if more than 77
	if strlen("`var_label'") > 77 local var_label = substr("`var_label'", 1, 75) + "..." 
	label var `var' "`var_label'" // label the var
	di "`var_label'"
	
	// Store the entire string in a global for future reference
	// First the question number
	local q_number = substr("`var_label'", 1, strpos("`var_label'", ".") - 1)
	
	// Now store the entire lable as global with the extra number in case needed, 
		// 1 by default
		// but `extranumber' gets updated later if there are many with the same
		// q_number
	global q`q_number'_`extranumber' = `var'[1]
	// Rename it as v1 or v plus the number before the first period
	local varname = "q" + substr("`var_label'", 1, strpos("`var_label'", ".") - 1)
	// Add _# with correlative numbers if the last one is the same as the previous
	if "`varname'" == "`lastvarname'" {
		local lastvarname = "`varname'" // saved to check in next iteration
		local extranumber = `extranumber' + 1 // update
		// Rename the previous one if it was the first in a series with the same
			// basic number, since it would not have the extra number 1 added yet
		if `extranumber' == 2 rename `varname' `varname'_1
		local varname = "`varname'_`extranumber'" // create the name for the current var
	}
	else {
		local lastvarname = "`varname'" // saved to check in next iteration
		local extranumber = 1 // reset the counter
	}
	rename `var' `varname'
	di "`varname' renamed"
	
	// Destring and encode as appropriate. 
	// But first, replace "â€™" with apostrophe and missing answers to blanks
	replace `varname' = subinstr(`varname', "â€™", "'", .)
	replace `varname' = "" if inlist(`varname', "NA", "N/A", "n/a", "DK", "Don't Know", ///
		"Don't know", "don't know")
	replace `varname' = "" if _n == 1 // also replace the first row with the label
	destring `varname', replace
	// Encode if the variables was not destrung because it has non-numeric values, 
		// but also, skip vars. that are open-ended text, not worth encoding. Also,
		// skip q1, state name, so that the merge is on strings, it's safer.
		// This needs multiple lines to avoid an "expression too long" error
	capture confirm string variable `varname'
	if !_rc & !inlist("`varname'", "q1", "q2_2", "q4_17", "q7", "q9_6", "q_10") ///
		& !inlist("`varname'", "q11_6", "q12_5", "q14_21", "q15_97", "q16_7" "q20_2") ///
		& !inlist("`varname'", "q21", "q24_2", "q26_2", "q30_2", "q36_6") ///
		& !inlist("`varname'", "q37_10", "q39_15", "q40_2", "q44_2", "q45_2") ///
		& !inlist("`varname'", "q46_2", "q47_2", "q48_2", "q50_2", "q53") ///
		& !inlist("`varname'", "q54_2", "q56_2", "q57_2", "q59_17", "q60") ///
		& strpos("`varname'", "q31") == 0 /// 
		& strpos("`varname'", "q32") == 0 /// 
		& strpos("`varname'", "q61") == 0 { //
		
		di as error "`varname'"
		di as text ""
		
		di "About to encode `varname'"
		encode `varname', generate(`varname'_enc)
		order `varname'_enc, after(`varname')
		drop `varname'
		rename `varname'_enc `varname'
	}
}
drop if _n == 1 // drop the first row with labels.
duplicates report 
if r(unique_value) != r(N) {
	noi di as error "ATTENTION: program ended because of duplicates"
	r(1)
}
// Drop the variables that will be taken from a long-form dataset
// sometimes they are droped as, say q26, but most typically as q26_1
foreach number in $longform_q_numbers {
	capture drop q`number'
	if !_rc di "q`number' dropped"
	capture drop q`number'_1
	if !_rc di "q`number'_1 dropped"
	
	// Also, rename the q#_2, e.g., q26_2, since this includes the open-ended answers
		// to the multiselect questions in long form in another dataset, if they exist
	capture rename q`number'_2 q`number'_0 // _0 avoids conflicts with the multiselect 
		// options in the long form
	if !_rc di "q`number'_2 renamed"
	// Update the globals with the long labels. Take it from q#_1 and substract 
		// " - Other (please describe): - Text"
	global q`number'_0 = trim(substr("${q`number'_1}", 1, strpos("${q`number'_1}","Please select all that apply. - Other (please describe): - Text") - 1))
	global q`number'_2 "" // clearing $q#_2 for future use.
	global q`number'_4 "" // clearing it because some were stored there
	di as error "$q`number'_0"
}

save survey_clean_sorted.dta, replace

********************
// Import and clean the data from the files in long form
********************


// Import the file with questions multiselect questions in long format
import delimited survey_answers_${longform_qs_connected}_long.csv, clear varnames(nonames) bindquote(strict)

replace v3 = subinstr(v3, char(10), " ", .)
replace v3 = subinstr(v3, char(13), " ", .)

// Rename and label the variables
rename v1 q1
label var q1 "1. Please indicate what state, territory or district are you answering about."
rename v2 q_number
label var q_number "question number"
rename v3 answer
// Drop the row with labels
drop if _n == 1

// Remove spaces at the beginning or end
replace answer = trim(answer)

// Sort and extract Q subnumbers
sort q_number answer
// Create an indicator that a new answer has began when going down the list. This
	// will be used to add them to the previous value, so that we have the same 
	// q_second_number for all answers that are the same.
gen new_q_indicator = 1 if answer != answer[_n-1] // temp. var.
replace new_q_indicator = 0 if new_q_indicator == .
gen q_second_number = new_q_indicator // This will be updated soon.
// Update q_second_number by adding to the previous one if it's the same q_number,
	// that way, we keep going up for each new answer, but restart at 1 for a new
	// q_number
replace q_second_number = new_q_indicator + q_second_number[_n-1] if q_number == q_number[_n-1]
// Create a string with the main and second q numbers, like the varnames in the 
	// previous dataset, to merge them later.
gen str q_long_number = "q" + q_number + "_" + strofreal(q_second_number)
drop new_q_indicator
destring q_number, replace
*encode q_long_number, gen(q_long_number_enc)

// Extract the answers to macros for later use
// First, identify the largest second number
egen max_second_number = max(q_second_number)
global max_2nd_number = max_second_number[1]
drop max_second_number

foreach i in $longform_qs_spaced {
	forvalues j = 1/$max_2nd_number {
		// Temporarily drop all but each of the q`i'_`j' to extract the answer
		preserve
		di "preserved"
		di "`i'_`j'"
		drop if q_long_number != "`i'_`j'"
		if _N == 0 {
			restore
			continue
		}
		di "Question wording: ${`i'_0}"
		// Get the answer
		global `i'_`j' = answer[1]
		di "Question answer: ${`i'_`j'}"
		restore
	}
}

// Drop the answers, we have them stored. We will create a 1 for all cases that
	// are represented
drop answer
gen answer = 1

// Sort and reshape
// First drop q_second_number and q_long_number, not needed
drop q_long_number 
// Now we reshape separately for each q_number
local previous_q = 0 // for use later
foreach q in $longform_q_numbers /*$longform_qs_spaced*/ {
	di "`q'"
	preserve
	drop if q_number != `q'
	// First, convert strL to str
	gen str q1_str = q1 // because q1 is strL, which can't be used for matching
	drop q1 
	rename q1_str q1
	sort q1 q_number q_second_number
	reshape wide q_number, i(q1) j(q_second_number)
	// Rename and label the variables appropriately, as in the first dataset
	local i = 1
	foreach var of varlist _all {
		if "`var'" == "q1" continue
		di "`var'"
		if "`var'" == "q_number1" local i = 1
		else local i = `i' + 1
		di as error `i'
		rename `var' q`q'_`i'
		label var q`q'_`i' "`q'. ${q`q'_`i'}"
		replace q`q'_`i' = 1 if q`q'_`i' != .
		replace q`q'_`i' = 0 if q`q'_`i' == .
	}
	// Merge if not the first q, if the first q, just update previous q
	if `previous_q' == 0 local previous_q = `q'
	else {
		// Merge and update previous_q
		merge 1:1 q1 using q`previous_q'_long.dta
		local previous_q = `q'
		drop _merge
	}
	save q`q'_long.dta, replace
	if `previous_q' != `q' file erase q`previous_q'_long.dta // erase older ones
	restore
}

// Extract the last q# for the name of the last file.
local last_qnumber = substr("$longform_qs_spaced", strlen("$longform_qs_spaced") - 3, .)
di "`last_qnumber'"
use `last_qnumber'_long.dta, clear
save longvars.dta, replace

****************************************
// Merge with the main file.
merge 1:1 q1 using survey_clean_sorted.dta

/***************************************************************************
3. Analyze the data and create the graphs
***************************************************************************/
/* We are interested in questions where there is relevant variation. If all the
states are doing something, it's not something worth highlighting in the limited 
space available
*/

// Create a program that checks for distribution by tabbing the non-string vars in 
	// a list, and browsing through the string ones. Listing is not
	// very useful because answers are often too long to fit in the cell,
	// so manual browsing is needed.
capture program drop tab_browse // in case we re-run the module and the program is active
program define tab_browse 
	syntax varlist
	foreach var of varlist `varlist' {
		di "`var'"
		capture confirm string variable `var'
		if !_rc {
			browse q1 `var' if `var' != "" //q1 is the state's name
		}
		else tab `var', missing 
	}
end

*********************
// 3.1 Q11
*********************
tab_browse q11*

// Results: q11_3 and q11_4 have variation. We append them to the list of variables
	// to be used later in collapse
global select_vars "q11_3 q11_4 "

*********************
// 3.2 Q12
*********************
// Check if there's any variation
tab_browse q12*

// Check how the open-ended responses relate to the closed ones.
browse q1 q12_1 q12_2 q12_3 q12_5 if q12_5 != ""
/* Notes: 
Some of these policies are not in place any more. LA said they waived some recently.
When explaining results, note that if a state does not have a requirement, it would
not be waived. So the frequency of not having it plus waiving it should be considered.
*/	

// Append relevant vars to the list
global select_vars "$select_vars q12_1 q12_2 q12_3"


*********************
// 3.3 Q17
*********************
// Check if there's any variation and append relevant ones to the list
tab_browse q17*
global select_vars "$select_vars q17"


*********************
// 3.4 Q34
*********************
// Check if there's any variation and append relevant ones to the list
tab_browse q34*
global select_vars "$select_vars q34"

*********************
// 3.5 Multiselect questions
*********************
di as error "$q26"
di as error "0: $q26_0"
foreach number in $longform_q_numbers {
	di as error `number'
	forvalues i = 0/$max_2nd_number {
		di as text "q`number'_`i'"
		if "${q`number'_`i'}" != "" di "${q`number'_`i'}" // Display the macro with the question
		capture tab_browse q`number'_`i' // check if the q exists
		if !_rc tab_browse q`number'_`i' // tab if the q exists
	}
}
browse _all

// Create a list of vars for each question, skip the NA option, that's missing, 
	// other, and questions we're not interested in.
foreach number in $longform_q_numbers {
	local stop = 0
	local counter = 1
	while `stop' == 0 {
		// Skip if it's an "Other" answer or NA, or one we're not interested in.
		local skip = 0
		foreach answer in "Other" "NA" {
			if strpos("${q`number'_`counter'}", "`answer'") > 0 local skip = 1
		}
		if `skip' == 1 { // we do this outside of the answer loop, otherwise the 
			// continue below is from the answer loop instead of the number loop
			local counter = `counter' + 1
			continue
		}
		// End if there's no answer
		if "${q`number'_`counter'}" == "" {
			local stop = 1
			continue
		}
		di "q: ${q`number'_`counter'}"
		// Concatenate the other vars
		global q`number'_vars = trim("${q`number'_vars} " + "q`number'_`counter'")
		local counter = `counter' + 1
		di `counter'
		di `stop'
	}
	di "`number'"
	di "${q`number'_vars}"
}


// Split 56 into two, it's too many options we'll call each half 156 and 256 for the loops that come up
	// We do this dynamically in case we want to do the same with more variables
global extensive_qs "52 56"
foreach qn in $extensive_qs {
	local words`qn' = wordcount("${q`qn'_vars}")
	di as error `words`qn''
	local counter = 1
	global q1`qn'_vars = "" // in case we are running in the same session
	global q2`qn'_vars = ""
	foreach var in ${q`qn'_vars} {
		// Get the var suffix
		local suffix = substr("`var'", strpos("`var'", "_") + 1, .)
		di "suffix: `suffix'"
		
		di "counter: `counter'"
		if `counter' <= `words`qn'' / 2 local prefix "1"
		else local prefix "2"
		di "prefix: `prefix'"
		// Copy the question
		global q`prefix'`qn'_vars = trim("${q`prefix'`qn'_vars} q`prefix'`qn'_`suffix'")
		di as error "${q`prefix'`qn'_vars}"
		// Copy the global that has the answer
		global q`prefix'`qn'_`suffix' = "${q`qn'_`suffix'}"
		local counter = `counter' + 1
		// Copy the variable
		gen q`prefix'`qn'_`suffix' = q`qn'_`suffix'
		// Copy the question global
		global q`prefix'`qn'_0 = "${q`qn'_0}"
	}
	di as text "${q1`qn'_vars}"
	di as text "${q2`qn'_vars}"
}

// Create a var that combines key q56 options
global q356 "Strategies used to increase accessibility of victim compensation"
gen q356_1 = 1 if inlist(1, q56_1, q56_2, q56_3, q56_10, q56_14)
label var q356_1 "Advertisement (printed, billboard, online, TV, radio)"
gen q356_2 = 1 if q56_4 + q56_5 + q56_6 + q56_7 > 1
label var q356_2 "Had more than one option to apply (paper, online, calling)"
gen q356_3 = 1 if inlist(1, q56_7, q56_19)
label var q356_3 "Had information in other languages (application or toll free line)"
gen q356_4 = 1 if inlist(1, q56_18, q56_19)
label var q356_4 "Toll free information line (English or multilingual)"
gen q356_5 = 1 if inlist(1, q56_15, q56_16, q56_17)
label var q356_5 "Targeted outreach to providers or population groups"
foreach var of varlist q356_* { // to replace missing
	replace `var' = 0 if `var' == . & !inlist(1, q56_8, q56_9) //q56_8 & q56_9 are DK/NA
}
// Note: we are replacing DK as missing and won't be reporting them in the N because
	// unlike in opinion surveys where the DK matters, here the DK probably means
	// that the person who responded for the state doesn't know because they were
	// not in the program at the time, so it's more like a NA for the purposes of
	// the reporting. The actual NAs are there when the person did not complete 
	// the survey, some states stopped half way through. So N will be used to report
	// those who actually answered the question other than DK.

// Create a var that combines key q54 options
global q354 "Activities conducted to assess disparities in victim compensation"
gen q354_1 = 1 if inlist(1, q54_1, q54_2)
label var q354_1  "Claimant survey or focus group"
gen q354_2 = 1 if inlist(1, q54_3, q54_4)
label var q354_2  "Stakeholder survey or focus group"
gen q354_3 = 1 if inlist(1, q54_7, q54_9, q54_10)
label var q354_3  "Worked with a consultant"
gen q354_4 = 1 if inlist(1, q54_11, q54_12, q54_13)
label var q354_4  "Other"
gen q354_5 = 1 if inlist(1, q54_14)
label var q354_5 "No activity conducted"
foreach var of varlist q354_* { // to replace missing
	replace `var' = 0 if `var' == . & !inlist(1, q54_5, q54_8) //q54_5 & q54_8 are DK/NA
}

// We will update longform_q_numbers in a bit, but first:
// Get the N for each longform q by substracting the missing/NA
foreach number in $longform_q_numbers {
	// Use the version without prefix for the $extensive_qs ones
	if strlen("`number'") > 2 local number = substr("`number'", 2, .) // cut the prefix
	
	// Get the NA question
	local stop = 0
	local counter = 1
	while `stop' == 0 {
		if inlist("${q`number'_`counter'}", "`number'. NA", "`number'. Don't know", "NA", "Don't know") {
			qui sum q`number'_`counter'
			global q`number'_n = _N - r(sum)
			local stop = 1
		}
		else local counter = `counter' + 1
		di `counter'
	}
	// Copy the q`number'_n for the extensive_qs
	if strpos("$extensive_qs", "`number'") > 0 {
		global q1`number'_n = ${q`number'_n}
		global q2`number'_n = ${q`number'_n}
	}
}

// Remove the questions that we don't want from q26_*
global q26_vars "q26_1 q26_14 q26_15 q26_16"

// Now we update longform_q_numbers
foreach number in $longform_q_numbers {
	if strpos("$extensive_qs", "`number'") > 0 {
		local lf_q_n = trim("`lf_q_n' 1`number' 2`number'")
	}
	else local lf_q_n = trim("`lf_q_n' `number'")
	di "`lf_q_n'"
}
global longform_q_numbers "`lf_q_n'"
di "$longform_q_numbers"

// Define a global with the vars from which we selected only some answers
global select_answers_var_numbers "26"

// Create, via a loop, a macro str that will be used for the command of the labels for the longform qs
	// It should be something like:
	// label(1 "$[word 1 of "$q26_vars"]") label(2 "$[word 2 of "$q26_vars"]") ...
	// Each word, as a macro, has the long question that doesn't fit in a label
foreach number in $longform_q_numbers 354 356 {
	local stop = 0
	local counter = 1 
	global drop labels_q`number' // clear it before the next loop
	global labels_q`number' "" // clear it before the next loop
	while `stop' == 0 {
		// Set ways to end. First, extracting a local to be used later and see if the var exists
		local global_name = word("${q`number'_vars}", `counter')
		di "counter: `counter', global_name: `global_name'"
		di as error "${`global_name'}"
		if "`global_name'" == "" {
			local stop = 1
			continue
		}
		
		global labels_q`number' `"${labels_q`number'} label(`counter' "${`global_name'}")"'
		di as error `"labels_q`number':"'
		di as text `"${labels_q`number'}"'
		local counter = `counter' + 1
	}
}

// Edit title of the longform ones to be in two lines
foreach number in $longform_q_numbers {
	di "`number'"
	// Get the number of words and middle
	local words = wordcount("${q`number'_0}")
	local mid = ceil(`words'/2)
	// Concatenate the first half of words in q`number'_0a and the rest in q`number'_0b
	forvalues i = 1/`words' {
		if `i' <= `mid' local letter "a"
		else local letter "b"
		di word("${q`number'_0}", `i')
		global q`number'_0`letter' = trim("${q`number'_0`letter'} " + word("${q`number'_0}", `i'))
	}
	di "${q`number'_0a}"
	di "${q`number'_0b}"
}

// Get the N for Qs of the select_vars
foreach var of varlist $select_vars {
	qui tab `var'
	local `var'_n = r(N)
}

// Recode select_vars as 0 1 if they aren't already.
label define yesno 0 "No" 1 "Yes"
foreach var of varlist $select_vars {
	tab `var' if `var' == 2
	if r(N) > 0 {
		tab `var' if `var' == 0
		if r(N) == 0 {
			replace `var' = 0 if `var' == 1
			replace `var' = 1 if `var' == 2
			label var `var' yesno
		}
	}
}

// Create labels for select_vars. These are done manually because we summarize them
global labels_select_vars `"label(1 "Elig. Req.: Resident victimized in another state (N=`q11_3_n')") label(2 "Elig. Req.: Crime reported to Medical Professional (N=`q11_4_n')") label(3 "Waivable: Cooperation with Law Enforcement (N=`q12_1_n')") label(4 "Waivable: Filing Deadlines (N=`q12_2_n')") label(5 "Waivable: Law Enforcement Reporting Requirements (N=`q12_3_n')") label(6 "Protected victims against collection processes while deciding (N=`q17_n')") label(7 "Law or policy that required victims to be notified about program (N=`q34_n')")"'

// Create the graphs
// select_vars (count)
graph bar (sum) $select_vars, legend(${labels_select_vars} position(6) cols(1) span) ///
    ylabel(,angle(0)) ytitle("Number of states") ///
	title("Frequency of key policies and practices") ///
	note("Note: Questions edited for brevity.", span) bargap(30)
graph export "${results_directory}\select_vars_n.png", replace height(675) width(1023)
// select_vars (pcnt)
foreach var of varlist $select_vars {
	replace `var' = `var' * 100
}
graph bar (mean) $select_vars, legend(${labels_select_vars} position(6) cols(1) span) ///
    ylabel(,angle(0)) ytitle("Percentage of states") ///
	title("Frequency of key policies and practices") ///
	note("Note: Questions edited for brevity.", span) bargap(30)
graph export "${results_directory}\select_vars_pc.png", replace height(675) width(1023)

foreach var of varlist $select_vars {
	tab `var'
}

foreach number in 354 356 {
	// Get the N
	qui tab q`number'_1 // they all have the same missing
	local answers_n = r(N)
	// Create the legend command with a loop
	global labels_q`number' "" // clear it before the loop
	di as text "q`number'"
	di as error `"${labels_q`number'}"'	
	local counter = 1
	local stop = 0
	while `stop' == 0 {
		capture tab q`number'_`counter' // to check if the var. exists
		if _rc != 0 { // If it doesn't, end the loop
			local stop = 1
			continue
		}
		local varlabel :variable label q`number'_`counter'
		di "`counter': `varlabel'"
		global labels_q`number' `"${labels_q`number'} label(`counter' "`varlabel'")"'
		local counter = `counter' + 1
	}
	// di as error `"${labels_q`number'}"' 
	//if `number' == 354 local cols = 2
	// else 
	local cols = 1
	graph bar (sum) q`number'_*, legend(${labels_q`number'} position(6) size(medsmall) cols(`cols')) ///
		ylabel(,angle(0)) ytitle("Number of states") title("${q`number'}", size(medium)) note("N = `answers_n'. Columns show combinationes of multi-select choices.") bargap(30)
	graph export "${results_directory}\q`number'_n.png", replace height(675) width(1023)
}

foreach number in 26  {
	// Remove the Q number from the global with the question
	di "${q`number'_0a}"
	global q`number'_0a = substr("${q`number'_0a}", strpos("${q`number'_0a}", ".") + 2, .)
	di "${q`number'_0a}"
	graph bar (sum) ${q`number'_vars}, legend(${labels_q`number'} position(6) ///
		size(medsmall) cols(1) span) note("N = ${q`number'_n}. Only select answers reported.") ///
		ytitle(, margin(right + 10)) ylabel(,angle(0)) ytitle("Number of states") ///
		title("${q`number'_0a}" "${q`number'_0b}" , size(medsmall)) bargap(30)
	graph export "${results_directory}\q`number'.png", replace height(675) width(1023)
}

	


/***************************************************************************
Close the log
***************************************************************************/
log close
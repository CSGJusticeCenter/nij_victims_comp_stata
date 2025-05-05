/*
To do 
--set global cd 
--order do files in order of cleaning and merging 
--create data files for tzoumis first name and last name probabilities (raw and cleaned files)
--bring in Seba's cleaning files for addresses 
--make a separate folder with all necessary files to execute project
*/ 


/*do files ordering--make sure numbers align 
1. creating data files--names/probabilities list 
2. cleaning street addresses for the state 
3. creating excel sheet 
4. cleaning names in excel 
5. cleaning addresses in excel 
6. matching names and address functions in excel 
*/


clear 
set more off 

global dir="~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\BIFSG Stata" 

cd "$dir" //setting directory 

global data="$dir\Data Files" //directory for data files---update this to correct file locations in data folder 
global excel="$dir\Excel Files" //directory for excel output files 

//Census and Tzoumis race probability calculation 
do "checking HMDA demographics with national comparisons.do" //might not need this anymore 

//Creating corrected Tzoumis and Rosenman et al. (2023) name probabilities files with corrections where needed 
do "Name_race_prob_cleaning.do" // add in a version of data without correction/adjustment 

//separate first and last name files 



//Creating excel sheets//

//name cleaning do 
do "02-BIFSG_name_cleaning.do"

//name matching do 
do "03-BIFSG_name_matching.do"

//adding first and last name sheets w/ all names--we need corrected and uncorrected probabilities here 

//don't necessarily need to run all of these every time like recreating name corrections etc. 


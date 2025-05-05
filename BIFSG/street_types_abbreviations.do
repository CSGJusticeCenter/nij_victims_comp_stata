/**********************************************************************
Project: NIJ Equity in Victims Compensation
Author: Seba Guzman
Date: 11/27/2021

Street type database does the following:
	- Creates the file street_abbreviations.dta, which contains:
		- All street types (including extensions) and their abbreviations
		- All cardinal points and their abbreviations
		- All ordinal numbers First-Tenth and their abbreviations
		- A variable that identifies the type of abbreviation the row refers to
	- The file is based on one from USPS, but has some corrections.
	- Exports the data to a sheet in an excel file.
	- The file is ran from another program and receives information about where
	to save or export the outputs from them.
		
The file is used for cleaning and matching street names
**********************************************************************/

/* ATTENTION: code is desinged to run from another program that passes
`excel_filename' as argument and initiates the globals output_directory, code_directory, 
and excel_directory. If running on it's own, activate the lines below
*/
/*
local excel_filename "BIFSG_street_cleaning_and_matching_test_`state'"
global output_directory "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\data\Analysis\Phase 2 State\RAND BISG\"
global excel_directory "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\" 
global code_directory "~\The Council of State Governments\JC Research - Documents\RES_NIJVictimComp\code\BIFSG\"
*/

// Receive the arguments
local excel_filename `1'

// Set the working directory for logs
cd "$code_directory\logs"

// Create a global macro with the date to append to the log file name, and a log
global out_date : display %tdCCYY-NN-DD date("$S_DATE","DMY")
display "$S_DATE" 
display "$out_date" // to check that current date and out_date are the same
log close
log using "street_types_abbreviations_$out_date.log", replace

// Set the working directory for output
cd "$output_directory"

clear 
// Imput data with unabbreviated full name (abrv0), common abbreviations, and standard abbreviation (abrv1)
// Abbreviations were obtained from https://pe.usps.com/text/pub28/28apc_002.htm and organized into text for a spreadsheet in Excel, removing common abbreviations that are equal to the standard or the non-abbreviated type.
input str20 abrv0 str10 abrv2 str10 abrv3 str10 abrv4 str10 abrv5 str10 abrv6 str10 abrv7 str10 abrv8 str10 abrv1
"Alley"	"Allee"	""	"Ally"	""	""	""	""	"Aly"
"Anex"	""	"Annex"	"Annx"	""	""	""	""	"Anx"
"Arcade"	""	""	""	""	""	""	""	"Arc"
"Avenue"	"Av"	""	"Aven"	"Avenu"	""	"Avn"	"Avnue"	"Ave"
"Bayou"	"Bayoo"	""	""	""	""	""	""	"Byu"
"Beach"	""	""	""	""	""	""	""	"Bch"
"Bend"	""	""	""	""	""	""	""	"Bnd"
"Bluff"	""	"Bluf"	""	""	""	""	""	"Blf"
"Bluffs"	""	""	""	""	""	""	""	"Blfs"
"Bottom"	"Bot"	""	"Bottm"	""	""	""	""	"Btm"
"Boulevard"	""	"Boul"	""	"Boulv"	""	""	""	"Blvd"
"Branch"	""	"Brnch"	""	""	""	""	""	"Br"
"Bridge"	"Brdge"	""	""	""	""	""	""	"Brg"
"Brook"	""	""	""	""	""	""	""	"Brk"
"Brooks"	""	""	""	""	""	""	""	"Brks"
"Burg"	""	""	""	""	""	""	""	"Bg"
"Burgs"	""	""	""	""	""	""	""	"Bgs"
"Bypass"	""	"Bypa"	"Bypas"	""	"Byps"	""	""	"Byp"
"Camp"	""	""	"Cmp"	""	""	""	""	"Cp"
"Canyon"	"Canyn"	""	"Cnyn"	""	""	""	""	"Cyn"
"Cape"	""	""	""	""	""	""	""	"Cpe"
"Causeway"	""	"Causwa"	""	""	""	""	""	"Cswy"
"Center"	"Cen"	"Cent"	""	"Centr"	"Centre"	"Cnter"	"Cntr"	"Ctr"
"Centers"	""	""	""	""	""	""	""	"Ctrs"
"Circle"	""	"Circ"	"Circl"	""	"Crcl"	"Crcle"	""	"Cir"
"Circles"	""	""	""	""	""	""	""	"Cirs"
"Cliff"	""	""	""	""	""	""	""	"Clf"
"Cliffs"	""	""	""	""	""	""	""	"Clfs"
"Club"	""	""	""	""	""	""	""	"Clb"
"Common"	""	""	""	""	""	""	""	"Cmn"
"Commons"	""	""	""	""	""	""	""	"Cmns"
"Corner"	""	""	""	""	""	""	""	"Cor"
"Corners"	""	""	""	""	""	""	""	"Cors"
"Course"	""	""	""	""	""	""	""	"Crse"
"Court"	""	""	""	""	""	""	""	"Ct"
"Courts"	""	""	""	""	""	""	""	"Cts"
"Cove"	""	""	""	""	""	""	""	"Cv"
"Coves"	""	""	""	""	""	""	""	"Cvs"
"Creek"	""	""	""	""	""	""	""	"Crk"
"Crescent"	""	""	"Crsent"	"Crsnt"	""	""	""	"Cres"
"Crest"	""	""	""	""	""	""	""	"Crst"
"Crossing"	""	"Crssng"	""	""	""	""	""	"Xing"
"Crossroad"	""	""	""	""	""	""	""	"Xrd"
"Crossroads"	""	""	""	""	""	""	""	"Xrds"
"Curve"	""	""	""	""	""	""	""	"Curv"
"Dale"	""	""	""	""	""	""	""	"Dl"
"Dam"	""	""	""	""	""	""	""	"Dm"
"Divide"	"Div"	""	""	"Dvd"	""	""	""	"Dv"
"Drive"	""	"Driv"	""	"Drv"	""	""	""	"Dr"
"Drives"	""	""	""	""	""	""	""	"Drs"
"Estate"	""	""	""	""	""	""	""	"Est"
"Estates"	""	""	""	""	""	""	""	"Ests"
"Expressway"	"Exp"	"Expr"	"Express"	""	"Expw"	""	""	"Expy"
"Extension"	""	""	"Extn"	"Extnsn"	""	""	""	"Ext"
"Extensions"	""	""	""	""	""	""	""	"Exts"
"Fall"	""	""	""	""	""	""	""	"Fall"
"Falls"	""	""	""	""	""	""	""	"Fls"
"Ferry"	""	"Frry"	""	""	""	""	""	"Fry"
"Field"	""	""	""	""	""	""	""	"Fld"
"Fields"	""	""	""	""	""	""	""	"Flds"
"Flat"	""	""	""	""	""	""	""	"Flt"
"Flats"	""	""	""	""	""	""	""	"Flts"
"Ford"	""	""	""	""	""	""	""	"Frd"
"Fords"	""	""	""	""	""	""	""	"Frds"
"Forest"	""	"Forests"	""	""	""	""	""	"Frst"
"Forge"	"Forg"	""	""	""	""	""	""	"Frg"
"Forges"	""	""	""	""	""	""	""	"Frgs"
"Fork"	""	""	""	""	""	""	""	"Frk"
"Forks"	""	""	""	""	""	""	""	"Frks"
"Fort"	""	"Frt"	""	""	""	""	""	"Ft"
"Freeway"	""	"Freewy"	"Frway"	"Frwy"	""	""	""	"Fwy"
"Garden"	""	"Gardn"	"Grden"	"Grdn"	""	""	""	"Gdn"
"Gardens"	""	""	"Grdns"	""	""	""	""	"Gdns"
"Gateway"	""	"Gatewy"	"Gatway"	"Gtway"	""	""	""	"Gtwy"
"Glen"	""	""	""	""	""	""	""	"Gln"
"Glens"	""	""	""	""	""	""	""	"Glns"
"Green"	""	""	""	""	""	""	""	"Grn"
"Greens"	""	""	""	""	""	""	""	"Grns"
"Grove"	"Grov"	""	""	""	""	""	""	"Grv"
"Groves"	""	""	""	""	""	""	""	"Grvs"
"Harbor"	"Harb"	""	"Harbr"	""	"Hrbor"	""	""	"Hbr"
"Harbors"	""	""	""	""	""	""	""	"Hbrs"
"Haven"	""	""	""	""	""	""	""	"Hvn"
"Heights"	"Ht"	""	""	""	""	""	""	"Hts"
"Highway"	""	"Highwy"	"Hiway"	"Hiwy"	"Hway"	""	""	"Hwy"
"Hill"	""	""	""	""	""	""	""	"Hl"
"Hills"	""	""	""	""	""	""	""	"Hls"
"Hollow"	"Hllw"	""	"Hollows"	""	"Holws"	""	""	"Holw"
"Inlet"	""	""	""	""	""	""	""	"Inlt"
"Island"	""	""	"Islnd"	""	""	""	""	"Is"
"Islands"	""	"Islnds"	""	""	""	""	""	"Iss"
"Isle"	""	"Isles"	""	""	""	""	""	"Isle"
"Junction"	""	"Jction"	"Jctn"	""	"Junctn"	"Juncton"	""	"Jct"
"Junctions"	"Jctns"	""	""	""	""	""	""	"Jcts"
"Key"	""	""	""	""	""	""	""	"Ky"
"Keys"	""	""	""	""	""	""	""	"Kys"
"Knoll"	""	"Knol"	""	""	""	""	""	"Knl"
"Knolls"	""	""	""	""	""	""	""	"Knls"
"Lake"	""	""	""	""	""	""	""	"Lk"
"Lakes"	""	""	""	""	""	""	""	"Lks"
"Land"	""	""	""	""	""	""	""	"Land"
"Landing"	""	""	"Lndng"	""	""	""	""	"Lndg"
"Lane"	""	""	""	""	""	""	""	"Ln"
"Light"	""	""	""	""	""	""	""	"Lgt"
"Lights"	""	""	""	""	""	""	""	"Lgts"
"Loaf"	""	""	""	""	""	""	""	"Lf"
"Lock"	""	""	""	""	""	""	""	"Lck"
"Locks"	""	""	""	""	""	""	""	"Lcks"
"Lodge"	""	"Ldge"	"Lodg"	""	""	""	""	"Ldg"
"Loop"	""	"Loops"	""	""	""	""	""	"Loop"
"Mall"	""	""	""	""	""	""	""	"Mall"
"Manor"	""	""	""	""	""	""	""	"Mnr"
"Manors"	""	""	""	""	""	""	""	"Mnrs"
"Meadow"	""	""	""	""	""	""	""	"Mdw"
"Meadows"	"Mdw"	""	""	"Medows"	""	""	""	"Mdws"
"Mews"	""	""	""	""	""	""	""	"Mews"
"Mill"	""	""	""	""	""	""	""	"Ml"
"Mills"	""	""	""	""	""	""	""	"Mls"
"Mission"	"Missn"	"Mssn"	""	""	""	""	""	"Msn"
"Motorway"	""	""	""	""	""	""	""	"Mtwy"
"Mount"	"Mnt"	""	""	""	""	""	""	"Mt"
"Mountain"	"Mntain"	"Mntn"	""	"Mountin"	"Mtin"	""	""	"Mtn"
"Mountains"	"Mntns"	""	""	""	""	""	""	"Mtns"
"Neck"	""	""	""	""	""	""	""	"Nck"
"Orchard"	""	""	"Orchrd"	""	""	""	""	"Orch"
"Oval"	""	"Ovl"	""	""	""	""	""	"Oval"
"Overpass"	""	""	""	""	""	""	""	"Opas"
"Park"	""	"Prk"	""	""	""	""	""	"Park"
"Parks"	""	""	""	""	""	""	""	"Park"
"Parkway"	""	"Parkwy"	"Pkway"	""	"Pky"	""	""	"Pkwy"
"Parkways"	""	"Pkwys"	""	""	""	""	""	"Pkwy"
"Pass"	""	""	""	""	""	""	""	"Pass"
"Passage"	""	""	""	""	""	""	""	"Psge"
"Path"	""	"Paths"	""	""	""	""	""	"Path"
"Pike"	""	"Pikes"	""	""	""	""	""	"Pike"
"Pine"	""	""	""	""	""	""	""	"Pne"
"Pines"	""	""	""	""	""	""	""	"Pnes"
"Place"	""	""	""	""	""	""	""	"Pl"
"Plain"	""	""	""	""	""	""	""	"Pln"
"Plains"	""	""	""	""	""	""	""	"Plns"
"Plaza"	""	""	"Plza"	""	""	""	""	"Plz"
"Point"	""	""	""	""	""	""	""	"Pt"
"Points"	""	""	""	""	""	""	""	"Pts"
"Port"	""	""	""	""	""	""	""	"Prt"
"Ports"	""	""	""	""	""	""	""	"Prts"
"Prairie"	""	""	"Prr"	""	""	""	""	"Pr"
"Radial"	"Rad"	""	"Radiel"	""	""	""	""	"Radl"
"Ramp"	""	""	""	""	""	""	""	"Ramp"
"Ranch"	""	"Ranches"	""	"Rnchs"	""	""	""	"Rnch"
"Rapid"	""	""	""	""	""	""	""	"Rpd"
"Rapids"	""	""	""	""	""	""	""	"Rpds"
"Rest"	""	""	""	""	""	""	""	"Rst"
"Ridge"	""	"Rdge"	""	""	""	""	""	"Rdg"
"Ridges"	""	""	""	""	""	""	""	"Rdgs"
"River"	""	""	"Rvr"	"Rivr"	""	""	""	"Riv"
"Road"	""	""	""	""	""	""	""	"Rd"
"Roads"	""	""	""	""	""	""	""	"Rds"
"Route"	""	""	""	""	""	""	""	"Rte"
"Row"	""	""	""	""	""	""	""	"Row"
"Rue"	""	""	""	""	""	""	""	"Rue"
"Run"	""	""	""	""	""	""	""	"Run"
"Shoal"	""	""	""	""	""	""	""	"Shl"
"Shoals"	""	""	""	""	""	""	""	"Shls"
"Shore"	"Shoar"	""	""	""	""	""	""	"Shr"
"Shores"	"Shoars"	""	""	""	""	""	""	"Shrs"
"Skyway"	""	""	""	""	""	""	""	"Skwy"
"Spring"	""	"Spng"	""	"Sprng"	""	""	""	"Spg"
"Springs"	""	"Spngs"	""	"Sprngs"	""	""	""	"Spgs"
"Spur"	""	""	""	""	""	""	""	"Spur"
"Spurs"	""	""	""	""	""	""	""	"Spur"
"Square"	""	"Sqr"	"Sqre"	"Squ"	""	""	""	"Sq"
"Squares"	"Sqrs"	""	""	""	""	""	""	"Sqs"
"Station"	""	""	"Statn"	"Stn"	""	""	""	"Sta"
"Stravenue"	""	"Strav"	"Straven"	""	"Stravn"	"Strvn"	"Strvnue"	"Stra"
"Stream"	""	"Streme"	""	""	""	""	""	"Strm"
"Street"	""	"Strt"	""	"Str"	""	""	""	"St"
"Streets"	""	""	""	""	""	""	""	"Sts"
"Summit"	""	"Sumit"	"Sumitt"	""	""	""	""	"Smt"
"Terrace"	""	"Terr"	""	""	""	""	""	"Ter"
"Throughway"	""	""	""	""	""	""	""	"Trwy"
"Trace"	""	"Traces"	""	""	""	""	""	"Trce"
"Track"	""	"Tracks"	""	"Trk"	"Trks"	""	""	"Trak"
"Trafficway"	""	""	""	""	""	""	""	"Trfy"
"Trail"	""	"Trails"	""	"Trls"	""	""	""	"Trl"
"Trailer"	""	""	"Trlrs"	""	""	""	""	"Trlr"
"Tunnel"	"Tunel"	""	"Tunls"	""	"Tunnels"	"Tunnl"	""	"Tunl"
"Turnpike"	"Trnpk"	""	"Turnpk"	""	""	""	""	"Tpke"
"Underpass"	""	""	""	""	""	""	""	"Upas"
"Union"	""	""	""	""	""	""	""	"Un"
"Unions"	""	""	""	""	""	""	""	"Uns"
"Valley"	""	"Vally"	"Vlly"	""	""	""	""	"Vly"
"Valleys"	""	""	""	""	""	""	""	"Vlys"
"Viaduct"	"Vdct"	""	"Viadct"	""	""	""	""	"Via"
"View"	""	""	""	""	""	""	""	"Vw"
"Views"	""	""	""	""	""	""	""	"Vws"
"Village"	"Vill"	"Villag"	""	"Villg"	"Villiage"	""	""	"Vlg"
"Villages"	""	""	""	""	""	""	""	"Vlgs"
"Ville"	""	""	""	""	""	""	""	"Vl"
"Vista"	""	"Vist"	""	"Vst"	"Vsta"	""	""	"Vis"
"Walk"	""	""	""	""	""	""	""	"Walk"
"Walks"	""	""	""	""	""	""	""	"Walk"
"Wall"	""	""	""	""	""	""	""	"Wall"
"Way"	"Wy"	""	""	""	""	""	""	"Way"
"Ways"	""	""	""	""	""	""	""	"Ways"
"Well"	""	""	""	""	""	""	""	"Wl"
"Wells"	""	""	""	""	""	""	""	"Wls"
// Also cardinal points (not in the USPS's list)
 "North" ""	""	""	""	""	""	"" "N" 
 "South" ""	""	""	""	""	""	"" "S"
 "East" ""	""	""	""	""	""	"" "E"
 "West" ""	""	""	""	""	""	"" "W"
 "Northeast" ""	""	""	""	""	""	"" "NE"
 "Northwest" ""	""	""	""	""	""	"" "NW"
 "Southeast" ""	""	""	""	""	""	"" "SE"
 "Southwest" ""	""	""	""	""	""	"" "SW"
 // Also common numerals (not in the USPS's list)
 // Because spelled out numerals will be replaced with "abbreviations", abrv0 is the "abbreviation" (e.g. 1st)
 "1st" ""	""	""	""	""	""	"" "First"
 "2nd" ""	""	""	""	""	""	"" "Second"
 "3rd" ""	""	""	""	""	""	"" "Third"
 "4th" ""	""	""	""	""	""	"" "Fourth"
 "5th" ""	""	""	""	""	""	"" "Fifth"
 "6th" ""	""	""	""	""	""	"" "Sixth"
 "7th" ""	""	""	""	""	""	"" "Seventh"
 "8th" ""	""	""	""	""	""	"" "Eighth"
 "9th" ""	""	""	""	""	""	"" "Ninth"
 "10th" ""	""	""	""	""	""	"" "Tenth"
end

// Drop if any abbreviation is equal to the entire word or a previous abbreviation
forvalues 1st_num = 0/5 {
	local next_num = `1st_num' + 1
	forvalues 2nd_num = `next_num'/6 {
		replace abrv`2nd_num' = "" if abrv`2nd_num' == abrv`1st_num' & abrv`1st_num' != ""
	}
}

// Move abbreviations to the left if any cell is empty
forvalues m = 1/3 { //loop must be repeated to complete procedure
	forvalues n = 2/7 {
		local nextn = `n' + 1
		replace abrv`n' = abrv`nextn' if abrv`n' ==""
		replace abrv`nextn' = "" if abrv`n' == abrv`nextn'
	}
}

// Drop empty variables
tab abrv7
drop abrv7 abrv8

// Add abbreviations or types found in the datasets that are not here
// Fix Springs, Lane, and Extension
replace abrv4 = "Spr" if inlist(abrv0, "Spring")
replace abrv2 = "La" if abrv0 == "Lane"
replace abrv4 = "Exn" if abrv0 == "Extension"
// Add Beltway
set obs 225
replace abrv0 = "Beltway" if abrv0 == ""
replace abrv1 = "Bltwy" if abrv0 == "Beltway"
// Add Private
set obs 226
replace abrv0 = "Private" if abrv0 == ""
replace abrv1 = "Pvt" if abrv0 == "Private"
// Add Building
set obs 227
replace abrv0 = "Building" if abrv0 == ""
replace abrv1 = "Bldg" if abrv0 == "Building"
replace abrv2 = "Bldng" if abrv0 == "Building"
// Add Extended
set obs 228
replace abrv0 = "Extended" if abrv0 == ""
replace abrv1 = "Exd" if abrv0 == "Extended"
// Add Alternative
set obs 229
replace abrv0 = "Alternative" if abrv0 == ""
replace abrv1 = "Alt" if abrv0 == "Alternative"

// Sort after all additions
sort abrv0 

// Check if any full or std abbreviations are repeated
list abrv0 if abrv0 == abrv0[_n+1] //None repeated
sort abrv1
list abrv0 abrv1 if abrv1 == abrv1[_n+1] ///
	| abrv1 == abrv1[_n-1] // Some repeated

/*
// UNUSED OLD CODE
// Change standard abbreviations repeated to a different one so that std abbreviations are unique identifiers
replace abrv1 = abrv0 if inlist(abrv0, "Parks", "Parkways", "Spurs", "Walks")
replace abrv2 = "Park" if abrv0 == "Parks"
replace abrv3 = "Pkwy" if abrv0 == "Parkways"
replace abrv2 = "Spur" if abrv0 == "Spurs"
replace abrv2 = "Walk" if abrv0 == "Walks"
*/
// Generate a variable that identifies abbreviation type
gen abbreviation_type = "street suffix"
replace abbreviation_type = "cardinal point" if inlist(abrv1, "N", "S", "E", "W", "NE", "NW", "SE", "SW")
replace abbreviation_type = "numeral" if inlist(abrv0, "1st", "2nd", "3rd", "4th", "5th")
replace abbreviation_type = "numeral" if inlist(abrv0, "6th", "7th", "8th", "9th", "10th")
replace abbreviation_type = "2nd suffix" if inlist(abrv0, "Extended", "Extension", "Extensions", "Private", "Alternative" )

// Make everything uppercase to avoid mismatches
 foreach var_name of varlist abrv0-abrv1 {
 	replace `var_name' = upper(`var_name')
 }
// Resort
sort abbreviation_type abrv0

// Some abbreviations are used for more than one unabbreviated word (E.g. PARK can abbreviate PARK or PARKS)
	// because we need unique identifiers, we will always convert to the more common one 
	// (e.g. PARKS will be converted to PARK). This also requires that the non-abbreviated uncommon words
	// be treated as abbreviated of the more common one (e.g. PARKS be treated as abbreviation of PARK)

// Check which are duplicated
// First generate identifier of the duplicates
gen dupl0 = 0
forvalues num_search = 0/5 {
	local next_num = `num_search' + 1
	forvalues num_result  = `next_num'/6 {
		levelsof abrv`num_result', local(column)
		gen dupl`num_search'_`num_result' = ""
		foreach val in `column' {
			replace dupl0 = 1 if abrv`num_search' == "`val'" & "`val'" != "" ///
				//& abrv`num_search' != abrv`num_result'
			replace dupl`num_search'_`num_result' = "`val'" if abrv`num_search' ///
				== "`val'" & "`val'" != ""
		}
	}
}
// Report the duplicates and drop them
forvalues 1st_num = 0/5 {
	local next_num = `1st_num' + 1
	forvalues 2nd_num = `next_num'/6 {
		list dupl`1st_num'_`2nd_num' if dupl`1st_num'_`2nd_num' != ""
		drop dupl`1st_num'_`2nd_num'
	}
}
drop dupl0	

// Drop abbreviations are used for more than one unabbreviated word and move them to the more common one
// - Meadows
drop if abrv0 == "MEADOW"
replace abrv4 = "MEADOW" if abrv0 == "MEADOWS"
// - Parks
drop if abrv0 == "PARKS"
replace abrv3 = "PARKS" if abrv0 == "PARK"
// - Parkways
drop if abrv0 == "PARKWAYS"
replace abrv5 = "PKWYS" if abrv0 == "PARKWAY"
replace abrv6 = "PARKWAYS" if abrv0 == "PARKWAY"
// - Spurs 
drop if abrv0 == "SPURS"
replace abrv3 = "SPURS" if abrv0 == "SPUR"
// - Walks
drop if abrv0 == "WALKS"
replace abrv3 = "WALKS" if abrv0 == "WALK"

// Fill in the empty cells with a word and number that will not match anything.
	// This is needed so that each cell is a unique identifier when trying to do a match
gen row_num = string(_n)
forvalues var_num = 1/6 {
	replace abrv`var_num' = "empty abrv `var_num' " + row_num if abrv`var_num' == ""
}
drop row_num	 	

// Order Abrev 1
order abrv1, before(abrv2)	
save "street_abbreviations.dta", replace

// Export, but first update the directory to the Excel one
cd "$excel_directory"
export excel "`excel_filename'", ///
	firstrow(variables) sheet("street_abbreviations", replace) 


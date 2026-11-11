/*

build_simple_stacked_cleanfull.do 

*/

clear all
capture log close
set more off 


********************************************************************************

if c(username) == "bb779" { 
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "julienl" {
	global root "/Users/julienl/Dropbox/Projects/School construction"
}
else if inlist(c(username), "davidschonholzer", "dasc4929") {
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "jabef" {
	global root "C:\Users\jabef\Desktop\FU Job\Prof.Marcus\Python_Scraper\Oster_Methode\Reproduction\Biasi(2025)"
}


global prepdata 	"${root}/datasets"


********************************************************************************
***** 					BUILD STACKED DATASET							********
***** 	controls are districts which propose but not pass an election 	********
***** 		in t and do not pass anything between t-15 and t+10			********
********************************************************************************

use "$prepdata/analysis_dataset.dta", clear
qui levelsof year if pass == 1 & year >= 2000, local(Year)

local id_dataset = 1
qui foreach year of local Year {
	noisily disp "Year `year'"
	use "$prepdata/analysis_dataset.dta", clear
	local min = `year' - 5
	local max = `year' + 10
	keep if year >= `min' & year <= `max'
	
		
	* Spot treated units
	tempvar treat passe passbond
	gen `passbond' = passbond if year >= `min' & year <= `max'
	bysort leaid: egen `passe' = max(`passbond') // for controls, only consider years t+1 to t+10 to check for other passes
	gen `treat' = pass == 1 & year == `year'
	bysort leaid: egen treat = max(`treat')
	
	* Spot "clean" control units
	tempvar control 
	gen `control' = holdbond == 1 & pass == 0 & year == `year' & (`passe' == 0 | `passe' == .)
	bysort leaid: egen control = max(`control')

	* Keep only treated and "clean" controls 
	keep if treat == 1 | control == 1
	replace treat = 0 if treat == .
	drop control 
	
	
	gen cohort = `year'
	noisily count if treat == 1
	local T = r(N)
	noisily count if treat == 0
	local C = r(N)
	gen id_dataset = `id_dataset'
	if `T' > 0 & `C' > 0 save "$prepdata/`year'.dta", replace
	local maxyr = `year'
	local id_dataset = `id_dataset' + 1
}

use "$prepdata/analysis_dataset.dta", clear
qui levelsof year if pass == 1 & year >= 2000 & year < `maxyr', local(Year2)
use "$prepdata/`maxyr'.dta"
qui foreach yr of local Year2 {
	noisily disp "Appending year `yr'"
	append using "$prepdata/`yr'.dta"
	rm "$prepdata/`yr'.dta"
}
rm "$prepdata/`maxyr'.dta"

sort cohort leaid year
capt drop __*
save "$prepdata/stacked_cleanfull_data.dta", replace

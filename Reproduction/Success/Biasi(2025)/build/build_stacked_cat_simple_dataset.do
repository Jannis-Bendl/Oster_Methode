/*

build_stacked_cat_simple_dataset.do 

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
***** 		in t in the same category and do not pass anything 			********
***** 						between t+1 and t+10	 					********
********************************************************************************

use "$prepdata/analysis_dataset.dta", clear

preserve
keep leaid year fips subject subject grade scale_score test_enroll cap enroll
sort leaid year
tempfile test
save `test', replace
restore 


keep leaid year holdbond passbond enroll E* D* M*
duplicates drop

* Merge bond categories
merge 1:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
drop if _m == 2
drop _m

gen amount_pp = (amount / enroll) / 1000
winsor2 amount_pp, replace



* Get a sense of the variation
local categories landpurch class stem hvac infra safeall busvehicle athletic constrbuild // note: the latter is just for a robustness check for Ref 3

foreach cat of local categories {
	qui tab year if `cat' == 1 & year >= 2000
	disp "category is `cat'; nr years is `r(r)'"
}

duplicates drop

** all good; between 2000 and 2017, each category has at least one election per year.

tempfile categoryy
save `categoryy', replace

qui levelsof year if pass == 1 & year>= 2000, local(Year)
foreach cat of local categories {
	qui foreach year of local Year {
		noisily disp "Year `year'; category is `cat'"
		use `categoryy', clear

		local min = `year' - 5
		local max = `year' + 12
		keep if year >= `min' & year <= `max'
		
	
		* Spot treated units
		tempvar treat passe
		tempvar treat passe passbond
		gen `passbond' = passbond if year > `year' & year <= `max'
		bysort leaid: egen `passe' = max(`passbond') // for controls, only consider years t+1 to t+10 to check for other passes

		gen `treat' = pass == 1 & year == `year' &  `cat' == 1
		bysort leaid: egen treat = max(`treat')
		
		* Spot control units
		tempvar control 
		gen `control' = holdbond == 1 & pass == 0 & year == `year' & (`passe' == 0 | `passe' == .) &  `cat' == 1
		bysort leaid: egen control = max(`control')		
				
		keep if treat == 1 | control == 1
		drop control 

		gen cat = "`cat'"

		gen cohort = `year'
		noisily count if treat == 1
		local T = r(N)
		noisily count if treat == 0
		local C = r(N)
		
		merge 1:1 leaid year using "$prepdata/hpi.dta", keep(3) nogen
		sort leaid year
		merge 1:m leaid year using `test', keep(3) nogen
		sort leaid year
		if `T' > 0 & `C' > 0 save "$prepdata/`year'_`cat'.dta", replace
		local maxyr = `year'
		local lastcat = `cat'
	}
}



use "$prepdata/analysis_dataset.dta", clear
qui levelsof year if pass == 1 & year>= 2000 & year < `maxyr', local(Year2)
foreach cat of local categories {
	use "$prepdata/`maxyr'_`cat'.dta"
	qui foreach yr of local Year2 {
		noisily disp "Appending year `yr'"
		capt append using "$prepdata/`yr'_`cat'.dta"
		capt rm "$prepdata/`yr'_`cat.dta"
	}
	save "$prepdata/`cat'.dta", replace
	rm "$prepdata/`maxyr'_`cat'.dta"
}	


clear
set obs 1
gen leaid = .
foreach cat of local categories {
	append using "$prepdata/`cat'.dta"
	rm "$prepdata/`cat'.dta"
}

drop if leaid == .
sort cat cohort leaid year
save "$prepdata/stacked_cat_data_simple.dta", replace
	

/*

prepare_analysis_dataset.do 
		
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

*******************************************************************************
*** 				LOAD AND PREP TEST SCORE PANEL 						***
*******************************************************************************

//use "$prepdata/test_panel.dta", clear
use "$prepdata/test_panel_complete.dta", clear
keep leaid year subject grade scale_score enroll
ren enroll test_enroll
tempfile test
save `test'


*******************************************************************************
*** 			  LOAD BOND PANEL, FLAG WEIRD CASES						***
*******************************************************************************

use "$prepdata/merge_fin_bond.dta", clear


***************************************************************
*** 				CREATE TOT VARIABLES				***
***************************************************************


** Whether hold/pass bond in a year or not **
qui gen passbond=pass
qui replace passbond=0 if pass==.


*  hold bond variables 
gen holdbond = pass != .
bysort leaid: egen holdbond_ever = max(holdbond)

*** RD Variables ***

qui gen margin_d=(margin>=0 & margin<.)
qui gen margin_ds=margin*margin_d

qui gen margin_2=margin^2
qui gen margin_ds2=margin_ds^2

qui gen margin_3=margin^3
qui gen margin_ds3=margin_ds^3

** Leads and lags of margin dummy, margin share cubic polyn, and dummies for having an election
rename fy year
tsset leaid year

forvalues n = 0/27 {
	qui gen D`n' = l`n'.margin_d
	qui gen El`n' = l`n'.holdbond
	
	qui gen Ml`n' = l`n'.margin
	qui gen Mld`n' = l`n'.margin * D`n'
	qui gen M2l`n' = l`n'.margin_2 
	qui gen M2ld`n' = l`n'.margin_2 * D`n'
	qui gen M3l`n' = l`n'.margin_3
	qui gen M3ld`n' = l`n'.margin_3 * D`n'
	
	qui replace D`n' = 0 if D`n' == . 
	qui replace El`n' = 0 if El`n' == .
	
	qui replace Ml`n' = 0 if  Ml`n' == .
	qui replace Mld`n' = 0 if  Mld`n' == .
	qui replace M2l`n' = 0 if M2l`n'== .
	qui replace M2ld`n' = 0 if M2ld`n'== .
	qui replace M3l`n' = 0 if M3l`n'== .	
	qui replace M3ld`n' = 0 if M3ld`n'== .
	
}




forvalues n = 1/27 {
	qui gen D_`n' = f`n'.margin_d
	qui gen Ef`n' = f`n'.holdbond
	
	qui gen Mf`n' = f`n'.margin
	qui gen Mfd`n' = f`n'.margin * D_`n'
	qui gen M2f`n' = f`n'.margin_2
	qui gen M2fd`n' = f`n'.margin_2 * D_`n'
	qui gen M3f`n' = f`n'.margin_3	
	qui gen M3fd`n' = f`n'.margin_3 * D_`n'
	
	qui replace D_`n' = 0 if D_`n' == .
	qui replace Ef`n' = 0 if Ef`n' == .
	
	qui replace Mf`n' = 0 if  Mf`n' == .
	qui replace Mfd`n' = 0 if  Mfd`n' == .
	qui replace M2f`n' = 0 if M2f`n'== .
	qui replace M2fd`n' = 0 if M2fd`n'== .
	qui replace M3f`n' = 0 if M3f`n'== .
	qui replace M3fd`n' = 0 if M3fd`n'== .	
}


*** Sample restrictions
gen mainsamp=1

** Total expenditure reasonable? ** 
replace mainsamp=0 if exptrim==0


** Total enrollment **
// already only have enrollment >100 -- restrict to 250 / yr 
su v33, d
bys leaid: egen minv33=min(v33)
su v33 if minv33<250,d
replace mainsamp=0 if minv33<250
drop minv33

su mainsamp [aw=v33] // 85% of districts, 99% of stu-yrs 

*** Misc: ****
ren v33 enroll

* Dependent variables for regressions:
gen noncap=te_pp_r-cap_pp_r
ren cap_pp_r cap


*** Drop some things to speed up ***

drop stabbr amount votesharereqd debtlimit supermajority pctyes
*drop logm*
drop pop_n pov_n elecid
drop hasbond*
drop *trim
drop genelec salestax failedinclude has_leaid haspct sfmoratorium stype ssource ///
	 marginal flag_dy_dup disttype_1990 pov_lt_185 smallenroll elemdist secdist

	 
compress



***************************************************************
*** 			MERGE TO TEST SCORE PANEL				***
***************************************************************

merge 1:m leaid year using `test'
drop if _merge==2
drop _merge



compress
sort leaid year
save "$prepdata/analysis_dataset.dta", replace





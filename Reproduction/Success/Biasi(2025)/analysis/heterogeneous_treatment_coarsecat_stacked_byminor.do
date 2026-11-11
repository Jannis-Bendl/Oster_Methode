/*

heterogeneous_treatment_coarsecat_stacked_byminor.do
*/


clear all
capture log close
set more off 

* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global ylight = "217 233 242" 
global yg = "94 112 45"
global graph = "xlabel(,grid glp(dot) glc(gs10) tlc(gs10)) ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"
global graphbar = "ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"




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
global outdir 	"${root}/figures"
global tables 	"${root}/tables"


********************************************************************************
***** 			1.0 LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************


** save dataset with SES
use "$prepdata/dist_enroll_demo.dta", clear
tsset leaid fy
replace sh_dy_econdis = sh_dy_econdis/10 if sh_dy_econdis > 10 & sh_dy_econdis != .
replace sh_dy_econdis = 1 if sh_dy_econdis > 1 & l.sh_dy_econdis > 0.7 & sh_dy_econdis != .
replace sh_dy_econdis = . if sh_dy_econdis > 1 & l.sh_dy_econdis < 0.7 & sh_dy_econdis != .
sort leaid fy
tempfile demo
save `demo', replace
tempvar lowsesT lowsesB minorT minorB

gen `lowsesT' = 0 if sh_dy_econdis != . & fy == 1995
gen `lowsesB' = 0 if sh_dy_econdis != . & fy == 1995

gen share_minor = sh_dy_hisp + sh_dy_black
gen `minorT' = 0 if share_minor != . & fy == 1995
gen `minorB' = 0 if share_minor != . & fy == 1995

_pctile sh_dy_econdis if fy == 1995, n(100)
replace `lowsesT' = sh_dy_econdis >= r(r67) if sh_dy_econdis != . & fy == 1995
replace `lowsesB' = sh_dy_econdis <= r(r33) if sh_dy_econdis != . & fy == 1995

_pctile share_minor if fy == 1995, n(100)
replace `minorT' = share_minor >= r(r67) if share_minor != . & fy == 1995
replace `minorB' = share_minor <= r(r33) if share_minor != . & fy == 1995

foreach var in lowsesT lowsesB minorT minorB {
	bysort leaid: egen `var' = max(``var'')
}

keep leaid fy minor* lowses*

rename fy year
sort leaid year
tempfile temp
save `temp', replace

use "$prepdata/analysis_dataset.dta", clear
capt drop __*
sort leaid year
merge m:1 leaid year using `temp'
drop if _m == 2
drop _m
tempfile data
save `data', replace




** save dataset to be used to store coefficients
clear
set obs 1
gen categ = ""
save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace


** loop across categories

qui local categories landpurch class stem hvac infra safeall busvehicle athletic 
qui foreach cat of local categories {
	noisily disp "category = `cat'"
	use `data', clear
	keep if fips != 29 & fips != 53 & fips != 40 
	keep leaid year margin margin_d holdbond minorT minorB
	duplicates drop

	* Merge bond categories
	merge m:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
	drop if _m == 2
	drop _m

	// gen cat = `cat' == 1
	tsset leaid year
	global Dk = ""
	global Ek = ""
	global Mk = ""
	forvalues n = 0/22 {
		qui gen Dk`n' = l`n'.margin_d * l`n'.cat
		qui gen Ek`n' = l`n'.holdbond * l`n'.cat
		qui gen Mk`n' = l`n'.margin * l`n'.cat
		qui replace Dk`n' = 0 if Dk`n' == .
		qui replace Ek`n' = 0 if Ek`n' == .
		qui replace Mk`n' = 0 if Mk`n' == .
		global Dk = "$Dk Dk`n'"
		global Ek = "$Ek Ek`n'"
		global Mk = "$Mk Mk`n'"
	}
	
	local z = 1
		qui gen Dk_`z' = f`z'.margin_d * f`z'.cat
		qui gen Ek_`z' = f`z'.holdbond * f`z'.cat
		qui gen Mk_`z' = f`z'.margin * f`z'.cat
		qui replace Dk_`z' = 0 if Dk_`z' == .
		qui replace Ek_`z' = 0 if Ek_`z' == .
		qui replace Mk_`z' = 0 if Mk_`z' == .
	
	forvalues n = 22(-1)2 {
		qui gen Dk_`n' = f`n'.margin_d * f`n'.cat
		qui gen Ek_`n' = f`n'.holdbond * f`n'.cat
		qui gen Mk_`n' = f`n'.margin * f`n'.cat
		qui replace Dk_`n' = 0 if Dk_`n' == .
		qui replace Ek_`n' = 0 if Ek_`n' == .
		qui replace Mk_`n' = 0 if Mk_`n' == .
		global Dk = "$Dk Dk_`n'"
		global Ek = "$Ek Ek_`n'"
		global Mk = "$Mk Mk_`n'"
		}
	drop cat
	drop holdbond margin*
	sort leaid year
	capt drop __*
	merge 1:m leaid year using "$prepdata/stacked_cat_data_simple.dta", gen(_m) keep(3)
	drop if _m == 2
	drop _m
	drop __*
	
	* Test scores, high minority
	noisily capt reghdfe scale_score $Dk $Mk $Ek if cat == "`cat'" & minorT == 1 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
	preserve
	capt lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: test coeff, low SES = `r(estimate)'"
	noisily disp "test se, low SES = `r(se)'"
	capt gen Lcoef_test_1_10 = `r(estimate)' in 1
	capt gen Lub_test_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	capt gen Llb_test_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	capt lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5
	noisily disp "SR: test coeff, low SES = `r(estimate)'"
	noisily disp "test se, low SES = `r(se)'"
	capt gen Lcoef_test_1_5 = `r(estimate)' in 1
	capt gen Lub_test_1_5  = `r(estimate)' + 1.65 * `r(se)' in 1 
	capt gen Llb_test_1_5  = `r(estimate)' - 1.65 * `r(se)' in 1 
	capt lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: test coeff, low SES = `r(estimate)'"
	noisily disp "test se, low SES = `r(se)'"
	capt gen Lcoef_test_6_10 = `r(estimate)' in 1
	capt gen Lub_test_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	capt gen Llb_test_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	capt lincom (Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8)/6
	noisily disp "MR: teest coeff, low SES = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	capt gen Lcoef_test_3_8 = `r(estimate)' in 1
	capt gen Lub_test_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	capt gen Llb_test_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ Llb* Lub* Lcoef_test*
	drop if categ == ""
	append using "$prepdata/coarsecat_estimates_simple_byminor.dta"
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore
	
	* Test scores, low minority
	reghdfe scale_score $Dk $Mk $Ek if cat == "`cat'" & minorB == 1 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: test coeff, high SES = `r(estimate)'"
	noisily disp "test se, high SES = `r(se)'"
	gen Hcoef_test_1_10 = `r(estimate)' in 1
	gen Hub_test_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_test_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5
	noisily disp "SR: test coeff, high SES = `r(estimate)'"
	noisily disp "test se, high SES = `r(se)'"
	gen Hcoef_test_1_5 = `r(estimate)' in 1
	gen Hub_test_1_5  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_test_1_5  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: test coeff, high SES = `r(estimate)'"
	noisily disp "test se, high SES = `r(se)'"
	gen Hcoef_test_6_10 = `r(estimate)' in 1
	gen Hub_test_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_test_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8)/6
	noisily disp "MR: test coeff, high SES = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen Hcoef_test_3_8 = `r(estimate)' in 1
	gen Hub_test_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_test_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ Hlb* Hub* Hcoef_test*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_simple_byminor.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore
	
	keep if cat == "`cat'"
	keep  hpi cap  $Dk $Mk $Ek enroll leaid cohort fips year minorT minorB
	duplicates drop
	
	* Capital, high minority
	reghdfe cap  $Dk $Mk $Ek if minorT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)
	noisily disp "spending coeff, low SES = `r(estimate)'"
	noisily disp "spending se, low SES = `r(se)'"
	gen Lcoef_cap_1_5 = `r(estimate)' in 1
	gen Lub_cap_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Llb_cap_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	gen categ = "`cat'" in 1
	keep categ Llb* Lub* Lcoef*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_simple_byminor.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore	
	
	* Capital, low minority
	reghdfe cap  $Dk $Mk $Ek if minorB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)
	noisily disp "spending coeff, high SES = `r(estimate)'"
	noisily disp "spending se, high SES = `r(se)'"
	gen Hcoef_cap_1_5 = `r(estimate)' in 1
	gen Hub_cap_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_cap_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	gen categ = "`cat'" in 1
	keep categ Hlb* Hub* Hcoef*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_simple_byminor.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore
	
	
	* HPI, high minority
	reghdfe hpi $Dk $Mk $Ek if minorT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: test coeff, low SES = `r(estimate)'"
	noisily disp "test se, low SES = `r(se)'"
	gen Lcoef_hpi_1_10 = `r(estimate)' in 1
	gen Lub_hpi_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Llb_hpi_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5	
	noisily disp "SR: house coeff = `r(estimate)'"
	noisily disp "house se = `r(se)'"
	gen Lcoef_hpi_1_5 = `r(estimate)' in 1
	gen Lub_hpi_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Llb_hpi_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: house coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen Lcoef_hpi_6_10 = `r(estimate)' in 1
	gen Lub_hpi_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Llb_hpi_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8)/6
	noisily disp "MR: house coeff, low SES = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen Lcoef_hpi_3_8 = `r(estimate)' in 1
	gen Lub_hpi_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Llb_hpi_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ Llb* Lub* Lcoef_hpi*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_simple_byminor.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore
	
	* HPI, low minority
	reghdfe hpi $Dk $Mk $Ek if minorB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: house coeff, high SES = `r(estimate)'"
	noisily disp "test se, high SES = `r(se)'"
	gen Hcoef_hpi_1_10 = `r(estimate)' in 1
	gen Hub_hpi_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_hpi_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5	
	noisily disp "SR: house coeff = `r(estimate)'"
	noisily disp "house se = `r(se)'"
	gen Hcoef_hpi_1_5 = `r(estimate)' in 1
	gen Hub_hpi_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_hpi_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: house coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen Hcoef_hpi_6_10 = `r(estimate)' in 1
	gen Hub_hpi_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_hpi_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8)/6
	noisily disp "MR: house coeff, high SES = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen Hcoef_hpi_3_8 = `r(estimate)' in 1
	gen Hub_hpi_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen Hlb_hpi_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ Hlb* Hub* Hcoef_hpi*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_simple_byminor.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_simple_byminor.dta", replace
	restore
}



***** Build figure w/effects
use "$prepdata/coarsecat_estimates_simple_byminor.dta", clear
* Drop transportation

drop if categ == "busvehicle"


*** Bar charts

gen n = 1 if categ == "hvac"
replace n = 2 if categ == "stem"
replace n = 3 if categ == "safeall"
replace n = 4 if categ == "infra"
replace n = 5 if categ == "class"
replace n = 6 if categ == "athletic"
replace n = 7 if categ == "landpurch"

gen n1 = n - 0.2
gen n2 = n + 0.2


gen cat1 = n - 0.3
gen cat2a = n - 0.2
gen cat2 = n - 0.1
gen cat3 = n + 0.1
gen cat3a = n + 0.2
gen cat4 = n + 0.3

*---> Mean, test scores, high vs low SES

twoway	(bar Lcoef_test_3_8 cat1, barwidth(0.2)  color(none)) (bar Lcoef_test_3_8 cat1, barwidth(0.2)  color("$yo")) (rcap Lub_test_3_8 	Llb_test_3_8 cat1,  color("$yaleblue % 50"))  ///
	(bar Hcoef_test_3_8 cat2, barwidth(0.2)  color("$yo % 60") ) (rcap Hub_test_3_8 Hlb_test_3_8 cat2,  color("$yaleblue % 50"))  ///
 	 (bar Lcoef_hpi_3_8 cat3, barwidth(0.2) yaxis(2) color("$ylb")) (rcap Lub_hpi_3_8 	Llb_hpi_3_8 cat3, yaxis(2) color("$ylb % 50"))  ///
		 (bar Hcoef_hpi_3_8 cat4, barwidth(0.2) yaxis(2) color("$ylb % 60") ) (rcap Hub_hpi_1_10 Hlb_hpi_3_8 cat4, yaxis(2) color("$yaleblue % 50"))  ///
, xlabel(1 "HVAC"  4 "Plumbing, roofs, furnaces" 3 "Safety/health" 2 "STEM" 5 "Classrooms"  6 "Athletics" 7 "Land purchases", angle(45) labsize(small)) ///
		ylabel(-0.6(0.2)0.6) ylabel(-60(20)60, axis(2)) legend(ring(0) pos(6) row(2) order(2 "Test score, high share minority" 4 "Test score, low share minority" 6 "House prices, high share minority" 8 "House prices, low share minority")) xtitle(" ") ///
		 ytitle("Effect on test scores", color("$yo")) ytitle("Effect on house prices", color("$ylb") axis(2))
graph export "$outdir/testeffects_cat_stacked_minor_simple.png", replace

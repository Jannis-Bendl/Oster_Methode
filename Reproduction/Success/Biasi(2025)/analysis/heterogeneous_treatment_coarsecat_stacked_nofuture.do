/*

heterogeneous_treatment_coarsecat_stacked.do 

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
global outdir 	"${root}/figures"
global tables 	"${root}/tables"


* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global ylight = "217 233 242" 
global yg = "94 112 45"
global graph = "xlabel(,grid glp(dot) glc(gs10) tlc(gs10)) ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"
global graphbar = "ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"



********************************************************************************
***** 			1.0 LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************


** save dataset to be used to store coefficients
clear
set obs 1
gen categ = ""
save "$prepdata/coarsecat_estimates_nofuture.dta", replace


** loop across categories

qui local categories landpurch class stem hvac infra safeall busvehicle athletic 
qui foreach cat of local categories {
	noisily disp "category = `cat'"
	use "$prepdata/analysis_dataset.dta", clear
	keep if fips != 29 & fips != 53 & fips != 40 
	keep leaid year margin margin_d holdbond
	duplicates drop

	* Merge bond categories
	merge m:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
	drop if _m == 2
	drop _m

	gen cat = `cat' == 1
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
	/*
	local z = 0
		qui gen Dk`z' = margin_d * cat
		qui gen Ek`z' = holdbond * cat
		qui gen Mk`z' = margin * cat
		qui replace Dk`z' = 0 if Dk`z' == .
		qui replace Ek`z' = 0 if Ek`z' == .
		qui replace Mk`z' = 0 if Mk`z' == .
	*/
	forvalues n = 22(-1)2 {
		qui gen Dk_`n' = f`n'.margin_d * f`n'.cat
		qui gen Ek_`n' = f`n'.holdbond * f`n'.cat
		qui gen Mk_`n' = f`n'.margin * f`n'.cat
		qui replace Dk_`n' = 0 if Dk_`n' == .
		qui replace Ek_`n' = 0 if Ek_`n' == .
		qui replace Mk_`n' = 0 if Mk_`n' == .
		global Dk = "$Dk Dk_`n'"
		// global Ek = "$Ek Ek_`n'"
		// global Mk = "$Mk Mk_`n'"
		}
	drop cat
	drop holdbond margin*
	sort leaid year
	capt drop __*
	merge 1:m leaid year using "$prepdata/stacked_cat_data_simple.dta", gen(_m) keep(3)
	drop if _m == 2
	drop _m
	drop __*
	noisily reghdfe scale_score $Dk $Mk $Ek if cat == "`cat'" [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
	
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: test coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen coef_test_1_10 = `r(estimate)' in 1
	gen ub_test_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5
	noisily disp "SR: test coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen coef_test_1_5 = `r(estimate)' in 1
	gen ub_test_1_5  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_1_5  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: test coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen coef_test_6_10 = `r(estimate)' in 1
	gen ub_test_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5 + Dk6 )/4
	noisily disp "MR: test coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen coef_test_3_8 = `r(estimate)' in 1
	gen ub_test_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	*3-year coefficients
	lincom (Dk_5 + Dk_4)/2
	gen coef_test_pre_5_4 = `r(estimate)' in 1
	gen ub_test_pre_5_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_pre_5_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk_3  + Dk_2)/2
	gen coef_test_pre_3_2 = `r(estimate)' in 1
	gen ub_test_pre_3_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_pre_3_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk0 + Dk1 + Dk2)/3
	gen coef_test_0_2 = `r(estimate)' in 1
	gen ub_test_0_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_0_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5)/3
	gen coef_test_3_5 = `r(estimate)' in 1
	gen ub_test_3_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_3_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8)/3
	gen coef_test_6_8 = `r(estimate)' in 1
	gen ub_test_6_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_6_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_test_9_10 = `r(estimate)' in 1
	gen ub_test_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef_test*
	drop if categ == ""
	append using "$prepdata/coarsecat_estimates_nofuture.dta"
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_nofuture.dta", replace
	restore
	
	keep if cat == "`cat'"
	keep  hpi cap  $Dk $Mk $Ek enroll leaid cohort fips year
	duplicates drop
	reghdfe cap  $Dk $Mk $Ek [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	
	preserve
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)
	noisily disp "spending coeff = `r(estimate)'"
	noisily disp "spending se = `r(se)'"
	gen coef_cap_1_5 = `r(estimate)' in 1
	gen ub_cap_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	
	*3-year coefficients
	lincom (Dk_5 + Dk_4)/2
	gen coef_cap_pre_5_4 = `r(estimate)' in 1
	gen ub_cap_pre_5_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_pre_5_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk_3  + Dk_2)/2
	gen coef_cap_pre_3_2 = `r(estimate)' in 1
	gen ub_cap_pre_3_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_pre_3_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk0 + Dk1 + Dk2)/3
	gen coef_cap_0_2 = `r(estimate)' in 1
	gen ub_cap_0_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_0_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5)/3
	gen coef_cap_3_5 = `r(estimate)' in 1
	gen ub_cap_3_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_3_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8)/3
	gen coef_cap_6_8 = `r(estimate)' in 1
	gen ub_cap_6_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_6_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_cap_9_10 = `r(estimate)' in 1
	gen ub_cap_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_nofuture.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_nofuture.dta", replace
	restore
	
	noisily reghdfe hpi $Dk $Mk $Ek [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5 + Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/10
	noisily disp "MEAN: test coeff = `r(estimate)'"
	noisily disp "test se = `r(se)'"
	gen coef_hpi_1_10 = `r(estimate)' in 1
	gen ub_hpi_1_10  = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_1_10  = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk1 + Dk2 + Dk3 + Dk4 + Dk5)/5	
	noisily disp "SR: house coeff = `r(estimate)'"
	noisily disp "house se = `r(se)'"
	gen coef_hpi_1_5 = `r(estimate)' in 1
	gen ub_hpi_1_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_1_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8 + Dk9 + Dk10)/5
	noisily disp "LR: house coeff = `r(estimate)'"
	noisily disp "house se = `r(se)'"
	gen coef_hpi_6_10 = `r(estimate)' in 1
	gen ub_hpi_6_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_6_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5 + Dk6 )/4
	noisily disp "MR: house coeff = `r(estimate)'"
	noisily disp "house se = `r(se)'"
	gen coef_hpi_3_8 = `r(estimate)' in 1
	gen ub_hpi_3_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_3_8 = `r(estimate)' - 1.65 * `r(se)' in 1 

	*3-year coefficients
	lincom (Dk_5 + Dk_4)/2
	gen coef_hpi_pre_5_4 = `r(estimate)' in 1
	gen ub_hpi_pre_5_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_pre_5_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk_3  + Dk_2)/2
	gen coef_hpi_pre_3_2 = `r(estimate)' in 1
	gen ub_hpi_pre_3_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_pre_3_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk0 + Dk1 + Dk2)/3
	gen coef_hpi_0_2 = `r(estimate)' in 1
	gen ub_hpi_0_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_0_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4 + Dk5)/3
	gen coef_hpi_3_5 = `r(estimate)' in 1
	gen ub_hpi_3_5 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_3_5 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk6 + Dk7 + Dk8)/3
	gen coef_hpi_6_8 = `r(estimate)' in 1
	gen ub_hpi_6_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_6_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_hpi_9_10 = `r(estimate)' in 1
	gen ub_hpi_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef_hpi*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_nofuture.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_nofuture.dta", replace
}


***** Build figures

use "$prepdata/coarsecat_estimates_nofuture.dta", clear


*** Bar charts

gen n = 1 if categ == "hvac"
replace n = 2 if categ == "stem"
replace n = 3 if categ == "safeall"
replace n = 4 if categ == "infra"
replace n = 5 if categ == "class"
replace n = 6 if categ == "athletic"
replace n = 7 if categ == "busvehicle"
replace n = 8 if categ == "landpurch"

gen n1 = n - 0.2
gen n2 = n + 0.2


twoway	(bar coef_test_3_8 n, barwidth(0.4)  color(none)) (bar coef_test_3_8 n1, barwidth(0.4)  color("$yo")) (rcap ub_test_3_8 lb_test_3_8 n1,  color("$yaleblue % 50"))  ///
		 (bar coef_hpi_3_8 n2, barwidth(0.4)  color("$ylb") yaxis(2)) (rcap ub_hpi_3_8 lb_hpi_3_8 n2,  color("$yaleblue % 50") yaxis(2))  ///
		,  xlabel(1 "HVAC" 2 "Safety/health" 3 "STEM equipment" 4 "Plumbing, roofs, furnaces"  5 "Classrooms" 6 "Athletics"  7 "Transportation" 8 "Land purchases", angle(45) labsize(small))  ///
		ylabel(-0.3(0.1)0.6) ylabel(-30(10)60, axis(2)) legend(ring(0) pos(11.5) order(2 "Test scores" 4 "House price index")) xtitle(" ") ///
		ytitle("Effect on test scores (sd)") ytitle("Effect on house price index (%)", axis(2))
graph export "$outdir/effects_cat_stacked_nofuture.png", replace

	




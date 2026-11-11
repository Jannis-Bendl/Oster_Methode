/*
iv_noapportion_hpi.do 

*/


clear 
program drop _all
capture log close
set more off 

set seed 12345

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



** Select right stacked dataset

global dataset = "$prepdata/stacked_cat_data_simple.dta"
use "$dataset", clear

** Useful globals
global D_lag = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 D_1 "
global D_lead = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"

* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25

** REDEFINE WEIGHTS
capt drop __*
tempvar y w1 w2
bysort leaid: egen `y' = min(year)
replace `y' = 2000 if `y' < 2000
bysort leaid: gen `w1' = test_enroll if year == `y'
bysort leaid: gen `w2' = enroll if year == `y'
drop enroll test_enroll
bysort leaid: egen test_enroll = max(`w1')
bysort leaid: egen enroll = max(`w2')
capt drop __*
tempfile data
save `data', replace
keep leaid year enroll cap cat cohort fips
duplicates drop
sort leaid year
tempfile data1
save `data1'



********************************************************************************
***** 					Estimate category-by-category  	 		 ***************
********************************************************************************


** save dataset to be used to store coehpi_noapportionfficients
clear
set obs 1
gen categ = ""
save "$prepdata/iv_bycat_hpi_noapportion.dta", replace



** loop across categories

qui local categories landpurch class stem hvac infra safeall busvehicle athletic 
qui foreach cat of local categories {
	noisily disp "category = `cat'"
	use "$prepdata/analysis_dataset.dta", clear
	keep if fips != 29 & fips != 53 & fips != 40 
	keep leaid year margin margin_d holdbond enroll
	duplicates drop

	* Merge bond categories
	merge m:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
	drop if _m == 2
	drop _m
	
	gen amount_pp = (amount / enroll)

	* winsorize amount_pp at top 1% and 99%
	winsor2 amount_pp, replace

	replace amount_pp = (amount_pp / 1000)

	egen nrcat = rowtotal(landpurch class stem hvac infra safeall busvehicle athletic )

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
	merge 1:m leaid year using `data', nogen keep(3)
	

	capt drop __*
	
	drop scale_score test_enroll subject grade
	duplicates drop
	
	sort leaid year
	merge m:1  leaid year using "$prepdata/hpi.dta", nogen keep(1 3)
		
	
		
	*---------> Estimate first stage
	preserve
	capt drop scale_score test_enroll subject grade
	duplicates drop
	capt drop _est*

	replace amount_pp = 0 if pass == 0 | holdbond == 0

	reghdfe amount_pp $Dk $Mk $Ek  if cat == "`cat'" [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
	noisily lincom Dk1 + Dk2 + Dk3 + Dk4 + Dk5 
	predict caph

	//rename amount_pp caph

	*---------> Cumulate predictions
	keep leaid year cohort caph
	duplicates drop
	egen id = group(leaid cohort)
	tsset id year

	gen Lcap = l.caph
	forvalues n = 2/10 {
		gen L`n'cap = l`n'.caph
	}

	egen cap_1_5 = rowtotal(Lcap L2cap L3cap L4cap L5cap)
	egen cap_2_5 = rowtotal(L2cap L3cap L4cap L5cap)
	egen cap_3_6 = rowtotal(L3cap L4cap L5cap L6cap)
	egen cap_4_7 = rowtotal(L4cap L5cap L6cap L7cap)
	egen cap_5_8 = rowtotal(L5cap L6cap L7cap L8cap)
	egen cap_6_10 = rowtotal(L6cap L7cap L8cap L9cap L10cap)
	egen cap_1_10 = rowtotal(Lcap L2cap L3cap L4cap L5cap L6cap L7cap L8cap L9cap L10cap)

	drop id
	keep leaid cohort year cap_*
	tempfile temp
	save `temp', replace
	restore

	sort leaid year cohort
	merge m:1 leaid cohort year using `temp'

	* APPORTION:
	
	* choose var:
	local var = "cap_1_10"
	

	reghdfe hpi `var' $M_lag $M_lead $E_lag $E_lead if cat == "`cat'"  [aw = enroll], a(leaid#cohort fips#year#cohort)  cl(leaid)
	noisily disp _b[`var']
	noisily disp _b[`var']/_se[`var']

	clear
	set obs 1
	gen coef_hpi = _b[`var'] in 1
	gen ub_hpi  = _b[`var'] + 1.65 * _se[`var'] in 1 
	gen lb_hpi  = _b[`var'] - 1.65 * _se[`var'] in 1
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef_hpi*
	drop if categ == ""
	append using "$prepdata/iv_bycat_hpi_noapportion.dta"
	drop if categ == ""
	save "$prepdata/iv_bycat_hpi_noapportion.dta", replace
}



** Plot figure

use "$prepdata/iv_bycat_hpi_noapportion.dta", clear
sort categ
merge 1:1 categ using "$prepdata/iv_bycat_noapportion.dta", nogen


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

foreach type in test hpi {
	foreach var in coef ub lb {
		replace `var'_`type' = `var'_`type' * 2.8
	
}
}
twoway	(bar coef_test n, barwidth(0.4)  color(none)) (bar coef_test n1, barwidth(0.4)  color("$yo")) (rcap ub_test lb_test n1,  color("$yaleblue % 50"))  ///
		 (bar coef_hpi n2, barwidth(0.4)  color("$ylb") yaxis(2)) (rcap ub_hpi lb_hpi n2,  color("$yaleblue % 50") yaxis(2))  ///
		,  xlabel(1 "HVAC" 2 "STEM" 3 "Safety/health"  4 "Plumbing, roofs, furnaces"  5 "Classrooms" 6 "Athletics"  7 "Transportation" 8 "Land purchases", angle(45) labsize(small))  ///
		ylabel(-0.1(0.05)0.15) ylabel(-5(2.5)7.5, axis(2)) legend(ring(0) pos(6) order(2 "Test scores" 4 "House price index")) xtitle(" ") ///
		ytitle("Effect on test scores (sd)") ytitle("Effect on house price index (%)", axis(2))
graph export "$outdir/effects_cat_2sls_noapp.png", replace


rm "$prepdata/iv_bycat_hpi_noapportion.dta"
rm "$prepdata/iv_bycat_noapportion.dta"

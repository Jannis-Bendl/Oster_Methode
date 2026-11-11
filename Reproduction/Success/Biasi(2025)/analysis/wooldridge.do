 /*

wooldridge.do 
	
*/



clear 
program drop _all
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


** Useful globals
global D_lag = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 D_1 "
global D_lead = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"



** Select panel dataset
use "$prepdata/analysis_dataset.dta", clear



	
* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25


** REDEFINE WEIGHTS
tempvar y w1 w2
bysort leaid (year): egen `y' = min(year)
replace `y' = 2000 if `y' < 2000
bysort leaid (year): gen `w1' = test_enroll if year == `y'
bysort leaid (year): gen `w2' = enroll if year == `y'
drop enroll test_enroll
bysort leaid: egen test_enroll = max(`w1')
bysort leaid: egen enroll = max(`w2')

** Generate one group of observations per district-election
collapse holdbond passbond cap enroll margin scale_score (sum) test_enroll [aw = test_enroll], by(leaid year)
duplicates drop
gen elecid = year if holdbond == 1
bysort leaid: gen elecind = sum(holdbond)

forvalues n = 1/22 {
	gen hold`n' = .
	gen pass`n' = .
	replace hold`n' = elecid if elecind == `n'
	tempvar x
	bysort leaid: egen `x' = max(hold`n')
	replace hold`n' = `x'
	replace pass`n' = hold`n' if elecind == `n' & passbond == 1
	tempvar x
	bysort leaid: egen `x' = max(pass`n')
	replace pass`n' = `x'
}


bysort leaid (year): egen nrelection = sum(holdbond)
expand nrelection, gen(event)
drop event elecid elecind
bysort leaid year: gen event = _n

gen hold_e = 0
gen pass_e = .
forvalues n = 1/22 {
	replace hold_e = 1 if event == `n' & hold`n' == year
	replace pass_e = 1 if event == `n' & pass`n' == year
}
replace pass_e = 0 if pass_e == . & hold_e == 1

tempvar holdy win
gen `holdy' = year if hold_e == 1
gen `win' = pass_e if hold_e == 1
bysort leaid event: egen cohort = max(`holdy')
bysort leaid event: egen win = max(`win')
gen treat = year > cohort


gen margin_d = margin > 0
replace margin_d = . if margin == .

replace cohort = 0 if cohort == .
egen idcohort = group(leaid cohort)
tsset idc year

** Generate lagged variables

global cohort_year = ""
forvalues n = 27(-1)1 {
	qui gen D_`n' = f`n'.margin_d
	qui gen Ef`n' = f`n'.holdbond
	qui gen Mf`n' = f`n'.margin
	
	qui replace D_`n' = 0 if D_`n' == .
	qui replace Ef`n' = 0 if Ef`n' == .
	qui replace Mf`n' = 0 if  Mf`n' == .
	global cohort_year = "$cohort_year i.cohort#c.D_`n'"
}

forvalues n = 0/27 {
	qui gen D`n' = l`n'.margin_d
	qui gen El`n' = l`n'.holdbond
	qui gen Ml`n' = l`n'.margin
	
	qui replace D`n' = 0 if D`n' == . // matters a lot for endpoints -- since unbalanced
	qui replace El`n' = 0 if El`n' == .
	qui replace Ml`n' = 0 if  Ml`n' == .
	if `n' != 0 global cohort_year = "$cohort_year i.cohort#c.D`n'"

}




** CAP SPENDING
qui reghdfe cap $M_lead $M_lag  $E_lead $E_lag $cohort_year [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

preserve
gen Timeto = _n - 6 if _n <= 16
gen cap_coef = .
gen cap_up = .
gen cap_down = .
forvalues n = 5(-1)1 {
	lincom ( _b[2001.cohort#c.D_`n'] + _b[2002.cohort#c.D_`n'] +  _b[2003.cohort#c.D_`n'] +  _b[2004.cohort#c.D_`n'] +  _b[2005.cohort#c.D_`n'] + ///
			 _b[2006.cohort#c.D_`n'] + _b[2007.cohort#c.D_`n'] +  _b[2008.cohort#c.D_`n'] +  _b[2009.cohort#c.D_`n'] +  _b[2010.cohort#c.D_`n'] +  ///
			 _b[2011.cohort#c.D_`n'] + _b[2012.cohort#c.D_`n'] +  _b[2013.cohort#c.D_`n'] +  _b[2014.cohort#c.D_`n'] +  _b[2015.cohort#c.D_`n'] + ///
			 _b[2016.cohort#c.D_`n'] + _b[2017.cohort#c.D_`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == -`n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == -`n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == -`n'
			
}
replace cap_coef = 0 if Timeto == 0
replace cap_up = 0 if Timeto == 0
replace cap_down = 0 if Timeto == 0

forvalues n = 1(1)10 {
	lincom ( _b[2001.cohort#c.D`n'] + _b[2002.cohort#c.D`n'] +  _b[2003.cohort#c.D`n'] +  _b[2004.cohort#c.D`n'] +  _b[2005.cohort#c.D`n'] + ///
			 _b[2006.cohort#c.D`n'] + _b[2007.cohort#c.D`n'] +  _b[2008.cohort#c.D`n'] +  _b[2009.cohort#c.D`n'] +  _b[2010.cohort#c.D`n'] +  ///
			 _b[2011.cohort#c.D`n'] + _b[2012.cohort#c.D`n'] +  _b[2013.cohort#c.D`n'] +  _b[2014.cohort#c.D`n'] +  _b[2015.cohort#c.D`n'] + ///
			 _b[2016.cohort#c.D`n'] + _b[2017.cohort#c.D`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == `n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == `n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == `n'
			
}


gen Ccap_coef = 0 if Timeto == 0
gen Ccap_up = 0 if Timeto == 0
gen Ccap_down = 0 if Timeto == 0


forvalues n = 1(1)10 {
	lincom ( _b[2001.cohort#c.D`n'] + _b[2002.cohort#c.D`n'] +  _b[2003.cohort#c.D`n'] +  _b[2004.cohort#c.D`n'] +  _b[2005.cohort#c.D`n'] + ///
			 _b[2006.cohort#c.D`n'] + _b[2007.cohort#c.D`n'] +  _b[2008.cohort#c.D`n'] +  _b[2009.cohort#c.D`n'] +  _b[2010.cohort#c.D`n'] +  ///
			 _b[2011.cohort#c.D`n'] + _b[2012.cohort#c.D`n'] +  _b[2013.cohort#c.D`n'] +  _b[2014.cohort#c.D`n'] +  _b[2015.cohort#c.D`n'] + ///
			 _b[2016.cohort#c.D`n'] + _b[2017.cohort#c.D`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == `n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == `n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == `n'
			
}

global COEF = "( _b[2001.cohort#c.D1] + _b[2002.cohort#c.D1] +  _b[2003.cohort#c.D1] +  _b[2004.cohort#c.D1] +  _b[2005.cohort#c.D1] +			 _b[2006.cohort#c.D1] + _b[2007.cohort#c.D1] +  _b[2008.cohort#c.D1] +  _b[2009.cohort#c.D1] +  _b[2010.cohort#c.D1] +  _b[2016.cohort#c.D1] + _b[2017.cohort#c.D1] ) / 17"

lincom ($COEF)
replace Ccap_coef = `r(estimate)' if Timeto == 1
replace Ccap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == 1
replace Ccap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == 1

forvalues n = 1(1)10 {
	global temp = " (_b[2001.cohort#c.D`n'] + _b[2002.cohort#c.D`n'] +  _b[2003.cohort#c.D`n'] +  _b[2004.cohort#c.D`n'] +  _b[2005.cohort#c.D`n'] + 			 _b[2006.cohort#c.D`n'] + _b[2007.cohort#c.D`n'] +  _b[2008.cohort#c.D`n'] +  _b[2009.cohort#c.D`n'] +  _b[2010.cohort#c.D`n'] +  _b[2011.cohort#c.D`n'] + _b[2016.cohort#c.D`n'] + _b[2017.cohort#c.D`n'] ) / 17"
	global COEF = "$COEF + $temp"
	lincom ($COEF)
	replace Ccap_coef = r(estimate) if Timeto == `n'
	replace Ccap_up = `r(estimate)' + 1.65 * `r(se)' if Timeto == `n'
	replace Ccap_down = `r(estimate)' - 1.65 * `r(se)' if Timeto == `n'
}

keep Timeto cap_* Ccap_*
drop if Timeto == .
sort Timeto
//save "$outdir/wooldridge_cap.dta", replace

twoway 	(connected cap_coef Time, mcolor("$ylb") lcolor("$ylb") lw(thick) lp(solid))  (rcap cap_up cap_down Time, lcolor("$ylb % 30")) ///
		(line Ccap_coef Time, lcolor("$yo") lw(thick) lp(solid) yaxis(2)) (rarea Ccap_up Ccap_down Time, color("$yo % 20") yaxis(2)) ///
		, xtitle("Time since bond passage") ytitle("Effect on capital spending ($)") ytitle("Cumulative effect on capital spending ($)", axis(2)) ///
		legend(ring(0) pos(11) order(1 "Effect per year" 3 "Cumulative effect")) xlabel(-5(1)10) xline(0.3, lcolor(red)) ylabel(-600(200)1000, axis(1)) ylabel(-1800(600)3000, axis(2)) xsize(7) yline(0, lcolor(gs10) lw(vthin)) xlabel(-5(1)10)
graph export "$outdir/cap_wooldridge.png", replace
restore




** TEST SCORES
qui reghdfe scale_score $M_lead $M_lag $E_lead $E_lag $cohort_year [aw = test_enroll], a(leaid#cohort cohort#year) cluster(leaid)

preserve
gen Timeto = _n - 6 if _n <= 16
gen cap_coef = .
gen cap_up = .
gen cap_down = .

forvalues n = 5(-1)1 {
	lincom ( _b[2001.cohort#c.D_`n'] + _b[2002.cohort#c.D_`n'] +  _b[2003.cohort#c.D_`n'] +  _b[2004.cohort#c.D_`n'] +  _b[2005.cohort#c.D_`n'] + ///
			 _b[2006.cohort#c.D_`n'] + _b[2007.cohort#c.D_`n'] +  _b[2008.cohort#c.D_`n'] +  _b[2009.cohort#c.D_`n'] +  _b[2010.cohort#c.D_`n'] +  ///
			 _b[2011.cohort#c.D_`n'] + _b[2012.cohort#c.D_`n'] +  _b[2013.cohort#c.D_`n'] +  _b[2014.cohort#c.D_`n'] +  _b[2015.cohort#c.D_`n'] + ///
			 _b[2016.cohort#c.D_`n'] + _b[2017.cohort#c.D_`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == -`n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == -`n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == -`n'
			
}
replace cap_coef = 0 if Timeto == 0
replace cap_up = 0 if Timeto == 0
replace cap_down = 0 if Timeto == 0

forvalues n = 1(1)10 {
	lincom ( _b[2001.cohort#c.D`n'] + _b[2002.cohort#c.D`n'] +  _b[2003.cohort#c.D`n'] +  _b[2004.cohort#c.D`n'] +  _b[2005.cohort#c.D`n'] + ///
			 _b[2006.cohort#c.D`n'] + _b[2007.cohort#c.D`n'] +  _b[2008.cohort#c.D`n'] +  _b[2009.cohort#c.D`n'] +  _b[2010.cohort#c.D`n'] +  ///
			 _b[2011.cohort#c.D`n'] + _b[2012.cohort#c.D`n'] +  _b[2013.cohort#c.D`n'] +  _b[2014.cohort#c.D`n'] +  _b[2015.cohort#c.D`n'] + ///
			 _b[2016.cohort#c.D`n'] + _b[2017.cohort#c.D`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == `n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == `n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == `n'
			
}

keep Timeto cap_*
drop if Timeto == .
sort Timeto
//save "$outdir/wooldridge_test.dta", replace

twoway 	(connected cap_coef Time, lp(solid) lw(thick) mcolor("$ylb") lcolor("$ylb"))  (rarea cap_up cap_down Time, fcolor("$ylb % 30") lcolor("$ylb % 5")) ///
			, yline(0, lcolor(gs10) lw(vthin)) xline(0.5, lc(red)) ///
			legend(off) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") xlabel(-5(1)10)
graph export "$outdir/test_wooldridge.png", replace
restore


** HOUSE PRICES
sort leaid year
merge m:1  leaid year using "$prepdata/hpi.dta"
drop if _m == 2
drop _m

reghdfe hpi $M_lead $M_lag  $E_lead $E_lag $cohort_year [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

preserve
gen Timeto = _n - 6 if _n <= 16
gen cap_coef = .
gen cap_up = .
gen cap_down = .
forvalues n = 5(-1)1 {
	lincom ( _b[2001.cohort#c.D_`n'] + _b[2002.cohort#c.D_`n'] +  _b[2003.cohort#c.D_`n'] +  _b[2004.cohort#c.D_`n'] +  _b[2005.cohort#c.D_`n'] + ///
			 _b[2006.cohort#c.D_`n'] + _b[2007.cohort#c.D_`n'] +  _b[2008.cohort#c.D_`n'] +  _b[2009.cohort#c.D_`n'] +  _b[2010.cohort#c.D_`n'] +  ///
			 _b[2011.cohort#c.D_`n'] + _b[2012.cohort#c.D_`n'] +  _b[2013.cohort#c.D_`n'] +  _b[2014.cohort#c.D_`n'] +  _b[2015.cohort#c.D_`n'] + ///
			 _b[2016.cohort#c.D_`n'] + _b[2017.cohort#c.D_`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == -`n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == -`n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == -`n'
			
}
replace cap_coef = 0 if Timeto == 0
replace cap_up = 0 if Timeto == 0
replace cap_down = 0 if Timeto == 0

forvalues n = 1(1)10 {
	lincom ( _b[2001.cohort#c.D`n'] + _b[2002.cohort#c.D`n'] +  _b[2003.cohort#c.D`n'] +  _b[2004.cohort#c.D`n'] +  _b[2005.cohort#c.D`n'] + ///
			 _b[2006.cohort#c.D`n'] + _b[2007.cohort#c.D`n'] +  _b[2008.cohort#c.D`n'] +  _b[2009.cohort#c.D`n'] +  _b[2010.cohort#c.D`n'] +  ///
			 _b[2011.cohort#c.D`n'] + _b[2012.cohort#c.D`n'] +  _b[2013.cohort#c.D`n'] +  _b[2014.cohort#c.D`n'] +  _b[2015.cohort#c.D`n'] + ///
			 _b[2016.cohort#c.D`n'] + _b[2017.cohort#c.D`n'] ) / 17
	replace cap_coef = `r(estimate)' if Timeto == `n'
	replace cap_up = `r(estimate)' + 1.65 * `r(se)'  if Timeto == `n'
	replace cap_down = `r(estimate)' - 1.65 * `r(se)'  if Timeto == `n'
			
}

keep Timeto cap_*
drop if Timeto == .
sort Timeto
//save "$outdir/wooldridge_hpi.dta", replace

twoway 	(connected cap_coef Time, lp(solid) lw(thick) mcolor("$ylb") lcolor("$ylb"))  (rarea cap_up cap_down Time, fcolor("$ylb % 30") lcolor("$ylb % 5")) ///
			, yline(0, lcolor(gs10) lw(vthin)) xline(0.5, lc(red)) ///
			legend(off) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") xlabel(-5(1)10)
graph export "$outdir/hpi_wooldridge.png", replace
restore

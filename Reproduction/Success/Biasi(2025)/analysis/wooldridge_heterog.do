 /*

wooldridge_heterog.do 

*/


clear all
capture log close
set more off 

local name "heterogeneous_effects"
local outfolder "heterogeneous_effects"


* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global yg = "94 112 45"
global ylight = "217 233 242" 
global graph = "xlabel(,grid glp(dot) glc(gs10) tlc(gs10)) ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"
global graphbar = "ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"


 

clear 
program drop _all
capture log close
set more off 


* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global ylight = "217 233 242" 
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


capt drop __*
rename year fy
merge m:1 leaid fy using  `demo'
drop if _m == 2
drop _m
rename fy year

sort leaid year
merge m:1 leaid year using `temp'
drop if _m == 2
drop _m


** Generate one group of observations per district-election
collapse holdbond passbond cap enroll margin scale_score lowsesT lowsesB minorT minorB (sum) test_enroll [aw = test_enroll], by(leaid year)
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




**** --------------------------------> CAPITAL SPENDING  < -------------------------------- ****




** High SES
qui reghdfe cap $M_lead $M_lag  $E_lead $E_lag $cohort_year if lowsesB == 1 [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Hcap_*
rename Ccap_* HCcap_*
drop if Timeto == .
duplicates drop
save "$outdir/wooldridge_cap_ses.dta", replace
restore




** Low SES

qui reghdfe cap $M_lead $M_lag  $E_lead $E_lag $cohort_year if lowsesT == 1 [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Lcap_*
rename Ccap_* LCcap_*
drop if Timeto == .
duplicates drop
sort Timeto
merge 1:1 Timeto using "$outdir/wooldridge_cap_ses.dta"
drop _m
save "$outdir/wooldridge_cap_ses.dta", replace
restore




** Figure
preserve
use "$outdir/wooldridge_cap_ses.dta", clear

twoway 	(connected Lcap_coef Time, mcolor("$yo") lcolor("$yo") lw(thick) lp(solid))  (rcap Lcap_up Lcap_down Time, lcolor("$yo % 30")) ///
		(line LCcap_coef Time, lcolor("$yo") lw(medium) lp(solid) yaxis(2)) (rarea LCcap_up LCcap_down Time, color("$yo % 20") yaxis(2)) ///
		(connected Hcap_coef Time, mcolor("$yaleblue") lp(dash) lcolor("$yaleblue") lw(thick) )  (rcap Hcap_up Hcap_down Time, lcolor("$yaleblue % 30")) ///
		(line HCcap_coef Time, lcolor("$yaleblue") lw(medium) lp(solid) yaxis(2)) (rarea HCcap_up HCcap_down Time, color("$yaleblue % 20") yaxis(2)) ///
		, xtitle("Time since bond passage") ytitle("Effect on capital spending ($)") ytitle("Cumulative effect on capital spending ($)", axis(2)) ///
		legend(order(1 "FRPL in top tercile" 3 "FRPL in bottom tercile")  row(4) pos(11) ring(0)) xlabel(-5(1)10) xline(0.3, lcolor(red)) ylabel(-900(300)1800, axis(1)) ylabel(-1800(600)3600, axis(2)) xsize(7) yline(0, lcolor(gs10) lw(vthin)) xlabel(-5(1)10)
graph export "$outdir/cap_wooldridge_ses.png", replace

rm "$outdir/wooldridge_cap_ses.dta"
restore






**** --------------------------------> TEST SCORES  < -------------------------------- ****




** High SES
qui reghdfe scale_score $M_lead $M_lag $E_lead $E_lag $cohort_year if lowsesB == 1 [aw = test_enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Hcap_*
drop if Timeto == .
duplicates drop
save "$outdir/wooldridge_test_ses.dta", replace
restore




** Low SES
qui reghdfe scale_score $M_lead $M_lag $E_lead $E_lag $cohort_year if lowsesT== 1 [aw = test_enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Lcap_*
drop if Timeto == .
duplicates drop
sort Timeto
merge 1:1 Timeto using "$outdir/wooldridge_test_ses.dta"
drop _m
save "$outdir/wooldridge_test_ses.dta", replace
restore




** Figure
preserve
use "$outdir/wooldridge_test_ses.dta", clear

twoway 	(connected Lcap_coef Time, mcolor("$yo") lcolor("$yo") lw(thick) lp(solid))  (rarea Lcap_up Lcap_down Time, color("$yo % 30")) ///
		(connected Hcap_coef Time, mcolor("$yaleblue") lp(dash) lcolor("$yaleblue") lw(thick) )  (rarea Hcap_up Hcap_down Time, color("$yaleblue % 30")) ///
		, yline(0, lcolor(gs10) lw(vthin)) xline(0.5, lc(red)) legend(order(1 "High SES" 3 "Low SES")  row(4) pos(11) ring(0))  ///
			legend(order(1 "FRPL in top tercile" 3 "FRPL in bottom tercile")  row(4) pos(11) ring(0)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") xlabel(-5(1)10)
graph export "$outdir/test_wooldridg_ses.png", replace

rm "$outdir/wooldridge_test_ses.dta"
restore





**** --------------------------------> HOUSE PRICES  < -------------------------------- ****



sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m




** Low SES
reghdfe hpi $M_lead $M_lag  $E_lead $E_lag $cohort_year if lowsesB== 1 [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Hcap_*
drop if Timeto == .
duplicates drop
save "$outdir/wooldridge_hpi_ses.dta", replace
restore




** Low SES
reghdfe hpi $M_lead $M_lag  $E_lead $E_lag $cohort_year if lowsesT== 1 [aw = enroll], a(leaid#cohort cohort#year) cluster(leaid)

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
rename cap_* Lcap_*
sort Timeto
merge 1:1 Timeto using "$outdir/wooldridge_hpi_ses.dta"
drop _m
save "$outdir/wooldridge_hpi_ses.dta", replace
restore





* Figure
preserve
use "$outdir/wooldridge_hpi_ses.dta", clear

twoway 	(connected Lcap_coef Time, mcolor("$yo") lcolor("$yo") lw(thick) lp(solid))  (rarea Lcap_up Lcap_down Time, color("$yo % 30")) ///
		(connected Hcap_coef Time, mcolor("$yaleblue") lp(dash) lcolor("$yaleblue") lw(thick) )  (rarea Hcap_up Hcap_down Time, color("$yaleblue % 30")) ///
		, yline(0, lcolor(gs10) lw(vthin)) xline(0.5, lc(red)) legend(order(1 "High SES" 3 "Low SES")  row(4) pos(11) ring(0))  ///
			legend(order(1 "FRPL in top tercile" 3 "FRPL in bottom tercile")  row(4) pos(11) ring(0)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") xlabel(-5(1)10)
graph export "$outdir/hpi_wooldridge_ses.png", replace

rm "$outdir/wooldridge_hpi_ses.dta"
restore

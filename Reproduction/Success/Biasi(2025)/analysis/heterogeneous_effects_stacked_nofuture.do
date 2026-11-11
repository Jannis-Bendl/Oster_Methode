 /*

heterogeneous_effects_stacked_nofuture.do 
	
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



use "$prepdata/stacked_data.dta", clear


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

** Useful globals
global D_lag = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 D_1 "
global D_lead = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"

** Label variables to plot
gen zero = 0
label var zero "0"
forvalues n = 1 / 27{
	label var D_`n' "-`n'"
	label var D`n' "`n'"
}
	label var D0 "0"

* Figure aspect
*global axissize = "ylabel(, labsize(large))  xlabel(, labsize(large))"
*global labsize = "size(large)"
*global xsize = "xsize(5)"
global axissize = " "
global labsize = " "
global xsize = "xsize(6.5)"


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



*---> Fix specification you want to run:
global model = 		"$D_lag zero $D_lead El0 Ml0 $E_lag $M_lag"
global FE = 		"leaid#cohort fips#year#cohort"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"


********************************************************************************
*************** 										 		 ***************
*************** 		By student characteristics	 		 ***************
*************** 										 		 ***************
********************************************************************************


*---------> Share of low-SES students

* Capital spending
preserve
*keep if first_sign == 1
drop grade subject test_enroll scale_score
duplicates drop
capt drop x
gen x = _n - 6 if _n <= 16
gen coefcum_si = .
gen upcum_si = .
gen downcum_si = .
gen coef_si = .
gen up_si = .
gen down_si = .
gen coefcum_su = .
gen upcum_su = .
gen downcum_su = .
gen coef_su = .
gen up_su = .
gen down_su = .

eststo cap_lowses: reghdfe cap $model if lowsesB == 1 [aw = enroll], a($FE) cl(leaid) 

local t = invttail(`e(df_r)', .025)
replace coefcum_si = _b[D1] if x == 1
replace upcum_si = _b[D1] + ((`t')*_se[D1]) if x == 1
replace downcum_si = _b[D1] - ((`t')*_se[D1]) if x == 1
global COEF = "D1"
forvalues n = 2/10 {
	global COEF = "$COEF + D`n'"
	lincom ($COEF)
	replace coefcum_si = r(estimate) if x == `n'
	replace upcum_si = r(estimate) + ((`t')*r(se)) if x == `n'
	replace downcum_si = r(estimate) - ((`t')*r(se)) if x == `n'

}

local k = 1
forvalues n = 5(-1)1 {
	replace coef_si = _b[D_`n'] if x == -`n'
	replace up_si = _b[D_`n'] + ((`t')*_se[D_`n'])	if x == -`n'
	replace down_si = _b[D_`n'] - ((`t')*_se[D_`n'])	if x == -`n'
	replace x = -`n' if x == -`n'
	local k = `k' + 1
}
	replace coef_si = 0 if x == 0
	replace up_si = 0 if x == 0
	replace down_si = 0 if x == 0
	replace coefcum_si = 0 if x == 0
	replace upcum_si = 0 if x == 0
	replace downcum_si = 0 if x == 0
	
	local k = `k' + 1

forvalues n = 1(1)10 {
	replace coef_si = _b[D`n']	if x == `n'
	replace up_si = _b[D`n'] + ((`t')*_se[D`n'])	if x == `n'
	replace down_si = _b[D`n'] - ((`t')*_se[D`n']) if x == `n'
	local k = `k' + 1
}

eststo cap_highses: reghdfe cap $model if lowsesT == 1 [aw = enroll], a($FE) cl(leaid) 

local t = invttail(`e(df_r)', .025)
replace coefcum_su = _b[D1] if x == 1
replace upcum_su = _b[D1] + ((`t')*_se[D1]) if x == 1
replace downcum_su = _b[D1] - ((`t')*_se[D1]) if x == 1
global COEF = "D1"
forvalues n = 2/10 {
	global COEF = "$COEF + D`n'"
	lincom ($COEF)
	replace coefcum_su = r(estimate) if x == `n'
	replace upcum_su = r(estimate) + ((`t')*r(se)) if x == `n'
	replace downcum_su = r(estimate) - ((`t')*r(se)) if x == `n'

}

local k = 1
forvalues n = 5(-1)1 {
	replace coef_su = _b[D_`n'] if x == -`n'
	replace up_su = _b[D_`n'] + ((`t')*_se[D_`n'])	if x == -`n'
	replace down_su = _b[D_`n'] - ((`t')*_se[D_`n'])	if x == -`n'
	local k = `k' + 1
}
	replace coef_su = 0 if x == 0
	replace up_su = 0 if x == 0
	replace down_su = 0 if x == 0
	replace coefcum_su = 0 if x == 0
	replace upcum_su = 0 if x == 0
	replace downcum_su = 0 if x == 0
	
	local k = `k' + 1

forvalues n = 1(1)10 {
	replace coef_su = _b[D`n']	if x == `n'
	replace up_su = _b[D`n'] + ((`t')*_se[D`n'])	if x == `n'
	replace down_su = _b[D`n'] - ((`t')*_se[D`n']) if x == `n'
	local k = `k' + 1
}

gen x2 = x - 0.2
twoway 	(connected coef_si x2, mcolor("$yaleblue") lcolor("$yaleblue") lw(medthick) lp(dash))  (rcap up_si down_si x2, lcolor("$yaleblue % 30")) ///
		(connected coef_su x, mcolor("$yo") lcolor("$yo") lw(thick) lp(solid))  (rcap up_su down_su x, lcolor("$yo % 30")) ///
		(line coefcum_si x2, lcolor("$yaleblue") lw(medium) lp(solid) yaxis(2)) (rarea upcum_si downcum_si x2, color("$yaleblue % 20") yaxis(2)) ///
		(line coefcum_su x, lcolor("$yo") lw(medium) lp(solid) yaxis(2)) (rarea upcum_su downcum_su x, color("$yo % 20") yaxis(2)) ///
		, xtitle("Time to bond passage") ytitle("Effect on capital spending ($)") ytitle("Cumulative effect on capital spending ($)", axis(2)) ///
		legend(order(1 "Low share FRPL" 3 "High share FRPL" 5 "High SES (cumulative)" 7 "Low SES (cumulative)") row(4) pos(11) ring(0)) xlabel(-5(1)10) xline(0.3, lcolor(red)) ylabel(-500(500)2500, axis(1)) ylabel(-2000(2000)10000, axis(2))  xsize(6) yline(0, lcolor(gs10) lw(vthin))
graph export "$outdir/cap_byses_nofuture.png", replace
restore


** Pooled test scores
eststo test_lowses: reghdfe scale_score $model  if lowsesB == 1 [aw = test_enroll], a($FE_test) cl(leaid cohort)
eststo test_highses: reghdfe scale_score $model if lowsesT == 1 [aw = test_enroll], a($FE_test) cl(leaid) 
coefplot	(test_lowses, label("Low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(test_highses, label("High share FRPL") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on test scores (sd)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-0.1(0.1)0.2)   xsize(6)
graph export "$outdir/testpooled_byses_nofuture.png", replace

** House prices
preserve
estimates clear
drop grade subject test_enroll scale_score 
capt drop _est*
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m

eststo hp_lowses: reghdfe hpi $model if lowsesB == 1 [aw = enroll], a($FE) cl(leaid) 
eststo hp_highses: reghdfe hpi $model if lowsesT == 1 [aw = enroll], a($FE) cl(leaid) 
coefplot	(hp_lowses, label("Low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hp_highses, label("High share FRPL") lcolor("$yo")lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize)  xsize(6)
graph export "$outdir/hpi_byses_nofuture.png", replace
restore


*---------> Share of minority students


* Capital spending
preserve
*keep if first_sign == 1
drop grade subject test_enroll scale_score
duplicates drop
capt drop x
gen x = _n - 6 if _n <= 16
gen coefcum_si = .
gen upcum_si = .
gen downcum_si = .
gen coef_si = .
gen up_si = .
gen down_si = .
gen coefcum_su = .
gen upcum_su = .
gen downcum_su = .
gen coef_su = .
gen up_su = .
gen down_su = .

eststo cap_lowses: reghdfe cap $model if minorB == 1 [aw = enroll], a($FE) cl(leaid) 

local t = invttail(`e(df_r)', .025)
replace coefcum_si = _b[D1] if x == 1
replace upcum_si = _b[D1] + ((`t')*_se[D1]) if x == 1
replace downcum_si = _b[D1] - ((`t')*_se[D1]) if x == 1
global COEF = "D1"
forvalues n = 2/10 {
	global COEF = "$COEF + D`n'"
	lincom ($COEF)
	replace coefcum_si = r(estimate) if x == `n'
	replace upcum_si = r(estimate) + ((`t')*r(se)) if x == `n'
	replace downcum_si = r(estimate) - ((`t')*r(se)) if x == `n'

}

local k = 1
forvalues n = 5(-1)1 {
	replace coef_si = _b[D_`n'] if x == -`n'
	replace up_si = _b[D_`n'] + ((`t')*_se[D_`n'])	if x == -`n'
	replace down_si = _b[D_`n'] - ((`t')*_se[D_`n'])	if x == -`n'
	replace x = -`n' if x == -`n'
	local k = `k' + 1
}
	replace coef_si = 0 if x == 0
	replace up_si = 0 if x == 0
	replace down_si = 0 if x == 0
	replace coefcum_si = 0 if x == 0
	replace upcum_si = 0 if x == 0
	replace downcum_si = 0 if x == 0
	
	local k = `k' + 1

forvalues n = 1(1)10 {
	replace coef_si = _b[D`n']	if x == `n'
	replace up_si = _b[D`n'] + ((`t')*_se[D`n'])	if x == `n'
	replace down_si = _b[D`n'] - ((`t')*_se[D`n']) if x == `n'
	local k = `k' + 1
}

eststo cap_highses: reghdfe cap $model if minorT == 1 [aw = enroll], a($FE) cl(leaid) 

local t = invttail(`e(df_r)', .025)
replace coefcum_su = _b[D1] if x == 1
replace upcum_su = _b[D1] + ((`t')*_se[D1]) if x == 1
replace downcum_su = _b[D1] - ((`t')*_se[D1]) if x == 1
global COEF = "D1"
forvalues n = 2/10 {
	global COEF = "$COEF + D`n'"
	lincom ($COEF)
	replace coefcum_su = r(estimate) if x == `n'
	replace upcum_su = r(estimate) + ((`t')*r(se)) if x == `n'
	replace downcum_su = r(estimate) - ((`t')*r(se)) if x == `n'

}

local k = 1
forvalues n = 5(-1)1 {
	replace coef_su = _b[D_`n'] if x == -`n'
	replace up_su = _b[D_`n'] + ((`t')*_se[D_`n'])	if x == -`n'
	replace down_su = _b[D_`n'] - ((`t')*_se[D_`n'])	if x == -`n'
	local k = `k' + 1
}
	replace coef_su = 0 if x == 0
	replace up_su = 0 if x == 0
	replace down_su = 0 if x == 0
	replace coefcum_su = 0 if x == 0
	replace upcum_su = 0 if x == 0
	replace downcum_su = 0 if x == 0
	
	local k = `k' + 1

forvalues n = 1(1)10 {
	replace coef_su = _b[D`n']	if x == `n'
	replace up_su = _b[D`n'] + ((`t')*_se[D`n'])	if x == `n'
	replace down_su = _b[D`n'] - ((`t')*_se[D`n']) if x == `n'
	local k = `k' + 1
}

gen x2 = x - 0.2
twoway 	(connected coef_si x2, mcolor("$yaleblue") lcolor("$yaleblue") lw(medthick) lp(dash))  (rcap up_si down_si x2, lcolor("$yaleblue % 30")) ///
		(connected coef_su x, mcolor("$yo") lcolor("$yo") lw(thick) lp(solid))  (rcap up_su down_su x, lcolor("$yo % 30")) ///
		(line coefcum_si x2, lcolor("$yaleblue") lw(medium) lp(solid) yaxis(2)) (rarea upcum_si downcum_si x2, color("$yaleblue % 20") yaxis(2)) ///
		(line coefcum_su x, lcolor("$yo") lw(medium) lp(solid) yaxis(2)) (rarea upcum_su downcum_su x, color("$yo % 20") yaxis(2)) ///
		, xtitle("Time to bond passage") ytitle("Effect on capital spending ($)") ytitle("Cumulative effect on capital spending ($)", axis(2)) ///
		legend(order(1 "Low minority" 3 "High minority" 5 "Low minority (cumulative)" 7 "High minority (cumulative)")  $labsize row(4) pos(11) ring(0)) xlabel(-5(1)10) xline(0.3, lcolor(red)) ylabel(-500(500)2500, axis(1)) ylabel(-2000(2000)10000, axis(2))  xsize(6) yline(0, lcolor(gs10) lw(vthin))
graph export "$outdir/cap_byminor_nofuture.png", replace
restore


** Pooled test scores
eststo test_lowmin: reghdfe scale_score $model  if minorB == 1 [aw = test_enroll], a($FE_test) cl(leaid) 
eststo test_highmin: reghdfe scale_score $model if minorT == 1 [aw = test_enroll], a($FE_test) cl(leaid) 

coefplot	(test_lowmin, label("Low minority") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(test_highmin, label("High minority") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on test scores (sd)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-0.1(0.1)0.2)  xsize(6)
graph export "$outdir/testpooled_byminor_nofuture.png", replace



** House prices
preserve
estimates clear
drop grade subject test_enroll scale_score 
capt drop _est*
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m

eststo hp_lowmin: reghdfe hpi $model  if minorB == 1 [aw = enroll], a($FE) cl(leaid) 
eststo hp_highmin: reghdfe hpi $model  if minorT == 1 [aw = enroll], a($FE) cl(leaid) 

coefplot	(hp_lowmin, label("Low minority") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hp_highmin, label("High minority") lcolor("$yo")lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize)  xsize(6)
graph export "$outdir/hpi_byminor_nofuture.png", replace
restore

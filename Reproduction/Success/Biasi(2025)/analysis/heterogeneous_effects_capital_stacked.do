/*

heterogeneous_effects_capital_stacked.do

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


** Select right stacked dataset
global est = "main"
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
	
	
	

gen share_nondis = 1 - sh_dy_econdis

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
global model = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead"
global FE = 		"leaid#cohort fips#year#cohort"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"



*---------> Merge in past spending
preserve
use "$prepdata/capstock.dta", clear
gen T1 = .
gen T2 = .
gen T3 = .
gen M2 = .
levelsof year, local(Year)
foreach y of local Year {
	_pctile capstock if year == `y', n(100)
	replace T1 = capstock <= `r(r33)' if year == `y'
	replace T2 = capstock > `r(r33)' & capstock <= `r(r67)' if year == `y'
	replace T3 = capstock > `r(r67)' if year == `y'
	replace M2 = capstock > `r(r50)' if year == `y'
	replace T1 = . if capstock == .
	replace T2 = . if capstock == .
	replace T3 = . if capstock == .
	replace M2 = . if capstock == .
}
gen captercile = 1 if T1 == 1
replace captercile = 2 if T2 == 1
replace captercile = 3 if T3 == 1
sort leaid year
tempfile capstock
save `capstock', replace
restore

sort leaid year
merge m:1 leaid year using `capstock', keep(1 3) nogen

gen time = year - cohort
tempvar capter_med
gen `capter_med' = captercile if time == -1
tempvar cap_abovemed
gen `cap_abovemed' = M2 if time == -1
bysort leaid cohort: egen cap_abovemed = median(`cap_abovemed')
drop time





********************************************************************************
***** 							By capital stock  	 		 ***************
********************************************************************************



** Correlation between cap spending and share low SES, 2000
egen tag = tag(leaid year)
gen capstockT = capstock / 1000
reg capstockT sh_dy_econdis if tag == 1 & year == 2000, rob
lincom sh_dy_econdis
global slope: di %3.2fc r(estimate)
global pval: di %12.2fc r(p)
global star = cond(${pval} < 0.01, "***",cond(${pval} < 0.05,"**",cond(${pval} < 0.1,"*","")))

twoway (scatter capstockT sh_dy_econdis if tag == 1 & year == 2000,  mcolor("$yaleblue")) (lfit capstockT sh_dy_econdis if tag == 1 & year == 2000, lcolor("$yo")), ytitle("Capital stock ($1,000), 2000") xtitle("Share FRPL students, 2000") legend(off) text(80 0.8  "slope = ${slope}${star}")
graph export "$outdir/corr_capstock_ses_$est.png", replace


** Pooled test scores: low SES, by cap spending
eststo test_lowcap_lowses: reghdfe scale_score $model  if cap_abo == 0 & lowsesT == 1 [aw = test_enroll], a($FE_test) cl(leaid cohort)
eststo test_lowcap_highses: reghdfe scale_score $model if cap_abo == 0 & lowsesB == 1  [aw = test_enroll], a($FE_test) cl(leaid) 
coefplot	(test_lowcap_highses, label("Low capital stock, low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(test_lowcap_lowses, label("Low capital stock, high share FRPL") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on test scores (sd)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-0.1(0.1)0.4)   xsize(6)
graph export "$outdir/testpooled_lowcap_bySES_$est.png", replace


** Pooled test scores: high SES, by capital spending 
eststo test_highcap_lowses: reghdfe scale_score $model  if cap_abo == 1 & lowsesT == 1 [aw = test_enroll], a($FE_test) cl(leaid cohort)
eststo test_highcap_highses: reghdfe scale_score $model if cap_abo == 1 & lowsesB == 1  [aw = test_enroll], a($FE_test) cl(leaid) 
coefplot	(test_highcap_highses, label("High capital stock, low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(test_highcap_lowses, label("High capital stock, high share FRPL") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on test scores (sd)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-0.1(0.1)0.4)   xsize(6)
graph export "$outdir/testpooled_highcap_bySES_$est.png", replace


** House prices
preserve
estimates clear
drop grade subject test_enroll scale_score 
capt drop _est*
duplicates drop
sort leaid year
merge m:1  leaid year using "$prepdata/hpi.dta"
drop if _m == 2
drop _m

eststo hp_lowcap: reghdfe hpi $model if cap_abo == 0 [aw = enroll], a($FE) cl(leaid) 
eststo hp_highcap: reghdfe hpi $model if cap_abo == 1 [aw = enroll], a($FE) cl(leaid) 
coefplot	(hp_highcap, label("High capital stock") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hp_lowcap, label("Low capital stock") lcolor("$yo")lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize)  xsize(6)
graph export "$outdir/hpi_bycap_$est.png", replace


coefplot	(hp_highcap, label("High capital stock") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hp_lowcap, label("Low capital stock") lcolor("$yo")lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize) xsize(5)
graph export "$outdir/hpi_bycap_$est_slides.png", replace
restore




** House prices: low SES, by cap spending
preserve
estimates clear
drop grade subject test_enroll scale_score 
capt drop _est*
duplicates drop
sort leaid year
merge m:1  leaid year using "$prepdata/hpi.dta"
drop if _m == 2
drop _m

eststo hpi_lowcap_lowses: reghdfe hpi $model  if cap_abo == 0 & lowsesT == 1 [aw = enroll], a($FE) cl(leaid cohort)
eststo hpi_lowcap_highses: reghdfe hpi $model if cap_abo == 0 & lowsesB == 1  [aw = enroll], a($FE) cl(leaid) 
coefplot	(hpi_lowcap_highses, label("Low capital stock, low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hpi_lowcap_lowses, label("Low capital stock, high share FRPL") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-20(10)40)   xsize(6)
graph export "$outdir/hpi_lowcap_bySES_$est.png", replace


** House prices: high SES, by capital spending 
eststo hpi_highcap_lowses: reghdfe hpi $model  if cap_abo == 1 & lowsesT == 1 [aw = enroll], a($FE) cl(leaid cohort)
eststo hpi_highcap_highses: reghdfe hpi $model if cap_abo == 1 & lowsesB == 1  [aw = enroll], a($FE) cl(leaid) 
coefplot	(hpi_highcap_highses, label("High capital stock, low share FRPL") lcolor("$yaleblue") lp(dash) lw(medthick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 20") lcolor("$yaleblue % 10"))) ///
			(hpi_highcap_lowses, label("High capital stock, high share FRPL") lcolor("$yo") lp(solid) lw(thick) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 20") lcolor("$yo % 10"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(2) pos(11) ring(0) $labsize) ytitle("Effect on house prices (%)", $labsize) xtitle("Time to bond passage", $labsize) ylabel(-20(10)40)    xsize(6)
graph export "$outdir/hpi_highcap_bySES_$est.png", replace
restore

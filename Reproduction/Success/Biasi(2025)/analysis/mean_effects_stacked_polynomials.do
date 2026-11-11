 /*

mean_effects_stacked_polynomials.do 
	
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
global Md_lag = "Mld22 Mld21 Mld20 Mld19 Mld18 Mld17 Mld16 Mld15 Mld14 Mld13 Mld12 Mld11 Mld10 Mld9 Mld8 Mld7 Mld6 Mld5 Mld4 Mld3 Mld2 Mld1 Mld0"
global Md_lead = "Mfd1 Mfd2 Mfd3 Mfd4 Mfd5 Mfd6 Mfd7 Mfd8 Mfd9 Mfd10 Mfd11 Mfd12 Mfd13 Mfd14 Mfd15 Mfd16 Mfd17 Mfd18 Mfd19 Mfd20 Mfd21 Mfd22"
global M2_lag = "M2l22 M2l21 M2l20 M2l19 M2l18 M2l17 M2l16 M2l15 M2l14 M2l13 M2l12 M2l11 M2l10 M2l9 M2l8 M2l7 M2l6 M2l5 M2l4 M2l3 M2l2 M2l1 M2l0"
global M2_lead = "M2f1 M2f2 M2f3 M2f4 M2f5 M2f6 M2f7 M2f8 M2f9 M2f10 M2f11 M2f12 M2f13 M2f14 M2f15 M2f16 M2f17 M2f18 M2f19 M2f20 M2f21 M2f22"
global Md2_lag = "M2ld22 M2ld21 M2ld20 M2ld19 M2ld18 M2ld17 M2ld16 M2ld15 M2ld14 M2ld13 M2ld12 M2ld11 M2ld10 M2ld9 M2ld8 M2ld7 M2ld6 M2ld5 M2ld4 M2ld3 M2ld2 M2ld1 M2ld0"
global Md2_lead = "M2fd1 M2fd2 M2fd3 M2fd4 M2fd5 M2fd6 M2fd7 M2fd8 M2fd9 M2fd10 M2fd11 M2fd12 M2fd13 M2fd14 M2fd15 M2fd16 M2fd17 M2fd18 M2fd19 M2fd20 M2fd21 M2fd22"


** Select right stacked dataset
global est = "main"
use "$prepdata/stacked_data.dta", clear

** Label variables to plot
gen zero = 0
label var zero "0"
forvalues n = 1 / 27{
	label var D_`n' "-`n'"
	label var D`n' "`n'"
}
	label var D0 "0"
	
	
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



********************************************************************************
***** 					 Estimates + figures					 ***************
********************************************************************************

*---> Fix specification you want to run:
global model1 = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead $Md_lag $Md_lead"
global model2 = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead $M2_lag $M2_lead"
global model3 = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead $Md_lag $Md_lead $M2_lag $M2_lead $Md2_lag $Md2_lead"
global FE = 		"leaid#cohort cohort#fips#year"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"


** Capital spending 1
capt drop x coeff
gen coef2 = .
gen up2 = .
gen down2 = .
gen coef3 = .
gen up3 = .
gen down3 = .


forvalues w = 1/3 {


preserve
drop grade subject test_enroll scale_score
duplicates drop

gen x = _n-6
replace x = . if x > 10
eststo capsp_linear: reghdfe cap ${model`w'} [aw = enroll], a($FE) cl(leaid) 

local t = invttail(`e(df_r)', .025)
replace coef3 = _b[D1] if x == 1
replace up3 = _b[D1] + ((`t')*_se[D1]) if x == 1
replace down3 = _b[D1] - ((`t')*_se[D1]) if x == 1
global COEF = "D1"
forvalues n = 2/10 {
	global COEF = "$COEF + D`n'"
	lincom ($COEF)
	replace coef3 = r(estimate) if x == `n'
	replace up3 = r(estimate) + ((`t')*r(se)) if x == `n'
	replace down3 = r(estimate) - ((`t')*r(se)) if x == `n'

}

local k = 1
forvalues n = 5(-1)1 {
	replace coef2 = _b[D_`n'] if x == -`n'
	replace up2 = _b[D_`n'] + ((`t')*_se[D_`n'])	if x == -`n'
	replace down2 = _b[D_`n'] - ((`t')*_se[D_`n'])	if x == -`n'
	replace x = -`n' if x == -`n'
	local k = `k' + 1
}
	replace coef2 = 0 if x == 0
	replace up2 = 0 if x == 0
	replace down2 = 0 if x == 0
	replace coef3 = 0 if x == 0
	replace up3 = 0 if x == 0
	replace down3 = 0 if x == 0
	
	local k = `k' + 1

forvalues n = 1(1)10 {
	replace coef2 = _b[D`n']	if x == `n'
	replace up2 = _b[D`n'] + ((`t')*_se[D`n'])	if x == `n'
	replace down2 = _b[D`n'] - ((`t')*_se[D`n']) if x == `n'
	local k = `k' + 1
}
gen x2 = x - 0.2
sort x


twoway 	(connected coef2 x, mcolor("$ylb") lcolor("$ylb") lw(thick) lp(solid))  (rcap up2 down2 x, lcolor("$ylb % 30")) ///
		(line coef3 x, lcolor("$yo") lw(thick) lp(solid) yaxis(2)) (rarea up3 down3 x, color("$yo % 20") yaxis(2)) ///
		, xtitle("Time since bond passage") ytitle("Effect on capital spending ($)") ytitle("Cumulative effect on capital spending ($)", axis(2)) ///
		legend(ring(0) pos(11) order(1 "Effect per year" 3 "Cumulative effect")) xlabel(-5(1)10) xline(0.3, lcolor(red)) ylabel(-600(200)1000, axis(1)) ylabel(-1800(600)3000, axis(2)) xsize(7) yline(0, lcolor(gs10) lw(vthin))
graph export "$outdir/cap_stacked_future_${est}_pol`w'.png", replace
restore 


	
** Test scores

capt drop __*
eststo test: reghdfe scale_score ${model`w'}  [aw = test_enroll], a($FE_test) cluster(leaid)

coefplot	(test,  lcolor("$yaleblue") lp(solid) lw(thick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(off) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") // ylabel(-400(400)1200)
graph export "$outdir/test_stacked_future_${est}_pol`w'.png", replace




** House prices
preserve
capt drop _est*
drop grade subject test_enroll scale_score
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m
rename year year

eststo hp_lin: reghdfe hpi  ${model`w'} [aw = enroll], a($FE) cl(leaid) 
coefplot	(hp_lin,  lcolor("$yaleblue") lp(solid) lw(thick) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) ///
			level(90) legend(off) ytitle("Effect on house prices (%)") xtitle("Time since bond passage")	
graph export "$outdir/hpi_stacked_future_${est}_pol`w'.png", replace
restore


}

 /*

sorting_index.do 

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



** Select right stacked dataset
global est = "main"
use "$prepdata/stacked_data.dta", clear

capt drop __*


** Label variables to plot
gen zero = 0
label var zero "0"
forvalues n = 1 / 27{
	label var D_`n' "-`n'"
	label var D`n' "`n'"
}
	label var D0 "0"
	
* Keep only states with OK density
* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25


preserve
keep leaid year
duplicates drop
sort leaid year
tempfile tag
save `tag', replace
restore

********************************************************************************
***** 					 Build index					 ***************
********************************************************************************

preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore

preserve
use "$prepdata/analysis_dataset.dta", clear
merge m:1 leaid year using  "$prepdata/demographics.dta", keep(1 3) nogen
merge m:1 leaid year using  `temp', keep(1 3) nogen
merge m:1 leaid year using  "$prepdata/hpi.dta", keep(1 3) nogen
merge m:1 leaid year using `tag', keep(3) nogen


* Demographic variables to include in the index

local demvars = " black asian hisp frpl poor shprivate el sped teacher" 
global dem = ""
global demH = ""
foreach d of local demvars {
	global dem = "$dem `d'" 
	global demH = "$demH `d'" 
}

capt bysort leaid: egen bondever = max(passbond)


reghdfe scale_score $dem [aw = test_enroll], a(leaid year#fips#grade#subject)
disp e(N)
capt drop I* P*
predict P_scale_score, xb
replace P_scale_score = P_scale_score - _b[_cons]
gen I_scale_score = scale_score - P_scale_score
capt corr scale_score P_scale if e(sample) == 0
capt corr scale_score I_scale if e(sample) == 0


egen tag = tag(leaid year)
reghdfe hpi $dem [aw = test_enroll], a(leaid year#fips#grade#subject)
predict P_hpi, xb
replace P_hpi = P_hpi - _b[_cons]
gen I_hpi = hpi - P_hpi
corr I_hpi hpi

bysort leaid year (grade): carryforward P_hpi I_hpi, replace
gsort leaid year -grade
bysort leaid year: carryforward P_hpi I_hpi, replace
keep leaid year grade subject I_* P_*
sort leaid year grade subject 
tempfile score
save `score', replace
restore

*---> Merge into stacked data
sort leaid year grade subject
merge m:1 leaid year grade subject using `score', keep(3) nogen


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
***** 			 Estimates + figures of effects	- means			 ***************
*******************************************************************************


merge m:1 leaid year using  "$prepdata/demographics.dta", keep(1 3) nogen
preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore
merge m:1 leaid year using  `temp', keep(1 3) nogen

*---> Fix specification you want to run:

global model = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead"
global FE = 		"leaid#cohort cohort#fips#year"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"


gen tag = grade == 4 & subj == 1

** Test scores

capt drop __*
eststo Btest: reghdfe scale_score $model [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ctest: reghdfe scale_score $model $dem [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ptest: reghdfe P_scale_score $model [aw = test_enroll], a($FE_test) cluster(leaid)


coefplot	(Btest, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Ctest, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Ptest, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") 
graph export "$outdir/test_stacked_sortrob_$est.png", replace

** HPI 
preserve
capt drop _est*
drop grade subject test_enroll scale_score
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m

eststo Bhpi: reghdfe hpi $model [aw = enroll], a($FE) cluster(leaid)
eststo Chpi: reghdfe hpi $model $dem [aw = enroll], a($FE) cluster(leaid)
eststo Phpi: reghdfe P_hpi $model [aw = enroll], a($FE) cluster(leaid)


coefplot	(Bhpi, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Chpi, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Phpi, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") 
graph export "$outdir/hpi_stacked_sortrob_$est.png", replace
restore



********************************************************************************
***** 			 Estimates + figures of effects	- by SES		 ***************
********************************************************************************

preserve
use  "$prepdata/demographics.dta", clear
tempvar lowsesT lowsesB minorT minorB

gen `lowsesT' = 0 if frpl != . & year == 1995
gen `lowsesB' = 0 if frpl != . & year == 1995

gen share_minor = hisp + black
gen `minorT' = 0 if share_minor != . & year == 1995
gen `minorB' = 0 if share_minor != . & year == 1995

_pctile frpl if year == 1995, n(100)
replace `lowsesT' = frpl >= r(r67) if frpl != . & year == 1995
replace `lowsesB' = frpl <= r(r33) if frpl != . & year == 1995

_pctile share_minor if year == 1995, n(100)
replace `minorT' = share_minor >= r(r67) if share_minor != . & year == 1995
replace `minorB' = share_minor <= r(r33) if share_minor != . & year == 1995

foreach var in lowsesT lowsesB minorT minorB {
	bysort leaid: egen `var' = max(``var'')
}

keep leaid year minor* lowses*

sort leaid year
tempfile temp
save `temp', replace
restore

sort leaid year
merge m:1 leaid year using `temp', keep(1 3) nogen



*----> Split by SES

** Test scores
capt drop __*
eststo Btest: reghdfe scale_score $model if lowsesT == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ctest: reghdfe scale_score $model $dem if lowsesT == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ptest: reghdfe P_scale_score $model if lowsesT == 1  [aw = test_enroll], a($FE_test) cluster(leaid)

coefplot	(Btest, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Ctest, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Ptest, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") ylabel(-0.2(0.1)0.2)
graph export "$outdir/test_stacked_sortrob_lowSES_$est.png", replace

eststo Btest: reghdfe scale_score $model if lowsesB == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ctest: reghdfe scale_score $model $dem if lowsesB == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ptest: reghdfe P_scale_score $model if lowsesB == 1  [aw = test_enroll], a($FE_test) cluster(leaid)

coefplot	(Btest, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Ctest, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Ptest, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") ylabel(-0.2(0.1)0.2)
graph export "$outdir/test_stacked_sortrob_highSES_$est.png", replace

** HPI 
preserve
capt drop _est*
drop grade subject test_enroll scale_score
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m

eststo Bhpi: reghdfe hpi $model if lowsesT == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Chpi: reghdfe hpi $model $dem if lowsesT == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Phpi: reghdfe P_hpi $model if lowsesT == 1  [aw = enroll], a($FE) cluster(leaid)

coefplot	(Bhpi, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Chpi, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Phpi, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") ylabel(-10(10)30)
graph export "$outdir/hpi_stacked_sortrob_lowSES_$est.png", replace


eststo Bhpi: reghdfe hpi $model if lowsesB == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Chpi: reghdfe hpi $model $dem if lowsesB == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Phpi: reghdfe P_hpi $model if lowsesB == 1  [aw = enroll], a($FE) cluster(leaid)

coefplot	(Bhpi, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Chpi, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Phpi, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage")  ylabel(-10(10)30)
graph export "$outdir/hpi_stacked_sortrob_highSES_$est.png", replace
restore


*----> Split by Minority

** Test scores
capt drop __*
eststo Btest: reghdfe scale_score $model if minorT == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ctest: reghdfe scale_score $model $dem if minorT == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ptest: reghdfe P_scale_score $model if minorT == 1  [aw = test_enroll], a($FE_test) cluster(leaid)

coefplot	(Btest, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Ctest, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Ptest, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") 
graph export "$outdir/test_stacked_sortrob_highminor_$est.png", replace

eststo Btest: reghdfe scale_score $model if minorB == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ctest: reghdfe scale_score $model $dem if minorB == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
eststo Ptest: reghdfe P_scale_score $model if minorB == 1  [aw = test_enroll], a($FE_test) cluster(leaid)

coefplot	(Btest, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Ctest, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Ptest, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") 
graph export "$outdir/test_stacked_sortrob_lowminor_$est.png", replace

** HPI 
preserve
capt drop _est*
drop grade subject test_enroll scale_score
duplicates drop
sort leaid year
merge m:1  leaid year using "$root/data/prep/hpi.dta"
drop if _m == 2
drop _m

eststo Bhpi: reghdfe hpi $model if minorT == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Chpi: reghdfe hpi $model $dem if minorT == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Phpi: reghdfe P_hpi $model if minorT == 1  [aw = enroll], a($FE) cluster(leaid)

coefplot	(Bhpi, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Chpi, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Phpi, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") 
graph export "$outdir/hpi_stacked_sortrob_highminor_$est.png", replace


eststo Bhpi: reghdfe hpi $model if minorB == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Chpi: reghdfe hpi $model $dem if minorB == 1  [aw = enroll], a($FE) cluster(leaid)
eststo Phpi: reghdfe P_hpi $model if minorB == 1  [aw = enroll], a($FE) cluster(leaid)

coefplot	(Bhpi, label("Main Effects") lcolor("$yaleblue") lp(solid) lw(medium) mcolor("$yaleblue") recast(connect) ciopts(recast(rarea) fcolor("$yaleblue % 30") lcolor("$yo % 5"))) ///
			(Chpi, label("Controlling for observables") lcolor("$ylb") lp(solid) lw(thick) mcolor("$ylb") recast(connect) ciopts(recast(rarea) fcolor("$ylb % 30") lcolor("$ylb % 5"))) ///
			(Phpi, label("Covariates Prediction") lcolor("$yo") lp(dash) lw(thin) mcolor("$yo") recast(connect) ciopts(recast(rarea) fcolor("$yo % 30") lcolor("$yo % 5"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.5, lc(red)) ///
			level(90) legend(ring(0) pos(11)) ytitle("Effect on house prices (%)") xtitle("Time since bond passage") 
graph export "$outdir/hpi_stacked_sortrob_lowminor_$est.png", replace
restore





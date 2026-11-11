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



foreach data in "main" "match" "cleanfull" {

global est = "`data'"

** Select right stacked dataset

if "$est" == "main" {
	global dataset = "$prepdata/stacked_cat_data_simple.dta"
}
else if "$est" == "match" {
	global dataset = "$prepdata/stacked_cat_data_future.dta"
}
else if "$est" == "cleanfull" {
	global dataset = "$prepdata/stacked_cat_data_cleanfull.dta"
}

use "$dataset", clear

** REDEFINE WEIGHTS
capt drop __*
tempvar y w1 w2
bysort leaid (year): egen `y' = min(year)
replace `y' = 2000 if `y' < 2000
bysort leaid (year): gen `w1' = test_enroll if year == `y'
bysort leaid (year): gen `w2' = enroll if year == `y'
drop enroll test_enroll
bysort leaid: egen test_enroll = max(`w1')
bysort leaid: egen enroll = max(`w2')

tempfile data
save `data', replace

********************************************************************************
***** 			1.0 LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************

** save dataset to be used to store coefficients
clear
set obs 1
gen categ = ""
save "$prepdata/coarsecat_estimates_$est.dta", replace


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
		global Ek = "$Ek Ek_`n'"
		global Mk = "$Mk Mk_`n'"
		}
	drop cat
	drop holdbond margin*
	sort leaid year
	capt drop __*
	merge 1:m leaid year using `data', gen(_m) keep(3)
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
	lincom (Dk1 + Dk2)/2
	gen coef_test_1_2 = `r(estimate)' in 1
	gen ub_test_1_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_1_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4)/2
	gen coef_test_3_4 = `r(estimate)' in 1
	gen ub_test_3_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_3_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk5 + Dk6)/2
	gen coef_test_5_6 = `r(estimate)' in 1
	gen ub_test_5_6 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_5_6 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk7 + Dk8)/2
	gen coef_test_7_8 = `r(estimate)' in 1
	gen ub_test_7_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_7_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_test_9_10 = `r(estimate)' in 1
	gen ub_test_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_test_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef_test*
	drop if categ == ""
	append using "$prepdata/coarsecat_estimates_$est.dta"
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_$est.dta", replace
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
	lincom (Dk1 + Dk2)/2
	gen coef_cap_1_2 = `r(estimate)' in 1
	gen ub_cap_1_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_1_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4)/2
	gen coef_cap_3_4 = `r(estimate)' in 1
	gen ub_cap_3_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_3_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk5 + Dk6)/2
	gen coef_cap_5_6 = `r(estimate)' in 1
	gen ub_cap_5_6 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_5_6 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk7 + Dk8)/2
	gen coef_cap_7_8 = `r(estimate)' in 1
	gen ub_cap_7_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_7_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_cap_9_10 = `r(estimate)' in 1
	gen ub_cap_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_cap_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_$est.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_$est.dta", replace
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
	lincom (Dk1 + Dk2)/2
	gen coef_hpi_1_2 = `r(estimate)' in 1
	gen ub_hpi_1_2 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_1_2 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk3 + Dk4)/2
	gen coef_hpi_3_4 = `r(estimate)' in 1
	gen ub_hpi_3_4 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_3_4 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk5 + Dk6)/2
	gen coef_hpi_5_6 = `r(estimate)' in 1
	gen ub_hpi_5_6 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_5_6 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk7 + Dk8)/2
	gen coef_hpi_7_8 = `r(estimate)' in 1
	gen ub_hpi_7_8 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_7_8 = `r(estimate)' - 1.65 * `r(se)' in 1 
	lincom (Dk9 + Dk10)/2
	gen coef_hpi_9_10 = `r(estimate)' in 1
	gen ub_hpi_9_10 = `r(estimate)' + 1.65 * `r(se)' in 1 
	gen lb_hpi_9_10 = `r(estimate)' - 1.65 * `r(se)' in 1 
	
	
	gen categ = "`cat'" in 1
	keep categ lb* ub* coef_hpi*
	drop if categ == ""
	sort categ
	merge 1:1 categ using "$prepdata/coarsecat_estimates_$est.dta", nogen
	drop if categ == ""
	save "$prepdata/coarsecat_estimates_$est.dta", replace
}


***** Build figures

use "$prepdata/coarsecat_estimates_$est.dta", clear


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
		,  xlabel(1 "HVAC" 2 "STEM" 3 "Safety/health"  4 "Plumbing, roofs, furnaces"  5 "Classrooms" 6 "Athletics"  7 "Transportation" 8 "Land purchases", angle(45) labsize(small))  ///
		ylabel(-0.2(0.1)0.5) ylabel(-20(10)50, axis(2)) legend(ring(0) pos(11.5) order(2 "Test scores" 4 "House price index")) xtitle(" ") ///
		ytitle("Effect on test scores (sd)") ytitle("Effect on house price index (%)", axis(2))
graph export "$outdir/effects_cat_stacked_$est.png", replace


twoway	(bar coef_cap_1_5 n, barwidth(0.4)  color("$yg")) (rcap ub_cap_1_5 lb_cap_1_5 n,  color("$yaleblue % 50"))  ///
		,  xlabel(1 "HVAC" 2 "STEM" 3 "Safety/health"  4 "Plumbing, roofs, furnaces"  5 "Classrooms" 6 "Athletics"  7 "Transportation" 8 "Land purchases", angle(45) labsize(small))  ///
		 legend(off) xtitle(" ") ///
		ytitle("Effect on cumulative cap. spending ($)") 
graph export "$outdir/effects_cat_stacked_cap_$est.png", replace

	
if "$est" == "main" {

	
*** Year- specific estimates
 
** Capital spending
preserve
capt drop n
egen n = group(categ)
keep *_cap_* n categ
foreach var in coef_cap ub_cap lb_cap  {
	gen `var'_pre_1 = 0
}


rename *_cap_pre_5_4 *_cap0
rename *_cap_pre_3_2 *_cap1
rename *_cap_pre_1 *_cap2
rename *_cap_1_2 *_cap3
rename *_cap_3_4 *_cap4
rename *_cap_5_6 *_cap5
rename *_cap_7_8 *_cap6
rename *_cap_9_10 *_cap7

drop *_cap_*

reshape long coef_cap ub_cap lb_cap, i(n) j(time)
gen n2 = time + 0.1
gen n3 = time + 0.2
gen n4 = time + 0.3
gen n5 = time + 0.4


twoway	(connected coef_cap time if categ == "hvac", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_cap lb_cap time if categ == "hvac", color("$yaleblue % 30")) ///
		(connected coef_cap n2 if categ == "infra", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_cap lb_cap n2 if categ == "infra", color("$ylb % 30")) ///
		(connected coef_cap n3 if categ == "safeall", lw(medthick) ms(triangle) color("$yo")) (rcap ub_cap lb_cap n3 if categ == "safeall", color("$yo % 30")) ///
		(connected coef_cap n4 if categ == "stem", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_cap lb_cap n4 if categ == "stem", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "HVAC" 3 "Plumbing, roofs, furnaces" 5 "Safety/health" 7 "STEM")) xline(2.2) ytitle("Effect on capital spending ($)") ylabel(-1000(500)2000) xtitle("Time since election") yline(0)  xsize(5)
graph export "$outdir/effects_cap_1_$est.png", replace

		
twoway	(connected coef_cap time if categ == "class", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_cap lb_cap time if categ == "class", color("$yaleblue % 30")) ///
		(connected coef_cap n2 if categ == "athletic", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_cap lb_cap n2 if categ == "athletic", color("$ylb % 30")) ///
		(connected coef_cap n3 if categ == "landpurch", lw(medthick) ms(triangle) color("$yo")) (rcap ub_cap lb_cap n3 if categ == "landpurch", color("$yo % 30")) ///
		(connected coef_cap n4 if categ == "busvehicle", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_cap lb_cap n4 if categ == "busvehicle", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "Classroom" 3 "Athletic" 5 "Land purchases" 7 "Transportation")) xline(2.2) ytitle("Effect on capital spending ($)")  ylabel(-1000(500)2000) xtitle("Time since election") yline(0) xsize(5)
graph export "$outdir/effects_cap_2_$est.png", replace
restore

** Test scores
preserve
capt drop n
capt drop n*
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

keep *_test_* n categ
foreach var in coef_test ub_test lb_test coef_hpi ub_hpi lb_hpi {
	gen `var'_pre_1 = 0
}

rename *_test_pre_5_4 *_test0
rename *_test_pre_3_2 *_test1
rename *_test_pre_1 *_test2
rename *_test_1_2 *_test3
rename *_test_3_4 *_test4
rename *_test_5_6 *_test5
rename *_test_7_8 *_test6
rename *_test_9_10 *_test7

drop *_test_*
reshape long coef_test ub_test lb_test, i(n) j(time)
gen n2 = time + 0.1
gen n3 = time + 0.2
gen n4 = time + 0.3
gen n5 = time + 0.4


twoway	(connected coef_test time if categ == "hvac", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_test lb_test time if categ == "hvac", color("$yaleblue % 30")) ///
		(connected coef_test n2 if categ == "infra", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_test lb_test n2 if categ == "infra", color("$ylb % 30")) ///
		(connected coef_test n3 if categ == "safeall", lw(medthick) ms(triangle) color("$yo")) (rcap ub_test lb_test n3 if categ == "safeall", color("$yo % 30")) ///
		(connected coef_test n4 if categ == "stem", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_test lb_test n4 if categ == "stem", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "HVAC" 3 "Other infr" 5 "Safety/health" 7 "STEM")) xline(2.2) ytitle("Effect on test scores") ylabel(-0.4(0.2)0.6) xtitle("Time since election") yline(0)  xsize(5)
graph export "$outdir/effects_test_1_$est.png", replace

		
twoway	(connected coef_test time if categ == "class", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_test lb_test time if categ == "class", color("$yaleblue % 30")) ///
		(connected coef_test n2 if categ == "athletic", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_test lb_test n2 if categ == "athletic", color("$ylb % 30")) ///
		(connected coef_test n3 if categ == "landpurch", lw(medthick) ms(triangle) color("$yo")) (rcap ub_test lb_test n3 if categ == "landpurch", color("$yo % 30")) ///
		(connected coef_test n4 if categ == "busvehicle", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_test lb_test n4 if categ == "busvehicle", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "Classroom" 3 "Athletic" 5 "Land purchases" 7 "Transportation")) xline(2.2) ytitle("Effect on test scores") ylabel(-0.4(0.2)0.6) xtitle("Time since election") yline(0) xsize(5)
graph export "$outdir/effects_test_2_$est.png", replace

restore


** House prices
preserve
capt drop n
egen n = group(categ)
keep *_hpi_* n categ
foreach var in coef_hpi ub_hpi  {
	gen `var'_pre_1 = 0
}
rename *_hpi_pre_5_4 *_hpi0
rename *_hpi_pre_3_2 *_hpi1
rename *_hpi_pre_1 *_hpi2
rename *_hpi_1_2 *_hpi3
rename *_hpi_3_4 *_hpi4
rename *_hpi_5_6 *_hpi5
rename *_hpi_7_8 *_hpi6
rename *_hpi_9_10 *_hpi7


drop *_hpi_*
reshape long coef_hpi ub_hpi lb_hpi, i(n) j(time)
gen n2 = time + 0.1
gen n3 = time + 0.2
gen n4 = time + 0.3
gen n5 = time + 0.4


twoway	(connected coef_hpi time if categ == "hvac", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_hpi lb_hpi time if categ == "hvac", color("$yaleblue % 30")) ///
		(connected coef_hpi n2 if categ == "infra", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_hpi lb_hpi n2 if categ == "infra", color("$ylb % 30")) ///
		(connected coef_hpi n3 if categ == "safeall", lw(medthick) ms(triangle) color("$yo")) (rcap ub_hpi lb_hpi n3 if categ == "safeall", color("$yo % 30")) ///
		(connected coef_hpi n4 if categ == "stem", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_hpi lb_hpi n4 if categ == "stem", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "HVAC" 3 "Other infr" 5 "Safety/health" 7 "STEM")) xline(2.2) ytitle("Effect on house prices") ylabel(-50(10)40) xtitle("Time since election") yline(0)  xsize(5)
graph export "$outdir/effects_hpi_1_$est.png", replace

		
twoway	(connected coef_hpi time if categ == "class", lw(medthick) ms(circle) color("$yaleblue")) (rcap ub_hpi lb_hpi time if categ == "class", color("$yaleblue % 30")) ///
		(connected coef_hpi n2 if categ == "athletic", lw(medthick) ms(square) lp(shortdash) color("$ylb")) (rcap ub_hpi lb_hpi n2 if categ == "athletic", color("$ylb % 30")) ///
		(connected coef_hpi n3 if categ == "landpurch", lw(medthick) ms(triangle) color("$yo")) (rcap ub_hpi lb_hpi n3 if categ == "landpurch", color("$yo % 30")) ///
		(connected coef_hpi n4 if categ == "busvehicle", lp(dash_dot) lw(medthick) ms(diamond) color("$yg")) (rcap ub_hpi lb_hpi n4 if categ == "busvehicle", color("$yg % 30")) ///
	, xlabel(0 "-5 to -4" 1 "-3 to -2" 2 "-1 to 0" 3 "1 to 2" 4 "3 to 4" 5 "5 to 6" 6 "7 to 8" 7 "9 to 10") legend(ring(0) pos(11) order(1 "Classroom" 3 "Athletic" 5 "Land purchases" 7 "Transportation")) xline(2.2) ytitle("Effect on house prices") ylabel(-50(10)50) xtitle("Time since election") yline(0) xsize(5)
graph export "$outdir/effects_hpi_2_$est.png", replace

restore

}

}

 /*

district_specific_effects_test.do 
			
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


** Useful globals
global D_lag = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 D_1 "
global D_lead = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"




********************************************************************************

** Select right stacked dataset

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
	
* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25


preserve
keep leaid year
duplicates drop
sort leaid year
tempfile tag
save `tag', replace
restore


sort leaid year
merge m:1 leaid year using  "$prepdata/demographics.dta", keep(1 3) nogen
preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore
merge m:1 leaid year using  `temp', keep(1 3) nogen



********************************************************************************
***** 			Estimate cohort-specific effects		 		***************
********************************************************************************




*---> Fix specification you want to run:

global model = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead"
global model2 = 		"K_6 K_5 K5 K10 K11 $E_lead  $E_lag  $M_lag $M_lead"
global model2_ = 		"i.cohort#c.K_6 i.cohort#c.K_5 i.cohort#c.K5 i.cohort#c.K10 i.cohort#c.K11 $E_lead  $E_lag  $M_lag $M_lead"
global model2_d = 		"K_6 K_5 c.K5 i.leaid#c.K10 c.K11 $E_lead  $E_lag  $M_lag $M_lead"
global model3 = 		"$D_lag_C zero $D_lead_C $E_lead  $E_lag  $M_lag $M_lead"
global FE = 		"leaid#cohort cohort#fips#year"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"

gen K_6 = 0
forvalues n = 22(-1)6 {
	replace K_6 = K_6 + 1 if D_`n' == 1
}

gen K_5 = 0
forvalues n = 5(-1)1 {
	replace K_5 = K_5 + 1 if D_`n' == 1
}

gen K5 = 0
forvalues n = 1(1)5 {
	replace K5 = K5 + 1 if D`n' == 1
}

gen K10 = 0
forvalues n = 6(1)10 {
	replace K10 = K10 + 1 if D`n' == 1
}

gen K11 = 0
forvalues n = 11(1)22 {
	replace K11 = K11 + 1 if D`n' == 1
}



* Effect on main test scores
reghdfe scale_score $model2_d [aw = test_enroll], a($FE_test) 

preserve
matrix A = e(b)'
svmat A
replace A1 = . if A1 == 0

local n = 1
gen district_code = ""
foreach name in `e(indepvars)' {
	replace district_code = "`name'" in `n'
	local n = `n' + 1
}
keep if regexm(district_code,"leaid#c")
replace district_code = subinstr(district_code,"bn.leaid#c.K10","",1)
destring district_code, replace force
keep if district_code != .
sort district_code
save "$prepdata/testeffect_distr_main.dta", replace
restore

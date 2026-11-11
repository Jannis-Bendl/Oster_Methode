/*

iv_hpi_threesteps_stacked_cap_boot.do 

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

use "$prepdata/dist_enroll_demo.dta", clear
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
rename year fy
merge m:1 leaid fy using  `demo'
drop if _m == 2
drop _m
rename fy year

sort leaid year
merge m:1 leaid year using `temp'
drop if _m == 2
drop _m

capt drop __*

** Useful globals
global D_lag = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 "
global D_lead = "D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2"
global D_lead_small = "D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1 El0"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"


** Program to tabulate effects
program define effects
args name var
local t = invttail(`e(df_r)', .025)
	
global N_`name': di %9.0fc e(N)
global r2_`name': di %6.3fc e(r2_a)

global b_`name': di %6.3fc _b[`var']
global disc_`name': di %6.3fc _b[`var'] * 2.8
//global se_`name': di %6.3fc _se[`var']
global p_`name': di %12.2fc (2 * ttail(`e(df_r)', abs(_b[`var']/_se[`var'])))
global star_`name' = cond(${p_`name'} < 0.01, "***",cond(${p_`name'} < 0.05,"**",cond(${p_`name'} < 0.1,"*","")))

end



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




* prepare bond data
preserve
use "$prepdata/bond_cat_amt_clean.dta", clear
keep leaid year amount
tempfile bonds
save `bonds'
restore

* bond sizes
merge m:1 leaid year using `bonds'
drop if _merge == 2
drop _merge

gen amount_pp = (amount / enroll)

* winsorize amount_pp at top 1% and 99%
winsor2 amount_pp, replace
replace amount_pp = amount_pp / 1000



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
bysort leaid cohort: egen capter_med = median(`capter_med')
tempvar cap_abovemed
gen `cap_abovemed' = M2 if time == -1
bysort leaid cohort: egen cap_abovemed = median(`cap_abovemed')
drop time


drop scale_score test_enroll subject grade
duplicates drop
capt drop _est*

sort leaid year
merge m:1  leaid year using "$prepdata/hpi.dta"
drop if _m == 2
drop _m

replace amount_pp = 0 if pass == 0 | holdbond == 0




********************************************************************************
***** 							Mean effects		  	 		 ***************
********************************************************************************

preserve
clear
set obs 300
gen iteration = _n

foreach type in base sesB sesT minB minT capL capH {
gen se_`type' = .
}
sort iter
save "$prepdata/boot_hpi_cap.dta", replace
restore


egen tag = tag(leaid year cohort)
tempfile main
save `main', replace



*** BOOTSTRAP STANDARD ERRORS

local iter = 1
quietly while `iter' < 101 {
noisily disp "Iteration nr. `iter'"
use `main', clear
bsample, cluster(leaid cohort)

*---------> Estimate first stage
reghdfe cap $D_lag zero $D_lead $E_lag $E_lead $M_lag $M_lead if tag == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
predict caph

*---------> Cumulate predictions
preserve
keep leaid year cohort caph
duplicates drop
egen id = group(leaid cohort)
tsset id year
replace caph = caph / 1000
gen Lcap = l.caph
forvalues n = 2/10 {
	gen L`n'cap = l`n'.caph
}
egen cap_1_10 = rowtotal(Lcap L2cap L3cap L4cap L5cap L6cap L7cap L8cap L9cap L10cap)

drop id
sort leaid cohort year
tempfile temp
save `temp', replace
restore
merge m:1 leaid cohort year using  `temp', nogen

*---------> Estimate second stage

local var = "cap_1_10"

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar Lbase = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if lowsesB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LsesB = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if lowsesT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LsesT = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if minorB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LminB = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if minorT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LminT = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if cap_abo == 0 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LcapL = _b[`var']

reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if cap_abo == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
scalar LcapH = _b[`var']

use "$prepdata/boot_hpi_cap.dta", clear

foreach type in base sesB sesT minB minT capL capH {
replace se_`type' = L`type' if iter == `iter'
}
sort iter
save "$prepdata/boot_hpi_cap.dta", replace
local iter = `iter' + 1 
}

preserve
use "$prepdata/boot_hpi_cap.dta", clear
list
foreach type in base sesB sesT minB minT capL capH {
sum se_`type', det
global se_`type': di %6.3fc r(sd)
}
restore

*** OBTAIN MAIN ESTIMATES & PLOT/TABULATE

use `main', clear

********************************************************************************
***** 							Mean effects		  	 		 ***************
********************************************************************************


*---------> Estimate first stage



reghdfe cap $D_lag zero $D_lead $E_lag  $E_lead $M_lag  $M_lead  [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid) 
predict caph


*---------> Cumulate predictions
preserve
keep leaid year cohort caph
duplicates drop
egen id = group(leaid cohort)
tsset id year
replace caph = caph / 1000
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
sort leaid cohort year
tempfile temp
save `temp', replace
restore
merge m:1 leaid cohort year using  `temp', nogen

*---------> Estimate second stage

local var = "cap_1_10"

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects base `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if lowsesB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects sesB `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if lowsesT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects sesT `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if minorB == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects minB `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if minorT == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects minT `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if cap_abo == 0 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects capL `var'
disp _b[`var']
disp _se[`var']

qui reghdfe hpi `var' $E_lag $M_lag $E_lead $M_lead  if cap_abo == 1 [aw = enroll], a(leaid#cohort fips#year#cohort) cl(leaid)
effects capH `var'
disp _b[`var']
disp _se[`var']


** Build table: HPI
texdoc init  "$tables/iv_hpi_cap_boot.tex", replace force
tex   & & \multicolumn{2}{c}{Share low SES} & \multicolumn{2}{c}{Share minority} & \multicolumn{2}{c}{Capital stock}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6} \cmidrule(lr){7-8} 
tex Sample: & All & Low  & High & Low & High  & High & Low  \\ \cmidrule(lr){2-2}  \cmidrule(lr){3-3} \cmidrule(lr){4-4} \cmidrule(lr){5-5} \cmidrule(lr){6-6} \cmidrule(lr){7-7} \cmidrule(lr){8-8}
tex  & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\
tex Cap spending (\textdollar 1,000) & ${b_base}${star_base}  & ${b_sesB}${star_sesB}  & ${b_sesT}${star_sesT} & ${b_minB}${star_minB}  & ${b_minT}${star_minT}  &  ${b_capH}${star_capH}  & ${b_capL}${star_capL} \\
tex			& (${se_base}) & (${se_sesB})& (${se_sesT}) & (${se_minB})  & (${se_minT}) & (${se_capH}) & (${se_capL})  \\
tex w/depreciation 		 & $disc_base & $disc_sesB  & $disc_sesT & $disc_minB & $disc_minT & $disc_capH  & $disc_capL \\\hline
tex District FE & X & X & X  & X  & X  & X & X \\ 
tex Yr-St-Gr-Subj FE & X & X & X  & X  & X  & X & X \\ 
tex N 		 & $N_base & $N_sesB  & $N_sesT & $N_minB & $N_minT & $N_capH  & $N_capL    
texdoc close

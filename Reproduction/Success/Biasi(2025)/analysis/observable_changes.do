 /*

observable_changes.do 

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


*******************************************************************************
***** 			 				Load data				 		***************
*******************************************************************************

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


merge m:1 leaid year using  "$prepdata/demographics.dta", keep(1 3) nogen
merge m:1 leaid year using  "$prepdata/hpi.dta", keep(1 3) nogen
preserve
use "$prepdata/nhgis.dta", clear
keep leaid year young educcol electorate hhinc shprivate
sort leaid year
tempfile temp
save `temp', replace
restore
merge m:1 leaid year using  `temp', keep(1 3) nogen

replace electorate = ln(electorate)

********************************************************************************
***** 			 		Changes in observables			 		***************
********************************************************************************


*---> Fix specification you want to run:
keep leaid year cohort fips $D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead lnenr white black hisp asian frpl poor shprivate sped el teachers young educcol electorate hhinc enroll
duplicates drop
isid leaid year cohort
global model = 		"$D_lag zero $D_lead $E_lead  $E_lag  $M_lag $M_lead"
global FE = 		"leaid#cohort cohort#fips#year"

gen lnenr = ln(enroll)


* Demographic variables to consider
gen old = 1 - young
local demvars = "black hisp asian frpl poor shprivate sped el teachers old educcol electorate hhinc" 

foreach d of local demvars {
eststo S_`d': reghdfe `d' $model [aw = enroll], a($FE) cluster(leaid)
if "`d'" == "lnenr" local ylabel = "ln(Enrollment)"
if "`d'" == "white" local ylabel = "Share White students"
if "`d'" == "black" local ylabel = "Share Black students"
if "`d'" == "hisp" local ylabel = "Share Hispanic students"
if "`d'" == "asian" local ylabel = "Share Asian students"
if "`d'" == "frpl" local ylabel = "Share FRPL students"
if "`d'" == "poor" local ylabel = "Share people age 5-17 below poverty"
if "`d'" == "shprivate" local ylabel = "Private school enrollment"
if "`d'" == "sped" local ylabel = "Share Special Education students"
if "`d'" == "el" local ylabel = "Share English-Learner students"
if "`d'" == "teachers" local ylabel = "Student-teacher ratio"
if "`d'" == "old" local ylabel = "Share citizens 18 and above"
if "`d'" == "educcol" local ylabel = "Share citizens w/college degree"
if "`d'" == "electorate" local ylabel = "ln(citizens above 18)"
if "`d'" == "hhinc" local ylabel = "Average household income ($1,000)"

if "`d'" == "white" local yscale = "-0.01(0.01)0.03"
if "`d'" == "black" local yscale = "-0.01(0.01)0.03"
if "`d'" == "hisp" local yscale = "-0.03(0.01)0.01"
if "`d'" == "asian" local yscale = "-0.01(0.01)0.03"
if "`d'" == "frpl" local yscale = "-0.06(0.02)0.02"
if "`d'" == "poor" local yscale = "-0.03(0.01)0.01"
if "`d'" == "shprivate" local yscale = "-0.01(0.005)0.01"
if "`d'" == "sped" local yscale = "-0.01(0.005)0.01"
if "`d'" == "el" local yscale = "-0.06(0.02)0.02"
if "`d'" == "teachers" local yscale = "-1(0.5)1"
if "`d'" == "old" local yscale = "-0.01(0.005)0.01"
if "`d'" == "educcol" local yscale = "-0.01(0.005)0.01"
if "`d'" == "electorate" local yscale = "-0.1(0.05)0.1"
if "`d'" == "hhinc" local yscale = "-3(1)3"

if "`d'" != "lnenr" & "`d'" != "electorate" {
qui sum `d'
local mean: di %3.2f `r(mean)'

coefplot	(S_`d',  lcolor("$ylb") mcolor("$ylb") lw(thick) recast(connect) ciopts(recast(rcap) lc("$ylb"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) ///
			xline(6.5, lc(red)) level(90) legend(off) ///
			ytitle("`ylabel'") title("`ylabel' (mean = `mean')", size(vlarge)) ylabel(`yscale') xtitle("Time since bond passage") 
	graph export "$outdir/demchange_`d'.png", replace			
}


if "`d'" == "lnenr" | "`d'" == "electorate" {

coefplot	(S_`d',  lcolor("$ylb") mcolor("$ylb") lw(thick) recast(connect) ciopts(recast(rcap) lc("$ylb"))) ///
			, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) ///
			xline(6.5, lc(red)) level(90) legend(off) ///
			ytitle("`ylabel'") title("`ylabel'", size(vlarge)) ylabel(`yscale') xtitle("Time since bond passage") 
graph export "$outdir/demchange_`d'.png", replace			
}
			
}

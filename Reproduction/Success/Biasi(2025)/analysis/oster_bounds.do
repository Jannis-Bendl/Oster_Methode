 /*

oster_bounds.do 
		
*/


clear 
program drop _all
capture log close
set more off 

* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global yg = "94 112 45"
global ylight = "217 233 242" 
global graph = "xlabel(,grid glp(dot) glc(gs10) tlc(gs10)) ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"
global graphbar = "ylabel(,grid glp(dot) glc(gs10) tlc(gs10)) plotregion(lp(blank))"




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
global D_lag_C = "D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 i.cohort#D_5 i.cohort#D_4 i.cohort#D_3 i.cohort#D_2 i.cohort#D_1"
global D_lead_C = " i.cohort#D1 i.cohort#D2 i.cohort#D3 i.cohort#D4 i.cohort#D5 i.cohort#D6 i.cohort#D7 i.cohort#D8 i.cohort#D9 i.cohort#D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22"
global E_lag_small = "         El1 El2 El3 El4 El5 El6 El7 El8 El9 El10"
global E_lead_small = "Ef5 Ef4 Ef3 Ef2 Ef1"
global M_lag = "Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1 Ml0"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22"
global Md_lag = "Mld22 Mld21 Mld20 Mld19 Mld18 Mld17 Mld16 Mld15 Mld14 Mld13 Mld12 Mld11 Mld10 Mld9 Mld8 Mld7 Mld6 Mld5 Mld4 Mld3 Mld2 Mld1 Mld0"
global Md_lead = "Mfd1 Mfd2 Mfd3 Mfd4 Mfd5 Mfd6 Mfd7 Mfd8 Mfd9 Mfd10 Mfd11 Mfd12 Mfd13 Mfd14 Mfd15 Mfd16 Mfd17 Mfd18 Mfd19 Mfd20 Mfd21 Mfd22"
global M2_lag = "M2l22 M2l21 M2l20 M2l19 M2l18 M2l17 M2l16 M2l15 M2l14 M2l13 M2l12 M2l11 M2l10 M2l9 M2l8 M2l7 M2l6 M2l5 M2l4 M2l3 M2l2 M2l1 M2l0"
global M2_lead = "M2f1 M2f2 M2f3 M2f4 M2f5 M2f6 M2f7 M2f8 M2f9 M2f10 M2f11 M2f12 M2f13 M2f14 M2f15 M2f16 M2f17 M2f18 M2f19 M2f20 M2f21 M2f22"
global Md2_lag = "M2ld22 M2ld21 M2ld20 M2ld19 M2ld18 M2ld17 M2ld16 M2ld15 M2ld14 M2ld13 M2ld12 M2ld11 M2ld10 M2ld9 M2ld8 M2ld7 M2ld6 M2ld5 M2ld4 M2ld3 M2ld2 M2ld1 M2ld0"
global Md2_lead = "M2fd1 M2fd2 M2fd3 M2fd4 M2fd5 M2fd6 M2fd7 M2fd8 M2fd9 M2fd10 M2fd11 M2fd12 M2fd13 M2fd14 M2fd15 M2fd16 M2fd17 M2fd18 M2fd19 M2fd20 M2fd21 M2fd22"

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
	
* Keep only states with OK density
gen okdens1 = 1 if fips != 5 & fips != 29 
gen okdens2 = 1 if fips != 5 & fips != 29 & fips != 53
gen okdens3 = 1 if fips != 5 & fips != 29 & fips != 40 
gen okdens4 = 1 if fips != 5 & fips != 29 & fips != 40 & fips != 53
gen okdens5 = 1 if fips != 5 & fips != 28 & fips != 29 & fips != 40 & fips != 53
gen okdens6 = 1 if fips != 5 & fips != 28 & fips != 29 & fips != 40 
gen okdens7 = 1 if fips != 29 & fips != 53 & fips != 40 

keep if okdens7 == 1 & fips != 25


preserve
keep leaid year
duplicates drop
sort leaid year
tempfile tag
save `tag', replace
restore


preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore


merge m:1 leaid year using  "$prepdata/demographics.dta", keep(1 3) nogen
merge m:1 leaid year using  "$prepdata/hpi.dta", keep(1 3) nogen
merge m:1 leaid year using `temp', keep(1 3) nogen


********************************************************************************
***** 		Estimate main equation (grouping dummies for simplicity)	***************
********************************************************************************


* Demographic variables to include in the index
local demvars = "black asian frpl poor shprivate el sped teacher" 
global dem = ""
global demH = ""
foreach d of local demvars {
	global dem = "$dem `d'" // `d'#i.grade#i.subject"
	global demH = "$demH `d'" // c.`d'#c.`d'"
}


*---> Cumulate effects

gen K_6 = 0
forvalues n = 22(-1)6 {
	replace K_6 = K_6 + 1 if D_`n' == 1
}

gen K_5 = 0
forvalues n = 5(-1)1 {
	replace K_5 = K_5 + 1 if D_`n' == 1
}

gen K2 = 0
forvalues n = 1(1)2 {
	replace K2 = K2 + 1 if D`n' == 1
}

gen K8 = 0
forvalues n = 3(1)8 {
	replace K8 = K8 + 1 if D`n' == 1
}

gen K9 = 0
forvalues n = 9(1)22 {
	replace K9 =  K9 + 1 if D`n' == 1
}


*---> Fix specification you want to run:

global model = 		"K_6 K_5 K2 K8 K9 $E_lead  $E_lag  $M_lag $M_lead"
//global model = 		"K8 $E_lead  $E_lag  $M_lag $M_lead"
global model_ = 		"Kall K11 $E_lead  $E_lag  $M_lag $M_lead"
global FE = 		"leaid#cohort cohort#fips#year"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"


********************** TEST SCORES **********************

* Generate maximum possible R2
preserve
keep leaid subject grade scale_score test_enroll year fips
duplicates drop
reg *
keep if e(sample)
egen fakeid = group(leaid subject grade)
tsset fakeid year
reghdfe scale_score l.scale_score [aw = test_enroll], a(subject#grade fips#year)
global Rmax = `e(r2)'
restore

* fix sample
qui reghdfe scale_score $model $dem [aw = test_enroll], a($FE_test) 
gen sampleT = e(sample)

*---> Model w/5 groups of dummies
* "Not" model (no covariates)
qui reghdfe scale_score $model if sampleT == 1 [aw = test_enroll], a($FE_test) 
global r2_not = `e(r2)'
global b8_not = _b[K8]

* "Tilde" model (w/ covariates)
qui reghdfe scale_score $model $dem [aw = test_enroll], a($FE_test) 
global r2_tilde = `e(r2)'
global b8_tilde = _b[K8]

/* The following was just a short script to make sure our algorithm delivers the same results as the command psacalc
qui reg scale_score K8 $dem [aw = test_enroll]
qui reg scale_score K8 if e(sample) [aw = test_enroll]
global r2_not = `e(r2)'
global b8_not = _b[K8]

qui reg scale_score K8 $dem [aw = test_enroll]
global r2_tilde = `e(r2)'
global b8_tilde = _b[K8]

psacalc beta K8 // , mcontrol($E_lead  $E_lag  $M_lag $M_lead)

disp "uncontrolled" 
disp $b8_not
disp "controlled" 
disp $b8_tilde

	disp "Bias-adjusted 5 year effect is"
	disp $b8_tilde - 1 * ($b8_not - $b8_tilde) * (1 - $r2_tilde)/($r2_tilde - $r2_not)
	*/
	
	
* Fix delta
global delta = 1

* Assuming various levels of Rmax
local f = ($r2_tilde - $r2_not)
local f1 = $r2_tilde + (0.5 * `f')
local f2 = $r2_tilde + (1 * `f')
local f3 = $r2_tilde + (1.5 * `f')

disp "Main effect is $b5_not"
foreach r in `f1' `f2' `f3' 1 {
	disp "Rmax is `r'"
	disp "Bias-adjusted 5 year effect is"
	disp $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`r' - $r2_tilde)/($r2_tilde - $r2_not)
}

* save globals

global Tcoef : disp %9.3f $b8_tilde 

local f = ($r2_tilde - $r2_not)
local f1 = $r2_tilde + (0.8 * `f')
local f2 = $r2_tilde + (1 * `f')
local f3 = $r2_tilde + (1.2 * `f')

global delta = 1

global Tbound1_1 : disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound2_1 : disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound3_1 : disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound4_1 : disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global Rmax_C_1:  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)

global delta = 0.8

* save globals
global Tbound1_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound2_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound3_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound4_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global Rmax_C_0:  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)


global delta = 1.2

* save globals
global Tbound1_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound2_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound3_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Tbound4_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global Rmax_C_15:  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)






********************** HOUSE PRICES **********************


* Generate maximum possible R2
preserve
keep leaid hpi enroll year fips
duplicates drop
reg *
keep if e(sample)
tsset leaid year
reghdfe hpi l.hpi [aw = enroll], a(fips year)
global Rmax = `e(r2)'
restore


preserve
drop scale_score subject grade test_enroll
duplicates drop

* Fix sample
qui reghdfe hpi $model $dem [aw = enroll], a($FE) 
gen sampleH = e(sample)

*---> Model w/5 groups of dummies
* "Not" model (no covariates)
qui reghdfe hpi $model if sampleH == 1 [aw = enroll], a($FE) 
global r2_not = `e(r2)'
global b8_not = _b[K8]


* "Tilde" model (w/ covariates)
qui reghdfe hpi $model $dem [aw = enroll], a($FE) 
global r2_tilde = `e(r2)'
global b8_tilde = _b[K8]


* Fix delta
global delta = 1


* Assuming various levels of Rmax
local f = ($r2_tilde - $r2_not)
local f1 = $r2_tilde + (0.8 * `f')
local f2 = $r2_tilde + (1 * `f')
local f2 = $r2_tilde + (1.2 * `f')

disp "Main effect is $b5_not"
foreach r in `f1' `f2' `f3' 1 {
	disp "Rmax is `r'"
	disp "Bias-adjusted 5 year effect is"
	disp $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`r' - $r2_tilde)/($r2_tilde - $r2_not)
}


restore


* save globals


local f = ($r2_tilde - $r2_not)
local f1 = $r2_tilde + (0.5 * `f')
local f2 = $r2_tilde + (1 * `f')
local f3 = $r2_tilde + (1.5 * `f')

global Hcoef : disp %9.3f $b8_tilde 


global Hbound1_1 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound2_1 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound3_1 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound4_1 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global RmaxH_C_1:  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)

global delta = 0.8

* save globals
global Hbound1_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound2_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound3_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound4_0 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global RmaxH_C_0:  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)


global delta = 1.2

* save globals
global Hbound1_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f1' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound2_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f2' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound3_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * (`f3' - $r2_tilde)/($r2_tilde - $r2_not)
global Hbound4_15 :  disp %9.3f $b8_tilde - $delta * ($b8_not - $b8_tilde) * ($Rmax - $r2_tilde)/($r2_tilde - $r2_not)
global RmaxH_C_15 :  disp %9.3f $r2_tilde + $delta * $b8_tilde * ($r2_tilde - $r2_not)/($b8_not - $b8_tilde)


texdoc init  "$tables/oster.tex", replace force
tex &		Baseline & \multicolumn{4}{c}{Bounds for $ R_{max}=$ } & max  \\\cmidrule{3-6}
tex 	Coefficient		&	 	&  $ \tilde{R^2} + 0.8(\tilde{R^2} - \dot{R}) $	&  $ \tilde{R^2} + (\tilde{R^2} - \dot{R}) $ &  $ \tilde{R^2} + 1.2(\tilde{R^2} - \dot{R})$ &  $\bar{R}_{max}$ & $ R^{2}$ \\ 
tex & (1) & (2)  & (3)  & (4)  & (5) & (6)\\ \hline	
tex \textbf{$\delta = 0.8$} & & & & & \\
tex Test scores & $Tcoef & $Tbound1_0		& $Tbound2_0 & 	$Tbound3_0 &	$Tbound4_0	 & $Rmax_C_0	\\
tex House prices &	$Hcoef & $Hbound1_0		& $Hbound2_0 & 	$Hbound3_0 &	$Hbound4_0	 & $RmaxH_C_0		\\\hline
tex & & & & \\
tex \textbf{$\delta = 1$} & & & & & \\
tex Test scores & $Tcoef & $Tbound1_1		& $Tbound2_1 & 	$Tbound3_1 &	$Tbound4_1  & $Rmax_C_1	\\
tex House prices	&$Hcoef & $Hbound1_1		& $Hbound2_1 & 	$Hbound3_1 &	$Hbound4_1 & $RmaxH_C_1	\\\hline
tex & & & & \\
tex \textbf{$\delta = 1.2$} & & & & & \\
tex Test scores & $Tcoef & $Tbound1_15	 & $Tbound2_15 & 	$Tbound3_15 &	$Tbound4_15	  & $Rmax_C_15	\\
tex House prices	& $Hcoef & $Hbound1_15 & $Hbound2_15 & 	$Hbound3_15 &	$Hbound4_15	 & $RmaxH_C_15	
texdoc close



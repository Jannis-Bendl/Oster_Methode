 /*

effects_decomposition.do 

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




********************************************************************************
***** 		 Calculate impact of covariates on outcomes			 ***************
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
merge m:1 leaid year using  "$prepdata/hpi.dta", keep(1 3) nogen
merge m:1 leaid year using  `temp', keep(1 3) nogen
merge m:1 leaid year using `tag', keep(3) nogen

* Demographic variables to include in the index
local demvars = " black hisp asian frpl poor shprivate el sped teacher" 
global dem = ""
global demH = ""
foreach d of local demvars {
	global dem = "$dem `d'" // `d'##i.grade##i.subject"
	global demH = "$demH `d'" // c.`d'##c.`d'"
}

capt bysort leaid: egen bondever = max(passbond)


reghdfe scale_score $dem [aw = test_enroll], a(leaid year#fips#grade#subject)
foreach d in $dem {
	scalar define Et_`d' = _b[`d']
}


reghdfe hpi $dem [aw = test_enroll], a(leaid year#fips#grade#subject)
foreach d in $dem {
	scalar define Eh_`d' = _b[`d']
}
restore



********************************************************************************
***** 	 Estimate effects on outcomes and covariates			 ***************
********************************************************************************

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
global FE = 		"leaid#cohort cohort#fips#year"
global FE_test = 	"leaid#cohort subject#grade#fips#year#cohort"
global FE_subj = 	"leaid#cohort grade#fips#year#cohort"

gen tag = grade == 4 & subj == 1
capt drop x
gen x = _n - 6 if _n <= 16

*---> Effects on test scores
gen Tcoef = .
gen Tub = .
gen Tlb = .
reghdfe scale_score $model [aw = test_enroll], a($FE_test) cluster(leaid)
forvalues n = 5(-1)1 {
	replace Tcoef = _b[D_`n'] if x == -`n'
	replace Tub = _b[D_`n'] + 1.65*_se[D_`n'] if x == -`n'
	replace Tlb = _b[D_`n'] - 1.65*_se[D_`n'] if x == -`n'
}

replace Tcoef = 0 if x == 0
replace Tub = 0 if x == 0
replace Tlb = 0 if x == 0

forvalues n = 1(1)10 {
	replace Tcoef = _b[D`n'] if x == `n'
	replace Tub = _b[D`n'] + 1.65*_se[D`n'] if x == `n'
	replace Tlb = _b[D`n'] - 1.65*_se[D`n'] if x == `n'
}



*---> Effects on house prices
gen Thpi = .
gen Thub = .
gen Thlb = .
preserve
capt drop _est*
drop grade subject test_enroll scale_score
duplicates drop
sort leaid year
merge m:1  leaid year using "$prepdata/hpi.dta"
drop if _m == 2
drop _m
reghdfe hpi $model  [aw = enroll], a($FE) cluster(leaid)
restore

forvalues n = 5(-1)1 {
	replace Thpi = _b[D_`n'] if x == -`n'
	replace Thub = _b[D_`n'] + 1.65*_se[D_`n'] if x == -`n'
	replace Thlb = _b[D_`n'] - 1.65*_se[D_`n'] if x == -`n'
}

replace Thpi = 0 if x == 0
replace Thub = 0 if x == 0
replace Thlb = 0 if x == 0

forvalues n = 1(1)10 {
	replace Thpi = _b[D`n'] if x == `n'
	replace Thub = _b[D`n'] + 1.65*_se[D`n'] if x == `n'
	replace Thlb = _b[D`n'] - 1.65*_se[D`n'] if x == `n'
}


*---> Effects on covariates

qui foreach d in $dem {
	noisily disp "`d'"
	reghdfe `d' $model if tag == 1 [aw = test_enroll], a($FE_test) cluster(leaid)
	gen `d'_coef = .
	gen `d'_coefH = .
	forvalues n = 5(-1)1 {
	replace `d'_coef = _b[D_`n'] if x == -`n'
	replace `d'_coefH = `d'_coef * Eh_`d' if x == -`n'
	replace `d'_coef = `d'_coef * Et_`d' if x == -`n'
}

forvalues n = 1(1)10 {
	replace `d'_coef = _b[D`n'] if x == `n'
	replace `d'_coefH = `d'_coef * Eh_`d' if x == `n'
	replace `d'_coef = `d'_coef * Et_`d' if x == `n'
}
}

egen cov_coef = rowtotal(black_coef hisp_coef asian_coef frpl_coef poor_coef shprivate_coef el_coef sped_coef teacher_coef)
egen cov_coef1 = rowtotal(black_coef hisp_coef asian_coef el_coef sped_coef)
egen cov_coef2 = rowtotal(frpl_coef poor_coef)
gen cov_coef3 = shprivate_coef
gen cov_coef4 = teacher_coef

gen cov_coef1a = black_coef
gen cov_coef1b = hisp_coef
gen cov_coef1c = asian_coef
gen cov_coef1d = el_coef
gen cov_coef1e = sped_coef

gen cov_coef2a = frpl_coef
gen cov_coef2b = poor_coef

egen cov_coefH = rowtotal(black_coefH hisp_coefH asian_coefH frpl_coefH poor_coefH shprivate_coefH el_coefH sped_coefH teacher_coefH)
egen cov_coefH1 = rowtotal(black_coefH hisp_coefH asian_coefH el_coefH sped_coefH)
egen cov_coefH2 = rowtotal(frpl_coefH poor_coefH)
gen cov_coefH3 = shprivate_coefH
gen cov_coefH4 = teacher_coefH

gen cov_coefH1a = black_coefH
gen cov_coefH1b = hisp_coefH
gen cov_coefH1c = asian_coefH
gen cov_coefH1d = el_coefH
gen cov_coefH1e = sped_coefH

gen cov_coefH2a = frpl_coefH
gen cov_coefH2b = poor_coefH

*---> Plot effects on test scores
twoway 	(connected Tcoef x, lw(thick) lc("$ylb") mc("$ylb")) (rarea Tub Tlb x, lw(thick) fc("$ylb % 30") lc("$ylb % 10") lw(thin))  ///
		(connected cov_coef x, lw(thin) lp(dash) lc("$yo") mc("$yo")), ///
		ytitle("Effect on test scores") ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") legend(order(1 "Total effect" 3 "Composition effect") pos(11) ring(0)) ylabel(-0.05(0.05)0.15) xline(0.5)
graph export "$outdir/test_sorting_decomp.png", replace


*---> Plot effects on house prices
twoway 	(connected Thpi x, lw(thick) lc("$ylb") mc("$ylb")) (rarea Thub Thlb x, lw(thick) fc("$ylb % 30") lc("$ylb % 10") lw(thin))  ///
		(connected cov_coefH x, lw(thin) lp(dash) lc("$yo") mc("$yo")), ///
		ytitle("Effect on house prices (%)") ytitle("Effect on test scores (sd)") xtitle("Time since bond passage") legend(order(1 "Total effect" 3 "Composition effect") pos(11) ring(0))  xline(0.5)
graph export "$outdir/hpi_sorting_decomp.png", replace



*---> Tabulate effects

* Test scores
su cov_coef if x >= 1 & x <= 10
global cov = `r(mean)'
global cov : di %9.3fc ${cov}
su Tcoef if x >= 5 & x <= 10
global eff = `r(mean)'
global eff : di %9.3fc ${eff}
global covsh = 100 * ${cov}/${eff}
global covsh : di %3.2f  ${covsh}

forvalues n = 1/4 {
	su cov_coef`n' if x >= 1 & x <= 10
	global cov`n' = `r(mean)'
	global cov`n' : di %9.3fc ${cov`n'}
	global covsh`n' = 100 * ${cov`n'}/${eff}
	global covsh`n' : di %3.2f  ${covsh`n'}
}

foreach l in a b c d e {
	su cov_coef1`l' if x >= 1 & x <= 10
	global cov1`l' = `r(mean)'
	global cov1`l' : di %9.3fc ${cov1`l'}
	global covsh1`l' = 100 * ${cov1`l'}/${eff}
	global covsh1`l' : di %3.2f  ${covsh1`l'}
}

foreach l in a b {
	su cov_coef2`l' if x >= 1 & x <= 10
	global cov2`l' = `r(mean)'
	global cov2`l' : di %9.3fc ${cov2`l'}
	global covsh2`l' = 100 * ${cov2`l'}/${eff}
	global covsh2`l' : di %3.2f  ${covsh2`l'}
}


* House prices
su cov_coefH if x >= 1 & x <= 10
global covH = `r(mean)'
global covH : di %9.3fc ${covH}
su Thpi if x >= 5 & x <= 10
global effH = `r(mean)'
global effH : di %9.3fc ${effH}
global covshH = 100 * ${covH}/${effH}
global covshH : di %3.2f  ${covshH}

forvalues n = 1/4 {
	su cov_coefH`n' if x >= 1 & x <= 10
	global covH`n' = `r(mean)'
	global covH`n' : di %9.3fc ${covH`n'}
	global covshH`n' = 100 * ${covH`n'}/${effH}
	global covshH`n' : di %3.2f  ${covshH`n'}
}


foreach l in a b c d e {
	su cov_coefH1`l' if x >= 1 & x <= 10
	global covH1`l' = `r(mean)'
	global covH1`l' : di %9.3fc ${covH1`l'}
	global covshH1`l' = 100 * ${covH1`l'}/${effH}
	global covshH1`l' : di %3.2f  ${covshH1`l'}
}

foreach l in a b {
	su cov_coefH2`l' if x >= 1 & x <= 10
	global covH2`l' = `r(mean)'
	global covH2`l' : di %9.3fc ${covH2`l'}
	global covshH2`l' = 100 * ${covH2`l'}/${effH}
	global covshH2`l' : di %3.2f  ${covshH2`l'}
}


texdoc init  "$tables/effect_cov_decomposition.tex", replace force
tex 					Outcome 	&  Test scores	&  House Prices \\ \cmidrule{2-2}\cmidrule{3-3}
tex & & \\		
tex Main effect	1-10 years post-authorization					&	${eff}		& ${effH}		\\	
tex & & \\\hline
tex \emph{Predicted effect}:		&				& 				\\
tex \emph{Enrollment shares}	&	&	\\
tex Black					& ${cov1a}		& ${covH1a} 		\\
tex									& \textbf{[${covsh1a}\%]}		& \textbf{[${covshH1a}\%]} 		\\
tex Hispanic					& ${cov1b}		& ${covH1b} 		\\
tex									& \textbf{[${covsh1b}\%]}		& \textbf{[${covshH1b}\%]} 		\\
tex Asian					& ${cov1c}		& ${covH1c} 		\\
tex									& \textbf{[${covsh1c}\%]}		& \textbf{[${covshH1c}\%]} 		\\
tex English-learner					& ${cov1d}		& ${covH1d} 		\\
tex									& \textbf{[${covsh1d}\%]}		& \textbf{[${covshH1d}\%]} 		\\
tex Special Education					& ${cov1e}		& ${covH1e} 		\\
tex									& \textbf{[${covsh1e}\%]}		& \textbf{[${covshH1e}\%]} 		\\
tex \emph{Total enrollment shares}	& ${cov1}		& ${covH1} 		\\
tex 								& \textbf{[${covsh1}\%]}		& \textbf{[${covshH1}\%]} 	\\
tex & & \\
tex \emph{Other variables} & & \\
tex Share FRPL			& ${cov2a}		& ${covH2a} 		\\
tex 			& \textbf{[${covsh2a}\%]}		& \textbf{[${covshH2a}\%]} 		\\		
tex Poverty rate			& ${cov2b}		& ${covH2b} 		\\
tex 			& \textbf{[${covsh2b}\%]}		& \textbf{[${covshH2b}\%]} 		\\		
tex Private school enrollment			& ${cov3}		& ${covshH3} 		\\
tex 			& \textbf{[${covsh3}\%]}		& \textbf{[${covH3}\%]} 		\\		
tex Teacher-to-student ratio			& ${cov4}		& ${covH4} 		\\
tex 			& \textbf{[${covsh4}\%]}		& \textbf{[${covshH4}\%]} 		\\		
tex & & \\\hline
tex	\emph{All covariates}					& ${cov}		& ${covH} 		\\
tex									& \textbf{[${covsh}\%]}		& \textbf{[${covshH}\%]} 		\\
texdoc close

		
		
		
		
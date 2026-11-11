/*

literature_effects.do 

*/


* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global yg = "94 112 45"
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


*** LOAD DATA

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


sort leaid year
merge m:1 leaid year using `temp'
drop if _m == 2
drop _m



* Merge bond categories
merge m:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
drop if _m == 2
drop _m
capt drop __*

egen maincats = rowmax(landpurch class stem hvac safeall athletic busvehicle infra)
gen anyothercats = maincats == 0 & categorized == 0
replace anyothercats = . if anyothercats == .

* generate categories of passed bonds
gen athleticP = athletic if passbond == 1
gen hvacP = hvac if passbond == 1
gen infraP = infra if passbond == 1
gen stemP = stem if passbond == 1
gen safeallP = safeall if passbond == 1
gen classP = class if passbond == 1
gen landpurchP = landpurch if passbond == 1
gen busvehicleP = busvehicle if passbond == 1
gen anyothercatsP = anyothercats if passbond == 1


********************************************************************************
***** 			1.0 LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************


** Useful globals
global D_lag = "D_27 D_26 D_25 D_24 D_23 D_22 D_21 D_20 D_19 D_18 D_17 D_16 D_15 D_14 D_13 D_12 D_11 D_10 D_9 D_8 D_7 D_6 D_5 D_4 D_3 D_2 D_1 "
global D_lead = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22 D23 D24 D25 D26 D27"
global D_lag_small = "D_5 D_4 D_3 D_2 D_1"
global D_lead_small = " D1 D2 D3 D4 D5 D6 D7 D8 D9 D10"
global E_lag = "El27 El26 El25 El24 El23 El22 El21 El20 El19 El18 El17 El16 El15 El14 El13 El12 El11 El10 El9 El8 El7 El6 El5 El4 El3 El2 El1"
global E_lead = "Ef1  Ef2 Ef3 Ef4 Ef5 Ef6 Ef7 Ef8 Ef9 Ef10 Ef11 Ef12 Ef13 Ef14 Ef15 Ef16 Ef17 Ef18 Ef19 Ef20 Ef21 Ef22 Ef23 Ef24 Ef25 Ef26 Ef27"
global M_lag = "Ml27 Ml26 Ml25 Ml24 Ml23 Ml22 Ml21 Ml20 Ml19 Ml18 Ml17 Ml16 Ml15 Ml14 Ml13 Ml12 Ml11 Ml10 Ml9 Ml8 Ml7 Ml6 Ml5 Ml4 Ml3 Ml2 Ml1"
global M_lead = "Mf1 Mf2 Mf3 Mf4 Mf5 Mf6 Mf7 Mf8 Mf9 Mf10 Mf11 Mf12 Mf13 Mf14 Mf15 Mf16 Mf17 Mf18 Mf19 Mf20 Mf21 Mf22 Mf23 Mf24 Mf25 Mf26 Mf27"

** Label variables to plot
gen zero = 0
label var zero "0"
forvalues n = 1 / 27{
	label var D_`n' "-`n'"
	label var D`n' "`n'"
}
	label var D0 "0"

********************************************************************************
***** 							Effects on test scores   	 	***************
********************************************************************************

capt drop __*


*---------> California (Cellini, Ferreira, Rothstein 2010) weak +

eststo ca: reghdfe scale_score $D_lag zero $D_lead $E_lag $E_lead  $M_lag $M_lead if fips == 6 & year <= 2008 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
lincom (D3 + D4 + D5 + D6) / 4
global effect_ca = r(estimate)


*---------> Texas (Martorell et al. 2016) zero

eststo tx: reghdfe scale_score $D_lag zero $D_lead $E_lag $E_lead  $M_lag $M_lead if fips == 48 & year <= 2010 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
lincom (D3 + D4 + D5 + D6) / 4
global effect_tx = r(estimate)

*---------> Wisconsin (Baron 2021) zero

eststo wi: reghdfe scale_score $D_lag zero $D_lead $E_lag $E_lead  $M_lag $M_lead if fips == 55 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
lincom (D3 + D4 + D5 + D6) / 4
global effect_wi = r(estimate)

*---------> Michigan (Hong and Zimmer 2016) +

eststo mi: reghdfe scale_score $D_lag zero $D_lead $E_lag $E_lead  $M_lag $M_lead if fips == 26 & year <= 2009 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
lincom (D3 + D4 + D5 + D6) / 4
global effect_mi = r(estimate)

*---------> Ohio (Colin and Thompson 2017) +, Goncalves 2015, Enami 2021. Nothing in short run, larger in long run

eststo oh: reghdfe scale_score $D_lag zero $D_lead $E_lag $E_lead  $M_lag $M_lead if fips == 39 & year <= 2014 [aw = test_enroll], a(leaid#cohort subject#grade#fips#year#cohort) cl(leaid) 
lincom (D3 + D4 + D5 + D6) / 4
global effect_oh = r(estimate)

coefplot	(oh, label("OH (Conlin & Thompson EER 2017, +)") color("$yo") lp(solid) lw(medthick) recast(connect) ciopts(recast(rcap) color("$yo % 80"))) ///
			(ca, label("CA (Cellini et al. QJE 2010, weak +)") color("$yo % 50") lp(shortdash) lw(medthick) recast(connect) ciopts(recast(rcap) color("$yo % 50"))) ///
			(wi, label("WI (Baron AEJ:Pol 2022, zero)") color("$yaleblue % 30") lp(longdash) recast(connect) ciopts(recast(rcap) color("$yaleblue % 30"))) ///
			(tx, label("TX (Martorell et al. JPubE 2016, zero)") color("$yaleblue % 60") lp(dash_dot) recast(connect) ciopts(recast(rcap) color("$yaleblue % 60"))) ///
			(mi, label("MI (Hong and Zimmer 2016, zero)") color("$yaleblue") lp(dash) lw(medthick) recast(connect) ciopts(recast(rcap) color("$yaleblue"))) ///
, vert keep($D_lag_small zero $D_lead_small) omitted yline(0, lcolor(gs10) lw(vthin)) xline(6.7) $axissize  ///
			level(90) legend(row(5) pos(11) ring(0) $labsize) ytitle("Effect on test scores (sd)", $labsize) xtitle("Time to bond passage", $labsize) $xsize 
graph export "$outdir/testpooled_literature.png", replace


********************************************************************************
***** 						Composition of student body   	 	***************
********************************************************************************


preserve
keep leaid year fips lowsesT lowsesB enroll
duplicates drop
label define state 6 "CA" 48 "TX" 26 "MI" 55 "WI" 39 "OH"
label values fips state
keep if (fips == 6 & year <= 2008 ) | (fips == 48 & year <= 2010) | fips == 55 | ( fips == 26 & year <= 2009) | (fips == 39 & year <= 2014)
graph bar lowsesT lowsesB [aw = enroll], over(fips) bar(1, color("$yo")) bar(2, color("$ylb")) legend(order(1 "Low SES" 2 "High SES") ring(0) pos(11))
restore


********************************************************************************
***** 						Composition of bonds   	 	***************
********************************************************************************

preserve
keep if (fips == 6 & year <= 2008 ) | (fips == 48 & year <= 2010) | fips == 55 | ( fips == 26 & year <= 2009) | (fips == 39 & year <= 2014)
egen n = rowtotal(classP stemP hvacP infraP safeallP athleticP busvehicleP landpurchP)
collapse (sum) classP stemP hvacP infraP safeallP athleticP anyothercatsP  busvehicleP landpurchP n, by(fips)
label define state 6 "CA" 48 "TX" 26 "MI" 55 "WI" 39 "OH"
label values fips state
foreach var in  classP stemP hvacP infraP safeallP athleticP  busvehicleP landpurchP {
	replace `var' = `var'/n
}
drop n
sort fips

graph bar (mean) hvacP infraP safeallP stemP classP landpurchP busvehicleP athleticP    ///
	,  over(fips) stack ///
	legend(order(1 "HVAC" 2 "Other infr" 3 "Safety/health"  4 "STEM"  5 "Classrooms" 6 "Land" 7 "Transportation" 8 "Athletics") pos(6) col(8) size(medium)) xsize(11) ///
	bar(8, color("$yo")) bar(7, color("$yo % 13")) bar(6, color("$yo % 25")) bar(5, color("$yo % 10")) bar(4, color("$yg % 10")) bar(3, color("$yg% 40")) bar(2, color("$yg % 60")) bar(1, color("$yg"))


restore



preserve
gen ses = 1 if lowsesT == 1
replace ses = 2 if lowsesT == 0 & lowsesB == 0
replace ses = 3 if lowsesB == 1
keep if (fips == 6 & year <= 2008 ) | (fips == 48 & year <= 2010) | fips == 55 | ( fips == 26 & year <= 2009) | (fips == 39 & year <= 2014)
egen n = rowtotal(classP stemP hvacP infraP safeallP athleticP busvehicleP landpurchP)
collapse (sum) classP stemP hvacP infraP safeallP athleticP anyothercatsP  busvehicleP landpurchP n, by(fips ses)
bysort fips: egen N = sum(n) 
label define state 6 "CA" 48 "TX" 26 "MI" 55 "WI" 39 "OH"
label values fips state
label define ses 1 "High share FRPL" 2 "Medium share FRPL" 3 "Low share FRPL"
label values ses ses
foreach var in  classP stemP hvacP infraP safeallP athleticP  busvehicleP landpurchP {
	replace `var' = `var'/N
}
drop n
sort fips
graph bar (mean) hvacP infraP safeallP stemP classP landpurchP busvehicleP athleticP    ///
	,  over(ses, label(angle(45)))  over(fips) stack ///
	legend(order(1 "HVAC" 2 "Other infr" 3 "Safety/health"  4 "STEM"  5 "Classrooms" 6 "Land" 7 "Transportation" 8 "Athletics") pos(6) col(8) size(medium)) xsize(11) ///
	bar(8, color("$ylb * 1.5")) bar(7, color("$ylb % 80")) bar(6, color("$ylb % 50")) bar(5, color("$ylb % 20")) bar(4, color("$yo % 20")) bar(3, color("$yo % 50")) bar(2, color("$yo % 80")) bar(1, color("$yo * 1.5"))

graph export "$outdir/composition_literature.png", replace

restore


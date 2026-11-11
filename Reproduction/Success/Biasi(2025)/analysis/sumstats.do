 /*

mean_effects_stacked.do 
	
*/


clear 
program drop _all
capture log close
set more off 

* Install necessary commands
ssc install heatplot, replace
ssc install estout, replace
ssc install palettes, replace
ssc install colrspace, replace

* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global ylight = "217 233 242" 
global yg = "94 112 45"
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

*-----> prepare district demographics & save them

use "$prepdata/dist_enroll_demo.dta", clear
gen share_minor = sh_dy_hisp + sh_dy_black
keep leaid fy sh_dy_econdis share_minor
rename fy year
sort leaid year
tempfile temp
save `temp', replace

*-----> Load spending rules
use "$prepdata/merge_fin_bond.dta", clear
keep leaid fy supermajority debtlimit
duplicates drop leaid supermajority debtlimit, force
gsort leaid -fy
bysort leaid: gen N = _n
keep if N == 1
drop N fy
sort leaid
tempfile rules
save `rules', replace


*-----> Load bond categories and amounts
use  "$prepdata/bond_cat_amt_clean.dta", clear

egen maincats = rowmax(landpurch class stem hvac safeall athletic busvehicle infra)
gen anyothercats = maincats == 0 & categorized == 1
replace anyothercats = . if categorized == 0
sort leaid year
merge 1:1 leaid year using `temp', nogen
tempfile temp
save `temp', replace

*-----> Tag observations in regressions
use "$prepdata/stacked_data.dta", clear
keep leaid year
duplicates drop
sort leaid year
tempfile tag
save `tag', replace

*-----> Load main dataset (note: I am using the full dataset here, not the stacked one.)
use "$prepdata/analysis_dataset.dta", clear
sort leaid year
merge m:1 leaid year using `tag'
gen regsample = 1 if _m == 3

* store test scores; average across grades, by subject
preserve
keep leaid year scale_score test_enroll grade subject 
duplicates drop
drop if scale_score == .
reshape wide scale_score, i(leaid year grade) j(subject)
rename *0 *_ela
rename *1 *_math
collapse scale_score*, by(leaid year)
tempfile test
save `test', replace
restore

* remove duplicates due to stacked design
keep leaid year pass holdbond cap te_ci_pp_r  holdbond fips fipst enroll margin regsample
duplicates drop

* merge in other info
sort leaid year
merge 1:1 leaid year using `temp', keep(1 3) nogen
merge 1:1 leaid year using `test', keep(1 3) nogen 
merge m:1 leaid using `rules', keep(1 3) nogen 
merge 1:1  leaid year using "$root/data/prep/hpi.dta", keep(1 3)

* ever has an election
bysort leaid: egen oneel = max(holdbond)

* normalize & winsorize bond amount per pupil
qui gen passbond=pass
qui replace passbond=0 if pass==.

gen amount_pp = (amount / enroll) / 1000
winsor2 amount_pp, replace

* generate variables to plot:
gen amount_pp_P = amount_pp if passbond == 1
gen athleticP = athletic if passbond == 1
gen hvacP = hvac if passbond == 1
gen infraP = infra if passbond == 1
gen stemP = stem if passbond == 1
gen safeallP = safeall if passbond == 1
gen classP = class if passbond == 1
gen landpurchP = landpurch if passbond == 1
gen busvehicleP = busvehicle if passbond == 1
gen anyothercatsP = anyothercats if passbond == 1

gen has_superm = supermajority >.5
replace has_superm = . if supermajority == .

gen passbond_if = passbond if holdbond == 1


* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25


* Label variables
label var te_ci_pp_r "Current"
label var cap "Capital"
label var has_superm "Share w/supermajority"
label var supermajority "Voting requirement"
label var holdbond "Share proposing a bond/year"
label var passbond "Share approved bonds"
label var margin "Vote margin"
label var sh_dy_econdis "Share low-SES"
label var share_minor "Share Black/Hispanic"
label var scale_score_ela "ELA test scores"
label var scale_score_math "Math test scores"
label var hpi "House price index ($1989 = 100$)"

label var athleticP "Athletic facilities"
label var hvacP "HVAC"
label var infraP "Other infrastructure"
label var stemP "STEM equipment"
label var safeallP "Safety/health"
label var busvehicleP "Transportation"
label var classP "Classrooms"
label var landpurchP "Land purchases"
label var passbond_if "Share approved"
label var debtlimit "Debt limit"

label var amount_pp_P "Size p.p. proposed (\textdollar 1,000)"
label var amount_pp "Size p.p. proposed (\textdollar 1,000)"

gen sample = 1
label define sample 1 "Full sample"
label values sample sample

gen sample1 = 1
label define regsample 1 "W/election"
label values sample1 regsample 

gen sample2 = 1
label define oneel 1 "Analysis sample"
label values sample2 oneel 

*******************************************
*****								  *****
***									    ***
*		 MAIN SUMMARY STATS TABLE 		  *
***									    ***
*****								  *****
*******************************************

global var_full = "cap te_ci_pp_r  has_superm supermajority debtlimit holdbond passbond_if margin amount_pp classP infraP hvacP stemP safeallP athleticP busvehicleP landpurchP sh_dy_econdis share_minor scale_score_ela scale_score_math hpi"
global var_super = "cap te_ci_pp_r  supermajority debtlimit holdbond passbond_if margin amount_pp classP infraP hvacP stemP safeallP athleticP busvehicleP landpurchP sh_dy_econdis share_minor scale_score_ela scale_score_math hpi"

eststo r1: estpost tabstat $var_full, statistics(mean sd) columns(statistics) by(sample) nototal

eststo r2: estpost tabstat $var_full if oneel == 1, statistics(mean sd) columns(statistics) by(sample1) nototal

eststo r3: estpost tabstat $var_full if regsample == 1, statistics(mean sd) columns(statistics) by(sample2) nototal


esttab r1 r2 r3 using "$tables/summary.tex",	booktabs main(mean) aux(sd) nostar nonote noobs unstack label ///
	replace nogap frag nonum nomtitle collabels(none) cells(mean(fmt(a2)) sd(par)) ///
	refcat(cap_pp_r "\emph{Expenditure per pupil (\textdollar)}" has_superm "\emph{Spending rules}" ///
		holdbond "\emph{Bonds}"  classP "\emph{Categories, approved bonds}"  sh_dy_econdis "\emph{Demographics and outcomes}", nolabel) ///
		postfoot("\midrule")

		
qui egen tag_st=tag(fipst)
qui egen tag_d=tag(leaid)

eststo m1: estpost su tag_d tag_st if sample

distinct leaid if sample
estadd scalar Ndist = r(ndistinct) : m1
distinct fipst if sample
estadd scalar Nstates = r(ndistinct) : m1

eststo m2a: estpost su tag_d tag_st if oneel == 1

distinct leaid if oneel == 1
estadd scalar Ndist = r(ndistinct) : m2a
distinct fipst if oneel == 1
estadd scalar Nstates = r(ndistinct) : m2a

eststo m2b: estpost su tag_d tag_st if regsample == 1

distinct leaid if regsample == 1
estadd scalar Ndist = r(ndistinct) : m2b
distinct fipst if regsample == 1
estadd scalar Nstates = r(ndistinct) : m2b


esttab m1 m2a m2b  	using "$tables/summary.tex", append fragment booktabs style(tex) label ///
	nostar nonumbers noobs mlabels(, none) collabels(, none) stats(Ndist Nstates, fmt(%11.0gc %11.0gc) ///
		labels("Number of districts" "Number of states")) substitute("\midrule" "")

	
	
				
*******************************************
*****								  *****
***									    ***
*	   Close vs non-close elections 	  *
***									    ***
*****								  *****
*******************************************
						
					
gen close = abs(margin) < 0.1
replace close = -1 if margin == .
replace close = close + 1

label define closeel 0 "None" 1 "Non-close" 2 "Close (margin$=+/-0.1$)"
label values close closeel
replace passbond_if = . if margin == .

global var_close = "cap te_ci_pp_r  has_superm supermajority debtlimit passbond_if margin amount_pp classP infraP hvacP stemP safeallP athleticP busvehicleP landpurchP sh_dy_econdis share_minor scale_score_ela scale_score_math hpi"

eststo r1close: estpost ttest $var_close if close > 0, by(close) 


esttab 	r1close using "$tables/summary_close.tex", ///
		cells("mu_1(fmt(a3)) mu_2(fmt(a3)) b(fmt(a3)star)" ". . se(par)") star(* 0.10 ** 0.05 *** 0.01) ///
		main(mean) aux(sd) nonote unstack label collabels("Non-close" "Close (margin$=+/-0.1$) " "Difference") ///
		nomtitle replace ///
		booktabs noobs  ///
		nogap frag nonum   ///
		refcat(cap_pp_r "\emph{Expenditure per pupil (\textdollar)}" ///
		has_superm "\emph{Spending rules}" ///
		holdbond "\emph{Bonds}" ///
		classP "\emph{Categories, approved bonds}" ///
		sh_dy_econdis "\emph{Demographics and outcomes}", nolabel) ///
		postfoot("\midrule")
		

eststo m3a: estpost su tag_d tag_st if close >0

distinct leaid if close >0
estadd scalar Ndist = r(ndistinct) : m3a
distinct fipst if close >0
estadd scalar Nstates = r(ndistinct) : m3a


eststo m2a: estpost su tag_d tag_st if close == 1

distinct leaid if close == 1
estadd scalar Ndist = r(ndistinct) : m2a
distinct fipst if close == 1
estadd scalar Nstates = r(ndistinct) : m2a

eststo m2b: estpost su tag_d tag_st if close == 2

distinct leaid if close == 2
estadd scalar Ndist = r(ndistinct) : m2b
distinct fipst if close == 2
estadd scalar Nstates = r(ndistinct) : m2b



esttab m2a m2b  m3a	using "$tables/summary_close.tex", append fragment booktabs style(tex) label ///
	nostar nonumbers noobs mlabels(, none) collabels(, none) stats(Ndist Nstates, fmt(%11.0gc %11.0gc) ///
		labels("Number of districts" "Number of states")) substitute("\midrule" "")
	


*******************************************
*****								  *****
***									    ***
*	   Lags between elections 	  		  *
***									    ***
*****								  *****
*******************************************
	
	
preserve
keep leaid year holdbond passbond has_super
duplicates drop

gen laghold_succ = 1 if pass == 1 & f.holdbond == 1
gen laghold_fail = 1 if pass == 0 & holdbond == 1 & f.holdbond == 1
gen lagpass_succ = 1 if pass == 1 & f.holdbond == 1
gen lagpass_fail = 1 if pass == 0 & holdbond == 1 & f.holdbond == 1

forvalues n = 2 / 30 {
replace laghold_succ = `n' if laghold_succ == . & pass == 1 & f`n'.holdbond == 1
replace laghold_fail = `n' if laghold_fail == . & pass == 0 & holdbond == 1 & f`n'.holdbond == 1
replace lagpass_succ = `n' if lagpass_succ == . & pass == 1 & f`n'.pass == 1
replace lagpass_fail = `n' if lagpass_fail == . & pass == 0 & holdbond == 1 & f`n'.pass  == 1
}

* proposing a bond
qui sum laghold_succ, det
local meansucc: di %3.1f `r(mean)'
disp "`meansucc'"
qui sum laghold_fail, det
local meanfail: di %3.1f `r(mean)'
disp "`meansucc'"
twoway (histogram laghold_succ, color("$ylb % 50")) (histogram laghold_fail, color("$yo % 50")), legend(pos(1) ring(0) order(1 "After successful election (mean lag = `meansucc')" 2 "After unsuccessful election (mean lag = `meanfail')")) ytitle("Share districts") xtitle("Lag w/subsequent election")
graph export "$outdir/lag_hold.png", replace



* passing a bond
qui sum lagpass_succ, det
local meansucc: di %3.1f `r(mean)'
disp "`meansucc'"
qui sum lagpass_fail, det
local meanfail: di %3.1f `r(mean)'
disp "`meansucc'"
twoway (histogram lagpass_succ, color("$ylb % 50")) (histogram lagpass_fail, color("$yo % 50")), legend(pos(1) ring(0) order(1 "After successful election (mean lag = `meansucc')" 2 "After unsuccessful election (mean lag = `meanfail')")) ytitle("Share districts")  xtitle("Lag w/subsequent successful election")
graph export "$outdir/lag_pass.png", replace

restore




*******************************************
*****								  *****
***									    ***
*		   Bond distribution 	  		  *
***									    ***
*****								  *****
*******************************************

preserve

*keep leaid year class stem safeall infra athletic busvehicle landpurch hvac passbond
egen tot = rowtotal(class stem safeall infra athletic busvehicle landpurch hvac )

foreach var in class stem safeall infra athletic busvehicle landpurch hvac {
	qui sum `var'
	local sum_`var' = r(mean)
	*local sum_`var' = `sum_`var'' / `total'	
	qui sum `var'P if passbond == 1
	local sumP_`var' = r(mean)
	*local sumP_`var' = `sumP_`var'' / `totalP'
}
clear
set obs 8
gen cat = "Classrooms" in 1
replace cat = "STEM" in 2
replace cat = "Safety & health" in 3
replace cat = "Other infrastructure" in 4
replace cat = "Athletics" in 5
replace cat = "Transportation" in 6
replace cat = "Land purchases" in 7
replace cat = "HVAC" in 8
gen tot = .
gen totP = .
local n = 1
foreach var in class stem safeall infra athletic busvehicle landpurch hvac {
	replace tot = `sum_`var'' in `n'
	replace totP = `sumP_`var'' in `n'
	local n = `n'+1
}
gen tott = -tot
graph bar tot totP, over(cat, sort(tott) label(angle(45))) ytitle("Total number of bonds") bar(1, color("$yaleblue")) bar(2, color("$yo"))legend(ring(0) pos(1) order(1 "Proposed bonds" 2 "Authorized bonds"))  xsize(4.5) //  blabel(bar, format(%3.2f)) 
graph export "$outdir/bond_categories.png", replace
restore

preserve
keep if class != 0
*keep leaid year class stem safeall infra athletic busvehicle landpurch hvac 
egen tot = rowtotal(class stem safeall infra athletic busvehicle landpurch hvac )
egen totP = rowtotal(classP stemP safeallP infraP athleticP busvehicleP landpurchP hvacP )
sum tot if tot > 0, det
tab tot if tot > 0
sum totP if totP > 0, det
tab totP if totP > 0
gen k = 1
forvalues b = 1/8 {
	sum k if tot == `b'
	local sum_`b' = r(sum)
	sum k if totP == `b'
	local sumP_`b' = r(sum)
	*local sum_`var' = `sum_`var'' / `total'
}
clear
set obs 8
gen n = _n
gen tot = .
gen totP = .
forvalues b = 1/8 {
	replace tot = `sum_`b'' if n == `b'
	replace totP = `sumP_`b'' if n == `b'
}
graph bar tot totP, over(n, label(labsize(medlarge))) ytitle("Total number of bonds") bar(1, color("$yaleblue")) bar(2, color("$yo")) legend(ring(0) pos(1) order(1 "Proposed bonds" 2 "Authorized bonds")) title("Number of categories in each bond" " ", pos(6)) xsize(5.5)
graph export "$outdir/bond_nrcategories.png", replace
restore



*******************************************
*****								  *****
***									    ***
*		   Category bundling 	  		  *
***									    ***
*****								  *****
*******************************************



* Pairwise bundling - passed bonds

preserve
rename classP Classrooms
rename stemP STEM
rename safeallP SafetyHealth
rename infraP OtherInfrastructure
rename athleticP Athletic
rename busvehicleP Transportation
rename landpurchP LandPurchases
rename hvacP  HVAC

matrix C = J(8,8,.)

local varlist = "HVAC SafetyHealth OtherInfrastructure STEM Classrooms Athletic Transportation LandPurchases "
local n = 1
local m = 1
qui foreach var1 of local varlist {
	foreach var2 of local varlist {
	sum `var2' if `var1' == 1
	matrix C[`n',`m'] = r(mean)
	local m = `m' + 1
	}
	local m = 1
	local n = `n' + 1
}

matrix rownames C = `varlist'
matrix colnames C = `varlist'
matrix list C
heatplot C, values(format(%9.3f)) xlabel(, angle(45)) legend(title("Shares")) color("$yo % 20" "$yo % 30" "$yo % 40" "$yo % 50" "$yo % 60" "$yo % 70" "$yo % 80" "$yo % 90" "$yo")
graph export "$outdir/heatplot_pass.png", replace
restore

* Pairwise bundling - proposed bonds
preserve
rename class Classrooms
rename stem STEM
rename safeall SafetyHealth
rename infra OtherInfrastructure
rename athletic Athletic
rename busvehicle Transportation
rename landpurch LandPurchases
rename hvac  HVAC

matrix C = J(8,8,.)

local varlist = "HVAC SafetyHealth OtherInfrastructure STEM Classrooms Athletic Transportation LandPurchases "
local n = 1
local m = 1
qui foreach var1 of local varlist {
	foreach var2 of local varlist {
	sum `var2' if `var1' == 1
	matrix C[`n',`m'] = r(mean)
	local m = `m' + 1
	}
	local m = 1
	local n = `n' + 1
}

matrix rownames C = `varlist'
matrix colnames C = `varlist'
matrix list C
heatplot C, values(format(%9.3f)) xlabel(, angle(45)) legend(title("Shares")) color("$yo % 20" "$yo % 30" "$yo % 40" "$yo % 50" "$yo % 60" "$yo % 70" "$yo % 80" "$yo % 90" "$yo")
graph export "$outdir/heatplot_propose.png", replace
restore

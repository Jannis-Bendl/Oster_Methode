/*

sumstats_bonds.do

*/

clear all
capture log close
set more off 

local name "sumstats"
local outfolder "sumstats"

* Choices:

local omit omit
*local omit noomit
local range "5 10"
local allrange "27 27"
*local range "0 10"
*local allrange "0 27"


* Yale colors
global yaleblue = "0 53 107"
global ylb = "40 109 192"
global yo = "189 83 25"
global yg = "94 112 45"
global ygray = "74 74 74"
global ylight = "217 233 242"
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
***** 		1.0 LOAD DATA & PRODUCE STATS: ALL DISTRICTS 	 	****************
********************************************************************************

use "$prepdata/analysis_dataset.dta", clear
keep if scale_score != .
keep if holdbond == 1
keep leaid year enroll holdbond passbond margin
duplicates drop
tempfile roster
save `roster'
use "$prepdata/bond_cat_amt_clean.dta", clear
sort leaid year
merge 1:1 leaid year using `roster'
keep if holdbond == 1 | _m == 3
drop _m

* Generate necessary variables
replace passbond = 0 if holdbond == 1 & passbond == .
egen nrcat = rowtotal(busvehicle hvac athletic stem class landpurch safeall infra)
gen hasamt = amount != .
gen amount_pp = amount/enroll
replace amount_pp = amount_pp/1000
winsor2 amount_pp, replace

* Label variables
label var passbond  "Share authorized"
label var amount_pp  "Bound amount per pupil (\textdollar1,000)"
label var categorized  "Bond belongs to a category"
label var class  "Classrooms"
label var infra  "Basic infrastructures"
label var hvac  "HVAC"
label var safeall  "Safety \& health"
label var stem  "STEM"
label var athletic  "Athletics"
label var landpurch  "Land purchases"
label var busvehicle  "Transportation"

su nrcat if nrcat > 0 & nrcat != ., det
global nra: di %9.1f `r(mean)'
global nrmd: di %9.0f `r(p50)'
global nrmc: di %9.0f `r(p75)'
su nrcat if nrcat > 0 & nrcat != . & pass == 1, det
global nra_a: di %9.1f `r(mean)'
global nrmd_a: di %9.0f `r(p50)'
global nrmc_a: di %9.0f `r(p75)'

local n = 1
foreach cat in class infra hvac  safeall stem  athletic landpurch busvehicle {
	su `cat'
	local x = 100 * `r(mean)'
	global s_`n': di %9.1f `x'
	su nrcat if nrcat > 0 & nrcat != . & `cat' == 1, det
	global nra_`n': di %9.1f `r(mean)'
	global nrmd_`n': di %9.0f `r(p50)'
	global nrmc_`n': di %9.0f `r(p75)'
	su nrcat if nrcat > 0 & nrcat != . & `cat' == 1 & pass == 1, det
	global nra_a_`n': di %9.1f `r(mean)'
	global nrmd_a_`n': di %9.0f `r(p50)'
	global nrmc_a_`n': di %9.0f `r(p75)'
	local n = `n' + 1
}





*** BOND CATEGORIES: SUMMARY TABLE


texdoc init  "$tables/bond_sumstats_nrcat.tex", replace force
tex & Share of bonds & \multicolumn{3}{c}{\# Categories, all bonds} &  \multicolumn{3}{c}{\# Categories, authorized bonds} \\ \cmidrule{3-5}\cmidrule{6-8}
tex & w/category & Mean & Median & 3th qtile & Mean & Median & 3th qtile \\ \hline
tex 	All bonds 				& -- & {$nra} 	& {$nrmd} 	& {$nrmc} 	& {$nra_a} 	& {$nrmd_a} & {$nrmc_a} \\
tex 	 		& & 			&			&			&			&			&			\\
tex 	\emph{By category} 		& & 			&			&			&			&			&			\\
tex 	Classrooms				& {$s_1}\%	& {$nra_1} 	& {$nrmd_1} 	& {$nrmc_1} 	& {$nra_a_1} 	& {$nrmd_a_1} & {$nrmc_a_1} \\
tex 	Infrastructure			& {$s_2}\%	& {$nra_2} 	& {$nrmd_2} 	& {$nrmc_2} 	& {$nra_a_2} 	& {$nrmd_a_2} & {$nrmc_a_2} \\
tex 	HVAC					& {$s_3}\%	& {$nra_3} 	& {$nrmd_3} 	& {$nrmc_3} 	& {$nra_a_3} 	& {$nrmd_a_3} & {$nrmc_a_3} \\
tex 	Safety/health			& {$s_4}\%	& {$nra_4} 	& {$nrmd_4} 	& {$nrmc_4} 	& {$nra_a_4} 	& {$nrmd_a_4} & {$nrmc_a_4} \\
tex 	STEM					& {$s_5}\%	& {$nra_5} 	& {$nrmd_5} 	& {$nrmc_5} 	& {$nra_a_5} 	& {$nrmd_a_5} & {$nrmc_a_5} \\
tex 	Athletics				& {$s_6}\%	& {$nra_6} 	& {$nrmd_6} 	& {$nrmc_6} 	& {$nra_a_6} 	& {$nrmd_a_6} & {$nrmc_a_6} \\
tex 	Land purchases			& {$s_7}\%	& {$nra_7} 	& {$nrmd_7} 	& {$nrmc_7} 	& {$nra_a_7} 	& {$nrmd_a_7} & {$nrmc_a_7} \\
tex 	Transportation			& {$s_8}\%	& {$nra_8} 	& {$nrmd_8} 	& {$nrmc_8} 	& {$nra_a_8} 	& {$nrmd_a_8} & {$nrmc_a_8} 
texdoc close


		
*** PREDICTING CATEGORIES w/DISTRICT CHARACTERISTICS
sort leaid year
merge 1:1 leaid year using "$prepdata/demographics.dta", keep(1 3) nogen
preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore
merge m:1 leaid year using  `temp', keep(1 3) nogen

gen lnenr = ln(enroll)
tsset leaid year

global catprop = ""
global catpass = ""
foreach cat in class infra hvac  safeall stem  athletic landpurch busvehicle {
	if "`cat'" == "class" 	local var = "Classrooms"
	if "`cat'" == "infra" 	local var = "Infrastructure"
	if "`cat'" == "hvac" 		local var = "HVAC"
	if "`cat'" == "safeall" 	local var = "Satefy/health"
	if "`cat'" == "stem" 		local var = "STEM"
	if "`cat'" == "athletic" 	local var = "Athletics"
	if "`cat'" == "landpurch" local var = "Land purchases"
	if "`cat'" == "busvehicle" local var = "Transportation"
	gen L`cat' = l.`cat' ==1 | l2.`cat' == 1 | l3.`cat' ==1 | l4.`cat' == 1 | l5.`cat' == 1
	label var L`cat' "`var'"
	global catprop "$catprop L`cat'"
	gen LP`cat' = (l.`cat' ==1 & l.pass == 1) | (l2.`cat' == 1  & l.pass == 1) | (l3.`cat' ==1  & l.pass == 1) | (l4.`cat' == 1  & l.pass == 1) | (l5.`cat' == 1 & l.pass == 1) 
	label var LP`cat' "`var'"
	global catpass  "$catpass LP`cat'"
}


* Label variables
label var black "Black"
label var hisp "Hispanic"
label var asian "Asian"
label var sped "Special ed."
label var el "English-learner"
label var frpl "FRPL"
label var poor "Poverty rate"
label var shpriv "Private sch. enrl. rate"
label var teachers "S/T ratio"

gen S = 0

foreach cat in class infra hvac  safeall stem  athletic landpurch busvehicle {
	disp "`cat'"
	 eststo R_`cat': reghdfe `cat' black hisp asian sped el frpl poor shpriv teachers $catprop $catpass S, a(leaid fips#year) cluster(leaid)
}

esttab R* using "$tables/cat_observables.tex", booktabs b(3) se(3) unstack nonote label replace se drop(_cons) ///
		indicate("Distr., State * yr FE = S") ///
		obslast nogap starlevel(\$^*\$ .1 \$^{**}\$ .05 \$^{***}\$ .01) /// 
		mgroups("Classrooms" "Infrastructure" "HVAC" "Safety/health" "STEM" "Athletics" "Land purch." "Transp", pattern(1 1 1 1 1 1 1 1) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
		frag substitute(\_ _) ///
		refcat(black "\emph{Student shares}" poor "\emph{District characteristics}" Lclass "\emph{Bonds proposed (last 5 yrs)}" LPclass "\emph{Bonds authorized (last 5 yrs)}", nolabel) ///
		nomtitle stats(F N N_clust r2, fmt(2 0 0 2) ///
		labels(`"F-stat"' `"N"' `"Clusters (districts)"' `"R-squared"'))



********************************************************************************
***** 		2.0 LOAD DATA & PRODUCE STATS: STACKED DATA 	 	****************
********************************************************************************

preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile shpriv
save `shpriv', replace
restore

use "$prepdata/stacked_data.dta", clear
keep if scale_score != .
keep if holdbond == 1
keep leaid year enroll holdbond passbond margin
duplicates drop
sort leaid year
merge m:1 leaid year using `shpriv', keep(1 3) nogen
tempfile roster
save `roster'



use "$prepdata/bond_cat_amt_clean.dta", clear
sort leaid year
merge 1:1 leaid year using `roster'
keep if holdbond == 1 | _m == 3
drop _m

* Generate necessary variables
replace passbond = 0 if holdbond == 1 & passbond == .
gen amount_pp = amount/enroll
replace amount_pp = amount_pp/1000
winsor2 amount_pp, replace

* Label variables
label var passbond  "Share authorized"
label var amount_pp  "Bound amount per pupil (\textdollar1,000)"
label var categorized  "Bond belongs to a category"
label var class  "Classrooms"
label var infra  "Basic infrastructures"
label var hvac  "HVAC"
label var safeall  "Safety \& health"
label var stem  "STEM"
label var athletic  "Athletics"
label var landpurch  "Land purchases"
label var busvehicle  "Transportation"

* Generate necessary variables
replace passbond = 0 if holdbond == 1 & passbond == .


	
*** PREDICTING CATEGORIES w/DISTRICT CHARACTERISTICS
sort leaid year
merge 1:1 leaid year using "$prepdata/demographics.dta", keep(1 3) nogen	
gen lnenr = ln(enroll)
tsset leaid year

global catprop = ""
global catpass = ""
foreach cat in class infra hvac  safeall stem  athletic landpurch busvehicle {
	if "`cat'" == "class" 	local var = "Classrooms"
	if "`cat'" == "infra" 	local var = "Infrastructure"
	if "`cat'" == "hvac" 		local var = "HVAC"
	if "`cat'" == "safeall" 	local var = "Satefy/health"
	if "`cat'" == "stem" 		local var = "STEM"
	if "`cat'" == "athletic" 	local var = "Athletics"
	if "`cat'" == "landpurch" local var = "Land purchases"
	if "`cat'" == "busvehicle" local var = "Transportation"
	gen L`cat' = l.`cat' ==1 | l2.`cat' == 1 | l3.`cat' ==1 | l4.`cat' == 1 | l5.`cat' == 1
	label var L`cat' "`var'"
	global catprop "$catprop L`cat'"
	gen LP`cat' = (l.`cat' ==1 & l.pass == 1) | (l2.`cat' == 1  & l.pass == 1) | (l3.`cat' ==1  & l.pass == 1) | (l4.`cat' == 1  & l.pass == 1) | (l5.`cat' == 1 & l.pass == 1) 
	label var LP`cat' "`var'"
	global catpass  "$catpass LP`cat'"
}


* Label variables
label var black "Black"
label var hisp "Hispanic"
label var asian "Asian"
label var sped "Special ed."
label var el "English-learner"
label var frpl "FRPL"
label var poor "Poverty rate"
label var shpriv "Private sch. enrl. rate"
label var teachers "S/T ratio"

gen S = 0

foreach cat in class infra hvac  safeall stem  athletic landpurch busvehicle {
	disp "`cat'"
	 eststo R_`cat': reghdfe `cat' black hisp asian sped el frpl poor shpriv teachers $catprop $catpass S, a(leaid fips#year) cluster(leaid)
}

esttab R* using "$tables/cat_observables_stacked.tex", booktabs b(3) se(3) unstack nonote label replace se drop(_cons) ///
		indicate("Distr. * coh, State * yr * coh FE = S") ///
		obslast nogap starlevel(\$^*\$ .1 \$^{**}\$ .05 \$^{***}\$ .01) /// 
		mgroups("Classrooms" "Infrastructure" "HVAC" "Safety/health" "STEM" "Athletics" "Land purch." "Transp", pattern(1 1 1 1 1 1 1 1) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
		frag substitute(\_ _) ///
		refcat(black "\emph{Student shares}" poor "\emph{District characteristics}" Lclass "\emph{Bonds proposed (last 5 yrs)}" LPclass "\emph{Bonds authorized (last 5 yrs)}", nolabel) ///
		nomtitle stats(F N N_clust r2, fmt(2 0 0 2) ///
		labels(`"F-stat"' `"N"' `"Clusters (districts)"' `"R-squared"'))










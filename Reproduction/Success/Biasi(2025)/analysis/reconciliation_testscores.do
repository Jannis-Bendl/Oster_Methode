 /*

reconciliation_testscores.do 

*/


clear 
program drop _all
capture log close
set more off 

ssc install tuples, replace

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
***** 			Plot & correlate them with outcomes		 		***************
********************************************************************************



*---------> Capital Stock
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

preserve
use "$prepdata/stacked_data.dta", clear
sort leaid year
capt drop __*
merge m:1 leaid year using `capstock', keep(1 3) nogen
gen time = year - cohort
tempvar capter_med
gen `capter_med' = captercile if time == -1
tempvar cap_abovemed
gen `cap_abovemed' = M2 if time == -1
bysort leaid cohort: egen cap_abovemed = median(`cap_abovemed')
tempvar capist
gen `capist' = capstock if time == -1
bysort leaid cohort: egen capist = median(`capist')
drop time
collapse cap_abovemed capstock, by(leaid)
tempfile capistock
save `capistock', replace
restore

** Demographic info

use  "$prepdata/demographics.dta", clear
preserve
use "$prepdata/nhgis.dta", clear
keep leaid year shprivate
sort leaid year
tempfile temp
save `temp', replace
restore
merge m:1 leaid year using  `temp', keep(1 3) nogen
collapse fipst white black hisp asian frpl poor sped el, by(leaid)
sort leaid
tempfile demographics
save `demographics', replace

** Bond size

use "$prepdata/analysis_dataset.dta", clear
keep leaid year enroll fips
duplicates drop
tempfile enroll
save `enroll', replace

use "$prepdata/bond_cat_amt_clean.dta", clear
keep leaid year amount class hvac infra safeall stem athletic busvehicle landpurch
sort leaid year
merge 1:1 leaid year using `enroll'
gen amount_pp = amount / enroll
collapse amount_pp enroll class hvac infra safeall stem athletic busvehicle landpurch, by(leaid)
tempfile amount
save `amount', replace

** Effects

use "$prepdata/testeffect_distr_main.dta"
keep district_code A1
keep if district_code != .
rename A1 main_effect
rename district_code leaid


sort leaid
merge 1:1 leaid using `capistock', nogen
merge 1:1 leaid using `demographics', nogen
merge 1:1 leaid using `amount', nogen



* Regressions
gen lnam = ln(amount_pp)
gen lncap = ln(capstock)

reg main_effect hisp black frpl poor lnam sped el lncap class hvac infra safeall stem athletic busvehicle landpurch [aw = enroll], a(fips)
gen sample = e(sample)


gen AA = 0
gen BB = 0
gen CC = 0
gen DD = 0
gen EE = 0
gen FF = 0
global dem = "AA hisp black frpl poor sped el"
global bond = "BB lnam class hvac infra safeall stem athletic busvehicle landpurch"
global dem_bond = "CC c.lnam#c.hisp c.lnam#c.black c.lnam#c.frpl c.lnam#c.poor c.class#c.hisp c.class#c.black c.class#c.frpl c.class#c.poor c.hvac#c.hisp c.hvac#c.black c.hvac#c.frpl c.hvac#c.poor c.infra#c.hisp c.infra#c.black c.infra#c.frpl c.infra#c.poor     c.safeall#c.hisp c.safeall#c.black c.safeall#c.frpl c.safeall#c.poor      c.stem#c.hisp c.stem#c.black c.stem#c.frpl c.stem#c.poor    c.athletic#c.hisp c.athletic#c.black c.athletic#c.frpl c.athletic#c.poor   c.busvehicle#c.hisp c.busvehicle#c.black c.busvehicle#c.frpl c.busvehicle#c.poor  c.landpurch#c.hisp c.landpurch#c.black c.landpurch#c.frpl c.landpurch#c.poor    "
global cap = "DD lncap"
global bond_cap = "EE c.lncap#c.class c.lncap#c.hvac c.lncap#c.infra c.lncap#c.safeall c.lncap#c.stem c.lncap#c.athletic c.lncap#c.busvehicle c.lncap#c.landpurch"
global fips = "FF i.fips"



program define numbers
args string
local num = 0
disp `nr'
foreach l in "AA" "BB" "CC" "DD" "EE" "FF" {
	if regexm("`string'","`l' ")	local num = `num' + 1
}
disp `num'
scalar num = `num'
end

qui reg main_effect if sample == 1 [aw = enroll], a(fips)
disp e(r2_a)
qui reg main_effect $dem if sample == 1  [aw = enroll], a(fips)
disp e(r2_a)
qui reg main_effect $bond if sample == 1 [aw = enroll], a(fips)
disp e(r2_a)
qui reg main_effect lncap if sample == 1 [aw = enroll], a(fips)
disp e(r2_a)
qui reg main_effect $dem $bond lncap if sample == 1 [aw = enroll], a(fips)
disp e(r2_a)
qui reg main_effect $dem $bond $dem_bond lncap $bond_cap if sample == 1 [aw = enroll], a(fips)
disp e(r2_a)

reg main_effect c.hisp##c.lnam c.black##c.lnam c.frpl##c.lnam c.poor##c.lnam lnam lncap class hvac infra safeall stem athletic busvehicle landpurch [aw = enroll], a(fips)




* Shapley Owen decomposition

local NRVAR = 6

gen explvar = ""
gen label = ""
gen r2j = .
qui reg main_effect $dem $bond $dem_bond lncap $bond_cap i.fips if sample == 1 [aw = enroll]
replace r2j = `e(r2_a)' if _n == 10
replace label = "All" if _n == 10

* dem
local var = "$dem"
replace label = "Demographics" if _n == 1
replace explvar = "`var'" if _n == 1

tuples "$bond" "$dem_bond" "$cap" "$bond_cap" "$fips", disp
numbers "`tuple1'"
local num = num
disp `num'
numbers "`tuple5'"
local num = num
disp `num'

local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .

	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff


* bond
local var = "$bond"
replace label = "Bond characteristics" if _n == 2
replace explvar = "`var'" if _n == 2

tuples "$dem" "$dem_bond" "$cap" "$bond_cap" "$fips"
local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .


	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	local num = num
	disp `num'
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff


* dem_bond
local var = " $dem_bond"
replace label = "Dem x bond" if _n == 3
replace explvar = "`var'" if _n == 3

tuples "$dem" "$bond" "$cap" "$bond_cap" "$fips"

local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .

	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	local num = num
	disp `num'
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff



* cap
local var = " $cap"
replace label = "Capital stock" if _n == 4
replace explvar = "`var'" if _n == 4

tuples "$dem" "$bond" "$dem_bond" "$bond_cap" "$fips"
local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .

	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	local num = num
	disp `num'
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff



* bond_cap
local var = "$bond_cap"
replace label = "Bond x cap stock" if _n == 5
replace explvar = "`var'" if _n == 5

tuples "$dem" "$bond" "$dem_bond" "$cap" "$fips"

local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .

	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	local num = num
	disp `num'
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff

* state
local var = "$fips"
replace label = "State" if _n == 6
replace explvar = "`var'" if _n == 6

tuples "$dem" "$bond" "$dem_bond" "$cap" "$bond_cap"

local N = `ntuples' + 1
gen variables = ""
gen n = _n - 1 if _n <= `N'
gen R2 = .
gen R2plus = .
gen k = .

	qui reg main_effect if sample == 1 [aw = enroll]
	replace R2 = `e(r2_a)' if n == 0
	qui reg main_effect `var' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == 0
	replace k = 0  if n == 0
	replace variables = "none"	 if n == 0

local n = 1	
qui while `n' < `N' {
	noisily disp "`var', `n'"
	qui reg main_effect `tuple`n'' if sample == 1 [aw = enroll]
	numbers "`tuple`n''"
	local num = num
	disp `num'
	replace k = `num'  if n == `n'
	replace R2 = `e(r2_a)' if n == `n'
	qui reg main_effect `var' `tuple`n'' if sample == 1 [aw = enroll]
	replace R2plus = `e(r2_a)' if n == `n'
	replace variables = "`tuple`n''"	 if n == `n'
	local n = `n' + 1
}
gen factk =  round(exp(lnfactorial(k)),1)
gen factpk =  round(exp(lnfactorial(`NRVAR' - k - 1)),1)
scalar define factpp = round(exp(lnfactorial(`NRVAR')),1)
gen diff = factk * factpk * (R2plus - R2) / factpp
sum diff, det
replace r2j = `r(sum)' if explvar == "`var'" 
drop variables n R2 R2plus k factk factpk diff


preserve
keep label r2j
keep if label != ""
sort label 
save temp.dta, replace
restore
drop r2j label explvar



* Build table
use temp.dta, clear

local n = 1

foreach label in "State" "Demographics" "Bond characteristics" "Bond x cap stock" "Capital stock" "Dem x bond" "All" {
	qui	sum r2j if label == "`label'"
	local x = 100 * r(mean)
	local coef_`n': di %9.1f `x'
	local label_`n' = "`label'"
	disp "\`label_`n''"
	disp `coef_`n'' "%"
	local n = `n' + 1
}
local n = 1

	qui	sum r2j if label == "All"
	local all = `r(mean)'
foreach label in "State" "Demographics" "Bond characteristics" "Bond x cap stock" "Capital stock" "Dem x bond" "All" {
	qui	sum r2j if label == "`label'"
	local x = r(mean)
	local y = 100 * `x'/`all'
	local share_`n': di %9.1f `y'
	disp "\`label_`n''"
	disp `share_`n'' "%"
	local n = `n' + 1
}

texdoc init  "$tables/shapleyowen.tex", replace force
tex 		Group of variables $j$ & Explained variation $ R^2_{j}$ & Share of total $ R^2$ \\ \hline	
tex `label_1' & `coef_1'\%	 & `share_1'\%	\\
tex `label_2' & `coef_2'\%	& `share_2'\%	\\
tex `label_3' & `coef_3'\%	& `share_3'\%	\\
tex `label_4' & `coef_4'\%	& `share_4'\%	\\
tex `label_5' & `coef_5'\%	& `share_5'\%	\\
tex `label_6' & `coef_6'\%	& `share_6'\%	\\\hline
tex `label_7' & `coef_7'\%	& 100 \%	
texdoc close

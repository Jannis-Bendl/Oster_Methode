/*

composition_by_institution.do 

*/


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


use "$prepdata/analysis_dataset.dta", clear
rename year fy
merge m:1 leaid fy using  `demo'
drop if _m == 2
drop _m
rename fy year

sort leaid year
merge m:1 leaid year using `temp'
drop if _m == 2
drop _m



* Keep only states that pass McCrary test
keep if fips != 29 & fips != 53 & fips != 40 & fips != 25


drop scale_score subject grade test_enroll
duplicates drop

* Merge bond categories
merge m:1 leaid year using  "$prepdata/bond_cat_amt_clean.dta"
drop if _m == 2
drop _m

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
***** 					0 Merge info on capital stock	 ***************
********************************************************************************

preserve
use "$prepdata/capstock.dta", clear
gen M2 = .
gen T1 = .
gen T2 = .
gen T3 = .
levelsof year, local(Year)
foreach y of local Year {
	_pctile capstock if year == `y', n(100)
	replace T1 = capstock <= `r(r33)' if year == `y'
	replace T2 = capstock > `r(r33)' & capstock <= `r(r67)' if year == `y'
	replace M2 = capstock > `r(r50)' if year == `y'
	replace T3 = capstock > `r(r67)' if year == `y'
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


tsset leaid year
tempvar capter_med
gen `capter_med' = captercile if f.holdbond == 1
tempvar cap_abovemed
gen `cap_abovemed' = M2 if f.holdbond == 1
bysort leaid: egen cap_abovemed = median(`cap_abovemed')



********************************************************************************
***** 						1. Bond composition, all states	 	***************
********************************************************************************


* SES
preserve
gen group = 1 if lowsesT == 1
replace group = 2 if lowsesB == 1
egen n = rowtotal(classP stemP hvacP infraP safeallP athleticP busvehicleP landpurchP)
collapse (sum) classP stemP hvacP infraP safeallP athleticP anyothercatsP  busvehicleP landpurchP n, by(group)
label define ss 2 "Low share FRPL" 1 "High share FRPL"
label values group ss
foreach var in  classP stemP hvacP infraP safeallP athleticP  busvehicleP landpurchP {
	replace `var' = `var'/n
}

drop n
sort group
tempvar ses
save `ses', replace
	graph bar (mean)  landpurchP busvehicleP athleticP classP stemP infraP safeallP hvacP ///
	, over(group, label(labsize(medium))) stack ///
	legend(order(8 "HVAC" 7 "Safety/health" 6 "Other infr" 5 "STEM"  4 "Classrooms" 3 "Athletics"  2 "Transportation" 1 "Land") pos(6) col(4)) xsize(3) ///
	bar(1, color("$ylb")) bar(2, color("$mid6")) bar(3, color("$mid5")) bar(4, color("$mid4")) bar(5, color("$mid3")) bar(6, color("$mid2")) bar(7, color("$mid1")) bar(8, color("$yo")) 
graph export "$outdir/composition_lowSES.png", replace
restore

* Minority
preserve
gen group = 4 if minorT == 1
replace group = 5 if minorB == 1
egen n = rowtotal(classP stemP hvacP infraP safeallP athleticP busvehicleP landpurchP)
collapse (sum) classP stemP hvacP infraP safeallP athleticP anyothercatsP  busvehicleP landpurchP n, by(group)
label define ss 5 "Low share minority" 4 "High share minority"
label values group ss
foreach var in  classP stemP hvacP infraP safeallP athleticP  busvehicleP landpurchP {
	replace `var' = `var'/n
}

drop n
sort group
tempvar minor
save `minor', replace
graph bar (mean)  landpurchP busvehicleP athleticP classP stemP infraP safeallP hvacP ///
	, over(group, label(labsize(medium))) stack ///
	legend(order(8 "HVAC" 7 "Safety/health" 6 "Other infr" 5 "STEM"  4 "Classrooms" 3 "Athletics"  2 "Transportation" 1 "Land") pos(6) col(4)) xsize(3) ///
	bar(1, color("$ylb")) bar(2, color("$mid6")) bar(3, color("$mid5")) bar(4, color("$mid4")) bar(5, color("$mid3")) bar(6, color("$mid2")) bar(7, color("$mid1")) bar(8, color("$yo")) 
graph export "$outdir/composition_minor.png", replace
restore


* Capital stock
preserve
gen group = 7 if cap_abo == 0
replace group = 8 if cap_abo == 1
egen n = rowtotal(classP stemP hvacP infraP safeallP athleticP busvehicleP landpurchP)
collapse (sum) classP stemP hvacP infraP safeallP athleticP anyothercatsP  busvehicleP landpurchP n, by(group)
label define ss 8 "High capital stock" 7 "Low capital stock"
label values group ss
foreach var in  classP stemP hvacP infraP safeallP athleticP  busvehicleP landpurchP {
	replace `var' = `var'/n
}

drop n
sort group
tempvar cap
save `cap', replace
graph bar (mean)  landpurchP busvehicleP athleticP classP stemP infraP safeallP hvacP ///
	, over(group, label(labsize(medium))) stack ///
	legend(order(8 "HVAC" 7 "Safety/health" 6 "Other infr" 5 "STEM"  4 "Classrooms" 3 "Athletics"  2 "Transportation" 1 "Land") pos(6) col(4)) xsize(3) ///
	bar(1, color("$ylb")) bar(2, color("$mid6")) bar(3, color("$mid5")) bar(4, color("$mid4")) bar(5, color("$mid3")) bar(6, color("$mid2")) bar(7, color("$mid1")) bar(8, color("$yo")) 
graph export "$outdir/composition_cap.png", replace
restore


** Build graphs

use `ses', clear
append using `minor'
append using `cap'


* trick to space bars
preserve
clear 
set obs 5
gen group = 3 in 1
replace group = 6 in 2
replace group = 9 in 3
replace group = 12 in 4

gen hvacP = 0
tempfile trick
save `trick', replace
restore
append using `trick'

label var classP "Classroom"
label var stemP "STEM"
label var hvacP "HVAC"
label var infraP "Other inft"
label var safeallP "Safety"
label var athleticP "Athletic"
label var busvehicleP "Transportation"
label var landpurchP "Land purchases"

label define lab 2 "Low share FRPL" 1 "High share FRPL" 5 "Low minority" 4 "High minority" 8 "High cap stock" ///
				7 "Low cap stock" 3 " " 6 " " 

drop if group > 8
				
				
label values group lab

				
graph bar (mean) hvacP stemP safeallP infraP   classP athleticP busvehicleP landpurchP      ///
	,  over(group, relabel(3 " " 6 " ") label(angle(45) labsize(small)) ) stack ///
	legend(order(1 "HVAC" 2 "STEM" 3 "Safety/health"  4  "Other infr" 5 "Classrooms" 6  "Athletics"  7 "Transportation" 8 "Land") pos(6) row(2) size(medium)) xsize(6.5) ///
	bar(8, color("$yo % 8")) bar(7, color("$yo % 13")) bar(6, color("$yo % 25")) bar(5, color("$yo % 60")) bar(4, color("$yo % 68")) bar(3, color("$yo% 77")) bar(2, color("$yo % 85")) bar(1, color("$yo"))
graph export "$outdir/composition_test.png", replace

	
	
graph bar (mean) athleticP classP stemP busvehicleP hvacP landpurchP infraP safeallP            ///
	,  over(group, relabel(3 " " 6 " " 9 " ") label(angle(45) labsize(small))) stack ///
	legend(order(1 "Athletics" 2 "Classrooms" 3 "STEM"  4 "Transportation"  5 "HVAC"  6 "Land"  7 "Other infr" 8 "Safety/health") pos(6) row(2) size()) xsize(6.5) ///
	bar(8, color("$yaleblue % 8")) bar(7, color("$yaleblue % 13")) bar(6, color("$yaleblue % 19")) bar(5, color("$yaleblue % 26")) bar(4, color("$yaleblue % 30")) bar(3, color("$yaleblue% 32")) bar(2, color("$yaleblue % 85")) bar(1, color("$yaleblue"))
graph export "$outdir/composition_hpi.png", replace

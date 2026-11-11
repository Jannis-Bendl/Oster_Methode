/*

prepare_demographics.do

*/

clear all
capture log close
set more off 

local name "mean_effects"
local outfolder "mean_effects"

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

global prepdata 	"${root}/code/paper/QJE_replication_files/datasets"
global outdir 	"${root}/code/paper/QJE_replication_files/figures"
global tables 	"${root}/code/paper/QJE_replication_files/tables"


use "$prepdata/dist_enroll_demo.dta", clear
rename fy year
tsset leaid year
replace sh_dy_econdis = sh_dy_econdis/10 if sh_dy_econdis > 10 & sh_dy_econdis != .
replace sh_dy_econdis = 1 if sh_dy_econdis > 1 & l.sh_dy_econdis > 0.7 & sh_dy_econdis != .
replace sh_dy_econdis = . if sh_dy_econdis > 1 & l.sh_dy_econdis < 0.7 & sh_dy_econdis != .
sort leaid year
merge 1:1 leaid year using "$prepdata/LEA_demographics.dta", nogen
drop fips enroll enrollment agency_type staff_non_teacher_fte_ratio staff_total_fte_ratio flag* // note: non-teacher/total FTE only available since 2015, hence dropped

* rename variables
rename sh_dy_white white
rename sh_dy_black black
rename sh_dy_hisp hisp
rename sh_dy_asian asian
rename sh_dy_econdis frpl
rename est_population_5_17_poverty_pct poor
rename staff_teachers_fte_ratio teachers
rename share_spec_ed_students sped
rename share_english_language_learners el


* Fix teacher variable
_pctile teacher, n(100)
replace teacher = . if teacher <= 0 | teacher > `r(r99)'
tsset leaid year
ipolate teacher year, gen(t)
replace teacher = t if teacher == .
drop t
sort leaid year
save "$prepdata/demographics.dta", replace



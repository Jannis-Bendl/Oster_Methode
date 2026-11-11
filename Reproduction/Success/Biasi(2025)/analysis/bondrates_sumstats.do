* Distribution of bond interest rates using Mergent Muni Database

clear all
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
global outdir 	"${root}/figures/paper"
global tables 	"${root}/tables"

global yaleblue = "0 53 107"


**

insheet using "data/mergent_bonds/AGENT.DLM", delimiter("|") clear
rename v1 id
rename v2 name
keep id name
tempfile name
save `name', replace

insheet using "data/mergent_bonds/ISSUAGNT.DLM", delimiter("|") clear
rename v1 issue_id
rename v2 id
keep issue_id id
duplicates drop
sort id
merge m:1 id using `name', nogen keep(3)
bysort issue_id: gen n = _n
reshape wide id name, i(issue_id) j(n)
tempfile bname
save `bname', replace


insheet using "data/mergent_bonds/BONDINFO.DLM", delimiter("|") clear
rename v1 issue_id
rename v4 coupon_f
gen year_set = floor(v6/10000)
gen year_mat = floor(v5/10000)
egen type = group(v10)
keep issue coup year* type
sort issue_id
merge m:1 issue_id using `bname', nogen keep(3)

* rough way of identifying school districts
gen school = .
forvalues n = 1/32 {
replace school = 1 if regexm(name`n', "SCHOOL DISTR")
}
keep if school == 1

gen mat = year_mat - year_set

reghdfe coup, a(year_set#mat#type) resid
predict coup_res, resid
replace coup_res = _b[_cons] + coup_res

* histogram
su coup_res if year_set >= 1995 & year_set <= 2017, det
local mean: di %6.2f `r(mean)'
local sd: di %6.2f  `r(sd)'
histogram coup_res if year_set >= 1995 & year_set <= 2017, xtitle("Annual interest rate") color("$yaleblue") note("Mean =`mean', sd =`sd'")
graph export "$outdir/bondrates.png", replace

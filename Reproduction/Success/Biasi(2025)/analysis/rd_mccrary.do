/********************************************************************************
rd_mccrary.do 
********************************************************************************/

clear all
capture log close
set more off 
ssc install rddensity, replace

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
* Load data, label state names 
********************************************************************************

local dset = "full"
use "$prepdata/analysis_dataset.dta", clear

drop test_enroll scale_score subject grade
duplicates drop


* State names 
********************************************************************************
gen statename = ""
replace statename =	"Arizona"			if fips ==	4
replace statename =	"Arkansas"			if fips ==	5
replace statename =	"California"		if fips ==	6
replace statename =	"Colorado"			if fips ==	8
replace statename =	"Connecticut"		if fips ==	9
replace statename =	"Delaware"			if fips ==	10
replace statename =	"Florida"			if fips ==	12
replace statename =	"Georgia"			if fips ==	13
replace statename =	"Idaho"				if fips ==	16
replace statename =	"Indiana"			if fips ==	18
replace statename =	"Iowa"				if fips ==	19
replace statename =	"Louisiana"			if fips ==	22
replace statename =	"Maryland"			if fips ==	24
replace statename =	"Massachusetts"		if fips ==	25
replace statename =	"Michigan"			if fips ==	26
replace statename =	"Minnesota"			if fips ==	27
replace statename =	"Mississippi"		if fips ==	28
replace statename =	"Missouri"			if fips ==	29
replace statename =	"Nebraska"			if fips ==	31
replace statename =	"Nevada"			if fips ==	32
replace statename =	"New York"			if fips ==	36
replace statename =	"North Carolina"	if fips ==	37
replace statename =	"North Dakota"		if fips ==	38
replace statename =	"Ohio"				if fips ==	39
replace statename =	"Oklahoma"			if fips ==	40
replace statename =	"Oregon"			if fips ==	41
replace statename =	"Pennsylvania"		if fips ==	42
replace statename =	"Rhode Island"		if fips ==	44
replace statename =	"Texas"				if fips ==	48
replace statename =	"Vermont"			if fips ==	50
replace statename =	"Virginia"			if fips ==	51
replace statename =	"Washington"		if fips ==	53
replace statename =	"West Virginia"		if fips ==	54
replace statename =	"Wisconsin"			if fips ==	55

 
********************************************************************************
* Mccrary figures by state 
********************************************************************************

levelsof fips if margin != ., local(Fips)
foreach fips of local Fips {
	
	* get state name
	tempvar x
	gen `x' = _n if fips == `fips'
	summ `x', meanonly
	local index = r(min)
	local name = statename[`index']
	disp "`name'"
	
	* set lower bound (-.3 except for: AZ, DE, GA, ID, NE, OR)
	local lowb "-.3"
	local h "0.1"
	local highb "0.3"
	if inlist(`fips',10,13) { 
		local lowb "-.15" 
	}
	else if inlist(`fips',31,41) { 
		local lowb "-.25" 
	}
	else if inlist(`fips',4) { 
		local lowb "-.2" 
	}
	else if inlist(`fips',16) { 
		local lowb "-.275" 
	}
	if inlist(`fips',40) { 
		local lowb "-0.4" 
		local highb "0.4" 
		local h "0.2" 
}
		
		qui sum margin if fips == `fips', det
		local lowb = `r(p1)'
		local highb = `r(p95)'

	* plot 
	capt rddensity margin if holdbond == 1 & fips == `fips' , p(3) level(90) all
	local p: di %9.2f `e(pv_p) '
	capt rddensity margin if holdbond == 1 & fips == `fips' , p(3) plot level(90) plot_range(-0.2 0.3) ///
	plot_ciuniform graph_opt(title("`name' (p-value = `p')") xtitle("Vote margin") legend(off))  ///
	cirl_opt(color("$yo % 40")) esll_opt(color("$yo") lw(medthick) lp(solid)) ///
	eslr_opt(color("$ylb") lw(medthick) lp(solid)) ///
	cirr_opt(color("$ylb % 40")) histl_opt(color("$yo % 80") barwidth(.014)) ///
	histr_opt(color("$ylb % 80") barwidth(.010)) // plot_n(10 20) 
	
	* export 
	if _rc == 0 { 
		capt graph export "$outdir/mccrary_`fips'.png", replace
	}
}

foreach fips in 9 12 24 28 32 37 38 42 44	 51 {

	* get state name
	tempvar x
	gen `x' = _n if fips == `fips'
	summ `x', meanonly
	local index = r(min)
	local name = statename[`index']
	disp "`name'"
	
	histogram margin if holdbond == 1 & fips == `fips', bin(10) color("$ylb") xtitle("Vote margin") legend(off) xline(0, lcolor("$yo")) title("`name'")
	graph export "$outdir/mccrary_`fips'.png", replace
}
	
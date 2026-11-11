 /*

rd_figures_stacked.do 

*/

ssc install rddensity, replace
ssc install lpdensity, replace

clear all
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
***** 			LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************

use "$prepdata/analysis_dataset.dta", clear
sort leaid year
rename year fy
merge m:1 leaid fy using  "$prepdata/dist_enroll_demo.dta"
drop if _m == 2
drop _m
rename fy year

preserve
use "$prepdata/nhgis.dta", clear
tsset leaid year
tsfill, full
sort leaid year
bysort leaid: carryforward *, replace
keep leaid year shpr hhinc educcol
replace hhinc = hhinc * 1000
sort leaid year
tempvar controls
save `controls', replace
restore

merge m:1 leaid year using `controls'
drop if _merge==2
drop _merge


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

* program to create leads and lags
cap program drop makevars
program define makevars
	args grpvar yrvar mainvar
	tsset `grpvar' `yrvar'
	forvalues lag=1/4 {
		gen l`lag'`mainvar'=l`lag'.`mainvar'
	}
	forvalues lead=1/8 {
		gen f`lead'`mainvar'=f`lead'.`mainvar'
	}
end	
 	

* Keep only states which pass McCrary test
gen okdens = 1 if fips != 29 & fips != 53  & fips != 40  & fips != 25


preserve
use "$prepdata/stacked_data.dta", clear
keep leaid year cohort
duplicates drop
tempfile temp
save `temp', replace
restore



********************************************************************************
* RD Covariates Tests (Ariel's code)
********************************************************************************

* set sample restrictions
keep if okdens == 1 & fips != 25

 
********************************************************************************
* Create average scale_score by year_district and drop duplicates
********************************************************************************
egen num_weighted = total(scale_score * test_enroll), by(leaid year) 
egen enroll_sum = total(test_enroll), by(leaid year) 
gen scale_score_mean = num_weighted/enroll_sum

drop test_enroll scale_score subject grade
duplicates drop

makevars leaid year cap


sort leaid year
merge 1:m leaid year using `temp', keep(3) nogen

********************************************************************************
* Merge in HPI variable 
********************************************************************************
merge m:1 leaid year using "$prepdata/hpi.dta"
drop if _m==2 
drop _m
 
* set parameters 
local bw = 0.20
local poly = 2 
local bins = 10

* labels and names for loops
local rdvars sh_dy_econdis sh_dy_white shprivate hhinc educcol sshare tr_pp_r te_ci_pp_r scale_score hpi
local title `" "Share low-SES students" "Share white students" "Share students enrolled in private school" "Household income" "Share pop. w/ college or higher"	"State share of capital spending" "Total revenue pp" "Current instructional expenditure pp" "Pooled math and ELA test score" "House price index (HPI)" "'
local ytitle `" "Share low-SES students, election year" "Share white students, election year" "Share enrolled in private school, election year" "Household income" "Share w/ college or higher" "State share of capital spending, election year" "Total revenue pp, election year" "Current instructional expenditure pp, election year" "Mean test score" "House price index (HPI)" "'
local name rd_sharedis rd_sharewhite rd_shareprivate rd_hhinc rd_college rd_sshare rd_revenue rd_currentexp rd_testscore rd_hpi
local yscale `" ".3(.1).6" ".6(.1)1" ".04(.02).12" "30000(5000)55000" ".08(.02).18" "-.05(.05).15" "10000(2000)20000" "6000(1000)11000" "-.6(.2).4" "140(20)220" "'

local n : word count `name'

********************************************************************************
* manual binning (using collapse)
********************************************************************************
preserve 

* keep if in bw range
keep if inrange(margin,-`bw',`bw')

* create bins
local cuts = `bw'/`bins'
egen bin = cut(margin), at(-`bw'(`cuts')`bw')

* collapse 
collapse `rdvars', by(bin)

rename bin margin 

gen margin_d = 1 - (margin < 0)

* shift points to right side of bin so that there is no gap between the two confidence intervals 
replace margin = margin + `cuts'*.95 if margin_d==0

* loop for plots 
forvalues i = 1/`n' {
	local t : word `i' of `title'
	local y : word `i' of `ytitle'
	local v : word `i' of `rdvars'
	local na : word `i' of `name'
	local ylab : word `i' of `yscale'

	* plot 
	twoway (qfitci `v' margin if margin_d==1, clcolor(dkorange*1.2) color(dkorange*.2)) ///
	   (qfitci `v' margin if margin_d==0, clcolor(ebblue*2) color(ebblue*.2)) ///
	   (scatter `v' margin if margin_d==1, color(dkorange*1.2)) ///
	   (scatter `v' margin if margin_d==0, color(ebblue*2)) ///
		, legend(off) xtitle("Vote margin") ytitle("`y'") title("`t'") ylabel(`ylab')
		
	* export	
	graph export "$outdir/`na'_stacked.png", replace	
}
	
restore 



********************************************************************************
***** 						McCrary Test 	***************
********************************************************************************


rddensity margin if holdbond == 1 & okdens == 1, plot  nomass plot_grid(es) p(3)  q(3) hist_range(-0.5 0.5) kernel(uniform)  ///
			graph_opt(title("") xtitle("Vote margin") legend(off))  /// ///
			plot_ciuniform hist_n(20 20)  cirl_opt(color("$yo % 40")) cirr_opt(color("$ylb % 40")) ///
			histl_opt(color("$yo % 80") barwidth(.025)) histr_opt(color("$ylb % 80") barwidth(.025))
 graph export "$outdir/mccrary_stacked.png", replace
 

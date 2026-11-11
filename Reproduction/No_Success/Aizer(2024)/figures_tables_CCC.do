/********
Examine Various first stage regressions using our instruments

********/
clear all
set matsize 5000
set scheme s1color // grpah scheme
version 14.0
global rootdir = "C:/Users/jabef/Desktop/FU Job/Prof.Marcus/Python_Scraper/Oster_Methode/Reproduction/Aizer(2024)"
global datadir = "$rootdir/Analysis/Analysis Sample"
global resultdir = "$rootdir/Analysis/Results"
global graphdir = "$resultdir/Figures"

global figures = 1
global tables = 1
global tables_app = 1

capture mkdir "${resultdir}"
capture mkdir "${graphdir}"

cd "$rootdir/Analysis/"
capture log close
log using "${resultdir}/tables.log", replace

use "${datadir}/combined_analysis_data.dta"

********************
*** Regression Parameters Set
********************

global durvar = "duration1"

global X0 = "${durvar}"
global X1 = "i.birth_year"
global X2 = "i.reason1 honorable"
global X3 = "i.campdum1"
global X4 = "EverRejec Disable1 NonJunior1 flag_age_younger1 flag_age_older1 AgeNonEligible1 age1718 allottee_amount1 allottee_father1 allottee_mother1 flag_interruption log_distance_address_camp1 hispanic_imputed county_urate"
global X6 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county"
global X5 = "m_allottee_amount1 m_allottee_relation1 m_county_urate"
global X7 = "m_school_grade m_hhsize m_farm m_totheight m_weight m_fatherliving m_motherliving m_tenure_county"

global campchars = "flag_camp_instate1 camp_meanprecip camp_meanmintemp camp_meanmaxtemp camp_type1_enc_* log_distance_city_camp11 log_distance_city_camp12"
global peerchars = "peer_wmean_hispanic_imputed peer_wmean_enrollment_age1 peer_wmean_flag_age_younger1 peer_wmean_flag_age_older1 peer_wmean_AgeNonEligible1 peer_wmean_allottee_amount1 peer_wmean_allottee_father1 peer_wmean_allottee_mother1 peer_wmean_flag_interruption"

global iv = "leaveout_duration_yq"

global option_se = "vce(cluster groupayq)"
global option_se_cens = "vce(cluster groupayq)"
global option_bdec = 3

*** define program that replaces R2 in xtreg, fe regressions for output
capture program drop xtregfe_replace_r2
program xtregfe_replace_r2, eclass
	/* 
	 This program replaces the stored r-squared from the xtreg, fe regression.
	 
	 The default is to use "within-r2", which does not take into account the
	 fixed effects in the calculation of the R2. This is different from, for
	 instance when you manually include the FE.
	 
	 The purpose is for outputting: since outreg and related commands by default
	 output the stored e(r2) in the tables, we have to manually replace this to
	 output them into the default R-squared slot.
	*/
	
	* check if the command is xtreg, fe; replace e(r2) if true
	if "`e(cmd)'" == "xtreg" & "`e(model)'" == "fe" {
		ereturn scalar r2 = 1 - e(rss)/e(tss) // replace R2 with Total R2
		}
	* exit and explain that it wasn't replaced for what reason
	if "`e(cmd)'" != "xtreg" | "`e(model)'" != "fe" {
		if "`e(cmd)'" != "xtreg" disp "Not xtreg: did not replace e(r2)"
		if "`e(cmd)'" == "xtreg" & "`e(model)'" != "fe" disp "Not FE: did not replace e(r2)"
		}
end


********************
*** PREPARE DATA START
********************

*** some more variable definitions
tab birth_year, gen(birth_years_) // for xtivreg2
tab reason1, gen (reason1_)
gen stateall = "Both"
gen insample_00 = 1
tab camp_type1_enc, gen(camp_type1_enc_)
gen all = 1

gen insample_05_large = insample_05
replace insample_05_large = 1 if insample_05 == .
quietly tab reason_detailed1, gen(rd1_)

replace weight = weight / 100
label var weight "Weight (100 pounds) (CO only)"

gen P70m0 = P70
replace P70m0 = 0 if P70 == .
label var P70m0 "P(70), imputed to 0 if missing" 

gen county_urate = murate1937 if inrange(enrollment_year1,1937,1938)
replace county_urate = murate1940 if inrange(enrollment_year1,1939,1940)

gen cens_matched = cens_match_type != 0
label var cens_matched "1940 Cens: Matched"

gen ww2_matched = ww2_serial != .
label var ww2_matched "WWII: Matched"

gen dmf_machine_ldeath_age = log(dmf_machine_ageatdeath)

label var camp_type1_enc_1 "Camp Type: Department of Grazing"
label var camp_type1_enc_2 "Camp Type: Federal Reclamation Project"
label var camp_type1_enc_3 "Camp Type: Fish and Wildlife Service"
label var camp_type1_enc_4 "Camp Type: National Forest"
label var camp_type1_enc_5 "Camp Type: National Monument"
label var camp_type1_enc_6 "Camp Type: National Park"
label var camp_type1_enc_7 "Camp Type: Soil Conservation"
label var camp_type1_enc_8 "Camp Type: State Park"
label var camp_type1_enc_9 "Camp Type: Other"
label var reason1_1 "Reason ended: End of term"
label var reason1_2 "Reason ended: Employment"
label var reason1_3 "Reason ended: Convenience of the government"
label var reason1_4 "Reason ended: Urgent and Proper Call"
label var reason1_5 "Reason ended: Deserted"
label var reason1_6 "Reason ended: Rejected upon  examination"
label var reason1_7 "Reason ended: No Record"
label var county_urate "White Male Unemployment Rate 1937/1940"
label var dmf_machine_ldeath_age "Log Death Age from DMF"

* generate missing flags
foreach var in $X4 $X6 bmi {
	gen m_`var' = `var' == .
	local lab: variable label `var'
	label var m_`var' "Missing `lab'"
	}
	
gen m_allottee_relation1 = allottee_relation1 == ""
label var m_allottee_relation1 "Missing allottee relation"

gen allnonmiss_NM = 1
foreach var in $X5 {
	replace allnonmiss_NM = 0 if `var' == 1
	}

gen allnonmiss = 1
foreach var in $X5 $X7 {
	replace allnonmiss = 0 if `var' == 1
	}
	
* mean camp characteristics
sort ccccampnumber1 enrollment_yq1
foreach var in duration1 allottee_father allottee_mother enrollment_age1 hispanic_imputed { 
	by ccccampnumber1 enrollment_yq1: egen cm_`var' = mean(`var')
	local lab: variable label `var'
	label var cm_`var' "Camp Mean `lab'"
	}

*** last observed height, weight, and school grade
gen ccc_cw_height = ww2_height_r
replace ccc_cw_height = totheight if ccc_cw_height == . & m_totheight == 0

gen ccc_cw_weight = ww2_weight_r 
replace ccc_cw_weight = weight if ccc_cw_weight == . & m_weight == 0

gen ccc_cw_educ = cw_years_educ
replace ccc_cw_educ = school_grade if ccc_cw_educ == . & m_school_grade == 0

gen nonmissing_xvars = ccc_cw_height != . & ccc_cw_weight != . & ccc_cw_educ != .
	
* make sure everyone has death age and duration1
gen sampletake = 1
replace sampletake = 0 if ccccampnumber1 == ""
replace sampletake = 0 if groupayq == .
replace sampletake = 0 if duration1 == .

* special regression sample for those we can calculate camp and peer chars.
xtreg ldeath_age  ${peerchars} ${campchars} if sampletake == 1 & death_age >= 45 & ccccampnumber1 != "" & groupayq != .  & death_age != . & duration1 != . , $option_se fe
gen death_regsample = e(sample)

tempfile preimpute
save `preimpute'

*** imputation of variables
* first impute the county urates with county values
replace county_urate = murate1937 if enrollment_year1 < 1937
replace county_urate = murate1940 if enrollment_year1 > 1940

* impute the missing values as average
foreach var in $X4 $X6 {
	quietly sum `var'
	replace `var' = `r(mean)' if `var' == .
	}
	
* these values were median values of 1937 and 1940 unemployment values across CO and NM counties
gen urate_abv = (county_urate >= .0632534) if enrollment_year1 < 1939
replace urate_abv = (county_urate >=.0514035) if enrollment_year1 >= 1939

label var urate_abv "From County with Above Median Unemployment Rate"

drop if sampletake == 0

tempfile regfile
save `regfile'

*** PREPARE DATA END
********************


*******************************************************************************
******************************** BEGIN FIGURES ********************************
*******************************************************************************
if $figures == 1 {

********************
*** FIGURE 1 Distribution of Service Duration for CCC
********************

*** Histogram of Duration
* shorter durations and in months
gen duration1_mo = duration1 * 12
hist duration1_mo if duration1_mo <= 36, w(1) xtitle("First Duration (Months)") xlabel(0(6)36) xtick(0(1)36) ///
	xline(6) xline(12) xline(18) xline(24) xline(30) xline(36) lw(0)
graph save "${graphdir}/hist_dur_mo.gph", replace
graph export "${graphdir}/png/hist_dur_mo.png", replace

********************
*** FIGURE 2 Distribution of Reason for Discharge for CCC
********************

* generate some data
tab reason1, matcell(A)
gen reason1_graph = _n if _n<=7
svmat A
rename A1 reason1_count
egen reason1_count_sum = sum(reason1_count)
gen reason1_dens = reason1_count/reason1_count_sum
tabstat duration1, by(reason1) save

gen reason1_means = .
forvalues i = 1(1)7 {
	mat def Q = r(Stat`i')
	replace reason1_means = Q[1,1] if reason1_graph == `i'
	}
label val reason1_graph reas
format reason1_means %9.2f

twoway (bar reason1_dens reason1_graph,  ///
	xlabel(1(1)7, value) xtick(1(1)7) ytitle("Density") ///
	xtitle("Reasons for Discharge (CCC)")) ///
	(scatter reason1_dens reason1_graph, mlabel(reason1_means) mlabangle(45)) ///
	, legend(off) graphregion(color(white)) bgcolor(white)
graph save "${graphdir}/hist_reason.gph", replace
graph export "${graphdir}/png/hist_reason.png", replace

********************
*** FIGURE 3 Determinants of Duration
********************

global ifstat = "if death_age >= 45 & death_age != ."

* 4) cohort county dummies, individual controls camp and peer controls
xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat , $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")

*** plot the coefficients and their stadnard errors
* retrieve estimates and SE
local mlen : word count ${X4} ${X6}  // total number of variables to retrieve
disp `mlen'
mat def Bb = J(`mlen',2,.)
mat rownames Bb = ${X4} ${X6}
mat colnames Bb = b se

foreach var in $X4 $X6 {
	local rown = rownumb(Bb,"`var'")
	mat Bb[`rown',1] = _b[`var']
	mat Bb[`rown',2] = _se[`var']
	}

* crate variables out of retrieve values
svmat Bb
rename Bb1 plt_b_est
rename Bb2 plt_b_se

* assign each row to a variable
gen plt_names = ""
local i = 1
foreach var in $X4 $X6 {
	replace plt_names = "`var'" if _n == `i'
	local i = `i' + 1
	}
replace plt_b_est = . if plt_b_est == 0 & plt_b_se == 0
* remove two variables for plotting
replace plt_b_est = . if plt_names == "Disable1"
replace plt_b_est = . if plt_names == "NonJunior1"
replace plt_b_se = . if plt_b_est == .

* define row and 95% CI
gen plt_b_se_H = plt_b_est + 1.96*plt_b_se
gen plt_b_se_L = plt_b_est - 1.96*plt_b_se

gsort -plt_b_est
gen plt_lines = _n if plt_b_est != .

* label the values of line for plotting
label def plt_lines_lbl 0 "null", replace

quietly sum plt_lines
forvalues i = 1(1)`r(max)' {
	local var = plt_names[`i']
	local varl : variable label `var'
	* change label for ease of graphing
	local varl = subinstr("`varl'"," (CO only)","",.)
	local varl = subinstr("`varl'"," : Enrollment 1","",.)
	local varl = subinstr("`varl'"," (dollars per month)","",.)
	local varl = subinstr("`varl'"," (imputed using hispanic index)"," (imputed)",.)
	local varl = subinstr("`varl'","Reported age older than DMF or oldest reported","Reported older age",.)
	local varl = subinstr("`varl'","Reported age younger than DMF or oldest reported","Reported younger age",.)
	local varl = subinstr("`varl'","Household size excluding applicant","Household size",.)
	local varl = subinstr("`varl'","Gap in service (more than 3 months)","Gap in service (>3 mo)",.)
	local varl = subinstr("`varl'","Log distance from home to camp","Log home-camp distance",.)
	label def plt_lines_lbl `i' "`varl'", add
	}
	
label val plt_lines plt_lines_lbl

gen plt_sig95 = ~inrange(0,plt_b_se_L,plt_b_se_H)
replace plt_sig95 = . if plt_b_est == .

* plot
quietly sum plt_lines
local mlen = `r(max)'
twoway (scatter plt_lines plt_b_est if plt_sig95 == 1, xline(0) msize(1.1) mcolor(green) msymbol(D)) ///
	(scatter plt_lines plt_b_est if plt_sig95 == 0, msize(1.1) mcolor(green) msymbol(X)) ///
	(rcap plt_b_se_H plt_b_se_L plt_lines, hor lcolor(orange))  ///
	, ylabel(1(1)`mlen',val angle(0)) ytitle("") xlabel(-0.3(0.1)0.3) legend(off)
graph save "${graphdir}/Duration_Coefs.gph", replace
graph export "${graphdir}/png/Duration_Coefs.png", replace
	
disp $meany

drop plt_b_est plt_b_se_H plt_b_se_L plt_lines plt_sig95 plt_b_se plt_names

********************
*** FIGURE 4 Binscatter Plot (Death Age)
********************

sort duration1
 
*** (Cattaneo et al)
* note this may error out when running for the first time 
* but when you run agin it works
global v = 0
global p = 1
global s = 1
global nb = 20

* ssc install binsreg

label var ldeath_age "Log Death Age"
label var duration1 "Duration"

foreach yvar in ldeath_age {
if "`yvar'" == "ldeath_age" global ifstat = "if death_age >= 45"

local ytitle : variable label `yvar'

/*
* bin scatter with optimal nbins
binsreg ${yvar} duration1 $ifstat , ///
	deriv( $v ) dots(1 1) ///
    randcut(1) ///
	polyreg(1) plotxrange(0 4) cb(T) ///
	xtitle("Duration") ytitle("Log Death Age")

* bin scatter with 20 nbins but optimal selection of p and s
binsreg ${yvar} duration1 $ifstat , ///
	deriv( $v )  nbins($nb) dots(T) ///
	pselect(1 2 3) sselect(1 2 3) randcut(1) ///
	polyreg(1) plotxrange(0 4) cb(T) ///
	xtitle("Duration") ytitle("Log Death Age")
*/
** controlling for birth year
* bin scatter with optimal nbins
capture noisily binsreg `yvar' duration1 $ifstat , absorb(birth_year) ///
	deriv( $v ) dots( ${p} ${s} ) ///
    randcut(1) ///
	polyreg(1) plotxrange(0 4) cb(T) ///
	xtitle("Duration") ytitle("`ytitle'") cbplotopt(lcolor(bg) fcolor(navy*0.5))
binsreg `yvar' duration1 $ifstat , absorb(birth_year) ///
	deriv( $v ) dots( ${p} ${s} ) ///
    randcut(1) ///
	polyreg(1) plotxrange(0 4) cb(T) ///
	xtitle("Duration") ytitle("`ytitle'") cbplotopt(lcolor(bg) fcolor(navy*0.5))
graph save "${graphdir}/binscatter_CCFF_`yvar'_optBin.gph", replace
graph export "${graphdir}/png/binscatter_CCFF_`yvar'_optBin.png", replace
* bin scatter with 20 nbins but optimal selection of p and s
binsreg `yvar' duration1 $ifstat , absorb(birth_year) ///
	deriv( $v )  nbins(${nb}) dots(T) ///
	pselect(1 2 3) sselect(1 2 3) randcut(1) ///
	polyreg(1) plotxrange(0 4) cb(T) ///
	xtitle("Duration") ytitle("`ytitle'") cbplotopt(lcolor(bg) fcolor(navy*0.5))
graph save "${graphdir}/binscatter_CCFF_`yvar'_Bin${nb}.gph", replace
graph export "${graphdir}/png/binscatter_CCFF_`yvar'_Bin${nb}.png", replace
}

********************
*** FIGURE 5 Sensitivity to Controls (Death Age)
********************

*ssc install tuples

* define y var
foreach yvar in ldeath_age {

*** split into finer bins
global x1 = "EverRejec Disable1 NonJunior1" 
global x2 = "flag_age_younger1 flag_age_older1 AgeNonEligible1 age1718" 
global x3 = "allottee_amount1 allottee_father1 allottee_mother1 flag_interruption m_allottee_amount1 m_allottee_relation1 "
global x4 = "log_distance_address_camp1 hispanic_imputed county_urate m_county_urate"
global x5 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county m_school_grade m_hhsize m_farm m_totheight m_weight m_fatherliving m_motherliving m_tenure_county"
global x6 = "flag_camp_instate1 camp_meanprecip camp_meanmintemp camp_meanmaxtemp camp_type1_enc_* log_distance_city_camp11 log_distance_city_camp12"
global x7 = "peer_wmean_hispanic_imputed peer_wmean_enrollment_age1 peer_wmean_flag_age_younger1 peer_wmean_flag_age_older1 peer_wmean_AgeNonEligible1 peer_wmean_allottee_amount1 peer_wmean_allottee_father1 peer_wmean_allottee_mother1 peer_wmean_flag_interruption"
global x8 = "groupayq"
global ifstat = "if death_age >= 45"

*** first work let groupayq float

* define the list of coefficients to iterate over
local nlist = "x1 x2 x3 x4 x5 x6 x7 x8"
local totctrls : word count `nlist' // total # of controls

* define matrices for storage
local rown = `totctrls' + 1
mat def A = J(`rown',3,.)
mat colnames A = min mean max
* for row naming of matrices
local q = "0"
forvalues jj = 1(1)`totctrls' {
	local q = "`q' `jj'"
	}
mat rownames A = `q'

* complete spec
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample) // to keep sample size consistent

*** base spec with 0 controls
reg `yvar' $X0 $X1 $ifstat & qin == 1 , $option_se
* store in matrix
mat def A[1,1] = _b[${X0}]
mat def A[1,2] = _b[${X0}]
mat def A[1,3] = _b[${X0}]

*** run loop
forvalues i = 1(1)`totctrls' { 
	tuples `nlist', min(`i') max(`i') // tuples command (ssc install) selects random subset from given list
	
	* n choose k formula to define the total number of regs that need to run
	local k = round(exp(lnfactorial(`totctrls'))/(exp(lnfactorial(`i'))*exp(lnfactorial(`totctrls'-`i'))),1) //  n choose k formula
	
	local mincoeff = 9999999 // for storage
	local maxcoeff = -9999999 // for storage
	local sumcoeff = 0 // for storage

	** looping over the regression specifications
	forvalues j = 1(1)`k' {
		disp "`tuple`j''"
		
		* define the control variables
		global controlset = ""
		forvalues q = 1(1)`totctrls' { // loop that adds each global set in
			if strpos("`tuple`j''","x`q'") global controlset = "$controlset ${x`q'}" 
		}
		* for the groupayq variable, do some additional things:
		if !strpos("$controlset","groupayq") {
			local regspec = "reg"
			local regspec_fe = ""
			}
		if strpos("$controlset","groupayq") {
			global controlset = subinstr("$controlset","groupayq","",.) // remove "groupayq" from controls
			local regspec = "xtreg"
			local regspec_fe = "fe"
			}
		
		quietly `regspec' `yvar' $X0 $X1 $controlset $ifstat & qin == 1 , $option_se `regspec_fe'
		disp _b[${X0}]
		local mincoeff = min(`mincoeff',_b[${X0}])
		local maxcoeff = max(`maxcoeff',_b[${X0}])
		local sumcoeff = `sumcoeff' + _b[${X0}]
	}
	local meancoeff = `sumcoeff'/`k'
	
	local ii = `i' + 1
	mat def A[`ii',1] = `mincoeff'
	mat def A[`ii',2] = `meancoeff'
	mat def A[`ii',3] = `maxcoeff'
	}
	
drop qin 

putexcel set "${resultdir}/sensitivity.xlsx", sheet("`yvar'", replace) modify
putexcel A1 = matrix(A,names)
putexcel clear

preserve
clear
* create dataset with the estiamted values
svmat A, name(col)

* for graphing...
gen nums = _n - 1 
local maxnums = _N - 1
quietly sum max
local maxl = ceil(1.05*`r(max)'*1000)/1000
quietly sum min
local minl = floor(0.60*`r(min)'*1000)/1000
local dr = (`maxl' - `minl')/5
if "`yvar'" == "ldeath_age" local ylabelt = "ylabel(0.004(0.002)0.016)"
else local ylabelt = "ylabel(`minl'(`dr')`maxl')"

* graph

twoway (line min nums, lp(.-)) (line mean nums) (line max nums, lp(--)), ///
	xtitle("Number of Control Groups") ytitle("Coefficient Estimate") ///
	xlabel(0(1)`maxnums') `ylabelt' legend(order(1 "Min" 2 "Mean" 3 "Max") rows(1))
graph save "${graphdir}/sensitivity_groupayq_float_`yvar'.gph", replace
graph export "${graphdir}/png/sensitivity_groupayq_float_`yvar'.png", replace
restore
}


********************
*** FIGURE 6 Effect of Duration to Probability of Survival to Ages
********************

global controls = "birth_years_* $X4 $X5 $X6 $X7 $campchars $peerchars"
global testsamples = "insample_00"
global state = "Both"

* should consolidate this and regressions when running together to save time
matrix define OLScoefs = J(46,4,.)
matrix define RAWrates = J(46,2,.)

matrix colnames OLScoefs = "est_all" "se_all" "est_m0" "se_m0"
matrix colnames RAWrates = "mean Pxx_all" "mean Pxx_m0"

local j = 1
forvalues i = 46(1)90 {
	disp "age `i'"
	gen p`i'a = death_age >= `i'
	replace p`i'a = . if death_age == .

	gen p`i'm0 = death_age >= `i'
	replace p`i'm0 = 0 if death_age == .


	* for looping purposes
	if inlist("$state","CO","NM") 	global statevar = "state"
	if "$state" == "Both" 		  	global statevar = "stateall"
	if "$se" == "Cluster"		  	global vceoption = "vce(cluster groupayq)"
	if "$se" == "Standard"			global vceoption = ""
	if "$se" == "Cluster"		  	global vceoption2 = "cluster(groupayq)"
	if "$se" == "Standard"			global vceoption2 = ""
	
	* mean rate
	quietly sum p`i'a ${ifstat} & ccccampnumber1 != "" & ${testsamples} == 1 & $statevar == "$state"
	matrix RAWrates[`j',1] = `r(mean)' 
	quietly sum p`i'm0 ${ifstat} & ccccampnumber1 != "" & ${testsamples} == 1 & $statevar == "$state"
	matrix RAWrates[`j',2] = `r(mean)'
	
	local c1 = 1
	local c2 = 2
	foreach impute in "a" "m0" {
		global outcome = "p`i'`impute'"
		global yvarrest = "${outcome} != ."
		
		* OLS
		quietly xtreg ${outcome} ${durvar} ${controls_show} ${controls} ${ifstat} & ccccampnumber1 != "" & ${yvarrest} & ${testsamples} == 1 & $statevar == "$state", fe ${vceoption}
		matrix OLScoefs[`j',`c1'] = _b[duration1]
		matrix OLScoefs[`j',`c2'] = _se[duration1]
		
		local c1 = `c1' + 2
		local c2 = `c2' + 2
	
	}
	
	local j = `j' + 1
	
	drop p`i'a p`i'm0
	}


svmat OLScoefs
gen OLS_CI95_L = OLScoefs1 - 1.96 * OLScoefs2
gen OLS_CI95_H = OLScoefs1 + 1.96 * OLScoefs2

foreach var in OLScoefs1 OLScoefs2 OLS_CI95_L OLS_CI95_H  {
	rename `var' `var'_a
	}

gen OLS_CI95_L = OLScoefs3 - 1.96 * OLScoefs4
gen OLS_CI95_H = OLScoefs3 + 1.96 * OLScoefs4


rename OLScoefs3 OLScoefs1
rename OLScoefs4 OLScoefs2


foreach var in OLScoefs1 OLScoefs2 OLS_CI95_L OLS_CI95_H  {
	rename `var' `var'_m0
	}
svmat RAWrates
rename RAWrates1 RAWrates_a
rename RAWrates2 RAWrates_m0


gen plotx = 46 + _n - 1 if OLScoefs1_a != .

save "temp_${suffix}.dta", replace

quietly sum death_age, d
local p25 = `r(p25)'
local p75 = `r(p75)'

* just OLS
twoway (rarea OLS_CI95_H_a OLS_CI95_L_a plotx, fcolor(none)) (scatter OLScoefs1_a plotx) ///
	(line RAWrates_a plotx, yaxis(2) lpattern(--)) ///
	, yline(0) xtitle("Probability of Survival Age") ytitle("Coefficient", axis(1)) ytitle("Survival Rate", axis(2)) ///
	legend(label(1 "OLS 95% CI") label(2 "OLS Coeff")  label(3 "Raw survival rate"))
graph save "${graphdir}/P_age_ols.gph", replace
graph export "${graphdir}/png/P_age_ols.png", replace
*** end figures

drop OLScoefs* OLS_CI95_L* OLS_CI95_H* RAWrates* plotx

}
*******************************************************************************
********************************* END FIGURES *********************************
*******************************************************************************


*******************************************************************************
***************************** BEGIN MAIN TABLES *******************************
*******************************************************************************
if $tables == 1 {
********************
*** Table 1: Sample Summary Statistics
*** Appendix Table : Full Summary Statistics
********************
clear
use `preimpute'

global summvar_app = "birth_year enrollment_age1 enrollment_year1 flag_age_younger1 flag_age_older1 age1718 AgeNonEligible1 allottee_father1 allottee_mother1 NonJunior1 hispanic_imputed"
global summvar_app_co = "school_grade hhsize farm totheight weight bmi underweight overweight fatherliving motherliving tenure_county prev_job murate1937 murate1940"
global summvar_service = "allottee_amount1 duration1 EverRejec Disable1 flag_interruption reason1_* honorable"
global summvar_camp = "distance_address_camp1 distance_city_camp11 distance_city_camp12 camp_meanprecip camp_meanmintemp camp_meanmaxtemp cm_hispanic_imputed camp_type1_enc_*"
global summvar_outcomes = "death_age flag_death_age P70 P70m0 P70m_discharge"
global summvar_cens = "cens_matched"
global summvar_cens_1940 = "cens_Year_of_Birth cens_age cens_hispanic cens_white cens_evermarried cens_in_labor_force cens_working cens_wage_working cens_Home_State_CO cens_Home_State_NM cens_years_educ cens_parent_present cens_dad_years_educ cens_mom_years_educ cens_hhincome cens_mom_native cens_dad_native cens_owns_home cens_houseval cens_moved"
global summvar_ww2 = "ww2_matched ww2_birthyear ww2_eyear ww2_yrsed ww2_height_r ww2_weight_r ww2_bmi ww2_evermarried ww2_home_state_CO ww2_moved ww2_home_state_NM ww2_bpl_CO ww2_bpl_NM ww2_bpl_restUS"

global summvar_cens_b1940 = "" // before 1940
global summvar_cens_a1940 = "" // after 1940
foreach var of varlist $summvar_cens $summvar_cens_1940 {
	local lab : variable label `var'
	gen `var'_b1940 = `var' if Eligible1940 == 1
	gen `var'_a1940 = `var' if Eligible1940 == .
	label var `var'_b1940 "`lab'"
	label var `var'_a1940 "`lab'"
	
	global summvar_cens_b1940 = "$summvar_cens_b1940" + "`var'_b1940 "
	global summvar_cens_a1940 = "$summvar_cens_a1940" + "`var'_a1940 "
	}

global summvarlist = "${summvar_app} ${summvar_app_co} ${summvar_service} ${summvar_camp} ${summvar_outcomes} ${summvar_cens} ${summvar_cens_b1940} ${summvar_cens_a1940} ${summvar_ww2}"

keep sampletake death_regsample ${summvarlist}
order ${summvarlist}, first

outreg2 using "${resultdir}/SummStats.xml" if sampletake == 1, replace sum(log) label cttop("Analytic Sample") eqkeep(N mean sd) keep(${summvarlist}) addnote("Analytic Sample All enrollment variables pertain to first enrollment")
outreg2 using "${resultdir}/SummStats.xml" if sampletake == 1 & death_age != . & death_age >= 45, append sum(log) label cttop("Mortality Sample") eqkeep(N mean sd) keep(${summvarlist}) 
outreg2 using "${resultdir}/SummStats.xml" if sampletake == 1 & death_regsample == 1, append sum(log) label cttop("Regression Sample") eqkeep(N mean sd) keep(${summvarlist}) 

drop $summvar_cens_b1940 $summvar_cens_a1940

clear
use `regfile'

********************
*** Table 2: Comparison with Contemporary Censuses
********************
* provided in separate file

********************
*** Table 3: Effect of Duration on Long-term Outcomes (Longevity)
*** Appendix Table : Full Death Age Regressions
*** Appendix Table : Preditors of Missing Death Age
********************

foreach yvar in ldeath_age flag_death_age  {

if "`yvar'" == "ldeath_age" global ifstat = "if death_age >= 45"
if "`yvar'" == "death_age" global ifstat = "if death_age >= 45"
if "`yvar'" == "flag_death_age" global ifstat = "if all == 1"

* simple linear regression

* get the most restrictive sample and only use that
xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)

* set what to take mean over
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"

* 1) raw
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

* 2) with Birth Dummies and county-quarter
quietly xtreg `yvar' $X0 $X1 $ifstat & qin == 1, fe $option_se
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

* 3) birth, county dummies, all CO controls, missing controls county-quarter
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6}) label

* 4) cohort county dummies, all CO controls, missing controls, camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + CO only
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

drop qin
}



* Oster bound on most spec 6)
quietly xtreg ldeath_age $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)
* run areg, because groupayq variables are significant controls (and how that's how we report R2)
areg ldeath_age $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se a(groupayq)
quietly sum death_age $ifstat & e(sample) == 1
local meany = `r(mean)'
disp `meany'

local rmax = min(1.3*`e(r2)' , 1)
psacalc beta ${X0}, rmax(`rmax') delta(1)
local delta_pos = r(beta)
psacalc beta ${X0}, rmax(`rmax') delta(-1)
local delta_neg = r(beta)
local max = max(`delta_pos',`delta_neg')
local min = min(`delta_pos',`delta_neg')
local olower : display %9.4f `min'
local oupper : display %9.4f `max'
local olower_m : display %9.4f (1+`min')*`meany'
local oupper_m : display %9.4f (1+`max')*`meany'

local o_bounds = "[ `olower';`oupper']"
local o_bounds_m = "[ `olower_m';`oupper_m']"
disp "Oster bounds of coefficients: `o_bounds'"
disp "Oster bounds of mean effects: `o_bounds_m'"
drop qin

********************
*** Table 4: IV Estimates
*** Appendix Table : Full IV Estimates
********************
** defining stars
capture program drop stars
program define stars, rclass
	args varls
	local tstat = abs(_b[`varls']/_se[`varls'])
	if `tstat' < 1.645 return local starrs = " "
	if `tstat' > 1.645 & `tstat' <= 1.96 return local starrs = "*"
	if `tstat' > 1.96 & `tstat' <= 2.567 return local starrs = "**"
	if `tstat' > 2.567 return local starrs = "***" 
end
***
gen COG = reason1 == 3
gen EOTCOG = inlist(reason1,1,3)

************************
foreach Xvar in duration1  {
foreach iv in COG {
global iv = "`iv'"
global X0 = "`Xvar'"
foreach yvar in ldeath_age  {

*global ifstat = "if death_age >= 45 & duration1 <= 3"

foreach sampling in basic { 
if "$iv" == "COG"  {
	
	if "`sampling'" == "basic" {
	local addif = "& EOTCOG == 1"
	global samples = "EOTCOG"	
	}
	
	
	}
	
global ifstat = "if death_age >= 45 `addif'"

local model = "xtreg"
local fixedeffect = "fe"
local ivmodel = "xtivreg"


* simple linear regression

* get the most restrictive sample and only use that
xtreg `yvar' ${iv} $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se `fixedeffect'
gen qin = e(sample)


* set what to take mean over
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"

sum `meanyvar' if qin == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")

* 1) raw
* OLS
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly reg $X0 ${iv} $ifstat & qin == 1 , $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly reg `yvar' ${iv} $ifstat & qin == 1 , $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly ivregress 2sls `yvar' (${X0} = ${iv}) $ifstat & qin == 1, $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", replace bdec($option_bdec) ctitle("No Controls") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'","FE","None","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label
	
* 2) with Birth Dummies and county-quarter
* OLS
quietly `model' `yvar' $X0 $X1 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $ifstat & qin == 1, `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label

* 3) birth, county-quarter dummies, all CO controls, missing controls county-quarter
* OLS
quietly `model' `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se `fixedeffect'
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label


* 4) cohort county dummies, all CO controls, missing controls, camp chars
* OLS
quietly `model' `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se `fixedeffect'
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1, `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
* OLS
quietly `model' `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se `fixedeffect'
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1, `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
* OLS
quietly `model' `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se `fixedeffect'
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1, `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1, `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("Add Camp FE") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ,Camp","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label
	
* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + CO only
* OLS
quietly `model' `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO", $option_se `fixedeffect'
stars ${X0}
local ols_est = strtrim(string(round(_b[${X0}],0.001),"%9.3f")+r(starrs))
local ols_se = "("+string(_se[$X0],"%9.3f")+")"

* FS
quietly `model' $X0 ${iv} $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO", `fixedeffect' $option_se
stars ${iv}
local fs_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local fs_se = "("+string(_se[${iv}],"%9.3f")+")"
quietly test ${iv}
local fstat = string(`r(F)',"%9.2f")

* RF
quietly `model' `yvar' ${iv} $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO", `fixedeffect' $option_se
stars ${iv}
local rf_est = strtrim(string(round(_b[${iv}],0.001),"%9.3f")+r(starrs))
local rf_se = "("+string(_se[${iv}],"%9.3f")+")"

* IV
quietly `ivmodel' `yvar' (${X0} = ${iv}) $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO", `fixedeffect' $option_se

outreg2 using "${resultdir}/IV_${X0}_${iv}_`sampling'_`fixedeffect'.xml", append bdec($option_bdec) ctitle("CO Only") ///
	addtext("Mean Dep",${meany},"OLS Est","`ols_est'","OLS SE","`ols_se'","FS Est","`fs_est'","FS SE","`fs_se'","FS F-stat","`fstat'", ///
			"RF Est","`rf_est'","RF SE","`rf_se'", ///
			"FE","BD,CYQ,Camp","Sample","${samples}","Reason","N") ///
	keep(${X0} ${keepdum}) label
drop qin
	}
}
}
}

********************
*** Table 5: Census and WWII Estimates (Labor Market)
*** Table 6: Census and WWII Estimates (Mobility)
*** Appendix Tables : Full Results
* note that the results in main tables correspond to specification (6)
********************

*** Census Results
clear
use `regfile'

*** examine education comparison
sort school_grade cens_years_educ
by school_grade cens_years_educ: gen dup = _n
by school_grade cens_years_educ: gen Neduc = _N


*** do the sample selection
*keep if cens_match_type != . // only people matched to Census
tab Eligible1940, m
keep if Eligible1940 == 1 // only who are currently not serving in 1940

*** ADDITIONAL RESTRICTIONS FOR THE WAGE EQUATION
gen cens_wage_obs = .
replace cens_wage_obs = 1 if enrollment_year1 < 1939 & discharge_year1 < 1939
replace cens_wage_obs = 0 if enrollment_year2 != . & discharge_year2 != . & enrollment_year2 <= 1939 & discharge_year2 >= 1939
replace cens_wage_obs = 0 if enrollment_year3 != . & discharge_year3 != . & enrollment_year3 <= 1939 & discharge_year3 >= 1939
replace cens_wage_obs = 0 if enrollment_year4 != . & discharge_year4 != . & enrollment_year4 <= 1939 & discharge_year4 >= 1939
replace cens_wage_obs = 0 if cens_wage_obs == .

replace cens_wage = 0 if cens_wkswork1 == 0
replace cens_wage = 0 if cens_wage == . & cens_wkswork1 == 0

*** OLS
*** start regressions
foreach yvar in cens_matched cens_in_labor_force cens_working  ///
	cens_wkswork1 cens_wage cens_lwage_working  {
	
	if "`yvar'" == "cens_matched" {
		global ifstat = "if all == 1"
		local exp = ""
		}
	if "`yvar'" != "cens_matched" {
		global ifstat = "if cens_matched == 1"
		local exp = "" 
		
		if inlist("`yvar'","cens_wkswork1","cens_wage","cens_lwage_working") {
			global ifstat = "if cens_matched == 1 & cens_wage_obs == 1"
			}
			
			
		}
	
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local meanyvar = "`yvar'"
	if "`yvar'" == "cens_lwage_working" local meanyvar = "cens_wage_working" 
	if "`yvar'" == "cens_lhouseval" local meanyvar = "cens_houseval"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `exp' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) CO 
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	
	drop qin
}

********************
*** Table 5: WWII Results
********************
clear
use `regfile'

*** regression
*** start regressions
foreach yvar in ww2_matched ww2_eyear ww2_bmi ww2_height_r {

	if "`yvar'" == "ww2_matched" {
		global ifstat = "if all == 1"
		local ww2_exp = ""
		}
	if "`yvar'" != "ww2_matched" {
		global ifstat = "if insample_ww2 == 1"
		local ww2_exp = "ww2_exp"
		}
	* simple linear regression

	*** controling for the "experience" or "time since out"
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local meanyvar = "`yvar'"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label
	
	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	
	* 9) CO 
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	drop qin
	
}

********************
*** Table 5 Table 6: Census and WWII combined
********************
clear
use `regfile'

gen cw_moved_state_exp = cw_moved_exp

*** regression
*** OLS
*** start regressions
global ifstat = "if all == 1"
foreach yvar in cw_years_educ cw_moved cw_moved_state /// 
	cw_moved_wage_yearly_better cw_moved_mort_res_50_68_medhi { 
	
	local exp_var = "`yvar'_exp"
	if inlist("`yvar'","cw_years_educ","cw_moved","cw_moved_state") global ifstat = "if all == 1"
	if inlist("`yvar'","cw_moved_mort_res_50_68_medhi") {
		local exp_var = "cw_moved_exp"
		global ifstat = "if cw_moved == 1"
		}
	if inlist("`yvar'","cw_moved_wage_yearly_better") {
		local exp_var = "cw_moved_exp"
		global ifstat = "if cw_moved == 1"
		}

	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local meanyvar = "`yvar'"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `exp_var' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label
	
	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	
	* 9) CO 
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	drop qin
}

*** mortality
foreach yvar in fs_moved fs_moved_state fs_moved_mort_50_68_better {
* simple linear regression

* set what to take mean over
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"

if inlist("`yvar'","fs_moved","fs_moved_state") global ifstat = "if death_age >= 45"

if inlist("`yvar'","fs_moved_mort_50_68_better") global ifstat = "if death_age >= 45 & fs_moved == 1"

* get the most restrictive sample and only use that
xtreg `yvar' $X0 $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)

* 1) raw
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

* 2) with Birth Dummies and county-quarter
quietly xtreg `yvar' $X0 $X1 $ifstat & qin == 1, fe $option_se
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

* 3) birth, county dummies, all CO controls, missing controls county-quarter
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6}) label

* 4) cohort county dummies, all CO controls, missing controls, camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
quietly xtreg `yvar' $X0 $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label


* 8) sample serving before the median enrollment year
quietly sum enrollment_year1 $ifstat & qin == 1, d
local myear = `r(p50)'
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
global medyear = string(`myear',"%9.0f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	

* 9) CO 
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 & state == "CO", $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	
drop qin
}

********************
*** Table 7: CCC Outcomes vs JC Outcomes 
********************
* omitted, as CCC outcomes are from Tables 5-6

********************
*** Table 8: Control Function Estimates
********************
* provided as a separate file
}

*******************************************************************************
****************************** END MAIN TABLES ********************************
*******************************************************************************

********************
*** Appendix Table : Determinants of Duration
********************
if $tables_app == 1 {
*** duration
global ifstat = "if death_age >= 45 & death_age != ."

* 1) cohort dummies, all CO controls, missing controls (individual controls)
quietly reg ${durvar} $X1 $X4 $X6 $X5 $X7 $ifstat , $option_se
forvalues i = 1(1)7 {
	sum reason1_`i' if e(sample) == 1
	gen reason1_demeaned`i' = reason1_`i' -  `r(mean)'
	}
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}.xml", replace bdec($option_bdec) ctitle("Indiv Controls") addtext("Mean Dep",${meany},"FE","BD","Sample","All","Reason","N") keep(${X0} ${X4} ${X6}) label

* 2) cohort dummies, camp and peer controls
quietly reg ${durvar} $X1 ${campchars} ${peerchars} $ifstat , $option_se
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}.xml", append bdec($option_bdec) ctitle("Camp Controls") addtext("Mean Dep",${meany},"FE","BD","Sample","All","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 3) cohort dummies, individual controls camp and peer controls
quietly reg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat , $option_se
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}.xml", append bdec($option_bdec) ctitle("Indiv+Camp") addtext("Mean Dep",${meany},"FE","BD","Sample","All","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 4) cohort county dummies, individual controls camp and peer controls
xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat , $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}.xml", append bdec($option_bdec) ctitle("Add County-Quarter FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 5) CO Only cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & state == "CO", $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("CO") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","CO","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 6) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & state == "CO" & allnonmiss == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("CO Non-missing Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","CO","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

*** end ols for duration as yvar
use `regfile', clear

********************
*** Appendix Table : Heterogeneity in Determinants of Duration
********************
global ifstat = "if death_age >= 45 & death_age != ."

* 1) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & insample_05 == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", replace bdec($option_bdec) ctitle("Randomized Pass") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","Randomize Pass","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 2) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & state == "CO", $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("CO") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","CO","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 3) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & state == "CO" & allnonmiss == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("CO Non-missing Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","CO","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 4) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X5 ${campchars} ${peerchars} $ifstat & state == "CO", $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("CO with NM controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","NM","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

* 5) cohort county dummies, individual controls camp and peer controls
quietly xtreg ${durvar} $X1 $X4 $X5 ${campchars} ${peerchars} $ifstat & state == "NM", $option_se fe
xtregfe_replace_r2
quietly sum ${durvar} if e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${durvar}_het.xml", append bdec($option_bdec) ctitle("NM") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","NM","Reason","N") keep(${X0} ${X4} ${X6} ${campchars} ${peerchars}) label

***********************************
*** Appendix Table : Clustering at Different Levels
************************************

foreach se_var in none groupayq application_county1 enrollment_yq1 {
if "`se_var'" == "none" global option_se = ""
if "`se_var'" != "none" global option_se = "vce(cluster `se_var')"


local yvar = "ldeath_age"

if "`yvar'" == "ldeath_age" global ifstat = "if death_age >= 45"
* simple linear regression

* get the most restrictive sample and only use that
xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)

* set what to take mean over
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"

* 1) raw
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

* 2) with Birth Dummies and county-quarter
quietly xtreg `yvar' $X0 $X1 $ifstat & qin == 1, fe $option_se
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

* 3) birth, county dummies, all CO controls, missing controls county-quarter
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6}) label

* 4) cohort county dummies, all CO controls, missing controls, camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + CO only
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

* 8) Non-missing height, weight, education (this is not shown in the final tables)
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & nonmissing_xvars == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_cl_`se_var'.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

drop qin

}

*********************
*** Appendix Table :  Fixed effects at different levels
*********************

* generate different levels of FE
egen cs_fe = group(birth_year state)
egen cc_fe = group(birth_year application_county1)

foreach fe in groupayq cs_ayq_fe cc_ayq_fe {

if inlist("`fe'","cs_ayq_fe","cc_ayq_fe") local feset = "groupayq"
if !inlist("`fe'","cs_ayq_fe","cc_ayq_fe") local feset = "`fe'"
global option_se = "vce(cluster `feset')"
xtset, clear
xtset `feset'

if inlist("`fe'","groupayq") global X1 = "i.birth_year"
if inlist("`fe'","cs_ayq_fe") global X1 = "i.cs_fe"
if inlist("`fe'","cc_ayq_fe") global X1 = "i.cc_fe"

if "`fe'" == "cs_ayq_fe" local BD = "Birth-State"
if "`fe'" == "cc_ayq_fe" local BD = "Birth-County"

local yvar = "ldeath_age"

if "`yvar'" == "ldeath_age" global ifstat = "if death_age >= 45"
* simple linear regression

* get the most restrictive sample and only use that
xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)

* set what to take mean over
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"

* 1) raw
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

* 2) with Birth Dummies and county-quarter
quietly xtreg `yvar' $X0 $X1 $ifstat & qin == 1, fe $option_se
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","`BD',CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

* 3) birth, county dummies, all CO controls, missing controls county-quarter
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","`BD',CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6}) label

* 4) cohort county dummies, all CO controls, missing controls, camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","`BD',CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","`BD',CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","`BD',CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + CO only
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","`BD',CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

* 8) Non-missing height, weight, education (this is not shown in the final tables)
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & nonmissing_xvars == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_fe_`fe'.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","`BD',CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

drop qin

}

* reset
global option_se = "vce(cluster groupayq)"
global X1 = "i.birth_year"

********************
*** Appendix Table : Only Machine-matched DMF
********************
use `regfile', clear

foreach yvar in ldeath_age dmf_machine_ldeath_age dmf_machine_match  {

if "`yvar'" == "ldeath_age" global ifstat = "if death_age >= 45 & dmf_machine_match == 1"
if "`yvar'" == "dmf_machine_ldeath_age" global ifstat = "if dmf_machine_ageatdeath >= 45 & dmf_machine_match == 1"
if "`yvar'" == "dmf_machine_match" global ifstat = "if all == 1"

* simple linear regression

* get the most restrictive sample and only use that
xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se fe
gen qin = e(sample)

* set what to take mean over
if "`yvar'" == "dmf_machine_match" local meanyvar = "`yvar'"
if "`yvar'" == "ldeath_age" local meanyvar = "death_age"
if "`yvar'" == "dmf_machine_ldeath_age" local meanyvar = "dmf_machine_ageatdeath"

* 1) raw
quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

* 2) with Birth Dummies and county-quarter
quietly xtreg `yvar' $X0 $X1 $ifstat & qin == 1, fe $option_se
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

* 3) birth, county dummies, all CO controls, missing controls county-quarter
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6}) label

* 4) cohort county dummies, all CO controls, missing controls, camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + CO only
quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se fe
xtregfe_replace_r2
quietly sum `meanyvar' $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_`yvar'_dmf_mm.xml", append bdec($option_bdec) ctitle("CO only") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","CO","Reason","N") keep(${X0} ${keepdum} ${X4} ${X2} ${X6} ${peerchars}) label

drop qin
}


********************
*** Appendix Table : OLS Survival
********************
*** P70 OLS
global ifstat = "if death_age >= 45"

foreach yvar in P70 P70m_discharge P70m0 {
global yvar = "`yvar'"
global xvar = "$X0" 
local app = "replace"

quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} i.campdum1 $ifstat , $option_se fe
gen qin = e(sample)

forvalues i = 1(1)6 {
* these specifications correspond to column names on Table 4
	if `i' == 1  global cntrlvars = "" 	// raw
	if `i' == 2  global cntrlvars = "$X1" // birth and county FE
	if `i' == 3  global cntrlvars = "$X1 $X4 $X6 $X5 $X7" // controls
	if `i' == 4  global cntrlvars = "$X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars}" // camp + peer
	if `i' == 5  global cntrlvars = "$X1 $X4 $X6 $X5 $X7 i.campdum1 ${peerchars}"
	if `i' == 6  global cntrlvars = "$X1 $X4 $X6 $X5 $X7 i.campdum1 ${peerchars} $X2" // reason
	
	*** 
	if `i' == 1 	quietly reg ${yvar} $X0 $ifstat & qin == 1 , $option_se
	if `i' > 1 	{
		quietly xtreg ${yvar} $X0 ${cntrlvars} $ifstat & qin == 1 , $option_se fe
		xtregfe_replace_r2
	}
	* output
	quietly sum ${yvar} $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", `app' bdec(${option_bdec}) addtext("Mean Dep",${meany}) keep(${X0}) label


	if "${yvar}" == "P70" {
		*** bounding exercise
		/*
		 OLS can be decomposed into beta = (inv(X'X)*X')y
		 in other words, beta = (x/sum(x^2)) * y for simple regression.
		 if we have missing y and y positive and bounded, we can calculate the possible
		 beta_max by imputing y with y_max for observations with positive x 
		 and with y_min for observations with negative x.
		 beta_min is the opposite.
		*/
		* first partition to make simple-regression equivalent.
		if `i' ==1  quietly reg ${xvar} $ifstat
		if `i' > 1  quietly xtreg ${xvar} ${cntrlvars} $ifstat, fe $option_se
		
		* need to take into account the regression model to get the correct residuals
		if "`e(cmd)'" == "xtreg" & "`e(model)'" == "fe"	 local pred_cmd = "e"
		if "`e(cmd)'" == "regress"						 local pred_cmd = "res"
		predict ${xvar}_res if e(sample), `pred_cmd'

		* impute small and big bound
		quietly sum ${yvar}
		gen yvar_impute_small = ${yvar}
		replace yvar_impute_small = `r(min)' if yvar_impute_small == . & ${xvar}_res >= 0 & ${xvar}_res != .
		replace yvar_impute_small = `r(max)' if yvar_impute_small == . & ${xvar}_res < 0 & ${xvar}_res != .

		gen yvar_impute_big = ${yvar}
		replace yvar_impute_big = `r(max)' if yvar_impute_big == . & ${xvar}_res >= 0 & ${xvar}_res != .
		replace yvar_impute_big = `r(min)' if yvar_impute_big == . & ${xvar}_res < 0 & ${xvar}_res != .

		* do the regressions
		if `i' ==1  quietly reg yvar_impute_small ${xvar} ${cntrlvars} $ifstat
		if `i' > 1  quietly xtreg yvar_impute_small ${xvar} ${cntrlvars} $ifstat, fe
		outreg2 using "${resultdir}/reg_`yvar'_bound_min.xml", `app' noaster bdec(${option_bdec}) addtext("Mean Dep",${meany}) keep(${X0}) label 

		if `i' ==1  quietly reg yvar_impute_big ${xvar} ${cntrlvars} $ifstat
		if `i' > 1  quietly xtreg yvar_impute_big ${xvar} ${cntrlvars} $ifstat, fe
		outreg2 using "${resultdir}/reg_`yvar'_bound_max.xml", `app' noaster bdec(${option_bdec}) addtext("Mean Dep",${meany}) keep(${X0}) label

		drop duration1_res yvar_impute_small yvar_impute_big
		}
		
	local app = "append"
	}
	
	drop qin
}

********************
*** Appendix Table : Heterogeneity in OLS for death age
********************

global ifstat = "if death_age >= 45"

foreach yvar in ldeath_age {

if "`yvar'" == "ldeath_age" local meanyvar = "death_age"
if "`yvar'" != "ldeath_age" local meanyvar = "`yvar'"

local app = "replace"
foreach smps in "CO" "NM" "Age <= 18" "Age > 18" ///
	"Allottee Mother" "Allottee Father" "Allottee Other" ///
	"Urate above median" "Urate below median" "Hispanic" "Not Hispanic" ///
	"BMI < 18.5 (CO)" "BMI 18.5-25 (CO)" "BMI >= 25 (CO)" ///
	"Phase 2 (1935-1937)" "Phase 3 (1937-1940)" "Phase 4 (1940-1942)" ///
	"Randomized" "CO NM controls only" {

	if "`smps'" == "CO" 				 global sampleselect = `"state == "CO""'
	if "`smps'" == "NM"					 global sampleselect = `"state == "NM""'
	if "`smps'" == "Age <= 18" 			 global sampleselect = "enrollment_age1 <= 18"
	if "`smps'" == "Age > 18"			 global sampleselect = "enrollment_age1 > 18"
	if "`smps'" == "Allottee Mother" 	 global sampleselect = "allottee_mother1 == 1"
	if "`smps'" == "Allottee Father"	 global sampleselect = "allottee_father1 == 1"
	if "`smps'" == "Allottee Other"		 global sampleselect = "allottee_mother1 == 0 & allottee_father1 == 0"
	if "`smps'" == "Urate above median"	 global sampleselect = "urate_abv == 1 & m_county_urate == 0"
	if "`smps'" == "Urate below median"	 global sampleselect = "urate_abv == 0 & m_county_urate == 0"
	if "`smps'" == "Hispanic" 			 global sampleselect = "hispanic_imputed == 1"
	if "`smps'" == "Not Hispanic"		 global sampleselect = "hispanic_imputed == 0"
	if "`smps'" == "BMI < 18.5 (CO)" 	 global sampleselect = `"bmi < 18.5 & m_bmi == 0 & state == "CO""'
	if "`smps'" == "BMI 18.5-25 (CO)" 	 global sampleselect = `"bmi >= 18.5 & bmi < 25 & m_bmi == 0  & state == "CO""'
	if "`smps'" == "BMI >= 25 (CO)" 	 global sampleselect = `"bmi >= 25  & m_bmi == 0 & state == "CO""'
	if "`smps'" == "Phase 2 (1935-1937)" global sampleselect = "Phase2 == 1"
	if "`smps'" == "Phase 3 (1937-1940)" global sampleselect = "Phase3 == 1"
	if "`smps'" == "Phase 4 (1940-1942)" global sampleselect = "Phase4 == 1"
	if "`smps'" == "Randomized" 		 global sampleselect = "insample_05 == 1"
	
	* cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & $sampleselect , $option_se fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_het_yecampFE.xml", `app' bdec($option_bdec) ctitle("`smps'") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars}) label
	
	local app = "append"
}

* add CO with just NM controls
local app = "append"
local smps = "CO NM controls only"
if "`smps'" == "CO NM controls only" global sampleselect = `"state == "CO""'

	* cohort county dummies, all CO controls, missing controls, peer 
	quietly xtreg `yvar' $X0 $X1 $X4 $X5 ${peerchars} ${campchars} $ifstat & $sampleselect , $option_se fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_het_nocampFE.xml", `app' bdec($option_bdec) ctitle("`smps'") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars} ${campchars}) label

	* cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 $X1 $X4 $X5 ${peerchars} i.campdum1 $ifstat & $sampleselect , $option_se fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_het_yecampFE.xml", `app' bdec($option_bdec) ctitle("`smps'") addtext("Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${peerchars}) label
	
}


	
********************
*** Appendix Table: Census Placebo
********************

clear
use `regfile'

*** examine education comparison
sort school_grade cens_years_educ
by school_grade cens_years_educ: gen dup = _n
by school_grade cens_years_educ: gen Neduc = _N

*** do the sample selection
*keep if cens_match_type != . // only people matched to Census
tab Eligible1940, m
keep if Eligible1940 == 1 // only who are currently not serving in 1940

*** ADDITIONAL RESTRICTIONS FOR THE WAGE EQUATION
gen cens_wage_obs = .
replace cens_wage_obs = 1 if enrollment_year1 < 1939 & discharge_year1 < 1939
replace cens_wage_obs = 0 if enrollment_year2 != . & discharge_year2 != . & enrollment_year2 <= 1939 & discharge_year2 >= 1939
replace cens_wage_obs = 0 if enrollment_year3 != . & discharge_year3 != . & enrollment_year3 <= 1939 & discharge_year3 >= 1939
replace cens_wage_obs = 0 if enrollment_year4 != . & discharge_year4 != . & enrollment_year4 <= 1939 & discharge_year4 >= 1939
replace cens_wage_obs = 0 if cens_wage_obs == .

replace cens_wage = 0 if cens_wkswork1 == 0
replace cens_wage = 0 if cens_wage == . & cens_wkswork1 == 0

*** placebo

*** placebo for ever had a regular job (prev_job, not census variable)
foreach yvar in prev_job  {
	
	if "`yvar'" == "cens_matched" {
		global ifstat = "if all == 1"
		local exp = ""
		}
	if "`yvar'" != "cens_matched" {
		global ifstat = "if cens_matched == 1"
		local exp = "" 
		
		if inlist("`yvar'","cens_wkswork1","cens_wage","cens_lwage_working") {
			global ifstat = "if cens_matched == 1 & cens_wage_obs == 1"
			}
			
			
		}
	
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local meanyvar = "`yvar'"
	if "`yvar'" == "cens_lwage_working" local meanyvar = "cens_wage_working" 
	if "`yvar'" == "cens_lhouseval" local meanyvar = "cens_houseval"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `exp' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label

	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 9) CO 
	quietly xtreg `yvar' $X0 `exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	
	drop qin
}


********************
*** Appendix Table : WWII Height by Age and Placebo
********************
clear
use `regfile'

*** height by age
*** start regressions
foreach yvar in ww2_height_r {
foreach ifand in age_g20 age_l20 {
	if "`ifand'" == "age_g20" local addif = "& enrollment_age1 >= 20"
	if "`ifand'" == "age_l20" local addif = "& enrollment_age1 < 20"

	if "`yvar'" == "ww2_matched" {
		global ifstat = "if all == 1 `addif'"
		local ww2_exp = ""
		}
	if "`yvar'" != "ww2_matched" {
		global ifstat = "if insample_ww2 == 1 `addif'"
		local ww2_exp = "ww2_exp"
		}
	* simple linear regression

	*** controling for the "experience" or "time since out"
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local meanyvar = "`yvar'"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label
	
	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	
	* 9) CO 
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'_`ifand'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	drop qin
	
}
}

*** placebo
*** regression
*** start regressions
foreach yvar in ww2_height_r ww2_bmi {

	local ww2_exp = "ww2_exp"

	* simple linear regression

	*** controling for the "experience" or "time since out"
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	if "`yvar'" == "ww2_height_r" {
		local yvar = "totheight"
		global ifstat = "if insample_ww2 == 1 & m_totheight == 0"
		global X6 = "school_grade hhsize farm weight fatherliving motherliving tenure_county"
		}
	if "`yvar'" == "ww2_bmi" {
		local yvar = "weight"
		global ifstat = "if insample_ww2 == 1 & m_weight == 0"
		global X6 = "school_grade hhsize farm totheight fatherliving motherliving tenure_county"
		}
	local meanyvar = "`yvar'"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N") addnote("Only Duration <= 3 years, death age >= 45") label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	 xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label
	
	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	
	* 9) CO 
	quietly xtreg `yvar' $X0 `ww2_exp' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	drop qin
	
}
global X6 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county"

********************
*** Appendix Table : Census and WWII combined placebo
********************
clear
use `regfile'

gen cw_moved_state_exp = cw_moved_exp

*** regression
*** OLS
*** start regressions
global ifstat = "if all == 1"


*** placebo
*** Appendix Table 5

global X6 = "hhsize farm totheight weight fatherliving motherliving tenure_county"

foreach yvar in cw_years_educ {
	
	local exp_var = "`yvar'_exp"
	if inlist("`yvar'","cw_moved_mort_res_40_50","cw_moved_mort_occ_40_50","cw_moved_mort_res_50_68","cw_moved_mort_occ_50_68") local exp_var = "cw_moved_exp"
	* simple linear regression
	* get the most restrictive sample and only use that
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} ${campchars} $ifstat , $option_se_cens fe
	gen qin = e(sample)
	
	local yvar = "school_grade"
	global ifstat = "if m_school_grade == 0"
	local meanyvar = "`yvar'"

	*** controling for the "experience" or "time since out"
	* 1) raw
	quietly reg `yvar' $X0 $ifstat & qin == 1 , $option_se_cens
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", replace bdec($option_bdec) ctitle("No Controls") addtext("Mean Dep",${meany},"FE","None","Sample","All","Reason","N")  label

	* 2) with Birth Dummies and county-quarter
	quietly xtreg `yvar' $X0 `exp_var' $X1 $ifstat & qin == 1, fe $option_se_cens
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Birth + County-quarter Dummies") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

	* 3) birth, county dummies, all CO controls, missing controls county-quarter
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 $ifstat & qin == 1, $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Indiv Controls") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7}) label

	* 4) cohort county dummies, all CO controls, missing controls, camp chars
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${campchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 5) cohort county dummies, all CO controls, missing controls, peer + camp chars
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Peer Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 6) cohort county dummies, all CO controls, missing controls, peer + camp FE
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Camp FE") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	* 7) cohort county dummies, all CO controls, missing controls, peer + camp FE + reason
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X2 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Add Reason for Dismissal") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars}) label
	
	* 8) sample serving before the median enrollment year
	quietly sum enrollment_year1 $ifstat & qin == 1, d
	local myear = `r(p50)'
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & enrollment_year1 <= `myear', $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	global medyear = string(`myear',"%9.0f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("Before Median Year") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y","Median Year",${medyear}) keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label
	
	* 9) CO 
	quietly xtreg `yvar' $X0 `exp_var' $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat & qin == 1 & state == "CO" , $option_se_cens fe
	xtregfe_replace_r2
	quietly sum `meanyvar' $ifstat & e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${resultdir}/reg_`yvar'.xml", append bdec($option_bdec) ctitle("CO Only") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","Y") keep(${X0} ${keepdum} ${X4} ${X6} ${X5} ${X7} ${peerchars} ${campchars}) label

	drop qin
}
global X6 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county"


********************
*** Appendix Table : Sample Selection
********************

***** sample selection table begin ******
use `preimpute', clear

*** get counts
matrix define SampleSel = J(8,2,.)
mat colnames SampleSel = "Itself" "Sequential"
mat rownames SampleSel = "All" "Camp Exist" "Enrollment Exist" "Duration Exist" ///
	"Death Age Exist" "Death Age Restrict" "Camp Controls" "Peer Controls"

* all
local j = 1
quietly sum all // count
mat SampleSel[`j',1] = `r(N)' // export
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* camp missing
quietly sum all if ccccampnumber1 != ""
mat SampleSel[`j',1] = `r(N)'
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* county + enrollment year-quarter missing
quietly sum all if groupayq != .
mat SampleSel[`j',1] = `r(N)'
quietly sum all if ccccampnumber1 != "" & groupayq != .
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* duration missing
quietly sum all if duration1 != .
mat SampleSel[`j',1] = `r(N)'
quietly sum all if ccccampnumber1 != "" & groupayq != .  & duration1 != .
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* death age missing
quietly sum all if death_age != .
mat SampleSel[`j',1] = `r(N)'
quietly sum all if ccccampnumber1 != "" & groupayq != .  & duration1 != . & death_age != .
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* death age restriction
quietly sum all if death_age >= 45
mat SampleSel[`j',1] = `r(N)'
quietly sum all if death_age >= 45 & ccccampnumber1 != "" & groupayq != .  & death_age != . & duration1 != .
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* iv's missing (we don't use iv anymore)

local ifs = `"if death_age >= 45 & ccccampnumber1 != "" & groupayq != .  & death_age != . & duration1 != ."'
sum all `ifs'

* camp characteristics missing
quietly reg all $campchars
quietly sum all if e(sample)
mat SampleSel[`j',1] = `r(N)'
quietly reg all birth_years_* $campchars `ifs'
quietly sum all if e(sample)
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* peer characteristics missing
quietly reg all $peerchars
sum all if e(sample)
mat SampleSel[`j',1] = `r(N)'
quietly reg duration1 birth_years_* $campchars $peerchars `ifs'
quietly sum all if e(sample)
mat SampleSel[`j',2] = `r(N)'
local j = `j' + 1

* save the sample selection matrix
putexcel A1=matrix(SampleSel, names) using "${resultdir}/SampleSelection.xlsx", replace
***** sample selection end ******
}
*

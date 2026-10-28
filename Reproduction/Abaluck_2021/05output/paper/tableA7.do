* Automated Latex output for Table A7: Alternative Plan Characteristics Specifications
* Blame: 	Jerray Chang <jerray@uchicago.edu>
* Created: 	05/14/21
* Note: to run, use: make tableA7 PCT="100" OPTS_FOLDER="BaselineStuff-take4"

/*
 * DOC:
 *	In order to run this do file, you must have already run the following plan characteristics regression commands:
 *	- make 04analysis ARGS="runPlanCharReg_IV" SAMPLE="SampleSelection2" OPTS_FOLDER="PlanCharsRegressions" TAG="PlanCharsRegressionsV4_iv" &
 *	- make 04analysis ARGS="runPlanCharReg_OLS" SAMPLE="SampleSelection2" OPTS_FOLDER="PlanCharsRegressions" TAG="PlanCharsRegressionsV4_ols" &
 *	The two commands above will save estimates that we pull from to create Table A7, as documented below.
 *
 *  Locations of all the estimate files needed to get the numbers in Table A7:
 *  Panel A: OLS
 *    Col 1: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_starRating_lin
 *    Col 2: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_45_lin
 *    Col 3: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_345_lin
 *    Col 4: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_pffs_dum_lin
 *    Col 5: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_hmo_dum_lin
 *    Col 6: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_ppo_dum_lin
 *
 *  Panel B: IV
 *    (note that in this code I change the numbering of the locals `endogenous_i' for a clean, sequential look,
 *     but below are the numbers corresponding to PlanCharsRegressions_IV.do)
 *    Col 1: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_1'_iv_lin
 *    Col 2: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_7'_iv_lin
 *    Col 3: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_8'_iv_lin
 *    Col 4: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_10'_iv_lin
 *    Col 5: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_11'_iv_lin
 *    Col 6: ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_12'_iv_lin
 *
 *  The tableA7.do code is organized as follows:
 *  Steps 1 and 2: I borrow excerpts from the 04analysis/PlanCharsRegressions_OLS.do (and similar ones from the IV file in Step 2),
 * 				   and add lines that save mata objects for the important values (beta coefs, std err, N)
 *  Step 3: 	   I compile these mata objects into latex output using the tableA7_latexWrapper.do mata function, latex_tableA7()
 *
 */


*---------------------------------------------------------------------------
* 1. Get OLS regression results
*---------------------------------------------------------------------------

* Setup
local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/tableA7_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local 0 "SampleSelection2; optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_ols_1pct)"
}
else {
    local 0 "SampleSelection2; optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_ols)"
}
include 05output/main.do

{
    * OLS Plan Characteristic Regression Locals
    local exogenous_1      star_rating_cont
    local plan_controls_1  star_rating_cont_lag
    local results_lin_1    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_starRating_lin

    local exogenous_2      star45
    local plan_controls_2  star45_lag
    local results_lin_2    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_45_lin

    local exogenous_3     star345
    local plan_controls_3 star345_lag
    local results_lin_3   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_345_lin

    local exogenous_4     pffs_dum
    local plan_controls_4 pffs_dum_lag
    local results_lin_4   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_pffs_dum_lin

    local exogenous_5     hmo_dum
    local plan_controls_5 hmo_dum_lag
    local results_lin_5   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_hmo_dum_lin

    local exogenous_6     ppo_dum
    local plan_controls_6 ppo_dum_lag
    local results_lin_6   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_ppo_dum_lin

    local exogvarlist `exogenous_1' `exogenous_2' `exogenous_3' `exogenous_4' `exogenous_5' `exogenous_6'
    mata ols_f_stats = J(0, 1, .)

    * Store estimates in mata objects
    forvalues i = 1 / 6 {
        estimates use `"`results_lin_`i''"'
        reghdfe

        mata ols_coefs_`i' = J(6, 1, .)
        mata ols_se_`i' = J(6, 1, .)

        mata ols_f_stats = ols_f_stats \ `=e(F)'
        local j = 1
        foreach var in `exogvarlist' {
            cap mata ols_coefs_`i'[`j'] = `=_b[`var']'
            cap mata ols_se_`i'[`j']    = `=_se[`var']'
            display "This is inside the j loop"
            local j = `j' + 1
            display "This is inside the exogvarlist loop"
        }
        display "This is inside the i loop"
    }
    display "done with OLS section"
}

*---------------------------------------------------------------------------
* 2. Get IV regression results
*---------------------------------------------------------------------------

if ("`pct'" == "01") {
    local 0 "SampleSelection2; optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_iv_1pct)"
}
else {
    local 0 "SampleSelection2; optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_iv)"
}
include 05output/main.do

* OLS Plan Characteristic Regression Locals
local endogenous_1     star_rating_cont
local iv_1             star_rating_iv
local plan_controls_1  star_rating_cont_lag
local results_lin_1    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_1'_iv_lin

local endogenous_2     star45
local iv_2             star45_iv
local plan_controls_2  star45_lag
local results_lin_2    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_2'_iv_lin

local endogenous_3    star345
local iv_3            star345_iv
local plan_controls_3 star345_lag
local results_lin_3   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_3'_iv_lin

local endogenous_4    pffs_dum
local iv_4            pffs_dum_iv
local plan_controls_4 pffs_dum_lag
local results_lin_4   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_4'_iv_lin

local endogenous_5    hmo_dum
local iv_5            hmo_dum_iv
local plan_controls_5 hmo_dum_lag
local results_lin_5   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_5'_iv_lin

local endogenous_6    ppo_dum
local iv_6            ppo_dum_iv
local plan_controls_6 ppo_dum_lag
local results_lin_6   ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_6'_iv_lin

local endogvarlist `endogenous_1' `endogenous_2' `endogenous_3' `endogenous_4' `endogenous_5' `endogenous_6'
mata iv_f_stats = J(0, 1, .)
mata R2_iv = J(0,1,.)

* Store estimates in mata objects
forvalues i = 1/6 {
	* IV - Linear ------------------
	estimates use `"`results_lin_`i''"', number(1)
	ivreghdfe

	local NIV  = `=e(N)'

	disp "First Stage F-Stat-------------------"
	disp e(widstat)

	mata beta_coefs_`i' = J(6, 1, .)
	mata beta_se_`i' = J(6, 1, .)

	mata iv_f_stats    = iv_f_stats    \ `=e(widstat)'
	local j = 1
	foreach var in `endogvarlist' {
		cap mata beta_coefs_`i'[`j'] = `=_b[`var']'
		cap mata beta_se_`i'[`j']    = `=_se[`var']'
		display "This is inside the j loop"
		local j = `j' + 1
        display "This is inside the exogvarlist loop"
	}
    display "This is inside the i loop"

	estimates use `"`results_lin_`i''"', number(2)
	reg
    mata R2_iv = R2_iv \ `=_b[_cons]'
}

*---------------------------------------------------------------------------
* 3. Compile Latex table
*---------------------------------------------------------------------------

/* DOC:
 * By this line, we should have the following mata objects:
 * - For each specification i in {1,2,3,4,5},
 * 		- the coefficient(s) in the i OLS regression
 * 		- the se(s) in the i OLS regression
 * 		- the coefficient(s) in the i IV regression
 * 		- the se(s) in the i iv regression
 * - the IV first-stage f-stats for all specifications
 * - the max R2 for all specifications
 * - the N for the IV (the same for all) regressions
 *
 * To combine all the coefs and ses into a giant matrix, some of the elements have to be blank.
 * I solve this above by using a loop over all the exogenous variables `exogvarlist' combined with a loop over the elements of the vectors.
 */

mata ols_coefs  = ols_coefs_1 ,  ols_coefs_2,  ols_coefs_3,  ols_coefs_4,  ols_coefs_5,  ols_coefs_6
mata ols_se     = ols_se_1 ,     ols_se_2,     ols_se_3,     ols_se_4,     ols_se_5,     ols_se_6
mata beta_coefs = beta_coefs_1 , beta_coefs_2, beta_coefs_3, beta_coefs_4, beta_coefs_5, beta_coefs_6
mata beta_se    = beta_se_1 ,    beta_se_2,    beta_se_3,    beta_se_4,    beta_se_5,    beta_se_6
mata ols_coefs
mata beta_coefs

mata ols_matrix =    ///
    ols_coefs[1,.] \ ///
    ols_se[1,.]    \ ///
    ols_coefs[2,.] \ ///
    ols_se[2,.]    \ ///
    ols_coefs[3,.] \ ///
    ols_se[3,.]    \ ///
    ols_coefs[4,.] \ ///
    ols_se[4,.]    \ ///
    ols_coefs[5,.] \ ///
    ols_se[5,.]    \ ///
    ols_coefs[6,.] \ ///
    ols_se[6,.]

mata beta_matrix =    ///
    beta_coefs[1,.] \ ///
    beta_se[1,.]    \ ///
    beta_coefs[2,.] \ ///
    beta_se[2,.]    \ ///
    beta_coefs[3,.] \ ///
    beta_se[3,.]    \ ///
    beta_coefs[4,.] \ ///
    beta_se[4,.]    \ ///
    beta_coefs[5,.] \ ///
    beta_se[5,.]    \ ///
    beta_coefs[6,.] \ ///
    beta_se[6,.]

mata tableA7_matrix = ols_matrix \ beta_matrix
mata tableA7_matrix

* We won't use the FS f-stats and R^2 in the table, but we calculate
* them as legacy code from Table 4. Here they are if you're curious:

mata iv_f_stats
mata R2_iv

* Now we have our matrix of coefficients and standard errors. Together with the N:
display `"`NIV'"'
* we're good to go and put them together!
include 05output/paper/tableA7_latexWrapper.do

local out ${out}/tables/`pre'tableA7_`pct'pct.tex
mata latex_tableA7(tableA7_matrix, tableA7_fmt, tableA7_rlabels, ///
    tableA7_paneltitles, tableA7_header, tableA7_footer, tableA7_space, ///
    24, "\midrule", `"`out'"', `NIV')

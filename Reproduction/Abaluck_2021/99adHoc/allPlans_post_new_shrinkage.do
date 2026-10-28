* ---------------------------------------------------------------------
* Title:   Generate allPlans_postnewshrinkage.dta
* Program: allPlans - post new shrinkage
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Wednesday, March 4th 2020
* Updated: Thursday, March 12th 2020
* Purpose: Generates new plans-level dataset using data with new shrinkage mechanism,
*          which will primarily be used to investiage whether the data
*          with the new shrinkage "passes" the lagged mortality balance tests.
* Note:    Utilizes _19ivSample100_binned.dta
* Trello:  https://trello.com/c/h4ArG9Wp/244-update-covariates-for-all-specifications#comment-5e5eeb27bfd684692820192c
* To run this file, paste in Stata while in 05full-sample folder:
*          At 01 percent: do "99adHoc/allPlans_post_new_shrinkage.do" SampleSelection2; runReg optsFolder(BaselineStuff-take4) tag(BaselineStuff_regsNoDemo_1pct)
*          At 100 percent: do "99adHoc/allPlans_post_new_shrinkage.do" SampleSelection2; runReg optsFolder(BaselineStuff-take4) tag(BaselineStuff_regsNoDemo)
*          At 01 percent batch mode:  nohup stata16-mp -b do "99adHoc/allPlans_post_new_shrinkage.do SampleSelection2; runReg optsFolder(BaselineStuff-take4) tag(BaselineStuff_regsNoDemo_1pct)" &
*          At 100 percent batch mode: nohup stata16-mp -b do "99adHoc/allPlans_post_new_shrinkage.do SampleSelection2; runReg optsFolder(BaselineStuff-take4) tag(BaselineStuff_regsNoDemo)" &
*
* Depends: >
*          ./00common/00preamble.do
*          ./04analysis/AnalysisConfigurations.do
*          ./04analysis/Parse/CommandLineArgs.do
*          ./04analysis/Preprocessing/SampleSelection6.do
*          ./04analysis/Parse/RegressionOptions.do
*
* Output:  >
*          ${out}/tables/allPlans_postnewshrinkage.dta
*
* Debugging Strategy:
*          Run matching regressions in (A) Pre-Collapsed IV Regressions and (B) Post-Collapsed IV Regressions.
*          The coefficients, standard errors, t-statistics, p-values, confidence intervals, and number of
*          observations should match between the (A) and (B) regressions. These regression outputs should also
*          match the standard no-demo regressions.

*Setup
*---------------------------------------------------------------------------
local 0: subinstr local 0 ";" ","
syntax anything, optsFolder(str) tag(str) [runReg runPlots runBalance runPlanCharReg_IV runPlanCharReg_OLS runFallback  nocached]
local sampleSelection: copy local anything

local startTime $S_TIME $S_DATE
local logName allPlans_v44_`sampleSelection'`tag'
log using `"`logName'.log"', text replace

* Preprocessing of data
*---------------------------------------------------------------------------
cap noi {
    do 00common/00preamble.do
    do 98adHoc/addProgram.do
    do 98adHoc/addXiProgram.do
    include 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
    do 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')

    local cachedFile ${data}/`pre'`sampleSelection'_`pct'pct.dta
    cap confirm file "`cachedFile'"
    if ( ("`cached'" != "") | _rc ) {
        include 04analysis/Preprocessing/`sampleSelection'.do
        save "`cachedFile'", replace
    }
    else {
        use "`cachedFile'", clear
    }
    include 04analysis/Preprocessing/SampleSelectionMacros.do
	include 04analysis/Parse/RegressionOptions.do
}

* Create Dummies for bin_num
*---------------------------------------------------------------------------
tabulate bin_num, generate(dum_bin_num)
tabulate bin_num_lag, generate (dum_bin_num_lag)


* Generate Xi IV Variables
*---------------------------------------------------------------------------
local versions A B C D E F
* Elasticities for differen versions
* A = -10
* B = -7
* C = -3.5
* D = -3
* E = -1
* F = -0.5

foreach v of local versions{
	gen xi_two_iv`v' = xi_two_lag`v' * `terminated'
}

* Save Intermediary Dataset
*---------------------------------------------------------------------------
save `"${data}/`pre'ivSample_preCollapse_`pct'_postnewshrinkage_v44_binned_addedMean.dta"', replace

* Additional Sample Restrictions
keep if true_mMA2_lag == 1 //Per Recomendation of Prof. Abaluck
gen bene_count = 1 //Used to count enrollment

* (A) Pre-Collapsed IV Regressions
*---------------------------------------------------------------------------
* [Note] The results of regression (A) should match that regression (B)
local versions 1B
foreach v of local versions {
	di `"ivreghdfe `mortality' (`endogenous' =   `instrument`v'') `indepvars`v'' `ifcommand'  `addCond', absorb(`FE') cluster(`cluster')"'
    ivreghdfe `mortality' (`endogenous' = 	`instrument`v'') `indepvars`v'' `ifcommand' `addCond', absorb(`FE') cluster(`cluster')
}

* Collapse beneficiary level data into plan level data
*---------------------------------------------------------------------------
* Plan-Level Variables to Collapse over
local plan_level_lag_vars year state_lag county_lag cntrct_id_lag pbpid_id_lag cntrct_lag pbpid_lag
local plan_level_lag_vars `plan_level_lag_vars' disappeared_landscape1_lag `alpha'_lag mucounty_mleCYPlan_lag fe_county_lag_year fe_county_lag plantypeFE true_mMA2_lag instrument Zxdum_med dum_med frac_plan_county_lag lag_mortality bin_num_lag dum_bin_num_lag*
local plan_level_lag_vars `plan_level_lag_vars' monthly_premium_C_lag mlr_lag star_rating_cont_lag star_rating_cont_lag_dec monthly_premium_C_lag_dec mlr_lag_dec average_risk_score_lag_dec hvam_lag_dec missing_star_rating_lag missing_monthly_premium_lag missing_mlr_lag missing_partd_offered_lag missing_gap_coverage_lag missing_hvam_lag
local plan_level_lag_vars `plan_level_lag_vars' partd_offered_lag gap_coverage_lag average_risk_score_lag missing_average_risk_score_lag
local plan_level_lag_vars `plan_level_lag_vars' disappeared_plan_lag relationship_code_lag
local plan_level_lag_vars `plan_level_lag_vars' typeofmedicarehealthplan_lag
// JC 2/4/21: added typeofmedicarehealthplan to the Amanda File (seems like that would be helpful for her).
local plan_level_lag_vars `plan_level_lag_vars' dis_plan_80_post_lag dis_plan_80_lag dis_plan_90_post_lag dis_plan_90_lag dis_landscape1_80_lag
local plan_level_lag_vars `plan_level_lag_vars' kappa_lag* ln_marketshare_lag xi_one_lag* xi_two_lag* xi_two_iv*
local plan_level_lag_vars `plan_level_lag_vars' star45_lag star345_lag monthly_premium_dum_lag
display "`plan_level_lag_vars'"

local collapse_vars (mean) died_365 (mean) demo_age (mean) `alpha' (mean) mucounty_mleCYPlan (mean) predictedMortality (mean) predictedMortality_dual (mean) predictedMortality_dual_risk (sum) bene_count
local collapse_vars `collapse_vars' (mean) monthly_premium_C (mean) star_rating_cont (mean) mlr (mean) partd_offered (mean) gap_coverage (mean) average_risk_score (mean) hvam (mean) missing_monthly_premium (mean) missing_star_rating (mean) missing_mlr (mean) missing_gap_coverage (mean) missing_partd_offered (mean) missing_hvam (mean) missing_average_risk_score (mean) eta
local collapse_vars `collapse_vars' (mean) bin_num (mean) dum_bin_num?
local collapse_vars `collapse_vars' (mean) xi_two? (mean) xi_one (mean) star45 (mean) star345 (mean) monthly_premium_dum
display "`collapse_vars'"
gcollapse `collapse_vars', by(`plan_level_lag_vars')

* Sanity check after collapse - each plan should only appear once
bys year state_lag county_lag cntrct_id_lag pbpid_id_lag: gen counter = _N
assert counter == 1
drop counter

* Count enrollment in each plan
egen total_enroll = sum(bene_count)
gen percent_enroll = bene_count/total_enroll
label variable total_enroll "Total number of beneficiaries in all county-year plans"
label variable percent_enroll "Percent of beneficiaries in each year-county-plan"
label variable bene_count "Number of beneficiaries in each year-county-plan"

* Save new allPlans datasets
save "${out}/tables/allPlans_`pct'_postnewshrinkage_v46_binned_addedMean.dta", replace
// JC 2/4/21: added typeofmedicarehealthplan to Amanda file, changed v44 -> v46 (v45 is the bootstrapMUs)
describe

* (B) Post-Collapsed IV Regressions
*---------------------------------------------------------------------------
* [Note] The results of regression (B) should match that regression (A)
foreach v of local versions {
	di `"ivreghdfe `mortality' (`endogenous' =   `instrument`v'') `indepvars`v'' `ifcommand' `addCond' [fweight = bene_count], absorb(`FE') cluster(`cluster')"'
    ivreghdfe `mortality' (`endogenous' = 	`instrument`v'') `indepvars`v'' `ifcommand' `addCond' [fweight = bene_count], absorb(`FE') cluster(`cluster')
}


*Send Email
*---------------------------------------------------------------------------
mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

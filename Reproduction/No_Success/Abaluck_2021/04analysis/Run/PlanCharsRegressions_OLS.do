*****************************************************************************
******************** Regressions w/  and Linear Controls ********************
*****************************************************************************

* Plan Characteristic Regressions w/ Monthly Premiums, MLR, and Star Rating
*---------------------------------------------------------------------------
local exogenous_1       star_rating_cont       monthly_premium_C        mlr
local plan_controls_1   star_rating_cont_lag   monthly_premium_C_lag    mlr_lag
local ifcommand_1       `ifcommand' `addCond'
local results_lin_1     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_premium_mlr_lin

local exogenous_2       monthly_premium_C        mlr          gap_coverage
local plan_controls_2   monthly_premium_C_lag    mlr_lag      gap_coverage_lag
local ifcommand_2       `ifcommand' `addCond'
local results_lin_2     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_mlr_donut_lin

local exogenous_3       monthly_premium_C
local plan_controls_3   monthly_premium_C_lag
local ifcommand_3       `ifcommand' `addCond'
local results_lin_3     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_monthlyPremium_lin

local exogenous_4       star_rating_cont
local plan_controls_4   star_rating_cont_lag
local ifcommand_4       `ifcommand' `addCond'
local results_lin_4     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_starRating_lin

local exogenous_5       mlr
local plan_controls_5   mlr_lag
local ifcommand_5       `ifcommand' `addCond'
local results_lin_5     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_mlr_lin

local exogenous_6       hvam
local plan_controls_6   hvam_lag
local ifcommand_6       `ifcommand' `addCond'
local results_lin_6     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_hvam_lin

local exogenous_7       gap_coverage
local plan_controls_7   gap_coverage_lag
local ifcommand_7       `ifcommand' `addCond'
local results_lin_7     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_donut_lin

local exogenous_8       ln_marketshare
local plan_controls_8   ln_marketshare_lag
local ifcommand_8       `ifcommand' `addCond'
local results_lin_8     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_marketshare_lin

local exogenous_9       star45
local plan_controls_9   star45_lag
local ifcommand_9       `ifcommand' `addCond'
local results_lin_9     ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_45_lin

local exogenous_10      star345
local plan_controls_10  star345_lag
local ifcommand_10      `ifcommand' `addCond'
local results_lin_10    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_star_rating_345_lin

local exogenous_11      monthly_premium_dum
local plan_controls_11  monthly_premium_dum_lag
local ifcommand_11      `ifcommand' `addCond'
local results_lin_11    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_monthly_premium_dum_lin

local exogenous_12      pffs_dum
local plan_controls_12  pffs_dum_lag
local ifcommand_12      `ifcommand' `addCond'
local results_lin_12    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_pffs_dum_lin

local exogenous_13      hmo_dum
local plan_controls_13  hmo_dum_lag
local ifcommand_13      `ifcommand' `addCond'
local results_lin_13    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_hmo_dum_lin


local exogenous_14      ppo_dum
local plan_controls_14  ppo_dum_lag
local ifcommand_14      `ifcommand' `addCond'
local results_lin_14    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_ppo_dum_lin


forvalues i = 1 / 14 {
	di `"reghdfe `endogenous' `exogenous_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')"'
	reghdfe `endogenous' `exogenous_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')
	estimates save `"`results_lin_`i''"', replace
}

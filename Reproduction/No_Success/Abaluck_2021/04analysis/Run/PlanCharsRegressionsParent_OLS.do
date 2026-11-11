**************************************************************************************
*********** Regressions w/ Missing Indicator Variables and Linear Controls ***********
**************************************************************************************

* Plan Characteristic Regressions w/dummies for Humana, United, BCBS
*---------------------------------------------------------------------------
local exogenous       parent_humana     parent_bcbs     parent_united
local plan_controls   parent_humana_lag parent_bcbs_lag parent_united_lag

local results_lin ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_lin

* Linear ------------------
di `"reghdfe `endogenous' `exogenous' `indepvars' `plan_controls' `ifcommand', absorb(`FE') cluster(`cluster')"'
reghdfe `endogenous' `exogenous' `indepvars' `plan_controls' `ifcommand', absorb(`FE') cluster(`cluster')
estimates save `"`results_lin'_parents_hub"', replace

foreach var in `endogenous' parent_big parent_kaiser {
    gettoken lag plan_controls: plan_controls
    di `"reghdfe `endogenous' `var' `indepvars' `lag' `ifcommand', absorb(`FE') cluster(`cluster')"'
    reghdfe `endogenous' `var' `indepvars' `lag' `ifcommand', absorb(`FE') cluster(`cluster')
    estimates save `"`results_lin'_`var'"', replace
}

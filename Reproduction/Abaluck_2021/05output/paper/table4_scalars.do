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

capture frame drop scalars
frame create scalars
frame scalars: gen scalars = .
frame scalars: gen strL name = ""

estimates use ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_SampleSelection6_BaselineStuff_regs_1B.ster
qui ivreghdfe
scalar forecast_coeff = _b[`alpha']

* Calculate Lambda Mu ---------------------------------------------
gen lambda_mu = forecast_coeff * `alpha' `ifcommand'
summarize lambda_mu `ifcommand'
scalar var_lambda_mu = r(Var)
disp var_lambda_mu

frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_lambda_mu"))
frame scalars: mata: st_sstore(st_nobs(), "name", "var_lambda_mu")

summarize `alpha' `ifcommand'
scalar var_alpha = r(Var)
disp var_alpha

frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_alpha"))
frame scalars: mata: st_sstore(st_nobs(), "name", "var_alpha")

* Get singletons and drop them
tempvar ones nonsingletons
gen byte `ones' = 1
reghdfe `ones' `ifcommand' `addCond', absorb(`FE') cluster(`cluster')
gen byte `nonsingletons' = e(sample)

******************************************************************************
*********************** Regressions w/ Linear Controls ***********************
******************************************************************************

* Plan Characteristic Regressions w/ Multiple Plan Characteristics
*---------------------------------------------------------------------------
local endogenous_1  star_rating_cont        monthly_premium_C               mlr
local results_lin_1 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_star_mlr_iv_lin

local endogenous_2  monthly_premium_C               mlr            gap_coverage
local results_lin_2 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_mlr_donut_iv_lin

forvalues i = 1 / 2 {
	cap drop xbeta
	cap drop xbeta_demean
	cap drop flag

    local if `ifcommand' `addCond'
    local varlist `mortality' `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `FE' `cluster'
    marksample touse

	estimates use `"`results_lin_`i''"'
    ivreghdfe

    cap matrix drop b
    matrix _ = e(b)
	foreach var of local endogenous_`i' {
        matrix b = nullmat(b), _[1, "`var'"]
    }
	* Calculate Xbeta ---------------
    gen byte flag = `touse' & `nonsingletons'
    count if flag
    assert r(N) == e(N)
    matrix score xbeta = b if flag
    gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
	summarize xbeta_demean if flag
	scalar var_xbeta = r(Var)

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_xbeta"))
    frame scalars: mata: st_sstore(st_nobs(), "name", st_local("endogenous_`i'"))
}

* Plan Characteristic Regressions w/ Single Plan Characteristic
*---------------------------------------------------------------------------

local endogenous_1   monthly_premium_C
local results_lin_1  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_1'_iv_lin

local endogenous_2   star_rating_cont
local results_lin_2  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_2'_iv_lin

local endogenous_3   mlr
local results_lin_3  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_3'_iv_lin

local endogenous_4   gap_coverage
local results_lin_4  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_4'_iv_lin

local endogenous_5   hvam
local results_lin_5  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_5'_iv_lin

local endogenous_6   ln_marketshare
local results_lin_6  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_6'_iv_lin

local endogenous_7   star45
local results_lin_7  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_7'_iv_lin

local endogenous_8   star345
local results_lin_8  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_8'_iv_lin

local endogenous_9   monthly_premium_dum
local results_lin_9  ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_9'_iv_lin

local endogenous_10  pffs_dum
local results_lin_10 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_10'_iv_lin

local endogenous_11  hmo_dum
local results_lin_11 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_11'_iv_lin

local endogenous_12  ppo_dum
local results_lin_12 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_12'_iv_lin

forvalues i = 1 / 12 {
	cap drop xbeta
	cap drop xbeta_demean
	cap drop flag

    local if `ifcommand' `addCond'
    local varlist `mortality' `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `FE' `cluster'
    marksample touse

	estimates use `"`results_lin_`i''"'
    ivreghdfe

    cap matrix drop b
    matrix _ = e(b)
	foreach var of local endogenous_`i' {
        matrix b = nullmat(b), _[1, "`var'"]
    }

	* Calculate Xbeta ---------------
    gen byte flag = `touse' & `nonsingletons'
    count if flag
    disp r(N), e(N), r(N) - e(N)
    matrix score xbeta = b if flag
    gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
	summarize xbeta_demean if flag
	scalar var_xbeta = r(Var)

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_xbeta"))
    frame scalars: mata: st_sstore(st_nobs(), "name", st_local("endogenous_`i'"))
}

frame scalars: save "${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_scalars_iv_lin.dta", replace

capture frame drop scalars
frame create scalars
frame scalars: gen scalars = .
frame scalars: gen strL name = ""

* Create IV Variables by Interacting lag-Plan Characteristics w/ Lag-Terminate
*---------------------------------------------------------------------------
local plan_chars monthly_premium mlr hvam gap_coverage partd_offered ln_marketshare
* Monthly Premium, MLR, HVAM, Part D Coverage, Donut Hole Coverage
foreach plan_char of local plan_chars{
	gen `plan_char'_iv             = `plan_char'_lag         * `terminated'
    gen missing_`plan_char'_iv     = missing_`plan_char'_lag * `terminated'

    assert !mi(`plan_char'_iv)           if true_mMA2_lag == 1
    assert !mi(missing_`plan_char'_iv)   if true_mMA2_lag == 1
}

*Star Rating
gen star_rating_iv             = star_rating_cont_lag * `terminated'
gen missing_star_rating_iv     = missing_star_rating_lag * `terminated'
assert !mi(star_rating_iv) if true_mMA2_lag == 1
assert !mi(missing_star_rating_iv) if true_mMA2_lag == 1

*Star Rating Dummies
gen star45_iv  = star45_lag * `terminated'
assert !mi(star45_iv) if true_mMA2_lag == 1

gen star345_iv  = star345_lag * `terminated'
assert !mi(star345_iv) if true_mMA2_lag == 1

* Monthly Premium (C)
gen monthly_premium_C_iv = monthly_premium_C_lag * `terminated'
assert !mi(monthly_premium_C_iv)           if true_mMA2_lag == 1

* Monthly Premium Dummy
gen monthly_premium_dum_iv = monthly_premium_C * `terminated'
assert !mi(monthly_premium_dum_iv)

* Plan Type
local plan_type_var pffs_dum hmo_dum ppo_dum
foreach var of local plan_type_var{
	gen missing_`var'_lag = strpos(typeofmedicarehealthplan, "BLANK") > 0
	gen `var'_iv = `var'_lag * `terminated'
	gen missing_`var'_iv = missing_`var'_lag * `terminated'
}

* Calculate Lambda Mu ---------------------------------------------
local forecast_coeff = 1.056  // Pull from Main Regression  w/ bene demographics, coefficient on mu: ivreghdfe died_365 (mu = instrument)
gen lambda_mu = `forecast_coeff' * `alpha' `ifcommand'
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

cap drop xbeta 
cap drop xbeta_demean

******************************************************************************
*********************** Regressions w/ Linear Controls ***********************
******************************************************************************

* Plan Characteristic Regressions w/ Multiple Plan Characteristics
*---------------------------------------------------------------------------
local endogenous_1       star_rating_cont        monthly_premium_C               mlr
local iv_1               star_rating_iv          monthly_premium_C_iv            mlr_iv
local plan_controls_1    star_rating_cont_lag    monthly_premium_C_lag           mlr_lag
local ifcommand_1       `ifcommand' `addCond'
local results_lin_1 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_star_mlr_iv_lin


local endogenous_2       monthly_premium_C               mlr            gap_coverage
local iv_2               monthly_premium_C_iv            mlr_iv         gap_coverage_iv
local plan_controls_2    monthly_premium_C_lag           mlr_lag        gap_coverage_lag
local ifcommand_2       `ifcommand' `addCond'
local results_lin_2 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_mlr_donut_iv_lin

forvalues i = 1 / 2 {
	* IV - Linear ------------------
	di `"ivreghdfe `mortality' (`endogenous_`i'' =  `iv_`i'') `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')"'
	ivreghdfe `mortality' (`endogenous_`i'' =  `iv_`i'') `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')
	estimates save `"`results_lin_`i''"', replace

    cap matrix drop b
    matrix _ = e(b)
	foreach var of local endogenous_`i' {
        matrix b = nullmat(b), _[1, "`var'"]
    }

	disp "First Stage F-Stat-------------------"
	disp e(widstat)

	* Calculate Xbeta ---------------
    gen byte flag = e(sample)
    matrix score xbeta = b if flag
    gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
	summarize xbeta_demean if flag
	scalar var_xbeta = r(Var)

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_xbeta"))
    frame scalars: mata: st_sstore(st_nobs(), "name", st_local("endogenous_`i'"))

	* Calculate R2 -----------------------
	disp "R2 ----------"
	scalar R2 = var_xbeta/var_lambda_mu
	disp R2
	cap drop xbeta xbeta_demean flag

	di `"reghdfe `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')"'
	reghdfe `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')
	estimates save `"`results_lin_`i''_FS"', replace
}


* Plan Characteristic Regressions w/ Single Plan Characteristic
*---------------------------------------------------------------------------
local endogenous_1            monthly_premium_C
local iv_1                    monthly_premium_C_iv
local plan_controls_1         monthly_premium_C_lag
local ifcommand_1             `ifcommand' `addCond'
local results_lin_1 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_1'_iv_lin

local endogenous_2            star_rating_cont
local iv_2                    star_rating_iv
local plan_controls_2         star_rating_cont_lag
local ifcommand_2             `ifcommand' `addCond'
local results_lin_2 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_2'_iv_lin

local endogenous_3            mlr
local iv_3                    mlr_iv
local plan_controls_3         mlr_lag
local ifcommand_3             `ifcommand' `addCond'
local results_lin_3 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_3'_iv_lin

local endogenous_4            gap_coverage
local iv_4                    gap_coverage_iv
local plan_controls_4         gap_coverage_lag
local ifcommand_4             `ifcommand' `addCond'
local results_lin_4 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_4'_iv_lin

local endogenous_5            hvam
local iv_5                    hvam_iv
local plan_controls_5         hvam_lag
local ifcommand_5             `ifcommand' `addCond'
local results_lin_5 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_5'_iv_lin

local endogenous_6            ln_marketshare
local iv_6                    ln_marketshare_iv
local plan_controls_6         ln_marketshare_lag
local ifcommand_6             `ifcommand' `addCond'
local results_lin_6 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_6'_iv_lin

local endogenous_7            star45
local iv_7                    star45_iv
local plan_controls_7         star45_lag
local ifcommand_7             `ifcommand' `addCond'
local results_lin_7 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_7'_iv_lin

local endogenous_8            star345
local iv_8                    star345_iv
local plan_controls_8         star345_lag
local ifcommand_8             `ifcommand' `addCond'
local results_lin_8 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_8'_iv_lin

local endogenous_9            monthly_premium_dum
local iv_9                    monthly_premium_dum_iv
local plan_controls_9         monthly_premium_dum_lag
local ifcommand_9             `ifcommand' `addCond'
local results_lin_9 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_9'_iv_lin

local endogenous_10           pffs_dum
local iv_10                   pffs_dum_iv
local plan_controls_10        pffs_dum_lag
local ifcommand_10            `ifcommand' `addCond'
local results_lin_10 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_10'_iv_lin

local endogenous_11           hmo_dum
local iv_11                   hmo_dum_iv
local plan_controls_11        hmo_dum_lag
local ifcommand_11            `ifcommand' `addCond'
local results_lin_11 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_11'_iv_lin

local endogenous_12           ppo_dum
local iv_12                   ppo_dum_iv
local plan_controls_12        ppo_dum_lag
local ifcommand_12            `ifcommand' `addCond'
local results_lin_12 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`endogenous_12'_iv_lin


forvalues i = 1/12 {
	* IV - Linear ------------------
	di `"ivreghdfe `mortality' (`endogenous_`i'' =  `iv_`i'') `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')"'
	ivreghdfe `mortality' (`endogenous_`i'' =  `iv_`i'') `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') cluster(`cluster')
	estimates save `"`results_lin_`i''"', replace

    cap matrix drop b
    matrix _ = e(b)
	foreach var of local endogenous_`i' {
        matrix b = nullmat(b), _[1, "`var'"]
    }

	disp "First Stage F-Stat-------------------"
	disp e(widstat)

	* Calculate Xbeta ---------------
    gen byte flag = e(sample)
    matrix score xbeta = b if flag
    gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
	summarize xbeta_demean if flag
	scalar var_xbeta = r(Var)

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_xbeta"))
    frame scalars: mata: st_sstore(st_nobs(), "name", st_local("endogenous_`i'"))

	* Calculate R2 -----------------------
	disp "R2 ----------"
	scalar R2 = var_xbeta/var_lambda_mu
	disp R2
	cap drop xbeta xbeta_demean flag

	* First Stage Regressions - Linear ------------------
	di `"reghdfe `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') vce(cluster `cluster')"'
	reghdfe `endogenous_`i'' `iv_`i'' `indepvars' `plan_controls_`i'' `ifcommand_`i'', absorb(`FE') vce(cluster `cluster')
	estimates save `"`results_lin_`i''_FS"', replace
}

frame scalars: save "${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_scalars_iv_lin.dta", replace

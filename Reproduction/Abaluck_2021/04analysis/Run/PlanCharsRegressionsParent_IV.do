* Create IV Variables by Interacting lag-Plan Characteristics w/ Lag-Terminate
*---------------------------------------------------------------------------

local plan_chars parent_humana parent_bcbs parent_united parent_big parent_kaiser

* Monthly Premium, MLR, HVAM, Part D Coverage, Donut Hole Coverage
foreach plan_char of local plan_chars {
	gen `plan_char'_iv = `plan_char'_lag * `terminated'

    disp "checking missing values for `plan_char'"
    assert !mi(`plan_char'_iv) if true_mMA2_lag == 1
}

gen missing_parent_iv = missing_parent_lag * `terminated'
assert !mi(missing_parent_iv) if true_mMA2_lag == 1

*Calculate Lambda Mu ---------------------------------------------
local forecast_coeff = 1.056
gen lambda_mu = `forecast_coeff' * `alpha' `ifcommand'
summarize lambda_mu `ifcommand'
scalar var_lambda_mu = r(Var)
disp var_lambda_mu

foreach var in xbeta xbeta_mean_county xbeta_demean var_xbeta R2 {
    cap drop `var'
}

***********************************************************************
*                    Regressions with all Parents                     *
***********************************************************************

unab endogenous:      parent_humana     parent_bcbs     parent_united
unab iv:              parent_humana_iv  parent_bcbs_iv  parent_united_iv
unab plan_controls:   parent_humana_lag parent_bcbs_lag parent_united_lag
local results_lin ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_lin

* IV - Linear ------------------
di `"ivreghdfe `mortality' (`endogenous' =  `iv') `indepvars' `plan_controls' `ifcommand', absorb(`FE') cluster(`cluster')"'
ivreghdfe `mortality' (`endogenous' =  `iv') `indepvars' `plan_controls' `ifcommand', absorb(`FE') cluster(`cluster')
estimates save `"`results_lin'_parents_hub"', replace

disp "First Stage F-Stat-------------------"
disp e(widstat)

* Calculate Xbeta ---------------
gen byte flag = e(sample)
matrix score xbeta = b if flag
gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
summarize xbeta_demean if flag
scalar var_xbeta = r(Var)

* Calculate R2 -----------------------
disp "R2 ----------"
scalar R2 = var_xbeta/var_lambda_mu
disp R2
foreach var in xbeta xbeta_mean_county xbeta_demean var_xbeta R2 flag {
    cap drop `var'
}

***********************************************************************
*                       Individual Regressions                        *
***********************************************************************

local iv `iv' parent_big_iv parent_kaiser_iv
local plan_controls `plan_controls' parent_big_lag parent_kaiser_lag
foreach var in `endogenous' parent_big parent_kaiser {
    gettoken ivvar iv: iv
    gettoken lag plan_controls: plan_controls

    * IV - Linear ------------------
    di `"ivreghdfe `mortality' (`var' =  `ivvar') `indepvars' `lag' `ifcommand', absorb(`FE') cluster(`cluster')"'
    ivreghdfe `mortality' (`var' =  `ivvar') `indepvars' `lag' `ifcommand', absorb(`FE') cluster(`cluster')
    estimates save `"`results_lin'_`var'"', replace

    cap matrix drop b
    matrix _ = e(b)
	foreach v of local var {
        matrix b = nullmat(b), _[1, "`v'"]
    }

    disp "First Stage F-Stat-------------------"
    disp e(widstat)

    * Calculate Xbeta ---------------
    gen byte flag = e(sample)
    matrix score xbeta = b if flag
    gegen xbeta_demean = demean(xbeta) if flag, by(fe_county)
	summarize xbeta_demean if flag
	scalar var_xbeta = r(Var)

	* Calculate R2 -----------------------
	disp "R2 ----------"
	scalar R2 = var_xbeta/var_lambda_mu
	disp R2
    foreach var in xbeta xbeta_mean_county xbeta_demean var_xbeta R2 flag {
        cap drop `var'
    }

    * First Stage Regressions - Linear ------------------
    di `"reghdfe `var' `ivvar' `indepvars' `lag' `ifcommand', absorb(`FE') vce(cluster `cluster')"'
    reghdfe `var' `ivvar' `indepvars' `lag' `ifcommand', absorb(`FE') vce(cluster `cluster')
    estimates save `"`results_lin'_`var'_FS"', replace
}

capture frame drop scalars
frame create scalars
frame scalars: gen scalars = .
frame scalars: gen strL name = ""

/*
estimates use ${out}/estimates/plan/ivreg/_19dead365_100pct_SampleSelection6BaselineStuff_regs_1B.ster
ivreghdfe
local beta = _b[`alpha']
*/

* ToDo: Check beta before running
local beta = 0.8764
scalar lambda_squared = `=`beta' * `beta''
disp lambda_squared

frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("lambda_squared"))
frame scalars: mata: st_sstore(st_nobs(), "name", "lambda_squared")

* Var(Mu_shrunk)
summarize `alpha' `ifcommand'
scalar var_mu_shrunk = r(Var)
disp var_mu_shrunk

frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_mu_shrunk"))
frame scalars: mata: st_sstore(st_nobs(), "name", "var_mu_shrunk")

local versions A B C D E F
* Elasticities for differen versions
* A = -10
* B = -7
* C = -3.5
* D = -3
* E = -1
* F = -0.5

foreach v of local versions{
	cap drop sample
	gen xi_two_iv`v'                = xi_two_lag`v' * `terminated'
	
	local endogenous                xi_two`v'
	local iv                        xi_two_iv`v'
	local planchars_controls        xi_two_lag`v'

	local results_lin ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_xi_two_lin_`v'
	local results_dec ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_xi_two_dec_`v'

	disp "TABLE 1 ------------------------------------------------------------------------------------"
	* Regressions
	*---------------------------------------------------------------------------
	* IV - Linear -----------
	di `"ivreghdfe `mortality' (`endogenous' =  `iv') `indepvars' `planchars_controls' `ifcommand', absorb(`FE') cluster(`cluster')"'
	ivreghdfe `mortality' (`endogenous' = `iv') `indepvars' `planchars_controls' `ifcommand', absorb(`FE') cluster(`cluster')
	estimates save `"`results_lin'"', replace
    scalar lambda_xi`v' = _b[`endogenous']
    disp lambda_xi`v'

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("lambda_xi`v'"))
    frame scalars: mata: st_sstore(st_nobs(), "name", "lambda_xi`v'")

	* First Stage Regressions - Linear -----------
	di `"reghdfe `endogenous' `iv' `indepvars' `planchars_controls' `ifcommand', absorb(`FE') vce(cluster `cluster')"'
	reghdfe `endogenous' `iv' `indepvars' `planchars_controls' `ifcommand', absorb(`FE') vce(cluster `cluster')
	estimates save `"`results_lin'_FS"', replace

	* Statistics
	*---------------------------------------------------------------------------
	summarize xi_two`v' `ifcommand'
	scalar var_xi_two`v' = r(Var)
	disp var_xi_two`v'

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("var_xi_two`v'"))
    frame scalars: mata: st_sstore(st_nobs(), "name", "var_xi_two`v'")

	disp "TABLE 1 OUTPUT------------------------------------------------------------------------------"

	disp "Implied Utility Coefficient on Premiums"
    qui sum kappa`v'
    scalar kappa`v' = r(mean)
    disp kappa`v'

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("kappa`v'"))
    frame scalars: mata: st_sstore(st_nobs(), "name", "kappa`v'")

	disp "Adjusted Mean Utility Forecast Coefficient"
	disp lambda_xi`v'

	disp "Implied Utility Coefficient on Plan Quality"
	scalar utility_coeff`v' = (var_xi_two`v' * lambda_xi`v')/(lambda_squared * var_mu_shrunk)
	disp utility_coeff`v'

	disp "Implied Value of 1 Percentage Point Reduction in Mortality"
	scalar value_reduc_mortality`v'_1 = utility_coeff`v' / (100 * kappa`v')
	disp value_reduc_mortality`v'_1

	disp "TABLE 2 ------------------------------------------------------------------------------------"
	di "reghdfe `endogenous' `alpha' `indepvars' `planchars_controls' `ifcommand', absorb(`FE') vce(cluster `cluster')"
	reghdfe `endogenous' `alpha' `indepvars' `planchars_controls' `ifcommand', absorb(`FE') vce(cluster `cluster')
	estimates save `"`results_lin'_QUALITY"', replace
	scalar coeff_mu`v' = _b[`alpha']
    disp coeff_mu`v'

    frame scalars: mata: stata(sprintf("set obs %g", st_nobs() + 1))
    frame scalars: mata: st_store(st_nobs(), "scalars", st_numscalar("coeff_mu`v'"))
    frame scalars: mata: st_sstore(st_nobs(), "name", "coeff_mu`v'")

	disp "Implied Utility Coefficient on Premiums"
	disp scalar(kappa`v')

	disp "Adjusted Mean Utility Forecast Coefficient"
	disp "Blank"

	disp "Implied Utility Coefficient on Plan Quality"
	disp coeff_mu`v'

	disp "Implied Value of 1 Percentage Point Reduction in Mortality"
	scalar value_reduc_mortality`v'_2 = coeff_mu`v' / (100 * kappa`v')
	disp value_reduc_mortality`v'_2
}

frame scalars: save "${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_scalars_xi_two_lin.dta", replace

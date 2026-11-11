* Elasticities for differen versions
local A = "-10"
local B = "-7"
local C = "-3.5"
local E = "-1"
local F = "-0.5"

capture frame drop scalars
frame create scalars
frame scalars: use "${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_scalars_xi_two_lin.dta", clear
frame scalars {
    mata: scalars = st_data(., "scalars")
    mata: names   = st_sdata(., "name")

    estimates use ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_SampleSelection6_BaselineStuff_regs_1B.ster
    qui ivreghdfe
    scalar beta = _b[`alpha']
    mata: lambda_squared = st_numscalar("beta")^2
    mata: var_mu_shrunk  = scalars[selectindex(names :== "var_mu_shrunk")]
}

local versions A B C E F
mata table5_rlabels = J(2 * `:list sizeof versions', 1, "")
mata reg_matrix = J(2 * `:list sizeof versions', 4, .)

local i = 0
foreach v of local versions {
    local ++i
    cap drop sample
    local endogenous         xi_two`v'
    local iv                 xi_two_iv`v'
    local planchars_controls xi_two_lag`v'

    local results_lin ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_xi_two_lin_`v'
    estimates use `"`results_lin'"'
    qui ivreghdfe

    mata kappa`v'         = scalars[selectindex(names :== "kappa`v'")]
    mata lambda_xi`v'     = scalars[selectindex(names :== "lambda_xi`v'")]
    mata var_xi_two`v'    = scalars[selectindex(names :== "var_xi_two`v'")]
    mata utility_coeff`v' = (var_xi_two`v' * `=_b[`endogenous']')  / (lambda_squared * var_mu_shrunk)
    mata utility_se`v'    = (var_xi_two`v' * `=_se[`endogenous']') / (lambda_squared * var_mu_shrunk)

    mata reg_matrix[2 * `i' - 1, 1]  = kappa`v'
    mata reg_matrix[2 * `i' - 1, 2]  = `=_b[`endogenous']'
    mata reg_matrix[2 * `i',     2]  = `=_se[`endogenous']'
    mata reg_matrix[2 * `i' - 1, 3]  = utility_coeff`v'
    mata reg_matrix[2 * `i',     3]  = abs(utility_se`v')
    mata reg_matrix[2 * `i' - 1, 4]  = utility_coeff`v' / (100 * kappa`v')
    mata reg_matrix[2 * `i',     4]  = abs(utility_se`v'    / (100 * kappa`v'))
    mata table5_rlabels[2 * `i' - 1] = st_local("`v'")
}

// mata table5_rfmt = J(`:list sizeof versions', 1, "%8.4f" \ "(%8.4f)")
mata table5_rfmt = ///
    J(`:list sizeof versions', 1, "%8.4f" \ "(%8.4f)"), ///
    J(`:list sizeof versions', 1, "%8.4f" \ "(%8.4f)"), ///
    J(`:list sizeof versions', 1, "%8.2f" \ "(%8.2f)"), ///
    J(`:list sizeof versions', 1, "%8.2f" \ "(%8.2f)")

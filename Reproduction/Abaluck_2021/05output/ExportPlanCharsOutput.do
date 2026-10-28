local exogenous_2      monthly_premium_C gap_coverage mlr
local results_lin_2    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_mlr_donut_lin
local results_iv_lin_2 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_premium_mlr_donut_iv_lin

local exogenous_3      monthly_premium_C
local results_lin_3    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_monthlyPremium_lin
local results_iv_lin_3 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`exogenous_3'_iv_lin

local exogenous_4      star_rating_cont
local results_lin_4    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_starRating_lin
local results_iv_lin_4 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`exogenous_4'_iv_lin

local exogenous_5      mlr
local results_lin_5    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_mlr_lin
local results_iv_lin_5 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`exogenous_5'_iv_lin

local exogenous_7      gap_coverage
local results_lin_7    ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_donut_lin
local results_iv_lin_7 ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_`exogenous_7'_iv_lin

mata reg_matrix = J(8 + `="`_iv'" != ""', 5, .)
{
    local i = 0
    foreach id in 4 3 7 5 2 {
        local ++i
        estimates use `"`results`_iv'_lin_`id''"'
        if ( "`_iv'" == "_iv" ) {
            qui ivreghdfe
            mata reg_matrix[rows(reg_matrix), `i'] = `=e(widstat)'
        }
        else {
            qui reghdfe
        }
        scalar NPlanChars = `e(N)'
        if ( `id' == 2 ) {
            local j = 1
            foreach var in `exogenous_`id'' {
                local ++j
                mata reg_matrix[2 * `j' - 1, `i'] = `=_b[`var']'
                mata reg_matrix[2 * `j', `i']     = `=_se[`var']'
            }
        }
        else {
            mata reg_matrix[2 * `i' - 1, `i'] = `=_b[`exogenous_`id'']'
            mata reg_matrix[2 * `i', `i']     = `=_se[`exogenous_`id'']'
        }
    }
}
mata reg_matrix

if ( "`_iv'" == "_iv" ) {
    mata reg_matrix = reg_matrix \ J(1, cols(reg_matrix), .)

    capture frame drop scalars
    frame create scalars
    frame scalars {
        use "${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'`tag'_scalars_iv_lin.dta", clear
        mata: scalars = st_data(., "scalars")
        mata: names   = st_sdata(., "name")
        estimates use ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_SampleSelection6_BaselineStuff_regs_1B.ster
        qui ivreghdfe
        scalar beta = _b[`alpha']
        mata: var_lambda_mu = scalars[selectindex(names :== "var_alpha")] * (st_numscalar("beta")^2)

        local i = 0
        foreach id in 4 3 7 5 2 {
            if ( `:list sizeof exogenous_`id'' > 1 ) {
                local regex
                foreach var of local exogenous_`id' {
                    local regex `regex'(?=.*`var')
                }
            }
            else {
                local regex ^`exogenous_`id''$
            }
            mata: var_xbeta = scalars[selectindex(ustrregexm(names, st_local("regex")))]
            mata: R2 = var_xbeta / var_lambda_mu
            mata: reg_matrix[rows(reg_matrix), `++i'] = R2
        }
    }
}

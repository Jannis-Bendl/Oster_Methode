include "05output/printxlWrapper.do"

if ( `"`versions'"' == "" ) {
    local versions 1B 1F
}
else if (`"`versions'"' != "1B 1D 1F 1H") & (`"`versions'"' != "1B 1F") {
    display as error "NotImplementedException: versions cannot be specified as: `versions'"
    exit 198
}

mata beta_coefs = J(0, 1, .)
mata beta_se    = J(0, 1, .)

mata reg_coefs  = J(0, 1, .)
mata reg_se     = J(0, 1, .)

local T: copy local terminated
foreach v of local versions {
    disp _n(1)
    disp "`v') `xlsheet'"

    disp _n(1)
    disp _skip(4) "REDUCED FORM (`instrument`v'')"
    local results ${out}/estimates/`contract'/ivreg/`pre'FallbackBalance_`pct'pct_`sampleSelection'`tag'_`v'
    estimates use `"`results'_RF"'
    cap areg
    disp _skip(8), %9.4f _b[`instrument`v''], %9.4f _se[`instrument`v''], %6.2f `=_b[`instrument`v''] / _se[`instrument`v'']'
    mata reg_coefs = reg_coefs \ `=_b[`instrument`v'']'
    mata reg_se    = reg_se    \ `=_se[`instrument`v'']'


    disp _n(1)
    disp _skip(4) "IV (`alpha')"
    local results ${out}/estimates/`contract'/ivreg/`pre'FallbackBalance_`pct'pct_`sampleSelection'`tag'_`v'
    estimates use `"`results'"'
    cap ivreghdfe
    disp _skip(8), %-22s `"FallbackBalance"', %9.4f _b[`alpha'], %9.4f _se[`alpha'], %6.2f `=_b[`alpha'] / _se[`alpha']'
    mata beta_coefs = beta_coefs \ `=_b[`alpha']'
    mata beta_se    = beta_se    \ `=_se[`alpha']'
}

// Print N= field
    estimates use `"`results'_RF"'
    qui reghdfe
    local NRF  = `=e(N)'
* JC: Delete next line after confirming that this number is correct
    display "`NRF'"

// mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', beta_coefs, beta_se, col, row)
// mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', reg_coefs,  reg_se,  col, row)

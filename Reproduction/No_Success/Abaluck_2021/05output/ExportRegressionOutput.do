include "05output/printxlWrapper.do"
include "05output/printxlCellWrapper.do"

if ( `"`versions'"' == "" ) {
    local versions 1B 1F
} 
else if (`"`versions'"' != "1B 1D 1F 1H") & (`"`versions'"' != "1B 1F") {
    display as error "NotImplementedException: versions cannot be specified as: `versions'"
    exit 198
}

if (`"`versions'"' == "1B 1F") {
    mata beta_coefs = J(0, 1, .)
    mata beta_se = J(0, 1, .)

    mata iv_f_stats  = J(0, 1, .)
    mata fs_f_stats  = J(0, 1, .)


    mata rf_coefs = J(41, 1, .)
    mata rf_se    = J(41, 1, .)
    mata rf_rsqr  = J(41, 1, .)

    mata fs_coefs = J(41, 1, .)
    mata fs_se    = J(41, 1, .)

    foreach v of local versions {
        local results ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'_`tag'_`v'

        estimates use `"`results'"'
        ivreghdfe
        mata iv_f_stats    = iv_f_stats    \ `=e(F)'
        foreach var in `endogenous' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'

            mata beta_coefs = beta_coefs \ `=_b[`var']'
            mata beta_se    = beta_se    \ `=_se[`var']'
        }

        estimates use `"`results'_RF"'
        reghdfe
        if ( `"`v'"' == "1B" ) local i = 1
        else if ( `"`v'"' == "1F" ) local i = 2
        foreach var in `instrument`v'' {
            mata rf_coefs[`i'] = `=_b[`var']'
            mata rf_se[`i']    = `=_se[`var']'
            mata rf_rsqr[`i']  = `=e(r2)'
            local ++i
        }

        estimates use `"`results'_FS"'
        reghdfe
* JC: this is the wrong Fstat, we use the correct one below.        mata fs_f_stats    = fs_f_stats    \ `=e(F)'
        if ( `"`v'"' == "1B" ) local i = 1
        else if ( `"`v'"' == "1F" ) local i = 2
        foreach var in `instrument`v'' {
            mata fs_coefs[`i'] = `=_b[`var']'
            mata fs_se[`i']    = `=_se[`var']'
            local ++i
        }
        test `instrument`v''
        mata fs_f_stats    = fs_f_stats    \ `=r(F)'
    }

    local xlUsing ${out}/tables/`xlwb'

    // Print N= field
    estimates use `"`results'"'
    qui ivreghdfe
    local NIV  = `=e(N)'

    if ("`table_tag'" == "") {
    mata: printxlCellWrapper(`"`xlUsing'"', `"`xlsheet'"', `"N = `NIV'"', 1, 8)

    // Print out betas
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', beta_coefs, beta_se, 4, 10)

    // Print out the FS variables
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', fs_coefs, fs_se, 6, 10)

    // Print out RF variables
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', rf_coefs, rf_se, 7, 10)

    // Print out F stats
    mata: printxlWrapper_fStat(`"`xlUsing'"', `"`xlsheet'"', iv_f_stats, 8, 10)
    mata: printxlWrapper_fStat(`"`xlUsing'"', `"`xlsheet'"', fs_f_stats, 9, 10)
    }
}
else if (`"`versions'"' == "1B 1D 1F 1H") {
    mata beta_coefs = J(0, 1, .)
    mata beta_se = J(0, 1, .)

    mata iv_f_stats  = J(0, 1, .)
    mata fs_f_stats  = J(0, 1, .)


    mata rf_coefs = J(41, 1, .)
    mata rf_se    = J(41, 1, .)
    mata rf_rsqr  = J(41, 1, .)

    mata fs_coefs = J(41, 1, .)
    mata fs_se    = J(41, 1, .)

    foreach v of local versions {
        local results ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'_`tag'_`v'

        estimates use `"`results'"'
        ivreghdfe
        mata iv_f_stats    = iv_f_stats    \ `=e(F)'
        foreach var in `endogenous' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'

            mata beta_coefs = beta_coefs \ `=_b[`var']'
            mata beta_se    = beta_se    \ `=_se[`var']'
        }

        estimates use `"`results'_RF"'
        reghdfe
        if ( `"`v'"' == "1B" ) local i = 1
        else if ( `"`v'"' == "1D" ) local i = 9
        else if ( `"`v'"' == "1F" ) local i = 3
        else if ( `"`v'"' == "1H" ) local i = 23
        foreach var in `instrument`v'' {
            mata rf_coefs[`i'] = `=_b[`var']'
            mata rf_se[`i']    = `=_se[`var']'
            mata rf_rsqr[`i']  = `=e(r2)'
            local ++i
        }

        estimates use `"`results'_FS"'
        reghdfe
* JC: this is the wrong Fstat, we use the correct one below.        mata fs_f_stats    = fs_f_stats    \ `=e(F)'
        if ( `"`v'"' == "1B" ) local i = 1
        else if ( `"`v'"' == "1D" ) local i = 9
        else if ( `"`v'"' == "1F" ) local i = 3
        else if ( `"`v'"' == "1H" ) local i = 23
        foreach var in `instrument`v'' {
            mata fs_coefs[`i'] = `=_b[`var']'
            mata fs_se[`i']    = `=_se[`var']'
            local ++i
        }
        test `instrument`v''
        mata fs_f_stats    = fs_f_stats    \ `=r(F)'
    }

    local xlUsing ${out}/tables/`xlwb'

    // Print N= field
    estimates use `"`results'"'
    qui ivreghdfe
    local NIV  = `=e(N)'

    if ("`table_tag'" == "") {
    mata: printxlCellWrapper(`"`xlUsing'"', `"`xlsheet'"', `"N = `NIV'"', 1, 8)

    // Print out betas
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', beta_coefs, beta_se, 4, 10)

    // Print out the FS variables
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', fs_coefs, fs_se, 6, 10)

    // Print out RF variables
    mata: printxlWrapper(`"`xlUsing'"', `"`xlsheet'"', rf_coefs, rf_se, 7, 10)

    // Print out F stats
    mata: printxlWrapper_fStat(`"`xlUsing'"', `"`xlsheet'"', iv_f_stats, 8, 10)
    mata: printxlWrapper_fStat(`"`xlUsing'"', `"`xlsheet'"', fs_f_stats, 9, 10)
    }
}

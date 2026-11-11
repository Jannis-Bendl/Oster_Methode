* NOTE(mauricio): Should this be fe_age or fe_age_median? We use the
* latter in the regressions.

if ( `"`versions'"' == "" ) {
    local versions 1B 1D 1F 1H
}

if (`:list sizeof endogenous' > 1) {
	disp as error "Multiple Endogeneous variables detected; rewrite the code so the first stage runs one" ///
			_n(1) "variable at a time -- IV and RF regressions are correct"
	exit 198
}

foreach v of local versions {
    foreach demo of local balancevars {
        local results ${out}/estimates/`contract'/ivreg/`pre'`demo'_`pct'pct_`sampleSelection'`tag'_`v'

        *************************
        * Run OLS Balance Tests *
        *************************

        * DEBUG
        di `"reghdfe `demo' `indepvars' `demoControls' `ifcommand', absorb(`demoFE') vce(cluster `cluster')"'
        reghdfe `demo' `indepvars' `demoControls' `ifcommand', absorb(`demoFE') vce(cluster `cluster')
        estimates save `"`results'_REG"', `replace'
        local beta = `=_b[`terminated']'
        local se   = `=_se[`terminated']'
        local NREG = `=e(N)'
        mata: printf("REG (N = %21.0fc) `terminated': %7.3f (%7.3f)\n", `NREG', `beta', `se')


        *****************************************
        * Run IV and Reduced Form *
        *****************************************

        di `"ivreghdfe `demo' (`endogenous' =   `instrument`v'') `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')"'
        ivreghdfe `demo' (`endogenous' = 	`instrument`v'') `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')
        estimates save `"`results'"', replace
        foreach var in `endogenous' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'
            local NIV  = `=e(N)'
            mata: printf("IV (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NIV', `beta', `se')
        }

        di `"reghdfe `demo' `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') vce(cluster `cluster')"'
        reghdfe `demo' `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') vce(cluster `cluster')
        estimates save `"`results'_RF"',  replace
        foreach var in `instrument`v'' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'
            local NRF  = `=e(N)'
            mata: printf("RF (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NRF', `beta', `se')
        }
    }
}

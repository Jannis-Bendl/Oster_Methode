if (`:list sizeof endogenous' > 1) {
	disp as error "Multiple Endogeneous variables detected; rewrite the code so the first stage runs one" ///
			_n(1) "variable at a time -- IV and RF regressions are correct"
	exit 198

}

foreach v of local versions {
    local results ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'_`tag'_`v'

    * IV
    di `"ivreghdfe `mortality' (`endogenous' =   `instrument`v'') `indepvars`v'' `ifcommand' `addCond', absorb(`FE') cluster(`cluster')"'
    ivreghdfe `mortality' (`endogenous' = 	`instrument`v'') `indepvars`v'' `ifcommand' `addCond', absorb(`FE') cluster(`cluster')
    estimates save `"`results'"', replace
    foreach var in `endogenous' {
        local beta = `=_b[`var']'
        local se   = `=_se[`var']'
        local NIV  = `=e(N)'
        mata: printf("IV (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NIV', `beta', `se')
    }

    * Reduced Form
    di `"reghdfe `mortality' `instrument`v'' `indepvars`v'' `ifcommand' `addCond', absorb(`FE') vce(cluster `cluster')"'
    reghdfe `mortality' `instrument`v'' `indepvars`v'' `ifcommand'   `addCond', absorb(`FE') vce(cluster `cluster')
    estimates save `"`results'_RF"',  replace
    foreach var in `instrument`v'' {
        local beta = `=_b[`var']'
        local se   = `=_se[`var']'
        local NRF  = `=e(N)'
        mata: printf("RF (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NRF', `beta', `se')
    }

    * First Stage
    di `"reghdfe `endogenous' `instrument`v'' `indepvars`v'' `ifcommand'  `addCond', absorb(`FE') vce(cluster `cluster')"'
    reghdfe `endogenous' `instrument`v'' `indepvars`v'' `ifcommand' `addCond', absorb(`FE') vce(cluster `cluster')
    estimates save `"`results'_FS"',  replace
    qui test `instrument`v''
    disp "F-Stat: `r(F)'"
    foreach var in `instrument`v'' {
        local beta = `=_b[`var']'
        local se   = `=_se[`var']'
        local NFS  = `=e(N)'
        mata: printf("FS (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NFS', `beta', `se')
    }

    * OLS
    di `"reghdfe `mortality' `endogenous' `indepvars`v'' `ifcommand' `addCond', absorb(`FE') vce(cluster `cluster')"'
    reghdfe `mortality' `endogenous' `indepvars`v'' `ifcommand' `addCond', absorb(`FE') vce(cluster `cluster')
    estimates save `"`results'_OLS"',  replace
    foreach var in `endogenous' {
        local beta = `=_b[`var']'
        local se   = `=_se[`var']'
        local NIV  = `=e(N)'
        mata: printf("IV (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NIV', `beta', `se')
    }
}

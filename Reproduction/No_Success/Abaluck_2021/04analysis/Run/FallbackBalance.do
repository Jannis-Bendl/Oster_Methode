if ( `"`versions'"' == "" ) {
    local versions 1B 1D 1F 1H
}

***********************************
*********** Regressions ***********
***********************************
foreach v of local versions {
	local results ${out}/estimates/`contract'/ivreg/`pre'FallbackBalance_`pct'pct_`sampleSelection'`tag'_`v'
	* IV Regression --------------
	di `"ivreghdfe eta (`endogenous' =  `instrument`v'') `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')"'
	ivreghdfe eta (`endogenous' = 	`instrument`v'') `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')
		estimates save `"`results'"', `replace'
	        foreach var in `endogenous' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'
            local NIV  = `=e(N)'
            mata: printf("IV (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NIV', `beta', `se')
        }

	* Reduced Form --------------
	di `"reghdfe eta `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')"'
	reghdfe eta `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') cluster(`cluster')
	estimates save `"`results'_RF"', `replace'
        foreach var in `instrument`v'' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'
            local NRF  = `=e(N)'
            mata: printf("RF (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NRF', `beta', `se')
        }


	* First Stage --------------
	di `"reghdfe `endogenous' `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') vce(cluster `cluster')"'
    reghdfe `endogenous' `instrument`v'' `indepvars`v'' `ifcommand', absorb(`FE') vce(cluster `cluster')
	estimates save `"`results'_FS"', `replace'
        foreach var in `instrument`v'' {
            local beta = `=_b[`var']'
            local se   = `=_se[`var']'
            local NFS  = `=e(N)'
            mata: printf("FS (N = %21.0fc) `var': %7.3f (%7.3f)\n", `NFS', `beta', `se')
        }
}

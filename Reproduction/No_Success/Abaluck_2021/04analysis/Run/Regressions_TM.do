if (`:list sizeof endogenous' > 1) {
	disp as error "Multiple Endogeneous variables detected; rewrite the code so the first stage runs one" ///
			_n(1) "variable at a time -- IV and RF regressions are correct"
	exit 198
}

* Generate Instrument - TM
gen instrument_TM = `terminated' * TM_share_lag

* Specifcy X Variable
local endogenousx1 mTM
local endogenousx2 mTM `alpha'
*Specifcy Instrument
local instrumentx1 instrument_TM
local instrumentx2 instrument_TM instrument

* Generate Different Control Versions
local indepvars `indepvars' TM_share_lag
local indepvars: subinstr local indepvars "`interact'" "", all
local FE: subinstr local FE "`interact'" "", all

local indepvarsc1 `indepvars'
local FEc1 `FE'

local indepvarsc2 `indepvars'
local FEc2 `FE' `interact'i.year
local FEc2: subinstr local FEc2 "i.year" "", word

local indepvarsc3 `indepvars'
local FEc3 `FE' `interact'fe_county_lag
local FEc3: subinstr local FEc3 "fe_county_lag" "", word

local indepvarsc4 `indepvars'
local FEc4 `FE' `interact'i.year `interact'fe_county_lag
local FEc4: subinstr local FEc4 "fe_county_lag" "", word
local FEc4: subinstr local FEc4 "i.year" "", word


* Test Regression - First Stage
di "reghdfe `endogenousx1' `instrumentx1' `terminated' TM_share_lag  `ifcommand', absorb(fe_county_lag_year)"
reghdfe `endogenousx1' `instrumentx1' `terminated' TM_share_lag `ifcommand', absorb(fe_county_lag_year)

forvalues i = 1 / 2 {
    forvalues j = 1 / 4 {
    * IV
    di `"ivreghdfe `mortality' (`endogenousx`i'' =   `instrumentx`i'') `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') cluster(`cluster')"'
    ivreghdfe `mortality' (`endogenousx`i'' =   `instrumentx`i'') `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') cluster(`cluster')
    
    * Reduced Form
    di `"reghdfe `mortality' `instrumentx`i'' `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') vce(cluster `cluster')"'
    reghdfe `mortality' `instrumentx`i'' `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') vce(cluster `cluster')

    * First Stage
    di `"reghdfe `endogenousx`i'' `instrumentx`i'' `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') vce(cluster `cluster')"'
    reghdfe `endogenousx`i'' `instrumentx`i'' `indepvarsc`j'' `ifcommand' `addCond', absorb(`FEc`j'') vce(cluster `cluster')

    }
}
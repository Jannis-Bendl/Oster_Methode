* ---------------------------------------------------------------------
* Title:    Regression Options
* Blame:    Mauricio Caceres, Aaron Pollack
* Reformat: Emily Crawford (emily.crawford@yale.edu)
* Created:
* Updated:  Friday, March 15th 2020
* Purpose:  [TODO: Fill in.]
* Notes:
*           indepvars
*              IV Regression
*              Balance Tests
* ---------------------------------------------------------------------

* Classify Dependent Variable and Endogenous Variable
*---------------------------------------------------------------------------
local mortality    died_365         // Dependent variable
if (`"`two_year_mortality'"' != ""){
    local mortality dum_died_two_yr //Two-Year-Mortality
}
local endogenous   `alpha'          // Endogenous variable

* Add Independent Variables
*---------------------------------------------------------------------------
local indepvars  `indepvars' `alphalag'

* adds average risk score lag as a control if bene_demo's are specified (such as when `"`tag'"' == "BaselineStuff_regs_riskScore")
if (`"`risk_score_control'"' != "") {
    local indepvars `indepvars' average_risk_score_lag
}

if ( `"`indepvars'"' == "" ) {
    local indepvars `terminated' frac_plan_county_lag `ivcontrols'  // exogenous covariates
}


* Add Balance Variables
*---------------------------------------------------------------------------

local balancevars average_risk_score demo_age dum_sex2 mDual dum_race2 //Variables for balance
if ( `"`lagMortalityBalance'"' != "" ) {
    local balancevars  predictedMortality_dual lag_mortality predictedMortality_dual_risk  //Run with just Predicted Mortality and Lag Mortality
}

* Different Versions of the Instrument
*---------------------------------------------------------------------------
local instrument1B instrument
local instrument1D `cZDec'
local instrument1F Zxdum_med
local instrument1H `cZVen'

// todo(pollacka): add deciles and ventiles (_cZdec, _cZven) for otput

* Add controls and instrument for Traditional Medicare
if ( `"`addTM'"' != "" ) {
    local indepvars  `indepvars'  `tm'_lag  frac_`tm'_lag
    local endogenous `endogenous' `tm'
    foreach v of local versions {
        local instrument`v' `instrument`v'' ZxFracTM
    }
}

* Add controls and instrument for employee-sponsored plans
if ( `"`addEmployer'"' != "" ) {
    local indepvars  `indepvars' `employer'_lag  frac_`employer'_lag
    local endogenous `endogenous' `employer'
    foreach v of local versions {
        local instrument`v' `instrument`v'' ZxFracEmployer
    }
}

* Define Different or Same Controls for Each Instrument Version
if ( `"`controlsNormalized'"' == "" ) {
    * Different Controls for Each Version
    local indepvars1B `indepvars' `alpha'_lag
    local indepvars1D `indepvars' `cDec'
    local indepvars1F `indepvars' dum_med
    local indepvars1H `indepvars' `cVen'
}
else {
    * Same Controls for Each Version
    local indepvars `indepvars' dum_med

    local indepvars1B `indepvars'
    local indepvars1D `indepvars'
    local indepvars1F `indepvars'
    local indepvars1H `indepvars'
}

if (`"`addDec'"' != "") {
    local indepvars1D `indepvars1D' `cDec'
}


* Unless dropDec is specified include the decile controls
if (`"`dropDec'"' == "") {
    local indepvars1B `indepvars1B' `cDec'
    local indepvars1D `indepvars1D' `cDec'
    local indepvars1F `indepvars1F' `cDec'
    local indepvars1H `indepvars1H' `cVen'
}

* Unless dropAlphaLag is specified include the dropAlphaLag control
if (`"`dropAlphaLag'"' == "") {
    local indepvars1B `indepvars1B' `alpha'_lag
    local indepvars1D `indepvars1D' `alpha'_lag
    local indepvars1F `indepvars1F' `alpha'_lag
    local indepvars1H `indepvars1H' `alpha'_lag
}

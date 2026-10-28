local 0: subinstr local 0 ";" ","
syntax anything, optsFolder(str) tag(str) [appendix runReg runPlanCharReg runBalance runFallback runXi runPredictedMortality]
local sampleSelection: copy local anything

do 00common/00preamble.do nodep
include 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
do 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')

local cDec
local cZDec
forvalues i = 2 / 10 {
    local cDec  `cDec'  dum_dec`i'
    local cZDec `cZDec' Zxdum_dec`i'
}

local cVen
local cZVen
forvalues i = 2 / 20 {
    local cVen  `cVen'  dum_ven`i'
    local cZVen `cZVen' Zxdum_ven`i'
}

if ( `"`runReg'"' != "" ) {
    include 04analysis/Parse/RegressionOptions.do
    include 05output/ExportRegressionOutput.do

    // note the added code below to the runReg trigger:
    display `"`tag'"'
    display `"`table_tag'"'
    if ("`table_tag'" != "") {
        local tag: subinstr local tag "_1pct" ""
        if ("`tag'" == "BaselineStuff_regs") {
            mata Mregs = dropmissrow(fs_coefs)'   \ ///
                         dropmissrow(fs_se)'      \ ///
                         dropmissrow(fs_f_stats)' \ ///
                         dropmissrow(rf_coefs)'   \ ///
                         dropmissrow(rf_se)'      \ ///
                         dropmissrow(beta_coefs)' \ ///
                         dropmissrow(beta_se)'
            mata Specregs = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regsNoDemo") {
            mata MregsNoDemo = dropmissrow(fs_coefs)'   \ ///
                               dropmissrow(fs_se)'      \ ///
                               dropmissrow(fs_f_stats)' \ ///
                               dropmissrow(rf_coefs)'   \ ///
                               dropmissrow(rf_se)'      \ ///
                               dropmissrow(beta_coefs)' \ ///
                               dropmissrow(beta_se)'
            mata SpecregsNoDemo = "Linear" , "Median" \ "No" , "No"
        }
        else if ("`tag'" == "BaselineStuff_regs_countyTerm") {
            mata Mregs_countyTerm = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_countyTerm = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_noTM") {
            mata Mregs_noTM = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_noTM = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_PFFS") {
            mata Mregs_PFFS = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_PFFS = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_noPFFS") {
            mata Mregs_noPFFS = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_noPFFS = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_noDuals") {
            mata Mregs_noDuals = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_noDuals = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_riskScore") {
            mata Mregs_riskScore = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_riskScore = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_ageEffect") {
            mata Mregs_ageEffect = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_ageEffect = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_unshrunk") {
            mata Mregs_unshrunk = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_unshrunk = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_jackknife") {
            mata Mregs_jackknife = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_jackknife = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_excl_small_bin") {
            mata Mregs_excl_small_bin = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_excl_small_bin = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_twoYearMort") {
            mata Mregs_twoYearMort = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_twoYearMort = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if ("`tag'" == "BaselineStuff_regs_eta") {
            mata Mregs_excl_small_bin = beta_coefs' \ beta_se'
            local Nlocals `Nlocals' `=e(N)'
            mata Specregs_excl_small_bin = "Linear" , "Median" \ "Yes" , "Yes"
        }
        else if inlist("`tag'", "BaselineStuff_regsNoDemo_eta", "BaselineStuff_regs_eta_ind", "BaselineStuff_regsNoDemo_eta_ind") {
        }
        local tag_ext: subinstr local tag "BaselineStuff_" ""
        local objtags rfcoef rfrsqr fscoef
        foreach obj in rf_coefs rf_rsqr fs_coefs {
            gettoken objtag objtags: objtags
            cap mata mata desc `obj'
            if ( _rc == 0 ) {
                mata M`tag_ext'_`objtag' = `obj'[1]
            }
        }
    }
}

if ( `"`runBalance'"' != "" ) {
    if ( "`appendix'" == "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 05output/ExportBalanceOutput.do
        * JC: Add if-trigger below to create mata matrix for Table 2 automation
        if ("`table_tag'" != "") {
            mata MpanelB = reg_coefs' \ reg_se'
        }
    }
    else {
        include 04analysis/Parse/RegressionOptions.do
        include 05output/ExportAdditionalBalance.do
    }
}

* JC: Add this if-trigger for Table 2 automation
if ( `"`runFallback'"' != "" ) {
    include 04analysis/Parse/RegressionOptions.do
    include 05output/ExportFallbackOutput.do
    if ("`table_tag'" != "") {
        mata MpanelC = reg_coefs' \ reg_se'
    }
}


if ( `"`runPlanCharReg'"' != "" ) {
    include 04analysis/Parse/RegressionOptions.do
    if ("`table_tag'" != "") {
        local tagstr: subinstr local tag "_1pct" ""
        if ("`tagstr'" == "PlanCharsRegressionsV4_ols") {
            local _iv
        }
        else if ("`tagstr'" == "PlanCharsRegressionsV4_iv") {
            local _iv _iv
        }
    }
    include 05output/ExportPlanCharsOutput.do
}

if ( `"`runXi'"' != "" ) {
    if ("`table_tag'" != "") {
        local tagstr: subinstr local tag "_1pct" ""
        if ("`tagstr'" == "XiRegressions") {
            include 04analysis/Parse/RegressionOptions.do
            include 05output/ExportXiOutput.do
        }
    }
}

if ( `"`runPredictedMortality'"' != "" ) {
    include 04analysis/Parse/RegressionOptions.do
    include 05output/ExportPredictedMortality.do
}

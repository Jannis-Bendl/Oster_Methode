* e.g. make 04analysis ARGS="runReg" TAG="AaronRegressionsv1"

local 0: subinstr local 0 ";" ","
syntax anything, optsFolder(str) tag(str) [ ///
    runReg                                  ///
    runPlots_diff_avg                       ///
    runPlots_diff_normalized                ///
    runPlots_balance                        ///
    runPlots_FSRF_viv                       ///
    runPlots_balance_riskscore              ///
    runPlots_balance_age                    ///
    runPlots_map                            ///
    runBalance                              ///
    runPlanCharReg_IV                       ///
    runPlanCharReg_OLS                      ///
    runPlanCharRegParent_IV                 ///
    runPlanCharRegParent_OLS                ///
    runFallback                             ///
    runSwitchingBehavior                    ///
    runPredictedMortality                   ///
    runCountyChars                          ///
    runXi                                   ///
    runReg_TM                               ///
    nocached                                ///
]

set more off
set varabbrev off
local sampleSelection: copy local anything

local startTime $S_TIME $S_DATE
local logName 04ivReg`sampleSelection'`tag'
log using `"`logName'.log"', text replace

cap noi {
    do 00common/00preamble.do
    do 98adHoc/addProgram.do
    do 98adHoc/addXiProgram.do

    include 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
    do 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')

    local cachedFile ${data}/`pre'`sampleSelection'_`pct'pct.dta
    cap confirm file "`cachedFile'"
    if ( ("`cached'" != "") | _rc ) {
        include 04analysis/Preprocessing/`sampleSelection'.do
        save "`cachedFile'", replace
    }
    else {
        use "`cachedFile'", clear
    }
    include 04analysis/Preprocessing/SampleSelectionMacros.do

    if ( `"`runReg'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Regressions.do
    }

    if (  `"`runFallback'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/FallbackBalance.do
    }

    if (  `"`runPlanCharReg_IV'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
		include 04analysis/Run/PlanCharsRegressions_IV.do
    }

    if (  `"`runPlanCharReg_OLS'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/PlanCharsRegressions_OLS.do
    }

    if (  `"`runPlanCharRegParent_IV'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
		include 04analysis/Run/PlanCharsRegressionsParent_IV.do
    }

    if (  `"`runPlanCharRegParent_OLS'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/PlanCharsRegressionsParent_OLS.do
    }

    if ( `"`runBalance'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Balance.do
    }

    if ( ((`"`runPlots_diff_avg'"' != "")|(`"`runPlots_diff_normalized'"' != "")) & (`"`plotsTag'"' == "") ) {
        disp as err "Please provide plotsTag() to run the figures"
        exit 198
    }

    if ( `"`runPlots_diff_avg'"' != "" ) {
        include 04analysis/PlotsMerge/Version`plotsVersion'.do
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/diff_in_diff/Figures_v`plotsVersion'.do
        * include 04analysis/Run/Figures/diff_in_diff/Figures_v`plotsVersion'_pooled.do
    }

    if ( `"`runPlots_diff_normalized'"' != "" ) {
        include 04analysis/PlotsMerge/Version`plotsVersion'.do
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/diff_in_diff/Figures_v`plotsVersion'.do
        * include 04analysis/Run/Figures/diff_in_diff/Figures_v`plotsVersion'_pooled.do
    }


    if ( `"`runPlots_balance'"' != "" ) {
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/balance_fig.do
    }

    if ( `"`runPlots_FSRF_viv'"' != "" ) {
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/balance_fig.do
    }

    if ( `"`runPlots_balance_riskscore'"' != "" ) {
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/controls_balance.do
    }

    if ( `"`runPlots_balance_age'"' != "" ) {
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/controls_balance.do
    }

    if ( `"`runPlots_map'"' != "" ) {
        do 00common/00material.do
        include 04analysis/Parse/FigureOptions.do
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/term_map.do
    }

    if ( `"`runCountyChars'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Figures/term_map.do
    }

    if ( `"`runSwitchingBehavior'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/SwitchingBehavior.do
    }

    if ( `"`runPredictedMortality'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/PredictedMortality.do
    }

    if ( `"`runXi'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/XiRegressions.do
    }

    if ( `"`runReg_TM'"' != "" ) {
        include 04analysis/Parse/RegressionOptions.do
        include 04analysis/Run/Regressions_TM.do
    }
}

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

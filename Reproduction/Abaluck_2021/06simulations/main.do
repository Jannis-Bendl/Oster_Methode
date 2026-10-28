* e.g. make 06simulations SAMPLE="SampleSelection6" OPTS_FOLDER="BaselineStuff-take4-simulations" TAG="BaselineStuff_regs_newsample" &
local 0: subinstr local 0 ";" ","
syntax anything, optsFolder(str) tag(str)
local sampleSelection: copy local anything

local startTime $S_TIME $S_DATE
local logName 06simulation`sampleSelection'`tag'
log using `"`logName'.log"', text replace
set seed 42

cap noi {
    do 00common/00preamble.do nodep
    do 03ivSample/HierarchicalEffects.do
    do 06simulations/ByBin.do
    do 98adHoc/addProgram.do
    do 98adHoc/addXiProgram.do

    include 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
    do 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')

    use `"${data}/`pre'alphas`pct'.dta"', clear
    drop if mi(`bin_var')
    keep bene_code year mean_died_365_`bin_suf' plan_size_forbins
    gisid bene_code year
    tempfile mean_died
    save `"`mean_died'"'

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
    cap noi keep `ifcommand' `addCond'
    merge 1:1 bene_code year using `"`mean_died'"', keep(1 3) nogen assert(2 3)

    simulate, v(1B)             ///
        pre(`pre')              ///
        pct(`pct')              ///
        bin_var(`bin_var')      ///
        fesuf(`fesuf')          ///
        bin_suf(`bin_suf')      ///
        contract(`contract')    ///
        tag(BaselineStuff_regs) ///
        sampleSelection(`sampleSelection')
}

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

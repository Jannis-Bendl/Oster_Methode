* Objective:    Automate the latex output of Table 2.
* Note:         This code *heavily* borrows from 05output.do
* Blame:        Jerray Chang
* Created:      12/15/2020
* Last Updated: 3/12/2021

* Instructions: run this code _after_ the appropriate 04analysis runs are complete.
* Example:      make table2 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &

* Depends:
*     00preamble.do
*     04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
*     04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')
*     include 04analysis/Parse/RegressionOptions.do
*     include 05output/ExportRegressionOutput.do

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/table2_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option1 "SampleSelection6; runReg      optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo_1pct)"
    local run_option2 "SampleSelection2; runBalance  optsFolder(`optsFolder') tag(BaselineStuff_balanceTestLagMortality_1pct)"
    local run_option3 "SampleSelection2; runFallback optsFolder(`optsFolder') tag(BaselineStuff_fallBackBalanceTest_1pct)"
}
else {
    local run_option1 "SampleSelection6; runReg      optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo)"
    local run_option2 "SampleSelection2; runBalance  optsFolder(`optsFolder') tag(BaselineStuff_balanceTestLagMortality)"
    local run_option3 "SampleSelection2; runFallback optsFolder(`optsFolder') tag(BaselineStuff_fallBackBalanceTest)"
}

foreach option in 1 2 3 {
    local table_tag table_tag
    local 0: copy local run_option`option'
    include 05output/main.do
}

* note: we use the local `NRF' for N-bene-years.
include 05output/paper/table2_latexWrapper.do

local out ${out}/tables/`pre'Table2_`pct'pct.tex
mata latex_table2(table2_matrix,      ///
                  table2_fmt,         ///
                  table2_specs,       ///
                  table2_rlabels,     ///
                  table2_paneltitles, ///
                  table2_header,      ///
                  table2_footer,      ///
                  table2_space,       ///
                  7, "\midrule",      ///
                  `"`out'"', `NRF')

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

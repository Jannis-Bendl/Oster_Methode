* Objective: Automate the latex output of Table 3.
* Note:      This code *heavily* borrows from 05output.do
* Blame:     Jerray Chang <jerray@uchicago.edu>
* Modified:  Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>
* Created:   12/7/2020
* Example:   make table3 SAMPLE="SampleSelection6" OPTS_FOLDER="BaselineStuff-take4" &

* Warning: The specifications (linear or median) are hardcoded based on the order
*          that 05output/ExportRegressionOutput.do parses and saves the coefs, se,
*          and fstats. In other words, if for some reason ExportRegressionOutput.do
*          is changed such that the assumption below is no longer the case, then
*          the Latex output will _not_ adjust with this change.
*          
*          The code runs on the assumption that for each stat (e.g. beta_coefs,
*          beta_se, fs_f_stats, etc.),  ExportRegressionOutput.do puts all the
*          numbers for model "1B" in the first element, and the numbers for the
*          model "1F" in the second.

* Instructions: run this code _after_ the appropriate 04analysis runs are complete.

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/table3_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option1 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs_1pct)"
    local run_option2 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo_1pct)"
}
else {
    local run_option1 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs)"
    local run_option2 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo)"
}

foreach option in 1 2 {
    local table_tag table_tag
    local 0: copy local run_option`option'
    include 05output/main.do
}

include 05output/paper/table3_latexWrapper.do

local out ${out}/tables/`pre'Table3_`pct'pct.tex
mata latex_table3(table3_matrix,      ///
                  table3_fmt,         ///
                  table3_specs,       ///
                  table3_rlabels,     ///
                  table3_paneltitles, ///
                  table3_header,      ///
                  table3_footer,      ///
                  table3_space,       ///
                  7, "\midrule",      ///
                  `"`out'"', `NIV')

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

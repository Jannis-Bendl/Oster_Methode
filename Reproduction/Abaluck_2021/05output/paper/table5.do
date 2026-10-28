* Automated Latex output for Table 5: WTP Bounds
* Blame:    Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str) scalars]

local startTime $S_TIME $S_DATE
local logName logs/table5_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option "SampleSelection2; optsFolder(`optsFolder') tag(XiRegressions_1pct)"
}
else {
    local run_option "SampleSelection2; optsFolder(`optsFolder') tag(XiRegressions)"
}

{
    local 0: copy local run_option
    if ( "`scalars'" != "" ) {
        include 05output/main.do
        include 05output/paper/table5_scalars.do
    }
    local 0 `run_option' runXi
    local table_tag table_tag
    include 05output/main.do

    local out ${out}/tables/`pre'Table5_`pct'pct.tex
    mata export_latex(reg_matrix, `"`out'"', "", "", "", ///
                      table5_rlabels, table5_rfmt, ///
                      rows(table5_rlabels), "\bottomrule")
}

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

* Automated Latex output for Table A3: Predicted Mortality Model
* Blame:    Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/tableA3_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option "SampleSelection6; runPredictedMortality optsFolder(`optsFolder') tag(BaselineStuff_regs_1pct)"
}
else {
    local run_option "SampleSelection6; runPredictedMortality optsFolder(`optsFolder') tag(BaselineStuff_regs)"
}

{
    local table_tag table_tag
    local 0: copy local run_option
    include 05output/main.do

    local out ${out}/tables/`pre'tableA3_`pct'pct.tex
    mata export_latex(reg_matrix, `"`out'"', "", "", "", ///
                      tableA3_rlabels, tableA3_rfmt,     ///
                      (rows(tableA3_rlabels) - 2 \ rows(tableA3_rlabels)), ("\midrule" \ "\bottomrule"))
}

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

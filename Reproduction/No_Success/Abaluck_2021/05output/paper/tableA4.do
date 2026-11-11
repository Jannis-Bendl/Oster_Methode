* Automated Latex output for Table A4: Additional Balance Tests
* Blame:    Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/tableA4_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option1 "SampleSelection2; runBalance optsFolder(`optsFolder') tag(BaselineStuff_balanceTests_1pct)"
    local run_option2 "SampleSelection2; runBalance optsFolder(`optsFolder') tag(BaselineStuff_balanceTestLagMortality_1pct)"
}
else {
    local run_option1 "SampleSelection2; runBalance optsFolder(`optsFolder') tag(BaselineStuff_balanceTests)"
    local run_option2 "SampleSelection2; runBalance optsFolder(`optsFolder') tag(BaselineStuff_balanceTestLagMortality)"
}

foreach option in 1 2 {
    local 0: copy local run_option`option'
    local 0 `0' appendix
    include 05output/main.do
}

{
    mata tableA4_rlabels1 = "Age" \ "Male" \ "White" \ "Dual-Eligible" \ "Plan Risk Score"
    mata tableA4_rlabels2 = "Predicted Mortality" \ ""
    mata tableA4_rlabels1 = colshape((tableA4_rlabels1, J(rows(tableA4_rlabels1), 1, "")), 1)
    mata tableA4_rlabels2 = colshape((tableA4_rlabels2, J(rows(tableA4_rlabels2), 1, "")), 1)
    mata tableA4_rlabels  = tableA4_rlabels1 \ tableA4_rlabels2
    mata tableA4_rlabels[rows(tableA4_rlabels)-1] = "Predicted Mortality"
    mata tableA4_rlabels[rows(tableA4_rlabels)]   = "\hspace{0.4cm}(with Risk Score)"

    mata reg_matrix   = reg_matrix1 \ reg_matrix2
    mata tableA4_rfmt = reg_rfmt1 \ reg_rfmt2
    mata N = sprintf("N Beneficiary-Years & \multicolumn{2}{c}{%15.0fc} \\\bottomrule", `=e(N)')

    local out ${out}/tables/`pre'tableA4_`pct'pct.tex
    mata export_latex(reg_matrix, `"`out'"', "", "", "", ///
                      tableA4_rlabels, tableA4_rfmt,     ///
                      rows(tableA4_rlabels),             ///
                      ("\midrule Specification & \mc{Linear} & \mc{Median} \\ " + N))
}

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

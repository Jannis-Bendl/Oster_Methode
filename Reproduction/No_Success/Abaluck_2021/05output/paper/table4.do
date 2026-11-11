* Automated Latex output for Table 4: Plan Characteristics Regressions
* Blame:    Jerray Chang <jerray@uchicago.edu>
* Modified: Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str) scalars]

local startTime $S_TIME $S_DATE
local logName logs/table4_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option1 "SampleSelection2; runPlanCharReg optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_ols_1pct)"
    local run_option2 "SampleSelection2; runPlanCharReg optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_iv_1pct)"
}
else {
    local run_option1 "SampleSelection2; runPlanCharReg optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_ols)"
    local run_option2 "SampleSelection2; runPlanCharReg optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_iv)"
}

if ( "`scalars'" != "" ) {
    local 0 SampleSelection2; optsFolder(`optsFolder') tag(PlanCharsRegressionsV4_iv)
    include 05output/main.do
    include 05output/paper/table4_scalars.do
}

foreach option in 1 2 {
    local table_tag table_tag
    local 0: copy local run_option`option'
    include 05output/main.do

    local out ${out}/tables/`pre'Table4_`pct'pct_Panel`option'.tex

    mata table4_rlabels =           ///
        "Star Rating"             \ ///
        ""                        \ ///
        "Premium"                 \ ///
        ""                        \ ///
        "Has Donut Hole Coverage" \ ///
        ""                        \ ///
        "Medical Loss Ratio"      \ ///
        ""

    mata table4_rfmt = ///
        "%8.4f"   \    ///
        "(%8.4f)" \    ///
        "%8.4f"   \    ///
        "(%8.4f)" \    ///
        "%8.4f"   \    ///
        "(%8.4f)" \    ///
        "%8.4f"   \    ///
        "(%8.4f)"

    mata table4_ivlabels = "First-Stage F Statistic"  \ "Maximum Forecast R\${}^2\$"
    mata table4_ivfmt    = "\mc{%8.1fc}"              \ "%8.4f"

    if ( "`_iv'" == "" ) {
        mata export_latex(reg_matrix, `"`out'"', "", "", "", ///
                          table4_rlabels, table4_rfmt, 1, "")
    }
    else {
        mata NPlanChars = sprintf("\midrule N Beneficiary-Years & \multicolumn{5}{c}{%15.0fc} \\\bottomrule", st_numscalar("NPlanChars"))
        mata export_latex(reg_matrix, `"`out'"', "", "", "", ///
                          table4_rlabels \ table4_ivlabels, table4_rfmt \ table4_ivfmt, ///
                          (rows(table4_rlabels) \ rows(reg_matrix)), ///
                          ("\midrule" \ NPlanChars))
    }
}

capture error 0

mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

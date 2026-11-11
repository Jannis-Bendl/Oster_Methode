* Objective: automate the latex output of the "Oster" table.
* Blame:     Jerray Chang <jerray@uchicago.edu>
* Created:   March 8, 2021
* Updated:   March 12, 2021
* Purpose:   Create automated output of "Oster" table on forecast coefficient sensitivity to OVB.
* Note:      make command example: make osterOVB PCT="100" PRE="_19" &

capture error 0

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/osterOVB_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

if ("`pct'" == "01") {
    local run_option1 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo_1pct)"
    local run_option2 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs_1pct)"
    local run_option3 "SampleSelection2; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs_eta_ind_1pct)"
}
else {
    local run_option1 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regsNoDemo)"
    local run_option2 "SampleSelection6; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs)"
    local run_option3 "SampleSelection2; runReg optsFolder(`optsFolder') tag(BaselineStuff_regs_eta_ind)"
}

{
    foreach option in 1 2 3 {
        local table_tag table_tag
        local 0: copy local run_option`option'
        include 05output/main.do
    }

    di "Checkpoint: Oster calculations analogous to Peter's Excel sheet"
mata
    one          = J(4,1,1)
    temp         = J(4,1,.)
    rf_r2        = J(4, 1, .)
    max_r2       = (1.3, 1.3, 5, 5)
    selectn_prop = (1, 3, 1, 3)

    if (Mregs_rfcoef != MregsNoDemo_rfcoef) x = (Mregs_rfcoef - MregsNoDemo_rfcoef) / (Mregs_rfrsqr - MregsNoDemo_rfrsqr)
    if (Mregs_rfcoef == MregsNoDemo_rfcoef) x = 0

    temp  = Mregs_rfrsqr * (max_r2' - one)
    temp  = (temp, one)
    rf_r2 = rowmin(temp)
    rf_coef_bonus = abs((selectn_prop' * x) :* rf_r2)
    min_rf_coef   = (Mregs_rfcoef * one) - rf_coef_bonus
    max_rf_coef   = (Mregs_rfcoef * one) + rf_coef_bonus
    min_for_coef  = max_rf_coef / Mregs_fscoef
    max_for_coef  = min_rf_coef / Mregs_fscoef

    if (Mregs_eta_ind_rfcoef != MregsNoDemo_rfcoef) x = (Mregs_eta_ind_rfcoef - MregsNoDemo_rfcoef) / (Mregs_eta_ind_rfrsqr - MregsNoDemo_rfrsqr) ;;
    if (Mregs_eta_ind_rfcoef == MregsNoDemo_rfcoef) x = 0 ;;

    temp  = Mregs_eta_ind_rfrsqr * (max_r2' - one)
    temp  = (temp, one)
    rf_r2 = rowmin(temp)
    rf_coef_bonus        = abs(x * rf_r2 :* selectn_prop')
    min_rf_coef_eta_ind  = (Mregs_eta_ind_rfcoef * one) - rf_coef_bonus
    max_rf_coef_eta_ind  = (Mregs_eta_ind_rfcoef * one) + rf_coef_bonus
    min_for_coef_eta_ind = max_rf_coef_eta_ind / Mregs_eta_ind_fscoef
    max_for_coef_eta_ind = min_rf_coef_eta_ind / Mregs_eta_ind_fscoef
end

    include 05output/paper/osterOVB_latexWrapper.do

    local out ${out}/tables/`pre'osterOVB_`pct'pct.tex
    mata latex_osterOVB(max_r2, selectn_prop, /// 
        min_for_coef, max_for_coef, min_for_coef_eta_ind, max_for_coef_eta_ind, ///
        osterOVB_space, "", osterOVB_header, osterOVB_footer, osterOVB_fmt, `"`out'"')
    capture error 0
}


mail_notify, `capture' rc(`=_rc') ///
    progname(`logName')           ///
    start_time(`startTime')       ///
    email(`:env LOGNAME'@nber.org)

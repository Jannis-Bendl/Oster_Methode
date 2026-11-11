* Objective: automate the latex output of Table A4.
* Note: This code borrows from 05output.do
* Blame: Jerray Chang
* Created: 12/17/2020
* Example command: make tableA6 PCT="100" OPTS_FOLDER="BaselineStuff-take4"

* Must have run 04analysis for each of the tags in `table_tag' below before running this file.

* Depends:
* 00preamble.do
* 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
* 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')
* 04analysis/Parse/RegressionOptions.do
* 05output/ExportRegressionOutput.do
* 05output/paper/tableA6_latexWrapper.do

local 0: subinstr local 0 ";" ","
syntax, pct(str) [optsFolder(str)]

local startTime $S_TIME $S_DATE
local logName logs/tableA6_`pct'pct_`optsFolder'

do 00common/00preamble.do
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"
log using `"${out}/`logName'.log"', text replace

local Nlocals
{
    foreach table_tag in                    ///
        "BaselineStuff_regs_countyTerm"     ///
        "BaselineStuff_regs_noTM"           ///
        "BaselineStuff_regs_PFFS"           ///
        "BaselineStuff_regs_noPFFS"         ///
        "BaselineStuff_regs_noDuals"        ///
        "BaselineStuff_regs_ageEffect"      ///
        "BaselineStuff_regs_riskScore"      ///
        "BaselineStuff_regs_unshrunk"       ///
        "BaselineStuff_regs_excl_small_bin" ///
        "BaselineStuff_regs_twoYearMort"  {

        if ("`pct'" == "01") {
            local run_option "SampleSelection6; runReg optsFolder(`optsFolder') tag(`table_tag')"
        }
        else {
            local run_option "SampleSelection6; runReg optsFolder(`optsFolder') tag(`table_tag')"
        }

        local 0: copy local run_option
        include 05output/main.do
    }
    mata MN = strtoreal(tokens(st_local("Nlocals")))'
    include 05output/paper/tableA6_latexWrapper.do

    local out ${out}/tables/`pre'tableA6_`pct'pct.tex
    mata latex_tableA6(tableA6_matrix, MN, ///
        tableA6_fmt, tableA6_specs, tableA6_rlabels, ///
        tableA6_header, tableA6_footer, tableA6_space, ///
        20, "\midrule", `"`out'"')
}

* e.g. make table1 PCT="01" PRE="_19" &
local 0: subinstr local 0 ";" ","
syntax, pct(str) pre(str)

* Start-up
version 13
clear all
capture log close _all

* Options
set more off
set varabbrev off
set linesize 100
set matsize 11000
set maxvar 50000

* Programs
qui do "00common/00preamble.do"
cap mkdir "${out}/tables"
cap mkdir "${out}/logs"

log using "${out}/logs/`pre'table1_`pct'pct.log", replace

capture program drop main
program main
    syntax, syear(int) pct(str) pre(str)

    local progname   cms-mortality-code/table1
    disp  "Program:  `progname'"
    disp  "Start:    $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    capture noisily {
        make_table1, syear(`syear') pct(`pct') pre(`pre')
    }

    local rc = _rc

    disp "Program: `progname'"
    disp "End:     $S_TIME $S_DATE"
    disp "Status:  `rc'"

    mail_notify, `capture' rc(`rc') ///
        progname(`progname')        ///
        start_time(`start_time')    ///
        email(`:env LOGNAME'@nber.org)

    exit `rc'
end

capture program drop make_table1
program make_table1
    syntax, syear(int) pct(str) pre(str)

    * If `term' changes, this needs to be changed
    local terminated disappeared_landscape1_lag

    * sanity check
    display `"This is syear: `syear'"'
    display `"This is pct: `pct'"'
    display `"This is pre: `pre'"'

    cap frame drop trueMA2
    frame create trueMA2
    frame trueMA2 {
        use bene_code year true_mMA2_lag using `"${data}/`pre'ivSample`pct'.dta"', clear
    }

    mata table1 = J(12, 4, .)
    use `"${data}/`pre'ivSample_preCollapse_`pct'_postnewshrinkage_v44_binned_addedMean.dta"', clear
        display "using `pre'ivSample_preCollapse_100_postnewshrinkage_v44_binned_addedMean.dta"

        keep cntrct                       ///
             pbpid                        ///
             bene_code                    ///
             year                         ///
             true_mMA2_lag                ///
             plan                         ///
             plan_lag                     ///
             fe_county                    ///
             fe_county_lag                ///
             bin_num                      ///
             `terminated'                 ///
             typeofmedicarehealthplan_lag ///
             demo_age                     ///
             dum_race2                    ///
             dum_sex2                     ///
             mDual                        ///
             died_365

        * If `ifglobal' and `ifcommand' change, this needs to be changed
        keep if (year >= `syear') & (true_mMA2_lag == 1) 
        keep if !mi(bin_num)
        qui gunique plan_lag, by(fe_county_lag year) gen(nplan)

        bys bene_code (year): gen switch = (fe_county != fe_county_lag) | (plan != plan_lag)
        replace switch = . if mi(fe_county_lag) | mi(plan_lag)

        * If we were using _19ivSample100.dta, we would need to merge
        * in the "typeofmedicarehealthplan_lag" variable. But there are
        * other dta files that include it so we don't have to do this!

        * derive Amanda's % HMO, %PPO, %PFFS variables here
        gen pc_HMO_lag  = strpos(typeofmedicarehealthplan_lag, "HMO") > 0
        gen pc_PPO_lag  = strpos(typeofmedicarehealthplan_lag, "PPO") > 0
        gen pc_PFFS_lag = strpos(typeofmedicarehealthplan_lag, "PFFS") > 0

        make_table_column
        mata table1[., 2] = st_matrix("r(col)")

        make_table_column if `terminated' == 0 
        mata table1[., 3] = st_matrix("r(col)")

        make_table_column if `terminated' == 1 // If `term' changes, this needs to be changed
        mata table1[., 4] = st_matrix("r(col)")

        * Plan disappearance is individual-level; people need not be enrolled in
        * disappeared plans the year they disappeared, so the plan counts don't
        * add up. Here we force them to add up by basically considering whether
        * a plan "ever disappeared" for plan counts.

        mata table1[11, 3] = table1[11, 2] - table1[11, 4]

    use `"${data}/`pre'ivSample`pct'_full.dta"', clear
        cap rename state_county ssacounty
        keep ssacounty     ///
             cntrct        ///
             pbpid         ///
             cntrct_lag    ///
             pbpid_lag     ///
             bene_code     ///
             year          ///
             plan          ///
             plan_lag      ///
             fe_county     ///
             fe_county_lag ///
             `terminated'  ///
             demo_age      ///
             dum_race2     ///
             dum_sex2      ///
             mDual         ///
             died_365

        bys bene_code (year): gen ssacounty_lag = ssacounty[_n - 1]

        * merge true MA lag into full data
        frlink 1:1 bene_code year, frame(trueMA2)
        frget true_mMA2_lag, from(trueMA2)
        replace true_mMA2_lag = 0 if !mi(plan_lag) & (true_mMA2_lag != 1)
        keep if year >= `syear'

        include "98adHoc/addProgram.do"
        include "98adHoc/addPlanChars.do"

        * derive Amanda's % HMO, %PPO, %PFFS variables here
        gen pc_HMO_lag  = strpos(typeofmedicarehealthplan_lag, "HMO") > 0
        gen pc_PPO_lag  = strpos(typeofmedicarehealthplan_lag, "PPO") > 0
        gen pc_PFFS_lag = strpos(typeofmedicarehealthplan_lag, "PFFS") > 0

        bys bene_code (year): gen switch = (fe_county != fe_county_lag) | (plan != plan_lag)
        replace switch = . if mi(fe_county_lag) | mi(plan_lag)

        qui gunique plan_lag if true_mMA2_lag == 1, by(fe_county_lag year) gen(nplan)
        replace nplan = 0 if !mi(plan_lag) & mi(nplan)

        make_table_column
        mata table1[., 1] = st_matrix("r(col)")

        qui gquantiles nplan, p(50) _pctile
        mata table1[10, 1] = st_numscalar("r(r1)")
        display "finished generating numbers, starting mata latex formatting"

    mata table1_rlabels =                ///
        "Beneficiary Age"              \ ///
        "\% White"                     \ ///
        "\% Male"                      \ ///
        "\% Dual-Eligible"             \ ///
        "\% Switched Plans"            \ ///
        "\% Died"                      \ ///
        "\% HMO"                       \ ///
        "\% PPO"                       \ ///
        "\% PFFS"                      \ ///
        "Median N Plans in Choice Set" \ ///
        "Total Plans"                  \ ///
        "N Beneficiary-Years"

    mata table1_rfmt = ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.1f"    \   ///
        "%8.0f"    \   ///
        "%21.0fc"  \   ///
        "%21.0fc"

// JC start edit

    mata table1_header =                                                                                                   ///
        "\begin{table}[t]" \                                                                                               ///
        "	 \caption{\label{tab:sumstat_bene}Summary Statistics}" \                                                       ///
        "	 \begin{centering}" \                                                                                          ///
        "	 \begin{tabular}{l cccc } " \                                                                                  ///
        "		 \toprule" \                                                                                               ///
        "		 &\mc{\multirow{3}{2cm}{\centering All Medicare Plans}} & \multicolumn{3}{c}{IV Sample} \tabularnewline" \ ///
        "		 \cline{3-5}" \                                                                                            ///
        "		 &  & \mc{All}  & \mc{Non-} & \multicolumn{1}{c}{\multirow{2}{*}{Terminated}} \\" \                        ///
        "		 &  & \mc{MA Plans}  & \mc{Terminated} & \tabularnewline" \                                                ///
        "		 & \mc{(1)} & \mc{(2)} & \mc{(3)} & \mc{(4)} \\" \                                                         ///
        "		 \midrule"

    if ("`pre'"=="_22") {
        mata table1_header[2] = "  \caption{\label{tab:sumstat_bene}Summary Statistics Extended Years}"
    }

    mata table1_header[2]

    mata table1_footer =        ///
        "		 \bottomrule" \ ///
        "	 \end{tabular}" \   ///
        "	 \par" \            ///
        "	 \end{centering}" \ ///
        "	 \vspace{0.3cm}" \  ///
        "  {\footnotesize{}Notes: This table summarizes the analysis samples in 2008--2011. Column (1) reports average enrollee demographics, annual plan switching rates, and annual mortality of the full Medicare population. Column (2) restricts the sample to beneficiary-years who ended the previous year in a MA plan. Columns (3) and (4) present the sample divided into beneficiary-years previously enrolled in MA plans that did and did not terminate. The total number of plans in column 3 subtracts the number of plans that ever terminate in column (4) from the number of MA plans in column (2). Choice sets are defined as county-years; plans operating in different counties are treated as different plans. We round the % Switched Plans in the final column to 100% from 99.99%.}" \ ///
        "  {\footnotesize\par}" \ ///
        "\end{table}"

    mata table1_clabels = ( "" , "All" , "", "", "" \ "" , "Medicare", "All", "Non-", "" \ "" , "Plans", "MA Plans", "Terminated", "Terminated" )

    mata table1[2::9, .] = 100 * table1[2::9, .]

    mata export_raw(table1, table1_clabels, table1_rlabels)

    local out ${out}/tables/`pre'Table1_`pct'pct.tex
    mata export_latex(table1, `"`out'"', table1_header, table1_footer, "", table1_rlabels, table1_rfmt, 10, "\midrule")

end

capture program drop make_table_column
program make_table_column, rclass
    syntax [if]
    qui count `if'

    tempname col
    matrix `col' = J(12, 1, .)
    matrix `col'[12, 1] = `:disp %21.0f r(N)'

    * Demographic summary stats
    local sumvars demo_age dum_race2 dum_sex2 mDual switch died_365 pc_HMO_lag pc_PPO_lag pc_PFFS_lag
    local row = 0
    foreach var of local sumvars {
        qui sum `var' `if', meanonly
        matrix `col'[`++row', 1] = `r(mean)'
    }

    * Count median plans in choice set
    qui gquantiles nplan `if', p(50) _pctile
    matrix `col'[10, 1] = `:disp %21.0f `r(r1)''

    * Count unique plans
    qui gunique fe_county_lag plan_lag `if'
    matrix `col'[11, 1] = `:disp %21.0f `r(J)''

    return matrix col = `col'
end

cap mata mata drop export_raw()
mata
function export_raw(
    real matrix M,
    string matrix collabels,
    string vector rowlabels)
{
    real scalar i, j
    string matrix table1_str, table1_raw

    if (rows(M) != 12) {
        errprintf("Matrix had %g rows and function supports 9", rows(M))
    }

    if (cols(M) != 4) {
        errprintf("Matrix had %g cols and function supports 4", cols(M))
    }

    table1_str = J(12, 4, "")
    for (i=1; i<= rows(M); i++) {
        for (j=1; j<= cols(M); j++) {
            table1_str[i,j] = sprintf("%g", M[i,j])
       }
    }
    table1_raw = (collabels) \ (rowlabels, table1_str)

    return(table1_raw)
}
end

* -------------------------------------

main, syear(2008) pct(`pct') pre(`pre')

log close

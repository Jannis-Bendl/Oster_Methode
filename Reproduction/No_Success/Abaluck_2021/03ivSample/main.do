* ---------------------------------------------------------------------
* Title:   Generate IV sample
* Program: 03ivSample/main.do
* Blame:   Mauricio Caceres Bravo <mauricio.caceresbravo@yale.edu>
* Purpose: Compute the mus/alphas from the FE and RE models
* Note:    Run via `make 03ivSample &` from reposiroty root
* Note:    Indicate which samples to run when calling `main`
* Note:    I believe there is a bug in `predict` for `xtreg, mle`,
*          so the post-estimation does not shrink the plan effects
*          correctly. We do it by hand.
*
* Output:  >
*          ${data}
*              ${sample}alphas${pct}.dta
*              ${sample}ivSample${pct}.dta
*              ${sample}ivSample${pct}_full.dta
*
*          ${out}/estimates/
*              {contract,plan}/
*                  xtreg/
*                      ${sample}dead365_${pct}pct${model}${Level}.ster
*                  hdfe/
*                      ${sample}dead365_${pct}pct${model}${Level}.ster
*
*          where ${pct} is one of 01, 05, 20, or 100. ${model} is mleCounty or
*          feCounty, indicating the model used to estimate the alphas. ${Level} is
*          Plan or Contract. Last, ${sample} is either blank or the sample prefix,
*          as applicable. We run many versions of the IV regressions, figures,
*          summary statistics, etc. depending on the set of restrictions we want to
*          apply. While in theory it is much more efficient to create indicators
*          for each version and have separate variables in the same dataset, I
*          find it a lot easier, coding-wise, to make new datasets each time.

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
qui do "00common/00preamble.do" nodep
qui do "03ivSample/MakeEmpiricalSwitching.do"
qui do "03ivSample/ComputeAllPlanEffects.do"
qui do "03ivSample/HierarchicalEffects.do"
qui do "03ivSample/MakeAnalysisSample.do"
qui do "03ivSample/ApplyVariableLabels.do"
qui do "03ivSample/MakeNoDualEffects.do"
qui do "03ivSample/MergeTrueMAFlag.do"

* Make output directories, if they don't exist
cap mkdir `"${out}"'
cap mkdir `"${out}/estimates"'
cap mkdir `"${out}/estimates/plan"'
cap mkdir `"${out}/estimates/plan/hdfe"'
cap mkdir `"${out}/estimates/plan/xtreg"'
cap mkdir `"${out}/estimates/plan/ivreg"'
cap mkdir `"${out}/estimates/contract"'
cap mkdir `"${out}/estimates/contract/hdfe"'
cap mkdir `"${out}/estimates/contract/xtreg"'
cap mkdir `"${out}/estimates/contract/ivreg"'
cap mkdir `"${out}/estimates/org"'
cap mkdir `"${out}/estimates/org/hdfe"'
cap mkdir `"${out}/estimates/org/xtreg"'
cap mkdir `"${out}/estimates/org/ivreg"'

* ---------------------------------------------------------------------
* Main program wrapper <3>

/* DOC
 *
 * Main function wrapper to generate the plan effects (mus)
 *
 * `makePlanEffects` generates a_ij and u_ij the plan effects at the individual
 *      and plan level.
 * `makeAnalysisSample` merges in the alphas with the denominator file and makes
 *      a dataset we can use directly in future analysis.
 *
 * We make the final analysis sample, applying all the restrictions here
 * _before_ generating the alphas or running any analysis.
 *
 *     replace:      (All) Replace data/output if it exists.
 *     pct(str):     (All) Percent sample to query. We have access up to 20%
 *     subset(str):  (All) Sample restrictions
 *     pre(str):     (All) Prefix associated with sample restrictions
 *     forcema(str): (All) Keep if ever MA (forcema gives MA indicator)
 *
 */
program main
    syntax, samples(str) [CAPture NOIsily]
    forvalues i = 1 / 100 {
        local _`i' _all _`i'
    }

    local progname   abaluck/cms-mortality/code/03ivSample
    disp  "Program:  `progname'"
    disp  "Start:    $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    `capture' `noisily' {
        foreach pct in 01 100 {

            * -------------------------------
            * Universal sample truncated 2011
            * -------------------------------

            if ( `"`:list _19 & samples'"' != "" ) {

                local subset (year <= 2011)
                local subset (`subset') & ((lastyear >= 2011) | (lastyear == deathyear))
                local subset (`subset') & (age_first >= 65)
                local subset (`subset') & (everMissingPlan == 0)
                local subset (`subset') & (discontinuousEnrollment == 0)
                local subset (`subset') & (diesAfterLast == 0)
                local subset (`subset') & (alwaysIn50StatesOrDC == 1)
                * local subset (`subset') & (exitsBeforeDeathOrEnd == 0)

                disp "{hline 80}" _n(1) "Universal `pct' (_19)" _n(1)
                makePlanEffects,    replace pct(`pct') pre(_19) subset(keep if `subset')
                makeNoDualEffects,  replace pct(`pct') pre(_19)
                makeAnalysisSample, replace pct(`pct') pre(_19) subset(keep if `subset')
                makeEverMASample,   replace pct(`pct') pre(_19)

                save `"${data}/_19ivSample`pct'.dta"', replace
            }
        }
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

capture program drop makeEverMASample
program makeEverMASample
    syntax, pct(str) [pre(str) replace]
    local plan_lag fe_county_lag cntrct_id_lag pbpid_id_lag

    * Ever MA sample is main version of the universal sample
    gegen _everma = max(mMA), by(bene_code) replace
    keep if _everma
    drop _everma
    sort bene_code year

    mergeTrueMAFlag
    applyVariableLabels

    makeSwitching, pct(`pct') `replace'
    merge m:1 `plan_lag' year using `"${data}/plan_switched`pct'_lag.dta"', keep(1 3) nogen

    qui note drop _dta
    label data drop
    label data "`pct'% ivSample (version: _19, ever mMA subset)"
end

* ---------------------------------------------------------------------
* Run the things <3>

main, cap noi samples(_19)

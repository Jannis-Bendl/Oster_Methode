* ---------------------------------------------------------------------
* Title:   Clean Denominator and Part B
* Program: 02clean/main.do
* Blame:   Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>
* Note:    This keeps _every_ cohort. Drop select cohorts later.
* Note:    Run via `make 02clean &` from reposiroty root
*
* Purpose: This script cleans the denominator data queried from SAS. It
*          creates a beneficiary-year panel for _every_ enrollee with
*          non-missing enrollment indicators, using contract ID, plan
*          ID, buy-in indicator, HMO indicator, and dual code, adding
*          year mortality, terminations, various demographic indicators,
*          and various enrollment indicators.
*
* Output:  >
*          ${data}
*              denom${pct}_loc.dta
*              denom${pct}_cohorts.dta
*              mergedCohorts${pct}.dta
*
*          where ${year} ranges from 2006 to 2017 and ${pct} is one of
*          01, 05, 20, or 100.

* Start-up
version 13
clear all
capture log close _all

* Options
set more off
set varabbrev off
set linesize 128
set matsize 11000
set maxvar 50000

* Programs
qui do "00common/00preamble.do"
qui do "02clean/QueryEnrollment.do"
qui do "02clean/CleanEnrollmentCohorts.do"
qui do "02clean/MakeEmpiricalTerminations.do"
qui do "02clean/MergedSample.do"

* ---------------------------------------------------------------------
* Main program wrapper <3>

/* DOC
 *
 * Main function wrapper to clean denominator query The output is any
 * beneficiary-year for which we we have full enrollment data. The
 * program parameters are:
 *
 *     replace:        (All) Replace data/output if it exists.
 *     pct(str):       (All) Percent sample to query. We have access up to 100%
 *     syear(int):     (queryEnrollment) First year of our query; we have access from 2006.
 *     eyear(int):     (MergedSample) Final year of our query; we have access through 2017.
 *
 */
program main
    syntax, [CAPture NOIsily]

    local progname  abaluck/cms-mortality-code/02clean
    disp  "Program: `progname'"
    disp  "Start:   $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    `capture' `noisily' {
        foreach pct in 01 100 {
            queryEnrollment, replace pct(`pct') syear(2006)
            cleanCohorts,    replace pct(`pct')
            makeTerminated,  replace pct(`pct')
            mergedSample,    replace pct(`pct') eyear(2011)
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

* ---------------------------------------------------------------------
* Run the things <3>

main, cap noi

* ---------------------------------------------------------------------
* Title:   Format helper files
* Program: 00auxfiles/main.do
* Blame:   Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>
* Note:    Run via `make 00auxfiles &` from reposiroty root

version 13
clear all
capture log close _all

set more off
set varabbrev off
set linesize 128
set matsize 11000
set maxvar 50000

qui do "00common/00preamble.do"
qui do "00auxfiles/TrueMAFlag_NBER.do"
qui do "00auxfiles/Terminations.do"
qui do "00auxfiles/CollapsePlanCharacteristics.do"
qui do "00auxfiles/CollapseAuxFiles.do"


program main
    syntax, [CAPture NOIsily]

    local progname  abaluck/cms-mortality-code/00auxfiles
    disp  "Program: `progname'"
    disp  "Start:   $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    `capture' `noisily' {
        terminations, syear(2006)
        trueMAFlag

        collapseAuxFiles, if(if 1)
        collapseAuxFiles, if(if year >= 2006 & year <= 2011) pre(_19)
        collapseAuxFiles, if(if year >= 2006 & year <= 2017) pre(_22)

        collapsePlanCharacteristics, if(if keep)
        collapsePlanCharacteristics, if(if keep & year >= 2008 & year <= 2011) pre(_19)
        collapsePlanCharacteristics, if(if keep & year >= 2008 & year <= 2017) pre(_22)

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


main, cap noi

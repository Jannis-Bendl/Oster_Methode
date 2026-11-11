* ---------------------------------------------------------------------
* Title:   Download helper files
* Program: 00download/main.do
* Blame:   Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>
* Note:    Run via `make 00download &` from reposiroty root

version 13
clear all
capture log close _all

set more off
set varabbrev off
set linesize 128
set matsize 11000
set maxvar 50000

qui do "00common/00preamble.do"


program main
    syntax, [CAPture NOIsily]

    local progname  abaluck/cms-mortality-code/00download
    disp  "Program: `progname'"
    disp  "Start:   $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    `capture' `noisily' {
        python script 00download/LifeTables.py
        do 00download/LandscapeFiles.do; cached
        do 00download/PlanData.do; cached
        do 00download/MLR.do; cached
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

* ---------------------------------------------------------------------
* Title:   Plan and Hospital VAM versions of Figure A2 (distribution of `pseudo-shrinkage coefficients')
* Program: figureA2.do (099_lambda_chart.do)
* Blame:   Jerray Chang <jerray@chicago.edu>
*          Original code by Amy Tingle
* Created: Thu Jan 21 13:11:55 EDT 2021
* Purpose: Create plan and hospital VAM versions of Figure A2 (distribution of `pseudo-shrinkage coefficients')
* Note:    Run via make figureA2 PCT="01" PRE="_19" &
*          or `nohup stata16-mp -b do 05output/paper/figureA2.do; plan`
*
* Output:  >
*          /disk/agedisk3/medicare.work/doyle-DUA51929/caceres-dua51929/cms-mortality/
*              out/05full-sample/fig/lambda/
*                  ${pre}lambda_hist${pct}_1trim_2.svg
*
*          where ${pct} is one of 01, 05, 20, or 100 and ${pre} is the data version.

local 0: subinstr local 0 ";" ","
syntax, pct(str) pre(str)
display "`0'"

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
set scheme burd4

* Programs and globals
qui do "00common/00preamble.do"
qui do "00common/00material.do"
include 04analysis/Parse/FigureOptions.do

cap mkdir `"${out}/"'
cap mkdir `"${out}/logs"'
cap mkdir `"${out}/fig"'
cap mkdir `"${out}/fig"'
cap mkdir `"${out}/fig/lambda"'
log using `"${out}/logs/`pre'figureA2_`pct'pct.log"', replace

* ---------------------------------------------------------------------
capture program drop main
program main
    syntax, pct(str) [pre(str) CAPture NOIsily]

    local progname  abaluck/cms-mortality/code/099_lambda_chart
    disp  "Program: `progname'"
    disp  "Start:   $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

    `capture' `noisily' {
        planLambdaGraph, pct(`pct') pre(`pre') `capture' `noisily'
    }

    local rc = _rc

    disp "Program: `progname'"
    disp "End:     $S_TIME $S_DATE"
    disp "Status:  `rc'"

    mail_notify, `capture' rc(`rc') ///
        progname(`progname')        ///
        start_time(`start_time')    ///
        email(`:env LOGNAME'@nber.org)

end


capture program drop planLambdaGraph
program planLambdaGraph
    syntax, pct(str) [pre(str) CAPture NOIsily]

    `capture' `noisily' {
        use "${data}/`pre'ivSample`pct'_full.dta" if bin_num != ., clear

        /* calculate how many plans are in a contract */
        cap frame drop plan_count
        frame put fe_county_plan fe_county_contract, into(plan_count)
        frame plan_count {
            gcontract fe_county_contract, f(plan_count)
            tempfile plan_count
            save `"`plan_count'"'
        }
        merge m:1 fe_county_contract using `"`plan_count'"', nogen

        * calculate raw avg in each county
        cap frame drop u_avg
        frame put fe_county u_feCYPlan, into(u_avg)
        frame u_avg {
            gcollapse (mean) u_county_avg = u_feCYPlan, by(fe_county)
            tempfile u_avg
            save `"`u_avg'"'
        }
        merge m:1 fe_county using `"`u_avg'"', nogen

        cap frame drop contract_avg
        frame put fe_county_contract u_feCYPlan mucounty_mleCYPlan, into(contract_avg)
        frame contract_avg {
            gcollapse (mean) mu_raw_contract_avg = u_feCYPlan /// 
                             mu_shrunk_contract_avg = mucounty_mleCYPlan, by(fe_county_contract)
            tempfile contract_avg
            save `"`contract_avg'"'
        }
        merge m:1 fe_county_contract using `"`contract_avg'"', nogen

        * calculate number of bene-yrs per contract and plan
        gegen beneyr_per_contract = count(1), by(fe_county_contract)
        gegen beneyr_per_plan     = count(1), by(fe_county_plan)
        gen lambda = (mu_shrunk_contract_avg - u_county_avg) /  (mu_raw_contract_avg - u_county_avg)

        drop if mi(lambda)
        gstats sum lambda

        gen abs_lambda = abs(lambda)
        sort abs_lambda
        gen trim_1 = .01 * _N
        replace trim_1 = _N - trim_1
        drop if _n > trim_1
        gstats sum lambda
        hist lambda, freq graphregion(color(white)) color(`"`alColorNoTerm'"') xtitle("Pseudo Shrinkage Coefficient") ytitle("Frequency (in thousands)") ylabel(0 40000000 "40,000" 80000000 "80,000" 120000000 "120,000" 160000000 "160,000")
        graph export "${out}/fig/`pre'lambda_hist`pct'_1trim_2.svg", `xopts'
    }
end

*---------------------------------
main, pct(`pct') pre(`pre') cap noi

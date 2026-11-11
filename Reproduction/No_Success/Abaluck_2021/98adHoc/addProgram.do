* ---------------------------------------------------------------------
* Title:    Generic program for adding characteristics
* Program:  mergePlanContractVariables
* Blame:    Mauricio Caceres (mauricio.caceres.bravo@gmail.com)
* Created:  Thursday, July 2nd 2020
* Updated:  Tuesday, February 16th 2021
* Purpose:  Generic merge by plan with contract fallback
* Notes:    Requires Stata 16+
* ---------------------------------------------------------------------

capture program drop mergePlanContractVariables
program mergePlanContractVariables
    syntax, planFile(str) contractFile(str) keepvars(str) [prefix(str) mergeby(str)]

    * Merge by plan with contract fallback (if former fails)

    tempvar _merge_plan
    tempvar _merge_contract

    merge m:1 `mergeby' cntrct pbpid using `"`planFile'"',     keep(1 3)     keepusing(`keepvars') gen(`_merge_plan')
    merge m:1 `mergeby' cntrct       using `"`contractFile'"', keep(1 3 4 5) keepusing(`keepvars') gen(`_merge_contract') update

    gen `prefix'pbpid_merge  = (`_merge_plan' == 3)
    gen `prefix'cntrct_merge = inlist(`_merge_contract', 3, 4) & (`prefix'pbpid_merge == 0)

    confirm variable `keepvars'

    * Create Lag Plan Characteristic Variables
    tempname lag
    frame create `lag'
    frame `lag' {
        use `"`planFile'"', clear
            keep `mergeby' cntrct pbpid `keepvars'
            gduplicates drop

            local mergelag
            foreach var of local mergeby {
                if ( `"`var'"' == "year" ) {
                    replace year = year + 1
                    local mergelag `mergelag' year
                }
                else {
                    rename `var' `var'_lag
                    local mergelag `mergelag' `var'_lag
                }
            }

            foreach var of varlist `keepvars' {
                rename `var' `var'_lag
            }

            rename (pbpid cntrct) (pbpid_lag cntrct_lag)
            local mergeplanlag `mergelag' pbpid_lag cntrct_lag
            gisid `mergeplanlag'
        tempfile planLag
        save `"`planLag'"'

        use `"`contractFile'"', clear
            keep `mergeby' cntrct `keepvars'
            gduplicates drop

            local mergelag
            foreach var of local mergeby {
                if ( `"`var'"' == "year" ) {
                    replace year = year + 1
                    local mergelag `mergelag' year
                }
                else {
                    rename `var' `var'_lag
                    local mergelag `mergelag' `var'_lag
                }
            }

            local varlag
            foreach var of varlist `keepvars' {
                local varlag `varlag' `var'_lag
                rename `var' `var'_lag
            }

            rename cntrct cntrct_lag
            local mergecontractlag `mergelag' cntrct_lag
            gisid `mergecontractlag'
        tempfile contractLag
        save `"`contractLag'"'
    }

    tempvar _merge_plan_lag
    tempvar _merge_contract_lag

    merge m:1 `mergeplanlag'     using `"`planLag'"',     keep(1 3)     gen(`_merge_plan_lag')
    merge m:1 `mergecontractlag' using `"`contractLag'"', keep(1 3 4 5) gen(`_merge_contract_lag') update

    gen `prefix'pbpid_merge_lag  = (`_merge_plan_lag' == 3)
    gen `prefix'cntrct_merge_lag = inlist(`_merge_contract_lag', 3, 4) & (`prefix'pbpid_merge_lag == 0)

    confirm variable `varlag'
end

capture program drop mergeContractVariables
program mergeContractVariables
    syntax, contractFile(str) keepvars(str) [prefix(str) mergeby(str)]

    * Merge by contract only
    tempvar _merge_contract
    merge m:1 `mergeby' cntrct using `"`contractFile'"', keep(1 3) gen(`_merge_contract') keepusing(`keepvars')
    gen `prefix'cntrct_merge = (`_merge_contract' == 3)
    confirm variable `keepvars'

    * Create Lag contract characteristic variables
    tempname lag
    frame create `lag'
    frame `lag' {
        use `"`contractFile'"', clear
            keep `mergeby' cntrct `keepvars'
            gduplicates drop

            local mergelag
            foreach var of local mergeby {
                if ( `"`var'"' == "year" ) {
                    replace year = year + 1
                    local mergelag `mergelag' year
                }
                else {
                    rename `var' `var'_lag
                    local mergelag `mergelag' `var'_lag
                }
            }

            local varlag
            foreach var of varlist `keepvars' {
                local varlag `varlag' `var'_lag
                rename `var' `var'_lag
            }

            rename cntrct cntrct_lag
            local mergecontractlag `mergelag' cntrct_lag
            gisid `mergecontractlag'
        tempfile contractLag
        save `"`contractLag'"'
    }

    tempvar _merge_contract_lag
    merge m:1 `mergecontractlag' using `"`contractLag'"', keep(1 3) gen(`_merge_contract_lag')
    gen `prefix'cntrct_merge_lag  = (`_merge_contract_lag' == 3)
    confirm variable `varlag'
end

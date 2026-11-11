capture program drop makeTerminated
program makeTerminated
    syntax, pct(str) [replace]

    local base ${data}/denom`pct'_cohorts

    * -------------------------------
    * Disappeared plans and contracts
    * -------------------------------

    local vars fe_county cntrct_id pbpid_id year
    use `vars' using `"`base'"', clear
        qui sum year, meanonly
        local yearmin = `r(min)'
        local yearmax = `r(max)'
        gduplicates drop
        local plan cntrct_id pbpid_id

        * DOC: The last year a plan appears if it is before 2014 (all
        * plans would "disappear" in 2014 since it is the last year of
        * the sample, so we exclude flagging that).

        bys fe_county `plan' (year): gen disappeared_plan = (_n == _N) if year < `yearmax'
        bys fe_county `plan' (year): gen last_year = year[_N]

        * DOC: If a plan does not appear the next year it disappeared
        * that year. This is a discontinuity not a disappearence per se.

        local discontinuous (year[_n + 1] != (year + 1)) & (_n < _N)
        bys fe_county `plan' (year): gen discontinuous_plan = `discontinuous'

        * DOC: We create a contemporaneous and a lagged indicator:
        * First, does this plan disappear this year (i.e. not appear
        * anymore from the next year henceforth)? Second, did last
        * year's plan disappear?

        drop if year == `yearmax'
        compress
    save `"${data}/plan_disappeared`pct'.dta"', `replace'
        rename (fe_county cntrct_id pbpid_id) (fe_county_lag cntrct_id_lag pbpid_id_lag)
        rename (disappeared_plan discontinuous_plan) (disappeared_plan_lag discontinuous_plan_lag)
        rename last_year last_year_lag
        replace year = year + 1
        compress
    save `"${data}/plan_disappeared`pct'_lag.dta"', `replace'

    * DOC: This is the same as above, but for plans instead of contracts.

    local vars fe_county cntrct_id year
    use `vars' using `"`base'"', clear
        qui sum year, meanonly
        local yearmin = `r(min)'
        local yearmax = `r(max)'
        gduplicates drop
        local plan cntrct_id

        bys fe_county `plan' (year): gen disappeared_contract = (_n == _N) if year < `yearmax'
        bys fe_county `plan' (year): gen last_year_contract   = year[_N]

        local discontinuous (year[_n + 1] != (year + 1)) & (_n < _N)
        bys fe_county `plan' (year): gen discontinuous_contract = `discontinuous'

        drop if year == `yearmax'
        compress
    save `"${data}/contract_disappeared`pct'.dta"', `replace'
        rename (fe_county cntrct_id) (fe_county_lag cntrct_id_lag)
        rename (disappeared_contract discontinuous_contract) (disappeared_contract_lag discontinuous_contract_lag)
        rename last_year_contract last_year_contract_lag
        replace year = year + 1
        compress
    save `"${data}/contract_disappeared`pct'_lag.dta"', `replace'
end

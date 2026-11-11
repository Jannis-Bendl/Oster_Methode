* ---------------------------------------------------------------------
* Disappeared plans

* DOC: We generate the base sample for pre-analysis. First, we generate
* the lag plan and contract, that is, the beneficiary's plan and
* contract from the year prior. While encoding some identifiers is
* straightforward, in this case we need to be careful to encode the
* lagged identifiers consistently.
*
* Further, while we do not subset the data here, we do generate the
* variables we will use to define any analysis sample, including the
* number of beneficiaries per county, plan- or contract-county, and
* so on. Last, we generate an indicator for whether a plan never
* again appears in a given county (this proxies for a plan terminated
* indicator).

capture program drop mergedSample
program mergedSample
    syntax, pct(str) eyear(int) [replace]

    local base ${data}/denom`pct'_cohorts
    local out  ${data}/mergedCohorts`pct'

    * DOC: Replationship code (terminated, renewal, consolidation, split).
    use `"${data}/planTerm"', clear
        keep if substr(cntrct, 1, 1) == "H"
        drop if mi(cntrct) | mi(pbpid)
        keep year cntrct pbpid relationship_code
        sort cntrct pbpid year
        gduplicates drop
        gisid cntrct pbpid year
        compress
        sort cntrct pbpid year
    tempfile planCodes
    save `"`planCodes'"'

    * -------------------------
    * Merge in indicators, lags
    * -------------------------

    use `"`base'"', clear
        sort bene_code year
        gisid bene_code year

        * DOC: We used to make sure lags are only created for beneficiaries that
        * continuously appear (if there is a jump then it is not a lag).  Benes
        * with discontinuous enrollment get dropped as a cohort in 03ivSample,
        * however, so it is not an issue in the analysis.

        by bene_code (year): gen fe_county_lag = fe_county[_n - 1]

        by bene_code (year): gen cntrct_id_lag = cntrct_id[_n - 1]
        by bene_code (year): gen pbpid_id_lag  = pbpid_id[_n - 1]
        by bene_code (year): gen plan_lag      = plan[_n - 1]

        by bene_code (year): gen cntrct_lag    = cntrct[_n - 1]
        by bene_code (year): gen pbpid_lag     = pbpid[_n - 1]

        compress

        merge m:1 fe_county     year cntrct_id     pbpid_id     using `"${data}/plan_disappeared`pct'.dta"',     keep(1 3) nogen
        merge m:1 fe_county_lag year cntrct_id_lag pbpid_id_lag using `"${data}/plan_disappeared`pct'_lag.dta"', keep(1 3) nogen

        merge m:1 fe_county     year cntrct_id     using `"${data}/contract_disappeared`pct'.dta"',     keep(1 3) nogen
        merge m:1 fe_county_lag year cntrct_id_lag using `"${data}/contract_disappeared`pct'_lag.dta"', keep(1 3) nogen

        * ---------------------------
        * Terminations from landscape
        * ---------------------------

        * DOC: The idea is that we want to use an external definition
        * of terminations. The nationwide definition was too narrow, so
        * we moved to a county-level definition. This was empirically
        * driven. That is, if we did not see a plan in our sample we
        * termed it a "termination".
        *
        * We move to whether or not we continue to see a plan in the
        * landscape file (never touched it; I trust Amanda and Jason on
        * that) to validate our measure of disappearance as termination.
        *
        * Note if we have flagged a bene as being in TM or in an 'Other'
        * plan (-1, -2) we do not merge in the landscape file.

        replace county = trim(upper(county))
        replace state  = trim(upper(state))
        gen state_county = state + county
        gen pbpid_bak = pbpid
        replace pbpid = "" if inlist(plan, -1, -2)

        local mopts gen(_landscape) keep(1 3) keepusing(landscape_year landscape_xw)
        merge m:1 state_county cntrct pbpid year using `"${data}/terminate_xw"', `mopts'

        replace pbpid = pbpid_bak if inlist(plan, -1, -2)
        drop pbpid_bak

        replace landscape_xw = 1 if (last_year == 2014)
        replace landscape_xw = 1 if inlist(plan, -1, -2)
        replace landscape_xw = 0 if year > `eyear'
        replace landscape_xw = 0 if mi(landscape_xw)

        * DOC: The landscape file can only be merged through 2011. We
        * start this analysis only with plan data through 2011, so we
        * can only do the crosswalk until that year.

        merge m:1 pbpid cntrct year using `"`planCodes'"', keep(1 3) gen(_plan_codes)
        gen code_xw = (_plan_codes == 3)
        replace code_xw = 1 if inlist(plan, -1, -2)
        replace code_xw = 0 if year > `eyear'
        replace relationship_code = "" if inlist(plan, -1, -2)

        tab year code_xw
        tab year code_xw if mMA == 1

        * DOC: Here we create two alternative termination definitions:
        *
        * 0) disappeared_plan
        *     - Empirical terminations
        * 1) disappeared_landscape1
        *     - Disappeared in the landscape file
        *     - Non-C relationship code (consolidation)
        *     - Non-R relationship code (renewal)

        gen byte disappeared_landscape_auxa = (year == landscape_year) & (landscape_xw == 1) & (code_xw == 1)
        gen byte disappeared_landscape_auxb = (disappeared_landscape_auxa == 1) & (relationship_code != "C")
        gen byte disappeared_landscape1     = (disappeared_landscape_auxb == 1) & (relationship_code != "R")
        gen byte disappeared_plan_auxb      = (disappeared_plan           == 1) & (relationship_code != "C")
        gen byte disappeared_plan1          = (disappeared_plan_auxb      == 1) & (relationship_code != "R")

        gegen disappeared_contract1   = min(disappeared_plan1),        by(fe_county year cntrct_id)
        gegen disappeared_clandscape1 = min(disappeared_landscape1),   by(fe_county year cntrct_id)
        gegen relationship_ccode      = max(relationship_code == "C"), by(fe_county year cntrct_id)
        gegen landscape_cxw           = min(landscape_xw),             by(fe_county year cntrct_id)
        gegen code_cxw                = min(code_xw),                  by(fe_county year cntrct_id)

        compress
        local year year

        * DOC: Here we make the lag variables by merging on lag encoded contract
        * (or plan) IDs. We do this for the disappearance indicators and some of
        * the landscape-based variables.

        local dvars1 disappeared_clandscape? disappeared_contract?
        local lvars1 fe_county_lag cntrct_id_lag
        local  vars1 fe_county     cntrct_id

        tempname disappearedXContract
        frame put `vars1' year `dvars1' relationship_ccode, into(`disappearedXContract')
        frame `disappearedXContract' {
            gduplicates drop
            rename (`vars1' relationship_ccode) (`lvars1' relationship_ccode_lag)
            rename disappeared_* disappeared_*_lag
            replace year = year + 1
            sort `lvars1'
            compress
            unab get1: _all
            local get1: list get1 - lvars1
            local get1: list get1 - year
        }

        local dvars2 disappeared_landscape? disappeared_plan?
        local lvars2 fe_county_lag cntrct_id_lag pbpid_id_lag
        local  vars2 fe_county     cntrct_id     pbpid_id

        tempname disappearedXPlan
        frame put `vars2' year `dvars2' relationship_code, into(`disappearedXPlan')
        frame `disappearedXPlan' {
            gduplicates drop
            rename (`vars2' relationship_code) (`lvars2' relationship_code_lag)
            rename disappeared_* disappeared_*_lag
            replace year = year + 1
            sort `lvars2'
            compress
            unab get2: _all
            local get2: list get2 - lvars2
            local get2: list get2 - year
        }

        frlink m:1 `lvars1' year, frame(`disappearedXContract')
        frlink m:1 `lvars2' year, frame(`disappearedXPlan')

        frget `get1', from(`disappearedXContract')
        frget `get2', from(`disappearedXPlan')

        cap drop `disappearedXContract'
        cap drop `disappearedXPlan'

        frame drop `disappearedXContract'
        frame drop `disappearedXPlan'

    save `"`out'"', `replace'
end

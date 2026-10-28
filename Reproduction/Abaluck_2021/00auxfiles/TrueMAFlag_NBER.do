* ---------------------------------------------------------------------
* True MA Flag

* DOC: Compute `TrueMA` flag that excludes:
*
* - 800 series plans
* - Special needs plans
* - Demonstration plans
* - All plans that are not one of: HMO, non-HMO/POS, Local PPO, Local
*   HMO, PFFS, or Regional PPO
*
* The original instructions for this program were written in Trello card
* 'Rerun non-stacked stacked regressions' EDIT #6 ("The People's Edit"):
*
* 1) Merge in the medicare plan type from the enrollment files, named
*    ma`year'. In order to do this, create a new variable which takes the
*    value of plantype OR typeofmedicarehealthplan, whichever is non-blank
*
* 2) Keep HMO, HMO/POS, Local PPO, Local HMO, PFFS, Regional PPO, and
*    treat as non-MA everything else (send us a tabulation of the other
*    plan types just to be clear) -- see Amanda's code below.
*
* 3) Of the remaining MA Plans:
*
*     a) Check if any (contract, plans) always have missing special needs and
*        demonstration indicators (i.e. in all counties). If so, send Amanda a
*        few examples of those.
*
*     b) Also check if there are some (contract, plans) which have missing
*        indicators sometimes but not other times (e.g .in some counties but
*        not others) and send Amanda examples of those.
*
*     c) In cases where special needs / demonstration is non-missing, let's
*        check for what % of (contract, plans) (beneficiary weighted), we see:
*
*         i) All the same value for the non-missing cases
*         ii) Different values for the non-missing cases
*
* 4) Set to non-MA any contract plans which ever are special needs or
*    demonstration, or always have missing special needs and demonstration
*    indicators
*
* 5) Don't forget to search to non-MA all 800 series plans
*
* 6)
*
*     a) Recreate the table which shows age by ventile of lagged alpha for
*        terminated and non-terminated plans in this sample. Create two
*        versions of this table -- one with gender, race and age, and one with
*        only age to make creating my special graph easier.
*
*     b) Rerun all balance tests using these restrictions in 2010-2011
*
*     c) Rerun all the regressions with this new relabeling.

capture program drop trueMAFlag
program trueMAFlag
    syntax, [replace]

    * DOC: Get state and county crosswalk (from names to SSA codes)

    import delimited using "00common/00ssa-codes.txt", varn(1) stringc(2 3) clear
        keep name state st
        replace name = trim(upper(name))
        replace name = "WASHINGTON D.C." if regexm(name, "COLUMBIA")
        replace st   = trim(upper(st))
        gduplicates drop
        rename (state st) (ssastate state)
    tempfile states
    save `"`states'"'

    tempfile xw
    local ssaxw /homes/data/ssa-fips-state-county-crosswalk
    forvalues year = 2011 / 2014 {
        use `"`ssaxw'/`year'/ssa_fips_state_county`year'"', clear
            keep county state ssacounty ssastate
            gduplicates drop
            replace county = trim(upper(county))
            replace state  = trim(upper(state))
            drop if mi(county) | mi(state)
            drop if mi(ssacounty) | mi(ssastate)
            keep state county ssacounty ssastate
            gduplicates drop state county, force
            compress
        if ( `year' > 2011 ) append using `"`xw'"'
        save `"`xw'"', replace
    }
    gduplicates drop
    gisid state county
    merge m:1 ssastate state using `"`states'"', keep(1 3) assert(2 3) nogen
    save `"`xw'"', replace

    * DOC: Get flags for trueMALag indicator from enrollment files

    import delimited using "00common/00plan-types.txt", varn(1) stringc(1 2) clear
        replace new_type   = trim(upper(new_type))
        replace broad_type = trim(upper(broad_type))
        rename (new_type broad_type) (newType broadType)
    tempfile newType
    save `"`newType'"'

    tempfile trueMA
    forvalues year = 2007 / 2014 {
        use /homes/data/cms/landscape/`year'/ma`year', clear
        qui {
            local keep state county contractid planid
            cap ds plantype
            if ( _rc == 0 ) {
                local keep `keep' plantype
                gen trueMAType1 = trim(upper(plantype))
                gen byte trueMADemo1 = regexm(lower(trueMAType1), "demo") if !mi(trueMAType1)

                replace trueMAType1 = "NON-MA"                               ///
                    if trueMAType1 == "1876 COST"                            ///
                     | trueMAType1 == "CONTINUING CARE RETIREMENT COMMUNITY" ///
                     | trueMAType1 == "ESRD II"                              ///
                     | trueMAType1 == "MEDICARE PRESCRIPTION DRUG PLAN"      ///
                     | trueMAType1 == "MEDICARE-MEDICAID PLAN HMO"           ///
                     | trueMAType1 == "NATIONAL PACE"
            }

            cap ds typeofmedicarehealthplan
            if ( _rc == 0 ) {
                local keep `keep' typeofmedicarehealthplan
                gen trueMAType2 = trim(upper(typeofmedicarehealthplan))
                gen byte trueMADemo2 = regexm(lower(trueMAType2), "demo") if !mi(trueMAType2)
                gen byte trueMANoPartD = substr(trueMAType2, -1, 1) == "*"

                replace trueMAType2 = "NON-MA"   ///
                    if trueMAType2 == "COST"     ///
                     | trueMAType2 == "COST *"   ///
                     | trueMAType2 == "DEMO"     ///
                     | trueMAType2 == "DEMO *"   ///
                     | trueMAType2 == "MSA"      ///
                     | trueMAType2 == "MSA *"    ///
                     | trueMAType2 == "MSA DEMO" ///
                     | trueMAType2 == "MSA DEMO *"
            }

            cap ds specialneedsplan
            if ( _rc == 0 ) {
                local keep `keep' specialneedsplan
                gen byte trueMASpecial = (trim(lower(specialneedsplan)) == "yes") if !mi(specialneedsplan)
            }

            keep `keep' trueMA*
            rename (contractid planid) (cntrct pbpid)
            replace county = trim(upper(county))
            replace state  = trim(upper(state))
            replace pbpid  = "0" + pbpid if length(pbpid) == 1
            replace pbpid  = "0" + pbpid if length(pbpid) == 2
            assert (length(pbpid) == 3) | mi(pbpid)
            drop if mi(county) | mi(state) | mi(cntrct) | mi(pbpid)
            gduplicates drop
            gen long year = `year'
        }

        if ( `year' > 2007 ) append using `"`trueMA'"'
        save `"`trueMA'"', replace
    }
    assert (!mi(typeofmedicarehealthplan) + !mi(plantype)) < 2
    gen newType = trim(upper(cond(mi(typeofmedicarehealthplan), plantype, typeofmedicarehealthplan)))
    merge m:1 newType using `"`newType'"', keep(1 3)
    assert (_merge == 3) | mi(newType)

* NOTE: This arbitrarily gets rid of plans with a non-unique broad
* type _OR_ a missing broad type; it is only a small minority.

    gunique broadType, by(cntrct pbpid) gen(_unique)
    * assert (_unique == 1) | mi(broadType)
    tab _unique
    bys cntrct pbpid (year): drop if _unique != 1
    drop _*

    * DOC: Various tabulations and sanity checks

    gen byte trueMANonMA = (trueMAType1 == "NON-MA") | (trueMAType2 == "NON-MA")
    replace trueMANonMA  = . if mi(trueMAType1) & mi(trueMAType2)
    gen byte trueMADemo  = max(trueMADemo1, trueMADemo2)
    drop trueMADemo?
    drop trueMAType?

    tab typeofmedicarehealthplan trueMANonMA, mi
    tab plantype trueMANonMA, mi
    drop typeofmedicarehealthplan plantype specialneedsplan
    gduplicates drop

    gegen _alwaysMissingSpecial = min(mi(trueMASpecial)), by(cntrct pbpid)
    gegen _alwaysMissingDemo    = min(mi(trueMADemo)),    by(cntrct pbpid)
    gegen _everMissingSpecial   = max(mi(trueMASpecial)), by(cntrct pbpid)
    gegen _everMissingDemo      = max(mi(trueMADemo)),    by(cntrct pbpid)

    gegen _tag = tag(cntrct), replace
    gtop cntrct pbpid state county year if _tag & (_alwaysMissingSpecial == 1)
    gtop cntrct pbpid state county year if _tag & (_alwaysMissingDemo == 1)

    gegen _tag = tag(cntrct pbpid), replace
    count if _tag & (_alwaysMissingSpecial == 1)
    local n1 = `r(N)'
    count if _tag
    local n2 = `r(N)'
    disp "% Plans alawys missing special: `=100 * `n1' / `n2''"

    count if _tag & (_alwaysMissingDemo == 1)
    local n1 = `r(N)'
    count if _tag
    local n2 = `r(N)'
    disp "% Plans alawys missing demo: `=100 * `n1' / `n2''"

    gegen _tag = tag(cntrct), replace
    gtop cntrct pbpid state county year if _tag & (_everMissingSpecial == 1) & (_alwaysMissingSpecial == 0)
    gtop cntrct pbpid state county year if _tag & (_everMissingDemo == 1)    & (_alwaysMissingDemo == 0)

    gegen _tag = tag(cntrct pbpid), replace
    count if _tag & (_everMissingSpecial == 1) & (_alwaysMissingSpecial == 0)
    local n1 = `r(N)'
    count if _tag
    local n2 = `r(N)'
    disp "% Plans sometimes missing special, sometimes not: `=100 * `n1' / `n2''"

    count if _tag & (_everMissingDemo == 1) & (_alwaysMissingDemo == 0)
    local n1 = `r(N)'
    count if _tag
    local n2 = `r(N)'
    disp "% Plans sometimes missing demo, sometimes not: `=100 * `n1' / `n2''"

    tab _alwaysMissingSpecial _everMissingSpecial
    tab _alwaysMissingDemo    _everMissingDemo

    local gcall
    local gcall `gcall' (min) _minLagSpecial = trueMASpecial
    local gcall `gcall' (min) _minLagDemo    = trueMADemo
    local gcall `gcall' (min) _minLagNonMA   = trueMANonMA
    local gcall `gcall' (max) _maxLagSpecial = trueMASpecial
    local gcall `gcall' (max) _maxLagDemo    = trueMADemo
    local gcall `gcall' (max) _maxLagNonMA   = trueMANonMA

    gcollapse `gcall', by(cntrct pbpid) merge replace

    gen byte _sameLagSpecial = (_minLagSpecial == _maxLagSpecial)
    gen byte _sameLagDemo    = (_minLagDemo    == _maxLagDemo)
    gen byte _sameLagNonMA   = (_minLagNonMA   == _maxLagNonMA)

    gegen _tag = tag(cntrct pbpid), replace
    tab _sameLagSpecial if _tag & !mi(trueMASpecial)
    tab _sameLagDemo    if _tag & !mi(trueMADemo)
    tab _sameLagNonMA   if _tag & !mi(trueMANonMA)

    drop _*

    * NOTE: This snippet filled in missing values, but we don't need it
    * because we eventually decided that 'missing' for special needs
    * meant that the plan was not special needs, and that we would
    * combine both plan type variables. Hence the only 'missings' we
    * need to pad are for a single plan, which we dropped.

    * foreach var of varlist trueMA* {
    *     bys state county cntrct pbpid year (`var'): replace `var' = `var'[_n - 1] if mi(`var')
    * }
    * gduplicates drop

* NOTE: A small minority of plan types are not consistent within county.

    gcollapse (max) trueMA*, by(state county cntrct pbpid year)

    label var trueMANoPartD  "Plan does not offer Part D coverage"
    label var trueMASpecial  "Special needs plan"
    label var trueMANonMA    "Plan cannot be MA"
    label var trueMADemo     "Demonstration plans"

    save, replace

    * DOC: Merge in SSA state and county codes

    use `"`trueMA'"', clear
        rename state name
        merge m:1 name using `"`states'"', keep(1 3) gen(_mergeState)
        merge m:1 state name county using `"`xw'"', keep(1 3) gen(_mergeCounty)
    save `"${data}/trueMA"', replace

    * Create merge files at the state-plan level
    use `"${data}/trueMA"' if regexm(county, "ALL COUNTIES"), clear
        drop if mi(ssastate)
        keep  ssastate cntrct pbpid year trueMA*
        gisid ssastate cntrct pbpid year
    save `"${data}/trueMAMergeStatePlan"', replace
        replace year = year + 1
        rename * *_lag
        rename year_lag year
    save `"${data}/trueMAMergeStatePlanLag"', replace

    * Create merge files at the county-plan level
    use `"${data}/trueMA"' if !regexm(county, "ALL COUNTIES"), clear
        drop if mi(ssacounty)
        keep  ssacounty cntrct pbpid year trueMA*
        gisid ssacounty cntrct pbpid year
    save `"${data}/trueMAMergeCountyPlan"', replace
        replace year = year + 1
        rename * *_lag
        rename year_lag year
    save `"${data}/trueMAMergeCountyPlanLag"', replace

    * Create merge files at the state-contract level
    use `"${data}/trueMA"' if regexm(county, "ALL COUNTIES"), clear
        gsort ssastate cntrct -year
        by ssastate cntrct: gen yearcount = _n
        keep if yearcount == 1
        drop yearcount

        drop if mi(ssastate)
        keep  ssastate cntrct trueMA*
        rename trueMA* trueMA2*
        gduplicates drop
        gisid ssastate cntrct
    save `"${data}/trueMAMergeStateContract"', replace
        rename * *_lag
    save `"${data}/trueMAMergeStateContractLag"', replace

    * Create merge files at the county-contract level
    use `"${data}/trueMA"' if !regexm(county, "ALL COUNTIES"), clear
        gsort ssacounty cntrct -year
        by ssacounty cntrct: gen yearcount = _n
        keep if yearcount == 1
        drop yearcount

        drop if mi(ssacounty)
        keep  ssacounty cntrct trueMA*
        rename trueMA* trueMA2*
        gduplicates drop
        gisid ssacounty cntrct
    save `"${data}/trueMAMergeCountyContract"', replace
        rename * *_lag
    save `"${data}/trueMAMergeCountyContractLag"', replace
end

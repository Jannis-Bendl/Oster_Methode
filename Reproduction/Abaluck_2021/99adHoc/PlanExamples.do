* 1. PFFS plan that disappears everywhere
*     - By country, share of which plan each person goes
* 2. Non-PFFS plan that terminates everywhere
*     - By country, share of which plan each person goes
* 3. Other examples

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
set seed 1729

* Programs
qui do "00common/00preamble.do" nodep

capture program drop main
program main
    get_data, pct(100) if(if true_mMA2_lag == 1 & year >= 2008)
    * get_examples, cached
end

capture program drop get_data
program get_data
    syntax, pct(str) [if(str)]

    * use `"${data}/_19ivSample`pct'.dta"' `if', clear

    local allPlans_03ivSampleData _19ivSample_preCollapse_`pct'_postnewshrinkage_v31_binned_addedMean.dta
    use `"${data}/`allPlans_03ivSampleData'"' `if', clear
        bys bene_code (year): gen state_lead  = state[_n + 1]
        bys bene_code (year): gen county_lead = county[_n + 1]
        bys bene_code (year): gen pbpid_lead  = pbpid[_n + 1]
        bys bene_code (year): gen cntrct_lead = cntrct[_n + 1]
        bys bene_code (year): gen plan_lead   = plan[_n + 1]

        addNormalizedOrganizationNames organizationname, gen(org)
        bys bene_code (year): gen org_lead = org[_n + 1]

        gegen disappeared_everywhere = min(disappeared_landscape1), by(org pbpid cntrct)

        gen groups = 0
        replace groups = 1 if (disappeared_everywhere == 1) & (pffs_plan == 1)
        replace groups = 2 if (disappeared_everywhere == 1) & (pffs_plan == 0)

        keep if disappeared_landscape1 == 1
        drop if year == 2011
    save "${data}/WhereDoTerminatedPeopleGo.dta", replace
end

capture program drop get_examples
program get_examples
    syntax, [cached]
    use "${data}/WhereDoTerminatedPeopleGo.dta", clear
        gen moved            = (state  != state_lead) | (county != county_lead)

        gen changed_org      = (org    != org_lead)    & !mi(org) & !mi(org_lead)
        gen changed_pbpid    = ((cntrct == cntrct_lead) & (pbpid != pbpid_lead)) | (moved == 1)
        gen changed_cntrct   = (cntrct != cntrct_lead) | (moved == 1)
        gen changed_TM       = plan_lead == -1

        gen same_org         = (org    == org_lead)    & !mi(org) & !mi(org_lead)
        gen same_pbpid       = (cntrct == cntrct_lead) & (pbpid == pbpid_lead) & (moved == 0)
        gen same_cntrct      = (cntrct == cntrct_lead) & (moved == 0)

        gen parents          = inlist(organizationname, "BCBS", "Humana", "Kaiser", "United")
        gen missing_org      = mi(org)
        gen missing_org_next = mi(org_lead)

        local by     st ssacounty state county org cntrct pbpid
        local lead   state_lead county_lead pbpid_lead cntrct_lead org_lead
        local svars  changed_org changed_pbpid changed_cntrct parents missing_org missing_org_next changed_TM
        local svars  `svars' same_*

        gegen nbene = count(1), by(`by')
        gegen tag = tag(`by')
        gstats tab `svars', s(mean)

        gcollapse (mean) `svars', by(`by') merge replace

        gstats tab `svars' if groups == 0, s(p25 p40 p50 p60 p75 mean)
        gstats tab `svars' if groups == 1, s(p25 p40 p50 p60 p75 mean)
        gstats tab `svars' if groups == 2, s(p25 p40 p50 p60 p75 mean)

        gstats tab nbene if tag, s(p25 p40 p50 p60 p75 mean)

        keep if (0.2  < changed_org) & (changed_org < 0.8)
        keep if (10   < nbene)
        keep if missing_org == 0

        keep `by' `lead' `svars' nbene died_365 groups year
        sort `by'
        gunique `by'
        gen nbene_lead = 1
        gcollapse (sum) nbene_lead (sum) died_365, by(`by' `lead' `svars' nbene groups year)

        gegen minyear = min(year), by(`by')
        gegen maxyear = max(year), by(`by')
        assert minyear == maxyear
        drop minyear maxyear
        rename year year_terminate
        gisid `by' `lead', missok

        tempfile examples
        if ( "`cached'" == "" ) {
            glevelsof groups, loc(groups)
            foreach g of local groups {
                preserve
                    keep if groups == `g'
                    keep `by' groups
                    gduplicates drop
                    bsample 2
                    cap append using `"`examples'"'
                    save `"`examples'"', replace
                restore
            }
        }
        else {
            preserve
            use "${data}/WhereDoTerminatedPeopleGo_Examples.dta", clear
                keep `by' groups
                gduplicates drop
                gisid `by' groups
            save `"`examples'"', replace
            restore
        }
        merge m:1 `by' groups using `"`examples'"', keep(3) nogen

        drop missing_org
        gegen died_365 = sum(died_365), by(`by') replace
        gen frac_lead = nbene_lead / nbene
        gen frac_dead = died_365   / nbene

        cap label drop groups
        label define groups 0 "Any disappearance" 1 "PFFS disappeared everywhere" 2 "Non-PFFS disappeared everywhere"
        label values groups groups

    save "${data}/WhereDoTerminatedPeopleGo_Examples.dta", replace
end

capture program drop addNormalizedOrganizationNames
program addNormalizedOrganizationNames
    syntax varname, GENerate(str)

    local Humana  humana
    local BCBS    bcbs|blue.*cross|blue.*shield
    local United  united.*health(.*care)?|securehorizon
    local Kaiser  kaiser
    local parents Humana BCBS United Kaiser

    gen `generate' = `varlist'

    * TODO: xx check in the new data for names that might also be bcbs
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "blue medicare hmo")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "senior blue")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "blue care network")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "traditional blue medicare ppo")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "blue medicare ppo")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "bluemedicare regional ppo")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "bluechoice healthplan")
    replace `generate' = "BCBS" if strpos(lower(`varlist'), "forever blue medicare ppo")

    foreach parent of local parents {
        replace `generate' = `"`parent'"' if regexm(lower(`generate'), `"``parent''"')
    }
end

main

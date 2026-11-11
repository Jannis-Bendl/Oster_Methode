* ---------------------------------------------------------------------
* Merge plan effects, terminations, PFFS, etc.

capture program drop makeAnalysisSample
program makeAnalysisSample
    syntax, pct(str) [subset(str asis) pre(str) replace]

    * ---------------------
    * Average lag mortality
    * ---------------------

    use fe_county cntrct_id pbpid_id died_365 using `"${data}/`pre'alphas`pct'.dta"', clear
        gcollapse (mean) died_365, by(fe_county cntrct_id pbpid_id)
        rename *id *id_lag
        rename fe_county fe_county_lag
        rename died_365 lagmean_died_365_plan
        sort fe_county_lag cntrct_id_lag pbpid_id_lag
    tempfile lagMortPlan
    save `"`lagMortPlan'"'

    use fe_county cntrct_id died_365 using `"${data}/`pre'alphas`pct'.dta"', clear
        gcollapse (mean) died_365, by(fe_county cntrct_id)
        rename *id *id_lag
        rename fe_county fe_county_lag
        rename died_365 lagmean_died_365_contract
        sort fe_county_lag cntrct_id_lag
    tempfile lagMortContract
    save `"`lagMortContract'"'

    * --------------
    * PFFS indicator
    * --------------

    use `"${data}/planTerm"', clear
        keep if substr(cntrct, 1, 1) == "H"
        drop if mi(cntrct) | mi(pbpid)
        gen pffs_cntrct = inlist(plan_type, "08", "09", "40")
        keep cntrct pffs_cntrct year
        gduplicates drop
        sort   cntrct year
        gisid  cntrct year
        compress
    tempfile pffsIndContract
    save `"`pffsIndContract'"'
        rename (cntrct pffs_cntrct) (cntrct_lag pffs_cntrct_lag)
        replace year = year + 1
    tempfile pffsIndContractLag
    save `"`pffsIndContractLag'"'

    use `"${data}/planTerm"', clear
        keep if substr(cntrct, 1, 1) == "H"
        drop if mi(cntrct) | mi(pbpid)
        gen pffs_plan = inlist(plan_type, "08", "09", "40")
        keep cntrct pbpid pffs_plan year
        gduplicates drop
        sort   cntrct pbpid year
        gisid  cntrct pbpid year
        compress
    tempfile pffsIndPlan
    save `"`pffsIndPlan'"'
        rename (cntrct pbpid pffs_plan) (cntrct_lag pbpid_lag pffs_plan_lag)
        replace year = year + 1
    tempfile pffsIndPlanLag
    save `"`pffsIndPlanLag'"'

    * ---------------------------
    * Set up regression variables
    * ---------------------------

    use `"${data}/`pre'alphas`pct'.dta"', clear
    keep bene_code year fe_county_contract fe_county_plan fe_age_median bin* mu* u*
    sort bene_code year
    tempfile mus
    save `"`mus'"'

    use `"${data}/mergedCohorts`pct'"', clear
        `subset'

        computeCountyFractionLag
        gunique fe_county, by(bene_code) gen(ncounty)

        local varsPFFS    cntrct     pbpid     year
        local varsPFFSLag cntrct_lag pbpid_lag year

        merge m:1 `varsPFFS'    using `"`pffsIndPlan'"',    keep(1 3) nogen
        merge m:1 `varsPFFSLag' using `"`pffsIndPlanLag'"', keep(1 3) nogen

        local varsPFFS    cntrct     year
        local varsPFFSLag cntrct_lag year

        merge m:1 `varsPFFS'    using `"`pffsIndContract'"',    keep(1 3) nogen
        merge m:1 `varsPFFSLag' using `"`pffsIndContractLag'"', keep(1 3) nogen

        unab allT:    disappeared_*lag
        unab cntrctT: disappeared_c*lag
        local planT:  list allT - cntrctT

        unab allNoLag:     disappeared_*
        unab cntrctNoLag:  disappeared_c*
        local planNoLag:   list allNoLag - cntrctNoLag
        local cntrctNoLag: list cntrctNoLag - cntrctT
        local planNoLag:   list planNoLag - planT

        foreach var of local planT {
            local newvar: subinstr local var "disappeared_" "Txpffs_"
            gen `newvar' = `var' * pffs_plan_lag
            replace `newvar' = 0 if inlist(plan_lag, -1, -2)
        }

        foreach var of local cntrctT {
            local newvar: subinstr local var "disappeared_" "Txpffs_"
            gen `newvar' = `var' * pffs_cntrct_lag
            replace `newvar' = 0 if inlist(cntrct_id_lag, -1, -2)
        }

        foreach var of local planNoLag {
            local newvar: subinstr local var "disappeared_" "Txpffs_"
            gen `newvar' = `var' * pffs_plan
            replace `newvar' = 0 if inlist(plan, -1, -2)
        }

        foreach var of local cntrctNoLag {
            local newvar: subinstr local var "disappeared_" "Txpffs_"
            gen `newvar' = `var' * pffs_cntrct
            replace `newvar' = 0 if inlist(cntrct_id, -1, -2)
        }

        merge m:1 fe_county_lag cntrct_id_lag pbpid_id_lag using `"`lagMortPlan'"',     keep(1 3) nogen
        merge m:1 fe_county_lag cntrct_id_lag              using `"`lagMortContract'"', keep(1 3) nogen

        gen delta_died_365_plan     = died_365 - lagmean_died_365_plan
        gen delta_died_365_contract = died_365 - lagmean_died_365_contract

        merge 1:1 bene_code year using `"`mus'"',  keep(1 3) nogen

        gen byte ones = 1
        tab fe_race, gen(dum_race)
        tab fe_sex,  gen(dum_sex)

        * DOC: We re-make the enrollment numbers using only remaining
        * beneficiaries.

        gegen nbene_contract_county = tag(fe_county_year cntrct_id bene_code),          replace
        gegen nbene_plan_county     = tag(fe_county_year cntrct_id pbpid_id bene_code), replace
        gegen nbene_county          = tag(fe_county_year bene_code),                    replace

        gegen nbene_contract_county = sum(nbene_contract_county), replace by(fe_county_year cntrct_id)
        gegen nbene_plan_county     = sum(nbene_plan_county),     replace by(fe_county_year cntrct_id pbpid_id)
        gegen nbene_county          = sum(nbene_county),          replace by(fe_county_year)

        gegen nbene_all_contract_county = tag(fe_county cntrct_id bene_code),          replace
        gegen nbene_all_plan_county     = tag(fe_county cntrct_id pbpid_id bene_code), replace
        gegen nbene_all_county          = tag(fe_county bene_code),                    replace

        gegen nbene_all_contract_county = sum(nbene_contract_county), replace by(fe_county cntrct_id)
        gegen nbene_all_plan_county     = sum(nbene_plan_county),     replace by(fe_county cntrct_id pbpid_id)
        gegen nbene_all_county          = sum(nbene_county),          replace by(fe_county)

        compress
        sort bene_code year

        * DOC: The idea here is to generate the alphas using the full
        * universal sample but to do the analysis only on those who were
        * ever enrolled in MA plans. Hence the full sample here, which
        * we later trim to the ever MA sample.

        qui note drop _dta
        label data drop
        label data "`pct'% ivSample (version: _19, full data)"

    save `"${data}/`pre'ivSample`pct'_full.dta"', `replace'
end

* DOC: compute the % share of TM the year prior in each county. We also
* compute the share in "employer" plans (HMO indicator C or contract
* letter R) the year prior. Note this is over the number of _remaining_
* beneficiaries, which is why it's ran _post_ any sample generation.

capture program drop computeCountyFractionLag
program computeCountyFractionLag

    frame put fe_county year eTM mTM eEmployer mEmployer, into(lagTMShare)
    frame lagTMShare {
        gcollapse (mean)                       /*
            */ frac_eTM_lag       = eTM        /*
            */ frac_mTM_lag       = mTM        /*
            */ frac_eEmployer_lag = eEmployer  /*
            */ frac_mEmployer_lag = mEmployer  /*
            */ , by(fe_county year) fast
        label var frac_eTM_lag       "Proportion TM last year in bene's current county (eMA; fraction)"
        label var frac_mTM_lag       "Proportion TM last year in bene's current county (mMA; modal)"
        label var frac_eEmployer_lag "Proportion hmoind = C or cntrct = R last year in bene's current county (eMA; fraction)"
        label var frac_mEmployer_lag "Proportion hmoind = C or cntrct = R last year in bene's current county (mMA; modal)"
        replace year = year + 1
        sort fe_county year
        compress
        tempfile lagTMShare
        save `"`lagTMShare'"'
    }
    frame drop lagTMShare

    frame put fe_county year plan, into(lagPlanShare)
    frame lagPlanShare {
        gen nbene_plan_county = 1
        gen nbene_county = 1
        gegen nbene_plan_county = sum(nbene_plan_county), by(fe_county year plan) replace
        gegen nbene_county = sum(nbene_county), by(fe_county year) replace
        gen frac_plan_county_lag = nbene_plan_county / nbene_county

        keep fe_county plan year frac_plan_county_lag
        label var frac_plan_county_lag "Proportion in current county-plan the year prior"
        replace year = year + 1
        rename (fe_county plan) (fe_county_lag plan_lag)
        sort fe_county_lag plan_lag year
        gduplicates drop
        compress
        gisid fe_county_lag plan_lag year

        * make sure that all plans see market share < 1
        assert frac_plan_county_lag <= 1

        * make sure that market shares sum to 1
        gegen plan_sum = sum(frac_plan_county_lag), by(fe_county_lag year)
        gen double absdiff = abs(1 - plan_sum)
        gstats sum absdiff
        assert absdiff < 1e-6
        drop absdiff plan_sum

        tempfile lagPlanShare
        save `"`lagPlanShare'"'
    }
    frame drop lagPlanShare

    merge m:1 fe_county year using `"`lagTMShare'"', keep(1 3) nogen
    merge m:1 fe_county_lag plan_lag year using `"`lagPlanShare'"', keep(1 3) nogen
end

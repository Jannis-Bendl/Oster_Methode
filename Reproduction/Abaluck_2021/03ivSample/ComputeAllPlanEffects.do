* ---------------------------------------------------------------------
* Loop through every plan effects version
*
* See muNamingConventionLabel in ApplyVariableLabels.do for variable naming conventions

capture program drop makePlanEffects
program makePlanEffects
    syntax, pct(str) [subset(str asis) pre(str) replace forcema(str)]
    local opts pre(`pre') pct(`pct') `replace'

    use `"${data}/mergedCohorts`pct'.dta"', clear

    * DOC: This applies various sub-setting schemes. Typically subset
    * will be specified, but we variously allow for or forcing everyone
    * enrolled to have been in an MA plan at some point.

    `subset'
    if ( `"`forcema'"' != "" ) {
        gegen _everma = max(`forcema'), by(bene_code)
        keep if _everma
        drop _everma
    }

    keep bene_code      ///
         year           ///
         plan           ///
         pbpid_id       ///
         cntrct_id      ///
         demo_age       ///
         died_365       ///
         fe_county      ///
         fe_county_year ///
         fe_race        ///
         fe_sex         ///
         fe_age         ///
         age_first      ///
         mDual

    gegen fe_county_contract = group(fe_county cntrct_id)
    gegen fe_county_plan     = group(fe_county cntrct_id pbpid_id)

    * DOC: Because age changes over time, the consistency of the results
    * gets messed up. We use median age in `predict`

    gegen fe_age_median   = median(demo_age), by(bene_code) replace
    replace fe_age_median = 5 * floor(fe_age_median / 5)
    replace fe_age_median = 60 if fe_age_median <= 60
    replace fe_age_median = 95 if fe_age_median >= 95

    * DOC: Drop all benes ever in high dual plan

    gegen county_contract_size     = tag(fe_county_contract bene_code)
    gegen county_plan_size         = tag(fe_county_plan     bene_code)
    gegen county_contract_dualsize = tag(fe_county_contract bene_code) if mDual == 1
    gegen county_plan_dualsize     = tag(fe_county_plan     bene_code) if mDual == 1

    gegen county_contract_size     = sum(county_contract_size),     by(fe_county_contract) replace
    gegen county_plan_size         = sum(county_plan_size),         by(fe_county_plan)     replace
    gegen county_contract_dualsize = sum(county_contract_dualsize), by(fe_county_contract) replace
    gegen county_plan_dualsize     = sum(county_plan_dualsize),     by(fe_county_plan)     replace

    gen county_contract_dual_rate  = county_contract_dualsize / county_contract_size
    gen county_plan_dual_rate      = county_plan_dualsize     / county_plan_size

    gegen drop_bene = max((county_contract_dual_rate > .5) | (county_plan_dual_rate > .5)), by(bene_code)
    display "dropping benes ever in a high dual plan"
    drop if drop_bene == 1
    drop drop_bene

    * DOC: flag non-small contracts. small contracts will not be used to
    * create plan or contract level effects

    gen byte county_contract_size_100min = (county_contract_size >= 100)
    gen byte county_plan_size_50min      = (county_plan_size     >= 50)
    gen byte country_large_contract_plan = (county_contract_size_100min == 1) & (county_plan_size_50min == 1)

    drop county_contract_size county_plan_size

    * DOC: Make plan and age bins
    gegen contract_size_forbins = count(1), by(fe_county_contract)
    gegen plan_size_forbins     = count(1), by(fe_county_plan) replace

    gen     bin_num = 1 if contract_size_forbins <=  50
    replace bin_num = 2 if contract_size_forbins > 50   & contract_size_forbins <= 150
    replace bin_num = 3 if contract_size_forbins > 150  & contract_size_forbins <= 350
    replace bin_num = 4 if contract_size_forbins > 350  & contract_size_forbins <= 1000
    replace bin_num = 5 if contract_size_forbins > 1000 & contract_size_forbins <= 4000
    replace bin_num = 6 if contract_size_forbins > 4000

    gen     bin_old = 1 if plan_size_forbins <= 1000
    replace bin_old = 2 if plan_size_forbins > 1000  & plan_size_forbins <= 2500
    replace bin_old = 3 if plan_size_forbins > 2500  & plan_size_forbins <= 5000
    replace bin_old = 4 if plan_size_forbins > 5000  & plan_size_forbins <= 15000
    replace bin_old = 5 if plan_size_forbins > 15000 & plan_size_forbins <= 25000
    replace bin_old = 6 if plan_size_forbins > 25000 & plan_size_forbins <= 75000
    replace bin_old = 7 if plan_size_forbins > 75000 & plan_size_forbins <= 200000
    replace bin_old = 8 if plan_size_forbins > 200000

    gen bin_year = (year > 2008) + 1
    gen bin_age  = floor(age_first / 5) * 5
    replace bin_age = 85 if bin_age > 85

    glevelsof bin_year, loc(year_bins) silent
    glevelsof bin_age,  loc(age_bins)  silent
    glevelsof bin_old,  loc(size_old)  silent
    glevelsof bin_num,  loc(size_bin)  silent

    global year_bins: copy local year_bins
    global age_bins:  copy local age_bins
    global size_old:  copy local size_old
    global size_bin:  copy local size_bin

    local id      bene_code year
    local fe      fe_county fe_county_plan fe_county_contract fe_county_year
    local vars    died_365 fe_race fe_sex fe_age mDual country_large_contract_plan
    local varopts id(`id') fe(`fe') vars(`vars')
    sort `id'

    runRExtreg, `opts' level(plan)     fesuf(CY)
    runRExtreg, `opts' level(contract) fesuf(CY)

    computeHierarchicalMU, `opts' fesuf(CY)

    alphasByBin,      size(bin_old size_old) suffix(CYBOld) `varopts' `opts'
    alphasByBin,      size(bin_num size_bin) suffix(CYB)    `varopts' `opts'
    alphasByBin,      size(bin_num size_bin) suffix(CYBAD)  `varopts' `opts' demo(i.fe_age mDual) skipnoc
    alphasByBinGroup, size(bin_num size_bin) suffix(CYAB)   `varopts' `opts' group(bin_age  age_bins)
    alphasByBinGroup, size(bin_num size_bin) suffix(CYYB)   `varopts' `opts' group(bin_year year_bins)

    local varalphas mucounty_* mucnoc_*
    foreach varset of local varalphas {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                bys bene_code (year): gen `var'_lag = `var'[_n - 1]
            }
        }
    }

    addBinLevelMeans bin_old,          s(oldbin)    fesuf(CYBOld)
    addBinLevelMeans bin_num,          s(bin)       fesuf(CYB)
    addBinLevelMeans bin_num,          s(adonlybin) fesuf(CYBAD) skipnoc
    addBinLevelMeans bin_num bin_age,  s(agebin)    fesuf(CYAB)
    addBinLevelMeans bin_num bin_year, s(yearbin)   fesuf(CYYB)

    local varalphas u_* unoc_* mu*
    foreach varset of local varalphas {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                muNamingConventionLabel `var'
            }
        }
    }

    save `"${data}/`pre'alphas`pct'.dta"', `replace'

    local varalphas u_* mucounty_* unoc_* mucnoc_* muc*bin*

    disp "Check alpha consistency (must be stable over time)"
    local keepalphas
    foreach varset of local varalphas {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                if ( substr("`var'", -3, 3) == "lag" ) continue
                    local keepalphas `keepalphas' `var'
            }
        }
    }

    disp "done with the alphas"

    keep fe_county_* `keepalphas' bin*
    gduplicates drop

    frame put fe_county_contract u*CYContract,                into(contract_check)
    frame put fe_county_contract u*CYBContract   bin_num,     into(contractb_check)
    frame put fe_county_contract u*CYBADContract bin_num,     into(contractbad_check)
    frame put fe_county_contract u*CYABContract  bin_agebin,  into(contractab_check)
    frame put fe_county_contract u*CYYBContract  bin_yearbin, into(contractyb_check)

    frame put fe_county_plan *u*CYPlan,                into(plan_check)
    frame put fe_county_plan *u*CYBPlan   bin_num,     into(planb_check)
    frame put fe_county_plan *u*CYBADPlan bin_num,     into(planbad_check)
    frame put fe_county_plan *u*CYABPlan  bin_agebin,  into(planab_check)
    frame put fe_county_plan *u*CYYBPlan  bin_yearbin, into(planyb_check)

    frame contract_check:   gduplicates drop
    frame contract_check:   gisid fe_county_contract

    frame contractb_check:  gduplicates drop
    frame contractb_check:  gisid fe_county_contract bin_num

    frame contractbad_check:  gduplicates drop
    frame contractbad_check:  gisid fe_county_contract bin_num

    frame contractab_check: gduplicates drop
    frame contractab_check: gisid fe_county_contract bin_agebin

    frame contractyb_check: gduplicates drop
    frame contractyb_check: gisid fe_county_contract bin_yearbin

    frame plan_check:   gduplicates drop
    frame plan_check:   gisid fe_county_plan

    frame planb_check:  gduplicates drop
    frame planb_check:  gisid fe_county_plan bin_num

    frame planbad_check:  gduplicates drop
    frame planbad_check:  gisid fe_county_plan bin_num

    frame planab_check: gduplicates drop
    frame planab_check: gisid fe_county_plan bin_agebin

    frame planyb_check: gduplicates drop
    frame planyb_check: gisid fe_county_plan bin_yearbin

    frame drop contract_check
    frame drop contractb_check
    frame drop contractbad_check
    frame drop contractab_check
    frame drop contractyb_check

    frame drop plan_check
    frame drop planb_check
    frame drop planbad_check
    frame drop planab_check
    frame drop planyb_check

    disp "done with the checks"

    * * --------------------------
    * * Sanity check for shrinkage
    * * --------------------------
    *
    * * Note basic shrinkage only between 0, 1 when there is a single plan
    * gegen nplan      = nunique(fe_county_plan), by(fe_county_contract)
    * gen float what   = what_feCYBPlan
    * gen float u      = u_feCYBPlan
    * gen float mu     = mucounty_mleCYBPlan
    * gen float lambda = (mucounty_mleCYBPlan - what) / (u - what)
    * 
    * gstats sum lambda if nplan == 1
    * gstats tab lambda if nplan == 1, by(bin_num) s(mean p1 p5 p25 p50 p75 p95 p99)
    * 
    * * With more than one plan, the hierarchical shrinkage need not
    * * literally shrink because we have some matrix algebra. We can 
    * * double check the matrix was positive definite, however.
    * gen float fe    = (u - what)
    * gen float fesum = fe * fe
    * gen float musum = fe * (mucounty_mleCYBPlan - what_feCYBPlan)
    * gegen fesum     = sum(fesum), by(fe_county) replace
    * gegen musum     = sum(musum), by(fe_county) replace
    * gen float check = musum / fesum
    * gstats sum check
    * gstats tab check, by(bin_num) s(mean p1 p5 p25 p50 p75 p95 p99)
end

* ---------------------------------------------------------------------
* Sets of alphas

capture program drop alphasByBin
program alphasByBin
    syntax, size(str) suffix(str) pct(str) id(str) fe(str) vars(str) [*]
    gettoken size_var size_bin: size

    local j = 0
    foreach bin_count of global `size_bin' {
        local suffixj `suffix'`bin_count'
        local len = length(`"`suffixj'"') + 8

        disp ""
        disp "running `suffixj'"
        disp "{hline `len'}"

        local if `size_var' == `bin_count'
        count if `if'
        local N = `r(N)'

        qui gdistinct fe_county_plan fe_county_contract if `if'
        matrix distinct = r(distinct)
        local nplan     = distinct[1, 2]
        local ncontract = distinct[2, 2]

        local fail = (`nplan' <= 1) | (`ncontract' <= 1) | (`r(N)' <= 1)
        if ( `fail' & (`pct' < 100) ) continue

        frame put `id' `fe' `vars' if `if', into(`suffixj')
        frame `suffixj' {
            runRExtreg, `options' pct(`pct') level(plan)     fesuf(`suffixj')
            runRExtreg, `options' pct(`pct') level(contract) fesuf(`suffixj')

            computeHierarchicalMU, `options' pct(`pct') fesuf(`suffixj')

            rename *fe`suffixj'*  *fe`suffix'*
            rename *mle`suffixj'* *mle`suffix'*

            unab getvars: *fe`suffix'* *mle`suffix'*
            keep `id' `getvars'
            sort `id'
        }

        frlink 1:1 `id', frame(`suffixj')
        assert (`if') == !mi(`suffixj')
        if ( `j++' ) {
            foreach var of varlist `getvars' {
                replace `var' = frval(`suffixj', `var') if `if'
            }
        }
        else {
            frget `getvars', from(`suffixj')
        }
        frame drop `suffixj'
        drop `suffixj'
    }
end

capture program drop alphasByBinGroup
program alphasByBinGroup
    syntax, size(str) group(str) suffix(str) pct(str) id(str) fe(str) vars(str) [*]

    gettoken size_var  size_bin:  size
    gettoken group_var group_bin: group

    local j = 0
    foreach bin_group of global `group_bin' {
        foreach bin_count of global `size_bin' {
            local suffixj `suffix'`bin_count'`bin_group'
            local len = length(`"`suffixj'"') + 8

            disp ""
            disp "running `suffixj'"
            disp "{hline `len'}"

            local if (`size_var' == `bin_count') & (`group_var' == `bin_group')
            count if `if'
            local N = `r(N)'

            qui gdistinct fe_county_plan fe_county_contract if `if'
            matrix distinct = r(distinct)
            local nplan     = distinct[1, 2]
            local ncontract = distinct[2, 2]

            local fail = (`nplan' <= 1) | (`ncontract' <= 1) | (`r(N)' <= 1)
            if ( `fail' & (`pct' < 100) ) continue

            frame put `id' `fe' `vars' if `if', into(`suffixj')
            frame `suffixj' {
                runRExtreg, `options' pct(`pct') level(plan)     fesuf(`suffixj')
                runRExtreg, `options' pct(`pct') level(contract) fesuf(`suffixj')

                computeHierarchicalMU, `options' pct(`pct') fesuf(`suffixj')

                rename *fe`suffixj'*  *fe`suffix'*
                rename *mle`suffixj'* *mle`suffix'*

                unab getvars: *fe`suffix'* *mle`suffix'*
                keep `id' `getvars'
                sort `id'
            }

            frlink 1:1 `id', frame(`suffixj')
            assert (`if') == !mi(`suffixj')
            if ( `j++' ) {
                foreach var of varlist `getvars' {
                    replace `var' = frval(`suffixj', `var') if `if'
                }
            }
            else {
                frget `getvars', from(`suffixj')
            }
            frame drop `suffixj'
            drop `suffixj'
        }
    }
end

* ---------------------------------------------------------------------
* Helpers

capture program drop runRExtreg
program runRExtreg
    syntax, pct(str) level(str) fesuf(str) [pre(str) replace large DEMOgraphics(str) skipnoc *]

    if ( "`demographics'" == "" ) local demographics i.fe_race i.fe_sex i.fe_age mDual

    local felevel  fe_county_`level'
    local varsuf   mle`fesuf'`=proper(`"`level'"')'
    local fevarsuf fe`fesuf'`=proper(`"`level'"')'

    mytimer_ts runRExtreg: xtreg 365-mortality fe_county_year `demographics' || `felevel'

    local locals pre pct replace level fesuf varsuf felevel fevarsuf
    foreach l of local locals {
        disp %-14s "    `l': ", "``l''"
    }

    sort  `felevel'
    xtset `felevel'

    tempvar nbene
    gegen `nbene' = count(1), by(`felevel') replace

    * DOC: Due to memory constraints, we de-mean mortality, run the
    * fixed-effects model on that, and shrink the alphas manually.

    local hdfeopts absorb(u_`fevarsuf'=`felevel' fe_county_year) resid keepsingleton
    qui reghdfe died_365 `demographics', `hdfeopts'
    estimates save `"${out}/estimates/`level'/hdfe/`pre'_`pct'pct`varsuf'"', `replace'

    predict rawxb_`fevarsuf', xb
    predict rawfe_`fevarsuf', d
    replace rawfe_`fevarsuf' = rawfe_`fevarsuf' - u_`fevarsuf'
    replace rawxb_`fevarsuf' = rawxb_`fevarsuf' + rawfe_`fevarsuf'

    gen dtilde_`varsuf' = died_365 - rawxb_`fevarsuf'
    replace dtilde_`varsuf' = dtilde_`varsuf' + _b[_cons]
    drop raw*

    * DOC: Here we estimate the model and manually shrink the
    * value-added estaimtes.

    if ( `"`large'"' != "" ) {
        local if if country_large_contract_plan
    }
    cap noi xtreg dtilde_`varsuf' `if', mle
    cap noi disp e(sigma_u)
    cap noi disp e(sigma_e)

    estimates save `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`varsuf'"', `replace'

    local sigma_alpha = e(sigma_u)
    local sigma_eps   = e(sigma_e)
    local mu_hat      = _b[_cons]

    gegen what_`fevarsuf' = mean(u_`fevarsuf'), by(fe_county)
    gen lambda_`varsuf'   = `sigma_alpha'^2 / (`sigma_alpha'^2 + `sigma_eps'^2 / `nbene')

    * DOC: As above, but without controls

    if ( "`skipnoc'" == "" ) {
    local hdfeopts absorb(unoc_`fevarsuf'=`felevel' fe_county_year) resid keepsingleton
    qui reghdfe died_365, `hdfeopts'
    estimates save `"${out}/estimates/`level'/hdfe/`pre'_`pct'pct`varsuf'_noc"', `replace'

    predict rawxb_`fevarsuf', xb
    predict rawfe_`fevarsuf', d
    replace rawfe_`fevarsuf' = rawfe_`fevarsuf' - unoc_`fevarsuf'
    replace rawxb_`fevarsuf' = rawxb_`fevarsuf' + rawfe_`fevarsuf'

    gen dnoc_`varsuf' = died_365 - rawxb_`fevarsuf'
    replace dnoc_`varsuf' = dnoc_`varsuf' + _b[_cons]
    drop raw*

    if ( `"`large'"' != "" ) {
        local if if country_large_contract_plan
    }
    cap noi xtreg dnoc_`varsuf' `if', mle
    cap noi disp e(sigma_u)
    cap noi disp e(sigma_e)

    estimates save `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`varsuf'_noc"', `replace'

    local sigma_alpha = e(sigma_u)
    local sigma_eps   = e(sigma_e)
    local mu_hat      = _b[_cons]

    gegen wnoc_`fevarsuf' = mean(unoc_`fevarsuf'), by(fe_county)
    gen lnoc_`varsuf'     = `sigma_alpha'^2 / (`sigma_alpha'^2 + `sigma_eps'^2 / `nbene')
    }
end

capture program drop addBinLevelMeans
program addBinLevelMeans
    syntax varlist, [Suffix(str) fesuf(str) skipnoc]

    local vars: copy local varlist
    gettoken var vars: vars
    local missing mi(`var')
    foreach var of local vars {
        local missing `missing' | mi(`var')
    }

    gegen mean_died_365_`suffix' = mean(died_365) if !(`missing'), by(`varlist')
    local laglist
    foreach var of local varlist {
        local laglist `laglist' `var'_lag
        cap confirm var `var'_lag
        if ( _rc ) bys bene_code (year): gen `var'_lag = `var'[_n - 1]
    }

    tempname lag
    frame put `varlist' mean_died_365_`suffix', into(`lag')
    frame `lag' {
        drop if `missing'
        gduplicates drop
        rename * *_lag
    }
    frlink m:1 `laglist', frame(`lag')
    frget mean_died_365_`suffix'_lag, from(`lag')
    frame drop `lag'

    gen muc`suffix'_mle`fesuf'Plan     = mucounty_mle`fesuf'Plan     + mean_died_365_`suffix'
    gen muc`suffix'_mle`fesuf'Plan_lag = mucounty_mle`fesuf'Plan_lag + mean_died_365_`suffix'_lag

    if ( "`skipnoc'" == "" ) {
    gen mucnoc`suffix'_mle`fesuf'Plan     = mucnoc_mle`fesuf'Plan     + mean_died_365_`suffix'
    gen mucnoc`suffix'_mle`fesuf'Plan_lag = mucnoc_mle`fesuf'Plan_lag + mean_died_365_`suffix'_lag
    }

    if ( `:list sizeof varlist' > 1 ) {
        gegen bin_`suffix'     = group(`varlist')
        gegen bin_`suffix'_lag = group(`laglist')
    }
end

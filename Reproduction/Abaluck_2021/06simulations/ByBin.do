/* For testing

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
set seed 42

* Programs
qui do "00common/00preamble.do" nodep
qui do "00common/00material.do"
qui do "03ivSample/HierarchicalEffects.do"

cap mkdir `"${out}/fig"'
cap mkdir `"${out}/fig/simulations"'

capture program drop main
program main
    * simulate, pre(_19) pct(01) bin_var(bin_old) fesuf(mleCYBOld)  bin_suf(oldbin)
    * simulate, pre(_19) pct(01) bin_var(bin_num) fesuf(mleCYB)     bin_suf(bin)
    simulate, pre(_19) pct(100) bin_var(bin_old) fesuf(mleCYBOld) bin_suf(oldbin)
    simulate, pre(_19) pct(100) bin_var(bin_num) fesuf(mleCYB)    bin_suf(bin)
end


main

*/


capture program drop simulate
program simulate
    syntax, [nsim(int 20) *]

    merge_pdv, `options'
    make_vsl_table 369
    mata vsl = st_matrix("r(vsl)")

    disp `"Table VSL"'
    mata vsl

    simulate_prepare_data, `options'
    make_simulated_share_assignment, `options'

    mata sim = J(0, 3, .)
    forvalues i = 1 / `nsim' {
        qui simulate_plan_reassignment, `options'
        qui make_simulated_mu_table,    `options'

        mata sim = sim \ (J(2, 1, `i'), st_matrix("r(meancond)"), st_matrix("r(meanall)"))
    }

    disp `"Table A5 over `nsim' iterations (`options')"'
    mata sim

    qui export_tables, `options'
end


capture program drop simulate_prepare_data
program simulate_prepare_data
    syntax, pre(str) pct(str) bin_var(str) [fesuf(str) bin_suf(str) *]

    /* For testing

    use `"${data}/`pre'alphas`pct'.dta"', clear
    keep bene_code year mean_died_365_`bin_suf'
    tempfile mean_died
    save `"`mean_died'"'

    use `"${data}/`pre'ivSample`pct'.dta"', clear
    keep if (true_mMA2_lag == 1) & (year >= 2008) & !mi(`bin_var'_lag)
    merge 1:1 bene_code year using `"`mean_died'"', keep(1 3) nogen assert(2 3)

    gen ytd = deathyear - year
    gstats tab ytd, by(year)

    */

    gegen nbene_yr_plan = count(1), by(fe_county_plan year) replace
    drop if nbene_yr_plan < 12

    gegen tag_plan     = tag(fe_county_plan), replace
    gegen tag_contract = tag(fe_county_contract), replace
    rename plan_size_forbins nbene_plan

    * NOTE: This was in the original code, but we really should be
    * using the plan sized in the full sample, not in the selected
    * sample. There are version where those two are the same but version
    * where they may differ.
    *
    * gegen nbene_plan = count(1), by(fe_county_plan) replace

    glevelsof `bin_var', loc(bins) silent

    local floats sigma_w2            ///
                 sigma_eta2          ///
                 sigma_eps2          ///
                 mu_true             ///
                 mu_hat              ///
                 random_plan         ///
                 reassign_mu_rand    ///
                 reassign_top_bottom ///
                 reassign_mu_p95     /// reassign_mu_min
                                     /// reassign_mu_worst

    local bytes tag_p25   ///
                tag_p75   ///
                tag_p95   ///
                tag_rand /// tag_best
                         /// tag_worst

    foreach var in `floats' `bytes' {
        cap drop `var'
    }
    mata (void) st_addvar(J(1, `:list sizeof floats', st_global("c(type)")), tokens(st_local("floats")))
    mata (void) st_addvar(J(1, `:list sizeof bytes', "byte"), tokens(st_local("bytes")))

    foreach bin of local bins {
        local level contract
        local Level Contract
        estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`fesuf'`bin'`Level'"'
        qui xtreg
        replace sigma_w2 = e(sigma_u)^2 if `bin_var' == `bin'

        local level plan
        local Level Plan
        estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`fesuf'`bin'`Level'"'
        qui xtreg
        replace sigma_eta2 = cond(e(sigma_u)^2 < sigma_w2, 0, e(sigma_u)^2 - sigma_w2) if `bin_var' == `bin'
        replace sigma_eps2 = e(sigma_e)^2 if `bin_var' == `bin'
    }

    sort fe_county_year
end


capture program drop simulate_plan_reassignment
program simulate_plan_reassignment
    syntax, bin_var(str) bin_suf(str) [*]
    cap drop mu_est
    cap drop mu_*rand*

    * DOC: How to do the simulations? We discussed
    *
    *     - They should be by county-year
    *     - They should be beneficiary-weighted (for now).
    *
    * While unweighted might make sense we decided to table that
    * discussion for the time-being. We simulate:
    *
    *     0. Draws of mu_j
    *     1. Reassignment to random plan
    *     2. Top to bottom quartile plans (75th pctile - 25th pctile)
    *     3. Reassigning worst 5% of _benes_ to random plan
    *     X. (Not in use) simulation reassigning worst plan in each county year to random plan
    *     X. (not in use) Assignment to minimum-mortality plan

    gegen randomnorm_plan     = first(rnormal()), replace by(`bin_var' fe_county_plan)
    gegen randomnorm_contract = first(rnormal()), replace by(`bin_var' fe_county_contract)

    local bmean mean_died_365_`bin_suf'
    replace mu_true = (randomnorm_plan * sqrt(sigma_eta2) + randomnorm_contract * sqrt(sigma_w2)) + `bmean'
    replace mu_hat  = mu_true + rnormal() * sqrt(sigma_eps2) / sqrt(nbene_plan)

    _computeHierarchicalMU mu_est = mu_hat, nj(nbene_plan) by(`bin_var') variables

    gegen mu_bene_rank = rank(mu_est), by(fe_county_year) ties(unique) replace
    gcollapse (min) mu_min = mu_est ///
              (max) mu_max = mu_est ///
              (p25) mu_p25 = mu_est ///
              (p75) mu_p75 = mu_est ///
              (p95) mu_p95_rank = mu_bene_rank, by(fe_county_year) merge replace

    * bys fe_county_year: gen mu_argrand = ceil(runiform() * _N)
    * bys fe_county_year: gen mu_rand    = mu_est[mu_argrand[1]]

    replace tag_p25   = (mu_est == mu_p25)
    replace tag_p75   = (mu_est == mu_p75)
    replace tag_p95   = (mu_bene_rank > mu_p95_rank)
    * replace tag_rand  = 1
    * replace tag_best  = 1
    * replace tag_worst = (mu_est == mu_max)

    replace random_plan  = cond(tag_p95, 1, runiform())
    gegen random_plan    = rank(random_plan), by(fe_county_year) ties(track) replace
    replace random_plan  = (random_plan == 1)
    gegen mu_true_random = firstnm(cond(random_plan, mu_true, .)), by(fe_county_year) replace

    * replace random_plan  = cond(tag_worst, 1, runiform())
    * gegen random_plan    = rank(random_plan), by(fe_county_year) ties(track) replace
    * replace random_plan  = (random_plan == 1)
    * gegen mu_true_worst  = firstnm(cond(random_plan, mu_true, .)), by(fe_county_year) replace

    gegen mu_true_max = firstnm(cond(mu_max == mu_est, mu_true, .)), by(fe_county_year) replace
    gegen mu_true_p25 = firstnm(cond(mu_p25 == mu_est, mu_true, .)), by(fe_county_year) replace
    gegen mu_true_p75 = firstnm(cond(mu_p75 == mu_est, mu_true, .)), by(fe_county_year) replace
    * gegen mu_true_min = firstnm(cond(mu_min == mu_est, mu_true, .)), by(fe_county_year) replace

    replace reassign_top_bottom = cond(tag_p75,   mu_true_p25,    mu_true)
    replace reassign_mu_p95     = cond(tag_p95,   mu_true_random, mu_true)
    * replace reassign_mu_rand    = cond(tag_rand,  mu_rand,        mu_true)
    * replace reassign_mu_worst   = cond(tag_worst, mu_true_worst,  mu_true)
    * replace reassign_mu_min     = cond(tag_worst, mu_true_min,    mu_true)
end


capture program drop make_simulated_share_assignment
program make_simulated_share_assignment
    syntax, pct(str) pre(str) [*]
    local tag        PlanCharsRegressionsV4
    local sample     SampleSelection2
    local endogenous ln_marketshare

    estimates use ${out}/estimates/plan/ivreg/`pre'dead365_`pct'pct_`sample'`tag'_iv_`endogenous'_iv_lin.ster
    qui ivreghdfe
    tempname lambda llower lupper
    scalar `lambda' = _b[`endogenous']
    scalar `llower' = `lambda' - invnormal(0.975) * _b[`endogenous']
    scalar `lupper' = `lambda' + invnormal(0.975) * _b[`endogenous']

    preserve
        keep if true_mMA2 == 1

        gegen enroll_plan   = count(1), by(year state county cntrct_id pbpid_id)
        gegen enroll_county = count(1), by(year state county)
        gen percent_enroll  = enroll_plan / enroll_county
        gen delta           = `lambda' * (ln(1/enroll_plan) - log(percent_enroll))
        gen lower           = `llower' * (ln(1/enroll_plan) - log(percent_enroll))
        gen upper           = `lupper' * (ln(1/enroll_plan) - log(percent_enroll))

        qui gstats tab delta upper lower, s(mean) mata(meanshare)
        mata meanshare_output = meanshare.output
    restore
end

capture program drop make_simulated_mu_table
program make_simulated_mu_table, rclass
    syntax, [*]

    tempname meancond meanall
    * mata `col' = J(3, 1, .)
    * mata `simulation' = J(3, 6, .)
    * mata `simulation'[., 5] = J(3, 1, `lambda')
    * mata `simulation'[., 6] = J(3, 1, st_numscalar("`mean'"))

    genfly: gstats tab                                         ///
        {cond(tag_p75,  - (mu_true - reassign_top_bottom), .)} ///
        {cond(tag_p95,  - (mu_true - reassign_mu_p95),     .)} ///
        , s(mean) mata(`meancond')

    genfly: gstats tab                      ///
        {- (mu_true - reassign_top_bottom)} ///
        {- (mu_true - reassign_mu_p95)}     ///
        , s(mean) mata(`meanall')

    *      | Change   | %        | Change   | %        |
    * ---- | -------- | -------- | -------- | -------- |
    * 1    |      xxx |      xxx |      xxx |      xxx |
    *      | [xx, xx] | [xx, xx] | [xx, xx] | [xx, xx] |
    * 2    |      xxx |      xxx |      xxx |      xxx |
    *      | [xx, xx] | [xx, xx] | [xx, xx] | [xx, xx] |
    * 3    |      xxx |      xxx |      xxx |      xxx |
    *      | [xx, xx] | [xx, xx] | [xx, xx] | [xx, xx] |

    mata st_matrix("`meancond'", `meancond'.output)
    mata st_matrix("`meanall'",  `meanall'.output)

    return matrix meancond = `meancond'
    return matrix meanall  = `meanall'
end


capture program drop make_vsl_table
program make_vsl_table, rclass
    args vsly

    tempname vsl
    local pdv pdv_100max_95delta_noscale ///
              pdv_100max_95delta_2dscale ///
              pdv_100max_98delta_noscale ///
              pdv_100max_98delta_2dscale

    gstats tab `pdv', s(mean) mata(`vsl')

    *  VSL | Scale  | P(death) | delta | $ (1000s) |
    * ---- | ------ | -------- | ----- | --------- |
    * 369k |     1x |       1x | 0.95  |   2,167.3 |
    *      |        |       2x | 0.95  |   1,302.0 |
    *      | ------ |--------- | ----- | --------- |
    *      |   0.5x |       1x | 0.95  |   1,083.6 |
    *      |        |       2x | 0.95  |     651.0 |

    mata st_matrix("`vsl'", (`vsly' * `vsl'.output) \ (`vsly' * `vsl'.output :/ 2))
    return matrix vsl = `vsl'
end


capture program drop merge_pdv
program merge_pdv
    syntax, pre(str) [*]
    tempname life
    frame create `life'
    frame change `life'
        use `"${data}/`pre'life_tables"', clear
            mata _ComputeDiscountedLife(0.95, 100, 1, "pdv_100max_95delta_noscale")
            mata _ComputeDiscountedLife(0.95, 100, 2, "pdv_100max_95delta_2dscale")
            mata _ComputeDiscountedLife(0.98, 100, 1, "pdv_100max_98delta_noscale")
            mata _ComputeDiscountedLife(0.98, 100, 2, "pdv_100max_98delta_2dscale")

            * "1" is "male" and "2" is "female"
            drop lt_*
            local stub pdv_[0-9]+max_[0-9]+delta_.+scale
            greshape long (1|2)(?=$), by(demo_age year) key(demo_sex) match(ustrregex) string
        tempfile pdv
        save `"`pdv'"'
    frame change default
    merge m:1 year demo_age demo_sex using `"`pdv'"', keep(1 3) assert(2 3) nogen
end


capture program drop export_tables
program export_tables
    syntax, contract(str) pre(str) pct(str) sampleSelection(str) tag(str) v(str) [*]

    mata save_table("${out}/tables/`pre'tables`pct'pct.txt", "vsl_expected_discounting", vsl)

    qui sum died_365
    scalar deadmean = r(mean)
    local results ${out}/estimates/`contract'/ivreg/`pre'dead365_`pct'pct_`sampleSelection'_`tag'_`v'
    estimates use `"`results'"'
    qui ivreghdfe

    mata st_numscalar("lambda", st_matrix("e(b)")[1])
    mata st_numscalar("lse",    sqrt(st_matrix("e(V)")[1, 1]))
    scalar llower = lambda - invnormal(0.975) * lse
    scalar lupper = lambda + invnormal(0.975) * lse

    clear
    mata st_numscalar("nobs", rows(sim))
    set obs `=scalar(nobs)'

    local vars run affected all
    mata (void) st_addvar(J(1, `:list sizeof vars', st_global("c(type)")), tokens(st_local("vars")))
    mata st_store(., tokens(st_local("vars")), sim)
    gen id = _n

    bys run (id): gen group = _n
    gcollapse affected all, by(group)
    gen affmort = 100 * affected / deadmean
    gen allmort = 100 * all      / deadmean
    order affmort, after(affected)

    mata col    = J(2, 1, .)
    mata order  = 1 \ 3 \ 2 \ 4
    mata sim    = st_data(., "affected affmort all allmort")
    mata supper = st_numscalar("lupper") * sim
    mata slower = st_numscalar("llower") * sim
    mata sim    = st_numscalar("lambda") * (sim[., 1], col, sim[., 2], col, sim[., 3], col, sim[., 4], col)
    mata sim    = sim \ (supper[., 1], slower[., 1], supper[., 2], slower[., 2], supper[., 3], slower[., 3], supper[., 4], slower[., 4])
    mata sim    = sim[order, .]

    mata row1   = (meanshare_output[1, 1], .) \ (meanshare_output[2, 1], meanshare_output[3, 1])
    mata row1   = row1, 100 * row1 :/ st_numscalar("deadmean")
    mata row1   = row1, row1
    mata sim    = row1 \ sim

    mata save_table("${out}/tables/`pre'tables`pct'pct.txt", "counterfactuals", sim)
end


capture mata: mata drop save_table()
capture mata: mata drop _ComputeDiscountedLife()

mata:
void function _ComputeDiscountedLife(
    real scalar delta,
    real scalar maxage,
    real scalar scalepdeath,
    string scalar prefix)
{
    real scalar year, n_j, rows
    real matrix X, X_t, info, PDV
    real vector discounting, pdv_m, pdv_f, sel, selinv, palive_m, palive_f, age
    string vector types, vars

    X    = st_data(., ("year", "demo_age", "lt_male_pd", "lt_female_pd"))
    info = panelsetup(X[., 1], 1)
    PDV  = J(rows(X), 2, .)

    for(year = 1; year <= rows(info); year++) {
        X_t    = panelsubmatrix(X, year, info)[., 2::4]
        n_j    = rows(X_t)
        rows   = min((n_j, (maxage + 1 - X_t[1, 1])))
        sel    = 1::rows
        selinv = rows::1
        age    = X_t[sel, 1]

        palive_m    = exp(runningsum(log(1 :- scalepdeath :* X_t[sel, 2])))
        palive_f    = exp(runningsum(log(1 :- scalepdeath :* X_t[sel, 3])))
        discounting = delta:^age
        pdv_m       = runningsum((discounting :* palive_m)[selinv])[selinv] :/ (delta:^age)
        pdv_f       = runningsum((discounting :* palive_f)[selinv])[selinv] :/ (delta:^age)

        PDV[sel :+ (info[year, 1] - 1), .] = (pdv_m, pdv_f)
    }

    types = J(1, 2, st_global("c(type)"))
    vars  = prefix :+ ("1", "2")
    (void) st_addvar(types, vars)
    (void) st_store(., vars, PDV)
}

void function save_table(
    string scalar output,
    string scalar tag,
    real matrix M)
{
    real scalar i, j, fh
    string scalar fmt

    fmt = "\t%21.9f"
    fh  = fopen(output, "a")
    fwrite(fh, sprintf("<tab:%s>\n", tag))
    for(i = 1; i <= rows(M); i++) {
        for(j = 1; j <= cols(M); j++) {
            fwrite(fh, sprintf(fmt, M[i, j]))
        }
        fwrite(fh, sprintf("\n"))
    }
    fclose(fh)
}
end

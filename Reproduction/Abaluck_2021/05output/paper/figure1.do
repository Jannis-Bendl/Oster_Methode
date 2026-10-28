* e.g. make figure1 PCT="01" PRE="_19" &
local 0: subinstr local 0 ";" ","
syntax, pct(str) pre(str)

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

* Programs
qui do "00common/00preamble.do"
qui do "00common/00material.do"
cap mkdir "${out}/fig"
cap mkdir "${out}/logs"

log using "${out}/logs/`pre'figure1_`pct'pct.log", replace

capture program drop main
program main
    syntax, syear(int) pct(str) pre(str)

    local progname   cms-mortality-code/figure1
    disp  "Program:  `progname'"
    disp  "Start:    $S_TIME $S_DATE"
    local start_time $S_TIME $S_DATE

	capture noisily {
        make_figure1, syear(`syear') pct(`pct') pre(`pre')
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

capture program drop make_figure1
program make_figure1
    syntax, syear(int) pct(str) pre(str) [fesuf(str) level(str)] [CAPture NOIsily]

    * sanity check
    display `"This is syear: `syear'"'
    display `"This is pct: `pct'"'
    display `"This is pre: `pre'"'

    if "`fesuf'" == ""  local fesuf  CYB
    if "`level'" == ""  local level  plan

    di "syntax for make_figure1 passed"
    local varsuf mle`fesuf'`=proper(`"`level'"')'
    local mu     mucbin_`varsuf'
    local mu_noc mucnocbin_`varsuf'

    use `"${data}/`pre'ivSample`pct'_full.dta"', clear

    * The variance is V(E[mu | b]) + E[V(mu | b)], where E[mu | b] is
    * average mortality, and V(mu | b) we get from the regressions.
    * For the first term:

    gegen mean_mort = mean(died_365) if !mi(bin_num), by(bin_num)
    sum mean_mort if !mi(bin_num)
    scalar var_binned_mean_mort = `r(Var)'

    * The analysis sample, which is what is used for Table 1 columns (2)
    * to (4) as well, is given by
    *
    *     true_mMA2_lag == 1 & year >= 2008 & !mi(bin_num)
    *
    * However, here there is no subset by year.
display "done with full dataset, moving on to estimation sample."

    use `"${data}/`pre'ivSample`pct'.dta"', clear
    glevelsof bin_num, loc(bins) silent
    keep if true_mMA2 == 1 & !mi(bin_num)

    * --------
    * Variance
    * --------

    * For the second term:

    cap frame drop var
    frame create var
    frame change var

    clear
    set obs `:list sizeof bins'
    qui {
    gen var             = .
    gen bene_year_count = .
    gen plan_count      = .
    gen bin             = .
    foreach var of varlist * {
        gen `var'_noc = .
    }
    }

    forvalues j = 1 / `:list sizeof bins' {
    local bin_count: word `j' of `bins'
    local varsuf mle`fesuf'`bin_count'`=proper(`"`level'"')'
    cap noi estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`varsuf'"'
    if ( _rc == 601 & `pct' < 100 ) {
        disp as txt "(note: skipping bin `bin_count' in `pct' sample)"
        continue
    }
    else if ( _rc ) {
        error _rc
    }
    xtreg

    replace var             = (e(sigma_u))^2 in `j'
    replace bene_year_count = e(N)           in `j'
    replace plan_count      = e(N_g)         in `j'
    replace bin             = `bin_count'    in `j'

    if (`"`fesuf'"' == "CYB") {
        local varsuf mle`fesuf'`bin_count'`=proper(`"`level'"')'
        estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pct`varsuf'_noc"'
        xtreg

        replace var_noc             = (e(sigma_u))^2 in `j'
        replace bene_year_count_noc = e(N)           in `j'
        replace plan_count_noc      = e(N_g)         in `j'
        replace bin_noc             = `bin_count'    in `j'
    }
    }

    if (`"`fesuf'"' == "CYB") {
        assert bin             == bin_noc
        assert bene_year_count == bene_year_count_noc
        assert plan_count      == plan_count_noc
    }

    gcollapse (mean) var var_noc [fw = bene_year_count]
    * mata: st_numscalar("var_noc", `=var_noc[1]' + var_binned_mean_mort)
    * mata: st_numscalar("var",     `=var[1]'     + var_binned_mean_mort)
    scalar var_noc = var_noc + var_binned_mean_mort
    scalar var     = var     + var_binned_mean_mort

    if (`"`fesuf'"' == "CYBAD") {
        local var_CYBAD     = trim("`:disp %9.3f sqrt(scalar(var))'")
        display `"CYBAD mu (control for age and dual) SD = `var_CYBAD'"'
    }

    * ------------
    * Density plot
    * ------------

    frame change default

    gunique bene_code, by(fe_county_plan) gen(bene_count)

    local vars fe_county_plan pbpid_id cntrct_id ssacounty bene_count bin_num
    gcontract `vars' `mu' `mu_noc', f(beneyr_count)

    * gstats winsor `mu' `mu_noc' [fw = beneyr_count], cuts(1 99) trim replace
    gstats winsor `mu' `mu_noc', cuts(1 99) trim replace

    qui sum `mu' [fw = bene_count], meanonly
    local rec_mean = r(mean)
    qui replace `mu' = `mu' - `rec_mean'
    qui replace `mu_noc' = `mu_noc' - `rec_mean'

    qui sum `mu' [fw = bene_count], meanonly
    local mean = trim("`:disp %9.3f r(mean)'")

    qui sum `mu_noc' [fw = bene_count], meanonly
    local mean_noc = trim("`:disp %9.3f r(mean)'")

    include "04analysis/Parse/FigureOptions.do"

    local opts
    local opts  `opts' ytitle("Density")
    local opts  `opts' xtitle("Observational Mortality")

    local xopts
    local xopts `xopts' fontface("LM Roman 10")
    local xopts `xopts' width(1600px) height(1200px)
    local xopts `xopts' replace

    local legend
    local legend `legend' order(1 `"Without Controls"' 2 `"With Controls"')
    local legend `legend' cols(2) colgap(*6)
    local legend `legend' position(12)

    qui sum `mu', meanonly
    local min = `r(min)'
    local max = `r(max)'

    qui sum `mu_noc', meanonly
    local min = min(`min', `r(min)')
    local max = max(`max', `r(max)')

    local range = `max' - `min'
    local pos1  = `min' + 0.11 * `range'
    local pos2  = `max' - 0.25 * `range'

    local lopts1 lcolor(`"`alColorBadNoTerm'"') lpattern(dash)  lwidth(0.5)
    local lopts2 lcolor(`"`alColorBadTerm'"') lpattern(solid) lwidth(0.5)

    local var_noc = trim("`:disp %9.3f sqrt(scalar(var_noc))'")
    local var     = trim("`:disp %9.3f sqrt(scalar(var))'")

    local text1 text(51 `pos1' `"Mean = `mean_noc'"' `"S.D. = `var_noc'"', size(small))
    local text2 text(51 `pos2' `"Mean = `mean'"'     `"S.D. = `var'"',     size(small))

    local k1 kdensity mucnocbin_mle`fesuf'Plan [fw = bene_count], `lopts1' `text1' bwidth(0.002)
    local k2 kdensity mucbin_mle`fesuf'Plan    [fw = bene_count], `lopts2' `text2' bwidth(0.002)

    twoway (`k1') (`k2'), `opts' legend(`legend')
    graph export `"${out}/fig/`pre'Figure1_`pct'pct.svg"', `xopts'
    graph export `"${out}/fig/`pre'Figure1_`pct'pct.eps"', mag(100) fontface(Times) replace
    
end

main, syear(2008) pct(`pct') pre(`pre')

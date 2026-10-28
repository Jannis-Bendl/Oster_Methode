* ---------------------------------------------------------------------
* Title:   Average Mortality and Mu over TxMedian Groupings, Regression
*          Adjusted (Mimic Structure of IV Regressions)
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Fridasy, 19 February 2021
* Updated: [TBD]
* Purpose: Avearages died_365 and mu over TxMedian Groupings for each pre-
*          and post-period.
* Note:    Runs after Version7.do, which generates the TxMedian groupings.
* ---------------------------------------------------------------------

* Error Checking
*---------------------------------------------------------------------------
qui glevelsof year, loc(years)
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

* Run Regression for Mortality (Died_365) and Mu seperately for above- and below- median
*---------------------------------------------------------------------------
rename (`alpha'_lag `alpha') (mu_lag mu)
* Regression Set Up --------------------------------
local outcomes_mort lag_mortality died_365
local outcomes_mu   mu_lag mu
local fe_reg        fe_county_lag_year year#plantypeFE fe_county#i.plantypeFE i.plantypeFE `bin_var'_lag
local controls      i.plantypeFE#c.frac_plan_county_lag c.frac_plan_county_lag i.fe_age i.fe_sex i.fe_race i.mDual
local cluster_var   fe_county_lag
local if_above_med  if  dum_med == 1
local if_below_med  if  dum_med == 0

cap drop time
gen time = -1
foreach outcome of local outcomes_mort{
    local name "mort"
    replace time = time + 1
    * Above Median
    disp "reghdfe `outcome' i.TxMedian `controls' `if_above_med', absorb(`fe_reg') cluster(`cluster_var')"
    reghdfe `outcome' i.TxMedian `controls' `if_above_med', absorb(`fe_reg') cluster(`cluster_var')

    * Save Coefficients
    gen b_`outcome'_above = .
    cap macro drop coeff
    local coeff b_`outcome'_above

    gen se_`outcome'_above = .
    cap macro drop stderror
    local stderror se_`outcome'_above
    cap drop E_`coeff'*
    replace `coeff' = _b[1.TxMedian] if TxMedian==1
    replace `coeff' = _b[2.TxMedian] if TxMedian==2
    replace `stderror' = _se[2.TxMedian] if TxMedian==2

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_abovemed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
    gen b_`outcome'_tilde = .
    replace b_`outcome'_tilde = `coeff'_tilde `if_above_med'
    tabulate TxMedian `coeff'_tilde

    * Save Standard Errors
    gen se_`outcome'_up = .
    gen se_`outcome'_lo = .
    replace se_`outcome'_up  = `coeff'_tilde + 1.96*`stderror' if TxMedian==2
    replace se_`outcome'_lo  = `coeff'_tilde - 1.96*`stderror' if TxMedian==2

    * Below Median
    disp "reghdfe `outcome' i.TxMedian `controls' `if_below_med', absorb(`fe_reg') cluster(`cluster_var')"
    reghdfe `outcome' i.TxMedian `controls' `if_below_med', absorb(`fe_reg') cluster(`cluster_var')

    * Save Coefficients
    gen b_`outcome'_below = .
    cap macro drop coeff
    local coeff b_`outcome'_below

    gen se_`outcome'_below = .
    cap macro drop stderror
    local stderror se_`outcome'_below
    cap drop E_`coeff'*
    replace `coeff' = _b[3.TxMedian] if TxMedian==3
    replace `coeff' = _b[4.TxMedian] if TxMedian==4
    replace `stderror' = _se[4.TxMedian] if TxMedian==4

    tabulate TxMedian `coeff'

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_belowmed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
    replace b_`outcome'_tilde = `coeff'_tilde `if_below_med'
    tabulate TxMedian `coeff'_tilde

    * Save Standard Errors
    replace se_`outcome'_up  = `coeff'_tilde + 1.96*`stderror' if TxMedian==4
    replace se_`outcome'_lo  = `coeff'_tilde - 1.96*`stderror' if TxMedian==4

    * Save to File
    preserve
    gcollapse (mean) b_`name' = b_`outcome'_tilde (mean) se_`name'_lo = se_`outcome'_lo (mean) se_`name'_up = se_`outcome'_up, by(TxMedian time)
    gisid TxMedian time
    list
    tempfile SummStats_`outcome'
    save `SummStats_`outcome''
    restore
}


cap drop time
gen time = -1
foreach outcome of local outcomes_mu{
    local name "mu"
    replace time = time + 1
    * Above Median
    disp "reghdfe `outcome' i.TxMedian `controls' `if_above_med', absorb(`fe_reg') cluster(`cluster_var')"
    reghdfe `outcome' i.TxMedian `controls' `if_above_med', absorb(`fe_reg') cluster(`cluster_var')

    * Save Coefficients
    gen b_`outcome'_above = .
    cap macro drop coeff
    local coeff b_`outcome'_above

    gen se_`outcome'_above = .
    cap macro drop stderror
    local stderror se_`outcome'_above
    cap drop E_`coeff'*
    replace `coeff' = _b[1.TxMedian] if TxMedian==1
    replace `coeff' = _b[2.TxMedian] if TxMedian==2
    replace `stderror' = _se[2.TxMedian] if TxMedian==2

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_abovemed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
    gen b_`outcome'_tilde = .
    replace b_`outcome'_tilde = `coeff'_tilde `if_above_med'
    tabulate TxMedian `coeff'_tilde

    * Save Standard Errors
    gen se_`outcome'_up = .
    gen se_`outcome'_lo = .
    replace se_`outcome'_up  = `coeff'_tilde + 1.96*`stderror' if TxMedian==2
    replace se_`outcome'_lo  = `coeff'_tilde - 1.96*`stderror' if TxMedian==2

    * Below Median
    disp "reghdfe `outcome' i.TxMedian `controls' `if_below_med', absorb(`fe_reg') cluster(`cluster_var')"
    reghdfe `outcome' i.TxMedian `controls' `if_below_med', absorb(`fe_reg') cluster(`cluster_var')

    * Save Coefficients
    gen b_`outcome'_below = .
    cap macro drop coeff
    local coeff b_`outcome'_below

    gen se_`outcome'_below = .
    cap macro drop stderror
    local stderror se_`outcome'_below
    cap drop E_`coeff'*
    replace `coeff' = _b[3.TxMedian] if TxMedian==3
    replace `coeff' = _b[4.TxMedian] if TxMedian==4
    replace `stderror' = _se[4.TxMedian] if TxMedian==4

    tabulate TxMedian `coeff'

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_belowmed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
    replace b_`outcome'_tilde = `coeff'_tilde `if_below_med'
    tabulate TxMedian `coeff'_tilde

    * Save Standard Errors
    replace se_`outcome'_up  = `coeff'_tilde + 1.96*`stderror' if TxMedian==4
    replace se_`outcome'_lo  = `coeff'_tilde - 1.96*`stderror' if TxMedian==4

    * Save to File
    preserve
    gcollapse (mean) b_`name' = b_`outcome'_tilde (mean) se_`name'_lo = se_`outcome'_lo (mean) se_`name'_up = se_`outcome'_up, by(TxMedian time)
    gisid TxMedian time
    list
    tempfile SummStats_`outcome'
    save `SummStats_`outcome''
    restore
}


* Generate Graphs
*---------------------------------------------------------------------------
preserve
use `SummStats_lag_mortality', clear
append using `SummStats_died_365'
rename time year
list
tempfile plots_mort
save `plots_mort'
restore

preserve
use `SummStats_mu_lag', clear
append using `SummStats_mu'
rename time year
list
tempfile plots_mu
save `plots_mu'
restore

use `plots_mort', clear
merge m:1 TxMedian year using `plots_mu', keep(1 3) nogen
label define period 0 "Before" 1 "After"
label values year period

* Plots
*---------------------------------------------------------------------------
* Plot Legend
local lab1 Nonterminated; Above-Median Observational Mortality
local lab2 Terminated; Above-Median Observational Mortality
local lab3 Nonterminated; Below-Median Observational Mortality
local lab4 Terminated; Below-Median Observational Mortality

* Plot Folder
cap mkdir `"${out}/fig/`plotsTag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/normalized"'
local plots_folder `"${out}/fig/`plotsTag'/`tag'/normalized"'

qui glevelsof year, loc(plotyears)
    forvalues j = 1 / 4 {
        local opts xlabel(`plotyears', labsize(small))

        if ( `j' == 1 ) local opts `opts' lcolor(`"`lColorGoodNoTerm'"')
        if ( `j' == 2 ) local opts `opts' lcolor(`"`lColorGoodTerm'"')
        if ( `j' == 3 ) local opts `opts' lcolor(`"`lColorBadNoTerm'"')
        if ( `j' == 4 ) local opts `opts' lcolor(`"`lColorBadTerm'"')

        if inlist(`j', 1, 3) local opts `opts' lpattern(`lStyleNoTerm')
        if inlist(`j', 2, 4) local opts `opts' lpattern(`lStyleTerm')

        local mu_l`j'   line b_mu   year if TxMedian == `j', `opts' `lopts'
        local mort_l`j' line b_mort year if TxMedian == `j', `opts' `lopts'
    }
    `set_font'
    local mu_ci2   rcap se_mu_up se_mu_lo     year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
    local mu_ci4   rcap se_mu_up se_mu_lo     year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'
    local mort_ci2 rcap se_mort_up se_mort_lo year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
    local mort_ci4 rcap se_mort_up se_mort_lo year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'

    local legend order(1 `"`lab1'"' 2 `"`lab2'"' 3 `"`lab3'"' 4 `"`lab4'"')
    local legend `legend' cols(1) ring(1) position(1) bmargin(small)

    twoway (`mu_l1') (`mu_l2') (`mu_l3') (`mu_l4') (`mu_ci2') (`mu_ci4'), legend(`legend') scheme(burd4) ytitle("Observational Mortality") xtitle("Year Relative to Termination") yscale(range(0.035 0.06)) ylabel(0.035 (0.005) 0.06) xlabel(0 1, valuelabel)
    graph export `plots_folder'/planEffect_normalized.svg, `xopts'
    graph export `plots_folder'/planEffect_normalized.eps, mag(100) fontface(Times) replace

    twoway (`mort_l1') (`mort_l2') (`mort_l3') (`mort_l4') (`mort_ci2') (`mort_ci4'), legend(`legend') scheme(burd4) ytitle("One-Year Mortality") xtitle("Year Relative to Termination") yscale(range(0.035 0.06)) ylabel(0.035 (0.005) 0.06) xlabel(0 1, valuelabel)
    graph export `plots_folder'/mortality_normalized.svg, `xopts'
    graph export `plots_folder'/mortality_normalized.eps, mag(100) fontface(Times) replace

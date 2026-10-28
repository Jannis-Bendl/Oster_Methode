* ---------------------------------------------------------------------
* Title:   Average Mortality and Mu over TxMedian Groupings, Generate Regression
*          Adjusted, Pooled Plots
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Sunday, May 10th 2020
* Updated: Wednesday, 10 February 2021
* Purpose: Avearages died_365 and mu over TxMedian Groupings for each base
*          year and subsequent 1/2 lead years. Creates matrices of averages
*          to be used in plots, and generates pooled, regression-adjusted plots.
* Note:    Runs after Version6.do, which generates the TxMedian groupings.
*
* Depends: >
*          ./00common/00preamble.do
*          ./00common/00material.do
*          ./04analysis/AnalysisConfigurations.do
*          ./04analysis/Parse/CommandLineArgs.do
*          ./04analysis/Preprocessing/SampleSelection6.do
*          ./04analysis/Parse/RegressionOptions.do
*          ./04analysis/Parse/FigureOptions.do
*          ./04analysis/PlotsMerge/Version6.do
*
* Output:  >
*          ${out}/fig/`plotsTag'/`tag'/normalized/pooled/planEffect_lead`lead'_normalized.svg
*          ${out}/fig/`plotsTag'/`tag'/normalized/pooled/mortality_lead`lead'_normalized.svg
* ---------------------------------------------------------------------

* Error Checking
*---------------------------------------------------------------------------
preserve
qui glevelsof year, loc(years)
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

* Generate Variables for Pooled Plots
*---------------------------------------------------------------------------
foreach refYear of local years {
    forvalues lead = 0 / 2 {
        local pool_vars TxMedian dum_med fe_year_state_county fe_age fe_sex fe_race mDual fe_year_plantype fe_county_plantype plantypeFE_contemp frac_plan_county fe_county `bin_var'

        foreach pool_var of local pool_vars{
            cap confirm variable `pool_var'`refYear'
            if (_rc) continue

            cap confirm variable `pool_var'_lead`lead'
            if (_rc) gen `pool_var'_lead`lead' = .
            qui bysort bene_code (year `pool_var'`refYear'): replace `pool_var'_lead`lead' = `pool_var'`refYear' if year==`refYear'+`lead' & !mi(`pool_var'`refYear')
        }
    }
}


* Run Regression for Mortality (Died_365) and Mu seperately for above- and below- median
*---------------------------------------------------------------------------
forvalues lead = 0 / 2 {
* Error Checking -------------
    local TxMedian TxMedian_lead`lead'
    cap confirm variable `TxMedian'
    if (_rc) continue

* Regression Set Up --------------------------------
    local fe_reg        fe_year_state_county_lead`lead' fe_year_plantype_lead`lead' fe_county_plantype_lead`lead' i.plantypeFE_contemp_lead`lead' `bin_var'_lead`lead'
    local indepvars     i.plantypeFE_contemp_lead`lead'#c.frac_plan_county_lead`lead' c.frac_plan_county_lead`lead' 
    local cluster_var   fe_county_lead`lead'

    local if_above_med  if  dum_med_lead`lead' == 1
    local if_below_med  if  dum_med_lead`lead' == 0

* Died_365 ---------------------------------------
    cap macro drop outcome
    local outcome died_365
    cap drop E_`outcome'*

    * Above Median ---------------------------------------
    * Run Regression
    di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')"
    reghdfe `outcome' i.`TxMedian' `indepvars' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')

    * Save Coefficients
    cap confirm variable b_mort_abovemed_lead`lead'
    if (_rc) gen b_mort_abovemed_lead`lead' = .
    cap macro drop coeff
    local coeff b_mort_abovemed_lead`lead'

    cap confirm variable se_mort_abovemed_lead`lead'
    if (_rc) gen se_mort_abovemed_lead`lead' = .
    cap macro drop stderror
    local stderror se_mort_abovemed_lead`lead'
    cap drop E_`coeff'*
    replace `coeff' = _b[1.TxMedian] if `TxMedian'==1
    replace `coeff' = _b[2.TxMedian] if `TxMedian'==2
    replace `stderror' = _se[2.TxMedian] if `TxMedian'==2

    tabulate `TxMedian' `coeff'

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_abovemed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
    cap confirm variable b_mort_lead`lead'_tilde
    if (_rc) gen b_mort_lead`lead'_tilde = .
    replace b_mort_lead`lead'_tilde = `coeff'_tilde `if_above_med'
    tabulate `TxMedian' `coeff'_tilde

    * Save Standard Errors
    cap confirm variable se_mort_lead`lead'_up
    if (_rc) gen se_mort_lead`lead'_up = .
    cap confirm variable se_mort_lead`lead'_lo
    if (_rc) gen se_mort_lead`lead'_lo = .
    replace se_mort_lead`lead'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==2
    replace se_mort_lead`lead'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==2


    * Below Median ---------------------------------------
    * Run Regression
    di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')"
    reghdfe `outcome' i.`TxMedian' `indepvars' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')

    * Save Coefficients
    cap confirm variable b_mort_belowmed_lead`lead'
    if (_rc) gen b_mort_belowmed_lead`lead' = .
    cap macro drop coeff
    local coeff b_mort_belowmed_lead`lead'

    cap confirm variable se_mort_belowmed_lead`lead'
    if (_rc) gen se_mort_belowmed_lead`lead' = .
    cap macro drop stderror
    local stderror se_mort_belowmed_lead`lead'
    cap drop E_`coeff'*
    replace `coeff'    = _b[3.TxMedian] if `TxMedian'==3
    replace `coeff'    = _b[4.TxMedian] if `TxMedian'==4
    replace `stderror' = _se[4.TxMedian] if `TxMedian'==4

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_belowmed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
    cap confirm variable b_mort_lead`lead'_tilde
    if (_rc) gen b_mort_lead`lead'_tilde = .
    replace b_mort_lead`lead'_tilde = `coeff'_tilde `if_below_med'
    tabulate `TxMedian' `coeff'_tilde

    * Save Standard Errors
    cap confirm variable se_mort_lead`lead'_up
    if (_rc) gen se_mort_lead`lead'_up = .
    cap confirm variable se_mort_lead`lead'_lo
    if (_rc) gen se_mort_lead`lead'_lo = .
    replace se_mort_lead`lead'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==4
    replace se_mort_lead`lead'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==4

* Mu ---------------------------------------
    cap macro drop outcome
    local outcome `alpha'
    cap drop E_`outcome'*

    * Above Median ---------------------------------------
    * Run Regression
    di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')"
    reghdfe `outcome' i.`TxMedian' `indepvars' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')

    * Save Coefficients
    cap confirm variable b_mu_abovemed_lead`lead'
    if (_rc) gen b_mu_abovemed_lead`lead' = .
    cap macro drop coeff
    local coeff b_mu_abovemed_lead`lead'

    cap confirm variable se_mu_abovemed_lead`lead'
    if (_rc) gen se_mu_abovemed_lead`lead' = .
    cap macro drop stderror
    local stderror se_mu_abovemed_lead`lead'
    cap drop E_`coeff'*
    replace `coeff' = _b[1.TxMedian] if `TxMedian'==1
    replace `coeff' = _b[2.TxMedian] if `TxMedian'==2
    replace `stderror' = _se[2.TxMedian] if `TxMedian'==2

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_abovemed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
    cap confirm variable b_mu_lead`lead'_tilde
    if (_rc) gen b_mu_lead`lead'_tilde = .
    replace b_mu_lead`lead'_tilde = `coeff'_tilde `if_above_med'
    tabulate `TxMedian' `coeff'_tilde

    * Save Standard Errors
    cap confirm variable se_mu_lead`lead'_up
    if (_rc) gen se_mu_lead`lead'_up = .
    cap confirm variable se_mu_lead`lead'_lo
    if (_rc) gen se_mu_lead`lead'_lo = .
    replace se_mu_lead`lead'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==2
    replace se_mu_lead`lead'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==2

    * Below Median ---------------------------------------
    * Run Regression
    di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')"
    reghdfe `outcome' i.`TxMedian' `indepvars' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')

    * Save Coefficients
    cap confirm variable b_mu_belowmed_lead`lead'
    if (_rc) gen b_mu_belowmed_lead`lead' = .
    cap macro drop coeff
    local coeff b_mu_belowmed_lead`lead'

    cap confirm variable se_mu_belowmed_lead`lead'
    if (_rc) gen se_mu_belowmed_lead`lead' = .
    cap macro drop stderror
    local stderror se_mu_belowmed_lead`lead'
    cap drop E_`coeff'*
    replace `coeff' = _b[3.TxMedian] if `TxMedian'==3
    replace `coeff' = _b[4.TxMedian] if `TxMedian'==4
    replace `stderror' = _se[4.TxMedian] if `TxMedian'==4

    * Normalization
    gegen E_`coeff'             = mean(`coeff')
    gegen E_`outcome'_belowmed  = mean(`outcome') if !missing(`coeff')
    gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
    cap confirm variable b_mu_lead`lead'_tilde
    if (_rc) gen b_mu_lead`lead'_tilde = .
    replace b_mu_lead`lead'_tilde = `coeff'_tilde `if_below_med'
    tabulate `TxMedian' `coeff'_tilde

    * Save Standard Errors
    cap confirm variable se_mu_lead`lead'_up
    if (_rc) gen se_mu_lead`lead'_up = .
    cap confirm variable se_mu_lead`lead'_lo
    if (_rc) gen se_mu_lead`lead'_lo = .
    replace se_mu_lead`lead'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==4
    replace se_mu_lead`lead'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==4
}

* Average over TxMedian Groupings
*---------------------------------------------------------------------------
forvalues lead = 0 / 2 {
    local opts by(TxMedian_lead`lead') s(mean) nomissing mata(M)
    gstats tab b_mu_lead`lead'_tilde se_mu_lead`lead'_up se_mu_lead`lead'_lo b_mort_lead`lead'_tilde se_mort_lead`lead'_up se_mort_lead`lead'_lo, `opts' columns(var)
    mata MLead`lead'  = M.numx, M.output
    mata MLead = `lead' \ `lead' \ `lead' \ `lead'
    mata MLead`lead' = MLead,MLead`lead'
    mata: MLead`lead'
}


* Create Matrices for Plots
*---------------------------------------------------------------------------
mata Mpooled1 = MLead0 \ MLead1
mata: Mpooled1

mata Mpooled2 = MLead0 \ MLead1 \ MLead2
mata: Mpooled2

* Add labels to matrices
forvalues j = 1 / 4 {
    local lab`j': label TxMedian `j'
}

* Create Plots
*---------------------------------------------------------------------------
cap mkdir `"${out}/fig/`plotsTag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/normalized"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/normalized/pooled"'
local plots_folder `"${out}/fig/`plotsTag'/`tag'/normalized/pooled/"'
forvalues lead = 1 / 2 {
    capture mata: mata describe Mpooled`lead'
    if (_rc) continue
    clear

    * Create Stata Dataset of Plots Averages
    mata stata(sprintf("set obs %g", rows(Mpooled`lead')))
    mata _addTypes = ("long", "byte", "double", "double" , "double", "double" , "double", "double")
    mata _addNames = ("year", "TxMedian", "`alpha'", "`alpha'_se_upper","`alpha'_se_lower", "mortality", "mortality_se_upper", "mortality_se_lower")
    mata (void) st_addvar(_addTypes, _addNames)
    mata st_store(., _addNames, Mpooled`lead')

    qui glevelsof year, loc(plotyears)
    forvalues j = 1 / 4 {
        local opts xlabel(`plotyears', labsize(small))

        if ( `j' == 1 ) local opts `opts' lcolor(`"`lColorGoodNoTerm'"')
        if ( `j' == 2 ) local opts `opts' lcolor(`"`lColorGoodTerm'"')
        if ( `j' == 3 ) local opts `opts' lcolor(`"`lColorBadNoTerm'"')
        if ( `j' == 4 ) local opts `opts' lcolor(`"`lColorBadTerm'"')

        if inlist(`j', 1, 3) local opts `opts' lpattern(`lStyleNoTerm')
        if inlist(`j', 2, 4) local opts `opts' lpattern(`lStyleTerm')

        local ul`j' line `alpha'   year if TxMedian == `j', `opts' `lopts'
        local ml`j' line mortality year if TxMedian == `j', `opts' `lopts'
    }
    `set_font'
    local us2 rcap `alpha'_se_upper    `alpha'_se_lower    year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
    local us4 rcap `alpha'_se_upper    `alpha'_se_lower    year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'
    local ms2 rcap  mortality_se_upper  mortality_se_lower year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
    local ms4 rcap  mortality_se_upper  mortality_se_lower year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'


    local legend order(1 `"`lab1'"' 2 `"`lab2'"' 3 `"`lab3'"' 4 `"`lab4'"')
    local legend `legend' cols(1) ring(1) position(1) bmargin(small)

    twoway (`ul1') (`ul2') (`ul3') (`ul4') (`us2') (`us4'), legend(`legend') scheme(burd4) ytitle("Observational Mortality") xtitle("Year Relative to Termination")
    graph export `plots_folder'/planEffect_lead`lead'_normalized.svg, `xopts'

    twoway (`ml1') (`ml2') (`ml3') (`ml4') (`ms2') (`ms4'), legend(`legend') scheme(burd4) ytitle("One-Year Mortality") xtitle("Year Relative to Termination")
    graph export `plots_folder'/mortality_lead`lead'_normalized.svg, `xopts'
}
restore

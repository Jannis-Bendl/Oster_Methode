* ---------------------------------------------------------------------
* Title:   Average Mortality and Mu over TxMedian Groupings, Generate Regression
*          Adjusted, Yearly Plots
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Wednesday, April 22th 2020
* Updated: Wednesday, 10 February 2021
* Purpose: Avearages died_365 and mu over TxMedian Groupings for each base
*          year and subsequent 1/2 lead years. Creates matrices of averages
*          to be used in plots, and generates yearly, regression-adjusted plots.
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
*          ${out}/fig/`plotsTag'/`tag'/`normalized'/`refYear'/planEffect_lead`lead'_normalized.svg
*          ${out}/fig/`plotsTag'/`tag'/`normalized'/`refYear'/mortality_lead`lead'_normalized.svg
* ---------------------------------------------------------------------

* Error Checking
*---------------------------------------------------------------------------
preserve
qui glevelsof year, loc(years)
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

* Run Regression for Mortality (Died_365) and Mu seperately for above- and below- median
*---------------------------------------------------------------------------
summarize year, meanonly
local max_year = r(max)

foreach refYear of local years {
    forvalues lead = 0 / 2 {
    * Error Checking -------------
        if (`refYear' == `max_year') | (`refYear' + `lead' > `max_year') {
            continue, break
        }

        local TxMedian TxMedian`refYear' 
        cap confirm variable `TxMedian'
        if (_rc) continue

    * Regression Set Up --------------------------------
        local if_year       if  year == `=`refYear'+`lead''
        local if_above_med  &  dum_med`refYear' == 1
        local if_below_med  &  dum_med`refYear' == 0
        local fe_reg        fe_year_state_county`refYear' fe_year_plantype`refYear' fe_county_plantype`refYear' i.plantypeFE_contemp`refYear' `bin_var'`refYear'
        local indepvars     i.plantypeFE_contemp`refYear'#c.frac_plan_county`refYear' c.frac_plan_county`refYear' 
        local cluster_var   fe_county`refYear'

    * Died_365 ---------------------------------------
        cap macro drop outcome
        local outcome died_365
        cap drop E_`outcome'*
    * Above Median ---------------------------------------
        * Run Regression
        di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')"
        reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')

        * Save Coefficients
        cap confirm variable b_mort_abovemed_`refYear'_lead`lead'
        if (_rc) gen b_mort_abovemed_`refYear'_lead`lead' = .
        cap macro drop coeff
        local coeff b_mort_abovemed_`refYear'_lead`lead'

        cap confirm variable se_mort_abovemed_`refYear'_lead`lead'
        if (_rc) gen se_mort_abovemed_`refYear'_lead`lead' = .
        cap macro drop stderror
        local stderror se_mort_abovemed_`refYear'_lead`lead'
        cap drop E_`coeff'*
        replace `coeff'    = _b[1.TxMedian] if `TxMedian'==1
        replace `coeff'    = _b[2.TxMedian] if `TxMedian'==2
        replace `stderror' = _se[2.TxMedian] if `TxMedian'==2

        * Normalization
        gegen E_`coeff'             = mean(`coeff')
        gegen E_`outcome'_abovemed  = mean(`outcome') if !missing(`coeff')
        gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
        tabulate `TxMedian' `coeff'_tilde

        * Save Standard Errors
        gen `stderror'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==2
        gen `stderror'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==2


    * Below Median ---------------------------------------
        * Run Regression
        di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')"
        reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')

        * Save Coefficients
        cap confirm variable b_mort_belowmed_`refYear'_lead`lead'
        if (_rc) gen b_mort_belowmed_`refYear'_lead`lead' = .
        cap macro drop coeff
        local coeff b_mort_belowmed_`refYear'_lead`lead'

        cap confirm variable se_mort_belowmed_`refYear'_lead`lead'
        if (_rc) gen se_mort_belowmed_`refYear'_lead`lead' = .
        cap macro drop stderror
        local stderror se_mort_belowmed_`refYear'_lead`lead'
        cap drop E_`coeff'*
        replace `coeff'    = _b[3.TxMedian] if `TxMedian'==3
        replace `coeff'    = _b[4.TxMedian] if `TxMedian'==4
        replace `stderror' = _se[4.TxMedian] if `TxMedian'==4

        * Normalization
        gegen E_`coeff'             = mean(`coeff')
        gegen E_`outcome'_belowmed = mean(`outcome') if !missing(`coeff')
        gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
        tabulate `TxMedian' `coeff'_tilde

        * Save Standard Errors
        gen `stderror'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==4
        gen `stderror'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==4

    * Mu ---------------------------------------
        cap macro drop outcome
        local outcome `alpha'
        cap drop E_`outcome'*

    * Above Median ---------------------------------------
        * Run Regression
        di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')"
        reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_above_med', absorb(`fe_reg') vce(cluster `cluster_var')

        * Save Coefficients
        cap confirm variable b_mu_abovemed_`refYear'_lead`lead'
        if (_rc) gen b_mu_abovemed_`refYear'_lead`lead' = .
        cap macro drop coeff
        local coeff b_mu_abovemed_`refYear'_lead`lead'
        cap confirm variable se_mu_abovemed_`refYear'_lead`lead'
        if (_rc) gen se_mu_abovemed_`refYear'_lead`lead' = .
        cap macro drop stderror
        local stderror se_mu_abovemed_`refYear'_lead`lead'
        cap drop E_`coeff'*
        replace `coeff'    = _b[1.TxMedian] if `TxMedian'==1
        replace `coeff'    = _b[2.TxMedian] if `TxMedian'==2
        replace `stderror' = _se[2.TxMedian] if `TxMedian'==2

        * Normalization
        gegen E_`coeff'             = mean(`coeff')
        gegen E_`outcome'_abovemed = mean(`outcome') if !missing(`coeff')
        gen `coeff'_tilde           = `coeff' + E_`outcome'_abovemed - E_`coeff'
        tabulate `TxMedian' `coeff'_tilde
        * Save Standard Errors
        gen `stderror'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==2
        gen `stderror'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==2

    * Below Median ---------------------------------------
        * Run Regression
        di "reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')"
        reghdfe `outcome' i.`TxMedian' `indepvars' `if_year' `if_below_med', absorb(`fe_reg') vce(cluster `cluster_var')

        * Save Coefficients
        cap confirm variable b_mu_belowmed_`refYear'_lead`lead'
        if (_rc) gen b_mu_belowmed_`refYear'_lead`lead' = .
        cap macro drop coeff
        local coeff b_mu_belowmed_`refYear'_lead`lead'
        cap confirm variable se_mu_belowmed_`refYear'_lead`lead'
        if (_rc) gen se_mu_belowmed_`refYear'_lead`lead' = .
        cap macro drop stderror
        local stderror se_mu_belowmed_`refYear'_lead`lead'
        cap drop E_`coeff'*
        replace `coeff'    = _b[3.TxMedian] if `TxMedian'==3
        replace `coeff'    = _b[4.TxMedian] if `TxMedian'==4
        replace `stderror' = _se[4.TxMedian] if `TxMedian'==4

        * Normalization
        gegen E_`coeff'             = mean(`coeff')
        gegen E_`outcome'_belowmed = mean(`outcome') if !missing(`coeff')
        gen `coeff'_tilde           = `coeff' + E_`outcome'_belowmed - E_`coeff'
        tabulate `TxMedian' `coeff'_tilde
        * Save Standard Errors
        gen `stderror'_up  = `coeff'_tilde + 1.96*`stderror' if `TxMedian'==4
        gen `stderror'_lo  = `coeff'_tilde - 1.96*`stderror' if `TxMedian'==4

       * Aggregate Betas into One Variable --------------------------------
        cap confirm variable beta_mort_`refYear'
        if (_rc) gen beta_mort_`refYear' = .
        cap confirm variable se_mort_`refYear'_up
        if (_rc) gen se_mort_`refYear'_up = .
        cap confirm variable se_mort_`refYear'_lo
        if (_rc) gen se_mort_`refYear'_lo = .
        bysort bene_code (year): replace beta_mort_`refYear'    = b_mort_abovemed_`refYear'_lead`lead'_tilde `if_year' & !mi(b_mort_abovemed_`refYear'_lead`lead'_tilde)
        bysort bene_code (year): replace beta_mort_`refYear'    = b_mort_belowmed_`refYear'_lead`lead'_tilde `if_year' & !mi(b_mort_belowmed_`refYear'_lead`lead'_tilde)
        bysort bene_code (year): replace se_mort_`refYear'_up   = se_mort_abovemed_`refYear'_lead`lead'_up   `if_year' & !mi(se_mort_abovemed_`refYear'_lead`lead'_up)
        bysort bene_code (year): replace se_mort_`refYear'_up   = se_mort_belowmed_`refYear'_lead`lead'_up   `if_year' & !mi(se_mort_belowmed_`refYear'_lead`lead'_up)
        bysort bene_code (year): replace se_mort_`refYear'_lo   = se_mort_abovemed_`refYear'_lead`lead'_lo   `if_year' & !mi(se_mort_abovemed_`refYear'_lead`lead'_lo)
        bysort bene_code (year): replace se_mort_`refYear'_lo   = se_mort_belowmed_`refYear'_lead`lead'_lo   `if_year' & !mi(se_mort_belowmed_`refYear'_lead`lead'_lo)

        cap confirm variable beta_mu_`refYear'
        if (_rc) gen beta_mu_`refYear' = .
        cap confirm variable se_mu_`refYear'_up
        if (_rc) gen se_mu_`refYear'_up = .
        cap confirm variable se_mu_`refYear'_lo
        if (_rc) gen se_mu_`refYear'_lo = .
        bysort bene_code (year): replace beta_mu_`refYear'   = b_mu_abovemed_`refYear'_lead`lead'_tilde  `if_year' & !mi(b_mu_abovemed_`refYear'_lead`lead'_tilde)
        bysort bene_code (year): replace beta_mu_`refYear'   = b_mu_belowmed_`refYear'_lead`lead'_tilde  `if_year' & !mi(b_mu_belowmed_`refYear'_lead`lead'_tilde)
        bysort bene_code (year): replace se_mu_`refYear'_up  = se_mu_abovemed_`refYear'_lead`lead'_up     `if_year' & !mi(se_mu_abovemed_`refYear'_lead`lead'_up)
        bysort bene_code (year): replace se_mu_`refYear'_up  = se_mu_belowmed_`refYear'_lead`lead'_up     `if_year' & !mi(se_mu_belowmed_`refYear'_lead`lead'_up)
        bysort bene_code (year): replace se_mu_`refYear'_lo  = se_mu_abovemed_`refYear'_lead`lead'_lo     `if_year' & !mi(se_mu_abovemed_`refYear'_lead`lead'_lo)
        bysort bene_code (year): replace se_mu_`refYear'_lo  = se_mu_belowmed_`refYear'_lead`lead'_lo     `if_year' & !mi(se_mu_belowmed_`refYear'_lead`lead'_lo)

    }
}

* Average over TxMedian Groupings, Create Matrices for Plots
*---------------------------------------------------------------------------
foreach refYear of local years {
    forvalues lead = 1 / 2 {
        if (`refYear' == `max_year') | (`refYear' + `lead' > `max_year') {
            continue, break
        }

        local if   if year >= `=`refYear'' & year <= `=`refYear'+`lead''
        local opts by(year TxMedian`refYear') s(mean) nomissing mata(M)
        gstats tab beta_mu_`refYear' se_mu_`refYear'_up se_mu_`refYear'_lo beta_mort_`refYear' se_mort_`refYear'_up se_mort_`refYear'_lo `if', `opts' columns(var)
        mata M`refYear'Lead`lead' = M.numx, M.output
    }
}

* Add labels to matrices
forvalues j = 1 / 4 {
    local lab`j': label TxMedian `j'
}

* Create Plots
*---------------------------------------------------------------------------
cap mkdir `"${out}/fig/`plotsTag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/normalized"'
foreach refYear of local years {
    if (`refYear' == `max_year') {
            continue, break
    }
    cap mkdir `"${out}/fig/`plotsTag'/`tag'/normalized/`refYear'"'
    local plots_folder `"${out}/fig/`plotsTag'/`tag'/normalized/`refYear'"'
    forvalues lead = 1 / 2 {
        capture mata mata describe M`refYear'Lead`lead'
        if (_rc) continue
        clear

        * Create Stata Dataset of Plots Averages
        mata stata(sprintf("set obs %g", rows(M`refYear'Lead`lead')))
        mata _addTypes = ("long", "byte", "double", "double", "double", "double", "double" , "double")
        mata _addNames = ("year", "TxMedian", "`alpha'", "`alpha'_se_upper","`alpha'_se_lower", "mortality", "mortality_se_upper", "mortality_se_lower")
        mata (void) st_addvar(_addTypes, _addNames)
        mata st_store(., _addNames, M`refYear'Lead`lead')

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

        local us2 rcap `alpha'_se_upper    `alpha'_se_lower    year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
        local us4 rcap `alpha'_se_upper    `alpha'_se_lower    year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'
        local ms2 rcap  mortality_se_upper  mortality_se_lower year if TxMedian == 2, lcolor(`"`lColorGoodTerm'"') lpattern(`lStyleTerm') `lopts'
        local ms4 rcap  mortality_se_upper  mortality_se_lower year if TxMedian == 4, lcolor(`"`lColorBadTerm'"')  lpattern(`lStyleTerm') `lopts'


        local legend order(1 `"`lab1'"' 2 `"`lab2'"' 3 `"`lab3'"' 4 `"`lab4'"')
        local legend `legend' cols(1) ring(1) position(1) bmargin(small)

        twoway (`ul1') (`ul2') (`ul3') (`ul4') (`us2') (`us4'), legend(`legend') scheme(burd4) ytitle("Observational Mortality") xtitle("Year")
        graph export `plots_folder'/planEffect_lead`lead'_normalized.svg, `xopts'

        twoway (`ml1') (`ml2') (`ml3') (`ml4') (`ms2') (`ms4'), legend(`legend') scheme(burd4) ytitle("One-Year Mortality") xtitle("Year")
        graph export `plots_folder'/mortality_lead`lead'_normalized.svg, `xopts'
    }
}
restore

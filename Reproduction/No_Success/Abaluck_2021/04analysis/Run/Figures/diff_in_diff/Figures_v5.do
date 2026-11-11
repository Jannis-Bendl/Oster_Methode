* ---------------------------------------------------------------------
* Title:   Average Mortality and Mu over TxMedian Groupings, Generate Plots
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Wednesday, April 22th 2020
* Updated: Friday, May 8th 2020
* Purpose: Avearages died_365 and mu over TxMedian Groupings for each base
*          year and subsequent 1/2 lead years. Creates matrices of averages
*          to be used in plots, and generates plots.
* Note:    Runs after Version5.do, which generates the TxMedian groupings.
*
* Depends: >
*          ./00common/00preamble.do
*          ./00common/00material.do
*          ./04analysis/AnalysisConfigurations.do
*          ./04analysis/Parse/CommandLineArgs.do
*          ./04analysis/Preprocessing/SampleSelection6.do
*          ./04analysis/Parse/RegressionOptions.do
*          ./04analysis/Parse/FigureOptions.do
*          ./04analysis/PlotsMerge/Version5.do
*
* Output:  >
*          ${out}/fig/`plotsTag'/`tag'/`refYear'/planEffectLead`lead'.svg
*          ${out}/fig/`plotsTag'/`tag'/`refYear'/mortalityLead`lead'.svg
* ---------------------------------------------------------------------

* Error Checking
*---------------------------------------------------------------------------
preserve
qui glevelsof year, loc(years)
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

summarize year, meanonly
local max_year = r(max)

* Average over TxMedian Groupings, Create Matrics for Plots
*---------------------------------------------------------------------------
foreach refYear of local years {
    forvalues lead = 1 / 2 {
        if (`refYear'+`lead' > `max_year') | (`refYear' == `max_year'){
            continue,break
        }

        local TxMedian TxMedian`refYear'
        cap confirm variable `TxMedian'
        if (_rc) continue

        local if   if year >= `=`refYear'' & year <= `=`refYear'+`lead''
        local opts by(year `TxMedian') s(mean) nomissing mata(M)
        gstats tab `alpha' died_365 `if', `opts' columns(var)
        mata M`refYear'Lead`lead'  = M.numx, M.output
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
cap mkdir `"${out}/fig/`plotsTag'/`tag'/avg"'
foreach refYear of local years {
    if (`refYear' == `max_year') {
            continue, break
    }
    cap mkdir `"${out}/fig/`plotsTag'/`tag'/avg/`refYear'"'
    local plots_folder `"${out}/fig/`plotsTag'/`tag'/avg/`refYear'"'
    forvalues lead = 1 / 2 {
        capture mata: mata describe M`refYear'Lead`lead'
        if (_rc) continue
        clear

        * Create Stata Dataset of Plots Averages
        mata stata(sprintf("set obs %g", rows(M`refYear'Lead`lead')))
        mata _addTypes = ("long", "byte", "double", "double")
        mata _addNames = ("year", "TxMedian", "`alpha'", "mortality")
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

        local legend order(1 `"`lab1'"' 2 `"`lab2'"' 3 `"`lab3'"' 4 `"`lab4'"')
        local legend `legend' cols(1) ring(1) position(1) bmargin(small)

        twoway (`ul1') (`ul2') (`ul3') (`ul4'), legend(`legend') scheme(burd4) ytitle("Plan-Level Observational Mortality") xtitle("Year")
        graph export `plots_folder'/planEffectLead`lead'.svg, `xopts'

        twoway (`ml1') (`ml2') (`ml3') (`ml4'), legend(`legend') scheme(burd4) ytitle("Individual Mortality") xtitle("Year")
        graph export `plots_folder'/mortalityLead`lead'.svg, `xopts'
    }
}
restore

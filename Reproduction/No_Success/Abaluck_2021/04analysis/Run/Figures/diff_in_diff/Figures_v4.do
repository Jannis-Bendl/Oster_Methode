/*
 * DOC: There are some subtleties when it comes to connecting the plots
 * and the regressions in PlotsMerge/Version6.do (current default):
 *
 * 1. We define above/below median at year T using alphas from year T - 1
 *     - These alphas include the alphas from terminated plans
 *       (because their benes are still in year T).
 *     - The above/below median uses a beneficiary-weighted median
 *
 * 2. The weights uses the number of _surviving_ beneficiaries
 *     - If plans had disproportionately more people die, their alphas
 *       would count less towards the above/below median definition
 *     - _Every_ beneficiary in that plan would get assigned an
 *       above/below median value in the year prior
 *     - NOTE: One exception is the lag_county_median option, which uses
 *        weights from T - 1, but still merges onto year T.
 *
 * 3. If every beneficiary in a terminated plan died, then that plan
 *    would get dropped from the plots altogether.
 *
 * 4. If we require in the regressions that a condition be true for T -
 *    1, because the regressions only look at data at time T with T - 1
 *    variables (i.e. 1 year of data with columns for lags) then we are
 *    fine. However, the plots actually do look at data over time. Hence
 *    if we require a condition for a lag variable (e.g. true_mMA_lag ==
 *    1) then for the plots we are in effect requiring that be true of
 *    _every_ year.
 *
 * 5. If we load 1 year of regression data, the plots canot be made (they
 *    need 2+ years of data)
 *
 */

qui glevelsof year, loc(years)
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

* Test Statement
*---------------------------------------------------------------------------
foreach refYear of local years {
    forvalues lead = 1 / 2 {
        local if   if year >= `=`refYear'' & year <= `=`refYear'+`lead''

        * mean by year of the 4 groups
        *local TxMedian TxMedian`refYear'Lead`lead'

        local TxMedian TxMedian`refYear'
        *display "TxMedian`refYear'Lead`lead'"
        *tab TxMedian`refYear'Lead`lead', missing
        cap confirm variable `TxMedian'
        if (_rc) continue

        *local opts by(`TxMedian') s(mean) nomissing mata(M)
        *local opts by(year `TxMedian') s(mean) nomissing mata(M)
        gstats tab `alpha' died_365 `if', by(year `TxMedian') s(mean) nomissing mata(M) columns(var)
        mata M`refYear'Lead`lead'  = M.numx, M.output
        *mata M.printOutput()
        *mata: M`refYear'Lead`lead'
    }
}

/*
gen lead = 1
foreach refYear of local years {
       local if   if year <= `=`refYear'+`lead'' & year >= `=`refYear'' 

        * mean by year of the 4 groups
        local TxMedian TxMedian`refYear'Lead`lead' 
        cap confirm variable `TxMedian'
        if (_rc) continue

        local opts by(year `TxMedian') s(mean) nomissing mata(M)
        gstats tab `alpha' died_365 `if', `opts' columns(var)
        mata M`refYear'Lead`lead'  = M.numx, M.output
        *mata M.printOutput()
        mata: M`refYear'Lead`lead'
}
*/



forvalues j = 1 / 4 {
    local lab`j': label TxMedian `j'
}

cap mkdir `"${out}/fig/`plotsTag'"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'"'
foreach refYear of local years {
    cap mkdir `"${out}/fig/`plotsTag'/`tag'/`refYear'"'
    forvalues lead = 0 / 1 {
        *mata: M`refYear'Lead`lead'
        *display "M`refYear'Lead`lead'"
        capture mata: mata describe M`refYear'Lead`lead'
        if (_rc) continue //(rc)==0 then false, if (rc)!=0 (i.e. there is an error) then true, and break
        clear

        * Set number of rows equal to number of groups from year T to T - lag
        mata stata(sprintf("set obs %g", rows(M`refYear'Lead`lead'))) //Sets number of observations in stata dataset to number of rows in Mata matrix

        mata _addTypes = ("long", "byte", "double", "double")
        mata _addNames = ("year", "TxMedian", "`alpha'", "mortality")
        mata (void) st_addvar(_addTypes, _addNames) //Create dataset of given types and names
        mata st_store(., _addNames, M`refYear'Lead`lead')

        qui glevelsof year, loc(plotyears)
        forvalues j = 1 / 4 {
            local opts xlabel(`plotyears', labsize(small))

            if ( `j' == 1 ) local opts `opts' lcolor(`"`lColorBadNoTerm'"')
            if ( `j' == 2 ) local opts `opts' lcolor(`"`lColorBadTerm'"')
            if ( `j' == 3 ) local opts `opts' lcolor(`"`lColorGoodNoTerm'"')
            if ( `j' == 4 ) local opts `opts' lcolor(`"`lColorGoodTerm'"')

            if inlist(`j', 1, 3) local opts `opts' lpattern(`lStyleNoTerm')
            if inlist(`j', 2, 4) local opts `opts' lpattern(`lStyleTerm')

            local ul`j' line `alpha'   year if TxMedian == `j', `opts' `lopts'
            local ml`j' line mortality year if TxMedian == `j', `opts' `lopts'
        }

        local legend order(1 `"`lab1'"' 2 `"`lab3'"' 3 `"`lab2'"' 4 `"`lab4'"')
        local legend `legend' cols(1) ring(1) position(1) bmargin(small)

        list

        twoway (`ul1') (`ul3') (`ul2') (`ul4'), legend(`legend') scheme(burd4)
        graph export `"${out}/fig/`plotsTag'/`tag'/`refYear'/planEffectLag`lag'.svg"', `xopts'

        twoway (`ml1') (`ml3') (`ml2') (`ml4'), legend(`legend') scheme(burd4)
        graph export `"${out}/fig/`plotsTag'/`tag'/`refYear'/mortalityLag`lag'.svg"', `xopts'
        */
    }
}


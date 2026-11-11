capture program drop collapsePlanCharacteristics
program collapsePlanCharacteristics
    syntax, if(str) [pre(str)]

    use `"${data}/landscape/ma_xw"' `if', clear
    adHocFixes
    collapseLandscape
    mergeAuxPlanFiles, pre(`pre')
    label data "Selected landscape characteristics (collapsed across years)"
    save `"${data}/`pre'ma_chars.dta"', replace

    * DOC: How to collapse to contract level? The original note states:
    *
    *     > also save version that only keeps the lowest plan in each
    *     > contract. this will be used if merging by ssacounty, cntrct,
    *     > pbpid does not result in a match
    *
    * We discussed this and decided that picking the characteristic
    * from the first numbered plan was plausible (and it is done in the
    * literature).

    bys ssacounty cntrct (pbpid): keep if _n == 1
    gisid ssacounty cntrct
    mergeAuxContractFiles, pre(`pre')

    label data "Selected landscape characteristics (collapsed across years and plans)"
    save `"${data}/`pre'ma_chars_cntrct.dta"', replace
end


capture program drop collapseLandscape
program collapseLandscape

    * TODO: Explain how we are meant to be collapsing chars in comment here.

    rename typeofadditionalcoverageoff typeofadditionalcoverageoffered
    rename monthlyconsolidatedpremiumi monthly_premium
    gen partd_offered = (drugbenefittype != "")

    gen gap_coverage = 1
    replace gap_coverage = . if typeofextracoverageoffered == ""
    replace gap_coverage = 0 if typeofextracoverageoffered == "No Gap Coverage" | typeofextracoverageoffered == "None"

    * part D flags
    sort ssacounty year organizationname

    * take avg premium, avg deductible across years
    local by   ssacounty cntrct pbpid
    local call (mean) monthly_premium annualdrugdeductible (max) partd_offered gap_coverage

    * NOTE: the type here is the raw type, not the broad type we came up
    * with once upon a time.

    * gen new_type = trim(upper(typeofmedicarehealthplan))
    * merge m:1 new_type using `"${data}/plan_broad_types.dta"', keep(1 3)

    * NOTE: This is not unique at the county-contract-plan-year. We
    * de-duplicate arbitrarily. We determined this was OK because it
    * only affected 6 plans.

    gsort `by' -year
    collapse `call' (firstnm) organizationname, by(`by' state typeofmedicarehealthplan)
    drop if mi(ssacounty)
    gduplicates drop `by', force
    order `by'
    gisid `by'
end


capture program drop mergeAuxPlanFiles
program mergeAuxPlanFiles
    syntax, [pre(str)]

    merge m:1 organizationname state using `"${data}/mlr_2011.dta"', ///
        keep(1 3) keepusing(mlr) gen(_mlr)

    merge m:1 cntrct using `"${data}/star-ratings/star_ratings_2008_2011.dta"', ///
        keep(1 3) keepusing(average_star) gen(_star)
end


capture program drop mergeAuxContractFiles
program mergeAuxContractFiles
    syntax, [pre(str)]

    * This is for contract-level versions of the files merged in
    * mergeAuxPlanFiles; no such files are needed at the moment.
end


capture program drop adHocFixes
program adHocFixes
    replace ssacounty = "09000" if state == "DC"
    replace ssacounty = "05210" if ssacounty == "05200"
end

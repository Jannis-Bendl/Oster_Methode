local 0: subinstr local 0 ";" ","
syntax, [CACHEd]

cap mkdir `"${data}/plan-data"'
cap mkdir `"${data}/plan-data/zip"'

***********************************************************************
*                             Risk Scores                             *
***********************************************************************

* Download
local url https://www.cms.gov/Medicare/Medicare-Advantage/Plan-Payment/Downloads
local files 2006paymentdata-.zip  ///
            2007paymentdata-.zip  ///
            2008paymentdata.zip   ///
            2009paymentdata-.zip  ///
            2010paymentdata-.zip  ///
            2011paymentdata.zip   ///
            2012paymentdata.zip   ///
            2013paymentdata.zip   ///
            2014paymentdata.zip   ///
            2015-payment-data.zip ///
            2016-payment-data.zip ///
            2017-payment-data.zip

foreach f of local files {
    disp `"plan-data/zip/`f'"'
    cap confirm file `"${data}/plan-data/zip/`f'"'
    if ( _rc == 0 ) {
        if ( `"`cached'"' != "" ) continue
        else erase `"${data}/plan-data/zip/`f'"'
    }
    copy `url'/`f' `"${data}/plan-data/zip/`f'"'
}

local CWD `"`c(pwd)'"'
cd `"${data}/plan-data/zip"'
foreach f of local files {
    if ( `"`cached'"' != "" ) {
        unzipfile `"`f'"'
    }
    else {
        unzipfile `"`f'"', replace
    }
    assert regexm(`"`f'"', "([0-9][0-9][0-9][0-9])")
    local year = regexs(1)
    cap confirm file "PlanPaymentDataElements.pdf"
    if ( _rc == 0 ) {
        cap erase "PlanPaymentDataElements`year'.pdf"
        copy "PlanPaymentDataElements.pdf" "PlanPaymentDataElements`year'.pdf"
        cap erase "PlanPaymentDataElements.pdf"
    }
}

* Concatenate
foreach f of local files {
    assert regexm(`"`f'"', "([0-9][0-9][0-9][0-9])")
    local year = regexs(1)

    local xlfile `year'PartCPlan Level.xlsx
    cap confirm file `"`xlfile'"'
    if ( _rc ) local xlfile `year'PartCPlanLevel.xlsx
    cap confirm file `"`xlfile'"'
    if ( _rc ) local xlfile `year'PartCPlanLevel2.xlsx
    confirm file `"`xlfile'"'
    disp `"`xlfile'"'

    import excel `"`xlfile'"', clear cellrange(A3) firstrow
    desc
    save `"`year'PartCPlanLevel.dta"', replace
}

cd `"`CWD'"'
cap confirm file `"${data}/plan-data/PartCPlanLevelData.dta"'
if ( _rc | (`"`cached'"' == "") ) {
    tempfile rs
    forvalues year = 2006 / 2017 {
        use `"${data}/plan-data/zip/`year'PartCPlanLevel.dta"', clear
        if regexm("`:type AverageRebatePMPMPayment'", "str") {
            replace AverageRebatePMPMPayment = subinstr(AverageRebatePMPMPayment, "$", "", .)
        }
        if !regexm("PlanBenefitPackage", "str") {
            tostring PlanBenefitPackage, replace
            replace PlanBenefitPackage = trim(PlanBenefitPackage)
            replace PlanBenefitPackage = "0" + PlanBenefitPackage if length(PlanBenefitPackage) < 3
            replace PlanBenefitPackage = "0" + PlanBenefitPackage if length(PlanBenefitPackage) < 3
            assert length(PlanBenefitPackage) == 3
        }
        destring AverageRebatePMPMPayment, replace
        gduplicates drop
        gen long year = `year'
        if ( `year' > 2006 ) append using `"`rs'"'
        save `"`rs'"', replace
    }

    use `"`rs'"', clear
    foreach var of varlist * {
        label var `var' `"`=ustrregexra(`"`:var label `var''"', "\s+", " ")'"'
    }
    gisid ContractNumber PlanBenefitPackage year, missok
    save `"${data}/plan-data/PartCPlanLevelData.dta"', replace
}

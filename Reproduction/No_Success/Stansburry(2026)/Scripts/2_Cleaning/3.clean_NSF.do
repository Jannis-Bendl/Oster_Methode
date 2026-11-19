********************************************************************************
*Import and Clean NSF Awards Data
********************************************************************************

*Import NSF Award data
import excel using "$RAWROOT\awards_cleaned_notext.xlsx", firstrow clear

****************************************
*Examine and clean variables
****************************************

***********
**First examine numerical vars

*Reformat all dates rather than datetime
replace AwardEffectiveDate = dofc(AwardEffectiveDate)
format AwardEffectiveDate %td
summarize AwardEffectiveDate, det
histogram(AwardEffectiveDate)
misstable summarize AwardEffectiveDate /*No missing*/
label var AwardEffectiveDate "Date the award funding starts"

replace AwardExpirationDate = dofc(AwardExpirationDate)
format AwardExpirationDate %td /*1899-2026 - many of these seem wrong but nothing in the codebook indicates why this might be*/
summarize AwardExpirationDate, det
histogram(AwardExpirationDate)
misstable summarize AwardExpirationDate /*No missing*/
label var AwardExpirationDate "Date the award funding ends"

replace FirstAmendDate = dofc(FirstAmendDate)
format FirstAmendDate %td /*1899-2020 - many of these seem wrong but nothing in the codebook indicates why this might be*/
summarize FirstAmendDate, det
histogram(FirstAmendDate)
misstable summarize FirstAmendDate /*172 missing values*/
label var FirstAmendDate "First date the award was amended"

replace LatestAmendDate = dofc(LatestAmendDate)
format LatestAmendDate %td /*1899-2020 - many of these seem wrong but nothing in the codebook indicates why this might be*/
summarize LatestAmendDate, det
histogram(LatestAmendDate)
misstable summarize LatestAmendDate /*172 missing values*/
label var LatestAmendDate "Last date the award was amended"

*Generate Effective Date Year variables
g AwardEffectiveYear = year(AwardEffectiveDate)
summarize AwardEffectiveYear, det /*1973-2021*/
histogram(AwardEffectiveYear)
misstable summarize AwardEffectiveYear /*No missing*/
label var AwardEffectiveYear "Year the award funding starts"

g AwardExpirationYear = year(AwardExpirationDate)
summarize AwardExpirationYear, det /*1899-2026 - many of these seem wrong but nothing in the codebook indicates why this might be*/
histogram(AwardExpirationYear)
misstable summarize AwardExpirationYear /*No missing*/
label var AwardExpirationYear "Year the award funding ends"

g FirstAmendYear = year(FirstAmendDate)
summarize FirstAmendYear, det /*1899-2020 - many of these seem wrong but nothing in the codebook indicates why this might be*/
histogram(FirstAmendYear)
misstable summarize FirstAmendYear /*172 missing values*/
label var FirstAmendYear "First year the award was amended"

g LatestAmendYear = year(LatestAmendDate)
summarize LatestAmendYear, det /*1899-2020 - many of these seem wrong but nothing in the codebook indicates why this might be*/
histogram(LatestAmendYear)
misstable summarize LatestAmendYear /*172 missing values*/
label var LatestAmendYear "Last year the award was amended"

***********

local moneyvars AmountAwardedToDate TotalIntendedAmount AmountFromARRA
foreach v of local moneyvars {
    capture confirm variable `v'
    if _rc==0 {
        capture confirm string variable `v'
        if _rc==0 {
            * Strip $, commas, spaces; convert parentheses to negatives
            gen double __tmp_`v' = real(subinstr(subinstr(subinstr(`v',"$","",.),",","",.)," ","",.))
            replace __tmp_`v' = -__tmp_`v' if strpos(`v',"(")>0 & strpos(`v',")")>0
            drop `v'
            rename __tmp_`v' `v'
        }
        * If it was already numeric, we leave it as-is
        format `v' %15.0fc
    }
}

*Other numeric var
summarize TotalInvestigators, det /*0-19*/
histogram(TotalInvestigators) /*Mostly one*/
misstable summarize TotalInvestigators /*No missing values*/
label var TotalInvestigators "Total number of investigators who have worked on or are working on the award"

destring(AmountAwardedToDate), replace
summarize AmountAwardedToDate, det /*0-1.83e+09; one negative value, -47,492, reflecting that the funding was credited back*/
histogram(AmountAwardedToDate)
misstable summarize AmountAwardedToDate /*100 missing values*/
label var AmountAwardedToDate "Amount of money awarded to date"

destring(TotalIntendedAmount), replace
summarize TotalIntendedAmount, det /*0-891e+08*/
histogram(TotalIntendedAmount)
misstable summarize TotalIntendedAmount /*229,613 missing values*/
label var TotalIntendedAmount "Total intended award amount"

destring(AmountFromARRA), replace
summarize AmountFromARRA, det /*0-1.48e+08*/
histogram(AmountFromARRA)
misstable summarize AmountFromARRA /*455,896 missing values*/
label var AmountFromARRA "Portion of AwardAmountToDate funded by the American Recovery and Reinvestment Act"

***********
**Now examine string vars
tab AwardEffectiveYear if missing(AwardID) /*No missing values*/
label var AwardID "Unique award ID"

tab AwardEffectiveYear if missing(AwardTitle) /*17 missing values*/
label var AwardTitle "Title of award"

tab AwardInstrument, m /*No missing values*/
encode AwardInstrument, gen(AwardInstrument_hist)
histogram(AwardInstrument_hist) /*Mostly Standard Grants*/
drop AwardInstrument_hist
codebook AwardInstrument
replace AwardInstrument= "Continuing Grant" if AwardInstrument=="Continuing grant"
replace AwardInstrument= "Fellowship Award" if AwardInstrument=="Fellowship"
label var AwardInstrument "Award Classification"

tab DirectorateAbbr, m /*229,481 missing values*/
encode DirectorateAbbr, gen(DirectorateAbbr_hist)
histogram(DirectorateAbbr_hist) /*Majority MPS awards*/
drop DirectorateAbbr_hist
codebook DirectorateAbbr
label var DirectorateAbbr "Directorate abbreviation for the NSF organization funding the grant"

tab DirectorateName, m /*125 missing values*/
encode DirectorateName, gen(DirectorateName_hist)
histogram(DirectorateName_hist) /*Majority Mathematical and Physical Sciences awards*/
drop DirectorateName_hist
codebook DirectorateName
label var DirectorateName "Directorate name for the NSF organization funding the grant"

tab DivisionAbbr, m /*229,659 missing values*/
encode DivisionAbbr, gen(DivisionAbbr_hist)
histogram(DivisionAbbr_hist)
drop DivisionAbbr_hist
codebook DivisionAbbr
label var DivisionAbbr "Division abbreviation for the NSF organization funding the grant"

tab DivisionName, m /*5,763 missing values*/
encode DivisionName, gen(DivisionName_hist)
histogram(DivisionName_hist) /*Majority Mathematical Sciences*/
drop DivisionName_hist
codebook DivisionName /*Possibly clean this? Though its very messy so it may be cleaner to use our field variables rather than these self-reported divisions*/
label var DivisionName "Division name for the NSF organization funding the grant"

tab AwardEffectiveYear if missing(ProgramElement) /*68,738 missing values*/
label var ProgramElement "List of programs funding this award"

tab AwardEffectiveYear if missing(ProgramReference) /*171,680 missing values*/
label var ProgramReference "List of programs intellectually related to the subject matter of the award"

save "$TEMP/nsf_data", replace


*******************************************************
*Import crosswalk
*******************************************************
import excel using "$RAWROOT/refid_public_crosswalk_wroles.xlsx", firstrow clear

************
*Clean crosswalk

tab RoleCode, m /*No missing values*/
encode RoleCode, gen(DivisionAbbr_hist)
histogram(DivisionAbbr_hist) /*Mostly PIs*/
drop DivisionAbbr_hist
codebook RoleCode
label var RoleCode "Role in award (e.g., Principal Investigator)"

tab RoleCode if missing(AwardID) /*No missing values*/
label var AwardID "Unique award ID"

tab RoleCode if missing(REFID) /*No missing values*/
label var REFID "ID for merging"

merge m:1 AwardID using "$TEMP/nsf_data" /*Crosswalk had 32,346 observations and that's what merged, extra observations from nsf dataset are presumably from individuals not in 2015*/
drop if _merge==2
drop _merge

*Save NSF Award dataset
save "$DATA/nsf_data_cleaned", replace

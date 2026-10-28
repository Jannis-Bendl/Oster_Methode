* ---------------------------------------------------------------------
* Title:   Determines above/below-median x terminated groupings for plots.
* Blame:   Emily Crawford (emily.crawford@yale.edu) inspired by Mauricio Caceres.
* Created: Wednesday, March 15th 2020
* Updated: Sunday, May 10th 2020
* Purpose: Determines which groupings of above/below median x terminated
*          (hereby abbreviate TxMedian) each beneficiary-year belongs to 
*          for all plot versions.
* Note:    We define all groupings in the base year using the contemporary
*          variables in base-year dataset. Those grouping for the beneficiary
*          in the base year carry over (for that
*          particular reference year) for all subsequent t, t+1,
*          t+2 years, etc.
* Trello:  https://trello.com/c/0szJ8NmO/198-create-new-plots
*
* Depends: >
*          ./00common/00preamble.do
*          ./04analysis/AnalysisConfigurations.do
*          ./04analysis/Parse/CommandLineArgs.do
*          ./04analysis/Preprocessing/SampleSelection6.do
*
* Output:  >
*          Add TxMedian`refYear' variables to loaded dataset
*

* Error Catching
*---------------------------------------------------------------------------
preserve
if ( regexm(`"`terminated'"', "_lag$") ) {
    disp _n(1)
    disp as err "{bf:Warning:} The lag version of terminated() was passed with plotsVersion(5)"
    disp as err "{bf:Warning:} This is probably wrong; double-check your configuration file."
}

if ( regexm(`"`ifcommand'"', "_lag") ) {
    disp _n(1)
    disp as err "{bf:Warning:} Possible lag condition in ifcommand() with plotsVersion(5)"
    disp as err "{bf:Warning:} This is probably wrong; double-check your configuration file."
}

if ( regexm(`"`alpha'"', "_lag$") ) {
    disp _n(1)
    disp as err "{bf:Warning:} Possible lag condition of alpha() with plotsVersion(5)"
    disp as err "{bf:Warning:} This is probably wrong; double-check your configuration file."
}

* Create list of of all years
qui glevelsof year, loc(years)

* Need more than one year of data to create plots
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}

* Define TxMedian grouping for each bene-reference Year
*---------------------------------------------------------------------------
* Restrictions
keep `ifcommand'
keep year bene_code `alpha' `terminated' true_mMA2 died_365 state county
drop if mi(bene_code) | mi(year) | mi(`alpha') | mi(`terminated') | mi(state) | mi(county)
gduplicates drop

* Define above/below median
fasterxtile med_alpha = `alpha' `ifcommand', nq(2) by(year)
gen dum_med_alpha = (med_alpha == 2)

*** Define code for above/below median x terminated
* TxMedian = 1 if non-terminated  &   above median
* TxMedian = 2 if terminated      &   above median
* TxMedian = 3 if non-terminated  &   below median
* TxMedian = 4 if terminated      &   below median
gen byte TxMedian = `terminated' + cond(dum_med_alpha == 1, 1, 3)

* Reshape to Wide Format
*---------------------------------------------------------------------------
* Format dataset for reshape to wide
gen refYear = year
keep TxMedian bene_code refYear

*Reshape to wide: TxMedian variable for every year
greshape wide TxMedian, i(bene_code) j(refYear)
gisid bene_code

* Add Labels
*---------------------------------------------------------------------------
local g1 Non-Terminated; observational mortality > median
local g2 Terminated; observational mortality > median
local g3 Non-Terminated; observational mortality < median
local g4 Terminated; observational mortality < median


cap label drop TxMedian
label define TxMedian 1 `"`g1'"' 2 `"`g2'"' 3 `"`g3'"' 4 `"`g4'"'
label values TxMedian* TxMedian

* Merge TxMedian Groupings into Main Dataset
*---------------------------------------------------------------------------
tempfile TxMedianCohorts
save `"`TxMedianCohorts'"'
restore

merge m:1 bene_code using `"`TxMedianCohorts'"', keep(1 3)

* Clean TxMedian Variables
*---------------------------------------------------------------------------
foreach refYear of local years {
    display "TxMedian`refYear'"
    replace TxMedian`refYear'=. if year < `refYear'
}

* Checks
*---------------------------------------------------------------------------
* Calculate last year
preserve
summarize year, meanonly
local last_year = r(max)

foreach refYear of local years{
    * Check 1: If beneficiary is true_mMA2 for a given year, then must have a TxMedian code.
    assert !missing(TxMedian`refYear') `ifcommand'  & year==`refYear'
        disp "All beneficiaries that are true_mMA2==1 in `refYear' have TxMedian assignment."

    * Check 2: If beneficiary-year is given TxMedian assignment, then that assignment must exist for each subsequent year.
    cap drop TxMedian_fill
    qui bysort bene_code (year): gen TxMedian_fill = missing(TxMedian`refYear') if !missing(TxMedian`refYear'[_n-1])
    qui count if TxMedian_fill==1
    if r(N) > 0{
        disp as err "{bf:Warning:} If beneficiary-year has TxMedian assignment in `refYear', must have same assignment for subsequent years."
        list bene_code year true_mMA2 TxMedian`refYear' if TxMedian_fill==0
    }
    else{
        disp "TxMedian assignments of `refYear' properly carry over to the subsequent years."
    }
}
    * Check 3: Beneficiaries only disappear from sample by dying. Only perform this check for 100% dataset,
    * as there are too many exceptions in the 1 percent.
    if `pct'==100{
        cap drop die_last_year
        qui bysort bene_code (year): gen die_last_year = (died_365[_N]==1) | (year[_N]==`last_year')
        qui count if die_last_year==0
        if r(N) > 0{
            disp as err "{bf:Warning:} Beneficiaries must disappear from sample by dying."
            list bene_code year died_365 if die_last_year==0
        }
        else{
            disp "Beneficiaries only exit the sample by dying."
        }
    }
restore

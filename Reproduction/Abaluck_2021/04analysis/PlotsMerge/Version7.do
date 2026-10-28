* ---------------------------------------------------------------------
* Title:   Determines above/below-median x terminated groupings and
*          fixed effects for plots.
* Blame:   Emily Crawford (emily.crawford@yale.edu) inspired by Mauricio Caceres.
* Created: Friday, May 8th 2020
* Updated: Sunday, May 10th 2020
* Purpose: Determines which groupings of above/below median x terminated
*          (hereby abbreviate TxMedian) each beneficiary-year belongs to 
*          for all plot versions. Also determines fixed effect variable
*          of year-state-county grouping.
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
*          Add TxMedian`refYear' and fe_year_state_county_`refYear' variables
*          to loaded dataset
*

* Error Catching
*---------------------------------------------------------------------------
* Create list of of all years
qui glevelsof year, loc(years)

* Need more than one year of data to create plots
if ( `:list sizeof years' <= 1 ) {
    disp as err "{bf:Warning:} Unable to create plot variables with only 1 year"
    exit 198
}


* Setup
*---------------------------------------------------------------------------
* Restrictions
keep `ifcommand'

* Regenerate list of years
qui glevelsof year, loc(years)

*** Define code for above/below median x terminated
* TxMedian = 1 if non-terminated  &   above median
* TxMedian = 2 if terminated      &   above median
* TxMedian = 3 if non-terminated  &   below median
* TxMedian = 4 if terminated      &   below median
gen byte TxMedian = `terminated' + cond(dum_med == 1, 1, 3)

* Add Labels
*---------------------------------------------------------------------------
local g1 Non-Terminated; Above-Median Observational Mortality
local g2 Terminated; Above-Median Observational Mortality
local g3 Non-Terminated; Below-Median Observational Mortality
local g4 Terminated; Below-Median Observational Mortality

cap label drop TxMedian
label define TxMedian 1 `"`g1'"' 2 `"`g2'"' 3 `"`g3'"' 4 `"`g4'"'
label values TxMedian* TxMedian
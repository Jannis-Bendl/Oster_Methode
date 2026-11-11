* ---------------------------------------------------------------------
* Title:    County Terminations Choropleth Map
* Blame:    Emily Crawford (emily.crawford@yale.edu)
* Modified: Jerray Chang (jerray@uchicago.edu)
* Created:  Wednesday, 11 November 2020
* Updated:  Monday, 15 February 2021
* Purpose:  Creates county-level dataset for choropleth map
*           of county terminations (Figure A1)
* ---------------------------------------------------------------------

* term_map.dta: county-level dataset including
*     - ssacounty
*     - number of plans
*     - number of plans that terminate
*     - number of plans that had at least 12 beneficiaries over 2008-2011
*     - number of plans that had at least 12 beneficiaries over 2008-2011, that terminate
*     - number of unique beneficiaries
*     - number of unique beneficiaries that were ever Dual-eligible
*     - a FIPS crosswalk (including variable "county" used in map creation)
*     - an indicator variable for if any plan terminated
*     - an indicator variable for if any plan terminated among those with at least 12 beneficiaries over 2008-2011

* Create County-Level Dataset
*---------------------------------------------------------------------------
* Keep Only True MA Plans
keep if true_mMA2_lag == 1

* All Observations
cap frame drop CountyTerm
frame put bene_code year fe_county_lag plan_lag eDual ssacounty_lag `terminated' , into(CountyTerm)
frame CountyTerm {
    gegen double count_plan       = tag(fe_county_lag plan_lag)                       // Num Unique Plans
    gegen double count_plan_term  = tag(fe_county_lag plan_lag) if `terminated' == 1  // Num Terminations
    gegen double count_bene       = tag(fe_county_lag bene_code)                      // Num Unique Bene
    gegen double count_bene_eDual = tag(fe_county_lag bene_code) if eDual == 1        // Num Dual-eligible Bene

    local collapsevars (sum) num_plan_lag = count_plan (sum) num_plan_term_lag = count_plan_term
    local collapsevars `collapsevars' (sum) num_bene_lag = count_bene (sum) num_bene_eDual_lag = count_bene_eDual
    gcollapse `collapsevars' , by(ssacounty_lag)
    gisid ssacounty_lag
    assert num_plan_term_lag <= num_plan_lag
    tempfile CountyTerm
    save `"`CountyTerm'"'
}

* Only Keeping Plan-Years With At Least 12 Beneficiares
cap frame drop CountyTerm12Min
frame put bene_code year fe_county_lag plan_lag eDual ssacounty_lag `terminated', into(CountyTerm12Min)
frame CountyTerm12Min {
    gegen plan_size_lag = count(1), by(fe_county_lag plan_lag year)
    drop if plan_size_lag < 12                                                        // Remove Plan-Years If Have Less Than 12 Beneficiaries
    gegen double count_plan       = tag(fe_county_lag plan_lag)                       // Num Unique Plans
    gegen double count_plan_term  = tag(fe_county_lag plan_lag) if `terminated' == 1  // Num Terminations
    gegen double count_bene       = tag(fe_county_lag bene_code)                      // Num Unique Bene
    gegen double count_bene_eDual = tag(fe_county_lag bene_code) if eDual == 1        // Num Dual-eligible Bene

    local collapsevars (sum) num_plan_12min_lag = count_plan (sum) num_plan_term_12min_lag = count_plan_term
    local collapsevars `collapsevars' (sum) num_bene_12min_lag = count_bene (sum) num_bene_eDual_12min_lag = count_bene_eDual
    gcollapse `collapsevars', by(ssacounty_lag)
    gisid ssacounty_lag
    assert num_plan_term_12min_lag <= num_plan_12min_lag
    tempfile CountyTerm12Min
    save `"`CountyTerm12Min'"'
}

keep ssacounty_lag
gduplicates drop
merge m:1 ssacounty_lag using `"`CountyTerm'"',      keep(1 3) gen(_numterm)
merge m:1 ssacounty_lag using `"`CountyTerm12Min'"', keep(1 3) gen(_numterm12min)

// state SSA ID are first 2 characters
gen state_ssa = substr(ssacounty_lag, 1, 2)
destring state_ssa, gen(statessa)

// merge with SSA-FIPS crosswalk
local ssafips /homes/data/ssa-fips-state-county-crosswalk/2011/ssa_fips_state_county2011
ren ssacounty_lag ssacounty
merge 1:1 ssacounty using `"`ssafips'"', nogen keep(match)
rename ssacounty ssacounty_lag
rename county county_name
rename state state_name

// destring and rename county FIPS code for the maptile command
destring fipscounty, gen(county)

// sanity check: make sure no duplicates
quietly by county, sort: gen dup = cond(_N == 1, 0, _n)
gisid county

// create indicator variables
gen has_term = (num_plan_term_lag>=1 & !mi(num_plan_term_lag))
replace has_term = . if mi(num_plan_term_lag)
gen has_term12 = ((num_plan_term_12min_lag > =1) & !mi(num_plan_term_12min_lag))
replace has_term12 = . if mi(num_plan_term_12min_lag)

save "${out}/fig/term_map", replace
describe

if (`"`runPlots_map'"' != "") {
    local 0; pct(`pct') pre(`pre')
    include "04analysis/Run/Figures/term_map/figureA1.do"
}

if (`"`runCountyChars'"' != "") {
    include "04analysis/Run/CountyChars.do"
}

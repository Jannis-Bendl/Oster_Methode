* ---------------------------------------------------------------------
* Title:    Sample Selection - General
* Program:  SampleSelection
* Blame:    Mauricio Caceres, Aaron Pollack, Emily Crawford (emily.crawford@yale.edu)
* Reformat: Emily Crawford (emily.crawford@yale.edu)
* Created:  Wednesday, March 17th 2020
* Updated:  Monday, December 14th 2020
* Purpose:  Runs base sample selection steps.
* Note:
* ---------------------------------------------------------------------

local 03ivSampleData `pre'ivSample`pct'.dta
disp "Using data file `03ivSampleData'."

* Create Lag Mortality File to be Merged in Later
*---------------------------------------------------------------------------
use `"${data}/`03ivSampleData'"', clear
    keep county state pbpid_id cntrct_id year died_365
    gcollapse (mean) died_365, by(county state cntrct_id pbpid_id year)
    rename died_365 lag_mortality

    replace year = year + 1
    rename (county state pbpid_id cntrct_id) (county_lag state_lag pbpid_id_lag cntrct_id_lag)

    drop if mi(county_lag) | mi(state_lag) | mi(pbpid_id_lag) | mi(cntrct_id_lag) | mi(year)
    gisid county_lag state_lag pbpid_id_lag cntrct_id_lag year
    tempfile lagmort
    save `lagmort'

* Create Contemporary Plan Share File
*---------------------------------------------------------------------------
use `"${data}/`03ivSampleData'"', clear
    keep fe_county plan year
    gcontract fe_county plan year, f(nbene_plan_county)
    gegen nbene_county = sum(nbene_plan_county), by(fe_county year) replace
    gen frac_plan_county = nbene_plan_county / nbene_county

    keep fe_county plan year frac_plan_county
    gisid year fe_county plan
    label var frac_plan_county "Proportion in contemporary county-plan"
    compress

    * Ensure that all plans see market share < 1
    assert frac_plan_county <= 1

    * Ensure that market shares sum to 1
    gegen plan_sum = sum(frac_plan_county), by(year fe_county)
    gen absdiff = abs(1 - plan_sum)
    assert absdiff < 1e-5
    drop absdiff plan_sum

    * Save Contemporary Plan Share
    tempfile PlanShare
    save `PlanShare'

    replace year = year + 1
    rename (fe_county plan frac_plan_county) (fe_county_lag plan_lag frac_plan_county_lag)
    label var frac_plan_county_lag "Proportion in contemporary county-plan the year prior"

    * Save Lag Plan Share
    tempfile lagPlanShare
    save `lagPlanShare'

* Create Contemporary Empirical Termination Variable
*---------------------------------------------------------------------------
use `"${data}/`03ivSampleData'"', clear
    keep fe_county_lag cntrct_id_lag pbpid_id_lag year dis_plan_80_lag dis_plan_80_post_lag
    drop if mi(cntrct_id_lag) | mi(pbpid_id_lag)
    drop if mi(dis_plan_80_lag)
    gduplicates drop
    gisid fe_county_lag cntrct_id_lag pbpid_id_lag year
    rename (fe_county_lag cntrct_id_lag pbpid_id_lag) (fe_county cntrct_id pbpid_id)
    rename (dis_plan_80_lag dis_plan_80_post_lag) (dis_plan_80 dis_plan_80_post)
    replace year = year - 1
    tempfile ContEmpTerm
    save `ContEmpTerm'

* Create Abridged Definition of Termination
*---------------------------------------------------------------------------
use `"${data}/`03ivSampleData'"', clear
    * New Termination Definition
    gen bene_count = 1
    drop if mi(fe_county_lag) | mi(cntrct_id_lag) | mi(pbpid_id_lag) | mi(disappeared_landscape1_lag)
    gcollapse (sum) bene_count (mean) dis_plan_80_lag, by(fe_county_lag cntrct_id_lag pbpid_id_lag year disappeared_landscape1_lag)
    gisid fe_county_lag cntrct_id_lag pbpid_id_lag year
    assert dis_plan_80_lag == 1 | dis_plan_80_lag == 0
    gegen min_year_term = min(year) if (dis_plan_80_lag == 1) | (disappeared_landscape1_lag == 1), by(fe_county_lag cntrct_id_lag pbpid_id_lag)
    gen dis_landscape1_80_lag = 0
    replace dis_landscape1_80_lag = 1 if year == min_year_term
    gegen dis_count = total(dis_landscape1_80_lag), by(fe_county_lag cntrct_id_lag pbpid_id_lag)
    assert dis_count == 1 | dis_count == 0
    drop dis_count
    tab dis_landscape1_80_lag dis_plan_80_lag
    tab dis_landscape1_80_lag disappeared_landscape1_lag

    keep fe_county_lag cntrct_id_lag pbpid_id_lag year dis_landscape1_80_lag
    gisid fe_county_lag cntrct_id_lag pbpid_id_lag year
    tempfile LandscapeEmpricalTermination
    save `LandscapeEmpricalTermination'

* Data File to be Used
*---------------------------------------------------------------------------
use `"${data}/`03ivSampleData'"', clear

if ( `"`remerge_truema'"' != "" ) {
    qui do "03ivSample/MergeTrueMAFlag.do"
    local remerge_truema: subinstr local remerge_truema ";" ","
    `remerge_truema'
}

* Generate jack knife variables
*---------------------------------------------------------------------------
if ( `"`jack_knife'"' != "" ) {
    tempvar nplan nplan_lag

    foreach var of varlist `raw_alpha' `dtilde' {
        bys bene_code (year): gen `var'_lag = `var'[_n - 1]
    }

    gegen `nplan' = count(1), by(fe_county plan)
    gen mu_jackknife = (`raw_alpha' - `dtilde' / `nplan') * `nplan' / (`nplan' - 1)
    replace mu_jackknife = (`raw_alpha' - `dtilde') if `nplan' == 1
    assert !mi(mu_jackknife) if !mi(`raw_alpha')

    * (delete this comment once checked): Why compute jack knife using
    * lags instead of lagging the jack knife?

    gegen `nplan_lag' = count(1), by(fe_county_lag plan_lag)
    gen mu_jackknife_lag = (`raw_alpha'_lag - `dtilde'_lag / `nplan_lag') * `nplan_lag' / (`nplan_lag' - 1)
    replace mu_jackknife_lag = (`raw_alpha'_lag - `dtilde'_lag) if `nplan_lag' == 1
}

* Drop Missings
*---------------------------------------------------------------------------
drop if mi(`bin_var'_lag)
drop if mi(true_mMA2_lag)

* Merge in Additional Variables
*---------------------------------------------------------------------------

* Merge in Lag Mortality
merge m:1 county_lag state_lag pbpid_id_lag cntrct_id_lag year using `lagmort', keep(1 3) gen(_lag_mortality)

* Merge in Contemporary and Lag Plan Share
cap drop frac_plan_county      
cap drop frac_plan_county_lag
cap drop _plan_share
cap drop _lag_plan_share

merge m:1 fe_county     plan     year using `PlanShare',    keep(1 3) gen(_plan_share)
merge m:1 fe_county_lag plan_lag year using `lagPlanShare', keep(1 3) gen(_lag_plan_share)

* Merge in New Definition of Termination
merge m:1 fe_county_lag cntrct_id_lag pbpid_id_lag year using `LandscapeEmpricalTermination', keep(1 3) gen(_landscape_emp_term)

* Merge in Contemporary Empirical Termination
merge m:1 fe_county cntrct_id pbpid_id year using `ContEmpTerm', keep(1 3) gen(_contempterm)

* Merge in Plan Characteristics
include 98adHoc/addPlanChars.do

* Apply Additional Restrictions or Transforms
*---------------------------------------------------------------------------
* Restrict Years to 2008 and Greater
if ( `"`ifglobal'"' != "" ) keep `ifglobal'

* Drop All Plan Consolidations
if ( `"`ifconsol'"' != "" ) drop `ifconsol'

* Drop County-Years with no Terminations
if ( `"`anyterm'"' != "" ) {
    gegen nterm = sum(`terminated') `ifcommand', by(fe_county year)
    keep if nterm > 0
}

* Drop Empirical Terminations
if ( `"`ifempterm'"' != "" ) drop `ifempterm' & `terminated' != 1
* Drop Post Empirical Terminations
if ( `"`ifpostterm'"' != "" ) {
    if (strpos(trim(`"`ifpostterm'"'), "if") == 1) {
        keep `ifpostterm'
    }
    else keep if 1 `ifpostterm'
}

* Generate Instruments
*---------------------------------------------------------------------------
* Generate Instrument - Mu
gen instrument = `terminated' * `alphalag'


* Decile and Ventile Alpha-Lag by Year (Among Whole Sample, By Year, or By County Year)
if (`"`global_meds'"' != "") {
    fasterxtile dec_alpha_lag = `alphalag' `ifcommand', nq(10)
    fasterxtile ven_alpha_lag = `alphalag' `ifcommand', nq(20)
}
else if (`"`quantile_by_year'"' != "") {
    fasterxtile dec_alpha_lag = `alphalag' `ifcommand', nq(10) by(year)
    fasterxtile ven_alpha_lag = `alphalag' `ifcommand', nq(20) by(year)
}
else {
    fasterxtile dec_alpha_lag = `alphalag' `ifcommand', nq(10) by(fe_county_year)
    fasterxtile ven_alpha_lag = `alphalag' `ifcommand', nq(20) by(fe_county_year)
}


* Generate Above-Below Median Dummy Variable for Alpha Lag (Among Whole Sample, By Year, or By County Year)
if (`"`global_meds'"' != "") {
    fasterxtile med_alpha_lag = `alphalag' `ifcommand', nq(2)
    gen dum_med = (med_alpha_lag == 2)
    label variable dum_med "Above-below median dummy for `alphalag'"
}
else if (`"`quantile_by_year'"' != "") {
    fasterxtile med_alpha_lag = `alphalag' `ifcommand', nq(2) by(year)
    gen dum_med = (med_alpha_lag == 2)
}
else {
    fasterxtile med_alpha_lag = `alphalag' `ifcommand', nq(2) by(fe_county_year)
    gen dum_med = (med_alpha_lag == 2)
}

* Generate Instrument with Binary Alpha
gen Zxdum_med = `terminated' * dum_med

* Generate Instrument with Decile Alpha-Lag
tab dec_alpha_lag, gen(dum_dec) // Dummy for each decile of alpha-lag
foreach var of varlist dum_dec* {
    gen byte Zx`var' = `var' * `terminated'
}

* Generate Instrument with Ventile Alpha-Lag
tab ven_alpha_lag, gen(dum_ven) // Dummy for each ventile of alpha-lag
foreach var of varlist dum_ven* {
    gen byte Zx`var' = `var' * `terminated'
}

if (`"`tm'"' != "") {
    gen ZxFracTM       = `terminated' * frac_`tm'_lag
}

if (`"`employer'"' != "") {
    gen ZxFracEmployer = `terminated' * frac_`employer'_lag
}

* Additional misc variables
gegen fe_county_lag_year = group(year fe_county_lag)
gegen fe_cntrct_lag = group(cntrct_id_lag)
gegen fe_county_`contract' = group(fe_county `level'), replace

cap drop plantypeFE
cap drop plantypeFE_contemp
cap drop mutile

gegen plantypeFE = group(typeofmedicarehealthplan_lag)
gegen plantypeFE_contemp = group(typeofmedicarehealthplan)

fasterxtile mutile = `alpha'_lag, n(100)
fasterxtile plan_size_dec = nbene_plan_county `ifcommand', nq(10)

gegen county_num_term = total(`terminated'), by(fe_county_lag)
gen county_term_ind = (county_num_term>=1)
gen PFFS_lag = strpos(typeofmedicarehealthplan_lag, "PFFS") > 0

gen dum_died_two_yr = 0
replace dum_died_two_yr = 1 if died_365 == 1
replace dum_died_two_yr = 1 if year == (deathyear - 1)

* Add nbene plan_lag variables
gegen nbene_plan_county_lag = tag(county_lag state_lag pbpid_id_lag cntrct_id_lag year bene_code), replace
gegen nbene_plan_county_lag = sum(nbene_plan_county_lag), replace by(county_lag state_lag pbpid_id_lag cntrct_id_lag year)
gegen plan_num_bene = count(1), by(year fe_county_lag plan_lag)

* Sanity Checks
*---------------------------------------------------------------------------
assert !mi(fe_county_lag) if true_mMA2_lag == 1
assert !mi(year) if true_mMA2_lag == 1
assert !mi(`terminated') if true_mMA2_lag == 1
assert !mi(`alpha'_lag) if true_mMA2_lag == 1
assert !mi(frac_plan_county_lag) if true_mMA2_lag == 1
assert !mi(dum_died_two_yr)

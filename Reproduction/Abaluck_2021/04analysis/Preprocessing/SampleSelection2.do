* ---------------------------------------------------------------------
* Title:    Sample Selection 2
* Blame:    Mauricio Caceres, Aaron Pollack
* Reformat: Emily Crawford (emily.crawford@yale.edu)
* Created:  Wednesday, March 17th 2020
* Updated:  Tuesday, January 5th 2020
* Purpose:  Runs sample selection steps used for the Plan
*           Characteristic Regressions.
* Note:
* ---------------------------------------------------------------------

* Base Sample Selection
*------------------------------------------------------------------------------------
include 04analysis/Preprocessing/SampleSelectionGeneral.do

* Apply Modal Value; Generate Missing Indicator
*------------------------------------------------------------------------------------

* Current
local plan_lags
local plan_chars monthly_premium star_rating mlr hvam average_risk_score partd_offered gap_coverage
foreach var of varlist `plan_chars' {
    local plan_lags `plan_lags' `var'_lag
    bysort state county cntrct_id pbpid_id (`var'): egen `var'_mode = mode(`var'), missing
    replace `var' = `var'_mode
    gen missing_`var' = mi(`var')
    drop `var'_mode
}

* Lag
foreach var of varlist `plan_lags' {
    bysort state_lag county_lag cntrct_id_lag pbpid_id_lag (`var'): egen `var'_mode = mode(`var'), missing
    replace `var' = `var'_mode
    gen missing_`var' = mi(`var')
    drop `var'_mode
}

* Create indicator variable for premiums
*---------------------------------------------------------------------------

gen monthly_premium_dum     = 0 if (monthly_premium == 0)
replace monthly_premium_dum = 1 if (monthly_premium > 0) & !mi(monthly_premium)

gen monthly_premium_dum_lag     = 0 if (monthly_premium_lag == 0)
replace monthly_premium_dum_lag = 1 if (monthly_premium_lag > 0) & !mi(monthly_premium_lag)

* Replace Missing Values w/ Mean for true_mMA2 and non-true_mMA2 Plans
*---------------------------------------------------------------------------
local plan_chars monthly_premium star_rating mlr hvam average_risk_score
foreach plan_char of local plan_chars {
	* Replace at County-Plan Level
    gegen MEAN`plan_char'_c_pln     = mean(`plan_char'),     by(fe_county pbpid_id)
    gegen MEAN`plan_char'_c_pln_lag = mean(`plan_char'_lag), by(fe_county_lag pbpid_id_lag)
    replace `plan_char'     = MEAN`plan_char'_c_pln     if mi(`plan_char')
    replace `plan_char'_lag = MEAN`plan_char'_c_pln_lag if mi(`plan_char'_lag)

    * Replace at County-Contract Level
    gegen MEAN`plan_char'_c_ctr     = mean(`plan_char'),     by(fe_county cntrct_id)
    gegen MEAN`plan_char'_c_ctr_lag = mean(`plan_char'_lag), by(fe_county_lag cntrct_id_lag)
    replace `plan_char'     = MEAN`plan_char'_c_ctr     if mi(`plan_char')
    replace `plan_char'_lag = MEAN`plan_char'_c_ctr_lag if mi(`plan_char'_lag)

    * Replace at Contract Level
    gegen MEAN`plan_char'_ctr     = mean(`plan_char'),     by(cntrct_id)
    gegen MEAN`plan_char'_ctr_lag = mean(`plan_char'_lag), by(cntrct_id_lag)
    replace `plan_char'     = MEAN`plan_char'_ctr     if mi(`plan_char')
    replace `plan_char'_lag = MEAN`plan_char'_ctr_lag if mi(`plan_char'_lag)

    * Replace at County Level
    gegen MEAN`plan_char'_cnty     = mean(`plan_char'),     by(fe_county)
    gegen MEAN`plan_char'_cnty_lag = mean(`plan_char'_lag), by(fe_county_lag)
    replace `plan_char'     = MEAN`plan_char'_cnty     if mi(`plan_char')
    replace `plan_char'_lag = MEAN`plan_char'_cnty_lag if mi(`plan_char'_lag)

	* Replace at True MA  Level
	gegen MEAN`plan_char'_MA     = mean(`plan_char'),     by(true_mMA2)
    gegen MEAN`plan_char'_MA_lag = mean(`plan_char'_lag), by(true_mMA2_lag)
    replace `plan_char'     = MEAN`plan_char'_MA     if mi(`plan_char')
    replace `plan_char'_lag = MEAN`plan_char'_MA_lag if mi(`plan_char'_lag)

    drop MEAN`plan_char'*
}

* Part D Coverage
replace partd_offered     = 0 if missing_partd_offered
replace partd_offered     = 0 if missing_gap_coverage
replace gap_coverage      = 0 if missing_partd_offered
replace gap_coverage      = 0 if missing_gap_coverage

replace partd_offered_lag = 0 if missing_partd_offered_lag
replace partd_offered_lag = 0 if missing_gap_coverage_lag
replace gap_coverage_lag  = 0 if missing_partd_offered_lag
replace gap_coverage_lag  = 0 if missing_gap_coverage_lag

* Monthly Premium Dummy
replace monthly_premium_dum     = 0 if missing_monthly_premium     == 1
replace monthly_premium_dum_lag = 0 if missing_monthly_premium_lag == 1

* Create monthly premium value in terms of 100
*---------------------------------------------------------------------------
gen monthly_premium_C     = monthly_premium     / 100
gen monthly_premium_C_lag = monthly_premium_lag / 100

* Create dummy vars for star_rating
*---------------------------------------------------------------------------
gen star45      = (star_rating     >= 4)
gen star45_lag  = (star_rating_lag >= 4)
gen star345     = (star_rating     >= 3)
gen star345_lag = (star_rating_lag >= 3)
rename (star_rating star_rating_lag) (star_rating_cont star_rating_cont_lag)

* Create Dummies for Plan Type
*---------------------------------------------------------------------------
gen pffs_dum     = strpos(typeofmedicarehealthplan, "PFFS") > 0
gen pffs_dum_lag = strpos(typeofmedicarehealthplan_lag, "PFFS") > 0
gen hmo_dum      = strpos(typeofmedicarehealthplan, "HMO") > 0
gen hmo_dum_lag  = strpos(typeofmedicarehealthplan_lag, "HMO") > 0
gen ppo_dum      = strpos(typeofmedicarehealthplan, "PPO") > 0
gen ppo_dum_lag  = strpos(typeofmedicarehealthplan_lag, "PPO") > 0

* Create lag decile variables
*---------------------------------------------------------------------------
local plan_chars monthly_premium_C star_rating_cont mlr average_risk_score hvam
foreach plan_char of local plan_chars{
    fasterxtile `plan_char'_lag_dec  = `plan_char'_lag, nq(10)
}

* Checks for Missing Values
*---------------------------------------------------------------------------
* Monthly Premium, Star Rating, MLR, Average Risk Score, HVAM, Part D Coverage, Donut Hole Coverage
local plan_chars monthly_premium star_rating_cont star45 star345 mlr average_risk_score hvam partd_offered gap_coverage
foreach plan_char of local plan_chars {
    disp `"`plan_char'"'
    assert !mi(`plan_char')
    disp `"`plan_char'_lag"'
    assert !mi(`plan_char'_lag)
}

* Create parent dummies
*---------------------------------------------------------------------------
include 98adHoc/addNormalizedOrganizationName.do
gen missing_parent     = mi(organization_normalized)
gen missing_parent_lag = mi(organization_normalized_lag)

foreach Parent of local Parents {
    local parent = lower(`"`Parent'"')
    gen parent_`parent'     = (organization_normalized     == `"`Parent'"')
    gen parent_`parent'_lag = (organization_normalized_lag == `"`Parent'"')
}

gen parent_big     = (parent_humana     == 1) | (parent_united     == 1) | (parent_bcbs     == 1)
gen parent_big_lag = (parent_humana_lag == 1) | (parent_united_lag == 1) | (parent_bcbs_lag == 1)

gen parent_hub     = parent_humana     + 2 * parent_united     + 3 * parent_bcbs
gen parent_hub_lag = parent_humana_lag + 2 * parent_united_lag + 3 * parent_bcbs_lag

label define organization 0 "Other" 1 "Humana" 2 "United" 3 "BCBS"
label values parent_hub parent_hub_lag organization

tab parent_hub
tab parent_hub_lag

* Calculate Xi
*---------------------------------------------------------------------------
include 98adHoc/addXi.do
merge m:1 year state     county     cntrct_id     pbpid_id     using `XiMerge',    keep(1 3) gen(_xi)
merge m:1 year state_lag county_lag cntrct_id_lag pbpid_id_lag using `LagXiMerge', keep(1 3) gen(_xi_lag)

gen missing_ln_marketshare     = mi(ln_marketshare)
gen missing_ln_marketshare_lag = mi(ln_marketshare_lag)

* Xi
assert !mi(xi_one)             if true_mMA2 == 1
assert !mi(xi_two)             if true_mMA2 == 1
assert !mi(ln_marketshare)     if true_mMA2 == 1
assert !mi(xi_one_lag)         if true_mMA2_lag == 1
assert !mi(xi_two_lag)         if true_mMA2_lag == 1
assert !mi(ln_marketshare_lag) if true_mMA2_lag == 1

* Calculate Eta
di `"reghdfe `alpha' star_rating_cont monthly_premium mlr gap_coverage `ifcommand', noabsorb"'
reghdfe `alpha' star_rating_cont monthly_premium mlr gap_coverage `ifcommand', noabsorb
predict mu_hat, xb

di `"reghdfe mu_hat `alpha' `ifcommand', noabsorb resid"'
reghdfe mu_hat `alpha' `ifcommand', noabsorb resid
predict eta, resid

* Predicted Mortality
reg died_365 i.fe_age i.fe_sex i.fe_race `ifcommand'
predict predictedMortality `ifcommand', xb

* Predicted Mortality - Dual
reg died_365 i.fe_age i.fe_sex i.fe_race i.mDual `ifcommand'
predict predictedMortality_dual `ifcommand', xb

* Predicted Mortality - Average Risk Score
reg died_365 i.fe_age i.fe_sex i.fe_race i.mDual average_risk_score `ifcommand'
predict predictedMortality_dual_risk `ifcommand', xb

if ( `"`eta_control'"' != "" ) {
    local indepvars `indepvars' eta
}
else if ( `"`eta_ind_control'"' != "" ) {
    local plan_chars star_rating_cont monthly_premium mlr gap_coverage
    foreach plan_char of local plan_chars {
        di `"reghdfe `plan_char' `alpha' `ifcommand', noabsorb resid"'
        reghdfe `plan_char' `alpha' `ifcommand', noabsorb resid
        predict `plan_char'_resid, residuals
        local indepvars `indepvars' `plan_char'_resid
    }
}

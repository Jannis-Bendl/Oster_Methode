unab cZDec: Zxdum_dec*
unab cDec:  dum_dec*
gettoken cDec0  cDec:  cDec
gettoken cZDec0 cZDec: cZDec

unab cZVen: Zxdum_ven*
unab cVen:  dum_ven*
gettoken cVen0  cVen:  cVen
gettoken cZVen0 cZVen: cZVen

* Generate Fixed Effects
*---------------------------------------------------------------------------
local FE     // Fixed Effects for IV Regressions
local demoFE // Fixed Effects for Balance Tests
local cluster
local demoControls

if ( "`interact'" == "nointeract" ) {
    local interact
}
else {
    local interact b0.`terminated'#
}


* Year - County-Lag Grouping
if ( "`cy'" != "" ) {
    local FE `FE' fe_county_lag_year `interact'i.year `interact'fe_county_lag
    local demoFE `demoFE' fe_county_lag_year `interact'i.year `interact'fe_county_lag

    local cluster `cluster' fe_county_lag
}
else if (  "`feCountyLag'" != "" ) {
    local demoFE `demoFE' fe_county_lag
    local FE `interact'fe_county_lag
    local cluster `cluster' fe_county_lag
}
else if (  "`feCntrctLag'" != "" ) {
    local demoFE `demoFE' cntrct_id_lag
    local FE `FE' `interact'fe_cntrct_lag
    local cluster `cluster' fe_county_lag
}
else {
    local demoFE `demoFE' fe_county
    local demoControls `demoControls' i.year

    local FE `FE' `interact'i.year `interact'fe_county

    local cluster `cluster' fe_county

    if ( "`state'" != "" ) {
        local cluster `cluster' fe_state
    }
}

* Demographics Variable w/ Interaction with Terminate
if ( "`bene_demo'" != "" ) {
    local FE `FE' `interact'i.fe_age
    local FE `FE' `interact'i.fe_sex
    local FE `FE' `interact'i.fe_race
    local FE `FE' `interact'i.mDual
}
* Demographics Variable w/o Interaction with Terminate
if ( "`bene_demo_noTerm'" != "" ) {
    local FE `FE' i.fe_age
    local FE `FE' i.fe_sex
    local FE `FE' i.fe_race
    local FE `FE' i.mDual
}

if ( "`pffsControls'" != "" ) {
    local FE `FE' i.pffs_plan
}

* Plan Size Fixed Effects
if ( "`planSizeControls'" != "" ) {
    local FE `FE' i.plan_size_dec
}

if ( "`planAgeControls'" != "" ) {
    merge m:1 cntrct pbpid state county year using "${data}/plan_age.dta", keep(1 3) gen(_plan_age)
    local FE `FE' i.plan_age
}

if ( "`dual'" != "" ) {
    local FE `FE' `interact'i.`dual'
}

* Additional sets of controls
if ( "`mutile'" != "" ) {
    local FE     `FE'     plantypeFE#mutile
    local demoFE `demoFE' plantypeFE#mutile
}

* Add Plantype x Market Share Controls
if ( ("`plantype'" != "") & ("`market_share'" != "") ) {
    * Plan Type Fixed Effects - Interaction with dum_med, year, and county
    local FE      `FE'      dum_med#i.plantypeFE year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE
    local demoFE  `demoFE'  dum_med#i.plantypeFE year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE

    local indepvars `indepvars' i.plantypeFE#c.`alphalag'
    local indepvars `indepvars' i.plantypeFE#c.frac_plan_county_lag
}
else if ("`plantype'" != ""){
    local FE      `FE'      dum_med#i.plantypeFE year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE
    local demoFE  `demoFE'  dum_med#i.plantypeFE year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE

    local indepvars `indepvars' i.plantypeFE#c.`alphalag'
}
else if ("`market_share'" != ""){
    local indepvars `indepvars' c.`alphalag'#c.frac_plan_county_lag
}


if ( ("`plantype_noMu'" != "") & ("`market_share_noMu'" != "") ) {
    * Plan Type Fixed Effects - Interaction with dum_med, year, and county
    local FE      `FE'      year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE
    local demoFE  `demoFE'  year#i.plantypeFE fe_county_lag#i.plantypeFE i.plantypeFE

    local indepvars `indepvars' i.plantypeFE#c.frac_plan_county_lag
    local indepvars `indepvars' c.frac_plan_county_lag
}

if ( "`bin_size'" != "" ) {
    local FE      `FE'      `interact'i.`bin_var'_lag
    local demoFE  `demoFE'  `interact'i.`bin_var'_lag
}


* Only include counties that have ever had a termination
if ("`county_term'" != "") {
    local addCond "& county_term_ind==1"
}
* Only inlude beneficiaries that remain in True MA Plans
else if ("`leave_trueMA'" != "") {
    local addCond "& !(true_mMA2==0)"
}
* Only calculate effect among PFFS plans
else if ("`pffs_term'" != ""){
    local addCond "& !(`terminated'==1 & PFFS_lag==0)"
}
* Calculate effect excluding PFFS plans
else if ("`excl_pffs_term'" != ""){
    local addCond "& !(`terminated'==1 & PFFS_lag==1)"
}
* Removes all controls that include terminate
else if ("`term_effect'" != ""){
    local indepvars: subinstr local indepvars "`interact'" "", all
    local FE: subinstr local FE "`interact'" "", all
}
* Exclude Small Plans
else if ( `"`small_plan'"' != "" ){
    gen small_plan = (plan_num_bene < `small_plan')
    assert !mi(small_plan)
    local addCond "& small_plan==0"
}
else if (`"`two_year_mortality'"' != ""){
}
else if ( `"`excl_small_bin'"' != "" ){
    local addCond "& !(`bin_var'_lag == `small_bin')"
}
else if ( `"`excl_small_2_bin'"' != "" ){
    local addCond "& !((`bin_var'_lag == `small_bin1') | (`bin_var'_lag == `small_bin2'))"
}
else{
    local addCond
}
disp "`addCond'"

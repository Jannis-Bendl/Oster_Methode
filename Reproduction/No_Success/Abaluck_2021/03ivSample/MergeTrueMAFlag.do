* ---------------------------------------------------------------------
* Merge trueMA

* DOC: Use flags queried from MA files to construct true_eMA and
* true_mMA flags based on eMA and mMA, respectively. Note that
* technically the true_eMA flag is a mix of the modal flag and the eMA
* flag, since we use modal enrollment to merge in the trueMA indicators.

capture program drop mergeTrueMAFlag
program mergeTrueMAFlag
    syntax, [plansuffix(str) contractsuffix(str)]

    cap drop eMA_lag
    cap drop mMA_lag
    cap drop state_lag
    cap drop county_lag
    cap drop ssacounty
    cap drop ssacounty_lag

    cap drop true*MA*
    cap drop _notMA    
    cap drop _notMA_lag
    cap drop _notMA2
    cap drop _notMA2_lag
    cap drop _county_contract
    cap drop _county_contract_lag
    cap drop _county_plan
    cap drop _county_plan_lag
    cap drop _state_contract
    cap drop _state_contract_lag
    cap drop _state_plan
    cap drop _state_plan_lag

    sort bene_code year

    by bene_code (year): gen state_lag  = state[_n - 1]
    by bene_code (year): gen county_lag = county[_n - 1]

    by bene_code (year): gen byte eMA_lag = eMA[_n - 1]
    by bene_code (year): gen byte mMA_lag = mMA[_n - 1]

    gen ssacounty     = state     + county
    gen ssacounty_lag = state_lag + county_lag

    rename (state state_lag) (ssastate ssastate_lag)

    * First merge on  by contract at the state and county level
    merge m:1 ssastate      cntrct                    using `"${data}/trueMAMergeStateContract"',     keep(1 3) gen(_state_contract)
    merge m:1 ssastate_lag  cntrct_lag                using `"${data}/trueMAMergeStateContractLag"',  keep(1 3) gen(_state_contract_lag)

    merge m:1 ssacounty     cntrct                    using `"${data}/trueMAMergeCountyContract"',    keep(1 3 4 5) gen(_county_contract)     update replace
    merge m:1 ssacounty_lag cntrct_lag                using `"${data}/trueMAMergeCountyContractLag"', keep(1 3 4 5) gen(_county_contract_lag) update replace

    * Next merge at the plan level, these files offer greater atomicity, so keep merged rows which fill in missing rows
    merge m:1 ssastate      cntrct     pbpid     year using `"${data}/trueMAMergeStatePlan"',     keep(1 3)    gen(_state_plan)
    merge m:1 ssastate_lag  cntrct_lag pbpid_lag year using `"${data}/trueMAMergeStatePlanLag"',  keep(1 3)    gen(_state_plan_lag)

    merge m:1 ssacounty     cntrct     pbpid     year using `"${data}/trueMAMergeCountyPlan"',    keep(1 3 4 5)  update gen(_county_plan)
    merge m:1 ssacounty_lag cntrct_lag pbpid_lag year using `"${data}/trueMAMergeCountyPlanLag"', keep(1 3 4 5)  update gen(_county_plan_lag)

    rename (ssastate ssastate_lag) (state state_lag)

    gen byte trueMA800     = regexm(pbpid,     "8[0-9][0-9]")
    gen byte trueMA800_lag = regexm(pbpid_lag, "8[0-9][0-9]")

    label var trueMA800     "800 series plan"
    label var trueMA800_lag "800 series plan"

    gen byte true_mMA     = mMA
    gen byte true_mMA_lag = mMA_lag

    gen byte true_eMA     = eMA
    gen byte true_eMA_lag = eMA_lag

    * DOC: Note that if the trueMA indicator is missing (i.e. merge
    * was blank) then we set MA to 0. That is, if a plan is not in the
    * enrollment files then we decided it is not labeld MA.

    gen byte _notMA     = (trueMASpecial     == 1) | (trueMANonMA     != 0) | (trueMADemo     != 0) | (trueMA800     == 1)
    gen byte _notMA_lag = (trueMASpecial_lag == 1) | (trueMANonMA_lag != 0) | (trueMADemo_lag != 0) | (trueMA800_lag == 1)

    replace true_mMA     = 0 if (_notMA     == 1) & !mi(true_mMA)
    replace true_mMA_lag = 0 if (_notMA_lag == 1) & !mi(true_mMA_lag)

    replace true_eMA     = 0 if (_notMA     == 1) & !mi(true_eMA)
    replace true_eMA_lag = 0 if (_notMA_lag == 1) & !mi(true_eMA_lag)

    ************************************************************************
    * Generate a paralel set of variables based on results of contract merge
    ************************************************************************

    * DOC: For each component variable of _notMA2 and _notMA2_lag, we  set
    * the variable according to the following logic
    *       if plan merge succeeded:
    *           trueMANonMA
    *       else if contract merge succeeded:
    *           trueMA2NonMA
    *       else:
    *            missing
    *
    * and similarly for the rest of the trueMA variables.

    gen byte trueMASpecialMerged = .
    replace  trueMASpecialMerged = trueMA2Special if (_county_contract > 2 | _state_contract > 2)
    replace  trueMASpecialMerged = trueMASpecial  if (_county_plan     > 2 | _state_plan     > 2)

    gen byte trueMANonMAMerged   = .
    replace  trueMANonMAMerged   = trueMA2NonMA   if (_county_contract > 2 | _state_contract > 2)
    replace  trueMANonMAMerged   = trueMANonMA    if (_county_plan     > 2 | _state_plan     > 2)

    gen byte trueMADemoMerged    = .
    replace  trueMADemoMerged    = trueMA2Demo    if (_county_contract > 2 | _state_contract > 2)
    replace  trueMADemoMerged    = trueMADemo     if (_county_plan     > 2 | _state_plan     > 2)

    gen byte trueMASpecialMerged_lag = .
    replace  trueMASpecialMerged_lag = trueMA2Special_lag if (_county_contract_lag > 2 | _state_contract_lag > 2)
    replace  trueMASpecialMerged_lag = trueMASpecial_lag  if (_county_plan_lag     > 2 | _state_plan_lag     > 2)

    gen byte trueMANonMAMerged_lag   = .
    replace  trueMANonMAMerged_lag   = trueMA2NonMA_lag   if (_county_contract_lag > 2 | _state_contract_lag > 2)
    replace  trueMANonMAMerged_lag   = trueMANonMA_lag    if (_county_plan_lag     > 2 | _state_plan_lag     > 2)

    gen byte trueMADemoMerged_lag    = .
    replace  trueMADemoMerged_lag    = trueMA2Demo_lag    if (_county_contract_lag > 2 | _state_contract_lag > 2)
    replace  trueMADemoMerged_lag    = trueMADemo_lag     if (_county_plan_lag     > 2 | _state_plan_lag     > 2)

    * Generate the true_mMA* variables according to the *Merged variables defined above
    gen byte true_mMA2     = mMA
    gen byte true_mMA2_lag = mMA_lag
    gen byte true_eMA2     = eMA
    gen byte true_eMA2_lag = eMA_lag

    gen byte _notMA2      = (trueMASpecialMerged     == 1) | (trueMANonMAMerged     != 0) | (trueMADemoMerged     != 0) | (trueMA800     == 1)
    gen byte _notMA2_lag  = (trueMASpecialMerged_lag == 1) | (trueMANonMAMerged_lag != 0) | (trueMADemoMerged_lag != 0) | (trueMA800_lag == 1)

    replace true_mMA2     = 0 if (_notMA2     == 1) & !mi(true_mMA2)
    replace true_mMA2_lag = 0 if (_notMA2_lag == 1) & !mi(true_mMA2_lag)
    replace true_eMA2     = 0 if (_notMA2     == 1) & !mi(true_eMA2)
    replace true_eMA2_lag = 0 if (_notMA2_lag == 1) & !mi(true_eMA2_lag)
end

capture program drop collapseAuxFiles
program collapseAuxFiles
    syntax, if(str) [pre(str)]

    * Risk scores
    * -----------

    use `"${data}/plan-data/PartCPlanLevelData.dta"', clear
        rename ContractNumber cntrct
        rename PlanBenefitPackage pbpid
        rename AverageRiskScore average_risk_score
        keep cntrct pbpid year average_risk_score
        gisid cntrct pbpid year
        keep `if'
    save `"${data}/`pre'risk_scores.dta"', replace
        bys cntrct year (pbpid): keep if _n == 1
    save `"${data}/`pre'risk_scores_cntrct.dta"', replace

    * MLR
    * ---

    local imopts varn(1) clear
    import delimited using "00common/00ssa-codes.txt", `imopts'
    keep name st
    replace st = trim(upper(st))
    rename (name st) (state abbrev)
    tempfile st
    save "`st'"

    local xlopts sheet("Landscape Data") firstrow clear
    import excel "00common/MLR and LS payers.xlsx", `xlopts'
    keep state organizationname mlr_name
    drop if mi(mlr_name)
    tempfile mlr_name
    save "`mlr_name'"

    clear
    local row_lookup_code               ///
        ACTIVITES_TO_PREVENT_HOSP_READM ///
        ADJUSTED_INCURRED_CLAIMS        ///
        ALLOWABLE_FRAUD_REDUCTION_EXP   ///
        NUMBER_OF_LIFE_YEARS            ///
        RISK_REVENUE                    ///
        DIRECT_PREMIUM_WRITTEN          ///
        ALL_OTHER_CLAIMS_ADJ_EXPENSES   ///
        COMMUNITY_BENEFIT_EXP           ///
        COMMUNITY_BENEFIT_EXPENDITURES  ///
        COST_CONTAINMENT_EXP_NOT_INCL   ///
        TOTAL_DIRECT_PREMIUM_EARNED     ///
        DIR_CLAIM_LIABILITY_CURR_YR     ///
        HITER_TO_HEALTH_IMPROVEMENT     ///
        IMPROVE_HEALTH_OUTCOMES         ///
        IMP_PAT_SAFETY_REDUCE_MED_ERRS  ///
        MEMBER_MONTHS                   ///
        NUMBER_OF_COVERED_LIVES         ///
        NUMBER_OF_GROUPS                ///
        WELLNESS_AND_HEALTH_PROM_ACTS   ///
        TOT_DEF_EXP_INCUR_IMP_HLT_CARE  ///
        PRE_EARNED_INC_FED_STATE_HRP    ///
        TOTAL_FED_AND_STATE_TAXES_FEES

    set obs `:list sizeof row_lookup_code'
    mata row_lookup_code = tokens(st_local("row_lookup_code"))'
    mata (void) st_addvar("str32", "row_lookup_code")
    mata (void) st_sstore(., "row_lookup_code", row_lookup_code)
    tempfile keep_row_codes
    save "`keep_row_codes'"

    use "${data}/mlr/2011.dta", clear
        drop if business_state == "Grand Total"

        keep year                      ///
             mr_submission_template_id ///
             business_state            ///
             group_affiliation         ///
             company_pk                ///
             company_name              ///
             domiciliary_state         ///
             naic_group_code           ///
             naic_company_code         ///
             federal_ein               ///
             dba_marketing_name        ///
             not_for_profit            ///
             row_lookup_code           ///
             government_prog_plans_yearly

        gen missing = 1
        foreach var of varlist * {
            replace missing = missing & mi(`var')
        }
        drop if missing
        drop missing
        drop if (mi(government_prog_plans_yearly) | government_prog_plans_yearly == 0)
        compress
        gduplicates drop
        rename government_prog_plans_yearly gov

        table row_lookup_code year, c(freq) format(%6.0fc) stubw(30)

        /* NOTE: Based on 2011 data dictionary,

            MLR_NUMERATOR = ADJ_INCURRED_CLAIMS
                            (total claims with permitted adjustments)
                          + TOT_DEF_EXP_INCUR_IMP_HLT_CARE
                            (total expenses for activities to improve health care quality)

            MLR_DENOMINATOR = PRE_EARNED_INC_FED_STATE_HRP
                              (total premium adjusted for payments to or from the federal and state high risk pools)
                            - TOTAL_FED_AND_STATE_TAXES_FEES
                              (total federal and state payments as adjustment to premium)
        */

        merge m:1 row_lookup_code using "`keep_row_codes'", keep(3) nogen

        * Shorten variable names so reshape will work
        replace row_lookup_code = "ACTIV_PRVENT_HOSP_READM"   if row_lookup_code == "ACTIVITES_TO_PREVENT_HOSP_READM"
        replace row_lookup_code = "ALLW_FRAUD_REDUCT_EXP"     if row_lookup_code == "ALLOWABLE_FRAUD_REDUCTION_EXP"
        replace row_lookup_code = "ALL_OTHER_CLAIMS_ADJ_EXP"  if row_lookup_code == "ALL_OTHER_CLAIMS_ADJ_EXPENSES"
        replace row_lookup_code = "COMMUNITY_BENEFIT_EXPND"   if row_lookup_code == "COMMUNITY_BENEFIT_EXPENDITURES"
        replace row_lookup_code = "COST_CONTAIN_EXP_NOT_INCL" if row_lookup_code == "COST_CONTAINMENT_EXP_NOT_INCL"
        replace row_lookup_code = "IMP_PAT_SFTY_RED_MEDERRS"  if row_lookup_code == "IMP_PAT_SAFETY_REDUCE_MED_ERRS"
        replace row_lookup_code = "WLLNSS_N_HLTH_PROM_ACTS"   if row_lookup_code == "WELLNESS_AND_HEALTH_PROM_ACTS"
        replace row_lookup_code = "FED_AND_STATE_TAXES_FEES"  if row_lookup_code == "TOTAL_FED_AND_STATE_TAXES_FEES"
        replace row_lookup_code = "TOT_EXP_IMP_HLT_CARE"      if row_lookup_code == "TOT_DEF_EXP_INCUR_IMP_HLT_CARE"

        greshape wide gov, i(mr_submission_template_id) j(row_lookup_code) string
        gen missing = 1
        foreach var of varlist * {
            replace missing = missing & mi(`var')
        }
        drop if missing
        drop missing
        compress

        rename *, lower
        renpfix gov
        gen mlr_num = adjusted_incurred_claims + tot_exp_imp_hlt_care
        gen mlr_den = pre_earned_inc_fed_state_hrp - fed_and_state_taxes_fees

        replace mlr_num = adjusted_incurred_claims if tot_exp_imp_hlt_care == .
        replace mlr_den = pre_earned_inc_fed_state_hrp if fed_and_state_taxes_fees == .

        gen mlr = (mlr_num / mlr_den)

        * this removes 84 (11%) of obs *
        drop if mlr < 0 | mlr > 2

        * merge on state codes
        rename business_state state
        merge m:1 state using "`st'", nogen keep(3)
        rename (state abbrev) (business_state state)

        keep state company_name mlr
        duplicates drop
        gisid state company_name
        rename company_name mlr_name
        merge 1:m state mlr_name using "`mlr_name'", keep(3) nogen
        keep organizationname state mlr
        gisid organizationname state
    save "${data}/mlr_2011.dta", replace
end

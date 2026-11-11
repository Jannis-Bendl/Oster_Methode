* ---------------------------------------------------------------------
* Variable labels and naming conventions (see README.md)

/* DOC
 *
 *  We apply variable labels here. Each label should explain what each
 *  variable is; the rationale and details on how each variable was created
 *  can be found in ./README.md (in this same folder).
 *
 */

capture program drop applyVariableLabels
program applyVariableLabels

    label var bene_code                      "Internal encoding of beneficiary ID"
    label var year                           "Enrollment year"
    label var zip                            "5-digit zip (bene)"
    label var state                          "SSA State (bene)"
    label var county                         "SSA County (bene)"
    label var st                             "Two-digit state abbreviation"
    label var eTM_lag                        "Lag: `:var label eTM'"
    label var mTM_lag                        "Lag: `:var label mTM'"
    label var eEmployer_lag                  "Lag: `:var label eEmployer'"
    label var mEmployer_lag                  "Lag: `:var label mEmployer'"
    label var ncounty                        "Unique counties a beneficiary has lived in the current analysis sample"
    label var state_county                   "Concatenated state + county codes"

    label var discontinuousEnrollment        "Year gap in bene enrollment data"
    label var everMissingPlan                "Contract and plan information are ever missing simultaneously"
    label var diesAfterLast                  "Last year of enrollment occurs after year of death"
    label var ndeaths_365                    "Number of distinct years of death recorded for a beneficiary (should be 0 or 1)"

    label var fe_age                         "5-year age bins"
    label var fe_age_median                  "5-year median age bins (so the age dummy is constant over time within bene)"
    label var fe_sex                         "Recoded sex codes from string to numeric"
    label var fe_race                        "Recoded race codes from string to numeric"
    label var fe_state                       "Recoded state codes from string to numeric"
    label var fe_county                      "Recoded county codes from string to numeric"
    label var fe_county_year                 "Internal encoding of state-county-year"
    label var fe_county_contract             "Internal encoding of state-county-contract"
    label var fe_county_plan                 "Internal encoding of state-county-contract-plan"

    label var fe_county_lag                  "Lag: `:var label fe_county'"
    label var cntrct_id_lag                  "Lag: `:var label cntrct_id'"
    label var pbpid_id_lag                   "Lag: `:var label pbpid_id'"
    label var plan_lag                       "Lag: `:var label plan'"
    label var cntrct_lag                     "Lag: `:var label cntrct'"
    label var pbpid_lag                      "Lag: `:var label pbpid'"

    label var landscape_year                 "Last year plan appears in landscape file"
    label var code_xw                        "Whether to keep a plan based on the plan info XW (see README for details)"
    label var code_cxw                       "Whether to keep a contract based on the plan info XW (see README for details)"
    label var relationship_code              "Plan relationship code from plan info files"
    label var relationship_ccode             "Contract relationship code == 'C' (any plan relationship_code == 'C')"
    label var relationship_code_lag          "Lag: `:var label relationship_code'"
    label var relationship_ccode_lag         "Lag: `:var label relationship_ccode'"

    label var lagmean_died_365_plan          "Average mortality in T - 1 county-contract-plan the year T - 1"
    label var lagmean_died_365_contract      "Average mortality in T - 1 county-contract the year T - 1"
    label var delta_died_365_plan            "died_365 - lagmean_died_365_plan (note died_365 is 0/1)"
    label var delta_died_365_contract        "died_365 - lagmean_died_365_contract (note died_365 is 0/1)"

    label var disappeared_plan               "I(plan disappears after current year: no enrollment)"
    label var discontinuous_plan             "I(plan disappears next year but reappears after)"
    label var last_year                      "Last year plan is seen in the data"
    label var disappeared_contract           "I(contract disappears after current year: no enrollment)"
    label var discontinuous_contract         "I(contract disappears next year but reappears after)"
    label var last_year_contract	     "Last year contract is seen in the data"

    label var last_year_lag                  "Lag: `:var label last_year'"
    label var disappeared_plan_lag           "Lag: `:var label disappeared_plan'"
    label var discontinuous_plan_lag         "Lag: `:var label discontinuous_plan'"
    label var disappeared_contract_lag       "Lag: `:var label disappeared_contract'"
    label var last_year_contract_lag         "Lag: `:var label last_year_contract'"
    label var discontinuous_contract_lag     "Lag: `:var label discontinuous_contract'"

    label var disappeared_landscape_auxa     "Auxilary var: year is landscape_year, is 1, code_xw is 1"
    label var disappeared_landscape_auxb     "Auxilary var: disappeared_landscape_auxa and relationship_code not C"
    label var disappeared_landscape1         "Landscape term: disappeared_landscape_auxb and relationship_code not R"
    label var disappeared_plan_auxb          "Auxilary var: disappeared_plan and relationship_code not C"
    label var disappeared_plan1              "Alt plan term: disappeared_plan_auxb and relationship_code not R"
    label var disappeared_contract1          "disappeared_plan1 = 1 for every plan in contract-county"
    label var disappeared_clandscape1        "disappeared_landscape1 = 1 for every plan in contract-county"
    label var disappeared_landscape1_lag     "Lag: `:var label disappeared_landscape1'"
    label var disappeared_plan1_lag          "Lag: `:var label disappeared_plan1'"
    label var disappeared_contract1_lag      "Lag: `:var label disappeared_contract1'"
    label var disappeared_clandscape1_lag    "Lag: `:var label disappeared_clandscape1'"

    label var state_lag                      "Lag: `:var label state'"
    label var county_lag                     "Lag: `:var label county'"
    label var eMA_lag                        "Lag: `:var label eMA'"
    label var mMA_lag                        "Lag: `:var label mMA'"
    label var pffs_plan                      "Plan iS PFFS"
    label var pffs_plan_lag                  "Lag: `:var label pffs'"

    label var Txpffs_plan_lag                "disappeared_plan_lag x pffs_plan_lag (TM and 'other' set to 0)"
    label var Txpffs_plan1_lag               "disappeared_plan1_lag x pffs_plan_lag (TM and 'other' set to 0)"
    label var Txpffs_landscape1_lag          "disappeared_landscape1_lag x pffs_plan_lag (TM and 'other' set to 0)"
    label var Txpffs_contract_lag            "disappeared_contract_lag x pffs_cntrct_lag (TM and 'other' set to 0)"
    label var Txpffs_contract1_lag           "disappeared_contract1_lag x pffs_cntrct_lag (TM and 'other' set to 0)"
    label var Txpffs_clandscape1_lag         "disappeared_clandscape1_lag x pffs_cntrct_lag (TM and 'other' set to 0)"

    label var Txpffs_plan                    "disappeared_plan x pffs_plan (TM and 'other' set to 0)"
    label var Txpffs_plan1                   "disappeared_plan1 x pffs_plan (TM and 'other' set to 0)"
    label var Txpffs_landscape1              "disappeared_landscape1 x pffs_plan (TM and 'other' set to 0)"
    label var Txpffs_contract                "disappeared_contract x pffs_cntrct (TM and 'other' set to 0)"
    label var Txpffs_contract1               "disappeared_contract1 x pffs_cntrct (TM and 'other' set to 0)"
    label var Txpffs_clandscape1             "disappeared_clandscape1 x pffs_cntrct (TM and 'other' set to 0)"

    label var nbene_contract_county          "# distinct benes in the county-contract-year"
    label var nbene_plan_county              "# distinct benes in the county-plan-year"
    label var nbene_county                   "# distinct benes in the county-year"
    label var nbene_all_contract_county      "# distinct benes in the county-contract across all years"
    label var nbene_all_plan_county          "# distinct benes in the county-plan across all years"
    label var nbene_all_county               "# distinct benes in the county across all years"

    label var ssacounty                      "True MA: `:var label ssacounty'"
    label var ssacounty_lag                  "True MA: Lag: `:var label ssacounty'"
    label var trueMANoPartD                  "True MA: `:var label trueMANoPartD'"
    label var trueMASpecial                  "True MA: `:var label trueMASpecial'"
    label var trueMANonMA                    "True MA: `:var label trueMANonMA'"
    label var trueMADemo                     "True MA: `:var label trueMADemo'"
    label var trueMANoPartD_lag              "True MA: Lag: `:var label trueMANoPartD'"
    label var trueMASpecial_lag              "True MA: Lag: `:var label trueMASpecial'"
    label var trueMANonMA_lag                "True MA: Lag: `:var label trueMANonMA'"
    label var trueMADemo_lag                 "True MA: Lag: `:var label trueMADemo'"
    label var trueMA800                      "True MA: `:var label trueMA800'"
    label var trueMA800_lag                  "True MA: Lag: `:var label trueMA800'"

    label var true_mMA                       "Plan is considered 'true MA' based on mMA (see 03ivSample/TrueMAFlag.do)"
    label var true_mMA_lag                   "Lag: Plan is considered 'true MA' based on mMA (see 03ivSample/TrueMAFlag.do)"
    label var true_eMA                       "Plan is considered 'true MA' based on eMA (see 03ivSample/TrueMAFlag.do)"
    label var true_eMA_lag                   "Lag: Plan is considered 'true MA' based on eMA (see 03ivSample/TrueMAFlag.do)"
    label var _notMA                         "Aux variavble to compute true_*MA flags"
    label var _notMA_lag                     "Aux variavble to compute true_*MA_lag flags"

    foreach varset in what_* wnoc_* {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                if ( regexm(`"`var'"', "_lag$") ) {
                    label var `var' "Lag: Unshrunk plan county mean; see 03ivSample/README.md for naming conventions"
                }
                else {
                    label var `var' "Unshrunk plan county mean; see 03ivSample/README.md for naming conventions"
                }
            }
        }
    }

    * foreach varset in lambda_* lnoc_* {
    *     cap ds `varset'
    *     if ( _rc == 0 ) {
    *         foreach var of varlist `varset' {
    *             if ( regexm(`"`var'"', "_lag$") ) {
    *                 label var `var' "Lag: Plan shrinkage coefficient; see 03ivSample/README.md for naming conventions"
    *             }
    *             else {
    *                 label var `var' "Plan shrinkage coefficient; see 03ivSample/README.md for naming conventions"
    *             }
    *         }
    *     }
    * }

    foreach varset in u* mu* {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                muNamingConventionLabel `var'
            }
        }
    }
end

capture program drop muNamingConventionLabel
program muNamingConventionLabel
    args var

    local regex = "(mu|muhat|u)(county|c|)(noc|)(.+bin|)_(mle|fe|mleaux)(CY|County)(?:Misc|Old|New)?(B|AB|YB|BND|BAD|)(Plan|Contract|Org)(_lag|)"
    if !ustrregexm("`var'", "`regex'") {
        c_local lbl "See 03ivSample/README.md for naming conventions"
        exit 0
    }

    if ustrregexs(7) == "B"   local bin " by plan bins"
    if ustrregexs(7) == "BAD" local bin " by plan bins"
    if ustrregexs(7) == "AB"  local bin " by plan-age bins"
    if ustrregexs(7) == "YB"  local bin " by plan-year bins"
    if ustrregexs(7) == "BND" local bin " by plan bins (no dual)"

    local lag    = cond(ustrregexs(9) == "_lag", "Lag: ", "")
    local shrunk = cond(ustrregexs(5) == "mle",  "shrunk", "raw unshrunk")
    local hier   = cond(ustrregexs(1) == "u",    "", "hierarchical-")
    local Level  = cond(ustrregexs(8) == "Org", "Organization", ustrregexs(8))

    local lbl "`lag'`Level' `hier'`shrunk'`bin'"

    local comma " w/"
    if ustrregexs(6) == "CY" {
        local lbl "`lbl'`comma'county-year FE"
            local comma ", "
    }

    if ustrregexs(6) == "County" {
        local lbl "`lbl'`comma'county FE, year FE"
            local comma ", "
    }

    if ustrregexs(2) != "" {
        local lbl "`lbl'`comma'county mean"
            local comma ", "
    }

    if ustrregexs(4) != "" {
        local lbl "`lbl'`comma'bin mean"
            local comma ", "
    }

    if ustrregexs(3) != "" {
        local lbl "`lbl'; no demo controls"
    }

    if ustrregexs(7) == "BAD" {
        local lbl "`lbl'; control for age and dual only"
    }

    if (length("`lbl'") > 80) {
        char `var'[label] `lbl'
        disp "note: truncated labels saved as variable characteristics named 'label'"
        local lbl = substr("`lbl'", 1, 77) + "..."
    }

    label var `var' "`lbl'"
end

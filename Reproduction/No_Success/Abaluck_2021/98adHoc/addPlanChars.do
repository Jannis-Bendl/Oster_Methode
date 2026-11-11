* ---------------------------------------------------------------------
* Title:    Add Plan Characteristic Variables (Plan Premiums, Part D Data,
*           MLR, HVAM)
* Program:  addPlanChars
* Blame:    Emily Crawford (emily.crawford@yale.edu)
* Created:  Wednesday, June 10th, 2020
* Updated:  Tuesday, February 16th 2021
* Purpose:  Merges plan characteristic variables from landscape files.
* Note:     This file runs as part of Sample Selection 2.
*           We attempt to merge plan characteristic variables to 03ivSample
*           dataset by plan (pbpid). If there is no match by plan, then we
*           attempt a merge by contract (cntrct).
*
* cms_ls_2008_2011 -> _19ma_chars_old
* cms_ls_2008_2011_cntrct_level -> _19ma_chars_cntrct_level_old
* ---------------------------------------------------------------------

* NOTE: HVAM not currently used
gen hvam = 0
gen hvam_lag = 0

local plan_chars typeofmedicarehealthplan ///
                 monthly_premium          ///
                 partd_offered            ///
                 gap_coverage             ///
                 mlr                      /// hvam ///
                 organizationname         ///
                 average_star

mergePlanContractVariables,  mergeby(ssacounty)    ///
    contractFile(${data}/`pre'ma_chars_cntrct.dta) ///
    planFile(${data}/`pre'ma_chars.dta)            ///
    keepvars(`plan_chars')                         ///
    prefix(plan_chars_)

mergePlanContractVariables,  mergeby(year)            ///
    contractFile(${data}/`pre'risk_scores_cntrct.dta) ///
    planFile(${data}/`pre'risk_scores.dta)            ///
    keepvars(average_risk_score)                      ///
    prefix(risk_score_)

rename average_star* star_rating*

* NOTE: This groups missing types together instead of dropping them.
replace typeofmedicarehealthplan     = "BLANK" if mi(typeofmedicarehealthplan)
replace typeofmedicarehealthplan_lag = "BLANK" if mi(typeofmedicarehealthplan_lag)

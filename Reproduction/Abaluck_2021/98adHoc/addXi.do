* ---------------------------------------------------------------------
* Title:   Calculates xi to be used in plan characteristic regressions.
* Blame:   Emily Crawford (emily.crawford@yale.edu)
* Created: Friday, March 13th 2020
* Updated: Tuesday, July 7th 2020
*          Tuesday, February 16th 2021
* Purpose: Calculates the adjusted and unadjusted xi variables, that will
*          be used in the plan characteristic regressions.
* Trello:  https://trello.com/c/zLeGaL4r/245-xi-plan-characteristic-regression
* ---------------------------------------------------------------------

local _lag
gen annual_premium`_lag' = 12 * monthly_premium`_lag'
tempname xi
frame put year state`_lag' county`_lag' pbpid_id`_lag' cntrct_id`_lag' true_mMA2`_lag' annual_premium`_lag', into(`xi')
frame `xi' {
    addXi, `_lag'
    tempfile XiMerge
    save `"`XiMerge'"'
}

local _lag _lag
gen annual_premium`_lag' = 12 * monthly_premium`_lag'
tempname xi
frame put year state`_lag' county`_lag' pbpid_id`_lag' cntrct_id`_lag' true_mMA2`_lag' annual_premium`_lag', into(`xi')
frame `xi' {
    addXi, `_lag'
    tempfile LagXiMerge
    save `LagXiMerge'
}

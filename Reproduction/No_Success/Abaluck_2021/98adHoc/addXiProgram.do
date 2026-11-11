capture program drop addXi
program addXi
    syntax, [_lag]

    * Define outside plans as those that are not "true MA"
    *---------------------------------------------------------------------------
    gen pbpid_id_outside_ind`_lag' = pbpid_id`_lag'
    replace pbpid_id_outside_ind`_lag' = -10 if true_mMA2`_lag' == 0

    gen cntrct_id_outside_ind`_lag' = cntrct_id`_lag'
    replace cntrct_id_outside_ind`_lag' = -10 if true_mMA2`_lag' == 0

    * Collapse plans, summing over enrollment
    *---------------------------------------------------------------------------
    local by state`_lag' county`_lag' year cntrct_id_outside_ind`_lag' pbpid_id_outside_ind`_lag'
    gcollapse (mean) annual_premium`_lag', by(`by') freq(enroll`_lag')
    gisid `by'

    * Calculate total enrollment over each county-year
    *---------------------------------------------------------------------------
    gegen total_enroll_county`_lag' = total(enroll`_lag'), by(state`_lag' county`_lag' year)
    gen percent_enroll`_lag' = enroll`_lag' / total_enroll_county`_lag'

    * Sanity check that summing market share over county-year is equal to 1
    gegen  counter = total(percent_enroll`_lag'), by(state`_lag' county`_lag' year)
    assert abs(1 - counter) <= 1e-6
    drop counter

    * Create Variable of Outside Plan Market Share for Each Observation
    *---------------------------------------------------------------------------

    gen byte _outsideplan_share = ((pbpid_id_outside_ind`_lag' == -10) & (cntrct_id_outside_ind`_lag' == -10))
    gegen _outsideplan_share = max(_outsideplan_share), by(state`_lag' county`_lag' year) replace
    bys state`_lag' county`_lag' year (_outsideplan_share): gen outside_plan_percent_enroll`_lag' = percent_enroll`_lag'[_N] if _outsideplan_share
    tab _outsideplan_share

    gen log_percent_enroll`_lag' = ln(percent_enroll`_lag')
    assert !missing(log_percent_enroll`_lag') | (_outsideplan_share == 0)

    gen log_out_plan_perc_enroll`_lag' = ln(outside_plan_percent_enroll`_lag')
    replace log_out_plan_perc_enroll`_lag' = 0 if _outsideplan_share
    assert !missing(log_out_plan_perc_enroll`_lag') | (_outsideplan_share == 0)

    * _outsideplan_share == 1 if county-year has no outside plans and 3
    * if it does; this mimics old code where _outsideplan_share was a
    * merge indicator.
    replace _outsideplan_share = cond(_outsideplan_share, 3, 1)

    * Define Xi #1
    *---------------------------------------------------------------------------
    gen delta`_lag'  = log_percent_enroll`_lag' // - log_out_plan_perc_enroll`_lag'
    gen xi_one`_lag' = delta`_lag'

    drop outside_plan_percent_enroll`_lag'
    drop if ((pbpid_id_outside_ind`_lag' == -10) & (cntrct_id_outside_ind`_lag' == -10))
    assert !mi(delta`_lag')
    assert !mi(xi_one`_lag')

    rename (pbpid_id_outside_ind`_lag' cntrct_id_outside_ind`_lag') (pbpid_id`_lag' cntrct_id`_lag')
    compress

    * Define Xi #2
    *---------------------------------------------------------------------------
    gen A_jt`_lag' = annual_premium`_lag' * (1 - percent_enroll`_lag')
    qui summarize A_jt`_lag' [aw = enroll`_lag']
    scalar mean_A_jt`_lag' = r(mean)

    gen kappa`_lag'  = -3.5 * (1 / mean_A_jt`_lag')
    gen xi_two`_lag' = delta`_lag' - (kappa`_lag' * annual_premium`_lag')
    assert !mi(xi_two`_lag')

    * Different Values of Kappa
    local kappa -10  ///
                -7   ///
                -3.5 ///
                -3   ///
                -1   ///
                -0.5

    local suff  A ///
                B ///
                C ///
                D ///
                E ///
                F

    forvalues i = 1 / 6 {
        local k: word `i' of `kappa'
        local s: word `i' of `suff'
        gen kappa`_lag'`s'  = `k' * (1 / mean_A_jt`_lag')
        gen xi_two`_lag'`s' = delta`_lag' - (kappa`_lag'`s' * annual_premium`_lag')
        assert !mi(xi_two`_lag'`s')
    }

    * Save Contemporary or Lag Plan Dataset
    *---------------------------------------------------------------------------
    rename delta`_lag' ln_marketshare`_lag'
    keep year state`_lag' county`_lag' cntrct_id`_lag' pbpid_id`_lag' ln_marketshare`_lag' xi_one* xi_two* kappa*
    gisid year state`_lag' county`_lag' cntrct_id`_lag' pbpid_id`_lag'
end

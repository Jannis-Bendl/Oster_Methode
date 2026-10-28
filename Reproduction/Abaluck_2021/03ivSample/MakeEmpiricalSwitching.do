capture program drop makeSwitching
program makeSwitching
    syntax, pct(str) [replace]

    gen byte switch_missing = mi(fe_county) | mi(pbpid_id) | mi(cntrct_id) | mi(fe_county_lag) | mi(pbpid_id_lag) | mi(cntrct_id_lag)

    gen byte  switch_plan     = 0
    replace switch_plan = 1 if (fe_county_lag != fe_county) | (pbpid_id != pbpid_id_lag) | (cntrct_id != cntrct_id_lag)
    replace switch_plan = . if switch_missing

    gen byte  switch_plan_same_cntrct = 0
    replace switch_plan_same_cntrct = (fe_county_lag == fe_county) & (cntrct_id_lag == cntrct_id) & (pbpid_id_lag != pbpid_id)
    replace switch_plan_same_cntrct = . if switch_missing
    
    gen byte switch_cntrct = 0
    replace switch_cntrct = 1 if (fe_county_lag != fe_county) | (cntrct_id_lag != cntrct_id)
    replace switch_cntrct = . if switch_missing

    local plan_lag fe_county_lag cntrct_id_lag pbpid_id_lag
    local vars year `plan_lag' switch_plan switch_missing

    tempname switching
    frame put `vars', into(`switching')
    frame `switching' {
        gcollapse (mean) p_switch_plan_yr_lag = switch_plan (sum) switch_missing, by(`plan_lag' year)

        gisid fe_county_lag cntrct_id_lag pbpid_id_lag year, missok
        assert !mi(p_switch_plan_yr_lag) | switch_missing
        rename switch_missing nswitch_missing

        foreach p in 80 90 {
            * % Threshold for Switch Plan
            gen plan_`p'_leave_lag = 0
            replace plan_`p'_leave_lag = 1 if p_switch_plan_yr_lag >= `=`p' / 100'

            gegen min_year_`p'_term = min(year) if plan_`p'_leave_lag == 1, by(`plan_lag')
            gegen min_year_`p'_term = max(min_year_`p'_term), by(`plan_lag') replace

            * Create Termination Indicator
            gen dis_plan_`p'_lag = 0
            replace dis_plan_`p'_lag = 1 if year == min_year_`p'_term

            * Create Post Termination Indicator
            gen dis_plan_`p'_post_lag = 0
            replace dis_plan_`p'_post_lag = 1 if year > min_year_`p'_term

            * Checks
            assert dis_plan_`p'_lag <= 1
            assert !mi(dis_plan_`p'_lag)
            assert !mi(dis_plan_`p'_post_lag)
        }

        save `"${data}/plan_switched`pct'_lag.dta"', `replace'
    }
end

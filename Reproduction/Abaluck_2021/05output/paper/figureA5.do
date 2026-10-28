* e.g. make figureA5 PCT="01" PRE="_19" &
local 0: subinstr local 0 ";" ","
syntax, pct(str) pre(str)

* Start-up
version 13
clear all
capture log close _all

* Options
set more off
set varabbrev off
set linesize 100
set matsize 11000
set maxvar 50000
set scheme burd4

* Programs
qui do "00common/00preamble.do"
qui do "00common/00material.do"
include "04analysis/Parse/FigureOptions.do"

cap mkdir "${out}/fig"
cap mkdir "${out}/logs"

log using "${out}/logs/`pre'figureA5_`pct'pct.log", replace

capture program drop main
program main
    syntax, pct(str) pre(str)
    get_ventile_plots, pct(`pct') pre(`pre')
end


capture program drop get_ventile_plots
program get_ventile_plots
    syntax, pct(str) pre(str)
    get_year_mus,    pre(`pre') pct(`pct')
    ventile_mu_plot, pre(`pre') pct(`pct') type(Hierarchical) u(mucounty_mleCYYBPlan) amin(-0.04) amax(0.04)
    * ventile_mu_plot, pre(`pre') pct(`pct') type(Unshrunk)     u(u_feCYYBPlan)         amin(-0.04) amax(0.04)
    * ventile_mu_plot, pre(`pre') pct(`pct') type(Hierarchical) u(mucyearbin_mleCYYBPlan) note(; bin-level mortality averages added)

    * u_feCYYBPlan mucyearbin_mleCYYBPlan
    local vars mucounty_mleCYYBPlan 
    foreach u of local vars {
        shell convert -quality 100 "${out}/fig/YearBin`pre'_`pct'pct_common_`u'.svg" "${out}/fig/YearBin`pre'_`pct'pct_common_`u'.png"
    }
end


capture program drop get_year_mus
program get_year_mus
    syntax, pre(str) pct(str)

    local vars u_feCYYBPlan mucounty_mleCYYBPlan mucyearbin_mleCYYBPlan
    use `"${data}/`pre'alphas`pct'.dta"', clear
        gcontract bin_num bin_year fe_county plan `vars', f(nbene)
        gisid     bin_num bin_year fe_county plan

        greshape wide `vars' nbene, i(bin_num fe_county plan) j(bin_year)

        label var bin_num                     "Plan size bin number"
        label var fe_county                   "Encoded county ID (internal)"
        label var plan                        "Encoded modal contract-plan ID (internal)"
        label var u_feCYYBPlan1               "Unshrunk plan effect (2006-2008)"
        label var u_feCYYBPlan2               "Unshrunk plan effect (2009-2011)"
        label var mucounty_mleCYYBPlan1       "Hierarchical shrunk plan effect (2006-2008)"
        label var mucounty_mleCYYBPlan2       "Hierarchical shrunk plan effect (2009-2011)"
        label var mucyearbin_mleCYYBPlan1     "Hierarchical shrunk plan effect with bin mean (2006-2008)"
        label var mucyearbin_mleCYYBPlan2     "Hierarchical shrunk plan effect with bin mean (2009-2011)"
        label var nbene1                      "Number of beneficiaries (2006-2008)"
        label var nbene2                      "Number of beneficiaries (2009-2011)"
end


capture program drop ventile_mu_plot
program ventile_mu_plot
    syntax, pre(str) pct(str) u(str) type(str) [note(str) amin(real 0) amax(real 0)]

    preserve

    drop if mi(nbene1) | mi(nbene2)
    fasterxtile ven1 = `u'1 [fw = nbene1], nq(20)
    fasterxtile ven2 = `u'2 [fw = nbene2], nq(20)

    gegen u1  = mean(`u'1) [fw = nbene1], by(ven1)
    gegen u2  = mean(`u'2) [fw = nbene2], by(ven1)
    gegen sd1 = sd(`u'1)   [fw = nbene1], by(ven1)
    gegen sd2 = sd(`u'2)   [fw = nbene2], by(ven1)

    * gegen u1  = max(u1),  by(ven1) replace
    * gegen u2  = max(u2),  by(ven1) replace
    * gegen sd1 = max(sd1), by(ven1) replace
    * gegen sd2 = max(sd2), by(ven1) replace

    keep u? sd? ven1
    gduplicates drop
    gen diff = u2 - u1
    sort ven1

    format %9.3f u? diff
    rename (ven1 u1 u2) (Ventiles_2006_2008 mu_2006_2008 mu_2009_2011)
    list Ventiles_2006_2008 mu_2006_2008 mu_2009_2011 diff, sep(0) abbrev(32) noobs
    rename (Ventiles_2006_2008 mu_2006_2008 mu_2009_2011) (ven1 u1 u2)

    gen h = u2 + sd2
    gen l = u2 - sd2

    local _max = 0
    local _min = 0
    foreach var of varlist u? l h {
        qui sum `var', meanonly
        local _min = min(`_min', `=r(min)')
        local _max = max(`_max', `=r(max)')
    }
    if (`amin' == 0) local amin = `_min'
    if (`amax' == 0) local amax = `_max'
    gen deg45 = `amin' + (ven1 - 1) * (`amax' - `amin') / (ven1[_N] - 1)

    sort u1
    local ptitle title("`type' plan mu by year 2009-2011 ventiles")
    local ptitle title("`type' plan mu by year 2006-2008 ventiles")
    local atitle "Plan Observational Mortality"

    local notea  `"Plans in both halves only; means are beneficiary-weighted separately in each half."'
    local noteb  `"`type' plan effects by plan size and year bins`note'."'
    local note   note(`"`notea'"' `"`noteb'"')
    local legend legend(order(2 `"Average"' 3 `"SD"' 1 `"45 degree"') cols(3))
    local ylab  ylab(-0.03(0.02)0.03) yscale(range(-0.03 0.03))
    local xlab  xlab(-0.03(0.02)0.03) xscale(range(-0.03 0.03))
    local xopts fontface("LM Roman 10") width(1600px) height(1200px) replace

    local 45opts  lwidth(0.25)
    local 45opts  `45opts' lpattern(solid)
    local 45opts  `45opts' lcolor("${material_gray_500}")

    local lopts   lwidth(0.5 0.5)
    local lopts   `lopts' lpattern(dash dash)
    local lopts   `lopts' lcolor("${material_blue_300}" "${material_blue_300}")

    local opts    mcolor("${material_blue_900}") msymbol(circle)
    local opts    `opts' yscale(range(`amin' `amax'))
    local opts    `opts' xscale(range(`amin' `amax'))
    local opts    `opts' xtitle("`atitle', 2006-2008")
    local opts    `opts' ytitle("`atitle', 2009-2011")

    local scatter scatter u2 u1, `opts'
    local line    line h l u1, `lopts'
    local 45deg   line deg45 deg45, `45opts'

    twoway (`45deg') (`scatter') (`line'), `legend' `ylab' `xlab'
    graph export `"${out}/fig/YearBin`pre'_`pct'pct_common_`u'.svg"', `xopts'

    * twoway (`45deg') (`scatter') (`line'), `legend' `ptitle' `note'
    * graph export `"${out}/fig/YearBin`pre'_`pct'pct_common_`u'_titlenote.svg"', `xopts'

    restore
end


main, pct(`pct') pre(`pre')

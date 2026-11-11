local 0: subinstr local 0 ";" ","

* -----------------
* Parse CLi options
* -----------------

* NOTE: This assumes none of these locals have been defined.
* This should be OK since the only two things run before this
* file are 00common/00preamble, which defines globals, and
* 04analysis/AnalysisConfigurations/`tag'.do, which should only
* define the local `options'.

local g04ivReg_required pct(str asis)        ///
                        TERMinated(str asis) ///
                        alpha(str asis)      ///
                        tag(str asis)
local g04ivReg_level    cntrct plan
local g04ivReg_options  replace              ///
                        agebinned            ///
                        stacked              ///
                     	nosave               ///
                     	allsample            ///
                        tmsample             ///
                        savesuffix(str asis) ///
                        dual(str asis)       ///
                        noYEAR               ///
                        deciles              ///
                        controlsNormalized   ///
                        dropDec              ///
                        forcema(str asis)    ///
                        ivcontrols(str asis) ///
                        pre(str asis)        ///
                        global_meds          ///
                        quantile_by_year     ///
                        ifglobal(str asis)   ///
                        ifpost(str asis)     ///
                        ifmibin(str asis)    ///
                        ifmitrueMA(str asis) ///
                        versions(str asis)   ///
                        noINTERact           ///
                        anyterm              ///
                        plain                ///
                        indepvars(str asis)  ///
                        dropAlphaLag         ///
                        pffsControls         ///
                        planAgeControls      ///
                        planSizeControls     ///
                        parentOrgs           ///
                        feCountyLag          ///
                        feCntrctLag          ///
                        lagMortalityBalance  ///
                        state                ///
                        multiStateFE         ///
                        tm(str asis)         ///
                        employer(str asis)   ///
                        addTM                ///
                        addEmployer          ///
                        plotsTag(str asis)   ///
                        xlwb(str asis)       ///
                        xlsheet(str asis)    ///
                        plotsVersion(int 6)  ///
                        ifcommand(str asis)  ///
                        ifconsol(str asis)   ///
                        ifpostterm(str asis) ///
                        ifempterm(str asis)  ///
                        cntrctYear           ///
                        cy                   ///
                        plantype             ///
                        market_share         ///
                        bene_demo            ///
                        bene_demo_noTerm     ///
                        plantype_noMu        ///
                        market_share_noMu    ///
                        county_term          ///
                        leave_trueMA         ///
                        pffs_term            ///
                        risk_score_control   ///
                        bin_size             ///
                        addXi                ///
                        remove_dua           ///
                        term_effect          ///
                        age_effect           ///
                        excl_pffs_term       ///
                        small_plan(str asis) ///
                        raw_alpha(str asis)  ///
                        dtilde(str asis)     ///
                        predictMortality     ///
                        addDec               ///
                        two_year_mortality   ///
                        jack_knife           ///
                        excl_consol          ///
                        bin_var(str asis)    ///
                        bin_suf(str asis)    ///
                        fesuf(str asis)      ///
                        excl_small_bin       ///
                        excl_small_2_bin     ///
                        small_bin(str asis)  ///
                        small_bin1(str asis) ///
                        small_bin2(str asis) ///
                        eta_control          ///
                        eta_ind_control      ///
                        pffs_contemp         ///
                        pffs_excl_contemp    ///
                        remerge_truema(str asis) ///


mata st_local("OldMacros", invtokens(st_dir("local", "macro", "*")'))
syntax, `g04ivReg_required' [`g04ivReg_level' `g04ivReg_options']
mata st_local("NewMacros", invtokens(st_dir("local", "macro", "*")'))
local NewMacros: list NewMacros - OldMacros

* --------
* Defaults
* --------

if ( `:list posof "versions" in NewMacros' == 0 ) {
    local versions 1B 1D 1F 1H
    local NewMacros `NewMacros' versions
}

* ---------------------------
* Copy options to parent file
* ---------------------------

foreach option of local NewMacros {
    if ( "`option'" != "OldMacros" ) {
        disp %-32s `"`option': "', `"``option''"'
        c_local `option': copy local `option'
    }
}

if ( "`cntrct'" != "" ) {
    c_local level      cntrct_id
    c_local level_lag  cntrct_id_lag
    c_local contract   contract
}
else {
    c_local level      cntrct_id     pbpid_id
    c_local level_lag  cntrct_id_lag pbpid_id_lag
    c_local contract   plan
}

c_local alphalag `alpha'_lag
disp "The mu variable is `alphalag'."

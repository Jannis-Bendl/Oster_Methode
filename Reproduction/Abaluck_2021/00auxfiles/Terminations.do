capture program drop terminations
program terminations
    syntax, syear(passthru)

    stateCrosswalk
    countyCrosswalk, `syear'

    mergeStateAndCounty
    landscapeTerminations
end

capture program drop stateCrosswalk
program stateCrosswalk
    import delimited using "00common/00ssa-codes.txt", varn(1) stringc(2 3) clear
        foreach var of varlist * {
            if regexm(`"`:type `var''"', "str") replace `var' = trim(upper(`var'))
        }
        compress
    save `"${data}/state_xw.dta"', replace
end

capture program drop countyCrosswalk
program countyCrosswalk
    syntax, syear(int)

    * DOC: This is the NBER SSA to State-County crosswalks. In the
    * landscape files we have a state abbreviation and a county name,
    * whereas in the CMS data we have SSA codes.

    tempfile xw
    local ssaxw /homes/data/ssa-fips-state-county-crosswalk
    forvalues year = 2011 / 2018 {
        if ( `year' >= 2018 ) {
            use `"`ssaxw'/`year'/xwalk`year'"', clear
                rename *, lower
                rename county_name county
                rename ssacd ssacounty
                keep state county ssacounty
                gen ssastate = substr(ssacounty, 1, 2)
                gduplicates drop state county, force
                compress
        }
        else {
            use `"`ssaxw'/`year'/ssa_fips_state_county`year'"', clear
                keep state county ssacounty ssastate
                gduplicates drop state county, force
                compress
        }

        if ( `year' > 2011 ) {
            gen year = `year'
            append using `"`xw'"'
        }
        else {
            expand `=2011 - `syear' + 1'
            bys state county ssacounty ssastate: gen year = _n + `syear' - 1
        }
        save `"`xw'"', replace
    }
    * cleanStateCounty, replace
    cleanStateCounty
    drop if mi(county)    | mi(state)
    drop if mi(ssacounty) | mi(ssastate)
    gduplicates drop
    gisid state county year

    save `"${data}/county_xw.dta"', replace
end

capture program drop cleanStateCounty
program cleanStateCounty
    syntax, [replace dc]
    replace county = trim(upper(county))
    replace state  = trim(upper(state))
    if ( `"`dc'"' != "" ) {
        replace county = "DISTRICT OF COLUMBIA" if county == "THE DISTRICT" & state == "DC"
    }
    if ( `"`replace'"' != "" ) {
        replace county = regexr(county, "BOROUH", "BOROUGH")
        replace county = regexr(county, " BOROUGH$", "")
        replace county = "DISTRICT OF COLUMBIA" if county == "THE DISTRICT"     & state == "DC"
        replace county = "NORTHWEST ARCTIC"     if county == "NORTHWEST ARTIC"  & state == "AK"
        replace county = "EASTBATON ROUGE"      if county == "E. BATON ROUGE"   & state == "LA"
        replace county = "JEFFERSON DAVIS"      if county == "JEFFRSON DAVIS"   & state == "LA"
        replace county = "ST JOHN THE BAPTIST"  if county == "ST. JOHN BAPTIST" & state == "LA"
        replace county = "WESTBATON ROUGE"      if county == "W. BATON ROUGE"   & state == "LA"
        replace county = "LAKE OF THE WOODS"    if county == "LAKE OF  WOODS"   & state == "MN"
        replace county = "YELLOW MEDICINE"      if county == "YELLOW MEDCINE"   & state == "MN"
        replace county = "SCOTTS BLUFF"         if county == "SCOTT BLUFF"      & state == "NE"
        replace county = "NORTHUMBERLAND"       if county == "NORTHUMBERLND"    & state == "PA"
        replace county = "NORTHUMBERLAND"       if county == "NORTHUMBERLND"    & state == "VA"
        replace county = "POQUOSON CITY"        if county == "POQUOSON"         & state == "VA"
        replace county = "MENOMINEE"            if county == "MENOMONEE"        & state == "WI"
        replace county = "DADE"                 if county == "MIAMI-DADE"       & state == "FL"
        replace county = "DADE"                 if county == "MIAMI"            & state == "FL"

        replace county = subinstr(county, " ", "", .)
        replace state  = subinstr(state,  " ", "", .)

        qui count if regexm(county, "[^A-Z]")
        while `r(N)' {
            replace county = regexr(county, "[^A-Z]", "")
            qui count if regexm(county, "[^A-Z]")
        }
    }
end

capture program drop mergeStateAndCounty
program mergeStateAndCounty
    use `"${data}/landscape/ma"', clear
        rename *, lower
        replace county = trim(upper(county))
        replace state  = trim(upper(state))
        drop if mi(state) | mi(county) | mi(contractid) | mi(planid)
        replace county = "DISTRICT OF COLUMBIA" if regexm(county, "COLUMBIA") & (state == "WASHINGTON D.C.")
        replace state  = "DISTRICT OF COLUMBIA" if state == "WASHINGTON D.C."
        gen state_bak  = state
        gen county_bak = county

        frame create state_xw
        frame state_xw: use `"${data}/state_xw.dta"', clear
        frlink m:1 state, frame(state_xw name)
        assert !mi(state_xw)
        frget st keep, from(state_xw)
        frame drop state_xw
        drop state_xw

        label var keep "Keep only 50 states and DC"

        rename (state st) (name state)
        * cleanStateCounty, replace
        cleanStateCounty
        rename (contractid planid) (cntrct pbpid)
        drop if mi(county) | mi(state) | mi(cntrct) | mi(pbpid)

        merge m:1 state county year using `"${data}/county_xw.dta"', keep(1 3)
        rename (name county state_bak county_bak) (state_merge county_merge name county)
        gen landscape_xw = (_merge == 3)

        tab year _merge
        tab year _merge if keep
        drop _merge
        compress
    save `"${data}/landscape/ma_xw"', replace
end

capture program drop landscapeTerminations
program landscapeTerminations

    * DOC: These are plan terminations from the landscape file; only
    * plans that disappear by 2018 are listed, meaning the last year we
    * can check for plan disappearance is 2017.

    use `"${data}/landscape/ma_xw"' if keep, clear
        keep state county ssacounty ssastate cntrct pbpid year landscape_xw
        gduplicates drop
        qui sum year
        local maxyear = `r(max)'
        gisid state county cntrct pbpid year
        bys state county cntrct pbpid (year): keep if year[_n] != (year[_n + 1] - 1)
        drop if year == `maxyear'
        compress
    save `"${data}/landscape_terminations"', replace

    use `"${data}/landscape_terminations"' if substr(cntrct, 1, 1) == "H", clear
        rename year landscape_year
        drop county state
        rename (ssacounty ssastate) (county state)
        gen state_county = county
        gduplicates drop
        drop if mi(state_county)

        compress
        sort  state_county cntrct pbpid
        keep  state_county cntrct pbpid landscape_*
        gisid state_county cntrct pbpid landscape_year
        gen year = landscape_year
    save `"${data}/terminate_xw"', replace
end

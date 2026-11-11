capture program drop makeNoDualEffects
program makeNoDualEffects
    syntax, pct(str) [pre(str) replace]
    local opts pre(`pre') pct(`pct') `replace'

    use `"${data}/`pre'alphas`pct'.dta"', clear

    gegen drop_bene = max(mDual == 1), by(bene_code)
    display "dropping benes ever in a high dual plan"
    drop if drop_bene == 1
    drop drop_bene

    gegen nd_contract_size_forbins = count(1), by(fe_county_contract)

    gen     bin_nodual = 1 if nd_contract_size_forbins <=  50
    replace bin_nodual = 2 if nd_contract_size_forbins > 50   & nd_contract_size_forbins <= 150
    replace bin_nodual = 3 if nd_contract_size_forbins > 150  & nd_contract_size_forbins <= 350
    replace bin_nodual = 4 if nd_contract_size_forbins > 350  & nd_contract_size_forbins <= 1000
    replace bin_nodual = 5 if nd_contract_size_forbins > 1000 & nd_contract_size_forbins <= 4000
    replace bin_nodual = 6 if nd_contract_size_forbins > 4000

    glevelsof bin_nodual, loc(nodual_bin)  silent
    global nodual_bin: copy local nodual_bin

    local id      bene_code year
    local fe      fe_county fe_county_plan fe_county_contract fe_county_year
    local vars    died_365 fe_race fe_sex fe_age mDual country_large_contract_plan
    local varopts id(`id') fe(`fe') vars(`vars')
    sort `id'

    alphasByBin, size(bin_nodual nodual_bin) suffix(CYBND) `varopts' `opts'

    local varalphas mucounty_*CYBND* mucnoc_*CYBND*
    foreach varset of local varalphas {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                bys bene_code (year): gen `var'_lag = `var'[_n - 1]
            }
        }
    }

    addBinLevelMeans bin_nodual, s(nodualbin) fesuf(CYBND)

    local varalphas u_*CYBND* unoc_*CYBND* mu*CYBND*
    foreach varset of local varalphas {
        cap ds `varset'
        if ( _rc == 0 ) {
            foreach var of varlist `varset' {
                muNamingConventionLabel `var'
            }
        }
    }

    gisid bene_code year
    keep bene_code year *nodual* *CYBND*
    merge 1:1 bene_code year using `"${data}/`pre'alphas`pct'.dta"', keep(2 3) assert(2 3) nogen

    save `"${data}/`pre'alphas`pct'.dta"', replace
end

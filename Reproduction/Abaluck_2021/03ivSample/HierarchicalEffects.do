* ---------------------------------------------------------------------
* Hierarchical Plan Effects

* DOC:
*
*     sigma_w   -> contract -> e(sigma_u)
*     sigma_eta -> plan     -> `=sqrt(e(sigma_u)^2-`sigma_w'^2)'
*     sigma_eps -> plan     -> e(sigma_e)
*
*     A1 = p_c by p_c matrix of sigma_w
*     A2 = diag(sigma_eta^2 ... sigma_eta^2) p_c x p_c diagonal matrix
*     B  = diag(sigma_eps^2 / n_1 ... sigma_eps^2 / n_{p_c}) p_c x p_c diagonal matrix
*     U  = [u_1 ... u_{p_c}] p_c x 1 vector of plan effects
*     MU = (A1 + A2) (A1 + A2 + B)^-1 U
*
* "03ivSample/Hierarchical Empirical Bayes (Hull).pdf" has the details
* and an explanation of what this is. The mata code at the end is the
* workhorse that actually does the computations.

* local 0 , pct(`pct') pre(`pre') fesuf(CY)

capture program drop computeHierarchicalMU
program computeHierarchicalMU
    syntax, pct(str) fesuf(str) [pre(str) replace skipnoc *]

    * -------------------------------------
    * Get the scalars from the xtreg models
    * -------------------------------------

    local level contract
    local Level Contract
    estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pctmle`fesuf'`Level'"'
    qui xtreg
    scalar sigma_w2 = e(sigma_u)^2

    local level plan
    local Level Plan
    estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pctmle`fesuf'`Level'"'
    qui xtreg
    scalar sigma_eta2 = cond(e(sigma_u)^2 < sigma_w2, 0, e(sigma_u)^2 - scalar(sigma_w2))
    scalar sigma_eps2 = e(sigma_e)^2

    _computeHierarchicalMU mucounty_mle`fesuf'Plan = u_fe`fesuf'Plan, cmean(what_fe`fesuf'Plan) `options'

    * -----------------------------
    * As above but without controls
    * -----------------------------

    if ( "`skipnoc'" == "" ) {
    local level contract
    local Level Contract
    estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pctmle`fesuf'`Level'_noc"'
    qui xtreg
    scalar sigma_w2 = e(sigma_u)^2

    local level plan
    local Level Plan
    estimates use `"${out}/estimates/`level'/xtreg/`pre'_`pct'pctmle`fesuf'`Level'_noc"'
    qui xtreg
    scalar sigma_eta2 = cond(e(sigma_u)^2 < sigma_w2, 0, e(sigma_u)^2 - scalar(sigma_w2))
    scalar sigma_eps2 = e(sigma_e)^2

    _computeHierarchicalMU mucnoc_mle`fesuf'Plan = unoc_fe`fesuf'Plan, cmean(wnoc_fe`fesuf'Plan) `options'
    }
end

* DOC: Internal utility to compute hierarhical plan effects.  Assumes
* scalars or variables sigma_w2, sigma_eta2, and sigma_eps2 are defined

capture program drop _computeHierarchicalMU
program _computeHierarchicalMU
    syntax newvarname =/ exp, [nj(str) by(str) cmean(str) replace VARiables scalars *]

    if ( "`variables'`scalars'" == "" ) local scalars scalars
    scalar _scalars = "`scalars'" != ""

    if ( `"`by'"' != "" ) {
        tempvar c p
        gegen `c' = group(`by' fe_county_contract)
        gegen `p' = group(`by' fe_county_plan)
    }
    else {
        local c fe_county_contract
        local p fe_county_plan
    }

    if ( `"`nj'"' == "" ) {
        tempvar nj
        gegen `nj'  = count(1), by(`p')
    }

    tempvar ix tag invnj
    gen long `ix' = _n
    gegen `tag' = tag(`p')
    if ( _scalars ) {
        gen `invnj' = scalar(sigma_eps2) / `nj'
    }
    else {
        gen `invnj' = sigma_eps2 / `nj'
    }

    * ----------------------------
    * Compute the hierarchical mu
    * ----------------------------

    * DOC: The hierarchy is at the county level; see the PDF reference
    * above for what each of the sigmas mean. u_fe refer to the unshrunk
    * plan effects, and what_mle refer to the mean of the unshrunk
    * effects.

    local out: copy local varlist
    local u:   copy local exp

    mata: _computeHierarchicalMU("`c'", "`p'", "`invnj'", "`u'", "`ix'", "`tag'", "`out'", `"`cmean'"')
    gegen `out' = firstnm(`out'), by(`p') replace
    gstats sum `out'

    // cvar   ="`c'"
    // pvar   ="`p'"
    // nvar   ="`invnj'"
    // uvar   ="`u'"
    // ixvar  ="`ix'"
    // tag    ="`tag'"
    // outvar ="`out'"
    // cmean  =`"`cmean'"'

    scalar drop _scalars
end

* Workhorse for hierarchical effects. See the PDF referenced above.
*
* Note: This accomodates multiple sigma_ values across various groups if
* a variable is passed. However, _within_ a plan they are assumed to be
* the same, so the first entry within the group is picked. If scalars
* are passed then the scalar is used for every group.

cap mata: mata drop _computeHierarchicalMU()
mata:
void function _computeHierarchicalMU(
    string scalar cvar,
    string scalar pvar,
    string scalar nvar,
    string scalar uvar,
    string scalar ixvar,
    string scalar tag,
    string scalar outvar,
    string scalar cmean)
{
    real colvector mu, sigma_w2, sigma_eta2
    real matrix X, info, nj, out
    real matrix X_i, A1, A2, AB
    real scalar i, sel, scalars

    scalars = st_numscalar("_scalars")
    if ( cmean == "" ) {
        X = st_data(., invtokens((cvar, pvar, nvar, uvar, ixvar)), tag)
    }
    else {
        X = st_data(., invtokens((cvar, pvar, nvar, uvar, ixvar, cmean)), tag)
    }

    if ( scalars == 0 ) X = X, (1::rows(X))
    _sort(X, (1, 2))

    if ( scalars ) {
        sigma_w2   = st_numscalar("sigma_w2")
        sigma_eta2 = st_numscalar("sigma_eta2")
    }
    else {
        sigma_w2   = st_data(., "sigma_w2",   tag)[X[., cols(X)]]
        sigma_eta2 = st_data(., "sigma_eta2", tag)[X[., cols(X)]]
    }

    info = panelsetup(X[., 1], 1)
    nj   = info[., 2] :- info[., 1] :+ 1
    mu   = J(rows(X), 1, .)

    if ( cmean == "" ) {
        for(i = 1; i <= rows(info); i++) {
            sel  = scalars? 1: info[i, 1]
            X_i  = panelsubmatrix(X, i, info)
            A1   = J(nj[i], nj[i], sigma_w2[sel])
            A2   = diag(J(1, nj[i], sigma_eta2[sel]))
            AB   = A1 + A2 + diag(X_i[., 3])
            mu[|info[i, 1] \ info[i, 2]|] = (A1 + A2) * (invsym(AB) * X_i[., 4])
        }
    }
    else {
        for(i = 1; i <= rows(info); i++) {
            sel  = scalars? 1: info[i, 1]
            X_i  = panelsubmatrix(X, i, info)
            A1   = J(nj[i], nj[i], sigma_w2[sel])
            A2   = diag(J(1, nj[i], sigma_eta2[sel]))
            AB   = A1 + A2 + diag(X_i[., 3])
            mu[|info[i, 1] \ info[i, 2]|] = ((A1 + A2) * (invsym(AB) * (X_i[., 4] :- X_i[., 6]))) :+ X_i[., 6]
        }
    }

    out = sort((X[., 5], mu), 1)
    (void) st_addvar(st_global("c(type)"), outvar)
    st_store(out[., 1], st_varindex(outvar), out[., 2])
}
end

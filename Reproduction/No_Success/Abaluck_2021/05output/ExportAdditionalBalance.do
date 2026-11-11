if ( `"`versions'"' == "" ) {
    local versions 1B 1F
}
else if (`"`versions'"' != "1B 1D 1F 1H") & (`"`versions'"' != "1B 1F") {
    display as error "NotImplementedException: versions cannot be specified as: `versions'"
    exit 198
}

local vars1 demo_age dum_sex2 dum_race2 mDual average_risk_score
local vars2 predictedMortality_dual predictedMortality_dual_risk

local T: copy local terminated
mata reg_matrix`option' = J(`:list sizeof vars`option'' * 2, `:list sizeof versions', .)

local j = 0
foreach v of local versions {
    local ++j
    local i = 0
    disp _n(1)
    disp "`v') `xlsheet'"
    foreach demo of local vars`option' {
        local results ${out}/estimates/`contract'/ivreg/`pre'`demo'_`pct'pct_`sampleSelection'`tag'_`v'
        estimates use `"`results'_RF"'
        cap reghdfe
        mata reg_matrix`option'[`++i', `j'] = `=_b[`instrument`v'']'
        mata reg_matrix`option'[`++i', `j'] = `=_se[`instrument`v'']'
    }
}
mata reg_matrix`option'
mata reg_rfmt`option' = J(`:list sizeof vars`option'', 1, "%8.3f" \ "(%8.3f)")

estimates use `"${out}/estimates/misc/`pre'dead365_`pct'pct_`sampleSelection'_`tag'"'
reg

local vars    ///
    70.fe_age ///
    75.fe_age ///
    80.fe_age ///
    85.fe_age ///
    90.fe_age ///
    95.fe_age ///
    3.fe_sex  ///
    2.fe_race ///
    3.fe_race ///
    4.fe_race ///
    5.fe_race ///
    6.fe_race ///
    7.fe_race ///
    1.mDual

local i = 0
mata reg_matrix   = J(2 * `:list sizeof vars' + 2, 1, .)
mata tableA3_rfmt = J(`:list sizeof vars', 1, "%8.4f" \ "(%8.4f)") \ "%8.4f" \ "\mc{%21.0fc}"
foreach var of local vars {
    mata reg_matrix[`++i', 1] = `=_b[`var']'
    mata reg_matrix[`++i', 1] = `=_se[`var']'
}
mata reg_matrix[`++i', 1] = st_numscalar("e(r2)")
mata reg_matrix[`++i', 1] = st_numscalar("e(N)")

mata tableA3_rlabels =  ///
    "Age 70-74"       \ ///
    "Age 75-79"       \ ///
    "Age 80-84"       \ ///
    "Age 85-90"       \ ///
    "Age 90-94"       \ ///
    "Age 95+"         \ ///
    "Female"          \ ///
    "White"           \ ///
    "Black"           \ ///
    "Other"           \ ///
    "Asian"           \ ///
    "Hispanic"        \ ///
    "Native American" \ ///
    "Dual"

mata tableA3_rlabels = colshape((tableA3_rlabels, J(rows(tableA3_rlabels), 1, "")), 1)
mata tableA3_rlabels = tableA3_rlabels \ "\$R^2\$" \ "N Beneficiary-Years"

* Copy all the required output; compile LaTeX locally

qui do "00common/00preamble.do"
cap mkdir 99adHoc/Graphics
cap mkdir 99adHoc/Tables

local CWD    `"`c(pwd)'"'
local OUTFIG `"`c(pwd)'/99adHoc/Graphics"'
local OUTTAB `"`c(pwd)'/99adHoc/Tables"'

***********************************************************************
*                         Main Paper Results                          *
***********************************************************************

cd `"${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance"'

foreach fig in bal_100pct_nq10 fb_100pct_nq10 FS_100pct_nq10 rf_100pct_nq10 {
    cap erase "`OUTFIG'/`fig'.svg"
    copy "`fig'.svg" "`OUTFIG'/`fig'.svg"
}

cd `"${out}/fig"'

foreach fig in _19Figure1_100pct {
    cap erase "`OUTFIG'/`fig'.svg"
    copy "`fig'.svg" "`OUTFIG'/`fig'.svg"
}

cd `"${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_mimic_IV_normalized/normalized"'
foreach fig in planEffect_normalized mortality_normalized {
    cap erase "`OUTFIG'/`fig'.svg"
    copy "`fig'.svg" "`OUTFIG'/`fig'.svg"
}

cd `"${out}/tables"'

foreach i in 1 2 3 5 {
    local tab _19Table`i'_100pct
    cap erase "`OUTTAB'/`tab'.tex"
    copy "`tab'.tex" "`OUTTAB'/`tab'.tex"
}

foreach i in 1 2 {
    local tab _19Table4_100pct_Panel`i'
    cap erase "`OUTTAB'/`tab'.tex"
    copy "`tab'.tex" "`OUTTAB'/`tab'.tex"
}

***********************************************************************
*                              Appendix                               *
***********************************************************************

cd `"${out}/fig"'

foreach fig in _19figureA1_term_map_pct_100 _19lambda_hist100_1trim_2 YearBin_19_100pct_common_mucounty_mleCYYBPlan {
    cap erase "`OUTFIG'/`fig'.svg"
    copy "`fig'.svg" "`OUTFIG'/`fig'.svg"
}

cd `"${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance_riskscore"'
local fig riskscore_bal_100
cap erase "`OUTFIG'/`fig'.svg"
copy "`fig'.svg" "`OUTFIG'/`fig'.svg"

cd `"${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance_age"'
local fig age_bal_100
cap erase "`OUTFIG'/`fig'.svg"
copy "`fig'.svg" "`OUTFIG'/`fig'.svg"

cd `"${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_FSRF_viv"'
foreach fig in FSRF_100pct_nq10_v1 viv_100pct_nq10 {
    cap erase "`OUTFIG'/`fig'.svg"
    copy "`fig'.svg" "`OUTFIG'/`fig'.svg"
}

cd `"${out}/tables"'

foreach i in 1 2 3 4 6 7 {
    local tab _19tableA`i'_100pct
    cap erase "`OUTTAB'/`tab'.tex"
    copy "`tab'.tex" "`OUTTAB'/`tab'.tex"
}

local tab _19osterOVB_100pct
cap erase "`OUTTAB'/`tab'.tex"
copy "`tab'.tex" "`OUTTAB'/`tab'.tex"

local tab _19tables100pct
cap erase "`OUTTAB'/`tab'.txt"
copy "`tab'.txt" "`OUTTAB'/`tab'.txt"

* To run tablefill, first install it:
*
*     python -m pip install --user git+https://github.com/mcaceresb/tablefill
*
* Then run it from a python session or from here.

python
from tablefill import tablefill
for i in [8, 9]:
    tablefill(template = "`CWD'/05output/paper/TableA{0}_template.tex".format(i),
              output   = "`OUTTAB'/_19tableA{0}_100pct.tex".format(i),
              input    = "`tab'.txt")
end

cd `CWD'

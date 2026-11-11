cap mkdir `"${out}/estimates/"'
cap mkdir `"${out}/estimates/misc"'

reg died_365 i.fe_age i.fe_sex i.fe_race i.mDual `ifcommand'
estimates save `"${out}/estimates/misc/`pre'dead365_`pct'pct_`sampleSelection'_`tag'"', replace

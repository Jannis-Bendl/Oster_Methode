* Global
clear all
cd "/Users/johnnytang/Dropbox/Johnny Tang/RegulatoryCompetition/RegulatoryCompetition_ReplicationPackage/Analysis_Insurer/"

import delimited "output/ReducedForm/data_all.csv", case(preserve)

keep if insureryr_uses_captives == 1

replace kappa_economic_K_div_L_leaveon = kappa_economic_K_div_L_leaveon * (-1)

areg has_captive_intensive kappa_economic_K_div_L_leaveon CaptiveTaxRate newbusinesses_pop tourists Commissioner_Appointed state_share sells_in_state, absorb(CEDENTSNLTOPENTITYKEY_year)

local r2_reg = e(r2)

local r2_reg_max = `r2_reg' * 1.3

psacalc delta kappa_economic_K_div_L_leaveon, rmax(`r2_reg_max')
putexcel set "output/ReducedForm/reg_has_captives_capreq_insurerstateyr_ostertest", replace
putexcel A1 = "delta"
putexcel A2 = `r(delta)'
putexcel save

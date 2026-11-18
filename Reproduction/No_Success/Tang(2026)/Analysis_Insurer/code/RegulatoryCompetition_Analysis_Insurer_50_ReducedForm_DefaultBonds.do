clear all
cd "/Users/johnnytang/Dropbox/Johnny Tang/RegulatoryCompetition/RegulatoryCompetition_ReplicationPackage/Analysis_Insurer"
use "../raw/ChodorowReich/forJohnnyTang.dta"

gen id = _n

preserve
	clear
	import delimited "../raw/ChodorowReich/DefaultBonds.csv"
	gen id = _n
	tempfile defaultbonds
	save `defaultbonds'
restore

merge 1:1 id using `defaultbonds'

cap gen int monthly = mofd(exec_date)
qui tsset insurer_n exec_date
gen byte crisis = tin(1jan2008,31dec2009)

xtset insurer_n exec_date

foreach tenor of numlist 1/5 7 10 {
	gen delta_defaultprob`tenor' = defaultprob`tenor' - l.defaultprob`tenor'
}
gen crisis_R_regx_insurer = crisis * R_regx_insurer if (crisis != .) & (R_regx_insurer != .)
gen crisis_R1_regx06_insurer = crisis * R1_regx06_insurer if (crisis != .) & (R1_regx06_insurer != .)

gen noncrisis_R_regx_insurer = (1 - crisis) * R_regx_insurer if (crisis != .) & (R_regx_insurer != .)
gen noncrisis_R1_regx06_insurer = (1 - crisis) * R1_regx06_insurer if (crisis != .) & (R1_regx06_insurer != .)

label var delta_defaultprob5 "$\Delta$ P(Default)"
label var R_regx_insurer "$\Delta$ Assets"
label var R1_regx06_insurer "Large Abnormal Returns"
label var ret_T10 "Return on 10-year Treasury"
label var crisis_R_regx_insurer "1(Crisis) X $\Delta$ Assets"
label var crisis_R1_regx06_insurer "1(Crisis) X Large Abnormal Returns"
label var noncrisis_R_regx_insurer "1(Non-Crisis) X $\Delta$ Assets"
label var noncrisis_R1_regx06_insurer "1(Non-Crisis) X Large Abnormal Returns"
label var crisis "1(Crisis)"
label var defaultprob5 "P(Default)"
cd "output/DefaultRisk/"

local reg_table = "ss_defaultrisk_bonds"
summarize defaultprob5 delta_defaultprob5 R_regx_insurer R1_regx06_insurer ret_T10 if delta_defaultprob5 != .
outreg2 if delta_defaultprob5 != . using `reg_table', auto(2) label tex(frag) nonotes replace sum(log) keep(defaultprob5 delta_defaultprob5 R_regx_insurer R1_regx06_insurer ret_T10 R1_regx06_insurer) sortvar(defaultprob5 delta_defaultprob5 R_regx_insurer R1_regx06_insurer ret_T10 R1_regx06_insurer)
local reg_table = "reg_defaultrisk_bonds"

ivreghdfe delta_defaultprob5 R_regx_insurer, cluster(exec_date)
outreg2 using `reg_table', ctitle("\$\Delta\$ P(Default)") drop(_I* Ibens*) auto(2) alpha(0.01,0.05,0.10) label addtext(Specification, "OLS", Duration Controls, "$ $") nocons nonotes nor2 tex(frag) replace

gen R_regx_insurer_bk = R_regx_insurer
replace R_regx_insurer = R1_regx06_insurer
ivreghdfe delta_defaultprob5 R_regx_insurer, cluster(exec_date)
outreg2 using `reg_table', ctitle("\$\Delta\$ P(Default)") drop(_I* Ibens*) auto(2) alpha(0.01,0.05,0.10) label addtext(Specification, "RF", Duration Controls, "$ $") nocons nonotes nor2 tex(frag) append
replace R_regx_insurer = R_regx_insurer_bk
drop R_regx_insurer_bk

ivreghdfe delta_defaultprob5 (R_regx_insurer = R1_regx06_insurer), cluster(exec_date)
outreg2 using `reg_table', ctitle("\$\Delta\$ P(Default)") drop(_I* Ibens*) auto(2) alpha(0.01,0.05,0.10) label addtext(Specification, "IV", Duration Controls, "$ $") nocons nonotes nor2 tex(frag) append

ivreghdfe delta_defaultprob5 (R_regx_insurer = R1_regx06_insurer), absorb(i.insurer_n#i.year#c.ret_T10) cluster(exec_date)
outreg2 using `reg_table', ctitle("\$\Delta\$ P(Default)") drop(_I* Ibens*) auto(2) alpha(0.01,0.05,0.10) label addtext(Specification, "IV", Duration Controls, "X") nocons nonotes nor2 tex(frag) append

* Portfolio Return + Portfolio Return * Crisis + Crisis
ivreghdfe delta_defaultprob5 crisis (crisis_R_regx_insurer noncrisis_R_regx_insurer = crisis_R1_regx06_insurer noncrisis_R1_regx06_insurer), absorb(i.insurer_n#i.year#c.ret_T10) cluster(exec_date)
outreg2 using `reg_table', ctitle("\$\Delta\$ P(Default)") drop(_I* Ibens*) sortvar(R_regx_insurer R1_regx06_insurer crisis crisis_R_regx_insurer noncrisis_R_regx_insurer crisis_R1_regx06_insurer noncrisis_R1_regx06_insurer) auto(2) alpha(0.01,0.05,0.10) label addtext(Specification, "IV", Duration Controls, "X") nocons nonotes nor2 tex(frag) append

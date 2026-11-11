keep `ifglobal'
keep `ifcommand'
gen pc_PFFS = strpos(typeofmedicarehealthplan, "PFFS") > 0

* Table A2 sum stats:
* row 1: Do Not Switch
tab switch_plan, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el11 : di %5.1f perc[1,1]
tab switch_plan if disappeared_landscape1_lag == 1, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el12 : di %5.1f perc[1,1]

* row 2: Switch Plan within Same Insurer
tab switch_plan_same_cntrct, matcell(freq) 
    matrix perc = freq/`r(N)' * 100
    local el21 : di %5.1f perc[2,1]
tab switch_plan_same_cntrct if disappeared_landscape1_lag == 1, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el22 : di %5.1f perc[2,1]

* row 3: Switch Insurer
tab switch_cntrct, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el31 : di %5.1f perc[2,1]
tab switch_cntrct if disappeared_landscape1_lag == 1, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el32 : di %5.1f perc[2,1]

* row 4: Switch into TM
gen switch_TM = switch_plan * (pbpid_id == -1)
assert !mi(switch_TM)
tab switch_TM, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el41 : di %5.1f perc[2,1]
tab switch_TM if disappeared_landscape1_lag == 1, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el42 : di %5.1f perc[2,1]

* row 5: Switch into PFFS
gen switchxPFFS = pc_PFFS * switch_plan
tab switchxPFFS, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el51 : di %5.1f perc[2,1]
    local N1 : di %12.0fc `r(N)'
tab switchxPFFS if disappeared_landscape1_lag == 1, matcell(freq)
    matrix perc = freq/`r(N)' * 100
    local el52 : di %5.1f perc[2,1]
    local N2 : di %12.0fc `r(N)'

foreach local in el11 el12 el21 el22 el31 el32 el41 el42 el51 el52 N1 N2 {
    local `local' = strltrim("``local''")
}

* Note: The reason we do not use this alternative PFFS definition is
* because it has missing observations and we want to keep a consistent
* N, but other than this they are almost exactly the same.

capture erase `"${out}/tables/`pre'tableA2_`pct'pct.tex"'
file open switchbehav using `"${out}/tables/`pre'tableA2_`pct'pct.tex"', write replace
local table "switchbehav"

#delimit ;

file write `table'
    "\begin{table}[h]" _n
    "\caption{\label{tab:sumstat_switch}Switching Behavior Summary Statistics}" _n
    "\vspace{-0.5cm}" _n
    "\begin{center}" _n
    "\begin{tabular}{l cc}" _n
    "\toprule" _n
    " & \mc{MA} & \mc{Terminated} \tabularnewline" _n
    "  & (1) & (2)\tabularnewline" _n
    "\midrule" _n
;

file write `table'
    "\% Do Not Switch & `el11' & `el12' \tabularnewline" _n
    "\% Switch Plans within Same Insurer & `el21' & `el22' \tabularnewline" _n
    "\vspace{0.25cm}" _n
    "\% Switch Insurer & `el31' & `el32' \tabularnewline" _n
    "\% Switch Into TM Plan & `el41' & `el42' \tabularnewline" _n
    "\% Switch Into PFFS Plan & `el51' & `el52' \tabularnewline" _n
    "\midrule" _n 
    "N Beneficiary-Years & \mc{`N1'} & \mc{`N2'} \tabularnewline" _n
;

file write `table'
    "\bottomrule" _n
    "\end{tabular}" _n
    "\end{center}" _n
    "{\footnotesize{}Notes: This table compares choice behavior of consumers in MA plans to those in a MA plan that terminates. Market shares sum to more than one due to rounding.}\tabularnewline" _n
    "{\footnotesize\par}" _n
    "\end{table}" _n
;

#delimit cr

file close `table'

use "$data_dir/England_and_Wales/district_pop_by_age_combined.dta", clear

*Define fertile population as (female) 15-50
gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F

collapse (sum) pop_fertile_F, by(district year)

egen dist_code=group(district)
xtset dist_code year
tsfill

sort dist_code year

	sort dist_code year
	replace district=district[_n-1] if district=="" & dist_code==l.dist_code

sort dist_code year
by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)

keep dist_code district year pop_fertile_F_int
keep if inrange(year,1851,1876)

merge 1:1 district year using "$data_dir/England_and_Wales/marriage_data_district_standardized.dta", keep(3) keepusing(marriages_total) nogen

merge 1:1 district year using "$data_dir/England_and_Wales/district_births_data_standardized.dta", keep(3) keepusing(births) nogen


gen birth_rate=births/(pop_fertile_F_int/1000)
gen mar_rate=marriages_total/(pop_fertile_F_int/1000)

sort dist_code year

reghdfe birth_rate f.mar_rate mar_rate l.mar_rate l2.mar_rate l3.mar_rate l4.mar_rate l5.mar_rate, absorb(year dist_code) cluster(dist_code)

matrix RES=(1,_b[F.mar_rate],_se[F.mar_rate])
matrix RES=RES\(2,_b[mar_rate],_se[mar_rate])
matrix RES=RES\(3,_b[L.mar_rate],_se[L.mar_rate])
matrix RES=RES\(4,_b[L2.mar_rate],_se[L2.mar_rate])
matrix RES=RES\(5,_b[L3.mar_rate],_se[L3.mar_rate])
matrix RES=RES\(6,_b[L4.mar_rate],_se[L4.mar_rate])
matrix RES=RES\(7,_b[L5.mar_rate],_se[L5.mar_rate])

svmat RES
keep RES1 RES2 RES3

	drop if RES1==.
	
	ren RES1 order_var
	ren RES2 Beta
	ren RES3 SE
	
	gen ci_high=Beta+1.96*SE
	gen ci_low=Beta-1.96*SE
	
	
	two (scatter Beta order_var, mcolor(black)) (rcap ci_high ci_low order_var, lcolor(black)), legend(off) xlabel(1 "t+1" 2 "Period t" 3 "t-1" 4 "t-2" 5 "t-3" 6 "t-4" 7 "t-5", angle(45) grid notick) xtitle("") ylabel(-0.3(0.3)0.6, grid notick angle(0)) yline(0, lw(medthick) lcolor(black))
	
	graph export "$results/F19_EW_Marriages_Births_AR.pdf", replace

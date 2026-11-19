/*	Start by grabbing district X census fertile aged pops, which we will 
	interpolate and then merge with annual marriage data so that we can 
	calculate the relevant 5 year averages */

use dist_code district pop_fertile_F_1871 pop_fertile_F_1881 pop_fertile_F_1891 comparison_75_80 using "$temp_dir/EW_DD_cleaned.dta" if comparison_75_80==1, clear		
	duplicates drop
	
	reshape long pop_fertile_F, i(dist_code) j(year) string
	
	destring year, replace ignore("_")
			
	xtset dist_code year
	
	tsfill, full
	 
	sort dist_code year
	by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)
	replace district=district[_n-1] if district=="" & dist_code==dist_code[_n-1]
			
	keep district year pop_fertile_F_int		

merge 1:1 district year using "$data_dir/England_and_Wales/marriage_data_district_standardized.dta", keep(3) nogen	

	*Identify some relevant marriage categories
	gen marriages_all	  	= marriages_total/(pop_fertile_F_int/1000)
	gen marriages_first   	= bachelors_spinsters/(pop_fertile_F_int/1000)
	gen marriages_minors  	= (minors_female)/(pop_fertile_F_int/1000)
	gen marriages_illit   	= (illiterate_female)/(pop_fertile_F_int/1000)	
	
	gen period=1873 if inrange(year,1873,1877)
	replace period=1878 if inrange(year,1878,1882)

	keep if period==1873 | period==1878
	
	collapse marriages_all marriages_first marriages_minors marriages_illit, by(district period)
	
	ren period year
		
	merge 1:1 district year using "$temp_dir/EW_DD_cleaned.dta", keep(3) keepusing(birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 total_pop_1871 year dist_code regionXyearfes)
	
foreach x in all first minors illit {
*Baseline
eststo mar_`x'_1: reghdfe marriages_`x' opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd ysumm

*Controls
eststo mar_`x'_2: reghdfe marriages_`x' $dist_int_1878 $mar_int_1878 opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd ysumm

*Absorb any effect operating through pre-existing newspapers
eststo mar_`x'_3: reghdfe marriages_`x' $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd ysumm

*Control for lagged fertility
eststo mar_`x'_4: reghdfe marriages_`x' birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd ysumm
}

esttab mar_all_1 mar_all_2 mar_all_3 mar_all_4 mar_first_4 mar_minors_4 mar_illit_4  using "$results/T28_EW_Marriages", label keep(opened_75_77X1878) stats(N r2_within ymean, label("Observations" "Within R-Squared" "Mean of DV") fmt(0 3 1) ) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

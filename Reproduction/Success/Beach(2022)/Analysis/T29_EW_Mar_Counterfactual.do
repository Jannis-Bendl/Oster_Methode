use "$temp_dir/F20_T29_panel.dta", clear

replace year=1873 if inrange(year,1873,1877)
replace year=1878 if inrange(year,1878,1882)

keep if year==1873 | year==1878

collapse counter_birth_rate, by(district year)

merge 1:1 district year using "$temp_dir/EW_DD_cleaned.dta", keep(3) nogen		

*Baseline w/ region X year FES
eststo T29_1: reghdfe birth_rate opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

eststo T29_2: reghdfe counter_birth_rate opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)


*With controls
eststo T29_3: reghdfe birth_rate $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

eststo T29_4: reghdfe counter_birth_rate $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)


esttab T29_* using "$results/T29_EW_Mar_Counterfactual", label keep(opened_75_77X1878) stats(districts N r2_within, label("Districts" "Observations" "Withing R-squared") fmt(0 0 3)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

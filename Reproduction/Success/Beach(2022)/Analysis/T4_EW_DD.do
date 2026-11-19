use "$temp_dir/EW_DD_cleaned.dta", clear		

*Baseline w/ region X year FES
eststo Base_1: reghdfe birth_rate opened_75_77X1878 [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

*Controls
eststo Base_2: reghdfe birth_rate $dist_int_1878 $mar_int_1878 opened_75_77X1878 [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

*Absorb any effect operating through pre-existing newspapers
eststo Base_3: reghdfe birth_rate $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

*Control for lagged fertility
eststo Base_4: reghdfe birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

***** Altonji-Oster exercise
*This code uses the wrong r-squared with lots of fixed effects... move to first differences 
preserve	
	keep if inrange(year,1873,1878) & comparison_75_80==1
	sort dist_code year
	gen chg_lagged_br=birth_rate_lagged-birth_rate_lagged[_n-1] if dist_code==dist_code[_n-1] & year==1878
	
	
	drop _I*
	
	foreach x in Midlands Northern Southern {
	gen `x'X1878=(region=="`x'" & year==1878)
}
	
	reg chg_br MidlandsX1878 NorthernX1878 SouthernX1878 opened_75_77X1878 [aweight=total_pop_1871], r
	reg chg_br MidlandsX1878 NorthernX1878 SouthernX1878 chg_lagged_br $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], r
	
psacalc beta opened_75_77X1878, mcontrol(MidlandsX1878 NorthernX1878 SouthernX1878) rmax(.9036)
scalar oster_beta = r(beta)
restore	

estadd scalar oster_beta = scalar(oster_beta) : Base_4

*Event Study			
eststo Base_5: reghdfe birth_rate birth_rate_lagged $dist_int_1868 $mar_int_1868 $dist_int_1878 $mar_int_1878 $dist_int_1878 $mar_int_1883 pre_75_papersX1868 pre_75_papersX1878 pre_75_papersX1883 opened_75_77X1868 opened_75_77X1878 opened_75_77X1883 [aweight=total_pop_1871] if inrange(year,1868,1883) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
estadd scalar districts = e(N_clust)

esttab Base_* using "$results/T4_EW_Base", ///
    label ///
    keep(opened_75_77X1868 opened_75_77X1878 opened_75_77X1883) ///
    order(opened_75_77X1868 opened_75_77X1878 opened_75_77X1883) ///
    stats(districts N r2_within oster_beta, ///
    label("Districts" "Observations" "Within R-squared" ///
    "Coef. implied lower bound following Oster (2019)") ///
    fmt(0 0 3 3)) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

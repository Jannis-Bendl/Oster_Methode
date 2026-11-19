use "$temp_dir/EW_DD_cleaned.dta" if inrange(year,1873,1878) & comparison_75_80==1, clear		

drop _I*

xi i.year i.dist_code

foreach x in Midlands Northern Southern {
	gen `x'X1878=(region=="`x'" & year==1878)
}

*Baseline (unweighted)
eststo T26_1: reghdfe birth_rate birth_rate_lagged MidlandsX1878 NorthernX1878 SouthernX1878 $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878, absorb(year dist_code) cluster(dist_code)


gen ones=1

foreach x in 25 50 100 200 {
eststo T26_a`x': ols_spatial_HAC birth_rate ones _I* birth_rate_lagged MidlandsX1878 NorthernX1878 SouthernX1878 $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878, lat(lat) lon(lon) t(year) p(dist_code) dist(`x') lag(2)
	
eststo T26_b`x': ols_spatial_HAC birth_rate ones _I* birth_rate_lagged MidlandsX1878 NorthernX1878 SouthernX1878 $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878, lat(lat) lon(lon) t(year) p(dist_code) dist(`x') lag(2) bartlett		
}


esttab T26_1 T26_a25 T26_a50 T26_a100 T26_a200 using "$results/T26_EW_Spatial_SE", b(3) se(3) label keep(opened_75_77X1878) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex replace

esttab T26_1 T26_b25 T26_b50 T26_b100 T26_b200 using "$results/T26_EW_Spatial_SE", b(3) se(3) label keep(opened_75_77X1878) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex append

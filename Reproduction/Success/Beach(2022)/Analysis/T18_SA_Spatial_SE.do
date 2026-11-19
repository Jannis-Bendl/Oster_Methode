use "$temp_dir/SA_DivisionXperiod.dta" if totpop1875>2000, clear


*Column 7 of Table 17 (Unweighted specification)
eststo T17_1: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost, absorb(dcode period) cluster(dcode)

xi i.period i.dcode
gen ones=1

foreach x in 25 50 100 200 {
eststo T17a_`x': ols_spatial_HAC rate ones _I* brit_imm_shrXpost densityXpost literacyXpost, lat(lat) lon(lon) t(period) p(dcode) dist(`x') lag(2)

eststo T17b_`x': ols_spatial_HAC rate ones _I* brit_imm_shrXpost densityXpost literacyXpost, lat(lat) lon(lon) t(period) p(dcode) dist(`x') lag(2) bartlett
}

esttab T17_1 T17a_25 T17a_50 T17a_100 T17a_200 using "$results/T18_SA_Spatial_SE", b(3) se(3) label keep(brit_imm_shrXpost) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex replace

esttab T17_1 T17b_25 T17b_50 T17b_100 T17b_200 using "$results/T18_SA_Spatial_SE", b(3) se(3) label keep(brit_imm_shrXpost) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex append

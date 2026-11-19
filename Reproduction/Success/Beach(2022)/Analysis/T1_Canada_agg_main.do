use "$temp_dir/Canada_agg_reg.dta", clear
 
**************************************
** Table 1: Quebec and Ontario only **
**************************************

eststo t1_c1: reghdfe br_ brit_origin_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)
estadd scalar counties = e(N_clust)
	sum british_origin_shr_1861 if e(sample)==1

*With Controls
eststo t1_c2: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)
estadd scalar counties = e(N_clust)

*Expand to assess dynamics -- note we add brit_origin_3 to end such that it is dropped and will appear as the omitted category
eststo t1_c3: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_2 brit_origin_4 brit_origin_5 brit_origin_3 [aweight=fem_fertile_pop_1871] if inrange(period,2,5) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)
estadd scalar counties = e(N_clust)

esttab t1_c1 t1_c2 t1_c3 using "$results/T1_Canada_agg", b(3) se(3) label keep(brit_origin_2 brit_origin_3 brit_origin_4 brit_origin_5) order(brit_origin_2 brit_origin_3 brit_origin_4 brit_origin_5) stats(N r2_within counties, label("Observations" "Within R-squared" "No. of Counties") fmt(0 3 0)) star(* 0.10 ** 0.05 *** 0.01) mtitles("1872-1880" "1872-1880" "1864-1885") tex replace

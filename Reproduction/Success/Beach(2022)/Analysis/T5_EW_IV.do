use "$temp_dir/EW_DD_cleaned.dta", clear

**Reduced Form of Actual Articles (within the band)
gen articles_ownXpost=articles_own*post_BB_trial

eststo EW_iv1: reghdfe birth_rate $dist_int_1878 $mar_int_1878 birth_rate_lagged articles_ownXpost [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) cluster(dist_code)

*Instrument for BB coverage with number of new papers
eststo EW_iv2: ivreghdfe birth_rate (articles_ownXpost=opened_75_77Xpost) $dist_int_1878 $mar_int_1878 birth_rate_lagged [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) first cluster(dist_code)
		
eststo EW_iv3:	ivreghdfe birth_rate (articles_ownXpost=opened_75_77Xpost) $dist_int_1878 $mar_int_1878 pre_75_papersX1878 birth_rate_lagged [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_75_80==1, absorb(year dist_code regionXyearfes) first cluster(dist_code)
	
esttab EW_iv* using "$results/T5_EW_IV", keep(articles_ownXpost) stats(r2_within) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex replace

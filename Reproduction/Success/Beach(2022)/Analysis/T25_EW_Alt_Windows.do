use "$temp_dir/EW_DD_cleaned.dta", clear		

*Alternative windows

*5 Year
gen openedXpost_5=opened_73_77*_Iyear_1878
gen estXpost_5=pre_73_papers*_Iyear_1878
gen comparison_restriction_5=comparison_73_82

*4 year
gen openedXpost_4=opened_74_77*_Iyear_1878
gen estXpost_4=pre_74_papers*_Iyear_1878
gen comparison_restriction_4=comparison_74_81

*3 year
gen openedXpost_3=opened_75_77*_Iyear_1878
gen estXpost_3=pre_75_papers*_Iyear_1878
gen comparison_restriction_3=comparison_75_80

*2 year
gen openedXpost_2=opened_76_77*_Iyear_1878
gen estXpost_2=pre_76_papers*_Iyear_1878
gen comparison_restriction_2=comparison_76_79


gen openedXpost=.
label var openedXpost "Newspaper openings $\times$ Post"

forv x= 2/5 {
	replace openedXpost=openedXpost_`x'
	
	eststo M1_`x': reghdfe birth_rate openedXpost [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_restriction_`x'==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
	
	eststo M2_`x': reghdfe birth_rate $dist_int_1878 $mar_int_1878 openedXpost [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_restriction_`x'==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
	
	eststo M3_`x': reghdfe birth_rate $dist_int_1878 $mar_int_1878 estXpost_`x' openedXpost [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_restriction_`x'==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
	
	eststo M4_`x': reghdfe birth_rate $dist_int_1878 $mar_int_1878 birth_rate_lagged estXpost_`x' openedXpost [aweight=total_pop_1871] if inrange(year,1873,1878) & comparison_restriction_`x'==1, absorb(year dist_code regionXyearfes) cluster(dist_code)
	
}

esttab M1_5 M1_4 M1_3 M1_2 using "$results/T25_EW_Alt_Windows", label keep(openedXpost) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex replace

esttab M2_5 M2_4 M2_3 M2_2 using "$results/T25_EW_Alt_Windows", label keep(openedXpost) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex append

esttab M3_5 M3_4 M3_3 M3_2 using "$results/T25_EW_Alt_Windows", label keep(openedXpost) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex append

esttab M4_5 M4_4 M4_3 M4_2 using "$results/T25_EW_Alt_Windows", label keep(openedXpost) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex append

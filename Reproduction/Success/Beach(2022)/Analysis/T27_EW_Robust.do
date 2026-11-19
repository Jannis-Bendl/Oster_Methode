use "$temp_dir/EW_DD_cleaned.dta" if inrange(year,1873,1878) & comparison_75_80==1, clear		


**Can we do more to rule out other channels?
eststo b1: reghdfe birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)

*Add control for CLFP in 1871
eststo b2: reghdfe birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 clfp_71X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)

*Add control for FLFP
eststo b3: reghdfe birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 flfp_71X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)

gen own_bodichon_60_69Xpost=articles_bodichon_60_69*_Iyear_1878

eststo b4: reghdfe birth_rate birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 own_bodichon_60_69Xpost [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)


*EVERYTHING
eststo b5: reghdfe birth_rate clfp_71X1878 flfp_71X1878 own_bodichon_60_69Xpost birth_rate_lagged $dist_int_1878 $mar_int_1878 estXpost opened_75_77X1878 [aweight=total_pop_1871], absorb(year dist_code regionXyearfes) cluster(dist_code)

esttab b1 b2 b3 b4 b5 using "$results/T27_EW_Robust", label keep(opened_75_77X1878) stats(N r2_within, label("Observations" "Within R-Squared") fmt(0 3)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

import excel "$data_dir/Canada/Henripin_Canada_birth_rates.xlsx", sheet("birth_rate") firstrow case(lower) clear
gen order_var=[_n]


	two (connect que ont ne order_var, msymbol(O S T) mcolor(black black black) lpattern(solid solid solid) lcolor(black black black)),	xlabel(1 `""1846-" "1856""' 2 `""1856-" "1866""' 3 `""1866-" "1876""' 4 `""1876-" "1886""' 5 `""1886-" "1896""' 6 `""1896-" "1906""' 7 `""1906-" "1916""' 8 `""1916-" "1926""', grid notick) ylabel(25(5)50, grid notick angle(0)) legend(order(1 "Quebec" 2 "Ontario" 3 "Nova Scotia") rows(3) position(1) ring(0) bmargin(small) colgap(small)) xtitle("Period") ytitle("Births per 1000 persons")  xline(3, lcolor(black) lw(medthick)) name(main, replace)


	graph export "$results/F2_canada_time_series.pdf", replace

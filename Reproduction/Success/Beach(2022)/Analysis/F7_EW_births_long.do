clear all


*Get births data
use district births year using "$data_dir/England_and_Wales/district_births_data_standardized"
		
*Merge to get pop data
merge 1:1 district year using "$data_dir/England_and_Wales/district_pop_by_age_combined", nogen keepusing(total_pop)

collapse (sum) births total_pop, by(year)
	replace total_pop=. if total_pop==0

*interpolate population
	tsset year, delta(1)
	tsfill

	sort year
	ipolate total_pop year, gen(total_pop_int)

*Generate 5 year averages to reduce noise

gen cbr_registrar=((births+f.births+f2.births+f3.births+f4.births)/5)/(total_pop_int/1000) 
	keep if inlist(year,1851,1856,1861,1866,1871,1876,1881,1886,1891)

keep year cbr_registrar

merge 1:1 year using "$data_dir/England_and_Wales/WS_a3_1_birth_rate_series.dta"
ren cbr cbr_ws, nogen

sort year
two line cbr_ws cbr_registrar year, lcolor(black black) lw(medthick medthick) lpattern(longdash solid) xlabel(1541(15)1891, grid notick angle(45)) ylabel(25(5)45, grid notick angle(0)) xline(1877, lw(medthick) lcolor(black)) ytitle("Births per 1000 Persons") xtitle("Year") legend(order(1 "Wrigley and Schofield" 2 "Registrar General") pos(11) ring(0) cols(1)) 

graph export "$results/F7_ew_cbr_long.pdf", replace

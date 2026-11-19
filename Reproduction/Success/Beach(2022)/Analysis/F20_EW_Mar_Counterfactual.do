use "$temp_dir/F20_T29_panel.dta", clear

gen treat_group=(opened_75_77>0)

collapse birth_rate counter_birth_rate, by(treat_group year)

keep if inrange(year,1872,1882)
*Normalize time series
	sum birth_rate if year==1877 & treat_group==0
	gen norm_birth_rate=birth_rate/140.1334 if treat_group==0

	sum birth_rate if year==1877 & treat_group==1
	replace norm_birth_rate=birth_rate/140.235 if treat_group==1
	
	gen norm_counter_birth_rate=counter_birth_rate/140.235 if treat_group==1

two (line norm_birth_rate year if treat_group==0, lw(medthick) lcolor(black*.3) lpattern(dash_dot)) (line norm_birth_rate year if treat_group==1, lw(medthick) lcolor(black) lpattern(solid)) (line norm_counter_birth_rate year if treat_group==1, lcolor(black*.6) lw(medthick) lpattern(longdash)), xline(1877) ylabel(0.92(0.04)1, grid notick angle(0)) xlabel(1872(2)1882, grid notick) legend(order(1 "Control Districts" 2 "Treated Districts" 3 "Treated Counterfactual") pos(8) ring(0) cols(1)) xtitle("Year") ytitle("Normalized Birth Rate")

graph export "$results/F20_EW_Mar_Counterfactual.pdf", replace

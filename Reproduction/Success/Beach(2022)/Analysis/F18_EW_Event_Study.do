*Grab district characteristics
use year comparison_75_80 district region_code pre_75_papers opened_75_77 opened_78_80 total_pop_1871 mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 using "$temp_dir/EW_DD_cleaned.dta" if year==1878 & comparison_75_80==1, clear

drop year comparison_75_80

*Now go back and generate annual fertility rates
merge 1:m district using "$data_dir/England_and_Wales/district_births_data_standardized", keepusing(births year) keep(3) nogen
			
*Merge to get pop data
	merge 1:1 district year using "$data_dir/England_and_Wales/district_pop_by_age_combined", nogen keepusing(age_15_F age_20_F age_25_F age_30_F age_35_F age_40_F age_45_F) keep(1 3)
	
	*Define fertile population as (female) 15-50
	gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F
		
		
	*interpolate fertile pop.
	egen dist_code=group(district)

	xtset dist_code year, delta(1)
	tsfill

	*Carry forward district name
		sort dist_code year
			replace district=district[_n-1] if district=="" & dist_code==l.dist_code

	*interpolate population
		sort dist_code year
			by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)
	
gen birth_rate=births/(pop_fertile_F_int/1000)

sort dist_code year

gen birth_rate_m1=birth_rate[_n-1] if dist_code==dist_code[_n-1] & year==year[_n-1 + 1]

keep if inrange(year,1863,1891)

forv x=1868/1886 {
	gen opened_75_77X`x'=(year==`x')
	replace opened_75_77X`x'=opened_75_77X`x'*opened_75_77
}

gen opened_75_77X1867down=(year<1867)
replace opened_75_77X1867down=opened_75_77X1867down*opened_75_77

gen opened_75_77X1887up=(year>1886)
replace opened_75_77X1887up=opened_75_77X1887up*opened_75_77


reghdfe birth_rate c.pre_75_papers#i.year i.region_code#i.year c.mar_rate_73_77#i.year c.shrmar_registrar_73_77#i.year c.shrmar_catholic_73_77#i.year c.shrmar_minors_73_77#i.year c.shrmar_illit_73_77#i.year c.shrmar_first_73_77#i.year c.density_71#i.year c.total_mr_71_80#i.year c.under5_mr_71_80#i.year c.illeg_birth_share_73_77#i.year c.shr_manuf#i.year c.shr_agriculture#i.year c.u30_fert_shr_1871#i.year  opened_75_77X* [aweight=total_pop_1871], absorb(year dist_code) cluster(dist_code)



matrix RES=(1867,_b[opened_75_77X1867down],_se[opened_75_77X1867down])
forv x=1868/1876 {
	matrix RES=RES\(`x',_b[opened_75_77X`x'],_se[opened_75_77X`x'])
}

matrix RES=RES\(1877,0,.)

forv x=1878/1887 {
	matrix RES=RES\(`x',_b[opened_75_77X`x'],_se[opened_75_77X`x'])
}

		
svmat RES
keep RES1 RES2 RES3

	drop if RES1==.
	
	ren RES1 year
	ren RES2 Beta
	ren RES3 SE
	
	gen ci_high=Beta+1.96*SE
	gen ci_low=Beta-1.96*SE
	
	
	two (scatter Beta year, mcolor(black)) (rcap ci_high ci_low year, lcolor(black)), yline(0, lw(medthick)) xline(1877, lw(medthick) lpattern(longdash)) legend(off) xlabel(1867 "1863-1867" 1869(2)1885 1887 "1887-1891", angle(45) grid notick) xtitle("") ylabel(-10(5)5, grid notick angle(0))
	
	graph export "$results/F18_EW_Event_Study.pdf", replace

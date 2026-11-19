clear all


/*  Start with cleaned aggregate dataset, which provides an easy way of grabbing
	district characteristics */
	
use district region total_pop_1851 area using "$data_dir/England_and_Wales/EW_District_Chars.dta"
	gen density_1851=total_pop_1851/area

*Merge to get births data
merge 1:m district using "$data_dir/England_and_Wales/district_births_data_standardized", nogen keepusing(births year)
		
*Merge to get pop data
merge 1:1 district year using "$data_dir/England_and_Wales/district_pop_by_age_combined", nogen keepusing(age_15_F age_20_F age_25_F age_30_F age_35_F age_40_F age_45_F)
	
	*Define fertile population as (female) 15-50
		gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F
		
		*Now to fill in for other periods
			egen dist_code=group(district)

			xtset dist_code year, delta(1)
			
			*interpolate population
				sort dist_code year
				by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)

********************************************************************************
********************************************************************************

*Top Panel: Birth Rates in E&W over time (raw and detrended)
preserve
	collapse (sum) births pop_fertile_F_int, by(year)
	gen birth_rate=births/(pop_fertile_F_int/1000)

	reg birth_rate year if inrange(year,1851,1877)
	predict birth_rate_res, res

	*Left is raw data
	two (line birth_rate year if inrange(year,1851,1891), lcolor(black) lwidth(medthick)), xlabel(1851(5)1891, grid labsize(large) notick) ylabel(100(20)160, grid labsize(large) notick angle(0)) legend(off) name(F1a, replace) ytitle("Birth Rate", size(vlarge)) xtitle("Year", size(vlarge)) title("Birth Rate", size(huge)) nodraw
	
	*Right is detrended (1851-1871)
	two (line birth_rate_res year if inrange(year,1851,1877), lcolor(black) lwidth(medthick)) ///
		(line birth_rate_res year if inrange(year,1877,1891), lcolor(black) lpattern(dash) lwidth(medthick)), xlabel(1851(5)1891, grid labsize(large) notick) ylabel(-40(20)20, grid labsize(large) notick angle(0)) yline(0, lcolor(black*.5) lwidth(medthick)) xline(1877, lcolor(black) lwidth(thick)) legend(off) ytitle("Birth Rate Residuals", size(vlarge)) xtitle("Year", size(vlarge)) title("Detrended Relative to 1851-1877", size(huge)) name(F1b, replace) nodraw

	graph combine F1a F1b, xsize(11) title("National Patterns", size(huge)) name(f_national, replace)		
	graph export "$results/F1_ew_national_time_series_a.pdf", replace
restore		
		

*Middle Panel: Cutting series by region	

preserve
	replace region="Midlands" if inlist(region,"north_mid", "south_mid","west_mid")
	replace region="Wales" if region=="wales"
	replace region="London" if inlist(region,"london")
	replace region="Southern" if inlist(region,"southeast", "southwest","east")
	replace region="Northern" if inlist(region,"north", "northwest","yorkshire")

	collapse (sum) births pop_fertile_F_int, by(region year)
	
	gen birth_rate=births/(pop_fertile_F_int/1000)

	
two (connect birth_rate year if inrange(year,1851,1891) & region=="London", lcolor(black) mcolor(black) msymbol(Sh) lpattern(solid)) ///
	(connect birth_rate year if inrange(year,1851,1891) & region=="Midlands", lcolor(black) mcolor(black) msymbol(Th) lpattern(solid)) /// 
	(connect birth_rate year if inrange(year,1851,1891) & region=="Wales", lcolor(black) mcolor(black) msymbol(Dh) lpattern(solid)) /// 
	(connect birth_rate year if inrange(year,1851,1891) & region=="Northern", lcolor(black) mcolor(black) msymbol(X) lpattern(solid)) ///
	(connect birth_rate year if inrange(year,1851,1891) & region=="Southern", lcolor(black) mcolor(black) msymbol(Oh) lpattern(solid)), xlabel(1851(5)1891, labsize(large) grid notick)  ylabel(100(20)160, labsize(large) grid notick angle(0)) legend(off) name(F2a, replace) ytitle("Birth Rate", size(vlarge)) xtitle("Year", size(vlarge)) title("Birth Rates", size(huge)) nodraw

*Detrended	
gen birth_rate_res=.

foreach x in London Midlands Wales Northern Southern {
	reg birth_rate year if region=="`x'" & inrange(year,1851,1877)
	predict _temp_res, res
	
	replace birth_rate_res=_temp_res if region=="`x'"
	drop _temp_res
}	
	
two (connect birth_rate_res year if inrange(year,1851,1891) & region=="London", lcolor(black) mcolor(black) msymbol(Sh) lpattern(solid)) ///
	(connect birth_rate_res year if inrange(year,1851,1891) & region=="Midlands", lcolor(black) mcolor(black) msymbol(Th) lpattern(solid)) /// 
	(connect birth_rate_res year if inrange(year,1851,1891) & region=="Wales", lcolor(black) mcolor(black) msymbol(Dh) lpattern(solid)) /// 
	(connect birth_rate_res year if inrange(year,1851,1891) & region=="Northern", lcolor(black) mcolor(black) msymbol(X) lpattern(solid)) ///
	(connect birth_rate_res year if inrange(year,1851,1891) & region=="Southern", lcolor(black) mcolor(black) msymbol(Oh) lpattern(solid)), xlabel(1851(5)1891, labsize(large) grid notick)  ylabel(-40(20)20, labsize(large) grid notick angle(0)) legend(order(1 "London" 2 "Midlands" 3 "Wales" 4 "Northern" 5 "Southern") rows(3) position(7) ring(0) bmargin(small) colgap(small) size(large)) yline(0, lcolor(black*.5) lwidth(medthick)) xline(1877, lcolor(black) lwidth(thick)) name(F2b, replace) ytitle("Birth Rate Residuals", size(vlarge)) xtitle("Year", size(vlarge)) title("Detrended Relative to 1851-1877", size(huge)) nodraw

	
graph combine F2a F2b, xsize(11) title("Regional Patterns", size(huge)) name(f_regional, replace)
graph export "$results/F1_ew_national_time_series_b.pdf", replace
restore


*Bottom Panel: Cutting series by population density
preserve
	sum density_1851, d

	gen rural=(density_1851<r(p25))
	gen urban=(density_1851>r(p75))
	gen med_density=(rural==0 & urban==0)

	sum density_1851 if rural==1
	sum density_1851 if urban==1
	sum density_1851 if med_density==1

	collapse (sum) births pop_fertile_F_int, by(year rural urban med_density)

	gen birth_rate=births/(pop_fertile_F_int/1000)

	two (connect birth_rate year if inrange(year,1851,1891) & urban==1, lcolor(black) mcolor(black) msymbol(O)) ///
		(connect birth_rate year if inrange(year,1851,1891) & rural==1, lcolor(black) mcolor(black) msymbol(Th)) /// 
		(connect birth_rate year if inrange(year,1851,1891) & med_density==1, lcolor(black) mcolor(black) msymbol(X)), xlabel(1851(5)1891, labsize(large) grid notick)  ylabel(100(20)160, labsize(large) grid notick angle(0)) legend(off) name(F3a, replace) ytitle("Birth Rate", size(vlarge)) xtitle("Year", size(vlarge)) title("Birth Rates", size(huge)) nodraw

		
	*Detrend	
	gen birth_rate_res=.
	foreach x in urban rural med_density {
		reg birth_rate year if `x'==1 & inrange(year,1851,1877)
		predict _temp_res, res
		
		replace birth_rate_res=_temp_res if `x'==1
		drop _temp_res
	}	

	two (connect birth_rate_res year if inrange(year,1851,1891) & urban==1, lcolor(black) mcolor(black) msymbol(O)) ///
		(connect birth_rate_res year if inrange(year,1851,1891) & rural==1, lcolor(black) mcolor(black) msymbol(Th)) /// 
		(connect birth_rate_res year if inrange(year,1851,1891) & med_density==1, lcolor(black) mcolor(black) msymbol(X)), xlabel(1851(5)1891, labsize(large) grid notick)  ylabel(-40(20)20, labsize(large) grid notick angle(0)) legend(order(1 "Top 25th" 2 "Bottom 25th" 3 "25-75th Percentile") rows(3) position(7) ring(0) bmargin(small) colgap(small) size(large)) yline(0, lcolor(black*.5) lwidth(medthick)) xline(1877, lcolor(black) lwidth(thick)) name(F3b, replace) ytitle("Birth Rate Residuals", size(vlarge)) xtitle("Year", size(vlarge)) title("Detrended Relative to 1851-1877", size(huge)) nodraw

	graph combine F3a F3b, xsize(11) title("Patterns by Population Density", size(huge)) name(f_density, replace)
	graph export "$results/F1_ew_national_time_series_c.pdf", replace
restore

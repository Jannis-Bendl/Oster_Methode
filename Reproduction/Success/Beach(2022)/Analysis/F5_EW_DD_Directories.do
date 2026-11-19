use district new_papers_* region total_pop_1871 using "$data_dir/England_and_Wales/EW_District_Chars.dta", clear
	
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

	
*Narrow comparison
	gen num_newly_opened=new_papers_1875+new_papers_1876+new_papers_1877
	gen num_nearly_opened=new_papers_1878+new_papers_1879+new_papers_1880
	
		gen broad_treat=(num_newly_opened>0)
		gen broad_control=(num_newly_opened==0 & num_nearly_opened>0)

		keep if broad_treat==1 | broad_control==1	
				
*Detrend by Region
	replace region="Midlands" if inlist(region,"north_mid", "south_mid","west_mid")
	replace region="Wales" if region=="wales"
	replace region="London" if inlist(region,"london")
	replace region="Southern" if inlist(region,"southeast", "southwest","east")
	replace region="Northern" if inlist(region,"north", "northwest","yorkshire")
		egen region_code=group(region)

gen birth_rate=births/(pop_fertile_F_int/1000)
reg birth_rate i.dist_code i.region_code#c.year [aweight=total_pop_1871] if inrange(year,1851,1877)
	predict birth_rate_res, res
		
collapse birth_rate_res [aweight=total_pop_1871], by(year broad_treat)


	two (connect birth_rate_res year if inrange(year,1851,1891) & broad_treat==1, lcolor(black) mcolor(black) msymbol(O) lpattern(solid)) ///
		(connect birth_rate_res year if inrange(year,1851,1891) & broad_treat==0, lcolor(black) mcolor(black) msymbol(Th) lpattern(solid)), xlabel(1851(5)1891, grid notick) ylabel(-30(10)10, grid notick) yline(0, lcolor(black)) xline(1877, lcolor(black) lw(medthick)) legend(order(1 "Opened 1875-77" 2 "Opened 1878-80") rows(2) position(7) ring(0) bmargin(small) colgap(small)) ytitle("Birth Rate Residuals") xtitle("Year") name(res, replace)
		
		graph export "$results/F5_EW_DD_Newspapers.pdf", replace

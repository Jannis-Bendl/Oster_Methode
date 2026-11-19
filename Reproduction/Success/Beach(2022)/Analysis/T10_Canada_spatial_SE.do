use "$temp_dir/Canada_agg_reg.dta" if inrange(period,3,4) & inlist(province,"ontario","quebec"), clear
 
******************************************
** Grab sample from Column 2 of Table 1 **
******************************************


*With Controls
eststo t1_c2: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 [aweight=fem_fertile_pop_1871], absorb(period loc_code) cluster(loc_code)

*Spatial standard errors
drop if lat==. | lon==.
drop _I*

xi i.period i.loc_code

/*	Replicate main result but without weights since we the two way clustering 
	command doesn't support regression weights */
eststo T10_1: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4, absorb(period loc_code) cluster(loc_code)
			

gen ones=1

foreach x in 25 50 100 200 {
*Panel A: Uniform Weights
eststo T10_a`x': ols_spatial_HAC br_ ones _I* density_4 pg_4 ag_shr_4 mf_ratio4 youngfertileshare_4 brit_origin_4, lat(lat) lon(lon) t(period) p(loc_code) dist(`x') lag(2)

*Panel B: Linear Decay
eststo T10_b`x': ols_spatial_HAC br_ ones _I* density_4 pg_4 ag_shr_4 mf_ratio4 youngfertileshare_4 brit_origin_4, lat(lat) lon(lon) t(period) p(loc_code) dist(`x') lag(2) bartlett
}

esttab T10_1 T10_a25 T10_a50 T10_a100 T10_a200 using "$results/T10_Canada_spatial_SE", b(3) se(3) label keep(brit_origin_4) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex replace


esttab T10_1 T10_b25 T10_b50 T10_b100 T10_b200 using "$results/T10_Canada_spatial_SE", b(3) se(3) label keep(brit_origin_4) star(* 0.10 ** 0.05 *** 0.01) mtitles("Baseline" "25 km" "50 km" "100 km" "200 km") tex append


*Footnote 64: How close is nearest county?

keep province county lat lon
duplicates drop

egen county_id=group(province county)

save "$temp_dir/canada_county_dist_calc.dta", replace

forv x=1/98 {
	preserve
			*Define district of interest and store lat lons
			local master=county_id[`x']	
			
			gen district=`master'
			local master_lat= lat[`x']
			local master_lon= lon[`x']
			
			drop if county_id==district
			
			*Calculate distance to each district
			geodist `master_lat' `master_lon' lat lon, gen(distance)
			
			collapse (min) distance, by(district)
				ren district county_id
			
			*Merge with final distance dataset
			merge 1:1 county_id using "$temp_dir/canada_county_dist_calc.dta", nogen
			
			compress
			save "$temp_dir/canada_county_dist_calc.dta", replace
		restore	
}

use "$temp_dir/canada_county_dist_calc.dta", clear

sum distance, d

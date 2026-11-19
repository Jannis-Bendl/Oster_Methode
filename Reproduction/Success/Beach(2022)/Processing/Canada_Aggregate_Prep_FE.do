use "$data_dir/Canada/CountyXCensus_pop_cats.dta", clear
	foreach x in totpop fem_fertile_pop pop_0_2 pop_3_8 pop_0_5 pop_5_10 pop_0_6 pop_6_11 {
		ren `x' `x'_
	}
	
	reshape wide totpop_ fem_fertile_pop_ pop_0_2_ pop_3_8_ pop_0_5_ pop_5_10_ pop_0_6_ pop_6_11_, i(province county) j(year)
	
	/* 	Birth year is inferred based on age at time of enumeration (April)
		we define the period based on the earliest potential birth year for 
		each age category. e.g. 0 in 1881 maps to 1880 while 10 in 1891 maps 
		to 1881 */
	
	gen br_1864_70=((pop_0_6_1871)/6)/(fem_fertile_pop_1861/1000)
	gen br_1872_77=((pop_3_8_1881)/6)/(fem_fertile_pop_1871/1000)
	gen br_1878_80=((pop_0_2_1881)/3)/(fem_fertile_pop_1871/1000)
	gen br_1881_85=((pop_5_10_1891)/5)/(fem_fertile_pop_1881/1000)
	
	keep br_* province county fem_fertile_pop_1871 fem_fertile_pop_1881
	reshape long br_, i(province county) j(year) string

	gen period=.
		replace period=2 if year=="1864_70"
		replace period=3 if year=="1872_77"
		replace period=4 if year=="1878_80"
		replace period=5 if year=="1881_85"
		
		
drop if county=="Nipissing" //Only one pre-period change		


*Bring in controls
merge m:1 province county using "$data_dir/Canada/County_controls", keep(3) nogen //Labrador is missing

*Bring in lat lon
merge m:1 province county using "$data_dir/Canada/province_county_lat_lon.dta", keep(3) nogen


gen post_period=(inrange(period,4,6))
gen britXpost=british_origin_shr_1861*post_period

gen pop_growth_61_71=ln(totpop_1871)-ln(totpop_1861)

forval i = 2/6 {

gen brit_origin_`i'=0
replace brit_origin_`i'=british_origin_shr_1861 if period==`i'

gen native_brit_origin_`i'=0
replace native_brit_origin_`i'=british_origin_shr_1861-ews_origin_shr_1861-irish_origin_shr_1861 if period==`i'

gen brit_imm_origin_`i'=0
replace brit_imm_origin_`i'=ews_origin_shr_1861+irish_origin_shr_1861 if period==`i'

gen ews_origin_`i'=0
replace ews_origin_`i'=ews_origin_shr_1861 if period==`i'

gen irish_origin_`i'=0
replace irish_origin_`i'=irish_origin_shr_1861 if period==`i'

gen other_imm_shr_`i'=0
replace other_imm_shr_`i'=other_imm_shr_1861 if period==`i'

gen non_cath_`i'=0
replace non_cath_`i'=(1-catholic_shr_1861) if period==`i'

gen non_french_`i'=0
replace non_french_`i'=(1-french_origin_shr_1861) if period==`i'

gen coe_shr_`i'=0
replace coe_shr_`i'=brit_rel_shr_1861 if period==`i'

gen density_`i'=0
replace density_`i'=density_1861 if period==`i'

gen pg_`i'=0
replace pg_`i'=pop_growth_61_71 if period==`i'

gen ag_shr_`i'=0
replace ag_shr_`i'=ag_shr_1861 if period==`i'

gen mf_ratio`i'=0
replace mf_ratio`i'=male_female_ratio_1861 if period==`i'

gen school_tot`i'=0
replace school_tot`i'=school_shr_tot_1871 if period==`i'

gen noread_`i'=0
replace noread_`i'=cant_read_shr_over20_1871 if period==`i'

gen youngfertileshare_`i'=0
replace youngfertileshare_`i'=fertile_under30_share_1871 if period==`i'
}

** 
gen loc=province+"_"+county
encode loc, gen(loc_code)
xtset loc_code period

xi i.period i.loc_code

drop if period==1

sort loc_code period

label var brit_origin_2 "British-origin shr. \multicolumn{1}{r}{$\times$ 1864-70 period}"
label var brit_origin_3 "British-origin shr. \multicolumn{1}{r}{$\times$ 1872-77 period}"
label var brit_origin_4 "British-origin shr. \multicolumn{1}{r}{$\times$ 1878-80 period}"
label var brit_origin_5 "British-origin shr. \multicolumn{1}{r}{$\times$ 1881-85 period}"

compress
save "$temp_dir/Canada_agg_reg.dta", replace

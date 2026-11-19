use "$temp_dir/Canada_agg_reg.dta" if inrange(period,2,5) & inlist(province,"ontario","quebec"), clear
 
 *Set control variable to missing for 3 out of 4 periods
 foreach x in british_origin_shr_1861  french_origin_shr_1861 catholic_shr_1861 brit_rel_shr_1861 ag_shr_1861 male_female_ratio_1861 school_shr_m_1871 cant_read_shr_over20_1871 ews_origin_shr_1861 irish_origin_shr_1861 other_imm_shr_1861 density_1861 {
 replace `x'=. if inlist(period,3,4,5)
 }
 

ren brit_rel_shr_1861 coe_shr_1864
	
label var br_ "Children per 1000 women per year, all periods"	
label var british_origin_shr_1861 "British origin share, 1861"	
label var french_origin_shr_1861 "French origin share, 1861"
label var catholic_shr_1861 "Catholic share, 1861"
label var coe_shr_1864  "Church of Eng/Scot. share, 1861"
label var ag_shr_1861  "Ag. employment share, 1861"
label var male_female_ratio_1861 "Male/female ratio, 1861"
label var school_shr_m_1871  "Share of children in school, 1871"
label var cant_read_shr_over20_1871 "Over 20 illiterate share, 1871"
label var ews_origin_shr_1861 "Eng/Wal/Scot. immigrant share, 1861"
label var irish_origin_shr_1861 "Irish immigrant share, 1861"
label var other_imm_shr_1861  "Other immigrants share, 1861"
label var density_1861 "Density (persons/acre) 1861"

cd "$results"
sutex br_ british_origin_shr_1861  french_origin_shr_1861 catholic_shr_1861 coe_shr_1864 ag_shr_1861 male_female_ratio_1861 school_shr_m_1871 cant_read_shr_over20_1871 ews_origin_shr_1861 irish_origin_shr_1861 other_imm_shr_1861 density_1861, labels minmax file(T6_Canada_agg_sum_stats) replace

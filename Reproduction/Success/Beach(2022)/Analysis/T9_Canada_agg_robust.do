use "$temp_dir/Canada_agg_reg.dta", clear
 
*********************************************
** Table 9: Quebec and Ontario robustness ***
*********************************************

* 2 vs 4 comparison (0-5 against 0-5)
eststo t2_c1: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 [aweight=fem_fertile_pop_1871] if inlist(period,2,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)

* 3 vs 5 comparison (5-10 against 5-10)
eststo t2_c2: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_5 [aweight=fem_fertile_pop_1871] if inlist(period,3,5) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)

*Unweighted
eststo t2_c3: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)

*Quebec only
eststo t2_c4: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"quebec"), absorb(period loc_code) cluster(loc_code)

*Schooling controls
eststo t2_c5: reghdfe br_ school_tot* density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* brit_origin_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)

*Separate Immigrants
gen native_britXpost=(british_origin_shr_1861-ews_origin_shr_1861-irish_origin_shr_1861)*post_period
gen brit_immXpost=(ews_origin_shr_1861+irish_origin_shr_1861)*post_period
gen other_immXpost=other_imm_shr_1861*post_period

label var native_britXpost "Canadian-born British shr \multicolumn{1}{r}{$\times$ 1878-80 period}"
label var brit_immXpost "First-gen. imm. British shr. \multicolumn{1}{r}{$\times$ 1878-80 period}"
label var other_immXpost "Other first-gen imm. shr. \multicolumn{1}{r}{$\times$ 1878-80 period}"

eststo t2_c6: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* native_britXpost brit_immXpost other_immXpost [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)


*Non French share as measure of british connection
label var non_french_4 "Non-French \multicolumn{1}{r}{$\times$ 1878-80 period}"

eststo t2_c7: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* non_french_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)

*Non-Catholic Share
label var non_cath_4 "Non-Catholic \multicolumn{1}{r}{$\times$ 1878-80 period}"
eststo t2_c8: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* non_cath_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) & inlist(province,"ontario","quebec"), absorb(period loc_code) cluster(loc_code)
	gen non_catholic=1-catholic_shr_1861
	
	sum non_catholic if e(sample)==1

eststo t2_c9: reghdfe br_ density_* pg_* ag_shr_* mf_ratio* youngfertileshare_* non_cath_4 [aweight=fem_fertile_pop_1871] if inrange(period,3,4) , absorb(period loc_code) cluster(loc_code)

esttab t2_c* using "$results/T9_Canada_Robust", label keep(brit_origin_4 brit_origin_5 brit_immXpost native_britXpost other_immXpost non_french_4 non_cath_4) order(brit_origin_4 brit_origin_5 brit_immXpost native_britXpost other_immXpost non_french_4 non_cath_4) stats(N r2_within, label("Observations" "Within R-Squared") fmt(0 3)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace	

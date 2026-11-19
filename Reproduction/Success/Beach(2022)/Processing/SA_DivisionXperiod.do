use "$data_dir/South_Africa/South_Africa_1875_1891.dta", clear

**** generate fertility rates
gen rate1875=pop1875_0_14 / fem1875_15_54
gen rate1891=pop1891_0_14 / fem1891_15_54

gen diff=rate1891-rate1875

**** generate british measures
gen non_dutch_shr=1-(dutch_reform_m+dutch_reform_f)/totpop1875
gen brit_imm_shr=brit_imm/totpop1875
gen other_imm_shr=other_imm/totpop1875


*** controls
gen density=totpop1875/area
gen literacy=lit_pop_adult1875/tot_pop_adult1875

*Turn into a panel
keep division lat lon rate1875 rate1891 non_dutch_shr brit_imm_shr other_imm_shr density literacy totpop1875

reshape long rate, i(division lat lon non_dutch_shr brit_imm_shr other_imm_shr density literacy totpop1875) j(period)

egen dcode=group(division)

gen post=(period==1891)

gen brit_imm_shrXpost=brit_imm_shr*post
gen other_imm_shrXpost=other_imm_shr*post
gen non_dutch_shrXpost=non_dutch_shr*post


gen densityXpost=density*post
gen literacyXpost=literacy*post

gen br_1875=rate if period==1875
gen br_1891=rate if period==1891

label var br_1875 "Birth rate, 1875 period"
label var br_1891 "Birth rate, 1891 period"

label var brit_imm_shr "Brit. imm. share, 1875"
label var non_dutch_shr "Non-Dutch share, 1875"
label var density "Pop. per sq. mi., 1875"
label var literacy "Literacy rate among 15-55, 1875"

label var brit_imm_shrXpost "Brit. imm. share $\times$ 1877-91"
label var non_dutch_shrXpost "Non-Dutch share $\times$ 1877-91"
label var other_imm_shrXpost "Non-Brit. imm. share $\times$ 1877-91"


	compress
	save "$temp_dir/SA_DivisionXperiod.dta", replace

use "$temp_dir/Canadian_Microdata.dta", clear

*Alternative pre periods: Baseline is 72_77 (3-8 year olds)
	* 4 year period // 3-6 year olds (74_77)
	eststo micro_car_1: reghdfe bc_scaled mom_british britXpost if inlist(period,"74_77","78_81"), absorb(distXyear age_binXyear head_occXyear) cluster(distca)
	
	*3 year adjusted to account for age heaping (4, 5, 6)
	eststo micro_car_2: reghdfe bc_scaled mom_british britXpost if inlist(period,"74_76","78_81"), absorb(distXyear age_binXyear head_occXyear) cluster(distca)
	
	*3 year nearest (3, 4, 5)
	eststo micro_car_3: reghdfe bc_scaled mom_british britXpost if inlist(period,"75_77","78_81"), absorb(distXyear age_binXyear head_occXyear) cluster(distca)
	
*Restrict to couples
eststo micro_car_4: reghdfe bc_scaled mom_british britXpost if inlist(period,"72_77","78_81") & inferred_couple==1, absorb(distXyear age_binXyear head_occXyear) cluster(distca)

*Separate Irish from British	
gen mom_irish=(mom_origin==2200)
gen irishXpost=(mom_irish & period=="78_81")

gen mom_brit_no_irish=(mom_british==1 & mom_irish==0)
gen brit_no_irishXpost=(mom_brit_no_irish==1 & period=="78_81")

eststo micro_car_5: reghdfe bc_scaled mom_irish mom_brit_no_irish brit_no_irishXpost irishXpost if inlist(period,"72_77","78_81"), absorb(distXyear age_binXyear head_occXyear) cluster(distca)

* Drop the Irish
eststo micro_car_7: reghdfe bc_scaled mom_british britXpost if inlist(period,"72_77","78_81") & mom_origin!=2200, absorb(distXyear age_binXyear head_occXyear) cluster(distca)

*Alternative Culture Definition
*Alt Culture Def.
gen non_cath=(mom_religiond!=6001)
gen non_cathXpost=(non_cath & period=="78_81")

eststo micro_car_8: reghdfe bc_scaled non_cath non_cathXpost if inlist(period,"72_77","78_81") & mom_origin!=2200, absorb(distXyear age_binXyear head_occXyear) cluster(distca)


label var brit_no_irishXpost "British (but no Irish) $\times$ Post 1877"
label var irishXpost "Irish $\times$ Post 1877"
label var non_cathXpost "Non-Catholic $\times$ Post 1877"

esttab micro_car_* using "$results/T11_Canada_Micro_Robust", label keep(britXpost brit_no_irishXpost irishXpost non_cathXpost) stats(N, label("Observations") fmt(%9.0fc)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace	

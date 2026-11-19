use "$temp_dir/Canadian_Microdata.dta" if inlist(period,"72_77","78_81"), clear

*Baseline results -- Quebec and Ontario Only
eststo micro_ca_1: reghdfe bc_scaled mom_british britXpost if  inlist(provca,15,17), absorb(distca period_fe) cluster(distca)

* All counties
eststo micro_ca_2: reghdfe bc_scaled mom_british britXpost, absorb(distca period_fe) cluster(distca)

* Dist X year
eststo micro_ca_3: reghdfe bc_scaled mom_british britXpost, absorb(distXyear) cluster(distca)

* Age bin X year
eststo micro_ca_4: reghdfe bc_scaled mom_british britXpost, absorb(distXyear age_binXyear) cluster(distca)

* Occ X year
eststo micro_ca_5: reghdfe bc_scaled mom_british britXpost, absorb(distXyear age_binXyear head_occXyear) cluster(distca)

esttab micro_ca_1 micro_ca_2 micro_ca_3 micro_ca_4 micro_ca_5 using "$results/T2_Canada_mico", label keep(britXpost) stats(N, label("Observations") fmt(%9.0fc)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

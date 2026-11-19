use "$temp_dir/SA_DivisionXperiod.dta", clear

*Baseline
eststo SA_1: reghdfe rate densityXpost brit_imm_shrXpost [aweight=totpop1875], absorb(dcode period) cluster(dcode)

*With literacy controls
eststo SA_2: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost [aweight=totpop1875], absorb(dcode period) cluster(dcode)

*Add other immigrant share
eststo SA_3: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost other_imm_shrXpost [aweight=totpop1875], absorb(dcode period) cluster(dcode)

*Use non-dutch share instead
eststo SA_4: reghdfe rate densityXpost literacyXpost non_dutch_shrXpost [aweight=totpop1875], absorb(dcode period) cluster(dcode)

*No major urban
eststo SA_5: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost [aweight=totpop1875] if density<10, absorb(dcode period) cluster(dcode)

*No weights
eststo SA_6: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost , absorb(dcode period) cluster(dcode)

*No weights but pop>2000
eststo SA_7: reghdfe rate densityXpost literacyXpost brit_imm_shrXpost if totpop1875>2000, absorb(dcode period) cluster(dcode)


esttab SA_* using "$results/T17_SA_Main_results", b(3) se(3) label keep(brit_imm_shrXpost non_dutch_shrXpost other_imm_shrXpost) stats(N r2_within, label("Observations" "Within R-squared") fmt(0 3)) star(* 0.10 ** 0.05 *** 0.01) tex replace

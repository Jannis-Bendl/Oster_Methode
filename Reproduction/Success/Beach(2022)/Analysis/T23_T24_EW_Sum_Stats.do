use birth_rate density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 comparison_75_80 year dist_code using "$temp_dir/EW_DD_cleaned.dta" if inrange(year,1868,1883), clear	

*Recode controls to be missing in all but one year so that we don't inflate the number of observations
foreach x in density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 {
	replace `x'=. if year!=1868
}

cd "$results"

*Full Sample
sutex birth_rate density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77, minmax labels file(T23_EW_Sum_Stats_Full) replace


*DD Sample
sutex birth_rate density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 if comparison_75_80==1, minmax labels file(T24_EW_Sum_Stats_DD) replace

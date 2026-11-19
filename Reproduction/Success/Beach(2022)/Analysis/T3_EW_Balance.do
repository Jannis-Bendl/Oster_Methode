use "$temp_dir/EW_DD_cleaned.dta" if year==1878, clear
	

gen est_5=established_papers+new_papers_1867+new_papers_1868+new_papers_1869+new_papers_1870+new_papers_1871+new_papers_1872
gen est_4=established_papers+new_papers_1867+new_papers_1868+new_papers_1869+new_papers_1870+new_papers_1871+new_papers_1872+new_papers_1873
gen est_3=established_papers+new_papers_1867+new_papers_1868+new_papers_1869+new_papers_1870+new_papers_1871+new_papers_1872+new_papers_1873+new_papers_1874
gen est_2=established_papers+new_papers_1867+new_papers_1868+new_papers_1869+new_papers_1870+new_papers_1871+new_papers_1872+new_papers_1873+new_papers_1874+new_papers_1875

*Balance test

gen openedXpost=0

*Rows 1-13
foreach x in mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 shr_manuf shr_agriculture u30_fert_shr_1871 {

egen std_`x'=std(`x')
		
	replace openedXpost=opened_73_77Xpost
	eststo `x'_1: reg std_`x' i.region_code openedXpost if year==1878 & comparison_73_82==1 [aweight=total_pop_1871], r	
	
	replace openedXpost=opened_74_77Xpost
	eststo `x'_2: reg std_`x' i.region_code openedXpost if year==1878 & comparison_74_81==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_75_77Xpost
	eststo `x'_3: reg std_`x' i.region_code openedXpost if year==1878 & comparison_75_80==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_76_77Xpost
	eststo `x'_4: reg std_`x' i.region_code openedXpost if year==1878 & comparison_76_79==1 [aweight=total_pop_1871], r
	
	*Attach label to openedXPost
	local label: var label `x'
	label var openedXpost "`label'"
	
	
	if "`x'"=="mar_rate_73_77" {
		esttab `x'_* using "$results/T3_EW_Balance", keep(openedXpost) label nogaps mtitles("5 year" "4 year" "3 year" "2 year") nonotes nonumbers noobs b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace	
	}
	
	else {
		esttab `x'_* using "$results/T3_EW_Balance", keep(openedXpost) label nogaps nomtitles nonotes nonumbers noobs b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex append
	}
	
}


*row 14

*Need to do established papers outside of the loop
	replace openedXpost=opened_73_77Xpost

	egen std_est_5=std(est_5)
	eststo est_1: reg std_est_5 i.region_code openedXpost if year==1878 & comparison_73_82==1 [aweight=total_pop_1871], r	
	
	replace openedXpost=opened_74_77Xpost
	egen std_est_4=std(est_4)
	eststo est_2: reg std_est_4 i.region_code openedXpost if year==1878 & comparison_74_81==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_75_77Xpost
	egen std_est_3=std(est_3)
	eststo est_3: reg std_est_3 i.region_code openedXpost if year==1878 & comparison_75_80==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_76_77Xpost
	egen std_est_2=std(est_2)
	eststo est_4: reg std_est_2 i.region_code openedXpost if year==1878 & comparison_76_79==1 [aweight=total_pop_1871], r

	label var openedXpost "Num. established newspapers"
	
esttab est_* using "$results/T3_EW_Balance", keep(openedXpost) label nogaps nomtitles nonumbers b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) tex append

*Row 15
egen std_birth_rate_lagged=std(birth_rate_lagged)
		
	replace openedXpost=opened_73_77Xpost
	eststo br_1: reg std_birth_rate_lagged i.region_code openedXpost if year==1878 & comparison_73_82==1 [aweight=total_pop_1871], r	
	
	replace openedXpost=opened_74_77Xpost
	eststo br_2: reg std_birth_rate_lagged i.region_code openedXpost if year==1878 & comparison_74_81==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_75_77Xpost
	eststo br_3: reg std_birth_rate_lagged i.region_code openedXpost if year==1878 & comparison_75_80==1 [aweight=total_pop_1871], r
	
	replace openedXpost=opened_76_77Xpost
	eststo br_4: reg std_birth_rate_lagged i.region_code openedXpost if year==1878 & comparison_76_79==1 [aweight=total_pop_1871], r
	
	*Attach label to openedXPost
	label var openedXpost "Birth rate, 1873-1877"
	
		esttab br_* using "$results/T3_EW_Balance", keep(openedXpost) label nogaps nomtitles nonotes stats(N, label("Districts") fmt(0)) noobs b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex append

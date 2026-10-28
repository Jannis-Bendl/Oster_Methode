*This file produces the tables in Xu "Reshaping Global Trade" (QJE)

*MAIN PAPER*

* =================================================================
* Table I: Summary statistics: Ports and Countries
* =================================================================
{
	*Ports
	use "$filepath/data/sr_ports_final.dta", clear
		replace avg_dist = avg_dist/1000
		keep if event == 0
		
		qui sum shock_lon, d
		gen above_avg = (shock_lon>r(mean))
		
		
		global port_var shock_lon ships frac_uk count_dest avg_dist bank_count for_bank empire_uk		

		qui estpost sum $port_var , d
		eststo tab1_1

	*Countries
	use "$filepath/data/lr_trade_final.dta", clear
		keep if year==1865 
		duplicates drop country_o, force
		
		rename expr_tot ships
		rename dest_num count_dest 
		rename bank_num bank_count
		rename fail_frac_o shock_lon
		gen empire_uk = (emp_o=="United Kingdom")
		replace avg_dist = avg_dist/1000
		
		keeporder country_o $port_var
		
		qui estpost sum $port_var , d
		eststo tab1_2
		
	esttab tab1_* using "$filepath/output/tab_sumstats.tex", replace ///
			order(shock_lon ships frac_uk count_dest avg_dist bank_count for_bank empire_uk) ///
			varlabels (ships "Exports" ///
				count_dest "Destinations (\# countries)" ///
				avg_dist "Distance to destination (km k)" ///
				frac_uk "Share exports to UK" ///
				bank_count "British banks" ///
				for_bank "Non-British banks" ///
				shock_lon "Exposure to failed British banks" ///
				empire_uk "Fraction in British Empire") ///
			mtitle("\underline{Ports}" "\underline{Countries}") lines ///
			cells("mean(fmt(2)) p50(fmt(2)) sd(par fmt(2))") booktabs collabels("mean" "median" "sd") ///
				nonum gaps 	

	}

* =================================================================
* Table II: Pre-crisis comparison of bank characteristics
* =================================================================
{
	use  "$filepath/data/bank_char_final.dta", clear
	
	*Balance tests
		global bank_var_js any_shareholder bank_capital_m bank_paidupcap_m bank_deposits_m bank_reserve_m ///
			bank_size_m leverage reserve liquidity
			
		global bank_var any_shareholder bank_lending_th age bank_locations bank_countries bank_region_count ///
			bank_Asia_th bank_Africa_th bank_NAmerica_th bank_SAmerica_th bank_Oceania_th bank_Europe_th ///
			bank_BritEmp_th bank_UK_th
			
		*Panel A: joint-stock banks
		eststo clear
		qui estpost sum $bank_var_js if jsbank==1	
			eststo t1
		qui estpost sum $bank_var_js if failure==0 & jsbank==1
			eststo t2
		qui estpost sum $bank_var_js  if failure==1 & jsbank==1
			eststo t3
		qui estpost ttest $bank_var_js if jsbank==1, by(failure)
			eststo t4
			
			esttab t1 t2 t3 t4 using "$filepath/output/table2_a", replace ///
			starlevels(* 0.1 ** 0.05 *** 0.01) ///
			varlabels(any_shareholder "OG Connection" ///
				bank_capital_m "Capital, authorized (\pounds m)" ///
				bank_paidupcap_m "Capital, paid up (\pounds m)" ///
				bank_deposits_m "Deposits (\pounds m)" ///
				bank_reserve_m "Reserve fund (\pounds m)" ///
				bank_size_m "Total size (\pounds m)" ///
				leverage "Leverage ratio" ///
				reserve "Reserve ratio" ///
				liquidity "Liquidity ratio", elist(any_shareholder \hline)) lines ///
			mtitle("All" "Not Failed" "Failed" "Diff") ///
			cells("mean(pattern(1 1 1 0) fmt(2)) b(pattern(0 0 0 1)) sd(pattern(1 1 1 0) par)  se(pattern(0 0 0 1) par star fmt(2))") ///
			booktabs collabels(none) nonum compress 		
				
		*Panel B: all banks
		eststo clear
		qui estpost sum $bank_var 
			eststo t1
		qui estpost sum $bank_var if failure==0 
			eststo t2
		qui estpost sum $bank_var  if failure==1 
			eststo t3
		qui estpost ttest $bank_var , by(failure)
			eststo t4
			
			esttab t1 t2 t3 t4 using "$filepath/output/table2_b", replace ///
			starlevels(* 0.1 ** 0.05 *** 0.01) ///
			varlabels(any_shareholder "OG Connection" ///
				bank_lending_th "Trade finance (\pounds k)" ///
				age "Age (years)" ///
				bank_locations "Cities (\#)" ///
				bank_countries "Countries (\#)" ///
				bank_region_count "Regions (\#)" ///
				bank_Asia_th "Asia (\pounds k)" ///
				bank_Africa_th "Africa (\pounds k)" ///
				bank_NAmerica_th "N. America (\pounds k)" ///
				bank_SAmerica_th "S. America (\pounds k)" ///
				bank_Oceania_th "Oceania (\pounds k)" ///
				bank_Europe_th "Europe (\pounds k)" ///
				bank_UK_th "UK (\pounds k)" ///
				bank_BritEmp_th "British Emp (\pounds k)", ///
				elist(any_shareholder \hline)) lines ///
			mtitle("All" "Not Failed" "Failed" "Diff") ///
			cells("mean(pattern(1 1 1 0) fmt(2)) b(pattern(0 0 0 1) fmt(2)) sd(pattern(1 1 1 0) par fmt(2))  se(pattern(0 0 0 1) par star fmt(2))") ///
			booktabs collabels(none) nonum compress 

	}
	

* =================================================================
* Table III: Pre-crisis location balance 
* =================================================================
{
	*Main table III
	{
	use "$filepath/data/port_balance.dta", clear
	rename ships ships_p
	rename s_n s_np
	rename frac_uk frac_uk_ships
	qui merge 1:1 bank using "$filepath/data/country_balance.dta"
	drop _merge
	
	*Effective sample size: 1/HHI of the s_n weights
	*Ports: s_n
	gen s_np2 = s_np^2
	egen s_np_HHI = total(s_np2)
	gen sampsize_port = 1/s_np_HHI
	
	*Countries: s_nexpr
	gen s_n2 = s_n^2
	egen s_n_HHI = total(s_n2)
	gen sampsize_country = 1/s_n_HHI

	eststo clear
	
	* weight by s_np
	global port_var ships_p avg_age frac_uk_ships for_bank count_dest capital dist_lon empire_uk 
		
	qui foreach var of varlist $port_var{
		sum `var', d
		replace `var' = (`var'-r(mean))/r(sd)
			
		gen D_`var' = failure
		rename `var' I_Failure
		qui reg D_`var' I_Failure [aw=s_np]
		rename I_Failure `var'
		eststo m2`var'		
	}
			
	* weight by s_n	
	global country_var expr_tot expr_growth frac_uk gold silver bimetallic conflict_any conflict_inter ///
		cotton_raw_val cotton_manu_val cotton_val grains_val bullion_val coffee_val alcohol_val prim_prod
	
	qui foreach var of varlist *_val{
		replace `var' = ln(`var')
		replace `var' = 0 if missing(`var')
	}
		
	qui foreach var of varlist $country_var{
		sum `var', d
		replace `var' = (`var'-r(mean))/r(sd)
		
		gen D_`var' = failure
		rename `var' I_Failure
		qui reg D_`var' I_Failure [aw=s_n]
		rename I_Failure `var'
		eststo m2`var'
		
	}
	
	*Label variables
	{
		label var ships_p "Ships"
		label var frac_uk_ships "Share to UK"
		label var frac_uk "Share to UK"
		label var dist_lon "Distance to London"
		label var empire_uk "Brit empire"
		label var for_bank "Foreign banks"
		label var count_dest "Destinations"
		label var capital "Capital city"
		label var expr_tot "Exports val."
		label var expr_growth "$\Delta$ Exports"
		label var prim_prod "Commodities share"
		label var gold "Gold"
		label var silver "Silver"
		label var bimetallic "Bimetallic"
		label var conflict_any "Conflict:any"		
		label var conflict_inter "Conflict: interstate"		
		label var cotton_raw_val "Cotton, raw"
		label var cotton_manu_val "Cotton, manu."
		label var cotton_val "Cotton"
		label var grains_val "Grains"
		label var bullion_val "Bullion"
		label var sugar_val "Sugar"
		label var coffee_val "Coffee"
		label var alcohol_val "Alcohol"		
	}
	
	* local name: variable label ships_p
	* 1. port list
	local port_label_list = ""
	local port_var_list = ""
	foreach t of varlist ships_p frac_uk_ships dist_lon empire_uk for_bank count_dest capital {
	   local name: variable label `t'
	   local port_label_list  "`port_label_list' "`name'""
	   local port_var_list "`port_var_list' m2`t'"
	   
	}
		
	*Table with values and shares*
	*ports
	esttab `port_var_list' using "$filepath/output/port_balance.tex", replace ///
	se star bracket starlevels(** 0.05 *** 0.01) nonotes ///
	drop(_cons) booktab mgroups (`port_label_list', pattern(1 1 1 1 1 1 1 1)  ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
	stats(N, label(N)) coeflabels(I_Failure "{}") nomtitles	//
	
	* 2. country(1) list
	local c_label_list = ""
	local c_var_list = ""
	foreach t of varlist expr_tot expr_growth frac_uk gold silver bimetallic conflict_any conflict_inter {
	   local name: variable label `t'
	   local c_label_list  "`c_label_list' "`name'""
	   local c_var_list "`c_var_list' m2`t'"
	
	}
	*countries (1)
	esttab  `c_var_list' using "$filepath/output/country_balance1.tex", replace ///
		se star bracket starlevels(** 0.05 *** 0.01) nonotes ///
		drop(_cons) ///
		booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
		stats(N, label(N)) coeflabels(I_Failure "{}") nomtitles

	* 3. country(2) list
	
	local c_label_list = ""
	local c_var_list = ""
	foreach t of varlist cotton_raw_val cotton_manu_val cotton_val grains_val bullion_val coffee_val alcohol_val prim_prod{
	   local name: variable label `t'
	   local c_label_list  "`c_label_list' "`name'""
	   local c_var_list "`c_var_list' m2`t'"   
	}
	
	*countries (2)
	esttab `c_var_list' ///
	using "$filepath/output/country_balance2.tex", replace ///
		se star bracket starlevels(** 0.05 *** 0.01) ///
		drop(_cons) nonotes ///
		booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
		stats(N, label(N))	coeflabels(I_Failure "{}") nomtitles
	}


	* G16: balance by SITC industries
	{
			
		global country_var_sitc sitc_54_val sitc_29_val sitc_42_val sitc_2_val sitc_68_val ///
				sitc_89_val sitc_1_val sitc_24_val sitc_53_val ///
				sitc_3_val sitc_32_val sitc_27_val sitc_33_val sitc_67_val sitc_69_val sitc_52_val ///
				sitc_51_val sitc_71_val sitc_64_val sitc_28_val sitc_66_val sitc_63_val ///
				sitc_61_val sitc_23_val sitc_55_val sitc_84_val
	eststo clear		
		qui foreach var of varlist $country_var_sitc {		
			sum `var', d
			replace `var' = (`var'-r(mean))/r(sd)
				
			gen D_`var' = failure
			rename `var' I_Failure
			qui reg D_`var' I_Failure [aw=s_np]
			rename I_Failure `var'
			eststo m2`var'		
		}
		

		*APPENDIX TABLES G16**
		label variable sitc_54_val "Medicines (54)"
		label variable sitc_29_val "Animal \& veg materials (29)"
		label variable sitc_42_val "Animal fats (42)"
		label variable sitc_68_val "Non-ferrous metals (68)"
		label variable sitc_89_val "Misc (89)"
		label variable sitc_1_val "Meat (1)"
		label variable sitc_24_val "Cork \& wood (24)"
		
		local c_label_list = ""
		local c_var_list = ""
		foreach t of varlist sitc_54_val sitc_29_val sitc_42_val sitc_68_val sitc_89_val sitc_1_val {
			local name: variable label `t'
			local c_label_list  "`c_label_list' "`name'""
			local c_var_list "`c_var_list' m2`t'"   
		}
			
		
		esttab `c_var_list' using "$filepath/output/country_balance_sitc-a.tex", replace ///
				se star bracket starlevels(** 0.05 *** 0.01) ///
				drop(_cons) ///
				booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				stats(N, label(N)) mlabel(, none) coeflabels(I_Failure "{}") nonotes	
		
		label variable sitc_53_val "Dyes (53)"
		label variable sitc_3_val "Fish (3)"
		label variable sitc_32_val "Coal (32)"
		label variable sitc_27_val "Crude minerals (27)"
		label variable sitc_33_val "Petroleum prod (33)"
		label variable sitc_67_val "Iron (67)"
		
		local c_label_list = ""
		local c_var_list = ""
		foreach t of varlist sitc_24_val sitc_53_val sitc_3_val sitc_32_val sitc_27_val sitc_33_val sitc_67_val {
			local name: variable label `t'
			local c_label_list  "`c_label_list' "`name'""
			local c_var_list "`c_var_list' m2`t'"   
			}	
			
		esttab  `c_var_list'   ///
		using "$filepath/output/country_balance_sitc-b.tex", replace ///
			se star bracket starlevels(** 0.05 *** 0.01) ///
			drop(_cons) ///
			booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
			stats(N, label(N)) mlabel(, none) coeflabels(I_Failure "{}") nonotes		
				
		
		label variable sitc_69_val "Metal manu (69)"
		label variable sitc_52_val "Inorganic chem (52)"
		label variable sitc_51_val "Organic chem (51)"
		label variable sitc_71_val "Machinery (71)"
		label variable sitc_64_val "Paper (64)"
		label variable sitc_28_val "Metal ores (28)"
		
		local c_label_list = ""
		local c_var_list = ""
		foreach t of varlist sitc_69_val sitc_52_val sitc_51_val sitc_71_val sitc_64_val sitc_28_val {
			local name: variable label `t'
			local c_label_list  "`c_label_list' "`name'""
			local c_var_list "`c_var_list' m2`t'"   
			}	
			
		esttab  `c_var_list' ///
			using "$filepath/output/country_balance_sitc-c.tex", replace ///
				se star bracket starlevels(** 0.05 *** 0.01) ///
				drop(_cons) ///
				booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				stats(N, label(N)) mlabel(, none) coeflabels(I_Failure "{}") nonotes		
		
		label variable sitc_61_val "Leather goods (61)"
		label variable sitc_66_val "Nonmetallic mineral manu (66)"
		label variable sitc_63_val "Wood manu (63)"
		label variable sitc_23_val "Rubber (23)"
		label variable sitc_55_val "Soap (55)"
		label variable sitc_84_val "Clothing (84)"
			
		
		local c_label_list = ""
		local c_var_list = ""
		foreach t of varlist sitc_66_val sitc_63_val sitc_61_val sitc_23_val sitc_55_val sitc_84_val{
			local name: variable label `t'
			local c_label_list  "`c_label_list' "`name'""
			local c_var_list "`c_var_list' m2`t'"   
			}	
		
		esttab `c_var_list' ///
			using "$filepath/output/country_balance_sitc-d.tex", replace ///
				se star bracket starlevels(** 0.05 *** 0.01) ///
				drop(_cons) ///
				booktab mgroups (`c_label_list', pattern(1 1 1 1 1 1 1 1)  ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				stats(N, label(N)) mlabel(, none) coeflabels(I_Failure "{}") nonotes					
		
	}
	

	*Appendix Fig B3: Joint significance: 
	{
	
		eststo clear 
		label var expr_growth "{&Delta} Exports"
		qui foreach var of varlist $port_var{
			replace `var' = 0 if missing(`var')
		}
			
		qui eststo joint: reg failure ships_p frac_uk_ships dist_lon empire_uk for_bank count_dest capital ///
			expr_tot expr_growth  gold silver bimetallic conflict_any conflict_inter ///
			cotton_raw_val cotton_manu_val cotton_val grains_val bullion_val coffee_val alcohol_val prim_prod
		coefplot joint, xline(0) drop(_cons) mcolor(edkblue) msymbol(O) mfcolor(white) ///
		levels(95 90) ciopts(lwidth(1 ..) lcolor(*.4 *1)) xlabel(-1(0.5)1) ///
		graphregion(color(white)) ysize(6)
		graph export "$filepath/output/app_fig_jointsig.pdf", replace 

		*F-stat: 
			
		test ships_p frac_uk_ships dist_lon empire_uk for_bank count_dest capital ///
			expr_tot expr_growth  gold silver bimetallic conflict_any conflict_inter ///
			cotton_raw_val cotton_manu_val cotton_val grains_val bullion_val coffee_val alcohol_val prim_prod
		
	}
}	

* =================================================================
* Tables IV & V: Short-term effects
* =================================================================
{
	eststo clear
	*Define variables
	{
		global country_controls post_lon event_og indic_o
		global port_controls post_capital post_frac_uk post_avg_age post_avg_og
		global port_fe event_og post_lon indic_p
		global port_ot_fe post_lon countryoid#event_og indic_ot indic_p
		global port_dest dest_id#event indic_dest
		global ext_controls capital frac_uk avg_age avg_og indic_o	
	}
				
	*Country-level effects in Tables IV & V
	{
		use "$filepath/data/sr_country_final.dta", clear
	
		*regressions
		qui reghdfe lnships post_fail_lon_c $country_controls [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tab4_1
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
		qui reghdfe lndest post_fail_lon_c $country_controls [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tab5_1
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2 
			
		qui reghdfe lnships_dest post_fail_lon_c $country_controls [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tab5_2
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2 
	}
	
	*Port-level effects in Tables IV & V
	{
		use "$filepath/data/sr_ports_final.dta", clear
		
		*regressions
		 qui reghdfe lnships post_fail_lon $port_fe [aw=port_size], absorb(port_id) cluster(countryoid)
			eststo tab4_2
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		 qui reghdfe lnships post_fail_lon indic_ot $port_fe [aw=port_size], absorb(port_id countryoid#event) cluster(countryoid)
			eststo tab4_3
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		qui reghdfe lnships post_fail_lon indic_ot $port_fe $port_controls [aweight=port_size], ///
			absorb(port_id countryoid#event) cluster(countryoid)  
			eststo tab4_4
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		qui reghdfe lnships post_fail_lon indic_ot $port_fe $port_controls [aweight=port_size] if port_id_cotton!=., ///
			absorb(port_id countryoid#event) cluster(countryoid)  
			eststo tab4_5
			qui sum port_id_cotton
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		qui poisson ships post_fail_lon indic_ot $port_fe $port_controls i.post_country i.port_id [iweight=port_size], cluster(countryoid)  
			eststo tab4_6
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) 
			estadd scalar Clust = e(N_clust)
	
		qui reghdfe lnships_newslag post_fail_lon indic_ot $port_fe $port_controls [aweight=port_size], ///
			absorb(port_id countryoid#event) cluster(countryoid)  
			eststo tab4_7
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		qui reghdfe lndest post_fail_lon indic_ot $port_fe $port_controls [aweight=port_size] , ///
			absorb(port_id countryoid#event) cluster(countryoid)  	
			eststo tab5_3
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2-1
			
			
		use "$filepath/data/sr_ext_final.dta", clear	
			
		*regressions
			qui reghdfe entry shock_lon $ext_controls if event==1 , absorb(countryoid) cluster(countryoid)
			eststo tab5_4
			qui sum port_id_entry
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)
			
			qui reghdfe exit shock_lon $ext_controls if event==0 , absorb(countryoid) cluster(countryoid)
			eststo tab5_5
			qui sum port_id_exit
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)
		
	}
	
	*Table output
	{
	* Table IV: Intensive margin effects
		version $system: esttab tab4_* using "$filepath/output/tab_ports_controls_qje.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post" ///
			post_fail_lon_c "Fail\textsubscript{o} $\times$ post") ///
				order(post_fail_lon_c  post_fail_lon) ///
				keep(post_fail_lon_c post_fail_lon) ///
				booktab mgroups ("Country" "Port"  "Excl. cotton" "Poisson" "News dates", ///
				pattern(1 1 0 0 1 1 1) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) ///
				span erepeat(\cmidrule(lr){@span})) lines ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG link $\times$ post=post_avg_og" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Country\textsubscript{o} FE = indic_o" ///
						"Port\textsubscript{p} FE = indic_p" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						 , labels (Y  )) nonotes mlabels(, none) eqlabels(" " " ")
						 
						 				 
	*Table V: Extensive margin effect of bank failures on shipping
		esttab tab5_* using "$filepath/output/tab_extensive_qje.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post" ///
			post_fail_lon_c "Fail\textsubscript{o} $\times$ post" ///
			shock_lon "Fail\textsubscript{po}") ///
				order(post_fail_lon_c  post_fail_lon shock_lon ) ///
				keep(post_fail_lon_c post_fail_lon shock_lon) ///
				booktab mgroups ("Con: dest" "Con: avg ships" "Ports: dest" "I(Port Entry)" "I(Port Exit)", pattern(1 1 1 1 1) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Port controls $\times$ post = post_capital" ///
						"Port controls = avg_age" ///
						"Port\textsubscript{p} FE = indic_p" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Country\textsubscript{o} FE=indic_o" ///
						 , labels (Y  )) nonotes mlabels(, none)
	
	}

}	



* =================================================================
* APPENDIX TABLES
* =================================================================

*Define globals for fixed effects
	global lr_fe_dt country_o_id country_d_id#year c.lgeo_dist#year brit_bank#year
	global lr_fe_d country_o_id country_d_id c.lgeo_dist#year brit_bank#year
	global lr_fe c.lgeo_dist#year brit_bank#year



	*A1: pseudo first stage
{
	use  "$filepath/data/bank_char_final.dta", clear
		gen bank_accept_growth = (bank_acceptance_66/bank_acceptance_65-1)
	
	eststo clear
	qui reg bank_accept_growth failure, r
		eststo m1
		estadd local weight "none"	
		
	 qui reg bank_accept_growth failure [aweight=bank_capital], r
		eststo m2
		estadd local weight "Capital, 1865"	
		
	qui reg bank_accept_growth failure [aweight=bank_lending ], r
		eststo m3
		estadd local weight "Trade credit, 1865"	
		
	qui reg bank_accept_growth failure [aweight=bank_size ], r
		eststo m4
		estadd local weight "Size, 1865"	
		
	esttab using "$filepath/output/app_tab_A1.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		drop(_cons) ///
		varlabels(failure "Failure\textsubscript{b}" ///
				_cons "Constant") ///
			booktab mgroups ("$\Delta$ Credit\textsubscript{b}", pattern(1 0 0 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				stats(weight N r2_a, label("Weighting" N "Adj. R{$^2$}" )) mlabels(, none) ///
			nonotes
	
}

	*A2: Comparison of banks in first stage to all banks
{
	use  "$filepath/data/bank_char_final.dta", clear
		gen bank_accept_growth = (bank_acceptance_66/bank_acceptance_65-1)
		gen missing = (bank_accept_growth==.)
		
	eststo clear	
		qui estpost sum $bank_var_js if jsbank==1
			eststo t1
		qui estpost sum $bank_var_js if missing!=1 & jsbank==1
			eststo t2
		qui estpost sum $bank_var_js if missing==1 & jsbank==1
			eststo t3
		
		qui estpost ttest $bank_var_js if jsbank==1, by(missing)
			eststo t4
			
			esttab t1 t2 t3 t4 using "$filepath/output/app_tab_A2.tex", replace ///
			starlevels(* 0.1 ** 0.05 *** 0.01) ///
			varlabels(any_shareholder "OG Connection" ///
				bank_capital_m "Capital, authorized (\pounds m)" ///
				bank_paidupcap_m "Capital, paid up (\pounds m)" ///
				bank_deposits_m "Deposits (\pounds m)" ///
				bank_reserve_m "Reserve fund (\pounds m)" ///
				bank_size_m "Total size (\pounds m)" ///
				leverage "Leverage ratio" ///
				reserve "Reserve ratio" ///
				liquidity "Liquidity ratio", elist(any_shareholder \hline)) lines ///
			mtitle("All" "In first stage" "Not in first stage" "Diff") ///
			cells("mean(fmt(2)) sd(par) b se(par star fmt(2))") booktabs collabels(none) ///
				nonum compress 
	
}

	*A3: balance by geographic exposure
{
	use  "$filepath/data/bank_char_final.dta", clear
	
	global bank_var_expos bank_UK_expos bank_BritEmp_expos bank_Europe_expos bank_Asia_expos bank_Africa_expos bank_NAmerica_expos ///
			bank_SAmerica_expos bank_Oceania_expos 
		
		eststo clear
		qui estpost sum $bank_var_expos
			eststo t1
		qui estpost sum $bank_var_expos if failure==0 
			eststo t2
		qui estpost sum $bank_var_expos  if failure==1 
			eststo t3
		qui estpost ttest $bank_var_expos, by(failure)
			eststo t4
			
			esttab t1 t2 t3 t4 using "$filepath/output/app_tab_A3", replace ///
			starlevels(* 0.1 ** 0.05 *** 0.01) ///
			varlabels(bank_UK_expos "UK \%" ///
			bank_BritEmp_expos "Brit. Emp. \%" ///
			bank_Europe_expos "Europe \%" ///
			bank_Asia_expos "Asia \%" ///
			bank_Africa_expos "Africa \%" ///
			bank_NAmerica_expos "N. America \%" ///
			bank_SAmerica_expos "S. America \%" ///
			bank_Oceania_expos "Australia \%", ///
				) lines ///
			mtitle("All" "Not Failed" "Failed" "Diff") ///
			cells("mean(pattern(1 1 1 0) fmt(2)) b(pattern(0 0 0 1) fmt(2)) sd(pattern(1 1 1 0) par fmt(2))  se(pattern(0 0 0 1) par star fmt(2))") ///
			booktabs collabels(none) nonum compress 

	
}

	*A4: Robustness at country-level 
{
	use "$filepath/data/country_char.dta", clear
		gen frac_uk = expr_uk/expr_tot
		replace frac_uk = . if year!=1865
	collapse (firstnm) *_val frac_uk prim_prod_avg gold silver bimetallic conflict*, by(country_o)
	
	qui merge 1:m country_o using "$filepath/data/sr_country_final.dta"
		drop if _merge!=3
		drop _merge

	qui foreach commod in sugar cotton_raw cotton_manu grains tobacco coffee alcohol {
		gen post_`commod' = ln(`commod'_val)*event
		replace post_`commod' = 0 if missing(post_`commod')
	}
	
	qui foreach var in frac_uk prim_prod_avg gold silver bimetallic conflict_any ///
		conflict_inter conflict_extra{
			gen post_`var' = `var'*event
			replace post_`var' = 0 if missing(post_`var')
		}
	
	eststo clear
	
	*regressions
	qui reghdfe lnships post_fail_lon_c $country_controls post_frac_uk [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_1
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
	
	qui reghdfe lnships post_fail_lon_c $country_controls post_gold [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_2
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_silver [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_3
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2		

	qui reghdfe lnships post_fail_lon_c $country_controls post_bimetallic [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_4
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_conflict_any [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_5
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_conflict_inter [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_6
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_conflict_extra [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabA4_7
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2

	qui reghdfe lnships post_fail_lon_c $country_controls post_cotton_raw [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_1
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_cotton_manu [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_2
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_grains [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_3
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_coffee [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_4
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_alcohol [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_5
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_tobacco [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_6
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
			
	qui reghdfe lnships post_fail_lon_c $country_controls post_prim_prod_avg [aw=port_size], absorb(countryoid) cluster(countryoid)
		eststo tabAb_7
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N)/2
		
	esttab tabA4_* using "$filepath/output/app_tab_A4b", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon_c "Fail\textsubscript{o} $\times$ post") ///
				keep(post_fail_lon_c) ///
				booktab lines ///
				stats(N N_clust, label(N "Clusters" )) mlabels(, none) ///
				indicate("Share to UK $\times$ post = post_frac_uk" ///
						"Gold $\times$ post = post_gold" ///
						"Silver $\times$ post = post_silver" ///
						"Bimetallic $\times$ post = post_bimetallic" ///
						"Conflict (any) $\times$ post = post_conflict_any" ///
						"Conflict (inter) $\times$ post = post_conflict_inter" ///
						"Conflict (extra) $\times$ post = post_conflict_extra" ///	
						"Country\textsubscript{o} FE=indic_o" ///
						 , labels (Y  )) nonotes
						 
	esttab tabAb_* using "$filepath/output/app_tab_A4a", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon_c "Fail\textsubscript{o} $\times$ post") ///
				keep(post_fail_lon_c) ///
				booktab lines ///
				stats(N N_clust, label(N "Clusters" )) mlabels(, none) ///
				indicate("Cotton raw $\times$ post = post_cotton_raw" ///
						"Cotton manu $\times$ post = post_cotton_manu" ///
						"Grains $\times$ post = post_grains" ///
						"Coffee $\times$ post = post_coffee" ///
						"Alcohol $\times$ post = post_alcohol" ///
						"Tobacco $\times$ post = post_tobacco" ///
						"Share commod $\times$ post = post_prim_prod_avg" ///	
						"Country\textsubscript{o} FE=indic_o" ///
						 , labels (Y  )) nonotes
	
}

	*A5: other financing 
{
	use "$filepath/data/sr_ports_final.dta", clear
		qui reghdfe lnships post_fail_lon post_fail_c_other $port_fe [aw=port_size], ///
			absorb(port_id) cluster(countryoid)
			eststo tabA5_1
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		qui reghdfe lnships post_fail_lon post_fail_c_other $port_fe $port_controls [aw=port_size], ///
			absorb(port_id) cluster(countryoid)
			eststo tabA5_2
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
		qui reghdfe lnships post_fail_lon post_for_bank post_for_bank_fail indic_ot $port_fe [aw=port_size], ///
			absorb(port_id event#countryoid) cluster(countryoid)
			eststo tabA5_3
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2

		qui reghdfe lnships post_fail_lon post_for_bank post_for_bank_fail indic_ot $port_fe $port_controls [aw=port_size], ///
			absorb(port_id event#countryoid) cluster(countryoid)
			eststo tabA5_4
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
		esttab tabA5_* using "$filepath/output/tab_ports_substitution_qje.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post" ///
			post_fail_c_other "Fail\textsubscript{other, po} $\times$ post" ///
			post_for_bank_fail "non-Brit banks $\times$ Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon post_fail_c_other) ///
				keep(post_fail_lon post_fail_c_other post_for_bank_fail) ///
				booktab lines ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Port controls $\times$ post = post_capital" ///
						"Port\textsubscript{p} FE = indic_p" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						 , labels (Y  )) nonotes mlabels(, none)
	
}


	*A6: elasticity to physical distance 
{

		use "$filepath/data/lr_trade_final.dta", clear
		rename regio_o_id regio_id
		rename lgeo_dist ldist
			
		eststo clear
		
		qui reghdfe lexpr_f ldist if year>=1850, ///
			absorb(country_o_id#year country_d_id#year) ///
			cluster(country_o_id)
		eststo m0
			estadd scalar N_true = e(N) + e(num_singletons)
		
		qui reghdfe lexpr_f ldist if year>=1850, ///
			absorb(country_o_id#year country_d_id#year Comlang#year) ///
			cluster(country_o_id)
		eststo m1
			estadd scalar N_true = e(N) + e(num_singletons)
			
		qui reghdfe lexpr_f ldist if year>=1850, ///
			absorb(country_o_id#year country_d_id#year Contig#year) ///
			cluster(country_o_id)
		eststo m2
			estadd scalar N_true = e(N) + e(num_singletons)
		
		qui reghdfe lexpr_f ldist if year>=1850, ///
			absorb(country_o_id#year country_d_id#year Evercol#year) ///
			cluster(country_o_id)
		eststo m3
			estadd scalar N_true = e(N) + e(num_singletons)
				
		qui reghdfe lexpr_f ldist if year>=1850, ///
			absorb(country_o_id#year country_d_id#year Comlang#year Contig#year Evercol#year) ///
			cluster(country_o_id)
		eststo m4
			estadd scalar N_true = e(N) + e(num_singletons)
	
	
	estfe . m* , labels(country_o_id#year "Country\textsubscript{ot} FE" ///
		country_d_id#year "Country\textsubscript{dt} FE" ///
		Comlang#year "Common language $\times$ t" ///
		Contig#year "Common border $\times$ t" ///
		Evercol#year "Common empire $\times$ t") 
		return list	

	esttab m* using "$filepath/output/app_tab_A6.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) brackets ///
			keep(ldist) ///
			varlabels(ldist "log distance \textsubscript{od}" ///
				, elist(ldist \hline)) lines ///
				booktab  ///
				nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" Clusters "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	

	
}


	*A7: robustness to different clustering
{
	use "$filepath/data/lr_trade_final.dta", clear
	
	eststo clear
	qui reghdfe lexpr_f fail_frac_1* if year>=1865 & year<=1870, ///
		absorb($lr_fe_dt) ///
		cluster(country_o_id)
	eststo m1
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd local cluster "Orig country"
		
	qui reghdfe lexpr_f fail_frac_1* if year>=1865 & year<=1870, ///
		absorb($lr_fe_dt) ///
		cluster(country_d_id)
	eststo m2
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd local cluster "Dest country"
	
	qui reghdfe lexpr_f fail_frac_1* if year>=1865 & year<=1870, ///
		absorb($lr_fe_dt) ///
		cluster(country_o_id#country_d_id)
	eststo m3
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd local cluster "Orig-Dest pair"
			
	qui reghdfe lexpr_f fail_frac_1* if year>=1865 & year<=1870, ///
		absorb($lr_fe_dt) ///
		cluster(country_o_id country_d_id)
	eststo m4
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd local cluster "Multi: Orig, Dest"
		
	qui reghdfe lexpr_f fail_frac_1* if year>=1865 & year<=1870, ///
		absorb($lr_fe_dt) ///
		cluster(country_o_id country_d_id year)
	eststo m5
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd local cluster "Multi: Orig, Dest, year"

	estfe . m* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		brit_bank#year "I(Brit bank\textsubscript{ot})" ///
		country_d_id#year "Country\textsubscript{dt}")
		return list

	esttab m* using "$filepath/output/app_tab_A7.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) brackets ///
			keep(fail_frac_1865 fail_frac_1867 fail_frac_1868 fail_frac_1869 ///
			fail_frac_1870 ) ///
			varlabels(fail_frac_1865 "$\beta$\textsubscript{1865}" ///
				fail_frac_1867 "$\beta$\textsubscript{1867}" ///
				fail_frac_1868 "$\beta$\textsubscript{1868}" ///
				fail_frac_1869 "$\beta$\textsubscript{1869}" ///
				fail_frac_1870 "$\beta$\textsubscript{1870}" ///
				, elist(fail_frac_1870)) lines ///
				booktab  ///
				nodep nomtitles ///
			stats(N_true cluster r2_a, label("N" "Clustering" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
	
}

	*A8: distribution of exposure for countries
{
	use "$filepath/data/lr_trade_final.dta", clear

	collapse expr_tot, by(country_o year fail_frac_o)

	gen fail_frac_o_nozero = fail_frac_o if fail_frac_o>0

	label variable fail_frac_o "Unconditional"
	label variable fail_frac_o_nozero "Greater than 0"

	// create a matrix 2*6: two vars and 6 index
	mat data=J(2,6,.)

	// insert 1 value into the table
	qui summarize fail_frac_o if year==1866, detail 

	mat data[1,1] = r(N)
	mat data[1,2] = r(mean)
	mat data[1,3] = r(p25)
	mat data[1,4] = r(p50)
	mat data[1,5] = r(p75)
	mat data[1,6] = r(p90)

	// insert 2 value into the table
	qui summarize fail_frac_o_nozero if year==1866, detail
	mat data[2,1] = r(N)
	mat data[2,2] = r(mean)
	mat data[2,3] = r(p25)
	mat data[2,4] = r(p50)
	mat data[2,5] = r(p75)
	mat data[2,6] = r(p90)

	
	mat rownames data = "Unconditional" "Greater than 0"
	mat colnames data = "Count" "Mean" "25th" "50th" "75th" "90th"
	esttab matrix(data, fmt(0 2 2 2 2 2)) ///
		using "$filepath/output/app_tab_A8.tex", replace  nomtitles booktabs
}


	*A9: Effects on imports
{
	use "$filepath/data/shock_country.dta", clear
		rename country_o country_d
		rename shock_country fail_frac_d
		keeporder country_d fail_frac_d
		
		qui merge 1:m country_d using "$filepath/data/lr_trade_final"
		drop if _merge==1
		drop _merge
		
		replace fail_frac_d = 0 if missing(fail_frac_d)
		
		foreach var of varlist d6_55-d6_115{
			gen d`var'_fail_frac_d = `var'*fail_frac_d
		}
			drop dd6_65_*
	
	
	eststo clear
	qui reghdfe lexpr_f dd6*fail_frac_o  , ///
		absorb(country_o_id country_d_id#year c.lgeo_dist#year) cluster(country_o_id)
		eststo m0
		estadd scalar N_true = e(N) + e(num_singletons)
	
	qui reghdfe lexpr_f dd6*fail_frac_d  , ///
		absorb(country_d_id country_o_id#year c.lgeo_dist#year) cluster(country_o_id )
		eststo m1
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6*fail_frac_o dd6*fail_frac_d , ///
		absorb(country_d_id#country_o_id c.lgeo_dist#year ) cluster(country_o_id)
		eststo m2
		estadd scalar N_true = e(N) + e(num_singletons)
		
	
	estfe . m* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		country_d_id#year "Country\textsubscript{dt} FE" ///
		country_d_id "Country\textsubscript{d} FE" ///
		country_o_id#year "Country\textsubscript{ot} FE" ///
		country_d_id#country_o_id "Country\textsubscript{od}")
		return list	

	esttab m* using "$filepath/output/app_tab_A9.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			wide keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o ///
				dd6_55_fail_frac_d dd6_60_fail_frac_d  ///
				dd6_70_fail_frac_d dd6_75_fail_frac_d dd6_80_fail_frac_d ///
				dd6_85_fail_frac_d dd6_90_fail_frac_d dd6_95_fail_frac_d ///
				dd6_100_fail_frac_d dd6_105_fail_frac_d dd6_110_fail_frac_d ///
				dd6_115_fail_frac_d) ///
			varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855} Fail\textsubscript{o}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860} Fail\textsubscript{o}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870} Fail\textsubscript{o}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875} Fail\textsubscript{o}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880} Fail\textsubscript{o}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885} Fail\textsubscript{o}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890} Fail\textsubscript{o}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895} Fail\textsubscript{o}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900} Fail\textsubscript{o}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905} Fail\textsubscript{o}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910} Fail\textsubscript{o}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914} Fail\textsubscript{o}" ///
				dd6_55_fail_frac_d "$\beta$\textsubscript{1850-1855} Fail\textsubscript{d}" ///
				dd6_60_fail_frac_d "$\beta$\textsubscript{1856-1860} Fail\textsubscript{d}" ///
				dd6_70_fail_frac_d "$\beta$\textsubscript{1866-1870} Fail\textsubscript{d}" ///
				dd6_75_fail_frac_d "$\beta$\textsubscript{1871-1875} Fail\textsubscript{d}" ///
				dd6_80_fail_frac_d "$\beta$\textsubscript{1876-1880} Fail\textsubscript{d}" ///
				dd6_85_fail_frac_d "$\beta$\textsubscript{1881-1885} Fail\textsubscript{d}" ///
				dd6_90_fail_frac_d "$\beta$\textsubscript{1886-1890} Fail\textsubscript{d}" ///
				dd6_95_fail_frac_d "$\beta$\textsubscript{1891-1895} Fail\textsubscript{d}" ///
				dd6_100_fail_frac_d "$\beta$\textsubscript{1896-1900} Fail\textsubscript{d}" ///
				dd6_105_fail_frac_d "$\beta$\textsubscript{1901-1905} Fail\textsubscript{d}" ///
				dd6_110_fail_frac_d "$\beta$\textsubscript{1906-1910} Fail\textsubscript{d}" ///
				dd6_115_fail_frac_d "$\beta$\textsubscript{1911-1914} Fail\textsubscript{d}" ///	
				, elist(dd6_115_fail_frac_d \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes
	
}


	*C2: bank balance by OG connection
{	
	use  "$filepath/data/bank_char_final.dta", clear
		*Panel by OG connection
		global bank_var_js any_shareholder bank_capital_m bank_paidupcap_m bank_deposits_m bank_reserve_m ///
			bank_size_m leverage reserve liquidity
		eststo clear
		qui estpost sum $bank_var_js age if any_shareholder!=.	
			eststo t1
		qui estpost sum $bank_var_js age if any_shareholder==0 
			eststo t2
		qui estpost sum $bank_var_js age if any_shareholder==1 
			eststo t3
		qui estpost ttest $bank_var_js age, by(any_shareholder)
			eststo t4
			
			esttab t1 t2 t3 t4 using "$filepath/output/app_tab_og", replace ///
			starlevels(* 0.1 ** 0.05 *** 0.01) ///
			drop(any_shareholder) ///
			varlabels(bank_capital_m "Capital, authorized (\pounds m)" ///
				bank_paidupcap_m "Capital, paid up (\pounds m)" ///
				bank_deposits_m "Deposits (\pounds m)" ///
				bank_reserve_m "Reserve fund (\pounds m)" ///
				bank_size_m "Total size (\pounds m)" ///
				leverage "Leverage ratio" ///
				reserve "Reserve ratio" ///
				liquidity "Liquidity ratio" ///
				age "Age", ///
				elist(any_shareholder \hline)) lines ///
			mtitle("All" "Not Failed" "Failed" "Diff") ///
			cells("mean(pattern(1 1 1 0) fmt(2)) b(pattern(0 0 0 1)) sd(pattern(1 1 1 0) par)  se(pattern(0 0 0 1) par star fmt(2))") ///
			booktabs collabels(none) nonum compress 	
	
}

	*F1: structural gravity
	eststo clear
{
	use "$filepath/data/lr_trade_sg.dta", clear
	
	qui eststo tabF1_1: reghdfe lexpr_ff dd6*fail_frac_o, absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	
			
	qui eststo tabF1_2: reghdfe lexpr_ff dd6*fail_frac_o if lgdp_o!=., absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	

	qui eststo tabF1_3: reghdfe lexpr_ff dd6*fail_frac_o lgdp_o, absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	
						
	qui eststo tabF1_4: reghdfe lexpr_ff dd6*fail_frac_o lgdp_o mr_gdp, absorb(country_o_id country_d_id#year brit_bank#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	

			estfe tabF1_*, labels(year#c.lgeo_dist "Distance" ///
			country_o_id "Country\textsubscript{o} FE" ///
			brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///
			country_d_id#year "Country\textsubscript{dt} FE")
			return list
			esttab tabF1_* using "$filepath/output/app_tab_F1.tex", ///
			  replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
				keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o lgdp_o mr_gdp ) ///
			varlabels(lpop "ln(population)" ltotexp "ln(total exports)" ///
				lgdp_o "$\psi$" mr_gdp "$\phi$" ///
				dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				  booktab nodep nomtitles ///
				stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
				indicate( `r(indicate_fe)', labels(Y )) nonotes
				
	*Magnitudes in a two-period (long) difference
	{
		gen post = (year>1866)
		gen fail_post = fail_frac_o*post
		*Reduced form: 
		qui reghdfe lexpr_ff fail_post, absorb($lr_fe_dt) cluster(country_o_id)
		
		*Structural gravity:
		qui reghdfe lexpr_ff fail_post lgdp_o mr_gdp, absorb(country_o_id country_d_id#year brit_bank#year) cluster(country_o_id)
		
		*Reduced form on same subsample with GDP data
		qui reghdfe lexpr_ff fail_post if lgdp!=., absorb($lr_fe_dt) cluster(country_o_id)
	}	
	
}


	*G1: port-level additional controls
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
		
	*Column 1: baseline w country FE
	qui areg lnships post_fail_lon $port_ot_fe [aw=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
	
	qui reghdfe lnships post_fail_lon $port_ot_fe [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  	
			eststo tabG1_1
			qui sum port_id
			
			estadd local ports "`r(max)'"
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta `rbeta'
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
		
		drop rbeta rdelta
		
	*Column 2: add capital city
	qui areg lnships post_fail_lon post_lon post_capital $port_ot_fe [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_capital [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_2
			qui sum port_id
			estadd local ports "`r(max)'"
			
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta `rbeta'
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta
	
	*Column 3: add frac_uk
	qui areg lnships post_fail_lon $port_ot_fe post_frac_uk [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_frac_uk  [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_3
			qui sum port_id
			estadd local ports "`r(max)'"
		
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta `rbeta'
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta 
	
	*Column 4: add age of banks
	qui areg lnships post_fail_lon $port_ot_fe post_avg_age [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_avg_age [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_4
			qui sum port_id
			estadd local ports "`r(max)'"
			
			sum rbeta
				gen contbeta = "`r(mean)'"
				replace contbeta = substr(contbeta, 1, 5)
				di contbeta
				estadd local beta "-.706"
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta contbeta
		
	
	*Column 5: add OG connection
	qui areg lnships post_fail_lon $port_ot_fe post_avg_og [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_avg_og  [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_5
			qui sum port_id
			estadd local ports "`r(max)'"
			
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta `rbeta'
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta
		
	*Column 6: add non-British banks
	qui areg lnships post_fail_lon $port_ot_fe post_for_bank [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_for_bank [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_6
			qui sum port_id
			estadd local ports "`r(max)'"
			
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta "-.701"
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta
		
	
	*Column 7: add all controls
	qui areg lnships post_fail_lon $port_ot_fe post_capital post_avg_age post_avg_og post_frac_uk post_for_bank [aweight=port_size], ///
			absorb(near_id) cluster(countryoid)  
			psacalc beta post_fail_lon
				gen rbeta = r(beta)	
			psacalc delta post_fail_lon
				gen rdelta = r(delta)
				
	qui reghdfe lnships post_fail_lon $port_ot_fe post_capital post_avg_age post_avg_og post_frac_uk post_for_bank [aweight=port_size], ///
		absorb(near_id) cluster(countryoid)  
			eststo tabG1_7
			qui sum port_id
			estadd local ports "`r(max)'"
		
			sum rbeta
				local contbeta = `r(mean)'
				local rbeta = round(`contbeta', 0.001)
			estadd local beta `rbeta'
			
			sum rdelta
				local contdelta = `r(mean)'
				local rdelta = round(`contdelta', 0.01)
			estadd local delta `rdelta'
			
		drop rbeta rdelta 

	
	esttab tabG1_* using "$filepath/output/app_tab_ports_controls.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon post_capital post_frac_uk post_avg_age post_avg_og) ///
				keep(post_fail_lon) ///
				stats(N ports N_clust beta delta, ///
				label(N "Ports" "Clusters" "$\beta$*" "$\delta$")) ///
				booktab lines ///
				mlabels(, none) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG connection $\times$ post=post_avg_og" ///
						"Non-Brit banks $\times$ post=post_for_bank" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes
		
}

	*G2: port-level regional controls
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
	
	gen og_exposure = avg_og 
	foreach type in og asia africa namer samer austr europe{
		gen post_`type' = `type'_exposure*event
		
		
	qui reghdfe lnships post_fail_lon $port_fe indic_ot post_`type' [aw=port_size], ///
		absorb(near_id countryoid#event) cluster(countryoid)
		
		eststo tabG2_`type'
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
	}
	
		
		esttab tabG2_* using "$filepath/output/app_tab_ports_region.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon) ///
				keep(post_fail_lon) ///
				booktab mlabels(, none) ///
				 lines ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("OG exposure $\times$ post = post_og" ///
						"Asia exposure $\times$ post=post_asia" ///
						"Africa exposure $\times$ post=post_africa" ///
						"N. Amer exposure $\times$ post=post_namer" ///
						"S. Amer exposure $\times$ post=post_samer" ///
						"Australia exposure $\times$ post=post_austr" ///
						"Europe exposure $\times$ post=post_europe" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes	
		
}

	*G3: port-level empire controls
{
	use "$filepath/data/sr_ports_final.dta", clear
	
	foreach type in uk fr sp ott por dut{
		
	gen empire_`type'_post = empire_`type'*event
		
	qui reghdfe lnships post_fail_lon $port_fe [aw=port_size], absorb(near_id empire_`type'_post) cluster(countryoid)
		eststo tabG3_`type'
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	}
		
	
		estfe . tabG3* , labels(near_id "Port\textsubscript{p} FE" ///
				empire_uk_post "British Emp\textsubscript{p} $\times$ post FE" ///
				empire_fr_post "French Emp\textsubscript{p} $\times$ post FE" ///
				empire_sp_post "Spanish Emp\textsubscript{p} $\times$ post FE" ///
				empire_ott_post "Ottoman Emp\textsubscript{p} $\times$ post FE" ///
				empire_por_post "Portuguese Emp\textsubscript{p} $\times$ post FE" ///
				empire_dut_post "Dutch Emp\textsubscript{p} $\times$ post FE")
			return list	
	
	esttab tabG3* using "$filepath/output/app_tab_ports_empires.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				keep(post_fail_lon) ///
				booktab lines ///
				mlabels(, none) ///
				stats(N_true ports Clust, label("N" "Ports" "Clusters" )) ///
				indicate( `r(indicate_fe)', labels(Y )) nonotes

}

	*G4: decomposition
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
	
	gen fail_0 = (shock_location==0)
			replace fail_0 = 0 if london==0
		sum shock_location if event==1 & london==0 & shock_location>0, d
		gen fail_med = `r(p50)'
		gen fail_above_med = (shock_location>=fail_med)
		gen fail_below_med = (shock_location<fail_med)
			replace fail_below_med = 0 if london==0 | shock_location==0

		gen post_fail_0 = event*fail_0
		gen post_above_med = event*fail_above_med
		gen post_below_med = event*fail_below_med
		
	global terciles post_above_med post_below_med post_london indic_p indic_ot
	gen indic = 1
	
	foreach type in indic post_capital post_frac_uk post_avg_age post_avg_og $port_controls{
		
		qui reghdfe lnships $terciles `type' [aw=port_size], absorb(countryoid#event near_id) cluster(countryoid)
			eststo tabG4_`type'
			qui sum port_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	}
	
		esttab tabG4* using "$filepath/output/app_tab_ports_terciles.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_london "No London bank\textsubscript{po} $\times$ post" ///
				post_below_med "Below median Fail\textsubscript{po} $\times$ post" ///
				post_above_med "Above median Fail\textsubscript{po} $\times$ post") ///
				order( post_above_med post_below_med post_fail_lon) ///
				keep( post_above_med post_below_med post_london) ///
				stats(N_true ports Clust  , ///
				label(N "Ports" "Clusters")) ///
				booktab  lines ///
				mlabels(, none) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG connection $\times$ post=post_avg_og" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes
		
}

	*G5: bilateral
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
		sort near_id event
			bysort near_id : gen port_ukcount = _n if lnships_uk!=.
			bysort near_id: gen port_uksum = port_ukcount + port_ukcount[_n-1]
			gsort near_id -event_og
			replace port_uksum = port_uksum[_n-1] if port_uksum==. & port_ukcount==1
		egen port_ukid = group(near_id) if port_uksum==3
		
			sort near_id event
			bysort near_id : gen port_nonukcount = _n if lnships_nonuk!=.
			bysort near_id: gen port_nonuksum = port_nonukcount + port_nonukcount[_n-1]
			gsort near_id -event_og
			replace port_nonuksum = port_nonuksum[_n-1] if port_nonuksum==. & port_nonukcount==1
		egen port_nonukid = group(near_id) if port_nonuksum==3
	
	qui reghdfe lnships_uk post_fail_lon $port_ot_fe  [aw=port_size] if port_uksum==3, ///
		absorb(countryoid#event near_id) cluster(countryoid)
		eststo tabG5_1
		qui sum port_ukid
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
	qui reghdfe lnships_uk post_fail_lon $port_ot_fe $port_controls [aw=port_size] if port_uksum==3, ///
		absorb(countryoid#event near_id) cluster(countryoid)
		eststo tabG5_2
		qui sum port_ukid
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships_nonuk post_fail_lon $port_ot_fe  [aw=port_size] if port_nonuksum==3, ///
		absorb(countryoid#event near_id) cluster(countryoid)
		eststo tabG5_3
		qui sum port_nonukid
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
	qui reghdfe lnships_nonuk post_fail_lon $port_ot_fe $port_controls [aw=port_size] if port_nonuksum==3, ///
		absorb(countryoid#event near_id) cluster(countryoid)	
		eststo tabG5_4
		qui sum port_nonukid
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
	use "$filepath/data/sr_bilateral_final.dta", clear
	
	qui reghdfe lnships_dest post_fail_lon $port_ot_fe indic_dest [aw=port_size], ///
		absorb(countryoid#event near_id dest_id#event) cluster(countryoid)
		eststo tabG5_5
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships_dest post_fail_lon $port_ot_fe lndist_dest indic_dest [aw=port_size], ///
		absorb(countryoid#event near_id dest_id#event) cluster(countryoid)
		eststo tabG5_6
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2

	esttab tabG5_* using "$filepath/output/app_tab_ports_bilat.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon) keep(post_fail_lon) ///
				booktab mlabels(, none) ///
				lines  mgroups ("Ships to UK" "Ships not to UK" "All ships", pattern(1 0 1 0 1 0) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Destination\textsubscript{d} $\times$ post FE=indic_dest" ///
						"ln(distance\textsubscript{od}) = lndist_dest" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						"Port controls $\times$ post= post_capital" ///
						 , labels (Y  )) nonotes		
}

	*G6: excluding cotton countries
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
		egen port_id_all = group(near_id) 
		egen port_id_us = group(near_id) if country_o!="USA"
		egen port_id_br = group(near_id) if country_o!="Brazil"
		egen port_id_eg = group(near_id) if country_o!="Egypt"
		egen port_id_in = group(near_id) if country_o!="India - British Possessions"
				
	foreach type in all us br eg in cotton{
		qui reghdfe lnships post_fail_lon $port_ot_fe $port_controls if port_id_`type'!=. [aw=port_size], ///
			absorb(countryoid#event near_id) cluster(countryoid)
		
			eststo tabG6_`type'
			qui sum port_id_`type'
			estadd local ports "`r(max)'"
			estadd local N_true = e(N) + e(num_singletons)
			estadd local Clust = e(N_clust) + e(num_singletons)/2
	}	
	
		esttab tabG6_* using "$filepath/output/app_tab_ports_cotton.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon)keep(post_fail_lon) ///
				booktab lines mgroups ("All" "excl USA" "excl Brazil" "excl Egypt" "excl India" "excl all cotton", pattern(1 1 1 1 1 1)) ///
				mlabels(, none) ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG connection $\times$ post=post_avg_og" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes			
		
		
}

	*G7: port-level additional controls (for newslag dates)	
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
	
		egen port_id_lag = group(port_id) if lnships_newslag!=.
		
	foreach type in indic_p post_capital post_frac_uk post_avg_age post_avg_og {
		qui reghdfe lnships_newslag post_fail_lon $port_ot_fe `type' [aweight=port_size], ///
			absorb(near_id countryoid#event) cluster(countryoid)  	
			
			eststo tabG7_`type'
			qui sum port_id_lag
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	}
		qui reghdfe lnships_newslag post_fail_lon $port_ot_fe $port_controls [aweight=port_size], ///
			absorb(near_id countryoid#event) cluster(countryoid)  	
			
			eststo tabG7_6
			qui sum port_id_lag
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
		esttab tabG7_* using "$filepath/output/app_tab_ports_newslag.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				keep(post_fail_lon) ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				booktab lines ///
				mlabels(, none) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG connection $\times$ post=post_avg_og" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes
	
}
		
	*G8: poisson
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
	
	foreach type in indic_p post_capital post_frac_uk post_avg_age post_avg_og {
		qui poisson ships post_fail_lon $port_ot_fe `type' i.near_id [iweight=port_size], ///
			cluster(countryoid)  	
			
			eststo tabG8_`type'
			qui sum port_id
			estadd local ports "`r(max)'"
	}
		qui poisson ships post_fail_lon $port_ot_fe $port_controls i.near_id [iweight=port_size], ///
			cluster(countryoid)  	
			
			eststo tabG8_6
			qui sum port_id
			estadd local ports "`r(max)'"
	
		esttab tabG8_* using "$filepath/output/app_tab_ports_poisson.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				keep(post_fail_lon) ///
				stats(N ports N_clust, ///
				label(N "Ports" "Clusters")) ///
				booktab lines ///
				mlabels(, none) ///
				indicate("Capital city $\times$ post = post_capital" ///
						"Share to UK $\times$ post = post_frac_uk" ///
						"Age of banks $\times$ post=post_avg_age" ///
						"OG connection $\times$ post=post_avg_og" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes eqlabels(" " " ")
	
	
	
	
	
}
	
	*G9: poisson + bilateral
	eststo clear
{
	use "$filepath/data/sr_ports_final.dta", clear
		sort near_id event
			bysort near_id : gen port_ukcount = _n if lnships_uk!=.
			bysort near_id: gen port_uksum = port_ukcount + port_ukcount[_n-1]
			gsort near_id -event_og
			replace port_uksum = port_uksum[_n-1] if port_uksum==. & port_ukcount==1
		egen port_ukid = group(near_id) if port_uksum==3
		
			sort near_id event
			bysort near_id : gen port_nonukcount = _n if lnships_nonuk!=.
			bysort near_id: gen port_nonuksum = port_nonukcount + port_nonukcount[_n-1]
			gsort near_id -event_og
			replace port_nonuksum = port_nonuksum[_n-1] if port_nonuksum==. & port_nonukcount==1
		egen port_nonukid = group(near_id) if port_nonuksum==3
	
	qui poisson ships_uk post_fail_lon $port_ot_fe i.near_id [iw=port_size] if port_uksum==3, ///
		cluster(countryoid)
		eststo tabG9_1
		qui sum port_ukid
		estadd local ports "`r(max)'"
	
	qui poisson ships_uk post_fail_lon $port_ot_fe $port_controls i.near_id [iw=port_size] if port_uksum==3, ///
		cluster(countryoid)
		eststo tabG9_2
		qui sum port_ukid
		estadd local ports "`r(max)'"
		
	qui poisson ships_uk post_fail_lon $port_ot_fe i.near_id [iw=port_size] if port_nonuksum==3, ///
		cluster(countryoid)
		eststo tabG9_3
		qui sum port_nonukid
		estadd local ports "`r(max)'"
	
	qui poisson ships_uk post_fail_lon $port_ot_fe $port_controls i.near_id [iw=port_size] if port_nonuksum==3, ///
		cluster(countryoid)
		eststo tabG9_4
		qui sum port_nonukid
		estadd local ports "`r(max)'"
	
	use "$filepath/data/sr_bilateral_final.dta", clear
	
	qui poisson ships_dest post_fail_lon $port_ot_fe $port_dest i.near_id [iw=port_size], ///
		cluster(countryoid)
		eststo tabG9_5
		qui sum port_id
		estadd local ports "`r(max)'"
		
	qui poisson ships_dest post_fail_lon $port_ot_fe $port_dest lndist_dest i.near_id [iw=port_size], ///
		cluster(countryoid)
		eststo tabG9_6
		qui sum port_id
		estadd local ports "`r(max)'"

	esttab tabG9_* using "$filepath/output/app_tab_ports_bilat_poisson.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				order(post_fail_lon) keep(post_fail_lon) ///
				booktab mlabels(, none) ///
				lines  mgroups ("Ships to UK" "Ships not to UK" "All ships", pattern(1 0 1 0 1 0) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				stats(N ports N_clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Destination\textsubscript{d} $\times$ post FE=indic_dest" ///
						"ln(distance\textsubscript{od}) = lndist_dest" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						"Port controls $\times$ post= post_capital" ///
						 , labels (Y  )) nonotes eqlabels(" " " ")
}

	*G10: bilateral busier routes
	eststo clear
{
	use "$filepath/data/sr_bilateral_final.dta", clear
	sum ships_dest if event==0, d
			gen p10 = 1 if ships_dest> `r(p10)'  & event==0
			gen p25 = 1 if ships_dest> `r(p25)' & event==0
			
		sort port_id dest_id event	
		foreach var of varlist p10 p25{
			bysort port_id dest_id: replace `var' = `var'[_n-1] if missing(`var')
			egen `var'_id = group(near_id) if `var'==1
			}
	
	qui reghdfe lnships_dest post_fail_lon $port_ot_fe $port_dest [aw=port_size], ///
		absorb(near_id) cluster(countryoid)
		eststo tabG10_1
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships_dest post_fail_lon $port_ot_fe $port_dest [aw=port_size] if p10==1, ///
		absorb(near_id) cluster(countryoid)
		eststo tabG10_2
		qui sum p10_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships_dest post_fail_lon $port_ot_fe $port_dest [aw=port_size] if p25==1, ///
		absorb(near_id) cluster(countryoid)	
		eststo tabG10_3
		qui sum p25_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	*port-level aggregation
		foreach var of varlist p10 p25{
			bysort near_id event `var': egen ships_`var' = total(ships_dest)
			replace ships_`var' = . if `var'==.
		}
	
		collapse(firstnm) ships_p10 ships_p25 ///
			, by(near_id port_id p10_id p25_id countryoid event post_fail_lon ///
			post_lon indic_ot indic_p port_size)
			
			qui foreach var of varlist ships_p10 ships_p25{
				gen ln`var' = ln(`var')
			}
			
			*Duplicates in the data due to the collapse
			bysort p10_id event: gen p10_tab = _n
	
		qui reghdfe lnships_p10 post_fail_lon $port_ot_fe [aw=port_size] if p10_id!=. & p10_tab==1, ///
			absorb(near_id) cluster(countryoid)
			eststo tabG10_4
			sum p10_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
		qui reghdfe lnships_p25 post_fail_lon $port_ot_fe [aw=port_size] if p25_id!=., ///
			absorb(near_id) cluster(countryoid)
			eststo tabG10_5
			sum p25_id
			estadd local ports "`r(max)'"
			estadd scalar N_true = e(N) + e(num_singletons)
			estadd scalar Clust = e(N_clust) + e(num_singletons)/2
			
			
		esttab tabG10_1 tabG10_2 tabG10_4 tabG10_3 tabG10_5 using "$filepath/output/app_tab_ports_shippingroutes.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				keep(post_fail_lon) ///
				booktab mlabels(, none) ///
				lines  mgroups ("All routes" "Top 90\% routes" "Top 75\% routes", pattern(1 1 0 1 0) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				stats(N ports N_clust, ///
				label(N "Ports" "Clusters")) ///
				indicate("Destination\textsubscript{d} $\times$ post FE=indic_dest" ///
						"Country\textsubscript{o} $\times$ post FE=indic_ot" ///
						"Port\textsubscript{p} FE = indic_p" ///
						 , labels (Y  )) nonotes		
}
		
	*G11: islands & entrepots
	eststo clear
{
	version 16
	use "$filepath/data/sr_ports_final.dta", clear
		egen port_id_island = group(near_id) if island!=1
		egen port_id_entrepot = group(near_id) if entrepot!=1
	
	qui reghdfe lnships post_fail_lon $port_ot_fe $port_controls [aw=port_size], ///
		absorb(near_id) cluster(countryoid)
		eststo tabG11_1
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships post_fail_lon $port_fe $port_controls [aw=port_size], ///
		absorb(near_id) cluster(countryoid)
		eststo tabG11_2
		qui sum port_id
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships post_fail_lon $port_ot_fe $port_controls [aw=port_size] if island!=1, ///
		absorb(near_id) cluster(countryoid)
		eststo tabG11_3
		qui sum port_id_island
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
	qui reghdfe lnships post_fail_lon $port_fe $port_controls [aw=port_size] if island!=1, ///
		absorb(near_id) cluster(countryoid)	
		eststo tabG11_4
		qui sum port_id_island
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	qui reghdfe lnships post_fail_lon $port_ot_fe $port_controls [aw=port_size] if entrepot!=1, ///
		absorb(near_id) cluster(countryoid)
		eststo tabG11_5
		qui sum port_id_entrepot
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
	
	qui reghdfe lnships post_fail_lon $port_fe $port_controls [aw=port_size] if entrepot!=1, ///
		absorb(near_id) cluster(countryoid)	
		eststo tabG11_6
		qui sum port_id_entrepot
		estadd local ports "`r(max)'"
		estadd scalar N_true = e(N) + e(num_singletons)
		estadd scalar Clust = e(N_clust) + e(num_singletons)/2
		
	
	
	esttab tabG11_* using "$filepath/output/app_tab_ports_islands_entrepots.tex", ///
		replace se starlevels(* 0.1 ** 0.05 *** 0.01) star bracket ///
		varlabels(post_fail_lon "Fail\textsubscript{po} $\times$ post") ///
				keep(post_fail_lon) ///
				stats(N_true ports Clust, ///
				label(N "Ports" "Clusters")) ///
				booktab mgroups ("All" "No islands" "No entrepots" , pattern(1 0 1 0 1 0) ///
				prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) lines ///
				mlabels(, none) ///
				indicate("Capital city $\times$ post = post_capital" ///
				"Share to UK $\times$ post = post_frac_uk" ///
				"Age of banks $\times$ post=post_avg_age" ///
				"OG connection $\times$ post=post_avg_og" ///
				"Port\textsubscript{p} FE = indic_p" ///
				"Country\textsubscript{o} $\times$ post FE = indic_ot" ///
						 , labels (Y  )) nonotes 
	
}
		
***Long-term robustness***
	
	*G12: long-term	
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	qui merge m:1 country_o year using "$filepath/data/lr_gdp.dta"
		drop _merge
	
	*Create variables
	qui foreach var of varlist *_val{
			gen ln`var' = ln(`var')
			replace ln`var' = 0 if missing(ln`var')
		}
	
	gen cons_cotton = 1
	gen cons_cotton_manu = 1
	gen cons_pop = 1
	
	replace sitc_ind65=999 if missing(sitc_ind65)
	gen lpop = ln(pop_o)
	gen lpop_65 = lpop if year==1865
		sort country_o year
		bysort country_o: replace lpop_65 = lpop_65[_n-1] if missing(lpop_65)
		gsort country_o -year
		bysort country_o: replace lpop_65 = lpop_65[_n-1] if missing(lpop_65)
		
		
		qui foreach type in 55 60 70 75 80 85 90 95 100 105 110 115 {
			gen dd6_`type'_lpop_65 = d6_`type'*lpop_65
			foreach commod in cotton grains bullion cotton_manu sugar coffee alcohol tobacco{
					gen dd6_`type'_`commod' = ln`commod'_val*d6_`type'
				}
		}

	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_d) cluster(country_o_id) 
		eststo tabG12_1
		estadd scalar N_true = e(N) + e(num_singletons)
	
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt) cluster(country_o_id) 
		eststo tabG12_2
		estadd scalar N_true = e(N) + e(num_singletons)

			
	qui reghdfe lexpr_f dd6_*fail_frac_o dd*cotton, ///
			absorb($lr_fe_dt cons_cotton) cluster(country_o_id) 
		eststo tabG12_3
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6_*fail_frac_o dd*cotton_manu, ///
			absorb($lr_fe_dt cons_cotton_manu) cluster(country_o_id) 
		eststo tabG12_4
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6_*fail_frac_o dd*lpop_65, ///
			absorb($lr_fe_dt cons_pop) cluster(country_o_id) 
		eststo tabG12_5
		estadd scalar N_true = e(N) + e(num_singletons)
		
	*SITC codes
	qui reghdfe lexpr_f dd*fail_frac_o if sitc_ind!=999, ///
		absorb($lr_fe_dt sitc_ind#year) cluster(country_o_id)
		eststo tabG12_6
		estadd scalar N_true = e(N) + e(num_singletons)	
		
	*Regio ID
	qui reghdfe lexpr_f dd*fail_frac_o if sitc_ind!=999, ///
		absorb($lr_fe_dt regio_o_id#year) cluster(country_o_id)
		eststo tabG12_7
		estadd scalar N_true = e(N) + e(num_singletons)
		
	*Regio ID, full
	qui reghdfe lexpr_f dd*fail_frac_o, ///
		absorb($lr_fe_dt regio_o_id#year) cluster(country_o_id)
		eststo tabG12_8
		estadd scalar N_true = e(N) + e(num_singletons)
		
	estfe . tabG12_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		cons_cotton "ln(cotton\textsubscript{o}) $\times$ t" ///
		cons_cotton_manu "ln(cotton manu\textsubscript{o}) $\times$ t" ///
		cons_pop "ln(population\textsubscript{o}) $\times$ t" ///
		sitc_ind65#year "SITC industry\textsubscript{o} $\times$ t" ///
		regio_o_id#year "Region\textsubscript{o} $\times$ t" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id "Country\textsubscript{d}" ///
		country_d_id#year "Country\textsubscript{dt}")
		return list	
	
	
	version $system: esttab tabG12_* using "$filepath/output/app_tab_G12.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o  ) ///
			varlabels(lpop "ln(population)" ltotexp "ln(total exports)" ///
				dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes
			
}
	
	*G13: commonality
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui reghdfe lexpr_f dd6_*fail_frac_o Comlang, ///
			absorb($lr_fe_dt) cluster(country_o_id) 
		eststo tabG13_1
		estadd scalar N_true = e(N) + e(num_singletons)
			
	qui reghdfe lexpr_f dd6_*fail_frac_o Contig, ///
			absorb($lr_fe_dt) cluster(country_o_id) 
		eststo tabG13_2
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6_*fail_frac_o Evercol, ///
			absorb($lr_fe_dt) cluster(country_o_id) 
		eststo tabG13_3
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt Comlang#year) cluster(country_o_id) 
		eststo tabG13_4
		estadd scalar N_true = e(N) + e(num_singletons)
			
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt Contig#year) cluster(country_o_id) 
		eststo tabG13_5
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt Evercol#year) cluster(country_o_id) 
		eststo tabG13_6
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_ff dd*fail_frac_o, ///
		absorb($lr_fe country_o_id#country_d_id) cluster(country_o_id)
		eststo tabG13_7
		estadd scalar N_true = e(N) + e(num_singletons)
	
		
	estfe . tabG13_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		Comlang#year "Common language $\times$ t" ///
		Contig#year "Common border $\times$ t" ///
		Evercol#year "Common empire $\times$ t" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id#year "Country\textsubscript{dt}" ///
		country_o_id#country_d_id "Country\textsubscript{od}")
		return list	

	esttab tabG13_* using "$filepath/output/app_tab_G13.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o Comlang Contig Evercol) ///
			varlabels(Comlang "Common language" Contig "Common border" Evercol "Common empire" ///
				dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(Evercol)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
	
}
		
	*G14: monetary standard & conflict 	
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	qui merge m:1 country_o year using "$filepath/data/cow_war_intrastate.dta"
		drop if _merge==2
		drop _merge
		
		sort country_o  year country_d
		
		by country_o: replace endyear1 = endyear1[_n-1] if intrastate_war[_n-1]==1 
		by country_o: replace endyear1 = endyear1[_n-1] if missing(endyear1)
		replace endyear1 = 0 if missing(endyear1)
		by country_o: replace intrastate_war = 1 if intrastate_war[_n-1]==1 & year<=endyear1
		replace intrastate_war = 0 if missing(intrastate_war)
		
	egen any_war = rowmax(intrastate_war war)
	
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt gold#year) cluster(country_o_id) 
		eststo tabG14_1
		estadd scalar N_true = e(N) + e(num_singletons)	
		
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt silver#year) cluster(country_o_id) 
		eststo tabG14_2
		estadd scalar N_true = e(N) + e(num_singletons)	
		
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt conflict_any#year) cluster(country_o_id) 
		eststo tabG14_3
		estadd scalar N_true = e(N) + e(num_singletons)		
			
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt conflict_inter#year) cluster(country_o_id) 
		eststo tabG14_4
		estadd scalar N_true = e(N) + e(num_singletons)	
			
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt conflict_extra#year) cluster(country_o_id) 
		eststo tabG14_5
		estadd scalar N_true = e(N) + e(num_singletons)	
	
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt any_war) cluster(country_o_id) 
		eststo tabG14_6
		estadd scalar N_true = e(N) + e(num_singletons)	
		
	qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt dyadic_war) cluster(country_o_id) 
		eststo tabG14_7
		estadd scalar N_true = e(N) + e(num_singletons)	
	
	estfe . tabG14_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		gold#year "Gold standard\textsubscript{o} $\times$ t" ///
		silver#year "Silver standard\textsubscript{o} $\times$ t" ///
		conflict_any#year "Conflict (any)\textsubscript{o} $\times$ t" ///
		conflict_inter#year "Conflict (interstate)\textsubscript{o} $\times$ t" ///
		conflict_extra#year "Conflict (other)\textsubscript{o} $\times$ t" ///
		any_war "Country\textsubscript{ot} war" ///
		dyadic_war "Country-pair\textsubscript{odt} war" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id#year "Country\textsubscript{dt}")
		return list	

	esttab tabG14_* using "$filepath/output/app_tab_G14.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o) ///
			varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
}	
		
	*G15: industry composition of exports
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
	
	qui foreach type in 55 60 70 75 80 85 90 95 100 105 110 115 {
			gen dd6_`type'_frac_uk = d6_`type'*frac_uk
			gen dd6_`type'_primprod66 = d6_`type'*prim_prod66
		foreach commod in cotton grains bullion cotton_manu sugar coffee alcohol tobacco{
					gen dd6_`type'_`commod' = ln(`commod'_val)*d6_`type'
					replace dd6_`type'_`commod' = 0 if missing(dd6_`type'_`commod')
				}
		}
				
		foreach type in grains bullion alcohol tobacco primprod66 frac_uk{
			gen cons_`type' = 1
			
		qui reghdfe lexpr_f dd6_*fail_frac_o dd*`type', ///
			absorb($lr_fe_dt cons_`type') cluster(country_o_id)
			
		eststo tabG15_`type'
		estadd scalar N_true = e(N) + e(num_singletons)	
		}
		
		estfe . tabG15_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		cons_grains "ln(grains\textsubscript{o}) $\times$ t" ///
		cons_bullion "ln(bullion\textsubscript{o}) $\times$ t" ///
		cons_alcohol "ln(alcohol\textsubscript{o}) $\times$ t" ///
		cons_tobacco "ln(tobacco\textsubscript{o}) $\times$ t" ///
		cons_primprod66 "Commodities share\textsubscript{o} $\times$ t" ///
		cons_frac_uk "Export share to UK\textsubscript{o} $\times$ t" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id#year "Country\textsubscript{dt}")
		return list	

		esttab tabG15_* using "$filepath/output/app_tab_G15.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o) ///
			varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
	
	
}

	*G16: additional balance
{
	*See code for Table III
}


		
	*G17: SITC industries
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	
	foreach type in 32 67 69 71 64{
		replace sitc_`type'_val = 0 if missing(sitc_`type'_val)
		
		qui reghdfe lexpr_f dd6_*fail_frac_o, ///
			absorb($lr_fe_dt c.sitc_`type'_val#year) cluster(country_o_id) 
		eststo tabG17_`type'
		estadd scalar N_true = e(N) + e(num_singletons)	
		
	}
		
	estfe . tabG17_* , labels(year#c.lgeo_dist "Controls" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///
		country_o_id "Country\textsubscript{o} FE" ///	
		country_d_id#year "Country\textsubscript{dt}" ///
		year#c.sitc_32_val "Coal (32)\textsubscript{o} $\times$ t" ///
		year#c.sitc_67_val "Iron (67)\textsubscript{o} $\times$ t" ///
		year#c.sitc_69_val "Metal manu (69)\textsubscript{o} $\times$ t" ///
		year#c.sitc_71_val "Machinery (71)\textsubscript{o} $\times$ t" ///
		year#c.sitc_64_val "Paper (64)\textsubscript{o} $\times$ t")
		return list	

	esttab tabG17_* using "$filepath/output/app_tab_G17.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o ) ///
				varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
	
}
	
	*G18: Cotton exporters
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
		replace country_o = "India" if country_o=="India - British Possessions"
		
		foreach type in USA Brazil Egypt India{
			gen cons_`type' = 1
		
		qui reghdfe lexpr_f dd6_*fail_frac_o if country_o!="`type'", ///
			absorb($lr_fe_d cons_`type') cluster(country_o_id)
			
		eststo tabG18_`type'
		estadd scalar N_true = e(N) + e(num_singletons)	
		
		qui reghdfe lexpr_f dd6_*fail_frac_o if country_o!="`type'", ///
			absorb($lr_fe_dt cons_`type') cluster(country_o_id)
			
		eststo tabG18_`type'2
		estadd scalar N_true = e(N) + e(num_singletons)	
		}
		
		
		estfe . tabG18_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		cons_USA "excluding USA" ///
		cons_Brazil "excluding Brazil" ///
		cons_Egypt "excluding Egypt" ///
		cons_India "excluding India" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id "Country\textsubscript{d}" ///
		country_d_id#year "Country\textsubscript{dt}")
		return list	

		esttab tabG18_* using "$filepath/output/app_tab_G18.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o  ) ///
			varlabels(lpop "ln(population)" ltotexp "ln(total exports)" ///
				dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes		
	
}
		
	*G19 & G20: financial crises
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	
	foreach cri in cur_cri infl_cri stock_cri sovdebtdom_cri sovdebtext_cri sovdebt_cri bank_cri any_cri{
		
			qui reghdfe lexpr_f dd6_*fail_frac_o, ///
				absorb($lr_fe_dt `cri') cluster(country_o_id)
				
			eststo tabG19_`cri'
			estadd scalar N_true = e(N) + e(num_singletons)	
	
		}
	estfe . tabG19_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		cur_cri "Currency crisis\textsubscript{ot}" ///
		infl_cri "Inflation crisis\textsubscript{ot}" ///
		stock_cri "Stock mkt crisis\textsubscript{ot}" ///
		sovdebtdom_cri "Sovereign debt (domestic)\textsubscript{ot}" ///
		sovdebtext_cri "Sovereign debt (external)\textsubscript{ot}" ///
		sovdebt_cri "Sovereign debt (any)\textsubscript{ot}" ///
		bank_cri "Banking crisis\textsubscript{ot}" ///
		any_cri "Any crisis\textsubscript{ot}" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id#year "Country\textsubscript{dt}")
		return list	

		esttab tabG19_* using "$filepath/output/app_tab_G19.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o  ) ///
			varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes			
			
	
	
	foreach cri in infl_cri stock_cri sovdebt_cri bank_cri any_cri{
			qui reghdfe lexpr_f dd6_*fail_frac_o, ///
				absorb($lr_fe_dt `cri'65#year) cluster(country_o_id)
				
			eststo tabG20_`cri'
			estadd scalar N_true = e(N) + e(num_singletons)	
		
	}
	
		estfe . tabG20_* , labels(year#c.lgeo_dist "Controls" ///
		country_o_id "Country\textsubscript{o} FE" ///
		infl_cri65#year "Inflation crisis\textsubscript{o} $\times$ t" ///
		stock_cri65#year "Stock mkt crisis\textsubscript{o} $\times$ t" ///
		sovdebt_cri65#year "Sovereign debt crisis\textsubscript{o} $\times$ t" ///
		bank_cri65#year "Banking crisis\textsubscript{o} $\times$ t" ///
		any_cri65#year "Any crisis\textsubscript{o} $\times$ t" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id#year "Country\textsubscript{dt}")
		return list	

		esttab tabG20_* using "$filepath/output/app_tab_G20.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o  ) ///
			varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes	
	
	
}
		
	*G21: Suez
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge 1:1 country_o country_d year using "$filepath/data/suez_dist.dta"
		drop _merge
		
	
	qui reghdfe lexpr_ff dd6*fail_frac_o , absorb($lr_fe_dt) cluster(country_o_id)
		eststo tabG21_1
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_ff dd6*fail_frac_o , absorb($lr_fe_dt c.lgeo_dist_suez_sail#year) cluster(country_o_id)
		eststo tabG21_2
		estadd scalar N_true = e(N) + e(num_singletons)
		
	qui reghdfe lexpr_ff dd6*fail_frac_o , absorb($lr_fe_dt c.lgeo_dist_suez_steam#year) cluster(country_o_id)
		eststo tabG21_3
		estadd scalar N_true = e(N) + e(num_singletons)
		
			{
		estfe . tabG21_* , labels(year#c.lgeo_dist "Geodesic dist" ///
		year#c.lgeo_dist_suez_sail "Suez: sailing dist" ///
		year#c.lgeo_dist_suez_steam "Suez: steam dist" ///
		country_o_id "Country\textsubscript{o} FE" ///
		regio_o_id#year "Region\textsubscript{o} $\times$ t" ///
		brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
		country_d_id "Country\textsubscript{d}" ///
		country_d_id#year "Country\textsubscript{dt}")
		return list	
	
	
	version $system: esttab tabG21_* using "$filepath/output/app_tab_G21.tex", ///
		replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
			keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
				dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
				dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
				dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
				dd6_115_fail_frac_o  ) ///
			varlabels( lgdp_o "ln(GDP)" lpop "ln(population)" ltotexp "ln(total exports)" ///
				dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
				dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
				dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
				dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
				dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
				dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
				dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
				dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
				dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
				dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
				dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
				dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
				, elist(dd6_b115fail_frac_o \hline)) lines ///
				booktab nodep nomtitles ///
				mgroups ("No Suez effect" "Suez effect: sailing distance" "Suez effect: steam distance", pattern(1 1 1 )) ///
			stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
			indicate( `r(indicate_fe)', labels(Y )) nonotes
		
		}
	
}
		
		
	*G22: islands & entrepots
	eststo clear
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge 1:1 country_o country_d year using "$filepath/data/island_entrepot.dta"
		drop _merge
		
	
	qui reghdfe lexpr_ff dd6*fail_frac_o , absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_1
			estadd scalar N_true = e(N) + e(num_singletons)
			
		qui reghdfe lexpr_ff dd6*fail_frac_o if island_o!=1, absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_2
			estadd scalar N_true = e(N) + e(num_singletons)
		
		qui reghdfe lexpr_ff dd6*fail_frac_o if island_d!=1, absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_3
			estadd scalar N_true = e(N) + e(num_singletons)
			
		qui reghdfe lexpr_ff dd6*fail_frac_o if entrepot_o!=1, absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_4
			estadd scalar N_true = e(N) + e(num_singletons)
		
		qui reghdfe lexpr_ff dd6*fail_frac_o if entrepot_d!=1, absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_5
			estadd scalar N_true = e(N) + e(num_singletons)	
			
		qui reghdfe lexpr_ff dd6*fail_frac_o if island_o!=1 & island_d!=1 & entrepot_o!=1 & entrepot_d!=1, ///
			absorb($lr_fe_dt) cluster(country_o_id)
			eststo tabG22_6
			estadd scalar N_true = e(N) + e(num_singletons)		
			
	
			estfe . tabG22_* , labels(year#c.lgeo_dist "Controls" ///
			country_o_id "Country\textsubscript{o} FE" ///
			regio_o_id#year "Region\textsubscript{o} $\times$ t" ///
			brit_bank#year "I(Brit bank\textsubscript{o}) $\times$ t" ///	
			country_d_id "Country\textsubscript{d}" ///
			country_d_id#year "Country\textsubscript{dt}")
			return list	

		esttab tabG22_* using "$filepath/output/app_tab_G22.tex", ///
			replace se(a3) starlevels(* 0.1 ** 0.05 *** 0.01) star b(a3) bracket ///
				keep(dd6_55_fail_frac_o dd6_60_fail_frac_o  ///
					dd6_70_fail_frac_o dd6_75_fail_frac_o dd6_80_fail_frac_o ///
					dd6_85_fail_frac_o dd6_90_fail_frac_o dd6_95_fail_frac_o ///
					dd6_100_fail_frac_o dd6_105_fail_frac_o dd6_110_fail_frac_o ///
					dd6_115_fail_frac_o  ) ///
				varlabels(dd6_55_fail_frac_o "$\beta$\textsubscript{1850-1855}" ///
					dd6_60_fail_frac_o "$\beta$\textsubscript{1856-1860}" ///
					dd6_70_fail_frac_o "$\beta$\textsubscript{1866-1870}" ///
					dd6_75_fail_frac_o "$\beta$\textsubscript{1871-1875}" ///
					dd6_80_fail_frac_o "$\beta$\textsubscript{1876-1880}" ///
					dd6_85_fail_frac_o "$\beta$\textsubscript{1881-1885}" ///
					dd6_90_fail_frac_o "$\beta$\textsubscript{1886-1890}" ///
					dd6_95_fail_frac_o "$\beta$\textsubscript{1891-1895}" ///
					dd6_100_fail_frac_o "$\beta$\textsubscript{1896-1900}" ///
					dd6_105_fail_frac_o "$\beta$\textsubscript{1901-1905}" ///
					dd6_110_fail_frac_o "$\beta$\textsubscript{1906-1910}" ///
					dd6_115_fail_frac_o "$\beta$\textsubscript{1911-1914}" ///
					, elist(dd6_b115fail_frac_o \hline)) lines ///
					booktab nodep nomtitles ///
					mgroups ("All" "No Island$\textsubscript{o}$" "No Island$\textsubscript{d}$" ///
					"No Entrepot$\textsubscript{o}$" "No Entrepot$\textsubscript{d}$" "Exclude all", pattern(1 1 1 1 1 1)) ///
				stats(N_true N_clust r2_a, label("N" "Clusters" "Adj. R{$^2$}")) ///
				indicate( `r(indicate_fe)', labels(Y )) nonotes
	
}
		
		

	
	
	
		
		
		
		
		

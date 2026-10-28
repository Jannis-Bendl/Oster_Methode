*This file produces the final data used in Xu "Reshaping Global Trade" (QJE)



* =================================================================
* LONG-RUN DATA
* =================================================================	
	
	*Create bilateral trade panel
{	
	use "$filepath/data/lr_trade.dta", clear
		qui merge m:1 country_o using "$filepath/data/shock_country.dta"
		gen brit_bank = (_merge==3)
		replace shock_country = 0 if _merge==1
		replace bank_num = 0 if _merge==1
		drop if _merge==2
		drop _merge
		
	rename shock_country fail_frac_o
	
	*Create variables
	gen lexpr_ff = ln(expr_f)
	gen lgeo_dist = ln(geo_dist)
	
	egen country_o_id=group(country_o)
	egen country_d_id=group(country_d)
	egen regio_o_id = group(REGIO_o)
	
		forvalues x = 1850/1914{
			gen fail_frac_`x' = (`x'==year)*fail_frac_o
		}
		drop fail_frac_1866
		
		*Year-group dummies
		gen d6_55=(year<=1855)
		gen d6_60=(year>1855 & year<=1860)
		gen d6_65=(year<=1865 & year>1860)
		gen d6_70=(year<=1870 & year>1865)
		gen d6_75=(year<=1875 & year>1870)
		gen d6_80=(year<=1880 & year>1875)
		gen d6_85=(year<=1885 & year>1880)
		gen d6_90=(year<=1890 & year>1885)
		gen d6_95=(year<=1895 & year>1890)
		gen d6_100=(year<=1900 & year>1895)
		gen d6_105=(year<=1905 & year>1900)
		gen d6_110=(year<=1910 & year>1905)
		gen d6_115=(year<=1915 & year>1910)
		
		***Treatment variables
		foreach var of varlist d6_55-d6_115{
			gen d`var'_fail_frac_o = `var'*fail_frac_o
		}
			drop dd6_65_*
			
	bysort country_o year: egen expr_tot = total(expr_f)
	bysort country_o year: gen dest_num = _N
	bysort country_o year: egen avg_dist = mean(geo_dist)
	
		*initial share exports to UK
		gen frac_uk = expr_f/expr_tot if year==1865 & country_d=="United Kingdom"
		sort country_o year
			bysort country_o: replace frac_uk = frac_uk[_n-1] if missing(frac_uk)
		gsort country_o -year
			bysort country_o: replace frac_uk = frac_uk[_n-1] if missing(frac_uk)
			replace frac_uk = 0 if missing(frac_uk)
			
		*foreign bank measure from port-level data
preserve
		use "$filepath/data/sr_ports.dta", clear
		keep if event==0
		keep country_o location for_bank 
		duplicates drop location, force
		collapse (sum) for_bank , by(country_o)
		save "$filepath/data/banks_1865.dta", replace
restore
		qui merge m:1 country_o using "$filepath/data/banks_1865.dta"
		drop if _merge==2
		drop _merge
		replace for_bank = 0 if for_bank==. & country_o!="United Kingdom"
	
	*Dyadic conflict data
	qui merge 1:1 country_o country_d year using "$filepath/data/cow_war_dyadic.dta"
		drop if _merge==2
		drop _merge
		replace dyadic_war = 0 if missing(dyadic_war)
			
	save "$filepath/data/lr_trade_final.dta", replace
}

	*Create country-level characteristics panel
{
	use "$filepath/data/lr_trade_final.dta", clear
		gen expr_uk = expr_f if country_d=="United Kingdom"
		collapse (mean) expr_tot fail_frac_o (firstnm) expr_uk, by(country_o year)
	
		qui merge m:1 country_o using "$filepath/data/country_sitc_ind65"
		replace sitc_ind = 999 if missing(sitc_ind)
		drop _merge
	
		qui merge m:1 country_o using "$filepath/data/primary_products_1865.dta" /*Federico Tena primary products share*/
			drop _merge
			bysort country_o: egen prim_prod66 = mean(prim_prod_avg) if year<=1866
			sort country_o year
			bysort country_o: replace prim_prod66 = prim_prod66[_n-1] if missing(prim_prod66)
		
		qui merge m:1 country_o using "$filepath/data/commodities_all.dta"
			drop _merge
			
		qui merge m:1 country_o using "$filepath/data/currency_standard.dta"
			drop _merge
				
		qui merge m:1 country_o using "$filepath/data/conflict.dta"
			drop _merge
				
		qui merge 1:1 country_o year using "$filepath/data/cow_war_country_o.dta"
			drop if _merge==2
			drop _merge
			
			gen war = (warwin!=.)
			replace warwin = 0 if missing(warwin)
			replace warloss = 0 if missing(warloss)
			gen conflict = warwin + warloss
		
		foreach var of varlist conflict_any conflict_inter conflict_extra{
			replace `var' = 0 if missing(`var')
		}
		
		qui merge 1:1 country_o year using "$filepath/data/RR_1865.dta"
			drop if _merge==2
			drop _merge
			
		
		drop if country_o=="Norway Sweden" | country_o=="Hawaii" | country_o=="Poland"
		
	save "$filepath/data/country_char.dta", replace
}	

	
	*Suez canal bilateral data
{
	use "$filepath/data/pascali_dist.dta", clear 
			
	*Merge with final trade data to expand travel distances to those country pairs
	qui merge 1:1 country_o country_d year using "$filepath/data/lr_trade.dta"
		drop if _merge==1
		drop _merge
		
	*Fill in missing distances
		foreach var of varlist steam_suez_p sail_suez_p steam_nosuez_p sail_nosuez_p{
			gsort country_o country_d -`var'
			bysort country_o country_d: replace `var'= `var'[_n-1] if missing(`var')
		}

	*Create measures of changes from Geodesic distance: pre-Suez is more expensive
	{
		bysort country_o country_d: egen first_year = min(year)
		bysort country_o country_d: egen last_year = max(year)
		/*only countries with first_year<1869 and last_year>1870 will experience a change in trade costs*/
		
		gen suez_change_sail = sail_suez_p/sail_nosuez_p
		gen suez_change_steam = steam_suez_p/steam_nosuez_p
		
		gen lgeo_dist_presuez_sail = ln(geo_dist/suez_change_sail)
		gen lgeo_dist_presuez_steam = ln(geo_dist/suez_change_steam)
	
	}
	
	*Create regression variables
	{
		gen lgeo_dist_p = ln(geo_dist_p)
		gen lgeo_dist = ln(geo_dist)
		
		foreach type in sail steam{
			gen suez_dist_`type' = `type'_nosuez if year<=1869
			replace suez_dist_`type' = `type'_suez if year>1869
			gen lsuez_dist_`type' = ln(suez_dist_`type')
		}
			
		gen lgeo_dist_suez_sail = lgeo_dist_presuez_sail if year<=1869
		replace lgeo_dist_suez_sail = lgeo_dist if year>=1870 | lgeo_dist_presuez_sail==.
		
		gen lgeo_dist_suez_steam = lgeo_dist_presuez_steam if year<=1869
		replace lgeo_dist_suez_steam = lgeo_dist if year>=1870 | lgeo_dist_presuez_sail==.

	}
	
	keeporder year country_o country_d lgeo_dist_suez_sail lgeo_dist_suez_steam
		save "$filepath/data/suez_dist.dta", replace

}


	*Create bilateral trade panel for structural gravity
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	qui merge m:1 country_o year using "$filepath/data/lr_gdp.dta"
		drop _merge
		gen lgdp_o = ln(gdp_o)
		
	
	* Generate variables for estimation
		* Note: theta = 1/N
		levelsof year, local(time)
		gen theta_gdp=.
		gen theta = .
		qui{
		foreach i of local time {
		  distinct country_o if year == `i' & lgdp_o!= .
		  return list
		  replace theta_gdp = 1/`r(ndistinct)' if year ==`i'
		  distinct country_o if year == `i'
		  return list
		  replace theta = 1/`r(ndistinct)' if year ==`i'
		}
		}
		gen var1_gdp = theta_gdp*lgeo_dist
		gen var2_gdp = (theta_gdp^2)*lgeo_dist
		egen temp1_gdp = sum(var1), by (country_o_id year)
		egen temp2_gdp = sum(var1), by (country_d_id year)
		egen temp3_gdp = sum(var2), by (year)
		gen  temp4_gdp =  (temp1+temp2-temp3)
		gen  temp5_gdp = lgeo_dist- temp4
		rename temp5_gdp mr_gdp
		drop temp1* temp2* temp3* var1* var2* temp4*
		
	save "$filepath/data/lr_trade_sg.dta", replace
	
}


* =================================================================
* SHORT-RUN DATA
* =================================================================

	*Country-level in Tables IV - V
	{
			use "$filepath/data/shock_country.dta", clear
			qui merge 1:m country_o using "$filepath/data/sr_country.dta"
				drop if _merge!=3
				drop _merge
				
			gen post_fail_lon_c = event*shock_country*london
			gen post_london = event*london
			gen lnships = ln(ships)
			gen lndest = ln(count_dest)
			gen lnships_dest = ln(ships/count_dest)
			egen countryoid = group(country_o)
			gen indic_o = 1
		
		save "$filepath/data/sr_country_final.dta", replace
		
	}
	
	*Port-level in Tables IV - V
	{
			use "$filepath/data/shock_location.dta", clear
			qui merge 1:m location using "$filepath/data/sr_ports.dta"
				drop if _merge!=3
				drop _merge
				
			gen post_fail_lon = event*shock*london
			gen shock_lon = shock*london
			gen post_lon = event*london
			gen post_for_bank = event*for_bank
			gen post_for_bank_fail = event*shock_location*for_bank
			foreach type in s s_newslag s_uk s_nonuk{
				gen lnship`type' = ln(ship`type')
			}
			egen countryoid = group(country_o)
			egen port_id = group(near_id)
			
			foreach type in london avg_age avg_og capital frac_uk countryoid{
				gen post_`type' = event*`type'
			}
			
			egen port_id_cotton = group(port_id) if country_o!="USA" & country_o!="Brazil" & country_o!="Egypt" & country_o!="India - British Possessions"
			gen indic_p = 1
			gen indic_ot = 1
			
		save "$filepath/data/sr_ports_final.dta", replace
			
	}
	
	*Binary entry/exit in Table V
	{
			use "$filepath/data/shock_location.dta", clear
			qui merge 1:m location using "$filepath/data/sr_extensive.dta"
				drop if _merge!=3
				drop _merge
				
			gen shock_lon = shock*london
			egen port_id_entry = group(near_id) if entry!=. & event==1
			egen port_id_exit = group(near_id) if exit!=. & event==0
			egen countryoid = group(country_o)
			egen port_id = group(near_id)
			gen indic_o = 1
	
		save "$filepath/data/sr_ext_final.dta", replace
	}
	
	*Bilateral in appendix
	{
		use "$filepath/data/shock_location.dta", clear
		qui merge 1:m location using "$filepath/data/sr_bilateral.dta"
			drop if _merge!=3
			drop _merge
		
		gen post_fail_lon = event*shock*london
		gen post_lon = event*london
		gen lnships_dest = ln(ships_dest)
		egen countryoid=group(country_o)
		egen port_id = group(near_id)
		egen dest_id = group(country_dest)
		foreach type in dest p ot{
			gen indic_`type' = 1
		}

		save "$filepath/data/sr_bilateral_final.dta", replace
		
	}
	

	*Port-level balance test in Table III
	{
	
		use "$filepath/data/sr_ports.dta", clear
			keep if event==0
		
		collapse (sum) ships* for_bank port_size (mean) dist_lon  (max) capital count_dest (firstnm) avg_age empire_uk, by(location)
			gen frac_uk = ships_uk/ships
		
		*ssaggregate
			ssaggregate ships* for_ dist_lon  capital frac_uk count_dest avg_age empire_uk [aw=port_size] , ///
			n(bank) s(bank_share_l) l(location) sfilename("$filepath/data/location_exposureshare.dta")
		
		qui merge 1:1 bank using "$filepath/data/bank_char_final.dta"
			drop if _merge==2
			drop _merge
			keeporder bank failure s_n ships* for_ dist_lon capital frac_uk count_dest avg_age empire_uk
			
		save "$filepath/data/port_balance.dta", replace	
		
	}
	
	*Country-level balance test in Table III
	{
		use "$filepath/data/trade_1865.dta", clear
			
		qui merge m:1 country_o year using "$filepath/data/country_char.dta"
			keep if _merge==3
			drop _merge

		qui merge 1:m country_o using "$filepath/data/country_exposureshare.dta"
			drop if _merge==1
			drop _merge
		
		collapse (mean) expr_tot expr_growth expr_uk ///
			(firstnm) gold silver bimetal conflict_any conflict_inter ///
			prim_prod66 cotton_val-sitc_84_val frac_uk, by(country_o)
			
			foreach var of varlist expr_tot-frac_uk{
				qui replace `var'=0 if missing(`var')
			}

		*ssaggregate
			ssaggregate expr_tot expr_g frac_uk ///
			gold silver bimetal conflict_any conflict_inter ///
			prim_prod66 cotton_val-sitc_84_val, ///
			n(bank) s(bank_share_c) l(country_o) sfilename("$filepath/data/country_exposureshare.dta")
			
		qui merge 1:1 bank using "$filepath/data/bank_char_final.dta"
			drop if _merge==2
			drop _merge
		
		order bank failure
		drop bank_lending - any_shareholder
			
		save "$filepath/data/country_balance.dta", replace	
		
	}
	
	
	
	
	









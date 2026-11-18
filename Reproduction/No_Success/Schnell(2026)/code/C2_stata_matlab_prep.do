
cap log close _all
log using log/C2_stata_matlab_prep.log, replace

***********************************************************************
*------------------------- PREP MATLAB DATA --------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

This .do file produces the following files:
     
	For CZONE \in {39400,38300,19400,24300,35001,20901}
	- ${inter}/providers_CZONE.xlsx 
	- ${inter}/providers_CZONE_bin.xlsx 
	- ${inter}/markets_CZONE.xlsx
	
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------ Define Directories -------------------------*
*---------------------------------------------------------------------*

	do C00_stata_setup.do

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*
	
	tempfile main
	
	* Ensure bit-by-bit reproducibility
	set sortseed 1
		
***********************************************************************
*----------------------------- PREP DATA -----------------------------* 
***********************************************************************

*------------ FOR MATLAB: provider and market information ------------*

	*----- Provider-level -----*
	
	use provider_id czone county_fips tot_OP_2014 flag_* using "${inter}/provider_chars_cleaned.dta", clear

	* Keep active GPs with non-missing info
	keep if flag_clean == 1 & flag_GP == 1
	drop flag*
	
	* Make prescriptions monthly
	rename tot_OP_2014 pres
	replace pres = pres/12
	drop if pres == 0 
	
	* Get reimbursement 
	* - Unmatched: those with all cash and state_fips == 47
	merge 1:1 provider_id using "${inter}/R_provider_2014.dta", nogen keep(matched)
	egen R_group = xtile(R), by(czone) nq(3)
		
	* Merge in altruism groupings 
	merge 1:1 provider_id using "${inter}/provider_categorized.dta", nogen keep(master matched) keepusing(bins_q3)
	replace bins_q3 = 4 if bins_q3 == .
	rename bins_q3 beta
	
	save `main', replace
	
	foreach z in 39400 38300 19400 24300 35001 20901 {
		
		use `main', clear
		keep if czone == `z'
		
		* Save full file		
		export excel "${inter}/providers_`z'.xlsx", firstrow(var) replace

		* Save binned file
		gen R_round1 = round(R,0.2)
		gen R_round2 = round(R,1)
		gen R_round = R_round1 if beta != 4
		replace R_round = R_round2 if beta == 4
		bys beta R_round: gen count = 1 
		drop R_round1 R_round2
			
		collapse (mean) pres county_fips czone R (sum) count, by(beta R_round R_group) fast
		drop R_round
		export excel "${inter}/providers_`z'_bin.xlsx", firstrow(var) replace
	}
	
	*------ Market-level ------*
	
	* Number of providers and prescriptions by all providers, GPs
	use provider_id czone county_fips tot_OP_2014 flag* using "${inter}/provider_chars_cleaned.dta", clear
	drop if tot_OP_2014 == 0 

	* Get information for sample construction (beta, R)
	merge 1:1 provider_id using "${inter}/provider_categorized.dta", nogen keep(master matched)
	merge 1:1 provider_id using "${inter}/R_provider_2014.dta", nogen keep(master matched)
	
	gen n_all = 1 
	gen n_GP = flag_clean == 1 & flag_GP == 1 & R != . 
	replace R = 0 if n_GP == 0 
	gen OP_GP = n_GP*tot_OP_2014
	
	gen beta1_GP = bins_q3 == 1 & n_GP == 1
	gen beta2_GP = bins_q3 == 2 & n_GP == 1
	gen beta3_GP = bins_q3 == 3 & n_GP == 1
	gen beta4_GP = bins_q3 == . & n_GP == 1
	
	collapse (sum) n_all n_GP OP_all=tot_OP_2014 OP_GP R beta*, by(czone county_fips) fast 

	* Add US total
	egen OP_US = sum(OP_all)
	tostring county_fips, format(%05.0f) replace
	
	* Pain 
	* - All matched in master
	merge 1:1 county_fips using "${inter}/NHIS_county_year_2014.dta", nogen keep(matched) keepusing(year pop_tot pain_acs_tot)
	rename pop_tot pop
	rename pain_acs_tot pain
	
	* Misuse
	* - All matched in master
	merge 1:1 county_fips year using "${inter}/NSDUH_county_year_1314.dta", nogen keep(matched) keepusing(misuse_acs_perc_sm)
	rename misuse_acs_perc_sm misuse_sm
	replace misuse_sm = misuse_sm/100
	
	* Prices 
	* - 1,185 counties (44.38%) matched
	merge 1:1 county_fips year using "${inter}/StreetRx_county_year_2014.dta", nogen keep(master matched) keepusing(price_mme)
	rename price_mme price
	replace price = price*337.5
	drop year
	
	* Average office visit copayment
	gen state_fips = substr(county_fips,1,2)
	destring state_fips, replace
	merge m:1 state_fips using "${raw_public}/reimbursement/MEPS_state_copay_2014.dta", nogen keep(matched)
	
	* Collapse to czone (adjust weights for missing price info)
	gen weight = pop
	gen price_weight = weight if price != . 
	replace price = price*price_weight
	
	collapse (first) OP_US (rawsum) n_all n_GP OP_all OP_GP pop price price_weight R beta* (mean) pain misuse_sm tau_d=copay [aw=weight], by(czone) fast 
	replace price = price/price_weight
	foreach v in R beta1_GP beta2_GP beta3_GP beta4_GP {
		replace `v' = `v'/n_GP
	}
	drop price_weight 
	save `main', replace
	
	* Average opioid copayment
	use "${inter}/provider_month_copays_0614.dta", clear 
	keep if year == 2014
	gen weight = tot_OP
	collapse (rawsum) tot_OP (mean) avg_copay_OP [aw=weight], by(provider_id) fast 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(master matched) keepusing(czone county_fips)
	collapse (mean) tau_o=avg_copay_OP [aw=tot_OP], by(czone) fast 
	
	merge 1:1 czone using `main', nogen
	save `main', replace
	
	foreach z in 39400 38300 19400 24300 35001 20901 {
		
		use `main', clear
		drop beta* R
		keep if czone == `z'
	
		* Save data for estimation
		export excel "${inter}/markets_`z'.xlsx", firstrow(var) replace
	}

***********************************************************************

log close

		

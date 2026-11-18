
cap log close _all
log using log/C1_stata_analysis.log, replace

***********************************************************************
*------------------------- RUN STATA ANALYSES ------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

This .do file produces the following files: 

    FIGURES
	- Figure 1(a): opioid prescriptions and overdoses over time, 2006-2014
	- Figure 1(b): czone-year overdoses versus prescriptions, 2006-2014
	- Figure 2(a): sources of misused prescription opioids over time, 2006-2014
	- Figure 2(b): detailed sources of misused prescription opioids, 2014
	- Figure 3(a): opioid prescriptions and seizures over time, 2006-2014
	- Figure 3(b): czone-level seizures versus prescriptions, 2014
	- Figure 5(a): OxyContin and total prescriptions over time, 2006-2014
	- Figure 5(b): provider-level changes in OxyContin share following reformulation
	- Figure 6: opioid prescriptions by altruism against seizures, 2014
	
	- Figure A1(a): map of county-level opioid prescriptions per capita, 2014
	- Figure A1(b): raw distribution of prescriptions across physicians, 2014
	- Figure A1(c): conditional distributions of prescriptions across physicians, 2014
	- Figure A2(a,b) left: czone-level misuse (all, SM) versus prescriptions, 2014
	- Figure A2(a,b) middle: county-level misuse (all, SM) versus mortality, 2014
	- Figure A2(a,b) right: czone-level misuse (all, SM) versus seizures, 2014
	- Figure A3(a): map of state-level prices overlaid with quotes, 2014
	- Figure A3(b): state-level prices versus prescriptions, 2014
	- Figure A5(a): average OxyContin copayments over time, 2006-2014
	- Figure A5(b): OxyContin prescriptions by type over time, 2006-2014
	- Figure A6: provider-level changes in OxyContin shares by altruism 
	- Figure A7: percent of providers categorized by cumulative prescriptions, 2006-2014
	- Figure A8(a,b,c,d): baseline patient characteristics by altruism 
	- Figure A9: distance between czone characteristics and US average, 2014
	- Figure A10(a): map of county-level SM misuse, 2014
	- Figure A10(b): county-level SM misuse versus all misuse, 2014
	- Figure A10(c): state-level predicted versus actual misuse, 2013-2014
	- Figure A11(a): map of county-level pain, 2014
	- Figure A11(b): histogram of raw reports of pain, 2014
	- Figure A11(c): region-level predicted versus actual pain, 2014

    TABLES
	- Table 1: providers and prescribing patterns by altruism, 2006-2014
	
	- Table A1: average patient and provider characteristics
	- Table A2: czone-year mortality versus prescriptions, 2006-2014
	- Table A3: sources of misused prescription opioids by user type, 2014
	- Table A4: changes in OxyContin prescription shares by altruism
	- Table A5: patient and local area characteristics by altruism
	- Table A6: provider specialties and characteristics by altruism 
	- Table A7: czone altruism shares versus mortality, 2014
	- Table A8: czone altruism shares versus mortality with delta, 2014
	- Table A9: czone altruism shares versus mortality by component, 2014
	- Table A10: opioid prescriptions by altruism against misuse measures, 2014
	- Table A11: US and local czone characteristics, 2014
	- Table A12: predicting county-level opioid misuse and pain 
     
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------ Define Directories -------------------------*
*---------------------------------------------------------------------*

	do C00_stata_setup.do
	
*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*

	* Main colors (https://www.northwestern.edu/brand/visual-identity/color/)
	local colord = "025 008 065"
	local colorm = "118 093 160"
	local colorl = "204 196 223"
	
	* Extra colors (for maps)
	local colormd = "078 042 132"
	local colorml = "182 172 209"
	local colorvl = "228 224 238"
	
	* Label sizes
	local tsize = 4
	local lsize = 4	
	
	tempfile rx_mort
	tempfile nsduh
	tempfile oxy_chars
	tempfile chars
	tempfile oxy_changes
	tempfile alt_mort
	tempfile polar
	tempfile markets
	
	tempfile temp1
	tempfile temp2
	tempfile temp3
	
	local demo "pop_tot pop_dens perc_male perc_1834 perc_3564 perc_65plus perc_white perc_black perc_hisp"
	local econ "perc_hsg perc_scol perc_cplus med_hh_inc perc_unemp"
	
***********************************************************************
*----------------------------- PREP DATA -----------------------------* 
***********************************************************************

*---------- Opioid prescriptions and mortality (IQVIA,NVSS) ----------*
* Combine data sources 
* Create czone-year per capita measures

use "${inter}/county_month_opioids_0614.dta", clear 

	* Collapse to yearly data
	collapse (sum) tot_OP (mean) pop_tot, by(county_fips year) fast
	save `rx_mort', replace
	
use d_rxopioid d_opioids d_drugs county_fips year using "${inter}/NVSS_county_year_0614.dta", clear

	* All matched in master
	* - 13 counties unmatched in using 
	merge 1:1 county_fips year using `rx_mort', nogen
	foreach v in rxopioid opioids drugs {
		replace d_`v' = 0 if d_`v' == . 
	}
	
	* Collapse to commuting zone
	* - 9 counties unmatched in master
	destring county_fips, replace
	merge m:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	collapse (sum) tot_OP d_rxopioid d_opioids d_drugs pop_tot, by(czone year) fast 
	gen pc_OP = tot_OP/pop_tot
	foreach v in rxopioid opioids drugs {
		gen pc_`v' = d_`v'/(pop_tot/10000)
	}
	
	* Create deciles of opioids per capita 
	xtile q10_pcOP = pc_OP [aw=pop_tot], nq(10)	
	
	save `rx_mort', replace

*--------------------- Sources of misuse (NSDUH) ---------------------*

use "${inter}/NSDUH_clean_0614.dta", clear
	
	* Only keep those who misused prescription opioids
	keep if misuse_yr == 1
	* Source missing for 10.18% of observations (2006-2014)
	drop if source_det == . 
	
	* Reorder detailed sources
	* "Bought from internet" dropped in 2014 (0.17% of observations)
	* Combine other small categories into "Other"
	* - 0.24% "Wrote fake prescription" (3)
	* - 0.46% "Stole from office, clinic, hospital, or pharmacy" (4)
	foreach y in 0614 2014 { 
		gen source_det_`y' = . 
		replace source_det_`y' = 1 if source_det == 1
		replace source_det_`y' = 2 if source_det == 2
		replace source_det_`y' = 3 if source_det == 6
		replace source_det_`y' = 4 if source_det == 8
	}
	replace source_det_0614 = 5 if source_det == 9 
	replace source_det_0614 = 6 if source_det == 5
	replace source_det_0614 = 7 if source_det == 7
	replace source_det_0614 = 8 if source_det == 3 | source_det == 4 | source_det == 10
	replace source_det_2014 = 5 if source_det == 5
	replace source_det_2014 = 6 if source_det == 7
	replace source_det_2014 = 7 if source_det == 3 | source_det == 4 | source_det == 10
	
	save `nsduh', replace

*------------ OxyContin prescriptions and features (IQVIA) -----------*	
	
* Prescriptions
use "${inter}/provider_month_opioids_0614.dta", clear

	gen tot_oxy = tot_oxy_brand + tot_oxy_gen
	collapse (sum) tot_OP tot_oxy tot_oxy_brand tot_oxy_gen, by(date) fast 
	save `oxy_chars', replace

* Copayments
use "${inter}/provider_month_copays_0614.dta", clear
		
	foreach v in OP oxy_brand oxy_gen {
		replace avg_copay_`v' = tot_`v'*avg_copay_`v'
	}
	collapse (sum) tot_OP tot_oxy_* avg_copay_OP avg_copay_oxy_*, by(date) fast 
	foreach v in tot avg_copay {
		gen `v'_oxy = `v'_oxy_brand + `v'_oxy_gen
	}
	foreach v in OP oxy oxy_brand oxy_gen {
		replace avg_copay_`v' = avg_copay_`v'/tot_`v'
		drop tot_`v'
	}
	
	merge 1:1 date using `oxy_chars', nogen 
	save `oxy_chars', replace

*------------ Patient and provider characteristics (IQVIA) -----------*

use provider_id date year perc* using "${inter}/provider_month_patientchars_0614.dta", clear
	
	* Combine age categories 
	gen perc_0019 = perc_0002 + perc_0309 + perc_1019
	gen perc_4064 = perc_4059 + perc_6064
	gen perc_65plus = perc_6574 + perc_7584 + perc_85plus
	drop perc_0002 perc_0309 perc_1019 perc_4059 perc_6064 perc_6574 perc_7584 perc_85plus perc_age_mi perc_sex_mi

	* Opioid prescriptions
	* All matched
	merge 1:1 provider_id date using "${inter}/provider_month_opioids_0614.dta", nogen keepusing(tot_OP)
	
	* Collapse to provider-level data 
	gen weight = tot_OP
	collapse (rawsum) n_OP = tot_OP (mean) perc* [aw=weight], by(provider_id) fast 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) ///
		keepusing(flag* gender rank rank_n region birth_year grad_year) 

	save `chars', replace

*---------- Provider-level responses to refomulation (IQVIA) ---------*	

use "${inter}/provider_month_opioids_0614.dta", clear

	* Construct pre/ post periods
	set type double
	gen period = "" 
	replace period = "100" if date >= 596 & date <= 601
	replace period = "010" if date >= 601 & date <= 606
	replace period = "001" if date >= 608 & date <= 613
	
	drop if period == ""
	
	gen tot_oxy = tot_oxy_brand + tot_oxy_gen
	collapse (sum) tot_OP tot_oxy, by(provider_id period) fast 
	gen perc_oxy = (tot_oxy/tot_OP)*100
	drop tot_oxy tot_OP 
	
	reshape wide perc_oxy, i(provider_id) j(period) string
	
	* Categorize providers	
	gen pp_change1 = perc_oxy001 - perc_oxy010
	gen pp_change2 = perc_oxy001 - perc_oxy100
	
	gen bins_q3 = . 
	replace bins_q3 = 1 if pp_change1 < 0 & pp_change2 < 0 
	replace bins_q3 = 2 if (pp_change1 < 0 & pp_change2 > 0 & pp_change2 != .) | ///
	                       (pp_change1 > 0 & pp_change2 < 0 & pp_change1 != .)
	replace bins_q3 = 3 if pp_change1 > 0 & pp_change2 > 0 & pp_change1 !=. & pp_change2 !=.
	
	replace pp_change1 = . if perc_oxy001 == 0 & perc_oxy010 == 0 
	replace pp_change2 = . if perc_oxy001 == 0 & perc_oxy100 == 0 
	drop if pp_change1 == . & pp_change2 == . 
	
	* Construct percent changes (999999 for infinite increases)
	gen pc_change1 = (pp_change1/perc_oxy010)*100
	replace pc_change1 = 999999 if pp_change1 != . & perc_oxy010 == 0 
	gen pc_change2 = (pp_change2/perc_oxy100)*100
	replace pc_change2 = 999999 if pp_change2 != . & perc_oxy100 == 0 
	
	keep provider_id bins_q3 pc_* pp_*
	save "${inter}/provider_categorized.dta", replace

*------------ Provider characteristics by altruism (IQVIA) -----------*	

use provider_id bins_q3 using "${inter}/provider_categorized.dta", clear 

	drop if bins_q3 == . 

	* Expand to have zeros (2009-2011)
	expand 3 
	bys provider_id: gen year = 2008 + _n 
	expand 12 
	bys provider_id year: gen month = _n 
	gen date = ym(year, month)
	
	*----- PRESCRIPTIONS -----*
	merge 1:1 provider_id date using "${inter}/provider_month_opioids_0614.dta", nogen keep(matched) 
	
	gen tot_oxy = tot_oxy_brand + tot_oxy_gen
	gen perc_oxy = tot_oxy/tot_OP
	gen perc_oxy_gen = tot_oxy_gen/tot_oxy
	drop tot_oxy_brand tot_oxy_gen
	
	*----- PATIENT CHARS -----*
	merge 1:1 provider_id date using "${inter}/provider_month_patientchars_0614.dta", nogen keep(matched)

	* Reformat ages
	gen perc_0019 = perc_0002 + perc_0309 + perc_1019
	gen perc_4064 = perc_4059 + perc_6064
	gen perc_65plus = perc_6574 + perc_7584 + perc_85plus
	drop perc_0002 perc_0309 perc_1019 perc_4059 perc_6064 perc_6574 perc_7584 perc_85plus
	
	*------- CLEAN FLAG ------*
	
	* Providers with missing specialty and provider_id >= 9500000 unmatched
	* - 3,388 providers (1.84%) accounting for 3.70% of opioid prescriptions
	merge m:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) keepusing(flag*)
	
	save `oxy_changes', replace

*----- Local altruism shares, prescribing, mortality (IQVIA,NVSS) ----*	
	
use "${inter}/provider_categorized.dta", clear

	* Get location information 
	* - 6,080 providers (2.45%) with missing specialty and provider_id >= 9500000 unmatched
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) ///
		keepusing(czone county_fips)

	* Drop those with missing czone
	* - 7,965 providers (3.29%) dropped
	drop if czone == .
	tostring county_fips, replace format(%05.0f)
		
	* Collapse to county-level
	gen alt_low_main = bins_q3 == 1 
	gen alt_med_main = bins_q3 == 2
	gen alt_nmi_main = 1 if bins_q3 != . 
	forvalues i = 1/2 {
		gen alt_low_c`i' = pp_change`i' < 0 
		gen alt_nmi_c`i' = 1 if pp_change`i' != . 
	}
	collapse (sum) alt*, by(czone county_fips) fast 

	* Merge in mortality 
	* - All matched in master
	merge 1:m county_fips using "${inter}/NVSS_county_year_0614.dta", nogen keep(matched) ///
		keepusing(pc_drugs pc_rxopioid pc_heroin pop_tot year)
	
	* Merge in opioid prescriptions 
	* - All matched in master 
	merge 1:m county_fips year using "${inter}/county_month_opioids_0614.dta", nogen keep(matched) keepusing(tot_OP)
	collapse (sum) tot_OP (mean) alt_* pc* pop_tot, by(czone county_fips year) fast 
	gen pc_OP = tot_OP/pop_tot
	
	* Merge in county demographics 
	* - All matched in master
	merge m:1 county_fips using "${inter}/ACS_county_demos_1014.dta", nogen keep(matched)
	
	* Assign commuting zones to state with largest population share
	gen state_fips = substr(county_fips,1,2)
	destring state_fips, replace
	
	bys czone year: egen czone_pop = sum(pop_tot)
	bys czone state_fips year: egen pop_share = sum(pop_tot) 
	replace pop_share = pop_share/czone_pop
	bys czone year: egen max = max(pop_share)
	gen statei = state_fips if pop_share == max
	by czone year: egen czone_state = mean(statei)
	drop czone_pop pop_share max statei
	
	* Collapse to czone level 
	gen weight = pop_tot
	collapse (rawsum) alt* pop_tot (mean) pc* pop_dens med_hh_inc perc* [aw=weight], by(czone czone_state year) fast 
	foreach v in low med {
		gen share_`v'_main = alt_`v'_main/alt_nmi_main
	}
	forvalues i = 1/2 {
		gen share_low_c`i' = alt_low_c`i'/alt_nmi_c`i'
	}
	
	save `alt_mort', replace

*--- Prescribing by alt. with local misuse (IQVIA,NSDUH,NVSS,NIBRS) --*	

use provider_id bins_q3 using "${inter}/provider_categorized.dta", clear

	* Only keep low- and high-altruism providers
	drop if bins_q3 == . | bins_q3 == 2
	
	* Get opioid prescriptions and location information 
	* - 2,644 providers (1.88%) with missing specialty and provider_id >= 9500000 unmatched
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", ///
		nogen keep(matched) keepusing(county_fips czone tot_OP_2014 flag*)
	replace tot_OP_2014 = tot_OP_2014/12

	* Drop those with missing czone
	* - 4,411 providers (3.20%) accountings for 2.85% of opioid prescriptions
	drop if czone == .
	tostring county_fips, replace format(%05.0f)
		
	rename bins_q3 alt
	save `temp1', replace

	* Collapse to czone
	foreach v in 1 3 {
		gen n_prov`v' = 1 if alt == `v'
		gen tot_OP`v' = tot_OP_2014 if alt == `v'
	}
	collapse (sum) n_prov1 n_prov3 tot_OP1 tot_OP3, by(czone)
	save `polar', replace 
	
	*----- MISUSE (NSDUH) -----*
	
	use misuse_acs_perc* pop_tot county_fips year using "${inter}/NSDUH_county_year_1314.dta", clear 
	keep if year == 2014 
	rename misuse_acs_perc_all nsduh_all
	rename misuse_acs_perc_sm nsduh_sm
	
	*---- OVERDOSES (NVSS) ----*
	
	* - All 2014 matched in using
	* - NSDUH: 02270 and 46113 unmatched 
	merge 1:1 county_fips year using "${inter}/NVSS_county_year_0614.dta", nogen keep(matched) keepusing(pc_rxopioid)
	rename pc_rxopioid nvss
	
	* Collapse to czone level 
	* - 9 counties in master unmatched
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	gen weight = pop
	collapse (rawsum) pop (mean) nsduh* nvss [aw=weight], by(czone) fast 
	
	* Construct deciles 
	foreach v in nsduh_all nsduh_sm nvss {
		xtile d10_`v' = `v', n(10)
	}
	
	* Merge provider data back in 
	* - All matched in using
	merge 1:m czone using `polar', nogen keep(matched)
	save `polar', replace
	
	*---- SEIZURES (NIBRS) ----*
	
	use `temp1', clear
	
	* Keep providers in counties with NIBRS coverage 
	* - 67,228 providers (50.35%) accounting for 48.93% of prescriptions in master only
	gen year = 2014 
	merge m:1 county_fips year using "${inter}/NIBRS_county_year_0614.dta", nogen keep(matched) keepusing(county_frac)
	
	* Only keep counties with good coverage 
	* - Drops 35,498 providers (53.55%) accounting for 52.48% of prescriptions
	keep if county_frac > 0.95 & county_frac != . 

	* Collapse to czone
	foreach v in 1 3 {
		gen n_prov_nibrs`v' = 1 if alt == `v'
		gen tot_OP_nibrs`v' = tot_OP_2014 if alt == `v'
	}
	collapse (sum) n_prov_nibrs* tot_OP_nibrs*, by(czone)
	save `temp1', replace 

	* Merge in seizures
	use n_rxopioid county_frac county_fips year using "${inter}/NIBRS_county_year_0614.dta", clear 
	keep if year == 2014
	drop if county_frac == . | county_frac == 0 
	rename n_rxopioid nibrs
	
	* Only keep counties with good coverage 
	* - Drops 473 counties (31.45%)
	keep if county_frac > 0.95
	
	* Merge in population 
	* - All matched in master
	merge 1:1 county_fips year using "${inter}/county_year_pop_0614.dta", nogen keep(matched)
	gen pop_nibrs = pop_tot*county_frac 
	replace nibrs = nibrs/(pop_nibrs/1000)
	
	* Collapse to czone level 
	* - One county in master unmatched
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	gen weight = pop_nibrs
	collapse (rawsum) pop_nibrs (mean) nibrs [aw=weight], by(czone) fast 
	
	* Construct deciles 
	xtile d10_nibrs = nibrs, n(10)
	
	* Merge provider data back in 
	* - All matched in using
	merge 1:m czone using `temp1', nogen keep(matched)
	
	* Merge other czones back in 
	* - All matched in master
	merge 1:1 czone using `polar', nogen keep(using matched)
	
	* Reshape long
	reshape long tot_OP tot_OP_nibrs n_prov n_prov_nibrs, i(nibrs nsduh* nvss) j(alt)
	
	* Construct averages
	replace tot_OP = tot_OP/n_prov
	replace tot_OP_nibrs = tot_OP_nibrs/n_prov_nibrs
	
	save `polar', replace

*----------------------- Market-level summaries ----------------------*

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
	save `markets', replace
	
	* Average opioid copayment
	use "${inter}/provider_month_copays_0614.dta", clear 
	keep if year == 2014
	gen weight = tot_OP
	collapse (rawsum) tot_OP (mean) avg_copay_OP [aw=weight], by(provider_id) fast 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(master matched) keepusing(czone county_fips)
	collapse (mean) tau_o=avg_copay_OP [aw=tot_OP], by(czone) fast 
	
	merge 1:1 czone using `markets', nogen
	save `markets', replace
	
***********************************************************************
*------------------------------ FIGURES ------------------------------* 
***********************************************************************

*---------------------------------------------------------------------*
*-------------------------------- MAIN -------------------------------* 
*---------------------------------------------------------------------*

*---------------------------- Figure 1(a) ----------------------------*

use `rx_mort', clear

	* Collapse to national data 
	collapse (sum) tot_OP d_rxopioid d_drugs, by(year) fast 
	gen d_other = d_drugs - d_rxopioid
	
	* Rescale
	replace tot_OP = tot_OP/100000000
	foreach v in rxopioid other {
		replace d_`v' = d_`v'/10000
	}
	replace d_other = d_other/2

	twoway (bar tot_OP year, barw(0.95) lwidth(0) lcolor(white) fcolor("`colorl'")) ///
	       (line d_rxopioid year, yaxis(2) lwidth(0.75) lcolor("`colord'")) ///
	       (line d_other year, yaxis(2) lwidth(0.75) lpattern(dash) lcolor("`colorm'") ///
		xsize(6) xlab(, labsize(`lsize')) xtitle("") ///
		ylab(, labsize(`lsize') axis(1)) ytitle("Opioid prescriptions", size(`tsize') axis(1)) yscale(titlegap(2.5) axis(1)) ///
		ylab(, labsize(`lsize') axis(2)) ytitle("Drug overdoses", size(`tsize') axis(2)) yscale(titlegap(2.5) axis(2)) ///
		legend(order(1 2 3) col(1) lab(1 "Opioid prescriptions (hundred millions)") lab(2 "Prescription opioid overdoses (ten thousands)") ///
		lab(3 "All other drug overdoses (twenty thousands)") size(`lsize') symxsize(6) region(lcolor(white))) graphregion(color(white))) 
	graph export "${results}/Figure_1a.eps", replace
	
*---------------------------- Figure 1(b) ----------------------------*

local m1 "reg pc_rxopioid i.q10_pcOP [aw=pop_tot]"
local m2 "areg pc_rxopioid i.q10_pcOP i.year [aw=pop_tot], absorb(czone)"

forvalues m = 1/2 {
	
	use `rx_mort', clear
	`m`m''
	
	clear 
	mat beta`m' = e(b)'
	svmat beta`m'
	
	* Add back constant
	gen consi = beta`m' if _n == _N
	egen cons = mean(consi)
	drop if _n >= 11
	replace beta`m' = beta`m' + cons
	drop cons*
	gen q10_pcOP = _n
	
	if `m' == 2 {
		merge 1:1 q10_pcOP using `temp1', nogen
	}
	save `temp1', replace
}

	* Merge in average opioids per capita per decile and population
	use `rx_mort', clear
	collapse (mean) pc_OP [aw=pop_tot], by(q10_pcOP) 
	merge 1:1 q10_pcOP using `temp1', nogen 
	save `temp1', replace
	
	* Merge in population for weighting
	use `rx_mort', clear
	collapse (sum) pop_tot, by(q10_pcOP) 
	merge 1:1 q10_pcOP using `temp1', nogen 
	
	twoway (scatter beta1 pc_OP [aw=pop_tot], msize(2) mcolor("`colorl'")) ///
	       (lfit beta1 pc_OP [aw=pop_tot], lwidth(1) lcolor("`colorl'")) ///
	       (scatter beta2 pc_OP [aw=pop_tot], msym(Oh) msize(2) mcolor("`colord'")) ///
	       (lfit beta2 pc_OP [aw=pop_tot], lwidth(1) lcolor("`colord'") ///
	        xlab(0.2(0.4)1.4, labsize(`lsize')) xtitle("Opioid prescriptions per capita", size(`tsize')) xscale(titlegap(2.5)) ///
	        ylab(0.2(0.2)0.8, labsize(`lsize')) ytitle("Prescription opioid overdoses per 10,000", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(order(2 4) lab(2 "Raw data") lab(4 "Year and commuting zone FEs") size(3.5) symxsize(8) region(lcolor(white))) ///
		graphregion(color(white))) 
	graph export "${results}/Figure_1b.eps", replace	

*---------------------------- Figure 2(a) ----------------------------*

use `nsduh', clear
	
	gen n = 1 
	collapse (sum) n misuse_freq [pw=analwt_c], by(year source_cat) fast 
	foreach v in n misuse_freq {
		bys year: egen total = sum(`v')
		replace `v' = `v'/total*100
		drop total
	}

	* Label 2014 with percent of observations
	gen plabel = misuse_freq 
	tostring plabel, replace force format(%2.01f)
	replace plabel = plabel + "%" if year == 2014
	twoway (line misuse_freq year if source_cat == 1, lwidth(0.75) lcolor("`colorm'")) ///
	       (line misuse_freq year if source_cat == 2, lwidth(1.5) lcolor("`colord'")) ///
	       (line misuse_freq year if source_cat == 3, lwidth(0.75) lcolor("`colorl'")) ///
	       (scatter misuse_freq year if year == 2014, mlabel(plabel) mlabpos(3) mlabsize(3.75) msym(none) mlabcolor(black) ///
	        xtitle("") xlab(2006(2)2014.5, labsize(`lsize')) ylab(0(10)55, labsize(`lsize')) ///
		ytitle("Sources of misused prescription opioids (%)", size(`tsize')) yscale(titlegap(2.5))  ///
		legend(order(1 2 3) cols(3) lab(1 "Primary market") lab(2 "Secondary market") lab(3 "Other") ///
		size(`lsize') region(lcolor(white))) graphregion(color(white))) 
	graph export "${results}/Figure_2a.eps", replace 

*---------------------------- Figure 2(b) ----------------------------*

use `nsduh', clear

	keep if year == 2014
	collapse (sum) misuse_freq [pw=analwt_c], by(source_det_2014 source_fr) fast 
	
	egen total = sum(misuse_freq)
	replace misuse_freq = misuse_freq/total*100
	drop total
	bys source_det: egen perc_det = sum(misuse_freq)
		
	* Exclude missings for friend/ relative's source
	bys source_det: egen perc_fr_sub = sum(misuse_freq) if source_fr != .
	replace perc_fr_sub = misuse_freq/perc_fr_sub*100
	gen perc_fr = (perc_fr_sub/100)*perc_det
	drop misuse_freq
		
	* Construct bounds for rbar
	gen rbar1 = 0 if source_fr == 1 | source_fr == 2
	replace rbar1 = rbar1[_n] + perc_fr[_n-1] if source_fr == 2
	gen rbar2 = rbar1 + perc_fr if source_fr == 1 | source_fr == 2
		
	* Label with percent of observations
	gen plabel = perc_det
	tostring plabel, replace force format(%2.01f)
	replace plabel = plabel + "%"	
		
	tostring perc_fr, replace force format(%2.01f)
	replace perc_fr = perc_fr + "%"	
	
	local ytop = perc_det[5] + 3
	gen blank = . 	
	
	* Manually edit graph to move legend
	twoway (bar perc_det source_det if source_det == 1 | source_det == 2, barw(0.75) lwidth(0) lcolor(white) fcolor("`colorm'")) ///
	       (bar perc_det source_det if source_det == 3 | source_det == 4, barw(0.75) lwidth(0) lcolor(white) fcolor("`colord'")) ///
	       (bar perc_det source_det if (source_det == 5 & source_fr == .) | source_det == 6 | source_det == 7, barw(0.75) lwidth(0) lcolor(white) fcolor("`colorl'")) ///
	       (rbar rbar1 rbar2 source_det if source_fr == 1, barw(0.75) lwidth(1) lcolor("`colorm'") fcolor("`colorl'") ///
	        text(25.5 5.35 "{&larr} 28.5%", size(3.75) color(gs6) place(right))) ///
	       (rbar rbar1 rbar2 source_det if source_fr == 2, barw(0.75) lwidth(1) lcolor("`colord'") fcolor("`colorl'") ///
	        text(29.1 5.35 "{&larr} 1.0%", size(3.75) color(gs6) place(right))) ///
	       (scatter perc_det source_det if source_fr == ., mlabel(plabel) mlabpos(12) mlabsize(3.75) msym(none) mlabcolor(black)) ///
	       (bar blank blank, lwidth (1) lcolor(gs8) fcolor(white) xtitle("") ///
	        xlab(1 "From one doctor" 1.85 "From more" 2.15 "than one doctor" 2.85 "Bought from" 3.15 "friend or relative" ///
	             3.85 "Bought from" 4.15 "dealer or stranger" 4.85 "From friend or" 5.15 "relative for free" ///
	             5.85 "Took from friend or" 6.15 "relative without asking" 7 "Other", labsize(`lsize') angle(45) noticks labgap(2)) ///
	        xtick(1(1)7) xoverhangs ylab(0(10)`ytop') yscale(off) graphregion(color(white)) legend(order(1 2 3 7) cols(3) ///
	        lab(1 "Primary market") lab(2 "Secondary market") lab(3 "Other") lab(7 "Friend's source") size(`lsize') ///
		symysize(6) bmargin(0 0 0 -3) region(lcolor(white)))) 
	graph export "${results}/Figure_2b.eps", replace 

*---------------------------- Figure 3(a) ----------------------------*

use "${inter}/county_month_opioids_0614.dta", clear 

	* All matched in using except three counties (21999, 46113, 51515)
	merge 1:1 county_fips date using "${inter}/NIBRS_county_month_0614.dta", nogen keep(matched)
	
	* Adjust opioids by fraction of county population included in seizure data
	replace tot_OP = tot_OP*county_frac
	
	* Collapse to national-level data
	collapse (sum) n_* tot_OP, by(date) fast 
	gen n_other = n_all - n_rxopioid
	
	* Rescale
	replace tot_OP = tot_OP/1000000
	replace n_rxopioid = n_rxopioid/1000
	replace n_other = n_other/10000
	
	twoway (line n_other date, yaxis(1) yscale(alt axis(1)) ylabel(0.5(0.5)3.5, axis(1)) lwidth(0.35) lcolor("`colorl'")) ///
	       (line n_rxopioid date, yaxis(1) lwidth(0.5) lcolor("`colorm'")) ///
	       (line tot_OP date, yaxis(2) yscale(alt axis(2)) ylabel(3(1)7.5, axis(2)) lwidth(0.75) lcolor("`colord'") /// 
	        xsize(6) xlab(552 "2006" 576 "2008" 600 "2010" 624 "2012" 648 "2014", labsize(`lsize')) xtitle("") ///
		ylab(, labsize(`lsize') axis(1)) ytitle("Drug seizures", size(`tsize') axis(1)) yscale(titlegap(2.5) axis(1)) ///
		ylab(, labsize(`lsize') axis(2)) ytitle("Opioid prescriptions", size(`tsize') axis(2)) yscale(titlegap(2.5) axis(2)) ///
		legend(order(3 2 1) col(1) lab(3 "Opioid prescriptions (millions)") lab(2 "Prescription opioid seizures (thousands)") ///
		lab(1 "All other drug seizures (ten thousands)") size(`lsize') symxsize(6) region(lcolor(white))) graphregion(color(white))) 
	graph export "${results}/Figure_3a.eps", replace 

*---------------------------- Figure 3(b) ----------------------------*

use "${inter}/county_month_opioids_0614.dta", clear 

	* All matched in using except three counties (21999, 46113, 51515)
	merge 1:1 county_fips date using "${inter}/NIBRS_county_month_0614.dta", nogen keep(matched)
	keep if year == 2014
	drop if county_frac == . 

	* Only keep county observations with good coverage 
	* - Drops 503 counties (31.07%)
	keep if county_frac >= 0.95 
	
	* Adjust opioids/population by fraction of county population included in seizure data
	foreach v in tot_OP pop_tot {
		replace `v' = `v'*county_frac
	}
	collapse (sum) tot_OP n_rxopioid (mean) pop_tot county_frac, by(county_fips year) fast
	
	* Collapse to commuting zone level 
	* - One county unmatched in master (08014)
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	collapse (sum) tot_OP n_rxopioid pop_tot, by(czone) fast
	
	* Create seizures/ opioids per capita
	gen pc_rxopioid = n_rxopioid/(pop_tot/1000)
	gen pc_OP = tot_OP/pop_tot

	* Create deciles of opioids per capita 
	xtile q10_pcOP = pc_OP [aw=pop_tot], nq(10)
	collapse (mean) pc_OP pc_rxopioid [aw=pop_tot], by(q10_pcOP) fast 
		
	twoway (scatter pc_rxopioid pc_OP, msize(5.5) mcolor("`colorl'")) ///
	       (lfit pc_rxopioid pc_OP, lwidth(1) lcolor("`colord'") ///
		xlab(0(0.6)1.8, labsize(`lsize')) xtitle("Opioid prescriptions per capita", size(`tsize')) xscale(titlegap(2.5)) ///
		ylab(0(0.3)0.9, labsize(`lsize')) ytitle("Prescription opioid seizures per 1,000", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(off) graphregion(color(white))) 
	graph export "${results}/Figure_3b.eps", replace 
	
*---------------------------- Figure 5(a) ----------------------------*	

use `oxy_chars', clear
	
	foreach v in OP oxy oxy_brand oxy_gen {
		replace tot_`v' = tot_`v'/1000000
	}

	twoway (line tot_OP date, yaxis(1) yscale(range(15 23) alt axis(1)) ylabel(15(2)23, axis(1)) lwidth(0.35) lcolor("`colorl'") /// 
		xline(607, lcolor(gs6) lpattern(dash) lwidth(0.75)) ///
		text(15.3 605 "{&larr} August 2010", size(3.5) color(gs6) place(right))) ///
	       (line tot_oxy date, yaxis(2) yscale(alt axis(2)) lwidth(0.75) lcolor("`colord'") ///
	        xlab(552 "2006" 576 "2008" 600 "2010" 624 "2012" 648 "2014", labsize(`lsize')) xtitle("") ///
	        ylab(, labsize(`lsize') axis(1)) ytitle("All opioid prescriptions (millions)", size(`tsize') axis(1)) yscale(titlegap(2.5) axis(1)) ///
		ylab(, labsize(`lsize') axis(2)) ytitle("OxyContin prescriptions (millions)", size(`tsize') axis(2)) yscale(titlegap(2.5) axis(2)) ///
		legend(order(2 1) lab(2 "OxyContin") lab(1 "All opioids") size(3.75) symxsize(6) region(lcolor(white))) ///
		graphregion(color(white))) 	
	graph export "${results}/Figure_5a.eps", replace 

*---------------------------- Figure 5(b) ----------------------------*

use `oxy_changes', clear

	* Construct pre/ post periods
	set type double
	gen period = "" 
	replace period = "100" if date >= 596 & date <= 601
	replace period = "010" if date >= 601 & date <= 606
	replace period = "001" if date >= 608 & date <= 613
	drop if period == ""
	
	collapse (sum) tot_OP tot_oxy, by(provider_id period) fast 
	gen perc_oxy = tot_oxy/tot_OP
	
	reshape wide tot_OP tot_oxy perc_oxy, i(provider_id) j(period) string
	gen change1 = (perc_oxy001 - perc_oxy010)/perc_oxy010
	gen change2 = (perc_oxy001 - perc_oxy100)/perc_oxy100
	forvalues i = 1/2 {
		replace change`i' = 3 if change`i' > 3
		cumul change`i', gen(cum`i')
	}
	
	* Select random sample to reduce file size
	sample 20000, count
	 			
	* Overlaid CDFs (two changes)
	twoway (line cum2 change2, sort lwidth(0.75) lcolor("`colorl'")) ///
	       (line cum1 change1, sort lwidth(0.75) lcolor("`colord'") ///
		xsize(4.5) xlab(-1 "-100" 0 "0" 1 "100" 2 "200" 3 "...{&infinity}", labsize(`lsize')) ///
		xtitle("Percent change in share OxyContin", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ylab(, labsize(`lsize')) ytitle("CDF", size(`tsize')) xscale(titlegap(2.5)) ///
		legend(cols(2) order(2 1) lab(2 "Months surrounding") lab(1 "Year-on-year") ///
		size(3.75) region(lcolor(white))) graphregion(color(white)))	
	graph export "${results}/Figure_5b.eps", replace
	
*------------------------------ Figure 6 -----------------------------*

use `polar', clear
keep if nibrs != .

	* Collapse to decile level 
	gen weight = n_prov_nibrs
	collapse (rawsum) n_prov_nibrs (mean) tot_OP_nibrs nibrs [aw=weight], by(d10_nibrs alt) fast 
	
	* Convert to log scale
	gen ln_nibrs = ln(nibrs)
	
	* Save regression coefficients 
	foreach v in 1 3 {

		reg tot_OP_nibrs nibrs if alt == `v' [aw=n_prov_nibrs], robust
		local slope`v' = round(_b[nibrs],.01)
		local pval = round(ttail(e(df_r),abs(_b[nibrs]/_se[nibrs]))*2,.001)
	
		if `pval' <= 0.01 {
			local stars`v' = "***"
		}
		if `pval' > 0.01 & `pval' <= 0.05 {
			local stars`v' = "**"
		}
		if `pval' > 0.05 & `pval' <= 0.1 {
			local stars`v' = "*"
		}
	}
	
	twoway (scatter tot_OP_nibrs ln_nibrs if alt == 1 [aw=n_prov_nibrs], msize(0.7) mcolor("`colord'")) ///
	       (lfit tot_OP_nibrs ln_nibrs if alt ==1 [aw=n_prov_nibrs], lwidth(1) lcolor("`colord'")) ///
	       (scatter tot_OP_nibrs ln_nibrs if alt == 3 [aw=n_prov_nibrs], msize(0.7) mcolor("`colorl'")) ///
	       (lfit tot_OP_nibrs ln_nibrs if alt == 3 [aw=n_prov_nibrs], lwidth(1) lcolor("`colorl'") ///
		xlab(-3.6889 "ln(0.025)" -2.3026 "ln(0.1)" -0.6931 "ln(0.5)" 0.4055 "ln(1.5)", labsize(`lsize')) ///
		xtitle("Prescription opioid seizures per 1,000", size(`tsize')) xscale(titlegap(2.5)) ///
		ylab(, labsize(`lsize')) ytitle("Average monthly opioid" "prescriptions per physician", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(order(1 3) label(1 "Low altruism: slope = `slope1'`stars1'") label(3 "High altruism: slope = `slope3'`stars3'") ///
		size(3.75) region(lcolor(white))) graphregion(color(white))) 
	graph export "${results}/Figure_6.eps", replace	
	
*---------------------------------------------------------------------*
*------------------------------ APPENDIX -----------------------------* 
*---------------------------------------------------------------------*

*---------------------------- Figure A1(a) ---------------------------*

use "${inter}/county_month_opioids_0614.dta", clear 
keep if year == 2014
	
	* Collapse to yearly data 
	collapse (sum) tot_OP (mean) pop_tot, by(county_fips) fast

	* All matched in master
	merge 1:1 county_fips using "${raw_public}/geo/county_database_geo2xy.dta", nogen keep(matched)
	
	* Create quantiles of opioids per capita 
	gen pc_OP = tot_OP/pop_tot
	xtile q4_OP = pc_OP, nq(4)
		
	forvalues i = 1/4 {
		sum pc_OP if q4_OP == `i'
		local d`i' = floor(100*`r(min)')
		local d`i' = `d`i''/100
	}
	sum pc_OP if q4_OP == 4
	local d5 = round(`r(max)',0.01)

	spmap pc_OP using "${raw_public}/geo/county_coords_geo2xy.dta", id(map_id) ///
		fcolor("`colorvl'" "`colorml'" "`colorm'" "`colormd'") clm(custom) clb(`d1' `d2' `d3' `d4' 200) /// 
		legend(title("        Opioids per capita:", size(medium) justification(left)) ///
		label(2 "`d1'-`d2'") label(3 "`d2'-`d3'") label(4 "`d3'-`d4'") label(5 "`d4'-`d5'") bplacement(se) size(medium) bmargin(0 -3 1 0))
	graph export "${results}/Figure_A1a.eps", replace 	

*---------------------------- Figure A1(b) ---------------------------*

use "${inter}/provider_chars_cleaned.dta", clear 
			
	keep if flag_clean == 1 & flag_cons_2014 == 1
				
	* Create ECDF of log prescriptions in 2014
	gen ln_tot_OP = ln(tot_OP_2014)
	cumul ln_tot_OP, gen(ecdf) equal 
				
	* Select random sample to reduce file size
	sample 100000, count
				
	sort ln_tot_OP
	twoway (kdens ln_tot_OP, yaxis(1) lwidth(0.75) lcolor("`colord'")) ///
	       (line ecdf ln_tot_OP, yaxis(2) lpattern(longdash) lwidth(0.75) lcolor("`colorl'") ///
		xsize(4.5) xlab(2.30 "10" 4.61 "100" 6.91 "1000" 9.21 "10,000" 11 "60,000", labsize(`lsize')) ///
		xtitle("Opioid prescriptions per provider", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ylab(, labsize(`lsize') axis(1)) ytitle("Density", size(`tsize') axis(1)) yscale(titlegap(2.5) axis(1)) ///
		ylab(, labsize(`lsize') axis(2)) ytitle("CDF", size(`tsize') axis(2)) yscale(titlegap(2.5) axis(2)) ///
		legend(lab(1 "Density") lab(2 "CDF") size(3.5) symxsize(8) bmargin(0 0 0 3) region(style(none))) ///
		graphregion(color(white)))
	graph export "${results}/Figure_A1b.eps", replace

*---------------------------- Figure A1(c) ---------------------------*

use "${inter}/provider_chars_cleaned.dta", clear 
			
	keep if flag_clean == 1 & flag_cons_2014 == 1
		
	* Use prescriptions in 2014
	gen ln_tot_OP = ln(tot_OP_2014)
	egen mean = mean(ln_tot_OP)
			
	* Replace missing grad_year with 0 (fixed effect for missing) so not dropped
	replace grad_year = 0 if grad_year == . 
				
	foreach v in specialty county_fips grad_year {
		qui xi: areg ln_tot_OP, absorb(`v')
		predict res_`v', res
		replace res_`v' = res_`v' + mean
	}	
	qui xi: areg ln_tot_OP i.specialty i.grad_year, absorb(county_fips)
	predict res_all, res
	replace res_all = res_all + mean
			
	gen blank = .			
	twoway (kdens ln_tot_OP, lwidth(0.75) lcolor("`colord'")) ///
	       (kdens res_specialty, lwidth(0.5) lpattern(longdash) lcolor("`colorm'")) ///
	       (kdens res_county, lwidth(0.5) lpattern(dash) lcolor("`colorm'")) ///
	       (kdens res_grad, lwidth(0.5) lpattern(shortdash) lcolor("`colorm'")) ///
	       (kdens res_all, lwidth(0.75) lcolor("`colorl'")) ///
               (scatter blank ln_tot_OP, msym(none) ///
		xsize(4) xlab(2.30 "10" 4.61 "100" 6.91 "1000" 9.21 "10,000" 11 "60,000", labsize(`lsize')) ///
		xtitle("Opioid prescriptions per provider", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ylab(, labsize(`lsize')) ytitle("Density", size(`tsize')) yscale(titlegap(5)) ///
		legend(cols(4) order(1 6 2 3 4 5) holes(5 6) lab(1 "Raw") lab(6 "Conditional on:") ///
		lab(2 "Specialty") lab(3 "County") lab(4 "Experience") lab(5 "All the above") size(3.5) ///
		symxsize(7) pos(7) bmargin(-12 0 0 3) region(style(none))) graphregion(color(white)))
	graph export "${results}/Figure_A1c.eps", replace	

*--------------------------- Figure A2(a,b) --------------------------*

local t_all "any source"
local t_sm  "secondary market"
local l_all "a"
local l_sm  "b"

	*------------ Prescriptions -----------*
	
	* Opioid prescriptions (IQVIA)
	use "${inter}/county_month_opioids_0614.dta", clear 
	keep if year == 2014
	collapse (sum) tot_OP (mean) pop_tot, by(county_fips year) fast 
	gen pc_OP = tot_OP/pop_tot
	
	* Misuse (NSDUH)
	* - All matched in master
	* - NSDUH: 02270 and 46113 unmatched (and 2013, 1314)
	merge 1:1 county_fips year using "${inter}/NSDUH_county_year_1314.dta", nogen keep(matched) keepusing(misuse*)
	
	* Add in commuting zone
	* - 9 counties unmatched in master 
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	
	gen weight = pop_tot 
	collapse (rawsum) pop_tot (mean) pc_OP misuse_acs_perc* [aw=weight], by(czone) fast
	
	* Create deciles of opioids per capita 
	xtile q10_pcOP = pc_OP [aw=pop_tot], nq(10)
	collapse (mean) pc_OP misuse* [aw=pop_tot], by(q10_pcOP) fast 
	
	foreach type in all sm {
		twoway (scatter misuse_acs_perc_`type' pc_OP, msize(5.5) mcolor("`colorl'")) ///
		       (lfit misuse_acs_perc_`type' pc_OP, lwidth(1) lcolor("`colord'") ///
			xsize(4) xlab(0.25(0.25)1.25, labsize(`lsize')) xtitle("Opioid prescriptions per capita (IQVIA)", size(`tsize')) xscale(titlegap(2.5)) ///
			ysize(4) ylab(, labsize(`lsize')) ytitle("Predicted misuse rate: `t_`type'' (NSDUH)", size(`tsize')) yscale(titlegap(2.5)) ///
			title("Opioid prescriptions", color(gs0) size(`tsize')) legend(off) graphregion(color(white))) 
		graph export "${results}/Figure_A2`l_`type''_left.eps", replace 
	}
	
	*-------------- Mortality -------------*

	* Fatal overdoses (NVSS)
	use pc_rxopioid county_fips year pop_tot using "${inter}/NVSS_county_year_0614.dta", clear
	keep if year == 2014
	
	* Misuse (NSDUH)
	* - All matched in master
	* - NSDUH: 02270 and 46113 unmatched (and 2013, 1314)
	merge 1:1 county_fips year using "${inter}/NSDUH_county_year_1314.dta", nogen keep(matched) keepusing(misuse*)
	
	* Create deciles of misuse
	foreach type in all sm {
		
		preserve
		
		xtile q10_misuse = misuse_acs_perc_`type' [aw=pop_tot], nq(10)
		collapse (mean) pc_rxopioid misuse_acs_perc_`type' [aw=pop_tot], by(q10_misuse) fast 
	
		twoway (scatter pc_rxopioid misuse_acs_perc_`type', msize(5.5) mcolor("`colorl'")) ///
		       (lfit pc_rxopioid misuse_acs_perc_`type', lwidth(1) lcolor("`colord'") ///
			xsize(4) xlab(, labsize(`lsize')) xtitle("Predicted misuse rate: `t_`type'' (NSDUH)", size(`tsize')) xscale(titlegap(2.5)) ///
			ysize(4) ylab(, labsize(`lsize')) ytitle("Prescription opioid overdoses per 10,000 (NVSS)", size(`tsize')) yscale(titlegap(2.5)) ///
			title("Prescription opioid deaths", color(gs0) size(`tsize')) legend(off) graphregion(color(white))) 
		graph export "${results}/Figure_A2`l_`type''_middle.eps", replace 
		
		restore
	}

	*-------------- Seizures --------------*
	
	* Misuse (NSDUH)
	use misuse_acs_perc* county_fips year pop_tot using "${inter}/NSDUH_county_year_1314.dta", clear
	keep if year == 2014
	
	* Merge in seizures (NIBRS)
	* - 1,619 counties (51.53%) with non-missing county_frac matched in master 
	* - NIBRS: 21999 and 51515 unmatched (and 2006-2013)
	merge 1:1 county_fips year using "${inter}/NIBRS_county_year_0614.dta", nogen keep(matched) keepusing(n_rxopioid county_frac)
	drop if county_frac == . 
	
	* Only keep counties with good coverage
	* - 1,031 counties (63.68%)
	keep if county_frac >= 0.95
	
	* Create per capita seizures (population adjusted by NIBRS coverage)
	replace pop_tot = pop_tot*county_frac
	gen pc_rxopioid = n_rxopioid/(pop_tot/1000)
	
	* Add in commuting zone
	* - One county unmatched in master (08014)
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	
	gen weight = pop_tot 
	collapse (rawsum) pop_tot (mean) misuse_acs_perc* pc_rxopioid [aw=weight], by(czone) fast
	
	* Create deciles of misuse
	foreach type in all sm {
		
		preserve
			
		xtile q10_misuse = misuse_acs_perc_`type' [aw=pop_tot], nq(10)	
		collapse (mean) pc_rxopioid misuse_acs_perc_`type' [aw=pop_tot], by(q10_misuse) fast 
	
		twoway (scatter pc_rxopioid misuse_acs_perc_`type', msize(5.5) mcolor("`colorl'")) ///
		       (lfit pc_rxopioid misuse_acs_perc_`type', lwidth(1) lcolor("`colord'") ///
			xsize(4) xlab(, labsize(`lsize')) xtitle("Predicted misuse rate: `t_`type'' (NSDUH)", size(`tsize')) xscale(titlegap(2.5)) ///
			ysize(4) ylab(, labsize(`lsize')) ytitle("Prescription opioid seizures per 1,000 (NIBRS)", size(`tsize')) yscale(titlegap(2.5)) ///
			title("Prescription opioid seizures", color(gs0) size(`tsize')) legend(off) graphregion(color(white))) 
		graph export "${results}/Figure_A2`l_`type''_right.eps", replace 
		
		restore
	}

*---------------------------- Figure A3(a) ---------------------------*

* Location of quotes
use "${inter}/StreetRx_clean_2014.dta", clear
		
	rename longitude _X 
	rename latitude _Y

	* Shift longitudes of Alaska because it spans the international date line
	replace _X = cond(_X > 0, _X - 180 ,_X + 180) if state_fips == 2 

	* Change the map projection
	geo2xy _Y _X, replace
		
	* Rescale and move Alaska and Hawaii
	replace _X=(_X*.25) + 8 if state_fips == 2
	replace _Y=(_Y*.25) - 92.55 if state_fips == 2

	replace _X=(_X*1.5) + 28.5 if state_fips == 15
	replace _Y=(_Y*1.5) + 59.8 if state_fips == 15		
	save "${inter}/StreetRx_quotes.dta", replace

* Average prices
use "${inter}/StreetRx_state_year_2014.dta", clear
		
	* Create quantiles of average prices
	xtile q4_price = price_mme, nq(4)
		
	forvalues i = 1/4 {
		sum price_mme if q4_price == `i'
		local d`i' = floor(100*`r(min)')
		local d`i' = `d`i''/100
	}
	sum price_mme if q4_price == 4
	local d5 = round(`r(max)',0.01)
	
	* Overlay prices and quotes
	merge 1:1 state_fips using "${raw_public}/geo/state_database_geo2xy.dta", nogen keep(matched)
	spmap price_mme using "${raw_public}/geo/state_coords_geo2xy.dta", id(map_id) ///
		fcolor("`colorvl'" "`colorml'" "`colorm'" "`colormd'") clm(custom) clb(`d1' `d2' `d3' `d4' 2) /// 
		point(data("${inter}/StreetRx_quotes.dta") x(_X) y(_Y) size(0.25) ocolor("`colord'")) ///
		legend(title("       Price per MME:", size(medium) justification(left) bmargin(0 100 0 0)) ///
		label(2 "`d1'-`d2'") label(3 "`d2'-`d3'") label(4 "`d3'-`d4'") label(5 "`d4'-`d5'") bplacement(se) size(medium))
	graph export "${results}/Figure_A3a.eps", replace 

erase "${inter}/StreetRx_quotes.dta"

*---------------------------- Figure A3(b) ---------------------------*

use "${inter}/county_month_opioids_0614.dta", clear 

	* Collapse to county-year level
	keep if year == 2014
	collapse (sum) tot_OP (mean) pop_tot, by(county_fips year) fast 
	
	* Collapse to state-year level
	gen state_fips = substr(county_fips,1,2)
	destring state_fips, replace
	collapse (sum) tot_OP pop_tot, by(state_fips year) fast 
	
	* Create opioids per capita
	gen pc_OP = tot_OP/pop_tot

	* All matched for 2014
	merge 1:1 state_fips year using "${inter}/StreetRx_state_year_2014.dta", nogen keep(matched)
	
	* Create deciles of opioids per capita 
	xtile q10_pcOP = pc_OP [aw=n], nq(10)
	
	collapse (mean) pc_OP price_mme, by(q10_pcOP) fast 	
	twoway (scatter price_mme pc_OP, msize(5.5) mcolor("`colorl'")) ///
               (lfit price_mme pc_OP, lwidth(1) lcolor("`colord'") ///
		xlab(, labsize(`lsize')) xtitle("Opioid prescriptions per capita", size(`tsize')) xscale(titlegap(2.5)) ///
		ylab(, labsize(`lsize')) ytitle("Price per MME on secondary market", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(off) graphregion(color(white))) 
	graph export "${results}/Figure_A3b.eps", replace 

*--------------------------- Figure A5(a,b) --------------------------*

use `oxy_chars', clear

	foreach v in oxy oxy_brand oxy_gen {
		replace tot_`v' = tot_`v'/1000000
	}

	* OxyContin prescriptions and copayments
	twoway (line tot_oxy date, yaxis(1) lwidth(0.75) lcolor("`colorl'") /// 
		xline(607, lcolor(gs6) lpattern(dash) lwidth(0.75)) ///
		text(0.315 605 "{&larr} August 2010", size(3.5) color(gs6) place(right))) ///
	       (line avg_copay_oxy date, yaxis(2) ylabel(20(10)55, axis(2)) lwidth(0.6) lcolor("`colord'") ///
	        xlab(552 "2006" 576 "2008" 600 "2010" 624 "2012" 648 "2014", labsize(`lsize')) xtitle("") ///
	        ylab(, labsize(`lsize') axis(1)) ytitle("OxyContin prescriptions (millions)", size(`tsize') axis(1)) yscale(titlegap(2.5) axis(1)) ///
		ylab(, labsize(`lsize') axis(2)) ytitle("Average OxyContin copayment ($)", size(`tsize') axis(2)) yscale(titlegap(2.5) axis(2)) ///
		legend(lab(1 "Prescriptions") lab(2 "Copayments") size(3.75) symxsize(6) region(lcolor(white))) ///
		graphregion(color(white)))
	graph export "${results}/Figure_A5a.eps", replace 
	
	* Generic and branded OxyContin prescriptions
	twoway (line tot_oxy_brand date, ylabel(0(0.2)0.65) lwidth(0.6) lcolor("`colord'") /// 
		xline(607, lcolor(gs6) lpattern(dash) lwidth(0.75))) ///
	       (line tot_oxy_gen date, lwidth(0.6) lpattern(dash) lcolor("`colord'")) ///
	       (line tot_oxy date, lwidth(0.75) lcolor("`colorl'") ///
	        xlab(552 "2006" 576 "2008" 600 "2010" 624 "2012" 648 "2014", labsize(`lsize')) xtitle("") ///
	        ylab(, labsize(`lsize')) ytitle("OxyContin prescriptions (millions)", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(cols(3) lab(1 "Branded") lab(2 "Generic") lab(3 "All") size(3.75) symxsize(6) region(lcolor(white))) ///
		graphregion(color(white)))
	graph export "${results}/Figure_A5b.eps", replace 

*----------------------------- Figure A6 -----------------------------*

use `oxy_changes', clear

	* Construct pre/ post periods
	set type double
	gen period = "" 
	replace period = "100" if date >= 596 & date <= 601
	replace period = "010" if date >= 601 & date <= 606
	replace period = "001" if date >= 608 & date <= 613
	drop if period == ""
	
	collapse (sum) tot_OP tot_oxy, by(provider_id bins_q3 period) fast 
	gen perc_oxy = tot_oxy/tot_OP
	
	reshape wide tot_OP tot_oxy perc_oxy, i(provider_id bins_q3) j(period) string
	gen change1 = (perc_oxy001 - perc_oxy010)/perc_oxy010
	gen change2 = (perc_oxy001 - perc_oxy100)/perc_oxy100
	forvalues i = 1/2 {
		replace change`i' = 3 if change`i' > 3
		cumul change`i', gen(cum`i')
	}
	
	* Select random sample to reduce file size
	sample 40000, count
	
	gen blank = .
	* Scatterplot of changes + categorization
	twoway (scatter change2 change1 if bins_q3 == 1, msize(0.01) mcolor("`colord'")) ///
	       (scatter change2 change1 if bins_q3 == 2, msize(0.01) mcolor("`colorm'")) ///
	       (scatter change2 change1 if bins_q3 == 3, msize(0.01) mcolor("`colorml'")) ///
	       (scatter blank change1 if bins_q3 == 1, msize(1) mcolor("`colord'")) ///
	       (scatter blank change1 if bins_q3 == 2, msize(1) mcolor("`colorm'")) ///
	       (scatter blank change1 if bins_q3 == 3, msize(1) mcolor("`colorml'") ///
		xsize(4.5) xlab(-1 "-100" 0 "0" 1 "100" 2 "200" 3 "...{&infinity}", labsize(`lsize')) ///
		xtitle("Percent change: months surrounding", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ylab(-1 "-100" 0 "0" 1 "100" 2 "200" 3 "...{&infinity}", labsize(`lsize')) ///
		ytitle("Percent change: year-on-year", size(`tsize')) xscale(titlegap(2.5)) ///
		legend(order(4 5 6) cols(3) lab(4 "Low altruism") lab(5 "Medium altruism") lab(6 "High altruism") ///
		size(3.75) region(lcolor(white))) graphregion(color(white)))	
	graph export "${results}/Figure_A6.eps", replace
	
*----------------------------- Figure A7 -----------------------------*		
	
use "${inter}/provider_chars_cleaned.dta", clear

	keep provider_id tot_OP
	merge 1:1 provider_id using "${inter}/provider_categorized.dta", nogen keepusing(bins_q3)
	
	drop if tot_OP == . 
	gen n_cat = bins_q3 != . 
	gen n_prov = 1 
	gsort -tot_OP
	
	gen perc = sum(tot_OP)
	egen TOT = sum(tot_OP)
	replace perc = (perc/TOT)*100
	drop TOT
	
	gen perc_cat = sum(n_cat)
	gen TOT = sum(n_prov)
	replace perc_cat = (perc_cat/TOT)*100
	drop TOT
	
	gen perc_round = round(perc,.1)
	replace perc_round = 100.01 if _n == _N
	collapse (mean) perc_cat perc, by(perc_round) fast
	 
	twoway (line perc_cat perc, lwidth(0.75) lcolor("`colord'") graphregion(color(white)) ///
		text(12.2 102 "12.2% {&rarr}", size(3.5) color(gs6) place(left)) ///
		xlab(0(20)100, labsize(`lsize')) xtitle("Cumulative share of opioid prescriptions", size(`tsize')) xscale(titlegap(2.5)) ///
	        ylab(0(20)100, labsize(`lsize')) ytitle("Percent of providers categorized", size(`tsize')) yscale(titlegap(2.5)))
	graph export "${results}/Figure_A7.eps", replace
	
*------------------------- Figure A8(a,b,c,d) ------------------------*		

local tperc_male   "share male"
local tperc_2039   "share 20 to 39"
local tperc_4064   "share 40 to 64"
local tperc_third  "share third party"
local lperc_male   "a"
local lperc_2039   "b"
local lperc_4064   "c"
local lperc_third  "d"

use `oxy_changes', clear
			
	* Only keep year before reformulation
	keep if date >= 595 & date <= 606
		
	* Collapse to provider-period level (0010)
	preserve 
		collapse (mean) tot_OP bins_q3, by(provider_id) fast
		save `oxy_changes', replace
	restore
	collapse (mean) perc* [aw=tot_OP], by(provider_id) fast
	merge 1:1 provider_id using `oxy_changes', nogen
			
	foreach v in perc_male perc_2039 perc_4064 perc_third {
	
		twoway (kdens `v' if bins_q3 == 1 [aw=tot_OP], lwidth(0.6) lcolor("`colord'")) ///
		       (kdens `v' if bins_q3 == 2 [aw=tot_OP], lwidth(0.6) lcolor("`colorm'")) ///
		       (kdens `v' if bins_q3 == 3 [aw=tot_OP], lwidth(0.6) lcolor("`colorl'") ///
			xlab(, labsize(`lsize')) xtitle("Baseline: `t`v''", size(`tsize')) xscale(titlegap(2.5)) ///
			ylab(#3, labsize(`lsize')) ytitle("Density", size(`tsize')) yscale(titlegap(2.5)) ///
			legend(rows(1) lab(1 "Low altruism") lab(2 "Medium altruism") lab(3 "High altruism") size(3.75) ///
			region(lcolor(white))) graphregion(color(white)))	
				
		graph export "${results}/Figure_A8`l`v''.eps", replace
	}
	
*----------------------------- Figure A9 -----------------------------* 

use `markets', clear

	* Compute distance from national averages for market selection
	gen distance = 0
	gen pres_pc = (OP_GP)/pop
	gen prov_pc = n_GP/(pop/1000)
	
	foreach v in R tau_o tau_d misuse_sm pain price pres_pc prov_pc beta1 beta2 beta3 beta4 {
		gen nmi = `v' != . 
		gen weight = pop*nmi
		qui sum `v' [aw=weight]
		gen us_`v' = `r(mean)'
		gen std_`v' = (`v'-`r(mean)')/`r(sd)'
		drop nmi weight
		replace distance = std_`v'^2 + distance
		drop std_`v'
	}
	
	* Keep 15 largest czones
	gsort -pop
	keep if _n <= 15 
	set obs 16
	foreach v in R tau_o tau_d misuse_sm pain price pres_pc prov_pc beta1 beta2 beta3 beta4 {
		egen mean = mean(us_`v')
		replace `v' = mean if _n == 16
		drop mean us_`v'
	}
	replace distance = 0 if _n == 16
	replace czone = 0 if _n == 16
	save `markets', replace
	
	gen n = _n + 1
	replace n = 0 if n == 17
	
	label define lab 0 "United States" ///
			 2 "Los Angeles" ///
			 3 "New York City" ///
			 4 "Chicago" ///
			 5 "Newark" ///
			 6 "Houston" ///
			 7 "Philadelphia" ///
			 8 "Washington D.C." ///
			 9 "Boston" ///
			 10 "Detroit" ///
			 11 "San Francisco" ///
			 12 "Atlanta" ///
			 13 "Seattle" ///
			 14 "Phoenix" ///
			 15 "Dallas" ///
			 16 "Stamford" 
	label value n lab
	
	twoway (scatter distance n, mcolor("`colorm'") xline(1, lcolor(gray) lpattern(dash)) ///
		xscale(range(-1 16.5)) xtitle("") xlab(0 2(1)16, valuelabel angle(45) labsize(`lsize')) ///
		yscale(range(-1 20)) ytitle("Distance from U.S. average", size(`lsize')) ylab(, labsize(`lsize')) ///
		graphregion(color(white)))
	graph export "${results}/Figure_A9.eps", replace
	
	* Save for Matlab, post Matlab processing
	save "${inter}/markets_chars.dta", replace
	export delimited using "${inter}/markets_chars.csv", replace
	
*--------------------------- Figure A10(a) ---------------------------* 

use "${inter}/NSDUH_county_year_1314.dta", clear
keep if year == 2014
	
	* All matched
	merge 1:1 county_fips using "${raw_public}/geo/county_database_geo2xy.dta", nogen 
	
	* Create quantiles of misuse
	xtile q4_misuse = misuse_acs_perc_sm, nq(4)
		
	forvalues i = 1/4 {
		sum misuse_acs_perc_sm if q4_misuse == `i'
		local d`i' = floor(100*`r(min)')
		local d`i' = `d`i''/100
	}
	sum misuse_acs_perc_sm if q4_misuse == 4
	local d5 = round(`r(max)',0.01)
	
	spmap misuse_acs_perc_sm using "${raw_public}/geo/county_coords_geo2xy.dta", id(map_id) ///
		fcolor("`colorvl'" "`colorml'" "`colorm'" "`colormd'") clm(custom) clb(`d1' `d2' `d3' `d4' 5) /// 
		legend(title("Misuse rate:", size(medium) justification(left) bmargin(0 150 0 0)) ///
		label(2 "`d1'-`d2'") label(3 "`d2'-`d3'") label(4 "`d3'-`d4'") label(5 "`d4'-`d5'") bplacement(se) size(medium))
	graph export "${results}/Figure_A10a.eps", replace 

*--------------------------- Figure A10(b) ---------------------------* 	

use "${inter}/NSDUH_county_year_1314.dta", clear
keep if year == 2014
	
	* Create deciles of misuse
	xtile q10_all = misuse_acs_perc_all [aw=pop_tot], nq(10)
	collapse (mean) misuse* [aw=pop_tot], by(q10_all) fast 

	twoway (scatter misuse_acs_perc_sm misuse_acs_perc_all, msize(5.5) mcolor("`colorl'"))  ///
	       (lfit misuse_acs_perc_sm misuse_acs_perc_all, lwidth(1) lcolor("`colord'") xlabel(3(0.5)5) ///
		xsize(4) xlab(, labsize(`lsize')) xtitle("Predicted misuse rate: any source", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ylab(, labsize(`lsize')) ytitle("Predicted misuse rate: secondary market", size(`tsize')) yscale(titlegap(2.5)) ///
		legend(off) graphregion(color(white))) 
	graph export "${results}/Figure_A10b.eps", replace 
	
*--------------------------- Figure A10(c) ---------------------------* 

use "${inter}/NSDUH_state_year_1314.dta", clear

	* Use combined 2013-2014 data to match across data sets
	keep if year == 1314
	
	* Extract regression output
	reg misuse_acs_perc_all misuse_perc_all [aw=pop_tot], robust 
	local slope = round(_b[misuse],.001)
	local se = round(_se[misuse],.001)
	local r2 = round(`e(r2)',.001)
	foreach v in slope se r2 {
		local `v' = "0``v''"
		if length("``v''") == 4 {
			local `v' = "``v''0" 
		}
	}
	
	twoway (scatter misuse_acs_perc_all misuse_perc_all [aw=pop_tot], msym(Oh) mcolor("`colorl'")) ///
	       (lfit misuse_acs_perc_all misuse_perc_all [aw=pop_tot], lwidth(1) lcolor("`colord'") ///
	        xsize(4) xlab(, labsize(3.5)) xtitle("Actual misuse rate", size(3.5)) xscale(titlegap(2.5)) ///
	        ysize(4) ylab(, labsize(3.5)) ytitle("Predicted misuse rate: any source", size(3.5)) yscale(titlegap(2.5)) ///
		legend(off) note("  {&beta} = `slope' (se = `se'), R{superscript:2} = `r2'", size(3) ring(0) pos(11)) graphregion(color(white))) 
	graph export "${results}/Figure_A10c.eps", replace 

*--------------------------- Figure A11(a) ---------------------------*

use "${inter}/NHIS_county_year_2014.dta", clear
	
	merge 1:1 county_fips using "${raw_public}/geo/county_database_geo2xy.dta", nogen keep(matched)
	
	* Create quantiles of pain
	xtile q4_pain = pain_acs_tot, nq(4)
		
	forvalues i = 1/4 {
		sum pain_acs_tot if q4_pain == `i'
		local d`i' = floor(100*`r(min)')
		local d`i' = `d`i''/100
		* Problem rounding (d4 = 0.56000000000000001)
		if `i' == 4 {
			local d`i' = substr("`d`i''",1,3)
		}
	}
	sum pain_acs_tot if q4_pain == 4
	local d5 = round(`r(max)',0.01)
	
	spmap pain_acs_tot using "${raw_public}/geo/county_coords_geo2xy.dta", id(map_id) ///
		fcolor("`colorvl'" "`colorml'" "`colorm'" "`colormd'") clm(custom) clb(`d1' `d2' `d3' `d4' 1) /// 
		legend(title("        Pain prevalence:", size(medium) justification(left) bmargin(0 100 0 0)) ///
		label(2 "`d1'-`d2'") label(3 "`d2'-`d3'") label(4 "`d3'-`d4'") label(5 "`d4'-`d5'") bplacement(se) size(medium))
	graph export "${results}/Figure_A11a.eps", replace 

*--------------------------- Figure A11(b) ---------------------------* 

use "${inter}/NHIS_clean_2014.dta", clear 

	gen main = 1
	forvalues i = 0/3 {
		gen pain`i' = pain_tot == `i'
	}
	collapse (mean) pain0 pain1 pain2 pain3, by(main) fast 
	reshape long pain, i(main) j(level)
	
	twoway (bar pain level, barwidth(0.75) fcolor("`colorl'") lcolor("`colorl'") ///
	        xsize(4) xtitle("Pain scale", size(`tsize')) xscale(titlegap(2.5)) ///
		ysize(4) ytitle("Share reporting", size(`tsize')) yscale(titlegap(2.5)) ///
		graphregion(color(white))) 
	graph export "${results}/Figure_A11b.eps", replace 

*--------------------------- Figure A11(c) ---------------------------*

use "${inter}/NHIS_region_year_2014.dta", clear

	gen label = ""
	replace label = "NE" if region == 1
	replace label = "MW" if region == 2
	replace label = "S" if region == 3
	replace label = "W" if region == 4
	
	* Extract regression output
	reg pain_acs_tot pain_tot, robust
	local slope = round(_b[pain_tot],.001)
	local se = round(_se[pain_tot],.001)
	local r2 = round(`e(r2)',.001)
	foreach v in slope se r2 {
		local `v' = "0``v''"
		if length("``v''") == 4 {
			local `v' = "``v''0" 
		}
	}

	twoway (scatter pain_acs_tot pain_tot, msym(Oh) mcolor("`colorl'") ///
	        mlabel(label) mlabcolor(gs0) mlabgap(1.5)) ///
	       (lfit pain_acs_tot pain_tot, lwidth(1) lcolor("`colord'") ylabel(0.48(0.0075)0.5025) xlabel(0.45(0.03)0.54) ///
	        xsize(4) xlab(, labsize(`lsize')) xtitle("Actual pain prevalence", size(`tsize')) xscale(titlegap(2.5)) ///
	        ysize(4) ylab(, labsize(`lsize')) ytitle("Predicted pain prevalence", size(`tsize')) yscale(titlegap(2.5)) ///
		note("  {&beta} = `slope' (se = `se'), R{superscript:2} = `r2'", size(3) ring(0) pos(11)) ///
		legend(off) graphregion(color(white))) 
	graph export "${results}/Figure_A11c.eps", replace 


***********************************************************************
*------------------------------- TABLES ------------------------------* 
***********************************************************************

*---------------------------------------------------------------------*
*-------------------------------- MAIN -------------------------------* 
*---------------------------------------------------------------------*
	
*------------------------------ Table 1 ------------------------------*

use "${inter}/provider_categorized.dta", clear 
keep if bins_q3 != . 

	* Compute number of non-zero years 
	merge 1:m provider_id using "${inter}/provider_month_opioids_0614.dta", nogen keepusing(year tot_OP tot_gen)
	collapse (sum) tot_OP tot_gen, by(provider_id year bins_q3) fast 
	gen n_years = 1 
	
	* Add opioid-benzo co-prescribing 
	* - 849,795 provider-years (9.21%) accounting for 1.28% of LRx opioids unmatched in using 
	* - 407,883 provider-years (4.64%) accounting for 1.89% of XPonent opioids unmatched in master
	merge 1:1 provider_id year using "${inter}/provider_year_LRx_0614.dta", keep(master matched) keepusing(tot_LRx tot_copres)
	gen n_years_LRx = tot_LRx != .
	collapse (sum) n_years tot_OP tot_gen n_years_LRx tot_LRx tot_copres, by(provider_id bins_q3) fast 
	gen perc_gen = (tot_gen/tot_OP)*100
	gen perc_copres = (tot_copres/tot_LRx)*100
	
	* Drop providers with missing specialty and provider_id >= 9500000 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) keepusing(flag_GP)
	replace bins_q3 = 4 if bins_q3 == .
	
	gen n_prov = 1 
	gen n_prov_LRx = tot_LRx != 0 
	foreach v in tot_OP n_prov {
		gen `v'_GP = `v'*flag_GP
	}
	save `temp1', replace 
	
	* Collapse to categorized level
	collapse (sum) n_prov* n_years* tot_OP* tot_copres (mean) perc_gen perc_copres, by(bins_q3) fast 
	gen mean_OP = tot_OP/n_years
	gen mean_copres = tot_copres/n_years_LRx
	save `temp2', replace 
	
	* Collapse to overall 
	use `temp1', clear
	replace bins_q3 = 0 
	collapse (sum) n_prov* n_years* tot_OP* tot_copres (mean) perc_gen perc_copres, by(bins_q3) fast 
	gen mean_OP = tot_OP/n_years
	gen mean_copres = tot_copres/n_years_LRx
	append using `temp2'
	drop n_years* n_prov_LRx tot_copres
	
	* Construct percents
	gen cat = bins_q3 != 4 & bins_q3 != 0 	
	foreach v in tot_OP n_prov {
		
		* Overall	
		foreach type in "" "_GP" {
		
			replace tot_OP`type' = tot_OP`type'/1000000000 if "`v'" == "tot_OP"
			
			egen TOT = max(`v'`type')
			gen p`v'`type' = (`v'`type'/TOT)*100
			drop TOT
		}
		
		* Within category
		egen TOT = sum(`v'*cat)
		gen wp`v' = (`v'/TOT)*100 if cat == 1
		drop TOT
	}
	drop cat

	* Reshape
	gen order = 1 
	reshape wide n_prov* pn_prov* wpn_prov tot_OP* ptot_OP* wptot_OP mean* perc*, i(order) j(bins_q3)
	foreach v in n_prov pn_prov wpn_prov n_prov_GP pn_prov_GP tot_OP ptot_OP wptot_OP ///
		     tot_OP_GP ptot_OP_GP mean_OP perc_gen mean_copres perc_copres {
		forvalues i = 0/4 {
			rename `v'`i' b`i'_`v'
			if "`v'" != "n_prov" & "`v'" != "n_prov_GP" {
				tostring b`i'_`v', replace force format(%12.2f)
			} 
			if "`v'" == "n_prov" | "`v'" == "n_prov_GP" {
				tostring b`i'_`v', replace force format(%12.0fc)
			}
		}	
	}
	reshape long b0 b1 b2 b3 b4, i(order) j(type) string
	drop order 
	
	* Adjust ordering
	gen order = .
	replace order = 1 if _n == 11
	replace order = 2 if _n == 9
	replace order = 3 if _n == 14
	replace order = 4 if _n == 1
	replace order = 5 if _n == 6 
	replace order = 6 if _n == 2
	replace order = 7 if _n == 5
	replace order = 8 if _n == 3
	replace order = 9 if _n == 7
	replace order = 10 if _n == 13 	
	replace order = 11 if _n == 12
	replace order = 12 if _n == 10
	replace order = 13 if _n == 4
	replace order = 14 if _n == 8
	
	set obs 19
	replace order = 0.33 if _n == 15
	replace order = 0.66 if _n == 16
	replace order = 5.5 if _n == 17
	replace order = 10.33 if _n == 18
	replace order = 10.66 if _n == 19 
	sort order 
	drop order type
	
	* Update naming
	gen var = ""
	replace var = "\textbf{a. All providers}" if _n == 1
	replace var = "\addlinespace[1ex]\emph{Opioid prescribing}" if _n == 2
	replace var = "\addlinespace[1ex]\quad Total (billions)" if _n == 3
	replace var = "\quad Percent of total" if _n == 4
	replace var = "\quad Percent of categorized" if _n == 5
	replace var = "\quad Mean per provider-year" if _n == 6
	replace var = "\quad Mean percent generic" if _n == 7
	replace var = "\addlinespace[1ex]\emph{Opioid-benzodiazepine co-prescribing}" if _n == 8
	replace var = "\addlinespace[1ex]\quad Mean per provider-year" if _n == 9
	replace var = "\quad Mean percent opioids co-prescribed" if _n == 10	
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 11
	replace var = "Percent of providers" if _n == 12
	replace var = "Percent of categorized providers" if _n == 13
	replace var = "\midrule\addlinespace[1.5ex]\textbf{b. General practice physicians (GPs)}" if _n == 14
	replace var = "\addlinespace[1ex]\emph{Opioid prescribing}" if _n == 15
	replace var = "\addlinespace[1ex]\quad Total (billions)" if _n == 16
	replace var = "\quad Percent of GP total" if _n == 17
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of GPs" if _n == 18
	replace var = "Percent of GPs" if _n == 19

	* Format variables
	forvalues i = 0/4 {
		replace b`i' = "" if b`i' == "."
	}
	order var b0 b1 b2 b3 b4

	texsave using "${results}/Table_1.tex", nofix nonames size(footnotesize) frag replace ///
		headerlines("& & \multicolumn{4}{c}{By altruism group}" "\cmidrule(lr){3-6} \addlinespace[-2ex]" ///
		"& {All} & {Low} & {Medium} & {High} & {Uncategorized}" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}") 

*---------------------------------------------------------------------*
*------------------------------ APPENDIX -----------------------------* 
*---------------------------------------------------------------------*

*------------------------------ Table A1 -----------------------------*

	*-------------- Providers -------------*

	use `chars', clear

	* Characteristics 
	gen cmed_US = rank != "Foreign" 
	gen cmed_rank_share = rank != "Unranked" & rank != "Foreign"
	foreach v in US rank_share {
		replace cmed_`v' = . if region == 112
	}
	gen cage = 2010 - birth_year 
	gen cexper = 2010 - grad_year
	gen cfemale = gender - 1
	rename rank_n crank_n
	
	* By provider type
	gen flag_all = 1 
	foreach v1 in all MD GP {
		foreach v2 in n_OP cage cfemale cexper cmed_US cmed_rank_share crank_n {
			gen `v1'`v2' = `v2' if flag_`v1' == 1
		}
		rename flag_`v1' `v1'n_prov
	}
		
	gen main = 1 
	collapse (sum) alln* MDn* GPn* (mean) allc* MDc* GPc*, by(main) fast

	foreach v1 in MD GP all {
			
		* Construct percents
		foreach v2 in prov OP {
			gen `v1'pc_`v2' = (`v1'n_`v2'/alln_`v2')*100
		}
		
		* Format strings
		tostring `v1'n_prov, replace force format(%12.0fc)
		
		replace `v1'n_OP = `v1'n_OP/1000000000
		foreach v2 in pc_prov n_OP pc_OP cage cexper crank_n {
			tostring `v1'`v2', replace force format(%12.2f) 
		}
		foreach v2 in cfemale cmed_US cmed_rank_share {
			replace `v1'`v2' = `v1'`v2'*100
			tostring `v1'`v2', replace force format(%12.2f) 
		}
	}
	
	reshape long all MD GP, i(main) j(var) string
	drop main
	
	* Characteristics only available for physicians 
	foreach v in cage cfemale cexper cmed_US cmed_rank_share crank_n {
		replace all = "--" if var == "`v'"
	}
	save `temp1', replace 
	
	*-------------- Patients --------------*
	
	use `chars', clear
	 
	gen flag_all = 1
	foreach v1 in all MD GP {
		gen `v1'n_OP = n_OP*flag_`v1'
		foreach v2 in male female 0019 2039 4064 65plus cash medicaid medicare third {	
			gen `v1'pc_`v2' = `v1'n_OP*perc_`v2' 
		}
	}
	gen main = 1 
	collapse (sum) all* MD* GP*, by(main) fast 
	
	* Percents 
	foreach v1 in all MD GP {
		foreach v2 in male female 0019 2039 4064 65plus cash medicaid medicare third {
			replace `v1'pc_`v2' = (`v1'pc_`v2' /`v1'n_OP)*100	
		}
		drop `v1'n_OP
	}
	
	* Format strings
	foreach v1 in all MD GP {
		foreach v2 in male female 0019 2039 4064 65plus cash medicaid medicare third {
			tostring `v1'pc_`v2', replace force format(%12.2f) 	
		}
	}
	
	reshape long all MD GP, i(main) j(var) string
	drop main 
	append using `temp1'
	
	*-------------- Reformat --------------*

	* Adjust ordering
	gen order = .
	replace order = 1 if _n == 7
	replace order = 2 if _n == 6
	replace order = 3 if _n == 1
	replace order = 4 if _n == 2
	replace order = 5 if _n == 3
	replace order = 6 if _n == 4
	replace order = 7 if _n == 5
	replace order = 8 if _n == 8
	replace order = 9 if _n == 9
	replace order = 10 if _n == 10
	replace order = 11 if _n == 17
	replace order = 12 if _n == 19
	replace order = 13 if _n == 11
	replace order = 14 if _n == 13
	replace order = 15 if _n == 12
	replace order = 16 if _n == 14
	replace order = 17 if _n == 15
	replace order = 18 if _n == 16
	replace order = 19 if _n == 18
	replace order = 20 if _n == 20
	
	set obs 25
	replace order = 0.33 if _n == 21
	replace order = 0.66 if _n == 22 
	replace order = 2.5 if _n == 23
	replace order = 6.5 if _n == 24 
	replace order = 12.5 if _n == 25
	sort order 
	drop order 
	
	* Update naming
	replace var = "\textbf{a. Patient characteristics}" if _n == 1
	replace var = "\addlinespace[1ex]\quad\emph{Sex (\%)}" if _n == 2
	replace var = "\addlinespace[1ex]\quad\quad Male" if _n == 3
	replace var = "\quad\quad Female" if _n == 4
	replace var = "\addlinespace[1ex]\quad\emph{Age (\%)}" if _n == 5
	replace var = "\addlinespace[1ex]\quad\quad 0--19" if _n == 6
	replace var = "\quad\quad 20--39" if _n == 7
	replace var = "\quad\quad 40--64" if _n == 8
	replace var = "\quad\quad 65+" if _n == 9
	replace var = "\addlinespace[1ex]\quad\emph{Payment type (\%)}" if _n == 10
	replace var = "\addlinespace[1ex]\quad\quad Cash" if _n == 11
	replace var = "\quad\quad Medicaid" if _n == 12
	replace var = "\quad\quad Medicare" if _n == 13
	replace var = "\quad\quad Private" if _n == 14
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of prescriptions (billions)" if _n == 15
	replace var = "Percent of prescriptions" if _n == 16
	replace var = "\midrule\addlinespace[1.5ex]\textbf{b. Physician characteristics}" if _n == 17
	replace var = "\addlinespace[1ex]\quad Average age" if _n == 18
	replace var = "\quad Percent female" if _n == 19
	replace var = "\quad Average experience" if _n == 20
	replace var = "\quad Percent medical school in U.S." if _n == 21
	replace var = "\quad Percent of U.S. trained ranked" if _n == 22
	replace var = "\quad Average U.S. medical school rank" if _n == 23
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 24
	replace var = "Percent of providers" if _n == 25

	texsave using "${results}/Table_A1.tex", nofix nonames size(footnotesize) frag replace ///
		headerlines("& {All prescribers} & {Physicians} & {General practice physicians}" "&{(1)}&{(2)}&{(3)}") 

*------------------------------ Table A2 -----------------------------*

use `rx_mort', clear

	* Save standard deviation of independent variable
	sum pc_OP
	local SD_OP = `r(sd)'

	local append replace
	foreach type in rxopioid opioids drugs {
		
		reg pc_`type' pc_OP i.year [aw=pop_tot], cluster(czone)	
		regsave using `temp1', table(main_`type', asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `append'
		if "`type'" == "rxopioid" {
			local append append
		}
		
		areg pc_`type' pc_OP i.year [aw=pop_tot], absorb(czone) cluster(czone)	
		regsave using `temp1', table(fes_`type', asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `append'
		
	}
	
	use `temp1', clear
	keep if strpos(var,"pc") != 0 | strpos(var,"N") != 0 | strpos(var,"r2") != 0
	save `temp1', replace 
	
	* Merge in mean dependent variables
	use `rx_mort', clear
	gen var = "Mean dependent variable"
	foreach v1 in rxopioid opioids drugs {
		foreach v2 in main fes {
			gen `v2'_`v1' = pc_`v1'
		}
	}
	collapse (mean) main* fes* [aw=pop_tot], by(var) fast
	set obs 4
	replace var = "SD independent variable" if _n == 2
	replace var = "\addlinespace[1ex] Year FEs" if _n == 3 
	replace var = "Commuting zone FEs" if _n == 4
	foreach v1 in rxopioid opioids drugs {
		foreach v2 in main fes {
			replace `v2'_`v1' = `SD_OP' if _n == 2
			tostring `v2'_`v1', format(%8.3fc) replace force
			replace `v2'_`v1' = "X" if _n == 3
		}
		replace fes_`v1' = "X" if _n == 4
		replace main_`v1' = "" if _n == 4
	}
	append using `temp1'
	
	* Reformat table 
	gen n = _n
	replace n = 6.25 if n == 3
	replace n = 6.75 if n == 4
	replace n = 8.75 if n == 1
	replace n = 8.25 if n == 2
	sort n 
	drop n 

	replace var = "" if strpos(var,"_stderr") != 0
	replace var = "Opioid prescriptions per capita" if _n == 1
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Observations" if _n == 5
	replace var = "$ R^2$" if _n == 6
	
	order var main_rxopioid fes_rxopioid main_opioids fes_opioids main_drug fes_drug
	local i = 1 
	foreach v in main_rxopioid fes_rxopioid main_opioids fes_opioids main_drug fes_drug {
		label var `v' "(`i')" 
		local i = `i' + 1
	}
	
	texsave using "${results}/Table_A2.tex", nofix size(footnotesize) varlabels frag replace ///
		headerlines("{Fatal overdoses per 10,000:} & \multicolumn{2}{c}{Prescription opioids} & \multicolumn{2}{c}{All opioids} & \multicolumn{2}{c}{All drugs}" ///
		"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \addlinespace[-2ex]")
	
*------------------------------ Table A3 -----------------------------*

* Create statistics 
foreach type in det cat total {
	
	use `nsduh', clear
	keep if year == 2014
	
	gen freq_g30 = misuse_freq > 30
	gen freq_g182 = misuse_freq > 182
	
	if "`type'" == "det" {
	
		* Reorder sources to add small categories
		replace source_det_2014 = 9 if source_det_2014 == 7 
		replace source_det_2014 = 7 if source_det == 4
		replace source_det_2014 = 8 if source_det == 3
		drop source_det
		rename source_det_2014 source_det
	}
	
	gen n = 1
	gen source_total = 9.75
	collapse (sum) n misuse_freq freq_g30 freq_g182 [pw=analwt_c], by(source_`type') fast 
	
	if "`type'" != "total" {
		foreach v in n misuse_freq freq_g30 freq_g182 {
			egen total = sum(`v')
			replace `v' = `v'/total*100
			drop total
		}
	}	
	if "`type'" == "cat" {
		gen source_det = . 
		replace source_det = 2.25 if source_cat == 1
		replace source_det = 4.25 if source_cat == 2
		replace source_det = 9.25 if source_cat == 3
		drop source_cat
		append using `temp1'
	}
	if "`type'" == "total" {
		rename source_total source_det
		gen total = n[_n==1]
		foreach v in n freq_g30 freq_g182 {
			replace `v' = `v'/total*100
		}
		* Frequency weighted uses all observations 
		replace total = misuse_freq[_n==1]
		replace misuse_freq = misuse_freq/total*100
		drop total
		append using `temp1'
	}

	save `temp1', replace 
}
	
use `temp1', clear
	
	* Reformat table
	set obs 16
	replace source_det = 0.75 if _n == 14
	replace source_det = 2.75 if _n == 15
	replace source_det = 4.75 if _n == 16
	sort source_det
	
	tostring source_det, replace force
	replace source_det = "\emph{Total}" if _n == 4 | _n == 8 | _n == 15
	replace source_det = "\textbf{Primary market}" if _n == 1
	replace source_det = "\quad From one doctor" if _n == 2
	replace source_det = "\quad From more than one doctor" if _n == 3
	replace source_det = "\addlinespace[1ex]\textbf{Secondary market}" if _n == 5
	replace source_det = "\quad Bought from friend of relative" if _n == 6
	replace source_det = "\quad Bought from drug dealer or other stranger" if _n == 7
	replace source_det = "\addlinespace[1ex]\textbf{Other}" if _n == 9
	replace source_det = "\quad Got from friend or relative for free" if _n == 10
	replace source_det = "\quad Took from friend of relative without asking" if _n == 11
	replace source_det = "\quad Stole from office, clinic, hospital, or pharmacy" if _n == 12
	replace source_det = "\quad Wrote fake prescription" if _n == 13
	replace source_det = "\quad Got some other way" if _n == 14
	replace source_det = "\addlinespace[1ex]\hline\addlinespace[1ex] Share of misusers (\%)" if _n == 16
	
	local i = 1
	foreach v in n misuse_freq freq_g30 freq_g182 {
		tostring `v', replace force format(%12.2f)
		replace `v' = "" if `v' == "."
		label var `v' "(`i')" 
		local i = `i' + 1
	}
	
	order source_det n misuse_freq freq_g30 freq_g182
	
	texsave using "${results}/Table_A3.tex", nofix size(footnotesize) varlabels frag replace ///
		headerlines("& \multicolumn{2}{c}{All misusers} & \multicolumn{2}{c}{Frequent misusers}" ///
		"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \addlinespace[-2ex]" ///
		"&{Unweighted}&{Frequency weighted}&{$\geq$ 1 months}&{$\geq$ 6 months}")    

*------------------------------ Table A4 -----------------------------*

use "${inter}/provider_categorized.dta", clear 
keep if bins_q3 != . 

	* Drop providers with missing specialty and provider_id >= 9500000 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) keepusing(flag_GP)
	
	gen n_prov = 1 
	foreach v in pp_change1 pp_change2 pc_change1 pc_change2 n_prov {
		gen `v'_GP = `v'
		replace `v'_GP = . if flag_GP == 0 
	}
	
	* Collapse to categorized level 
	collapse (sum) n_prov* (mean) pp_* (p50) pc_*, by(bins_q3) fast 
	
	* Reshape
	gen order = 1 
	reshape wide pp* pc* n_prov*, i(order) j(bins_q3)
	foreach v in pp_change1 pp_change2 pc_change1 pc_change2 n_prov ///
		     pp_change1_GP pp_change2_GP pc_change1_GP pc_change2_GP n_prov_GP {
		forvalues i = 1/3 {
			rename `v'`i' b`i'_`v'
			if "`v'" != "n_prov" & "`v'" != "n_prov_GP" {
				tostring b`i'_`v', replace force format(%12.2fc)
				replace b`i'_`v' = "+$\infty$" if b`i'_`v' == "999,999.00"
			} 
			if "`v'" == "n_prov" | "`v'" == "n_prov_GP" {
				tostring b`i'_`v', replace force format(%12.0fc)
			}
		}
	}
	reshape long b1 b2 b3, i(order) j(type) string
	drop order 
	
	* Adjust ordering
	gen order = .
	replace order = 1 if _n == 7
	replace order = 2 if _n == 9
	replace order = 3 if _n == 3 	
	replace order = 4 if _n == 5
	replace order = 5 if _n == 1
	replace order = 6 if _n == 8
	replace order = 7 if _n == 10
	replace order = 8 if _n == 4 
	replace order = 9 if _n == 6
	replace order = 10 if _n == 2
	
	set obs 16
	replace order = 0.33 if _n == 11
	replace order = 0.66 if _n == 12
	replace order = 2.5 if _n == 13
	replace order = 5.33 if _n == 14
	replace order = 5.66 if _n == 15
	replace order = 7.5 if _n == 16
	sort order 
	drop order type
	
	* Update naming
	gen var = ""
	replace var = "\textbf{a. All providers}" if _n == 1
	replace var = "\addlinespace[1ex]\emph{Mean percentage point change}" if _n == 2
	replace var = "\addlinespace[1ex]\quad Sept. 2010--Feb. 2011 vs. Feb. 2010--July 2010" if _n == 3 | _n == 6
	replace var = "\quad Sept. 2010--Feb. 2011 vs. Sept. 2009--Feb. 2010" if _n == 4 | _n == 7
	replace var = "\addlinespace[1ex]\emph{Median percent change}" if _n == 5
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 8
	replace var = "\midrule\addlinespace[1.5ex] \textbf{b. General practice physicians (GPs)}" if _n == 9
	replace var = "\addlinespace[1ex]\emph{Mean percentage point change}" if _n == 10
	replace var = "\addlinespace[1ex]\quad Sept. 2010--Feb. 2011 vs. Feb. 2010--July 2010" if _n == 11 | _n == 14
	replace var = "\quad Sept. 2010--Feb. 2011 vs. Sept. 2009--Feb. 2010" if _n == 12 | _n == 15
	replace var = "\addlinespace[1ex]\emph{Median percent change}" if _n == 13
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of GPs" if _n == 16
	order var b1 b2 b3 
	
	texsave using "${results}/Table_A4.tex", nofix nonames size(footnotesize) frag replace ///
		headerlines("& \multicolumn{3}{c}{By altruism group}" "\cmidrule(lr){2-4} \addlinespace[-2ex]" ///
			    "& {Low} & {Medium} & {High}" "&{(1)}&{(2)}&{(3)}")  

*------------------------------ Table A5 -----------------------------*

local patient_chars 	"perc_male perc_female perc_0019 perc_2039 perc_4064 perc_65plus perc_cash perc_medicaid perc_medicare perc_third misuse"
local czone_chars 	"pop_tot pop_dens perc_white perc_black perc_hisp perc_hsg perc_scol perc_cplus med_hh_inc perc_unemp"

	*------ PATIENT CHARS -----*
	
	use provider_id date year perc* using "${inter}/provider_month_patientchars_0614.dta", clear
	
	* Combine age categories 
	gen perc_0019 = perc_0002 + perc_0309 + perc_1019
	gen perc_4064 = perc_4059 + perc_6064
	gen perc_65plus = perc_6574 + perc_7584 + perc_85plus
	drop perc_0002 perc_0309 perc_1019 perc_4059 perc_6064 perc_6574 perc_7584 perc_85plus perc_age_mi perc_sex_mi

	* Opioid prescriptions
	* - All matched
	merge 1:1 provider_id date using "${inter}/provider_month_opioids_0614.dta", nogen keepusing(tot_OP)
	
	* Collapse to provider level 
	gen weight = tot_OP
	collapse (rawsum) tot_OP (mean) perc* [aw=weight], by(provider_id) fast 

	* Extract practice county
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) keepusing(czone county_fips)
	* - 57,492 providers (3.89%) with missing czone
	
	* Add predicted misuse
	merge 1:1 provider_id using "${inter}/provider_misuse_2009.dta", nogen keep(master matched)
	replace misuse = misuse/100
	
	* Merge in altruism groupings 
	merge 1:1 provider_id using "${inter}/provider_categorized.dta", nogen keep(matched)
	drop if bins_q3 == .
	save `temp1', replace
	
	*---- LOCAL AREA CHARS ----*

	* County characteristics
	use county_fips pop_dens perc_white perc_black perc_hisp perc_hsg perc_scol perc_cplus perc_unemp med_hh_inc ///
		using "${inter}/ACS_county_demos_1014.dta", clear 
		
	* Get county population 
	gen year = 2010
	merge 1:1 county_fips year using "${inter}/county_year_pop_0614.dta", nogen keep(matched) 
	replace pop_tot = pop_tot/1000000
	
	* Collapse to czone 
	* - 9 counties unmatched
	destring county_fips, replace
	merge 1:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", nogen keep(matched)
	gen weight = pop_tot 
	collapse (rawsum) pop_tot (mean) pop_dens perc* med_hh_inc, by(czone) fast 
	
	* Merge provider data back in
	merge 1:m czone using `temp1', keep(using matched)

	* Save p-values of difference 
	gen low_alt = bins_q3 == 1
	foreach v in `patient_chars' `czone_chars' {
		qui reg `v' low_alt if bins_q3 == 1 | bins_q3 == 3, vce(cluster czone) 
		local pval_`v' = 2*ttail(e(df_r),abs(_b[low_alt]/_se[low_alt]))
	}
	
	*-------- REFORMAT --------*
	* Collapse to categorized level
	foreach type in mean sd {
		foreach v in `patient_chars' `czone_chars' {
		
			gen `v'`type' = `v'
			local chars_`type' = "`chars_`type'' `v'`type'"
		}
	}
	gen n_prov = 1
	gen n_prov_czone = _merge == 3
	collapse (sum) n_prov* (mean) `chars_mean' (sd) `chars_sd', by(bins_q3) fast 

	* Percents 
	foreach type in mean sd {
		foreach v in `patient_chars' perc_white perc_black perc_hisp perc_hsg perc_scol perc_cplus perc_unemp {
			replace `v'`type' = `v'`type'*100
		}
	}
	reshape long `patient_chars' `czone_chars', i(bins_q3 n_prov*) j(type) string
	replace bins_q3 = bins_q3 + 3 if type == "sd"
	drop type
	
	* Add p-values
	set obs 7
	replace bins_q3 = 7 if _n == 7
	foreach v in `patient_chars' `czone_chars' {
		replace `v' = round(`pval_`v'',0.001) if _n == 7
	}
	
	* Reshape
	gen order = 1 
	reshape wide n_prov* `patient_chars' `czone_chars', i(order) j(bins_q3)
	foreach v in `patient_chars' `czone_chars' { 
		     
		forvalues i = 1/6 {
			rename `v'`i' b`i'_`v'
			if "`v'" != "pop_dens" & "`v'" != "med_hh_inc" {
				tostring b`i'_`v', replace force format(%12.2f)
			} 
			if "`v'" == "pop_dens" | "`v'" == "med_hh_inc" {
				tostring b`i'_`v', replace force format(%12.0fc)
			}
			if `i' == 4  | `i' == 5 | `i' == 6 {
				replace b`i'_`v' = "(" + b`i'_`v' + ")"
			}
		}
		rename `v'7 b7_`v'
		tostring b7_`v', force replace format(%12.3f)
		replace b7_`v' = "" if b7_`v' == "."
		replace b7_`v' = "<0.001" if b7_`v' == "0.000"	
	}
	foreach v in "" "_czone" {
		forvalues i = 1/7 {
			tostring n_prov`v'`i', replace force format(%12.0fc)
			replace n_prov`v'`i' = "" if `i' >= 4 
			rename n_prov`v'`i' b`i'_n_prov`v'
			replace b`i'_n_prov`v' = "" if `i' == 7
		}
	}
	reshape long b1 b2 b3 b4 b5 b6 b7, i(order) j(type) string
	drop order 
	
	* Adjust ordering
	gen order = .
	replace order = 1 if _n == 15
	replace order = 2 if _n == 12
	replace order = 3 if _n == 5
	replace order = 4 if _n == 6	
	replace order = 5 if _n == 7
	replace order = 6 if _n == 8
	replace order = 7 if _n == 10
	replace order = 8 if _n == 16
	replace order = 9 if _n == 17 
	replace order = 10 if _n == 19
	replace order = 11 if _n == 2
	replace order = 12 if _n == 3
	replace order = 13 if _n == 23
	replace order = 14 if _n == 22
	replace order = 15 if _n == 21
	replace order = 16 if _n == 9
	replace order = 17 if _n == 13
	replace order = 18 if _n == 14
	replace order = 19 if _n == 18
	replace order = 20 if _n == 11
	replace order = 21 if _n == 20
	replace order = 22 if _n == 1
	replace order = 23 if _n == 4
	
	set obs 31
	replace order = 0.33 if _n == 24
	replace order = 0.66 if _n == 25
	replace order = 2.5 if _n == 26
	replace order = 6.5 if _n == 27
	replace order = 12.5 if _n == 28
	replace order = 14.5 if _n == 29
	replace order = 17.5 if _n == 30
	replace order = 20.5 if _n == 31
	sort order 
	drop order type
	
	* Update naming
	gen var = ""
	replace var = "\textbf{a. Patient characteristics}" if _n == 1
	replace var = "\addlinespace[1ex]\quad\emph{Sex (\%)}" if _n == 2
	replace var = "\addlinespace[1ex]\quad\quad Male" if _n == 3
	replace var = "\quad\quad Female" if _n == 4
	replace var = "\addlinespace[1ex]\quad\emph{Age (\%)}" if _n == 5
	replace var = "\addlinespace[1ex]\quad\quad 0--19" if _n == 6
	replace var = "\quad\quad 20--39" if _n == 7
	replace var = "\quad\quad 40--64" if _n == 8
	replace var = "\quad\quad 65+" if _n == 9
	replace var = "\addlinespace[1ex]\quad\emph{Payment type (\%)}" if _n == 10
	replace var = "\addlinespace[1ex]\quad\quad Cash" if _n == 11
	replace var = "\quad\quad Medicaid" if _n == 12
	replace var = "\quad\quad Medicare" if _n == 13
	replace var = "\quad\quad Private" if _n == 14
	replace var = "\addlinespace[1ex]\quad\emph{Predicted misuse (\%)}" if _n == 15
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 16
	replace var = "\midrule\addlinespace[1.5ex]\textbf{b. Commuting zone characteristics}" if _n == 17
	replace var = "\addlinespace[1ex]\quad Total population (millions)" if _n == 18
	replace var = "\quad Population density" if _n == 19
	replace var = "\addlinespace[1ex]\quad\emph{Race/ ethnicity (\%)}" if _n == 20
	replace var = "\addlinespace[1ex]\quad\quad White" if _n == 21
	replace var = "\quad\quad Black" if _n == 22
	replace var = "\quad\quad Hispanic" if _n == 23
	replace var = "\addlinespace[1ex]\quad\emph{Education (\%)}" if _n == 24
	replace var = "\addlinespace[1ex]\quad\quad High school" if _n == 25
	replace var = "\quad\quad Some college" if _n == 26
	replace var = "\quad\quad College+" if _n == 27
	replace var = "\addlinespace[1ex]\quad\emph{Employment and income}" if _n == 28
	replace var = "\addlinespace[1ex]\quad\quad Unemployment rate" if _n == 29
	replace var = "\quad\quad Median household income" if _n == 30
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 31
	order var b1 b4 b2 b5 b3 b6 b7
	
	texsave using "${results}/Table_A5.tex", nofix size(footnotesize) nonames frag replace ///
		headerlines("& \multicolumn{6}{c}{By altruism group} &" "\cmidrule(lr){2-7} \addlinespace[-2ex]" ///
			    "& \multicolumn{2}{c}{Low} & \multicolumn{2}{c}{Medium} & \multicolumn{2}{c}{High} & {P-value}" ///
			    "\cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7} \addlinespace[-2ex]" ///
			    "&{Mean}&{SD}&{Mean}&{SD}&{Mean}&{SD}&\mbox{(1) vs. (5)}" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}")  
			    
*------------------------------ Table A6 -----------------------------*

use "${inter}/provider_categorized.dta", clear 

	* Extract provider characteristics
	* - 6,080 providers (2.45%) unmatched in master
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(using matched) 
	replace bins_q3 = 4 if bins_q3 == .
	
	save `temp1', replace 
	
	*----- PHYSICIAN CHARS ----*
	
	* Only keep physicians 
	keep if flag_MD == 1 
	
	* Create desired variables
	* - Medical school: non-missing for 843,851 physicians (94.13%)
	* - Gender: non-missing for 667,566 physicians (74.47%)
	gen med_US = rank != "Foreign" 
	gen med_rank_share = rank != "Unranked" & rank != "Foreign"
	foreach v in US rank_share {
		replace med_`v' = . if region == 112
	}
	gen age = 2010 - birth_year 
	gen exper = 2010 - grad_year
	gen female = gender - 1
	save `temp2', replace
	
	* Average by group
	collapse (sum) n_prov_MD = flag_MD (mean) age female exper med_US med_rank_share rank_n, by(bins_q3) fast 
	save `temp3', replace 
	
	* Overall average
	use `temp2', clear 
	replace bins_q3 = 0 
	collapse (sum) n_prov_MD = flag_MD (mean) age female exper med_US med_rank_share rank_n, by(bins_q3) fast 
	append using `temp3'

	* Reshape
	gen order = 1 
	reshape wide n_prov_MD age female exper med_US med_rank_share rank_n, i(order) j(bins_q3)
	foreach v in n_prov_MD age female exper med_US med_rank_share rank_n {
		forvalues i = 0/4 {
			if "`v'" == "female" | "`v'" == "med_US" | "`v'" == "med_rank_share" {
				replace `v'`i' = `v'`i'*100
			}
			rename `v'`i' b`i'_`v'
			if "`v'" != "n_prov_MD" {
				tostring b`i'_`v', replace force format(%12.2f)
			}
			else {
				tostring b`i'_`v', replace force format(%12.0fc)
			}
		}
	}
	reshape long b0 b1 b2 b3 b4, i(order) j(type) string
	drop order 

	* Adjust ordering
	gen order = _n 
	replace order = 1.5 if _n == 3
	replace order = 7.5 if _n == 6
	set obs 8
	replace order = 0.5 if _n == 8
	sort order 
	drop order type
	
	* Update naming
	gen var = ""
	replace var = "\midrule\addlinespace[1.5ex]\textbf{b. Physician characteristics}" if _n == 1
	replace var = "\addlinespace[1ex]\quad Average age" if _n == 2
	replace var = "\quad Percent female" if _n == 3
	replace var = "\quad Average experience" if _n == 4
	replace var = "\quad Percent medical school in U.S." if _n == 5
	replace var = "\quad Percent of U.S. trained ranked" if _n == 6
	replace var = "\quad Average U.S. medical school rank" if _n == 7
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of physicians" if _n == 8
	save`temp3', replace

	*------- SPECIALTIES ------*
	
	use `temp1', clear 
	
	gen spec_group = ""
	replace spec_group = "General" if flag_GP == 1 
	replace spec_group = "Surgical" if medspec_short == "SR" | medspec_short == "SO" 
	replace spec_group = "Medical" if flag_MD == 1 & spec_group == ""
	
	gen prov_type = ""
	replace prov_type = "MD" if flag_MD == 1
	replace prov_type = "nonMD" if flag_MD == 0 
	
	foreach spec in General Medical Surgical {
		gen perc`spec' = spec_group == "`spec'"
	}
	foreach type in MD nonMD {
		gen perc`type' = prov_type == "`type'"
	}
	gen n_prov = 1
	save `temp1', replace
	
	* Percent of altruism grouping 
	collapse (mean) perc*, by(bins_q3) fast 
	save `temp2', replace 

	use `temp1', clear 
	replace bins_q3 = 0 
	collapse (mean) perc*, by(bins_q3) fast 
	append using `temp2'
	
	gen order = 1 
	reshape wide percMD percGeneral percMedical percSurgical percnonMD, i(order) j(bins_q3)
	foreach v in percMD percGeneral percMedical percSurgical percnonMD {
		forvalues i = 0/4 {
			replace `v'`i' = `v'`i'*100
			rename `v'`i' b`i'_`v'
			tostring b`i'_`v', replace force format(%12.2f)
		}
	}
	reshape long b0 b1 b2 b3 b4, i(order) j(type) string
	drop order 
	save `temp2', replace

	* Percent of provider type
	use `temp1', clear
	collapse (sum) percprov = n_prov perc*, by(bins_q3) fast 
	reshape long perc, i(bins_q3) j(type) string
	reshape wide perc, i(type) j(bins_q3) 
	
	gen perc0 = perc1 + perc2 + perc3 + perc4
	save `temp1', replace
	
	drop if type == "prov"
	foreach i in 1 2 3 4 0 {
		replace perc`i' = (perc`i'/perc0)*100 
		rename perc`i' b`i' 
		tostring b`i', replace force format(%12.2f) 
	}
	append using `temp2'
	save `temp2', replace 
	
	use `temp1', clear 
	keep if type == "prov"
	forvalues i = 0/4 {
		rename perc`i' b`i' 
		tostring b`i', replace force format(%12.0fc) 
	}
	append using `temp2'
	
	* Adjust ordering
	gen order = _n
	replace order = 1 if _n == 3 
	replace order = 6.66 if _n == 8
	replace order = 12 if _n == 1
	
	set obs 14
	replace order = 0.33 if _n == 12
	replace order = 0.66 if _n == 13
	replace order = 6.33 if _n == 14
	sort order 
	drop order type
	
	* Update naming
	gen var = ""
	replace var = "\textbf{a. Provider specialties}" if _n == 1
	replace var = "\addlinespace[1ex]\emph{Percent by provider type}" if _n == 2
	replace var = "\addlinespace[1ex]\quad Physicians" if _n == 3
	replace var = "\quad\quad General practice" if _n == 4
	replace var = "\quad\quad Medical specialties" if _n == 5
	replace var = "\quad\quad Surgical specialties" if _n == 6
	replace var = "\quad Non-physician providers" if _n == 7
	replace var = "\addlinespace[1ex]\emph{Percent by altruism group}" if _n == 8
	replace var = "\addlinespace[1ex]\quad Physicians" if _n == 9
	replace var = "\quad\quad General practice" if _n == 10
	replace var = "\quad\quad Medical specialties" if _n == 11
	replace var = "\quad\quad Surgical specialties" if _n == 12
	replace var = "\quad Non-physician providers" if _n == 13
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Number of providers" if _n == 14
	
	append using `temp3'
	order var b0 b1 b2 b3 b4
	
	texsave using "${results}/Table_A6.tex", nofix nonames size(footnotesize) frag replace ///
		headerlines("& & \multicolumn{4}{c}{By altruism group}" "\cmidrule(lr){3-6} \addlinespace[-2ex]" ///
			    "& {All} & {Low} & {Medium} & {High} & {Uncategorized}" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}")  
				
*------------------------------ Table A7 -----------------------------*

use `alt_mort', clear 
keep if year == 2014

	* Drops 5 (0.69%) commuting zones
	drop if alt_nmi_main == 0 
	
	* Save standard deviation of independent variables
	foreach v in share_low_main share_med_main pc_OP {
		sum `v'
		local SD_`v' = `r(sd)' 
	}

	* Regressions
	local append replace	
	foreach v in rxopioid drugs {
		
		reg pc_`v' share_low_main share_med_main [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_ncon, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `append'
		if "`v'" == "rxopioid" {
			local append append
		}
		
		reg pc_`v' share_low_main share_med_main `demo' [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_demo, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
		
		reg pc_`v' share_low_main share_med_main `demo' `econ' [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_econ, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
			
		reg pc_`v' share_low_main share_med_main `demo' `econ' pc_OP [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_op, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append	
	}
	
	use `temp1', clear 
	keep if strpos(var,"share") != 0 | strpos(var,"pc") != 0 | strpos(var,"N") != 0 | strpos(var,"r2") != 0
	save `temp1', replace 
	
	* Merge in mean dependent variables
	use `alt_mort', clear
	keep if year == 2014
	gen var = "Mean dependent variable"
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon demo econ op {
			gen `v1'_`v2' = pc_`v1'
		}
	}
	collapse (mean) rxopioid* drugs* [aw=alt_nmi_main], by(var) fast
	
	set obs 6
	replace var = "SD share low altruism" if _n == 2
	replace var = "SD share medium altruism" if _n == 3
	replace var = "SD opioids per capita" if _n == 4 
	replace var = "\addlinespace[1ex] Demographic controls" if _n == 5 
	replace var = "Socioeconomic controls" if _n == 6
	
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon demo econ op {
			replace `v1'_`v2' = `SD_share_low_main' if _n == 2
			replace `v1'_`v2' = `SD_share_med_main' if _n == 3
			replace `v1'_`v2' = `SD_pc_OP' if _n == 4
			tostring `v1'_`v2', format(%8.3fc) replace force
			replace `v1'_`v2' = "" if `v1'_`v2' == "."
		}
		replace `v1'_demo = "X" if _n == 5
		replace `v1'_econ = "X" if _n == 5 | _n == 6
		replace `v1'_op = "X" if _n == 5 | _n == 6 
	}
	append using `temp1'
	
	* Reformat table 
	gen n = _n
	replace n = 12.33 if n == 5
	replace n = 12.66 if n == 6
	replace n = 14.25 if n == 2
	replace n = 14.5 if n == 3
	replace n = 14.75 if n == 4
	replace n = 15 if n == 1 
	sort n 
	drop n 

	replace var = "" if strpos(var,"_stderr") != 0
	replace var = "Share low altruism" if _n == 1
	replace var = "Share medium altruism" if _n == 3
	replace var = "Opioid prescriptions per capita" if _n == 5
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Observations" if _n == 9
	replace var = "$ R^2$" if _n == 10
	
	texsave using "${results}/Table_A7.tex", nofix size(footnotesize) nonames frag replace ///	
		headerlines("{Fatal overdoses per 10,000:} & \multicolumn{4}{c}{Prescription opioids} & \multicolumn{4}{c}{All drugs}" ///
			    "\cmidrule(lr){2-5}\cmidrule(lr){6-9}\addlinespace[-2ex]" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}")  
								
*------------------------------ Table A8 -----------------------------*

local max1 = 0.8
local max2 = 1 

use `alt_mort', clear 
keep if year == 2014

	* Drops 5 (0.69%) commuting zones
	drop if alt_nmi_main == 0 
	
	* Save standard deviation of independent variables
	foreach v in share_low_main share_med_main pc_OP {
		sum `v'
		local SD_`v' = `r(sd)' 
	}

	* Regressions
	local append replace	
	foreach v in rxopioid drugs {
	
		reg pc_`v' share_low_main share_med_main [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_ncon, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `append'
		if "`v'" == "rxopioid" {
			local append append
		}
			
		reg pc_`v' share_low_main share_med_main `demo' `econ' pc_OP [aw=alt_nmi_main], robust
		regsave using `temp1', table(`v'_con, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
		forvalues i = 1/2 {
			psacalc delta share_low_main, rmax(`max`i'')
			local `v'_con`i' = round(`r(delta)',0.01)
		}
		
		areg pc_`v' share_low_main share_med_main `demo' `econ' pc_OP [aw=alt_nmi_main], absorb(czone_state) robust
		regsave using `temp1', table(`v'_fes, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
		forvalues i = 1/2 {
			psacalc delta share_low_main, rmax(`max`i'')
			local `v'_fes`i' = round(`r(delta)',0.01)
		}
	}
	
	use `temp1', clear 
	keep if strpos(var,"share") != 0 | strpos(var,"pc") != 0 | strpos(var,"N") != 0 | strpos(var,"r2") != 0
	save `temp1', replace 
	
	* Merge in mean dependent variables
	use `alt_mort', clear
	keep if year == 2014
	gen var = "Mean dependent variable"
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon con fes {
			gen `v1'_`v2' = pc_`v1'
		}
	}
	collapse (mean) rxopioid* drugs* [aw=alt_nmi_main], by(var) fast
	
	set obs 8
	replace var = "SD share low altruism" if _n == 2
	replace var = "SD share medium altruism" if _n == 3
	replace var = "SD opioids per capita" if _n == 4 
	replace var = "\addlinespace[1ex] Socio-demographic controls" if _n == 5 
	replace var = "State fixed effects" if _n == 6 
	replace var = "$ \delta$: $ R_{max}$ = 0.8" if _n == 7 
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] $ \delta$: $ R_{max}$ = 1" if _n == 8
	
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon con fes {
			replace `v1'_`v2' = `SD_share_low_main' if _n == 2
			replace `v1'_`v2' = `SD_share_med_main' if _n == 3
			replace `v1'_`v2' = `SD_pc_OP' if _n == 4
			tostring `v1'_`v2', format(%8.3fc) replace force
			replace `v1'_`v2' = "" if `v1'_`v2' == "."
		}
		foreach v2 in con fes {
			replace `v1'_`v2' = "X" if _n == 5 
			forvalues i = 1/2 {
				replace `v1'_`v2' = "``v1'_`v2'`i''" if length("``v1'_`v2'`i''") == 4 & _n == 6 + `i'
				replace `v1'_`v2' = "0" + "``v1'_`v2'`i''" if length("``v1'_`v2'`i''") == 3 & _n == 6 + `i'
			}
		}	
		replace `v1'_fes = "X" if _n == 6		
	}
	append using `temp1'
	
	* Reformat table 
	gen n = _n
	replace n = 14.33 if n == 5
	replace n = 14.66 if n == 6
	replace n = 16.25 if n == 2
	replace n = 16.5 if n == 3
	replace n = 16.75 if n == 4
	replace n = 17 if n == 1 
	replace n = 17.25 if n == 8
	replace n = 17.5 if n == 7
	sort n 
	drop n 

	replace var = "" if strpos(var,"_stderr") != 0
	replace var = "Share low altruism" if _n == 1
	replace var = "Share medium altruism" if _n == 3
	replace var = "Opioid prescriptions per capita" if _n == 5
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Observations" if _n == 9
	replace var = "$ R^2$" if _n == 10	
	
	texsave using "${results}/Table_A8.tex", nofix size(footnotesize) nonames frag replace ///	
		headerlines("{Fatal overdoses per 10,000:} & \multicolumn{3}{c}{Prescription opioids} & \multicolumn{3}{c}{All drugs}" ///
			    "\cmidrule(lr){2-4}\cmidrule(lr){5-7}\addlinespace[-2ex]" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}")  

*------------------------------ Table A9 -----------------------------*

foreach type in c2 c1 {
	
	use `alt_mort', clear 
	keep if year == 2014
	
	* Save standard deviation of independent variables
	drop if alt_nmi_`type' == 0 
	foreach v in share_low_`type' pc_OP {
		sum `v'
		local SD_`v' = `r(sd)'
	}

	* Regressions
	local append replace
	foreach v in rxopioid drugs {
		
		reg pc_`v' share_low_`type' [aw=alt_nmi_`type'], robust
		regsave using `temp1', table(`v'_ncon, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `append'
		if "`v'" == "rxopioid" {
			local append append
		}

		reg pc_`v' share_low_`type' `demo' `econ' [aw=alt_nmi_`type'], robust
		regsave using `temp1', table(`v'_con, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
		
		reg pc_`v' share_low_`type' `demo' `econ' pc_OP [aw=alt_nmi_`type'], robust
		regsave using `temp1', table(`v'_op, asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
	}

	use `temp1', clear 
	keep if strpos(var,"share") != 0 | strpos(var,"pc") != 0 | strpos(var,"N") != 0 | strpos(var,"r2") != 0 
	save `temp1', replace 
	
	* Merge in mean dependent variables
	use `alt_mort', clear
	keep if year == 2014
	
	gen var = "Mean dependent variable"
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon con op {
			gen `v1'_`v2' = pc_`v1'
		}
	}
	collapse (mean) rxopioid* drugs* [aw=alt_nmi_`type'], by(var) fast
	
	set obs 5
	if "`type'" == "c1" {
		replace var = "\textbf{a. Months surrounding only}" if _n == 2
	}
	if "`type'" == "c2" {
		replace var = "\midrule\addlinespace[1.5ex] \textbf{b. Year-on-year only}" if _n == 2 
	}
	replace var = "SD share low altruism" if _n == 3
	replace var = "SD opioids per capita" if _n == 4 
	replace var = "\addlinespace[1ex] Socio-demographic controls" if _n == 5 
	foreach v1 in rxopioid drugs {
		foreach v2 in ncon con op {
			replace `v1'_`v2' = `SD_share_low_`type'' if _n == 3
			replace `v1'_`v2' = `SD_pc_OP' if _n == 4
			tostring `v1'_`v2', format(%8.3fc) replace force
			replace `v1'_`v2' = "" if _n == 2
			
		}
		replace `v1'_ncon = "" if _n == 5
		replace `v1'_con = "X" if _n == 5
		replace `v1'_op = "X" if _n == 5
	}
	append using `temp1'
	
	* Reformat table 
	gen n = _n
	replace n = 0.5 if n == 2
	replace n = 9.25 if n == 5
	replace n = 11.33 if n == 3
	replace n = 11.66 if n == 4
	replace n = 12 if n == 1 
	sort n 
	drop n 

	replace var = "" if strpos(var,"_stderr") != 0
	replace var = "\addlinespace[1.5ex] Share low altruism" if _n == 2
	replace var = "Opioid prescriptions per capita" if _n == 4
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Observations" if _n == 7
	replace var = "$ R^2$" if _n == 8

	if "`type'" != "c2" {
		append using `temp2'
	}
	save `temp2', replace 
}

	use `temp2', clear
	texsave using "${results}/Table_A9.tex", nofix size(footnotesize) nonames frag replace ///	
		headerlines("{Fatal overdoses per 10,000:} & \multicolumn{3}{c}{Prescription opioids} & \multicolumn{3}{c}{All drugs}" ///
			    "\cmidrule(lr){2-4}\cmidrule(lr){5-7}\addlinespace[-2ex]" "&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}")  
			
*----------------------------- Table A10 -----------------------------*	

local append replace
foreach misuse in nibrs nsduh_sm nsduh_all nvss {

	use `polar', clear
	keep if tot_OP_nibrs != .
	
	* Change naming for NIBRS 
	if "`misuse'" == "nibrs" {
		drop tot_OP n_prov
		rename tot_OP_nibrs tot_OP
		rename n_prov_nibrs n_prov
	}
	
	* Standardize measure of misuse
	egen misuse = std(`misuse')

	* Construct interaction terms
	foreach v in 1 3 {
		gen alt`v' = alt == `v'
		gen inter`v' = alt`v'*misuse
	}
	
	reg tot_OP alt1 inter1 inter3 [aw=n_prov], cluster(czone)
	regsave using `temp1', table(`misuse', asterisk(10 5 1) parentheses(stderr) format(%8.2fc)) `append'
	lincom inter1 - inter3
	local pval = round(2*ttail(r(df),abs(r(estimate)/r(se))),0.001)	
	
	use `temp1', clear 
	replace `misuse' = "`pval'" if _n == 10
	save `temp1', replace
	
	local append append
}

	* Reformat table
	use `temp1', clear
	
	replace var = "pval" if _n == 10
	keep if (strpos(var,"inter") != 0 & strpos(var,"_coef") != 0) | _n == 10
	sxpose, clear firstnames
	
	replace pval = "0" + pval
	replace pval = "<0.001" if pval == "00"
	
	gen var = ""
	replace var = "Prescription opioid seizures per capita (NIBRS)" if _n == 1
	replace var = "\addlinespace[1ex]Prescription opioid misuse rate: secondary market (NSDUH)" if _n == 2 
	replace var = "\addlinespace[1ex]Prescription opioid misuse rate: any source (NSDUH)" if _n == 3 
	replace var = "\addlinespace[1ex]Fatal prescription opioid overdoses per capita (NVSS)" if _n == 4
	 
	order var inter1 inter3 pval
	local i = 1 
	foreach v in inter1 inter3 pval {
		label var `v' "(`i')" 
		local i = `i' + 1
	}
	label var var "Standardized measure of misuse"
	
	texsave using "${results}/Table_A10.tex", nofix size(footnotesize) varlabels frag replace ///
		headerlines(" & Low altruism & High altruism & P-value")

*----------------------------- Table A11 -----------------------------*	
	
use `markets', clear

keep if czone == 0 | czone == 39400 

	foreach v in misuse_sm beta1_GP beta2_GP beta3_GP beta4_GP {
		replace `v' = `v'*100
	}
	
	drop OP_* n_* pop distance
	gen n = 1
	
	reshape wide R tau_o tau_d misuse_sm pain price pres_pc prov_pc beta1 beta2 beta3 beta4, i(n) j(czone)
	foreach z in 0 39400 {
		
		if `z' == 0 {
			local name = "US"
		}
		if `z' == 39400 {
			local name = "ST"
		}
		
		local i = 1
		foreach v in tau_o price R pain misuse_sm tau_d pres_pc prov_pc beta1_GP beta2_GP beta3_GP beta4_GP {
			rename `v'`z' `name'`i'
			local i = `i' + 1
		}
	}
	reshape long US ST, i(n) j(var)
	drop n 
	
	set obs 15
	gen order = . 
	replace order = 1 if _n == 13 
	replace order = 2 if var == 4
	replace order = 3 if var == 6
	replace order = 4 if var == 1
	replace order = 5 if _n == 14
	replace order = 6 if var == 3
	replace order = 7 if var == 8
	replace order = 8 if var == 9 
	replace order = 9 if var == 10
	replace order = 10 if var == 11 
	replace order = 11 if var == 12 
	replace order = 12 if _n == 15
	replace order = 13 if var == 7 
	replace order = 14 if var == 5 
	replace order = 15 if var == 2
	sort order
	
	gen label = ""
	replace label = "\textbf{a. Demand-side factors}" if _n == 1 
	replace label = "\addlinespace[1ex] \quad Average pain level" if _n == 2
	replace label = "\quad Office visit copay" if _n == 3 
	replace label = "\quad Prescription copay" if _n == 4 
	replace label = "\addlinespace[1.5ex]\textbf{b. Supply-side factors}" if _n == 5 
	replace label = "\addlinespace[1ex] \quad Office visit revenue" if _n == 6
	replace label = "\quad GPs per 1,000 people" if _n == 7 
	replace label = "\quad Percent low altruism" if _n == 8 
	replace label = "\quad Percent medium altruism" if _n == 9 
	replace label = "\quad Percent high altruism" if _n == 10 
	replace label = "\quad Percent uncategorized" if _n == 11 
	replace label = "\addlinespace[1.5ex]\textbf{c. Equilibrium outcomes}" if _n == 12 
	replace label = "\addlinespace[1ex] \quad Opioids (from GPs) per capita" if _n == 13
	replace label = "\quad Secondary market misuse rate" if _n == 14
	replace label = "\quad Secondary market price" if _n == 15
	drop order var 
	order label US ST
	
	foreach v in US ST {
		tostring `v', replace force format(%08.3g)
		replace `v' = "" if `v' == "."
 		replace `v' = "0"+`v' if strpos(`v',".") == 1
		replace `v' = `v'+".0" if length(`v') == 2
		replace `v' = `v'+"0" if length(`v') == 3 & strpos(`v',".") != 0 
		replace `v' = `v'+"0" if length(`v') == 4 & strpos(`v',"0") == 1
	}

	texsave using "${results}/Table_A11.tex", nofix size(footnotesize) nonames frag replace ///
		headerlines("& \multicolumn{1}{c}{United States} & \multicolumn{1}{c}{Seattle}" ///
		"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\addlinespace[-2ex]" "&{(1)}&{(2)}") 
		
*----------------------------- Table A12 -----------------------------*		
* NOTE: Must first run clean_NSDUH.do and clean_NHIS.do to extract r2 from full model

* Predicting misuse
use "${inter}/NSDUH_clean_0614.dta", clear
keep if year == 2014
	
	* Consider 18+ for comparability with NHIS
	drop if age_12to17 == 1
	
	* Adjust categories to match NHIS
	rename age_26to34 age_25to34
	
	* Main outcome variables
	gen misuse_perc_sm = source_cat == 2
	replace misuse_perc_sm = misuse_perc_sm*100
			
	replace misuse_yr = misuse_yr*100
	rename misuse_yr misuse_perc_all 
		
	local replace "replace"
	foreach type in all sm {
	
		* Standardize outcome variables
		egen std_`type' = std(misuse_perc_`type')
	
		reg std_`type' male age_25to34 age_35to49 age_50to64 age_65plus ///
			race_white race_black race_hisp educ_hsg educ_scol educ_cplus ///
			inc_50to74 inc_75plus emp_yes emp_no mar_yes mar_oth hi_yes, robust
			
		regsave using `temp1', table(misuse_`type', asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) `replace'
		local replace "append"
	}

* Predicting pain
use "${inter}/NHIS_clean_2014.dta", clear
	
	* Adjust categories to match NSDUH
	gen age_35to49 = age_35to44 == 1 | age_45to49 == 1
	gen age_50to64 = age_50to54 == 1 | age_55to64 == 1
	gen inc_75plus = inc_75to99 == 1 | inc_100plus == 1
	
	foreach type in any tot {
	
		* Standardize outcome variables
		egen std_`type' = std(pain_`type')
	
		reg std_`type' male age_25to34 age_35to49 age_50to64 age_65plus ///
			race_white race_black race_hisp educ_hsg educ_scol educ_cplus ///
			inc_50to74 inc_75plus emp_yes emp_no mar_yes mar_oth hi_yes, robust
			
		regsave using `temp1', table(pain_`type', asterisk(10 5 1) parentheses(stderr) format(%8.3fc)) append
	}
	
	use `temp1', clear
	
	* Drop the constant 
	drop if strpos(var,"cons") != 0 
	
	* Add r2 from full model 
	append using "${inter}/NHIS_NSDUH_R2.dta"
	
	* Reformat table
	gen order = _n
	set obs 47
	replace order = 0.5 if _n == 40
	replace order = 2.5 if _n == 41
	replace order = 10.5 if _n == 42
	replace order = 16.5 if _n == 43
	replace order = 22.5 if _n == 44
	replace order = 26.5 if _n == 45
	replace order = 30.5 if _n == 46
	replace order = 34.5 if _n == 47
	sort order
	
	replace var = "" if strpos(var,"_stderr") != 0
	replace var = "\emph{Sex}" if _n == 1
	replace var = "\addlinespace[1ex]\quad Male" if _n == 2
	replace var = "\emph{Age}" if _n == 4
	replace var = "\addlinespace[1ex]\quad 25--34" if _n == 5
	replace var = "\quad 35--49" if _n == 7
	replace var = "\quad 50--64" if _n == 9
	replace var = "\quad 65+" if _n == 11
	replace var = "\emph{Race/ ethnicity}" if _n == 13
	replace var = "\addlinespace[1ex]\quad White" if _n == 14
	replace var = "\quad Black" if _n == 16
	replace var = "\quad Hispanic" if _n == 18
	replace var = "\emph{Education}" if _n == 20
	replace var = "\addlinespace[1ex]\quad High school" if _n == 21
	replace var = "\quad Some college" if _n == 23
	replace var = "\quad College+" if _n == 25
	replace var = "\emph{Income}" if _n == 27
	replace var = "\addlinespace[1ex]\quad 50--74k" if _n == 28
	replace var = "\quad 75k+" if _n == 30
	replace var = "\emph{Employment}" if _n == 32
	replace var = "\addlinespace[1ex]\quad Employed" if _n == 33
	replace var = "\quad Unemployed" if _n == 35
	replace var = "\emph{Marital status}" if _n == 37
	replace var = "\addlinespace[1ex]\quad Married" if _n == 38
	replace var = "\quad Divorced" if _n == 40
	replace var = "\emph{Health insurance}" if _n == 42
	replace var = "\addlinespace[1ex]\quad Insured" if _n == 43
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Observations" if _n == 45
	replace var = "$ R^2$" if _n == 46 
	replace var = "\addlinespace[1ex]\hline\addlinespace[1ex] Full model: adjusted $ R^2$" if _n == 47
	drop order
	
	texsave using "${results}/Table_A12.tex", nofix nonames size(scriptsize) frag replace ///
		headerlines("& \multicolumn{2}{c}{Misuse} & \multicolumn{2}{c}{Pain}" ///
		"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \addlinespace[-2ex]" ///
		"& Overall & Secondary market & Any & Total" "&{(1)}&{(2)}&{(3)}&{(4)}")

***********************************************************************

log close

		

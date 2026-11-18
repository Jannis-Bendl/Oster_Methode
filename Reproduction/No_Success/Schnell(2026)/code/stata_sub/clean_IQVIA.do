***********************************************************************
*-------------------------- Prep IQVIA Data --------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Provider-month prescriptions (XPonent data)
   - monthly opioid counts
   - percent OxyContin
   - percent generic

b. Provider-month copays (XPonent data)
   - average monthly copay
   - average copay by product class 

c. Provider-month patient characteristics (XPonent data)
   - monthly percent in age, gender, insurance type cells

d. Provider characteristics (AMA Masterfile)
   - location information (practice address, county, czone, state)
   - specialty 
   - flag for consistent prescribing
   
e. Geographic aggregates (XPonent data)
   - county-month opioids
   
f. Provider-year co-prescribing of opioids + benzos (LRx data)

*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------ Define Directories -------------------------*
*---------------------------------------------------------------------*
	
	tempfile main 
	
*---------------------------------------------------------------------*
*-------------------------- Define Programs --------------------------*
*---------------------------------------------------------------------*	

cap program drop clean_products	
cap program define clean_products 

	replace product = "ANEXSIA" if product == "ANEXSIA 5" | product == "ANEXSIA 7.5"
	replace product = "COCET" if product == "COCET PLUS"
	replace product = "DARVOCET-N" if product == "DARVOCET-N 100" | product == "DARVOCET-N 50"
	replace product = "DILAUDID" if product == "DILAUDID-5" | product == "DILAUDID-HP"
	replace product = "HYDROMORPHONE HCL" if product == "HYDROMORPHONE HCL/NS"
	replace product = "LORCET" if product == "LORCET 10/650" | product == "LORCET PLUS" | product == "LORCET-HD"
	replace product = "LORTAB" if product == "LORTAB 10/500" | product == "LORTAB 2.5/500" | ///
	                              product == "LORTAB 5/500" | product == "LORTAB 7.5/500" | ///
								  product == "LORTAB (REFORM)" | product == "LORTAB 10/325" | ///
								  product == "LORTAB 5/325" | product == "LORTAB 7.5/325"
	replace product = "MORPHINE SULF" if product == "MORPHINE SULF PFS" | product == "MORPHINE SULF C-JECT" | product == "MORPHINE SULF/NS"
	replace product = "PANLOR" if product == "PANLOR DC" | product == "PANLOR SS"
	replace product = "ROXANOL" if product == "ROXANOL-100" | product == "ROXANOL-T"
	replace product = "ROXICODONE" if product == "ROXICODONE INTENSOL"
	replace product = "STADOL" if product == "STADOL NS"
	replace product = "STAGESIC" if product == "STAGESIC-10"
	replace product = "SYNALGOS DC" if product == "SYNALGOS-DC PAINPAK"
	replace product = "VICODIN" if product == "VICODIN ES" | product == "VICODIN HP"
	replace product = "XODOL" if product == "XODOL 10/300" | product == "XODOL 5/300" | product == "XODOL 7.5/300"

end 
	
***********************************************************************
*------------------ a. Provider-month prescriptions ------------------*
***********************************************************************

foreach y in "06" "07" "08" "09" "10" "11" "12" "13" "14" {

	use provider_id product year month sum_tot_scripts ///
	using "${raw_IMS}/OP/princeton_Opioid_yr20`y'.dta", clear
	
	clean_products
	collapse (sum) tot_OP = sum_tot_scripts, by(provider_id product year month) fast 
	
	* Merge in product info; all matched in master
	merge m:1 product using "${raw_IMS}/add_ons/products.dta", nogen keep(matched) keepusing(drug_OP generic)
	
	*------- OXYCONTIN -------*
	gen tot_oxy_brand = product == "OXYCONTIN"
	gen tot_oxy_gen = product == "OXYCODONE HCL ER"
				   
	*-------- GENERIC --------*
	gen tot_gen = generic == 1
	
	foreach v in oxy_brand oxy_gen gen {
		replace tot_`v' = tot_`v'*tot_OP
	}
	collapse (sum) tot*, by(provider_id year month) fast
	
	* Create date variable 
	destring year, replace 
	destring month, replace 
	gen date = ym(year, month)
	
	if "`y'" != "06" {
		append using "${inter}/provider_month_opioids_0614.dta"
	}
	save "${inter}/provider_month_opioids_0614.dta", replace
}

*------------------ Total over entire sample -------------------*

use "${inter}/provider_month_opioids_0614.dta", clear

	gen n_months = 1
	foreach v in tot_OP n_months {
		gen `v'_2014 = `v' if year == 2014
	}
	
	collapse (sum) tot* n_months*, by(provider_id) fast 
	
	* Create flag for consistent prescribers 
	gen flag_cons_2014 = n_months_2014 == 12
	
	save "${inter}/provider_total_opioids_0614.dta", replace

***********************************************************************
*---------------------- b. Provider-month copays ---------------------*
***********************************************************************
* NOTE: Totals in this file do not match elsewhere (total only for cells with non-missing copays)

foreach y in "06" "07" "08" "09" "10" "11" "12" "13" "14" {

	use provider_id product year month sum_tot_scripts avg_derived_copay ///
	using "${raw_IMS}/OP/princeton_Opioid_yr20`y'.dta", clear
	
	* Only keep observations with non-missing copays (otherwise quantities off for weighting)
	drop if avg_derived_copay == . 
	
	clean_products
	gen avg_copay_OP = avg_derived_copay*sum_tot_scripts
	collapse (sum) tot_OP = sum_tot_scripts avg_copay_OP, by(provider_id product year month) fast 
	
	* Merge in product info; all matched in master
	merge m:1 product using "${raw_IMS}/add_ons/products.dta", nogen keep(matched) keepusing(drug_OP)
	
	*------- OXYCONTIN -------*
	foreach v in tot avg_copay {
		gen `v'_oxy_brand = `v'_OP if product == "OXYCONTIN"
		gen `v'_oxy_gen = `v'_OP if product == "OXYCODONE HCL ER"
	}
	
	collapse (sum) tot* avg_copay*, by(provider_id year month) fast
	
	foreach v in OP oxy_brand oxy_gen {
		replace avg_copay_`v' = avg_copay_`v'/tot_`v'
	}

	* Create date variable 
	destring year, replace 
	destring month, replace 
	gen date = ym(year, month)
	
	if "`y'" != "06" {
		append using "${inter}/provider_month_copays_0614.dta"
	}
	compress
	save "${inter}/provider_month_copays_0614.dta", replace
}

***********************************************************************
*------------------ c. Provider-month patient chars ------------------*
***********************************************************************

foreach y in "06" "07" "08" "09" "10" "11" "12" "13" "14" {

	use provider_id year month sum_tot_scripts payment_type patient_gender patient_age ///
	using "${raw_IMS}/OP/princeton_Opioid_yr20`y'.dta", clear
	
	collapse (sum) tot_OP = sum_tot_scripts, by(provider_id year month payment_type patient_gender patient_age) fast
	
	*-------- GENDER ---------*
	gen perc_male = tot_OP if patient_gender == "M"
	gen perc_female = tot_OP if patient_gender == "F"
	gen perc_sex_mi = tot_OP if patient_gender == "U"
	
	*--------- AGES ----------*
	gen perc_0002 = tot_OP if patient_age == "00-02"
	gen perc_0309 = tot_OP if patient_age == "03-09"
	gen perc_1019 = tot_OP if patient_age == "10-19"
	gen perc_2039 = tot_OP if patient_age == "20-39"
	gen perc_4059 = tot_OP if patient_age == "40-59"
	gen perc_6064 = tot_OP if patient_age == "60-64"
	gen perc_6574 = tot_OP if patient_age == "65-74"
	gen perc_7584 = tot_OP if patient_age == "75-84"
	gen perc_85plus = tot_OP if patient_age == "85+"
	gen perc_age_mi = tot_OP if patient_age == "UNK"
	
	*----- PAYMENT TYPES -----*
	gen perc_cash = tot_OP if payment_type == 1 
	gen perc_medicaid = tot_OP if payment_type == 2
	gen perc_third = tot_OP if payment_type == 3 & patient_age != "65-74" & patient_age != "75-84" & patient_age != "85+"
	gen perc_medicare = tot_OP if payment_type == 3 & (patient_age == "65-74" | patient_age == "75-84" | patient_age == "85+")

	collapse (sum) tot_OP perc*, by(provider_id month year) fast 
	foreach v in male female sex_mi 0002 0309 1019 2039 4059 6064 6574 7584 85plus age_mi cash medicaid third medicare {
		replace perc_`v' = perc_`v'/tot_OP
	}
	drop tot_OP 	

	* Create date variable 
	destring year, replace 
	destring month, replace 
	gen date = ym(year, month)
	
	if "`y'" != "06" {
		append using "${inter}/provider_month_patientchars_0614.dta"
	}
	compress
	save "${inter}/provider_month_patientchars_0614.dta", replace
}

***********************************************************************
*-------------------- d. Provider characteristics --------------------*
***********************************************************************

use provider_id provider_address1 provider_city provider_state provider_zip provider_address_type ///
	provider_specialty provider_status provider_grad_year provider_med_school provider_num ///
	using "${raw_IMS}/princeton_AMA_PROVIDER.dta", clear

	foreach v in city state zip address_type specialty status address grad_year {
		rename provider_`v' `v'
	}
	destring grad_year, replace
	
	* Only keep opioid prescribers (1,486,263 providers [91.33%])
	merge 1:1 provider_id using "${inter}/provider_total_opioids_0614.dta", nogen keep(matched) keepusing(tot_OP* flag_cons*)
	erase "${inter}/provider_total_opioids_0614.dta"
		
	* Create flag for "clean" sample
	* - Active physicians with non-missing office practice address
	gen flag_clean = 1 
		
	*------ SPECIALTIES ------*
	
	* Drop prescribers with missing specialty
	* - 5,646 providers (0.38%) accounting for 0.02% of prescriptions 
	merge m:1 specialty using "${raw_IMS}/add_ons/specialty_recode.dta", nogen keep(matched) keepusing(medspec*)
	
	* Create flag for fields that do not require MD/DO
	* - Non-MD/ DO: 544,499 providers (36.64%) accounting for 17.54% of prescriptions 
	*   [APRNs/PAs: 10.00%; Dentists: 6.54%; OHP: 0.89%; Vets: 0.12%]
	gen flag_MD = medspec_cat != "APRN/PA" & medspec_cat != "Dentist" & medspec_cat != "Veterinarian"  ///
		 & medspec_cat != "Other Healthcare Professional" 
	replace flag_clean = 0 if flag_MD == 0
	
	* Create flag for GPs
	gen flag_GP = medspec_cat == "General & Family Practice" | medspec_cat == "Internal Medicine"

	*------- LOCATIONS -------*	
	
	* Drop providers with missing address 
	* - 350 providers (0.02%) 
	drop if address == "" 
	
	* Drop providers located in AE/AP/GU/MP/PR/VI
	* - 578 providers (0.04%) 
	drop if state == "AE" | state == "AP" | state == "GU" | state == "MP" | state == "PR" | state == "VI" 
	
	* Merge in geocoded addresses
	* - 13,941 addresses (4.05%) not in geocoded file
	* - 45,532 providers (3.08%) accounting for 2.49% of prescriptions unmatched 
	destring zip, replace
	merge m:1 address city state zip using "${raw_IMS}/add_ons/GIS_addresses.dta", keep(master matched) 
	replace flag_clean = 0 if _merge == 1 
	drop _merge 
	
	* Merge in state_fips; all matched
	statastates, abbrev(state) nogen
	drop address city state state_name
	
	* Merge in commuting zones 
	* - 9 counties (0.29%) not in crosswalk
	* - 57,492 providers (3.89%) accounting for 2.93% of prescriptions unmatched
	merge m:1 county_fips using "${raw_public}/geo/cw_cty_czone.dta", keep(master matched)
	replace flag_clean = 0 if _merge == 1 
	drop _merge 
	
	*---- MEDICAL SCHOOLS ----*
	
	replace provider_med_school = "UNIVERSITY OF CALIFORNIA IRVINE COLLEGE OF MEDICINE" if ///
	        provider_med_school == "UNIV OF CA, IRVINE, CA COLL OF MED, IRVINE CA" 
	replace provider_med_school = "DREXEL UNIVERSITY COLLEGE OF MEDICINE" if ///
	        provider_med_school == "MEDICAL COLLEGE OF PENNSYLVANIA" | provider_med_school == "HAHNEMANN UNIVERSITY SCHOOL OF MEDICINE" 
	
	* 598,494 providers is master (40.45) unmatched
	* - All but 55,347 physicians (5.92) matched 
	merge m:1 provider_med_school using "${raw_IMS}/add_ons/med_rankings.dta", keep(master matched)
	
	replace med_rank_cat = 22 if _merge == 1 
	replace region = 112 if _merge == 1 
	drop _merge provider_med_school
	
	*--------- GENDER --------*
	* Only in newer version of AMA Master File 
	* Link by medical education number (formatted differently in new file)
	
	destring provider_num, replace 
	rename provider_num ME_NBR
	save `main', replace 
	
	use ME_NBR birth_year gender using "${raw_LRx}/AMA_Master/AMA_Master.dta", clear 
	replace ME_NBR = floor(ME_NBR/10)
	merge 1:m ME_NBR using `main', nogen keep(using matched)
	drop ME_NBR

	*------- CLEANING --------*

	* Flag active providers
	replace flag_clean = 0 if status != "Active"
	drop status 
	
	* Flag providers with work address 
	replace flag_clean = 0 if address_type != "Office" & address_type != "Both"
	
	save "${inter}/provider_chars_cleaned.dta", replace

***********************************************************************
*---------------------- e. Geographic aggregates ---------------------*
***********************************************************************

use provider_id year month date tot_OP using "${inter}/provider_month_opioids_0614.dta", clear

	merge m:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched)
	
	* Keep if geocoded work address not missing
	keep if address_type == "Office" | address_type == "Both"
	keep if county_fips != . 
	
	* Collapse to county-month level
	gen n_providers = 1
	collapse (sum) tot_OP n_providers, by(county_fips month year date) fast 
	tostring county_fips, replace force format(%05.0f)
	save `main', replace 
	
	* Add county population (all matched in IMS data except 02158)
	use "${inter}/county_year_pop_0614.dta", clear 
	expand 12 
	bys county_fips year: gen month = _n 
	gen date = ym(year, month)
	merge 1:1 county_fips month year using `main', nogen keep(master matched)
	foreach v in tot_OP n_providers {
		replace `v' = 0 if `v' == . 
	}
	
	save "${inter}/county_month_opioids_0614.dta", replace

***********************************************************************
*--------------------------- f. LRx data ---------------------------*
***********************************************************************

foreach y in "06" "07" "08" "09" "10" "11" "12" "13" "14" {

	* Opioids at patient-provider-day level
	use SVC_DT PATIENT_ID PROVIDER_ID using "${raw_LRx}/OP/OP_FactRx20`y'.dta", clear

	gen tot_LRx = 1	
	collapse (sum) tot_LRx, by(SVC_DT PATIENT_ID PROVIDER_ID) fast
	save `main', replace
	
	* Patient-provider-days with benzo prescriptions
	use SVC_DT PATIENT_ID PROVIDER_ID PRODUCT_ID using "${raw_LRx}/AA/AA_FactRx20`y'.dta", clear
	merge m:1 PRODUCT_ID using "${raw_LRx}/AA/AA_Product.dta", keepusing(USC_CD) nogen keep(matched)
	keep if USC_CD == 64610
	drop PRODUCT_ID USC_CD 
	
	gen tot_benzo = 1 
	collapse (sum) tot_benzo, by(SVC_DT PATIENT_ID PROVIDER_ID) fast
	
	* Instances of co-prescribing
	merge 1:1 SVC_DT PATIENT_ID PROVIDER_ID using `main', keep(using matched)
	gen tot_copres = _merge == 3 
	gen mean_copres = tot_copres
	collapse (mean) mean_copres (sum) tot_LRx tot_copres, by(PROVIDER_ID) fast 
	
	gen year = 20`y'
	if "`y'" != "06" {
		append using "${inter}/provider_year_LRx_0614.dta"
	}
	if "`y'" == "14" {
	
		* Need legacy IMS ID for link 
		* - All matched in master
		merge m:1 PROVIDER_ID using "${raw_LRx}/All_Provider.dta", keepusing(IMS_RXER_ID) nogen keep(matched)
		
		* Drop if missing legacy ID 
		* - 196,403 provider-year observations (2.08%) accounting for 2.08% of opioid prescriptions
		drop PROVIDER_ID 
		rename IMS_RXER_ID provider_id
		drop if provider_id == . 
		order provider_id year tot_LRx tot_copres mean_copres
	}
	save "${inter}/provider_year_LRx_0614.dta", replace
}
	

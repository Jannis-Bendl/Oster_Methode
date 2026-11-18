***********************************************************************
*---------------------- Prep Reimbursement Data ----------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Create state-specific Medicare rates
   - Import raw Medicare file 
   - Create national CPT shares
   - Create state-specific CPT reimbursement rates
   -> State-specific Medicare reimbursement rates
   
b. Create state-specific Medicaid rates
   - Use state-specific Medicare to Medicaid FFS payment ratios
   - Use state-specific Medicaid FFS to MC payment ratios
   - Weight by state-specific MC penetration 
   -> State-specific Medicaid rates

c. Create state-specific private rates
   - Use Medicaid FFS to private payment ratios
   -> State-specific private rates
   
d. Create provider-specific reimbursement rates
   - Combine state-insurer reimbursement rates with patient composition across providers
   -> Provider-specific reimbursements
   
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*

	tempfile main

***********************************************************************
*-------------- a. Create state-specific Medicare rates --------------*
***********************************************************************

*-------------------------- Read in raw data -------------------------*

import delimited using "${raw_public}/reimbursement/Medicare_Provider_Util_Payment_PUF_CY2014.txt", clear

	keep nppes_provider_state nppes_provider_country provider_type medicare_participation_indicator ///
	     hcpcs_code line_srvc_cnt average_medicare_allowed_amt 
	
	* Only keep physicians participating in Medicare
	* - Drops 3,731 observations (0.04%)
	drop if medicare_participation_indicator == "N"
	drop medicare_participation_indicator
	
	* Only keep those practicing in the US 
	* - Drops 402 observations (0.00%)
	keep if nppes_provider_country == "US"
	drop nppes_provider_country
	
	* Drop US territories and unknown 
	* - Drops 35,358 observations (0.38%)
	statastates, abbrev(nppes_provider_state)
	keep if _merge == 3 
	drop nppes_provider_state state_name _merge 
	
	* Create flag for GPs
	* - 2,173,752 observations (23.43%)
	gen flag_GP = provider_type == "Family Practice" | provider_type == "General Practice" | provider_type == "Internal Medicine"
	
	* Create flag for office visit CPT codes (99201-99205, 99211-99215)
	* - 1,550,489 observations (16.71%)
	gen flag_EM = hcpcs_code == "99201" | hcpcs_code == "99202" | hcpcs_code == "99203" | ///
	              hcpcs_code == "99204" | hcpcs_code == "99205" | hcpcs_code == "99211" | ///
		      hcpcs_code == "99212" | hcpcs_code == "99213" | hcpcs_code == "99214" | ///
		      hcpcs_code == "99215"
			 
	save "${inter}/Medicare_clean_2014.dta", replace

*-------------------- State-specific reimbursement -------------------*
* Combine CPT shares with state-specific reimbursement rates per CPT code

	*------------- CPT shares -------------*
	
	use "${inter}/Medicare_clean_2014.dta", clear 
	
	keep if flag_GP == 1 & flag_EM == 1 
	collapse (sum) perc_cpt=line_srvc_cnt, by(hcpcs_code) fast 
	egen tot = sum(perc_cpt)
	replace perc_cpt = perc_cpt/tot
	drop tot 
	save `main', replace 
	
	*---- State-specific reimbursement ----*
	
	use "${inter}/Medicare_clean_2014.dta", clear 

	keep if flag_GP == 1 & flag_EM == 1 
	collapse (mean) cpt_payment=average_medicare_allowed_amt [aw=line_srvc_cnt], by(hcpcs_code state_fips) fast 

	*--------------- COMBINE --------------*
	
	merge m:1 hcpcs_code using `main', nogen 
	gen R_medicare = perc_cpt*cpt_payment
	collapse (sum) R_medicare, by(state_fips) fast 
	save `main', replace
	
	erase "${inter}/Medicare_clean_2014.dta"

***********************************************************************
*-------------- b. Create state-specific Medicaid rates --------------*
***********************************************************************
* Medicaid: combine state-specific FFS and MC payment ratios with MC penetration
* Private: use state-specific payment ratio

use `main', clear	
	
	*----------------- FFS ----------------*
	
	* Merge in Medicaid FFS to Medicare payment ratios
	* - All matched
	merge 1:1 state_fips using "${raw_public}/reimbursement/KFF_data.dta", nogen keepusing(prim)
	gen R_medicaid_ffs = R_medicare*prim
	drop prim
	
	*------------ Managed care ------------*
	
	* Merge in Medicaid FFS to Medicaid MC payment ratios
	* - Missing for 33 states 
	* - Non-missing for AZ, CA, CT, FL, GA, IN, MI, NJ, NM, NY, OH, PA, RI, SC, TX, VA, WA, WI
	merge 1:1 state_fips using "${raw_public}/reimbursement/GAO_report.dta", nogen keepusing(mc_ffs_off)
	
	* Impute with median ratio for missing states
	egen med = median(mc_ffs_off)
	replace mc_ffs_off = med if mc_ffs_off == .
	gen R_medicaid_mc = R_medicaid_ffs*(1+mc_ffs_off)
	drop mc_ffs_off med
	
	*--------------- COMBINE --------------*
	
	* Merge in Medicaid managed care penetration
	* - All matched
	merge 1:1 state_fips using "${raw_public}/reimbursement/MMC_penetration_2014.dta", nogen
	
	gen R_medicaid = R_medicaid_ffs*(1-mc_perc) + R_medicaid_mc*mc_perc
	drop R_medicaid_mc mc_perc
	save `main', replace

***********************************************************************
*--------------- c. Create state-specific private rates --------------*
***********************************************************************	
	
use `main', clear 

	* Merge in Medicaid FFS to private payment ratios
	* - Missing for 19 states
	* - Non-missing for AK, AL, AZ, CA, CO, FL, GA, IA, ID, IN, KS, KY, LA, MA, MI, MN, 
	*                   MS, NC, NE, NJ, NM, NV, NY, OH, OK, OR, RI, TX, VT, WA, WI, WY
	merge 1:1 state_fips using "${raw_public}/reimbursement/GAO_report.dta", nogen keepusing(ffs_priv_off)
	
	* Impute with median ratio for missing states
	egen med = median(ffs_priv_off)
	replace ffs_priv_off = med if ffs_priv_off == .
	gen R_private = R_medicaid_ffs*(1-ffs_priv_off)
	drop ffs_priv_off med R_medicaid_ffs
	
	save "${inter}/R_state_2014.dta", replace

***********************************************************************
*---------- d. Create provider-specific reimbursement rates ----------*
***********************************************************************	

use provider_id year month perc_third perc_medicare perc_medicaid using "${inter}/provider_month_patientchars_0614.dta", clear 

	keep if year == 2014 
	
	* Adjust to exclude cash payments
	gen tot = perc_medicaid + perc_third + perc_medicare
	foreach v in medicaid third medicare {
		replace perc_`v' = perc_`v'/tot
	}
	drop if tot == 0
	
	* Get monthly prescriptions for weights
	* - All matched in 2014 except for those with all cash
	merge 1:1 provider_id year month using "${inter}/provider_month_opioids_0614.dta", nogen keep(matched) keepusing(year tot_OP)
	collapse (mean) perc* [aw=tot_OP], by(provider_id) fast
	
	* Get information on state 
	* - 25,841 providers (1.72%) with missing specialty and provider_id >= 9500000 unmatched 
	merge 1:1 provider_id using "${inter}/provider_chars_cleaned.dta", nogen keep(matched) keepusing(state_fips flag_GP)

	* Reimbursement rates only relevant for GPs
	keep if flag_GP == 1
	
	* Merge reimbursement info
	* - All matched
	merge m:1 state_fips using "${inter}/R_state_2014.dta", nogen
	erase "${inter}/R_state_2014.dta"
	
	* Drop TN: no Medicaid FFS
	drop if state_fips == 47 
	
	gen R = R_medicaid*perc_medicaid + R_private*perc_third + R_medicare*perc_medicare
	keep provider_id R
	save "${inter}/R_provider_2014.dta", replace


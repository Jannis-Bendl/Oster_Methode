***********************************************************************
*-------------------------- Clean NVSS Data --------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Read in raw data (2006-2014) 

b. Clean individual-level data
   - Clean geography (state, county)
   - Clean causes of death (drugs)

c. Create geographic aggregates
   
*--------------------------------------------------------------------*/

***********************************************************************
*------------------------ a. Read in raw data ------------------------*
***********************************************************************	

forvalues y = 2006/2014 {	

	infix str state_occ 21-22 ///
	      str county_occ 23-25 ///
	      str state_res 29-30 ///
	      str county_res 35-37 ///
	      month 65-66 ///
	      str sex 69 ///
	      ageunit 70 ///
	      agenr 71-73 ///
	      place 83 ///
	      dow 85 ///
	      manner 107 ///
	      str autopsy 109 ///
	      str tobacco 142 ///
	      str icd10 146-149 ////
	      cause358 150-152 ///
	      cause113 154-156 ///
	      infant130 157-159 ///
	      cause39 160-161 ///
	      neconds 163-164 ///
	      str econd1 165-171 ///
	      str econd2 172-178 ///
	      str econd3 179-185 ///
	      str econd4 186-192 ///
	      str econd5 193-199 ///
	      str econd6 200-206 ///
	      str econd7 207-213 ///
	      str econd8 214-220 ///
	      str econd9 221-227 ///
	      str econd10 228-234 ///
	      str econd11 235-241 ///
	      str econd12 242-248 ///
	      str econd13 249-255 ///
	      str econd14 256-262 ///
	      str econd15 263-269 ///
	      str econd16 270-276 ///
	      str econd17 277-283 ///
	      str econd18 284-290 ///
	      str econd19 291-297 ///
	      str econd20 298-304 ///
	      nrconds 341-342 ///
	      str rcond1 344-348 ///
	      str rcond2 349-353 ///
	      str rcond3 354-358 ///
	      str rcond4 359-363 ///
	      str rcond5 364-368 ///
	      str rcond6 369-373 ///
	      str rcond7 374-378 ///
	      str rcond8 379-383 ///
	      str rcond9 384-388 ///
	      str rcond10 389-393 ///
	      str rcond11 394-398 ///
	      str rcond12 399-403 ///
	      str rcond13 404-408 ///
	      str rcond14 409-413 ///
	      str rcond15 414-418 ///
	      str rcond16 419-423 ///
	      str rcond17 424-428 ///
	      str rcond18 429-433 ///
	      str rcond19 434-438 ///
	      str rcond20 439-443 ///
	      race 445-446 ///
	      race_recode1 449 ///
	      race_recode2 450 ///
	      hispanic 488 ///
	      using "${raw_NVSS}/MULT`y'.USPART2", clear
	     
	save "${inter}/NVSS_`y'.dta", replace
}

***********************************************************************
*------------------- b. Clean individual-level data ------------------*
***********************************************************************

forvalues y = 2006/2014 {

	use state_res county_res month icd10 cause39 rcond* using "${inter}/NVSS_`y'.dta", clear

	*------- GEOGRAPHY -------*
	* Use county/state of residence (not occurrence)
	
	* Get state FIPs/ drop unknown + territories
	statastates, abbrev(state_res)
	keep if _merge == 3
	drop _merge state_res state_name 
	
	* Format county FIPs
	tostring state_fips, replace format(%02.0f)
	gen county_fips = state_fips + county_res
	drop county_res
	
	*---- CAUSES OF DEATH ----*
	* https://www.cdc.gov/drugoverdose/pdf/pdo_guide_to_icd-9-cm_and_icd-10_codes-a.pdf
	* Further follows Alpert et al. (2018) [see p.11]
	* X40-X44: unintentional drug poisonings
	* X60-X64: intentional drug poisonings (self)
	* X85: drug poisonings by assault/ homicide
	* Y10-Y14: drug poisonings of undetermined intent
	* T400: opium
	* T401: heroin
	* T402: other opioids
	* T403: methadone
	* T404: other synthetic (mainly fentanyl)
	* T405: cocaine
	* T406: unspecified narcotics

	* Underlying cause of death
	gen d_drugs = icd10 == "X40" | icd10 == "X41" | icd10 == "X42" | icd10 == "X43" | icd10 == "X44" | ///
		      icd10 == "X60" | icd10 == "X61" | icd10 == "X62" | icd10 == "X63" | icd10 == "X64" | ///
		      icd10 == "Y10" | icd10 == "Y11" | icd10 == "Y12" | icd10 == "Y13" | icd10 == "Y14" | ///
		      icd10 == "X85" 
	
	* Contributing cause of death (drug type)
	foreach v in cocaine opioids heroin rxopioid fentanyl {
		gen d_`v' = 0 
	}
	* Note: rcond1 = icd10
	forvalues i = 2/20 {
	
		replace d_opioids = 1 if d_drugs == 1 & (rcond`i' == "T400" | rcond`i' == "T401" | rcond`i' == "T402" | ///
				         rcond`i' == "T403" | rcond`i' == "T404" | rcond`i' == "T406")
		replace d_heroin = 1 if d_drugs == 1 & rcond`i' == "T401"
		replace d_rxopioid = 1 if d_drugs == 1 & (rcond`i' == "T402" | rcond`i' == "T403")
		replace d_fentanyl = 1 if d_drugs == 1 & (rcond`i' == "T404")
		replace d_cocaine = 1 if d_drugs == 1 & rcond`i' == "T405"
	}
	gen d_total = 1 
	drop icd10 cause39 rcond* 
	
	* Create date variable
	gen year = `y' 
	
	if `y' != 2006 {
		append using "${inter}/NVSS_clean_0614.dta"
	}
	save "${inter}/NVSS_clean_0614.dta", replace
	erase "${inter}/NVSS_`y'.dta"
}

***********************************************************************
*------------------ c. Create geographic aggregates ------------------*
***********************************************************************

use "${inter}/NVSS_clean_0614.dta", clear

	* Collapse to county-year level
	collapse (sum) d_*, by(county_fips year) fast 
	
	* Create measures per 10,000
	* 7 counties unmatched from master
	* - 02201, 02232, 02270, 02280, 26124, 46113, 51515
	merge 1:1 county_fips year using "${inter}/county_year_pop_0614.dta", nogen keep(matched)
	foreach v in drugs cocaine opioids heroin rxopioid fentanyl total {
	
		gen pc_`v' = d_`v'/(pop_tot/10000)
	}
	save "${inter}/NVSS_county_year_0614.dta", replace
	erase "${inter}/NVSS_clean_0614.dta"
	
	

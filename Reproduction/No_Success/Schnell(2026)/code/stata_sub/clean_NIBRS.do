***********************************************************************
*------------------------- Clean NIBRS Data --------------------------* 
***********************************************************************

/*-------------------------- OVERVIEW --------------------------------*

a. Read in raw data (2006-2014) 

b. Create ORI to county crosswalks
   - Create crosswalk based on county information in header segments
  
c. Clean NIBRS (2006-2014)
   - Compile list of reporting ORIs 
   - Clean property segment, collapse to ORI-month level 
   - Fill in zeros (based on reporting ORI-months)
   
d. Create county-month files 
   - Collapse data 
   - Summary statistics
  
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*----------------------------- Settings ------------------------------*
*---------------------------------------------------------------------*

	tempfile header
	tempfile ORI_reporting
	tempfile property
	
	local file_2006 "22407"
	local file_2007 "25113"
	local file_2008 "27647"
	local file_2009 "30770"
	local file_2010 "33530"
	local file_2011 "34585"
	local file_2012 "35035"
	local file_2013 "36120"
	local file_2014 "36398"
	
***********************************************************************
*------------------------ a. Read in raw data ------------------------*
***********************************************************************	

*---------------------------------------------------------------------*
*----------------------- Batch header segments -----------------------*
*---------------------------------------------------------------------*
* Uniquely identified by ORI

forvalues y = 2006/2014 {	

	if `y' <= 2012 {
	
		* Segment 1
		infix str segment 1-2 ///
		      state_code 3-4 /// 
		      str ORI 5-13 ///
		      str inc_num 14-25 ///
		      ORI_update 26-33 ///
		      ORI_NIBRS 34-41 ///
		      str city_name 42-71 ///
		      str state 72-73 ///
		      str pop_group 74-75 ///
		      division 76-76 ///
		      region 77-77 ///
		      agency_type 78-78 ///
		      str core_city 79-79 ///
		      str covered_by 80-88 ///
		      fbi_office 89-92 ///
		      str jud_district 93-96 ///
		      str nibrs_flag 97-97 ///
		      agency_inactive 98-105 ///
		      blank 106-132 ///
		      n_B1_records 133-135 ///
		      using "${raw_public}/nibrs/`file_`y''-0001-Data.txt", clear

		* inc_num always missing
		drop segment inc_num blank
		save `header', replace 
		
		* Segment 2
		infix str segment 1-2 ///
		      state_code 3-4 ///
		      str ORI 5-13 ///
		      str inc_num 14-25 ///
	              current_pop1 26-34 ///
		      county_code1 35-37 ///
		      msa_code1 38-40 ///
		      last_pop1 41-49 ///
	              current_pop2 50-58 ///
		      county_code2 59-61 ///
		      msa_code2 62-64 ///
		      last_pop2 65-73 ///
		      current_pop3 74-82 ///
		      county_code3 83-85 ///
		      msa_code3 86-88 ///
		      last_pop3  89-97 ///
		      current_pop4 98-106 ///
		      county_code4 107-109 ///
		      msa_code4 110-112 ///
		      last_pop4 113-121 ///
		      blank 122-132 ///
		      n_B2_records 133-135 ///
		      using "${raw_public}/nibrs/`file_`y''-0002-Data.txt", clear
	
		* inc_num always missing
		* state_code same across files
		drop segment state_code inc_num blank
		merge 1:1 ORI using `header', nogen
		save `header', replace
		
		* Segment 3  
		infix str segment 1-2 ///
		      state_code3 3-4 ///
		      str ORI 5-13 ///
		      str inc_num 14-25 ///
		      current_pop5 26-34 ///
		      county_code5 35-37 ///
		      msa_code5 38-40 ///
		      last_pop5 41-49 ///
		      I_nm 50-51 ///
		      nm_reported 52-53 ///
		      year 54-57 ///
		      str I_1 58-60 ///
		      str I_2 61-63 ///
		      str I_3 64-66 ///
		      str I_4 67-69 ///
		      str I_5 70-72 ///
		      str I_6 73-75 ///
		      str I_7 76-78 ///
		      str I_8 79-81 ///
		      str I_9 82-84 ///
		      str I_10 85-87 ///
		      str I_11 88-90 ///
		      str I_12 91-93 ///
		      str county_fips1 94-96 ///
		      str county_fips2 97-99 ///
		      str county_fips3 100-102 ///
		      str county_fips4 103-105 ///
		      str county_fips5 106-108 ///
		      blank 109-132 ///
		      n_B3_records 133-135 ///
		      using "${raw_public}/nibrs/`file_`y''-0003-Data.txt", clear
		
		* inc_num always missing
		* state_code same across files
		drop segment state_code inc_num blank
		merge 1:1 ORI using `header', nogen 
	}

	if `y' == 2013 | `y' == 2014 {
	
		infix str segment 1-2 ///
		      state_code 3-4 ///
		      str ORI 5-13 ///
		      str inc_num 14-25 ///
		      ORI_update 26-33 ///
		      ORI_NIBRS 34-41 ///
		      str city_name 42-71 ///
		      str state 72-73 ///
		      str pop_group 74-75 ///
		      division 76-76 ///
		      region 77-77 ///
		      agency_type 78-78 ///
		      str core_city 79-79 ///
		      str covered_by 80-88 ///
		      fbi_office 89-92 ///
		      str jud_district 93-96 ///
		      str nibrs_flag 97-97 ///
		      agency_inactive 98-105 ///
		      current_pop1 106-114 ///
		      county_code1 115-117 ///
		      msa_code1 118-120 ///
		      last_pop1 121-129 ///
		      current_pop2 130-138 ///
		      county_code2 139-141 ///
		      msa_code2 142-144 ///
		      last_pop2 145-153 ///
		      current_pop3 154-162 ///
		      county_code3 163-165 ///
		      msa_code3 166-168 ///
		      last_pop3  169-177 ///
		      current_pop4 178-186 ///
		      county_code4 187-189 ///
		      msa_code4 190-192 ///
		      last_pop4 193-201 ///
		      current_pop5 202-210 ///
		      county_code5 211-213 ///
		      msa_code5 214-216 ///
		      last_pop5 217-225 ///
		      I_nm 226-227 ///
		      nm_reported 228-229 ///
		      year 230-233 ///
		      str I_1 234-236 ///
		      str I_2 237-239 ///
		      str I_3 240-242 ///
		      str I_4 243-245 ///
		      str I_5 246-248 ///
		      str I_6 249-251 ///
		      str I_7 252-254 ///
		      str I_8 255-257 ///
		      str I_9 258-260 ///
		      str I_10 261-263 ///
		      str I_11 264-266 ///
		      str I_12 267-269 ///
		      str county_fips1 270-272 ///
		      str county_fips2 273-275 ///
		      str county_fips3 276-278 ///
		      str county_fips4 279-281 ///
		      str county_fips5 282-284 ///
		      date_leoka 285-292 ///
		      n_BH_records 293-295 ///
		      using "${raw_public}/nibrs/`file_`y''-0001-Data.txt", clear
		 
		* inc_num always missing
		drop segment inc_num
		     
	}
	save "${inter}/NIBRS_header_`y'.dta", replace	

*---------------------------------------------------------------------*
*-------------------------- Property segment -------------------------*
*---------------------------------------------------------------------*
* Uniquely identified by ORI, inc_num, prop_loss_type, prop_loss_descrip

	if `y' <= 2012 {
		local f = 6
	}
	if `y' == 2013 | `y' == 2014 {
		local f = 4
	}
	
	infix str segment 1-2 ///
	      state_code 3-4 ///
	      str ORI 5-13 ///
	      str inc_num 14-25 ///
	      inc_date 26-33 ///
	      prop_loss_type 34-34 ///
	      prop_loss_descrip 35-36 ///
	      prop_value 37-45 ///
	      date_recov 46-53 ///
	      num_stoln_auto 54-55 ///
	      num_recov_auto 56-57 ///
	      str drug_type1 58-58 ///
	      est_quant_main1 59-67 ///
              est_quant_frac1 68-70 ///
	      str meas_type1 71-72 ///
	      str drug_type2 73-73 ///
	      est_quant_main2 74-82 ///
	      est_quant_frac2 83-85 ///
	      str meas_type2 86-87 ///
	      str drug_type3 88-88 ///
	      est_quant_main3 89-97 ///
	      est_quant_frac3 98-100 ///
	      str meas_type3 101-102 ///
	      n_03_records 103-105 ///
	      using "${raw_public}/nibrs/`file_`y''-000`f'-Data.txt", clear
	      
	save "${inter}/NIBRS_property_`y'.dta", replace
}

***********************************************************************
*------------------------ b. Create crosswalk ------------------------*
***********************************************************************	
* Compute covered share (of ORI and of county) for main county

forvalues y = 2006/2014 {

	use ORI state county_fips1 current_pop* year using "${inter}/NIBRS_header_`y'.dta", clear
	drop if county_fips1 == "" | county_fips1 == "UCR"
	
	* All matched in master
	replace state = "NE" if state == "NB"
	statastates, abbreviation(state)
	keep if _merge == 3
	drop _merge 
	
	tostring state_fips, replace format(%02.0f)
	gen county_fips = state_fips + county_fips1 
	drop state state_fips state_name county_fips1

	* Compute fraction of ORI population in main county 
	* (To adjust ORI-level seizures)
	gen ORI_frac = current_pop1/(current_pop1 + current_pop2 + current_pop3 +  current_pop4 + current_pop5)
	replace ORI_frac = 0 if ORI_frac == . 

	* Compute fraction of county population covered by ORI
	* (To adjust county-level opioid prescriptions)
	* All matched in master except two counties (12025, 46113)
	merge m:1 county_fips year using "${inter}/county_year_pop_0614.dta", nogen keep(matched) 
	gen county_frac = current_pop1/pop_tot
	drop current_pop* pop_tot
	
	if `y' != 2006 {
		append using "${inter}/ORI_county_crosswalk.dta"
	}
	save "${inter}/ORI_county_crosswalk.dta", replace
}

***********************************************************************
*--------------------- c. Clean NIBRS (2006-2014) --------------------*
***********************************************************************	

*------------------- Compile list of reporting ORIs ------------------*
* Needed to impute true zeroes

forvalues y = 2006/2014 {

	use "${inter}/NIBRS_header_`y'.dta", clear

	* Drop US territories 
	drop if state_code >= 52
	
	keep ORI I_* year
	drop I_nm

	forvalues i = 1/12 {
	
		gen data`i' = I_`i' != ""
		drop I_`i'
	}
	
	reshape long data, i(ORI year) j(month)	
	keep if data == 1
	drop data
	
	if `y' != 2006 {
		append using `ORI_reporting'
	}
	save `ORI_reporting', replace
	erase "${inter}/NIBRS_header_`y'.dta" 
}

*----------------------- Clean property segment ----------------------*
* Clean and collapse to ORI-month level 
* Expand to include missing ORI-months 
* Uniquely identified by ORI, inc_num, prop_loss_type, prop_loss_descrip (inc_date)

	* Combine across years
	forvalues y = 2006/2014 {

		use ORI inc_num prop_loss_type prop_loss_descrip inc_date drug_type* meas_type* ///
			est_quant_main* est_quant_frac* using "${inter}/NIBRS_property_`y'.dta", clear 
	
		* Only keep drug/narcotic seizures
		keep if prop_loss_type == 6 & prop_loss_descrip == 10 
		drop prop_loss_type prop_loss_descrip
		
		* Format date 
		tostring inc_date, replace
		gen year = substr(inc_date,1,4)
		gen month = substr(inc_date,5,2)
		destring year, replace 
		destring month, replace
		drop inc_date
		
		* Drop 1.93% (3.36%) of drug (opioid) cases from previous years
		* (Else inconsistent for later years)
		keep if year == `y'
		
		if `y' != 2006 {
			append using `property'
		}
		if `y' == 2014 {
			
			* Drop 0.01% (0.01%) of drug (opioid) cases reported across multiple years 
			* (No way to identify true incident date)
			gen n = 1 
			bys ORI inc_num: egen count = sum(n) 
			keep if count == 1 
			drop n count
		}	
		save `property', replace
		erase "${inter}/NIBRS_property_`y'.dta"
	}

	use `property', clear 
	reshape long drug_type est_quant_main est_quant_frac meas_type, i(ORI inc_num year month) j(drug_num)
	drop if drug_type == ""

	* Drug types
	* - 56.11% (7.26%) (4.32%) of seizures for marijuana (Rx opioids) (heroin) 
	gen n_marijuana = drug_type == "E" 
	gen n_heroin = drug_type == "D" 
	gen n_morphine = drug_type == "F" 
	gen n_opium = drug_type == "G" 
	gen n_othern = drug_type == "H" 
	gen n_rxopioid = n_morphine == 1 | n_opium == 1 | n_othern == 1 	
	gen n_all = 1 
	
	* Drug quantities
	* - Only consider weight for marijuana (84.25%)
	* - Only consider pills for Rx opioids (82.64%) 
	* - Only consider weight for heroin (70.10%)
	
	tostring est_quant_main, replace 
	tostring est_quant_frac, replace
	replace est_quant_frac = "0" + est_quant_frac if length(est_quant_frac) == 2
	replace est_quant_frac = "00" + est_quant_frac if length(est_quant_frac) == 1
	gen amt = est_quant_main + "." + est_quant_frac
	destring amt, replace 
	
	gen q_rxopioid = amt if n_rxopioid == 1 & meas_type == "DU" 
	foreach v in marijuana heroin {
	
		gen q_`v' = amt if n_`v' == 1 & meas_type == "GM" | meas_type == "KG" | meas_type == "LB" | meas_type == "OZ"
		replace q_`v' = q_`v'*1000 if meas_type == "KG"
		replace q_`v' = q_`v'*453.592 if meas_type == "LB"
		replace q_`v' = q_`v'*28.3495 if meas_type == "OZ"
	}
	
	* Collapse to ORI-month level
	collapse (sum) n_all n_marijuana n_heroin n_rxopioid q_marijuana q_heroin q_rxopioid, by(ORI month year) fast 
	
	* Fill in missing ORI-months 
	* - All but one ORI matched (reporting in only five months)
	merge 1:1 ORI year month using `ORI_reporting'
	drop if _merge == 1
	foreach v in n_all n_marijuana n_heroin n_rxopioid q_marijuana q_heroin q_rxopioid {
		replace `v' = 0 if _merge == 2 
	}
	drop _merge 
	
	gen date = ym(year,month)
	
	save "${inter}/NIBRS_clean_0614.dta", replace	

***********************************************************************
*-------------------- d. Create county-month files -------------------*
***********************************************************************	

use "${inter}/NIBRS_clean_0614.dta", clear

	* All but one ORI matched in master
	merge m:1 ORI year using "${inter}/ORI_county_crosswalk.dta", nogen keep(matched)
	keep if county_fips != ""
	
	* Adjust reports by population share in county
	foreach v in all marijuana heroin rxopioid {
		replace n_`v' = n_`v'*ORI_frac
		cap replace q_`v' = q_`v'*ORI_frac
	}
	
	collapse (sum) n* q* county_frac, by(county_fips month year date) fast 
	save "${inter}/NIBRS_county_month_0614.dta", replace
	
	collapse (sum) n* q* (mean) county_frac, by(county_fips year) fast 
	save "${inter}/NIBRS_county_year_0614.dta", replace
	
	erase "${inter}/NIBRS_clean_0614.dta"
	erase "${inter}/ORI_county_crosswalk.dta"

	

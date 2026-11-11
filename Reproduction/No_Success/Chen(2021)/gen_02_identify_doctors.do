/*******************************************************************************
PURPOSE: Extract claims for identifying the proceduralist and the physicians 
		 who treat the patient
*******************************************************************************/

* run the code separately for each year, for-loop may not be able to proceed because of the large memory required
*----------------------------*
* 2008
*----------------------------*
use "${INPUT}/car/2008/carl2008.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2008.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2008/mdppas2008.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2008", replace


*----------------------------*
* 2009
*----------------------------*
use "${INPUT}/car/2009/carl2009.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2009.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2009/mdppas2009.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2009", replace


*----------------------------*
* 2010
*----------------------------*
use "${INPUT}/car/2010/carl2010.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2010.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2010/mdppas2010.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2010", replace


*----------------------------*
* 2011
*----------------------------*
use "${INPUT}/car/2011/carl2011.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2011.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2011/mdppas2011.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2011", replace


*----------------------------*
* 2012
*----------------------------*
use "${INPUT}/car/2012/carl2012.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2012.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2012/mdppas2012.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2012", replace


*----------------------------*
* 2013
*----------------------------*
use "${INPUT}/car/2013/carl2013.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2013.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2013/mdppas2013.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2013", replace


*----------------------------*
* 2014
*----------------------------*
use "${INPUT}/car/2014/carl2014.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2014.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2014/mdppas2014.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2014", replace


*----------------------------*
* 2015
*----------------------------*
use "${INPUT}/car/2015/carl2015.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2015.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2015/mdppas2015.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2015", replace


*----------------------------*
* 2016
*----------------------------*
use "${INPUT}/car/2016/carl2016.dta", clear
		
	keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi hcfaspcl plcsrvc mdfr_cd* lsbmtchg lalowchg prv_type
	keep if substr(betos, 1, 2) == "P2" | substr(betos, 1, 1) == "M"
	duplicates drop 
		
	*** joinby with MedPAR file
	joinby bene_id using "${OUTPUT}/med2016.dta"
	keep if (admsndt-3<=expnsdt1 & dschrgdt+3>=expnsdt2) 
	* later restrict to (admsndt<=expnsdt1 & expnsdt2<=dschrgdt) for both proceduralists and physicians 
				
	*** drop irrelevant claims
	g npi = prf_npi
	cap ren birth_dt birth_dt_patient
	cap ren sex sex_patient
	merge m:1 npi using "${INPUT_MDPPAS}/2016/mdppas2016.dta", keepusing(spec_broad spec_prim_1_name birth_dt sex tin1 tin2) keep(1 3)
	ren birth_dt birth_dt_doc
	ren sex sex_doc
	drop if (spec_broad == 1 | spec_broad == 6 | spec_broad==7 | spec_broad==9) & substr(betos, 1, 1) == "P" 
	drop if inlist(hcfaspcl, "49", "97")
	drop if _merge == 1 & inlist(prv_type, "3", "4", "5", "8")
	drop _merge	
	* drop procedures performed by proceduralists in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if betos == "P2A" & !inlist(spec_prim_1_name, "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY")
	/* most proceduralists for CABG are cardiac surgeons and thoracic surgeons */ 
	drop if betos == "P2D" & !inlist(spec_prim_1_name, "INTERVENTIONAL CARDIOLOGY", "CARDIAC SURGERY", "CARDIOLOGY", "GENERAL SURGERY", "THORACIC SURGERY", "VASCULAR SURGERY") 
	/* most proceduralists for PCI are (interventional) cardiologists */ 

	drop if inlist(mdfr_cd1, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
	drop if inlist(mdfr_cd2, "80", "81", "82", "AS") & substr(betos, 1, 1) == "P"
		
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	drop if t > 1 & (inlist(mdfr_cd1, "26") | inlist(mdfr_cd2, "26")) & substr(betos, 1, 1) == "P"
		
	*** keep relevant procedures
	foreach x in P2A P2D{
		bysort medparid: egen `x' = max(betos == "`x'")
	}
	replace P2D = 0 if P2A == 1 & P2D == 1 
	/* a few cases have both PCI and CABG in one hospital stay, group them to the more invasive procedure P2A */

	foreach x in P2A P2D{
		drop if `x' == 1 & betos != "`x'" & substr(betos, 1, 1) == "P"
	}
		
	*** keep the proceduralist with the highest allowable charge if multiple proceduralists
	cap drop tag t
	egen tag = tag(bene_id expnsdt1 prf_npi) if substr(betos, 1, 1) == "P"
	bysort bene_id expnsdt1: egen t = total(tag)
	bysort bene_id expnsdt1: egen lalowchg_max = max(lalowchg) if substr(betos, 1, 1) == "P"
	drop if t > 1 & lalowchg < lalowchg_max & substr(betos, 1, 1) == "P"
		
	drop if (admsndt>expnsdt1 | dschrgdt<expnsdt2) & substr(betos, 1, 1) == "P"

save "${OUTPUT}/team_2016", replace




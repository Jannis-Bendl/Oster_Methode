/*******************************************************************************
PURPOSE: Generate variables for doctor characteristics  
*******************************************************************************/
*------------------------------*
* obtain infomation from Physician Compare
*------------------------------*
*** Physician Compare data downloaded from https://data.cms.gov/provider-data/archived-data/doctors-clinicians
*** downloaded in January 2019, earliest available year: 2014; latest available year by January 2019: 2017 (Octobor version)
*** last year of Medicare data used in the paper: 2016

*** 2014
use "${INPUT_PhyCom}/PhyCompare2014Dec.dta", clear		
	keep npi gender medicalschool graduationyear
	
	* medical school rank
	replace medicalschool = upper(medicalschool)
	g medsch_rank = 1 if strpos(medicalschool, "HARVARD MEDICAL SCHOOL") | strpos(medicalschool, "JOHNS HOPKINS") | strpos(medicalschool, "NEW YORK UNIVERSITY SCHOOL OF MEDICINE") | strpos(medicalschool, "STANFORD") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, SAN FRANCISCO SCHOOL OF MEDICINE") 
	replace medsch_rank = 2 if strpos(medicalschool, "MAYO MEDICAL SCHOOL") | strpos(medicalschool, "UNIVERSITY OF PENNSYLVANIA SCHOOL OF MEDICINE") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, UCLA") | strpos(medicalschool, "DUKE UNIVERSITY SCHOOL OF MEDICINE") | medicalschool == "WASHINGTON UNIVERSITY SCHOOL OF MEDICINE" 
	replace medsch_rank = 3 if medicalschool == "COLUMBIA UNIVERSITY COLLEGE OF PHYSICIANS AND SURGEONS" | strpos(medicalschool, "UNIVERSITY OF WASHINGTON SCHOOL OF MEDICINE") | strpos(medicalschool, "YALE") | strpos(medicalschool, "UNIVERSITY OF PITTSBURGH") | strpos(medicalschool, "UNIVERSITY OF MICHIGAN MEDICAL SCHOOL") | strpos(medicalschool, "BAYLOR COLLEGE OF MEDICINE")  | strpos(medicalschool, "VANDERBILT UNIVERSITY")  | strpos(medicalschool, "MOUNT SINAI")  | strpos(medicalschool, "UNIVERSITY OF CHICAGO, PRITZKER")  | strpos(medicalschool, "NORTHWESTERN UNIVERSITY MEDICAL SCHOOL")
	replace medsch_rank = 4 if medsch_rank == .
	
	duplicates drop	
save "${OUTPUT}/PhyCompare2014Dec.dta", replace

*** 2015
use "${INPUT_PhyCom}/PhyCompare2015Nov.dta", clear
	keep npi gender medicalschool graduationyear
	
	* medical school rank
	replace medicalschool = upper(medicalschool)
	g medsch_rank = 1 if strpos(medicalschool, "HARVARD MEDICAL SCHOOL") | strpos(medicalschool, "JOHNS HOPKINS") | strpos(medicalschool, "NEW YORK UNIVERSITY SCHOOL OF MEDICINE") | strpos(medicalschool, "STANFORD") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, SAN FRANCISCO SCHOOL OF MEDICINE") 
	replace medsch_rank = 2 if strpos(medicalschool, "MAYO MEDICAL SCHOOL") | strpos(medicalschool, "UNIVERSITY OF PENNSYLVANIA SCHOOL OF MEDICINE") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, UCLA") | strpos(medicalschool, "DUKE UNIVERSITY SCHOOL OF MEDICINE") | medicalschool == "WASHINGTON UNIVERSITY SCHOOL OF MEDICINE" 
	replace medsch_rank = 3 if medicalschool == "COLUMBIA UNIVERSITY COLLEGE OF PHYSICIANS AND SURGEONS" | strpos(medicalschool, "UNIVERSITY OF WASHINGTON SCHOOL OF MEDICINE") | strpos(medicalschool, "YALE") | strpos(medicalschool, "UNIVERSITY OF PITTSBURGH") | strpos(medicalschool, "UNIVERSITY OF MICHIGAN MEDICAL SCHOOL") | strpos(medicalschool, "BAYLOR COLLEGE OF MEDICINE")  | strpos(medicalschool, "VANDERBILT UNIVERSITY")  | strpos(medicalschool, "MOUNT SINAI")  | strpos(medicalschool, "UNIVERSITY OF CHICAGO, PRITZKER")  | strpos(medicalschool, "NORTHWESTERN UNIVERSITY MEDICAL SCHOOL")
	replace medsch_rank = 4 if medsch_rank == .

	duplicates drop	
save "${OUTPUT}/PhyCompare2015Nov.dta", replace

*** 2016
use "${INPUT_PhyCom}/Refresh_Data_Archive_12_2016.dta", clear
	keep npi gender medicalschool graduationyear	
	
	* medical school rank
	replace medicalschool = upper(medicalschool)
	g medsch_rank = 1 if strpos(medicalschool, "HARVARD MEDICAL SCHOOL") | strpos(medicalschool, "JOHNS HOPKINS") | strpos(medicalschool, "NEW YORK UNIVERSITY SCHOOL OF MEDICINE") | strpos(medicalschool, "STANFORD") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, SAN FRANCISCO SCHOOL OF MEDICINE") 
	replace medsch_rank = 2 if strpos(medicalschool, "MAYO MEDICAL SCHOOL") | strpos(medicalschool, "UNIVERSITY OF PENNSYLVANIA SCHOOL OF MEDICINE") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, UCLA") | strpos(medicalschool, "DUKE UNIVERSITY SCHOOL OF MEDICINE") | medicalschool == "WASHINGTON UNIVERSITY SCHOOL OF MEDICINE" 
	replace medsch_rank = 3 if medicalschool == "COLUMBIA UNIVERSITY COLLEGE OF PHYSICIANS AND SURGEONS" | strpos(medicalschool, "UNIVERSITY OF WASHINGTON SCHOOL OF MEDICINE") | strpos(medicalschool, "YALE") | strpos(medicalschool, "UNIVERSITY OF PITTSBURGH") | strpos(medicalschool, "UNIVERSITY OF MICHIGAN MEDICAL SCHOOL") | strpos(medicalschool, "BAYLOR COLLEGE OF MEDICINE")  | strpos(medicalschool, "VANDERBILT UNIVERSITY")  | strpos(medicalschool, "MOUNT SINAI")  | strpos(medicalschool, "UNIVERSITY OF CHICAGO, PRITZKER")  | strpos(medicalschool, "NORTHWESTERN UNIVERSITY MEDICAL SCHOOL")
	replace medsch_rank = 4 if medsch_rank == .
	
	duplicates drop	
save "${OUTPUT}/Refresh_Data_Archive_12_2016.dta", replace

*** 2017
use "${INPUT_PhyCom}/Refresh_Data_Archive_10_2017.dta", clear
	keep npi gender medicalschool graduationyear	
	
	* medical school rank
	replace medicalschool = upper(medicalschool)
	g medsch_rank = 1 if strpos(medicalschool, "HARVARD MEDICAL SCHOOL") | strpos(medicalschool, "JOHNS HOPKINS") | strpos(medicalschool, "NEW YORK UNIVERSITY SCHOOL OF MEDICINE") | strpos(medicalschool, "STANFORD") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, SAN FRANCISCO SCHOOL OF MEDICINE") 
	replace medsch_rank = 2 if strpos(medicalschool, "MAYO MEDICAL SCHOOL") | strpos(medicalschool, "UNIVERSITY OF PENNSYLVANIA SCHOOL OF MEDICINE") | strpos(medicalschool, "UNIVERSITY OF CALIFORNIA, UCLA") | strpos(medicalschool, "DUKE UNIVERSITY SCHOOL OF MEDICINE") | medicalschool == "WASHINGTON UNIVERSITY SCHOOL OF MEDICINE" 
	replace medsch_rank = 3 if medicalschool == "COLUMBIA UNIVERSITY COLLEGE OF PHYSICIANS AND SURGEONS" | strpos(medicalschool, "UNIVERSITY OF WASHINGTON SCHOOL OF MEDICINE") | strpos(medicalschool, "YALE") | strpos(medicalschool, "UNIVERSITY OF PITTSBURGH") | strpos(medicalschool, "UNIVERSITY OF MICHIGAN MEDICAL SCHOOL") | strpos(medicalschool, "BAYLOR COLLEGE OF MEDICINE")  | strpos(medicalschool, "VANDERBILT UNIVERSITY")  | strpos(medicalschool, "MOUNT SINAI")  | strpos(medicalschool, "UNIVERSITY OF CHICAGO, PRITZKER")  | strpos(medicalschool, "NORTHWESTERN UNIVERSITY MEDICAL SCHOOL")
	replace medsch_rank = 4 if medsch_rank == . & !missing(medicalschool)

	duplicates drop	
save "${OUTPUT}/Refresh_Data_Archive_10_2017.dta", replace

*** append data and keep unique at the doctor level
use "${OUTPUT}/PhyCompare2014Dec.dta", replace
	append using "${OUTPUT}/PhyCompare2015Nov.dta"
	append using "${OUTPUT}/Refresh_Data_Archive_12_2016.dta"
	append using "${OUTPUT}/Refresh_Data_Archive_10_2017.dta"
	drop medicalschool
	duplicates drop
	
	* for a few doctors, the raw data provide slightly different info across years 
	sort npi graduationyear medsch_rank gender
	by npi: g n= _n
	keep if n == 1
	drop n
	
save "${OUTPUT}/PhyCompare20142017.dta", replace	

*------------------------------*
* physician demographics
*------------------------------*
*** physicians who care for the patient during the hospital stay
use "${OUTPUT}/team_experience_panel", clear

	destring npi, replace force
	merge m:1 npi using "${OUTPUT}/PhyCompare20142017.dta", keep(1 3) nogen keepusing(medsch_rank graduationyear)

	g female_attphy = (sex_doc == "F")
	g age_attphy = year(admsndt)-year(birth_dt_doc)
	g yrprac = year(admsndt)-graduationyear
	
	* average charatceristics	
	assert expnsdt1 == expnsdt2
	bysort medparid: egen female_attphy_avg = mean(female_attphy)
	bysort medparid: egen age_attphy_avg = mean(age_attphy)
	bysort medparid: egen yrprac_attphy_avg = mean(yrprac)	
	cap drop cnt
	bysort medparid: egen cnt= count(medsch_rank)
	forvalues i = 1/4{
		bysort medparid: egen cnt_`i' = total(medsch_rank == `i')
		gen medrank`i'_attphy_avg = cnt_`i'/cnt
	}
	
	keep medparid *_avg 
	duplicates drop
	
save "${OUTPUT}/team_doccharacteristics", replace

*** physicians other than the main physician
use "${OUTPUT}/team_experience_panel", clear
	drop if prf_npi == prf_npi1	
	
	destring npi, replace force
	merge m:1 npi using "${OUTPUT}/PhyCompare20142017.dta", keep(1 3) nogen keepusing(medsch_rank graduationyear)
	
	g female_attphy = (sex_doc == "F")
	g age_attphy = year(admsndt)-year(birth_dt_doc)
	g yrprac = year(admsndt)-graduationyear
	
	* average charatceristics
	assert expnsdt1 == expnsdt2
	bysort medparid: egen female_other_attphy_avg = mean(female_attphy)
	bysort medparid: egen age_other_attphy_avg = mean(age_attphy)
	bysort medparid: egen yrprac_other_attphy_avg = mean(yrprac)	
	cap drop cnt
	bysort medparid: egen cnt= count(medsch_rank)
	forvalues i = 1/4{
		bysort medparid: egen cnt_`i' = total(medsch_rank == `i')
		gen medrank`i'_other_attphy_avg = cnt_`i'/cnt
	}		
	
	keep medparid *other*_avg 
	duplicates drop
	merge 1:1 medparid using "${OUTPUT}/team_doccharacteristics", nogen
	
save "${OUTPUT}/team_doccharacteristics", replace

*--------------------------------*
* specialties
*--------------------------------*
use "${OUTPUT}/team_experience_panel", clear	
	
	bysort medparid: egen tot = total(expnsdt2-expnsdt1+1)
	foreach x in 11 29 39 46 44 08 93{
		bysort medparid: egen tot_`x' = total((hcfaspcl == "`x'")*(expnsdt2-expnsdt1+1))
		g shr_`x' = tot_`x'/tot
	}		
	keep medparid shr_*
	duplicates drop	
	merge 1:1 medparid using "${OUTPUT}/team_doccharacteristics", nogen
	
save "${OUTPUT}/team_doccharacteristics", replace	
		
use "${OUTPUT}/team_experience_panel", clear	
	drop if prf_npi == prf_npi1
	
	bysort medparid: egen tot = total(expnsdt2-expnsdt1+1)
	foreach x in 11 29 39 46 44 08 93{
		bysort medparid: egen tot_other_`x' = total((hcfaspcl == "`x'")*(expnsdt2-expnsdt1+1))
		g shr_other_`x' = tot_other_`x'/tot
	}		
	keep medparid shr_other_*
	duplicates drop	
	merge 1:1 medparid using "${OUTPUT}/team_doccharacteristics", nogen
	
save "${OUTPUT}/team_doccharacteristics", replace	
	
*--------------------------------*
* whether belong to the same practice group
*--------------------------------*	
use "${INPUT_MDPPAS}/2008/mdppas2008.dta", clear

	g year = 2008
	forvalues i = 2009/2016{
		append using "${INPUT_MDPPAS}/`i'/mdppas`i'.dta"
		replace year = `i' if missing(year)
	}

	keep npi year tin1 tin2 
	foreach x in npi tin1 tin2{
		ren `x' `x'_surgeon
	}

	drop if missing(npi_surgeon)
	merge 1:m npi_surgeon year using "${OUTPUT}/team_experience_panel", keepusing(medparid prf_npi1 tin1 tin2 expnsdt1 expnsdt2 admsndt dschrgdt prf_npi) keep(2 3) nogen
	destring tin1* tin2*, replace force
		
	g same_tin12 = 0
	replace same_tin12 = 1 if (tin1_surgeon == tin1  & !missing(tin1) & !missing(tin1_surgeon)) | (tin1_surgeon == tin2 & !missing(tin2) & !missing(tin1_surgeon)) | (tin2_surgeon == tin1 & !missing(tin1) & !missing(tin2_surgeon)) | (tin2_surgeon == tin2 & !missing(tin2) & !missing(tin2_surgeon))
	
	bysort medparid: egen cnt = total(expnsdt2-expnsdt1+1)
	bysort medparid: egen cnt_same_tin12= total(same_tin12*(expnsdt2-expnsdt1+1))
	g shr_same_tin12 = cnt_same_tin12/cnt
	
	keep medparid shr_same* 
	duplicates drop
	merge 1:1 medparid using "${OUTPUT}/team_doccharacteristics", keep(2 3) nogen
	
save "${OUTPUT}/team_doccharacteristics", replace
	


	
	

/*******************************************************************************
PURPOSE: Generate various experience measures, including:
		 a. shared work experience
		 b. individual work experience
		 c. hospital-specific work experience		 
*******************************************************************************/
*----------------------------*
* generate proceduralists' individual work experience
*----------------------------*
use "${OUTPUT}/team_2008", clear

	cap drop year
	g year = 2008
	forvalues i = 2009/2016{
		append using "${OUTPUT}/team_`i'"
		replace year = `i' if missing(year)	
	}	
	keep if inlist(betos, "P2A", "P2D")
	keep bene_id medparid admsndt betos prf_npi expnsdt1 spec_broad birth_dt_doc sex_doc er_amt dschrgdt year

	*** rename variables
	foreach x in spec_broad birth_dt_doc sex_doc{
		ren `x' `x'_surgeon
	}
	ren prf_npi npi_surgeon	
	
	*** identify procedure date
	duplicates drop 
	g sur_dt = .
	foreach x in P2A P2D{
		replace sur_dt = expnsdt1 if betos == "`x'"
	}	
	bysort medparid: egen surgery_dt_max = max(sur_dt)
	bysort medparid: egen surgery_dt_min = min(sur_dt)	
	drop sur_dt expnsdt1	
	
	*** exclude a small number of stays with more than one proceduralist
	duplicates drop	
	duplicates tag medparid, g(tag)
	ta tag, miss
	foreach x of varlist npi_surgeon admsndt-surgery_dt_min{
		cap replace `x' = . if tag != 0
		cap replace `x' = "" if tag !=0 
	}
	drop tag
	duplicates drop
	
	*** proceduralists' individual work experience
	g tag = 1 if !missing(npi_surgeon)
	g high = admsndt-1
	forvalues i = 1/3{
		g low`i' = admsndt-365*`i'
		rangestat (sum) surgery_cnt_`i'y=tag, interval(surgery_dt_min, low`i', high) by(npi_surgeon)
		replace surgery_cnt_`i'y = 0 if missing(surgery_cnt_`i'y)
	}
		
	append using "${OUTPUT}/op_ed" 
	replace admsndt = thru_dt if op_er == 1
	assert !missing(admsndt) if op_er == 1
	g er = 0
	gsort bene_id admsndt -op_er
	forvalues i = 1/7{		
		by bene_id: replace er = 1 if admsndt <= admsndt[_n-`i']+1 & op_er[_n-`i'] == 1 & bene_id == bene_id[_n-`i'] & dschrgdt != .
	}	
	replace er = 1 if er_amt>0 & !missing(er_amt)
	drop if op_er == 1
	rangestat (sum) surgery_cnt_ed_2y=er, interval(surgery_dt_min, low2, high) by(npi_surgeon)
	replace surgery_cnt_ed_2y = 0 if missing(surgery_cnt_ed_2y)
	
	bysort npi_surgeon: egen cnt_sur = total(!missing(admsndt))	
	foreach x in 10 15 20 25{
		cap drop temp*
		su cnt_sur 
		forvalue i = 1/`r(max)'{
			sort npi_surgeon admsndt surgery_dt_min
			by npi_surgeon: gen temp_`i' =exp(`x'*(surgery_dt_min[_n-`i']-admsndt)/3650)*(medparid[_n-`i'] != medparid)*(surgery_dt_min[_n-`i'] < admsndt)
		}
		egen surgeon_decay_`x'= rowtotal(temp*)
	}		
	
	drop low* high* op_er thru_dt er_amt tag temp*
	
	* number of proceduralists within one medparid
	egen tag = tag(medparid npi_surgeon)
	bysort medparid: egen mul_surgeon = total(tag)	
	drop tag

save "${OUTPUT}/team_experience_surgeon", replace	

*----------------------------*
* generate shared work experience and physicians' individual work experience
*----------------------------*	
use "${OUTPUT}/team_2008", clear

	cap drop year
	g year = 2008
	
	forvalues i = 2009/2016{
		append using "${OUTPUT}/team_`i'"
		replace year = `i' if missing(year)	
	}	
	keep if P2A == 1 | P2D == 1
		
	*** keep hospital care	
	keep if inlist(betos, "M2A", "M2B", "M2C")
	
	*** drop hospital visist by non-doctors
	drop if spec_broad==7 | spec_broad==9
	
	*** drop a small number of claims by doctors in irrelevant specialties
	replace spec_prim_1_name = upper(spec_prim_1_name)
	drop if spec_broad == 6 | inlist(spec_prim_1_name, "ANESTHESIOLOGY", "DERMATOLOGY", "DIAGNOSTIC RADIOLOGY", "OPHTHALMOLOGY", "PATHOLOGY")
	
	*** drop observations with zero allowable charges
	drop if lalowchg == 0
	
	*** drop hospital visits before admission date or after discharge date
	drop if expnsdt1 < admsndt
	drop if expnsdt1 > dschrgdt	
	
	*** merge with proceduralists
	merge m:1 medparid using "${OUTPUT}/team_experience_surgeon", keep(3) nogen
	drop if missing(npi_surgeon)	
	drop if prf_npi == npi_surgeon
	
	duplicates drop 
	cap drop tag
	egen tag = tag(medparid betos prf_npi expnsdt1 expnsdt2 hcpcs_cd) 
	drop if tag == 0 & inlist(betos, "M2A", "M2B", "M2C")
	
	*** a small number of claims bill multiple visits together, hence expand them
	g n = expnsdt2 - expnsdt1 +1
	isid medparid prf_npi expnsdt1 expnsdt2 betos hcpcs_cd
	expand n
	bysort medparid prf_npi expnsdt1 expnsdt2 betos hcpcs_cd: g rank = _n
	g expnsdt1_original = expnsdt1
	g expnsdt2_original = expnsdt2
	replace expnsdt1 = expnsdt1_original+rank-1
	replace expnsdt2 = expnsdt1
		
	*** shared work experience
	cou if expnsdt1 != expnsdt2
	cap drop n 
	g n = 1
	
	g high = admsndt-1
	forvalues i = 1/3{
		g low`i' = admsndt-365*`i'
		rangestat (sum) team_cnt_`i'=n, interval(expnsdt1, low`i', high) by(prf_npi npi_surgeon)
		replace team_cnt_`i' = 0 if missing(team_cnt_`i')
		bysort medparid: egen team_experience_`i' = mean(team_cnt_`i')
	}
	
	*** physicians' own experience
	g n_P2A = (P2A == 1)
	g n_P2D = (P2D == 1)
	
	forvalues i = 1/3{
		foreach x in P2A P2D{
			rangestat (sum) phy_`x'_cnt_`i'y=n_`x', interval(expnsdt1, low`i', high) by(prf_npi)
			replace phy_`x'_cnt_`i'y = 0 if missing(phy_`x'_cnt_`i'y) & !missing(prf_npi) & !missing(npi_surgeon)
		/* proceduralists who perform PCI and CABG are distinct sets of doctors, 
		* hence shared work experience is the same regardless of rangestat by(prf_npi npi_surgeon)
		* or rangestat by(prf_npi npi_surgeon) for PCI and CABG separately;
		* physicians can provide hospital care to both PCI and CABG patients, hence
		* rangestat by (prf_npi npi_surgeon) for PCI and CABG separately to count 
		* experience in PCI and CABG separately
		*/
		}
	}	
	
	forvalues i = 1/3{	
		bysort medparid: egen phy_P2D_experience_`i'y= mean(phy_P2D_cnt_`i'y)
		bysort medparid: egen phy_P2A_experience_`i'y= mean(phy_P2A_cnt_`i'y)
		
		g phy_experience_`i'y = phy_P2D_experience_`i'y if P2D == 1
		replace phy_experience_`i'y = phy_P2A_experience_`i'y if P2A == 1
	}				
	
	*** identify the main physician 
	bysort medparid prf_npi: egen t_n = total(n)
	bysort medparid prf_npi: egen t_allowchrg = total(lalowchg)
	gsort medparid -t_n -t_allowchrg prf_npi
	by medparid: g prf_npi1 = prf_npi[1]
		
	*** alternative measures of shared/individual work experience
	* mode/median	
	bysort medparid: egen team_experience_mode = mode(team_cnt_2), maxmode
	bysort medparid: egen team_experience_med = median(team_cnt_2)
 
	foreach x in mode med{
		g phy_experience_`x'_temp = phy_P2A_cnt_2y if P2A ==1 & team_experience_`x' == team_cnt_2
		replace phy_experience_`x'_temp = phy_P2D_cnt_2y if P2D ==1 & team_experience_`x' == team_cnt_2
		gsort medparid -phy_experience_`x'_temp 
		by medparid: g phy_experience_`x' = phy_experience_`x'_temp[1]  
	}
	* -stays with even number of claims have a median team experience that is the average of the middle two observations
	* -hence update the median individual experience accordingly
	bysort medparid: egen N = count(medparid)
	gsort medparid -phy_P2A_cnt_2y
	by medparid: replace phy_experience_med = (phy_P2A_cnt_2y[N/2]+phy_P2A_cnt_2y[N/2+1])/2 if P2A==1 & missing(phy_experience_med)
	gsort medparid -phy_P2D_cnt_2y 
	by medparid: replace phy_experience_med = (phy_P2D_cnt_2y[N/2]+phy_P2D_cnt_2y[N/2+1])/2 if P2D==1 & missing(phy_experience_med)
	
	* first physician
	gsort medparid expnsdt1 -lalowchg prf_npi
	by medparid: g prf_npi_1st = prf_npi[1]	
	by medparid: gen team_experience_2_1st = team_cnt_2[1]
	
	g phy_experience_1st_temp = phy_P2A_cnt_2y if P2A ==1 
	replace phy_experience_1st_temp = phy_P2D_cnt_2y if P2D ==1

	gsort medparid expnsdt1 -lalowchg prf_npi
	by medparid: gen phy_experience_1st = phy_experience_1st_temp[1]	
	drop phy_experience_1st_temp
		
	* decay parameter, shared work experience
	bysort npi_surgeon prf_npi: egen cnt = total(!missing(admsndt))	
	foreach x in 10 15 20 25{
		cap drop temp*
		su cnt if P2A == 1 | P2D == 1
		forvalue i = 1/`r(max)'{
			sort npi_surgeon prf_npi admsndt expnsdt1
			by npi_surgeon prf_npi: gen temp_`i' =exp(`x'*(expnsdt1[_n-`i']-admsndt)/3650)*(medparid[_n-`i'] != medparid)*(expnsdt1[_n-`i'] < admsndt)
		}
		egen team_cnt_decay_`x'= rowtotal(temp*)
		assert !missing(team_cnt_decay_`x')
		bysort medparid: egen team_experience_decay_`x' = mean(team_cnt_decay_`x')
	}		
	drop temp*

	* decay parameter, physician individual work experience
	bysort prf_npi P2A: egen cnt_phy = total(!missing(admsndt))	
	foreach x in 10 15 20 25{
		cap drop temp*
		su cnt_phy if P2A == 1 | P2D == 1
		forvalue i = 1/`r(max)'{
			sort prf_npi P2A admsndt expnsdt1
			by prf_npi P2A: gen temp_`i' =exp(`x'*(expnsdt1[_n-`i']-admsndt)/3650)*(medparid[_n-`i'] != medparid)*(expnsdt1[_n-`i'] < admsndt)
		}
		egen phy_cnt_decay_`x'= rowtotal(temp*)
		assert !missing(phy_cnt_decay_`x')
		bysort medparid: egen phy_experience_decay_`x' = mean(phy_cnt_decay_`x')
	}		
	drop temp*
	
	*** M2A/M2B observations during the hospital stay
	bysort medparid: egen expnsdt1_min = min(expnsdt1)	
	bysort medparid: egen expnsdt2_max = max(expnsdt2)	
	g full_1 = (expnsdt1_min <= (admsndt+2) & expnsdt2_max >= (dschrgdt-2)) if !missing(admsndt) & !missing(expnsdt2_max)
	g full_2 = (expnsdt1_min <= (admsndt+1) & expnsdt2_max >= (dschrgdt-2)) if !missing(admsndt) & !missing(expnsdt2_max)
	g full = full_1 if P2A
	replace full = full_2 if P2D
	
	drop low* high*
save "${OUTPUT}/team_experience_panel", replace		


use "${OUTPUT}/team_experience_panel", replace
	
	*** shared work experience
	g low2 = admsndt-365*2
	g high = admsndt-1
	rangestat (sum) team_cnt_ed_2=er, interval(expnsdt1, low2, high) by(prf_npi npi_surgeon)
	replace team_cnt_ed_2 = 0 if missing(team_cnt_ed_2)	
	assert !missing(team_cnt_ed_2)
	bysort medparid: egen team_experience_ed_2 = mean(team_cnt_ed_2)

	*** physicians' own experience	
	g ed_P2A = er*(P2A == 1)
	g ed_P2D = er*(P2D == 1)		
	foreach x in P2A P2D{
		rangestat (sum) phy_`x'_cnt_ed_2y=ed_`x', interval(expnsdt1, low2, high) by(prf_npi)	
		replace phy_`x'_cnt_ed_2y = 0 if missing(phy_`x'_cnt_ed_2y) & !missing(prf_npi) & !missing(npi_surgeon)
		assert !missing(phy_`x'_cnt_ed_2y)
		bysort medparid: egen phy_`x'_experience_ed_2y= mean(phy_`x'_cnt_ed_2y)
	}		
	g phy_experience_ed_2y = phy_P2D_experience_ed_2y if P2D == 1
	replace phy_experience_ed_2y = phy_P2A_experience_ed_2y if P2A == 1	
	
	drop low* high ed_P2A ed_P2D
	
save "${OUTPUT}/team_experience_panel", replace	

*----------------------------*
* generate hospital-specific experience
*----------------------------*
*** link proceduralists/physicians with hospitals
forvalues i = 2008/2016{	
	use "${OUTPUT}/team_experience_panel", replace	
		keep prf_npi		
		append using "${OUTPUT}/team_experience_surgeon", keep(npi_surgeon)
		replace prf_npi = npi_surgeon if missing(prf_npi)
		drop if missing(prf_npi)
		keep prf_npi
		duplicates drop
		
		merge 1:m prf_npi using "${INPUT}/car/`i'/carl`i'.dta", keepusing(bene_id expnsdt1 expnsdt2 betos hcpcs_cd plcsrvc mdfr_cd* lsbmtchg lalowchg) keep(3) nogen
		joinby bene_id using "${OUTPUT}/med`i'.dta"
		
		* drop lalowchg = 0
		drop if lalowchg == 0
		* drop care after discharge date or before admission date
		drop if expnsdt1 > dschrgdt
		drop if expnsdt1 < admsndt
		
		keep prf_npi bene_id expnsdt1 expnsdt2 betos hcpcs_cd plcsrvc mdfr_cd* lsbmtchg lalowchg medparid prvdrnum dschrgdt admsndt
		
	save "${OUTPUT}/hospexp_`i'.dta", replace	
}	

*** generate hospital-specific experience	
use "${OUTPUT}/hospexp_2008.dta", clear
	
	forvalues i = 2009/2016{
		append using "${OUTPUT}/hospexp_`i'.dta"
	}
	sort prf_npi medparid expnsdt1
	by prf_npi medparid: gen tag_pat = _n
	replace tag_pat = 0 if tag_pat != 1

	g low = admsndt-365*2
	g high = admsndt-1
	g low_yr1 = admsndt-365
	g high_yr1 = admsndt-1
	g low_yr2 = admsndt-365*2
	g high_yr2 = admsndt-1-365	
	
	rangestat (sum) hosp_pat=tag_pat, interval(expnsdt1, low, high) by(prf_npi prvdrnum)	
	rangestat (sum) hosp_yr1=tag_pat, interval(expnsdt1, low_yr1, high_yr1) by(prf_npi prvdrnum)	
	rangestat (sum) hosp_yr2=tag_pat, interval(expnsdt1, low_yr2, high_yr2) by(prf_npi prvdrnum)	
	
	foreach x in hosp_pat hosp_yr1 hosp_yr2{
		replace `x' = 0 if missing(`x')
	}
	
	keep prf_npi prvdrnum medparid hosp_pat hosp_yr1 hosp_yr2 
	duplicates drop 
	
save "${OUTPUT}/hospexp.dta", replace

use "${OUTPUT}/hospexp.dta", replace
	
	* proceduralists' hospital-specific experience
	ren prf_npi npi_surgeon
	merge 1:m npi_surgeon prvdrnum medparid using "${OUTPUT}/team_experience_panel", keep(2 3) nogen
	
	foreach x in pat yr1 yr2{
		ren hosp_`x' hosp_`x'_s
		sort medparid hosp_`x'_s
		by medparid: assert hosp_`x'_s[1] == hosp_`x'_s[_N]
		bysort medparid: egen hosp`x'_surgeon = max(hosp_`x'_s)
	}
	replace hosppat_surgeon = 0 if missing(hosppat_surgeon)	
	g hospyr_surgeon = (hospyr1_surgeon >= 1 & !missing(hospyr1_surgeon))+(hospyr2_surgeon >= 1 & !missing(hospyr2_surgeon))
	
	* physicians' hospital-specific experience
	merge m:1 prf_npi prvdrnum medparid using "${OUTPUT}/hospexp.dta", keep(1 3) nogen  
	foreach x in pat yr1 yr2{
		ren hosp_`x' hosp_`x'_p
	}
	bysort medparid: egen hosppat_phy = mean(hosp_pat_p)
	bysort medparid: egen hospyr_phy = mean((hosp_yr1_p >= 1 & !missing(hosp_yr1_p))+(hosp_yr2_p >= 1 & !missing(hosp_yr2_p)))	
		
save "${OUTPUT}/team_experience_panel", replace

*** erase temp files
forvalues i = 2008/2016{
	erase "${OUTPUT}/hospexp_`i'.dta"
}
	
*--------------------------------*
* keep observations unique at the hospital stay level
*--------------------------------*
use "${OUTPUT}/team_experience_panel", replace
	
	keep medparid *_experience_* surgery_cnt* P2A P2D mul_surgeon npi_surgeon prf_npi1 surgery_dt_max surgery_dt_min hosppat_* hospyr_* full surgeon_decay*
	cap drop *temp*
	duplicates drop
	isid medparid
	
save "${OUTPUT}/team_experience", replace


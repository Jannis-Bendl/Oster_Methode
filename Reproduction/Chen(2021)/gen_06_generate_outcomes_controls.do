/*******************************************************************************
PURPOSE: Generate outcome and control variables for analysis
*******************************************************************************/
*-------------------------------*
* generate outcome variables
*-------------------------------*	
use "${OUTPUT}/team_analysis", clear	
	
	*** 30-day mortality
	merge m:1 bene_id using "${OUTPUT}/death.dta", nogen keep(1 3)
	g die_30 = (death_dt1<=(dschrgdt+30) | death_dt2<=(dschrgdt+30)) if !missing(dschrgdt)
	
	*** number of tests and exams
	merge 1:1 medparid using "${OUTPUT}/testexam", keep(1 3) nogen keepusing(testexam_cnt)
	replace testexam_cnt = 0 if missing(testexam_cnt)
	
	*** outlier payments
	g outlier = (outlramt > 0) if !missing(outlramt)
				
	*** discharge destination
	g snf = inlist(dstntncd, "03", "04", "62", "64") if !missing(dstntncd)
	
save "${OUTPUT}/team_analysis", replace
	
	*** readmissions	
use "${OUTPUT}/med2010.dta", clear
	
	keep bene_id medparid admsndt dschrgdt sslssnf
	forvalues i = 2011/2016{
		append using "${OUTPUT}/med`i'.dta", keep(bene_id medparid admsndt dschrgdt sslssnf)
	}	
	duplicates drop
	merge 1:1 medparid using "${OUTPUT}/team_analysis"
	keep if _merge == 3 | (_merge !=3 & (sslssnf == "L" | sslssnf == "S"))
	drop sslssnf
	
	gsort bene_id admsndt dschrgdt -_merge
	by bene_id: g readm_30=((admsndt[_n+1]-dschrgdt)<=30 & (admsndt[_n+1]-dschrgdt)>1 & bene_id==bene_id[_n+1]) if _merge == 3
	drop if _merge == 1
	drop _merge

save "${OUTPUT}/team_analysis", replace

	*** post-discharge physician office/ED visits in carrier file
use "${INPUT}/car/2010/carl2010.dta", clear
	
	keep if inlist(betos, "M1A", "M1B", "M3")
	
	forvalues i = 2011/2016{
		append using "${INPUT}/car/`i'/carl`i'.dta"	
		keep if inlist(betos, "M1A", "M1B", "M3")
	}
	
	keep bene_id clm_id line_num betos expnsdt1 expnsdt2 prf_npi prv_type hcfaspcl hcpcs_cd lalowchg
	joinby bene_id using "${OUTPUT}/team_analysis" 
	
	keep bene_id clm_id line_num betos expnsdt1 expnsdt2 prf_npi prv_type hcfaspcl hcpcs_cd lalowchg medparid dschrgdt admsndt 
	keep if expnsdt2 <= dschrgdt+30 & expnsdt1 > dschrgdt & !missing(expnsdt1)
	
	* drop claims by non-dcotors
	drop if inlist(hcfaspcl, "32", "41", "42", "43", "45", "50", "59", "73") | inlist(hcfaspcl, "80", "89", "96", "97", "B5", "C1", "C5")
	keep if prv_type == "1"
	
	keep bene_id expnsdt1 expnsdt2 medparid dschrgdt 
	duplicates drop
	bysort medparid: egen postchrgvisit = count(expnsdt1)
	keep medparid postchrgvisit
	duplicates drop
	
	merge 1:1 medparid using "${OUTPUT}/team_analysis", keep(2 3) nogen
	replace postchrgvisit = 0 if missing(postchrgvisit)
	
save "${OUTPUT}/team_analysis", replace

*-------------------------------*
* generate controls for regressions
*-------------------------------*	
use "${OUTPUT}/team_analysis", clear	

	*** age
	egen age_gp = cut(age) if age >= 65 & age <= 100, at(65, 70, 75, 80, 85, 90, 95, 101)
	/*group age 100 to the last age group*/
	
	*** gender
	g female = (sex == "2") if sex == "1" | sex == "2"
	
	*** race
	g black = (race == "2") if !missing(race)
	g hispanic = (race == "5") if !missing(race)
	
	*** Medicaid coverage
	g medicaid = (buyin_mo>0) if buyin_mo<99	
	
	*** disability and ESRD status
	destring orec crec, replace force
	g disable = (orec == 1 | orec == 3 | crec == 1 | crec == 3)
	g esrd = (orec == 2 | orec == 3 | crec == 2 | crec == 3)
	
	*** chronic conditions	
	foreach x in alzhdmt chrnkdn diabtes copd chf strktia cncrbrs cncrclr cncrprs cncrlng cncendm{
		gen `x'_dummy=(`x'e<admsndt) if admsndt != .
	}
	
	g cancer_dummy = (cncrbrs_dummy == 1 | cncrclr_dummy == 1 | cncrprs_dummy == 1 | cncrlng_dummy == 1 | cncendm_dummy == 1)
	drop cn*dummy
	egen cc = rowtotal(alzhdmt_dummy chrnkdn_dummy diabtes_dummy copd_dummy chf_dummy strktia_dummy cancer_dummy esrd)	
	
	*** admission time categories
	g month = month(admsndt)
	g dow = dow(admsndt)
	
	*** physician specialty share
	* top 5 non-cardiology specliaties for CABG: 11, 29, 39, 46, 44
	* top 5 non-cardiology specliaties for PCI: 11, 39, 29, 08, 93
	local i = 1
	foreach x in 11 29 39 46 44{
		g shrrank_`i' = shr_`x' if P2A == 1
		local i = `i'+1
	}
	
	local i = 1
	foreach x in 11 29 39 46 44{
		g shrrank_other_`i' = shr_other_`x' if P2A == 1
		local i = `i'+1
	}
	
	local i = 1	
	foreach x in 11 29 39 08 93{
		replace shrrank_`i' = shr_`x' if P2D == 1
		local i = `i'+1	
	}	

	local i = 1	
	foreach x in 11 29 39 08 93{
		replace shrrank_other_`i' = shr_other_`x' if P2D == 1
		local i = `i'+1	
	}
	
	* observations with missing values
	forvalue i = 1/5{
		g shrrank_other_`i'_miss = (missing(shrrank_other_`i'))
		replace shrrank_other_`i' = 0 if missing(shrrank_other_`i')
	}
	
	g shrrank_other_miss = shrrank_other_1_miss
	drop shrrank_other_?_miss
	
	foreach x in female_other_attphy_avg age_other_attphy_avg yrprac_other_attphy_avg medrank1_other_attphy_avg medrank2_other_attphy_avg medrank3_other_attphy_avg medrank4_other_attphy_avg{	
		g `x'_miss = (missing(`x'))
		replace `x' = 0 if missing(`x')
	}
	
	g medrank_other_attphy_avg_miss = medrank1_other_attphy_avg_miss
	drop medrank?_other_attphy_avg_miss
	
	foreach x in female_attphy_avg age_attphy_avg yrprac_attphy_avg medrank1_attphy_avg medrank2_attphy_avg medrank3_attphy_avg medrank4_attphy_avg{
		g `x'_miss = (missing(`x'))
		replace `x' = 0 if missing(`x')
	}
	
	*** keep observations with an at-least 30-day observation window after the discharge to measure 30-day mortality
	replace die_30 = . if (20819-dschrgdt)<30 /* 20819 is the date value of December 31, 2016, i.e., the last day of data observation */
	drop if missing(die_30)
	replace die_30 = die_30*100
	
	*** length of stay: exclude observations died during the hospital stay
	replace loscnt = . if (death_dt1<=(dschrgdt+1) | death_dt2<=(dschrgdt+1)) & dschrgdt != .
	/* set the threshold as dschrgdt+1 (instead of dschrgdt) in case slight error in data reporting */
	
	label var team_experience_2 "Shared work experience"	
	destring npi_surgeon prf_npi1 prvdrnum, replace force
	
save "${OUTPUT}/team_analysis_final", replace



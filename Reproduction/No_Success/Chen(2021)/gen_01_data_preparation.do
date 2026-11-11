/*******************************************************************************
PURPOSE: Prepare datasets for analysis
*******************************************************************************/
*-------------------------------*
* obtain death dates
*-------------------------------*
use "${INPUT}/bsf/2008/bsfab2008.dta", clear
	
	keep bene_id death_dt
	keep if !missing(death_dt)
	
	forvalues i = 2009/2016{
		append using "${INPUT}/bsf/`i'/bsfab`i'.dta", keep(bene_id death_dt)
		keep if !missing(death_dt)
	}
	
	* a few observations with two diffferent death dates in the Medicare Beneficiary Summary File, include both
	duplicates drop
	bysort bene_id: gen n = _n
	ta n, miss /*maximum n is 2*/
	reshape wide death_dt, i(bene_id) j(n)
	
save "${OUTPUT}/death.dta", replace	
	
*-------------------------------*
* update MedPAR data 
*-------------------------------*
*** A small number of hospital stays split into different claims or duplicate in the raw data, hence update them
forvalues i = 2008/2016{
	use "${INPUT}/med/`i'/med`i'.dta", clear
	
		g adjacent = .
		sort bene_id prvdrnum admsndt dschrgdt 
		replace adjacent = 1 if bene_id == bene_id[_n-1] & prvdrnum == prvdrnum[_n-1] & admsndt[_n-1] <= admsndt & admsndt < = dschrgdt[_n-1]
		replace adjacent = 0 if bene_id == bene_id[_n+1] & prvdrnum == prvdrnum[_n+1] & admsndt <= admsndt[_n+1] & admsndt[_n+1] < = dschrgdt
		ta adjacent, miss
	 
		sort bene_id prvdrnum admsndt adjacent 
		by bene_id prvdrnum: replace admsndt = admsndt[_n-1] if bene_id == bene_id[_n-1] & prvdrnum == prvdrnum[_n-1] & adjacent[_n-1] ==0 & adjacent !=. & admsndt[_n-1] <= admsndt & admsndt < = dschrgdt[_n-1]
		drop if adjacent == 0
		drop if dschrgdt == .		
		g los = dschrgdt - admsndt
		* drop a few outliers that are unlikely to be the case
		drop if los>=100
	
	save "${OUTPUT}/med`i'.dta", replace	
}

*-------------------------------*
* generate number of exams/tests during the hospital stay
*-------------------------------*
*** generate data for each year
forvalues i=2010/2016{
	use "${INPUT}/car/`i'/carl`i'.dta", clear
		
		keep bene_id expnsdt1 expnsdt2 betos hcpcs_cd prf_npi plcsrvc lsbmtchg lalowchg 
		keep if substr(betos, 1, 1) == "I" | substr(betos, 1, 1) == "T" 
		
		duplicates drop 		
		joinby bene_id using "${OUTPUT}/med`i'.dta"
		
		keep if (admsndt<=expnsdt1 & dschrgdt>=expnsdt2) 	
		bysort medparid: egen testexam_cnt= count(betos)
		
		keep medparid admsndt testexam_*
		duplicates drop
		isid medparid
		
	save "${OUTPUT}/testexam_`i'", replace
}

*** append different years of data together
use "${OUTPUT}/testexam_2010", clear
	
	forvalues i = 2011/2016{
		append using "${OUTPUT}/testexam_`i'"
	}
	
	keep medparid testexam_*
	
save "${OUTPUT}/testexam", replace	

*** erase temp files
forvalues i = 2010/2016{
	erase "${OUTPUT}/testexam_`i'.dta"
}

*-----------------------------*
* revenue center codes in the outpatient file
*-----------------------------*
use "${INPUT}/op/2008/opr2008.dta", clear 
	
	keep bene_id thru_dt rev_cntr
	keep if inlist(rev_cntr, "0450", "0451", "0452", "0456", "0459", "0981")
	forvalues i = 2009/2016{
		append using "${INPUT}/op/`i'/opr`i'.dta", keep(bene_id thru_dt rev_cntr)
		keep if inlist(rev_cntr, "0450", "0451", "0452", "0456", "0459", "0981")
	}
	ta rev_cntr, miss
	keep bene_id thru_dt
	duplicates drop
	g op_er = 1
	
save "${OUTPUT}/op_ed", replace	

		

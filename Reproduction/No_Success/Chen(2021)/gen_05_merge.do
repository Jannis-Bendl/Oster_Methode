/*******************************************************************************
PURPOSE: Merge data for constructing analysis datasets
*******************************************************************************/

*** merge in experience
use "${OUTPUT}/med2008.dta", clear
	cap drop year
	g year = 2008
	
	forvalues i = 2009/2016{
		append using "${OUTPUT}/med`i'.dta"
		replace year = `i' if missing(year)
	}	
	ta year, miss
	merge 1:1 medparid using "${OUTPUT}/team_experience", keep(2 3) nogen
	
save "${OUTPUT}/team_analysis", replace

*** merge in patient demographics
use "${INPUT}/bsf/2008/bsfab2008.dta", clear
	keep bene_id state_cd cnty_cd bene_zip age bene_dob orec crec esrd_ind buyin_mo hmo_mo
	destring hmo_mo buyin_mo, replace 
	g year = 2008
	forvalues i = 2009/2016{
		cap append using "${INPUT}/bsf/`i'/bsfab`i'.dta", keep(bene_id state_cd cnty_cd bene_zip age bene_dob orec crec esrd_ind buyin_mo hmo_mo)
		cap append using "${INPUT}/bsf/`i'/bsfab`i'.dta", keep(bene_id state_cd cnty_cd zip_cd age bene_dob orec crec esrd_ind buyin_mo hmo_mo)
		destring hmo_mo buyin_mo, replace 
		replace year = `i' if missing(year)
	}	
	ta year, miss
	
	* the raw data include a small number of beneficiaries with duplicated observations within one year, hence update
	duplicates drop 
	gsort bene_id year -buyin_mo -hmo_mo state_cd cnty_cd age bene_dob orec crec esrd_ind
	by bene_id year: g n = _n
	keep if n == 1
	drop n
	
	merge 1:m bene_id year using "${OUTPUT}/team_analysis", keep(2 3) nogen
	
save "${OUTPUT}/team_analysis", replace

*** merge in chronic conditions
use "${INPUT}/bsf/2008/bsfcc2008.dta", clear
	g year = 2008
	forvalues i = 2009/2016{
		append using "${INPUT}/bsf/`i'/bsfcc`i'.dta"
		replace year = `i' if missing(year)
	}
	
	ta year, miss
	keep bene_id year *e
	merge 1:m bene_id year using "${OUTPUT}/team_analysis", keep(2 3) nogen

save "${OUTPUT}/team_analysis", replace

*** merge in doctor characteristics
use "${OUTPUT}/team_analysis", clear
	merge 1:1 medparid using "${OUTPUT}/team_doccharacteristics", keepusing(*avg shr_*) update replace nogen		
save "${OUTPUT}/team_analysis", replace

*** restrict sample to 2010 and after to allow for an at least 2-year look-back 
*** window for measuring shared work experience in the past two years
use "${OUTPUT}/team_analysis", clear
	drop if year < 2010
save "${OUTPUT}/team_analysis", replace

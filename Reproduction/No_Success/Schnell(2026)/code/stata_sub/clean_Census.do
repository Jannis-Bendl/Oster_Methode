***********************************************************************
*----------------- Clean County Population Estimates -----------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Read in raw data, save as .dta
   
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*
	
	local file_0010 "co-est00int-tot"
	local file_1019 "co-est2019-alldata"
	
***********************************************************************
*-------------------------- a. Read in data --------------------------*
***********************************************************************

foreach y in 0010 1019 {

	import delimited using "${raw_public}/census/`file_`y''.csv", clear
	keep state county pop* 
	drop if county == 0

	* Format county_fips (5 digits, string)
	tostring state, replace force format(%02.0f)
	tostring county, replace force format(%03.0f)
	gen county_fips = state + county 
	drop state county
	
	reshape long popestimate, i(county_fips) j(year)
	rename popestimate pop_tot
	
	if `y' == 0010 {
		drop if year < 2006 | year == 2010
	}
	if `y' == 1019 {
		drop if year > 2014
		append using "${inter}/county_year_pop_0614.dta"
		sort county_fips year
		
		* Drop five counties not in all years 
		* - 02158, 02270, 46102, 46113, 51515
		bys county_fips: gen n = _N
		keep if n == 9 
		drop n
	}
	save "${inter}/county_year_pop_0614.dta", replace
}

	

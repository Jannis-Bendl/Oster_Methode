
cap log close _all
log using log/C0_stata_clean.log, replace

***********************************************************************
*-------------------------- CLEAN RAW DATA ---------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

This .do file produces the following files: 

	ACS 
	- ${inter}/ACS_county_demos_1014.dta
	- ${inter}/ACS_county_NSDUH_1014.dta		<- erased once NSDUH cleaned below
	- ${inter}/ACS_county_NHIS_2014.dta			<- erased once NHIS cleaned below
	
	Census
	- ${inter}/county_year_pop_0614.dta
	
	IQVIA
	- ${inter}/provider_month_opioids_0614.dta
	- ${inter}/provider_month_copays_0614.dta
	- ${inter}/provider_month_patientchars_0614.dta
	- ${inter}/provider_chars_cleaned.dta
	- ${inter}/county_month_opioids_0614.dta
	- ${inter}/provider_year_LRx_0614.dta
	
	NHIS
	- ${inter}/NHIS_clean_2014.dta			
	- ${inter}/NHIS_region_year_2014.dta
 	- ${inter}/NHIS_county_year_2014.dta
	- ${inter}/NHIS_NSDUH_R2.dta			
	
	NIBRS
	- ${inter}/NIBRS_county_month_0614.dta
	- ${inter}/NIBRS_county_year_0614.dta
	
	NSDUH
	- ${inter}/NSDUH_clean_0614.dta			
	- ${inter}/NSDUH_state_year_1314.dta
	- ${inter}/NSDUH_county_year_1314.dta
	- ${inter}/provider_misuse_2009.dta
	
	NVSS 
	- ${inter}/NVSS_county_year_0614.dta
		
	Reimbursement 
	- ${inter}/R_provider_2014.dta
	
	StreetRx
	- ${inter}/StreetRx_clean_2014.dta
	- ${inter}/StreetRx_state_year_2014.dta

*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------ Define Directories -------------------------*
*---------------------------------------------------------------------*

	do C00_stata_setup.do
	
***********************************************************************
*------------------------------- CLEAN -------------------------------* 
***********************************************************************

	*---------- ACS ----------*
	* Raw data files provided in ${raw_public}/acs
	do "${code}/stata_sub/clean_5yrACS.do"
	
	*--------- Census --------*
	* Raw data files provided in ${raw_public}/census
	do "${code}/stata_sub/clean_Census.do"

	*--------- IQVIA ---------*
	* Restricted access: raw data files not provided
	do "${code}/stata_sub/clean_IQVIA.do"
	
	*---------- NHIS ---------*
	* Raw data files provided in ${raw_public}/nhis
	do "${code}/stata_sub/clean_NHIS.do"
	
	*--------- NIBRS ---------*
	* Raw data files provided in ${raw_public}/nibrs
	do "${code}/stata_sub/clean_NIBRS.do"
	
	*--------- NSDUH ---------*
	* Raw data files provided in ${raw_public}/nsduh
	do "${code}/stata_sub/clean_NSDUH.do"
	
	*---------- NVSS ---------*
	* Restricted access: raw data files not provided
	do "${code}/stata_sub/clean_NVSS.do"
	
	*----- Reimbursement -----*
	* Raw data files provided in ${raw_public}/reimbursement
	do "${code}/stata_sub/clean_reimbursement.do"
	
	*-------- StreetRx -------*
	* Restricted access: raw data files not provided
	do "${code}/stata_sub/clean_StreetRx.do"

***********************************************************************

log close

	

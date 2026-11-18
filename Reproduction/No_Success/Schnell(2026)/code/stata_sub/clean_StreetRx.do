***********************************************************************
*------------------------ Clean StreetRx Data ------------------------* 
***********************************************************************

/*-------------------------- OVERVIEW --------------------------------*

a. Clean data
   - Read in raw data 
   - Clean products (only keep opioid pills, add MME factors)
   - Clean prices
   - Clean dates (reported within one year)
   - Clean locations (only US states) 

b. Create geographic aggregates 

*--------------------------------------------------------------------*/

***********************************************************************
*--------------------------- a. Clean data ---------------------------*
***********************************************************************	

insheet using "${raw_SRx}/PU_201605.csv", clear

	rename generic drug
	rename selected_product_name product

	* Drop unnecessary variables (all quotes in US) 
	drop quote country source
	
*--------------------------- Clean products --------------------------*

	* Only keep prescription opioids (48.44% of quotes)
	keep if drug == "benzhydrocodone" | drug == "buprenorphine" | drug == "butorphanol" | drug == "codeine" | ///
		drug == "dihydrocodeine" | drug == "fentanyl" | drug == "fentanyl citrate" | drug == "hydrocodone" | ///
		drug == "hydrocodone/acetaminophen" | drug == "hydromorphone" | drug == "levorphanol" | drug == "meperidine" | ///
		drug == "methadone" | drug == "morphine" | drug == "morphine/oxycodone" | drug == "oxycodone" | ///
		drug == "oxymorphone" | drug == "pentazocine" | drug == "propoxyphene" | drug == "sufentanil" | ///
		drug == "tapentadol" | drug == "tramadol"

	* Only keep pill/tablet formulations (96.74% of quotes)
	* Drops butorphanol, dihydrocodeine, fentanyl citrate, sufentanil
	keep if formulation == "pill/tablet"
	* Only keep if dosage expressed in mg or mg/mg (others erroneously coded as pill/tablet; 99.16% of quotes)
	keep if dose_unit == "mg" | dose_unit == "mg/mg"
	drop formulation dose_unit

	* Add MME conversion factors
	* From https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Opioid-Morphine-EQ-Conversion-Factors-Aug-2017.pdf
	gen mme_factor = . 
	replace mme_factor = 30 if drug == "buprenorphine"
	replace mme_factor = 0.15 if drug == "codeine"
	replace mme_factor = 1 if drug == "hydrocodone" | drug == "hydrocodone/acetaminophen"
	replace mme_factor = 4 if drug == "hydromorphone"
	replace mme_factor = 11 if drug == "levorphanol"
	replace mme_factor = 0.1 if drug == "meperidine"
	replace mme_factor = 4 if drug == "methadone" & mg_strength <= 20 
	replace mme_factor = 8 if drug == "methadone" & mg_strength > 20 & mg_strength <= 40
	replace mme_factor = 10 if drug == "methadone" & mg_strength > 40 & mg_strength <= 60
	replace mme_factor = 12 if drug == "methadone" & mg_strength > 60
	replace mme_factor = 1 if drug == "morphine"
	replace mme_factor = 1.5 if drug == "oxycodone"
	replace mme_factor = 3 if drug == "oxymorphone"
	replace mme_factor = 0.4 if drug == "tapentadol"
	replace mme_factor = 0.1 if drug == "tramadol"
	
	* Drop products not included in conversion table (0.12% of quotes)
	* Drops benzhydrocodone (5 quotes), fentanyl (in mg, 35 quotes), pentazocine (34 quotes), propoxyphene (66 quotes)
	drop if mme_factor == . & drug != "morphine/oxycodone"

	* Create MME per quote
	rename mg_strength mg 
	gen mme = mg*mme_factor
	* Adjust morphine/oxycodone
	gen dose2 = subinstr(dose,"mg","",.)
	split dose2, p("/")
	forvalues v = 1/2 {
		destring dose2`v', replace
	}
	replace mme = dose21*1 + dose22*1.5 if drug == "morphine/oxycodone"
	drop dose* mme_factor

*---------------------------- Clean prices ---------------------------*

	* Construct price per mg
	drop price_per_mg
	replace price = subinstr(price,"$","",.)
	destring price, replace 
	gen price_mg = price/mg
	
	* Create price per MME
	gen price_mme = price/(mme)
	drop price 

*---------------------------- Clean dates ----------------------------*

	rename submitted_date date_s
	rename price_date date_p

	foreach v in s p {
		gen month_`v' = substr(date_`v',1,2)
		replace month_`v' = subinstr(month_`v',"/","",.)
		gen year_`v' = substr(date_`v',-2,2)
		destring month_`v', replace
		destring year_`v', replace
		replace year_`v' = year_`v' + 1900 if year_`v' > 18
		replace year_`v' = year_`v' + 2000 if year_`v' <= 18
		drop date_`v'
		gen date_`v' = ym(year_`v', month_`v')
	}
	
	* Only keep quotes reported within one year (99.56% of quotes)
	drop if (date_s - date_p > 12) | (date_p > date_s)
	
	* Only keep date of price quote
	drop year_s month_s date_s
	foreach v in year month date {
		rename `v'_p `v'
	}
	
*-------------------------- Clean locations --------------------------*

	* Convert shapefile (assumes you have counties.shp/.dbf/.shx in your working dir)
	chdir "${raw_public}/geo"
	shp2dta using tl_2014_us_county, database(county_database) coordinates(county_coords) genid(_ID) replace
	
	* Extract state and county fips
	drop state
	geoinpoly lat lon using "${raw_public}/geo/county_coords.dta"
	* 99.93% matched in master
	merge m:1 _ID using "${raw_public}/geo/county_database.dta", nogen keep(matched) keepusing(STATEFP COUNTYFP)
	
	rename STATEFP state_fips
	rename COUNTYFP county_fips 
	replace county_fips = state_fips + county_fips
	
	* Only keep quotes from US states (99.88% of quotes)
	destring state_fips, replace
	statastates, fips(state_fips)
	keep if _merge == 3 
	
	drop _ID state_abbrev _merge
	keep if year == 2014
	
	erase "${raw_public}/geo/county_database.dta"
	erase "${raw_public}/geo/county_coords.dta"

*------------------ Create percentiles for trimming ------------------*

	foreach v in 5 95 {
		egen p`v' = pctile(price_mme), p(`v')
	}
	gen trimmed = price_mme > p5 & price_mme < p95
	drop p5 p95 

save "${inter}/StreetRx_clean_2014.dta", replace 

****************************************************************************
*------------------------ b. Geographic aggregates ------------------------*
****************************************************************************	

use "${inter}/StreetRx_clean_2014.dta", replace 

	gen price_mme_trimmed = price_mme*trimmed
	
	foreach v in state county {
	
		preserve
		collapse (sum) price_mme=price_mme_trimmed n=trimmed, by(`v'_fips year) fast 	
		replace price_mme = price_mme/n
	
		save "${inter}/StreetRx_`v'_year_2014.dta", replace
		restore
	}
	

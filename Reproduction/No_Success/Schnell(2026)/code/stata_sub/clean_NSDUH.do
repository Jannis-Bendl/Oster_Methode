***********************************************************************
*------------------------- Clean NSDUH Data --------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Clean state estimates (2013-2014)

b. Clean single years (2006-2014)
   - Note: sources asked 2005+, opioid variables changed 2015+
   - only keep key variables 
   - construct desired categories
   
c. Create county misuse (2013-2014)
   - create necessary indicators
   - regress misuse on indicators 
   - predict misuse in the ACS
   
d. Create individual provider misuse (2009)
   - create necessary indicators
   - regress misuse on indicators 
   - predict misuse in IQVIA data 
  
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*
	
	tempfile state
	tempfile main
	
***********************************************************************
*---------------- a. Clean state estimates (2013-2014) ---------------*
***********************************************************************	

import excel using "${raw_public}/nsduh/NSDUH_state_raw_1314.xlsx", clear firstrow
	
	drop level_thous D 
	drop if State == "" 
	rename percent misuse_perc_all
	
	statastates, name(State) nogen
	keep state_fips misuse_perc_all
	gen year = 1314
	
	save `state', replace	

***********************************************************************
*----------------- b. Clean single years (2006-2014) -----------------*
***********************************************************************	

forvalues y = 2006/2014 { 

	use "${raw_public}/nsduh/NSDUH_`y'.dta", clear 
	
	rename *, lower
	keep iranlrc iranlfy anllts anlsrcf* age2 irsex newrace2 analwt_c educcat ///
	     empstaty irpinc3 irfamin3 poverty2 irinsur4 irmarit
	    
	* Two versions (one with missings combined) in 2013
	if `y' == 2013 {
		drop anlsrcfr
	}

*------------------------ Socio-demographics -------------------------*

	* Age 
	gen age_12to14 = age2 <= 3
	gen age_12to15 = age2 <= 4
	gen age_12to17 = age2 <= 6
	gen age_15to17 = age2 >= 4 & age2 <= 6
	gen age_16to19 = age2 >= 5 & age2 <= 8
	gen age_18to19 = age2 == 7 | age2 == 8
	gen age_18to21 = age2 >= 7 & age2 <= 10 
	gen age_18to25 = age2 >= 7 & age2 <= 12 
	gen age_20to25 = age2 >= 9 & age2 <= 12
	gen age_22to25 = age2 == 11 | age2 == 12
	gen age_26to29 = age2 == 13
	gen age_26to34 = age2 == 13 | age2 == 14
	gen age_30to34 = age2 == 14
	gen age_35to49 = age2 == 15
	gen age_35to64 = age2 == 15 | age2 == 16
	gen age_50to64 = age2 == 16
	gen age_65plus = age2 == 17
	
	* Sex 
	gen male = irsex == 1
	gen female = male == 0
	
	* Race/ ethnicity
	gen race_white = newrace2 == 1
	gen race_black = newrace2 == 2
	gen race_hisp = newrace2 == 7
	gen race_other = race_white == 0 & race_black == 0 & race_hisp == 0
	
	* Education (only available for 18+)
	gen educ_mi = educcat2 == 5 
	gen educ_lths = educcat2 == 1
	gen educ_hsg = educcat2 == 2
	gen educ_scol = educcat2 == 3
	gen educ_cplus = educcat2 == 4
	
	* Employment (only available for 15+)
	gen emp_mi = empstaty == 99	
	gen emp_yes = empstaty == 1 | empstaty == 2
	gen emp_no = empstaty == 3
	gen emp_nlf = empstaty == 4
	
	* Income
	gen inc_lt10 = irfamin3 == 1
	gen inc_10to19 = irfamin3 == 2 
	gen inc_20to29 = irfamin3 == 3
	gen inc_30to39 = irfamin3 == 4
	gen inc_40to49 = irfamin3 == 5
	gen inc_50to74 = irfamin3 == 6
	gen inc_75plus = irfamin3 == 7
	
	* Poverty 
	* Code missing as no (living in college dorm)
	gen pov_no = poverty2 == 2 | poverty2 == 3 | poverty2 == . 
	gen pov_yes = poverty2 == 1
	
	* Health insurance 
	gen hi_yes = irinsur4 == 1 
	gen hi_no = irinsur4 == 2 

	* Marital status (only defined for those 15+) 
	* Code those under 15 never married 
	gen mar_yes = irmarit == 1 
	gen mar_oth = irmarit == 2 | irmarit == 3
	gen mar_nvr = irmarit == 4 | irmarit == 99
	
	drop age2 irsex newrace2 educcat2 empstaty irpinc3 irfamin3 poverty2 irinsur4 irmarit
	
*----------------------------- Outcomes ------------------------------*

	* Misuse in past year 
	gen misuse_yr = (iranlrc == 1 | iranlrc == 2)
	drop iranlrc
	
	* Misuse frequency (past year)
	rename iranlfy misuse_freq
	replace misuse_freq = 0 if misuse_freq == 991 | misuse_freq == 993
	
	* Detailed sources of misuse (missing for non-users and a few users)
	rename anllts source_det
	replace source_det = . if source_det == 11 

	* Categorized sources of misuse
	gen source_cat = 3
	replace source_cat = . if source_det == . | source_det == 11 
	replace source_cat = 1 if source_det == 1 | source_det == 2
	replace source_cat = 2 if source_det == 6 | source_det == 8 | source_det == 9
	
	label define source_lbl 1 "Primary market"
	label define source_lbl 2 "Secondary market", add
	label define source_lbl 3 "Other", add
	label values source_cat source_lbl
	
	* Sources for prescription from friend/relative for free
	rename anlsrcf source_fr
	replace source_fr = . if source_fr == 11
	replace source_fr = 1 if source_fr == 2
	replace source_fr = 2 if source_fr == 6 | source_fr == 8 | source_fr == 9 
	replace source_fr = 3 if source_fr == 4 | source_fr == 5 | source_fr == 7 | source_fr == 10
	label values source_fr source_lbl
	
	gen year = `y'
	order year misuse_yr misuse_freq source_det source_cat source_fr age* male race* ///
	      educ* emp* inc* pov* hi* mar* analwt_c

	if `y' != 2006 {
		append using "${inter}/NSDUH_clean_0614.dta"
	}
	save "${inter}/NSDUH_clean_0614.dta", replace
}

***********************************************************************
*---------------- c. Create county misuse (2013-2014) ----------------*
***********************************************************************	
* Weighted and unweighted (by days of misuse)
* All misuse and misuse on secondary market

*------------------------- Create indicators -------------------------*

use "${inter}/NSDUH_clean_0614.dta", clear
	
	* Main outcome variables
	gen misuse_perc_sm = source_cat == 2
	gen misuse_avgdays_sm = misuse_freq*misuse_perc_sm
	replace misuse_perc_sm = misuse_perc_sm*100
			
	replace misuse_yr = misuse_yr*100
	rename misuse_yr misuse_perc_all 
	rename misuse_freq misuse_avgdays_all
			
	* Create indicators
	foreach v1 in age_12to14 age_15to17 age_18to19 age_20to25 age_26to29 age_30to34 age_35to49 age_50to64 age_65plus {
		foreach v2 in male female {
			gen `v1'_`v2' = `v1'*`v2'
		}
	}
	foreach v1 in age_12to17 age_18to25 age_26to34 age_35to64 age_65plus {
		foreach v2 in male female {
			foreach v3 in white black hisp other {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*race_`v3'
				foreach v4 in pov_yes pov_no {
					gen `v1'_`v2'_`v3'_`v4' = `v1'*`v2'*race_`v3'*`v4'
				}
			}
			foreach v3 in hi_yes hi_no {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
			if "`v1'" != "age_12to17" {
				foreach v3 in lths hsg scol cplus {
					gen `v1'_`v2'_`v3' = `v1'*`v2'*educ_`v3'
				}
			}
		}
	}
	foreach v1 in age_16to19 age_20to25 age_26to34 age_35to64 age_65plus {
		foreach v2 in male female {
			foreach v3 in emp_yes emp_no emp_nlf {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
		}
	}
	foreach v1 in age_15to17 age_18to25 age_26to34 age_35to49 age_50to64 age_65plus {
		foreach v2 in male female {
			foreach v3 in mar_yes mar_nvr mar_oth {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
		}
	}
	foreach v1 in inc_lt10 inc_10to19 inc_20to29 inc_30to39 inc_40to49 inc_50to74 inc_75plus {
		foreach v2 in white black hisp other {
			gen `v1'_`v2' = `v1'*race_`v2'
		}
	}

	save `main', replace
	
*------------------ Regression for predicting misuse -----------------*

foreach type in all sm {

	foreach y in 2013 2014 1314 {
		
		use `main', clear
		
		* Use two years to compare to state estimates
		if `y' != 1314 {
			keep if year == `y'
		}
		else {
			keep if year == 2013 | year == 2014
		}

		* age_15to17_male_mar_yes and age_15to17_female_mar_yes dropping in 2014 (all 0)
		reg misuse_perc_`type' ///
			age_12to14_male age_12to14_female age_15to17_male age_15to17_female age_18to19_male age_18to19_female ///
			age_20to25_male age_20to25_female age_26to29_male age_26to29_female age_30to34_male age_30to34_female ///
			age_35to49_male age_35to49_female age_50to64_male age_50to64_female age_65plus_male age_65plus_female ///
			age_12to17_male_white age_12to17_male_black age_12to17_male_hisp ///
			age_12to17_female_white age_12to17_female_black age_12to17_female_hisp ///
			age_18to25_male_white age_18to25_male_black age_18to25_male_hisp ///
			age_18to25_female_white age_18to25_female_black age_18to25_female_hisp ///
			age_26to34_male_white age_26to34_male_black age_26to34_male_hisp ///
			age_26to34_female_white age_26to34_female_black age_26to34_female_hisp ///
			age_35to64_male_white age_35to64_male_black age_35to64_male_hisp ///
			age_35to64_female_white age_35to64_female_black age_35to64_female_hisp ///
			age_65plus_male_white age_65plus_male_black age_65plus_male_hisp ///
			age_65plus_female_white age_65plus_female_black age_65plus_female_hisp ///
			age_18to25_male_hsg age_18to25_male_scol age_18to25_male_cplus ///
			age_18to25_female_hsg age_18to25_female_scol age_18to25_female_cplus ///
			age_26to34_male_hsg age_26to34_male_scol age_26to34_male_cplus ///
			age_26to34_female_hsg age_26to34_female_scol age_26to34_female_cplus ///
			age_35to64_male_hsg age_35to64_male_scol age_35to64_male_cplus ///
			age_35to64_female_hsg age_35to64_female_scol age_35to64_female_cplus ///
			age_65plus_male_hsg age_65plus_male_scol age_65plus_male_cplus ///
			age_65plus_female_hsg age_65plus_female_scol age_65plus_female_cplus ///
			age_16to19_male_emp_yes age_16to19_male_emp_no age_16to19_male_emp_nlf ///
			age_16to19_female_emp_yes age_16to19_female_emp_no age_16to19_female_emp_nlf ///
			age_20to25_male_emp_yes age_20to25_male_emp_no ///
			age_20to25_female_emp_yes age_20to25_female_emp_no ///
			age_26to34_male_emp_yes age_26to34_male_emp_no ///
			age_26to34_female_emp_yes age_26to34_female_emp_no ///
			age_35to64_male_emp_yes age_35to64_male_emp_no ///
			age_35to64_female_emp_yes age_35to64_female_emp_no ///
			age_65plus_male_emp_yes age_65plus_male_emp_no ///
			age_65plus_female_emp_yes age_65plus_female_emp_no ///
			inc_10to19_white inc_20to29_white inc_30to39_white inc_40to49_white inc_50to74_white inc_75plus_white ///
			inc_10to19_black inc_20to29_black inc_30to39_black inc_40to49_black inc_50to74_black inc_75plus_black ///
			inc_10to19_hisp inc_20to29_hisp inc_30to39_hisp inc_40to49_hisp inc_50to74_hisp inc_75plus_hisp ///
			inc_10to19_other inc_20to29_other inc_30to39_other inc_40to49_other inc_50to74_other inc_75plus_other ///
			age_12to17_male_white_pov_yes age_12to17_male_black_pov_yes age_12to17_male_hisp_pov_yes age_12to17_male_other_pov_yes ///
			age_12to17_female_white_pov_yes age_12to17_female_black_pov_yes age_12to17_female_hisp_pov_yes age_12to17_female_other_pov_yes ///
			age_18to25_male_white_pov_yes age_18to25_male_black_pov_yes age_18to25_male_hisp_pov_yes age_18to25_male_other_pov_yes ///
			age_18to25_female_white_pov_yes age_18to25_female_black_pov_yes age_18to25_female_hisp_pov_yes age_18to25_female_other_pov_yes ///
			age_26to34_male_white_pov_yes age_26to34_male_black_pov_yes age_26to34_male_hisp_pov_yes age_26to34_male_other_pov_yes ///
			age_26to34_female_white_pov_yes age_26to34_female_black_pov_yes age_26to34_female_hisp_pov_yes age_26to34_female_other_pov_yes ///
			age_35to64_male_white_pov_yes age_35to64_male_black_pov_yes age_35to64_male_hisp_pov_yes age_35to64_male_other_pov_yes ///
			age_35to64_female_white_pov_yes age_35to64_female_black_pov_yes age_35to64_female_hisp_pov_yes age_35to64_female_other_pov_yes ///
			age_65plus_male_white_pov_yes age_65plus_male_black_pov_yes age_65plus_male_hisp_pov_yes age_65plus_male_other_pov_yes /// 
			age_65plus_female_white_pov_yes age_65plus_female_black_pov_yes age_65plus_female_hisp_pov_yes age_65plus_female_other_pov_yes ///
			age_12to17_male_hi_yes age_12to17_female_hi_yes age_18to25_male_hi_yes age_18to25_female_hi_yes ///
			age_26to34_male_hi_yes age_26to34_female_hi_yes age_35to64_male_hi_yes age_35to64_female_hi_yes ///
			age_65plus_male_hi_yes age_65plus_female_hi_yes ///
			age_15to17_male_mar_yes age_15to17_female_mar_yes ///
			age_18to25_male_mar_yes age_18to25_male_mar_nvr age_18to25_female_mar_yes age_18to25_female_mar_nvr ///
			age_26to34_male_mar_yes age_26to34_male_mar_nvr age_26to34_female_mar_yes age_26to34_female_mar_nvr ///
			age_35to49_male_mar_yes age_35to49_male_mar_nvr age_35to49_female_mar_yes age_35to49_female_mar_nvr ///
			age_50to64_male_mar_yes age_50to64_male_mar_nvr age_50to64_female_mar_yes age_50to64_female_mar_nvr ///
			age_65plus_male_mar_yes age_65plus_male_mar_nvr age_65plus_female_mar_yes age_65plus_female_mar_nvr, nocons

		scalar r2a = `e(r2_a)'
		
*----------------------- Predict misuse in ACS -----------------------*
* County-level for estimation 
* State-level to compare to NSDUH aggregates

		use "${inter}/ACS_county_NSDUH_1014.dta", clear

		predict misuse_acs_perc_`type', xb
		keep county_fips state_fips pop_tot misuse_acs_perc_`type'
		gen year = `y'
			
		if "`type'" == "all" & `y' != 2013 {
			append using "${inter}/NSDUH_county_year_1314.dta"
		}
		if "`type'" == "sm" {
			merge 1:1 county_fips year using "${inter}/NSDUH_county_year_1314.dta", nogen
		}
		save "${inter}/NSDUH_county_year_1314.dta", replace
		
		* Save r2 to be used in C1_analysis_stata.do
		if `y' == 2014 {
			clear
			set obs 1
			gen var = "r2"
			gen misuse_`type' = string(r2a,"%4.3f")
			merge 1:1 var using "${inter}/NHIS_NSDUH_R2.dta", nogen
			save "${inter}/NHIS_NSDUH_R2.dta", replace 	
		}
	}
}

* Collapse to state level 
use "${inter}/NSDUH_county_year_1314.dta", clear

	collapse (mean) misuse_acs* [aw=pop_tot], by(state_fips year) fast 
	merge 1:1 state_fips year using `state', nogen
	save "${inter}/NSDUH_state_year_1314.dta", replace 
	
	* Add state population 
	use "${inter}/ACS_county_NSDUH_1014.dta", clear
	collapse (sum) pop_tot, by(state_fips) fast
	merge 1:m state_fips using "${inter}/NSDUH_state_year_1314.dta", nogen 
	save "${inter}/NSDUH_state_year_1314.dta", replace 
	
	erase "${inter}/ACS_county_NSDUH_1014.dta"

***********************************************************************
*--------------- d. Create provider-level misuse (2014) --------------*
***********************************************************************	

*------------------------- Create indicators -------------------------*

use "${inter}/NSDUH_clean_0614.dta", clear

	keep if year == 2009
	
	* Main outcome variables
	replace misuse_yr = misuse_yr*100
	rename misuse_yr misuse_perc_all 
	
	foreach v1 in age_12to17 age_18to21 age_22to25 age_26to29 age_30to34 age_35to49 age_50to64 age_65plus {
		foreach v2 in male female {
			gen `v1'_`v2' = `v1'*`v2'
		}
	}
		
*------------------ Regression for predicting misuse -----------------*
		
	reg misuse_perc_all ///
		age_12to17_male age_12to17_female age_18to21_male age_18to21_female ///
		age_22to25_male age_22to25_female age_26to29_male age_26to29_female ///
		age_30to34_male age_30to34_female age_35to49_male age_35to49_female ///
		age_50to64_male age_50to64_female age_65plus_male age_65plus_female, nocons

*---------------------- Predict misuse in IQVIA ----------------------*

use PATIENT_ID PROVIDER_ID using "${raw_LRx}/OP/OP_FactRx2009.dta", clear

	merge m:1 PATIENT_ID using "${raw_LRx}/OP/OP_Patient.dta", nogen keep(matched)
	
	gen age = 2009 - PAT_BRTH_YR_NBR
	drop if age < 11 | age == . 
	
	gen age_12to17 = age <= 17 
	gen age_18to21 = age >= 18 & age <= 21
	gen age_22to25 = age >= 22 & age <= 25
	gen age_26to29 = age >= 26 & age <= 29
	gen age_30to34 = age >= 30 & age <= 34
	gen age_35to49 = age >= 35 & age <= 49
	gen age_50to64 = age >= 50 & age <= 64
	gen age_65plus = age >= 65
	
	gen male = PAT_GENDER_CD == "M"
	gen female = PAT_GENDER_CD == "F"
	drop if PAT_GENDER_CD == "U"
	
	foreach v1 in age_12to17 age_18to21 age_22to25 age_26to29 age_30to34 age_35to49 age_50to64 age_65plus {
		foreach v2 in male female {
			gen `v1'_`v2' = `v1'*`v2'
		}
	}
	
	predict misuse, xb
	collapse (mean) misuse, by(PROVIDER_ID) fast
	
	* Need legacy IMS ID for link 
	* - All matched in master
	merge m:1 PROVIDER_ID using "${raw_LRx}/All_Provider.dta", keepusing(IMS_RXER_ID) nogen keep(matched)
	drop PROVIDER_ID
		
	* Drop if missing legacy ID 
	rename IMS_RXER_ID provider_id
	drop if provider_id == . 
	order provider_id misuse

save "${inter}/provider_misuse_2009.dta", replace


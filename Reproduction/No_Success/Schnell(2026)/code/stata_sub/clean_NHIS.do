***********************************************************************
*-------------------------- Clean NHIS Data --------------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

a. Clean data 
   - only keep key variables 
   - construct desired categories
   - combine across file types
   
b. Create county pain 
   - create necessary indicators
   - regress pain on indicators 
   - predict pain in the ACS
   
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*
	
	tempfile main 
	tempfile region
	
***********************************************************************
*--------------------------- a. Clean data ---------------------------*
***********************************************************************

*---------------------------- Person file ----------------------------*
* Uniquely identified by hhx, fmx, fpx 

use "${raw_public}/nhis/personsx_2014.dta", clear

	keep hhx fmx fpx region age_p sex racerpi2 hispan_i r_maritl educ1 notcov 

	* Restrict to 18+ since interested in pain (only in sample adult file)
	drop if age_p <= 17

	* Age 	
	gen age_18to19 = age_p == 18 | age_p == 19
	gen age_18to24 = age_p >= 18 & age_p <= 24
	gen age_20 = age_p == 20
	gen age_20to21 = age_p == 20 | age_p == 21
	gen age_20to24 = age_p >= 20 & age_p <= 24
	gen age_21 = age_p == 21
	gen age_22to24 = age_p >= 22 & age_p <= 24
	gen age_25to29 = age_p >= 25 & age_p <= 29
	gen age_25to34 = age_p >= 25 & age_p <= 34
	gen age_30to34 = age_p >= 30 & age_p <= 34
	gen age_35to39 = age_p >= 35 & age_p <= 39
	gen age_35to44 = age_p >= 35 & age_p <= 44
	gen age_40to44 = age_p >= 40 & age_p <= 44
	gen age_45to49 = age_p >= 45 & age_p <= 49
	gen age_45to54 = age_p >= 45 & age_p <= 54
	gen age_45to64 = age_p >= 45 & age_p <= 64
	gen age_50to54 = age_p >= 50 & age_p <= 54
	gen age_55to59 = age_p >= 55 & age_p <= 59
	gen age_55to64 = age_p >= 55 & age_p <= 64
	gen age_60to61 = age_p == 60 | age_p == 61
	gen age_60to64 = age_p >= 60 & age_p <= 64
	gen age_62to64 = age_p >= 62 & age_p <= 64
	gen age_65to66 = age_p == 65 | age_p == 66
	gen age_65to69 = age_p >= 65 & age_p <= 69
	gen age_65to74 = age_p >= 65 & age_p <= 74
	gen age_65plus = age_p >= 65
	gen age_67to69 = age_p >= 67 & age_p <= 69
	gen age_70to74 = age_p >= 70 & age_p <= 74
	gen age_75to79 = age_p >= 75 & age_p <= 79
	gen age_75to84 = age_p >= 75 & age_p <= 84
	gen age_75plus = age_p >= 75
	gen age_80to84 = age_p >= 80 & age_p <= 84
	gen age_85plus = age_p >= 85

	* Sex 
	gen male = sex == 1
	gen female = male == 0
	
	* Race/ ethnicity
	gen race_white = racerpi2 == 1 & hispan_i == 12
	gen race_black = racerpi2 == 2 & hispan_i == 12
	gen race_hisp = hispan_i != 12
	gen race_other = race_white == 0 & race_black == 0 & race_hisp == 0
	
	* Marital status 
	gen mar_mi = r_maritl == 9
	gen mar_yes = r_maritl == 1
	gen mar_oth = r_maritl >= 2 & r_maritl <= 6
	gen mar_nvr = r_maritl == 7 | r_maritl == 8
	
	* Education
	gen educ_mi = educ1 >= 97 
	gen educ_lths = educ1 <= 12 
	gen educ_hsg = educ1 == 13 | educ1 == 14
	gen educ_scol = educ1 >= 15 & educ1 <= 17 
	gen educ_cplus = educ1 >= 18 & educ1 <= 21 
	
	* Health insurance 
	gen hi_mi = notcov == 9
	gen hi_no = notcov == 1
	gen hi_yes = notcov == 2
	
	drop age_p sex racerpi2 hispan_i r_maritl educ1 notcov 
	
	save `main', replace

*---------------------------- Family file ----------------------------*
* Uniquely identified by hhx, fmx 

use "${raw_public}/nhis/familyxx_2014.dta", clear

	keep hhx fmx incgrp4 rat_cat4
	
	* Income
	gen inc_mi = incgrp4 == 6 | incgrp4 == 7 | incgrp4 == 96 | incgrp4 == 99
	gen inc_lt35 = incgrp4 == 1
	gen inc_35to49 = incgrp4 == 2
	gen inc_50to74 = incgrp4 == 3 
	gen inc_75to99 = incgrp4 == 4
	gen inc_100plus = incgrp4 == 5
	
	* Poverty 
	gen pov_mi = rat_cat4 == 96 | rat_cat4 == 99
	gen pov_yes = rat_cat4 <= 3 | rat_cat4 == 15 
	gen pov_no = (rat_cat4 >= 4 & rat_cat4 <= 14) | rat_cat4 == 16 | rat_cat4 == 17 
	
	drop incgrp4 rat_cat4
	
	merge 1:m hhx fmx using `main', nogen keep(matched)
	save `main', replace

*------------------------- Sample adult file -------------------------*
* Uniquely identified by hhx, fmx (fpx)

use "${raw_public}/nhis/samadult_2014.dta", clear

	keep hhx fmx fpx wtfa_sa doinglwa paineck painlb painface

	* Employment
	gen emp_mi = doinglwa >= 7 
	gen emp_yes = doinglwa == 1
	gen emp_no = doinglwa >= 2 & doinglwa <= 4
	gen emp_nlf = doinglwa == 5
	
	* Pain: neck, back, face
	* Drop if missing (34 observations [0.09%])
	drop if paineck >= 7 | painlb >= 7 | painface >= 7
	gen pain_neck = paineck == 1
	gen pain_lb = painlb == 1 
	gen pain_face = painface == 1 
	
	gen pain_any = pain_neck != 0 | pain_lb != 0 | pain_face != 0 
	gen pain_avg = (pain_neck + pain_lb + pain_face)/3
	gen pain_tot = pain_neck + pain_lb + pain_face
	
	drop doinglwa paineck painlb painface
	
	* All matched in master (43.68%)
	merge 1:1 hhx fmx fpx using `main', nogen keep(matched)
	
*--------------------- Recode/ clean to match ACS --------------------*

	* Missing education: 159 observations (0.43%)
	drop if educ_mi == 1 

	* Missing employment: 12 observations (0.03%)
	drop if emp_mi == 1 

	* Missing health insurance: 131 observations (0.36%)
	drop if hi_mi == 1

	* Missing marital status: 76 observations (0.21%)
	drop if mar_mi == 1 
	
	* Missing income/ poverty: 3,385 observations (9.33%)
	* Correlation with regional measures higher with inc/ poverty 
	drop if inc_mi == 1 | pov_mi == 1
	
	drop educ_mi emp_mi hi_mi mar_mi inc_mi pov_mi
	
	save "${inter}/NHIS_clean_2014.dta", replace
	
***********************************************************************
*-------------------- b. Create county pain (2014) -------------------*
***********************************************************************	
* Pain in specific body parts (neck, lower back, face), any pain, avg. pain, total pain

*------------------------- Create indicators -------------------------*

use "${inter}/NHIS_clean_2014.dta", clear
			
	foreach v1 in age_18to19 age_20 age_21 age_22to24 age_25to29 age_30to34 age_35to39 age_40to44 age_45to49 age_50to54 ///
	              age_55to59 age_60to61 age_62to64 age_65to66 age_67to69 age_70to74 age_75to79 age_80to84 age_85plus {
		foreach v2 in male female {
			gen `v1'_`v2' = `v1'*`v2'
		}		
	}
	foreach v1 in age_18to19 age_20to24 age_25to29 age_30to34 age_35to44 age_45to54 age_55to64 age_65to74 age_75to84 age_85plus {
		foreach v2 in male female {
			foreach v3 in white black hisp other {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*race_`v3'
			}
		}
	}
	foreach v1 in age_18to24 age_25to34 age_35to44 age_45to64 age_65plus {
		foreach v2 in male female {
			foreach v3 in lths hsg scol cplus {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*educ_`v3'
			}
		}
	}
	foreach v1 in age_18to19 age_20to21 age_22to24 age_25to29 age_30to34 age_35to44 age_45to54 ///
	              age_55to59 age_60to61 age_62to64 age_65to69 age_70to74 age_75plus {
		foreach v2 in male female {
			foreach v3 in emp_yes emp_no emp_nlf {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
		}
	}
	foreach v1 in age_18to24 age_25to34 age_35to44 age_45to54 age_55to64 age_65to74 age_75plus {
		foreach v2 in male female {
			foreach v3 in hi_yes hi_no {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
			foreach v3 in white black hisp other {
				foreach v4 in pov_yes pov_no {
					gen `v1'_`v2'_`v3'_`v4' = `v1'*`v2'*race_`v3'*`v4'
				}
			}
		}
	}
	foreach v1 in age_18to19 age_20to24 age_25to29 age_30to34 age_35to39 age_40to44 age_45to49 ///
	              age_50to54 age_55to59 age_60to64 age_65to74 age_75to84 age_85plus {
		foreach v2 in male female {
			foreach v3 in mar_yes mar_nvr mar_oth {
				gen `v1'_`v2'_`v3' = `v1'*`v2'*`v3'
			}
		}
	}
	foreach v1 in inc_lt35 inc_35to49 inc_50to74 inc_75to99 inc_100plus {
		foreach v2 in white black hisp other {
			gen `v1'_`v2' = `v1'*race_`v2'
		}
	}
		
	save `main', replace

*------------------- Regression for predicting pain ------------------*

foreach type in any tot {

	use `main', clear
			
	reg pain_`type' ///
		age_18to19_male age_18to19_female age_20_male age_20_female age_21_male age_21_female ///
		age_22to24_male age_22to24_female age_25to29_male age_25to29_female age_30to34_male age_30to34_female ///
		age_35to39_male age_35to39_female age_40to44_male age_40to44_female age_45to49_male age_45to49_female ///
		age_50to54_male age_50to54_female age_55to59_male age_55to59_female age_60to61_male age_60to61_female ///
		age_62to64_male age_62to64_female age_65to66_male age_65to66_female age_67to69_male age_67to69_female ///
		age_70to74_male age_70to74_female age_75to79_male age_75to79_female age_80to84_male age_80to84_female ///
		age_85plus_male age_85plus_female ///
		age_18to19_male_white age_18to19_male_black age_18to19_male_hisp ///
		age_18to19_female_white age_18to19_female_black age_18to19_female_hisp ///
		age_20to24_male_white age_20to24_male_black age_20to24_male_hisp ///
		age_20to24_female_white age_20to24_female_black age_20to24_female_hisp ///
		age_25to29_male_white age_25to29_male_black age_25to29_male_hisp ///
		age_25to29_female_white age_25to29_female_black age_25to29_female_hisp ///
		age_30to34_male_white age_30to34_male_black age_30to34_male_hisp ///
		age_30to34_female_white age_30to34_female_black age_30to34_female_hisp ///
		age_35to44_male_white age_35to44_male_black age_35to44_male_hisp ///
		age_35to44_female_white age_35to44_female_black age_35to44_female_hisp /// 
		age_45to54_male_white age_45to54_male_black age_45to54_male_hisp ///
		age_45to54_female_white age_45to54_female_black age_45to54_female_hisp ///
		age_55to64_male_white age_55to64_male_black age_55to64_male_hisp ///
		age_55to64_female_white age_55to64_female_black age_55to64_female_hisp ///
		age_65to74_male_white age_65to74_male_black age_65to74_male_hisp ///
		age_65to74_female_white age_65to74_female_black age_65to74_female_hisp ///
		age_75to84_male_white age_75to84_male_black age_75to84_male_hisp ///
		age_75to84_female_white age_75to84_female_black age_75to84_female_hisp ///
		age_85plus_male_white age_85plus_male_black age_85plus_male_hisp ///
		age_85plus_female_white age_85plus_female_black age_85plus_female_hisp ///
		age_18to24_male_hsg age_18to24_male_scol age_18to24_male_cplus ///
		age_18to24_female_hsg age_18to24_female_scol age_18to24_female_cplus ///
		age_25to34_male_hsg age_25to34_male_scol age_25to34_male_cplus ///
		age_25to34_female_hsg age_25to34_female_scol age_25to34_female_cplus ///
		age_35to44_male_hsg age_35to44_male_scol age_35to44_male_cplus ///
		age_35to44_female_hsg age_35to44_female_scol age_35to44_female_cplus ///
		age_45to64_male_hsg age_45to64_male_scol age_45to64_male_cplus ///
		age_45to64_female_hsg age_45to64_female_scol age_45to64_female_cplus ///
		age_65plus_male_hsg age_65plus_male_scol age_65plus_male_cplus ///
		age_65plus_female_hsg age_65plus_female_scol age_65plus_female_cplus ///
		age_18to19_male_emp_yes age_18to19_male_emp_no age_18to19_female_emp_yes age_18to19_female_emp_no ///
		age_20to21_male_emp_yes age_20to21_male_emp_no age_20to21_female_emp_yes age_20to21_female_emp_no ///
		age_22to24_male_emp_yes age_22to24_male_emp_no age_22to24_female_emp_yes age_22to24_female_emp_no ///
		age_25to29_male_emp_yes age_25to29_male_emp_no age_25to29_female_emp_yes age_25to29_female_emp_no ///
		age_30to34_male_emp_yes age_30to34_male_emp_no age_30to34_female_emp_yes age_30to34_female_emp_no ///
		age_35to44_male_emp_yes age_35to44_male_emp_no age_35to44_female_emp_yes age_35to44_female_emp_no ///
		age_45to54_male_emp_yes age_45to54_male_emp_no age_45to54_female_emp_yes age_45to54_female_emp_no ///
		age_55to59_male_emp_yes age_55to59_male_emp_no age_55to59_female_emp_yes age_55to59_female_emp_no ///
		age_60to61_male_emp_yes age_60to61_male_emp_no age_60to61_female_emp_yes age_60to61_female_emp_no ///
		age_62to64_male_emp_yes age_62to64_male_emp_no age_62to64_female_emp_yes age_62to64_female_emp_no ///
		age_65to69_male_emp_yes age_65to69_male_emp_no age_65to69_female_emp_yes age_65to69_female_emp_no ///
		age_70to74_male_emp_yes age_70to74_male_emp_no age_70to74_female_emp_yes age_70to74_female_emp_no ///
		age_75plus_male_emp_yes age_75plus_male_emp_no age_75plus_female_emp_yes age_75plus_female_emp_no ///
		age_18to24_male_hi_yes age_18to24_female_hi_yes age_25to34_male_hi_yes age_25to34_female_hi_yes ///
		age_35to44_male_hi_yes age_35to44_female_hi_yes age_45to54_male_hi_yes age_45to54_female_hi_yes ///
		age_55to64_male_hi_yes age_55to64_female_hi_yes age_65to74_male_hi_yes age_65to74_female_hi_yes ///
		age_75plus_male_hi_yes age_75plus_female_hi_yes ///
		age_18to19_male_mar_yes age_18to19_male_mar_nvr age_18to19_female_mar_yes age_18to19_female_mar_nvr ///
		age_20to24_male_mar_yes age_20to24_male_mar_nvr age_20to24_female_mar_yes age_20to24_female_mar_nvr ///
		age_25to29_male_mar_yes age_25to29_male_mar_nvr age_25to29_female_mar_yes age_25to29_female_mar_nvr ///
		age_30to34_male_mar_yes age_30to34_male_mar_nvr age_30to34_female_mar_yes age_30to34_female_mar_nvr ///
		age_35to39_male_mar_yes age_35to39_male_mar_nvr age_35to39_female_mar_yes age_35to39_female_mar_nvr ///
		age_40to44_male_mar_yes age_40to44_male_mar_nvr age_40to44_female_mar_yes age_40to44_female_mar_nvr ///
		age_45to49_male_mar_yes age_45to49_male_mar_nvr age_45to49_female_mar_yes age_45to49_female_mar_nvr ///
		age_50to54_male_mar_yes age_50to54_male_mar_nvr age_50to54_female_mar_yes age_50to54_female_mar_nvr ///
		age_55to59_male_mar_yes age_55to59_male_mar_nvr age_55to59_female_mar_yes age_55to59_female_mar_nvr ///
		age_60to64_male_mar_yes age_60to64_male_mar_nvr age_60to64_female_mar_yes age_60to64_female_mar_nvr ///
		age_65to74_male_mar_yes age_65to74_male_mar_nvr age_65to74_female_mar_yes age_65to74_female_mar_nvr ///
		age_75to84_male_mar_yes age_75to84_male_mar_nvr age_75to84_female_mar_yes age_75to84_female_mar_nvr ///
		age_85plus_male_mar_yes age_85plus_male_mar_nvr age_85plus_female_mar_yes age_85plus_female_mar_nvr ///
		inc_35to49_white inc_35to49_black inc_35to49_hisp inc_35to49_other ///
		inc_50to74_white inc_50to74_black inc_50to74_hisp inc_50to74_other ///
		inc_75to99_white inc_75to99_black inc_75to99_hisp inc_75to99_other ///
		inc_100plus_white inc_100plus_black inc_100plus_hisp inc_100plus_other ///
		age_18to24_male_white_pov_yes age_18to24_male_black_pov_yes age_18to24_male_hisp_pov_yes age_18to24_male_other_pov_yes ///
		age_18to24_female_white_pov_yes age_18to24_female_black_pov_yes age_18to24_female_hisp_pov_yes age_18to24_female_other_pov_yes ///
		age_25to34_male_white_pov_yes age_25to34_male_black_pov_yes age_25to34_male_hisp_pov_yes age_25to34_male_other_pov_yes ///
		age_25to34_female_white_pov_yes age_25to34_female_black_pov_yes age_25to34_female_hisp_pov_yes age_25to34_female_other_pov_yes ///
		age_35to44_male_white_pov_yes age_35to44_male_black_pov_yes age_35to44_male_hisp_pov_yes age_35to44_male_other_pov_yes ///
		age_35to44_female_white_pov_yes age_35to44_female_black_pov_yes age_35to44_female_hisp_pov_yes age_35to44_female_other_pov_yes ///
		age_45to54_male_white_pov_yes age_45to54_male_black_pov_yes age_45to54_male_hisp_pov_yes age_45to54_male_other_pov_yes ///
		age_45to54_female_white_pov_yes age_45to54_female_black_pov_yes age_45to54_female_hisp_pov_yes age_45to54_female_other_pov_yes ///
		age_55to64_male_white_pov_yes age_55to64_male_black_pov_yes age_55to64_male_hisp_pov_yes age_55to64_male_other_pov_yes ///
		age_55to64_female_white_pov_yes age_55to64_female_black_pov_yes age_55to64_female_hisp_pov_yes age_55to64_female_other_pov_yes ///
		age_65to74_male_white_pov_yes age_65to74_male_black_pov_yes age_65to74_male_hisp_pov_yes age_65to74_male_other_pov_yes ///
		age_65to74_female_white_pov_yes age_65to74_female_black_pov_yes age_65to74_female_hisp_pov_yes age_65to74_female_other_pov_yes ///
		age_75plus_male_white_pov_yes age_75plus_male_black_pov_yes age_75plus_male_hisp_pov_yes age_75plus_male_other_pov_yes ///
		age_75plus_female_white_pov_yes age_75plus_female_black_pov_yes age_75plus_female_hisp_pov_yes age_75plus_female_other_pov_yes, nocons
		
	scalar r2a = `e(r2_a)'
			
*------------------------ Predict pain in ACS ------------------------*
* County-level for estimation 
* Region-level to compare to NHIS geography

	use "${inter}/ACS_county_NHIS_2014.dta", clear

	predict pain_acs_`type', xb
	
	if "`type'" == "any" {
		keep county_fips state_fips region pop_tot pain_acs_`type'
		gen year = 2014
	}
	else {
		keep county_fips pain_acs_`type'
		merge 1:1 county_fips using "${inter}/NHIS_county_year_2014.dta", nogen
	}
	save "${inter}/NHIS_county_year_2014.dta", replace
	
	* Save r2 to be used in C1_analysis_stata.do
	clear
	set obs 1
	gen var = "r2"
	gen pain_`type' = string(r2a,"%4.3f")
	if "`type'" == "tot" {
		merge 1:1 var using "${inter}/NHIS_NSDUH_R2.dta", nogen
	}
	save "${inter}/NHIS_NSDUH_R2.dta", replace 	
}
	
* Collapse to region level 
use "${inter}/NHIS_county_year_2014.dta", clear

	collapse (mean) pain_acs* [aw=pop_tot], by(region) fast 
	save `region'
	
	use "${inter}/NHIS_clean_2014.dta", clear
	collapse (mean) pain* [aw=wtfa_sa], by(region) fast
	merge 1:1 region using `region', nogen
	save "${inter}/NHIS_region_year_2014.dta", replace 
	
	* Add region population 
	use "${inter}/ACS_county_NHIS_2014.dta", clear
	collapse (sum) pop_tot, by(region) fast
	merge 1:1 region using "${inter}/NHIS_region_year_2014.dta", nogen 
	save "${inter}/NHIS_region_year_2014.dta", replace 
	
	erase "${inter}/ACS_county_NHIS_2014.dta"
	
	

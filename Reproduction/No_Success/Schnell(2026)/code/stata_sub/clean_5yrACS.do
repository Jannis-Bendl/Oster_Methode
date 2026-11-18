***********************************************************************
*----------------------- Clean 5-Year ACS Data -----------------------* 
***********************************************************************

/*-------------------------- OVERVIEW --------------------------------*

a. Create county controls 
   - use R12917043

b. Create NSDUH categories
   - use R12543447 (contains crosstabs)
   - base: 10+ (to mimic 12+ in NSDUH)
   
c. Create NHIS categories
   - use R12543447 (contains crosstabs)
   - base: 18+ (sample adult file 18 and over)
  
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*

	local H_ti "white"
	local B_ti "black"
	local I_ti "hisp"

***********************************************************************
*--------------------- a. Create county controls ---------------------*
***********************************************************************

use "${raw_public}/acs/R12917043.dta", clear 

	* Drop Puerto Rico
	rename STATE state_fips
	destring state_fips, replace
	drop if state_fips == 72
	
	* Basics 
	rename FIPS county_fips 
	rename A00001_001 pop_tot
	rename A00002_002 pop_dens

	* Sex
	gen perc_male = A02001_002/pop_tot
	gen perc_female = A02001_003/pop_tot
	
	* Age
	gen perc_0017 = (A01001_002 + A01001_003 + A01001_004 + A01001_005)/pop_tot
	gen perc_1834 = (A01001_006 + A01001_007)/pop_tot
	gen perc_3564 = (A01001_008 + A01001_009 + A01001_010)/pop_tot
	gen perc_65plus = (A01001_011 + A01001_012 + A01001_013)/pop_tot
	gen pop_tot_adult = A01001_006 + A01001_007 + A01001_008 + A01001_009 + A01001_010 + A01001_011 + A01001_012 + A01001_013
	
	* Race/ ethnicity
	gen perc_white = A03001_002/pop_tot
	gen perc_black = A03001_003/pop_tot
	gen perc_hisp = A04001_010/pop_tot
	
	* Education (25+)
	rename A12001_002 perc_lths 
	rename A12001_003 perc_hsg
	rename A12001_004 perc_scol
	gen perc_cplus = A12001_005 + A12001_006 + A12001_007 + A12001_008
	foreach v in lths hsg scol cplus {
		replace perc_`v' = perc_`v'/A12001_001
	}
	
	* Employment (16+)
	gen perc_emp = A17002_003 + A17002_005
	rename A17002_006 perc_unemp 
	rename A17002_007 perc_nlf
	foreach v in emp unemp nlf {
		replace perc_`v' = perc_`v'/A17002_001
	}
	
	* Median household income 
	rename A14006_001 med_hh_inc
	
	*-------- ORGANIZE --------*
	
	keep county_fips pop_dens perc* med_hh_inc pop_tot*
	save "${inter}/ACS_county_demos_1014.dta", replace

***********************************************************************
*--------------------- b. Create NSDUH categories --------------------*
***********************************************************************

use "${raw_public}/acs/R12543447.dta", clear 

	keep FIPS STATE B01001* B12002* B15001* B17001* B19101* B23001* B27001*
	rename FIPS county_fips
	rename STATE state_fips
	destring state_fips, replace
	qui compress
	
	* Drop Puerto Rico
	drop if state_fips == 72
	
	*---- TOTAL POPULATION ----*
	rename B01001001 pop_tot
	
	* 10+ (to mimic "12+")
	gen pop_base = B01001005 + B01001006 + B01001007 + B01001008 + B01001009 + B01001010 + B01001011 + ///
		       B01001012 + B01001013 + B01001014 + B01001015 + B01001016 + B01001017 + B01001018 + ///
		       B01001019 + B01001020 + B01001021 + B01001022 + B01001023 + B01001024 + B01001025 + ///
		       B01001029 + B01001030 + B01001031 + B01001032 + B01001033 + B01001034 + B01001035 + ///
		       B01001036 + B01001037 + B01001038 + B01001039 + B01001040 + B01001041 + B01001042 + ///
		       B01001043 + B01001044 + B01001045 + B01001046 + B01001047 + B01001048 + B01001049
		     
	*--------- AGE-SEX --------*
	* Code "12-14" to match NSDUH (really 10-14)
	* Code "20-25" to match NSDUH (really 20-24)
	
	gen age_12to14_male = B01001005/pop_base
	gen age_15to17_male = B01001006/pop_base
	gen age_18to19_male = B01001007/pop_base
	gen age_20to25_male = (B01001008 + B01001009 + B01001010)/pop_base
	gen age_26to29_male = B01001011/pop_base
	gen age_30to34_male = B01001012/pop_base 
	gen age_35to49_male = (B01001013 + B01001014 + B01001015)/pop_base
	gen age_50to64_male = (B01001016 + B01001017 + B01001018 + B01001019)/pop_base
	gen age_65plus_male = (B01001020 + B01001021 + B01001022 + B01001023 + B01001024 + B01001025)/pop_base
	
	gen age_12to14_female = B01001029/pop_base
	gen age_15to17_female = B01001030/pop_base
	gen age_18to19_female = B01001031/pop_base
	gen age_20to25_female = (B01001032 + B01001033 + B01001034)/pop_base
	gen age_26to29_female = B01001035/pop_base
	gen age_30to34_female = B01001036 /pop_base
	gen age_35to49_female = (B01001037 + B01001038 + B01001039)/pop_base
	gen age_50to64_female = (B01001040 + B01001041 + B01001042 + B01001043)/pop_base
	gen age_65plus_female = (B01001044 + B01001045 + B01001046 + B01001047 + B01001048 + B01001049)/pop_base
	
	foreach v in male female {
		gen age_12to17_`v' = age_12to14_`v' + age_15to17_`v'
		gen age_18to25_`v' = age_18to19_`v' + age_20to25_`v'
		gen age_26to34_`v' = age_26to29_`v' + age_30to34_`v'
		gen age_35to64_`v' = age_35to49_`v' + age_50to64_`v'
	}
	
	* Check that shares sum to one
	gen test_age_sex = 0 
	foreach v1 in age_12to14 age_15to17 age_18to19 age_20to25 age_26to29 age_30to34 age_35to49 age_50to64 age_65plus {
	
		foreach v2 in male female {
				
			replace test_age_sex = test_age_sex + `v1'_`v2'
		}
	}
	
	*------ AGE-SEX-RACE ------*
	* Code "12-17" to match NSDUH (really 10-17)
	* Code "18-25" to match NSDUH (really 18-24)
	
	foreach v1 in "H" "B" "I" {
		
		gen age_12to17_male_``v1'_ti' = (B01001`v1'005 + B01001`v1'006)/pop_base
		gen age_18to25_male_``v1'_ti' = (B01001`v1'007 + B01001`v1'008)/pop_base
		gen age_26to34_male_``v1'_ti' = (B01001`v1'009 + B01001`v1'010)/pop_base
		gen age_35to64_male_``v1'_ti' = (B01001`v1'011 + B01001`v1'012 + B01001`v1'013)/pop_base
		gen age_65plus_male_``v1'_ti' = (B01001`v1'014 + B01001`v1'015 + B01001`v1'016)/pop_base
			
		gen age_12to17_female_``v1'_ti' = (B01001`v1'020 + B01001`v1'021)/pop_base
		gen age_18to25_female_``v1'_ti' = (B01001`v1'022 + B01001`v1'023)/pop_base
		gen age_26to34_female_``v1'_ti' = (B01001`v1'024 + B01001`v1'025)/pop_base
		gen age_35to64_female_``v1'_ti' = (B01001`v1'026 + B01001`v1'027 + B01001`v1'028)/pop_base
		gen age_65plus_female_``v1'_ti' = (B01001`v1'029 + B01001`v1'030 + B01001`v1'031)/pop_base
	}
	
	gen test_age_sex_race = 0 
	foreach v2 in age_12to17 age_18to25 age_26to34 age_35to64 age_65plus {
				
		foreach v3 in male female {
			
			gen `v2'_`v3'_other = `v2'_`v3' - `v2'_`v3'_white - `v2'_`v3'_black - `v2'_`v3'_hisp
					
			* Check that shares sum to one
			replace test_age_sex_race = test_age_sex_race + `v2'_`v3'_other + `v2'_`v3'_white + `v2'_`v3'_black + `v2'_`v3'_hisp
		}
	}
	drop B01001*
	
	*------ AGE-SEX-EDUC ------*
	* Only defined for those 18+
	* Code "18-25" to match NSDUH (really 18-24)
	
	gen age_18to25_male_lths = (B15001004 + B15001005)/pop_base
	gen age_18to25_male_hsg = B15001006/pop_base
	gen age_18to25_male_scol = (B15001007 + B15001008)/pop_base
	gen age_18to25_male_cplus = (B15001009 + B15001010)/pop_base
	
	gen age_26to34_male_lths = (B15001012 + B15001013)/pop_base
	gen age_26to34_male_hsg = B15001014/pop_base
	gen age_26to34_male_scol = (B15001015 + B15001016)/pop_base
	gen age_26to34_male_cplus = (B15001017 + B15001018)/pop_base
	
	gen age_35to64_male_lths = (B15001020 + B15001021 + B15001028 + B15001029)/pop_base
	gen age_35to64_male_hsg = (B15001022 + B15001030)/pop_base
	gen age_35to64_male_scol = (B15001023 + B15001024 + B15001031 + B15001032)/pop_base
	gen age_35to64_male_cplus = (B15001025 + B15001026 + B15001033 + B15001034)/pop_base
	
	gen age_65plus_male_lths = (B15001036 + B15001037)/pop_base
	gen age_65plus_male_hsg = B15001038/pop_base
	gen age_65plus_male_scol = (B15001039 + B15001040)/pop_base
	gen age_65plus_male_cplus = (B15001041 + B15001042)/pop_base
	
	gen age_18to25_female_lths = (B15001045 + B15001046)/pop_base
	gen age_18to25_female_hsg = B15001047/pop_base
	gen age_18to25_female_scol = (B15001048 + B15001049)/pop_base
	gen age_18to25_female_cplus = (B15001050 + B15001051)/pop_base
	
	gen age_26to34_female_lths = (B15001053 + B15001054)/pop_base
	gen age_26to34_female_hsg = B15001055/pop_base
	gen age_26to34_female_scol = (B15001056 + B15001057)/pop_base
	gen age_26to34_female_cplus = (B15001058 + B15001059)/pop_base
	
	gen age_35to64_female_lths = (B15001061 + B15001062 + B15001069 + B15001070)/pop_base
	gen age_35to64_female_hsg = (B15001063 + B15001071)/pop_base
	gen age_35to64_female_scol = (B15001064 + B15001065 + B15001072 + B15001073)/pop_base
	gen age_35to64_female_cplus = (B15001066 + B15001067 + B15001074 + B15001075)/pop_base
	
	gen age_65plus_female_lths = (B15001077 + B15001078)/pop_base
	gen age_65plus_female_hsg = B15001079/pop_base
	gen age_65plus_female_scol = (B15001080 + B15001081)/pop_base
	gen age_65plus_female_cplus = (B15001082 + B15001083)/pop_base
	
	gen test_age_sex_educ = age_12to17_male + age_12to17_female
	foreach v1 in age_18to25 age_26to34 age_35to64 age_65plus {
	
		foreach v2 in male female {
			
			foreach v3 in lths hsg scol cplus {
				
				replace test_age_sex_educ = test_age_sex_educ + `v1'_`v2'_`v3'
			}
		}
	}
	drop B15001*
	
	*------- AGE-SEX-EMP ------*
	* Only defined for those 16+
	* Code "20-25" to match NSDUH (really 20-24)
	
	gen age_16to19_male_emp_yes = (B23001005 + B23001007)/pop_base
	gen age_16to19_male_emp_no = B23001008/pop_base
	gen age_16to19_male_emp_nlf = B23001009/pop_base
	
	gen age_20to25_male_emp_yes = (B23001012 + B23001014 + B23001019 + B23001021)/pop_base
	gen age_20to25_male_emp_no = (B23001015 + B23001022)/pop_base
	gen age_20to25_male_emp_nlf = (B23001016 + B23001023)/pop_base
	
	gen age_26to34_male_emp_yes = (B23001026 + B23001028 + B23001033 + B23001035)/pop_base
	gen age_26to34_male_emp_no = (B23001029 + B23001036)/pop_base
	gen age_26to34_male_emp_nlf = (B23001030 + B23001037)/pop_base
	
	gen age_35to64_male_emp_yes = (B23001040 + B23001042 + B23001047 + B23001049 + B23001054 + B23001056 + B23001061 + B23001063 + B23001068 + B23001070)/pop_base
	gen age_35to64_male_emp_no = (B23001043 + B23001050 + B23001057 + B23001064 + B23001071)/pop_base
	gen age_35to64_male_emp_nlf = (B23001044 + B23001051 + B23001058 + B23001065 + B23001072)/pop_base
	
	gen age_65plus_male_emp_yes = (B23001075 + B23001080 + B23001085)/pop_base
	gen age_65plus_male_emp_no = (B23001076 + B23001081 + B23001086)/pop_base
	gen age_65plus_male_emp_nlf = (B23001077 + B23001082 + B23001087)/pop_base
	
	gen age_16to19_female_emp_yes = (B23001091 + B23001093)/pop_base
	gen age_16to19_female_emp_no = B23001094/pop_base
	gen age_16to19_female_emp_nlf = B23001095/pop_base
	
	gen age_20to25_female_emp_yes = (B23001098 + B23001100 + B23001105 + B23001107)/pop_base
	gen age_20to25_female_emp_no = (B23001101 + B23001108)/pop_base
	gen age_20to25_female_emp_nlf = (B23001102 + B23001109)/pop_base
	
	gen age_26to34_female_emp_yes = (B23001112 + B23001114 + B23001119 + B23001121)/pop_base
	gen age_26to34_female_emp_no = (B23001115 + B23001122)/pop_base
	gen age_26to34_female_emp_nlf = (B23001116 + B23001123)/pop_base
	
	gen age_35to64_female_emp_yes = (B23001126 + B23001128 + B23001133 + B23001135 + B23001140 + B23001142 + B23001147 + B23001149 + B23001154 + B23001156)/pop_base
	gen age_35to64_female_emp_no = (B23001129 + B23001136 + B23001143 + B23001150 + B23001157)/pop_base
	gen age_35to64_female_emp_nlf = (B23001130 + B23001137 + B23001144 + B23001151 + B23001158)/pop_base
	
	gen age_65plus_female_emp_yes = (B23001161 + B23001166 + B23001171)/pop_base
	gen age_65plus_female_emp_no = (B23001162 + B23001167 + B23001172)/pop_base
	gen age_65plus_female_emp_nlf = (B23001163 + B23001168 + B23001173)/pop_base
	
	* Back out population aged 15 
	gen age_15_male = age_15to17_male + age_18to19_male - B23001003/pop_base
	gen age_15_female = age_15to17_female + age_18to19_female - B23001089/pop_base
	
	gen test_age_sex_emp = age_12to14_male + age_15_male + age_12to14_female + age_15_female
	foreach v1 in age_16to19 age_20to25 age_26to34 age_35to64 age_65plus {
	
		foreach v2 in male female {
		
			foreach v3 in emp_yes emp_no emp_nlf {
			
				replace test_age_sex_emp = test_age_sex_emp + `v1'_`v2'_`v3'
			}
		}
	}
	drop B23001* age_15_*
	
	*------- INCOME-RACE ------*
	
	gen fam_base = B19101001
	
	foreach v1 in "H" "B" "I" "" {
	
		gen inc_lt10_``v1'_ti' = B19101`v1'002/fam_base
		gen inc_10to19_``v1'_ti' = (B19101`v1'003 + B19101`v1'004)/fam_base
		gen inc_20to29_``v1'_ti' = (B19101`v1'005 + B19101`v1'006)/fam_base
		gen inc_30to39_``v1'_ti' = (B19101`v1'007 + B19101`v1'008)/fam_base
		gen inc_40to49_``v1'_ti' = (B19101`v1'009 + B19101`v1'010)/fam_base
		gen inc_50to74_``v1'_ti' = (B19101`v1'011 + B19101`v1'012)/fam_base
		gen inc_75plus_``v1'_ti' = (B19101`v1'013 + B19101`v1'014 + B19101`v1'015 + B19101`v1'016 + B19101`v1'017)/fam_base
	}

	gen test_inc_race = 0 
	foreach v1 in inc_lt10 inc_10to19 inc_20to29 inc_30to39 inc_40to49 inc_50to74 inc_75plus {
	
		gen `v1'_other = `v1'_ - `v1'_white - `v1'_black - `v1'_hisp 
		drop `v1'_
		replace test_inc_race = test_inc_race + `v1'_white + `v1'_black + `v1'_hisp + `v1'_other
	}
	drop B19101*
	
	*---- AGE-SEX-RACE-POV ----*
	* Code "18-25" to match NSDUH (really 18-24)
	
	* Update population base (actually 12+ with some excluded) 
	gen pov_base = B17001001 - B17001004 - B17001005 - B17001006 - B17001018 - B17001019 - B17001020 - ///
	               B17001033 - B17001034 - B17001035 - B17001047 - B17001048 - B17001049 
	
	foreach v1 in "H" "B" "I" "" {
	
		gen age_12to17_male_``v1'_ti'_pov_yes = (B17001`v1'007 + B17001`v1'008 + B17001`v1'009)/pov_base
		gen age_18to25_male_``v1'_ti'_pov_yes = B17001`v1'010/pov_base
		gen age_26to34_male_``v1'_ti'_pov_yes = B17001`v1'011/pov_base
		gen age_35to64_male_``v1'_ti'_pov_yes = (B17001`v1'012 + B17001`v1'013 + B17001`v1'014)/pov_base
		gen age_65plus_male_``v1'_ti'_pov_yes = (B17001`v1'015 + B17001`v1'016)/pov_base
		
		gen age_12to17_female_``v1'_ti'_pov_yes = (B17001`v1'021 + B17001`v1'022 + B17001`v1'023)/pov_base
		gen age_18to25_female_``v1'_ti'_pov_yes = B17001`v1'024/pov_base
		gen age_26to34_female_``v1'_ti'_pov_yes = B17001`v1'025/pov_base
		gen age_35to64_female_``v1'_ti'_pov_yes = (B17001`v1'026 + B17001`v1'027 + B17001`v1'028)/pov_base
		gen age_65plus_female_``v1'_ti'_pov_yes = (B17001`v1'029 + B17001`v1'030)/pov_base
		
		gen age_12to17_male_``v1'_ti'_pov_no = (B17001`v1'036 + B17001`v1'037 + B17001`v1'038)/pov_base
		gen age_18to25_male_``v1'_ti'_pov_no = B17001`v1'039/pov_base
		gen age_26to34_male_``v1'_ti'_pov_no = B17001`v1'040/pov_base
		gen age_35to64_male_``v1'_ti'_pov_no = (B17001`v1'041 + B17001`v1'042 + B17001`v1'043)/pov_base
		gen age_65plus_male_``v1'_ti'_pov_no = (B17001`v1'044 + B17001`v1'045)/pov_base
		
		gen age_12to17_female_``v1'_ti'_pov_no = (B17001`v1'050 + B17001`v1'051 + B17001`v1'052)/pov_base
		gen age_18to25_female_``v1'_ti'_pov_no = B17001`v1'053/pov_base
		gen age_26to34_female_``v1'_ti'_pov_no = B17001`v1'054/pov_base
		gen age_35to64_female_``v1'_ti'_pov_no = (B17001`v1'055 + B17001`v1'056 + B17001`v1'057)/pov_base
		gen age_65plus_female_``v1'_ti'_pov_no = (B17001`v1'058 + B17001`v1'059)/pov_base
	}
		
	gen test_age_sex_race_pov = 0 
	foreach v1 in age_12to17 age_18to25 age_26to34 age_35to64 age_65plus {
		
		foreach v2 in male female {
		
			foreach v3 in pov_yes pov_no {
			
				gen `v1'_`v2'_other_`v3' = `v1'_`v2'__`v3' - `v1'_`v2'_white_`v3' - `v1'_`v2'_black_`v3' - `v1'_`v2'_hisp_`v3'
				replace test_age_sex_race_pov = test_age_sex_race_pov + `v1'_`v2'_white_`v3' + `v1'_`v2'_black_`v3' + `v1'_`v2'_hisp_`v3' + `v1'_`v2'_other_`v3' 
			}
		}
	}
	drop B17001*
	
	*----- AGE-SEX-RACE-HI ----*
	* Code "12-17" to match NSDUH (really 6-17)
	* Code "18-25" to match NSDUH (really 18-24)
	
	* Update population base (actually 6+)
	gen hi_base = B27001001 - B27001003 - B27001031
	
	gen age_12to17_male_hi_yes = B27001007/hi_base
	gen age_18to25_male_hi_yes = B27001010/hi_base
	gen age_26to34_male_hi_yes = B27001013/hi_base
 	gen age_35to64_male_hi_yes = (B27001016 + B27001019 + B27001022)/hi_base
	gen age_65plus_male_hi_yes = (B27001025 + B27001028)/hi_base
	
	gen age_12to17_male_hi_no = B27001008/hi_base
	gen age_18to25_male_hi_no = B27001011/hi_base
	gen age_26to34_male_hi_no = B27001014/hi_base
	gen age_35to64_male_hi_no = (B27001017 + B27001020 + B27001023)/hi_base
	gen age_65plus_male_hi_no = (B27001026 + B27001029)/hi_base
	
	gen age_12to17_female_hi_yes = B27001035/hi_base
	gen age_18to25_female_hi_yes = B27001038/hi_base
	gen age_26to34_female_hi_yes = B27001041/hi_base
 	gen age_35to64_female_hi_yes = (B27001044 + B27001047 + B27001050)/hi_base
	gen age_65plus_female_hi_yes = (B27001053 + B27001056)/hi_base
	
	gen age_12to17_female_hi_no = B27001036/hi_base
	gen age_18to25_female_hi_no = B27001039/hi_base
	gen age_26to34_female_hi_no = B27001042/hi_base
	gen age_35to64_female_hi_no = (B27001045 + B27001048 + B27001051)/hi_base
	gen age_65plus_female_hi_no = (B27001054 + B27001057)/hi_base
	
	gen test_age_sex_hi = 0 
	foreach v1 in age_12to17 age_18to25 age_26to34 age_35to64 age_65plus {
		
		foreach v2 in male female {
			
			foreach v3 in hi_yes hi_no {
				
				replace test_age_sex_hi = test_age_sex_hi + `v1'_`v2'_`v3'
			}
		}
	}
	drop B27001*
	
	*----- AGE-SEX-MARITAL ----*
	* Only defined for those 15+
	* Code "18-25" to match NSDUH (really 18-24)
	
	gen age_15to17_male_mar_nvr = B12002004/pop_base
	gen age_18to25_male_mar_nvr = (B12002005 + B12002006)/pop_base
	gen age_26to34_male_mar_nvr = (B12002007 + B12002008)/pop_base
	gen age_35to49_male_mar_nvr = (B12002009 + B12002010 + B12002011)/pop_base
	gen age_50to64_male_mar_nvr = (B12002012 + B12002013 + B12002014)/pop_base
	gen age_65plus_male_mar_nvr = (B12002015 + B12002016 + B12002017)/pop_base
	
	gen age_15to17_male_mar_yes = B12002020/pop_base
	gen age_18to25_male_mar_yes = (B12002021 + B12002022)/pop_base
	gen age_26to34_male_mar_yes = (B12002023 + B12002024)/pop_base
	gen age_35to49_male_mar_yes = (B12002025 + B12002026 + B12002027)/pop_base
	gen age_50to64_male_mar_yes = (B12002028 + B12002029 + B12002030)/pop_base
	gen age_65plus_male_mar_yes = (B12002031 + B12002032 + B12002033)/pop_base
	
	gen age_15to17_male_mar_oth = (B12002036 + B12002051 + B12002066 + B12002081)/pop_base
	gen age_18to25_male_mar_oth = (B12002037 + B12002038 + B12002052 + B12002053 + B12002067 + B12002068 + B12002082 + B12002083)/pop_base
	gen age_26to34_male_mar_oth = (B12002039 + B12002040 + B12002054 + B12002055 + B12002069 + B12002070 + B12002084 + B12002085)/pop_base 
	gen age_35to49_male_mar_oth = (B12002041 + B12002042 + B12002043 + B12002056 + B12002057 + B12002058 + B12002071 + B12002072 + B12002073 + B12002086 + B12002087 + B12002088)/pop_base
	gen age_50to64_male_mar_oth = (B12002044 + B12002045 + B12002046 + B12002059 + B12002060 + B12002061 + B12002074 + B12002075 + B12002076 + B12002089 + B12002090 + B12002091)/pop_base
	gen age_65plus_male_mar_oth = (B12002047 + B12002048 + B12002049 + B12002062 + B12002063 + B12002064 + B12002077 + B12002078 + B12002079 + B12002092 + B12002093 + B12002094)/pop_base
				   
	gen age_15to17_female_mar_nvr = B12002097/pop_base
	gen age_18to25_female_mar_nvr = (B12002098 + B12002099)/pop_base
	gen age_26to34_female_mar_nvr = (B12002100 + B12002101)/pop_base
	gen age_35to49_female_mar_nvr = (B12002102 + B12002103 + B12002104)/pop_base
	gen age_50to64_female_mar_nvr = (B12002105 + B12002106 + B12002107)/pop_base
	gen age_65plus_female_mar_nvr = (B12002108 + B12002109 + B12002110)/pop_base
	
	gen age_15to17_female_mar_yes = B12002113/pop_base
	gen age_18to25_female_mar_yes = (B12002114 + B12002115)/pop_base
	gen age_26to34_female_mar_yes = (B12002116 + B12002117)/pop_base
	gen age_35to49_female_mar_yes = (B12002118 + B12002119 + B12002120)/pop_base
	gen age_50to64_female_mar_yes = (B12002121 + B12002122 + B12002123)/pop_base
	gen age_65plus_female_mar_yes = (B12002124 + B12002125 + B12002126)/pop_base
	
	gen age_15to17_female_mar_oth = (B12002129 + B12002144 + B12002159 + B12002174)/pop_base
	gen age_18to25_female_mar_oth = (B12002130 + B12002131 + B12002145 + B12002146 + B12002160 + B12002161 + B12002175 + B12002176)/pop_base
	gen age_26to34_female_mar_oth = (B12002132 + B12002133 + B12002147 + B12002148 + B12002162 + B12002163 + B12002177 + B12002178)/pop_base 
	gen age_35to49_female_mar_oth = (B12002134 + B12002135 + B12002136 + B12002149 + B12002150 + B12002151 + B12002164 + B12002165 + B12002166 + B12002179 + B12002180 + B12002181)/pop_base
	gen age_50to64_female_mar_oth = (B12002137 + B12002138 + B12002139 + B12002152 + B12002153 + B12002154 + B12002167 + B12002168 + B12002169 + B12002182 + B12002183 + B12002184)/pop_base
	gen age_65plus_female_mar_oth = (B12002140 + B12002141 + B12002142 + B12002155 + B12002156 + B12002157 + B12002170 + B12002171 + B12002172 + B12002185 + B12002186 + B12002187)/pop_base
	
	gen test_age_sex_mar = age_12to14_male + age_12to14_female 
	foreach v1 in age_15to17 age_18to25 age_26to34 age_35to49 age_50to64 age_65plus {
	
		foreach v2 in male female {
		
			foreach v3 in mar_nvr mar_yes mar_oth {
			
				replace test_age_sex_mar = test_age_sex_mar + `v1'_`v2'_`v3'
			}
		}
	}
	drop B12002*
	
	sum test* 
	drop test* pop_base fam_base pov_base hi_base
	
	save "${inter}/ACS_county_NSDUH_1014.dta", replace

***********************************************************************
*--------------------- c. Create NHIS categories ---------------------*
***********************************************************************

use "${raw_public}/acs/R12543447.dta", clear

	keep FIPS STATE B01001* B12002* B15001* B17001* B19101* B23001* B27001*
	rename FIPS county_fips
	rename STATE state_fips
	destring state_fips, replace
	qui compress
	
	* Drop Puerto Rico
	drop if state_fips == 72
	
	*---- TOTAL POPULATION ----*
	rename B01001001 pop_tot
	
	* 18 and over
	gen pop_base = B01001007 + B01001008 + B01001009 + B01001010 + B01001011 + B01001012 + B01001013 + ///
		       B01001014 + B01001015 + B01001016 + B01001017 + B01001018 + B01001019 + B01001020 + ///
		       B01001021 + B01001022 + B01001023 + B01001024 + B01001025 + ///
		       B01001031 + B01001032 + B01001033 + B01001034 + B01001035 + B01001036 + B01001037 + ///
		       B01001038 + B01001039 + B01001040 + B01001041 + B01001042 + B01001043 + B01001044 + ///
		       B01001045 + B01001046 + B01001047 + B01001048 + B01001049

	*--------- AGE-SEX --------*
	
	gen age_18to19_male = B01001007/pop_base
	gen age_20_male = B01001008/pop_base
	gen age_21_male = B01001009/pop_base
	gen age_22to24_male = B01001010/pop_base
	gen age_25to29_male = B01001011/pop_base
	gen age_30to34_male = B01001012/pop_base
	gen age_35to39_male = B01001013/pop_base
	gen age_40to44_male = B01001014/pop_base
	gen age_45to49_male = B01001015/pop_base
	gen age_50to54_male = B01001016/pop_base
	gen age_55to59_male = B01001017/pop_base
	gen age_60to61_male = B01001018/pop_base
	gen age_62to64_male = B01001019/pop_base
	gen age_65to66_male = B01001020/pop_base
	gen age_67to69_male = B01001021/pop_base
	gen age_70to74_male = B01001022/pop_base
	gen age_75to79_male = B01001023/pop_base
	gen age_80to84_male = B01001024/pop_base
	gen age_85plus_male = B01001025/pop_base
	
	gen age_18to19_female = B01001031/pop_base
	gen age_20_female = B01001032/pop_base
	gen age_21_female = B01001033/pop_base
	gen age_22to24_female = B01001034/pop_base
	gen age_25to29_female = B01001035/pop_base
	gen age_30to34_female = B01001036/pop_base
	gen age_35to39_female = B01001037/pop_base
	gen age_40to44_female = B01001038/pop_base
	gen age_45to49_female = B01001039/pop_base
	gen age_50to54_female = B01001040/pop_base
	gen age_55to59_female = B01001041/pop_base
	gen age_60to61_female = B01001042/pop_base
	gen age_62to64_female = B01001043/pop_base
	gen age_65to66_female = B01001044/pop_base
	gen age_67to69_female = B01001045/pop_base
	gen age_70to74_female = B01001046/pop_base
	gen age_75to79_female = B01001047/pop_base
	gen age_80to84_female = B01001048/pop_base
	gen age_85plus_female = B01001049/pop_base
	
	foreach v in male female {
		gen age_20to24_`v' = age_20_`v' + age_21_`v' + age_22to24_`v'
		gen age_18to24_`v' = age_18to19_`v' + age_20to24_`v'
		gen age_25to34_`v' = age_25to29_`v' + age_30to34_`v'
		gen age_35to44_`v' = age_35to39_`v' + age_40to44_`v'
		gen age_45to54_`v' = age_45to49_`v' + age_50to54_`v'
		gen age_55to64_`v' = age_55to59_`v' + age_60to61_`v' + age_62to64_`v'
		gen age_45to64_`v' = age_45to54_`v' + age_55to64_`v'
		gen age_65to74_`v' = age_65to66_`v' + age_67to69_`v' + age_70to74_`v'
		gen age_75to84_`v' = age_75to79_`v' + age_80to84_`v'
		gen age_65plus_`v' = age_65to74_`v' + age_75to84_`v' + age_85plus_`v'
	}
	
	* Check that shares sum to one
	gen test_age_sex = 0 
	foreach v1 in age_18to19 age_20 age_21 age_22to24 age_25to29 age_30to34 age_35to39 age_40to44 age_45to49 age_50to54 ///
	              age_55to59 age_60to61 age_62to64 age_65to66 age_67to69 age_70to74 age_75to79 age_80to84 age_85plus {
		     
		foreach v2 in male female {
				
			replace test_age_sex = test_age_sex + `v1'_`v2'
		}
	}
	
	*------ AGE-SEX-RACE ------*
	
	foreach v1 in "H" "B" "I" {
		
		gen age_18to19_male_``v1'_ti' = B01001`v1'007/pop_base
		gen age_20to24_male_``v1'_ti' = B01001`v1'008/pop_base
		gen age_25to29_male_``v1'_ti' = B01001`v1'009/pop_base
		gen age_30to34_male_``v1'_ti' = B01001`v1'010/pop_base
		gen age_35to44_male_``v1'_ti' = B01001`v1'011/pop_base
		gen age_45to54_male_``v1'_ti' = B01001`v1'012/pop_base
		gen age_55to64_male_``v1'_ti' = B01001`v1'013/pop_base
		gen age_65to74_male_``v1'_ti' = B01001`v1'014/pop_base
		gen age_75to84_male_``v1'_ti' = B01001`v1'015/pop_base
		gen age_85plus_male_``v1'_ti' = B01001`v1'016/pop_base
		
		gen age_18to19_female_``v1'_ti' = B01001`v1'022/pop_base
		gen age_20to24_female_``v1'_ti' = B01001`v1'023/pop_base
		gen age_25to29_female_``v1'_ti' = B01001`v1'024/pop_base
		gen age_30to34_female_``v1'_ti' = B01001`v1'025/pop_base
		gen age_35to44_female_``v1'_ti' = B01001`v1'026/pop_base
		gen age_45to54_female_``v1'_ti' = B01001`v1'027/pop_base
		gen age_55to64_female_``v1'_ti' = B01001`v1'028/pop_base
		gen age_65to74_female_``v1'_ti' = B01001`v1'029/pop_base
		gen age_75to84_female_``v1'_ti' = B01001`v1'030/pop_base
		gen age_85plus_female_``v1'_ti' = B01001`v1'031/pop_base
	}
	
	gen test_age_sex_race = 0 
	foreach v2 in age_18to19 age_20to24 age_25to29 age_30to34 age_35to44 ///
	              age_45to54 age_55to64 age_65to74 age_75to84 age_85plus {
				
		foreach v3 in male female {
			
			gen `v2'_`v3'_other = `v2'_`v3' - `v2'_`v3'_white - `v2'_`v3'_black - `v2'_`v3'_hisp
					
			* Check that shares sum to one
			replace test_age_sex_race = test_age_sex_race + `v2'_`v3'_other + `v2'_`v3'_white + `v2'_`v3'_black + `v2'_`v3'_hisp
		}
	}
	drop B01001*
	
	*------ AGE-SEX-EDUC ------*
	
	gen age_18to24_male_lths = (B15001004 + B15001005)/pop_base
	gen age_18to24_male_hsg = B15001006/pop_base
	gen age_18to24_male_scol = (B15001007 + B15001008)/pop_base
	gen age_18to24_male_cplus = (B15001009 + B15001010)/pop_base
	
	gen age_25to34_male_lths = (B15001012 + B15001013)/pop_base
	gen age_25to34_male_hsg = B15001014/pop_base
	gen age_25to34_male_scol = (B15001015 + B15001016)/pop_base
	gen age_25to34_male_cplus = (B15001017 + B15001018)/pop_base
	
	gen age_35to44_male_lths = (B15001020 + B15001021)/pop_base
	gen age_35to44_male_hsg = B15001022/pop_base
	gen age_35to44_male_scol = (B15001023 + B15001024)/pop_base
	gen age_35to44_male_cplus = (B15001025 + B15001026)/pop_base
	
	gen age_45to64_male_lths = (B15001028 + B15001029)/pop_base
	gen age_45to64_male_hsg = B15001030/pop_base
	gen age_45to64_male_scol = (B15001031 + B15001032)/pop_base
	gen age_45to64_male_cplus = (B15001033 + B15001034)/pop_base
	
	gen age_65plus_male_lths = (B15001036 + B15001037)/pop_base
	gen age_65plus_male_hsg = B15001038/pop_base
	gen age_65plus_male_scol = (B15001039 + B15001040)/pop_base
	gen age_65plus_male_cplus = (B15001041 + B15001042)/pop_base
	
	gen age_18to24_female_lths = (B15001045 + B15001046)/pop_base
	gen age_18to24_female_hsg = B15001047/pop_base
	gen age_18to24_female_scol = (B15001048 + B15001049)/pop_base
	gen age_18to24_female_cplus = (B15001050 + B15001051)/pop_base
	
	gen age_25to34_female_lths = (B15001053 + B15001054)/pop_base
	gen age_25to34_female_hsg = B15001055/pop_base
	gen age_25to34_female_scol = (B15001056 + B15001057)/pop_base
	gen age_25to34_female_cplus = (B15001058 + B15001059)/pop_base
	
	gen age_35to44_female_lths = (B15001061 + B15001062)/pop_base
	gen age_35to44_female_hsg = B15001063/pop_base
	gen age_35to44_female_scol = (B15001064 + B15001065)/pop_base
	gen age_35to44_female_cplus = (B15001066 + B15001067)/pop_base
	
	gen age_45to64_female_lths = (B15001069 + B15001070)/pop_base
	gen age_45to64_female_hsg = B15001071/pop_base
	gen age_45to64_female_scol = (B15001072 + B15001073)/pop_base
	gen age_45to64_female_cplus = (B15001074 + B15001075)/pop_base
	
	gen age_65plus_female_lths = (B15001077 + B15001078)/pop_base
	gen age_65plus_female_hsg = B15001079/pop_base
	gen age_65plus_female_scol = (B15001080 + B15001081)/pop_base
	gen age_65plus_female_cplus = (B15001082 + B15001083)/pop_base
	
	gen test_age_sex_educ = 0
	foreach v1 in age_18to24 age_25to34 age_35to44 age_45to64 age_65plus {
	
		foreach v2 in male female {
			
			foreach v3 in lths hsg scol cplus {
				
				replace test_age_sex_educ = test_age_sex_educ + `v1'_`v2'_`v3'
			}
		}
	}
	drop B15001*
	
	*------- AGE-SEX-EMP ------*
	* Code "18-19" to match NHIS (really 16-19)
	
	* Update population base (actually 16+)
	gen emp_base = B23001001
	
	gen age_18to19_male_emp_yes = (B23001005 + B23001007)/emp_base
	gen age_18to19_male_emp_no = B23001008/emp_base
	gen age_18to19_male_emp_nlf = B23001009/emp_base
	
	gen age_20to21_male_emp_yes = (B23001012 + B23001014)/emp_base
	gen age_20to21_male_emp_no = B23001015/emp_base
	gen age_20to21_male_emp_nlf = B23001016/emp_base
	
	gen age_22to24_male_emp_yes = (B23001019 + B23001021)/emp_base
	gen age_22to24_male_emp_no = B23001022/emp_base
	gen age_22to24_male_emp_nlf = B23001023/emp_base
	
	gen age_25to29_male_emp_yes = (B23001026 + B23001028)/emp_base
	gen age_25to29_male_emp_no = B23001029/emp_base
	gen age_25to29_male_emp_nlf = B23001030/emp_base
	
	gen age_30to34_male_emp_yes = (B23001033 + B23001035)/emp_base
	gen age_30to34_male_emp_no = B23001036/emp_base
	gen age_30to34_male_emp_nlf = B23001037/emp_base
	
	gen age_35to44_male_emp_yes = (B23001040 + B23001042)/emp_base
	gen age_35to44_male_emp_no = B23001043/emp_base
	gen age_35to44_male_emp_nlf = B23001044/emp_base
	
	gen age_45to54_male_emp_yes = (B23001047 + B23001049)/emp_base
	gen age_45to54_male_emp_no = B23001050/emp_base
	gen age_45to54_male_emp_nlf = B23001051/emp_base
	
	gen age_55to59_male_emp_yes = (B23001054 + B23001056)/emp_base
	gen age_55to59_male_emp_no = B23001057/emp_base
	gen age_55to59_male_emp_nlf = B23001058/emp_base
	
	gen age_60to61_male_emp_yes = (B23001061 + B23001063)/emp_base
	gen age_60to61_male_emp_no = B23001064/emp_base
	gen age_60to61_male_emp_nlf = B23001065/emp_base
	
	gen age_62to64_male_emp_yes = (B23001068 + B23001070)/emp_base
	gen age_62to64_male_emp_no = B23001071/emp_base
	gen age_62to64_male_emp_nlf = B23001072/emp_base
	
	gen age_65to69_male_emp_yes = B23001075/emp_base
	gen age_65to69_male_emp_no = B23001076/emp_base
	gen age_65to69_male_emp_nlf = B23001077/emp_base
	
	gen age_70to74_male_emp_yes = B23001080/emp_base
	gen age_70to74_male_emp_no = B23001081/emp_base
	gen age_70to74_male_emp_nlf = B23001082/emp_base
	
	gen age_75plus_male_emp_yes = B23001085/emp_base
	gen age_75plus_male_emp_no = B23001086/emp_base
	gen age_75plus_male_emp_nlf = B23001087/emp_base
	
	gen age_18to19_female_emp_yes = (B23001091 + B23001093)/emp_base
	gen age_18to19_female_emp_no = B23001094/emp_base
	gen age_18to19_female_emp_nlf = B23001095/emp_base
	
	gen age_20to21_female_emp_yes = (B23001098 + B23001100)/emp_base
	gen age_20to21_female_emp_no = B23001101/emp_base
	gen age_20to21_female_emp_nlf = B23001102/emp_base
	
	gen age_22to24_female_emp_yes = (B23001105 + B23001107)/emp_base
	gen age_22to24_female_emp_no = B23001108/emp_base
	gen age_22to24_female_emp_nlf = B23001109/emp_base
	
	gen age_25to29_female_emp_yes = (B23001112 + B23001114)/emp_base
	gen age_25to29_female_emp_no = B23001115/emp_base
	gen age_25to29_female_emp_nlf = B23001116/emp_base
	
	gen age_30to34_female_emp_yes = (B23001119 + B23001121)/emp_base
	gen age_30to34_female_emp_no = B23001122/emp_base
	gen age_30to34_female_emp_nlf = B23001123/emp_base
	
	gen age_35to44_female_emp_yes = (B23001126 + B23001128)/emp_base
	gen age_35to44_female_emp_no = B23001129/emp_base
	gen age_35to44_female_emp_nlf = B23001130/emp_base
	
	gen age_45to54_female_emp_yes = (B23001133 + B23001135)/emp_base
	gen age_45to54_female_emp_no = B23001136/emp_base
	gen age_45to54_female_emp_nlf = B23001137/emp_base
	
	gen age_55to59_female_emp_yes = (B23001140 + B23001142)/emp_base
	gen age_55to59_female_emp_no = B23001143/emp_base
	gen age_55to59_female_emp_nlf = B23001144/emp_base
	
	gen age_60to61_female_emp_yes = (B23001147 + B23001149)/emp_base
	gen age_60to61_female_emp_no = B23001150/emp_base
	gen age_60to61_female_emp_nlf = B23001151/emp_base
	
	gen age_62to64_female_emp_yes = (B23001154 + B23001156)/emp_base
	gen age_62to64_female_emp_no = B23001157/emp_base
	gen age_62to64_female_emp_nlf = B23001158/emp_base
	
	gen age_65to69_female_emp_yes = B23001161/emp_base
	gen age_65to69_female_emp_no = B23001162/emp_base
	gen age_65to69_female_emp_nlf = B23001163/emp_base
	
	gen age_70to74_female_emp_yes = B23001166/emp_base
	gen age_70to74_female_emp_no = B23001167/emp_base
	gen age_70to74_female_emp_nlf = B23001168/emp_base
	
	gen age_75plus_female_emp_yes = B23001171/emp_base
	gen age_75plus_female_emp_no = B23001172/emp_base
	gen age_75plus_female_emp_nlf = B23001173/emp_base
	
	gen test_age_sex_emp = 0
	foreach v1 in age_18to19 age_20to21 age_22to24 age_25to29 age_30to34 age_35to44 age_45to54 ///
		      age_55to59 age_60to61 age_62to64 age_65to69 age_70to74 age_75plus {
	
		foreach v2 in male female {
		
			foreach v3 in emp_yes emp_no emp_nlf {
			
				replace test_age_sex_emp = test_age_sex_emp + `v1'_`v2'_`v3'
			}
		}
	}
	drop B23001*
	
	*------- INCOME-RACE ------*
	
	gen fam_base = B19101001
	
	foreach v1 in "H" "B" "I" "" {
	
		gen inc_lt35_``v1'_ti' = (B19101`v1'002 + B19101`v1'003 + B19101`v1'004 + B19101`v1'005 + B19101`v1'006 + B19101`v1'007)/fam_base
		gen inc_35to49_``v1'_ti' = (B19101`v1'008 + B19101`v1'009 + B19101`v1'010)/fam_base
		gen inc_50to74_``v1'_ti' = (B19101`v1'011 + B19101`v1'012)/fam_base
		gen inc_75to99_``v1'_ti' = B19101`v1'013/fam_base
		gen inc_100plus_``v1'_ti' = (B19101`v1'014 + B19101`v1'015 + B19101`v1'016 + B19101`v1'017)/fam_base
	}

	gen test_inc_race = 0 
	foreach v1 in inc_lt35 inc_35to49 inc_50to74 inc_75to99 inc_100plus {
	
		gen `v1'_other = `v1'_ - `v1'_white - `v1'_black - `v1'_hisp 
		drop `v1'_
		replace test_inc_race = test_inc_race + `v1'_white + `v1'_black + `v1'_hisp + `v1'_other
	}
	drop B19101*
	
	*---- AGE-SEX-RACE-POV ----*
	
	* Update population base (18+ with some excluded)
	gen pov_base = B17001001 - ///
	               B17001004 - B17001005 - B17001006 - B17001007 - B17001008 - B17001009 - ///
	               B17001018 - B17001019 - B17001020 - B17001021 - B17001022 - B17001023 - ///
		       B17001033 - B17001034 - B17001035 - B17001036 - B17001037 - B17001038 - ///
		       B17001047 - B17001048 - B17001049 - B17001050 - B17001051 - B17001052 
	
	foreach v1 in "H" "B" "I" "" {
	
		gen age_18to24_male_``v1'_ti'_pov_yes = B17001`v1'010/pov_base
		gen age_25to34_male_``v1'_ti'_pov_yes = B17001`v1'011/pov_base
		gen age_35to44_male_``v1'_ti'_pov_yes = B17001`v1'012/pov_base
		gen age_45to54_male_``v1'_ti'_pov_yes = B17001`v1'013/pov_base
		gen age_55to64_male_``v1'_ti'_pov_yes = B17001`v1'014/pov_base
		gen age_65to74_male_``v1'_ti'_pov_yes = B17001`v1'015/pov_base
		gen age_75plus_male_``v1'_ti'_pov_yes = B17001`v1'016/pov_base
		
		gen age_18to24_female_``v1'_ti'_pov_yes = B17001`v1'024/pov_base
		gen age_25to34_female_``v1'_ti'_pov_yes = B17001`v1'025/pov_base
		gen age_35to44_female_``v1'_ti'_pov_yes = B17001`v1'026/pov_base
		gen age_45to54_female_``v1'_ti'_pov_yes = B17001`v1'027/pov_base
		gen age_55to64_female_``v1'_ti'_pov_yes = B17001`v1'028/pov_base
		gen age_65to74_female_``v1'_ti'_pov_yes = B17001`v1'029/pov_base
		gen age_75plus_female_``v1'_ti'_pov_yes = B17001`v1'030/pov_base
		
		gen age_18to24_male_``v1'_ti'_pov_no = B17001`v1'039/pov_base
		gen age_25to34_male_``v1'_ti'_pov_no = B17001`v1'040/pov_base
		gen age_35to44_male_``v1'_ti'_pov_no = B17001`v1'041/pov_base
		gen age_45to54_male_``v1'_ti'_pov_no = B17001`v1'042/pov_base
		gen age_55to64_male_``v1'_ti'_pov_no = B17001`v1'043/pov_base
		gen age_65to74_male_``v1'_ti'_pov_no = B17001`v1'044/pov_base
		gen age_75plus_male_``v1'_ti'_pov_no = B17001`v1'045/pov_base
		
		gen age_18to24_female_``v1'_ti'_pov_no = B17001`v1'053/pov_base
		gen age_25to34_female_``v1'_ti'_pov_no = B17001`v1'054/pov_base
		gen age_35to44_female_``v1'_ti'_pov_no = B17001`v1'055/pov_base
		gen age_45to54_female_``v1'_ti'_pov_no = B17001`v1'056/pov_base
		gen age_55to64_female_``v1'_ti'_pov_no = B17001`v1'057/pov_base
		gen age_65to74_female_``v1'_ti'_pov_no = B17001`v1'058/pov_base
		gen age_75plus_female_``v1'_ti'_pov_no = B17001`v1'059/pov_base
	}
		
	gen test_age_sex_race_pov = 0 
	foreach v1 in age_18to24 age_25to34 age_35to44 age_45to54 age_55to64 age_65to74 age_75plus {
		
		foreach v2 in male female {
		
			foreach v3 in pov_yes pov_no {
			
				gen `v1'_`v2'_other_`v3' = `v1'_`v2'__`v3' - `v1'_`v2'_white_`v3' - `v1'_`v2'_black_`v3' - `v1'_`v2'_hisp_`v3'
				replace test_age_sex_race_pov = test_age_sex_race_pov + `v1'_`v2'_white_`v3' + `v1'_`v2'_black_`v3' + `v1'_`v2'_hisp_`v3' + `v1'_`v2'_other_`v3' 
			}
		}
	}
	drop B17001*
	
	*----- AGE-SEX-RACE-HI ----*
	
	* Update population base (18+ with some excluded)
	gen hi_base = B27001001 - B27001003 - B27001006 - B27001031 - B27001034
	
	gen age_18to24_male_hi_yes = B27001010/hi_base
	gen age_25to34_male_hi_yes = B27001013/hi_base
	gen age_35to44_male_hi_yes = B27001016/hi_base
	gen age_45to54_male_hi_yes = B27001019/hi_base
 	gen age_55to64_male_hi_yes = B27001022/hi_base
	gen age_65to74_male_hi_yes = B27001025/hi_base
	gen age_75plus_male_hi_yes = B27001028/hi_base
	
	gen age_18to24_male_hi_no = B27001011/hi_base
	gen age_25to34_male_hi_no = B27001014/hi_base
	gen age_35to44_male_hi_no = B27001017/hi_base
	gen age_45to54_male_hi_no = B27001020/hi_base
	gen age_55to64_male_hi_no = B27001023/hi_base
	gen age_65to74_male_hi_no = B27001026/hi_base
	gen age_75plus_male_hi_no = B27001029/hi_base
	
	gen age_18to24_female_hi_yes = B27001038/hi_base
	gen age_25to34_female_hi_yes = B27001041/hi_base
	gen age_35to44_female_hi_yes = B27001044/hi_base
	gen age_45to54_female_hi_yes = B27001047/hi_base
 	gen age_55to64_female_hi_yes = B27001050/hi_base
	gen age_65to74_female_hi_yes = B27001053/hi_base
	gen age_75plus_female_hi_yes = B27001056/hi_base
	
	gen age_18to24_female_hi_no = B27001039/hi_base
	gen age_25to34_female_hi_no = B27001042/hi_base
	gen age_35to44_female_hi_no = B27001045/hi_base
	gen age_45to54_female_hi_no = B27001048/hi_base
	gen age_55to64_female_hi_no = B27001051/hi_base
	gen age_65to74_female_hi_no = B27001054/hi_base
	gen age_75plus_female_hi_no = B27001057/hi_base
	
	gen test_age_sex_hi = 0 
	foreach v1 in age_18to24 age_25to34 age_35to44 age_45to54 age_55to64 age_65to74 age_75plus {
		
		foreach v2 in male female {
			
			foreach v3 in hi_yes hi_no {
				
				replace test_age_sex_hi = test_age_sex_hi + `v1'_`v2'_`v3'
			}
		}
	}
	drop B27001*
	
	*----- AGE-SEX-MARITAL ----*
	
	gen age_18to19_male_mar_nvr = B12002005/pop_base
	gen age_20to24_male_mar_nvr = B12002006/pop_base
	gen age_25to29_male_mar_nvr = B12002007/pop_base
	gen age_30to34_male_mar_nvr = B12002008/pop_base
	gen age_35to39_male_mar_nvr = B12002009/pop_base
	gen age_40to44_male_mar_nvr = B12002010/pop_base
	gen age_45to49_male_mar_nvr = B12002011/pop_base
	gen age_50to54_male_mar_nvr = B12002012/pop_base
	gen age_55to59_male_mar_nvr = B12002013/pop_base
	gen age_60to64_male_mar_nvr = B12002014/pop_base
	gen age_65to74_male_mar_nvr = B12002015/pop_base
	gen age_75to84_male_mar_nvr = B12002016/pop_base
	gen age_85plus_male_mar_nvr = B12002017/pop_base
	
	gen age_18to19_male_mar_yes = B12002021/pop_base
	gen age_20to24_male_mar_yes = B12002022/pop_base
	gen age_25to29_male_mar_yes = B12002023/pop_base
	gen age_30to34_male_mar_yes = B12002024/pop_base
	gen age_35to39_male_mar_yes = B12002025/pop_base
	gen age_40to44_male_mar_yes = B12002026/pop_base
	gen age_45to49_male_mar_yes = B12002027/pop_base
	gen age_50to54_male_mar_yes = B12002028/pop_base
	gen age_55to59_male_mar_yes = B12002029/pop_base
	gen age_60to64_male_mar_yes = B12002030/pop_base
	gen age_65to74_male_mar_yes = B12002031/pop_base
	gen age_75to84_male_mar_yes = B12002032/pop_base
	gen age_85plus_male_mar_yes = B12002033/pop_base
	
	gen age_18to19_male_mar_oth = (B12002037 + B12002052 + B12002067 + B12002082)/pop_base
	gen age_20to24_male_mar_oth = (B12002038 + B12002053 + B12002068 + B12002083)/pop_base
	gen age_25to29_male_mar_oth = (B12002039 + B12002054 + B12002069 + B12002084)/pop_base 
	gen age_30to34_male_mar_oth = (B12002040 + B12002055 + B12002070 + B12002085)/pop_base 
	gen age_35to39_male_mar_oth = (B12002041 + B12002056 + B12002071 + B12002086)/pop_base
	gen age_40to44_male_mar_oth = (B12002042 + B12002057 + B12002072 + B12002087)/pop_base
	gen age_45to49_male_mar_oth = (B12002043 + B12002058 + B12002073 + B12002088)/pop_base
	gen age_50to54_male_mar_oth = (B12002044 + B12002059 + B12002074 + B12002089)/pop_base
	gen age_55to59_male_mar_oth = (B12002045 + B12002060 + B12002075 + B12002090)/pop_base
	gen age_60to64_male_mar_oth = (B12002046 + B12002061 + B12002076 + B12002091)/pop_base
	gen age_65to74_male_mar_oth = (B12002047 + B12002062 + B12002077 + B12002092)/pop_base
	gen age_75to84_male_mar_oth = (B12002048 + B12002063 + B12002078 + B12002093)/pop_base
	gen age_85plus_male_mar_oth = (B12002049 + B12002064 + B12002079 + B12002094)/pop_base
				   
	gen age_18to19_female_mar_nvr = B12002098/pop_base
	gen age_20to24_female_mar_nvr = B12002099/pop_base
	gen age_25to29_female_mar_nvr = B12002100/pop_base
	gen age_30to34_female_mar_nvr = B12002101/pop_base
	gen age_35to39_female_mar_nvr = B12002102/pop_base
	gen age_40to44_female_mar_nvr = B12002103/pop_base
	gen age_45to49_female_mar_nvr = B12002104/pop_base
	gen age_50to54_female_mar_nvr = B12002105/pop_base
	gen age_55to59_female_mar_nvr = B12002106/pop_base
	gen age_60to64_female_mar_nvr = B12002107/pop_base
	gen age_65to74_female_mar_nvr = B12002108/pop_base
	gen age_75to84_female_mar_nvr = B12002109/pop_base
	gen age_85plus_female_mar_nvr = B12002110/pop_base
	
	gen age_18to19_female_mar_yes = B12002114/pop_base
	gen age_20to24_female_mar_yes = B12002115/pop_base
	gen age_25to29_female_mar_yes = B12002116/pop_base
	gen age_30to34_female_mar_yes = B12002117/pop_base
	gen age_35to39_female_mar_yes = B12002118/pop_base
	gen age_40to44_female_mar_yes = B12002119/pop_base
	gen age_45to49_female_mar_yes = B12002120/pop_base
	gen age_50to54_female_mar_yes = B12002121/pop_base
	gen age_55to59_female_mar_yes = B12002122/pop_base
	gen age_60to64_female_mar_yes = B12002123/pop_base
	gen age_65to74_female_mar_yes = B12002124/pop_base
	gen age_75to84_female_mar_yes = B12002125/pop_base
	gen age_85plus_female_mar_yes = B12002126/pop_base
	
	gen age_18to19_female_mar_oth = (B12002130 + B12002145 + B12002160 + B12002175)/pop_base
	gen age_20to24_female_mar_oth = (B12002131 + B12002146 + B12002161 + B12002176)/pop_base
	gen age_25to29_female_mar_oth = (B12002132 + B12002147 + B12002162 + B12002177)/pop_base 
	gen age_30to34_female_mar_oth = (B12002133 + B12002148 + B12002163 + B12002178)/pop_base 
	gen age_35to39_female_mar_oth = (B12002134 + B12002149 + B12002164 + B12002179)/pop_base
	gen age_40to44_female_mar_oth = (B12002135 + B12002150 + B12002165 + B12002180)/pop_base
	gen age_45to49_female_mar_oth = (B12002136 + B12002151 + B12002166 + B12002181)/pop_base
	gen age_50to54_female_mar_oth = (B12002137 + B12002152 + B12002167 + B12002182)/pop_base
	gen age_55to59_female_mar_oth = (B12002138 + B12002153 + B12002168 + B12002183)/pop_base
	gen age_60to64_female_mar_oth = (B12002139 + B12002154 + B12002169 + B12002184)/pop_base
	gen age_65to74_female_mar_oth = (B12002140 + B12002155 + B12002170 + B12002185)/pop_base
	gen age_75to84_female_mar_oth = (B12002141 + B12002156 + B12002171 + B12002186)/pop_base
	gen age_85plus_female_mar_oth = (B12002142 + B12002157 + B12002172 + B12002187)/pop_base
		
	gen test_age_sex_mar = 0
	foreach v1 in age_18to19 age_20to24 age_25to29 age_30to34 age_35to39 age_40to44 age_45to49 ///
	              age_50to54 age_55to59 age_60to64 age_65to74 age_75to84 age_85plus {
	
		foreach v2 in male female {
		
			foreach v3 in mar_nvr mar_yes mar_oth {
			
				replace test_age_sex_mar = test_age_sex_mar + `v1'_`v2'_`v3'
			}
		}
	}
	drop B12002*
	
	sum test* 
	drop test* pop_base fam_base pov_base hi_base
		
	* Add region
	gen region = . 
	replace region = 1 if state_fips ==  9 | state_fips == 23 | state_fips == 25 | state_fips == 33 | ///
	                      state_fips == 34 | state_fips == 36 | state_fips == 42 | state_fips == 44 | ///
			      state_fips == 50
	replace region = 2 if state_fips == 17 | state_fips == 18 | state_fips == 19 | state_fips == 20 | ///
	                      state_fips == 26 | state_fips == 27 | state_fips == 29 | state_fips == 31 | ///
	                      state_fips == 38 | state_fips == 39 | state_fips == 46 | state_fips == 55
	replace region = 3 if state_fips ==  1 | state_fips ==  5 | state_fips == 10 | state_fips == 12 | ///
		              state_fips == 13 | state_fips == 21 | state_fips == 22 | state_fips == 24 | ///
			      state_fips == 28 | state_fips == 37 | state_fips == 40 | state_fips == 45 | ///
			      state_fips == 47 | state_fips == 48 | state_fips == 51 | state_fips == 54 | ///
			      state_fips == 11
	replace region = 4 if state_fips ==  2 | state_fips ==  4 | state_fips ==  6 | state_fips ==  8 | ///
	                      state_fips == 15 | state_fips == 16 | state_fips == 30 | state_fips == 32 | ///
			      state_fips == 35 | state_fips == 41 | state_fips == 49 | state_fips == 53 | ///
			      state_fips == 56 
		
	save "${inter}/ACS_county_NHIS_2014.dta", replace
	
	
	
	

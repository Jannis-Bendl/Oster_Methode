/*******************************************************************************
PURPOSE: Generate data for the ED and the two-way fixed effects analysis
*******************************************************************************/

* preamble
global PatCtrl_A "female black hispanic medicaid *_dummy disable esrd"
global DocCtrl_A "shrrank_1-shrrank_5 *_attphy_avg" 
global Ctrl_A "${PatCtrl_A} surgery_cnt_2y phy_experience_2y ${DocCtrl_A}"
global FE_A "i.age_gp i.npi_surgeon i.month i.dow i.prvdrnum#i.year"

global PatCtrl_B "female black hispanic medicaid *_dummy disable esrd"
global DocCtrl_B "shrrank_other_1-shrrank_other_5 age*avg yrprac*avg female*avg medrank*avg *_other_*miss"
global Ctrl_B "${PatCtrl_B} surgery_cnt_2y phy_experience_2y ${DocCtrl_B}"
global FE_B "i.age_gp i.npi_surgeon i.month i.dow i.prvdrnum#i.year i.prf_npi1"

*-----------------------------*
* generate data for ED analysis
*-----------------------------*	
use "${OUTPUT}/team_analysis_final", clear
	
	*** drop irrelevant observations and redundant variables
	drop if age<65 | age>100	
	drop if full != 1
	keep if er_amt > 0 & !missing(er_amt)
	drop if medrank1_attphy_avg_miss | age_attphy_avg_miss | yrprac_attphy_avg_miss | female_attphy_avg_miss

	drop *other*

	foreach x in P2A P2D{
		reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) 	
		drop if !e(sample) & `x' == 1
	}
	
	*** standardize shared work experience
	g team_experience_2_original = team_experience_2
	foreach x in P2A P2D{
		su team_experience_2_original if `x' == 1
		replace team_experience_2 = team_experience_2_original/r(sd) if `x' == 1
	}	
		
	*** generate predicted mortality 
	foreach proc in P2A P2D{	
		logit die_30 i.age_gp female black hispanic medicaid disable esrd *_dummy if `proc' == 1
		predict die_30_`proc' if `proc' == 1
	}
	
save "${OUTPUT}/team_analysis_ed", replace	

*-----------------------------*
* generate data for two-way fixed effects analysis
*-----------------------------*	
use "${OUTPUT}/team_analysis_final", clear
	
	*** drop irrelevant observations and redundant variables
	drop if age<65 | age>100	
	drop if full != 1
	drop if medrank1_attphy_avg_miss | age_attphy_avg_miss | yrprac_attphy_avg_miss | female_attphy_avg_miss
	
	drop age_attphy_avg* yrprac_attphy_avg* female_attphy_avg* medrank1_attphy_avg* medrank2_attphy_avg* medrank3_attphy_avg* medrank4_attphy_avg*

	foreach x in P2A P2D{
		reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) 	
		drop if !e(sample) & `x' == 1
	}
	
	*** standardize shared work experience
	g team_experience_2_original = team_experience_2
	foreach x in P2A P2D{
		su team_experience_2_original if `x' == 1
		replace team_experience_2 = team_experience_2_original/r(sd) if `x' == 1
	}	
		
	*** generate predicted mortality 
	foreach proc in P2A P2D{	
		logit die_30 i.age_gp female black hispanic medicaid disable esrd *_dummy if `proc' == 1
		predict die_30_`proc' if `proc' == 1
	}
		
save "${OUTPUT}/team_analysis_twoway", replace	


	
	
	
	
	

/*****************************************************************************************
PURPOSE: Generate Appendix Tables A6-A10
*****************************************************************************************/

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
* Table A6: exclude matching as a mechanism
*-----------------------------*
use "${OUTPUT}/team_analysis_ed", clear	
	
	merge 1:1 medparid using "${OUTPUT}/team_analysis_final", keepusing(*other*) keep(1 3) nogen
	drop age_attphy_avg* yrprac_attphy_avg* female_attphy_avg* medrank1_attphy_avg* medrank2_attphy_avg* medrank3_attphy_avg* medrank4_attphy_avg*
	
	eststo clear
	
	*** columns 1-2: separate proceduralist and physician FE
	foreach x in P2D P2A{
		reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(i.npi_surgeon#i.prf_npi1 i.age_gp fe_`x' = i.month i.dow i.prvdrnum#i.year)
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1 & !missing(fe_`x'), absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	
	* Note: reghdfe is not accurate in estimating the adjusted R-squared, hence use areg to get adjusted R-squared
	egen surphy = group(npi_surgeon prf_npi1)	
	egen prvdyear = group(prvdrnum year)
	foreach x in P2D P2A{	
		quiet areg die_30 team_experience_2 ${Ctrl_B} i.age_gp i.month i.dow i.prvdyear i.npi_surgeon if `x' == 1 & !missing(fe_`x'), absorb(prf_npi1) vce(cluster npi_surgeon)
			di e(r2_a)
	}
	
	*** columns 3-4: team fixed effects
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1 & !missing(fe_`x'), absorb(i.npi_surgeon#i.prf_npi1 i.age_gp i.month i.dow i.prvdrnum#i.year) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}	
	
	* Note: reghdfe is not accurate in estimating the adjusted R-squared, hence use areg to get adjusted R-squared
	foreach x in P2D P2A{
		quiet areg die_30 team_experience_2 ${Ctrl_B} i.age_gp i.month i.dow i.prvdyear if `x' == 1 & !missing(fe_`x'), absorb(surphy) vce(cluster npi_surgeon)	
			di e(r2_a)
	}
	
use "${OUTPUT}/team_analysis_ed", clear	

	*** columns 5-6: different practices
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1 & shr_same_tin12<.95 , absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	
	*** columns 7-8: shared work experience based on ED patients
	foreach x in P2D P2A{
		su team_experience_2_original if `x' == 1
		replace team_experience_2 = team_experience_ed_2/`r(sd)' if `x' == 1
	}
	
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 surgery_cnt_ed_2y phy_experience_ed_2y ${PatCtrl_A} ${DocCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm		
	}
	
	esttab using "${RESULTS}/regs_matching_ed.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG" "PCI" "CABG" "PCI" "CABG" "PCI" "CABG") mgroups("\shortstack{Two-way\\fixed effects}" "Team fixed effects" "Different practices" "\shortstack{Shared experience\\by ED patients}", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_experience_*) type booktabs noconstant label nostar brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.2\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace		

*-----------------------------*
* Table A7: controlling for hospital-specific experience
*-----------------------------*
*** Panel A 
use "${OUTPUT}/team_analysis_ed", clear
	foreach proc in P2A P2D{
		foreach x in hosppat_surgeon hosppat_phy{
			mkspline `x'_lr_`proc' 4 = `x' if `proc' == 1, pctile
			mkspline `x'_cb_`proc' = `x' if `proc' == 1, cubic nknots(4)
		}
	}
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} hosppat_surgeon hosppat_phy if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} hosppat_surgeon_lr_`x'* hosppat_phy_lr_`x'* if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} hosppat_surgeon_cb_`x'* hosppat_phy_cb_`x'* if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} hospyr_surgeon hospyr_phy if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_hospexp_A.tex", mgroups("PCI" "CABG", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  indicate("Full control = female", labels(Y)) collabels(none) mtitles("Linear" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Practice\\years}" "Linear" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Practice\\years}")  keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.17\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	foreach proc in P2A P2D{
		foreach x in hosppat_surgeon hosppat_phy{
			mkspline `x'_lr_`proc' 4 = `x' if `proc' == 1, pctile
			mkspline `x'_cb_`proc' = `x' if `proc' == 1, cubic nknots(4)
		}
	}
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} hosppat_surgeon hosppat_phy if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} hosppat_surgeon_lr_`x'* hosppat_phy_lr_`x'* if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} hosppat_surgeon_cb_`x'* hosppat_phy_cb_`x'* if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} hospyr_surgeon hospyr_phy if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_hospexp_B.tex", mgroups("PCI" "CABG", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  indicate("Full control = female", labels(Y)) collabels(none) mtitles("Linear" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Practice\\years}" "Linear" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Practice\\years}")  keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.7\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace

	
*-----------------------------*
* Table A8: doctors continuously practicing at the hospital
*-----------------------------*
*** Panel A 
use "${OUTPUT}/team_analysis_ed", clear
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if hospyr_surgeon == 2 & hospyr_phy >= 1.8 & !missing(hospyr_phy) & `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_hospexp_2_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.8\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*** Panel B 
use "${OUTPUT}/team_analysis_twoway", clear	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if hospyr_surgeon == 2 & hospyr_phy >= 1.8 & !missing(hospyr_phy) & `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_hospexp_2_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.8\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*-----------------------------*
* Table A9: controlling for 4-digit ICD fixed effects
*-----------------------------*
*** ICD9 to ICD10 crosswalk
use "${INPUT_PhyCom}/icd9toicd10cmgem.dta", clear

	g icd9_4 = substr(icd9cm, 1, 4)
	g icd10_4 = substr(icd10cm, 1, 4)
	
	keep icd9_4 icd10_4
	duplicates drop
	
	sort icd9_4 icd10_4
	by icd9_4: gen icd10_min = icd10_4[1]
	keep icd9_4 icd10_min 
	duplicates drop
	
save "${OUTPUT}/icd9toicd10_4.dta", replace

*** Panel A 
use "${OUTPUT}/team_analysis_ed", clear	

	g icd9_4 = substr(dgnscd1, 1, 4)
	* crosswalk ICD9 to ICD10
	merge m:1 icd9_4 using "${OUTPUT}/icd9toicd10_4.dta", keep(1 3) nogen	
	replace icd10_min = substr(dgnscd1, 1, 4) if dgns_vrsn_cd_1 == "0" & missing(icd10_min)		
	egen icd10_gp = group(icd10_min)
	bysort icd10_gp: egen n_P2A = total(P2A == 1)
	bysort icd10_gp: egen n_P2D = total(P2D == 1)
	replace icd10_gp = 99999 if n_P2A <= 20 & P2A == 1
	replace icd10_gp = 99999 if n_P2D <= 20 & P2D == 1 
	/* group together a small number of ICD10 groups with few observations */

	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A} i.icd10_gp) vce(cluster npi_surgeon)
			qui estadd ysumm
	}		
	esttab using "${RESULTS}/regs_icd4fe_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_*) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.8\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace	

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear	

	g icd9_4 = substr(dgnscd1, 1, 4)
	* crosswalk ICD9 to ICD10
	merge m:1 icd9_4 using "${OUTPUT}/icd9toicd10_4.dta", keep(1 3) nogen	
	replace icd10_min = substr(dgnscd1, 1, 4) if dgns_vrsn_cd_1 == "0" & missing(icd10_min)		
	egen icd10_gp = group(icd10_min)
	bysort icd10_gp: egen n_P2A = total(P2A == 1)
	bysort icd10_gp: egen n_P2D = total(P2D == 1)
	replace icd10_gp = 99999 if n_P2A <= 20 & P2A == 1
	replace icd10_gp = 99999 if n_P2D <= 20 & P2D == 1
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B} i.icd10_gp) vce(cluster npi_surgeon)
			qui estadd ysumm
	}	
	esttab using "${RESULTS}/regs_icd4fe_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_*) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.8\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace	
		
*-----------------------------*
* Table A10: alternative measures of shared work experience I
*-----------------------------*
*** Panel A 		
use "${OUTPUT}/team_analysis_ed", clear

	eststo clear
	foreach x in P2D P2A{						
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_1/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative surgery_cnt_1y phy_experience_1y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
		
		cap drop team_alternative
		g team_alternative = team_experience_2
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative surgery_cnt_2y phy_experience_2y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	

		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_3/`r(sd)'
		label var team_alternative "Shared work experience"
		* use observations in year 2011 or after to keep an at-least 3-year look-back window for observing shared work experience in the past three years
		eststo: reghdfe die_30 team_alternative surgery_cnt_3y phy_experience_3y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1 & year>= 2011, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_med/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_med surgery_cnt_2y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_mode/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_mode surgery_cnt_2y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_2_1st/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_1st surgery_cnt_2y ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}

	esttab using "${RESULTS}/regs_alterteamexp_A.tex", nostar indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Past\\year}" "\shortstack{Past\\two\\years}" "\shortstack{Past\\three\\years}" "\shortstack{Median}" "Mode" "\shortstack{First\\physician}" "\shortstack{Past\\year}" "\shortstack{Past\\two\\years}" "\shortstack{Past\\three\\years}" "\shortstack{Median}" "Mode" "\shortstack{First\\physician}") mgroups("PCI" "CABG" , pattern(1 0 0 0 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_alternative) type booktabs noconstant label brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace	

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear	

	eststo clear
	foreach x in P2D P2A{			
	
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_1/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative surgery_cnt_1y phy_experience_1y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
			
		cap drop team_alternative
		g team_alternative = team_experience_2
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative surgery_cnt_2y phy_experience_2y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm

		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_3/`r(sd)'
		label var team_alternative "Shared work experience"
		* use observations in year 2011 or after to keep an at-least 3-year look-back window for observing shared work experience in the past three years
		eststo: reghdfe die_30 team_alternative surgery_cnt_3y phy_experience_3y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1 & year>= 2011, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_med/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_med surgery_cnt_2y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_mode/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_mode surgery_cnt_2y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		cap drop team_alternative
		su team_experience_2_original if `x' == 1
		g team_alternative = team_experience_2_1st/`r(sd)'
		label var team_alternative "Shared work experience"
		eststo: reghdfe die_30 team_alternative phy_experience_1st surgery_cnt_2y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	

	}	
	esttab using "${RESULTS}/regs_alterteamexp_B.tex", nostar indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Past\\year}" "\shortstack{Past\\two\\years}" "\shortstack{Past\\three\\years}" "\shortstack{Median}" "Mode" "\shortstack{First\\physician}" "\shortstack{Past\\year}" "\shortstack{Past\\two\\years}" "\shortstack{Past\\three\\years}" "\shortstack{Median}" "Mode" "\shortstack{First\\physician}") mgroups("PCI" "CABG" , pattern(1 0 0 0 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_alternative) type booktabs noconstant label brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace	

	
	
	

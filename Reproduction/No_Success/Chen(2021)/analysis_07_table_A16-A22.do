/*****************************************************************************************
PURPOSE: Generate Appendix Tables A16-A22
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
* Table A16: exclude patients treated by proceduralists/physicians with few patients
*-----------------------------*
*** Panel A 	
use "${OUTPUT}/team_analysis_ed", clear
	
	bysort npi_surgeon: egen surgeon_P2A = total(P2A == 1)
	bysort npi_surgeon: egen surgeon_P2D = total(P2D == 1)
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1 & surgeon_`x'>4,  absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_dropfew_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	
	bysort npi_surgeon: egen surgeon_P2A = total(P2A == 1)
	bysort npi_surgeon: egen surgeon_P2D = total(P2D == 1)
	
	bysort prf_npi1: egen phy_P2A = total(P2A == 1 )
	bysort prf_npi1: egen phy_P2D = total(P2D == 1)
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1 & surgeon_`x'>4 & phy_`x'>=3,  absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_dropfew_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
		
*-----------------------------*
* Table A17: shared work experience and medical resource use: ED analysis
*-----------------------------*			
use "${OUTPUT}/team_analysis_ed", clear
	
	eststo clear
	foreach x in P2D P2A{
		foreach var in loscnt testexam_cnt outlier{
			eststo: reghdfe `var' team_experience_2 ${Ctrl_A} if `x' == 1 & !missing(loscnt), absorb(${FE_A}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}	
	esttab using "${RESULTS}/regs_medresource_ED.tex", keep(team_experience_2) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Length\\of stay}" "\shortstack{Number\\tests\\exams}" "\shortstack{Outlier\\payments}" "\shortstack{Length\\of stay}" "\shortstack{Number\\tests\\exams}" "\shortstack{Outlier\\payments}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace		
		
*-----------------------------*
* Table A18: post-discharge medical resource use
*-----------------------------*		
*** Panel A 	
use "${OUTPUT}/team_analysis_ed", clear
	
	* keep observations survived 30 days after the discharge			
	foreach x in readm_30 postchrgvisit{
		replace `x' = . if die_30 != 0
	}

	eststo clear
	foreach x in P2D P2A{
		foreach var in snf readm_30 postchrgvisit{
			eststo: reghdfe `var' team_experience_2 ${Ctrl_A} if `x' == 1 & !missing(loscnt), absorb(${FE_A}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}	
	esttab using "${RESULTS}/regs_postmedresource_A.tex", keep(team_experience_2) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{SNF\\Rehab.}" "\shortstack{30-Day\\Readmission}" "\shortstack{30-day\\outpatient\\visits}" "\shortstack{SNF\\Rehab.}" "\shortstack{30-Day\\Readmission}" "\shortstack{30-day\\outpatient\\visits}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace		
		
*** Panel B 	
use "${OUTPUT}/team_analysis_twoway", clear

	* keep observations survived 30 days after the discharge			
	foreach x in readm_30 postchrgvisit{
		replace `x' = . if die_30 != 0
	}
	
	eststo clear
	foreach x in P2D P2A{
		foreach var in snf readm_30 postchrgvisit{
			eststo: reghdfe `var' team_experience_2 ${Ctrl_B} if `x' == 1 & !missing(loscnt), absorb(${FE_B}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}	
	esttab using "${RESULTS}/regs_postmedresource_B.tex", keep(team_experience_2) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{SNF\\Rehab.}" "\shortstack{30-Day\\Readmission}" "\shortstack{30-day\\outpatient\\visits}" "\shortstack{SNF\\Rehab.}" "\shortstack{30-Day\\Readmission}" "\shortstack{30-day\\outpatient\\visits}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace		
	
*-----------------------------*
* Table A19: substitution between individual and shared work experience
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear
	foreach var in phy_experience_2y surgery_cnt_2y{
		foreach proc in P2A P2D{	
			su `var' if `proc' == 1
			replace `var' = (`var'-r(mean))/r(sd) if `proc' == 1
		}
	}
	
	mkspline teamexp_1 5 teamexp_2 10 teamexp_3 15 teamexp_4 20 teamexp_5 = team_experience_2_original
	mkspline teamexpcubic = team_experience_2_original, cubic knots(5 10 15 20)

	eststo clear	
	foreach x in P2D P2A{
	
		cap drop dd
		g dd = team_experience_2*phy_experience_2y if `x' == 1
		
		eststo: reghdfe die_30 dd team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		eststo: reghdfe die_30 dd teamexp_* ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		eststo: reghdfe die_30 dd teamexpcubic* ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm			
	}
	esttab using "${RESULTS}/regs_substitution_phy", indicate("Full control = female", labels(Y)) collabels(none) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("Baseline" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "Baseline" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}") keep(dd) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.95\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace 			

	eststo clear
	foreach x in P2D P2A{
		
		cap drop dd
		g dd = team_experience_2*surgery_cnt_2y if `x' == 1
		
		eststo: reghdfe die_30 dd team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		eststo: reghdfe die_30 dd teamexp_* ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
			
		eststo: reghdfe die_30 dd teamexpcubic* ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
	}
	esttab using "${RESULTS}/regs_substitution_proc", indicate("Full control = female", labels(Y)) collabels(none) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("Baseline" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "Baseline" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}") keep(dd) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.95\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace 			
	
		
*-----------------------------*
* Table A20: heterogeneity in effects of shared work experience
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear
	
	*** by age
	su age if P2A == 1, detail
	g age_b = (age <= r(p75)) if P2A == 1 & !missing(age)
	
	su age if P2D == 1, detail
	replace age_b = (age<= r(p75)) if P2D == 1	& !missing(age)
	
	*** by predicted mortality
	su die_30_P2A if P2A == 1, detail
	g die = (die_30_P2A <= r(p75)) if P2A == 1 & !missing(die_30_P2A)
	
	su die_30_P2D if P2D == 1, detail
	replace die = (die_30_P2D <= r(p75)) if P2D == 1 & !missing(die_30_P2D)
	
	*** by same practice groups
	g tin = (shr_same_tin12>=.95) if !missing(shr_same_tin12)
	
	*** by commorbidities
	g nouncomdise = 1-(esrd == 1 | alzhdmt_dummy == 1 | cancer_dummy == 1 | strktia_dummy == 1)

	*** regressions
	foreach var in tin nouncomdise die age_b{	
		forvalues i = 0/1{
			g dd`var'`i' = team_experience_2*(`var'== `i')
		}
	}	

	foreach x in P2D P2A{
		mat plot_`x' = J(16,2, .)
		local i = 1
		local j = 2
		local k = 3
		local l = 4
		foreach var in age_b die nouncomdise tin{	
			reghdfe die_30 dd`var'0 dd`var'1 `var' ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			mat coef = e(b)
			mat plot_`x'[`i', 1] = coef[1...., 1]
			mat plot_`x'[`k', 1] = coef[1...., 2]
			mat var = vecdiag(e(V))
			matewmf var se, function(sqrt)
			mat plot_`x'[`j', 1] = se[1...., 1]
			mat plot_`x'[`l', 1] = se[1...., 2]
			
			su die_30 if `var' == 0 & `x' == 1
			mat plot_`x'[`i', 2] = 100*plot_`x'[`i', 1]/r(mean)
			su die_30 if `var' == 1 & `x' == 1
			mat plot_`x'[`k', 2] = 100*plot_`x'[`k', 1]/r(mean)
			
			local i = `i'+4
			local j = `j'+4
			local k = `k'+4
			local l = `l'+4
		}			
	}
	mat plot = plot_P2D, plot_P2A
	mat colnames plot ="Coeffcient" "% Effect" "Coeffcient" "% Effect"
	mat rownames plot = "Yes" "" "No" "" "Yes" "" "No" "" "Yes" "" "No" "" "Yes" "" "No" ""
	mat list plot
	putexcel A1=matrix(plot, names) using "${RESULTS}/team_hetero_plot.xls", replace
		
*-----------------------------*
* Table A21: sample restricted to patients with high probability of PCI or CABG
*-----------------------------*
*** Panel A 	
use "${OUTPUT}/team_analysis_ed", clear
	
	g pci = (P2D == 1) if P2A == 1 | P2D == 1
	logit pci ${PatCtrl_A} i.age_gp
	predict pci_hat
	xtile pci_pctile = pci_hat if P2D == 1, nq(3)
	
	eststo clear
	eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if P2D == 1 & pci_pctile>=3 & !missing(pci_pctile), absorb(${FE_A}) vce(cluster npi_surgeon)
		qui estadd ysumm
		
	g cabg = (P2A == 1) if P2A == 1 | P2D == 1
	logit cabg ${PatCtrl_A} i.age_gp
	predict cabg_hat
	xtile cabg_pctile = cabg_hat if P2A == 1, nq(3)
	
	eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if P2A == 1 & cabg_pctile>=3 & !missing(cabg_pctile), absorb(${FE_A}) vce(cluster npi_surgeon)
		qui estadd ysumm
		
	esttab using "${RESULTS}/regs_procselection_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear

	g pci = (P2D == 1) if P2A == 1 | P2D == 1
	logit pci ${PatCtrl_B} i.age_gp 
	predict pci_hat
	xtile pci_pctile = pci_hat if P2D == 1, nq(3)
	
	eststo clear
	eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if P2D == 1 & pci_pctile>=3 & !missing(pci_pctile), absorb(${FE_B}) vce(cluster npi_surgeon)
		qui estadd ysumm		
	
	g cabg = (P2A == 1) if P2A == 1 | P2D == 1
	logit cabg ${PatCtrl_B} i.age_gp 
	predict cabg_hat
	xtile cabg_pctile = cabg_hat if P2A == 1, nq(3)
	
	eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if P2A == 1 & cabg_pctile>=3 & !missing(cabg_pctile), absorb(${FE_B}) vce(cluster npi_surgeon)
		qui estadd ysumm
		
	esttab using "${RESULTS}/regs_procselection_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*-----------------------------*
* Table A22: non-linear returns to shared work experience
*-----------------------------*	
*** Panel A 			
use "${OUTPUT}/team_analysis_ed", clear	
	
	g team_experience_2_sq = team_experience_2^2
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 team_experience_2_sq ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_nonlinear_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG")  keep(team_experience_2 team_experience_2_sq) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

	
*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear	
	
	g team_experience_2_sq = team_experience_2^2
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 team_experience_2_sq ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_nonlinear_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG")  keep(team_experience_2 team_experience_2_sq) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

	
	

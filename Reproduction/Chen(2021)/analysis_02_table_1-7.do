/*****************************************************************************************
PURPOSE: Generate Tables 1-7
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
* Table 1: patient characteristics: ED analysis
*-----------------------------*	
use "${OUTPUT}/team_analysis_ed", clear	

	foreach proc in P2A P2D{
		foreach x in age female black hispanic medicaid disable cc die_30_`proc'{
			reghdfe `x' surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `proc' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year) residuals(`x'_`proc')			
			su `x' if `proc' == 1
			replace `x'_`proc' = `x'_`proc'+r(mean)
		}
	}	
	
	foreach proc in P2A P2D{
		su team_experience_2 if `proc' == 1
		g xtile_`proc' = (team_experience_2 > r(mean)) if !missing(team_experience_2)
	}
	
	replace die_30_P2A_P2A = die_30_P2A_P2A*100
	replace die_30_P2D_P2D = die_30_P2D_P2D*100
	
	foreach proc in P2D P2A{
		mat summ_`proc' = J(17, 3, .)
		mat colname summ_`proc' = "Below mean" "Above mean" "p-value"
		mat rowname summ_`proc' = "Age" "" "Female" "" "Black" "" "Hispanic" "" "Medicaid" "" "Disabled" "" "Number of comorbidities" "" "Predicted 30-day mortality (%)" "(by patient characteristics)" "Observations"
		local i = 1
		local j = 2
		foreach x in age female black hispanic medicaid disable cc die_30_`proc' {					
			quiet ttest `x'_`proc' if `proc' == 1, by(xtile_`proc') 
			mat summ_`proc'[`i', 1] = r(mu_1)
			mat summ_`proc'[`j', 1] = r(sd_1)
			mat summ_`proc'[`i', 2] = r(mu_2)
			mat summ_`proc'[`j', 2] = r(sd_2)
			mat summ_`proc'[`i', 3] = r(p)
			mat summ_`proc'[17, 1] = r(N_1)
			mat summ_`proc'[17, 2] = r(N_2)
			local i = `i'+2
			local j = `j'+2
		}
		mat list summ_`proc'
		putexcel A1=matrix(summ_`proc', names) using "${RESULTS}/team_`proc'_characteristics.xls", replace
	}
	
*-----------------------------*
* Table 2: shared work experience and 30-day mortality: ED analysis
*-----------------------------*	
use "${OUTPUT}/team_analysis_ed", clear	
	
	foreach x in P2D P2A{
		eststo clear
		eststo: reghdfe die_30 team_experience_2 if `x' == 1, absorb(i.npi_surgeon) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 if `x' == 1, absorb(i.npi_surgeon i.prvdrnum#i.year i.month i.dow) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y if `x' == 1, absorb(i.npi_surgeon i.prvdrnum#i.year i.month i.dow) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.prvdrnum#i.year i.month i.dow) vce(cluster npi_surgeon)
			qui estadd ysumm
		eststo: reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${PatCtrl_A} ${DocCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm				

		esttab using "${RESULTS}/regs_`x'.tex", keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.3\hsize) mtitles(none) collabels(none) mlabels(none) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace 
	}

*-----------------------------*
* Table 3: shared work experience and 30-day mortality: two-way fixed effects model
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear	

	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_twoway.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace
	
*-----------------------------*
* Table 4: excluding matching as a mechanism
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear	
	
	eststo clear	
	*** columns 1-2: separate proceduralist and physician FE
	foreach x in P2D P2A{
		reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(i.npi_surgeon#i.prf_npi1 i.age_gp fe_`x' = i.month i.dow i.prvdrnum#i.year)
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1 & !missing(fe_`x'), absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	
	* NOTE: reghdfe is not accurate in estimating the adjusted R-squared, hence use areg to get adjusted R-squared
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
	
	* NOTE: reghdfe is not accurate in estimating the adjusted R-squared, hence use areg to get adjusted R-squared
	foreach x in P2D P2A{
		quiet areg die_30 team_experience_2 ${Ctrl_B} i.age_gp i.month i.dow i.prvdyear if `x' == 1 & !missing(fe_`x'), absorb(surphy) vce(cluster npi_surgeon)	
			di e(r2_a)
	}
		
	*** columns 5-6: different practices
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1 & shr_same_tin12<.95 , absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	
	*** columns 7-8: shared work experience based on ED patients
	foreach x in P2D P2A{
		su team_experience_2_original if `x' == 1
		replace team_experience_2 = team_experience_ed_2/r(sd) if `x' == 1
	}
	
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 surgery_cnt_ed_2y phy_experience_ed_2y ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm		
	}
	
	esttab using "${RESULTS}/regs_matching_twoway.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG" "PCI" "CABG" "PCI" "CABG" "PCI" "CABG") mgroups("\shortstack{Two-way\\fixed effects}" "Team fixed effects" "Different practices" "\shortstack{Shared experience\\by ED patients}", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_experience_*) type booktabs noconstant label nostar brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.2\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace	

*-----------------------------*
* Table 5: shared work experience and medical resource use
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear	
		
	eststo clear
	foreach x in P2D P2A{
		foreach var in loscnt testexam_cnt outlier{
			eststo: reghdfe `var' team_experience_2 ${Ctrl_B} if `x' == 1 & !missing(loscnt), absorb(${FE_B}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}	
	esttab using "${RESULTS}/regs_medresource_twoway.tex", keep(team_experience_2) mgroups("PCI" "CABG", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Length\\of stay}" "\shortstack{Number\\tests\\exams}" "\shortstack{Outlier\\payments}" "\shortstack{Length\\of stay}" "\shortstack{Number\\tests\\exams}" "\shortstack{Outlier\\payments}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace		

*-----------------------------*
* Table 6: substitution between individual and shared work experience
*-----------------------------*		
use "${OUTPUT}/team_analysis_twoway", clear	
	
	*** demean and standardize individual work experience
	foreach var in phy_experience_2y surgery_cnt_2y{
		foreach proc in P2A P2D{	
			su `var' if `proc' == 1
			replace `var' = (`var'-r(mean))/r(sd) if `proc' == 1
		}
	}
	
	*** regressions
	eststo clear			
	foreach x in P2D P2A{
		cap drop dd		
		g dd = team_experience_2*surgery_cnt_2y if `x' == 1
		lab var dd "Shared work experience*proceduralist experience"

		eststo: reghdfe die_30 dd team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
	}
	
	esttab using "${RESULTS}/regs_substitution_proc", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(dd team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.95\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace 			

	eststo clear			
	foreach x in P2D P2A{
		cap drop dd		
		g dd = team_experience_2*phy_experience_2y if `x' == 1
		lab var dd "Shared work experience*physician experience"
	
		eststo: reghdfe die_30 dd team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
	}
	esttab using "${RESULTS}/regs_substitution_phy", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") keep(dd team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.95\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace 			

	
*-----------------------------*
* Table 7: heterogeneity in effects of shared work experience
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear	

	*** by age
	su age if P2A == 1, detail
	g age75 = (age > r(p75)) if P2A == 1 & !missing(age)
	
	su age if P2D == 1, detail
	replace age75 = (age > r(p75)) if P2D == 1	& !missing(age)
	
	*** by predicted mortality
	su die_30_P2A if P2A == 1, detail
	g die = (die_30_P2A > r(p75)) if P2A == 1 & !missing(die_30_P2A)
	
	su die_30_P2D if P2D == 1, detail
	replace die = (die_30_P2D > r(p75)) if P2D == 1	& !missing(die_30_P2D)
	
	*** by different practice groups
	g tin = 1-(shr_same_tin12>=.95)
	
	*** by commorbidities
	g uncomdise = (esrd == 1 | alzhdmt_dummy == 1 | cancer_dummy == 1 | strktia_dummy == 1)
	
	*** regressions
	foreach var in age75 die uncomdise tin{
		eststo clear
		foreach x in P2D P2A{	
			cap drop dd
			g dd = `var'*team_experience_2
			label var dd "Interaction"
			eststo: reghdfe die_30 dd team_experience_2 `var' ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
				qui estadd ysumm				
		}	
	esttab using "${RESULTS}/regs_`var'_hetero.tex", keep(dd team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations"))  replace		
	}



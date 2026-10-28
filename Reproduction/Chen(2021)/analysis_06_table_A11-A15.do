/*****************************************************************************************
PURPOSE: Generate Appendix Tables A11-A15
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
* Table A11: alternative measures of shared work experience II
*-----------------------------*
*** Panel A 		
use "${OUTPUT}/team_analysis_ed", clear
	
	replace team_experience_decay_10 = . if year < 2011
	/* when decay parameter = 0.1, experience in year t-3 matters, hence restrict sample to year 2011 or after to allow for an at-least 3-year look-back window for decay parameter = 0.1 */
	
	g team_experience_decay = .
	lab var team_experience_decay "Shared work experience"
	
	eststo clear
	foreach x in P2D P2A{	
		foreach i in 10 15 20 25{
			su team_experience_2_original if `x' == 1
			replace team_experience_decay = team_experience_decay_`i'/`r(sd)'
			eststo: reghdfe die_30 team_experience_decay phy_experience_decay_`i' surgeon_decay_`i' ${PatCtrl_A} ${DocCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}	
	}		
	esttab using "${RESULTS}/regs_alterteamexp_decay_A.tex", nostar indicate("Full control = female", labels(Y)) collabels(none) mtitles("$\psi$=1" "$\psi$=1.5" "$\psi$=2" "$\psi$=2.5" "$\psi$=1" "$\psi$=1.5" "$\psi$=2" "$\psi$=2.5" ) mgroups("PCI" "CABG" , pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team*) type booktabs noconstant label brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations") )  replace	

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	
	replace team_experience_decay_10 = . if year < 2011
	
	g team_experience_decay = .
	lab var team_experience_decay "Shared work experience"
	
	eststo clear
	foreach x in P2D P2A{	
		foreach i in 10 15 20 25{
			su team_experience_2_original if `x' == 1
			replace team_experience_decay = team_experience_decay_`i'/`r(sd)'
			eststo: reghdfe die_30 team_experience_decay phy_experience_decay_`i' surgeon_decay_`i' ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}	
	}		
	esttab using "${RESULTS}/regs_alterteamexp_decay_B.tex", nostar indicate("Full control = female", labels(Y)) collabels(none) mtitles("$\psi$=1" "$\psi$=1.5" "$\psi$=2" "$\psi$=2.5" "$\psi$=1" "$\psi$=1.5" "$\psi$=2" "$\psi$=2.5" ) mgroups("PCI" "CABG" , pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team*) type booktabs noconstant label brackets cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations") )  replace	

	
*-----------------------------*
* Table A12: controlling for individual work experience in alternative forms
*-----------------------------*
*** Panel A 		
use "${OUTPUT}/team_analysis_ed", clear

	* high-order polynomials
	g phy_experience_2y_sq = phy_experience_2y^2
	g surgery_cnt_2y_sq = surgery_cnt_2y^2

	g phy_experience_2y_cubic = phy_experience_2y^3
	g surgery_cnt_2y_cubic = surgery_cnt_2y^3
	
	* splines
	foreach proc in P2A P2D{
		foreach x in phy_experience_2y surgery_cnt_2y{
			mkspline `x'_linear_`proc' 4 = `x' if `proc' == 1, pctile
			mkspline `x'_cubic_`proc' = `x' if `proc' == 1, cubic nknots(4)
		}
	}
	
	* interaction of splines
	forvalues i = 1/4{
		forvalues j = 1/4{
			foreach proc in P2A P2D{
				g surphyexp_`i'`j'_`proc'= phy_experience_2y_linear_`proc'`i'*surgery_cnt_2y_linear_`proc'`j'
			}
		}
	}
	
	g phy_experience_2y_round = round(phy_experience_2y) 
	
	eststo clear
	foreach x in P2D P2A{		
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} phy_experience_2y_sq surgery_cnt_2y_sq if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} phy_experience_2y_sq surgery_cnt_2y_sq phy_experience_2y_cubic surgery_cnt_2y_cubic if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_A} ${DocCtrl_A} phy_experience_2y_linear_`x'* surgery_cnt_2y_linear_`x'* if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_A} ${DocCtrl_A} phy_experience_2y_cubic_`x'* surgery_cnt_2y_cubic_`x'* if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm		
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_A} ${DocCtrl_A} if `x' == 1, absorb(${FE_A} i.phy_experience_2y_round i.surgery_cnt_2y) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 phy_experience_2y_linear_`x'* surgery_cnt_2y_linear_`x'* surphyexp_*`x' ${DocCtrl_A} ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
	}	
	esttab using "${RESULTS}/regs_alterindexp_A.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("Quadratic" "Cubic" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Fixed\\effects}" "Interaction" "Quadratic" "Cubic" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Fixed\\effects}" "Interaction") mgroups("PCI" "CABG" , pattern(1 0 0 0 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear

	* high-order polynomials
	g phy_experience_2y_sq = phy_experience_2y^2
	g surgery_cnt_2y_sq = surgery_cnt_2y^2

	g phy_experience_2y_cubic = phy_experience_2y^3
	g surgery_cnt_2y_cubic = surgery_cnt_2y^3
	
	* splines
	foreach proc in P2A P2D{
		foreach x in phy_experience_2y surgery_cnt_2y{
			mkspline `x'_linear_`proc' 4 = `x' if `proc' == 1, pctile
			mkspline `x'_cubic_`proc' = `x' if `proc' == 1, cubic nknots(4)
		}
	}
	
	* interaction of splines
	forvalues i = 1/4{
		forvalues j = 1/4{
			foreach proc in P2A P2D{
				g surphyexp_`i'`j'_`proc'= phy_experience_2y_linear_`proc'`i'*surgery_cnt_2y_linear_`proc'`j'
			}
		}
	}
	
	g phy_experience_2y_round = round(phy_experience_2y) 
	
	eststo clear
	foreach x in P2D P2A{		
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} phy_experience_2y_sq surgery_cnt_2y_sq if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} phy_experience_2y_sq surgery_cnt_2y_sq phy_experience_2y_cubic surgery_cnt_2y_cubic if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_B} ${DocCtrl_B} phy_experience_2y_linear_`x'* surgery_cnt_2y_linear_`x'* if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_B} ${DocCtrl_B} phy_experience_2y_cubic_`x'* surgery_cnt_2y_cubic_`x'* if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm		
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B} i.phy_experience_2y_round i.surgery_cnt_2y) vce(cluster npi_surgeon)
			qui estadd ysumm	
		eststo: reghdfe die_30 team_experience_2 phy_experience_2y_linear_`x'* surgery_cnt_2y_linear_`x'* surphyexp_*`x' ${DocCtrl_B} ${PatCtrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
	}	
	esttab using "${RESULTS}/regs_alterindexp_B.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("Quadratic" "Cubic" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Fixed\\effects}" "Interaction" "Quadratic" "Cubic" "\shortstack{Linear\\spline}" "\shortstack{Cubic\\spline}" "\shortstack{Fixed\\effects}" "Interaction") mgroups("PCI" "CABG" , pattern(1 0 0 0 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*-----------------------------*
* Table A13: 30-day mortality from admission day
*-----------------------------*	
*** Panel A 		
use "${OUTPUT}/team_analysis_ed", clear
	
	g die_30_adm = 100*(death_dt1<=(admsndt+30) | death_dt2<=(admsndt+30)) if admsndt != . & (20819-admsndt) >= 30 

	eststo clear
	foreach x in P2D P2A{			
		eststo: reghdfe die_30_adm team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm
		}
	esttab using "${RESULTS}/regs_admmortality_A.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{PCI}" "\shortstack{CABG}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	
	g die_30_adm = 100*(death_dt1<=(admsndt+30) | death_dt2<=(admsndt+30)) if admsndt != . & (20819-admsndt) >= 30 

	eststo clear
	foreach x in P2D P2A{		
		eststo: reghdfe die_30_adm team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm
		}	
	esttab using "${RESULTS}/regs_admmortality_B.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{PCI}" "\shortstack{CABG}") type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*-----------------------------*
* Table A14: alternative measurement windows of patient mortality
*-----------------------------*
*** Panel A 			
use "${OUTPUT}/team_analysis_ed", clear
	
	foreach i in 14 60{
		g die_`i' = 100*(death_dt1<=(dschrgdt+`i') | death_dt2<=(dschrgdt+`i')) if !missing(dschrgdt) & (20819-dschrgdt) >= `i' 
	}
	
	eststo clear
	foreach x in P2D P2A{
		foreach i in 14 30 60{
			eststo: reghdfe die_`i' team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}
	esttab using "${RESULTS}/regs_altermortality_A.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Two\\weeks}" "\shortstack{30-\\day}" "\shortstack{60-\\day}" "\shortstack{Two\\weeks}" "\shortstack{30-\\day}" "\shortstack{60-\\day}") mgroups("PCI" "CABG" , pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	
	foreach i in 14 60{
		g die_`i' = 100*(death_dt1<=(dschrgdt+`i') | death_dt2<=(dschrgdt+`i')) if !missing(dschrgdt) & (20819-dschrgdt) >= `i' 
	}
	
	eststo clear
	foreach x in P2D P2A{
		foreach i in 14 30 60{
			eststo: reghdfe die_`i' team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
				qui estadd ysumm
		}
	}
	esttab using "${RESULTS}/regs_altermortality_B.tex", keep(team_experience_2) indicate("Full control = female", labels(Y)) collabels(none) mtitles("\shortstack{Two\\weeks}" "\shortstack{30-\\day}" "\shortstack{60-\\day}" "\shortstack{Two\\weeks}" "\shortstack{30-\\day}" "\shortstack{60-\\day}") mgroups("PCI" "CABG" , pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*-----------------------------*
* Table A15: standard error clustered by alternative levels
*-----------------------------*
*** Panel A 			
use "${OUTPUT}/team_analysis_ed", clear
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster prvdrnum)
			qui estadd ysumm	

		eststo: reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) vce(cluster i.prvdrnum#i.year)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_alterse_A.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("Surgeon" "Hospital" "Hospital-year" "Surgeon" "Hospital" "Hospital-year") mgroups("PCI" "CABG" , pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.4\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace
	
*** Panel B
use "${OUTPUT}/team_analysis_twoway", clear
	
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
		
		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster prvdrnum)
			qui estadd ysumm	

		eststo: reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster i.prvdrnum#i.year)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_alterse_B.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("Surgeon" "Hospital" "Hospital-year" "Surgeon" "Hospital" "Hospital-year") mgroups("PCI" "CABG" , pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(1.4\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace


	
	
	

/*****************************************************************************************
PURPOSE: Generate Appendix Tables A1-A5
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
* Table A1: sample construction
*-----------------------------*
mat summ = J(12, 4, .)
*** Panel A. ED analysis sample
use "${OUTPUT}/team_2008", clear

	keep if (P2A == 1 | P2D == 1) & inlist(betos, "M2A", "M2B", "M2C")
	keep medparid admsndt dschrgdt P2A P2D expnsdt1 betos
	
	forvalues i = 2009/2016{
		append using "${OUTPUT}/team_`i'"
		keep if (P2A == 1 | P2D == 1) & inlist(betos, "M2A", "M2B", "M2C")
		keep medparid admsndt dschrgdt P2A P2D expnsdt1 betos
	}	
	keep if expnsdt1 >= admsndt & expnsdt1 <= dschrgdt	
	drop expnsdt1 betos
	
	duplicates drop
	merge 1:1 medparid using "${OUTPUT}/team_experience_surgeon", keep(3) nogen
	keep if year(admsndt)>=2010 & (20819-dschrgdt)>=30 & !missing(admsndt) & !missing(dschrgdt)	
	
	cou if P2D
	mat summ[1, 1] = r(N)
	cou if P2A
	mat summ[1, 3] = r(N)

use "${OUTPUT}/team_analysis_final", clear
	drop if full != 1
	
	cou if P2D
	mat summ[2, 1] = r(N)
	cou if P2A
	mat summ[2, 3] = r(N)
	
	drop if age<65 | age>100	
	cou if P2D
	mat summ[3, 1] = r(N)
	cou if P2A
	mat summ[3, 3] = r(N)
	
	keep if er_amt > 0 & !missing(er_amt)
	cou if P2D
	mat summ[4, 1] = r(N)
	cou if P2A
	mat summ[4, 3] = r(N)

	drop if medrank1_attphy_avg_miss | age_attphy_avg_miss | yrprac_attphy_avg_miss | female_attphy_avg_miss
	foreach var of varlist age_gp female black hispanic medicaid *_dummy disable esrd surgery_cnt_2y phy_experience_2y npi_surgeon prvdrnum admsndt{
		drop if missing(`var')
	}
	cou if P2D
	mat summ[5, 1] = r(N)
	cou if P2A
	mat summ[5, 3] = r(N)
	
use "${OUTPUT}/team_analysis_ed", replace	
	cou if P2D
	mat summ[6, 1] = r(N)
	cou if P2A
	mat summ[6, 3] = r(N)

*** Panel B. two-way fixed effects sample	
	forvalues i = 1(2)3{
		mat summ[8, `i'] = summ[1, `i']
	}
	
use "${OUTPUT}/team_analysis_final", clear
	drop if full != 1
	
	cou if P2D
	mat summ[9, 1] = r(N)
	cou if P2A
	mat summ[9, 3] = r(N)
	
	drop if age<65 | age>100	
	cou if P2D
	mat summ[10, 1] = r(N)
	cou if P2A
	mat summ[10, 3] = r(N)

	drop if medrank1_attphy_avg_miss | age_attphy_avg_miss | yrprac_attphy_avg_miss | female_attphy_avg_miss
	foreach var of varlist age_gp female black hispanic medicaid *_dummy disable esrd surgery_cnt_2y phy_experience_2y npi_surgeon prf_npi1 prvdrnum admsndt{
		drop if missing(`var')
	}
	cou if P2D
	mat summ[11, 1] = r(N)
	cou if P2A
	mat summ[11, 3] = r(N)
	
use "${OUTPUT}/team_analysis_twoway", replace	
	cou if P2D
	mat summ[12, 1] = r(N)
	cou if P2A
	mat summ[12, 3] = r(N)

	forvalues i = 1/12{
		mat summ[`i', 2] = 100*summ[`i', 1]/summ[1, 1]
		mat summ[`i', 4] = 100*summ[`i', 3]/summ[1, 3]
	}
	
	mat colname summ = "PCI" "CABG" "PCI" "CABG"
	mat list summ
	putexcel A1=matrix(summ, names) using "${RESULTS}/team_sample.xls", replace

*-----------------------------*
* Table A2: summary statistics
*-----------------------------*
*** Columns 1-2: all patients
use "${OUTPUT}/team_experience_panel", replace
	
	drop if full != 1
	
	egen tag_phy = tag(medparid prf_npi)
	bysort medparid: egen num_phy = total(tag_phy)
	
	merge m:1 medparid using "${OUTPUT}/team_analysis_final", keep(3) nogen keepusing(medparid)
	
	mat summary = J(9, 6, .)
	local j = 1
	foreach x in P2D P2A{
		preserve
			keep if `x' == 1
			foreach var in npi_surgeon prf_npi medparid{
				egen `var'_gp = group(`var')
			}
			su npi_surgeon_gp
			mat summary[1, `j'] = r(max)
			su prf_npi_gp
			mat summary[2, `j'] = r(max)
			su medparid_gp
			mat summary[3, `j'] = r(max)
			
			keep medparid num_phy
			duplicates drop
			su num_phy, detail
			mat summary[5, `j'] = r(mean)			
			mat summary[6, `j'] = r(sd)	
			mat summary[7, `j'] = r(p25)
			mat summary[8, `j'] = r(p50)			
			mat summary[9, `j'] = r(p75)	
			
		restore
		local j = `j'+1
	}

*** Columns 3-4: ED sample
use "${OUTPUT}/team_experience_panel", replace
	
	egen tag_phy = tag(medparid prf_npi)
	bysort medparid: egen num_phy = total(tag_phy)
	
	merge m:1 medparid using "${OUTPUT}/team_analysis_ed", keep(3) nogen keepusing(medparid)
	
	local j = 3
	foreach x in P2D P2A{
		preserve
			keep if `x'  == 1
			foreach var in npi_surgeon prf_npi medparid{
				egen `var'_gp = group(`var')
			}
			su npi_surgeon_gp
			mat summary[1, `j'] = r(max)
			su prf_npi_gp
			mat summary[2, `j'] = r(max)
			su medparid_gp
			mat summary[3, `j'] = r(max)
			
			keep medparid num_phy
			duplicates drop
			su num_phy, detail
			mat summary[5, `j'] = r(mean)			
			mat summary[6, `j'] = r(sd)	
			mat summary[7, `j'] = r(p25)
			mat summary[8, `j'] = r(p50)			
			mat summary[9, `j'] = r(p75)	
			
		restore
		local j = `j'+1
	}

*** Columns 5-6: two-way fixed effects sample
use "${OUTPUT}/team_experience_panel", replace
	
	egen tag_phy = tag(medparid prf_npi)
	bysort medparid: egen num_phy = total(tag_phy)
	
	merge m:1 medparid using "${OUTPUT}/team_analysis_twoway", keep(3) nogen keepusing(medparid)
	
	local j = 5
	foreach x in P2D P2A{
		preserve
			keep if `x' == 1
			foreach var in npi_surgeon prf_npi medparid{
				egen `var'_gp = group(`var')
			}
			su npi_surgeon_gp
			mat summary[1, `j'] = r(max)
			su prf_npi_gp
			mat summary[2, `j'] = r(max)
			su medparid_gp
			mat summary[3, `j'] = r(max)
			
			keep medparid num_phy 
			duplicates drop
			su num_phy, detail
			mat summary[5, `j'] = r(mean)			
			mat summary[6, `j'] = r(sd)	
			mat summary[7, `j'] = r(p25)
			mat summary[8, `j'] = r(p50)			
			mat summary[9, `j'] = r(p75)	
				
		restore
		local j = `j'+1
	}
	
mat rowname summary = "Number of proceduralists" "Number of physicians" "Number of cases" "Number of physicians per case" "Mean" "SD" "P25" "P50" "P75" 
mat colname summary = "PCI" "CABG" "PCI" "CABG" "PCI" "CABG"
mat list summary
putexcel A1=matrix(summary, names) using "${RESULTS}/team_description.xls", replace

*-----------------------------*
* Table A3: selection on observables and unobservables
*-----------------------------*
use "${OUTPUT}/team_analysis_ed", clear
	
	mat summary = J(2, 12, .)
	
	*** PCI
	foreach x in P2D{	
	* physician unobservables
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)	
		local beta_zero_`x' = coef[1,1]
		local R_zero_`x' = e(r2_within)
		mat summary[1,1] = `beta_zero_`x''
		mat summary[1,2] = `R_zero_`x''
		
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)
		local beta_tilde_`x' = coef[1,1]
		local R_tilde_`x' = e(r2_within)
		mat summary[1,3] = `beta_tilde_`x''
		mat summary[1,4] = `R_tilde_`x''	
		
		mat summary[1,5] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(1.3*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]
		mat summary[1,6] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(2*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]	
		
	* patient unobservables	
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)	
		local beta_zero_`x' = coef[1,1]
		local R_zero_`x' = e(r2_within)
		mat summary[2,1] = `beta_zero_`x''
		mat summary[2,2] = `R_zero_`x''
		
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} ${PatCtrl_A} i.age_gp if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)
		local beta_tilde_`x' = coef[1,1]
		local R_tilde_`x' = e(r2_within)
		mat summary[2,3] = `beta_tilde_`x''
		mat summary[2,4] = `R_tilde_`x''	
		
		mat summary[2,5] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(1.3*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]
		mat summary[2,6] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(2*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]	

	} 


	*** CABG
	foreach x in P2A{	
	* physician unobservables
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)	
		local beta_zero_`x' = coef[1,1]
		local R_zero_`x' = e(r2_within)
		mat summary[1,7] = `beta_zero_`x''
		mat summary[1,8] = `R_zero_`x''
		
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)
		local beta_tilde_`x' = coef[1,1]
		local R_tilde_`x' = e(r2_within)
		mat summary[1,9] = `beta_tilde_`x''
		mat summary[1,10] = `R_tilde_`x''	
		
		mat summary[1,11] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(1.3*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]
		mat summary[1,12] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(2*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]	
		
	* patient unobservables	
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)	
		local beta_zero_`x' = coef[1,1]
		local R_zero_`x' = e(r2_within)
		mat summary[2,7] = `beta_zero_`x''
		mat summary[2,8] = `R_zero_`x''
		
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} ${PatCtrl_A} i.age_gp if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
		mat coef = e(b)
		local beta_tilde_`x' = coef[1,1]
		local R_tilde_`x' = e(r2_within)
		mat summary[2,9] = `beta_tilde_`x''
		mat summary[2,10] = `R_tilde_`x''	
		
		mat summary[2,11] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(1.3*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]
		mat summary[2,12] = `beta_tilde_`x''-(`beta_zero_`x''-`beta_tilde_`x'')*[(2*`R_tilde_`x''-`R_tilde_`x'')/(`R_tilde_`x''-`R_zero_`x'')]	

	} 
	mat rowname summary = "Physician controls" "Patient controls"
	mat colname summary = "Beta0" "R0" "Betaf" "Rf" "BetaAdj1" "BetaAdj2" "Beta0" "R0" "Betaf" "Rf" "BetaAdj1" "BetaAdj2"
	mat list summary
	putexcel A1=matrix(summary, names) using "${RESULTS}/team_OsterAdj_ed.xls", replace
	
*-----------------------------*
* Table A4: ED Analysis with main physician fixed effects
*-----------------------------*
use "${OUTPUT}/team_analysis_ed", clear	
	
	merge 1:1 medparid using "${OUTPUT}/team_analysis_final", keepusing(*other*) keep(1 3) nogen
	drop age_attphy_avg* yrprac_attphy_avg* female_attphy_avg* medrank1_attphy_avg* medrank2_attphy_avg* medrank3_attphy_avg* medrank4_attphy_avg*
	
	drop if female_other_attphy_avg_miss | age_other_attphy_avg_miss | yrprac_other_attphy_avg_miss | medrank_other_attphy_avg_miss
	eststo clear
	foreach x in P2D P2A{
		eststo: reghdfe die_30 team_experience_2 ${PatCtrl_B} surgery_cnt_2y phy_experience_2y shrrank_other_1-shrrank_other_5 age*avg yrprac*avg female*avg medrank*avg if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
			qui estadd ysumm	
	}
	esttab using "${RESULTS}/regs_mainphyfe_ed.tex", indicate("Full control = female", labels(Y)) collabels(none) mtitles("PCI" "CABG")  keep(team_experience_2) type booktabs noconstant label nostar cells(b(fmt(3)) se(par(( )) fmt(3))) se width(.8\hsize) stats(ymean ysd N, fmt(2 2 %10.0fc) label("Mean dep. var." "S.D. dep. var." "Observations")) replace

*-----------------------------*
* Table A5: balance in patient characteristics, two-way fixed effects model
*-----------------------------*
use "${OUTPUT}/team_analysis_twoway", clear
	
	foreach proc in P2A P2D {
		foreach x in age female black hispanic medicaid disable cc die_30_`proc' {
			reghdfe `x' surgery_cnt_2y phy_experience_2y ${DocCtrl_B} if `proc' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year i.prf_npi1) residuals(`x'_`proc')			
			su `x' if `proc' == 1
			replace `x'_`proc' = `x'_`proc'+r(mean)
		}
	}		
	
	foreach proc in P2A P2D {
		su team_experience_2 if `proc' == 1
		g xtile_`proc' = (team_experience_2 > r(mean)) if !missing(team_experience_2)
	}
	
	replace die_30_P2A_P2A = die_30_P2A_P2A*100
	replace die_30_P2D_P2D = die_30_P2D_P2D*100
	
	foreach proc in P2D P2A {
		mat summ_`proc' = J(18, 3, .)
		mat colname summ_`proc' = "Below mean" "Above mean" "p-value"
		mat rowname summ_`proc' = "Age" "" "Female" "" "Black" "" "Hispanic" "" "Medicaid" "" "Disabled" "" "Number of comorbidities" "" "Predicted 30-day mortality (%)" "(by patient characteristics)" "" "Observations"
		local i = 1
		local j = 2
		foreach x in age female black hispanic medicaid disable cc die_30_`proc' {					
			quiet ttest `x'_`proc' if `proc' == 1, by(xtile_`proc') 
			mat summ_`proc'[`i', 1] = r(mu_1)
			mat summ_`proc'[`j', 1] = r(sd_1)
			mat summ_`proc'[`i', 2] = r(mu_2)
			mat summ_`proc'[`j', 2] = r(sd_2)
			mat summ_`proc'[`i', 3] = r(p)
			mat summ_`proc'[18, 1] = r(N_1)
			mat summ_`proc'[18, 2] = r(N_2)
			local i = `i'+2
			local j = `j'+2
		}
		mat list summ_`proc'
		putexcel A1=matrix(summ_`proc', names) using "${RESULTS}/team_`proc'_balance_twoway.xls", replace
	}
	

	
	
	
	

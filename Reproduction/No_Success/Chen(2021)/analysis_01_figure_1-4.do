/*****************************************************************************************
PURPOSE: Generate Figures 1-4
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
* Figure 1: distribution of shared work experience
*-----------------------------*	
local i = 1
foreach x in P2D P2A{
	use "${OUTPUT}/team_analysis_ed", clear		

		keep if `x' == 1
		reghdfe team_experience_2_original, a(i.npi_surgeon) residuals(exp_`x')
		replace exp_`x' = -50 if exp_`x'<=-50
		replace exp_`x' = 50 if exp_`x'>50 & !missing(exp_`x')
			
		hist exp_`x', graphregion(color(white)) frac ytitle("Fraction", height(6) size(medlarge)) xtitle("Shared Work Experience", height(6) size(medlarge)) color(gs7) lc(black) ylab(, nogrid)
		graph save "${RESULTS}/teamexp_`x'_resid", replace
		if `i' == 1{
			graph export "${RESULTS}/Figure1A.pdf", replace
		}
		else{
			graph export "${RESULTS}/Figure1B.pdf", replace	
		}	
		local i = `i'+1	
}

*** examples using individual proceduralists	
use "${OUTPUT}/team_analysis_ed", clear	

	bysort npi_surgeon: egen tot = count(medparid)
	keep if tot >= 15
	
	gsort npi_surgeon -medparid	
	forvalues i = 200(200)2000{
		preserve
			set seed `i'
			generate random = runiform()
			sort random
			keep if npi_surgeon == npi_surgeon[1]
		
			gsort npi_surgeon admsndt -medparid
			by npi_surgeon: g n = _n	
		
			sort n
			graph twoway connected team_experience_2_original n, lc(black) mc(black) ytitle("Shared Work Experience", height(6)) xtitle("Patients Ordered by Admission Date", height(6)) graphregion(color(white)) ylab(, nogrid) 
		restore	
	}			

*-----------------------------*
* Figure 2: actual and predicted 30-Day mortality versus shared work experience: ED patients
*-----------------------------*	
use "${OUTPUT}/team_analysis_ed", clear	
	
	*** predicted mortality as a function of physician characteristics
	foreach x in P2D P2A{
		quiet reghdfe die_30 ${DocCtrl_A} phy_experience_2y surgery_cnt_2y team_experience_2 ${PatCtrl_A} if `x' == 1, absorb(${FE_A}) 			
		mat die_30_`x' = e(b)
		mat b = die_30_`x'[1, 1..12]
		mat score phy_va_die_30_`x' = b if e(sample)
	}
	
	*** group shared work experience
	g team_exp_gp = .
	replace team_exp_gp = 1 if 0<=team_experience_2_original & team_experience_2_original<5
	replace team_exp_gp = 2 if 5<=team_experience_2_original & team_experience_2_original<10
	replace team_exp_gp = 3 if 10<=team_experience_2_original & team_experience_2_original<15
	replace team_exp_gp = 4 if 15<=team_experience_2_original & team_experience_2_original<20
	replace team_exp_gp = 5 if 20<=team_experience_2_original & team_experience_2_original<25
	replace team_exp_gp = 6 if team_experience_2_original >= 25 & !missing(team_experience_2_original)

	label define team_exp_gp_lab 1 "[0,5)" 2 "[5,10)" 3 "[10,15)" 4 "[15,20)" 5 "[20,25)" 6 ">=25"
	label value team_exp_gp team_exp_gp_lab

	*** generate figure
	local i = 1
	foreach x in P2D P2A{
		preserve
		keep if `x' == 1
		reghdfe die_30_`x' surgery_cnt_2y phy_experience_2y ${DocCtrl_A}, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year) residuals(die_30_`x'_r)
			
		su phy_va_die_30_`x'
		replace phy_va_die_30_`x' = phy_va_die_30_`x'-r(mean)
			
		collapse (mean) die_30 die_30_`x'_r phy_va_die_30_`x' `x', by(team_exp_gp)
		two (scatter die_30 team_exp_gp, mc(black) ms(O)) ///
		(scatter die_30_`x'_r team_exp_gp, mc(black) ms(Th)) ///
		(scatter phy_va_die_30_`x' team_exp_gp, mc(black) ms(sh)) ///
		(lfit die_30 team_exp_gp, lp(solid) lc(black)) ///
		(lfit die_30_`x'_r team_exp_gp, lp(dash) lc(black)) ///
		(lfit phy_va_die_30_`x' team_exp_gp, lp(dash) lc(black)), ///
		legend(order(1 "Actual mortality" ///
		2 "Predicted mortality as a function of patient characteristics (demeaned)" ///
		3 "Predicted mortality as a function of physician characteristics (demeaned)") ///
		rows(3) region(lwidth(none))) note("") ylab(,nogrid) xlab(, valuelabel) ///
		xtitle("Shared Work Experience", height(6) size(medium)) ///
		ytitle("30-Day Mortality (%)", height(6) size(medium)) graphregion(color(white))
		
		graph save "${RESULTS}/team_`x'_all.gph", replace
		
		if `i' == 1{
			graph export "${RESULTS}/Figure2A.pdf", replace
		}
		else{
			graph export "${RESULTS}/Figure2B.pdf", replace	
		}	
		local i = `i'+1
		restore
	}	
	
*-----------------------------*
* Figure 3: sensitivity of effect of shared work experience on 30-day mortality: ED analysis
*-----------------------------*	
set seed 12345678
mat coefP2A = J(13,14,.)
mat coefP2D = J(13,14,.)

*** input selectionobservable_patient.dta
clear
set obs 14
g n =_n
g var = ""
local i = 1
foreach x in i.age_gp female black hispanic medicaid disable esrd alzhdmt_dummy chrnkdn_dummy diabtes_dummy copd_dummy chf_dummy strktia_dummy cancer_dummy{
	replace var = "`x'" if n == `i'
	local i = `i'+1
}
save "${OUTPUT}/selectionobservable_patient.dta", replace
	
forvalues i = 1/13{
	clear
	set obs 200
	g ctrl = ""
	save "${OUTPUT}/ctrl.dta", replace
	
	* iterate until find 14 different sets of controls for each i 
	scalar ctrl_gp = 0
	local j = 1
	while ctrl_gp < 14{	
		use "${OUTPUT}/selectionobservable_patient.dta", clear			
			sample `i', count
			sort n
			forvalues l = 1/`i'{
				local ctrl`l' = var[`l']
			}
			global ctrl ""
			forvalues l = 1/`i'{
				global ctrl "${ctrl} `ctrl`l''"		
			}

		use "${OUTPUT}/ctrl.dta", clear
			replace ctrl = "${ctrl}" in `j'
			cap drop gp
			egen gp = group(ctrl)	
			su gp
			scalar ctrl_gp = r(max)
		save "${OUTPUT}/ctrl.dta", replace
		local j = `j'+1
	}
	
	* regressions with each of the randomly selected sets of controls
	local j = 1	
	forvalues k = 1/14{	
		use "${OUTPUT}/ctrl.dta", replace
			drop if missing(ctrl)
			duplicates drop
			sort ctrl
			global ctrl = ctrl[`k']
			di "${ctrl}"
			
		use "${OUTPUT}/team_analysis_ed", clear	
			foreach x in P2A P2D{
				quiet reghdfe die_30 team_experience_2 ${ctrl} surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year)
				mat b = e(b)
				mat coef`x'[`i', `j'] = b[1,1]
			}			
		local j = `j'+1		
	}
}		
	
use "${OUTPUT}/team_analysis_ed", clear	
	mat temp = J(1, 14, .)
	
	foreach x in P2A P2D{
		mat coef`x' = temp\coef`x'\temp	
		
		* without any patient control
		quiet reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_A} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year) vce(cluster npi_surgeon)
		mat b = e(b)
		mat coef`x'[1, 1] = b[1,1]			
		
		* with the full set of patient controls
		quiet reghdfe die_30 team_experience_2 ${PatCtrl_A} ${DocCtrl_A} surgery_cnt_2y phy_experience_2y if `x' == 1, absorb(${FE_A}) vce(cluster npi_surgeon)
		mat b = e(b)
		mat coef`x'[15, 1] = b[1,1]	
			
		putexcel A1=matrix(coef`x', names) using "${RESULTS}/selectionobservable_`x'_ed.xls", replace	
	}

*** Panel A
import excel "${RESULTS}/selectionobservable_P2D_ed.xls", sheet("Sheet1") firstrow clear
	g n = _n-1
	foreach x in min max mean{
		egen `x' = row`x'(c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14)
	}		
	twoway (connected max n, lp(dash) lc(gs5) mc(gs5) ms(sh)) ///
	(connected mean n, lp(solid) mc(black) ms(o) lw(medium) lc(black)) ///
	(connected min n, lp(dash) lc(gs5) mc(gs5) ms(th)) ///
	(pcarrowi -.75 1.8 -.62 0 "" -.75  12.2 -.62 14 "", mlc(black) lc(black)), ///
	yline(-.8615331   -.3148598, lp(shortdash)  lc(gs7)) ///
	xtitle("Number of Patient Controls Added", height(6) size(medium)) ///
	ytitle("Estimated Coefficient", height(6) size(medium)) graphregion(color(white)) ///
	legend(order (1 "Maximum" 2 "Mean" 3 "Minimum") pos(12) ring(0) col(3) size(medium))  ///
	ylab(-.86(.28)-.3, nogrid labsize(medium)) ///
	text(-.8 3.7 "Estimate with no patient control" "=-0.586 (s.e.=0.139)", size(medsmall) linegap(1) j(left)) ///
	text(-.8 11.5 "Estimate with full set of patient controls" "=-0.588 (s.e.=0.139)", size(medsmall) linegap(1) j(left))
	graph save "${RESULTS}/Figure3A.gph", replace	
	graph export "${RESULTS}/Figure3A.pdf", replace	
	
*** Panel B
import excel "${RESULTS}/selectionobservable_P2A_ed.xls", sheet("Sheet1") firstrow clear
	g n = _n-1
	foreach x in min max mean{
		egen `x' = row`x'(c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14)
	}
	twoway (connected max n, lp(dash) lc(gs5) mc(gs5) ms(sh)) ///
	(connected mean n, mc(black) ms(o) lp(solid) lw(medium) lc(black)) ///
	(connected min n, lp(dash) lc(gs5) mc(gs5) ms(th)) ///
	(pcarrowi -1.95 1.8 -1.4 0 "" -1.95 12.2 -1.4 14 "", mlc(black) lc(black)), ///
	yline(-2.405019   -.0785155, lp(shortdash)  lc(gs7)) ///
	xtitle("Number of Patient Controls Added", height(6) size(medium)) ///
	ytitle("Estimated Coefficient", height(6) size(medium)) graphregion(color(white)) ///
	legend(order (1 "Maximum" 2 "Mean" 3 "Minimum") pos(12) ring(0) col(3) size(medium))  ///
	ylab(-2.4(1.2)0, nogrid labsize(medium)) ///
	text(-2.15 3.7 "Estimate with no patient control" "=-1.279 (s.e.=0.606)", size(medsmall) linegap(1) j(left)) ///
	text(-2.15 11.5 "Estimate with full set of patient controls" "=-1.242 (s.e.=0.593)", size(medsmall) linegap(1) j(left))	
	graph save "${RESULTS}/Figure3B.gph", replace
	graph export "${RESULTS}/Figure3B.pdf", replace	
	
*-----------------------------*
* Figure 4: effects of shared work experience on 30-day mortality: two-way fixed effects model
*-----------------------------*	
use "${OUTPUT}/team_analysis_twoway", clear	

	*** group shared work experience
	g team_exp_gp = .
	replace team_exp_gp = 1 if 0<=team_experience_2_original & team_experience_2_original<5
	replace team_exp_gp = 2 if 5<=team_experience_2_original & team_experience_2_original<10
	replace team_exp_gp = 3 if 10<=team_experience_2_original & team_experience_2_original<15
	replace team_exp_gp = 4 if 15<=team_experience_2_original & team_experience_2_original<20
	replace team_exp_gp = 5 if 20<=team_experience_2_original & team_experience_2_original<25
	replace team_exp_gp = 6 if team_experience_2_original >= 25 & !missing(team_experience_2_original)
	
	label define team_exp_gp_lab 1 "[0,5)" 2 "[5,10)" 3 "[10,15)" 4 "[15,20)" 5 "[20,25)" 6 ">=25"
	label value team_exp_gp team_exp_gp_lab
	
	local i = 1
	*** generate figure
	foreach x in P2D P2A{	
		quiet reghdfe die_30 ib1.team_exp_gp ${Ctrl_B} if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
		mat gp = [1\2\3\4\5\6]
		mat coef = e(b)
		mat coef = coef[1...., 1..6 ]'
		mat var = vecdiag(e(V))
		mat var = var[1..., 1..6]'
		matewmf var se, function(sqrt)
		mat se = se
		mat ciu = coef+1.96*se
		mat cil = coef-1.96*se
				
		mat coefplot = gp, coef, cil, ciu
		cap drop coefplot*
		svmat coefplot
			
		tw (scatter coefplot2 coefplot1, ylab(,nogrid labsize(medium)) msize(medium) mc(black) ms(O))(rspike coefplot4 coefplot3 coefplot1, legend(off) lp(solid) lw(medium) lc(black)), graphregion(color(white)) yline(0, lpattern(longdash) lc(black)) ytitle("Coefficient and 95% Confidence Interval", height(6) size(medium)) xtitle("Shared Work Experience", height(6) size(medium)) graphregion(color(white)) xlab(1 "[0,5)" 2 "[5,10)" 3 "[10,15)" 4 "[15,20)" 5 "[20,25)" 6 ">=25" , valuelabel labsize(medium)) 
		graph save "${RESULTS}/regs_`x'_twoway", replace
		
		if `i' == 1{
			graph export "${RESULTS}/Figure4A.pdf", replace
		}
		else{
			graph export "${RESULTS}/Figure4B.pdf", replace	
		}	
		local i = `i'+1	
	}






/*****************************************************************************************
PURPOSE: Generate Appendix Figures A1-A5
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
* Figure A1: distribution of shared work experience
*-----------------------------*		
use "${OUTPUT}/team_analysis_final", clear
	
	replace team_experience_2 = 50 if team_experience_2>=50 & !missing(team_experience_2)	
	g team_experience_2_hist = 0 if team_experience_2 == 0
	forvalue i = 2(2)50{
		replace team_experience_2_hist = `i' if team_experience_2 <= `i' & team_experience_2 >`i'-2 
	}
	
	foreach x in P2D P2A{
		hist team_experience_2_hist if `x' == 1, discrete graphregion(color(white)) frac ytitle("Fraction", height(6) size(medlarge)) xtitle("Shared Work Experience", height(6) size(medlarge)) color(gs7) lc(black) ylab(, nogrid)
		graph save "${RESULTS}/teamexp_hist_`x'", replace
	}
	
*-----------------------------*
* Figure A2: sensitivity of effect of shared work experience on 30-day mortality: two-way fixed effects model
*-----------------------------*	
set seed 12345678
mat coefP2A = J(13,14,.)
mat coefP2D = J(13,14,.)
	
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
			
		use "${OUTPUT}/team_analysis_twoway", clear	
			foreach x in P2A P2D{
				reghdfe die_30 team_experience_2 ${ctrl} surgery_cnt_2y phy_experience_2y ${DocCtrl_B} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year i.prf_npi1)
				mat b = e(b)
				mat coef`x'[`i', `j'] = b[1,1]
			}			
		local j = `j'+1		
	}
}		
	
use "${OUTPUT}/team_analysis_twoway", clear	
	mat temp = J(1, 14, .)
	
	foreach x in P2A P2D{
		mat coef`x' = temp\coef`x'\temp	
		
		* without any patient control
		reghdfe die_30 team_experience_2 surgery_cnt_2y phy_experience_2y ${DocCtrl_B} if `x' == 1, absorb(i.npi_surgeon i.month i.dow i.prvdrnum#i.year i.prf_npi1) vce(cluster npi_surgeon)
		mat b = e(b)
		mat coef`x'[1, 1] = b[1,1]			
		
		* with the full set of patient controls
		reghdfe die_30 team_experience_2 ${PatCtrl_B} ${DocCtrl_B} surgery_cnt_2y phy_experience_2y if `x' == 1, absorb(${FE_B}) vce(cluster npi_surgeon)
		mat b = e(b)
		mat coef`x'[15, 1] = b[1,1]	
			
		putexcel A1=matrix(coef`x', names) using "${RESULTS}/selectionobservable_`x'_twoway.xls", replace	
	}

*** Panel A
import excel "${RESULTS}/selectionobservable_P2D_twoway.xls", sheet("Sheet1") firstrow clear
	g n = _n-1
	foreach x in min max mean{
		egen `x' = row`x'(c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14)
	}		
	twoway (connected max n, lp(dash) lc(gs5) mc(gs5) ms(sh)) ///
	(connected mean n, lp(solid) mc(black) ms(o) lw(medium) lc(black)) ///
	(connected min n, lp(dash) lc(gs5) mc(gs5) ms(th)) ///
	(pcarrowi -.76 1.8 -.55 0 "" -.76  12.2 -.55 14 "", mlc(black) lc(black)), ///
	yline(-.9479197   -.0683456, lp(shortdash)  lc(gs7)) ///
	xtitle("Number of Patient Controls Added", height(6) size(medium)) ///
	ytitle("Estimated Coefficient", height(6) size(medium)) graphregion(color(white)) ///
	legend(order (1 "Maximum" 2 "Mean" 3 "Minimum") pos(12) ring(0) col(3) size(medium))  ///
	ylab(-1(.5)0, nogrid labsize(medium)) ///
	text(-.85 3.7 "Estimate with no patient control" "=-0.501 (s.e.=0.219)", size(medium) linegap(1) j(left)) ///
	text(-.85 12 "Estimate with full set of patient controls" "=-0.508 (s.e.=0.224)", size(medium) linegap(1) j(left))
	graph save "${RESULTS}/team_selection_P2D_twoway.gph", replace	
	
*** Panel B
import excel "${RESULTS}/selectionobservable_P2A_twoway.xls", sheet("Sheet1") firstrow clear
	g n = _n-1
	foreach x in min max mean{
		egen `x' = row`x'(c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14)
	}
	twoway (connected max n, lp(dash) lc(gs5) mc(gs5) ms(sh)) ///
	(connected mean n, mc(black) ms(o) lp(solid) lw(medium) lc(black)) ///
	(connected min n, lp(dash) lc(gs5) mc(gs5) ms(th)) ///
	(pcarrowi -1.01 1.6 -.86 0 "" -1.01 12.4 -.86 14 "", mlc(black) lc(black)), ///
	yline(-1.254162   -.2539474, lp(shortdash)  lc(gs7)) ///
	xtitle("Number of Patient Controls Added", height(6) size(medium)) ///
	ytitle("Estimated Coefficient", height(6) size(medium)) graphregion(color(white)) ///
	legend(order (1 "Maximum" 2 "Mean" 3 "Minimum") pos(12) ring(0) col(3) size(medium))  ///
	ylab(-1.25(.5)-.25, nogrid labsize(medium)) ///
	text(-1.1 3.7 "Estimate with no patient control" "=-0.829 (s.e.=0.255)", size(medium) linegap(1) j(left)) ///
	text(-1.1 12 "Estimate with full set of patient controls" "=-0.754 (s.e.=0.255)", size(medium) linegap(1) j(left))
	graph save "${RESULTS}/team_selection_P2A_twoway.gph", replace
	
*-----------------------------*
* Figure A3: shared work experience based on all patients versus ED patients
*-----------------------------*	
use "${OUTPUT}/team_experience_panel", replace	
	merge m:1 medparid using "${OUTPUT}/team_experience_surgeon", keepusing(surgery_cnt_ed_2y) keep(3) nogen
	keep if year >= 2010
	
	keep medparid P2A P2D team_experience_2 team_experience_ed_2 surgery_cnt_ed_2y phy_experience_ed_2y npi_surgeon
	duplicates drop
	
	foreach x in P2A P2D{
		reg team_experience_2 team_experience_ed_2 surgery_cnt_ed_2y phy_experience_ed_2y if `x' == 1, vce(cluster npi_surgeon)
		mat coef = e(b)
		mat var = vecdiag(e(V))
		matewmf var se, function(sqrt) 
		local Coef = trim("`: display %10.3f coef[1,1]'")
		local SE = trim("`: display %10.3f se[1,1]'")	
		binscatter team_experience_2 team_experience_ed_2 if `x' == 1, note("Coefficient = `Coef'" "(`SE')", just(right) pos(4) ring(0) size(medsmall)) mc(gs4) lc(black) xtitle("Shared Work Experience Based on ED Patients", height(6)) ytitle("Shared Work Experience Based on All Patients", height(6)) ylab(, nogrid)
		graph save "${RESULTS}/team_expEDAll_`x'", replace
	}

*-----------------------------*
* Figure A4: standard deviation of shared work experience
*-----------------------------*	
global row "11"
global col "50"

*** draw subsets of patients
* random sampling
set seed 100
forvalues year = 2008/2016{
	forvalues i = 50(5)95{
		forvalues draw = 1/${col}{
			use "${INPUT}/bsf/`year'/bsfab`year'.dta", clear					
				keep bene_id
				duplicates drop
				sample `i'
				g year = `year'			
			save "${OUTPUT}/beneid_`year'_`i'_`draw'.dta", replace		
		}
	}
}

* append files
forvalues i = 50(5)95{
	forvalues draw = 1/${col}{
		use "${OUTPUT}/beneid_2008_`i'_`draw'.dta", clear			
			forvalues year = 2009/2016{
				append using "${OUTPUT}/beneid_`year'_`i'_`draw'.dta"
			}			
		save "${OUTPUT}/beneid_`i'_`draw'.dta", replace
	}
}		

*** generate new measures of experience	
forvalues i = 50(5)95{
	forvalues draw = 1/${col}{
		use  "${OUTPUT}/beneid_`i'_`draw'.dta", clear	
				
			merge 1:m bene_id year using "${OUTPUT}/team_experience_panel", keep(2 3)
			cap drop n 
			cap drop low* high*
			assert expnsdt1 == expnsdt2
			g n = (_merge == 3)
			g low = admsndt-730
			g high = admsndt-1
			
			* shared work experience
			rangestat (sum) team_cnt_`i'_`draw'=n, interval(expnsdt1, low, high) by(prf_npi npi_surgeon)			
			replace team_cnt_`i'_`draw' = 0 if missing(team_cnt_`i'_`draw')
			bysort medparid: egen team_experience_`i'_`draw' = mean(team_cnt_`i'_`draw')
			
			* physicians' individual experience
			cap drop n_P2A n_P2D
			g n_P2A = (P2A*(_merge == 3))
			g n_P2D = (P2D*(_merge == 3))
			
			foreach x in P2A P2D{
				rangestat (sum) phy_`x'_cnt_`i'_`draw'=n_`x', interval(expnsdt1, low, high) by(prf_npi)
				replace phy_`x'_cnt_`i'_`draw' = 0 if missing(phy_`x'_cnt_`i'_`draw') & !missing(prf_npi) & !missing(npi_surgeon)
			}

			bysort medparid: egen phy_P2D_experience_`i'_`draw'= mean(phy_P2D_cnt_`i'_`draw')
			bysort medparid: egen phy_P2A_experience_`i'_`draw'= mean(phy_P2A_cnt_`i'_`draw')
				
			g phy_experience_`i'_`draw' = phy_P2D_experience_`i'_`draw' if P2D == 1
			replace phy_experience_`i'_`draw' = phy_P2A_experience_`i'_`draw' if P2A == 1	
			
		keep medparid team_experience_`i'_`draw' phy_experience_`i'_`draw' P2A P2D
		duplicates drop
					
		save "${OUTPUT}/beneid_`i'_`draw'_exp.dta", replace						
	}
}
	* proceduralists' individual work experience
	forvalues i = 50(5)95{
		forvalues draw = 1/${col}{
			use  "${OUTPUT}/beneid_`i'_`draw'.dta", clear	
				merge 1:m bene_id year using "${OUTPUT}/team_experience_surgeon", keep(2 3)
				g tag = (_merge == 3) if !missing(npi_surgeon)
				g low = admsndt-730
				g high = admsndt-1
				rangestat (sum) surgery_cnt_`i'_`draw'=tag, interval(surgery_dt_min, low, high) by(npi_surgeon)
				replace surgery_cnt_`i'_`draw' = 0 if missing(surgery_cnt_`i'_`draw')
				
				keep medparid surgery_cnt_`i'_`draw'
				duplicates drop
				merge 1:1 medparid using "${OUTPUT}/beneid_`i'_`draw'_exp.dta", keep(2 3) nogen
				
			save "${OUTPUT}/beneid_`i'_`draw'_exp.dta", replace			
		}
	 }
 
*** extrapolate standard deviation of shared work experience
* Panels A and B: ED sample
mat sd_P2D = J(${row}, ${col}, .)
mat sd_P2A = J(${row}, ${col}, .)

local row = 1
forvalues i = 50(5)95{
	local col = 1
	forvalues draw = 1/${col}{
		use "${OUTPUT}/beneid_`i'_`draw'_exp.dta", clear				
			merge 1:1 medparid using "${OUTPUT}/team_analysis_ed", keep(3) nogen
			
			foreach x in P2A P2D{
				su team_experience_`i'_`draw' if `x' == 1
				mat sd_`x'[`row', `col'] = r(sd)
			}	
		local col = `col'+1		
		}		
	local row = `row'+1	
}

	foreach x in P2A P2D{
		use "${OUTPUT}/team_analysis_ed", clear
		su team_experience_2_original if `x' == 1
		mat sd_`x'[${row}, ${col}] = r(sd)
		putexcel A1=matrix(sd_`x', names) using "${RESULTS}/sd_`x'_ed.xls", replace
	}
	
*- Panel A: PCI, ED Sample
import excel "${RESULTS}/sd_P2D_ed.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen sd =rowmean(c*)
	
	reg sd pct
	mat coef = e(b)
	sort pct
	set obs 200
	replace pct = ((_n-1)+10) if missing(pct)
	gen sd_predict = coef[1, 1]*pct+coef[1,2]
	twoway (line sd_predict pct if pct<=200 & pct>= 10, lp(dash) lw(medthick) lc(gs6)) (line sd pct if pct<=20, lp(solid) lw(thick) lc(black)), ylab(0(5)40, grid glcolor(gs15)) xlab(10(10)200, ang(45)) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6) size(medlarge)) ytitle("Standard Deviation", height(6) size(medlarge)) legend(off) xline(20 100 200, lp(shortdash) lc(gs8) lw(medium)) 
	graph save "${RESULTS}/sd_P2D_ed", replace
	
*- Panel B: CABG, ED Sample	
import excel "${RESULTS}/sd_P2A_ed.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen sd =rowmean(c*)	
	
	reg sd pct
	mat coef = e(b)
	sort pct
	set obs 200
	replace pct = ((_n-1)+10) if missing(pct)
	gen sd_predict = coef[1, 1]*pct+coef[1,2]	
	twoway (line sd_predict pct if pct<=200 & pct>= 10, lp(dash) lw(medthick) lc(gs6)) (line sd pct if pct<=20, lp(solid) lw(thick) lc(black)), ylab(0(10)100, grid glcolor(gs15)) xlab(10(10)200, ang(45)) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6) size(medlarge)) ytitle("Standard Deviation", height(6) size(medlarge)) legend(off) xline(20 100 200, lp(shortdash) lc(gs8) lw(medium)) 
	graph save "${RESULTS}/sd_P2A_ed", replace
		
	
* Panels C and D: two-way fixed effects sample
mat sd_P2D = J(${row}, ${col}, .)
mat sd_P2A = J(${row}, ${col}, .)

local row = 1
forvalues i = 50(5)95{
	local col = 1
	forvalues draw = 1/${col}{
		use "${OUTPUT}/beneid_`i'_`draw'_exp.dta", clear				
			merge 1:1 medparid using "${OUTPUT}/team_analysis_twoway", keep(3) nogen
			foreach x in P2A P2D{
				su team_experience_`i'_`draw' if `x' == 1
				mat sd_`x'[`row', `col'] = r(sd)
			}	
		local col = `col'+1		
		}		
	local row = `row'+1	
}

	foreach x in P2A P2D{
		use "${OUTPUT}/team_analysis_twoway", clear
		su team_experience_2_original if `x' == 1
		mat sd_`x'[${row}, ${col}] = r(sd)
		putexcel A1=matrix(sd_`x', names) using "${RESULTS}/sd_`x'_twoway.xls", replace
	}

*- Panel C: PCI, two-way fixed effects sample
import excel "${RESULTS}/sd_P2D_twoway.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen sd =rowmean(c*)
	
	reg sd pct
	mat coef = e(b)
	sort pct
	set obs 200
	replace pct = ((_n-1)+10) if missing(pct)
	gen sd_predict = coef[1, 1]*pct+coef[1,2]	
	twoway (line sd_predict pct if pct<=200 & pct>= 10, lp(dash) lw(medthick) lc(gs6)) (line sd pct if pct<=20, lp(solid) lw(thick) lc(black)), ylab(0(10)80, grid glcolor(gs15)) xlab(10(10)200, ang(45)) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6) size(medlarge)) ytitle("Standard Deviation", height(6) size(medlarge)) legend(off) xline(20 100 200, lp(shortdash) lc(gs8) lw(medium)) 
	graph save "${RESULTS}/sd_P2D_twoway", replace
	
*- Panel D: CABG, two-way fixed effects sample
import excel "${RESULTS}/sd_P2A_twoway.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen sd =rowmean(c*)
	
	reg sd pct
	mat coef = e(b)
	sort pct
	set obs 200
	replace pct = ((_n-1)+10) if missing(pct)
	gen sd_predict = coef[1, 1]*pct+coef[1,2]	
	
	twoway (line sd_predict pct if pct<=200 & pct>= 10, lp(dash) lw(medthick) lc(gs6)) (line sd pct if pct<=20, lp(solid) lw(thick) lc(black)), ylab(0(20)160, grid glcolor(gs15)) xlab(10(10)200, ang(45)) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6) size(medlarge)) ytitle("Standard Deviation", height(6) size(medlarge)) legend(off) xline(20 100 200, lp(shortdash) lc(gs8) lw(medium)) 
	graph save "${RESULTS}/sd_P2A_twoway", replace
	
*-----------------------------*
* Figure A5: exploring measurement error
*-----------------------------*	
*** Panels A and B: ED sample
* coefficient estimates 
mat coeff_P2D = J(${row}, ${col}, .)
mat coeff_P2A = J(${row}, ${col}, .)

local row = 1
forvalues i = 50(5)95{
	local col = 1
	forvalues draw = 1/${col}{
		use "${OUTPUT}/beneid_`i'_`draw'_exp.dta", clear			
			merge 1:1 medparid using "${OUTPUT}/team_analysis_ed", keep(2 3)				
			foreach x in P2D P2A{
				su team_experience_`i'_`draw' if `x' == 1
				replace team_experience_`i'_`draw' = team_experience_`i'_`draw'/r(sd) if `x' == 1
				su team_experience_`i'_`draw' if `x' == 1
			}
			foreach x in P2D P2A{				
				quiet reghdfe die_30 team_experience_`i'_`draw' phy_experience_`i'_`draw' surgery_cnt_`i'_`draw' ${PatCtrl_A} ${DocCtrl_A} if `x' == 1, absorb(${FE_A}) 
					mat coef = e(b)
					mat coeff_`x'[`row', `col'] = coef[1...., 1]
			}	
		local col = `col'+1		
		}
	local row = `row'+1	
}

use "${OUTPUT}/team_analysis_ed", clear
	foreach x in P2D P2A{				
		quiet reghdfe die_30 team_experience_2 ${Ctrl_A} if `x' == 1, absorb(${FE_A}) 
			mat coef = e(b)
			mat coeff_`x'[${row}, ${col}] = coef[1...., 1]
	}
			
foreach x in P2A P2D{
	putexcel A1=matrix(coeff_`x', names) using "${RESULTS}/coeff_`x'_ed.xls", replace
}

* graph Panel A: PCI, Empirical Strategy I
import excel "${RESULTS}/coeff_P2D_ed.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen coef = rowmean(c*)
	egen coef_median = rowmedian(c*)
	
tw (connected coef pct, mc(black) lc(black)) (line coef_median pct, lp(longdash) lc(black)), yline(-.8615331   -.3148598, lp(dash) lc(gs6)) yline(0, lp(solid) lc(black)) ylab(-.9(.45)0, nogrid) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6)  size(medlarge)) ytitle("Coefficient", height(6) size(medlarge)) legend(order (1 "Mean" 2 "Median"))
graph save "${RESULTS}/coeff_P2D_ed", replace
	
* graph Panel B: CABG, Empirical Strategy I
import excel "${RESULTS}/coeff_P2A_ed.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)
	egen coef = rowmean(c*)
	egen coef_median = rowmedian(c*)
	
tw (connected coef pct, mc(black) lc(black)) (line coef_median pct, lp(longdash) lc(black)), yline(-2.405019   -.0785155, lp(dash) lc(gs6)) yline(0, lp(solid) lc(black)) ylab(-2.4(1.2)0, nogrid) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6)  size(medlarge)) ytitle("Coefficient", height(6) size(medlarge)) legend(order (1 "Mean" 2 "Median"))
graph save "${RESULTS}/coeff_P2A_ed", replace
		
*** Panels C and D: two-way fixed effects model
* coefficient estimates
mat coeff_P2D = J(${row}, ${col}, .)
mat coeff_P2A = J(${row}, ${col}, .)

local row = 1
forvalues i = 50(5)95{
	local col = 1
	forvalues draw = 1/${col}{
		use "${OUTPUT}/beneid_`i'_`draw'_exp.dta", clear
				
			merge 1:1 medparid using "${OUTPUT}/team_analysis_twoway", keep(2 3)
			foreach x in P2D P2A{
				su team_experience_`i'_`draw' if `x' == 1
				replace team_experience_`i'_`draw' = team_experience_`i'_`draw'/r(sd) if `x' == 1
				su team_experience_`i'_`draw' if `x' == 1
			}
			foreach x in P2D P2A{				
				quiet reghdfe die_30 team_experience_`i'_`draw' phy_experience_`i'_`draw' surgery_cnt_`i'_`draw' ${PatCtrl_B} ${DocCtrl_B} if `x' == 1, absorb(${FE_B}) 
					mat coef = e(b)
					mat coeff_`x'[`row', `col'] = coef[1...., 1]
			}	
		local col = `col'+1		
		}
	local row = `row'+1	
}

use "${OUTPUT}/team_analysis_twoway", clear
	foreach x in P2D P2A{				
		quiet reghdfe die_30 team_experience_2 ${Ctrl_B} if `x' == 1, absorb(${FE_B}) 
			mat coef = e(b)
			mat coeff_`x'[${row}, ${col}] = coef[1...., 1]
	}
	
foreach x in P2A P2D{	
	putexcel A1=matrix(coeff_`x', names) using "${RESULTS}/coeff_`x'_twoway.xls", replace
}

* graph Panel C: PCI, Empirical Strategy II	
import excel "${RESULTS}/coeff_P2D_twoway.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)	
	egen coef = rowmean(c*)
	egen coef_median = rowmedian(c*)
	
	tw (connected coef pct, mc(black) lc(black)) (line coef_median pct, lp(longdash) lc(black)), yline(-.9479197 -.0683456, lp(dash) lc(gs6)) yline(0, lp(solid) lc(black)) ylab(-1(.5)0, nogrid) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6)  size(medlarge)) ytitle("Coefficient", height(6) size(medlarge)) legend(order (1 "Mean" 2 "Median"))
	graph save "${RESULTS}/coeff_P2D_phyfe", replace
	
* graph Panel D: CABG, Empirical Strategy II	
import excel "${RESULTS}/coeff_P2A_twoway.xls", sheet("Sheet1") firstrow clear
	g pct = 10+(_n-1)	
	egen coef = rowmean(c*)
	egen coef_median = rowmedian(c*)

	tw (connected coef pct, mc(black) lc(black)) (line coef_median pct, lp(longdash) lc(black)), yline(-1.254162 -.2539474, lp(dash) lc(gs6)) yline(0, lp(solid) lc(black)) ylab(-1.3(.65)0, nogrid) graphregion(color(white)) xtitle("Percent of Traditional Medicare Enrollees", height(6)  size(medlarge)) ytitle("Coefficient", height(6) size(medlarge)) legend(order (1 "Mean" 2 "Median"))
	graph save "${RESULTS}/coeff_P2A_phyfe", replace



* erase temp files	
forvalues year = 2008/2016{
	forvalues i = 50(5)95{
		forvalues draw = 1/${col}{
			cap erase "${OUTPUT}/beneid_`year'_`i'_`draw'.dta"
		}
	}
}

forvalues i = 50(5)95{
	forvalues draw = 1/${col}{
		cap erase "${OUTPUT}/beneid_`i'_`draw'.dta"
		cap erase "${OUTPUT}/beneid_`i'_`draw'_exp.dta"
	}
}

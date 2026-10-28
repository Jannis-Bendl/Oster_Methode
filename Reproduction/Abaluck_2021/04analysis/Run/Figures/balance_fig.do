* ---------------------------------------------------------------------
* Title:    Balance Figures (Figure 4)
* Blame:    Peter Hull (hull@uchicago.edu)
* Reformat: Emily Crawford (emily.crawford@yale.edu)
* Created:  July 2020
* Updated:  Wednesday, November 18th 2020
* Purpose:  Creates balance figures (Figure 4) for the paper
* ---------------------------------------------------------------------
// To Run independently after saving "balanceplot_regressions.dta", uncomment block below:
/*
// local optsFolder 	BaselineStuff-take4
// local tag 			BaselineStuff_plots_balance
// local args	 		runPlots_balance
// local sample 		SampleSelection2
// qui do 00common/00preamble.do nodep
// include 04analysis/AnalysisConfigurations/`optsFolder'/`tag'.do
// do 04analysis/Parse/CommandLineArgs.do ; `options' tag(`tag')
// qui do 00common/00material.do
// include 04analysis/Parse/FigureOptions.do
// include 04analysis/Parse/RegressionOptions.do
*/

* Setup
cap ssc install scheme-burd

* Out Folder
cap mkdir `"${out}/"'
cap mkdir `"${out}/fig/"'
cap mkdir `"${out}/fig/`plotsTag'/"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/"'

local plots_folder `"${out}/fig/`plotsTag'/`tag'"'

if (`"`tag'"' == "") {
	display as error "Analysis Configurations tag required"
	error 111
}

if ((`"`tag'"' == "BaselineStuff_plots_FSRF_viv")+(`"`tag'"' == "BaselineStuff_plots_FSRF_viv_1pct") > 0) {
	local baldepvars `alpha' `mortality' `alpha'_lag
}
else {
	local baldepvars `alpha' predictedMortality_dual eta `mortality' `alpha'_lag
}

* Create 
xi i.plantypeFE*`alpha'_lag i.plantypeFE*dum_med, prefix(_P)
xi i.plantypeFE*frac_plan_county_lag, prefix(_F)
local balindepvars "_PplaX* `alpha'_lag dum_med `cDec'"
local balothercont "`terminated' frac_plan_county_lag _Pplan* _FplaX*"
local balFE "fe_county_lag_year b0.`terminated'#i.year b0.`terminated'#fe_county_lag plantypeFE#fe_county_lag plantypeFE#i.year `bin_var'_lag#b0.`terminated'"

* Run Regressions
*---------------------------------------------------------------------------
foreach var of varlist `baldepvars' {
	local versions 1D
	foreach v of local versions {
		di `"reghdfe `var'  `instrument`v'' `balindepvars' `balothercont' `ifcommand' `addCond', absorb(`balFE') cluster(`cluster')"'
		reghdfe `var'  `instrument`v'' `balindepvars' `balothercont' `ifcommand' `addCond', absorb(`balFE') cluster(`cluster')
	}
	cap drop temp
	gen temp = 0
	foreach cont_var of varlist `balindepvars' {
		replace temp = temp + _b[`cont_var']*`cont_var'
	}

	gen `var'_dis0 = 0 if _n<=10
	gen `var'_dis1 = 0 if _n<=10
	forval q=2/10 {
		replace `var'_dis1 =  _b[Zxdum_dec`q'] if _n==`q'
	}
	forval q=1/10 {
		qui summ temp if dec_alpha_lag == `q' & !`terminated'
		replace `var'_dis0 = `var'_dis0 + r(mean) if _n==`q'
		replace `var'_dis1 = `var'_dis1 + r(mean) if _n==`q'
	}
	drop temp
	qui summ `var'
	local `var'_mn=r(mean)
}
keep *_dis0 *_dis1
drop if `alpha'_dis0 == .
duplicates drop

foreach var in `baldepvars'  {
	gen `var'_dis_d = `var'_dis1-`var'_dis0
	qui summ `var'_dis_d
	replace `var'_dis1 = `var'_dis1 - r(mean)
	replace `var'_dis_d = `var'_dis_d - r(mean)
}
foreach var in `baldepvars' {
	foreach var2 in `var'_dis0 `var'_dis1 {
		qui summ `var2' 
		replace `var2'=`var2'-r(mean)+``var'_mn'
	}
}

if ((`"`tag'"' == "BaselineStuff_plots_balance")+(`"`tag'"' == "BaselineStuff_plots_balance_1pct") > 0) {
	save `"${out}/balanceplot_regressions.dta"', replace
}

*use `"${out}/balanceplot_regressions.dta"', clear

local legend label(1 "Nonterminated Plans") label(3 "Terminated Plans")
local legend `legend' order(1 3) cols(1) ring(1) position(1) bmargin(small)
local xtitle "Lagged Observational Mortality"
local scheme "scheme(burd4)"
local margins "graphregion(color(white)  margin(1 1 1 1))"


* Create Plots
*---------------------------------------------------------------------------
#delimit ;

if ((`"`tag'"' == "BaselineStuff_plots_balance")+(`"`tag'"' == "BaselineStuff_plots_balance_1pct") > 0) { ;
	/* first stage */
	scatter `alpha'_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') msymbol(circle)
		|| lfit `alpha'_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') lwidth(0.5)
		|| scatter `alpha'_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') msymbol(circle)
		|| lfit `alpha'_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') lwidth(0.5)
		xtitle(`xtitle') xlab(0.03(0.01)0.06) ylab(0.03(0.01)0.06)
		ytitle("Observational Mortality") 
		legend(`legend') 
		title("A. First Stage", color(black) pos(12) ) `scheme' `margins'
		name(fstage, replace)
	;
	graph export `plots_folder'/FS_`pct'pct_nq10.svg, `xopts' ;
	graph export `plots_folder'/FS_`pct'pct_nq10.eps, mag(100) fontface(Times) replace ;

	/* balance */ ;
	scatter predictedMortality_dual_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') msymbol(circle)
		|| lfit predictedMortality_dual_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') lwidth(0.5)
		|| scatter predictedMortality_dual_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') msymbol(circle)	
		|| lfit predictedMortality_dual_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') lwidth(0.5)
		xtitle(`xtitle') xlab(0.03(0.01)0.06)
		ylab(0.03(0.01)0.06, nogrid) ytitle("Predicted Mortality") 
		legend( `legend') 
		title("B. Balance", color(black) pos(12)) `scheme' `margins'
		name(balance, replace)
	;
	graph export `plots_folder'/bal_`pct'pct_nq10.svg, `xopts' ;
	graph export `plots_folder'/bal_`pct'pct_nq10.eps, mag(100) fontface(Times) replace ;

	/* eta */;
	scatter eta_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') msymbol(circle)
		|| lfit eta_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') lwidth(0.5)
		|| scatter eta_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') msymbol(circle)
		|| lfit eta_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') lwidth(0.5)
		xtitle(`xtitle') ylab(-0.01(0.005)0.01, nogrid) 
		ytitle("Predicted Forecast Residual")  xlab(0.03(0.01)0.06)
		legend( `legend' ) 
		title("C. Fallback", color(black) pos(12)) `scheme' `margins'
		name(eta, replace)
	;
	graph export `plots_folder'/fb_`pct'pct_nq10.svg, `xopts' ;
	graph export `plots_folder'/fb_`pct'pct_nq10.eps, mag(100) fontface(Times) replace ;

	/* rf */;
	scatter `mortality'_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') msymbol(circle)
		|| lfit `mortality'_dis0 `alpha'_lag_dis0, color(`"`lColorNoTerm'"') lwidth(0.5)
		|| scatter `mortality'_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') msymbol(circle)
		|| lfit `mortality'_dis1 `alpha'_lag_dis1, color(`"`lColorTerm'"') lwidth(0.5)
		xtitle(`xtitle') ytitle("One-Year Mortality")  xlab(0.03(0.01)0.06)
		legend( `legend') 
		title("D. Reduced Form", color(black) pos(12)) `scheme' `margins'
		name(rform, replace)
	;
	graph export `plots_folder'/rf_`pct'pct_nq10.svg, `xopts' ;
	graph export `plots_folder'/rf_`pct'pct_nq10.eps, mag(100) fontface(Times) replace ;

};

if ((`"`tag'"' == "BaselineStuff_plots_FSRF_viv")+(`"`tag'"' == "BaselineStuff_plots_FSRF_viv_1pct") > 0) { ;
	/* Figure A4 (FS and RF) and (visual IV) */
	* reg `alpha'_dis_d `alpha'_lag_dis0 if _n>3;
	* reg `mortality'_dis_d `alpha'_lag_dis0 if _n>3;
	* reg `mortality'_dis_d `alpha'_dis_d, nocons;

	scatter `alpha'_dis_d `alpha'_lag_dis0, color(`"`alColorNoTerm'"') msymbol(circle) 
		|| scatter `mortality'_dis_d `alpha'_lag_dis0, color(`"`alColorTerm'"') msymbol(circle)	
		xtitle(`xtitle') xlab(0.03(0.01)0.06) ylab(-0.02(0.01)0.03, axis(1))
		ylab(-0.02(0.01)0.03)
		ytitle("Observational Mortality / One-Year Mortality") 
		legend(label(1 "First Stage") label(2 "Reduced Form") order(1 2) cols(1) ring(0) position(1) bmargin(small)
	)  `scheme' `margins' title("A. First Stage and Reduced Form Heterogeneity", color(black) pos(12))
		name(doug, replace)
	;
	graph export `plots_folder'/FSRF_`pct'pct_nq10_v1.svg, `xopts' ;

	scatter `alpha'_dis_d `alpha'_lag_dis0, color(`"`alColorNoTerm'"') msymbol(circle) 
		|| scatter `mortality'_dis_d `alpha'_lag_dis0, color(`"`alColorTerm'"') msymbol(circle)	
		xtitle(`xtitle') xlab(0.03(0.01)0.06) ylab(-0.02(0.01)0.03, axis(1))
		ylab(-0.02(0.01)0.03)
		ytitle("Observational Mortality (FS) /" "One-Year Mortality (RF)") 
		legend(label(1 "First Stage") label(2 "Reduced Form") order(1 2) cols(1) ring(0) position(1) bmargin(small)
	)  `scheme' `margins' title("A. First Stage and Reduced Form Heterogeneity", color(black) pos(12))
		name(doug, replace)
	;
	graph export `plots_folder'/FSRF_`pct'pct_nq10_v2.svg, `xopts' ;


	scatter `mortality'_dis_d `alpha'_dis_d , color(`"`alColorNoTerm'"') msymbol(circle)
		|| lfit `mortality'_dis_d `alpha'_dis_d , estopts(nocons) color(`"`alColorNoTerm'"') lwidth(0.5)
		xtitle("Observational Mortality (First Stage)") xlab(-0.02(0.01)0.02)
		ytitle("One-Year Mortality (Reduced Form)") ylab(-0.02(0.01)0.02)
	`scheme' `margins' legend(off) title("B. Visual Instrumental Variables", color(black) pos(12))
		name(viv, replace)
	;
	graph export `plots_folder'/viv_`pct'pct_nq10.svg, `xopts' ;

} ;
#delimit cr

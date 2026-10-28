* ---------------------------------------------------------------------
* Title:    Controls Balance Figure (A3)
* Blame:    Peter Hull (hull@uchicago.edu)
* Reformat: Emily Crawford (emily.crawford@yale.edu) and Jerray Chang (jerray@uchicago.edu)
* Created:  July 2020
* Updated:  Wednesday, November 18th 2020
* Purpose:  Creates riskscore and age balance figures for the paper (Figure A3)
* ---------------------------------------------------------------------

* Setup
cap ssc install scheme-burd

* Out Folder
cap mkdir `"${out}/fig/`plotsTag'/"'
cap mkdir `"${out}/fig/`plotsTag'/`tag'/"'

local plots_folder `"${out}/fig/`plotsTag'/`tag'"'

* Set local options based on `tag'
*---------------------------------------------------------------------------
if (`"`tag'"' == "") {
	display as error "Analysis Configurations tag required"
	error 111
}

if ((`"`tag'"' == "BaselineStuff_plots_balance_riskscore")+(`"`tag'"' == "BaselineStuff_plots_balance_riskscore_1pct") > 0) {
	drop if missing_average_risk_score_lag==1
	local balancevar average_risk_score_lag
	local ptitle title("A. Plan Risk Scores", color(black) pos(12) ) 
	local ytitle "Plan Risk Score"
	local ylab ylab(0.6(0.2)1.3) 
	local xlab xlab(0.03(0.01)0.06)
	local filename riskscore
}

if ((`"`tag'"' == "BaselineStuff_plots_balance_age")+(`"`tag'"' == "BaselineStuff_plots_balance_age_1pct") > 0) {
	local balancevar demo_age
	local ptitle title("B. Beneficiary Age", color(black) pos(12) )
	local ytitle "Beneficiary Age"
	local ylab ylab(74(1)79)
	local xlab xlab(0.03(0.01)0.06)
	local filename age
}

* Create interaction dummies and local varlists
xi i.plantypeFE*`alpha'_lag i.plantypeFE*dum_med, prefix(_P)
xi i.plantypeFE*frac_plan_county_lag, prefix(_F)
local balindepvars "_PplaX* `alpha'_lag dum_med `cDec'"
local balothercont "`terminated' frac_plan_county_lag _Pplan* _FplaX*"
local balFE "fe_county_lag_year b0.`terminated'#i.year b0.`terminated'#fe_county_lag plantypeFE#fe_county_lag plantypeFE#i.year `bin_var'_lag#b0.`terminated'"

* Run Regressions
*---------------------------------------------------------------------------
foreach var of varlist `balancevar' `alpha'_lag {
	local versions 1D
	foreach v of local versions {
		di `"reghdfe `var' `instrument`v'' `balindepvars' `balothercont' `ifcommand' `addCond', absorb(`balFE') cluster(`cluster')"'
		reghdfe `var' `instrument`v'' `balindepvars' `balothercont' `ifcommand' `addCond', absorb(`balFE') cluster(`cluster')
	}
	cap drop temp
	gen temp = 0
	foreach cont_var of varlist `balindepvars'  {
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
drop if `balancevar'_dis0 == .
duplicates drop

foreach var in `balancevar' `alpha'_lag {
	gen `var'_dis_d = `var'_dis1-`var'_dis0
	qui summ `var'_dis_d
	replace `var'_dis1 = `var'_dis1 - r(mean)
	replace `var'_dis_d = `var'_dis_d - r(mean)
}
foreach var in `balancevar' `alpha'_lag {
	foreach var2 in `var'_dis0 `var'_dis1 {
		qui summ `var2' 
		replace `var2'=`var2'-r(mean)+``var'_mn'
	}
}


local legend label(1 "Nonterminated Plans") label(3 "Terminated Plans")
local legend `legend' order(1 3) cols(1) ring(1) position(1) bmargin(small)
local xtitle "Lagged Observational Mortality"
local scheme "scheme(burd4)"
local margins "graphregion(color(white)  margin(1 1 1 1))"


* Create Plots
*---------------------------------------------------------------------------
scatter `balancevar'_dis0 `alpha'_lag_dis0, /// 
	color(`"`alColorNoTerm'"')  msymbol(circle) ///
	|| lfit `balancevar'_dis0 `alpha'_lag_dis0, color(`"`alColorNoTerm'"') lwidth(0.5) ///
	|| scatter `balancevar'_dis1 `alpha'_lag_dis1, color(`"`alColorTerm'"')  msymbol(circle) ///	
	|| lfit `balancevar'_dis1 `alpha'_lag_dis1, color(`"`alColorTerm'"') lwidth(0.5) ///
	graphregion(color(white) margin(1 1 1 1)) scheme(burd4) /// 
	xtitle("Lagged Observational Mortality") `ylab' `xlab' ///
	ytitle(`ytitle') legend(`legend' ) `ptitle'
graph export `plots_folder'/`filename'_bal_`pct'.svg, `xopts'
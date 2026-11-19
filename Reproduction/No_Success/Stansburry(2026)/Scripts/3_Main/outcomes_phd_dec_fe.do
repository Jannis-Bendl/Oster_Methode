
********************************************************************************
*Main Outcomes, PhD Program by Decade FE
********************************************************************************
*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

est clear

foreach weight in WTSURVY {

local controls gender ib5.race_n

local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 (for Tenure) OR TENURE equals 1 (for all other outcomes) and LOCATIONUS equals 1

local fes YR PHDPROGRAMDECADE years_since_phd5y  BIRTHCOUNTRY //*PhD Program X Decade FEs as in robustness.do

local se cluster PHDPROGRAMYR 
local weight WTSURVY
local covars edpar_n // we will only include edpar_n in final table, but want to control for race / gender

*Extensive Margin
local dep TENURE
local cond if LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
	qui reghdfe `dep' ib3.edpar_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'
	qui sum `dep' [w=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
regsave using "$TEMP/e_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/
	
	// Check number of observations:
	foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
*Intensive Margin
local depvarlist TEN_R1 TENLOGRANK lnEARN JOBSATIS_num 
foreach dep of local depvarlist {
local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
qui reghdfe `dep' ib3.edpar_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'
	qui sum `dep' [w=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
regsave using "$TEMP/e_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/

	// Check number of observations:
	
	foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}

}

estfe *`weight', labels(YR "Survey Year FE" PHDPROGRAMDECADE "PhD Program Decade FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" gender "Demographic FEs" BIRTHCOUNTRY "Birth Country FE")

esttab *`weight' using "$tables/outcomes_phd_dec_fe.tex", replace ///
title(Main Outcomes with PhD Program by Decade FE: Tenure Likelihood, Tenure Institution Type, Earnings, and Job Satisfaction \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Tenure" "R1" "Log Rank" "Log Earnings" "Job Satisfaction") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "Includes demographic FEs for race and gender.")
}

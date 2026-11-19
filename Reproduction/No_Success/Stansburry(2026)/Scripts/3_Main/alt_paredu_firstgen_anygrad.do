********************************************************************************
*Replicating main analyses, but with firstgen/non-firstgen

********************************************************************************
*Updated: Anna Apr 27 2025

********************************************************************************
*This code generates:
*Table1.tex
********************************************************************************

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

*Generate variable for no grad degree
gen nograd = (edpar_n==1 | edpar_n==2)
replace nograd = . if missing(edpar_n)

est clear

foreach edpar in firstgen nograd {
local weight WTSURVY
local controls
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 (for Tenure) OR TENURE equals 1 (for all other outcomes) and LOCATIONUS equals 1
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY
local se cluster  PHDPROGRAMYR
local weight WTSURVY
local covars edpar_n race_n gender 

*Extensive Margin
local dep TENURE
local cond if LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
	qui reghdfe `dep' `edpar' gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`edpar'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
*Intensive Margin
local depvarlist TEN_R1 TENLOGRANK lnEARN JOBSATIS_num 
foreach dep of local depvarlist {
local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
 qui reghdfe `dep' `edpar'  gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`edpar'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations:
		foreach var of local covars {			
			di "`edpar': `dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
}



estfe *`edpar', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab *`edpar' using "$tables/main_outcomes_`edpar'.tex", replace ///
title(Baseline Regression, alternative parental education categories (`edpar' vs non-`edpar')) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*`edpar'* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Tenure" "R1" "Log Rank" "Log Earnings" "Job Satisfaction") ///
	varwidth(2) ///
	refcat(`edpar' "ref:non-`edpar'" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'.")
}

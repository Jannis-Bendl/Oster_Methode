********************************************************************************
*Main Outcomes robustness - white non-hispanic US-born only

********************************************************************************
*Updated: Anna Apr 27 2025

********************************************************************************
*This code generates:
*Table1_whiteUSonly.tex
********************************************************************************


*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

est clear

foreach weight in WTSURVY {


local controls
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 (for Tenure) OR TENURE equals 1 (for all other outcomes) and LOCATIONUS equals 1
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local weight WTSURVY
local covars edpar_n gender race_n

*Extensive Margin
local dep TENURE
local cond if LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40 & bornus==1 & race_n==5
	
	reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'] , absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

	// Check number of observations:
	foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
	}

*Intensive Margin
local depvarlist TEN_R1 TENLOGRANK lnEARN JOBSATIS_num 
foreach dep of local depvarlist {
local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40 & bornus==1 & race_n==5

	su `fes' `cond' & !mi(`dep') 
	
	reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'] , absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'
	qui sum `dep' [w=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	

	// Check number of observations:
	foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
}

estfe *`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab *`weight' using "$tables/main_outcomes_whiteUSonly.tex", replace ///
title(Main Outcomes: Sample limited to White non-Hispanic US-born \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Tenure" "R1" "Log Rank" "Log Earnings" "Job Satisfaction") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'.")
}

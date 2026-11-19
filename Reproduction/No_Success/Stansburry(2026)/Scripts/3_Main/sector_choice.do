*Full Extensive Margin Table: Sector Choice

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

*Gen Any Academia dep var
gen ANYACADEMIA = TENURETRACK + EDUNTT

*10 years or more since PhD
est clear

local weight WTSURVY
local depvarlist ANYACADEMIA TENURE TTNOTTEN EDUNTT INDSECTOR GOVSECTOR 
foreach dep of local depvarlist {

local controls
local cond if LFSTAT=="1"  & LOCATIONUS==1  & years_since_phd>=10 & years_since_phd<40
local condnote1 if years_since_phd is less than 40 and years_since_phd is greater than or equal to 10 and LOCATIONUS equals 1 and LFSTAT equal 1
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY 
local se cluster  PHDPROGRAMYR
local covars edpar_n gender race_n

qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

	// Check number of observations:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}

}

estfe *`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab e_* using "$tables/sector_choice_10plus.tex", replace ///
title(Sector of Employment (10-39 years post PhD) \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')   ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "DVs are binary variables taking the value of 1 to indicate working in specified sector.")
	
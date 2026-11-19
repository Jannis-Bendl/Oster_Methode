*Other Sectors


*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear


*DEP VAR: EARNINGS AND JOB SATISFACTION BY SECTOR


est clear

local weight WTSURVY
local depvarlist lnEARN  JOBSATIS_num 
foreach sector in TENURETRACK INDSECTOR GOVSECTOR EDUNTT {
foreach dep of local depvarlist {

local controls
local cond if years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 & `sector'==1 
local condnote1 if years_since_phd is less than40 and LFSTAT equals 1 and LOCATIONUS equals 1 and sector equals 1
local fes YR years_since_phd PHDCY5y PHDINST PHDFIELDNEW BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`sector'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

	// Check number of observations:
		 foreach var of local covars {                   
		 	di "`sector': `dep' and `var'"
			tab `var' if e(sample)
			}
}
}

estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCON "Birth Continent FE")

esttab * using "$tables/salary_satis_bysector.tex", replace ///
title(Post-PhD Salary amd Job Satisfaction Gap - Tenure Track Academia, Industry, Government, and Non-Tenure Track Academia \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Log Earnings" "Job Satis." "Log Earnings" "Job Satis." "Log Earnings" "Job Satis." "Log Earnings" "Job Satis.") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "Cols 1-2: Tenure track academia (incl. tenured). Cols 3-4: Industry. Cols 5-6: Government. Cols 7-8: Non-tenure track academia.")
	
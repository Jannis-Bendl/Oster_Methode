********************************************************************************
*Pipeline Table Cols 1-3
*PhD to Tenure Track Pipeline - SAMPLE 1 -9 years since PhD
********************************************************************************
*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

est clear

foreach weight in WTSURVY {


local controls
local condnote1 if years_since_phd less than or equal to 9
local condnote2 equals 1 (for TTRACK) OR TENURETRACK equals 1 (for all other outcomes) and LOCATIONUS equals 1
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local weight WTSURVY
local covars edpar_n gender race_n

*Extensive Margin
local dep TENURETRACK
local cond if years_since_phd<=9  & LOCATIONUS==1 & LFSTAT=="1"
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
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
local depvarlist TT_R1 TTLOGRANK
foreach dep of local depvarlist {
local cond if TENURETRACK==1 & years_since_phd<=9  & LOCATIONUS==1 & LFSTAT=="1"
qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
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


estfe *`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab *`weight' using "$tables/phd_to_tt_pipeline.tex", replace ///
title(Main Outcomes: Tenure Likelihood, Tenure Institution Type, Earnings, and Job Satisfaction \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Tenuretrack" "R1" "Log Rank" ) ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'.")
}

********************************************************************************
*Pipeline Table Cols 4
*Tenure-Track to Tenure Pipeline: "Got Tenure"
********************************************************************************

********************************************************************************
*Summary table for key outcomes (separately by whether the insitutions are ranked)
********************************************************************************
use "$TEMP/tenuredecision_data", clear

*Sample size
count if flag_decisionyr==1  & !missing(GOT_TENURE_NEXTYR) & YR>=1997  & YR==maxdecisionyr & num_GOT_TENURE_NEXTYR>=5  & !missing(FULLRANK) & INSTCOD_miss!=1  & !missing(PHDFIELDNEW) & !missing(INSTCOD) & !missing(edpar_n) & !missing(race_n) & !missing(gender) & !missing(BIRTHCOUNTRY) & !missing(PHDCY5y) & !missing(years_since_phd5y) & INSTCOD_miss!=1 & t_TENURE_NEXTYR >= 5

tab YR if flag_decisionyr==1

est clear

*Individuals at ranked TT institutions only
foreach weight in WTSURVY  {
foreach dep in GOT_TENURE_NEXTYR {
	
local cond if flag_decisionyr==1 & YR==maxdecisionyr & YR>=1997 & !missing(GOT_TENURE_NEXTYR) & t_GOT_TENURE_NEXTYR>=5 & !missing(FULLRANK)
local condnote1 if flag_decisionyr equals 1 and YR is greater than or equal to 1997 and not missing FULLRANK and
local condnote2 YR equals maxdecisionyr and GOT_TENURE_NEXTYR is not missing and t_GOT_TENURE_NEXTYR is greater than or equal to 5 
local standarderror vce(cluster PHDPROGRAMYR)
local fes YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHDFIELDNEW
local covars edpar_n gender race_n

*With INSTCOD FE - without research controls
reghdfe `dep' ib3.edpar_n gender ib5.race_n  `cond' & INSTCOD_miss!=1 & t_TENURE_NEXTYR >= 5 [aw=`weight'], absorb(`fes') `standarderror'
est sto i_`dep'_`weight'

		qui sum `dep' [aw=`weight'] if e(sample)
		qui estadd scalar ywtm=r(mean)
		regsave using "$TEMP/e_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/
		
		//check number of obs:
		
		foreach var of local covars {
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
		
}

estfe i_*_`weight', labels(YR "Survey Year FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" BIRTHCON "Birth Country FE" INSTCOD "Institution FE")

esttab i_*_`weight' using "$tables/got_tenure.tex", replace ///
title(Pipeline: Got Tenure, conditional on Tenure Track Institution) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
mtitle( "Tenure Similar or Higher Ranked" ) ///
	varwidth(2) ///
	addnote("Condition: `condnote1'" "`condnote2'" "and t_TENURE_NEXTYR is greater than or equal to 5 and not missing INSTCOD" "Fixed Effects: `fes'" "Standard Error: `standarderror'" "Weighted by `weight'." "Individuals only in ranked insitutions.")

}

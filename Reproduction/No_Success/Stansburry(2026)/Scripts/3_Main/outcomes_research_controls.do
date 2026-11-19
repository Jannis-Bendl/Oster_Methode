********************************************************************************
*Tenure Institution Rank with Research Controls
********************************************************************************

*Load data
use "$TEMP/tenure_withpubs_data", clear

*Calculate sample sizes for export request
foreach var in edpar_n gender race_n {
tab `var' if TENURE==1 & LOCATIONUS==1  & !missing(PHDINST) & !missing(BIRTHCON) & !missing(pubs) & !missing(LOGRANK)
}

est clear

*Basic research controls: 2nd order polynomial in the RANK within field of: Pubs total, average CNCI per paper, average authors per paper, average impact factor per paper
*Each measure interacted with broad PHD field group
*We use rank by field instead of the raw numbers to avoid the issue of super right-skewed publication and citation numbers. We present robustness checks with the raw numbers (specifications 3/4)

local research1 c.pubs_rn##c.pubs_rn##i.PHD_GROUP c.avg_CNCI_rn##c.avg_CNCI_rn##i.PHD_GROUP c.avg_authors_rn##c.avg_authors_rn##i.PHD_GROUP c.avg_impactfactor_rn##c.avg_impactfactor_rn##i.PHD_GROUP 
local research2 `research1' c.pubs_firstauthor_rn##c.pubs_firstauthor_rn##i.PHD_GROUP   c.pubs_lastauthor_rn##c.pubs_lastauthor_rn##i.PHD_GROUP i.NSFBucket##i.PHD_GROUP  c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP

local research3 c.pubs##c.pubs##i.PHD_GROUP c.avg_CNCI##c.avg_CNCI##i.PHD_GROUP c.avg_authors##c.avg_authors##i.PHD_GROUP c.avg_impactfactor##c.avg_impactfactor##i.PHD_GROUP
local research4 `research3' c.pubs_firstauthor##c.pubs_firstauthor##i.PHD_GROUP   c.pubs_lastauthor##c.pubs_lastauthor##i.PHD_GROUP i.NSFBucket##i.PHD_GROUP  c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP


*Predict Tenure institution type or rank using research output, PhD year, years since PhD, PhD field, and PhD institution
foreach weight in  WTSURVY {
foreach dep in TEN_R1 LOGRANK   {
local cond if  LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
local condnote1 if LFSTAT equals 1 and LOCATIONUS equals 1 and  years_since_phd is greater than or 
local condnote2 equal to 10 and years_since_phd is less than 40 
local se cluster PHDPROGRAMYR
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY
local controls 
local covars edpar_n gender race_n


*No research controls
qui reghdfe `dep' ib3.edpar_n gender ib5.race_n  `controls' `cond'  [aw=`weight'], absorb(`fes') vce(`se')
	est sto `dep'r0_`weight'
				qui sum `dep' [aw=`weight'] if e(sample)
				qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr2 "No", replace 
				qui estadd local fixr3 "No", replace 
				qui estadd local fixr4 "No", replace 
				
	// Check number of observations:
	foreach var of local covars {			
	di "`dep' and `var' Samples (no research controls):"
	tab `var' if e(sample)
		}
		
regsave using "$TEMP/r0_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/

*Loop over research controls
foreach i in 1 2 3 4 {
capture drop r_`dep'
qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `research`i'' `controls' `cond'  [aw=`weight'], absorb(`fes' ) vce(`se') 
est sto `dep'r`i'_`weight'
				qui sum `dep' [aw=`weight'] if e(sample)
				qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr2 "No", replace 
				qui estadd local fixr3 "No", replace 
				qui estadd local fixr4 "No", replace 
				qui estadd local fixr`i' "Yes", replace 
				
	// Check number of observations:
	/*
	foreach var of local covars {	
			di "`dep' and `var' and research`i' Samples:"
			tab `var' if e(sample) 
		}
		*/
					
regsave using "$TEMP/r`i'_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/
}

*Tables for export
estfe `dep'r0_`weight' `dep'r1_`weight' `dep'r2_`weight' `dep'r3_`weight' `dep'r4_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab `dep'r0_`weight' `dep'r1_`weight' `dep'r2_`weight' `dep'r3_`weight' `dep'r4_`weight' using "$tables/research_controls_`dep'.tex", replace ///
title(`dep' with Research Controls \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(fixr1 fixr2 fixr3 fixr4 ywtm N r2 r2_a df_m df_a df_r, fmt(%16s %16s %16s %16s a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Research Controls 1" "Research Controls 2" "Research Controls 3" "Research Controls 4" "Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mlabels(,depvar) ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "The regressions in this table take our baseline regressions and limit the sample to individuals with tenure." "Each dependent variable investigates the type of insitution the individuals are tenured at," "conditional on different research controls at the time of the survey." "Each research control variable incdicates different combinations of research controls interacted with PhD field group.")
	
}
}

********************************************************************************
*Tenure-Track to Tenure Pipeline: "Got Tenure" with Research Controls
********************************************************************************

use "$TEMP/tenuredecision_data", clear

cap drop INSTFIELDYR //synthetic safeguard

egen INSTFIELDYR = group(INSTCOD PHDFIELDNEW YR)

*Basic research controls: 2nd order polynomial in the RANK within field of: Pubs total, average CNCI per paper, average authors per paper, average impact factor per paper
*Each measure interacted with broad PHD field group
*We use rank by field instead of the raw numbers to avoid the issue of super right-skewed publication and citation numbers. We present robustness checks with the raw numbers (specifications 3/4)

local research1 c.pubs_rn##c.pubs_rn##i.PHD_GROUP c.avg_CNCI_rn##c.avg_CNCI_rn##i.PHD_GROUP c.avg_authors_rn##c.avg_authors_rn##i.PHD_GROUP c.avg_impactfactor_rn##c.avg_impactfactor_rn##i.PHD_GROUP 
local research2 `research1' c.pubs_firstauthor_rn##c.pubs_firstauthor_rn##i.PHD_GROUP   c.pubs_lastauthor_rn##c.pubs_lastauthor_rn##i.PHD_GROUP i.NSFBucket##i.PHD_GROUP  c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP

local research3 c.pubs##c.pubs##i.PHD_GROUP c.avg_CNCI##c.avg_CNCI##i.PHD_GROUP c.avg_authors##c.avg_authors##i.PHD_GROUP c.avg_impactfactor##c.avg_impactfactor##i.PHD_GROUP
local research4 `research3' c.pubs_firstauthor##c.pubs_firstauthor##i.PHD_GROUP   c.pubs_lastauthor##c.pubs_lastauthor##i.PHD_GROUP i.NSFBucket##i.PHD_GROUP  c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP

	
*"GOT TENURE" SAMPLE (those with FIELD ranked TT institutions)
*NOTE: currently this specification includes only the last decision year for each person TENURE_NEXTYR
est clear
foreach dep in GOT_TENURE_NEXTYR    {
	
local weight WTSURVY
local cond if flag_decisionyr==1  & !missing(GOT_TENURE_NEXTYR) & YR>=1997 & !missing(pubs) & YR==maxdecisionyr & num_GOT_TENURE_NEXTYR>=5  & !missing(FULLRANK) & INSTCOD_miss!=1
local condnote1 if flag_decisionyr equals 1 and not missing GOT_TENURE_NEXTYR and YR is greater than 
local condnote2 or equal to 1997 and not missing INSTCOD and not missing pubs and YR equals maxdecisionyr
local condnote3 and num_GOT_TENURE_NEXTYR is greater than or equal to 5 and not missing FULLRANK
local standarderror vce(cluster INSTFIELDYR)
local fes YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHD_CAT
local covars edpar_n gender race_n

*With INSTCOD and PHD_CAT FEs and field mean tenure rate - without research controls
qui reghdfe `dep' ib3.edpar_n gender ib5.race_n fmlo_`dep' `cond' [aw=`weight'], absorb(`fes' ) `standarderror'
est sto i_`dep'
		qui sum `dep' [aw=`weight'] if e(sample)
		qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr2 "No", replace 
				qui estadd local fixr3 "No", replace 
				qui estadd local fixr4 "No", replace 
		
	// Check number of observations:
	/*
	foreach var of local covars {			
	di "`dep' and `var' Samples (no research controls):"
	tab `var' if e(sample)
		}
		*/
		
regsave using "$TEMP/r0_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/
	
*... with various research controls
foreach i in 1 2 3 4 {
 reghdfe `dep' ib3.edpar_n gender ib5.race_n  fmlo_`dep'  `research`i''  `cond' [aw=`weight'], absorb(`fes' ) `standarderror'
est sto ir`i'_`dep'
				qui sum `dep' [aw=`weight'] if e(sample)
				qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr2 "No", replace 
				qui estadd local fixr3 "No", replace 
				qui estadd local fixr4 "No", replace 
				qui estadd local fixr`i' "Yes", replace
				
				
	// Check number of observations:
	/*
	foreach var of local covars {	
			di "`dep' and `var' and research`i' Samples:"
			tab `var' if e(sample) 
		}
		*/
	regsave using "$TEMP/r`i'_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/
	
}
}

***GOT_TENURE_NEXTYR
*I specifications
estfe i_GOT_TENURE_NEXTYR ir1_GOT_TENURE_NEXTYR ir2_GOT_TENURE_NEXTYR ir3_GOT_TENURE_NEXTYR ir4_GOT_TENURE_NEXTYR , labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" Current_R1 "R1 Insitution FE" Current_Research "Research Insitution FE" INSTCOD "Current Institution FE" BIRTHCON "Birth Continent FE")

esttab i_GOT_TENURE_NEXTYR ir1_GOT_TENURE_NEXTYR ir2_GOT_TENURE_NEXTYR ir3_GOT_TENURE_NEXTYR ir4_GOT_TENURE_NEXTYR  using "$tables/got_tenure_research_controls.tex", replace ///
title(Likelihood of Getting Tenure with research controls \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(fixr1 fixr2 fixr3 fixr4 ywtm N r2 r2_a df_m df_a df_r, fmt(%16s %16s %16s %16s a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Research Controls 1" "Research Controls 2" "Research Controls 3" "Research Controls 4" "Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Got Tenure" "Got Tenure" "Got Tenure" "Got Tenure" "Got Tenure" "Got Tenure" "Got Tenure") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "`condnote3'" "and t_TENURE_NEXTYR is greater than or equal to 5" "Fixed Effects: `fes'" "Standard Error: `standarderror'" "Weighted by `weight'." "Each research control variable incdicates different combinations of research controls interacted with PhD field group." "Includes only individuals who have INSTCOD.")
	

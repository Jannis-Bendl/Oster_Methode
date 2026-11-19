
********************************************************************************
*Tenure decision: Other outcomes ("Got Tenure" and all others)
********************************************************************************

use "$TEMP/tenuredecision_data", clear

est clear

*Individuals at ranked TT institutions only
foreach weight in WTSURVY  {
foreach dep in  GOT_TENURE_NEXTYR TENURE_ELSEWHERE TTNOTTEN_NEXTYR IND_NEXTYR GOV_NEXTYR EDUNTT_NEXTYR NW_NEXTYR  {
	
local cond if flag_decisionyr==1 & YR==maxdecisionyr & YR>=1997 & !missing(GOT_TENURE_NEXTYR) & t_GOT_TENURE_NEXTYR>=5 & !missing(FULLRANK)
local condnote1 if flag_decisionyr equals 1 and YR is greater than or equal to 1997 and not missing FULLRANK  and
local condnote2 YR equals maxdecisionyr and GOT_TENURE_NEXTYR is not missing and t_GOT_TENURE_NEXTYR is greater than or equal to 5 
local standarderror vce(cluster PHDPROGRAMYR)
local fes YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHDFIELDNEW
local covars edpar_n gender race_n

*With INSTCOD FE - without research controls
 reghdfe `dep' ib3.edpar_n gender ib5.race_n `cond' & INSTCOD_miss!=1 & t_TENURE_NEXTYR >= 5 [aw=`weight'] , absorb(`fes') `standarderror'
est sto i_`dep'_`weight'

		qui sum `dep' [aw=`weight'] if e(sample)
		qui estadd scalar ywtm=r(mean)
		
		// Check number of observations:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
		
}

estfe i_*, labels(YR "Survey Year FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" BIRTHCOUNTRY "Birth Country FE" INSTCOD "Institution FE")

esttab i_* using "$tables/tenure_full_outcomes_ranked.tex", replace ///
title(Likelihood of Position Next Year - Ranked Insitutions (Institution Controls)\label{tab2_tenure}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
mtitle("Tenure Similar or Higher Ranked" "Tenure Elsewhere" "Tenuretrack" "Industry" "Government" "Education" "Not Working") ///
	varwidth(2) ///
	addnote("Condition: `condnote1'" "`condnote2'" "and t_TENURE_NEXTYR is greater than or equal to 5 and not missing INSTCOD" "Fixed Effects: `fes'" "Standard Error: `standarderror'" "Weighted by `weight'." "Individuals only in ranked insitutions.")
}


est clear



*Individuals at non-ranked TT institutions only
foreach weight in WTSURVY  {
foreach dep in    TENURE_NEXTYR TTNOTTEN_NEXTYR IND_NEXTYR GOV_NEXTYR EDUNTT_NEXTYR NW_NEXTYR  {
	
local cond if flag_decisionyr==1 & YR==maxdecisionyr & YR>=1997 &  missing(FULLRANK)
local condnote1 if flag_decisionyr equals 1 and YR is greater than or equal to 1997 and not missing FULLRANK and
local condnote2 YR equals maxdecisionyr
local standarderror vce(cluster PHDPROGRAMYR)
local fes YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHDFIELDNEW
local covars edpar_n gender race_n

*With INSTCOD FE - without research controls
 reghdfe `dep' ib3.edpar_n gender ib5.race_n `cond' & INSTCOD_miss!=1 & t_TENURE_NEXTYR >= 5 [aw=`weight'] , absorb(`fes') `standarderror'
est sto i_`dep'_`weight'

		qui sum `dep' [aw=`weight'] if e(sample)
		qui estadd scalar ywtm=r(mean)
		
		// Check number of observations:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
		
}


estfe i_*_`weight', labels(YR "Survey Year FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" BIRTHCOUNTRY "Birth Country FE" INSTCOD "Institution FE")

esttab i_*_`weight' using "$tables/tenure_full_outcomes_nonranked.tex", replace ///
title(Likelihood of Position Next Year - Non-Ranked Insitutions (Institution Controls)\label{tab2_tenure}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
mtitle("Tenure" "Tenuretrack" "Industry" "Government" "Education" "Not Working") ///
	varwidth(2) ///
	addnote("Condition: `condnote1'" "`condnote2'" "and t_TENURE_NEXTYR is greater than or equal to 5 and not missing INSTCOD" "Fixed Effects: `fes'" "Standard Error: `standarderror'" "Weighted by `weight'." "Individuals only in non-ranked insitutions.")

}

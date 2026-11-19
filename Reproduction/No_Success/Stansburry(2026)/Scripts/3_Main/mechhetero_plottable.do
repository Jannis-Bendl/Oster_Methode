********************************************************************************
*Mechanisms: Role of preferences, choice, constraints - generate coefplot
********************************************************************************

********************************************************************************
*This code creates:
*mechhetero_full_coef.pdf
********************************************************************************

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

est clear

********************************************************************************
*Educational debt (upon PhD graduation)
*NOTE that this was only collected from 2000 onwards (check exact year in SED)
********************************************************************************
*Generate parental education variable specifically for this regression for the full figure
g debt_edpar = edpar_n

local depvarlist TENURE TEN_R1 TENLOGRANK
foreach dep of local depvarlist{
	
local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 & !missing(ugdebttot)
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 and LOCATIONUS equals 1 and not missing ugdebttot
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

*baseline with sample where there is debt information
qui reghdfe `dep' ib3.debt_edpar gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'_debt
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

		// Check number of observations for figure:
		di "Count of obs for `dep' for debt sample "
		 count if e(sample)
		 
		 // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
*with debt controls
qui reghdfe `dep' ib3.debt_edpar gender ib5.race_n ugdebttot_tenthou ugdebttot_tenthousq `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto d_`dep'_`weight'_debt
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

		// Check number of observations for figure:
		 di "Count of obs for `dep' for debt sample w controls"
		 count if e(sample)	 
		 
		  // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
}


estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

********************************************************************************
*Distance of current institution from high school state 
********************************************************************************
*Generate parental education variable specifically for this regression for the full figure
g dist_edpar = edpar_n

local depvarlist TENURE TEN_R1 TENLOGRANK
foreach dep of local depvarlist {

local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 & !missing(HSCURRCITY_DIST)
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 and LOCATIONUS equals 1 and not missing HSCURRCITY_DIST
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars dist_edpar	 gender race_n

*With distance information
qui reghdfe `dep' ib3.dist_edpar gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_`weight'_dist
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations:
		di "Count of obs for `dep' for distance sample "
		 count if e(sample)
		 
		 
		  // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	

*With distance controls
qui reghdfe `dep' ib3.dist_edpar gender ib5.race_n `controls' HSCURRCITY_DIST HSCURRCITY_DIST_sq HSCURRCITY_DIST_cube `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto d_`dep'_`weight'_dist
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' for distance sample w controls "
		 count if e(sample)
		 
 // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
}

estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")
	
********************************************************************************
*With and without children
********************************************************************************
*Generate parental education variable specifically for this regression for the full figure
g kid_edpar = edpar_n

local depvarlist TENURE TEN_R1 TENLOGRANK 
foreach dep of local depvarlist{

local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than
local condnote2 40 and LFSTAT equals 1 and LOCATIONUS equals 1
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars kid_edpar	gender race_n


*With children
qui reghdfe `dep' ib3.kid_edpar gender ib5.race_n `controls' `cond' & child_ever==1 [aw=`weight'], absorb(`fes') vce(`se')
	est sto u_`dep'_`weight'_kid
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' with kids "
		 count if e(sample)
		 
		 // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	

*Without children
qui reghdfe `dep' ib3.kid_edpar gender ib5.race_n `controls' `cond' & child_ever==0 [aw=`weight'], absorb(`fes') vce(`se')
	est sto f_`dep'_`weight'_kid
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' without kids "
		 count if e(sample)
		 
		   // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
	
	
}

estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")


********************************************************************************
*Rank of PHD institution: above vs below thirty
*note that the RELATIVE gaps (relative to dep var mean) are similar
********************************************************************************
*Generate parental education variable specifically for this regression for the full figure
g rank_edpar = edpar_n

local depvarlist TENURE TEN_R1 TENLOGRANK
foreach dep of local depvarlist{

local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and LFSTAT
local condnote2 equals 1 and LOCATIONUS equals 1
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars rank_edpar gender race_n

*Rank less than or equal to 30 
qui reghdfe `dep' ib3.rank_edpar gender ib5.race_n `controls' `cond' & PHDRANK<=30 [aw=`weight'], absorb(`fes') vce(`se')
	est sto u_`dep'_`weight'_rank
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' rank under 30 "
		 count if e(sample)
		 
	 // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}

*Rank more than 30
qui reghdfe `dep' ib3.rank_edpar gender ib5.race_n `controls' `cond' & PHDRANK>=30 & !missing(PHDRANK) [aw=`weight'], absorb(`fes') vce(`se')
	est sto f_`dep'_`weight'_rank
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' rank over 30 "
		 count if e(sample)
		 
		 
	 // Check number of observations for table:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}
}

estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

********************************************************************************
*PHD group (very broad field of study)
*Suggestively biggest gaps in social sciences, but not by much and likely not statistically significantly different
********************************************************************************
*Generate parental education variable specifically for this regression for the full figure
g group_edpar = edpar_n

levelsof PHD_GROUP, local(phdgroups) 
local depvarlist TENURE TEN_R1 TENLOGRANK

foreach p of local phdgroups {
foreach dep of local depvarlist{

local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 & PHD_GROUP==`p'
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than
local condnote2 40 and LFSTAT equals 1 and LOCATIONUS equals 1 and PHD_GROUP equals `p'
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars group_edpar race_n gender

qui reghdfe `dep' ib3.group_edpar gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e`p'_`dep'_`weight'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations for figure:
		di "Count of obs for `dep' PHD Group "
		 count if e(sample)
		 
	 // Check number of observations for table:
		foreach var of local covars {			
			di "`p': `dep' and `var' Samples:"
			tab `var' if e(sample)
		}	 
		 
	}
}
	
estfe *, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

********************************************************************************
*COEFPLOT OF ALL MECHANISMS FROM REGRESSIONS ABOVE
********************************************************************************
*Generate plots separately by dependent variables, then merge together

*Tenure
coefplot  ///
	(e_TENURE_WTSURVY_debt, mcolor(red) msymbol(O) ciopts(color(red)) label(Debt Sample)) ///
	(d_TENURE_WTSURVY_debt, mcolor(red%50) msymbol(D) ciopts(color(red%50) lpattern(dash)) label(Debt Controls)) ///
	(e_TENURE_WTSURVY_dist, mcolor(orange) msymbol(O) ciopts(color(orange)) label(Distance Sample)) ///
	(d_TENURE_WTSURVY_dist, mcolor(orange%50) msymbol(D) ciopts(color(orange%50) lpattern(dash)) label(Distance Controls)) ///
	(u_TENURE_WTSURVY_kid, mcolor(blue) msymbol(O) ciopts(color(blue)) label(With Children)) ///
	(f_TENURE_WTSURVY_kid, mcolor(blue%50) msymbol(D) ciopts(color(blue%50) lpattern(dash)) label(Without Children)) ///
	(u_TENURE_WTSURVY_rank, mcolor(green) msymbol(O) ciopts(color(green)) label(PhD Rank <=30)) ///
	(f_TENURE_WTSURVY_rank, mcolor(green%50) msymbol(D) ciopts(color(green%50) lpattern(dash)) label(PhD Rank >30)) ///
	(e1_TENURE_WTSURVY, mcolor(purple) msymbol(O) ciopts(color(purple)) label(Agr Sciences/Bio Sciences/Health)) ///
	(e2_TENURE_WTSURVY, mcolor(purple%50) msymbol(D) ciopts(color(purple%50) lpattern(dash)) label(Comp Sciences/Phys Sciences/Math/Engineering)) ///
	(e3_TENURE_WTSURVY, mcolor(purple%25) msymbol(T) ciopts(color(purple%25) lpattern(dash_dot)) label(Social Sciences)) ///
	, keep(*1.*edpar) xline(0) ///
	fxsize(50)  ///
	legend(off) ///
	name(tenure, replace) ///
	subtitle(Tenure, nobox bcolor(white) bexpand size(medsmall)) coeflabels(1.debt_edpar = "Debt" 1.dist_edpar = "Distance" 1.kid_edpar = "Children" 1.rank_edpar = "PhD Rank" 1.group_edpar = "PhD Field")
	graph export "$figures/mechhetero_tenure.pdf", replace 

*Tenure R1
coefplot  ///
	(e_TEN_R1_WTSURVY_debt, mcolor(red) msymbol(O) ciopts(color(red)) label(Debt Sample)) ///
	(d_TEN_R1_WTSURVY_debt, mcolor(red%50) msymbol(D) ciopts(color(red%50) lpattern(dash)) label(Debt Controls)) ///
	(e_TEN_R1_WTSURVY_dist, mcolor(orange) msymbol(O) ciopts(color(orange)) label(Distance Sample)) ///
	(d_TEN_R1_WTSURVY_dist, mcolor(orange%50) msymbol(D) ciopts(color(orange%50) lpattern(dash)) label(Distance Controls)) ///
	(u_TEN_R1_WTSURVY_kid, mcolor(blue) msymbol(O) ciopts(color(blue)) label(With Children)) ///
	(f_TEN_R1_WTSURVY_kid, mcolor(blue%50) msymbol(D) ciopts(color(blue%50) lpattern(dash)) label(Without Children)) ///
	(u_TEN_R1_WTSURVY_rank, mcolor(green) msymbol(O) ciopts(color(green)) label(PhD Rank <=30)) ///
	(f_TEN_R1_WTSURVY_rank, mcolor(green%50) msymbol(D) ciopts(color(green%50) lpattern(dash)) label(PhD Rank >30)) ///
	(e1_TEN_R1_WTSURVY, mcolor(purple) msymbol(O) ciopts(color(purple)) label(Agr Sciences/Bio Sciences/Health)) ///
	(e2_TEN_R1_WTSURVY, mcolor(purple%50) msymbol(D) ciopts(color(purple%50) lpattern(dash)) label(Comp Sciences/Phys Sciences/Math/Engineering)) ///
	(e3_TEN_R1_WTSURVY, mcolor(purple%25) msymbol(T) ciopts(color(purple%25) lpattern(dash_dot)) label(Social Sciences)) ///
	, keep(*1.*edpar) xline(0) yscale(off) ///
	fxsize(50)  ///
	legend(off) ///
	name(r1, replace) ///
	subtitle(R1, nobox bcolor(white)  bexpand size(medsmall))
graph export "$figures/mechhetero_R1.pdf", replace 
	
*Log Rank
coefplot  ///
	(e_TENLOGRANK_WTSURVY_debt, mcolor(red) msymbol(O) ciopts(color(red)) label(Debt Sample)) ///
	(d_TENLOGRANK_WTSURVY_debt, mcolor(red%50) msymbol(D) ciopts(color(red%50) lpattern(dash)) label(Debt Controls)) ///
	(e_TENLOGRANK_WTSURVY_dist, mcolor(orange) msymbol(O) ciopts(color(orange)) label(Distance Sample)) ///
	(d_TENLOGRANK_WTSURVY_dist, mcolor(orange%50) msymbol(D) ciopts(color(orange%50) lpattern(dash)) label(Distance Controls)) ///
	(u_TENLOGRANK_WTSURVY_kid, mcolor(blue) msymbol(O) ciopts(color(blue)) label(With Children)) ///
	(f_TENLOGRANK_WTSURVY_kid, mcolor(blue%50) msymbol(D) ciopts(color(blue%50) lpattern(dash)) label(Without Children)) ///
	(u_TENLOGRANK_WTSURVY_rank, mcolor(green) msymbol(O) ciopts(color(green)) label(PhD Rank <=30)) ///
	(f_TENLOGRANK_WTSURVY_rank, mcolor(green%50) msymbol(D) ciopts(color(green%50) lpattern(dash)) label(PhD Rank >30)) ///
	(e1_TENLOGRANK_WTSURVY, mcolor(purple) msymbol(O) ciopts(color(purple)) label(Agr Sciences/Bio Sciences/Health)) ///
	(e2_TENLOGRANK_WTSURVY, mcolor(purple%50) msymbol(D) ciopts(color(purple%50) lpattern(dash)) label(Comp Sciences/Phys Sciences/Math/Engineering)) ///
	(e3_TENLOGRANK_WTSURVY, mcolor(purple%25) msymbol(T) ciopts(color(purple%25) lpattern(dash_dot)) label(Social Sciences)) ///
	, keep(*1.*edpar) xline(0) yscale(off) ///
	legend(pos(3) col(1) stack ring(1)) //////
	name(logranklegend, replace) ///
	subtitle(Log Rank, nobox bcolor(white)  bexpand size(medsmall)) coeflabels(1.debt_edpar = "Debt" 1.dist_edpar = "Distance" 1.kid_edpar = "Children" 1.rank_edpar = "PhD Rank" 1.group_edpar = "PhD Field")
	graph export "$figures/mechhetero_rank.pdf", replace 

	
*Drop saved sub figures
graph drop tenure r1 logranklegend


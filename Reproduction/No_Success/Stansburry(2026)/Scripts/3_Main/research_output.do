**************************************************************************
*Gaps in research output by parental education
**************************************************************************

********************************************************************************
*This code creates:
* research_gap_WTSURVY.tex
********************************************************************************

*Load data
use "$TEMP/tenure_withpubs_data", clear

est clear

**************************************************************************
*Actual research output of tenured profs - is there a class gap?
*Conditional on PhD institution etc (same FEs as Table 1)
**************************************************************************

egen INSTFIELDYR = group(INSTCOD PHDFIELDNEW YR)

*Calculate sample sizes for export request
foreach var in edpar_n gender race_n {
tab `var' if TENURE==1 & LOCATIONUS==1  & !missing(PHDINST) & !missing(BIRTHCON) & !missing(avg_impactfactor_rn)
}

*Generate research controls local
local researchdeps pubs_rn pubs_firstauthor_rn pubs_lastauthor_rn avg_CNCI_rn  avg_impactfactor_rn NSFBucket pubs_top10cnci_sh pubs_hij_sh avg_authors_rn

est clear

*Regress these research vars on parental education
foreach dep of local researchdeps {
local weight WTSURVY
local cond  
local se cluster PHDPROGRAMYR
local fes YR PHDCY5y years_since_phd5y PHDINST PHDFIELDNEW BIRTHCOUNTRY 
local controls 
local covars edpar_n gender race_n

	reghdfe `dep' ib3.edpar_n gender ib5.race_n  `controls' `cond' [aw=`weight'] , absorb(`fes' ) vce(`se') 
	est sto `dep'_`weight'
	quietly summarize `dep' [aw=`weight'] if e(sample)
	estadd scalar ywtm=r(mean)
	
		// Check number of observations:
		foreach var of local covars {			
			di "`dep' and `var' Samples:"
			tab `var' if e(sample)
		}

	
regsave using "$TEMP/e_`dep'_`weight'", replace detail(all) /*Save regression output for later figure*/

}
	
local weight WTSURVY
local se robust
local fes YR PHDCY5y years_since_phd5y PHDINST PHDFIELDNEW BIRTHCON
local controls 

estfe pubs_rn_WTSURVY pubs_firstauthor_rn_WTSURVY pubs_lastauthor_rn_WTSURVY avg_CNCI_rn_WTSURVY avg_impactfactor_rn_WTSURVY NSFBucket_WTSURVY pubs_top10cnci_sh_WTSURVY pubs_hij_sh_WTSURVY avg_authors_rn_WTSURVY, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCON "Birth Continent FE")

esttab pubs_rn_WTSURVY pubs_firstauthor_rn_WTSURVY pubs_lastauthor_rn_WTSURVY avg_CNCI_rn_WTSURVY avg_impactfactor_rn_WTSURVY NSFBucket_WTSURVY pubs_top10cnci_sh_WTSURVY pubs_hij_sh_WTSURVY avg_authors_rn_WTSURVY using "$tables/research_gap_WTSURVY.tex", replace ///
title(Research Output Gap of Tenured Professors\label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Publication Count" "First Author" "Last Author" "Average CNCI" "Avg Impact Factor" "NSF Award Bucket" "Top Ten CNCI" "High Impact" "Avg Authors") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: if YR is greater then or equal to 2015 and TENURE equals 1 and LOCATIONUS equals 1 and" "YR equals minTENYR and merged with both NSF and publication-level data." "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "The regressions in this table investigate the research output gap on various research output measures by parental education." "Publication Count is the percentile of the raw number of publications." "First Author is the percentile of the number of first authored publications." "Last Author is the percentile of the number of last authored publications." "Average CNCI is the percentile of an average measure of normalized citation counts (normalized to the field, journal, etc.)" "Avg Impact Factor is the percentile of the average impact factor of publications." "NSF Award Bucket is a categorical variable that separates number of NSF awards in to 0, 1, 2 or 3, and greater than 4." "Top Ten CNCI is the share of top 10 percentile CNCI publications." "High Impact is the share of publications in high impact journals." "Avg Authors is the percentile of the average number of authors per publication.")



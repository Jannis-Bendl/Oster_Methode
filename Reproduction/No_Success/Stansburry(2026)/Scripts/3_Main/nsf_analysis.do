********************************************************************************
*NSF Award Analysis conditional on publications
********************************************************************************




*Decide whether to use INSTBYFIELD or INSTCOD AND PHDFIELDNEW FEs separately

********************************************************************************
*This code creates:
*NSFawards_research_NSFAwards1620_WTSURVY, ///
 NSFawards_research_woCAT_NSFAwards1620_WTSURVY, ///
 NSFawards_research_woCAT_NSFAwards1620_bin_WTSURVY
********************************************************************************

*Load clean data
use "$DATA/sdrdrf_9321_working", clear

egen INSTFIELDYR = group(INSTCOD PHDFIELDNEW YR)


keep if LOCATIONUS==1 /*only keep individuals based in the US*/
keep if YR==2015


**************************************************
*Generate cumulative pubs up to relevant year
**************************************************
preserve 

keep REFID YR
merge 1:m REFID using "$DATA/newwos_withrefid"
keep if _m==3

keep if PUB_YEAR<=YR

	*Sum publications, high impact publications, etc, up to 2015

*total publications
	bysort REFID YR: egen pubs = count(pub_randid)
	*pubs from 1997 onwards (those that are eligible for impact factor calc)
	gen post97 = 1 if PUB_YEAR>=1997
	bysort REFID YR : egen pubs_post97 = total(post97)
	*articles and reviews
	gen ar = 1 if PUB_TYPE=="Article"  | PUB_TYPE=="Review"
	bysort REFID YR : egen pubs_ar = total(ar)
	*pubs in high impact journals /*1997 publications onwards*/
	bysort REFID YR : egen pubs_hij = total(PUB_HIGHIMPACTJOURNAL_BIN)
	*pubs in low impact journals /*1997 publications onwards*/
	bysort REFID YR : egen pubs_lij = total(PUB_LOWIMPACTJOURNAL_BIN)
	*pubs in top 10 percent CNCI
	gen top10cnci = 1 if AVG_PCT>=90 & AVG_PCT<=100
	bysort REFID YR : egen pubs_top10cnci = total(top10cnci)
	*average impact factor of publications /*1997 publications onwards*/
	/*Note that about 20% of publications in any given year are missing impact factor - this means that the journal wasn't selected for the impact factor reports by Clarivate. We give them zero and a missing flag*/
	replace PUB_JCR_IMPACTFACTOR = 0 if missing(PUB_JCR_IMPACTFACTOR) & PUB_YEAR>=1997
	bysort REFID YR : egen avg_impactfactor = mean(PUB_JCR_IMPACTFACTOR)
	gen miss = 1 if missing(PUB_JCR_IMPACTFACTOR) & PUB_YEAR>=1997
	bysort REFID YR : egen pubs_post97_missif = total(miss)
	*average authors per publication
	bysort REFID YR : egen avg_authors = mean(PUB_NUM_AUTHORS)
	*effective publications (pubs/authors)
	gen oneover_authors = 1/PUB_NUM_AUTHORS
	bysort REFID YR: egen effective_pubs = total(oneover_authors)
	bysort REFID YR: egen effective_pubs_ar = total(cond(PUB_TYPE=="Article"  | PUB_TYPE=="Review"),oneover_authors,.)
	bysort REFID YR: egen effective_pubs_hij = total(cond(top10cnci==1),oneover_authors,.)
	bysort REFID YR: egen effective_pubs_top10cnci = total(cond(PUB_HIGHIMPACTJOURNAL_BIN==1),oneover_authors,.)
	*average first 5 year citations per publication
	bysort REFID YR : egen avg_cites_y5 = mean(PUB_CITES_Y5)
	bysort REFID YR : egen avg_cites_hij_y5 = mean(PUB_CITES_Y5_HIJ)
	*Average CNCI and CNCI percentile per publication
	bysort REFID YR : egen avg_CNCI = mean(CNCI)
	bysort REFID YR : egen avg_CNCI_pct = mean(AVG_PCT)
	*first author pubs
	gen firstauthor = 1 if AUTHOR_POS==1
	bysort REFID YR : egen pubs_firstauthor = total(firstauthor)
	*last author pubs
	gen lastauthor = 1 if AUTHOR_POS ==PUB_NUM_AUTHORS
	bysort REFID YR : egen pubs_lastauthor = total(lastauthor)
	*solo author pubs
	gen soloauthor = 1 if PUB_NUM_AUTHORS==1
	bysort REFID YR : egen pubs_soloauthor = total(soloauthor)
	
	keep REFID YR pubs* avg* effective*
	duplicates drop

	save "$TEMP/pre2015_pubs", replace

	restore
	
**************************************************
*Generate NSF Awards up to relevant year
**************************************************
preserve 

keep REFID YR
merge 1:m REFID using "$DATA/nsf_data_cleaned"


	
	*Keep only awards from before the observation year 
	keep if AwardEffectiveYear<=YR
	
	*total awards
	bysort REFID YR: egen NSFAwards = count(AwardID)
	*value of awards
	bysort REFID YR: egen NSFAwardValue = total(TotalIntendedAmount)
	
	keep REFID YR NSFAwards NSFAwardValue
	duplicates drop
	
	save "$TEMP/pre2015_NSF", replace

restore	


**************************************************
*Generate NSF Awards 2016-2020
**************************************************
preserve 

keep REFID YR
merge 1:m REFID using "$DATA/nsf_data_cleaned"


	
	*Keep only awards from before the observation year 
	keep if AwardEffectiveYear>=2016 & AwardEffectiveYear<=2020
	
	*total awards
	bysort REFID YR: egen NSFAwards1620 = count(AwardID)
	
	keep REFID YR NSFAwards1620
	duplicates drop
	
	save "$TEMP/bet2016_20_NSF", replace

restore	

********************************************************************************
*Match with cumulative pubs up to 2015
********************************************************************************
merge 1:1 REFID YR using "$TEMP/pre2015_pubs", gen(_m_pre2015_pubs) 
merge 1:1 REFID YR using "$TEMP/pre2015_nsf", gen(_m_pre2015_nsf) 
merge 1:1 REFID YR using "$TEMP/bet2016_20_NSF", gen(_m_bet2016_20_NSF) 

keep if _m_pre2015_pubs==3 



cap drop INSTBYFIELD 
egen INSTBYFIELD = group(INSTCOD PHDFIELDNEW)
***************************************
*Generate research controls
***************************************

gen pubs_nonhij = pubs-pubs_hij
gen effective_pubs_nonhij = effective_pubs - effective_pubs_hij

foreach var in  pubs pubs_post97 pubs_ar pubs_hij pubs_lij pubs_top10cnci pubs_firstauthor pubs_lastauthor pubs_soloauthor  avg_CNCI avg_cites_y5 avg_cites_hij_y5 effective_pubs effective_pubs_ar effective_pubs_hij effective_pubs_top10cnci effective_pubs_nonhij{
	gen log_`var' = ln(`var')
	gen `var'_sq = `var'^2
}
foreach var in pubs_top10cnci pubs_firstauthor pubs_lastauthor pubs_soloauthor {
	gen `var'_sh = `var'/pubs
}
foreach var in pubs_hij pubs_lij {
	gen `var'_sh = `var'/pubs_post97
	replace `var'_sh = 0 if pubs_post97==0
}

replace NSFAwards1620 = 0 if missing(NSFAwards1620)
replace NSFAwards = 0 if missing(NSFAwards)
gen NSFAwards_sq = NSFAwards^2
replace NSFAwardValue = 0 if missing(NSFAwardValue)
gen lnNSFAwardValue = ln(NSFAwardValue)
gen NSFAwardValue_sq = NSFAwardValue^2
gen NoNSF = (NSFAwards1620==0)
gen NSFBucket = 0 if NSFAwards==0
replace NSFBucket = 1 if NSFAwards==1
replace NSFBucket = 2 if NSFAwards>=2 & NSFAwards<=3
replace NSFBucket = 3 if NSFAwards>=4 & !missing(NSFAwards)

*Decile of pub variable by PhD Cat (_d)
*Percentile of pub variable by PhD Cat (_rn)
foreach var in pubs_top10cnci_sh pubs_ar pubs_firstauthor_sh pubs_lastauthor_sh pubs_hij_sh  avg_authors pubs pubs_hij pubs_top10cnci pubs_firstauthor pubs_lastauthor avg_CNCI  effective_pubs effective_pubs_ar effective_pubs_hij effective_pubs_top10cnci effective_pubs_nonhij avg_impactfactor  {
	egen `var'_d = xtile(`var'), by(phd_cat) nq(10)
	bys phd_cat: egen `var'_r = rank(`var')
	bys phd_cat: egen `var'_rd = count(`var')
	gen `var'_rn = `var'_r/`var'_rd
}

replace NSFAwards1620=0 if missing(NSFAwards1620)

**************************************************************************
*Local macros for each research output measure interacted with broad field 

**NOTE: RESEARCH CONTROLS 1 AND 4 CORRESPOND TO RESEARCH CONTROLS 1 AND 2 IN THE PAPER
**************************************************************************
local research1 c.pubs_rn##c.pubs_rn##i.PHD_GROUP c.avg_CNCI_rn##c.avg_CNCI_rn##i.PHD_GROUP c.avg_authors_rn##c.avg_authors_rn##i.PHD_GROUP c.avg_impactfactor_rn##c.avg_impactfactor_rn##i.PHD_GROUP 
local research2 `research1' c.pubs_firstauthor_rn##c.pubs_firstauthor_rn##i.PHD_GROUP   c.pubs_lastauthor_rn##c.pubs_lastauthor_rn##i.PHD_GROUP
local research3 `research2'   c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP
local research4  `research3'  i.NSFBucket##i.PHD_GROUP 

******************************************************************************************
*Does parental education predict NSF award receipt? Binary dep var: if individual had ANY NSF awards 2016-2020
******************************************************************************************
*Generate binary dep var
cap drop NSFAwards1620_bin
g NSFAwards1620_bin = 0 if NSFAwards1620==0
replace NSFAwards1620_bin = 1 if NSFAwards1620>=1

*Version with binary
foreach weight in  WTSURVY {
foreach dep in NSFAwards1620_bin {
local cond if INSTCOD_miss!=1 & LOCATIONUS==1 & (TENURETRACK==1 | TENURE==1) & PHD_CAT!="Economics" & PHD_CAT!="Health"
local condnote1 if YR is equal to 2015 and LOCATIONUS equals 1 and TENURETRACK or TENURE equals 1 and PHD_CAT is not Economics or Health
local condnote2 and INSTCOD_miss does not equal 1. Merged with both NSF and publication-level data.
local se cluster INSTFIELDYR
local fes PHDCY5y years_since_phd5y PHDINST BIRTHCOUNTRY INSTBYFIELD TENSTA
local controls 
local covars edpar_n gender race_n


*No research controls 
reghdfe `dep' ib3.edpar_n gender ib5.race_n  `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto `dep'r0_`weight'
				qui sum `dep' [aw=`weight'] if e(sample)
				qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr3 "No", replace
				qui estadd local fixr4 "No", replace 
				
			
	// Check number of observations:
	foreach var of local covars {			
			di "`dep' and `var' Samples (no research controls):"
			tab `var' if e(sample)
		}
			
*Loop over research controls 

foreach i in 1 3 4  {
capture drop r_`dep'
 qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `research`i'' `controls' `cond'  [aw=`weight'], absorb(`fes' ) vce(`se') 
est sto `dep'r`i'_`weight'
				qui sum `dep' [aw=`weight'] if e(sample)
				qui estadd scalar ywtm=r(mean)
				qui estadd local fixr1 "No", replace 
				qui estadd local fixr3 "No", replace
				qui estadd local fixr4 "No", replace 
				qui estadd local fixr`i' "Yes", replace 
				
				
		// Check number of observations:
	foreach var of local covars {	
			di "`dep' and `var' and research`i' Samples:"
			tab `var' if e(sample) 
		}
							
}

*Tables for export
estfe `dep'r0_`weight' `dep'r1_`weight' `dep'r3_`weight' `dep'r4_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" BIRTHCOUNTRY "Birth Country FE" INSTCOD "Current Institution FE" TENSTA "Tenure Status FE" INSTBYFIELD "Institution X Field FE")

esttab `dep'r0_`weight' `dep'r1_`weight' `dep'r3_`weight' `dep'r4_`weight' using "$tables/NSFawards_research_woCAT_`dep'_`weight'.tex", replace ///
title(NSF Award Binary 2016-2020 with Research Controls \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(fixr1 fixr3 fixr4 ywtm N r2 r2_a df_m df_a df_r, fmt(%16s %16s %16s a2 %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Baseline Research Controls" "Full Research Controls" "Full RC + Prior NSF Awards" "Dep Var Mean" "Observations" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mlabels("2016-2020 NSF Award Binary" "2016-2020 NSF Award Binary" "2016-2020 NSF Award Binary"  "2016-2020 NSF Award Binary") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'.")

}
}

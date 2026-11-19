********************************************************************************
*Create data for tenure institution rank regressions with research controls
********************************************************************************

********************************************************************************
*This code creates:
*tenure_withpubs_data.dta
********************************************************************************

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

*Keep one observation for each person that we observe with tenure who also appear in 2015: 2015 if they are tenured in 2015; 2017 if they are not tenured in 2015 but are tenured in 2017; 2019 or 2021 if they are not tenured in 2015 or 2017 but tenured in 2019 or 2021. This is to give us the biggest possible sample of tenured academics for whom we can observe publications
keep if TENURE==1 & LOCATIONUS==1 /*only keep individuals based in the US*/
keep if YR>=2015
bys REFID: egen minTENYR = min(cond(TENURE==1,YR,.))
keep if YR==minTENYR /*Keep only if tenured in 2015 or later*/


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
	
	save "$TEMP/pre2015_nsf", replace

restore	
	
********************************************************************************
*Match with cumulative pubs up to 2015 or first tenured year in data (if post 2015)
********************************************************************************
merge 1:1 REFID YR using "$TEMP/pre2015_pubs", gen(_m_pre2015_pubs) 
merge 1:1 REFID YR using "$TEMP/pre2015_nsf", gen(_m_pre2015_nsf) 
keep if _m_pre2015_pubs==3 


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

replace NSFAwards = 0 if missing(NSFAwards)
gen NSFAwards_sq = NSFAwards^2
replace NSFAwardValue = 0 if missing(NSFAwardValue)
gen lnNSFAwardValue = ln(NSFAwardValue)
gen NSFAwardValue_sq = NSFAwardValue^2
gen NoNSF = (NSFAwards==0)
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


save "$TEMP/tenure_withpubs_data", replace

********************************************************************************
*Citations Conditional on Publication
*Do lower-SES academics receive fewer citations for publications in the same journal?
********************************************************************************

********************************************************************************
*This code creates:
*citations_baseline.tex, ///
 citations_robust.tex
********************************************************************************

*Load SDR
use "$DATA/sdrdrf_9321_working", clear

********************************************************************************
*Publication level Analysis
********************************************************************************
*Keep only 2015 SDR (to match into WOS publication data)
keep if YR==2015

*Keep only certain variables to avoid creating very large dataset
keep REFID WTSURVY PHDCY PHDCY5y PHDFIELD PHDFIELDNEW years_since_phd years_since_phd5y TENURETRACK TENURE edpar_n gender race_n BIRTHCOUNTRY BIRTHCON PHDINST INSTCOD INSTCOD_miss PHD_CAT LOCATIONUS

*Merge with publication level data
merge 1:m REFID using "$DATA/newwos_withrefid", force
*The REFIDs from using which don't match were improperly formatted in scientific notation in the file we received from NSF - we have reached out to them to give us an updated version
drop if _merge==2

*Generate new citation variables
gen lnPUB_CITES_Y5 = ln(PUB_CITES_Y5)
gen ln1PUB_CITES_Y5 = ln(1+PUB_CITES_Y5) /*log of 1+var to include zeroes*/
gen lnPUB_CITES_Y5_HIJ = ln(PUB_CITES_Y5_HIJ)
gen ln1PUB_CITES_Y5_HIJ = ln(1+PUB_CITES_Y5_HIJ)
gen lnCNCI = ln(CNCI)
gen ln1CNCI = ln(1+100*CNCI)
gen anycites = 1 if PUB_CITES_Y5>=1 & !missing(PUB_CITES_Y5)
replace anycites = 0 if PUB_CITES_Y5==0 & !missing(PUB_CITES_Y5)

*Generate deciles for publication impact factor in each broad field
egen PUB_JCR_IMPACTFACTOR_d = xtile(PUB_JCR_IMPACTFACTOR), n(10) by(PHD_CAT)

*Generate buckets for number of authors
gen PUB_NUM_AUTHORS_b = PUB_NUM_AUTHORS
replace PUB_NUM_AUTHORS_b = 5 if PUB_NUM_AUTHORS>=5 & PUB_NUM_AUTHORS<10
replace PUB_NUM_AUTHORS_b = 10 if PUB_NUM_AUTHORS>=10 & PUB_NUM_AUTHORS<20
replace PUB_NUM_AUTHORS_b = 20 if PUB_NUM_AUTHORS>=20 & PUB_NUM_AUTHORS<50
replace PUB_NUM_AUTHORS_b = 50 if PUB_NUM_AUTHORS>=50

*Generate years since phd that the paper was published
gen SENIORITY = PUB_YEAR - PHDCY
gen SENIORITY5y = floor(SENIORITY/5)*5
 
*Generate fixed effects for each research output measure interacted with broad field
foreach var in PUB_YEAR PUB_TYPE  PUB_JCR_IMPACTFACTOR_d PUB_HIGHIMPACTJOURNAL PUB_LOWIMPACTJOURNAL PHDINST INSTCOD SENIORITY5y  PUB_NUM_AUTHORS_b   {
egen `var'_BYCAT = group(`var' PHD_CAT)
	}

********************************************************************************
*Predict first-five-year citations by publication year, field, impact factor of journal
********************************************************************************

*Restrict only to articles and reviews
gen PUB_JCR_IMPACTFACTORsq = PUB_JCR_IMPACTFACTOR^2
gen PUB_JCR_IMPACTFACTORcu = PUB_JCR_IMPACTFACTOR^3

*Sample size for regression
preserve 
foreach var in PUB_YEAR PUB_TYPE PUB_HIGHIMPACTJOURNAL PUB_LOWIMPACTJOURNAL PUB_NUM_AUTHORS_b PUB_JCR_IMPACTFACTOR gender race_n SENIORITY5y BIRTHCON {
	drop if missing(`var')
}

*Restrict to those who are on the tenuretrack, in the US, and have full publication data
keep if TENURETRACK==1 & LOCATIONUS==1 & PUB_YEAR>=1997 & INSTCOD_miss!=1 & (PUB_TYPE=="Article"|PUB_TYPE=="Review")
bys REFID: gen tag_REFID = 1 if _n==1
tab edpar_n if tag_REFID==1
restore

egen PHDPROGRAMYR = group(PHDINST PHDFIELDNEW PHDCY)

**Regression
est clear 
local researchvars PUB_YEAR PUB_HIGHIMPACTJOURNAL PUB_LOWIMPACTJOURNAL PUB_NUM_AUTHORS_b  PUB_JCR_RESEARCHFIELD_A PUB_JCR_IMPACTFACTOR_d_BYCAT PUB_TYPE
di "`researchvars'"
su `researchvars'

foreach weight in WTSURVY  {
foreach dep in anycites lnPUB_CITES_Y5 ln1PUB_CITES_Y5 lnCNCI ln1CNCI {  

local controls 
local cond `controls' if TENURETRACK==1 & LOCATIONUS==1 & PUB_YEAR>=1997 & INSTCOD_miss!=1 & (PUB_TYPE=="Article"|PUB_TYPE=="Review")
local condnote1 TENURETRACK equals 1 and LOCATIONUS equals 1 and PUB_YEAR is greater than or equal to 1997 
local condnote2 and INSTCOD_miss does not equal 1 and PUB_TYPE equals Article or Review
local fes `researchvars' BIRTHCOUNTRY SENIORITY5y  PHDINST PHDFIELDNEW INSTCOD
local fes_note1 `researchvars'  
local fes_note2 BIRTHCOUNTRY SENIORITY5y INSTCOD PHDINST PHDFIELDNEW 
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n


	reghdfe `dep' ib3.edpar_n  gender ib5.race_n `cond' [aw=`weight'] , absorb(`fes' ) vce(`se') residuals
	est sto e`dep'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)

	
	//Check number of observations:
		 foreach var of local covars {                   
		 	di "`dep' and `var'"
			tab `var' if e(sample)
			}

}
}

esttab e* using "$tables/citations_baseline.tex", replace ///
title(Citations per publication) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* gender *race_n* ) ///
s(ywtm N N_clust1 r2 r2_a  df_a , fmt(a2 %15.0gc %15.0gc a2 a2  %15.0gc ) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared"  "Absorbed Degrees of Freedom" )) indicate(`r(indicate_fe)')  ///
	mtitle("Any Cites" "(Log Cites(5y))" "Log(1+Cites(5y))" "Log(CNCI)" "Log(1+CNCI)") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2' and YR equals 2015" "Fixed Effects: `fes_note1'"  "`fes_note2'" "Controls: `controls'" "Standard Error: `se'" "Weighted by `weight'.")

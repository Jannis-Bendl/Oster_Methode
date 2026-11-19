**************************************************************************
*Predicting Rank Using Research Controls
*Where, specifically, is the "underplacement" happening? Predicting rank using publications and examining residuals
**************************************************************************

********************************************************************************
*This code creates:
*rankbypub_resid.pdf 
********************************************************************************


*Load data
use "$TEMP/tenure_withpubs_data", clear

est clear

*******************************************************************************
*Predict rank using research output
*******************************************************************************

*Generate research controls
local research1 c.pubs_rn##c.pubs_rn##i.PHD_GROUP c.avg_CNCI_rn##c.avg_CNCI_rn##i.PHD_GROUP c.avg_authors_rn##c.avg_authors_rn##i.PHD_GROUP c.avg_impactfactor_rn##c.avg_impactfactor_rn##i.PHD_GROUP 
local research2 `research1' c.pubs_firstauthor_rn##c.pubs_firstauthor_rn##i.PHD_GROUP   c.pubs_lastauthor_rn##c.pubs_lastauthor_rn##i.PHD_GROUP i.NSFBucket##i.PHD_GROUP  c.pubs_top10cnci_sh##i.PHD_GROUP c.pubs_hij_sh##i.PHD_GROUP

*Generate residuals of logrank on parental education
foreach weight in  WTSURVY {
local dep LOGRANK
local cond if !missing(FULLRANK)
local se robust
local fes YR PHDCY5y years_since_phd5y PHDINST PHDFIELDNEW BIRTHCOUNTRY
local controls 

reghdfe `dep' `controls' gender ib5.race_n `research2' `cond'  [aw=`weight'] , absorb(`fes' ) vce(`se') residuals
est sto `dep'_`weight'

}

*Predict these residuals
cap drop resid 
predict resid, r
cap drop xbd
predict xbd, xbd

*Plot residuals by parental education
twoway (kdensity resid if edpar_n==1  [aw=WTSURVY])  (kdensity resid if edpar_n==2  [aw=WTSURVY])  (kdensity resid if edpar_n==3  [aw=WTSURVY])  (kdensity resid if edpar_n==4  [aw=WTSURVY]) ///
	, legend(pos(6) cols(4) order(1 "No BA" 2 "BA" 3 "Non-PhD grad" 4 "PhD")) ///
	xtitle("Rank Residual") ///
	ytitle("Kernel density")
	
graph export "$figures/rankbypub_resid.pdf", replace

*Summarize residuals by parental education
bysort edpar_n: summ resid [aw=WTSURVY], d

*Residual less than -1 (VERY overplaced)
gen tag_minus1 = 1 if (resid<-1 & !missing(resid))
replace tag_minus1 = 0 if resid>=-1 & !missing(resid)
bys edpar_n: tab tag_minus1 [aw=WTSURVY]

*Residual less than -0.5 (SOMEWHAT overplaced)
gen tag_minuspoint5 = 1 if (resid<-0.5 & !missing(resid))
replace tag_minuspoint5 = 0 if resid>=-0.5 & !missing(resid)
bys edpar_n: tab tag_minuspoint5 [aw=WTSURVY]

*Residual less than 0 (overplaced)
gen tag_0 = 1 if (resid<0 & !missing(resid))
replace tag_0 = 0 if resid>=0 & !missing(resid)
bys edpar_n: tab tag_0 [aw=WTSURVY]

*Residual greater than 0.5 (SOMEWHAT underplaced)
gen tag_point5 = 1 if (resid>0.5 & !missing(resid))
replace tag_point5 = 0 if resid<=0.5 & !missing(resid)
bys edpar_n: tab tag_point5 [aw=WTSURVY]

* Count number of observations in the KD plot:
forvalues i = 1/4 {
	di  "edpar_n == `i'"
	count if edpar_n == `i' & !missing(resid) & !missing(WTSURVY)
}

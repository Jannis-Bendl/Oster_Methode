********************************************************************************
* 7.clean_seddrf_2021.do  — using synthetic builds
********************************************************************************

* Load SDR–DRF matched IDs (built in step 6)
use "$DATA/sdrdrfall9321_matched_ids.dta", clear

keep REFID DRF_ID DRF_ID_ORIG YR

* Identify REFIDs with multiple DRF_IDs across years/* Commented out in synthetic data as this doesnt occur for anyone
bys REFID DRF_ID: gen tag = (_n==1)
bys REFID: egen numDRFS = total(tag)
count if numDRFS!=1
keep if numDRFS!=1
drop numDRFS
*/

tab YR

* For those REFIDs, keep the most recent DRF_ID (by YR)
bys REFID: egen maxyrindata = max(YR)
keep if YR==maxyrindata
keep REFID DRF_ID
gen byte flag_multDRF = 1
save "$TEMP/refid_drfid_sdrdrf.dta", replace

********************************************************************************
* Merge SDR-derived IDs to 2021 SED-DRF; NOTE, this is slightly different than
* real code bc we also match on YR and remove the additional matches
********************************************************************************

* Load 2021 SED-DRF 
use "$DATA/seddrf_2021.dta", clear

*Merge with the merged SDR-DRF files, using DRF_ID: but noting that the match might be off for some
merge 1:m DRF_ID YR using "$DATA/sdrdrfall9321_matched_ids", gen(_m_ids) keep(2 3) force
*105 obs from the SDR DRF 9321 matched file don't match on DRF_ID

tab YR

/* Commented out in the synthetic version to simplify matching on fake REFIDs
merge m:1 REFID using "$TEMP/refid_drfid_sdrdrf", gen(_m_temp) update replace
*These ones were given the more recent DRF_ID, for people that had multiple - merge on those: now, 69 remain unmatched, representing 32 distinct REFIDs

merge m:1 DRF_ID using "$DATA/seddrf_2021", keep(1 3) gen(_m_ids2) update replace

*Drop unnecessary temp variables
drop if _m_ids==2 & _m_ids2==1
drop _m_ids _m_temp _m_ids2
rename DRF_ID DRF_formerge
rename DRF_ID_drf_temp DRF_ID
*/

*Save full dataset before further cleaning
save "$DATA/sdrdrf_matched_2021" , replace


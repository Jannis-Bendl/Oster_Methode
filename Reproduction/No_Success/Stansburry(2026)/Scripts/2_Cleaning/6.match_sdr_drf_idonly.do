********************************************************************************
*Merge SED with all years of SDR data
********************************************************************************

********************************************************************************
*This do file Merges SDR data for each year with relevant SED data (from the SDR/DRF datasets) and with other data, including institution names and ranks
*Note: The coding of variables for the SED changes over survey years. 
*Note: To make our use of SED variables fully comparable over survey years, we only use this match to extract the DRF_IDs which we then use to match with the 2021 SED DRF file, which has consistent variable coding over survey years
********************************************************************************

********************************************************************************
* Merge SDR with each year's SDR-DRF (.dta fallbacks) and keep matched REFIDs
********************************************************************************
local years 2021 2019 2017 2015 2013 2010 2008 2006 2003 2001 1999 1997 1995 1993

foreach y of local years {
    local yy : display %02.0f mod(`y',100)

    * Load SDR-DRF (from builder); keep only IDs we need
    use "$RAWROOT/sdrdrf`yy'.dta", clear
    * Ensure DRF_ID_ORIG exists if referenced later
    capture confirm variable DRF_ID_ORIG
    if _rc gen long DRF_ID_ORIG = DRF_ID

    * Merge 1:1 on REFID to the SDR temp of the same year
    merge 1:1 REFID using "$TEMP/sdr`yy'"

    * Keep matched only (mirror original intent)
    keep if _merge==3
    drop _merge

    * Label survey year and save to $TEMP
	capture drop YR
    gen int YR = `y'
    save "$TEMP/sdrdrf`yy'", replace
}

* ---- Harmonize $TEMP/sdrdrfYY files before append ----
local yys 21 19 17 15 13 10 08 06 03 01 99 97 95 93
foreach yy of local yys {
    use "$TEMP/sdrdrf`yy'", clear

    * Make PHDFIELD consistently string across years
    capture confirm variable PHDFIELD
    if _rc {
        gen str5 PHDFIELD = ""   // ensure presence
    }
    else {
        capture confirm numeric variable PHDFIELD
        if !_rc {
            tostring PHDFIELD, replace format(%03.0f)  // e.g., 430 -> "430"
        }
        else {
            replace PHDFIELD = string(real(PHDFIELD), "%03.0f") if !missing(real(PHDFIELD))
        }
    }

    * Optional: detach value labels to avoid redefinition warnings on append
    foreach v in ASIAN BLACK HISPANIC WHITE BACARN POSTDOC RACE_SDR {
        capture confirm variable `v'
        if !_rc label values `v'   // clear value label link
    }

    save "$TEMP/sdrdrf`yy'", replace
}

*Merge all of these files together
cd "$TEMP"
use sdrdrf21, clear
local fileappend sdrdrf19.dta sdrdrf17.dta sdrdrf15.dta sdrdrf13.dta sdrdrf10.dta sdrdrf08.dta sdrdrf06.dta sdrdrf03.dta sdrdrf01.dta sdrdrf99.dta sdrdrf97.dta sdrdrf95.dta sdrdrf93.dta
append using `fileappend'

*Consolidate IDs
replace DRF_ID=DRF_ID_ORIG if missing(DRF_ID) 
/*Note that there are some people for whom DRF_ID has been updated over time, so there may be multiple DRF_ID elements for an individual with the same REFID over different SDR survey years. See SDR/DRF documentation*/

*Save data
save "$DATA/sdrdrfall9321_matched_ids", replace

********************************************************************************
* Import all SDR years from synthetic fallbacks and harmonize vars
********************************************************************************
local years 2021 2019 2017 2015 2013 2010 2008 2006 2003 2001 1999 1997 1995 1993

foreach y of local years {
    local yy : display %02.0f mod(`y',100)

    * Load synthetic SDR for the year
    use "$RAWROOT/sdr`yy'.dta", clear

    * Drop legacy fields if present (mirrors original script)
    capture drop SURID
    capture drop PHDFIELD_ORIG

    * If some years had RACE (string), rename to RACE_SDR before encoding
    capture confirm variable RACE_SDR
    if _rc {
        capture confirm variable RACE
        if !_rc rename RACE RACE_SDR
    }

    * Ensure race / indicator vars exist as strings so encode works
    foreach v in ASIAN BLACK HISPANIC WHITE BACARN POSTDOC {
        capture confirm variable `v'
        if _rc {
            gen str3 `v' = "No"
            replace `v' = "Yes" if runiform()<0.20
        }
    }

    * Ensure RACE_SDR exists with categories
    capture confirm variable RACE_SDR
    if _rc {
        gen str12 RACE_SDR = "White"
        replace RACE_SDR = "Asian"    if runiform()<0.15
        replace RACE_SDR = "Black"    if runiform()<0.08
        replace RACE_SDR = "Hispanic" if runiform()<0.10
        replace RACE_SDR = "Other"    if runiform()<0.05
    }

    * Ensure PHDFIELD exists as string (2015 block destrings it)
    capture confirm variable PHDFIELD
    if _rc {
        gen str5 PHDFIELD = string( round(400 + runiform()*200), "%03.0f")
    }

    * Encode strings to numeric where applicable (mirrors original encode lines)
    foreach v in ASIAN BLACK HISPANIC WHITE BACARN POSTDOC RACE_SDR {
        capture confirm variable `v'
        if !_rc {
            capture confirm string variable `v'
            if !_rc {
                encode `v', gen(__`v')
                drop `v'
                rename __`v' `v'
            }
        }
    }

    * Special: original 2015 did destring(PHDFIELD)
    if `y' == 2015 {
        capture destring PHDFIELD, replace
    }
	
	* ---- Add current city/state fields for 9.centroid_clean.do ----
	* Currstatprov: prefer EMST if it exists (SDR-DRF); else use SDR's `state`; else default.
	capture confirm variable EMST
	if !_rc {
		gen str2 Currstatprov = EMST
	}
	else {
		capture confirm variable state
		if !_rc gen str2 Currstatprov = state
		else    gen str2 Currstatprov = "MA"
	}

	* Currinstcity: pick a synthetic city name that exists in $CENT/geocorr2022_2326201260.csv
	* That CSV has "City 1..300" spread across states:
	*   MA (1), CA (2–60), NY (61–120), TX (121–180), VA (181–240), FL (241–300)
	gen int _cid = .
	replace _cid = 1 + floor(runiform()*1)     if Currstatprov=="MA"
	replace _cid = 2 + floor(runiform()*59)    if Currstatprov=="CA"
	replace _cid = 61 + floor(runiform()*60)   if Currstatprov=="NY"
	replace _cid = 121 + floor(runiform()*60)  if Currstatprov=="TX"
	replace _cid = 181 + floor(runiform()*60)  if Currstatprov=="VA"
	replace _cid = 241 + floor(runiform()*60)  if Currstatprov=="FL"
	* fallback if state not in the six above
	replace _cid = 2 + floor(runiform()*59) if missing(_cid)

	gen str20 Currinstcity = "City " + string(_cid)
	drop _cid

    * Save like the original script expects
    save "$TEMP/sdr`yy'", replace
}

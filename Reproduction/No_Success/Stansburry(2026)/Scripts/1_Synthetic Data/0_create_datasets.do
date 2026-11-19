/***********************************************************************
  00_build_synthetic_raw_inputs.do  (STABLE)
************************************************************************/

clear all
set more off

* master seed reference
local MASTER_SEED = 2112

/* -----------------------------
   Helper programs (seedable)
--------------------------------*/

cap program drop fake_enum
program define fake_enum
    // usage: fake_enum <varname>, levels("<a b c>") [seed(#)]
    syntax varname(numeric) , LEVELS(string) [SEED(integer)]
    if ("`seed'"!="") set seed `seed'
    local k : word count `levels'
    gen int `varlist' = ceil(runiform()*`k')
    label define L_`varlist' 1 "`=word(`levels',1)'" , replace
    forvalues i=2/`k' {
        label define L_`varlist' `i' "`=word(`levels',`i')'", add
    }
    label values `varlist' L_`varlist'
end

cap program drop fake_date
program define fake_date
    // usage: fake_date <varname>, start(YYYY-MM-DD) end(YYYY-MM-DD) [seed(#)]
    syntax varname(numeric) , START(string) END(string) [SEED(integer)]
    if ("`seed'"!="") set seed `seed'
    gen double `varlist' = daily("`start'","YMD") + ///
        floor(runiform()*(daily("`end'","YMD")-daily("`start'","YMD")+1))
    format `varlist' %td
end


/* =========================================================
   A) SED institutions: L:\Datasets\DRF\SED_2021\inst21.xlsx
   =========================================================*/
clear
set seed `MASTER_SEED'   // block seed
set obs 2500
gen long instid = 100000 + _n
gen str80 inst_name = "Institution " + string(_n)
gen int state_fips = ceil(runiform()*56)
gen str2  state_abbr = substr("ALAKAZARCACOCTDCDEFLGAGUHIIDILINIAKSKYLAMAMDMEMIMNMSMOMTNCNDNENHNJNMNVNYOHOKORPAPRRISCSDTNTXUTVTVAWAWIWVWY", ///
                              max(1, state_fips*2-1), 2)
gen byte phd_granting = (runiform()<0.7)
gen int ipeds_unitid = 100000 + ceil(runiform()*50000)
order instid inst_name ipeds_unitid state_abbr phd_granting
export excel using "$RAWROOT/inst21.xlsx", firstrow(varlabels) replace

* Build minimal field-specific IPEDS ranking inputs if missing (no RNG)
local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22

cap mkdir "$RANK"

foreach f of local fields {
    local infile "$RANK/`f'IPEDS.dta"
    capture confirm file "`infile'"
    if _rc {
        clear
        set obs 200
        gen long INSTCOD = 100000 + _n
        gen str60 `f'Inst = "`f' University " + string(_n)
        gen int  `f'Rank = _n   // 1..200
        label var INSTCOD  "Institution code (IPEDS)"
        label var `f'Inst  "Program name for `f'"
        label var `f'Rank  "USNWR rank for `f'"
        save "`infile'", replace
    }
}

foreach f of local fields {
    use "$RANK/`f'IPEDS.dta", clear
    rename INSTCOD PHDINST
    rename `f'Inst `f'InstPHD
    rename `f'Rank `f'RankPHD
    save "$RANK/`f'IPEDSPHD.dta", replace
}


* =========================================================
* B) NSF awards (Excel): awards_cleaned_notext.xlsx
*     + crosswalk: refid_public_crosswalk_wroles.xlsx
* =========================================================
clear
set seed `MASTER_SEED'   // block seed
set obs 5000

* --- IDs (AwardID as STRING; script tabs on missing(AwardID)) ---
gen str12 AwardID = "NSF" + string(7000000 + _n)

* --- Dates: random %tc within ranges ---
tempvar startd endd firstamd latestamd
gen double `startd'  = clock("2000-01-01 00:00:00","YMDhms") ///
                       + runiform()*(clock("2023-12-31 23:59:59","YMDhms")-clock("2000-01-01 00:00:00","YMDhms"))
gen double `endd'    = `startd' + (90 + ceil(runiform()*1800))*24*60*60*1000
gen double `firstamd'= `startd' + (ceil(runiform()*365))*24*60*60*1000
gen double `latestamd' = `firstamd' + (ceil(runiform()*365))*24*60*60*1000

gen double AwardEffectiveDate = `startd'
gen double AwardExpirationDate = `endd'
gen double FirstAmendDate = `firstamd'
gen double LatestAmendDate = `latestamd'

* Some missing amendments 
replace FirstAmendDate = . if runiform()<0.035
replace LatestAmendDate = . if runiform()<0.035

* --- Counts & investigators ---
gen byte   TotalInvestigators = ceil(runiform()*5) - 1
replace    TotalInvestigators = min(TotalInvestigators, 19)

* --- $ amounts as STRINGS 
gen double _amt_awarded = max(0, round(rnormal(250000,120000), 1))
gen double _amt_intend  = max(0, round(rnormal(400000,200000), 1))
gen double _amt_arra    = max(0, round(rnormal(20000,15000), 1))

gen str18 AmountAwardedToDate = string(_amt_awarded, "%15.0fc")
gen str18 TotalIntendedAmount = string(_amt_intend , "%15.0fc")
gen str18 AmountFromARRA      = string(_amt_arra   , "%15.0fc")

replace TotalIntendedAmount = "" if runiform()<0.46
replace AmountFromARRA      = "" if runiform()<0.65
drop _amt_*

* --- Titles & instrument ---
gen str80 AwardTitle = "Award Title " + string(_n)
replace  AwardTitle = "" if _n<=20

gen str20 AwardInstrument = "Standard Grant"
replace  AwardInstrument = "Continuing grant" if runiform()<0.12
replace  AwardInstrument = "Fellowship"       if runiform()<0.05

* --- Directorate / Division --
gen str5  DirectorateAbbr = "MPS"
replace   DirectorateAbbr = "ENG" if runiform()<0.33
replace   DirectorateAbbr = "SBE" if runiform()<0.33
replace   DirectorateAbbr = ""    if runiform()<0.04

gen str40 DirectorateName = "Mathematical and Physical Sciences"
replace   DirectorateName = "Engineering"                   if DirectorateAbbr=="ENG"
replace   DirectorateName = "Social, Behavioral & Economic" if DirectorateAbbr=="SBE"
replace   DirectorateName = "" if runiform()<0.025

gen str5  DivisionAbbr = "DMS"
replace   DivisionAbbr = "PHY" if runiform()<0.25
replace   DivisionAbbr = "CHE" if runiform()<0.20
replace   DivisionAbbr = ""    if runiform()<0.46

gen str40 DivisionName = "Mathematical Sciences"
replace   DivisionName = "Physics"   if DivisionAbbr=="PHY"
replace   DivisionName = "Chemistry" if DivisionAbbr=="CHE"
replace   DivisionName = "" if DivisionAbbr==""

* --- Program lists (strings; heavy missingness) ---
gen str80 ProgramElement  = "DMS; XXX"   if runiform()<0.6
replace   ProgramElement  = ""           if missing(ProgramElement) & runiform()<0.9
gen str80 ProgramReference= "DMS; ABC"   if runiform()<0.2
replace   ProgramReference= ""           if missing(ProgramReference) | runiform()<0.8

gen long REFID = 200000 + _n
order AwardID AwardTitle AwardInstrument DirectorateAbbr DirectorateName ///
      DivisionAbbr DivisionName ProgramElement ProgramReference ///
      AwardEffectiveDate AwardExpirationDate FirstAmendDate LatestAmendDate ///
      TotalInvestigators AmountAwardedToDate TotalIntendedAmount AmountFromARRA
drop __000000 __000001 __000002 __000003 
export excel using "$RAWROOT/awards_cleaned_notext.xlsx", firstrow(varlabels) replace

* Crosswalk: REFID ↔ AwardID + RoleCode (seeded)
preserve
    keep AwardID
    tempfile _aw
    save `"$TEMP/_aw"', replace
restore

clear
use `"$TEMP/_aw"', clear
set seed `MASTER_SEED'   // block seed for crosswalk
gen byte nroles = ceil(runiform()*3)
expand nroles
drop nroles
bys AwardID: gen long REFID = 200000 + _n
gen str10 RoleCode = "PI"
replace  RoleCode = "Co-PI"            if runiform()<0.35
replace  RoleCode = "Senior Personnel" if runiform()<0.10
order RoleCode AwardID REFID
export excel using "$RAWROOT/refid_public_crosswalk_wroles.xlsx", firstrow(varlabels) replace


/* =========================================================
   C) SDR / SEDDRF microdata (.dta fallbacks for years used)
   =========================================================*/
local years 1993 1995 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021

foreach y of local years {
    local yy : display %02.0f mod(`y',100)

    * ---------- SDR: one row per REFID (unique) ----------
    clear
    set seed `MASTER_SEED' 
    set obs 20000

    gen long REFID   = 200000 + _n                 
    gen long SDR_ID  = `y'*100000 + _n
    gen int  YR      = `y'
    gen byte us_acad = (runiform()<0.60)
    gen byte got_tenure = (runiform()<0.20) if YR>=2005
    replace got_tenure = . if YR<2005

    gen str2 state = "MA"
    replace state = "CA" if runiform()<0.15
    replace state = "NY" if runiform()<0.10

    compress
    save "$RAWROOT/sdr`yy'.dta", replace

    * ---------- SDR-DRF: subset of SDR REFIDs with a DRF_ID ----------
    preserve
        keep REFID
		set seed `MASTER_SEED' 
        gen double u = runiform()
        sort u, stable
        drop u
        keep in 1/`=8000 + ceil(runiform()*4000)'   // 8–12k deterministically
        gen long DRF_ID = 1000000 + _n
        gen long DRF_ID_ORIG = DRF_ID
        gen int  YR = `y'

        * --------- Add SDR-like fields used in 8.clean ---------
		set seed `MASTER_SEED' 
        gen str1  GENDER = cond(runiform()<0.3,"F","M")
        gen int   RACE   = 10
        replace RACE = 5  if runiform()<0.08
        replace RACE = 2  if runiform()<0.12 & RACE==10
        replace RACE = 3  if runiform()<0.04  & RACE==10
        replace RACE = 4  if runiform()<0.03  & RACE==10
        replace RACE = 6  if runiform()<0.08
        replace RACE = 7  if runiform()<0.02
        replace RACE = 8  if runiform()<0.01
        replace RACE = 9  if runiform()<0.01
        replace RACE = 11 if runiform()<0.01
        replace RACE = 12 if runiform()<0.01
        replace RACE = 1  if runiform()<0.005

        gen str1 EDMOTHER = string(ceil(runiform()*8))
        gen str1 EDFATHER = string(ceil(runiform()*8))

        gen str3 BIRTHPL = string(ceil(runiform()*520), "%03.0f")
        replace   BIRTHPL = string(ceil(runiform()*56),  "%03.0f") if runiform()<0.7

        gen str1 LFSTAT = "1"
        replace LFSTAT = "2" if runiform()<0.03
        replace LFSTAT = "3" if LFSTAT!="2" & runiform()<0.07

        gen str1 FNINUS = cond(runiform()<0.85,"Y","N")
        gen str1 FNUS9095 = "" 
        replace FNUS9095 = "X" if YR==1995 & runiform()<0.9

        gen str1 CHLVIN = cond(runiform()<0.35,"Y","N")
        gen int  DEPENDS = rbinomial(4,0.25)
        gen int  CH18 = rbinomial(9,0.05)
        gen int  CH19 = rbinomial(9,0.05)
        gen str1 MARIND = cond(runiform()<0.6,"Y","N")

        gen str1 SPOWK = cond(runiform()<0.6,"1", cond(runiform()<0.2,"2","L"))
        gen str1 SPNAT = cond(runiform()<0.3,"Y", cond(runiform()<0.6,"N","L"))
        gen str1 SPSOC = cond(runiform()<0.15,"Y", cond(runiform()<0.7,"N","L"))

        gen long SALARY = round(max(20000, rnormal(90000,40000)))
        replace SALARY = 999999  if runiform()<0.003
        replace SALARY = 999998  if runiform()<0.002
        replace SALARY = 9999996 if runiform()<0.001
        gen long EARN   = round(max(20000, rnormal(110000,50000)))
        replace EARN = 999999  if runiform()<0.003
        replace EARN = 999998  if runiform()<0.002
        replace EARN = 9999995 if runiform()<0.001

        foreach v in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC {
            gen str1 `v' = string(ceil(runiform()*4))
            replace `v' = "L" if runiform()<0.05
        }
        foreach v in FACSAL FACBEN FACSEC FACLOC FACADV FACCHAL FACRESP FACIND FACSOC {
            gen str1 `v' = string(ceil(runiform()*4))
            replace `v' = "L" if runiform()<0.05
        }

        gen str1 TENSTA = "2"
        replace TENSTA = "4" if runiform()<0.25
        replace TENSTA = "3" if runiform()<0.20
        replace TENSTA = "5" if runiform()<0.05
        replace TENSTA = "L" if runiform()<0.03

        gen str1 EMSECSM = "1"
        replace EMSECSM = "2" if runiform()<0.20
        replace EMSECSM = "3" if runiform()<0.35
        replace EMSECSM = "L" if runiform()<0.03
        
        gen str2 NEDTP = cond(runiform()<0.55,"03","04")
        replace NEDTP = "01" if runiform()<0.05
        replace NEDTP = "1"  if YR<=2001 & runiform()<0.50
        replace NEDTP = "2"  if YR<=2001 & NEDTP!="1" & runiform()<0.40
        replace NEDTP = "3"  if YR<=2001 & NEDTP!="1" & NEDTP!="2"

        gen int  SUPDIR = rbinomial(20,0.2)
        replace  SUPDIR = 9998 if runiform()<0.01
        gen int  SUPIND = rbinomial(40,0.15)
        replace  SUPIND = 99998 if runiform()<0.01
        replace  SUPIND = 99996 if runiform()<0.01
        gen str1 SUPWK  = cond(runiform()<0.45,"Y", cond(runiform()<0.5,"N","L"))

        gen str6 N2OCPR = "711410" if runiform()<0.10
        replace  N2OCPR = "711460" if runiform()<0.03
        replace  N2OCPR = "711470" if runiform()<0.03
        replace  N2OCPR = ""       if runiform()<0.55
        gen str6 NOCPR  = "" 
        replace  NOCPR  = "711410" if N2OCPR==""
        replace  NOCPR  = "621420" if runiform()<0.02
        replace  NOCPR  = "621430" if runiform()<0.02
        replace  NOCPR  = "621440" if runiform()<0.02
        replace  NOCPR  = "621450" if runiform()<0.02
        gen str6 OCPR = "" 
        replace  OCPR = "611410" if runiform()<0.03 & N2OCPR=="" & NOCPR==""

        gen str2 N2OCPRNG = string(ceil(runiform()*90), "%02.0f")
        gen str2 NOCPRNG  = string(ceil(runiform()*90), "%02.0f")
        gen str2 OCPRNG   = string(ceil(runiform()*90), "%02.0f")
        replace  OCPRNG = "61" if runiform()<0.02
        replace  OCPRNG = "62" if runiform()<0.02
        replace  OCPRNG = "64" if runiform()<0.02
        replace  OCPRNG = "65" if runiform()<0.02
        replace  OCPRNG = "66" if runiform()<0.02
        replace  OCPRNG = "67" if runiform()<0.02
        replace  OCPRNG = "68" if runiform()<0.02
        replace  OCPRNG = "69" if runiform()<0.02
        replace  N2OCPRNG = "" if runiform()<0.05
        replace  NOCPRNG  = "" if runiform()<0.05
        replace  OCPRNG   = "" if runiform()<0.05

        gen str2 EMST = "MA"
        replace EMST = "CA" if runiform()<0.15
        replace EMST = "NY" if runiform()<0.10
        replace EMST = "TX" if runiform()<0.09
        replace EMST = "WA" if runiform()<0.06

        gen int GDEBTLVL = 0
        replace GDEBTLVL = 11 if runiform()<0.06
        replace GDEBTLVL = 12 if runiform()<0.05
        replace GDEBTLVL = 13 if runiform()<0.05
        replace GDEBTLVL = 14 if runiform()<0.04
        replace GDEBTLVL = 15 if runiform()<0.03
        replace GDEBTLVL = 16 if runiform()<0.02
        replace GDEBTLVL = 26 if runiform()<0.02
        replace GDEBTLVL = 27 if runiform()<0.02
        replace GDEBTLVL = 28 if runiform()<0.02
        replace GDEBTLVL = 38 if runiform()<0.01
        replace GDEBTLVL = 39 if runiform()<0.01
        replace GDEBTLVL = 40 if runiform()<0.01
        replace GDEBTLVL = 1  if runiform()<0.04
        replace GDEBTLVL = 2  if runiform()<0.04
        replace GDEBTLVL = 3  if runiform()<0.04
        replace GDEBTLVL = 4  if runiform()<0.03
        replace GDEBTLVL = 5  if runiform()<0.03
        replace GDEBTLVL = 6  if runiform()<0.03
        replace GDEBTLVL = 7  if runiform()<0.03
        gen int UDEBTLVL = GDEBTLVL

        gen str6 INSTCOD = string(100000 + ceil(runiform()*600000), "%06.0f")
        replace  INSTCOD = "999999" if runiform()<0.02
        replace  INSTCOD = "L"      if runiform()<0.01
        gen str6 BAINST  = string(100000 + ceil(runiform()*600000), "%06.0f")
        replace  BAINST = "999999" if runiform()<0.01

        gen str2 CARNEG = cond(YR<=2001, cond(runiform()<0.5,"11","12"), "")
        gen str2 CARN15C = cond(YR>=2006, cond(runiform()<0.6,"15", cond(runiform()<0.7,"16","17")), "")
        gen int  Currcarn2015 = .
        replace Currcarn2015 = 15 if runiform()<0.25
        replace Currcarn2015 = 16 if runiform()<0.20
        replace Currcarn2015 = 17 if runiform()<0.10

        gen str1 PUBPRI     = cond(runiform()<0.7,"1","2")
        gen str2 PBPR15C    = cond(runiform()<0.7,"1","2")
        gen str1 Currpubpriv= cond(runiform()<0.7,"1", cond(runiform()<0.05,"3","2"))

        gen str3 HSPLACE = string(1 + floor(runiform()*56), "%03.0f")

        capture confirm variable PHDCY
        if _rc gen int PHDCY = YR - (5 + ceil(runiform()*25))
        gen int AGE = (YR - PHDCY) + 30 + ceil(runiform()*10)
        replace AGE = . if runiform()<0.01

        gen str2 EMSIZE = ""
        replace EMSIZE = "1" if runiform()<0.15
        replace EMSIZE = "2" if EMSIZE=="" & runiform()<0.15
        replace EMSIZE = "3" if EMSIZE=="" & runiform()<0.15
        replace EMSIZE = "4" if EMSIZE=="" & runiform()<0.15
        replace EMSIZE = "5" if EMSIZE=="" & runiform()<0.15
        replace EMSIZE = "6" if EMSIZE=="" & runiform()<0.10
        replace EMSIZE = "7" if EMSIZE=="" & runiform()<0.08
        replace EMSIZE = "8" if EMSIZE=="" & runiform()<0.07
        replace EMSIZE = "L" if runiform()<0.03

        compress
        save "$RAWROOT/sdrdrf`yy'.dta", replace
    restore
}


* =========================================================
* C1) SED 2021 (noid2021): .dta fallback
* =========================================================
clear
set seed `MASTER_SEED'
set obs 20000

gen str1 EDMOTHER = string(ceil(runiform()*8))
gen str1 EDFATHER = string(ceil(runiform()*8))
gen int BIRTHPL = ceil(runiform()*600)

gen int BAFIELD  = .
replace  BAFIELD = 50   if runiform()<0.05
replace  BAFIELD = 150  if runiform()<0.06
replace  BAFIELD = 230  if runiform()<0.06
replace  BAFIELD = 350  if runiform()<0.06
replace  BAFIELD = 405  if runiform()<0.05
replace  BAFIELD = 430  if runiform()<0.06
replace  BAFIELD = 525  if runiform()<0.06
replace  BAFIELD = 565  if runiform()<0.06
replace  BAFIELD = 682  if runiform()<0.03
replace  BAFIELD = 667  if runiform()<0.04
replace  BAFIELD = 690  if runiform()<0.03
replace  BAFIELD = 657  if runiform()<0.02
replace  BAFIELD = 710  if runiform()<0.02
replace  BAFIELD = 577  if runiform()<0.02
replace  BAFIELD = 415  if runiform()<0.02
replace  BAFIELD = 0    if runiform()<0.01

gen int MAFIELD  = BAFIELD
gen int PHDFIELD = BAFIELD
replace  PHDFIELD = 415 if runiform()<0.05
replace  PHDFIELD = 547 if runiform()<0.03
replace  PHDFIELD = 577 if runiform()<0.03

gen str6 PHDINST = string(100000 + ceil(runiform()*199), "%06.0f")

local oldcodes "124885 176284 203951 209472 212841 238883 435338 365426 223214 231837 103778 260901 260910 418418"
foreach c of local oldcodes { 
	replace PHDINST = "`c'" if runiform()<0.01 
	}

local newcodes "110468 216348 206084 209490 212054 139755 134130 173957 228723 233277 104151 489779 215293"
foreach c of local newcodes { 
	replace PHDINST = "`c'" if runiform()<0.01 
	}

local rep "200 150 905 525 405 657 540 667 350 710 430 235 230 565 678 600 215 682 686 690"
forvalues i = 1/20 {
    replace PHDFIELD = real(word("`rep'", `i')) in `i'
}
forvalues i = 1/200 {
    replace PHDINST = string(100000 + `i' - 1, "%06.0f") in `i'
}

gen long DRF_ID = 1000000 + _n
gen int  YR     = 2021
gen int PHDCY = 1975 + ceil(runiform()*45)
gen str1 SEX   = cond(runiform()<.35,"1","2")
gen str3 HSPLACE = string(1 + ceil(runiform()*56), "%03.0f")

compress
save "$RAWROOT/noid2021.dta", replace


* =========================================================
* D) New WOS customized SAS files (.dta fallbacks)
* =========================================================
clear
set seed `MASTER_SEED'
set obs 120000

gen long REFID = 200000 + _n
gen str18  pub_randid = "PUB" + string(_n, "%09.0f")

gen int    PUB_YEAR   = 1990 + floor(runiform()*28)           // 1990–2017
label var  PUB_YEAR "Publication Year 1990-2017"

gen str20  PUB_TYPE   = "Article"
replace    PUB_TYPE   = "Review"      if runiform()<0.12
replace    PUB_TYPE   = "Proceedings" if runiform()<0.05
replace    PUB_TYPE   = "Letter"      if runiform()<0.03
label var  PUB_TYPE "Publication type (18 types)"

gen double PUB_JCR_IMPACTFACTOR = rnormal(3, 2)
replace    PUB_JCR_IMPACTFACTOR = max(PUB_JCR_IMPACTFACTOR, 0)
replace    PUB_JCR_IMPACTFACTOR = 999.999 if runiform()<0.02
replace    PUB_JCR_IMPACTFACTOR = . if PUB_YEAR<1997 & runiform()<0.6
label var  PUB_JCR_IMPACTFACTOR "Publication Journal Impact Factor (in publication year)"

gen int    NUM_PUB_JCR_RESEARCHFIELD = ceil(runiform()*9)
replace    NUM_PUB_JCR_RESEARCHFIELD = . if runiform()<0.01
label var  NUM_PUB_JCR_RESEARCHFIELD "Total number of JCR research fields"

gen int    PUB_NUM_AUTHORS   = max(1, ceil(rnormal(5, 3)))
replace    PUB_NUM_AUTHORS   = round(PUB_NUM_AUTHORS)
replace    PUB_NUM_AUTHORS   = 5575 in 1
label var  PUB_NUM_AUTHORS "Author count"

gen int    PUB_NUM_COUNTRIES = max(1, ceil(rnormal(2, 1)))
replace    PUB_NUM_COUNTRIES = . if runiform()<0.19
label var  PUB_NUM_COUNTRIES "Number of distinct countries represented by authors"

gen int    PUB_US = ceil(rnormal(2, 2))
replace    PUB_US = max(PUB_US, 0)
replace    PUB_US = -99 if PUB_YEAR<2008 & runiform()<0.25
replace    PUB_US = .   if runiform()<0.19
label var  PUB_US "US-affiliated author count (−99 indicates ≥1 pre-2008)"

gen byte   PUB_US_Indicator = (PUB_US>0 | PUB_US==-99)
replace    PUB_US_Indicator = 0 if missing(PUB_US_Indicator)
label var  PUB_US_Indicator "At least one US-affiliated author indicator"

gen int    PUB_FIRST_CITE_Y2_LAG = floor(runiform()*25)
replace    PUB_FIRST_CITE_Y2_LAG = . if runiform()<0.36
label var  PUB_FIRST_CITE_Y2_LAG "Months to first citation within two years"

gen int    PUB_CITES_Y2     = rpoisson(2)
gen int    PUB_CITES_Y2_RA  = rpoisson(2)
gen int    PUB_CITES_Y5     = rpoisson(5)
gen int    PUB_CITES_Y5_RA  = rpoisson(5)
gen int    PUB_CITES_Y2_HIJ = rpoisson(1)
gen int    PUB_CITES_Y5_HIJ = rpoisson(2)

gen int    NUM_REFS = rpoisson(30)
replace    NUM_REFS = 15417 in 2

gen double JIF_PCT = runiform()*100
replace    JIF_PCT = . if runiform()<0.285

gen double CNCI = max(0, rnormal(1, 0.8))
gen double AVG_PCT = runiform()*100

gen str2   PUB_JCR_RESEARCHFIELD_A = "AA"
replace    PUB_JCR_RESEARCHFIELD_A = "AD" if runiform()<0.25
replace    PUB_JCR_RESEARCHFIELD_A = "BU" if runiform()<0.25
replace    PUB_JCR_RESEARCHFIELD_A = "BI" if runiform()<0.25

foreach L in B C D E F {
    gen str2 PUB_JCR_RESEARCHFIELD_`L' = ""
    replace  PUB_JCR_RESEARCHFIELD_`L' = "PH" if runiform()<0.05
}

gen str5   PUB_HIGHIMPACTJOURNAL = cond(runiform()<0.35, "TRUE", "FALSE")
replace    PUB_HIGHIMPACTJOURNAL = "" if runiform()<0.28

gen str5   PUB_LOWIMPACTJOURNAL = cond(runiform()<0.20, "TRUE", "FALSE")
replace    PUB_LOWIMPACTJOURNAL = "" if runiform()<0.28

order pub_randid REFID PUB_YEAR PUB_TYPE PUB_JCR_IMPACTFACTOR NUM_PUB_JCR_RESEARCHFIELD ///
      PUB_NUM_AUTHORS PUB_NUM_COUNTRIES PUB_US PUB_US_Indicator PUB_FIRST_CITE_Y2_LAG ///
      PUB_CITES_Y2 PUB_CITES_Y2_RA PUB_CITES_Y5 PUB_CITES_Y5_RA PUB_CITES_Y2_HIJ PUB_CITES_Y5_HIJ ///
      NUM_REFS JIF_PCT CNCI AVG_PCT ///
      PUB_JCR_RESEARCHFIELD_A PUB_JCR_RESEARCHFIELD_B PUB_JCR_RESEARCHFIELD_C ///
      PUB_JCR_RESEARCHFIELD_D PUB_JCR_RESEARCHFIELD_E PUB_JCR_RESEARCHFIELD_F ///
      PUB_HIGHIMPACTJOURNAL PUB_LOWIMPACTJOURNAL
compress
save "$RAWROOT/sdrwos_pub_scalars_supp_metrics.dta", replace

* Crosswalk: pub_randid ↔ REFID (multiple authors per pub)
preserve
    keep pub_randid
    tempfile pubs
    save `pubs', replace
restore

clear
use `pubs', clear
set seed `MASTER_SEED'     // block seed
gen int n_authors = ceil(runiform()*5)
expand n_authors
bys pub_randid: gen int AUTHOR_POS = _n
gen long REFID = 200000 + _n
gen double GBM_predicted_probability = 0.75 + runiform()*0.25
replace    GBM_predicted_probability = runiform()*0.75 if runiform()<0.10
order pub_randid REFID AUTHOR_POS GBM_predicted_probability
compress
save "$RAWROOT/sdrwos_matchingresults.dta", replace


* =========================================================
* E) Geospatial inputs (for 9.centroid_clean)
* =========================================================

* 1) US place centroids
clear
set seed `MASTER_SEED'
set obs 500
gen str40 place_name = "Place " + string(_n)
gen str2  state_abbr = "MA"
replace state_abbr = "CA" in 2/50
replace state_abbr = "NY" in 51/100
replace state_abbr = "TX" in 101/150
replace state_abbr = "IL" in 151/200
replace state_abbr = "FL" in 201/250
replace state_abbr = "PA" in 251/300
replace state_abbr = "OH" in 301/350
replace state_abbr = "GA" in 351/400
replace state_abbr = "VA" in 401/450
replace state_abbr = "WA" in 451/500
gen double lon = -125 + runiform()*60
gen double lat =   25 + runiform()*20
order place_name state_abbr lon lat
export delimited using "$CENT/us_place_centroids.csv", replace

* 2) Geocorr-like file
clear
set seed `MASTER_SEED'
set obs 300
gen str20 Currinstcity  = "City " + string(_n)
gen str20 countyname    = "County " + string(ceil(_n/3))
gen str2  stab          = "MA"
replace stab = "CA" in 2/60
replace stab = "NY" in 61/120
replace stab = "TX" in 121/180
replace stab = "VA" in 181/240
replace stab = "FL" in 241/300
gen str70 placename = Currinstcity + ", " + countyname + ", " + stab
order placename countyname stab Currinstcity
export delimited using "$CENT/geocorr2022_2326201260.csv", replace

* Build shapefile-derived .dta (no RNG)
clear
shp2dta using "$CENT/usa_48states/usa_contig_weighted.shp", ///
    database("$CENT/usa_48states/usa_contig_weighted_data") ///
    coordinates("$CENT/usa_48states/usa_contig_weighted_coord") replace

* =======================================================================
* F) Create the rank / institution files we use in 8.clean
* =======================================================================

* BA22
clear
set seed `MASTER_SEED'
set obs 500
gen str6 BAinstid = string(100000 + ceil(runiform()*600000), "%06.0f")
gen int  BA22Rank  = _n
save "$RANK/BA22IPEDS.dta", replace

* LAC24
clear
set seed `MASTER_SEED'
set obs 300
gen str6 LAC24Inst = string(100000 + ceil(runiform()*600000), "%06.0f")
gen int  LAC24Rank = _n
save "$RANK/LAC24IPEDS.dta", replace

* Currinstcodes
clear
set seed `MASTER_SEED'
set obs 1200
gen str6 INSTCOD = string(100000 + ceil(runiform()*600000), "%06.0f")
gen int Currcarn2015 = 15 + mod(_n,3)
gen str1 Currpubpriv = cond(runiform()<.65,"1", cond(runiform()<.9,"2","3"))
gen str2 CARN15C = string(Currcarn2015)
gen str1 PBPR15C = cond(Currpubpriv=="1","1","2")
save "$DATA/Currinstcodes.dta", replace

cap erase "$synth_data/_aw.dta"
cap erase "$TEMP/_aw.dta"

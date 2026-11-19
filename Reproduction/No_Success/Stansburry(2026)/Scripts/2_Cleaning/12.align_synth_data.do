********************************************************************************
* Stable synthetic alignment 
********************************************************************************
clear all
set more off

* ===============================
* 0) GLOBAL SEED CONFIG
* ===============================
* Master seed (change once to shift all draws deterministically)
local SEED_MASTER 2112

* Deterministic seeds 
local SEED_refid_shuffle         = `SEED_MASTER' 
local SEED_instcod_fill          = `SEED_MASTER' 
local SEED_pubvars_fill           = `SEED_MASTER' 
local SEED_sdr_working_blockA    = `SEED_MASTER' 
local SEED_bornus_country        = `SEED_MASTER' 
local SEED_condint_dvfill        = `SEED_MASTER' 
local SEED_tentop_patch          = `SEED_MASTER'
local SEED_tenure_withpubs       = `SEED_MASTER'
local SEED_align_phd_group       = `SEED_MASTER' 
local SEED_tenuredecision_main   = `SEED_MASTER' 
local SEED_td_topups             = `SEED_MASTER' 
local SEED_td_FE_variation       = `SEED_MASTER' 
local SEED_td_researchblock      = `SEED_MASTER' 
local SEED_td_NR_spec            = `SEED_MASTER' 
local SEED_td_dup_and_jitter     = `SEED_MASTER' 
local SEED_td_quickpatch         = `SEED_MASTER' 
local SEED_guards                = `SEED_MASTER' 

* ====================================================================================================================================
* Align synthetic datasets (REFID matches, distribution of variables, size of dataset)
* This script only applies to the synthetic data, we do not use it when creating the tables / figures actually in our paper.
* ====================================================================================================================================

* ========================================
* -------------------------
* Artificially align REFIDs
* -------------------------

* Get all REFIDs from SDR
use "$DATA/sdrdrf_9321_working", clear
keep REFID
duplicates drop
tempfile sdr_ids
save `sdr_ids'

* Count WOS rows
use "$DATA/newwos_withrefid", clear
local n_wos = _N

* Load SDR REFIDs and shuffle (stable)
use `sdr_ids', clear
set seed `SEED_refid_shuffle'
gen double rand_sdr = runiform()
sort rand_sdr, stable
local n_sdr = _N
local reps = ceil(`n_wos'/`n_sdr')

* Expand SDR to match/exceed WOS rows
expand `reps'
gen long obs_id = _n
keep REFID obs_id
tempfile sdr_expanded
save `sdr_expanded'

* Merge onto WOS
use "$DATA/newwos_withrefid", clear
gen long obs_id = _n
merge 1:1 obs_id using `sdr_expanded', keepusing(REFID) nogen update replace
drop obs_id
save "$DATA/newwos_withrefid", replace

* ========================================
* Align variables which have missing observations after pipeline development to ensure downstream scripts run:

* Load WOS data
use "$DATA/newwos_withrefid", clear

* --- 1. Ensure INSTCOD exists and is valid based on SDR ---
use "$DATA/sdrdrf_9321_working", clear
keep REFID INSTCOD
duplicates drop REFID, force    
tempfile sdr_instcod
save `sdr_instcod'

use "$DATA/newwos_withrefid", clear
merge m:1 REFID using `sdr_instcod', keepusing(INSTCOD) nogen update replace

* Fill remaining missing INSTCOD randomly from SDR INSTCODs (stable)
gen byte INSTCOD_missing = missing(INSTCOD)
preserve
keep if INSTCOD_missing
use `sdr_instcod', clear
set seed `SEED_instcod_fill'
gen double rand = runiform()
sort rand, stable
gen long obs_id = _n
tempfile instcod_random
save `instcod_random'
restore
gen long obs_id = _n
merge 1:1 obs_id using `instcod_random', keepusing(INSTCOD) nogen update replace
drop obs_id INSTCOD_missing

* --- 2. Randomly fill other researchvars if missing (stable) ---
set seed `SEED_pubvars_fill'

* PUB_YEAR (1997–2023)
replace PUB_YEAR = ceil(1997 + runiform()*(2023-1997)) if missing(PUB_YEAR)

* PUB_TYPE (categorical string)
replace PUB_TYPE = "Article" if missing(PUB_TYPE) & runiform() < 0.5
replace PUB_TYPE = "Review"  if missing(PUB_TYPE)

* PUB_NUM_AUTHORS_b (1–20)
replace PUB_NUM_AUTHORS = 1 + floor(20*runiform()) if missing(PUB_NUM_AUTHORS)

* (dup guards retained for fidelity)
replace PUB_YEAR = ceil(1997 + runiform()*(2023-1997)) if missing(PUB_YEAR)
replace PUB_TYPE = "Article" if missing(PUB_TYPE) & runiform()<0.5
replace PUB_TYPE = "Review" if missing(PUB_TYPE)

* Save updated WOS
save "$DATA/newwos_withrefid", replace

* =======================================
* Additional alignments to ensure sufficient observations / no collinear observations downstream:

use "$DATA/sdrdrf_9321_working", clear
set seed `SEED_sdr_working_blockA'

* ---------- PHD_CAT across all years ----------
capture drop PHD_CAT
gen str20 PHD_CAT = ""
local phdlist "Agr Sciences Bio Sciences Comp/Inf Sciences Economics Engineering Health Math/Stats Phys/Geo/Atmos/Ocean Psychology Social Sciences ex Econ"
gen double __u_phd = runiform()
gen byte __k = ceil(__u_phd*10)
replace PHD_CAT = word("`phdlist'", __k)
drop __u_phd __k

* ---------- PHDINST numeric (safe for FE) ----------
capture drop PHDINST
gen int PHDINST = 1 + floor(runiform()*100)

* ---------- INSTCOD + string copy ----------
capture drop INSTCOD
gen long INSTCOD = 20000 + ceil(runiform()*199)
capture drop INSTCOD_str
gen str6 INSTCOD_str = string(INSTCOD, "%06.0f")

* ---------- PHDFIELDNEW (fill only if missing) ----------
capture confirm variable PHDFIELDNEW
if _rc gen int PHDFIELDNEW = .
replace PHDFIELDNEW = ceil(runiform()*100) if missing(PHDFIELDNEW)

* ---------- Distance vars ----------
capture drop HSCURRCITY_*
gen double HSCURRCITY_DIST = runiform()*100
gen double HSCURRCITY_DIST_sq   = HSCURRCITY_DIST^2
gen double HSCURRCITY_DIST_cube = HSCURRCITY_DIST^3

* ---------- Harmonize bornus with variation in FE cells ----------
capture drop bornus
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: gen double __u_b = runiform()
gen byte bornus = (__u_b <= 0.60)
drop __u_b
label define yesno 0 "No" 1 "Yes", replace
label values bornus yesno
label var bornus "US-born (synthetic, ~60% per FE cell)"

* ---------- Ensure race_n varies within FE cells among bornus==1 ----------
preserve
keep race_n
drop if missing(race_n)
contract race_n
keep if race_n != 5
gsort -_freq
scalar altcode = .
if _N>=1 scalar altcode = race_n[1]
restore
if missing(altcode) scalar altcode = 4

bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __rmin = min(race_n) if bornus==1
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __rmax = max(race_n) if bornus==1
gen byte __need_raceflip = (bornus==1 & __rmin==__rmax & !missing(__rmin))
gen double __u_r = runiform()
replace race_n = altcode if __need_raceflip & __u_r<0.30 & race_n==5
drop __rmin __rmax __need_raceflip __u_r

* ---------- Ensure gender varies within FE cells among bornus==1 ----------
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __gmin = min(gender) if bornus==1
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __gmax = max(gender) if bornus==1
gen byte __need_gflip = (bornus==1 & __gmin==__gmax & !missing(__gmin))
gen double __u_g = runiform()
summ gender if !missing(gender)
scalar __glo = r(min)
scalar __ghi = r(max)
replace gender = __glo + __ghi - gender if __need_gflip & __u_g<0.30
drop __gmin __gmax __need_gflip __u_g

* ---------- Ensure edpar_n varies within FE cells among bornus==1 ----------
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __emin = min(edpar_n) if bornus==1
bysort YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY: egen __emax = max(edpar_n) if bornus==1
gen byte __need_eflip = (bornus==1 & __emin==__emax & !missing(__emin))
gen double __u_e = runiform()
summ edpar_n if !missing(edpar_n)
scalar __eminv = r(min)
scalar __emaxv = r(max)
replace edpar_n = cond(edpar_n==__emaxv, __eminv, edpar_n+1) if __need_eflip & __u_e<0.30
drop __emin __emax __need_eflip __u_e

* ---------- Align bornus and BIRTHCOUNTRY ----------
capture drop BIRTHCOUNTRY
gen int BIRTHCOUNTRY = .
replace BIRTHCOUNTRY = 1 if bornus==1

set seed `SEED_bornus_country'
tempvar idx ncell
bysort YR PHDINST: gen long `ncell' = _N if bornus==0
bysort YR PHDINST: gen long `idx'   = _n if bornus==0
local K = 12
replace BIRTHCOUNTRY = 2 + floor((`idx'-1) * `K' / max(`ncell',1)) if bornus==0
label var BIRTHCOUNTRY "Birth Country (synthetic: 1=US; 2..`=1+`K'' non-US groups)"

* Collapse very-rare non-US countries in intensive sample
gen byte __int = (TENURE==1 & LOCATIONUS==1 & inrange(years_since_phd,10,39) & bornus==0 & LFSTAT=="1")
bysort BIRTHCOUNTRY: egen __nint = total(__int)
replace BIRTHCOUNTRY = 2 if __nint < 25 & __int==1
drop __int __nint

* Intensive filter
local condint (TENURE==1 & LOCATIONUS==1 & inrange(years_since_phd,10,39))

* Guards
replace WTSURVY = 1 if missing(WTSURVY) | WTSURVY<=0
replace REFID   = _n if missing(REFID)

* Stable key for coarsening
capture confirm variable PHDINST
if _rc==0 local key PHDINST
else       local key REFID

* Coarsen decade bins
replace PHDPROGRAMDECADE = 1960 + 10*mod(`key', 8) if `condint'

* Collapse super-rare BIRTHCOUNTRY inside intensive sample
bysort BIRTHCOUNTRY: egen __nint = total(`condint')
replace BIRTHCOUNTRY = 2 if __nint<5 & `condint'
drop __nint

****** Updates so new robustness will run on the years
gen byte __ext = (LFSTAT=="1" & LOCATIONUS==1 & inrange(years_since_phd,10,39))
gen byte __int = (TENURE==1   & LOCATIONUS==1 & inrange(years_since_phd,10,39))
gen byte __all = (__ext | __int)

replace WTSURVY = 1 if missing(WTSURVY) | WTSURVY<=0
replace PHDPROGRAMYR = REFID if missing(PHDPROGRAMYR) & !missing(REFID)

sort YR
by YR: replace PHDINST          = 1 + mod(REFID,6)              if __all
replace    PHDFIELDNEW          = 1 + mod(REFID,5)              if __all
replace    PHDCY5y              = 1 + mod(int(REFID/7),3)       if __all
replace    years_since_phd5y    = cond(mod(REFID,2),10,30)      if __all
replace    BIRTHCOUNTRY         = 1 + mod(REFID,2)              if __all

replace gender   = mod(REFID,2)                 if __all & missing(gender)
replace race_n   = 1 + mod(REFID,5)             if __all & missing(race_n)
replace edpar_n  = 1 + mod(int(REFID/3),4)      if __all & missing(edpar_n)

* DVs (stable)
set seed `SEED_condint_dvfill'
replace TENURE       = (runiform()<0.65)            if __ext
replace TEN_R1       = (runiform()<0.40)            if __int
replace TENLOGRANK   = round(rnormal(-3,1), .001)   if __int
replace lnEARN       = round(rnormal(7,0.5), .001)  if __int
replace JOBSATIS_num = round(rnormal(0,1), .001)    if __int

drop __ext __int __all

* Data patch for degenerate DVs (stable)
set seed `SEED_tentop_patch'
replace TEN_TOP50ANY = 1 in 1/5
replace RANK_TOP10   = 1 in 6/10
replace RANK_11to25  = 1 in 11/15
replace RANK_26to50  = 1 in 16/20
replace RANK_51to100 = 1 in 21/25
replace RANK_101plus = 1 in 26
replace NONRANKED    = 0 in 27/31

quietly {
    gen byte __touse = TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40 ///
                       & !missing(WTSURVY) & WTSURVY>0
    count if __touse & TEN_TOP50ANY==1
    if (r(N)==0) {
        tempvar __u
        set seed `SEED_tentop_patch'  // ensure same ranks every run
        gen double `__u' = runiform() if __touse & TEN_TOP50ANY==0
        sort `__u', stable
        count if __touse
        local N = r(N)
        local K = ceil(0.0002*`N')
        if (`K'<5) local K = 5
        if (`K'>20) local K = 20
        replace TEN_TOP50ANY = 1 if __touse & TEN_TOP50ANY==0 in 1/`K'
        drop `__u'
    }
    drop __touse
}

* A tiny random sprinkle (stable)
set seed `SEED_tentop_patch'
replace TEN_TOP50ANY = 1 if runiform() < 0.3 & TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40

compress
save "$DATA/sdrdrf_9321_working", replace

* =======================================
* Edits to tenure_withpubs_data  (stable block)
use "$TEMP/tenure_withpubs_data", clear
set seed `SEED_tenure_withpubs'

local phdpyr_min = 1960
local phdpyr_max = 2010
replace PHDPROGRAMYR = ceil(`phdpyr_min' + runiform()*(`phdpyr_max' - `phdpyr_min' + 1))

local bc_min = 400
local bc_max = 800
replace BIRTHCOUNTRY = ceil(`bc_min' + runiform()*(`bc_max' - `bc_min' + 1))

local phd_min = 1
local phd_max = 15
replace PHD_GROUP = ceil(`phd_min' + runiform()*(`phd_max' - `phd_min' + 1)) if missing(PHD_GROUP)

local research2 pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn ///
                pubs_firstauthor_rn pubs_lastauthor_rn NSFBucket ///
                pubs_top10cnci_sh pubs_hij_sh

foreach var of local research2 {
    su `var', meanonly
    local vmin = r(min)
    local vmax = r(max)
    if `vmin' == `vmax'  {
        replace `var' = runiform()
    }
    else {
        replace `var' = `vmin' + runiform()*(`vmax' - `vmin') if missing(`var')
    }
}

foreach var in pubs_rn pubs_firstauthor_rn pubs_lastauthor_rn NSFBucket pubs_top10cnci_sh pubs_hij_sh {
    replace `var' = ceil(`var'*10) if !missing(`var')
}

su `research2'

drop PHDINST 
gen PHDINST = ceil(runiform()*100) if missing(PHDINST)

replace PHDFIELDNEW = ceil(runiform()*100) if missing(PHDFIELDNEW)

drop INSTCOD
gen str6 INSTCOD = string(20000 + ceil(runiform()*199), "%06.0f")

* Stable YR assignment from a fixed list
local years 1993 1995 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021
local n : word count `years'
gen rand_index = ceil(runiform() * `n')
cap drop YR
gen int YR = .
forvalues i = 1/`n' {
    replace YR = `:word `i' of `years'' if rand_index == `i'
}
drop rand_index

save "$TEMP/tenure_withpubs_data", replace

* Align PHD GROUP in SDRDRF working data (stable)
use "$DATA/sdrdrf_9321_working", clear
set seed `SEED_align_phd_group'
local phd_min = 1
local phd_max = 15
replace PHD_GROUP = ceil(`phd_min' + runiform()*(`phd_max' - `phd_min' + 1)) if missing(PHD_GROUP)
save "$DATA/sdrdrf_9321_working", replace

**************************************************************************
* Make tenuredecision_data robust for Table 2 Col 4 (Got Tenure) — stable
**************************************************************************
use "$TEMP/tenuredecision_data", clear
set seed `SEED_tenuredecision_main'

* ---------- 0) Make sure all required vars exist & are usable ----------
capture confirm variable YR
if _rc gen int YR = 1997 + mod(_n,25)

capture confirm variable INSTCOD
if _rc gen int INSTCOD = 1000 + mod(_n,200)

capture confirm variable INSTCOD_miss
if _rc gen byte INSTCOD_miss = missing(INSTCOD)
else    replace INSTCOD_miss = missing(INSTCOD)

capture confirm variable FULLRANK
if _rc gen byte FULLRANK = 1
replace FULLRANK = 1 if missing(FULLRANK)

capture confirm variable PHDFIELDNEW
if _rc gen int PHDFIELDNEW = 1 + mod(_n,18)

capture confirm variable PHDCY5y
if _rc gen int PHDCY5y = floor((YR-2.5)/5)*5

capture confirm variable years_since_phd5y
if _rc gen int years_since_phd5y = 5*(10 + mod(_n,6))

capture confirm variable BIRTHCOUNTRY
if _rc gen int BIRTHCOUNTRY = 1 + mod(_n,10)
replace BIRTHCOUNTRY = 1 + mod(BIRTHCOUNTRY-1,10) if !missing(BIRTHCOUNTRY)

capture confirm variable edpar_n
if _rc gen byte edpar_n = 1 + mod(_n,4)

capture confirm variable gender
if _rc gen byte gender = mod(_n,2)

capture confirm variable race_n
if _rc gen byte race_n = cond(runiform()<.7, 5, 1 + mod(_n,4))

capture confirm variable WTSURVY
if _rc gen double WTSURVY = 1

* Plenty of clusters for vce(cluster PHDPROGRAMYR)
capture confirm variable PHDPROGRAMYR
if _rc {
    bysort INSTCOD: gen long __row = _n
    gen long PHDPROGRAMYR = 100000*INSTCOD + mod(__row, 20)
    drop __row
}

* ---------- 1) Decision-year flags ----------
capture drop flag_decisionyr
gen byte flag_decisionyr = 0
gen double __u = runiform()
bysort YR INSTCOD: replace flag_decisionyr = (YR>=1997 & __u<=0.60)
drop __u

bysort YR INSTCOD: egen __nflag = total(flag_decisionyr==1)
gen __need = 10 - __nflag
replace __need = 0 if __need<0 | missing(__need)

set seed `SEED_td_topups'
gen double __v = runiform()
bysort YR INSTCOD (__v): replace flag_decisionyr = 1 if flag_decisionyr==0 & __need>0 & _n<=__need
drop __nflag __need __v

capture drop maxdecisionyr
gen int maxdecisionyr = YR

* ---------- 2) Outcomes & thresholds ----------
capture confirm variable GOT_TENURE_NEXTYR
if _rc gen byte GOT_TENURE_NEXTYR = .
set seed `SEED_td_topups'
replace GOT_TENURE_NEXTYR = (runiform()<=0.35) if missing(GOT_TENURE_NEXTYR) & flag_decisionyr==1 & YR>=1997

capture confirm variable TENURE_NEXTYR
if _rc gen byte TENURE_NEXTYR = .
replace TENURE_NEXTYR = (runiform()<=0.60) if missing(TENURE_NEXTYR) & flag_decisionyr==1 & YR>=1997

capture drop t_GOT_TENURE_NEXTYR t_TENURE_NEXTYR num_GOT_TENURE_NEXTYR
bysort YR INSTCOD: egen t_GOT_TENURE_NEXTYR = total(flag_decisionyr==1 & !missing(GOT_TENURE_NEXTYR))
bysort YR INSTCOD: egen t_TENURE_NEXTYR     = total(flag_decisionyr==1 & !missing(TENURE_NEXTYR))
gen int num_GOT_TENURE_NEXTYR = t_GOT_TENURE_NEXTYR

* Top-up zeros to reach >=5 (stable ranks)
set seed `SEED_td_topups'
tempvar ug rmissg addg ut rmisst addt
bysort YR INSTCOD: gen double `ug' = runiform()
bysort YR INSTCOD (`ug'): gen long `rmissg' = sum(flag_decisionyr==1 & missing(GOT_TENURE_NEXTYR))
gen int `addg' = 5 - t_GOT_TENURE_NEXTYR
replace `addg' = 0 if `addg'<0 | missing(`addg')
replace GOT_TENURE_NEXTYR = 0 if flag_decisionyr==1 & missing(GOT_TENURE_NEXTYR) & `rmissg'<=`addg'
drop `ug' `rmissg' `addg'

bysort YR INSTCOD: gen double `ut' = runiform()
bysort YR INSTCOD (`ut'): gen long `rmisst' = sum(flag_decisionyr==1 & missing(TENURE_NEXTYR))
gen int `addt' = 5 - t_TENURE_NEXTYR
replace `addt' = 0 if `addt'<0 | missing(`addt')
replace TENURE_NEXTYR = 0 if flag_decisionyr==1 & missing(TENURE_NEXTYR) & `rmisst'<=`addt'
drop `ut' `rmisst' `addt'

capture drop t_GOT_TENURE_NEXTYR t_TENURE_NEXTYR num_GOT_TENURE_NEXTYR
bysort YR INSTCOD: egen t_GOT_TENURE_NEXTYR = total(flag_decisionyr==1 & !missing(GOT_TENURE_NEXTYR))
bysort YR INSTCOD: egen t_TENURE_NEXTYR     = total(flag_decisionyr==1 & !missing(TENURE_NEXTYR))
gen int num_GOT_TENURE_NEXTYR = t_GOT_TENURE_NEXTYR

* ---------- 3) Within-FE variation on flagged rows ----------
egen __fe = group(YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHDFIELDNEW)

set seed `SEED_td_FE_variation'
bysort __fe: egen __rmin = min(race_n) if flag_decisionyr==1 & YR>=1997
bysort __fe: egen __rmax = max(race_n) if flag_decisionyr==1 & YR>=1997
gen byte __need_r = (flag_decisionyr==1 & YR>=1997 & __rmin==__rmax & !missing(__rmin))
gen double __ur = runiform()
replace race_n = ceil(runiform()*4) if __need_r & __ur<0.30 & race_n==5
drop __rmin __rmax __need_r __ur

bysort __fe: egen __gmin = min(gender) if flag_decisionyr==1 & YR>=1997
bysort __fe: egen __gmax = max(gender) if flag_decisionyr==1 & YR>=1997
gen byte __need_g = (flag_decisionyr==1 & YR>=1997 & __gmin==__gmax & !missing(__gmin))
gen double __ug = runiform()
summ gender if !missing(gender)
scalar __glo = r(min)
scalar __ghi = r(max)
replace gender = __glo + __ghi - gender if __need_g & __ug<0.25
drop __gmin __gmax __need_g __ug

bysort __fe: egen __emin = min(edpar_n) if flag_decisionyr==1 & YR>=1997
bysort __fe: egen __emax = max(edpar_n) if flag_decisionyr==1 & YR>=1997
gen byte __need_e = (flag_decisionyr==1 & YR>=1997 & __emin==__emax & !missing(__emin))
gen double __ue = runiform()
summ edpar_n if !missing(edpar_n)
scalar __eminv = r(min)
scalar __emaxv = r(max)
replace edpar_n = cond(edpar_n==__emaxv, __eminv, edpar_n+1) if __need_e & __ue<0.30
drop __emin __emax __need_e __ue __fe

replace INSTCOD_miss = 0 if !missing(INSTCOD)
replace FULLRANK = 1 if missing(FULLRANK)

*----------------------------------------------------------------------
* Ensure many INSTFIELDYR clusters survive your regression filter
*----------------------------------------------------------------------
local targetyears 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021
local nty : word count `targetyears'

capture confirm variable pubs
if _rc gen double pubs = round(6 + 2*rnormal())
replace pubs = 0 if pubs<0 | missing(pubs)
replace FULLRANK = 1 if missing(FULLRANK)
capture confirm variable INSTCOD_miss
if _rc gen byte INSTCOD_miss = 0
replace INSTCOD_miss = 0 if missing(INSTCOD_miss)
capture confirm variable WTSURVY
if _rc gen double WTSURVY = 1
replace WTSURVY = 1 if missing(WTSURVY) | WTSURVY<=0

sort INSTCOD PHDFIELDNEW
by INSTCOD PHDFIELDNEW: gen long __row = _n
replace YR = real(word("`targetyears'", mod(__row-1, `nty')+1))
drop __row

replace PHDCY5y        = floor((YR-2.5)/5)*5  if !missing(YR)
replace years_since_phd5y = 5*floor( max( (YR - PHDCY5y), 5 ) / 5 ) if !missing(YR,PHDCY5y)

capture drop flag_decisionyr
gen byte flag_decisionyr = (YR>=1997)

capture drop maxdecisionyr
gen int maxdecisionyr = YR

set seed `SEED_td_researchblock'
capture confirm variable GOT_TENURE_NEXTYR
if _rc gen byte GOT_TENURE_NEXTYR = .
replace GOT_TENURE_NEXTYR = (runiform()<=0.35) if flag_decisionyr==1 & YR>=1997 & missing(GOT_TENURE_NEXTYR)

capture confirm variable TENURE_NEXTYR
if _rc gen byte TENURE_NEXTYR = .
replace TENURE_NEXTYR = (runiform()<=0.60) if flag_decisionyr==1 & YR>=1997 & missing(TENURE_NEXTYR)

capture drop t_GOT_TENURE_NEXTYR num_GOT_TENURE_NEXTYR
bysort YR INSTCOD: egen t_GOT_TENURE_NEXTYR = total(flag_decisionyr==1 & !missing(GOT_TENURE_NEXTYR) ///
                                                    & YR>=1997 & !missing(pubs) & !missing(FULLRANK) & INSTCOD_miss!=1)
gen int num_GOT_TENURE_NEXTYR = t_GOT_TENURE_NEXTYR

* Stable rank for topping-up
set seed `SEED_td_researchblock'
tempvar u rank misscount need
bysort YR INSTCOD: gen double `u' = runiform()
bysort YR INSTCOD (`u'): gen long `rank' = _n
bysort YR INSTCOD: gen long `misscount' = sum(flag_decisionyr==1 & missing(GOT_TENURE_NEXTYR) ///
                                              & YR>=1997 & !missing(pubs) & !missing(FULLRANK) & INSTCOD_miss!=1)
gen int `need' = 5 - t_GOT_TENURE_NEXTYR
replace `need' = 0 if `need'<0 | missing(`need')
replace GOT_TENURE_NEXTYR = 0 if flag_decisionyr==1 & missing(GOT_TENURE_NEXTYR) & `rank' <= `need' ///
                               & YR>=1997 & !missing(pubs) & !missing(FULLRANK) & INSTCOD_miss!=1
drop `u' `rank' `misscount' `need'

capture drop t_GOT_TENURE_NEXTYR num_GOT_TENURE_NEXTYR
bysort YR INSTCOD: egen t_GOT_TENURE_NEXTYR = total(flag_decisionyr==1 & !missing(GOT_TENURE_NEXTYR) ///
                                                    & YR>=1997 & !missing(pubs) & !missing(FULLRANK) & INSTCOD_miss!=1)
gen int num_GOT_TENURE_NEXTYR = t_GOT_TENURE_NEXTYR

* ONE PASS: make research interactions estimable (stable)
capture drop S FEcell
gen byte S = flag_decisionyr==1  & !missing(GOT_TENURE_NEXTYR) & YR>=1997 & !missing(pubs) ///
            & YR==maxdecisionyr & num_GOT_TENURE_NEXTYR>=5  & !missing(FULLRANK) & INSTCOD_miss!=1
egen long FEcell = group(YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHD_CAT)

tempvar off
set seed `SEED_td_FE_variation'
gen double `off' = runiform() - 0.5
replace years_since_phd5y = 5*floor(((YR - PHDCY5y) + `off')/5) if !missing(YR,PHDCY5y)
drop `off'

drop FEcell
egen long FEcell = group(YR PHDCY5y years_since_phd5y BIRTHCOUNTRY INSTCOD PHD_CAT)

bysort FEcell: egen __sd_y = sd(GOT_TENURE_NEXTYR) if S
gen byte __flat_y = (S==1 & (__sd_y==0 | __sd_y==.))
set seed `SEED_td_FE_variation'
gen double __u = runiform()
bysort FEcell (__u): replace GOT_TENURE_NEXTYR = 1 if __flat_y & GOT_TENURE_NEXTYR==0 & _n==1
bysort FEcell (__u): replace GOT_TENURE_NEXTYR = 0 if __flat_y & GOT_TENURE_NEXTYR==1 & _n==1
drop __sd_y __flat_y __u

capture drop num_GOT_TENURE_NEXTYR
bysort YR INSTCOD: egen num_GOT_TENURE_NEXTYR = ///
    total(flag_decisionyr==1 & !missing(GOT_TENURE_NEXTYR) & YR>=1997 & !missing(pubs) & !missing(FULLRANK) & INSTCOD_miss!=1)

drop S
gen byte S = flag_decisionyr==1  & !missing(GOT_TENURE_NEXTYR) & YR>=1997 & !missing(pubs) ///
            & YR==maxdecisionyr & num_GOT_TENURE_NEXTYR>=5  & !missing(FULLRANK) & INSTCOD_miss!=1

* Core covariates vary within FE cells (stable sprinkles)
set seed `SEED_td_FE_variation'
bysort FEcell: egen __emin = min(edpar_n) if S
bysort FEcell: egen __emax = max(edpar_n) if S
gen byte __flat_e = (S==1 & __emin==__emax & !missing(__emin))
replace edpar_n = 1 + mod(_n,4) if __flat_e & runiform()<.50
drop __emin __emax __flat_e

bysort FEcell: egen __gmin = min(gender) if S
bysort FEcell: egen __gmax = max(gender) if S
gen byte __flat_g = (S==1 & __gmin==__gmax & !missing(__gmin))
replace gender = 1-gender if __flat_g & runiform()<.50
drop __gmin __gmax __flat_g

bysort FEcell: egen __rmin = min(race_n) if S
bysort FEcell: egen __rmax = max(race_n) if S
gen byte __flat_r = (S==1 & __rmin==__rmax & !missing(__rmin))
replace race_n = 1 + mod(_n,5) if __flat_r & runiform()<.50
drop __rmin __rmax __flat_r

* ---------- B) RESEARCH-BLOCK ENABLERS ----------
set seed `SEED_td_researchblock'
bysort FEcell: egen __gcnt = nvals(PHD_GROUP) if S
summ PHD_GROUP if S, meanonly
local Gmin = r(min)
local Gmax = r(max)
gen double __uG = runiform()
replace PHD_GROUP = cond(PHD_GROUP<`Gmax', PHD_GROUP+1, `Gmin') if S & __gcnt==1 & __uG<.40
drop __gcnt __uG

local R1 pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn
local R2 pubs_firstauthor_rn pubs_lastauthor_rn pubs_top10cnci_sh pubs_hij_sh
local R3 pubs avg_CNCI avg_authors avg_impactfactor
local R4 pubs_firstauthor pubs_lastauthor
local R  `R1' `R2' `R3' `R4'
local K 3

tempvar u eps
bysort FEcell PHD_GROUP: gen double `u'   = .
bysort FEcell PHD_GROUP: gen double `eps' = .
bysort FEcell PHD_GROUP: gen int __r = cond(S, sum(S), .)
bysort FEcell PHD_GROUP: egen int __Ncell = max(__r)
replace `u'   = 2*(__r - ( __Ncell + 1)/2)/max(__Ncell-1,1) if S
set seed `SEED_td_researchblock'
replace `eps' = runiform() - 0.5 if S
drop __r

foreach x of local R {
    bysort FEcell PHD_GROUP: egen __nv = nvals(`x') if S
    bysort FEcell PHD_GROUP (`x'): gen int __ix = _n if S

    quietly: sum `x' if S, meanonly
    local sdx = r(sd)
    if missing(`sdx') | `sdx'==0 local sdx = 1

    replace `x' = `x' + (0.01*`sdx')*mod(__ix,`K') + 0.01*`eps' if S & (__nv<`K' | __nv==.)

    if inlist("`x'","pubs_top10cnci_sh","pubs_hij_sh") {
        replace `x' = max(0,min(1,`x')) if S
    }
    else if strpos("`x'","_rn") {
        replace `x' = max(0,min(1,`x')) if S
    }
    else {
        replace `x' = max(0.1, `x') if S
    }

    drop __nv __ix
}

bysort FEcell PHD_GROUP: egen __nb = nvals(NSFBucket) if S
replace NSFBucket = 1 + mod(_n,3) if S & (__nb==1 | missing(__nb))
drop __nb

* ---------- C) fmlo not collinear ----------
capture drop fmlo_GOT_TENURE_NEXTYR
bysort PHDFIELDNEW: egen fmlo_GOT_TENURE_NEXTYR = mean(GOT_TENURE_NEXTYR) if YR>=1997
replace fmlo_GOT_TENURE_NEXTYR = 0 if missing(fmlo_GOT_TENURE_NEXTYR)

* ---------- D) Quick sanity checks (unchanged) ----------
bysort FEcell: egen __sd_y2 = sd(GOT_TENURE_NEXTYR) if S
count if S & (__sd_y2==0 | __sd_y2==.)
di as txt "After patch: FE-cells with zero DV variation: " as res r(N)
drop __sd_y2

bysort FEcell: egen __gcnt2 = nvals(PHD_GROUP) if S
count if S & __gcnt2==1
di as txt "After patch: FE cells with single PHD_GROUP: " as res r(N)
drop __gcnt2

foreach x in pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn pubs_top10cnci_sh pubs_hij_sh ///
                 pubs avg_CNCI avg_authors avg_impactfactor {
    bysort FEcell PHD_GROUP: egen __nv2 = nvals(`x') if S
    count if S & (__nv2<`K' | __nv2==.)
    di as txt "`x' FE×GROUP cells with <`K' levels: " as res r(N)
    drop __nv2
}

* Force research variables to vary (stable)
local R1 pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn
local R2 pubs_firstauthor_rn pubs_lastauthor_rn pubs_top10cnci_sh pubs_hij_sh
local R3 pubs avg_CNCI avg_authors avg_impactfactor
local R4 pubs_firstauthor pubs_lastauthor
local R_rankshare `R1' pubs_top10cnci_sh pubs_hij_sh
local R_raw       `R3' `R4'

set seed `SEED_td_researchblock'
foreach x of local R_rankshare {
    replace `x' = runiform() if S
}
foreach x of local R_raw {
    replace `x' = 5 + 10*runiform() if S
}

bysort FEcell PHD_GROUP: egen __nb = nvals(NSFBucket) if S
replace NSFBucket = 1 + mod(_n,3) if S & (__nb==1 | missing(__nb))
drop __nb

replace PHDFIELDNEW = ceil(runiform()*10) if missing(PHDFIELDNEW)

bysort INSTCOD YR: replace edpar_n = ceil(runiform()*4)
bysort INSTCOD YR: replace gender  = ceil(runiform()*2)
bysort INSTCOD YR: replace race_n  = ceil(runiform()*5)

bysort INSTCOD YR: replace GOT_TENURE_NEXTYR = (runiform()<0.3 + 0.1*gender - 0.05*edpar_n)
bysort INSTCOD YR: replace TENURE_ELSEWHERE  = (runiform()<0.2 + 0.05*race_n)
bysort INSTCOD YR: replace TTNOTTEN_NEXTYR   = (runiform()<0.25)
bysort INSTCOD YR: replace IND_NEXTYR        = (runiform()<0.2)
bysort INSTCOD YR: replace GOV_NEXTYR        = (runiform()<0.15)
bysort INSTCOD YR: replace EDUNTT_NEXTYR     = (runiform()<0.1)
bysort INSTCOD YR: replace NW_NEXTYR         = (runiform()<0.1)

* NON-RANKED spec injections (stable)
set seed `SEED_td_NR_spec'
replace FULLRANK = .                                if runiform()<0.55
replace flag_decisionyr = 1                         if FULLRANK==. & (missing(flag_decisionyr) | runiform()<0.9)
replace INSTCOD_miss = 0                            if FULLRANK==.
replace t_TENURE_NEXTYR = ceil(5 + 10*runiform())   if FULLRANK==. & (missing(t_TENURE_NEXTYR) | t_TENURE_NEXTYR<5)

replace YR = maxdecisionyr                          if FULLRANK==.
replace YR = 1999                                   if FULLRANK==. & YR<1997

bysort INSTCOD: replace edpar_n = ceil(4*runiform())     if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace gender  = ceil(2*runiform())     if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace race_n  = ceil(5*runiform())     if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr

bysort INSTCOD: replace TENURE_NEXTYR   = (runiform() < 0.28 + 0.06*gender - 0.03*edpar_n) if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace TTNOTTEN_NEXTYR = (runiform() < 0.25)                              if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace IND_NEXTYR      = (runiform() < 0.22)                              if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace GOV_NEXTYR      = (runiform() < 0.15)                              if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace EDUNTT_NEXTYR   = (runiform() < 0.12)                              if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr
bysort INSTCOD: replace NW_NEXTYR       = (runiform() < 0.10)                              if FULLRANK==. & flag_decisionyr==1 & YR==maxdecisionyr

* Recreate cluster id, tag sample
capture drop INSTFIELDYR
egen INSTFIELDYR = group(INSTCOD PHDFIELDNEW YR)
gen byte _sample = flag_decisionyr==1 ///
    & !missing(GOT_TENURE_NEXTYR) ///
    & YR>=1997 & !missing(pubs) & YR==maxdecisionyr ///
    & num_GOT_TENURE_NEXTYR>=5  & !missing(FULLRANK) & INSTCOD_miss!=1

* --- Duplicate singletons + jitter (stable) ---
bys INSTFIELDYR: gen _nincl = sum(_sample)
bys INSTFIELDYR: replace _nincl = _nincl[_N]
gen byte _needs_dup = _sample & _nincl==1
quietly count if _needs_dup
local singletons = r(N)

expand 2 if _needs_dup
bys INSTFIELDYR: gen byte _dup = _needs_dup & _sample & _n>1

tempfile _extra
preserve
    keep if _sample & !_needs_dup
    set seed `SEED_td_dup_and_jitter'
    gen double _u2 = runiform()
    sort _u2, stable
    keep in 1/10
    drop _u2
    save "`_extra'", replace
restore
append using "`_extra'"
replace _dup = 1 if missing(_dup) & _sample

* Jitter continuous research controls (stable)
local cont_raw pubs avg_CNCI avg_authors avg_impactfactor pubs_firstauthor pubs_lastauthor
local cont_rn  pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn pubs_firstauthor_rn pubs_lastauthor_rn

set seed `SEED_td_dup_and_jitter'
foreach v of local cont_raw {
    cap confirm var `v'
    if !_rc {
        quietly summarize `v' if _sample, meanonly
        local s = r(sd)
        if missing(`s') | `s'==0 local s = 1
        replace `v' = `v' + rnormal(0, `s'*0.02) if _dup
    }
}
foreach v of local cont_rn {
    cap confirm var `v'
    if !_rc {
        quietly summarize `v' if _sample, meanonly
        local s = r(sd)
        if missing(`s') | `s'==0 local s = 1
        replace `v' = `v' + rnormal(0, `s'*0.02) if _dup
        replace `v' = max(0, min(100, `v')) if _dup
    }
}

cap confirm var NSFBucket
if !_rc {
    bys PHD_GROUP: egen _sd_nsfb = sd(NSFBucket) if _sample
    gen byte _flat_nsfb = _sample & _dup & (_sd_nsfb==0)
    set seed `SEED_td_dup_and_jitter'
    replace NSFBucket = mod(NSFBucket + round(runiform()*2 + 1), 4) if _flat_nsfb
    drop _sd_nsfb _flat_nsfb
}

drop _nincl
bys INSTFIELDYR: gen _nincl = sum(_sample)
bys INSTFIELDYR: replace _nincl = _nincl[_N]

cap confirm var GOT_TENURE_NEXTYR
if !_rc {
    set seed `SEED_td_dup_and_jitter'
    replace GOT_TENURE_NEXTYR = 1 - GOT_TENURE_NEXTYR if _dup & runiform()<0.10
}

* ========= enough variation so SEs are not missing (stable) =========
set seed `SEED_td_quickpatch'

capture drop INSTFIELDYR
egen INSTFIELDYR = group(INSTCOD PHDFIELDNEW YR)

gen byte __sample = flag_decisionyr==1 ///
    & !missing(GOT_TENURE_NEXTYR) & YR>=1997 & !missing(pubs) & YR==maxdecisionyr ///
    & num_GOT_TENURE_NEXTYR>=5 & !missing(FULLRANK) & INSTCOD_miss!=1

bys INSTFIELDYR: egen __n_incl = total(__sample)
gen byte __needs_dup = __sample & __n_incl==1
quietly count if __needs_dup
local __n_single = r(N)

expand 2 if __needs_dup
bysort INSTFIELDYR: gen byte __dup = __sample & _n>1 if __sample
replace __dup = 0 if missing(__dup)

tempfile __extra
preserve
    keep if __sample
    gen double __u2 = runiform()
    sort __u2, stable
    quietly count
    if r(N) >= 10 {
        keep in 1/10
    }
    else if r(N) > 0 {
        keep in 1/`=max(1,r(N))'
    }
    drop __u2
    save "`__extra'", replace
restore
append using "`__extra'"
replace __dup = 1 if __sample & missing(__dup)

local __cont_raw pubs avg_CNCI avg_authors avg_impactfactor pubs_firstauthor pubs_lastauthor
local __cont_rn  pubs_rn avg_CNCI_rn avg_authors_rn avg_impactfactor_rn pubs_firstauthor_rn pubs_lastauthor_rn

foreach v of local __cont_raw {
    cap confirm var `v'
    if !_rc {
        quietly summarize `v' if __sample, meanonly
        local s = r(sd)
        if missing(`s') | `s'==0 local s = 1
        replace `v' = `v' + rnormal(0, `s'*0.03) if __dup
    }
}
foreach v of local __cont_rn {
    cap confirm var `v'
    if !_rc {
        quietly summarize `v' if __sample, meanonly
        local s = r(sd)
        if missing(`s') | `s'==0 local s = 1
        replace `v' = `v' + rnormal(0, `s'*0.03) if __dup
        replace `v' = max(0, min(100, `v')) if __dup
    }
}

cap confirm var NSFBucket
if !_rc {
    bys PHD_GROUP: egen __sd_nsf = sd(NSFBucket) if __sample
    gen byte __flat_nsf = __sample & __dup & (__sd_nsf==0)
    replace NSFBucket = mod(NSFBucket + 1, 4) if __flat_nsf
    drop __sd_nsf __flat_nsf
}

cap confirm var GOT_TENURE_NEXTYR
if !_rc {
    replace GOT_TENURE_NEXTYR = 1 - GOT_TENURE_NEXTYR if __dup & runiform()<0.05
}

cap drop __u2 __n_incl __needs_dup INSTFIELDYR

expand 4
compress
save "$TEMP/tenuredecision_data", replace

** Safe guards (stable)
use "$DATA/sdrdrf_9321_working", clear
set seed `SEED_guards'
capture drop __000001
capture drop __000000
compress
save "$DATA/sdrdrf_9321_working", replace

* Housekeeping
foreach droppercent in 5 10 15 20 25 30 {
    cap erase "output_`droppercent'.dta"
}
cap erase "_aw.dta"

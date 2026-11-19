*********************************************************************************
*Create data set for "Got Tenure" regressions
*********************************************************************************
*Updated: Anna 4/27/2025

********************************************************************************
*This code creates:
*tenuredecisiondata.dta
********************************************************************************

********************************************************************************
*Note: Research output before TENURE decision - limited to those we see on the tenure track without tenure
*Note: We have individuals in the 2015 SDR who go forward to 2019 SDR and also back to 1997 SDR
*Note: We have publications up to 2017
********************************************************************************

*Load clean data
use "$DATA/sdrdrf_9321_working", clear

*Switch back sign of RANK to enable code to work for "Got Tenure"
*Replace rank variables with MINUS rank variables to aid ease of interpretation of tables and graph
foreach var in FULLRANK LOGRANK TENLOGRANK TENLOGBARANK BAFULLRANK LOGBARANK RANKGROUP_10 {
	replace `var' = -`var'
}

********************************************************************************
***Identify the likely tenure decision year(s) and generate dependent variables
********************************************************************************
* Note that these are all people we observe at least once on the tenure track without tenure at a US institution

*Generate ID and group variables
bysort REFID: egen obs_num = rank(YR)
egen REFID_num = group(REFID)
bys REFID: gen tag_REFID = 1 if _n==1

*First year observed with tenure in this data, if observed with tenure
bysort REFID: egen TENURE_MINYR = min(cond(TENURE==1,YR,.))

*Last year in data
bysort REFID: egen MAXYR = max(YR)

*Last year observed on the tenure track without tenure in our data a given institution, assuming these are likely years right before getting tenure or moving to get tenure elsewhere
bysort REFID INSTCOD: egen TT_MAXYR = max(cond(TTNOTTEN==1,YR,.))
replace TT_MAXYR = . if years_since_phd<5 /*Assume early career moves are not a result of not getting tenure*/
replace TT_MAXYR = . if LOCATIONUS!=1 /*Exclude non-US-based individuals*/

**Flag decision years (the year before a decision is likely to be made; the year before tenure would likely be given) where we observe someone again within 4 years afterwards
gen flag_decisionyr = 1 if YR==TT_MAXYR 
replace flag_decisionyr = . if TT_MAXYR==MAXYR /*Ignore likely decision years for those who's last year as TT is also their last year in the data*/
replace flag_decisionyr = . if YR>TENURE_MINYR /*Ignore likely decision years for those who already had tenure in the past*/


drop obs_num
bys REFID (YR): gen obs_num = _n  

xtset REFID_num obs_num /*set panel*/
gen yrs_until_next = F1.YR - YR
replace flag_decisionyr=. if yrs_until_next>5 /*Ignore likely decision years for those who have 5 years between the current and next survey year, leaving a large period of time where other decisions and factors could be at play*/

*Exclude those where there are apparently two sequential tenure decision points, but the first one has a missing institution code: suggests it might just have been miscoded (i.e., exclude the first year)
replace flag_decisionyr = . if F1.flag_decisionyr==1 & INSTCOD_miss==1

*Note that institution codes are DIFFERENT in 1993 and 1995 to the remaining years. Try to correct for "erroneous" decision year imputation given this
replace flag_decisionyr = . if YR==1995 & F1.flag_decisionyr==1 /*Treat these years as having missing institution codes (akin to line 62)*/
replace flag_decisionyr = . if YR==1993 & (F1.flag_decisionyr==1|F2.flag_decisionyr==1)
replace flag_decisionyr = . if YR==1995 & TENSTA=="4" & F1TENSTA=="4" /*Exclude those who have a decision year in this year but appear to be still on TT in the next survey year they appear in. This code replaces flag_decisionyr when the next year has a different INSTCOD (which could just be because of he erroneous institution codes of 1995 and 1993)*/
replace flag_decisionyr = . if YR==1993 & TENSTA=="4" & F1TENSTA=="4" 

*Note that generating flag_decisionyr could generate several decision points for each person
*Almost everyone has only one decision year: c./ 10% have more than one
bys REFID: egen num_decisionyrs = total(flag_decisionyr) 
summ num_decisionyrs if tag_REFID==1 & num_decisionyrs!=0, d

*Flag the first and last decision year (if a person has multiple)
bys REFID: egen maxdecisionyr = max(cond(flag_decisionyr==1,YR,.))
bys REFID: egen mindecisionyr = min(cond(flag_decisionyr==1,YR,.))

**Dependent variables for people's tenure status NEXT survey year (this will help indicate what happened after the tenure decision year)

drop obs_num
bys REFID (YR): gen obs_num = _n  

xtset REFID_num obs_num
gen TENURE_NEXTYR = (F1.TENURE==1)
gen TTNOTTEN_NEXTYR = (F1.TTNOTTEN==1)
gen IND_NEXTYR = (F1.INDSECTOR==1)
gen GOV_NEXTYR = (F1.GOVSECTOR==1)
gen EDUNTT_NEXTYR = (F1.EDUNTT==1)
gen NW_NEXTYR = (F1.non_working==1)

*Tenure at R1 or non R1  next year
gen TEN_NEXTYR_R1 = (F1.Current_R1==1 & TENURE_NEXTYR==1)
gen TEN_NEXTYR_NONR1 = (TENURE_NEXTYR==1 & TEN_NEXTYR_R1==0)

*Tenure at same institution next year (only for people whose TT institution we know)
gen TEN_NEXTYR_SAME = (INSTCOD_num == F1.INSTCOD_num & F1.TENURE==1)
replace TEN_NEXTYR_SAME  = . if INSTCOD_miss==1

*"Got tenure" at equivalent or higher ranked institution next year - For people at (graduate program) ranked TT institutions only 
gen GOT_TENURE_NEXTYR = 1 if F1.TENURE==1 & F1.FULLRANK<=(FULLRANK+5) & !missing(FULLRANK) & !missing(F1.FULLRANK)
replace GOT_TENURE_NEXTYR = 0 if F1.TENURE==1 & missing(GOT_TENURE_NEXTYR) & !missing(FULLRANK)
replace GOT_TENURE_NEXTYR = 0 if F1.TENURE==0 & !missing(FULLRANK)

*Tenure next year, but not at equivalent or higher ranked institution - for people at ranked TT institutions only
gen TENURE_ELSEWHERE = 1 if GOT_TENURE_NEXTYR==0 & TENURE_NEXTYR==1
replace TENURE_ELSEWHERE = 0 if !missing(GOT_TENURE_NEXTYR) & missing(TENURE_ELSEWHERE)


*Control variable: INSTITUTION's average for each of the dep vars (leaving out individual in question) from those in our data in a decision year
foreach dep in  GOT_TENURE_NEXTYR  TENURE_ELSEWHERE TENURE_NEXTYR TEN_NEXTYR_SAME  TEN_NEXTYR_R1 TEN_NEXTYR_NONR1 TTNOTTEN_NEXTYR IND_NEXTYR GOV_NEXTYR EDUNTT_NEXTYR NW_NEXTYR  {
	bys INSTCOD: egen t_`dep' = total(cond(flag_decisionyr==1,`dep',.))
	bys INSTCOD: egen c_`dep' = count(cond(flag_decisionyr==1,`dep',.))
	gen mlo_`dep' = (t_`dep'-`dep')/(c_`dep'-1)  /*-1 removes the individual in question*/
	}
	
*Control variable: broad FIELD's average for each of the dep vars (leaving out individual in question) from our data in a decision year
foreach dep in  GOT_TENURE_NEXTYR TENURE_ELSEWHERE  TENURE_NEXTYR TEN_NEXTYR_SAME  TEN_NEXTYR_R1 TEN_NEXTYR_NONR1 TTNOTTEN_NEXTYR IND_NEXTYR GOV_NEXTYR EDUNTT_NEXTYR NW_NEXTYR  {
	bys PHDFIELDNEW: egen ft_`dep' = total(cond(flag_decisionyr==1,`dep',.))
	bys PHDFIELDNEW: egen fc_`dep' = count(cond(flag_decisionyr==1,`dep',.))
	gen fmlo_`dep' = (ft_`dep'-`dep')/(fc_`dep'-1) 
	}
foreach dep in  GOT_TENURE_NEXTYR  {
	bys PHDFIELDNEW: egen fm_`dep' = mean(`dep')
	}
	
*Other control variables 
replace years_since_phd5y = 20 if years_since_phd5y>=20 & !missing(years_since_phd5y)

save "$TEMP/decisionyear_cleaned", replace

********************************************************************************
* Generate publication dataset (SIMULATED, no external merges) — STABLE
********************************************************************************
local MASTER_SEED 2112

preserve

* 1) Build decision set (REFID,YR). Prefer imputed decision years; fallback if none.
keep REFID YR flag_decisionyr
capture confirm variable flag_decisionyr
if _rc {
    di as err "flag_decisionyr not found in memory. Please run the decision-year block first."
    restore
    error 498
}

tempfile decset
keep if flag_decisionyr==1
keep REFID YR
sort REFID YR, stable              // FIXED order before random draws
count
if r(N)==0 {
    * Fallback: last observed year per REFID (deterministic)
    restore
    preserve
    keep REFID YR
    sort REFID YR, stable
    by REFID: keep if _n==_N
    save `decset', replace
}
else {
    save `decset', replace
    restore
    preserve
}

* 2) Create simulated publication-level rows per (REFID,YR)
use `decset', clear
sort REFID YR, stable
set seed `= `MASTER_SEED' + 300000'   // substream: pubs

* Random number of pubs per decision row: 0–6 with mass at 0–3
gen double __u_np = runiform()
gen n_pubs = ceil(__u_np*6)
replace n_pubs = 0 if runiform() < 0.15
expand n_pubs
drop n_pubs __u_np

* If zero rows, force exactly one pub per REFID deterministically
count
if r(N)==0 {
    use `decset', clear
    sort REFID YR, stable
    gen byte __keep = (_n==1)        // 1 pub on the first row only
    keep if __keep
    drop __keep
}

* Publication vars
set seed `= `MASTER_SEED' + 300100'   // substream: pub vars
gen str12  pub_randid = "PUB" + string(_n, "%08.0f")

* Year (mostly before/at decision, never before 1990)
gen int    PUB_YEAR = YR - ceil(runiform()*8)
replace     PUB_YEAR = YR   if runiform()<0.25
replace     PUB_YEAR = YR+1 if runiform()<0.15
replace     PUB_YEAR = 1990 if PUB_YEAR<1990

gen str12  PUB_TYPE = cond(runiform()<0.65,"Article","Review")
gen byte   PUB_HIGHIMPACTJOURNAL_BIN = (runiform()<0.30)
gen byte   PUB_LOWIMPACTJOURNAL_BIN  = (runiform()<0.25)
gen double AVG_PCT = ceil(runiform()*100)
gen double PUB_JCR_IMPACTFACTOR = .
replace     PUB_JCR_IMPACTFACTOR = runiform()*10 if PUB_YEAR>=1997 & runiform()<0.80   // ~20% missing post-97
gen int    PUB_NUM_AUTHORS = max(1, ceil(rnormal(4,1.5)))
gen int    PUB_CITES_Y5     = round(max(0, rnormal(6,5)), 1)
gen int    PUB_CITES_Y5_HIJ = round(max(0, rnormal(3,3)), 1)
gen double CNCI             = max(0, rnormal(1,0.6))
gen int    AUTHOR_POS       = min(PUB_NUM_AUTHORS, ceil(runiform()*PUB_NUM_AUTHORS))

* 3) Respect decision timing and minimal year
keep if PUB_YEAR <= (YR + 1)
drop if YR < 1995

* 4) Aggregates by (REFID, YR)
bysort REFID YR: egen pubs = count(pub_randid)

gen byte post97 = (PUB_YEAR>=1997)
bysort REFID YR: egen pubs_post97 = total(post97)

gen byte ar = inlist(PUB_TYPE,"Article","Review")
bysort REFID YR: egen pubs_ar = total(ar)

bysort REFID YR: egen pubs_hij = total(PUB_HIGHIMPACTJOURNAL_BIN)
bysort REFID YR: egen pubs_lij = total(PUB_LOWIMPACTJOURNAL_BIN)

gen byte top10cnci = (AVG_PCT>=90 & AVG_PCT<=100)
bysort REFID YR: egen pubs_top10cnci = total(top10cnci)

replace PUB_JCR_IMPACTFACTOR = 0 if missing(PUB_JCR_IMPACTFACTOR) & PUB_YEAR>=1997
bysort REFID YR: egen avg_impactfactor = mean(PUB_JCR_IMPACTFACTOR)
gen byte miss_if = missing(PUB_JCR_IMPACTFACTOR) & PUB_YEAR>=1997
bysort REFID YR: egen pubs_post97_missif = total(miss_if)

bysort REFID YR: egen avg_authors = mean(PUB_NUM_AUTHORS)

gen double oneover_authors = 1/PUB_NUM_AUTHORS
bysort REFID YR: egen effective_pubs            = total(oneover_authors)
bysort REFID YR: egen effective_pubs_ar         = total(cond(ar==1, oneover_authors, .))
bysort REFID YR: egen effective_pubs_hij        = total(cond(top10cnci==1, oneover_authors, .))
bysort REFID YR: egen effective_pubs_top10cnci  = total(cond(PUB_HIGHIMPACTJOURNAL_BIN==1, oneover_authors, .))

bysort REFID YR: egen avg_cites_y5     = mean(PUB_CITES_Y5)
bysort REFID YR: egen avg_cites_hij_y5 = mean(PUB_CITES_Y5_HIJ)

bysort REFID YR: egen avg_CNCI      = mean(CNCI)
bysort REFID YR: egen avg_CNCI_pct  = mean(AVG_PCT)

gen byte firstauthor = (AUTHOR_POS==1)
bysort REFID YR: egen pubs_firstauthor = total(firstauthor)

gen byte lastauthor = (AUTHOR_POS==PUB_NUM_AUTHORS)
bysort REFID YR: egen pubs_lastauthor  = total(lastauthor)

gen byte soloauthor = (PUB_NUM_AUTHORS==1)
bysort REFID YR: egen pubs_soloauthor  = total(soloauthor)

* 5) Collapse to one row per (REFID,YR) and save to $TEMP
keep REFID YR pubs* avg* effective*
duplicates drop
order REFID YR
save "$TEMP/premaxdecisionyr_pubs.dta", replace
restore

********************************************************************************
* Create NSF award dataset (SIMULATED, no external merges) — STABLE
********************************************************************************
preserve
    * Decision set (REFID,YR). Prefer imputed decision years; fallback if none.
    keep REFID YR flag_decisionyr
    capture confirm variable flag_decisionyr
    if _rc {
        di as err "flag_decisionyr not found. Run the decision-year section first."
        restore
        error 498
    }

    tempfile decset
    keep if flag_decisionyr==1
    keep REFID YR
    sort REFID YR, stable
    count
    if r(N)==0 {
        restore
        preserve
        keep REFID YR
        sort REFID YR, stable
        by REFID: keep if _n==_N   // last observed year as pseudo decision year
        save `decset', replace
    }
    else {
        save `decset', replace
        restore
        preserve
    }

    * Simulate awards per (REFID,YR)
    use `decset', clear
    sort REFID YR, stable
    set seed `= `MASTER_SEED' + 400000'   // substream: NSF awards

    * Draw number of awards (mass at 0–2, light tails), deterministic
    gen double __u_aw = runiform()
    gen n_awards = rpoisson(0.8)
    replace n_awards = 0 if __u_aw < 0.25
    expand n_awards
    drop n_awards __u_aw

    * If zero rows, force a minimal deterministic set
    count
    if r(N)==0 {
        use `decset', clear
        sort REFID YR, stable
        gen byte __keep = (_n==1)
        keep if __keep
        drop __keep
    }

    * Award timing relative to decision year; clip to >=1990
    set seed `= `MASTER_SEED' + 400100'   // substream: NSF vars
    gen int AwardEffectiveYear = YR - ceil(runiform()*6)
    replace AwardEffectiveYear = YR   if runiform()<0.30
    replace AwardEffectiveYear = YR+1 if runiform()<0.10
    replace AwardEffectiveYear = 1990 if AwardEffectiveYear<1990

    * Simulated award amounts ($). Skewed right, allow zeros.
    gen double TotalIntendedAmount = round(exp(rnormal(11.0, 1.0)) - 30000, 1)
    replace TotalIntendedAmount = 0 if runiform() < 0.20
    replace TotalIntendedAmount = 0 if TotalIntendedAmount < 0

    * Keep only awards up to decision year + 1; drop very early decisions
    keep if AwardEffectiveYear <= (YR + 1)
    drop if YR < 1995

    * Aggregate to decision row
    bysort REFID YR: egen NSFAwards      = count(AwardEffectiveYear)
    bysort REFID YR: egen NSFAwardValue  = total(TotalIntendedAmount)

    keep REFID YR NSFAwards NSFAwardValue
    duplicates drop
    order REFID YR
    save "$TEMP/premaxdecisionyr_NSF.dta", replace
restore

*---------- Clean & uniquify premaxdecisionyr_pubs -----------------------------
preserve
    use "$TEMP/premaxdecisionyr_pubs", clear

    * Make sure REFID and YR are numeric and nonmissing
    capture confirm numeric variable REFID
    if _rc destring REFID, replace force
    capture confirm numeric variable YR
    if _rc destring YR, replace force
    drop if missing(REFID) | missing(YR)

    * If any duplicates remain, collapse to one row per REFID YR
    quietly ds REFID YR, not
    local metrics `r(varlist)'
    * Choose sensible aggregations: sums for counts, means for averages
    collapse ///
        (sum) pubs pubs_post97 pubs_ar pubs_hij pubs_lij pubs_top10cnci ///
              pubs_firstauthor pubs_lastauthor pubs_soloauthor ///
              effective_pubs effective_pubs_ar effective_pubs_hij ///
              effective_pubs_top10cnci ///
        (mean) avg_CNCI avg_CNCI_pct avg_cites_y5 avg_cites_hij_y5 avg_impactfactor avg_authors, ///
        by(REFID YR)

    isid REFID YR
    save "$TEMP/premaxdecisionyr_pubs_u", replace
restore

*---------- Clean & uniquify premaxdecisionyr_NSF ------------------------------
preserve
    use "$TEMP/premaxdecisionyr_NSF", clear

    capture confirm numeric variable REFID
    if _rc destring REFID, replace force
    capture confirm numeric variable YR
    if _rc destring YR, replace force
    drop if missing(REFID) | missing(YR)

    * If duplicates, sum counts/values to a single row per REFID YR
    collapse (sum) NSFAwards NSFAwardValue, by(REFID YR)

    isid REFID YR
	tab YR
    save "$TEMP/premaxdecisionyr_NSF_u", replace
restore

	
********************************************************************************
*Merge publication and NSF awards into SDR
********************************************************************************
merge m:1 REFID YR using "$TEMP/premaxdecisionyr_pubs_u", gen(_m_preten_pubs)
merge m:1 REFID YR using "$TEMP/premaxdecisionyr_NSF_u",  gen(_m_preten_nsf)

********************************************************************************
*Generate further variables using now merged pubs and NSF data
********************************************************************************

*Number of people observed at tenure juncture with certain next year conditions at each current institution WITH publications
foreach dep in  GOT_TENURE_NEXTYR  TENURE_NEXTYR TEN_NEXTYR_SAME    {
bys INSTCOD: egen num_`dep' = count(cond(flag_decisionyr==1 & YR==maxdecisionyr & YR>=1997 & pubs!=.,`dep',.))
}

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

*Fixed effect for Field Rank Group BY PhD_Cat
gen RANKGROUP = floor(FULLRANK/10)
egen RANKGROUPCAT = group(RANKGROUP PHD_CAT)
egen INSTBYCAT = group(INSTCOD PHD_CAT)
egen INSTBYFIELD = group(INSTCOD PHDFIELDNEW)

*Replace rank variables with MINUS rank variables to aid ease of interpretation of tables and graph
foreach var in FULLRANK LOGRANK TENLOGRANK TENLOGBARANK BAFULLRANK LOGBARANK RANKGROUP_10 {
	replace `var' = -`var'
}

save "$TEMP/tenuredecision_data", replace
tab YR

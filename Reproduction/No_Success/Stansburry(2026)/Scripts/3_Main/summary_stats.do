*********************************************************************************
*Summary Statistics of Cleaned and Matched Data
*********************************************************************************

********************************************************************************
*This code creates:
*$desc/sdrdrf_sumstats, ///
 $desc/sed_sumstats, ///
 $desc/sdrdrf21_sumstats
********************************************************************************

********************************************************************************
*Matched SDR-DRF Summary Stats
********************************************************************************

*Load data
use "$DATA/sdrdrf_9321_working", clear

*How many unique individuals are missing parental education variable
distinct REFID
distinct REFID if missing(edpar_n)

*Drop all those without parental education
drop if missing(edpar_n)

*Summarize gender, race, and birth region
tab GENDER
tab race_n
count if missing(race_n)
count
drop if missing(race_n)
tab BIRTHCON

*Summarize PhD FIeld
distinct PHD_GROUP
distinct PHD_CAT
distinct PHDFIELDNEW
distinct PHDFIELD

*Summarize Earnings
count if   LFSTAT=="1" & LOCATIONUS==1 & YR!=1993
count if missing(lnEARN) & LOCATIONUS==1 &  LFSTAT=="1" & YR!=1993 
summ EARN if LFSTAT=="1" & LOCATIONUS==1 & YR==2021, d

*Summarize Debt
count if PHDCY>=2000
summ UDEBTLVL
summ GDEBTLVL
count if !missing(ugdebttot)
count

*Summarize number of surveys per individual
bys REFID: egen numsurveys = count(YR)
distinct REFID
bys REFID: gen tagREFID = 1 if _n==1
summ numsurveys if tagREFID==1, d

*Summarize ranks
count
count if missing(PHDRANK)
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & !missing(FULLRANK)
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & !missing(BAFULLRANK)
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & missing(BAFULLRANK) & !missing(FULLRANK)
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & !missing(BAFULLRANK) & missing(FULLRANK)
tab INSTCOD if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & missing(BAFULLRANK) & !missing(FULLRANK), sort
tab INSTCOD if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & !missing(BAFULLRANK) & missing(FULLRANK), sort

*Summarize Carnegie
count if (TENURETRACK==1|TENURE==1) & LOCATIONUS==1 & INSTCOD_miss!=1 & !missing(Current_R1) & Current_R1_miss!=1

*Unweighted shares and counts of key variables
foreach var in TENURETRACK TENURE TEN_R1 {
if "`var'"=="TENURETRACK"{
bys YR `var': egen `var'_total_uw = total(cond(`var'==1 & TENURE==0 & LOCATIONUS==1, `var',.))
bys YR edpar_n: egen `var'_count_uw = total(cond(`var'==1 & TENURE==0 & LOCATIONUS==1,`var',.))
}
else{
bys YR `var': egen `var'_total_uw = total(cond(`var'==1 & LOCATIONUS==1, `var',.))
bys YR edpar_n: egen `var'_count_uw = total(cond(`var'==1 & LOCATIONUS==1,`var',.))
}
gen `var'_share_uw = `var'_count_uw / `var'_total_uw
}

*Weighted shares and counts of key variables
foreach var in TENURETRACK TENURE TEN_R1 {
if "`var'"=="TENURETRACK"{
bys YR `var': egen `var'_total_w = total(cond(`var'==1 & TENURE==0 & LOCATIONUS==1, WTSURVY,.))
bys YR edpar_n: egen `var'_count_w = total(cond(`var'==1 & TENURE==0 & LOCATIONUS==1,WTSURVY,.))
}
else{
bys YR `var': egen `var'_total_w = total(cond(`var'==1 & LOCATIONUS==1, WTSURVY,.))
bys YR edpar_n: egen `var'_count_w = total(cond(`var'==1 & LOCATIONUS==1, WTSURVY,.))
}
gen `var'_share_w = `var'_count_w / `var'_total_w
}

*Generate labels
label var YR "Survey Year"
label var edpar_n "Parental education"
label var TENURETRACK_share_uw "Share of PhDs who are on the tenuretrack by parental education [Unweighted]"
label var TENURETRACK_count_uw "Count of firstgen PhDs who are on the tenuretrack by parental education [Unweighted]" 
label var TENURE_share_uw "Share of PhDs who are tenured by parental education [Unweighted]"
label var TENURE_count_uw  "Count of PhDs who are tenured by parental education [Unweighted]"
label var TEN_R1_share_uw  "Share of PhDs who are tenured at an R1 by parental education [Unweighted]"
label var TEN_R1_count_uw  "Count of PhDs who are tenured at an R1 by parental education [Unweighted]" 
label var TENURETRACK_share_w "Share of PhDs who are on the tenuretrack by parental education [Weighted]"
label var TENURETRACK_count_w "Count of PhDs who are on the tenuretrack by parental education [Weighted]"
label var TENURE_share_w "Share of PhDs who are tenured by parental education [Weighted]"
label var TENURE_count_w "Count of PhDs who are tenured by parental education [Weighted]"
label var TEN_R1_share_w "Share of PhDs who are tenured at an R1 by parental education [Weighted]"
label var TEN_R1_count_w "Count of PhDs who are tenured at an R1 by parental education [Weighted]"

*Keep relevant variables
keep YR edpar_n TENURETRACK_share_uw TENURETRACK_count_uw TENURE_share_uw TENURE_count_uw TEN_R1_share_uw TEN_R1_count_uw TENURETRACK_share_w TENURETRACK_count_w TENURE_share_w TENURE_count_w TEN_R1_share_w TEN_R1_count_w 
	
*Drop publicates
duplicates drop
	
egen nmcount = rownonmiss(_all)
drop if nmcount<14
drop nmcount

*For now, only keep weighted shares and counts for disclosure reasons
drop *_uw

*Save dataset
save "$DESC/sdrdrf_sumstats", replace

* -----------------------------------------------------------------------------
* Create version for PhD Recipients (Uses different year variable)
use "$DATA/sdrdrf_9321_working", clear

*Drop all those without parental education
drop if missing(edpar_n)

*Summarize gender, race, and birth region
tab race_n
count if missing(race_n)
count
drop if missing(race_n)

keep if PHDCY >= 1990 

* Create share and counts (unweighted) of PhD recipients per year
bys PHDCY: egen phd_total_uw = count(DRF_ID)
bys PHDCY edpar_n: egen phd_count_uw = count(DRF_ID)
gen phd_share_uw = phd_count_uw / phd_total_uw

label var phd_count_uw "Count of PhD recipients by parental education [Unweighted]"
label var phd_share_uw "Share of PhD recipients by parental education [Unweighted]"

*Keep relevant variables and drop duplicates
keep PHDCY edpar_n phd_share_uw phd_count_uw
duplicates drop

save "$DESC/phd_rec_sdrdrf_sumstats", replace
	
********************************************************************************
*2021 SDR Summary Stats
********************************************************************************

*Load data
use "$DATA/sdrdrf_9321_working", clear

drop if missing(edpar_n)

*Keep based on typical regression restrictions
keep if years_since_phd<40 & years_since_phd>=10 & LFSTAT=="1" & LOCATIONUS==1

*Keep only 2021 data
keep if YR==2021

*Tabulate parental education shares
tab edpar_n [aw=WTSURVY]

*Unweighted shares and counts
bys years_since_phd5y edpar_n: egen total_uw = count(REFID)
foreach var in TENURE TEN_R1   TEN_TOP50ANY TEN_TOP50 {
bys years_since_phd5y edpar_n: egen `var'_count_uw = total(cond(`var'==1,`var',.))
gen `var'_share_uw = `var'_count_uw / total_uw
}

*Weighted shares and counts
bys years_since_phd5y edpar_n: egen total_w = total(WTSURVY)
foreach var in TENURE TEN_R1   TEN_TOP50ANY TEN_TOP50 {
bys years_since_phd5y edpar_n: egen `var'_count_w = total(cond(`var'==1,WTSURVY,.))
gen `var'_share_w = `var'_count_w / total_w
}

keep years_since_phd5y edpar_n *_share* *_count* total_w total_uw
duplicates drop

*Generate labels
label var edpar_n "Parental education"
label var years_since_phd5y "Number of years since PhD in 5-year buckets"
label var TENURE_share_uw "Share of PhDs who are tenured by parental education [Unweighted]"
label var TENURE_count_uw  "Count of PhDs who are tenured by parental education [Unweighted]"
label var TEN_R1_share_uw  "Share of PhDs who are tenured at an R1 by parental education [Unweighted]"
label var TEN_R1_count_uw  "Count of PhDs who are tenured at an R1 by parental education [Unweighted]" 
label var TEN_TOP50ANY_share_uw "Share of PhDs who are tenured at a top 50 ranked institution (any) by parental education [Unweighted]"
label var TEN_TOP50_count_uw "Count of firstgen PhDs who are tenured at a top 50 ranked institution (grad)  by parental education [Unweighted]" 
label var TEN_TOP50_share_uw "Share of PhDs who are tenured at a top 50 ranked institution (grad) by parental education [Unweighted]"
label var TEN_TOP50ANY_count_uw "Count of firstgen PhDs who are tenured at a top 50 ranked institution (any)  by parental education [Unweighted]" 
label var TENURE_share_w "Share of PhDs who are tenured by parental education [Weighted]"
label var TENURE_count_w "Count of PhDs who are tenured by parental education [Weighted]"
label var TEN_R1_share_w "Share of PhDs who are tenured at an R1 by parental education [Weighted]"
label var TEN_R1_count_w "Count of PhDs who are tenured at an R1 by parental education [Weighted]"
label var TEN_TOP50ANY_share_w "Share of PhDs who are tenured at a top 50 ranked institution (any) by parental education [Weighted]"
label var TEN_TOP50ANY_count_w "Count of firstgen PhDs who are tenured at a top 50 ranked institution (any)  by parental education [Weighted]" 
label var TEN_TOP50_share_w "Share of PhDs who are tenured at a top 50 ranked institution (grad) by parental education [Weighted]"
label var TEN_TOP50_count_w "Count of firstgen PhDs who are tenured at a top 50 ranked institution (grad) by parental education [Weighted]" 
	
*For now, only keep weighted shares and counts for disclosure reasons
drop *_uw

*Save dataset
save "$DESC/sdrdrf21_sumstats", replace



*Generate totals for analyses in paper
*aggrgate over 5-year buckets
bys edpar_n: egen tot = total(total_w)
foreach var in TENURE TEN_R1 TEN_TOP50ANY TEN_TOP50 {
	bys edpar_n: egen tot_`var' = total(`var'_count_w)
	gen sh_`var' = tot_`var'/tot
}
keep edpar_n sh_*
duplicates drop




********************************************************************************
*Summary Stats for main Table (Table 2 outcomes)
********************************************************************************

*Load data
use "$DATA/sdrdrf_9321_working", clear

local keepvars YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY WTSURVY edpar_n gender race_n
foreach keepvar of local keepvars {
	local keepcond `keepcond' & !missing(`keepvar') 
}
keep  if LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40 `keepcond'

foreach var in PHD_GROUP edpar_n gender race_n {
	tab `var' [aw=WTSURVY]
}


*Load data
use "$DATA/sdrdrf_9321_working", clear
local keepvars YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY WTSURVY edpar_n gender race_n
foreach keepvar of local keepvars {
	local keepcond `keepcond' & !missing(`keepvar') 
}
keep  if LFSTAT=="1"  & LOCATIONUS==1  `keepcond'
foreach var in TENURETRACK INDSECTOR GOVSECTOR EDUNTT  {
	summ `var' [aw=WTSURVY]
}


************************************************
* Updated summary stats for Table 1
************************************************

* Create summary stats for table 1; Sample SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

drop if missing(edpar_n)

*Filter based on usual regression restrictions
keep if years_since_phd<40 & years_since_phd>=10 & LFSTAT=="1" & LOCATIONUS==1

*Tabulate parental education shares to check sample size
foreach var in TENURE TEN_R1 TEN_TOP50{
	tab edpar_n `var'
}  

* Collapse means for table
collapse (mean) TENURE TEN_R1 TEN_TOP50 , by(edpar_n)

foreach var in TENURE TEN_R1 TEN_TOP50 {
	replace `var' = `var'*100 // percent for table
	gen str10 `var'_str = string(`var', "%4.1f") + "%"
}

* Auto label for edpar_n
label define edpar_label 1 "Less than college" 2 "College" 3 "Non-PhD Grad Degree" 4 "PhD"
label values edpar_n edpar_label
decode edpar_n, gen(edpar_label)

* Save to a file for export
cap file close textout
file close _all
local outfile "$tables/tenure_by_edpar.tex"
file open texout using "`outfile'", write replace

* begin file
file write texout "\begin{table}[htbp]\centering" _n
file write texout "\caption{Tenure Outcomes of US PhD Recipients by Parental Education Group}" _n
file write texout "\label{tab:descriptives}" _n
file write texout "\begin{tabular}{lccc} &&& \\ \hline" _n
file write texout "Parental & Share tenured & Share tenured & Share tenured \\" _n
file write texout "education & anywhere & at R1 & at top 50 \\ \hline" _n

quietly {
	forvalues i=1/`=_N' {
		local pe = edpar_label[`i']
		local s1 = TENURE_str[`i']
		local s2 = TEN_R1_str[`i']
		local s3 = TEN_TOP50_str[`i']
		file write texout "`pe' & `s1' & `s2' & `s3' \\" _n
	}
}

file write texout "\bottomrule" _n
file write texout "\end{tabular}" _n
file write texout "\end{table}" _n
file close texout

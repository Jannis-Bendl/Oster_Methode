**Quasi-LEE Bounds exercise
**Question: what degree of differential selection on ability would we need for first-gen vs grad-parent group to explain our tenure log rank or tenure at R1 results?

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

********************************************************************************
*TENURE RANK RESULT
********************************************************************************
est clear

drop if missing(TENLOGRANK)
keep if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40

*Extract residuals from tenure rank regression without including parental education as a regressor
local dep TENLOGRANK
local weight WTSURVY
local controls
local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
local fes YR PHDFIELDNEW PHDINST PHDCY5y years_since_phd5y BIRTHCOUNTRY
local se cluster PHDPROGRAMYR

qui reghdfe `dep' gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se') residuals
predict resid, r

*Rank individuals by whether they performed better or worse than we would predict - WITHIN edpar group
drop if missing(resid)
bys edpar_n: egen resid_rank = rank(resid) /*This gives the most negative residuals rank 1. Because rank is coded in the negative, a more positive residual means you're at a better institution than you would predict and vice versa*/
bys edpar_n: egen count = count(DRF_ID)
gen resid_percentilerank = resid_rank/count
gen abovemedian = 1 if resid_percentilerank>=0.5
replace abovemedian = 0 if resid_percentilerank<0.5


****
*QUESTION: what share of the WORST no BA people and BEST Grad people do we have to drop before we equalize the gap?
*Operationalized as: Drop random selection of worst half of First Gen and best half of Grad Parent

*Set seed to identify (quasi)random observations to drop
set seed 23019384 /*arbitrarily chosen but must keep the same to replicate results*/

*Set share of observations from above- or below-median residual to drop
foreach droppercent in 5 10 15 20 25 30  {
local dropshare = `droppercent'/100

*Run many regressions randomly dropping different observations
tempname results 
postfile `results'  coefa using "output_`droppercent'", replace

forvalues j = 1/100 {
preserve 
bys edpar_n abovemedian: gen random = runiform(0,1)
*drop if random<=`dropshare' & abovemedian==0 & edpar_n==1
drop if random<=`dropshare' & abovemedian==1 & edpar_n==3

local dep TENLOGRANK
local weight WTSURVY
local controls
local cond if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 
local condnote1 if years_since_phd greater than or equal to 10 and years_since_phd less than 40 and
local condnote2 LFSTAT equals 1 and LOCATIONUS equals 1
local fes YR PHDCY5y years_since_phd PHDFIELDNEW PHDINST BIRTHCON
local se cluster REFID
local covars edpar_n

 reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se') residuals
	post `results' (_b[1.edpar_n])
	
 restore
}
postclose `results'

}

* Check nb of observations in above regressions (edpar_n == 1)
tab edpar_n if years_since_phd>=10 & years_since_phd<40  & LFSTAT=="1"  & LOCATIONUS==1 & !missing(gender) &!missing(race_n) &!missing(WTSURVY) &!missing(TENLOGRANK) & !missing(YR) &!missing(PHDCY5y) &!missing(years_since_phd) & !missing(PHDFIELDNEW) & !missing(PHDINST) &!missing(BIRTHCON)

preserve
foreach droppercent in 5 10 15 20 25{
use "$TEMP/output_`droppercent'", clear
di "`droppercent' percent"
egen mean = mean(coefa)
summ mean
}
restore

* Output table:
tempname memhold
tempfile results
postfile `memhold' int droppercent double mean using `results', replace

foreach droppercent in 5 10 15 20 25{
use "$TEMP/output_`droppercent'", clear
egen mean = mean(coefa)
post `memhold' (`droppercent') (m)
cap erase "$TEMP/output_`droppercent'.dta"

}
cap erase "$TEMP/output_30.dta"

postclose `memhold'
use `results', clear
gen mean_fmt =  round(mean, .001)

mkmat mean_fmt, matrix(table)
matrix colnames table = "Mean Tenure Ranking Gap"
matrix rownames table = "5\% Drop" "10\% Drop" "15\% Drop" "20\% Drop" "25\% Drop"

esttab matrix(table) using "$tables/bounding_exercise.tex", replace ///
noobs nonumber nomtitle ///
label title("Bounding Exercise") ///
varwidth(2) ///
addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'.")

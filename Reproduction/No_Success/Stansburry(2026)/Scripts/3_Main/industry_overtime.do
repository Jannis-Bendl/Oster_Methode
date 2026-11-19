*********************************************************************************
* INDUSTRY gaps over time -  coefficient plot 
**********************
*APRIL 2025 UPDATED


*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

*Generate dummies for graph
	
cap drop firstgen
gen firstgen = (edpar_n==1)
gen baparent = (edpar_n==2)
gen phdparent = (edpar_n==4)
foreach var in firstgen baparent phdparent {
	replace `var' = . if missing(edpar_n)
}

levelsof years_since_phd5y, local(levels) 
	foreach i of local levels {
		gen y`i' = (years_since_phd5y==`i')
		gen fg_y`i' = firstgen*y`i'
		gen ba_y`i' = baparent*y`i'
		gen phd_y`i' = phdparent*y`i'
	}
*Group together years 31-40 b/c small sample sizes
foreach prefix in fg_ ba_ phd_ {
	replace `prefix'y30 = 1 if `prefix'y35 ==1 
}
	
gen lnplus1SUPERVISEES = ln(SUPERVISEES+1)

replace JOBSATIS_num = -JOBSATIS_num

replace topmanager = . if topmanager_miss==1
	

*Industry over time
local weight WTSURVY
local sector INDSECTOR
foreach dep in  lnEARN topmanager    {

local controls
local cond if LOCATIONUS==1 & `sector'==1 & years_since_phd<40 & topmanager_miss!=1
local condnote1 if  years_since_phd less than 40 and LOCATIONUS equals 1 and `sector' equals 1
local fes YR PHDCY5y PHDINST PHDFIELDNEW BIRTHCOUNTRY   years_since_phd
local se cluster PHDPROGRAMYR
di "`sector': `dep'"
   qui  reghdfe `dep' y5 y10 y15 y20 y25 y30 y35 ///
  fg_y0 fg_y5 fg_y10 fg_y15 fg_y20 fg_y25 fg_y30  ///
  ba_y0 ba_y5 ba_y10 ba_y15 ba_y20 ba_y25 ba_y30  ///
  phd_y0 phd_y5 phd_y10 phd_y15 phd_y20 phd_y25 phd_y30  ///
  gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
 est sto e_`dep'
}

coefplot ///
	e_lnEARN, vertical keep(*fg*) yline(0) xtitle("Years since PhD")  ///
	coeflabels(fg_y0 = "1-4" fg_y5 = "5-9" ///
	fg_y10 = "10-14" fg_y15 = "15-19" ///
	fg_y20 = "20-24" fg_y25 = "25-29" fg_y30 = "31-39")  ///
	ytitle("Class gap (log)") ///
	title(Log(Earnings)) ///
	byopts(yrescale) ///
	name(earnings_plot, replace)
		
coefplot ///
	e_topmanager, vertical keep(*fg*) yline(0) xtitle("Years since PhD")  ///
	coeflabels(fg_y0 = "1-4" fg_y5 = "5-9" ///
	fg_y10 = "10-14" fg_y15 = "15-19" ///
	fg_y20 = "20-24" fg_y25 = "25-29" fg_y30 = "31-39")  ///
	ytitle("Class gap (percentage points)") ///
	title(Prob(Manager)) ///
	byopts(yrescale) ///
	name(manager_plot, replace)
		
graph combine earnings_plot manager_plot, row(1) 
graph export "$figures/industry_seniority_overtime.pdf", replace
	
	
*Sample size for figure
preserve
keep if LOCATIONUS==1 & INDSECTOR==1 & years_since_phd<40 
foreach var in YR PHDCY5y PHDFIELDNEW PHDINST BIRTHCON  gender race_n edpar_n years_since_phd5y{
	drop if missing(`var')
}
//tab edpar_n years_since_phd5y if !missing(SUPERVISEES)
tab edpar_n years_since_phd5y if !missing(lnEARN)
tab edpar_n years_since_phd5y if !missing(topmanager)
//tab edpar_n years_since_phd5y if !missing(anymanager)
restore

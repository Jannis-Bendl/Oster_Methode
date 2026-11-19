*********************************************************************************
*Robustness Checks for Baseline Regressions
*********************************************************************************

********************************************************************************
*This code creates:
*robstuness_diff_dep1.tex ///
robstuness_diff_dep2.tex /// 
 diff_spec_TEN_R1.pdf, ///
 diff_spec_TEN_TOP50.pdf, ///
 diff_spec_TENLOGRANK.pdf, ///
 diff_spec_TENLOGBARANK.pdf, ///
 diff_year_TENURE.pdf, ///
 diff_year_TEN_R1.pdf, ///
 diff_year_TEN_TOP50.pdf, ///
 diff_year_TENLOGRANK.pdf, ///
 diff_year_TENLOGBARANK.pdf
********************************************************************************

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

*********************************************************************************
*Different dependent variables (Tenure insitution is a research insitution, tenure insitution is an R1 OR R2, tenure insitution is a top 50 progam (any ranking), tenure insitution is a top 20 program, tenure insitution graduate program rank (not logged), tenure insitution BA rank (not logged))
*********************************************************************************
est clear

foreach weight in  WTSURVY {

local depvarlist TEN_RESEARCH TEN_R1R2 TEN_TOP50 TEN_TOP50ANY RANKGROUP_10 FULLRANK BAFULLRANK LOGBARANK RANK_TOP10 RANK_11to25 RANK_26to50 RANK_51to100 RANK_101plus NONRANKED

foreach dep of local depvarlist{

local cond if TENURE==1   & LOCATIONUS==1 & years_since_phd>=10  & years_since_phd<40
local condnote1 if TENURE equals 1 and LOCATIONUS equals 1 and  years_since_phd is greater than or 
local condnote2 equal to 10 and years_since_phd is less than 40 
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

 reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	}
}


estfe *`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")

esttab e_TEN_RESEARCH e_TEN_R1R2 e_TEN_TOP50 e_TEN_TOP50ANY e_RANKGROUP_10 e_FULLRANK e_BAFULLRANK e_LOGBARANK using "$tables/robustness_diff_dep1.tex", replace ///
title(Tenure Institution Type - Robustness Check (Different DVs) \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Research" "R1 or R2" "Top 50" "Top 50 (Any)" "Rank Group" "Rank" "BA Rank" "Log BA Rank") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by WTSURVY." "New DVs: TEN_RESEARCH (Tenure Research - Binary) TEN_R1R2" "(Tenure R1 or R2 - Binary) TEN_TOP50ANY (Tenure Any Top 50 Rank - Binary) TEN_TOP20" "(Tenure Top 20 - Binary) TENFULLRANK (Tenure FULLRANK) TENBAFULLRANK (Tenure BA FULLRANK)")
	
	
esttab e_RANK_TOP10 e_RANK_11to25 e_RANK_26to50 e_RANK_51to100 e_RANK_101plus e_NONRANKED using "$tables/robustness_diff_dep2.tex", replace ///
title(Tenure Institution Type - Robustness Check (Different DVs) \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom" "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Top 10" "11-25" "26-50" "51-100" "101+" "Non-ranked") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "`condnote2'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by WTSURVY.")


*********************************************************************************
*Different specifications (Alternate program rank FEs, PhD Program X Decade FE, saturated Survey year, age group, PhD year, and Years since PhD FEs, narrow PhD field FEs, birth country FEs (instead of birth continent))
*********************************************************************************
local depvarlist TENURE TEN_R1 TENLOGRANK lnEARN JOBSATIS_num

foreach weight in  WTSURVY {
foreach dep of local depvarlist{
	local controls
	local condnote1 if years_since_phd is greater than or equal to 10 and years_since_phd is less 
	local condnote2 than 40 and LOCATIONUS equals 1 and LFSTAT equals 1 (for TENURE) or TENURE equals 1 (for all other outcomes)
	local fes YR PHDCY5y years_since_phd5y PHDINST PHDFIELDNEW BIRTHCOUNTRY
	local se cluster PHDPROGRAMYR
	local covars edpar_n race_n gender
	
		*Conditions for extensive vs intensive margin regressions
		if "`dep'"=="TENURE" {
					local cond if  LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
		}
		else {
					local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
		}

	
	*Baseline
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_1_`weight'
	
	*Sample restriction: 10-29 years post PhD
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' & years_since_phd<=30  [aw=`weight'], absorb(`fes') vce(`se')
	est sto e_`dep'_2_`weight'
	
	*PhD Program X Decade FEs
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond'  [aw=`weight'], absorb(YR PHDPROGRAMDECADE years_since_phd5y  BIRTHCOUNTRY) vce(`se')
	est sto e_`dep'_3_`weight'
		
	*Saturated Survey year, age group, PhD year, and Years since PhD FEs
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(YR PHDCY AGE5y years_since_phd  PHDINST PHDFIELDNEW BIRTHCOUNTRY) vce(`se')
	est sto e_`dep'_4_`weight'
	
	*Narrow PhD field FEs
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(YR PHDCY5y years_since_phd PHDFIELD PHDINST BIRTHCOUNTRY) vce(`se')
	est sto e_`dep'_5_`weight'
	
	*Cluster standard errors at PhD program level
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(cluster PHDPROGRAM)
	est sto e_`dep'_6_`weight'

	
	*Cluster standard errors at PhD program X Decade level
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(cluster PHDPROGRAMDECADE)
	est sto e_`dep'_7_`weight'
	
	*No weights
	qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=one], absorb(`fes') vce(`se')
	est sto e_`dep'_1_one

}
}

foreach dep of local depvarlist {
estfe e_`dep'_1_*WTSURVY  e_`dep'_2_*WTSURVY  e_`dep'_3_*WTSURVY e_`dep'_4_*WTSURVY e_`dep'_5_*WTSURVY e_`dep'_6_*WTSURVY e_`dep'_7_*WTSURVY e_`dep'_1_*one, labels(YR "Survey Year FE" AGE5y "Age (5-Year Buckets) FE" PHDCY "PhD Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" years_since_phd "Years Since PhD FE" PHDFIELDNEW "PhD Field FE" PHDFIELD "PhD Field (Narrow) FE" PHDINST "PhD Institution FE" PHDRANK "PhD Rank FE" PHDPROGRAMDECADE "PhD Decade FE" BIRTHCON "Birth Continent FE" BIRTHCOUNTRY "Birth Country FE") 
}


*********************************************************************************
*Each survey year separately (Rank variables are not available for 1995 and 1997 due to insitution code differences)
*NOTE: We don't do PHDPROGRAM FEs here because it soaks up too much variation (e.g. in tenure rank regressions we have 500 FEs and 1000 obs per year)
*********************************************************************************
foreach weight in  WTSURVY {
local depvarlist TENURE TEN_R1 TENLOGRANK lnEARN JOBSATIS_num
foreach dep of local depvarlist{


local controls
local condnote1 if years_since_phd is greater than or equal to 10 and years_since_phd is less 
local condnote2 than 40 and LOCATIONUS equals 1 and LFSTAT equals 1 // (for TENURE)
local condnote3 than 40 and LOCATIONUS equals 1 and TENURE equals 1 // (for all other outcomes)
local fes YR PHDCY5y years_since_phd5y PHDINST PHDFIELDNEW BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

	
		*Conditions for extensive vs intensive margin regressions
		if "`dep'"=="TENURE" {
					local cond if  LFSTAT=="1"  & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
		}
		else {
					local cond if TENURE==1 & LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
		}


	*No rank data for 1993 or 1995 so adjust years to loop over them accordingly
	if "`dep'"=="TENURE" | "`dep'"=="TEN_R1" {
		local years 1993 1995 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021
			}
	else if "`dep'" == "JOBSATIS_num" {
		local years 1997 2003 2006 2008 2010 2013 2015 2017 2019 2021
	}
	else if "`dep'" == "lnEARN" {
		local years 1995 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021
	}
	else {
			local years 1997 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021
		}

foreach y of local years{
qui reghdfe `dep' ib3.edpar_n gender ib5.race_n `controls' `cond' & YR==`y' [aw=`weight'], absorb(`fes') vce(`se') //
	est sto e_`dep'_`y'_`weight'
	qui sum `dep' [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	

}

if "`dep'"=="TENURE" {
*First half of the years
estfe e_`dep'_1993_`weight' e_`dep'_1995_`weight' e_`dep'_1997_`weight' e_`dep'_1999_`weight' e_`dep'_2001_`weight' e_`dep'_2003_`weight' e_`dep'_2006_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")
}


else if "`dep'"=="TEN_R1" {
*First half of the years
estfe e_`dep'_1993_`weight' e_`dep'_1995_`weight' e_`dep'_1997_`weight' e_`dep'_1999_`weight' e_`dep'_2001_`weight' e_`dep'_2003_`weight' e_`dep'_2006_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE") 
}

else if "`dep'"=="JOBSATIS_num" {
*First half of the years 
estfe e_`dep'_1997_`weight' e_`dep'_2003_`weight' e_`dep'_2006_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE") 
}

else if "`dep'"=="lnEARN" {
*First half of the years 
estfe e_`dep'_1995_`weight' e_`dep'_1997_`weight' e_`dep'_1999_`weight' e_`dep'_2001_`weight' e_`dep'_2003_`weight' e_`dep'_2006_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE")
}

else {
*First half of the years
estfe e_`dep'_1997_`weight' e_`dep'_1999_`weight' e_`dep'_2001_`weight' e_`dep'_2003_`weight' e_`dep'_2006_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE") 
}

*Second half of the years
estfe e_`dep'_2008_`weight' e_`dep'_2010_`weight' e_`dep'_2013_`weight' e_`dep'_2015_`weight' e_`dep'_2017_`weight' e_`dep'_2019_`weight' e_`dep'_2021_`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5 Year Buckets) FE" years_since_phd5y "Years Since PhD (5 Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCOUNTRY "Birth Country FE") 
}

}

********************************************************************************
*Coefficient plots of the above regressions for export
* Note: The axes below are adjusted to fit the synthetic data
********************************************************************************

local depvarlist JOBSATIS_num TENLOGRANK TENURE TEN_R1 lnEARN

foreach dep of local depvarlist {
	
	* Title and X-scale 
	if "`dep'"== "TENURE" {
		local xopts xsc(r(-.15 .07)) xlabel(-.15(.01).07, labsize(small))
		local titleopts "Tenure anywhere"
	}
	
	if "`dep'"== "TEN_R1" {
		local xopts xsc(r(-.07 .1)) xlabel(-.07(.02).1, labsize(small))
		local titleopts "Tenure at an R1"
	}
	*/
		
	if "`dep'"== "lnEARN" {
		local xopts xsc(r(-.1 .15)) xlabel(-.1(.02).15, labsize(small))
		local titleopts "Log Earnings"
	}
	
	
	if "`dep'"== "TENLOGRANK" {
		local xopts xsc(r(-.4 .4)) xlabel(-.4(.1).4, labsize(small))
		local titleopts "Log Tenure Institution Rank"
	}
	
		
	if "`dep'"== "JOBSATIS_num" {
		local xopts xsc(r(-.4 .4)) xlabel(-.4(.05).4, labsize(small))
		local titleopts "Job Satisfaction"
	}
	
	coefplot (e_`dep'_1_WTSURVY, mcolor(ebblue) ciopts(color(ebblue))) ///
	(e_`dep'_2_WTSURVY, mcolor(cranberry) ciopts(color(cranberry))) ///
	(e_`dep'_3_WTSURVY, mcolor(midgreen) ciopts(color(midgreen))) ///
	(e_`dep'_4_WTSURVY, mcolor(gold) ciopts(color(gold))) ///
	(e_`dep'_5_WTSURVY, mcolor(purple) ciopts(color(purple))) ///
	(e_`dep'_6_WTSURVY, mcolor(orange_red) ciopts(color(orange_red))) ///
	(e_`dep'_7_WTSURVY, mcolor(midblue) ciopts(color(midblue))) ///
	(e_`dep'_1_one, mcolor(pink) ciopts(color(pink))), ///
	keep(*edpar_n) omitted baselevels ///
	xline(0) ///
	`xopts' ///
	legend(pos(6) order(2 "Baseline" 4 "10-29 yrs post PhD" 6 "PhD Program X Decade FE" 8 "Saturated Yrs" 10 "Narrow PhD Field" 12 "PhD Program Clusters" 14 "PhD Program X Decade Clusters" 16 "Unweighted" ) cols(4) size(small)) ///
	title("{bf: `titleopts'}") ///
	ytitle("") ysc(r(0.8 3.2)) ylabel(.8 "Less than" 1 "college" 1.9 "College" 3 "Non-PhD" 3.2 "Grad Degree" 3.9 "PhD",nogrid noticks)			
	 graph export "$figures/diff_spec_`dep'.pdf", replace
	 graph save "$figures/diff_spec_`dep'.gph", replace

}

*** YEAR VERSION ***

local depvarlist TEN_R1 TENURE

foreach dep of local depvarlist{
			
	* Title and X-scale 
	if "`dep'"== "TENURE" {
		local xopts xsc(r(-.08 .08)) xlabel(-.08(.02).08, labsize(small))
		local titleopts "Tenure anywhere"
	}
	
	
	if "`dep'"== "TEN_R1" {
		local xopts xsc(r(-.1 .1)) xlabel(-.1(.05).1, labsize(small))
		local titleopts "Tenure at an R1"
	}
	
	
	if "`dep'"== "TENLOGRANK" {
		local xopts xsc(r(-.4 .4)) xlabel(-.4(.1).4, labsize(small))
		local titleopts "Log Tenure Institution Rank"
	}
	
		if "`dep'"== "lnEARN" {
		local xopts xsc(r(-.25 .3)) xlabel(-.25(.05).3, labsize(small))
		local titleopts "Log Earnings"
	}
	
	
	if "`dep'"== "JOBSATIS_num" {
		local xopts xsc(r(-.3 .4)) xlabel(-.3(.1).4, labsize(small))
		local titleopts "Job Satisfaction"
	}

	coefplot (e_`dep'_1993_WTSURVY, mcolor(ebblue) ciopts(color(ebblue))) ///
	(e_`dep'_1995_WTSURVY, mcolor(cranberry) ciopts(color(cranberry))) ///
	(e_`dep'_1997_WTSURVY, mcolor(midgreen) ciopts(color(midgreen))) ///
	(e_`dep'_1999_WTSURVY, mcolor(gold) ciopts(color(gold))) ///
	(e_`dep'_2001_WTSURVY, mcolor(purple) ciopts(color(purple))) ///
	(e_`dep'_2003_WTSURVY, mcolor(orange_red) ciopts(color(orange_red))) ///
	(e_`dep'_2006_WTSURVY, mcolor(midblue) ciopts(color(midblue))) ///
	(e_`dep'_2008_WTSURVY, mcolor(pink) ciopts(color(pink))) ///
	(e_`dep'_2010_WTSURVY, mcolor(olive) ciopts(color(olive))) ///
	(e_`dep'_2013_WTSURVY, mcolor(dkorange) ciopts(color(dkorange))) ///
	(e_`dep'_2015_WTSURVY, mcolor(lavender) ciopts(color(lavender))) ///
	(e_`dep'_2017_WTSURVY, mcolor(teal) ciopts(color(teal))) ///
	(e_`dep'_2019_WTSURVY, mcolor(ltblue) ciopts(color(ltblue))) ///
	(e_`dep'_2021_WTSURVY, mcolor(forest_green) ciopts(color(forest_green))), ///
	keep(*edpar_n) omitted baselevels ///
	xline(0) ///
	`xopts' ///
	legend(pos(6) order(2 "1993" 4 "1995" 6 "1997" 8 "1999" 10 "2001" 12 "2003" 14 "2006" 16 "2008" 18 "2010" 20 "2013" 22 "2015" 24 "2017"26 "2019" 28 "2021" ) cols(7)) /// 
	title("{bf: `titleopts'}") ///
	ytitle("") ysc(r(0.8 3.2)) ylabel(.8 "Less than" 1 "college" 1.9 "College" 3 "Non-PhD" 3.2 "Grad Degree" 3.9 "PhD",nogrid noticks) 
	graph export "$figures/diff_year_`dep'.pdf", replace
	graph save "$figures/diff_year_`dep'.gph", replace

}

local depvarlist lnEARN

foreach dep of local depvarlist{
			
	* Title and X-scale 
		if "`dep'"== "lnEARN" {
		local xopts xsc(r(-.25 .3)) xlabel(-.25(.05).3, labsize(small))
		local titleopts "Log Earnings"
	}
	
	coefplot (e_`dep'_1995_WTSURVY, mcolor(cranberry) ciopts(color(cranberry))) ///
	(e_`dep'_1997_WTSURVY, mcolor(midgreen) ciopts(color(midgreen))) ///
	(e_`dep'_1999_WTSURVY, mcolor(gold) ciopts(color(gold))) ///
	(e_`dep'_2001_WTSURVY, mcolor(purple) ciopts(color(purple))) ///
	(e_`dep'_2003_WTSURVY, mcolor(orange_red) ciopts(color(orange_red))) ///
	(e_`dep'_2006_WTSURVY, mcolor(midblue) ciopts(color(midblue))) ///
	(e_`dep'_2008_WTSURVY, mcolor(pink) ciopts(color(pink))) ///
	(e_`dep'_2010_WTSURVY, mcolor(olive) ciopts(color(olive))) ///
	(e_`dep'_2013_WTSURVY, mcolor(dkorange) ciopts(color(dkorange))) ///
	(e_`dep'_2015_WTSURVY, mcolor(lavender) ciopts(color(lavender))) ///
	(e_`dep'_2017_WTSURVY, mcolor(teal) ciopts(color(teal))) ///
	(e_`dep'_2019_WTSURVY, mcolor(ltblue) ciopts(color(ltblue))) ///
	(e_`dep'_2021_WTSURVY, mcolor(forest_green) ciopts(color(forest_green))), ///
	keep(*edpar_n) omitted baselevels ///
	xline(0) ///
	`xopts' ///
	legend(pos(6) order(2 "1995" 4 "1997" 6 "1999" 8 "2001" 10 "2003" 12 "2006" 14 "2008" 16 "2010" 18 "2013" 20 "2015" 22 "2017" 24 "2019" 26 "2021" ) cols(7)) /// 
	title("{bf: `titleopts'}") ///
	ytitle("") ysc(r(0.8 3.2)) ylabel(.8 "Less than" 1 "college" 1.9 "College" 3 "Non-PhD" 3.2 "Grad Degree" 3.9 "PhD",nogrid noticks) 
	graph export "$figures/diff_year_`dep'.pdf", replace
	graph save "$figures/diff_year_`dep'.gph", replace
}

local depvarlist TENLOGRANK

foreach dep of local depvarlist{
			
	* Title and X-scale 
	if "`dep'"== "TENLOGRANK" {
		local xopts xsc(r(-.4 .4)) xlabel(-.4(.1).4, labsize(small))
		local titleopts "Log Tenure Institution Rank"
	}
	
	coefplot (e_`dep'_1997_WTSURVY, mcolor(midgreen) ciopts(color(midgreen))) ///
	(e_`dep'_1999_WTSURVY, mcolor(gold) ciopts(color(gold))) ///
	(e_`dep'_2001_WTSURVY, mcolor(purple) ciopts(color(purple))) ///
	(e_`dep'_2003_WTSURVY, mcolor(orange_red) ciopts(color(orange_red))) ///
	(e_`dep'_2006_WTSURVY, mcolor(midblue) ciopts(color(midblue))) ///
	(e_`dep'_2008_WTSURVY, mcolor(pink) ciopts(color(pink))) ///
	(e_`dep'_2010_WTSURVY, mcolor(olive) ciopts(color(olive))) ///
	(e_`dep'_2013_WTSURVY, mcolor(dkorange) ciopts(color(dkorange))) ///
	(e_`dep'_2015_WTSURVY, mcolor(lavender) ciopts(color(lavender))) ///
	(e_`dep'_2017_WTSURVY, mcolor(teal) ciopts(color(teal))) ///
	(e_`dep'_2019_WTSURVY, mcolor(ltblue) ciopts(color(ltblue))) ///
	(e_`dep'_2021_WTSURVY, mcolor(forest_green) ciopts(color(forest_green))), ///
	keep(*edpar_n) omitted baselevels ///
	xline(0) ///
	`xopts' ///
	legend(pos(6) order(2 "1997" 4 "1999" 6 "2001" 8 "2003" 10 "2006" 12 "2008" 14 "2010" 16 "2013" 18 "2015" 20 "2017" 22 "2019" 24 "2021" ) cols(7)) /// 
	title("{bf: `titleopts'}") ///
	ytitle("") ysc(r(0.8 3.2)) ylabel(.8 "Less than" 1 "college" 1.9 "College" 3 "Non-PhD" 3.2 "Grad Degree" 3.9 "PhD",nogrid noticks) 
	graph export "$figures/diff_year_`dep'.pdf", replace
	graph save "$figures/diff_year_`dep'.gph", replace
}


local depvarlist JOBSATIS_num

foreach dep of local depvarlist{
			
	* Title and X-scale 
	if "`dep'"== "JOBSATIS_num" {
		local xopts xsc(r(-.3 .4)) xlabel(-.3(.1).4, labsize(small))
		local titleopts "Job Satisfaction"
	}
	
	coefplot (e_`dep'_1997_WTSURVY, mcolor(midgreen) ciopts(color(midgreen))) ///
	(e_`dep'_2003_WTSURVY, mcolor(orange_red) ciopts(color(orange_red))) ///
	(e_`dep'_2006_WTSURVY, mcolor(midblue) ciopts(color(midblue))) ///
	(e_`dep'_2008_WTSURVY, mcolor(pink) ciopts(color(pink))) ///
	(e_`dep'_2010_WTSURVY, mcolor(olive) ciopts(color(olive))) ///
	(e_`dep'_2013_WTSURVY, mcolor(dkorange) ciopts(color(dkorange))) ///
	(e_`dep'_2015_WTSURVY, mcolor(lavender) ciopts(color(lavender))) ///
	(e_`dep'_2017_WTSURVY, mcolor(teal) ciopts(color(teal))) ///
	(e_`dep'_2019_WTSURVY, mcolor(ltblue) ciopts(color(ltblue))) ///
	(e_`dep'_2021_WTSURVY, mcolor(forest_green) ciopts(color(forest_green))), ///
	keep(*edpar_n) omitted baselevels ///
	xline(0) ///
	`xopts' ///
	legend(pos(6) order(2 "1997" 4 "2003" 6 "2006" 8 "2008" 10 "2010" 12 "2013" 14 "2015" 16 "2017" 18 "2019" 20 "2021") cols(7)) /// 
	title("{bf: `titleopts'}") ///
	ytitle("") ysc(r(0.8 3.2)) ylabel(.8 "Less than" 1 "college" 1.9 "College" 3 "Non-PhD" 3.2 "Grad Degree" 3.9 "PhD",nogrid noticks) 
	graph export "$figures/diff_year_`dep'.pdf", replace
	graph save "$figures/diff_year_`dep'.gph", replace

}

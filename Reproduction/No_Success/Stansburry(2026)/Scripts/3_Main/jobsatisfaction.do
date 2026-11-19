*********************************************************************************
*Job Satisfaction Analyses
*********************************************************************************

********************************************************************************
*This code creates:
*jobsat_TENURETRACK_WTSURVY.tex, ///
	jobsat_INDSECTOR_WTSURVY.tex, ///
	jobsat_GOVSECTOR_WTSURVY.tex, ///
	jobsat_EDUNTT_WTSURVY.tex, ///
	jobsat_ALL_WTSURVY.tex, ///
	jobimp_TENURETRACK_WTSURVY.tex, ///
	jobimp_INDSECTOR_WTSURVY.tex, ///
	jobimp_GOVSECTOR_WTSURVY.tex, ///
	jobimp_EDUNTT_WTSURVY.tex, ///
	jobimp_ALL_WTSURVY.tex, ///
	JobSatisfaction_ClassGap.pdf, ///
	JobImportance_ClassGap.pdf
********************************************************************************

*Load full SDR 1993-2021
use "$DATA/sdrdrf_9321_working", clear

********************************************************************************
*Job satisfaction, self-reported, Tenured academics 10-39 years post PhD
********************************************************************************
est clear

foreach weight in  WTSURVY {
foreach sector in TENURE {
foreach dep in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC {

local controls
local cond if LOCATIONUS==1 & `sector'==1 & years_since_phd>=10 & years_since_phd<40
local condnote1 if years_since_phd is greater than or equal to 10 and years_since_phd is less than 40 and LOCATIONUS equals 1 and `sector'==1
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

qui reghdfe `dep'_num ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto `sector'`dep'`weight'
	qui sum `dep'_num [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations:
		foreach var of local covars {			
			di "`sector': `dep' and `var' Samples:"
			tab `var' if e(sample)
		}

}
estfe `sector'*`weight', labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCON "Birth Continent FE")

esttab `sector'*`weight' using "$tables/jobsat_`sector'.tex", replace ///
title(Satisfaction with Factor in Job - `sector' \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Job" "Salary" "Benefits" "Security" "Location" "Advancement" "Challenge" "Responsibility" "Independence" "Society") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "DVs are a four-point continuous scale where the highest number represents 'very satisfied' with each aspect of their current job.")
}
}


********************************************************************************
*Job satisfaction, self-reported, by sector and with different sub-categories
*Note: gaps parallel the gaps in salary: no job satisfaction gap by class in government, but a gap in tenure track academia, industry
********************************************************************************
est clear

foreach weight in  WTSURVY {
foreach sector in TENURETRACK INDSECTOR GOVSECTOR EDUNTT  ALL {
foreach dep in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC {

local controls
local cond if LOCATIONUS==1 & `sector'==1 & years_since_phd<=40
local condnote1 if years_since_phd less than or equal to 40 and LOCATIONUS equals 1 and `sector'==1
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n gender race_n

qui reghdfe `dep'_num ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto `sector'`dep'
	qui sum `dep'_num [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations:
		foreach var of local covars {			
			di "`sector': `dep' and `var' Samples:"
			tab `var' if e(sample)
		}
}


estfe `sector'*, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCON "Birth Continent FE")

esttab `sector'* using "$tables/jobsat_`sector'.tex", replace ///
title(Satisfaction with Factor in Job - `sector' \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Job" "Salary" "Benefits" "Security" "Location" "Advancement" "Challenge" "Responsibility" "Independence" "Society") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "DVs are a four-point continuous scale where the highest number represents 'very satisfied' with each aspect of their current job.")
}
}


*Coefficient plot of job satisfaction regressions
local plotvars
local weight WTSURVY

foreach dep in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC {
foreach sector in TENURETRACK  INDSECTOR GOVSECTOR EDUNTT {
	local `dep'plotvars ``dep'plotvars' `sector'`dep'
}
}

coefplot  ///
	`JOBSATISplotvars' , bylabel(Overall) || ///
	`SATSALplotvars', bylabel(Salary) || ///
	`SATBENplotvars', bylabel(Benefits) || ///
	`SATSECplotvars', bylabel(Job Security) || ///
	`SATLOCplotvars', bylabel(Location) || ///
	`SATADVplotvars', bylabel(Advancement Opps.) || ///
	`SATCHALplotvars', bylabel(Int. Challenge) || ///
	`SATRESPplotvars', bylabel(Responsibility) || ///
	`SATINDplotvars', bylabel(Independence) || ///
	`SATSOCplotvars', bylabel(Contr. to Society) || ///
	, keep(*1.edpar_n) xline(0)  ///
	bycoefs ///
	legend(pos(6) cols(4) order(2 "Tenure-track" 4 "Industry" 6 "Government" 8 "Non-TT Education")) 
	graph export "$figures/JobSatisfaction_ClassGap.pdf", replace

* Check nb of obs in the coefplot for each point:
foreach weight in  WTSURVY {
foreach sector in TENURETRACK INDSECTOR GOVSECTOR EDUNTT {
foreach dep in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC {

	di "`dep' and `sector'"
	tab `dep' if LOCATIONUS==1 & `sector'==1 & !mi(`dep')
	}
}
}

********************************************************************************
*Perceived importance of job components (hypothetical: "when thinking about a job"),
*Note: Self-reported, across categories
*Note: In tenure track academia, first gen report higher importance
********************************************************************************
est clear

local weight WTSURVY
foreach sector in TENURE TENURETRACK INDSECTOR GOVSECTOR EDUNTT ALL  {
foreach dep in FACSAL FACBEN FACSEC FACLOC FACADV FACCHAL FACRESP FACIND FACSOC {
	
di "`sector': `dep'"

local controls
local cond if LOCATIONUS==1 & `sector'==1 & years_since_phd<40
local condnote1 if years_since_phd less than 40 and LOCATIONUS equals 1 and `sector' equals 1
local fes YR PHDCY5y years_since_phd5y PHDFIELDNEW PHDINST BIRTHCOUNTRY
local se cluster PHDPROGRAMYR
local covars edpar_n race_n gender

qui reghdfe `dep'_num ib3.edpar_n gender ib5.race_n `controls' `cond' [aw=`weight'], absorb(`fes') vce(`se')
	est sto `sector'`dep'
	qui sum `dep'_num [aw=`weight'] if e(sample)
	qui estadd scalar ywtm=r(mean)
	
	// Check number of observations:
		foreach var of local covars {			
			di "`sector': `dep' and `var' Samples:"
			tab `var' if e(sample)
		}
}


estfe `sector'*, labels(YR "Survey Year FE" PHDCY5y "PhD Year (5-Year Buckets) FE" years_since_phd5y "Years Since PhD (5-Year Buckets) FE" PHDFIELDNEW "PhD Field FE" PHDINST "PhD Institution FE" BIRTHCON "Birth Continent FE")

esttab `sector'* using "$tables/jobimp_`sector'.tex", replace ///
title(Importance of Factor in Job - `sector' \label{tab1}) label nobaselevels ///
se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n* *gender* *race_n*) ///
s(ywtm N N_clust1 r2 r2_a df_m df_a df_r, fmt(a2 %15.0gc %15.0gc a2 a2 %15.0gc %15.0gc %15.0gc) ///
label("Dep Var Mean" "Observations" "Clusters" "R-Squared" "Adjusted R-Squared" "Controls Degrees of Freedom" "Absorbed Degrees of Freedom"  "Residual Degrees of Freedom")) indicate(`r(indicate_fe)')  ///
	mtitle("Salary" "Benefits" "Security" "Location" "Advancement" "Challenge" "Responsibility" "Independence" "Society") ///
	varwidth(2) ///
	refcat(1.edpar_n "ref: Grad Degree" gender "ref: Male" 1.race_n "ref: White Non-Hispanic", nolabel) ///
	addnote("Condition: `condnote1'" "Fixed Effects: `fes'" "Standard Error: `se'" "Weighted by `weight'." "DVs are a four-point continuous scale where the highest number represents that the specific aspect of their current job is 'very important'.")
}


*Coefficient plot of job importance regressions
local plotvars
local weight WTSURVY

foreach dep in FACSAL FACBEN FACSEC FACLOC FACADV FACCHAL FACRESP FACIND FACSOC {
foreach sector in TENURETRACK  INDSECTOR GOVSECTOR EDUNTT {
	local `dep'plotvars ``dep'plotvars' `sector'`dep'
}
}

coefplot  ///
	`FACSALplotvars', bylabel(Salary) || ///
	`FACBENplotvars', bylabel(Benefits) || ///
	`FACSECplotvars', bylabel(Job Security) || ///
	`FACLOCplotvars', bylabel(Location) || ///
	`FACADVplotvars', bylabel(Advancement Opps.) || ///
	`FACCHALplotvars', bylabel(Int. Challenge) || ///
	`FACRESPplotvars', bylabel(Responsibility) || ///
	`FACINDplotvars', bylabel(Independence) || ///
	`FACSOCplotvars', bylabel(Contr. to Society) || ///
	, keep(*1.edpar_n) xline(0)  ///
	bycoefs ///
	legend(pos(6) cols(4) order(2 "Tenure-track" 4 "Industry" 6 "Government" 8 "Non-TT Education")) 
	graph export "$figures/JobImportance_ClassGap.pdf", replace
	
* Check nb of obs in the coefplot for each point:

foreach weight in  WTSURVY {
foreach sector in TENURETRACK INDSECTOR GOVSECTOR EDUNTT {
foreach dep in FACSAL FACBEN FACSEC FACLOC FACADV FACCHAL FACRESP FACIND FACSOC {

	di "`dep' and `sector'"
	tab `dep' if LOCATIONUS==1 & `sector'==1 & !mi(`dep')
	}
}
}

	
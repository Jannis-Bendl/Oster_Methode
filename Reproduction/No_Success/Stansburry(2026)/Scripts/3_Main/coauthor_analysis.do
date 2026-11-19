********************************************************************************
*Publication level Analysis of coauthorship homophily by SEB, gender, and race
********************************************************************************

********************************************************************************
*This code creates:
* coauthor_homophily_allauthors_weighted.tex
********************************************************************************

*Load SDR
use "$DATA/sdrdrf_9321_working", clear

********************************************************************************
*Residualize parental education on various observables that are strongly correlated with it
********************************************************************************

*generate intsitution by field
egen INSTBYFIELD = group(INSTCOD PHDFIELDNEW)

foreach dep in firstgen edpar_n{
reghdfe `dep' [aw=WTSURVY], absorb(YR gender race_n BIRTHCOUNTRY PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_PHDINST, r

reghdfe `dep' if INSTCOD_miss!=1 & LOCATIONUS==1 [aw=WTSURVY], absorb(YR gender race_n BIRTHCOUNTRY INSTCOD PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_INSTCOD, r

}

********************************************************************************
*Residualize gender on various observables that are strongly correlated with it
********************************************************************************
foreach dep in gender {
qui reghdfe `dep' [aw=WTSURVY], absorb(YR edpar_n race_n BIRTHCOUNTRY PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_PHDINST, r

qui reghdfe `dep' if INSTCOD_miss!=1 & LOCATIONUS==1 [aw=WTSURVY], absorb(YR edpar_n race_n BIRTHCOUNTRY INSTCOD PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_INSTCOD, r

}

********************************************************************************
*Residualize race (URM status) on various observables that are strongly correlated with it
********************************************************************************
foreach dep in urm {
qui reghdfe `dep' [aw=WTSURVY], absorb(YR edpar_n gender BIRTHCOUNTRY PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_PHDINST, r

qui reghdfe `dep' if INSTCOD_miss!=1 & LOCATIONUS==1 [aw=WTSURVY], absorb(YR edpar_n gender BIRTHCOUNTRY INSTCOD PHDFIELDNEW PHDINST PHDCY) residuals
predict res_`dep'_INSTCOD, r

}

*Keep only 2015 SDR since it is the year in which respondents are matched 
keep if YR==2015

*Keep only certain variables to avoid creating very large dataset
keep REFID WTSURVY PHDCY PHDCY5y PHD_GROUP PHDFIELD PHDFIELDNEW edpar_n firstgen gender race_n urm BIRTHCON BIRTHCOUNTRY PHDPROGRAM PHDINST INSTCOD PHD_CAT LOCATIONUS INSTCOD_miss years_since_phd5y PHDRANK TENSTA TENURETRACK res_* PHDPROGRAMYR

*Save temp dataset for all coauthor analyses
save "$TEMP/coauthor_sample", replace

********************************************************************************
*Merge with publication level data
********************************************************************************
merge 1:m REFID using "$DATA/newwos_withrefid", force
keep if _m==3

*Drop any who are missing variables which we need to calculate residuals
drop if missing(edpar_n) 
drop if missing(urm)

*Keep only publications with more than one author in the SDR
drop if PUB_NUM_AUTHORS==1
bysort pub_randid: egen authors_present = count(REFID)
drop if authors_present==1
*172,817 pub-author observations remain
bysort pub_randid: gen tag_pub =1 if _n==1
*67,586 publications remain. At the median, 29% of a pub's authors are in the SDR
gen share_authors_present = authors_present/PUB_NUM_AUTHORS
summ share_authors_present if tag_pub==1, d

*Save coauthor merged dataset
save "$TEMP/coauthor_merged", replace


*How many publications have at least 2 authors in the matched sample?
distinct pub_randid

*How many individuals have at least 1 other coauthor in the sample?
distinct REFID



***********************


********************************************************************************
*Residuals based on coauthors
********************************************************************************
use "$TEMP/coauthor_merged", clear


*********************************************************************************************
**All coauthors (regardless of whether all coauthors for each publication are in the dataset) WEIGHTED by the number of coauthors present
*Larger sample
*********************************************************************************************

*For each individual, calculate the weighted mean residualized parental education, gender, and race of their coauthors, weighted by number of authors present
preserve
foreach res in res_firstgen_PHDINST res_firstgen_INSTCOD  res_edpar_n_PHDINST res_edpar_n_INSTCOD  res_gender_PHDINST res_gender_INSTCOD  res_urm_PHDINST res_urm_INSTCOD  {
	bys pub_randid: egen d_`res' = count(`res')
	bys pub_randid: egen n_`res' = total(`res')
	gen loo_`res' = (n_`res' - `res')/(d_`res'-1) /*Leave-out-self mean residualized parental education at publication level - this is the avg education of the individual's coauthors on that pub*/
	gen wloo_`res' = loo_`res'*share_authors_present /*Weight by share of authors present*/
	bys REFID: egen x_`res' = mean(wloo_`res') /*Average of this for all publications*/
}

*Keep relevant variables for regressions
keep REFID x_* gender edpar_n firstgen urm WTSURVY PHDPROGRAMYR
duplicates drop
*23,177 authors

local weight [aw=WTSURVY]
est clear

***Regress demographic variables of the average coathour residuals generated above

*Parental Education variables
foreach res in res_firstgen_PHDINST  res_firstgen_INSTCOD   {
qui reg x_`res' ib3.edpar_n  `weight', vce(cluster PHDPROGRAMYR)
est sto e_1`res'

tab edpar_n if e(sample)
}

foreach res in res_firstgen_PHDINST  res_firstgen_INSTCOD   {
qui reg x_`res' firstgen  `weight', vce(cluster PHDPROGRAMYR)
est sto e_`res'

tab firstgen if e(sample)

}

*Gender variables
foreach res in res_gender_PHDINST  res_gender_INSTCOD  {
qui reg x_`res' gender `weight', vce(cluster PHDPROGRAMYR)
est sto e_`res'

tab gender if e(sample)

}


*Race variables
foreach res in res_urm_PHDINST  res_urm_INSTCOD  {
qui reg x_`res' urm  `weight', vce(cluster PHDPROGRAMYR)
est sto e_`res'

tab urm if e(sample)
}

*Generate a table of the above regressions 
esttab e_* using "$tables/coauthor_homophily_allauthors_weighted.tex", replace  ///
	title(Coauthor homophily (All Authors)- Weighted) label nobaselevels ///
	se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n firstgen gender urm ) ///
	mtitle("Par. Ed" "Par. Ed" "First gen" "First gen"  "Female" "Female" "URM" "URM")
restore


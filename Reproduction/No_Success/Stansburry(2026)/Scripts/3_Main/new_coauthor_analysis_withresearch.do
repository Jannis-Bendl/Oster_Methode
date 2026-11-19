********************************************************************************
*Publication level Analysis of coauthorship homophily by Research
********************************************************************************
*Updated: Anna Apr 30 2025
********************************************************************************
*This code creates:
* coauthor_research_pctrank_homophily_weighted.tex
********************************************************************************

*******************************************************************************************
*Same weighted analysis as "coauthor_analysis.do" but with cumulative research vars as the dependent vars
*******************************************************************************************

*Load coauthor dataset
use "$TEMP/coauthor_merged", clear

*Cumulative pubs
g count_pubs = 1 if !missing(pub_randid)
bysort REFID (PUB_YEAR) : g cumsum_pubs = sum(count_pubs)
bysort REFID PUB_YEAR : g year_dup = cond(_N==1,0,_n) /*cumulative sum goes by observation loaction, so we need to make sure all pubs in the same year are added together*/
bysort REFID PUB_YEAR (year_dup): g cumsum_pubs_u = cumsum_pubs[_N]

*Cumulative CNCI
bysort REFID (PUB_YEAR) : g cumsum_cnci = sum(CNCI)
bysort REFID PUB_YEAR (year_dup): g cumsum_cnci_u = cumsum_cnci[_N]


*Average cumulative JIF
bysort REFID (PUB_YEAR) : g count_n = _n
bysort REFID PUB_YEAR (year_dup): g n_use = count_n[_N]
bysort REFID (PUB_YEAR) : g cumavg_jif = sum(PUB_JCR_IMPACTFACTOR)/n_use
bysort REFID PUB_YEAR (year_dup): g cumavg_jif_u = cumavg_jif[_N]


*******************************************************************************************
*Same sbove analysis but with percentile ranks of cumulative research vars 
*******************************************************************************************
*Generate Decade variable 
g pub_decade = "90s" if PUB_YEAR<=1999
replace pub_decade = "00s" if PUB_YEAR<=2009 & PUB_YEAR>=2000
replace pub_decade = "long 10s" if PUB_YEAR>=2010

*Percentile of pub variables by PhD Cat (_r) and PhD Cat and decade (rnp)
foreach var in cumsum_pubs_u cumsum_cnci_u cumavg_jif_u {
	bys PHD_CAT: egen `var'_r = rank(`var')
	bys PHD_CAT: egen `var'_rd = count(`var')
	gen `var'r = `var'_r/`var'_rd
	
	bys PHD_CAT pub_decade: egen `var'_rp = rank(`var')
	bys PHD_CAT pub_decade: egen `var'_rdp = count(`var')
	gen `var'rp = `var'_rp/`var'_rdp
}

*Save coauthor dataset with all cumulative pub vars
save "$TEMP/coauthor__uvars", replace

*Generate new vars with less wide names for further use below
g cumsumpubsur = cumsum_pubs_ur
g cumsumcnciur = cumsum_cnci_ur
g cumavgjifur = cumavg_jif_ur

g cumsumpubsurp = cumsum_pubs_urp
g cumsumcnciurp = cumsum_cnci_urp
g cumavgjifurp = cumavg_jif_urp


********************************************************************************
*Residualize publication variables on other observables - percentile by phd_cat and decade
********************************************************************************
foreach dep in cumsumpubsurp cumsumcnciurp cumavgjifurp {
	

	
qui reghdfe `dep' [aw=WTSURVY], absorb(edpar_n gender race_n years_since_phd5y BIRTHCOUNTRY PHDINST PHDFIELDNEW PHDCY) residuals
predict res_`dep'_PHDINST, r

qui reghdfe `dep' if INSTCOD_miss!=1 & LOCATIONUS==1 [aw=WTSURVY], absorb(edpar_n gender race_n years_since_phd5y BIRTHCOUNTRY PHDFIELDNEW PHDINST INSTCOD PHDCY) residuals
predict res_`dep'_INSTCOD, r

}

********************************************************************************
*Residuals based on coauthors
********************************************************************************
preserve

*For each individual, calculate the mean residualized pubs/citations/jif of their coauthors, weighted by number of authors present
foreach res in res_cumsumpubsurp_PHDINST res_cumsumpubsurp_INSTCOD  res_cumsumcnciurp_PHDINST res_cumsumcnciurp_INSTCOD  res_cumavgjifurp_PHDINST res_cumavgjifurp_INSTCOD {
	bys pub_randid: egen d_`res' = count(`res')
	bys pub_randid: egen n_`res' = total(`res')
	gen l_`res' = (n_`res' - `res')/(d_`res'-1) /*Leave-out-self mean residualized parental education at publication level - this is the avg education of the individual's coauthors on that pub*/
	gen wl_`res' = l_`res'*share_authors_present /*Weight by share of authors present*/
	bys REFID: egen x_`res' = mean(wl_`res') /*Average of this for all publications*/
}

*Keep relevant variables for regressions
keep REFID x_* gender edpar_n firstgen urm race_n PHDPROGRAMYR
duplicates drop

est clear

***Regress demographic variables of the average coathour residuals generated above (where all authors are present)
 
*Parental Education variables
foreach res in res_cumsumpubsurp_PHDINST res_cumsumpubsurp_INSTCOD  res_cumsumcnciurp_PHDINST res_cumsumcnciurp_INSTCOD  res_cumavgjifurp_PHDINST res_cumavgjifurp_INSTCOD {
qui reg x_`res' ib3.edpar_n, vce(cluster PHDPROGRAMYR)
est sto e_`res'
}


*Generate a table of the above regressions
esttab e* using "$tables/coauthor_research_pctrank_decade_homophily_weighted.tex", replace  ///
	title(Coauthor publication output (Percentile Rank by Field and Decade)) label nobaselevels ///
	se(a2) star(* 0.10 ** 0.05 *** 0.01) keep(*edpar_n) ///
	mtitle("Pub Count" "Pub Count" "CNCI" "CNCI" "JIF" "JIF") 
	restore

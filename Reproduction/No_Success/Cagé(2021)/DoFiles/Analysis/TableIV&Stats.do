*********************************************************************************************
*********************************************************************************************
***************** 	     TABLE IV: COLLABORATION 		    *********************************
*********************************************************************************************
*********************************************************************************************

use "$Data_generated/analysis_dataset.dta", clear

********************************************************************************
*** In log
estimates clear	
	** Dep FE **
	eststo: areg  lncollabospc verdun_petain verdun    ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Pop "", replace 
		estadd local Sample  "1914 France", replace 
		estadd local PreTrends "", replace
		estadd local Moran "0.30", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
	

	eststo: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Pop "\checkmark", replace 
		estadd local Sample  "1914 France", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Moran "0.22", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	
********************************************************************************		
*** Robustness in main table: Exclude not Verdun municip. and Poisson  		 
*****************************************************************************************************
use "$Data_generated/analysis_dataset.dta", clear
preserve
drop if verdun==0
********************************************************************************
*** In log
	** Dep FE **
	eststo: areg  lncollabospc verdun_petain    ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample  "Verdun only", replace 
		estadd local Pop "", replace 
		estadd local PreTrends "", replace
		estadd local Moran "0.47", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo: areg  lncollabospc verdun_petain    $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample  "Verdun only", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Moran "0.99", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

restore 

*** POISSON 	
eststo: 	xi: poisson collabos   verdun_petain verdun  lnpop1936  i.code_dep    , cl(id_bureau) iter(10000)
		estadd local Sample  "1914 France", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local Pop "", replace 
		estadd local PreTrends "", replace
		estadd local Moran "NA", replace
		estadd ysumm	 
		estadd scalar clusters = e(N_clust)	
	 

eststo: xi: poisson collabos   verdun_petain verdun lnpop1936  $lpretrends_nomiss $precontrols_nomiss  i.code_dep   , cl(id_bureau)  iter(10000)
		estadd local Sample  "1914 France", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Moran "NA", replace
		estadd ysumm	 
		estadd scalar clusters = e(N_clust)	

		
*** POISSON: w/o Not Verdun 
eststo: 	xi: poisson collabos   verdun_petain   lnpop1936  i.code_dep   if  verdun!=0 & verdun!=. , cl(id_bureau) iter(10000)
		estadd local Sample  "Verdun only", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local Pop "", replace 
		estadd local PreTrends "", replace
		estadd local Moran "NA", replace
		estadd ysumm	 
		estadd scalar clusters = e(N_clust)	
	 

eststo: xi: poisson collabos   verdun_petain   lnpop1936  $lpretrends_nomiss $precontrols_nomiss  i.code_dep   if  verdun!=0 & verdun!=. , cl(id_bureau)  iter(10000)
		estadd local Sample  "Verdun only", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Moran "NA", replace
		estadd ysumm	 
		estadd scalar clusters = e(N_clust)	


esttab using "$Results/Tables/TableIV.tex", replace ///
	keep(verdun_petain verdun lnpop1911_nomiss lshNuance_Gauche_14_nomiss    lshNuance_Droite_14_nomiss  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain" verdun "Verdun"   lnpop1911_nomiss "Log pop 1911" lshNuance_Gauche_14_nomiss "Log Share Left, 1914"   lshNuance_Droite_14_nomiss "Log Share Right, 1914"      )   ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats (Moran r2 N ymean ysd clusters, fmt(0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels("Moran P-Val" "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label  ///
	mtitles("1914 France" "1914 France" "Verdun only" "Verdun only" "1914 France" "1914 France" "Verdun only" "Verdun only") ///
	mgroups( "Log collaborators per capita (OLS)"   "Number of collaborators (Poisson)", pattern(1 0 0 0 1 0 0 0  ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  
 
  
quietly {
*OSTER TEST
use "$Data_generated/analysis_dataset.dta", clear
	encode code_dept, gen (code_dept_n)
	xi: reg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss   i.code_dept_n,  cl(id_bureau)  
	psacalc delta verdun_petain , rmax(1)  mcontrol(verdun i.code_dept_n )	

	*** 1.3 times the R-squared 
xi: reg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss   i.code_dept_n,  cl(id_bureau)  
	 display 1.3*0.6063
	psacalc delta verdun_petain , rmax(0.78832)  mcontrol(verdun i.code_dept_n )	
}

quietly {		
*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with only pre-war Vote  **************** 
*********************************************************************
clear all
cd "$Data_generated/"
spset, clear

spshape2dta "$Data_origin/Maps/bureauderecrutement.shp", replace 


use "$Data_generated/bureauderecrutement.dta", clear 
format    ID_BUREAU %2.0f
tab ID_BUREAU
save, replace


		
*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with no controls  **************** 
*********************************************************************
use "$Data_generated/analysis_dataset.dta", clear
gen ID_BUREAU = id_bureau


collapse (mean)   lncollabospc latitude longitude verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss WWIdeathrate_nomiss WWIdeathrate_miss  (sum) collabos pop1936 , by (ID_BUREAU RI_number code_dep)

gen collasbospc=collabos /pop1936
gen logcollabospc=log(collasbospc+1)


	* OlS regression
 xi: reg  verdun_petain verdun      i.code_dep , rob
cap drop x_resid
	predict x_resid, resid

foreach outcomevar of varlist lncollabospc {
		xi: reg `outcomevar'   verdun     i.code_dep  , rob
		predict y_resid_`outcomevar', resid
		}
		

collapse (mean) x_resid y_resid* lncollabospc latitude longitude verdun_petain  $lpretrends_nomiss $precontrols_nomiss (sum)  collasbospc, by (ID_BUREAU)
	 
merge 1:1 ID_BUREAU using "$Data_generated/bureauderecrutement.dta"

drop if _merge!=3

*spset, clear
*spset ID_BUREAU , coord (_CX _CY)
 
	 moransi lncollabospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	 moransi verdun_petain, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail

	 moransi collasbospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	  
	spmatrix create idistance Wdist,   replace
 	
	putexcel set "$Results/Tables/Morantest.xlsx", sheet("Table 2") modify
	putexcel B2="OLS"
	putexcel B3="Chi-squared"
	putexcel C3="p-value"
	putexcel E2="IV"
	putexcel E3="Chi-squared"
	putexcel F3="p-value"	

	local i = 4
	foreach outcomevar in lncollabospc {
		reg y_resid_`outcomevar' x_resid
		estat moran, errorlag(Wdist) 
		putexcel A`i'="`outcomevar'"
		putexcel B`i'=`r(chi2)' 		
		putexcel C`i'=`r(p)'
		local i = `i' + 1
		sleep 1000
	}	
/*  
 
         chi2(1)      =     1.06
         Prob > chi2  =   0.3025
*/

		
*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with only pre-war controls  **************** 
*********************************************************************
clear all
spset, clear
use "$Data_generated/analysis_dataset.dta", clear
gen ID_BUREAU = id_bureau


collapse (mean)   lncollabospc latitude longitude verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss WWIdeathrate_nomiss WWIdeathrate_miss  (sum) collabos pop1936 , by (ID_BUREAU RI_number code_dep)

gen collasbospc=collabos /pop1936
gen logcollabospc=log(collasbospc+1)


	* OlS regression
 xi: reg  verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss  i.code_dep , rob
cap drop x_resid
	predict x_resid, resid

foreach outcomevar of varlist lncollabospc {
		xi: reg `outcomevar'   verdun    $lpretrends_nomiss $precontrols_nomiss  i.code_dep  , rob
		predict y_resid_`outcomevar', resid
		}

collapse (mean) x_resid y_resid* lncollabospc latitude longitude verdun_petain  $lpretrends_nomiss $precontrols_nomiss (sum)  collasbospc, by (ID_BUREAU)
	 
merge 1:1 ID_BUREAU using "$Data_generated/bureauderecrutement.dta"

drop if _merge!=3

*spset ID_BUREAU , coord (_CX _CY)
 
	 moransi lncollabospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	 moransi verdun_petain, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail

	 moransi collasbospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	  
	spmatrix create idistance Wdist,   replace
 	
	putexcel set "$Results/Tables/Morantest.xlsx", sheet("Table 2") modify
	putexcel B2="OLS"
	putexcel B3="Chi-squared"
	putexcel C3="p-value"
	putexcel E2="IV"
	putexcel E3="Chi-squared"
	putexcel F3="p-value"	

	local i = 4
	foreach outcomevar in lncollabospc {
		reg y_resid_`outcomevar' x_resid
		estat moran, errorlag(Wdist) 
		putexcel A`i'="`outcomevar'"
		putexcel B`i'=`r(chi2)' 		
		putexcel C`i'=`r(p)'
		local i = `i' + 1
		sleep 1000
	}	

/*  
         chi2(1)      =     1.47
         Prob > chi2  =   0.2249
		 
*/	
*********************************************************************
***** MORAN P-VALUES W/O NO VERDUN  **************** 
*********************************************************************
*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with only pre-war Vote  **************** 
*********************************************************************

clear all
cd "$Data_generated/"
spset, clear
/*
spshape2dta "$Data_origin/Maps/bureauderecrutement.shp", replace 


use "$Data_generated/bureauderecrutement.dta", clear 
format    ID_BUREAU %2.0f
tab ID_BUREAU
save, replace
*/	
*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with no controls  **************** 
*********************************************************************
use "$Data_generated/analysis_dataset.dta", clear
gen ID_BUREAU = id_bureau

keep if verdun!=0 & verdun<99999

collapse (mean)   lncollabospc latitude longitude verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss WWIdeathrate_nomiss WWIdeathrate_miss  (sum) collabos pop1936 , by (ID_BUREAU RI_number code_dep)

gen collasbospc=collabos /pop1936
gen logcollabospc=log(collasbospc+1)


	* OlS regression
	
 xi: reg  verdun_petain    i.code_dep , rob
cap drop x_resid
	predict x_resid, resid

foreach outcomevar of varlist lncollabospc {
		xi: reg `outcomevar'         i.code_dep  , rob
		predict y_resid_`outcomevar', resid
		}

collapse (mean) x_resid y_resid* lncollabospc latitude longitude verdun_petain  $lpretrends_nomiss $precontrols_nomiss (sum)  collasbospc, by (ID_BUREAU)
	 
merge 1:1 ID_BUREAU using "$Data_generated/bureauderecrutement.dta"

drop if _merge!=3

*spset, clear
*spset ID_BUREAU , coord (_CX _CY)
 
	 moransi lncollabospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	 moransi verdun_petain, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail

	 moransi collasbospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	  
	spmatrix create idistance Wdist,   replace
 	
	putexcel set "$Results/Tables/Morantest.xlsx", sheet("Table 2") modify
	putexcel B2="OLS"
	putexcel B3="Chi-squared"
	putexcel C3="p-value"
	putexcel E2="IV"
	putexcel E3="Chi-squared"
	putexcel F3="p-value"	

	local i = 4
	foreach outcomevar in lncollabospc {
		reg y_resid_`outcomevar' x_resid
		estat moran, errorlag(Wdist) 
		putexcel A`i'="`outcomevar'"
		putexcel B`i'=`r(chi2)' 		
		putexcel C`i'=`r(p)'
		local i = `i' + 1
		sleep 1000
	}	
/*  
 
         chi2(1)      =     0.52
         Prob > chi2  =   0.4722
*/


*********************************************************************
***** ROBUSTNESS: MORAN I P-VALUES
***** At ID-bureau level with only pre-war controls  **************** 
*********************************************************************
clear all
spset, clear
use "$Data_generated/analysis_dataset.dta", clear
gen ID_BUREAU = id_bureau

keep if verdun!=0 & verdun<99999


collapse (mean)   lncollabospc latitude longitude verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss WWIdeathrate_nomiss WWIdeathrate_miss  (sum) collabos pop1936 , by (ID_BUREAU RI_number code_dep)

gen collasbospc=collabos /pop1936
gen logcollabospc=log(collasbospc+1)

	* OlS regression
 xi: reg  verdun_petain    $lpretrends_nomiss $precontrols_nomiss  i.code_dep , rob
cap drop x_resid
	predict x_resid, resid

foreach outcomevar of varlist lncollabospc {
		xi: reg `outcomevar'    $lpretrends_nomiss $precontrols_nomiss  i.code_dep  , rob
		predict y_resid_`outcomevar', resid
		}

collapse (mean) x_resid y_resid* lncollabospc latitude longitude verdun_petain  $lpretrends_nomiss $precontrols_nomiss (sum)  collasbospc, by (ID_BUREAU)
	 
merge 1:1 ID_BUREAU using "$Data_generated/bureauderecrutement.dta"

drop if _merge!=3

*spset ID_BUREAU , coord (_CX _CY)
 
	 moransi lncollabospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	 moransi verdun_petain, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail

	 moransi collasbospc, lat(latitude) lon(longitude) swm(bin) dist(500) dunit(km) approx detail
	  
	spmatrix create idistance Wdist,   replace
 	
	putexcel set "$Results/Tables/Morantest.xlsx", sheet("Table 2") modify
	putexcel B2="OLS"
	putexcel B3="Chi-squared"
	putexcel C3="p-value"
	putexcel E2="IV"
	putexcel E3="Chi-squared"
	putexcel F3="p-value"	

	local i = 4
	foreach outcomevar in lncollabospc {
		reg y_resid_`outcomevar' x_resid
		estat moran, errorlag(Wdist) 
		putexcel A`i'="`outcomevar'"
		putexcel B`i'=`r(chi2)' 		
		putexcel C`i'=`r(p)'
		local i = `i' + 1
		sleep 1000
	}	

/*  
         chi2(1)      =     0.00
         Prob > chi2  =   0.9979
*/
}

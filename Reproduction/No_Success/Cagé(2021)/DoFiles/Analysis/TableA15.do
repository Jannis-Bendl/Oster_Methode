*********************************************************************************************
*********************************************************************************************
***************** 	TABLE A15 		    *********************************
*********************************************************************************************
*********************************************************************************************
quietly {
use "$Data_generated/analysis_dataset.dta", clear
estimates clear
pwcorr  verdun_petain verdun  marne  somme chemindesdames OutsideFrance  , st(10)

** Des stat in notes to tables
su  WWIdeathrate logww1 if verdun!=. & lncollabospc!=.


** Exposure to other War-related events 

		cap drop inter
		gen inter = verdun_petain * s_logww1

gen logdeaths_1916= log(totaldeaths_1916)
egen mlogdeaths_1916=mean(logdeaths_1916)
egen sdlogdeaths_1916=sd(logdeaths_1916)
gen s_logdeaths_1916=(logdeaths_1916-mlogdeaths_1916)/sdlogdeaths_1916

su logdeaths_1916 if verdun!=. &  lncollabospc!=.
		cap drop inter2
		gen inter2 = verdun_petain * s_logdeaths_1916


	eststo: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss s_logww1   ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample "All", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss s_logww1 inter ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample "All", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	

	eststo: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss s_logdeaths_1916   ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample "All", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo:  areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss s_logdeaths_1916 inter2 ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample "All", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	


******************* 	EXCLUDING FORTRESS REGIMENTS 	 ******************* 

gen fortress_reg =( RI_number >=145 | RI_number_1 >=145) if  RI_number <9999
tab fortress_reg
ttest verdun , by (fortress_reg)
ttest verdun_petain, by (fortress_reg)
ttest deads_totalreg , by(fortress_reg)


drop if RI_number >=145 
 drop if RI_number_1 >=145 
 
 
foreach y in lncollabospc    {
	eststo: xi: areg `y' verdun_petain  verdun      $lpretrends_nomiss  $precontrols_nomiss      ,  cl(id_bureau) absorb(code_dept) 
 		estadd local Sample "No Fortress", replace 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
	}
		
**  WWII related events 	
use "$Data_generated/analysis_dataset.dta", clear

global wwcontrols_nomiss "s_logww1  lndistdemarcationkm_nomiss vichyfrance_nomiss   lndistdemarcationkm_miss vichyfrance_miss" 
		
	eststo: areg  lncollabospc verdun_petain verdun $lpretrends_nomiss  $precontrols_nomiss $wwcontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample "All", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

			esttab using "$Results/Tables/TableA15.tex", replace ///
	keep(verdun_petain verdun   s_logww1 inter s_logdeaths_1916 inter2 lndistdemarcationkm_nomiss vichyfrance_nomiss ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain (VuP)" verdun "Verdun"  s_logww1 "WWI fatal. rate" inter "VuP*WWI fatal. rate"  s_logdeaths_1916 "Fat. in 1916" inter2 "VuP*1916 fat."  lndistdemarcationkm_nomiss "Log dist demarcation line" vichyfrance_nomiss "Vichy France" ) ///
		nogap ///
		cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(Sample  Pop PreTrends  r2 N ymean ysd clusters, fmt(0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels("Sample"   "1911 pop"     "Pre-WWI vote shares"  "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label mlabels(none) ///
	mgroups("Log collabos pc"  , pattern(1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
	
}

	
	

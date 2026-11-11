************************************************************************************************
******************* 				Table A7							     ******************* 
******************* 			SPLIT MUNICIP								 ******************* 
************************************************************************************************
quietly {
** Reclassify split
estimates clear	
use "$Data_generated/analysis_dataset.dta", clear

 gen D_vup=0 if verdun_petain==0 | verdun_petain<0.5
replace  D_vup=1 if verdun_petain==0.5  
replace  D_vup=2 if verdun_petain>0.5 &  verdun_petain<=1 

label define D_vup 0 "No Verdun-under-Petain or less than half" 1 "Half Verdun-under-Petain" 2 "More than half Verdun-under-Petain"
 label values  D_vup  D_vup 
 tab D_vup, gen ( D_vup)
 
** Redefine treatment=1 if strictly more than half 
 
	** Dep FE **

  eststo treat : areg  lncollabospc D_vup2 D_vup3  verdun     $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

 eststo treat1 : areg  lncollabospc D_vup2 D_vup3      $lpretrends_nomiss $precontrols_nomiss  if verdun==1  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
			** Exclude  Split  **
	tab verdun_petain 
	
	preserve 	
	replace verdun_petain =. if  verdun_petain >0 & verdun_petain <1
	tab verdun_petain
	su verdun_petain   
	** Dep FE **


	 eststo split1a: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		

 eststo split1b: areg  lncollabospc verdun_petain   $lpretrends_nomiss $precontrols_nomiss if verdun ==1 ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
restore

	** Reclassify  Split  **	
	preserve 	
	replace verdun_petain =. if  verdun_petain ==0.5
	replace verdun_petain =0 if  verdun_petain <0.5
	replace verdun_petain =1 if  verdun_petain >0.5 &  verdun_petain <=1
	tab verdun_petain
	su verdun_petain
	** Dep FE **

	eststo split5a: areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo split5b: areg  lncollabospc verdun_petain    $lpretrends_nomiss $precontrols_nomiss  if verdun ==1  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

		restore


esttab using "$Results/Tables/TableA7.tex", replace ///
	keep(verdun_petain D_vup2 D_vup3 ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain" D_vup2 "Half Verdun under P\'{e}tain"  D_vup3 "More than half Verdun under P\'{e}tain" ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Pop PreTrends Verdun  r2 N  ymean ysd clusters, fmt(0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "1911 pop"  "Pre-WWI vote shares"  "WWI death rate"    "R-squared" "Observations"  "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label  ///
	 	mtitles("1914 France" "Verdun only"  "1914 France" "Verdun only"  "1914 France" "Verdun only"    ) ///
mgroups(  "Log collabos pc", pattern(1 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
  
 }
	

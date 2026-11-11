
*********************************************************************************************
*********************************************************************************************
***************** 	     TABLE V: COLLABORATION : Evidence      *****************************
***************** 	   	from other data sources: LVF, OSS		*****************************
*********************************************************************************************
*********************************************************************************************

quietly {
use "$Data_generated/analysis_dataset.dta", clear
merge 1:1 id_geofla using "$Data_origin/Collaboration/collabos_wOSSDouroux_extract.dta"
drop if _merge==2 

foreach x in collabos_DouOSS collabos_Dou collabos_OSS collabos_Dou_wodup collabos_OSS_wodup collabos_DouOSS_wodup {
	replace `x'=0 if _merge!=3
}

  gen totcollabos = collabos_DouOSS_wodup + collabos
  gen totcollabos2 = collabos_DouOSS_wodup - LVF + collabos

 
 foreach x in  collabos_DouOSS collabos_Dou collabos_OSS  totcollabos totcollabos2 {
 	gen ln`x'pc = log(`x'+1) - log(pop1936+1)
 }

  pwcorr  lncollabos_DouOSSpc  lncollabospc
  
estimates clear 
	** Dep FE **
	
	label var lncollabos_DouOSSpc "OSS + LVF"
	label var lncollabos_Doupc "LVF"
	label var lncollabos_OSSpc "OSS"
	
	foreach y in lncollabos_DouOSSpc lntotcollabospc   {

 	eststo:     areg `y' verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample "1914 France", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

 	eststo:     areg `y' verdun_petain      $lpretrends_nomiss $precontrols_nomiss if verdun!=0 & verdun<9999,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample "Verdun only", replace 
		estadd local Verdun "", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
}
	
	
		esttab using "$Results/Tables/TableA10.tex", replace ///
		keep(verdun_petain   ) /// 
		coeflabels(verdun_petain "Verdun under P\'{e}tain"    )   ///
		nogap ///
		cells(b( fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(Verdun Pop PreTrends r2 N ymean ysd clusters, fmt(0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels("Verdun" "1911 pop"  "Pre-WWI vote shares"   "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label   ///
		mtitles("1914 France" "Verdun only" "1914 France" "Verdun only") ///
		mgroups( "OSS + LVF" "Paillole + OSS + LVF", pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
		
}

 		

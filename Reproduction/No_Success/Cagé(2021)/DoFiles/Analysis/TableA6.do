quietly{	
*********************************************************************************************
*********************************************************************************************
***************** 	  TABLE 	A6						    *********************************
***************** 	 Robustness     IHS + Exclude movers 	*********************************
*********************************************************************************************
*********************************************************************************************
use "$Data_generated/analysis_dataset.dta", clear
preserve 

estimates clear 	

** IHS
foreach x in collabos  collabospc {
cap drop `x'sq
cap drop ihs`x'
gen `x'sq=`x'*`x'
gen ihs`x'= log(`x'+sqrt(`x'sq+1))
}

	eststo: areg  ihscollabos verdun_petain verdun  lnpop1936   $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	


	eststo: areg  ihscollabos verdun_petain lnpop1936   $lpretrends_nomiss $precontrols_nomiss if verdun  >0,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Verdun "", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Pop1936 "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

restore

** Control for lat, long, dist Cauchy					

	eststo: areg  lncollabospc verdun_petain verdun   latitude longitude  latitudesq longitudesq $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample  "Whole", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "\checkmark", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
		
			eststo: areg  lncollabospc verdun_petain    latitude longitude latitudesq longitudesq  $lpretrends_nomiss $precontrols_nomiss if  verdun   >0   ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample  "Whole", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "\checkmark", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		

	eststo: areg  lncollabospc verdun_petain verdun  lndistance_Cauchy latitude longitude  latitudesq longitudesq $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample  "Whole", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "\checkmark", replace
		estadd local DistCauchy "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
		
			eststo: areg  lncollabospc verdun_petain    lndistance_Cauchy latitude longitude latitudesq longitudesq  $lpretrends_nomiss $precontrols_nomiss if  verdun   >0   ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Sample  "Whole", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PolyLatLong "\checkmark", replace
		estadd local DistCauchy "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
		
*******  Non movers  and Movers ******************************
*** In log
 	foreach y in   lnnonmoverpc      {	


	eststo: areg  `y' verdun_petain verdun    $lpretrends_nomiss  $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	


	eststo: areg  `y' verdun_petain     $lpretrends_nomiss  $precontrols_nomiss if  verdun   >0 ,  cl(id_bureau)  absorb(code_dept) 
 		estadd local Verdun "", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local PolyLatLong "", replace
		estadd local DistCauchy "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	}

	
esttab using "$Results/Tables/TableA6.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"  ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Verdun Pop PreTrends PolyLatLong DistCauchy r2 N  ymean ysd clusters, fmt(0 0  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels(  "Verdun" "1911 pop"  "Pre-WWI vote shares" "Polynomial Lat/Long" "Log. dist. Cauchy"  "R-squared" "Observations"  "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label  ///
	mtitles("1914 France"   "Verdun only"   "1914 France"   "Verdun only"  "1914 France"   "Verdun only"   "1914 France"   "Verdun only"  ) ///
	mgroups( "Collaborators - IHS" "Log Collabos pc"  "Log collabos pc - w/o movers", pattern(1 0 1 0 0 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  
}

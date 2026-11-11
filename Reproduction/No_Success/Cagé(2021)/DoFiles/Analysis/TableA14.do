
quietly {
use "$Data_generated/analysis_dataset.dta", clear
estimates clear 

foreach y in   lncollabospc {
eststo: xi: areg `y'   Dfoch_any  $lpretrends_nomiss   $precontrols_nomiss   ,  cl(id_bureau) absorb (code_dep) 	
		estadd local Sample "All", replace 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: areg `y'    marne   $lpretrends_nomiss   $precontrols_nomiss   ,  cl(id_bureau) absorb (code_dep) 	
		estadd local Sample "All", replace 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: areg `y'    somme   $lpretrends_nomiss   $precontrols_nomiss   ,  cl(id_bureau) absorb (code_dep) 	
		estadd local Sample "All", replace 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

 
eststo: xi: areg `y'  verdun_petain verdun   somme marne   Dfoch_any   $lpretrends_nomiss   $precontrols_nomiss   ,  cl(id_bureau) absorb (code_dep) 	
		estadd local Sample "All", replace 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
}

	esttab using "$Results/Tables/TableA14.tex", replace ///
	keep(verdun_petain verdun somme marne Dfoch_any ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain" verdun "Verdun" somme "Somme" marne "Marne" Dfoch_any "Foch" ) ///
		nogap ///
		cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(Sample  Pop PreTrends  r2 N ymean ysd clusters, fmt(0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels("Sample"   "1911 pop"     "Pre-WWI vote shares"  "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label mlabels(none) ///
	mgroups("Log collabos pc"  , pattern(1 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
	
}

*********************************************************************************************
*********************************************************************************************
***************** 	TABLE A16: Coordination vs Internalized Values   ************************
*********************************************************************************************
*********************************************************************************************

quietly {
** Merge indiv collabos to municip battle history to determine: movers from P to NP; NP to P; P to P; NP to NP

  use "$Data_origin/Collaboration/analysis_dataset_moversTableA16.dta", clear 

*** In log
estimates clear	
	foreach y in lnmover_fromPpc lsh_fromP_mover  lnmover_fromNPpc lsh_fromNP_mover {	
	
	** Dep FE and controls **
	eststo: xi: areg `y'  verdun_petain verdun      $lpretrends_nomiss $precontrols_nomiss   ,  cl(RI_number) absorb(code_dep) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

	}
	esttab using "$Results/Tables/TableA16.tex", replace ///
		keep(verdun_petain   ) /// 
		coeflabels(verdun_petain "Verdun under P\'{e}tain"   ) ///
		nogap ///
		cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(  Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt( 0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels(  "Verdun" "1911 pop"   "Pre-WWI vote shares"  "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label mlabels(none) 	mgroups("Collab. V-u-P" "Sh. V-u-P" "Collab. Not V-u-P" "Sh. Not V-u-P" , pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 


*** Col 1 vs 3 
  estimates clear
	qui eststo lnmover_fromPpc: xi: reg  lnmover_fromPpc verdun_petain verdun      $lpretrends_nomiss $precontrols_nomiss  i.code_dep
est store lsh_fromP_mover

	qui eststo  lnmover_fromNPpc : xi: reg  lnmover_fromNPpc   verdun_petain verdun      $lpretrends_nomiss $precontrols_nomiss   i.code_dep
est store lsh_fromNP_mover

suest  lnmover_fromPpc lnmover_fromNPpc, cl(RI_number) 
test [lnmover_fromPpc_mean]verdun_petain  = [lnmover_fromNPpc_mean]verdun_petain


*** Col 2 vs 4
  estimates clear
	qui eststo  lsh_fromP_mover: xi: reg  lsh_fromP_mover  verdun_petain verdun      $lpretrends_nomiss $precontrols_nomiss    i.code_dep
est store lsh_fromP_mover

	qui eststo  lsh_fromNP_mover : xi: reg  lsh_fromNP_mover   verdun_petain verdun      $lpretrends_nomiss $precontrols_nomiss    i.code_dep
est store lsh_fromNP_mover

suest  lsh_fromP_mover lsh_fromNP_mover, cl(RI_number) 
test [lsh_fromP_mover_mean]verdun_petain  = [lsh_fromNP_mover_mean]verdun_petain

}


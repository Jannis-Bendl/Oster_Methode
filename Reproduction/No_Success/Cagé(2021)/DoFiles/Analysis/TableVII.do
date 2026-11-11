

*********************************************************************************************
*********************************************************************************************
***************** 	     TABLE VII 1&2: BY GROUP			*********************************
*********************************************************************************************
*********************************************************************************************

use "$Data_generated/analysis_dataset.dta", clear

*********************************************************************************************
** TABLE VII - PANEL 1
*********************************************************************************************
estimates clear
foreach y in lnRNPpc lnPPFpc lnMSRpc lnFRApc lnSOLpc lnMILpc  lnLVFpc   {

***************** 
eststo: xi: areg `y'  verdun_petain verdun    $lpretrends_nomiss   $precontrols_nomiss  , cl(id_bureau) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
	}
esttab using "$Results/Tables/TableVII_panel1.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"  ) ///
		nogap ///
		cells(b( fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats( Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt(  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "Verdun" "1911 pop"  "Pre-WWI vote shares"    "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters" )) ///
				collabels(none) label   ///
		mtitles("\shortstack[]{RNP \\ Feb 1941}"    "\shortstack[]{PPF \\ Jun 1936}" "\shortstack[]{MSR \\ 1940(1936)}"  "\shortstack[]{Francism \\1941(1933)}"    "\shortstack[]{SOL \\Aug 1941}" "\shortstack[]{Milice \\Jan 1943}" "\shortstack[]{LVF \\Aug 1941}") ///
				/*mtitles( "02/1941"    "06/1936" "09/1940"  "1941 (1933)"   "09/1940"  "08/1941" "01/1943" "08/1941"  "07/1940" "07/1940"   "07/1940"   "11/1940" ) ///
		*/ mgroups( "Political Collaboration" "Paramilitary Collaboration",  pattern(1 0 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 	
		
*********************************************************************************************
** TABLE VII - PANEL 2 (continued)
*********************************************************************************************
estimates clear
foreach y in  lnSRApc lnGOpc lnSSpc lnCOLEpc     lnAMpc     {

***************** 
eststo: xi: areg `y'  verdun_petain verdun    $lpretrends_nomiss   $precontrols_nomiss  , cl(id_bureau) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
	}
esttab using "$Results/Tables/TableVII_panel2.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"  ) ///
		nogap ///
		cells(b( fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats( Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt(  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "Verdun" "1911 pop"  "Pre-WWI vote shares"    "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters" )) ///
				collabels(none) label   ///
		mtitles( "\shortstack[]{Germ Int \\Jul 1940}" "\shortstack[]{Gestapo \\Jul 1940}"  "\shortstack[]{SS \\Jul 1943}"  "\shortstack[]{Economic \\Jul 1940}"    "\shortstack[]{AM \\Nov 1940}") ///
				/*mtitles( "02/1941"    "06/1936" "09/1940"  "1941 (1933)"   "09/1940"  "08/1941" "01/1943" "08/1941"  "07/1940" "07/1940"   "07/1940"   "11/1940" ) ///
		*/ mgroups("Nazi Collaboration" "\shortstack{Economic\\Collaboration}" "Other",  pattern( 1 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
		
* des stat in bottom of table 

**** No "Suspects", or "Colllabos" in graph"
 	collapse (sum) RNP   PPF MSR FRA SOL MIL LVF SRA GO COLE GRC AM 
	
	su RNP   PPF MSR FRA SOL MIL LVF SRA GO COLE GRC AM 
	
 		

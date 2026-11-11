**********************************************************************************************
********************* 	TABLE III: BATTLE DEATH RATES 				 *************************  
**********************************************************************************************
	estimates clear 
	** At the regiment level: 
use  "$Data_generated/regimentsVerdun.dta", clear 
egen monthly_death = rowmean(deads_Verdun_feb deads_Verdun_march deads_Verdun_april deads_Verdun_mai deads_Verdun_june deads_Verdun_aug deads_Verdun_sept deads_Verdun_oct deads_Verdun_nov deads_Verdun_dec ) if verdun==1
gen logdeads_totalreg = log(deads_totalreg )
label var logdeads_totalreg "Log. Deaths by regiment"
gen logtotaldeaths_1916 = log(totaldeaths_1916)
label var logtotaldeaths_1916 "Log. Deaths by regiment in 1916"
estimates clear 
eststo:	 xi: reg logdeads_totalreg  marne verdun_petain verdun somme  chemindesdames OutsideFrance
 		estadd local FixedEffects "NA", replace 
		estadd local Unit "Regiment", replace 
		estadd local Time "Whole war", replace 
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

		eststo:	 xi: reg logtotaldeaths_1916   verdun_petain verdun somme  OutsideFrance
 		estadd local FixedEffects "NA", replace 
		estadd local Unit "Regiment", replace 
		estadd local Time "1916", replace 
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

		** At the municipality level:		
use "$Data_generated/analysis_dataset.dta", clear


 * 
 
 eststo:	 xi: reg logww1 marne verdun_petain verdun somme chemindesdames OutsideFrance , cl(id_bureau)
 		estadd local FixedEffects "NA", replace 
		estadd local Unit "Municipality", replace 
		estadd local Time "Whole war", replace 
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
 
 eststo:	 xi: areg logww1 marne verdun_petain verdun somme chemindesdames OutsideFrance , absorb(code_dep) cl(id_bureau)
 		estadd local FixedEffects "Dept", replace 
		estadd local Unit "Municipality", replace 
		estadd local Time "Whole war", replace 
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
esttab using "$Results/Tables/TableIII.tex", replace ///
		keep(verdun_petain verdun marne  somme   chemindesdames  OutsideFrance   ) /// 
		coeflabels( verdun_petain "Verdun under P\'{e}tain" verdun "Verdun"  marne "Marne"    somme "Somme"   chemindesdames  "Chemin des Dames" OutsideFrance "South Eastern Front" ) ///
		nogap ///
		cells(b( fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(FixedEffects Unit Time r2 N ymean ysd clusters, fmt(0 0 0 %9.2f %15.0fc  %15.2fc  %15.2fc  %15.0fc) labels("Fixed Effects" "Unit of obs." "Time-period" "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) 	  collabels(none) label mlabels(none) ///
		mgroups( "Deaths by regiment (log)" "Municipality WWI fatality rate (log+1)" , pattern(1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 


*** Specification 3:
eststo:	 xi: reg logww1 marne verdun_petain verdun somme chemindesdames OutsideFrance , cl(id_bureau)
test marne +verdun_petain+ verdun +somme+ chemindesdames=0
/*

 ( 1)  marne + verdun_petain + verdun + somme + chemindesdames = 0
       F(  1,   157) =    0.02
            Prob > F =    0.8859

*/
test marne +verdun_petain+ verdun +somme+ chemindesdames+OutsideFrance =0
/*
 ( 1)  marne + verdun_petain + verdun + somme + chemindesdames + OutsideFrance = 0
       F(  1,   157) =    0.96
            Prob > F =    0.3278
*/

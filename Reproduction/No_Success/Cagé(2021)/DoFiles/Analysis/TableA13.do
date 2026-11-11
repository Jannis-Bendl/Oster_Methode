*********************************************************************************************
*********************************************************************************************
***************** 	References to Command Generals	    *********************************
*********************************************************************************************
*********************************************************************************************
quietly{
import excel "$Data_raw/Regiments/Historiques_MentionsPetain/MentionsPETAIN.xlsx",   firstrow case(lower) clear 

ren ri_number RI_number

replace context_command = "2" in 28
replace context_strategy=0 if context_strategy==.
replace  context_medals =0 if context_medals==.
replace context_command = "2" in 28
destring context_command, replace
replace  context_command =0 if context_command==.
replace  context_medals =0 if context_medals==.
destring nivellementions, replace 

merge 1:1 RI_number using "$Data_generated/regimentsVerdun.dta", gen (merge_mentions)

keep if RI_number<174

su petainmention  nivellementions manginmentions fochmention 

ttest petainmention, by (verdun_petain)
ttest nivellementions, by (verdun_petain)
ttest manginmentions, by (verdun_petain)
ttest fochmention, by (verdun_petain)

su context_strategy context_command context_medals
su context_strategy context_command context_medals if petainmention>0 & petainmention<999

** stats in text section 2.4
display 0.4285714 + 0.244898 + 1.418367
* 2.0918364
display  0.4285714/2.0918364
display 0.244898/2.0918364
display 1.418367 /2.0918364

foreach y in petainmention nivellementions manginmentions fochmention {
gen l`y' = log(`y'+1)
}


label var lpetainmention Pétain 
label var lnivellementions Nivelle  
label var lmanginmentions Mangin
label var lfochmention  Foch

estimates clear 
foreach y in petainmention nivellementions   {
eststo:	reg l`y' verdun_petain verdun, rob 
		estadd ysumm	
eststo:	reg l`y' verdun_petain if verdun==1, rob 
		estadd ysumm	
eststo:	reg l`y' verdun_petain verdun marne somme  chemindesdames  , rob 
		estadd ysumm	

}

		****MEDALS **********************************************************
	
use "$Data_generated/analysis_dataset.dta", clear
 gen logmedals=log(sum_medals)
label var logmedals "Log. Citations"

su sum_medals 
	
eststo:	areg  logmedals verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample "1914 France", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

eststo:	areg logmedals  verdun_petain  $lpretrends_nomiss $precontrols_nomiss if  verdun  >0  ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Sample "Verdun only", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

  		
esttab using "$Results/Tables/TableA13.tex", replace ///
		keep(verdun_petain verdun  marne somme  chemindesdames  ) /// 
		coeflabels( verdun_petain "Verdun under P\'{e}tain" verdun "Verdun"  marne "Marne"    somme "Somme"   chemindesdames  "Chemin des Dames"   ) ///
		nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats(r2 N ymean ysd, fmt(%9.2f %15.0fc %9.2f  %9.2f) labels( "R-squared" "Observations" "Mean DepVar" "Sd DepVar")) ///
	collabels(none) label  ///
	mtitles("1914 France"  "Verdun only" "1914 France" "1914 France"  "Verdun only" "1914 France" "1914 France"  "Verdun only" "1914 France" "Verdun only" "1914 France") ///
	mgroups(  "P\'{e}tain" "Nivelle" "Medal Citations" , pattern(1 0 0 1 0 0 1 0  ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  

	}	
	


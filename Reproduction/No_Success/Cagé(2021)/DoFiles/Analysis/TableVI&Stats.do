***************************************************************
*********** Table VI   ****************************************
***************************************************************

use "$Data_generated/analysis_dataset.dta", clear
cap drop _merge 
merge 1:1 id_geofla using "$Data_origin/Regiments/regiments_petainhistory_idgeofla.dta" , gen (allPetain)

su peacetime_fieldcommand  startwar_fieldcommand peacetime  armycorps33th regimentinfantry33th IIarmy center_army_group 

gen Petain_peace = peacetime_fieldcommand + peacetime 
label var Petain_peace "P\'{e}tain before WWI"

label var IIarmy "P\'{e}tain in war before Verdun"
 
label var center_army_group "P\'{e}tain after Verdun"
label var beforeVerdun "P\'{e}tain before Verdun"
 
 foreach x in Petain_peace IIarmy center_army_group {
replace `x'=. if verdun==.
 }
 
 * des stats 
 su Petain_peace beforeVerdun    IIarmy center_army_group Dfoch if verdun!=.

 gen Petain_any =(Petain_peace==1|     IIarmy ==1|center_army_group==1| verdun_petain==1) if verdun_petain!=.
 su Petain_any if verdun_petain!=.


 foreach x in  Petain_peace  peacetime_fieldcommand  startwar_fieldcommand peacetime  armycorps33th regimentinfantry33th IIarmy center_army_group {
su  verdun_petain verdun  if `x'==1
}


encode code_dep, gen(code)

** Label vars
	label var lncollabospc  "Log collabos pc"
	foreach x in 14 19 24 32 36 {
		label var lshRight_`x'  19`x'
	}
	
	label var Dfoch_any "Foch"
	label var beforeVerdun "Pétain before Verdun"
	
	
	
	
	
	
 
 estimates clear 

foreach y in   lnWWI_LineVetpc lnNon_WWIVetpc   {
	** Dep FE 
	eststo  :   areg  `y' verdun_petain  verdun   $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo  :  areg  `y'  beforeVerdun    verdun   $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	


	eststo :  areg  `y'  beforeVerdun verdun_petain  verdun   $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dept) 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
		test beforeVerdun =  verdun_petain 
		}			
	
		esttab using "$Results/Tables/TableVI_new.tex", replace ///
		keep(verdun_petain beforeVerdun     ) /// 
		coeflabels(verdun_petain "Verdun under P\'{e}tain"  beforeVerdun "P\'{e}tain before Verdun"     )   ///
		nogap ///
		cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats( Verdun Pop PreTrends r2 N ymean ysd clusters, fmt( 0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "Verdun"  "1911 pop"  "Pre-WWI vote shares"   "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label   ///
		mtitles("Line vets" "Line vets" "Line vets"  "Non veterans"  "Non veterans"  "Non veterans" ) ///
mgroups( "Collaborators who are: "   , pattern(1 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
 
 ** Test whether indirect effect = direct effect in VuP vs BV
encode code_dept , gen(code_depn)
 
estimates clear 
	eststo  lnWWI_LineVetpc:   reg lnWWI_LineVetpc  verdun_petain  verdun   $lpretrends_nomiss $precontrols_nomiss i.code_depn 
 est store lnWWI_LineVetpc
 eststo  lnNon_WWIVetpc:   reg lnNon_WWIVetpc  verdun_petain  verdun   $lpretrends_nomiss $precontrols_nomiss i.code_depn 
 est store lnNon_WWIVetpc

 
suest  lnWWI_LineVetpc lnNon_WWIVetpc, cl(id_bureau) 
test [lnWWI_LineVetpc_mean]verdun_petain  = [lnNon_WWIVetpc_mean]verdun_petain
/*
           chi2(  1) =    1.77
         Prob > chi2 =    0.1833
*/

** Verdun subsample

** Test whether indirect effect = direct effect in VuP vs BV
* encode code_de , gen(code_depn)	/* fais plus haut */
	
estimates clear 
	eststo  lnWWI_LineVetpc:   reg lnWWI_LineVetpc  verdun_petain    $lpretrends_nomiss $precontrols_nomiss i.code_depn if  verdun>0
 est store lnWWI_LineVetpc
 eststo  lnNon_WWIVetpc:   reg lnNon_WWIVetpc  verdun_petain     $lpretrends_nomiss $precontrols_nomiss i.code_depn if  verdun>0 
 est store lnNon_WWIVetpc

 
suest  lnWWI_LineVetpc lnNon_WWIVetpc, cl(id_bureau) 
test [lnWWI_LineVetpc_mean]verdun_petain  = [lnNon_WWIVetpc_mean]verdun_petain
/*
           chi2(  1) =    1.77
         Prob > chi2 =    0.1833
*/



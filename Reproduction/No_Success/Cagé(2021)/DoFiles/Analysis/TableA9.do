			
*****************************************************************************************************
/****************** Table A9: RDD			   							****************************/
/****************** RDD LOCAL COMPARISONS ACROSS MILIT BOUNDARY			****************************/
*****************************************************************************************************
 quietly {   
use "$Data_generated/analysis_dataset.dta", clear

merge 1:1 id_geofla using "$Data_origin/Misc/RDD_distance_zones.dta" 

gen Dist_Bound_Verdun  = distance_to_zones
label var Dist_Bound_Verdun "Dist. boundary Verdun under Petain"

replace Dist_Bound_Verdun=Dist_Bound_Verdun/1000
su Dist_Bound_Verdun
gen logDist_Bound_Verdun = log(Dist_Bound_Verdun+1)

su Dist_Bound_Verdun logDist_Bound_Verdun
su Dist_Bound_Verdun  if verdun_petain==1
su Dist_Bound_Verdun  if verdun_petain==0


replace  Dist_Bound_Verdun=- Dist_Bound_Verdun if verdun_petain<=0.5

su Dist_Bound_Verdun
gen Dist_Bound_Verdun_petain =Dist_Bound_Verdun*verdun_petain
su Dist_Bound_Verdun_petain

global graphlist  " verdun_petain  WWIdeathrate lnpop1911  popdensity_1911 lndistdemarcationkm vichyfrance   combatdays1940mean shNuance_Gauche shNuance_Droite shNuance_Divers"


gen lat_x_long = latitude  * longitude 
estimates clear
global poly_lat_long "latitude  longitude  latitudesq  longitudesq lat_x_long"

 
*****************************************************************************************************
/****************************** RD Estimate	*************************************/
*****************************************************************************************************
** Number of municip:
count if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22
****    14,511= 41.52 % of original sample 
display   14511/34947

label var lshNuance_Gauche_14 "Log sh Left 1914"
label var lshNuance_Droite_14 "Log sh Right 1914"
label var lnpop1911 "Pop 1911"
label var WWIdeathrate "WWI Death Rate"

clear matrix
eststo clear

*** First Stage
qui eststo: xi: reg verdun_petain Dist_Bound_Verdun  verdun  $lpretrends_nomiss  $precontrols_nomiss   i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau) first
	estadd local Verdun "\checkmark", replace 
	estadd local Pop "\checkmark", replace 
	estadd local PreTrends "\checkmark", replace
	estadd local Fstat ".", replace
	estadd local Poly "", replace
	estadd ysumm	
	estadd scalar clusters = e(N_clust)	
qui eststo: xi: reg verdun_petain Dist_Bound_Verdun  verdun  $lpretrends_nomiss  $precontrols_nomiss  $poly_lat_long  i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau) first
 	estadd local Verdun "\checkmark", replace 
	estadd local Pop "\checkmark", replace 
	estadd local PreTrends "\checkmark", replace
	estadd local Fstat ".", replace
	estadd local Poly "\checkmark", replace
	estadd ysumm		
	estadd scalar clusters = e(N_clust)	

*** Second stage 
eststo: xi: ivreg2 lncollabospc   (verdun_petain= Dist_Bound_Verdun ) verdun  $lpretrends_nomiss $precontrols_nomiss     i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)  first
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Poly "", replace
		estadd local Fstat "51.73", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	
		
eststo: xi: ivreg2 lncollabospc   (verdun_petain= Dist_Bound_Verdun ) verdun  $lpretrends_nomiss $precontrols_nomiss  $poly_lat_long  i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)  first
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local Poly "\checkmark", replace
		estadd local Fstat "54.25", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
 
		
eststo: xi: ivreg2 lshNuance_Gauche_14  (verdun_petain= Dist_Bound_Verdun ) verdun   $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "", replace
		estadd local Fstat "50.74", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: ivreg2 lshNuance_Gauche_14  (verdun_petain= Dist_Bound_Verdun ) verdun  $poly_lat_long  $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "\checkmark", replace
		estadd local Fstat "53.44", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		
eststo: xi: ivreg2 lshNuance_Droite_14 (verdun_petain= Dist_Bound_Verdun ) verdun   $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "", replace
		estadd local Fstat "50.74", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: ivreg2 lshNuance_Droite_14 (verdun_petain= Dist_Bound_Verdun ) verdun  $poly_lat_long  $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "\checkmark", replace
		estadd local Fstat "53.44", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		
eststo: xi: ivreg2 WWIdeathrate (verdun_petain= Dist_Bound_Verdun ) verdun   $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "", replace
		estadd local Fstat "51.73", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: ivreg2 WWIdeathrate (verdun_petain= Dist_Bound_Verdun ) verdun  $poly_lat_long  $precontrols_nomiss  i.code_dept if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "", replace
		estadd local Poly "\checkmark", replace
		estadd local Fstat "54.25", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	


eststo: xi: ivreg2  lnpop1911 (verdun_petain= Dist_Bound_Verdun ) verdun    i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau) first   
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "", replace 
		estadd local PreTrends "", replace
		estadd local Poly "", replace
		estadd local Fstat "51.89", replace
		estadd ysumm	
		estadd scalar clusters = e(N_clust)	

eststo: xi: ivreg2  lnpop1911 (verdun_petain= Dist_Bound_Verdun ) verdun  $poly_lat_long  i.code_dep if Dist_Bound_Verdun>=-17.5 &  Dist_Bound_Verdun<=22, cl(id_bureau)   first 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "", replace 
		estadd local PreTrends "", replace
		estadd local Poly "\checkmark", replace
		estadd local Fstat "54.41", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		
esttab using "$Results/Tables/TableA9.tex", replace label ///
	keep(Dist_Bound_Verdun verdun_petain) /// 
	coeflabels(Dist_Bound_Verdun "Distance from military boundary" verdun_petain "Verdun under P\'{e}tain"    ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats(Verdun Pop PreTrends Poly r2 N ymean ysd clusters Fstat, fmt(0 0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc %15.2fc) labels("Verdun" "Pop 1911" "Pre-WWI vote shares" "RD polynomial"  "R-squared"  "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters" "F-stat first stage")) ///
	collabels(none)  ///
	mgroups("First stage" "Second stage", pattern(1 0 1 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
 }			
  

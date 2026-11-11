
********************************************************************************
* Table A12
********************************************************************************
quietly{
********************************************************************************
* 1919
********************************************************************************
use "$Data_generated/analysis_dataset.dta", clear 

global elec1919 "shExtremeGauche_19 shCommuniste_19 shSFIO_19 shDiversGauche_19 shPRRS_19 shREPSOC_19 shRADIND_19 shGaucheRadicale_19 shARD_19 shGRD_19 shRG_19 shFRURD_19 shUNR_19 shARS_19 shERD_19 shBlocNational_19 shAnciensCombattants_19 shDiversDroite_19 shActionFrancaise_19 shExtremeDroite_19 shDivers_19 shNuance_ExtremeGauche_19 shNuance_Gauche_19 shNuance_CentreGauche_19 shNuance_Gauche_19 shNuance_CentreDroit_19 shNuance_Droite_19 shNuance_ExtremeDroite_19 "

global elec1919_I "shExtremeGauche_I_19 shCommuniste_I_19 shSFIO_I_19 shDiversGauche_I_19 shPRRS_I_19 shREPSOC_I_19 shRADIND_I_19 shGaucheRadicale_I_19 shARD_I_19 shGRD_I_19 shRG_I_19 shFRURD_I_19 shUNR_I_19 shARS_I_19 shERD_I_19 shBlocNational_I_19 shAnciensCombattants_I_19 shDiversDroite_I_19 shActionFrancaise_I_19 shExtremeDroite_I_19 shDivers_I_19 shNuance_ExtremeGauche_I_19 shNuance_Gauche_I_19 shNuance_CentreGauche_I_19 shNuance_CentreDroit_I_19 shNuance_Droite_I_19 shNuance_ExtremeDroite_I_19"

su  $elec1919 $elec1919_I

encode code_dept, gen (code_dept_num)
 gen unique_arr = code_dept_num*100+ code_arr


foreach var in $elec1919 $elec1919_I {
	su `var'
	cap drop l`var'
	gen l`var'=ln(`var')  if `var'<=100
}

foreach p in Communiste SFIO PRRS REPSOC ARD GRD RG FRURD UNR ARS ERD AnciensCombattants DiversDroite ActionFrancaise  {
	gen D2Run`p'_19=(DRun`p'_19>0 & DRun`p'_19<99999)
}
	

label var  lshExtremeGauche_19  "Misc. Ext. Left"
label var  lshNuance_ExtremeGauche_I_19 "Misc. Ext. Left"
label var  lshCommuniste_19  "Communistes"
label var  lshSFIO_19  "SFIO"
label var  lshPRRS_19  "PRRS"
label var  lshREPSOC_19  "REP SOC"
label var  lshARD_19  "ARD"
label var  lshGRD_19  "GRD"
label var  lshRG_19  "RG"
label var  lshFRURD_19  "FR-URD"
label var  lshUNR_19  "UNR"
label var  lshARS_19  "ARS"
label var  lshERD_19  "ERD"
label var  lshAnciensCombattants_19  "Anc. Comb."
label var  lshDiversDroite_19  "Misc. Right"
label var  lshExtremeDroite_19   "Misc. Ext. Right"
label var  lshNuance_ExtremeGauche_19  "Extr. Left
label var  lshNuance_Gauche_19  "Left, 1919"
label var  lshNuance_CentreGauche_19  "Center Left"
label var  lshNuance_CentreDroit_19  "Center Right"
label var  lshNuance_Droite_19  "Right"
label var  lshNuance_ExtremeDroite_19  "Extr. Right"
label var lshActionFrancaise_19 "Action Francaise"

eststo clear

foreach p in Communiste SFIO PRRS REPSOC ARD GRD  FRURD UNR ARS ERD AnciensCombattants DiversDroite  ActionFrancaise {
	su sh`p'_19
		}
		
eststo clear
		
		foreach p in  SFIO PRRS FRURD UNR   ERD  {
	su sh`p'_19
	eststo: xi: reghdfe  lsh`p'_19 verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss  i.D2Run`p'_19, cl(id_bureau unique_arr) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		}
		
		
esttab using "$Results/Tables/vote1919_party.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"  ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Verdun  Pop PreTrends  r2 N ymean ysd clusters, fmt(0   0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels(  "Verdun" "1911 pop"  "Pre-WWI vote shares"     "R-squared" Observations "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label ///
	mgroups( "Left" "Center Left"   "Right"   ,  pattern(  1 1 1  0 0 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					

********************************************************************************
* 1924 results
********************************************************************************
use "$Data_generated/analysis_dataset.dta", clear 
encode code_dept, gen (code_dept_num)
gen unique_arr = code_dept_num*100+ code_arr
	
foreach var of varlist shBOP_24 shSFIO_24 shDVG_24 shRADSOC_24 shREPSOC_24 shREPRAD_24 shRG_24 shERD_24 shConservateur_24 shDivers_24 ///
shNuance_ExtremeGauche_24 shNuance_Gauche_24 shNuance_CentreGauche_24 shNuance_CentreDroit_24 shNuance_Droite_24 shNuance_Divers_24 ///
shLeft_24 shRight_24  {
	su `var'
	cap drop l`var'
	gen l`var'=ln(`var')  
	}
	
label var  lshBOP_24 "BOP"
label var  lshSFIO_24 "SFIO"
label var  lshDVG_24 "Misc. left"
label var  lshRADSOC_24 "RAD-SOC"
label var  lshREPSOC_24 "REP-SOC"
label var  lshREPRAD_24 "REP-RAD"
label var  lshRG_24 "RG"
label var  lshERD_24 "ERD"
label var  lshConservateur_24 "Conservateur"
label var  lshDivers_24 "Misc"


eststo clear
foreach p in BOP SFIO  RADSOC  REPRAD RG ERD Conservateur {

	su sh`p'_24
	gen D2Run`p'_24=(DRun`p'_24>0 & DRun`p'_24<99999)

	eststo: xi: reghdfe  lsh`p'_24 verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss  i.D2Run`p'_24, cl(id_bureau unique_arr) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		}
esttab using "$Results/Tables/vote1924_party.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"   ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt(  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels(  "Verdun" "1911 pop"  "Pre-WWI vote shares"    "R-squared" Observations "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label ///
	mgroups("Ext. Left" "Left" "Center Left" "Center Right" "Right",  pattern(1 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					

label var lshNuance_ExtremeGauche_24 "Extreme Left"
label var lshNuance_Gauche_24 "Left"
label var lshNuance_CentreGauche_24 "Center Left"
label var lshNuance_CentreDroit_24 "Center Right"
label var lshNuance_Droite_24 "Right"


********************************************************************************
*   1932 results
********************************************************************************

foreach var of varlist shPCF_32 shSFIO_32 shDVG_32	shREPSOC_32	shRADSOC_32	shDIV_32 shADRG_32 shADIND_32 shADPDP_32 shFRURD_32	shAGR_32 shDVD_32 ///
shNuance_ExtremeGauche_32 shNuance_Gauche_32 shNuance_CentreGauche_32 shNuance_Droite_32 shNuance_CentreDroit_32 shNuance_Divers_32 ///
shLeft_32 shRight_32  {
	cap drop l`var'
	gen l`var'=ln(`var')  
	su `var'
	}
	
* At the level of the party 	
label var lshPCF_32 	"PCF"
label var lshSFIO_32 	"SFIO"
label var lshDVG_32 	"Misc. left"
label var lshREPSOC_32  "REP-SOC"
label var lshRADSOC_32 	"RAD-SOC"
label var lshADRG_32 	"AD-RG"
label var lshADIND_32 	"AD-IND"
label var lshADPDP_32 	"AD-PDP"
label var lshFRURD_32	"FR-URD"
label var lshAGR_32 	"AGR"
label var lshDVD_32 	"Misc. right"


eststo clear
foreach p in PCF SFIO  REPSOC RADSOC ADRG ADIND ADPDP FRURD   {
	su sh`p'_32
	gen D2Run`p'_32=(DRun`p'_32>0 & DRun`p'_32<99999)

	eststo: xi:  reghdfe lsh`p'_32 verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss i.D2Run`p'_32, cl(id_bureau unique_arr) absorb(code_dept ) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		}
	esttab using "$Results/Tables/vote1932_party.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"  ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt(0 0   0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "Verdun" "1911 pop"  "Pre-WWI vote shares"     "R-squared" Observations "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label ///
	mgroups("Ext. Left" "Left" "Center Left" "Center Right" "Right",  pattern(1 1 1 0 1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

********************************************************************************
*   1936 results
********************************************************************************	
foreach var of varlist shPCF_36 shSFIO_36 shDVG_36 shUSR_36 shRADSOC_36 shDIV_36 shAD_36 shFRURD_36 shAGR_36 shDVD_36 shFRANCISTE_36 shPRN_36 ///
shNuance_ExtremeGauche_36 shNuance_Gauche_36 shNuance_CentreGauche_36 shNuance_Droite_36 shNuance_CentreDroit_36 shNuance_ExtremeDroite_36 shNuance_Divers_36 ///
shLeft_36 shRight_36  {
	cap drop l`var'
	gen l`var'=ln(`var'+1)  
	su `var'
	}

label var lshPCF_36 "PCF"
label var lshSFIO_36 "SFIO"
label var lshDVG_36 "DVG"
label var lshUSR_36 "USR"
label var lshRADSOC_36 "RAD-SOC"
label var lshDIV_36 "DIV"
label var lshAD_36 "AD"
label var lshFRURD_36 "FR-URD"
label var lshPRN_36 "PRN"
label var lshAGR_36 "AGR"
label var lshDVD_36 "DVD"
label var lshFRANCISTE_36 "Franciste"	

** Correlation Franciste in 1936 and Franciste in collab
pwcorr lshFRANCISTE_36  lnFRApc 


set more off
eststo clear	
foreach p in PCF SFIO USR RADSOC AD   PRN AGR FRANCISTE {
	su sh`p'_36 
	gen D2Run`p'_36=(DRun`p'_36>0 & DRun`p'_36<99999)
	eststo: xi: reghdfe  lsh`p'_36 verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss  i.D2Run`p'_36 , cl(id_bureau unique_arr) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
 		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		}		
esttab using "$Results/Tables/vote1936_party.tex", replace ///
		keep(verdun_petain  ) /// 
		coeflabels(verdun_petain "Verdun under P\'{e}tain"   ) ///
		nogap ///
		cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats( Verdun Pop PreTrends   r2 N ymean ysd clusters, fmt( 0 0 0 %9.2f %15.0fc %15.2fc %15.2fc  %15.0fc) labels( "Verdun" "1911 pop"   "Pre-WWI vote shares"   "R-squared" Observations "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label ///
	mgroups("Ext. Left" "Left" "Center Left" "Center Right" "Right" "Ext. Right",  pattern(1 1 1 0 1 0 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					
}
 


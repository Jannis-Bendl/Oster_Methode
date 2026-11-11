
/* 

This do file generates descriptive statistics in the main body of the paper and notes to Tables 
commands used to generate statistics based on individual level collaboration dataset are muted, based on Ethics agreement
*/ 

* I. INTRODUCTION

use  "$Data_origin/Collaboration/collabosPaillole.dta", clear 
** number of collaborators on list 
su N_c  Nnonmissinglocation
** Info on sex and age 
su NinfoAge_sex
** Info on male vet
egen totalvet = sum(WWI_LineVet)
dis totalvet
 
** % regiments at Verdun
use "$Data_generated/regimentsVerdun.dta", clear 
tab verdun
tab verdun_petain 

** % regiments at Verdun by May 1st
gen feb_march_apr = (feb==1|march==1|april==1)
tab feb_march_apr
display 92/173

** Numbers of Milice members and Gestapo 
/*
use "$Data_origin/Collaboration/list_collaborators_collaborationgroups_final_idgeofla_complete_V10.dta",clear
count if MIL==1 
count if GO==1
*/
** Number of WW1 fatalities
use "$Data_origin/WWIDeaths/MdH_municipbirth_clean.dta", clear 
d,s


** II. Verdun: Forging an Exogenous Heroic Network
** Break in time series of deaths: see lines 96 and 97 of do file: "$do/Analysis/Figure1&Stats.do"  
*** For Somme (footnote 18): lines 100 and 101 of do file: "$do/Analysis/Figure1&Stats.do"   
** Differences in bombardments and attack: Lines 370 to 375 of do file: do "$do/Analysis/FigureA3.do" 


** Shares of municipalities that sent troops to Verdun:
use "$Data_generated/analysis_dataset", clear 
tab verdun 
display 100- 7.24
tab verdun_petain 
display 100-43.14  
** % regiments at Verdun
use "$Data_generated/regimentsVerdun.dta", clear 
tab verdun
tab verdun_petain 

** III. EMPIRICAL STRATEGY
*** Average number of inhabitants in a municipality in 1911
use "$Data_generated/analysis_dataset", clear 
su pop1936  
count if pop1936!=0

*** Number of municipalities with one regiment match : see line 99 of !2_GenerateData.do in Preparation folder 

** Number of soldiers with municp birth info
use "$Data_origin/WWIDeaths/MdH_municipbirth_clean.dta", clear 
d,s

** IV. COLLABORATION DURING WWII: BACKGROUND AND DATA

 
** V. EFFECS ON COLLABORATION
*** Raw stats
use "$Data_generated/analysis_dataset.dta", clear
su collabospc if verdun_petain>0 
su collabospc if verdun_petain==0&verdun>0 

display (9.91-7.81)/7.81
 
keep if verdun>0
g vup=(verdun_petain>0 )
ttest collabospc, by (vup)

* municip not rotated at Verdun
 tab verdun
 tab verdun_petain 


** Additional collaborators and footnote 59 
  ** average number of Verdun-under-P\'{e}tain municipalities  (weighted sum including partial assignments)
 display 170*0.16667+ 435*0.33333 + 167*0.375 +432*0.4 + 2907*0.5+264*0.6667+224*0.875+15272 
 *** 17506.266 
 
  **average nber of collabos/municipalities
display 95967/34942
*column (8) table IV
display exp(0.221)
display 1.247*2.42-2.42
*** 0.598
*display final nber additional collabos
display 0.598*17506  

 ** Comparison with number of collaborators in different organizations
use  "$Data_origin/Collaboration/collabosPaillole.dta", clear 
su N_MIL N_GO 

 ** p. 26 total number of individuals in our data who joined the Gestapo, the SS, the SA or the German intelligence service
display N_SA+N_GO+N_SS+N_SRA 

 ** p. 26 total number of individuals in our data who joined the LVF 
display N_LVF 


 ** Oster test and FN 60: lines 112 to 127 of TableIV&Stats.do 
 
 ** Spatial corrections p-values: lines 124 to 426 of TableIV&Stats.do 
 
 ** Estimation sample for RD: lines 41 to 43 of TableA9.do  
 
 ** Estimation region by region: see dofile: FigureA7&Stats.do and "$Results/Tables/Table_depRobust.xls" 
 
 
** VI. MECHANISMS
*** Number of medal citations: line 69 of do file TableA13.do 

** LOYALTY   
*** Average "Pétain before Verdun", II Army, staff or field command and Footnote 75: line 24 of TableVI&Stats.do 



** FOOTNOTES 
** Footnote 17: lines 42 to 46 of do file: "$do/Analysis/FigureA2&Stats.do"   
** Footnote 18: lines 100 and 101 of do file: "$do/Analysis/Figure1&Stats.do"   
** Footnote 41: lines 63 to 77 of do file: TableIII.do
** Footnote 58: Movers
use  "$Data_origin/Collaboration/collabosPaillole.dta", clear 
egen totalmover = sum(mover)
su totalmover 
display 13235/86949


** Supplement: Correlation vote share for Francists in 1936 and collaborators in Francist movement 
use "$Data_generated/analysis_dataset.dta", clear
 gen lnshFRANCISTE_36 = log(shFRANCISTE_36+1)
 pwcorr lnshFRANCISTE_36 lnFRApc
 
** Footnote 64: Correlation with other data sources (Section C.): line 26 of do file TableA10.do 

** Footnote 72 (Num Medals instead of log): 

use "$Data_generated/analysis_dataset.dta", clear
 gen logmedals=log(sum_medals)
label var logmedals "Log. Citations"

areg  sum_medals verdun_petain verdun    $lpretrends_nomiss $precontrols_nomiss  ,  cl(id_bureau)  absorb(code_dept) 

areg   sum_medals verdun_petain  $lpretrends_nomiss $precontrols_nomiss if  verdun  >0  ,  cl(id_bureau)  absorb(code_dept) 

*** number of OSS/ LVF
/*
use"$Data_origin/Collaboration/list_collaborators_collaborationgroups_final_idgeofla_complete_V9_OSS_Douroux.dta", clear
count if id_douroux!=.
count if id_OSS!=.

use "$Data_origin/Collaboration/douroux_final_withoutduplicate.dta"
tab duplicates_douroux
dis 1397/10636
 */

** APPENDIX 
** Figure A11
use  "$Data_origin/Collaboration/collabosPaillole.dta", clear 
foreach x in MIL TOD RNP PPF AM GO SRA SD SP LT LFC SS COLE collabos {
	sum N_`x'
}

display 1550/95967   
*** 1.62% ***
** Eco collaborators who are also Political Collaborators, Nazi colaborators or Milice members 
su N_Eco_PolCol N_Eco_NaziCol N_Eco_MIL


** Section A.3 Number of observations for two rounds of 1936 elections 
*** # obs overall
use "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla_2ndRound.dta" , clear 
d,s 
** Within France's 1914 borders for the analysis 
use  "$Data_generated/1936elections_2rounds.dta",clear 
** Take one example of a political party
 su shPCF_2_36 

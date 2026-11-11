
/* 
 Do file created on 31 Jan 2020
 Last modified : 1 Nov 2022
 This do file imports and merges:
 1) assignments of communes to Bureaux de Recrutemments (BR) ;
 2) assignments of BR to Regiments ;
 3) Assignemnents of Regiments to Battle history. 
 
 It generates data for final analysis 
 
*/
clear all
set maxvar 10000

 ********************************************************************************
*******************			DEFINE GLOBAL VAR 			 ***********
********************************************************************************

quietly{
global wwcontrols "WWIdeathrate   lndistdemarcationkm vichyfrance" 

* Pretrends
global precontrols "lnpop1911"	
global pretrends  "shNuance_Gauche_14 shNuance_CentreGauche_14 shNuance_CentreDroit_14 shNuance_Droite_14" 
global lpretrends  "lshNuance_Gauche_14 lshNuance_CentreGauche_14 lshNuance_CentreDroit_14 lshNuance_Droite_14" 

global pretrends2  "shLeft_14 shRight_14 " 
global lpretrends2  "lshLeft_14 lshRight_14" 

** Define globals with no miss 
global wwcontrols_nomiss " WWIdeathrate_nomiss WWIdeathrate_miss  lndistdemarcationkm_nomiss vichyfrance_nomiss lndistdemarcationkm_miss vichyfrance_miss" 

global shelec1914_main "shSFIO_14 shREPSOC_14 shRADSOC_14 shRADIND_14 shPRDS_14 shProgressistes_14 shALP_14"
global lshelec1914_main "lshSFIO_14 lshREPSOC_14 lshRADSOC_14 lshRADIND_14 lshPRDS_14 lshProgressistes_14 lshALP_14"

global pretrends_nomiss "shNuance_Gauche_14_nomiss shNuance_Gauche_14_miss   shNuance_Droite_14_nomiss shNuance_Droite_14_miss"

global precontrols_nomiss "lnpop1911_nomiss lnpop1911_miss "	

global lpretrends_nomiss "lshNuance_Gauche_14_nomiss  lshNuance_Droite_14_nomiss lshNuance_Gauche_14_miss lshNuance_Droite_14_miss"
global lpretrends_nomiss1 "lshNuance_Gauche_14_nomiss  lshNuance_Gauche_14_miss  lshNuance_CentreGauche_14_nomiss  lshNuance_CentreGauche_14_miss  lshNuance_CentreDroit_14_nomiss lshNuance_CentreDroit_14_miss lshNuance_Droite_14_nomiss lshNuance_Droite_14_miss"
}

** Change following to "log" in order not to overwrite latest version of paper and App
	global figures "$Results/Figures/"
	global tables "$Results/Tables/"


 ********************************************************************************
 ********************************************************************************
*******************			CREATE AND MERGE DATASETS  			 ***********
********************************************************************************


quietly {
** Allocation of Communes to BR

import excel "$Data_origin/Dictionnaire/communesbureaux.xlsx",   firstrow case(lower) clear 
rename nom_reg nom_regc35

replace id_bureau=id_brd_8thversion if brd_change==1 |brd_change ==2

keep id_geofla  id_bureau nom_regc35 
save "$Data_generated/temp/id_geofla_to_BR.dta", replace 


** Allocation of BR to regiments 

import excel "$Data_raw/Dictionnaire/id_name_bureauxderecrutement_regiment.xlsx",   firstrow case(lower) clear 
keep bureau_de_recrutement_dictionnai id_bureau couverturecorps corps regimentnew-regimentnew13 
** descriptive stats on #bureaus with one regiment*
preserve
drop if id_bureau==1596 
** This bureau does not exist in Dictionaire 
d,s 
tab regimentnew2
display 158-32
restore

save "$Data_generated/temp/BR_to_RI.dta", replace 

use "$Data_generated/temp/id_geofla_to_BR.dta", clear
merge m:1 id_bureau using "$Data_generated/temp/BR_to_RI.dta"

drop if _merge!=3
drop _merge
d,s

* 
gen RI_number =  regimentnew 

tab RI_number 
* merge to battle history

merge m:1 RI_number  using  "$Data_generated/regimentsVerdun.dta", gen(mergeRegimentNew)
drop if mergeRegimentNew==2 

count if  regimentnew!=. &  regimentnew2==. 
**  27,929 unique
global placebo "placebo_mam placebo_amj placebo_mjj placebo_jja placebo_jas placebo_aso placebo_son placebo_ond"
global placebo2 " placebo_mj placebo_jj placebo_ja placebo_as placebo_so placebo_on placebo_nd"

foreach x in  RI_number marne verdun months_Verdun verdun_petain months_Verdun_Petain    Dfoch_any feb march april mai june july aug sept oct nov dec somme aisne chemindesdames  OutsideFrance    $placebo $placebo2   sum_medals{
ren `x' `x'_1
}
 
 ** merge for the other regimentnew variables 
foreach z in 2 3 4 5 6 7 8 9 10 11 12 13 {
gen RI_number =  regimentnew`z' 
* merge to battle history

merge m:1 RI_number  using "$Data_generated/regimentsVerdun.dta", gen(mergeRegimentNew`z')
drop if mergeRegimentNew`z'==2 

drop mergeRegimentNew*
 
foreach x in   RI_number marne verdun months_Verdun verdun_petain months_Verdun_Petain    Dfoch_any feb march april mai june july aug sept oct nov dec somme aisne chemindesdames  OutsideFrance    $placebo $placebo2   sum_medals{
ren `x' `x'_`z'
}
}


* compute average exposure 
foreach x in  RI_number marne verdun months_Verdun verdun_petain months_Verdun_Petain    Dfoch_any feb march april mai june july aug sept oct nov dec somme aisne chemindesdames  OutsideFrance    $placebo $placebo2   sum_medals{
egen `x'=rowmean (`x'_1 `x'_2 `x'_3 `x'_4 `x'_5 `x'_6 `x'_7 `x'_8  `x'_9 `x'_10  `x'_11  `x'_12  `x'_13)
}

 
foreach x in  marne verdun months_Verdun verdun_petain months_Verdun_Petain    Dfoch_any feb march april mai june july aug sept oct nov dec somme aisne chemindesdames  OutsideFrance    $placebo $placebo2   sum_medals { 
	forvalues i=1(1)13 {
drop `x'_`i'  
}
}
foreach x in  RI_number  { 
	forvalues i=2(1)13 {
drop `x'_`i'  
}
}
  
drop  regiment*
  

label var RI_number  "Infantry Regiment Number (avge)"
label var RI_number_1  "Infantry Regiment Number (first)"

label var marne "1st Battle of the Marne" 
label var verdun "Verdun" 
label var months_Verdun "Months at Verdun - total" 
label var verdun_petain "Verdun under Petain" 
label var months_Verdun_Petain "Months fought at Verdun under Petain" 
foreach x in feb march april mai june july aug sept oct nov dec {
label var `x' "At Verdun in `x' 1916"
}
label var somme "Battle of the Somme" 
label var chemindesdames "Chemin des Dames / Second Aisne Battle" 
label var OutsideFrance "Fought outside France or Belgium" 
label var aisne "Battle of the Aisne"
foreach x in mam amj mjj jja jas aso son ond {
label var placebo_`x' "Placebo treatment at Verdun in months: `x'"
}
label var Dfoch_any "Exposure to Foch command" 
label var  sum_medals "Sum Medals in regiments "

foreach x in mj jj ja as so on nd{
	label var placebo_`x' "Placebo treatment at Verdun in months: `x'"
}


 save "$Data_generated/temp/Communes_VerdunBattleHistory_DicComm.dta", replace 
}
 

********************************************************************************
*******************			ANALYSIS 										 ****
*******************			MERGE TO ALL OTHER DATA					 ***********
*******************			GENERATE CATEGORIES OF COLLABOS				 ***********
********************************************************************************

quietly {
** Merge analysis file with communes id containing closest RI 
use "$Data_generated/temp/Allmerged.dta" , clear 
cap drop _merge
duplicates tag id_geofla , gen (dup)
 drop dup

** Compute distance to Cauchy-a-la-Tour (coordinates of Cauchy town hall: 50.502, 2.4473)
gen centroidy_o =latitude
gen centroidx_o =longitude
gen centroidy_d =50.502
gen centroidx_d =2.4473
drop if centroidy_o==. |centroidy_d==. | centroidx_o==. |centroidx_d==. 

set more off
program define disto
version 5.0
* arguments: 
*            1= origin latitude
*            2= origin longitude
*            3= destination latitude
*            4= destination longitude
*            5= new variable (temporary name=y_)
* convert latitude and longitude from degrees to radians
local L1  "`1'*_pi/180"
local L2  "`3'*_pi/180"
local DLo  "abs(`2'-`4')*_pi/180"
*apply the great circle formula
local cosd  "(sin(`L1')*sin(`L2'))+(cos(`L1')*cos(`L2')*cos(`DLo'))"
*take the arc cos using arctan formula
*convert radians to degrees
*convert degrees to miles
gen `5' = 69.16*acos(`cosd')*180/_pi  
end

disto centroidy_o centroidx_o centroidy_d centroidx_d z

replace z=0 if z==.

** convert distance in miles in distance in km
gen distance_Cauchy=1.609*z

drop  centroidy_o centroidx_o centroidy_d centroidx_d z 
prog drop disto

gen lndistance_Cauchy = log(distance_Cauchy)


* merge to Battle history 
merge 1:1 id_geofla using "$Data_generated/temp/Communes_VerdunBattleHistory_DicComm.dta"

drop if _merge!=3
cap drop _merge

gen popdensity_1911 = pop1911/superficie 
	label var popdensity_1911 "Pop density in 1911"

su WWIdeathrate  

	
label var WWIdeathrate "WWI death rate per capita 1911"
**************************************************************************	

label var lnpop1911  "Log of population in 1911"
label var verdun_petain  "Verdun under Petain"
label var somme  "Somme"
label var vichyfrance  "Vichy France (vs. Occupied)"
label var latitude "Latitude"
label var longitude "Longitude"
label var latitudesq "Latitude sq"
label var longitudesq "Longitude sq"
label var superficie "Superficie"
label var WWIdeathrate "WW1 death rate (\% pop)"
label var lndistdemarcationkm "Distance demarcation line (log)"
label var vichyfrance "$=1$ if Vichy France"
label var lnpop1936 "1936 population (log)"
label var verdun_petain  "Verdun under Petain"

*******************************************************************************
** CATEGORIES OF COLLABORATORS 
********************************************************************************
	
 
	foreach x in mover nonmover	collabos ParaCol PolCol NaziCol  RNP MIL PPF LVF GO MSR SRA SOL FRA COLE  GRC SD SS AM  Male Female  WWI_LineVet Non_WWIVet   {
		gen `x'pc = (`x'/pop1936)*10000
		gen ln`x'pc = log(`x'+1) - log(pop1936+1)
		label var `x'pc "`x' per capita"
		label var ln`x'pc "Log `x' per capita"
		replace ln`x'pc=. if pop1936==. | pop1936==0
}
label var lncollabospc "Log Collabos per cap"
label var lnnonmoverpc "Log non mover Collabos per cap"

label var collabospc "Collabos per cap"
 
save "$Data_generated/analysis_dataset.dta", replace

 }
 


********************************************************************************
*******************			MERGE with 1914 Elections   			 ***********
********************************************************************************
use "$Data_generated/analysis_dataset.dta", clear
capture drop _merge 
destring fid code_com x_chf_lieu y_chf_lieu x_centroid y_centroid code_reg, replace 
d,s

save, replace

*** Take the 1914 election data, correct codes, collapse at modern-commune level before merging 
****** Import the correction file from INSEE
import excel "$Data_raw/Census/INSEE_Corhistoriq2016.xlsx",   firstrow case(lower) sheet(Corhistoriq2016) clear 
gen codecommune = dep+com
save "$Data_origin/Census/INSEE_Corhistoriq2016.dta" , replace 


*** Take the 1914 data and merge to correction file to correct code commune
use "$Data_origin/Elections/all_elections_1914_metropole_reshape_ccomune_idgeofla.dta", clear
duplicates tag id_geofla , gen (dup)
tab dup 
sort  nomcommune dup
drop dup

** For Lyon, Marseille, Paris 
****** 1) Correct INSEE codes and id_geofla for Paris
forvalues i=1(1)9 {
replace insee_com="7510`i'" if  codecom=="7500`i'"
}
forvalues i=10(1)20 {
replace insee_com="751`i'" if  codecom=="750`i'"
}
replace id_geofla="COMMUNE00000000000008019" if  insee_com=="75101"
replace id_geofla="COMMUNE00000000000035832" if  insee_com=="75102"
replace id_geofla="COMMUNE00000000000018618" if  insee_com=="75103"
replace id_geofla="COMMUNE00000000000012081" if  insee_com=="75104"
replace id_geofla="COMMUNE00000000000017421" if  insee_com=="75105"
replace id_geofla="COMMUNE00000000000032746" if  insee_com=="75106"
replace id_geofla="COMMUNE00000000000024072" if  insee_com=="75107"
replace id_geofla="COMMUNE00000000000013398" if  insee_com=="75108"
replace id_geofla="COMMUNE00000000000018558" if  insee_com=="75109"

replace id_geofla="COMMUNE00000000000032698" if  insee_com=="75110"
replace id_geofla="COMMUNE00000000000014405" if  insee_com=="75111"
replace id_geofla="COMMUNE00000000000026596" if  insee_com=="75112"
replace id_geofla="COMMUNE00000000000016345" if  insee_com=="75113"
replace id_geofla="COMMUNE00000000000034247" if  insee_com=="75114"
replace id_geofla="COMMUNE00000000000007121" if  insee_com=="75115"
replace id_geofla="COMMUNE00000000000001477" if  insee_com=="75116"
replace id_geofla="COMMUNE00000000000005031" if  insee_com=="75117"
replace id_geofla="COMMUNE00000000000001026" if  insee_com=="75118"
replace id_geofla="COMMUNE00000000000024639" if  insee_com=="75119"
replace id_geofla="COMMUNE00000000000025151" if  insee_com=="75120"

replace code_arr=1 if id_geofla=="COMMUNE00000000000008019"| id_geofla=="COMMUNE00000000000035832"| ///
id_geofla=="COMMUNE00000000000018618"| id_geofla=="COMMUNE00000000000012081"| id_geofla=="COMMUNE00000000000017421" |id_geofla=="COMMUNE00000000000032746"|id_geofla=="COMMUNE00000000000024072"|id_geofla=="COMMUNE00000000000013398"|id_geofla=="COMMUNE00000000000018558"|id_geofla=="COMMUNE00000000000032698"|id_geofla=="COMMUNE00000000000014405"|id_geofla=="COMMUNE00000000000026596"|id_geofla=="COMMUNE00000000000016345"|id_geofla=="COMMUNE00000000000034247"|id_geofla=="COMMUNE00000000000007121"|id_geofla=="COMMUNE00000000000001477"|id_geofla=="COMMUNE00000000000005031"|id_geofla=="COMMUNE00000000000001026"|id_geofla=="COMMUNE00000000000024639"|id_geofla=="COMMUNE00000000000025151"  

****** 2) Marseille is ok
****** 3) Lyon: create arrondissement 8 (=7) and 9 (=5 + commune de Saint-Rambert-l'Ile-Barbe) AND correct codes 
**** Lyon
**** Lyon 8eme (=7)
expand 2 if  codecommune=="69387", gen (exp)
replace insee_com="69388" if exp==1
replace id_geofla="COMMUNE00000000000018670"  if exp==1
drop exp
* then correct insee_com and id_geofla pour Lyon 1 
replace insee_com="69381" if nomcommune=="LYON" & codecommune=="69123"
replace id_geofla="COMMUNE00000000000024515" if nomcommune=="LYON" & codecommune=="69123"
replace code_arr=1 if nomcommune=="LYON" & codecommune=="69123"
**** Lyon 9eme: 
expand 2 if  codecommune=="69385", gen (exp2)
replace insee_com="69389" if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
replace code_arr=1 if id_geofla=="COMMUNE00000000000020800"
drop exp exp2  

merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta", force
 

**** Keep the ones that merge in a separate dataset 
preserve
keep if _merge==3
save "$Data_generated/temp/1914elections_part1.dta", replace 
restore 

*** Keep the ones that did not merge (old communes) and correct their insee code: 
preserve
keep  if _merge==1
d,s
drop _merge
duplicates tag codecommune, gen (dup)
tab dup 
sort nomcommune dup
drop dup
merge m:m codecommune using "$Data_origin/Census/INSEE_Corhistoriq2016.dta"  
keep if _merge==3
d,s

drop if comech=="" & depanc=="" 
duplicates tag  codecommune, gen (dup)
** drop if dates of commune change>2015 since our base dataset is from 2015
split eff, p("-" "-")
destring eff3, replace 
drop if eff3>2015 & eff3<9999999
drop eff1 eff2 eff3

tab dup 
replace  insee_com= comech if comech!=""
*** 1,523 changes made 
replace insee_com= depanc if comech=="" & depanc!="" 
** 6 changes made

sort codecommune dup
** keep most recent commune change in case there were several -- we do not actually need to do this since the old definitions will not merge so we can keep all and then throw away those who do not match
drop if codecommune=="08290" & comech=="08447"
drop if codecommune=="14262" & comech=="14629"

*** This should have fixed parts of the one that do not merge but need to find their id_geofla:
cap drop _merge
drop fid-dup

merge m:1 insee_com using "$Data_raw/Shapefiles/communeswgs84.dta"
drop if _merge!=3
d,s

** Save this dataset and later append to the part of the 1914 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1914elections_part2.dta", replace 

restore

use "$Data_generated/temp/1914elections_part1.dta", clear 
append using "$Data_generated/temp/1914elections_part2.dta"
d,s

* Generate variables : 1914 elections
global elec1914 "SFIO REPSOC RADSOC RADIND PRDS Progressistes ALP Divers"

*** To be sure not to have issues with the 0 when taking the log of the shares, we add +1 to all the votes before computing the share 
foreach x in $elec1914 {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen lsh`x'=ln(sh`x')
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	}
foreach x in Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen lsh`x'=ln(sh`x')
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	}	
 	
label var  shSFIO "Sh. SFIO 1914 (L)"
label var  shREPSOC "Sh. REP-SOC 1914 (CL)"
label var  shRADSOC "Share RAD-SOC 1914 (CL)"
label var  shRADIND "Share RAD-INC 1914 (CR)"
label var  shPRDS "Share PRDS 1914 (CR)"
label var  shProgressistes "Share Progressistes 1914 (R)"
label var  shALP "Share ALP 1914 (R)"

label var  shNuance_Gauche "Share Left, 1914"
label var  shNuance_CentreGauche "Share Center Left, 1914"
label var  shNuance_CentreDroit "Share Center Right, 1914"
label var  shNuance_Droite "Share Right, 1914"
label var  shNuance_Divers "Share Other, 1914"

foreach var of varlist Electeursinscrits-Divers DRunSFIO-shNuance_Divers_I code_arr {
	rename `var' `var'_14
	}
su  $shelec1914_main
	
drop _m 

collapse (mean) sh*_14 DRun*_14 (sum) Votants_14   Electeursinscrits_14 , by (id_geofla code_arr_14)
d,s
 
** Pour arrondissements 13 a 16 de marseille: create them and take moyenne de marseille :
expand 5 if  id_geofla=="COMMUNE00000000000011957", gen (exp2)
bysort exp2: gen ii=_n
gen marseille=0
replace marseille=1 if id_geofla=="COMMUNE00000000000011957" | id_geofla=="COMMUNE00000000000014628" | id_geofla=="COMMUNE00000000000030154" | id_geofla=="COMMUNE00000000000025519" | id_geofla=="COMMUNE00000000000021898" | id_geofla=="COMMUNE00000000000004879" | id_geofla=="COMMUNE00000000000014106" | id_geofla=="COMMUNE00000000000013379" | id_geofla=="COMMUNE00000000000001896" | id_geofla=="COMMUNE00000000000029222" | id_geofla=="COMMUNE00000000000021579" | id_geofla=="COMMUNE00000000000009040" 

foreach x in shSFIO_14 shSFIO_I_14 shREPSOC_14 shREPSOC_I_14 shRADSOC_14 shRADSOC_I_14 shRADIND_14 shRADIND_I_14 shPRDS_14 shPRDS_I_14 shProgressistes_14 shProgressistes_I_14 shALP_14 shALP_I_14 shDivers_14 shDivers_I_14 shNuance_Gauche_14 shNuance_Gauche_I_14 shNuance_CentreGauche_14 shNuance_CentreGauche_I_14 shNuance_CentreDroit_14 shNuance_CentreDroit_I_14 shNuance_Droite_14 shNuance_Droite_I_14 shNuance_Divers_14 shNuance_Divers_I_14 DRunSFIO_14 DRunREPSOC_14 DRunRADSOC_14 DRunRADIND_14 DRunPRDS_14 DRunProgressistes_14 DRunALP_14 DRunDivers_14 DRunNuance_Gauche_14 DRunNuance_CentreGauche_14 DRunNuance_CentreDroit_14 DRunNuance_Droite_14 DRunNuance_Divers_14 Votants_14 Electeursinscrits_14   {
	bysort marseille: egen mars_`x'=mean (`x') if marseille ==1
}
*13, 14, 15, 16 

*13, 14, 15, 16 
replace id_geofla="COMMUNE00000000000020002" if ii==1 & exp2==1
replace id_geofla="COMMUNE00000000000031575" if ii==2 & exp2==1 
replace id_geofla="COMMUNE00000000000013082" if ii==3 & exp2==1
replace id_geofla="COMMUNE00000000000034449" if ii==4 & exp2==1

foreach x in  COMMUNE00000000000020002 COMMUNE00000000000031575 COMMUNE00000000000013082 COMMUNE00000000000034449 {
		foreach y in shSFIO_14 shSFIO_I_14 shREPSOC_14 shREPSOC_I_14 shRADSOC_14 shRADSOC_I_14 shRADIND_14 shRADIND_I_14 shPRDS_14 shPRDS_I_14 shProgressistes_14 shProgressistes_I_14 shALP_14 shALP_I_14 shDivers_14 shDivers_I_14 shNuance_Gauche_14 shNuance_Gauche_I_14 shNuance_CentreGauche_14 shNuance_CentreGauche_I_14 shNuance_CentreDroit_14 shNuance_CentreDroit_I_14 shNuance_Droite_14 shNuance_Droite_I_14 shNuance_Divers_14 shNuance_Divers_I_14 DRunSFIO_14 DRunREPSOC_14 DRunRADSOC_14 DRunRADIND_14 DRunPRDS_14 DRunProgressistes_14 DRunALP_14 DRunDivers_14 DRunNuance_Gauche_14 DRunNuance_CentreGauche_14 DRunNuance_CentreDroit_14 DRunNuance_Droite_14 DRunNuance_Divers_14 Votants_14 Electeursinscrits_14 {
	replace `y'=mars_`y' if id_geofla=="`x'"
		}
}
drop ii marseille  mars* exp exp2
save "$Data_generated/temp/1914elections.dta", replace 

use  "$Data_generated/analysis_dataset.dta", clear 
merge 1:1 id_geofla using "$Data_generated/temp/1914elections.dta"
cap drop _merge
drop code_arr_14
save "$Data_generated/analysis_dataset.dta",  replace 



********************************************************************************
*******************			MERGE with 1919 Elections   			 ***********
********************************************************************************
*** Take the 1919 data and merge to correction file to correct code commune
global elec1919 "ExtremeGauche Communiste SFIO DiversGauche PRRS REPSOC RADIND GaucheRadicale ARD GRD RG FRURD UNR ARS ERD BlocNational AnciensCombattants DiversDroite ActionFrancaise ExtremeDroite Divers"

use  "$Data_origin/Elections/all_elections_1919_metropole_reshape_ccomune_idgeofla.dta",clear 
cap drop _merge

 sort nomcommune codecommune
 
** For Lyon, Marseille, Paris 
****** 1) Correct INSEE codes and id_geofla for Paris
forvalues i=1(1)9 {
replace insee_com="7510`i'" if  codecom=="7500`i'"
}
forvalues i=10(1)20 {
replace insee_com="751`i'" if  codecom=="750`i'"
}
replace id_geofla="COMMUNE00000000000008019" if  insee_com=="75101"
replace id_geofla="COMMUNE00000000000035832" if  insee_com=="75102"
replace id_geofla="COMMUNE00000000000018618" if  insee_com=="75103"
replace id_geofla="COMMUNE00000000000012081" if  insee_com=="75104"
replace id_geofla="COMMUNE00000000000017421" if  insee_com=="75105"
replace id_geofla="COMMUNE00000000000032746" if  insee_com=="75106"
replace id_geofla="COMMUNE00000000000024072" if  insee_com=="75107"
replace id_geofla="COMMUNE00000000000013398" if  insee_com=="75108"
replace id_geofla="COMMUNE00000000000018558" if  insee_com=="75109"

replace id_geofla="COMMUNE00000000000032698" if  insee_com=="75110"
replace id_geofla="COMMUNE00000000000014405" if  insee_com=="75111"
replace id_geofla="COMMUNE00000000000026596" if  insee_com=="75112"
replace id_geofla="COMMUNE00000000000016345" if  insee_com=="75113"
replace id_geofla="COMMUNE00000000000034247" if  insee_com=="75114"
replace id_geofla="COMMUNE00000000000007121" if  insee_com=="75115"
replace id_geofla="COMMUNE00000000000001477" if  insee_com=="75116"
replace id_geofla="COMMUNE00000000000005031" if  insee_com=="75117"
replace id_geofla="COMMUNE00000000000001026" if  insee_com=="75118"
replace id_geofla="COMMUNE00000000000024639" if  insee_com=="75119"
replace id_geofla="COMMUNE00000000000025151" if  insee_com=="75120"

replace code_arr=1 if id_geofla=="COMMUNE00000000000008019"| id_geofla=="COMMUNE00000000000035832"| ///
id_geofla=="COMMUNE00000000000018618"| id_geofla=="COMMUNE00000000000012081"| id_geofla=="COMMUNE00000000000017421" |id_geofla=="COMMUNE00000000000032746"|id_geofla=="COMMUNE00000000000024072"|id_geofla=="COMMUNE00000000000013398"|id_geofla=="COMMUNE00000000000018558"|id_geofla=="COMMUNE00000000000032698"|id_geofla=="COMMUNE00000000000014405"|id_geofla=="COMMUNE00000000000026596"|id_geofla=="COMMUNE00000000000016345"|id_geofla=="COMMUNE00000000000034247"|id_geofla=="COMMUNE00000000000007121"|id_geofla=="COMMUNE00000000000001477"|id_geofla=="COMMUNE00000000000005031"|id_geofla=="COMMUNE00000000000001026"|id_geofla=="COMMUNE00000000000024639"|id_geofla=="COMMUNE00000000000025151"  


****** 2) Lyon and Marseille: create all arrondissments with same values
 ** Lyon and Marseille have only one obs 
 replace code_arr=1 if   codecommune=="69123" 
expand 9 if  codecommune=="69123", gen (exp)
bysort exp: gen exp2=_n

replace id_geofla="COMMUNE00000000000024515" if  codecommune=="69123" & exp==0 & exp2==18038 
replace id_geofla="COMMUNE00000000000015694" if  codecommune=="69123" & exp==1 & exp2==1
replace id_geofla="COMMUNE00000000000029798" if  codecommune=="69123" & exp==1 & exp2==2
replace id_geofla="COMMUNE00000000000008962" if  codecommune=="69123" & exp==1 & exp2==3
replace id_geofla="COMMUNE00000000000024009" if  codecommune=="69123" & exp==1 & exp2==4
replace id_geofla="COMMUNE00000000000012135" if  codecommune=="69123" & exp==1 & exp2==5
replace id_geofla="COMMUNE00000000000022674" if  codecommune=="69123" & exp==1 & exp2==6
replace id_geofla="COMMUNE00000000000018670" if  codecommune=="69123" & exp==1 & exp2==7
replace id_geofla="COMMUNE00000000000020800" if  codecommune=="69123" & exp==1 & exp2==8

drop exp exp2 

** Marseille
  replace code_arr=1 if  codecommune=="13055" 
 expand 16 if  codecommune=="13055", gen (exp)
bysort exp: gen exp2=_n

replace id_geofla="COMMUNE00000000000021579" if  codecommune=="13055" & exp==0 & exp2==18854
replace id_geofla="COMMUNE00000000000009040" if  codecommune=="13055" & exp==1 & exp2==1
replace id_geofla="COMMUNE00000000000011957" if  codecommune=="13055" & exp==1 & exp2==2
replace id_geofla="COMMUNE00000000000020002" if  codecommune=="13055" & exp==1 & exp2==3
replace id_geofla="COMMUNE00000000000031575" if  codecommune=="13055" & exp==1 & exp2==4
replace id_geofla="COMMUNE00000000000013082" if  codecommune=="13055" & exp==1 & exp2==5
replace id_geofla="COMMUNE00000000000034449" if  codecommune=="13055" & exp==1 & exp2==6
replace id_geofla="COMMUNE00000000000014628" if  codecommune=="13055" & exp==1 & exp2==7
replace id_geofla="COMMUNE00000000000030154" if  codecommune=="13055" & exp==1 & exp2==8
replace id_geofla="COMMUNE00000000000025519" if  codecommune=="13055" & exp==1 & exp2==9
replace id_geofla="COMMUNE00000000000021898" if  codecommune=="13055" & exp==1 & exp2==10
replace id_geofla="COMMUNE00000000000004879" if  codecommune=="13055" & exp==1 & exp2==11
replace id_geofla="COMMUNE00000000000014106" if  codecommune=="13055" & exp==1 & exp2==12
replace id_geofla="COMMUNE00000000000013379" if  codecommune=="13055" & exp==1 & exp2==13
replace id_geofla="COMMUNE00000000000001896" if  codecommune=="13055" & exp==1 & exp2==14
replace id_geofla="COMMUNE00000000000029222" if  codecommune=="13055" & exp==1 & exp2==15
 
 drop exp exp2 

merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta", gen(merge1919)

**** Keep the ones that merge in a separate dataset 
preserve
keep if  merge1919 ==3
save "$Data_generated/temp/1919elections_part1.dta", replace 
restore 

*** Keep the ones that did not merge (old communes) and correct their insee code: 
keep  if  merge1919 ==1
d,s
drop merge1919
merge 1:m codecommune using "$Data_origin/Census/INSEE_Corhistoriq2016.dta" 
keep if _merge==3
d,s

drop if comech=="" & depanc=="" 
duplicates tag  codecommune, gen (dup)
** drop if dates of commune change>2015 since our base dataset is from 2015
split eff, p("-" "-")
destring eff3, replace 
drop if eff3>2015 & eff3<9999999
drop eff1 eff2 eff3

tab dup 
replace  insee_com= comech if comech!=""
replace insee_com= depanc if comech=="" & depanc!="" 

sort codecommune dup
cap drop _merge
drop fid-dup

merge m:1 insee_com using "$Data_raw/Shapefiles/communeswgs84.dta"
drop if _merge!=3
d,s

** Save this dataset and later append to the part of the 1919 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1919elections_part2.dta", replace 


use "$Data_generated/temp/1919elections_part1.dta", clear 
append using "$Data_generated/temp/1919elections_part2.dta"
d,s
* Generate variables : 1919 elections
foreach party in $elec1919 Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite  Nuance_ExtremeDroite Nuance_Divers {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	}		
gen sum_votes= vote_share_ExtremeGauche + vote_share_Communiste + vote_share_SFIO + vote_share_DiversGauche + vote_share_PRRS  + vote_share_REPSOC + vote_share_RADIND + vote_share_GaucheRadicale + vote_share_ARD + vote_share_GRD + vote_share_RG + vote_share_FRURD + vote_share_UNR + vote_share_ARS + vote_share_ERD + vote_share_BlocNational + vote_share_AnciensCombattants  + vote_share_DiversDroite + vote_share_ActionFrancaise + vote_share_ExtremeDroite + vote_share_Divers
	
********************
foreach x in $elec1919 {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	gen sh`x'_2=((`x'+1)/ (sum_votes+1))*100	
}
foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_ExtremeDroite Nuance_Divers {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100	
	gen sh`x'_2=((`x'+1)/ (sum_votes+1))*100	
	}	
 
* replace abnormal values by computed values when shares >100
foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_ExtremeDroite Nuance_Divers $elec1919 {
 	replace sh`x'=sh`x'_2 if sh`x'>100
 }
 
drop sum_votes	
foreach party in $elec1919 Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_ExtremeDroite Nuance_Divers {	
	drop vote_share_`party'
	drop sh`party'_2 
	}	
	
label var  shExtremeGauche "Sh. Misc. Ext. left 1919 (EL)"
label var  shCommuniste "Sh. PCC 1919 (EL)"
label var  shSFIO "Sh. SFIO 1919 (L)"
label var  shDiversGauche "Sh. Misc. left 1919 (L)"
label var  shPRRS "Sh. PRRS 1919 (CL)"
label var  shREPSOC "Sh. REP-SOC 1919 (CL)"
label var  shRADIND "Share RAD-IND 1919 (CR)"
label var  shGaucheRadicale "Share Gauche Radicale 1919 (CR)"
label var  shARD "Share shARD 1919 (CR)"
label var  shGRD "Share GRD 1919 (CR)"
label var  shRG "Share RG 1919 (CR)"

label var  shFRURD "Sh. FR-URD 1919 (R)"
label var  shUNR "Share UNR 1919 (R)"
label var  shARS "Share ARS 1919 (R)"
label var  shERD "Share ERD 1919 (R)"
label var  shBlocNational "Share Bloc National (other) 1919 (R)"
label var  shAnciensCombattants "Share Anciens Combattants 1919 (R)"
label var  shDiversDroite "Share Misc. right 1919 (R)"
label var  shActionFrancaise "Share Action Francaise 1919 (ER)"
label var  shExtremeDroite  "Share Misc. Ext. right 1919 (ER)"

label var  shDivers "Share misc 1919"

label var  shNuance_ExtremeGauche "Share Extreme Left, 1919"
label var  shNuance_Gauche "Share Left, 1919"
label var  shNuance_CentreGauche "Share Center Left, 1919"
label var  shNuance_CentreDroit "Share Center Right, 1919"
label var  shNuance_Droite "Share Right, 1919"
label var  shNuance_ExtremeDroite "Share Extreme Right, 1919"
label var  shNuance_Divers "Share Misc., 1919"

foreach var of varlist Bureau-Divers DRunExtremeGauche-shNuance_Divers_I {
	rename `var' `var'_19
	}
su  $shelec1919_main

 collapse (mean) sh*_19 DRun*_19 (sum) Votants_19 Electeursinscrits_19, by (id_geofla code_arr)
d,s

ren code_arr code_arr_19
drop code_arr_19

save "$Data_generated/temp/1919elections.dta", replace 
d,s
 
use "$Data_generated/analysis_dataset.dta", clear
cap drop _merge 
merge 1:1 id_geofla using "$Data_generated/temp/1919elections.dta" 

drop if _merge==2
drop _merge 
save "$Data_generated/analysis_dataset.dta",  replace 

********************************************************************************
*******************			MERGE with 1924 Elections   			 ***********
********************************************************************************
*** Take the 1924 data and merge to correction file to correct code commune
global elec1924 "BOP SFIO DVG RADSOC REPSOC REPRAD RG ERD Conservateur Divers"

use  "$Data_origin/Elections/all_elections_1924_metropole_reshape_ccomune_idgeofla.dta",clear 
cap drop _merge
 
**** Lyon 8eme: 
expand 2 if  codecommune=="69387", gen (exp)
replace insee_com="69388" if exp==1
replace id_geofla="COMMUNE00000000000018670"  if exp==1
 
**** Lyon 9eme: 
expand 2 if  codecommune=="69385", gen (exp2)
replace insee_com="69389" if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
replace code_arr=1 if id_geofla=="COMMUNE00000000000020800"
drop exp exp2 


merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta", gen(merge1924)

**** Keep the ones that merge in a separate dataset 
preserve
keep if merge1924==3
save "$Data_generated/temp/1924elections_part1.dta", replace 
restore 

*** Keep the ones that did not merge (old communes) and correct their insee code: 
keep  if merge1924==1
d,s
drop merge1924
merge 1:m codecommune using "$Data_origin/Census/INSEE_Corhistoriq2016.dta" 
keep if _merge==3
d,s

drop if comech=="" & depanc=="" 
duplicates tag  codecommune, gen (dup)
** drop if dates of commune change>2015 since our base dataset is from 2015
split eff, p("-" "-")
destring eff3, replace 
drop if eff3>2015 & eff3<9999999
drop eff1 eff2 eff3

tab dup 
replace  insee_com= comech if comech!=""
replace insee_com= depanc if comech=="" & depanc!="" 

sort codecommune dup
*** This should have fixed parts of the one that do not merge but need to find their id_geofla:
cap drop _merge
drop fid-dup

merge m:1 insee_com using "$Data_raw/Shapefiles/communeswgs84.dta"
drop if _merge!=3
d,s

** Save this dataset and later append to the part of the 1914 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1924elections_part2.dta", replace 


use "$Data_generated/temp/1924elections_part1.dta", clear 
append using "$Data_generated/temp/1924elections_part2.dta"
d,s


* Generate variables : 1924 elections
foreach party in $elec1924 Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	}		
gen sum_votes= vote_share_BOP + vote_share_SFIO + vote_share_DVG + vote_share_RADSOC + vote_share_REPSOC + vote_share_REPRAD + vote_share_RG + vote_share_ERD+ vote_share_Conservateur + vote_share_Divers
	

********************
foreach x in $elec1924 {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	gen sh`x'_2=((`x'+1)/ (sum_votes+1))*100	
}
foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100	
	gen sh`x'_2=((`x'+1)/ (sum_votes+1))*100	
	}	
 
 * replace abnormal values by computed values when shares >100
 foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers $elec1924 {
 	replace sh`x'=sh`x'_2 if sh`x'>100
 }
 
drop sum_votes	
foreach party in $elec1924 Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers {	
	drop vote_share_`party'
	drop sh`party'_2 
	}
 
label var  shBOP "Sh. BOP 1924 (EL)"
label var  shSFIO "Sh. SFIO 1924 (L)"
label var  shDVG "Sh. Misc. left 1924 (L)"
label var  shRADSOC "Share RAD-SOC 1924 (CL)"
label var  shREPSOC "Sh. REP-SOC 1924 (CL)"
label var  shREPRAD "Sh. REP-RAD 1924 (CR)"
label var  shRG "Share RG 1924 (CR)"
label var  shERD "Share ERD 1924 (R)"
label var  shConservateur "Share Conservateur 1924 (R)"
label var  shDivers "Share misc 1924"

label var  shNuance_ExtremeGauche "Share Extreme Left, 1924"
label var  shNuance_Gauche "Share Left, 1924"
label var  shNuance_CentreGauche "Share Center Left, 1924"
label var  shNuance_CentreDroit "Share Center Right, 1924"
label var  shNuance_Droite "Share Right, 1924"
label var  shNuance_Divers "Share Other, 1924"

foreach var of varlist   Electeursinscrits-total_liste DRunBOP-shNuance_Divers_I {
	rename `var' `var'_24
	}
su  $shelec1924_main

collapse (mean) sh*_24 DRun*_24 (sum) Votants_24 Electeursinscrits_24, by (id_geofla code_arr)
d,s
ren code_arr code_arr_24
drop code_arr_24
save "$Data_generated/temp/1924elections.dta", replace 
d,s

use "$Data_generated/analysis_dataset.dta", clear
cap drop _merge 
merge 1:1 id_geofla using "$Data_generated/temp/1924elections.dta"
drop if _merge==2
drop _merge 

save "$Data_generated/analysis_dataset.dta",  replace 

*******************************************************************************
*******************			MERGE with 1936 Elections   			 ***********
********************************************************************************
*** Take the 1936 data and merge to correction file to correct code commune
global elec1936 "PCF SFIO DVG USR RADSOC DIV AD FRURD PRN AGR DVD FRANCISTE"

use  "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla.dta",clear 

** Paris 
****** 1) Correct INSEE codes and id_geofla for Paris
forvalues i=1(1)9 {
replace insee_com="7510`i'" if  codecom=="7500`i'"
}
forvalues i=10(1)20 {
replace insee_com="751`i'" if  codecom=="750`i'"
}
replace id_geofla="COMMUNE00000000000008019" if  insee_com=="75101"
replace id_geofla="COMMUNE00000000000035832" if  insee_com=="75102"
replace id_geofla="COMMUNE00000000000018618" if  insee_com=="75103"
replace id_geofla="COMMUNE00000000000012081" if  insee_com=="75104"
replace id_geofla="COMMUNE00000000000017421" if  insee_com=="75105"
replace id_geofla="COMMUNE00000000000032746" if  insee_com=="75106"
replace id_geofla="COMMUNE00000000000024072" if  insee_com=="75107"
replace id_geofla="COMMUNE00000000000013398" if  insee_com=="75108"
replace id_geofla="COMMUNE00000000000018558" if  insee_com=="75109"

replace id_geofla="COMMUNE00000000000032698" if  insee_com=="75110"
replace id_geofla="COMMUNE00000000000014405" if  insee_com=="75111"
replace id_geofla="COMMUNE00000000000026596" if  insee_com=="75112"
replace id_geofla="COMMUNE00000000000016345" if  insee_com=="75113"
replace id_geofla="COMMUNE00000000000034247" if  insee_com=="75114"
replace id_geofla="COMMUNE00000000000007121" if  insee_com=="75115"
replace id_geofla="COMMUNE00000000000001477" if  insee_com=="75116"
replace id_geofla="COMMUNE00000000000005031" if  insee_com=="75117"
replace id_geofla="COMMUNE00000000000001026" if  insee_com=="75118"
replace id_geofla="COMMUNE00000000000024639" if  insee_com=="75119"
replace id_geofla="COMMUNE00000000000025151" if  insee_com=="75120"

replace code_arr=1 if id_geofla=="COMMUNE00000000000008019"| id_geofla=="COMMUNE00000000000035832"| ///
id_geofla=="COMMUNE00000000000018618"| id_geofla=="COMMUNE00000000000012081"| id_geofla=="COMMUNE00000000000017421" |id_geofla=="COMMUNE00000000000032746"|id_geofla=="COMMUNE00000000000024072"|id_geofla=="COMMUNE00000000000013398"|id_geofla=="COMMUNE00000000000018558"|id_geofla=="COMMUNE00000000000032698"|id_geofla=="COMMUNE00000000000014405"|id_geofla=="COMMUNE00000000000026596"|id_geofla=="COMMUNE00000000000016345"|id_geofla=="COMMUNE00000000000034247"|id_geofla=="COMMUNE00000000000007121"|id_geofla=="COMMUNE00000000000001477"|id_geofla=="COMMUNE00000000000005031"|id_geofla=="COMMUNE00000000000001026"|id_geofla=="COMMUNE00000000000024639"|id_geofla=="COMMUNE00000000000025151"  



** For Lyon: we only have data from the Archives for the 7e arrondissement (which later also becomes the 8th) so we create 7, and 8
  ** only one observation 
  ** create the 9 arrondissements and correct 9 = saint rambert l'ile barbe 
replace code_arr=1 if  nomcommune=="LYON"
  expand 9 if nomcommune=="LYON" , gen (exp)
  bysort exp: gen exp2=_n
* then impute  id_geofla
replace id_geofla="COMMUNE00000000000024515" if  nomcommune=="LYON" & exp==0 & exp2==28852 
replace id_geofla="COMMUNE00000000000015694" if  nomcommune=="LYON" & exp==1 & exp2==1
replace id_geofla="COMMUNE00000000000029798" if  nomcommune=="LYON" & exp==1 & exp2==2
replace id_geofla="COMMUNE00000000000008962" if  nomcommune=="LYON" & exp==1 & exp2==3
replace id_geofla="COMMUNE00000000000024009" if  nomcommune=="LYON" & exp==1 & exp2==4
replace id_geofla="COMMUNE00000000000012135" if  nomcommune=="LYON" & exp==1 & exp2==5
replace id_geofla="COMMUNE00000000000022674" if  nomcommune=="LYON" & exp==1 & exp2==6
replace id_geofla="COMMUNE00000000000018670" if  nomcommune=="LYON" & exp==1 & exp2==7
replace id_geofla="COMMUNE00000000000020800" if  nomcommune=="LYON" & exp==1 & exp2==8

** correct id_geofla and insee_com
*correct saint Rambert l'Ile Barbe
replace code_arr=1 if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE" 
replace insee_com="69389"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
replace id_geofla="COMMUNE00000000000020800"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
drop exp exp2

** Marseille -- fix 5e
replace code_arr=3 if codecommune=="13055"
replace id_geofla ="COMMUNE00000000000004879"  if codecommune=="13055"


cap drop _merge
merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta"  
 
**** Keep the ones that merge in a separate dataset 
preserve
keep if _merge==3
save "$Data_generated/temp/1936elections_part1.dta", replace 
restore 

*** Keep the ones that did not merge (old communes) and correct their insee code: 
preserve
keep  if _merge==1
d,s
drop _merge
merge 1:m codecommune using "$Data_origin/Census/INSEE_Corhistoriq2016.dta" 
keep if _merge==3
d,s

drop if comech=="" & depanc=="" 
duplicates tag  codecommune, gen (dup)
** drop if dates of commune change>2015 since our base dataset is from 2015
split eff, p("-" "-")
destring eff3, replace 
drop if eff3>2015 & eff3<9999999
drop eff1 eff2 eff3

tab dup 
replace  insee_com= comech if comech!=""
*** 1,804 changes made 
replace insee_com= depanc if comech=="" & depanc!="" 
** 0 changes made

sort codecommune dup

*** This should have fixed parts of the one that do not merge but need to find their id_geofla:
cap drop _merge
drop fid-dup

merge m:1 insee_com using "$Data_raw/Shapefiles/communeswgs84.dta"
drop if _merge!=3
d,s

** Save this dataset and later append to the part of the 1914 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1936elections_part2.dta", replace 

restore

use "$Data_generated/temp/1936elections_part1.dta", clear 
append using "$Data_generated/temp/1936elections_part2.dta"
d,s

* Generate variables : 1936 elections
	
rename RAD_SOC RADSOC	
rename FR_URD FRURD
	
** 1936 elections
global elec1936 "PCF SFIO DVG USR RADSOC DIV AD FRURD PRN AGR DVD FRANCISTE"

*** To be sure not to have issues with the 0 when taking the log of the shares, we add +1 to all the votes before computing the share 
foreach x in $elec1936 {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	}
foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_ExtremeDroite Nuance_Divers {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	}	
	
label var  shPCF 	"Sh. PCF 1936 (EL)"
label var  shSFIO 	"Sh. SFIO 1936 (L)"
label var  shDVG 	"Sh. misc. left 1936 (L)"
label var  shUSR 	"Sh. USR 1936 (CL)"
label var  shRADSOC "Share RAD-SOC 1936 (CL)"

label var  shDIV 	"Sh. misc. 1936"

label var  shAD 	"Sh. AD 1936 (CR)"
label var  shFRURD "Share FRURD 1936 (CR)"
label var  shPRN	"Share PRN 1936 (R)" 
label var  shAGR 	"Share AGR 1936 (R)"
label var  shDVD 	"Sh. misc. right 1936 (R)"

label var  shFRANCISTE 	"Sh. extreme right 1936 (ER)"

label var  shNuance_ExtremeGauche "Share Extreme Left, 1936"
label var  shNuance_Gauche "Share Left, 1936"
label var  shNuance_CentreGauche "Share Center Left, 1936"
label var  shNuance_CentreDroit "Share Center Right, 1936"
label var  shNuance_Droite "Share Right, 1936"
label var  shNuance_Divers "Share Other, 1936"
label var  shNuance_ExtremeDroite "Share Extreme Right, 1936"

foreach var of varlist Electeursinscrits-FRANCISTE DRunPCF-shNuance_Divers_I {
	rename `var' `var'_36
	}
	
gen elec1936_miss=(_merge==1)
drop _m 

collapse (mean) sh*_36 DRun*_36 (sum) Votants_36  Electeursinscrits_36, by (id_geofla code_arr )
ren code_arr code_arr_36 
drop code_arr_36 
 ** Like in 1914: Pour arrondissements 13 a 16 de marseille: create them and take moyenne de marseille :
expand 5 if  id_geofla=="COMMUNE00000000000011957", gen (exp2)
bysort exp2: gen ii=_n
gen marseille=0
replace marseille=1 if id_geofla=="COMMUNE00000000000011957" | id_geofla=="COMMUNE00000000000014628" | id_geofla=="COMMUNE00000000000030154" | id_geofla=="COMMUNE00000000000025519" | id_geofla=="COMMUNE00000000000021898" | id_geofla=="COMMUNE00000000000004879" | id_geofla=="COMMUNE00000000000014106" | id_geofla=="COMMUNE00000000000013379" | id_geofla=="COMMUNE00000000000001896" | id_geofla=="COMMUNE00000000000029222" | id_geofla=="COMMUNE00000000000021579" | id_geofla=="COMMUNE00000000000009040" 

foreach var of varlist shPCF_36-Electeursinscrits_36 {
	bysort marseille: egen mars_`var'=mean (`var') if marseille ==1
}

*13, 14, 15, 16 
replace id_geofla="COMMUNE00000000000020002" if ii==1 & exp2==1
replace id_geofla="COMMUNE00000000000031575" if ii==2 & exp2==1 
replace id_geofla="COMMUNE00000000000013082" if ii==3 & exp2==1
replace id_geofla="COMMUNE00000000000034449" if ii==4 & exp2==1

foreach x in  COMMUNE00000000000020002 COMMUNE00000000000031575 COMMUNE00000000000013082 COMMUNE00000000000034449 {
foreach var of varlist shPCF_36-Electeursinscrits_36 {
	replace `var'=mars_`var' if id_geofla=="`x'"
		}
}
drop ii marseille  mars*


save "$Data_generated/temp/1936elections.dta", replace 

use "$Data_generated/analysis_dataset.dta", clear
cap drop _merge 
merge 1:1 id_geofla using "$Data_generated/temp/1936elections.dta"
drop if _merge==2
drop _merge

save "$Data_generated/analysis_dataset.dta",  replace 

  

********************************************************************************
*******************			MERGE with 1932 Elections   			 ***********
********************************************************************************

*** Take the 1932 data and merge to correction file to correct code commune
use  "$Data_origin/Elections/all_elections_1932_metropole_reshape_ccomune_idgeofla.dta",clear 


****** 1) Correct INSEE codes and id_geofla for Paris

forvalues i=1(1)9 {
replace insee_com="7510`i'" if  codecom=="7500`i'"
}
forvalues i=10(1)20 {
replace insee_com="751`i'" if  codecom=="750`i'"
}
replace id_geofla="COMMUNE00000000000008019" if  insee_com=="75101"
replace id_geofla="COMMUNE00000000000035832" if  insee_com=="75102"
replace id_geofla="COMMUNE00000000000018618" if  insee_com=="75103"
replace id_geofla="COMMUNE00000000000012081" if  insee_com=="75104"
replace id_geofla="COMMUNE00000000000017421" if  insee_com=="75105"
replace id_geofla="COMMUNE00000000000032746" if  insee_com=="75106"
replace id_geofla="COMMUNE00000000000024072" if  insee_com=="75107"
replace id_geofla="COMMUNE00000000000013398" if  insee_com=="75108"
replace id_geofla="COMMUNE00000000000018558" if  insee_com=="75109"

replace id_geofla="COMMUNE00000000000032698" if  insee_com=="75110"
replace id_geofla="COMMUNE00000000000014405" if  insee_com=="75111"
replace id_geofla="COMMUNE00000000000026596" if  insee_com=="75112"
replace id_geofla="COMMUNE00000000000016345" if  insee_com=="75113"
replace id_geofla="COMMUNE00000000000034247" if  insee_com=="75114"
replace id_geofla="COMMUNE00000000000007121" if  insee_com=="75115"
replace id_geofla="COMMUNE00000000000001477" if  insee_com=="75116"
replace id_geofla="COMMUNE00000000000005031" if  insee_com=="75117"
replace id_geofla="COMMUNE00000000000001026" if  insee_com=="75118"
replace id_geofla="COMMUNE00000000000024639" if  insee_com=="75119"
replace id_geofla="COMMUNE00000000000025151" if  insee_com=="75120"


replace code_arr=1 if id_geofla=="COMMUNE00000000000008019"| id_geofla=="COMMUNE00000000000035832"| ///
id_geofla=="COMMUNE00000000000018618"| id_geofla=="COMMUNE00000000000012081"| id_geofla=="COMMUNE00000000000017421" |id_geofla=="COMMUNE00000000000032746"|id_geofla=="COMMUNE00000000000024072"|id_geofla=="COMMUNE00000000000013398"|id_geofla=="COMMUNE00000000000018558"|id_geofla=="COMMUNE00000000000032698"|id_geofla=="COMMUNE00000000000014405"|id_geofla=="COMMUNE00000000000026596"|id_geofla=="COMMUNE00000000000016345"|id_geofla=="COMMUNE00000000000034247"|id_geofla=="COMMUNE00000000000007121"|id_geofla=="COMMUNE00000000000001477"|id_geofla=="COMMUNE00000000000005031"|id_geofla=="COMMUNE00000000000001026"|id_geofla=="COMMUNE00000000000024639"|id_geofla=="COMMUNE00000000000025151"  

****** 3) Lyon: create arrondissement 8 (=7) and 9 (=5 + commune de Saint-Rambert-l'Ile-Barbe) AND correct codes 
**** Lyon
  
**** Lyon 8eme: 
expand 2 if  codecommune=="69387", gen (exp)
replace insee_com="69388" if exp==1
replace id_geofla="COMMUNE00000000000018670"  if exp==1

* then correct insee_com and id_geofla pour Lyon 1 
replace insee_com="69381" if nomcommune=="LYON" & codecommune=="69123"
replace id_geofla="COMMUNE00000000000024515" if nomcommune=="LYON" & codecommune=="69123"
replace code_arr=1 if id_geofla=="COMMUNE00000000000024515"
**** Lyon 9eme: 
expand 2 if  codecommune=="69385", gen (exp2)
replace insee_com="69389" if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if exp2==1
replace id_geofla="COMMUNE00000000000020800"  if nomcommune1932=="SAINT-RAMBERT-L'ILE-BARBE"
replace code_arr =1 if id_geofla=="COMMUNE00000000000020800"   

drop exp exp2 

**  MArseille not there at all 
  cap drop _merge
  
  
merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta"  

**** Keep the ones that merge in a separate dataset 
preserve
keep if _merge==3
save "$Data_generated/temp/1932elections_part1.dta", replace 
restore 

*** Keep the ones that did not merge (old communes) and correct their insee code: 
keep  if _merge==1
d,s
drop _merge
merge 1:m codecommune using "$Data_origin/Census/INSEE_Corhistoriq2016.dta" 
keep if _merge==3
d,s

drop if comech=="" & depanc=="" 
duplicates tag  codecommune, gen (dup)
** drop if dates of commune change>2015 since our base dataset is from 2015
split eff, p("-" "-")
destring eff3, replace 
drop if eff3>2015 & eff3<9999999
drop eff1 eff2 eff3

tab dup 
replace  insee_com= comech if comech!=""
*** 1,356changes made 
replace insee_com= depanc if comech=="" & depanc!="" 
** 6 changes made

sort codecommune dup

** For Lyon: expand for 9 arrondissements
expand 9 if nomcommune=="LYON" 
bysort nomcommune: gen ii=_n
* then correct insee_com
forvalues i=1(1)9 {
replace insee_com="6938`i'" if nomcommune=="LYON" &ii==`i'
}
drop ii 
*** This should have fixed parts of the one that do not merge but need to find their id_geofla:
cap drop _merge
drop fid-dup

merge m:1 insee_com using "$Data_raw/Shapefiles/communeswgs84.dta"
drop if _merge!=3
d,s

** Save this dataset and later append to the part of the 1914 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1932elections_part2.dta", replace 


use "$Data_generated/temp/1932elections_part1.dta", clear 
append using "$Data_generated/temp/1932elections_part2.dta"
d,s

* Generate variables : 1932 elections
	
rename REP_SOC REPSOC	
rename RAD_SOC RADSOC
rename AD_RG ADRG
rename AD_IND ADIND
rename AD_PDP ADPDP
rename FR_URD FRURD
global elec1932 "PCF SFIO DVG REPSOC RADSOC DIV ADRG ADIND ADPDP FRURD AGR DVD"

*** To be sure not to have issues with the 0 when taking the log of the shares, we add +1 to all the votes before computing the share 
foreach x in $elec1932 {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100
	}
foreach x in Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_Droite Nuance_CentreDroit Nuance_Divers {
	gen DRun`x'=(`x'>0 & `x'!=.)
	gen sh`x'=((`x'+1)/	(Suffragesexprimes+1))*100
	gen sh`x'_I=((`x'+1)/ (Electeursinscrits+1))*100	
	}	
	
label var  shPCF 	"Sh. PCF 1932 (EL)"
label var  shSFIO 	"Sh. SFIO 1932 (L)"
label var  shDVG 	"Sh. misc. left 1932 (L)"
label var  shREPSOC  "Sh. REP-SOC 1932 (CL)"
label var  shRADSOC "Share RAD-SOC 1932 (CL)"

label var  shDIV 	"Sh. misc. 1932"

label var  shADRG 	"Sh. AD-RG 1932 (CR)"
label var  shADIND 	"Sh. AD-IND 1932 (CR)"
label var  shADPDP "Share AD-PDP 1932 (R)"
label var  shFRURD "Share FR-URD 1932 (R)"
label var  shAGR 	"Share AGR 1932 (R)"
label var  shDVD 	"Sh. misc. right 1932 (R)"

label var  shNuance_Gauche "Share Extreme Left, 1932"
label var  shNuance_Gauche "Share Left, 1932"
label var  shNuance_CentreGauche "Share Center Left, 1932"
label var  shNuance_CentreDroit "Share Center Right, 1932"
label var  shNuance_Droite "Share Right, 1932"
label var  shNuance_Divers "Share Other, 1932"

foreach var of varlist Electeursinscrits-DVD DRunPCF-shNuance_Divers_I {
	rename `var' `var'_32
	}
	
drop _m 

collapse (mean) sh*_32 DRun*_32 (sum) Votants_32  Electeursinscrits_32, by (id_geofla code_arr)
ren code_arr code_arr_32
drop code_arr_32
d,s
save "$Data_generated/temp/1932elections.dta", replace 
d,s
 
use "$Data_generated/analysis_dataset.dta", clear
cap drop _merge 
merge 1:1 id_geofla using "$Data_generated/temp/1932elections.dta"
drop if _merge==2
drop _merge

drop exp2 
save "$Data_generated/analysis_dataset.dta",  replace 
 

 	
********************************************************************************
********************************************************************************
*******************			Generate Pol vars			 ***********
********************************************************************************
********************************************************************************

foreach y in 14 19 24 32 36 {
	gen turnout_`y'=(Votants_`y' / Electeursinscrits_`y')*100
	replace turnout_`y'=. if (Electeursinscrits_`y'==.|Votants_`y'==.)
	}
su turnout_14 turnout_19 turnout_24 turnout_32 turnout_36, d	

foreach x in 14 19 24 32 36 {
	replace  turnout_`x'=100 if turnout_`x'>100 & turnout_`x'!=.
	gen lturnout_`x'=log(turnout_`x')
}
su lturnout_*

gen shNuance_ExtremeGauche_14=0
gen shNuance_ExtremeDroite_14=0
gen shNuance_ExtremeDroite_24=0
gen shNuance_ExtremeDroite_32=0

foreach y in 14 19 24 32 36 {
	gen shLeft_`y'=shNuance_ExtremeGauche_`y' + shNuance_Gauche_`y' + shNuance_CentreGauche_`y'
	gen shRight_`y'=shNuance_ExtremeDroite_`y' + shNuance_CentreDroit_`y' + shNuance_Droite_`y'
		replace shLeft_`y'=100 if shLeft_`y'>100 & shLeft_`y'<9999
		replace shRight_`y'=100 if shRight_`y'>100 & shRight_`y'<9999
}
su shLeft* shRight*	

	foreach y in 14 19 24 32  36 {
		gen lshLeft_`y'=log(shLeft_`y'+1)
		gen lshRight_`y'=log(shRight_`y'+1)
}	
	
********************************************************************************
*******************			Generate nomiss historical vars 			 ***********
********************************************************************************
su $pretrends 
foreach x in $pretrends $shelec1914_main {
	gen l`x'=log(`x'+1)
}

foreach x in $wwcontrols $precontrols $pretrends $lpretrends  $pretrends2 $lpretrends2  $shelec1914_main $lshelec1914_main   {
	gen `x'_miss=(`x'==.)
	gen `x'_nomiss = `x'
	replace `x'_nomiss=0 if `x'==.
	}

** Divide shares in 1914 to display coeff
foreach x in $pretrends_nomiss  $pretrends2_nomiss  {
	replace `x'=`x'/100
	}

d,s
** replace deathrate by 0 if missing (interpretation: if not in Mdh = no death)
cap drop WWIdeathrate_miss
gen WWIdeathrate_miss=(WWIdeathrate ==. &  lncollabospc!=. & verdun!=.)
tab WWIdeathrate_miss
replace WWIdeathrate =0 if WWIdeathrate ==. &  lncollabospc!=.& verdun!=.
****** Use log of ww1 death rate 
		gen logww1 =log(WWIdeathrate +1 ) if lncollabospc!=.
		label var logww1 "Log. WWI fatal. rate"
 
 ** standardise var 
egen mlogww1=mean(logww1)
egen sdlogww1=sd(logww1)
gen s_logww1=(logww1-mlogww1)/sdlogww1
** 
drop mlogww1 sdlogww1

label var s_logww1 "Log. WWI fatal. rate - standardized" 

 foreach x in WWIdeathrate {
cap drop `x'sq
cap drop ihs`x'
gen `x'sq=`x'*`x'
gen ihs`x'= log(`x'+sqrt(`x'sq+1))
}

**** IHS COLLABOS 

foreach x in collabos {
cap drop `x'sq
cap drop ihs`x'
gen `x'sq=`x'*`x'
gen ihs`x'= log(`x'+sqrt(`x'sq+1))
}


save "$Data_generated/analysis_dataset.dta", replace

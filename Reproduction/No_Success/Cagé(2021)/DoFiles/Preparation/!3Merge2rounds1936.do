
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
********* 			merge two rounds of elections 1936 	   ************************************
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************


global elec1936 "PCF SFIO DVG USR RAD_SOC DIV AD FR_URD PRN AGR DVD FRANCISTE" 

************	Round 1 ***********************************************************************

use  "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla.dta",clear 
 
foreach x in $elec1936   Electeursinscrits Votants Suffragesexprimes BulletinsNonComptes Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers Nuance_ExtremeDroite   {
	ren `x' `x'_1
}
save  "$Data_generated/temp/all_elections_1936_metropole_reshape_ccomune_idgeofla_formerge.dta", replace 


use "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla_2ndRound.dta" , clear 
d,s

foreach x in $elec1936  Electeursinscrits Votants Suffragesexprimes BulletinsNonComptes Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers Nuance_ExtremeDroite code_arr {
	ren `x' `x'_2
}
save  "$Data_generated/temp/all_elections_1936_metropole_reshape_ccomune_idgeofla_2ndRound_formerge.dta" ,replace 



************	Round 2 ***********************************************************************




use  "$Data_generated/temp/all_elections_1936_metropole_reshape_ccomune_idgeofla_formerge.dta", clear 
merge 1:1 codecommune using "$Data_generated/temp/all_elections_1936_metropole_reshape_ccomune_idgeofla_2ndRound_formerge.dta" , gen (merge2rounds_1936)

keep if merge2rounds_1936==3 

foreach x in  $elec1936 Nuance_ExtremeGauche Nuance_Gauche Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite Nuance_Divers Nuance_ExtremeDroite {
	su `x'_1 `x'_2 if merge2rounds_1936==3
}

*********************************************************************************************
***** Correct id_geofla codes for Paris, Lyon, Marseille **************************
***********************************************************************************************
** Paris
replace id_geofla="COMMUNE00000000000008019" if nomcommune=="PARIS" & codecommune=="75001" 
replace id_geofla="COMMUNE00000000000035832" if nomcommune=="PARIS" & codecommune=="75002" 
replace id_geofla="COMMUNE00000000000018618" if nomcommune=="PARIS" & codecommune=="75003" 
replace id_geofla="COMMUNE00000000000012081" if nomcommune=="PARIS" & codecommune=="75004" 
replace id_geofla="COMMUNE00000000000017421" if nomcommune=="PARIS" & codecommune=="75005" 
replace id_geofla="COMMUNE00000000000032746" if nomcommune=="PARIS" & codecommune=="75006" 
replace id_geofla="COMMUNE00000000000024072" if nomcommune=="PARIS" & codecommune=="75007" 
replace id_geofla="COMMUNE00000000000013398" if nomcommune=="PARIS" & codecommune=="75008" 
replace id_geofla="COMMUNE00000000000018558" if nomcommune=="PARIS" & codecommune=="75009" 
replace id_geofla="COMMUNE00000000000032698" if nomcommune=="PARIS" & codecommune=="75010" 
replace id_geofla="COMMUNE00000000000014405" if nomcommune=="PARIS" & codecommune=="75011" 
replace id_geofla="COMMUNE00000000000026596" if nomcommune=="PARIS" & codecommune=="75012" 
replace id_geofla="COMMUNE00000000000016345" if nomcommune=="PARIS" & codecommune=="75013" 
replace id_geofla="COMMUNE00000000000034247" if nomcommune=="PARIS" & codecommune=="75014" 
replace id_geofla="COMMUNE00000000000007121" if nomcommune=="PARIS" & codecommune=="75015" 
replace id_geofla="COMMUNE00000000000001477" if nomcommune=="PARIS" & codecommune=="75016" 
replace id_geofla="COMMUNE00000000000005031" if nomcommune=="PARIS" & codecommune=="75017" 
replace id_geofla="COMMUNE00000000000001026" if nomcommune=="PARIS" & codecommune=="75018" 
replace id_geofla="COMMUNE00000000000024639" if nomcommune=="PARIS" & codecommune=="75019" 
replace id_geofla="COMMUNE00000000000025151" if nomcommune=="PARIS" & codecommune=="75020" 

replace code_arr=1 if id_geofla=="COMMUNE00000000000008019"| id_geofla=="COMMUNE00000000000035832"| ///
id_geofla=="COMMUNE00000000000018618"| id_geofla=="COMMUNE00000000000012081"| id_geofla=="COMMUNE00000000000017421" |id_geofla=="COMMUNE00000000000032746"|id_geofla=="COMMUNE00000000000024072"|id_geofla=="COMMUNE00000000000013398"|id_geofla=="COMMUNE00000000000018558"|id_geofla=="COMMUNE00000000000032698"|id_geofla=="COMMUNE00000000000014405"|id_geofla=="COMMUNE00000000000026596"|id_geofla=="COMMUNE00000000000016345"|id_geofla=="COMMUNE00000000000034247"|id_geofla=="COMMUNE00000000000007121"|id_geofla=="COMMUNE00000000000001477"|id_geofla=="COMMUNE00000000000005031"|id_geofla=="COMMUNE00000000000001026"|id_geofla=="COMMUNE00000000000024639"|id_geofla=="COMMUNE00000000000025151"  

expand 9 if nomcommune=="LYON" , gen (exp)
bysort exp: gen i=_n 
replace id_geofla="COMMUNE00000000000024515" if nomcommune=="LYON" & exp==0
replace insee_com="69381" if nomcommune=="LYON"  & exp==0 

replace id_geofla="COMMUNE00000000000015694" if nomcommune=="LYON" & exp==1 & i==1 
replace insee_com="69382" if nomcommune=="LYON"  & exp==1  & i==1 
 
replace id_geofla="COMMUNE00000000000029798" if nomcommune=="LYON" & exp==1 & i==2
replace insee_com="69383" if nomcommune=="LYON"  & exp==1  & i==2 

replace id_geofla="COMMUNE00000000000008962" if nomcommune=="LYON" & exp==1 & i==3
replace insee_com="69384" if nomcommune=="LYON"  & exp==1 & i==3
 
replace id_geofla="COMMUNE00000000000024009" if nomcommune=="LYON" & exp==1 & i==4
replace insee_com="69385" if nomcommune=="LYON"  & exp==1 & i==4
 
 replace id_geofla="COMMUNE00000000000012135" if nomcommune=="LYON" & exp==1& i==5
replace insee_com="69386" if nomcommune=="LYON"  & exp==1 & i==5
 
 replace id_geofla="COMMUNE00000000000022674" if nomcommune=="LYON" & exp==1 & i==6
replace insee_com="69387" if nomcommune=="LYON"  & exp==1 & i==6
 
 replace id_geofla="COMMUNE00000000000018670" if nomcommune=="LYON" & exp==1& i==7
replace insee_com="69388" if nomcommune=="LYON"  & exp==1 & i==7
 
 replace id_geofla="COMMUNE00000000000020800" if nomcommune=="LYON" & exp==1& i==8
replace insee_com="69389" if nomcommune=="LYON"  & exp==1 & i==8

duplicates tag id_geofla, gen (dup)
tab dup if id_geofla!=""
drop dup exp i 

replace code_arr=1 if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE" 
replace insee_com="69389"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
replace id_geofla="COMMUNE00000000000020800"  if nomcommune=="SAINT-RAMBERT-L'ILE-BARBE"
   
replace id_geofla="COMMUNE00000000000004879" if nomcommune=="MARSEILLE"  & id_geofla==""  
replace insee_com="69382" if nomcommune=="MARSEILLE"   & id_geofla==""  
 replace code_arr=3 if id_geofla=="COMMUNE00000000000004879"  

cap drop _merge

count if id_geofla==""

merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta"

preserve
keep if _merge==3
save "$Data_generated/temp/1936elections_2rounds_part1.dta", replace 
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
drop _merge 
merge m:1 id_geofla using "$Data_generated/analysis_dataset.dta"

drop if _merge!=3

** Save this dataset and later append to the part of the 1936 dataset that merges fine with the rest of the data 
save "$Data_generated/temp/1936elections_2rounds_part2.dta", replace 
restore

use  "$Data_generated/temp/1936elections_2rounds_part1.dta",  clear 
append using "$Data_generated/temp/1936elections_2rounds_part2.dta"
d,s

rename RAD_SOC_1 RADSOC_1	
rename FR_URD_1 FRURD_1
rename RAD_SOC_2 RADSOC_2	
rename FR_URD_2 FRURD_2
	
global elec1936_n "PCF SFIO DVG USR RADSOC DIV AD FRURD PRN AGR DVD FRANCISTE"
global elecAg1936  "Nuance_ExtremeGauche  Nuance_Gauche  Nuance_CentreGauche Nuance_CentreDroit Nuance_Droite  Nuance_ExtremeDroite Nuance_Divers"

** Like in other elections: Pour arrondissements 13 a 16 de marseille: create them and take average of marseille :
replace id_geofla="COMMUNE00000000000000002" if nom_com=="BOUDY-DE-BEAUREGARD"
 
expand 5 if  id_geofla=="COMMUNE00000000000011957", gen (exp2)
bysort exp2: gen ii=_n
gen marseille=0
replace marseille=1 if id_geofla=="COMMUNE00000000000011957" | id_geofla=="COMMUNE00000000000014628" | id_geofla=="COMMUNE00000000000030154" | id_geofla=="COMMUNE00000000000025519" | id_geofla=="COMMUNE00000000000021898" | id_geofla=="COMMUNE00000000000004879" | id_geofla=="COMMUNE00000000000014106" | id_geofla=="COMMUNE00000000000013379" | id_geofla=="COMMUNE00000000000001896" | id_geofla=="COMMUNE00000000000029222" | id_geofla=="COMMUNE00000000000021579" | id_geofla=="COMMUNE00000000000009040" 
 
foreach var of varlist Electeursinscrits_1-PRN_1  Electeursinscrits_2-PRN_2 {
	 egen ms_`var'=mean (`var') if marseille==1
}
replace id_geofla="COMMUNE00000000000020002" if ii==1 & exp2==1
replace id_geofla="COMMUNE00000000000031575" if ii==2 & exp2==1 
replace id_geofla="COMMUNE00000000000013082" if ii==3 & exp2==1
replace id_geofla="COMMUNE00000000000034449" if ii==4 & exp2==1

foreach x in  COMMUNE00000000000020002 COMMUNE00000000000031575 COMMUNE00000000000013082 COMMUNE00000000000034449 {
foreach var of varlist Electeursinscrits_1-PRN_1  Electeursinscrits_2-PRN_2 {
	replace `var'=ms_`var' if id_geofla=="`x'"
		}
}
drop ii marseille  ms* exp2*

 *** To be sure not to have issues with the 0 when taking the log of the shares, we add +1 to all the votes before computing the share 
foreach x in $elec1936_n {
		forvalues i=1(1)2 {
	gen DRun`x'_`i'=(`x'_`i'>0 & `x'_`i'!=.)
	gen sh`x'_`i'=((`x'_`i')/	(Suffragesexprimes_`i'))*100
	gen sh`x'_I_`i'=((`x'_`i')/ (Electeursinscrits_`i'))*100
	}
}	
foreach x in $elecAg1936 {
			forvalues i=1(1)2 {
	gen sh`x'_`i'=((`x'_`i')/	(Suffragesexprimes_`i'))*100
	gen sh`x'_I_`i'=((`x'_`i')/ (Electeursinscrits_`i'))*100
	}	
}	
 
* Turnout

foreach y in  1 2 {
	gen turnout_`y'=(Votants_`y' / Electeursinscrits_`y')*100
	replace turnout_`y'=. if (Electeursinscrits_`y'==.|Votants_`y'==.)
	}

foreach x in 1 2  {
	replace  turnout_`x'=100 if turnout_`x'>100 & turnout_`x'!=.
	gen lturnout_`x'=log(turnout_`x')
}

		forvalues i=1(1)2 {
label var  turnout_`i' 	"Turnout `i' rd 1936"
label var  lturnout_`i' 	"Log Turnout `i' rd 1936"

label var  shPCF_`i' 	"Sh. PCF `i' rd 1936 (EL)"
label var  shSFIO_`i' 	"Sh. SFIO `i' rd 1936 (L)"
label var  shDVG_`i' 	"Sh. misc. left `i' rd 1936 (L)"
label var  shUSR_`i' 	"Sh. USR `i' rd `i' rd 1936 (CL)"
label var  shRADSOC_`i' "Share RAD-SOC `i' rd 1936 (CL)"

label var  shDIV_`i' 	"Sh. misc. `i' rd 1936"

label var  shAD_`i' 	"Sh. AD `i' rd 1936 (CR)"
label var  shFRURD_`i' "Share FRURD `i' rd 1936 (CR)"
label var  shPRN_`i'	"Share PRN `i' rd 1936 (R)" 
label var  shAGR_`i' 	"Share AGR `i' rd 1936 (R)"
label var  shDVD_`i' 	"Sh. misc. right `i' rd 1936 (R)"

label var  shFRANCISTE_`i' 	"Sh. extreme right `i' rd 1936 (ER)"

label var  shNuance_ExtremeGauche_`i' "Share Extreme Left `i' rd, 1936"
label var  shNuance_Gauche_`i' "Share Left `i' rd, 1936"
label var  shNuance_CentreGauche_`i' "Share Center Left `i' rd, 1936"
label var  shNuance_CentreDroit_`i' "Share Center Right `i' rd, 1936"
label var  shNuance_Droite_`i' "Share Right `i' rd, 1936"
label var  shNuance_Divers_`i' "Share Other `i' rd, 1936"
label var  shNuance_ExtremeDroite_`i' "Share Extreme Right `i' rd, 1936"
		}
foreach var of varlist Electeursinscrits_1-PRN_1 Electeursinscrits_2-PRN_2  DRunPCF_1-shNuance_Divers_I_2 turnout_1 turnout_2 lturnout_1 lturnout_2 {
	rename `var' `var'_36
	}
	
gen elec1936_miss=(_merge==1)
drop _m 

collapse (mean) round sh*_1_36  sh*_2_36 DRun*1_36 DRun*2_36 turnout*1_36 lturnou*1_36  turnout*2_36 lturnou*2_36 (sum) Votants_1_36  Electeursinscrits_1_36 Votants_2_36  Electeursinscrits_2_36 PCF_1_36 SFIO_1_36 DVG_1_36 USR_1_36 RADSOC_1_36 DIV_1_36 AD_1_36 FRURD_1_36 PRN_1_36 AGR_1_36 DVD_1_36 FRANCISTE_1_36 Nuance_ExtremeGauche_1_36  Nuance_Gauche_1_36  Nuance_CentreGauche_1_36 Nuance_CentreDroit_1_36 Nuance_Droite_1_36  Nuance_ExtremeDroite_1_36 Nuance_Divers_1_36 ///
PCF_2_36 SFIO_2_36 DVG_2_36 USR_2_36 RADSOC_2_36 DIV_2_36 AD_2_36 FRURD_2_36 PRN_2_36 AGR_2_36 DVD_2_36 FRANCISTE_2_36 Nuance_ExtremeGauche_2_36  Nuance_Gauche_2_36  Nuance_CentreGauche_2_36 Nuance_CentreDroit_2_36 Nuance_Droite_2_36  Nuance_ExtremeDroite_2_36 Nuance_Divers_2_36 , by (id_geofla code_arr)
d,s

save "$Data_generated/1936elections_2rounds.dta", replace 

use "$Data_generated/analysis_dataset.dta", clear
keep  id_geofla latitude longitude code_dep fid-nom_reg id_bureau RI_number-OutsideFrance $precontrols_nomiss $lpretrends_nomiss  
cap drop _merge 
merge 1:1 id_geofla using "$Data_generated/1936elections_2rounds.dta"

keep if _merge==3
drop _merge

save "$Data_generated/1936elections_2rounds.dta",  replace 

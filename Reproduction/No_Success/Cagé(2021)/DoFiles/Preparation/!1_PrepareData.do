/*****************************************************************************************/
/*****************************************************************************************/
/*****************************************************************************************/
/**************** PREPARE DATASET ********************************************************/
/*****************************************************************************************/
/*****************************************************************************************/
/*****************************************************************************************/


******************************************************************************************************/


clear all
set maxvar   32767


 /************************************************************************************************************************************************/
/****         Other WWII Data   */
/************************************************************************************************************************************************/

** Other WWII 
import delimited using "$Data_origin/OtherWWII/communesdemarcationvichy.txt"
replace near_dist = near_dist/1000
rename near_dist distdemarcationkm
rename name vichy
sort id_geofla
keep id_geofla distdemarcationkm vichy
save "$Data_generated/temp/communesdemarcationvichy.dta", replace
 /************************************************************************************************************************************************/
 /************************************************************************************************************************************************/
/*********************************         MERGE ALL DATA AT MUNICIP LEVEL   ********************************************************************/
/************************************************************************************************************************************************/
 /************************************************************************************************************************************************/


 /************************************************************************************************************************************************
/****            Geo coordinates   */
************************************************************************************************************************************************/
*Importing and cleaning raw dataset of X/Y coordinates of communes' centroids 
import excel using "$Data_raw/Shapefiles/code-postal-code-insee-2015.xlsx", firstrow clear

*dropping oversea communes
drop if inlist(NOM_DEPT,"GUADELOUPE","GUYANE","MARTINIQUE","MAYOTTE","REUNION")

*formatting lat and long		
keep GeoPoint ID_GEOFLA
order ID_GEOFLA, b(GeoPoint)
split GeoPoint, p(",")
drop GeoPoint 
rename GeoPoint1 latitude
rename GeoPoint2 longitude
destring latitude, replace
destring longitude, replace
rename ID_GEOFLA id_geofla

*checking duplicates in terms of id_geofla - same coordinates
// sort id_geofla
// quietly by id_geofla:  gen dup = cond(_N==1,0,_n)
// br if dup!=0
duplicates drop id_geofla, force

*labelling variables and saving final dataset 
label var id_geofla "ID GEOFLA 2015"
label var latitude "Latitude communes INSEE 2015"
label var longitude "Longitude communes INSEE 2015"

save  "$Data_origin/Maps/gps_coordinates_insee_idgeofla2015.dta", replace
 
 
/************************************************************************************************************************************************
/****            Historic Population Data  */
************************************************************************************************************************************************/

use "$Data_raw/Shapefiles/communeswgs84.dta", clear 
merge 1:1 id_geofla using  "$Data_origin/Census/Population_Communes1911-1954_IGN_WIDE.dta", gen (mergeCensus)
drop *merge*
merge 1:1 id_geofla using  "$Data_origin/Maps/gps_coordinates_insee_idgeofla2015.dta"
drop *merge*

 
/************************************************************************************************************************************************
/****            MDDH: WWI Casualty data  */
************************************************************************************************************************************************/
 merge 1:1  id_geofla  using "$Data_generated/mdh_IGN_cityMdH_new_V&P_municip.dta", gen (mergeWWI)

cap drop _merge 

/************************************************************************************************************************************************
/****            Other data on WWII   */
************************************************************************************************************************************************/

 
sort id_geofla

merge 1:1 id_geofla using "$Data_generated/temp/communesdemarcationvichy.dta"

** Corsica 
 replace vichy = "VICHY" if code_dept =="2A" | code_dept=="2B"
 replace vichy= strtrim(vichy)
 replace vichy = "DIVIDED" if vichy=="" & distdemarcationkm==0

replace vichy= "COASTAL" if vichy==""
gen vichyfrance = vichy=="VICHY"
gen occupied = vichy=="OCCUPIED"
gen alsacelorraine = code_dept == "54" | code_dept=="55" | code_dept=="57"| code_dept=="88" | code_dept=="67" | code_dept=="68"
replace vichy="ALSACE-LOR" if alsacelorraine==1
gen bordercoast = vichy=="COASTAL"
 
 ** Some of the coastal areas omitted accidentally. So we fix.
 replace vichy = "VICHY" if vichy=="COASTAL" & (code_dept=="74" | code_dept=="73" | code_dept=="04" | code_dept == "05" | code_dept== "06" | code_dept =="83" | code_dept=="13" | code_dept=="30" | code_dept=="34" | code_dept=="11" | code_dept=="66" | code_dept=="09" | code_dept =="31" | code_dept=="65")

 capture program drop fv
 program define fv 
 replace vichy= "VICHY" if id_geofla=="`1'"
 end
 
fv COMMUNE00000000000009968
fv COMMUNE00000000000002616
fv COMMUNE00000000000003373
fv COMMUNE00000000000009068
fv COMMUNE00000000000017826
fv COMMUNE00000000000032492
fv COMMUNE00000000000034074
fv COMMUNE00000000000006883
fv COMMUNE00000000000007077
fv COMMUNE00000000000010697
fv COMMUNE00000000000010822
fv COMMUNE00000000000011024
fv COMMUNE00000000000013452
fv COMMUNE00000000000007363
fv COMMUNE00000000000015809
fv COMMUNE00000000000019446
fv COMMUNE00000000000019881
fv COMMUNE00000000000021793
fv COMMUNE00000000000022720
fv COMMUNE00000000000024157
fv COMMUNE00000000000026150
fv COMMUNE00000000000000242
fv COMMUNE00000000000004806
fv COMMUNE00000000000007503
fv COMMUNE00000000000013429
fv COMMUNE00000000000021788
fv COMMUNE00000000000023323

replace vichy = "VICHY" if vichy=="COASTAL" & y_centroid<6300000 & x_centroid>390000
replace vichy = "OCCUPIED" if vichy=="COASTAL"

capture drop _merge

/************************************************************************************************************************************************
/****           Collaborators    */
************************************************************************************************************************************************/

** Merge with collabos database 
cap drop _merge 
merge 1:1 id_geofla using "$Data_origin/Collaboration/collabosPaillole.dta"
drop if _merge==2
drop _merge

foreach x of varlist collabos-Age   {
replace   `x' =0 if  `x'==.
}
 
/****************************************************************************
/**** SAVE DATASET WITH ALL WWII ACTIVITY  */
****************************************************************************/

gen lnpop1911= log(population1911+1)

foreach x in 2015 1968 1975 1982 1990 1999 2008 2013 1962  1936 1931 1926 1921 1911 1906 1901 1896 1891 1886 1881 1876 {
	count if population`x' ==. & population`x'_insee2019!=.
}
foreach x in 2015 1968 1975 1982 1990 1999 2008 2013 1962 1946 1936 1931 1926 1921 1911 1906 1901 1896 1891 1886 1881 1876 {
cap drop pop`x'
ren population`x' pop`x'
*replace pop`x' = population`x'_insee2019
label variable pop`x' "Histo pop in `x' completed with INSEE 2019" 
}
drop *_insee2019  
 
 /****************************************************************************
/**** GEN VAR  */
****************************************************************************/

quietly {
** Log pop 1911

gen lndistdemarcationkm=log(distdemarcationkm+1)

tab vichy, gen (vichy)

* Impute population for Paris, Lyon, Marseille arrondissements
*** for Paris in 1946: data is from Census in Recensement folder 
*** for Paris in 1936: We now have the 2019 INSEE pop 
*** for  Marseille and Lyon in 1936 and 1946: data is not in the Census so we allocate as a function of total population and superficie 

foreach x in PARIS LYON MARSEILLE {
gen `x'=0
replace `x' = regexm(nom_com, "`x'") | regexm(nom_com, "`x'")
}

* for 1946: do it manually fromn Census pictures
replace pop1946=35670 if insee_com=="75101"
replace pop1946=40122 if insee_com=="75102"
replace pop1946=60479 if insee_com=="75103"
replace pop1946=59202 if insee_com=="75104"
replace pop1946=97571 if insee_com=="75105"
replace pop1946=82008 if insee_com=="75106"
replace pop1946=95547 if insee_com=="75107"
replace pop1946=71587 if insee_com=="75108"
replace pop1946=93398 if insee_com=="75109"
replace pop1946=122291 if insee_com=="75110"
replace pop1946=180697 if insee_com=="75111"
replace pop1946=145852 if insee_com=="75112"
replace pop1946=155465 if insee_com=="75113"
replace pop1946=170310 if insee_com=="75114"
replace pop1946=230719 if insee_com=="75115"
replace pop1946=182364 if insee_com=="75116"
replace pop1946=208642 if insee_com=="75117"
replace pop1946=246514 if insee_com=="75118"
replace pop1946=145310 if insee_com=="75119"
replace pop1946=185138 if insee_com=="75120"

*total superficie Lyon: 4794
foreach x in 69381 69382 69383 69384 69385 69386 69387 69388 69389 {
replace pop1936= ((574061*superficie)/4794) if insee_com=="`x'"
replace pop1946= ((464104*superficie)/4794) if insee_com=="`x'"
}

*total superficie Marseille: 23851
foreach x in  13201 13202 13203 13204 13205 13206 13207 13208 13209 13210 13211 13212 13213 13214 13215 13216 {
replace pop1936= ((914232*superficie)/23851) if insee_com=="`x'"
replace pop1946= ((636264*superficie)/23851) if insee_com=="`x'"
}
drop PARIS LYON MARSEILLE

* interpolate pop between 1936 and 1946
gen pop1937=(9*pop1936+pop1946) / 10
gen pop1938=(8*pop1936+2*pop1946) / 10
gen pop1939=(7*pop1936+3*pop1946) / 10
gen pop1940=(6*pop1936+4*pop1946) / 10
gen pop1941=(5*pop1936+5*pop1946) / 10
gen pop1942=(4*pop1936+6*pop1946) / 10
gen pop1943=(3*pop1936+7*pop1946) / 10
gen pop1944=(2*pop1936+8*pop1946) / 10
gen pop1945=(1*pop1936+9*pop1946) / 10

foreach x in 1937 1938 1939 1940 1941 1942 1943 1944 1945 {
label var pop`x' "Pop in `x' interpolated btw Census years"
}

}

drop if id_geofla==""


gen lnpop1936 =log(pop1936+1)
replace  lnpop1936=. if pop1936==. | pop1936==0
label var  lnpop1936 "Log pop in 1936"

gen lnpop1946 =log(pop1946+1)
replace  lnpop1946=. if pop1946==. | pop1946==0
label var  lnpop1946 "Log pop in 1936"

**
foreach x in latitude longitude {
gen `x'sq=`x'*`x'
}
 save "$Data_generated/temp/Allmerged.dta", replace 




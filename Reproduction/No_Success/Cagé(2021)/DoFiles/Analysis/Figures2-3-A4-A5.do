quietly{


*********************************************************************************************
*******************  				CREATE MAP LAYERS 				 ******************* 
**********************************************************************************************

 
  *********************************************************************************************
 *********************************************************************************************
*******************  					VERDUN 				 ******************* 
**********************************************************************************************
  *********************************************************************************************

*********************************************************************************************
*****SAVE DATASET WITH EACH COMMUNE AND CLOSEST GARRISON/WHICH RI IT WAS ALLOCATED TO	***** 
**********************************************************************************************

 *********************************************************************************************
*****SAVE COMMUNE AND AND WHETHER FIGHT IN VERDUN OR NOT FROM DIC COMMUNES  ***** 
**********************************************************************************************
import delimited "$Data_raw/Shapefiles/communes.csv", clear 
save "$Data_raw/Shapefiles/communes.dta", replace 

******
use "$Data_generated/analysis_dataset.dta", clear
drop code_cant
keep if verdun==0 
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 
export delimited  "$Data_origin/Maps/communes_NotVerdun_Dic.csv",   replace 
 
******
use "$Data_generated/analysis_dataset.dta", clear
drop code_cant
keep if verdun>0 & verdun_petain==0
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 
export delimited  "$Data_origin/Maps/communes_verdunNotPetain_Dic.csv",   replace 

******
use "$Data_generated/analysis_dataset.dta", clear
drop code_cant
keep if verdun>0 & verdun_petain==1
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 
export delimited  "$Data_origin/Maps/communes_verdunPetain_All_Dic.csv",   replace 


******
use "$Data_generated/analysis_dataset.dta", clear
drop code_cant
keep if verdun>0 & verdun_petain>0  & verdun_petain<1
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 
export delimited  "$Data_origin/Maps/communes_verdunPetain_Split_Dic.csv",   replace 


 *********************************************************************************************
 *********************************************************************************************
*******************  		COMMUNES AT	VERDUN MONTH BY MONTH				 ******************* 
**********************************************************************************************
  *********************************************************************************************

use "$Data_generated/analysis_dataset.dta", clear
 
keep id_geofla  feb march april mai june july aug sept oct nov dec 
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 

keep id_geofla-wkt 
export delimited   "$Data_origin/Maps/Communes_at_Verdun_Allmonths.csv",   replace 



  *********************************************************************************************
 *********************************************************************************************
*******************  					COLLABORATORS	and Resistants			 ******************* 
**********************************************************************************************
  *********************************************************************************************
use "$Data_generated/analysis_dataset.dta", clear

drop if verdun==.
keep id_geofla lncollabospc  

merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"
drop if _merge!=3
drop _merge 

export delimited  "$Data_origin/Maps/CollabosCommunes.csv",   replace 




*********************************************************************************************
*********************************************************************************************
*******************  					BDR					   			 ******************* 
**********************************************************************************************
*********************************************************************************************
 
use "$Data_generated/temp/id_geofla_to_BR.dta", clear
merge m:1 id_bureau using "$Data_generated/temp/BR_to_RI.dta"

br if _merge==2
drop if _merge!=3
drop _merge  
merge 1:1 id_geofla using "$Data_raw/Shapefiles/communes.dta"

drop if _merge!=3 

drop _merge 

gen couverture=(couverturecorps==1) 
gen fortress=(regimentnew>145 & regimentnew<99999)
forvalues i=2(1)13{
replace  fortress=1 if regimentnew`i'>145 & regimentnew`i'<99999
}

export delimited  "$Data_origin/Maps/Com_to_BR_to_RI.csv",   replace 
}

quietly{
*******************************************************************************
* Table A4A: Balance on Weather & Elevation
********************************************************************************
********************************************************************************
* Table A4B: Balance on Presence of Natural Resources at Municipal Level
********************************************************************************

use "$Data_generated/analysis_dataset.dta", clear
merge 1:1 id_geofla using  "$Data_origin/Misc/communes_precipitation.dta"
drop if _merge==2
merge 1:1 id_geofla using  "$Data_origin/Misc/communes_temperature.dta", gen(merge2)
drop if merge2==2
merge 1:1 id_geofla using "$Data_raw/NaturalRessources/data_natural_resources_idgeofla.dta", gen(merge3)
drop if merge3==2

drop if verdun==.
drop if lncollabospc==.

mat balance=J(10,12,.)
local i=1
foreach var in average_annual_precipitation average_annual_temperature   z_moyen ///
		 ///
		{
		
		
    sum `var' 
		mat balance[`i',1]=r(N)
		mat balance[`i',3]=round(r(mean) , 0.001)
		mat balance[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,   cluster(id_bureau)
		mat balance[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun, absorb(code_dept) cluster(id_bureau)
		mat balance[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',11]=round(r(p), 0.001)
		
	local ++i		
}

local mylist Coal Silver Copper Lead Zinc Nickel Tin Iron Uranium Sulfur Cobalt Titanium Hydrocarbon Gold
foreach i of local mylist {
replace `i'=0 if `i'==.
}

local i=4
foreach var in Coal Silver Copper Lead Zinc Iron Hydrocarbon  ///
		 ///
		{
		
    sum `var' 
		mat balance[`i',1]=r(N)
		mat balance[`i',3]=round(r(mean) , 0.001)
		mat balance[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,   cluster(id_bureau)
		mat balance[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun, absorb(code_dept) cluster(id_bureau)
		mat balance[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',11]=round(r(p), 0.001)
		
	local ++i		
}


mat colnames balance=  "Observations (municipalities)" "se" "Mean /(sd)" "sd" "Coeff" "se" "p-value" "se" "Coeff (dep FE)" "se" "p-value" "se"
mat rownames balance = "Precipitation rate (mm/day)" "Average temperature (Celsius)"   "Elevation (m)" "Coal" "Silver" "Copper" "Lead" "Zinc" "Iron"  "Hydrocarbon" 

capture log close
mat li balance

*erase previous version because fmrttable cannot overwrite
capture erase "$Results/Tables/TableA4.tex"

frmttable using "$Results/Tables/TableA4.tex" , fragment hlines(1011{0}1) tex statmat(balance) multicol(3,4,2;3,6,2) substat(1)   sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(Municipalities)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "")
}


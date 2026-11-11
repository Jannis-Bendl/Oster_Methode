quietly{
********************************************************************************
* Table A5: Balance on Soil Characteristics at Grid-Cell Level
********************************************************************************
use "$Data_raw/NaturalRessources/biogeography_soil_verdun.dta", clear

mat balance=J(7,12,.)
local i=1
foreach var in clay silt sand organic_ca nitrogen  caco30 ph   ///
		 ///
		{
		
		
    sum `var' 
		mat balance[`i',1]=r(N)
		mat balance[`i',3]=round(r(mean) , 0.001)
		mat balance[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,  cluster(id_bureau)
		mat balance[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun, absorb(code_dept)   cluster(id_bureau)
		mat balance[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',11]=round(r(p), 0.001)
		
	local ++i		
}


mat colnames balance=  "Observations (Square Grid)" "se" "Mean /(sd)" "sd" "Coeff" "se" "p-value" "se" "Coeff (dep FE)" "se" "p-value" "se"
mat rownames balance = "Clay" "Silt" "Sand" "Organic carbon" "Nitrogen" "Calcium carbonates" "pH" 

capture log close
mat li balance

*erase previous version because fmrttable cannot overwrite
capture erase "$Results/Tables/TableA5.tex"

frmttable using "$Results/Tables/TableA5.tex" , fragment hlines(1011{0}1) tex statmat(balance) multicol(3,4,2;3,6,2) substat(1)   sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(Square Grid 16km*16km)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "")
}

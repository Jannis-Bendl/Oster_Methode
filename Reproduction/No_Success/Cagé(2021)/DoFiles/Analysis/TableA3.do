quietly{
*************************************************************************************
* Table A3: Balance on Historical Characteristics from Squicciarini at Bailliage level
**************************************************************************************
import excel using "$Data_origin/Misc/Squicciarini/district_verdun_Petain.xls", firstrow clear

*renaming and keeping useful variables
rename Sheet1__ve verdun_petain
rename bureau_rec verdun
rename  DISTRICT_I district_id
keep district_id verdun_petain  verdun 

*merging with district-level characteristics
merge 1:1 district_id using "$Data_origin/Misc/4.district_dataset_label.dta"
keep if _merge==3 
rename department_id code_dept 

*dropping main districts that are both VuP and not VuP/ Verdun and not Verdun
//VuP split
drop if inlist(district_id, 290, 496, 144, 261, 372, 240, 86, 339, 163, 459, 506, 320, 523, 411, 364,388,93,520,409,43)
//Verdun split
drop if inlist(district_id,68,240,86,163,73,93,539)

*balance table
mat balance=J(6,12,.)
local i=1
foreach var in wheat_suit   plague_total   share_refractory lnHH_exp_dis  lnsubs lnfirms_distr  ///
		 ///
		{
		
    sum `var' 
		mat balance[`i',1]=r(N)
		mat balance[`i',3]=round(r(mean) , 0.001)
		mat balance[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun
		mat balance[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun, absorb(code_dept) 
		mat balance[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',11]=round(r(p), 0.001)
		
	local ++i		
}

mat colnames balance=  "Observations (baillages)" "se" "Mean /(sd)" "sd" "Coeff" "se" "p-value" "se" "Coeff (dep FE)" "se" "p-value" "se"
mat rownames balance = "Wheat suitability" "Plague outbreaks (1517-1786)" "Share of refractory clergy" "Log average HH expenditure 1901" "Subscrib. Encyclop\'{e}die (1777-1780)" "Log number of firms in 1800" 

capture log close
mat li balance

*erase previous version because fmrttable cannot overwrite
capture erase "$Results/Tables/TableA3.tex"

frmttable using "$Results/Tables/TableA3.tex" , fragment hlines(1011{0}1) tex statmat(balance) multicol(3,4,2;3,6,2) substat(1)   sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(Baillages)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "")
}

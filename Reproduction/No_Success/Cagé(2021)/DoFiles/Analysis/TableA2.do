quietly{
*
**************************************************************************************
* Table A2: Balance on Historical Characteristics from Squicciarini at Canton level
**************************************************************************************
import excel using "$Data_origin/Misc/Squicciarini/canton_verdun_Petain.xls",  firstrow clear

*renaming and keeping useful variables
keep ID_canton Sheet1__ve bureau_rec bureau_rec_1 CODE_DEPT  

rename bureau_rec verdun
rename Sheet1__ve verdun_petain
rename bureau_rec_1 id_bureau
rename CODE_DEPT code_dept
sort ID_canton

*replacing missing code departements
replace code_dept="17" if ID_canton==491
replace code_dept="2B" if ID_canton==598
replace code_dept="56" if ID_canton==1795
replace code_dept="83" if ID_canton==2576
replace code_dept="85" if ID_canton==2631

*replacing missing id_bureau
replace id_bureau=73 if ID_canton==491
replace id_bureau=6 if ID_canton==598
replace id_bureau=85 if ID_canton==1795
replace id_bureau=151 if ID_canton==2576
replace id_bureau=74 if ID_canton==2631

*replacing missing verdun
replace verdun=1 if ID_canton==491
replace verdun=1 if ID_canton==598
replace verdun=1 if ID_canton==1795
replace verdun=1 if ID_canton==2576
replace verdun=1 if ID_canton==2631

*replacing missing verdun under Petain
replace verdun_petain=0 if ID_canton==491
replace verdun_petain=0 if ID_canton==598
replace verdun_petain=1 if ID_canton==1795
replace verdun_petain=0 if ID_canton==2576
replace verdun_petain=0 if ID_canton==2631

*merging with canton-level characteristics
merge 1:1 ID_canton using "$Data_origin/Misc/canton_dataset.dta"
rename HH_expend hh_expend

*balance table
mat balance2=J(12,12,.)
local i=2
foreach var in    lnschools_total1873 share_cath_schools1873 sh_schools_bad_state1873 ///
				 ///
		{
		
    sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun, cluster(id_bureau)
		mat balance2[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain  verdun, absorb(code_dept) cluster(id_bureau)
		mat balance2[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',11]=round(r(p), 0.001)
		
	local ++i		
}

local i=6

foreach var in   lnschools_total1894 share_cath_schools1894 share_cath_students1894  share_mal_cath_students1894 share_fem_cath_students1894 ///
				 ///
		{
		
	sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun, cluster(id_bureau)
		mat balance2[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun , absorb(code_dept) cluster(id_bureau)
		mat balance2[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',11]=round(r(p), 0.001)
		
	local ++i		
}

local i=12

foreach var in hh_expend ///
				 ///
		{
		
	sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun, cluster(id_bureau)
		mat balance2[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun, absorb(code_dept) cluster(id_bureau)
		mat balance2[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance2[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance2[`i',11]=round(r(p), 0.001)
		
	local ++i		
}

mat colnames balance2=  "Observations (cantons)" "se" "Mean /(sd)" "sd" "Coeff" "se" "p-value" "se" "Coeff (dep FE)" "se" "p-value" "se"
mat rownames balance2 =  "1873"  "Number of schools" "Share Catholic schools" "Share schools in bad condition"   "1894"  "Number of schools" "Share Catholic schools"  "Share Catholic students"  "Share Male Catholic students"  "Share Female Catholic students"  "1901" "Average HH expenditure" 

capture log close
mat li balance2

*erase previous version because fmrttable cannot overwrite
capture erase "$Results/Tables/TableA2.tex"

frmttable using "$Results/Tables/TableA2.tex" , fragment hlines(1011{0}1) tex statmat(balance2) multicol(3,4,2;3,6,2) substat(1)   sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(Cantons)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "")
}

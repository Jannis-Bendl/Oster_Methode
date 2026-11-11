quietly{
********************************************************************************
* Table A1: Balance on 1872 Industrial and Religious Characteristics 
********************************************************************************

********************************************************************************
use "$Data_generated/analysis_dataset.dta", clear

**** Appendix *** 1872 table
sort id_geofla

capture drop _merge
merge 1:1 id_geofla using "$Data_origin/Misc/census1872small"

drop _merge

mat balance2=J(17,12,.)
local i=2
foreach var in logtotalpop1872  share_male1872 share_female1872 share_foreigners1872 silliterate_total ///
		 ///
		{
		
    sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,   cluster(id_bureau)
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

local i=8

foreach var in share_catholic_cultplaces1872 share_protestant_cultplaces1872 share_jewish_cultplaces1872 share_other_cultplaces1872 ///
		 ///
		{
		
	sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,   cluster(id_bureau)
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

local i=13

foreach var in share_industry1872 share_agriculture1872 share_merchants1872 share_liberals1872 share_unemployment1872 ///
		 ///
		{
		
	sum `var' 
		mat balance2[`i',1]=r(N)
		mat balance2[`i',3]=round(r(mean) , 0.001)
		mat balance2[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun,   cluster(id_bureau)
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

mat rownames balance2 = "Demographics and Education(1872)" "Log population" "Share Men" "Share Women" "Share Foreigners" "Share Illiterate" "Religious Characteristics(1872)" "Catholic places of worship" "Protestant places of worship" "Jewish places of worship" "Other places of worship" "Occupation Shares(1872)" "Industrial workers" "Farmers" "Merchants" "Liberal occupations" "Unemployed" 
	
capture log close
mat li balance2

*erase previous version because fmrttable cannot overwrite
capture erase "$Results/Tables/TableA1.tex"

frmttable using "$Results/Tables/TableA1.tex" ,  fragment hlines(1011{0}1) tex statmat(balance2) multicol(3,4,2;3,6,2) substat(1) sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3\ 0,3,3,3,3 ) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(chef-lieux)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "")
}

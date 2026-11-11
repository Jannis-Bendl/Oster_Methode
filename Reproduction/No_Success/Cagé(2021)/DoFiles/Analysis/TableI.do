use "$Data_generated/analysis_dataset.dta", clear
********************************************************************************
* Table I: Balance table in terms of pre-war vote 
********************************************************************************

****** Combining the Centers and the Diverses....
capture drop shNuance_CentreDiv_14	
egen shNuance_CentreDiv_14 =rsum(shNuance_CentreGauche_14 shNuance_CentreDroit_14 shNuance_Divers_14)
replace shNuance_CentreDiv_14=. if shNuance_CentreGauche_14==.
replace turnout_14=. if shNuance_CentreGauche_14==.

mat balance=J(10,12,.)


local i=2
foreach var in shNuance_Gauche_14 shNuance_CentreDiv_14 shNuance_Droite_14 turnout_14  lnpop1911 /*lnrecettes_pc*/ {

	sum `var' 
		mat balance[`i',1]=round(r(N),1)
		mat balance[`i',3]=round(r(mean) , 0.001)
		mat balance[`i',4]=round(r(sd), 0.001)
		
	reg `var' verdun_petain verdun ,   cluster(id_bureau)
		mat balance[`i',5]=round(_b[verdun_petain], 0.001)
		mat balance[`i',6]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',7]=round(r(p), 0.001)

	areg `var' verdun_petain verdun , absorb(code_dept) cluster(id_bureau)
		mat balance[`i',9]=round(_b[verdun_petain], 0.001)
		mat balance[`i',10]=round(_se[verdun_petain], 0.001)
		test verdun_petain
		mat balance[`i',11]=round(r(p), 0.001)
		
	local ++i		
	}

preserve 

keep if lnpop1936!=.

	local i=8
foreach var in lnpop1936 lndistdemarcationkm vichyfrance {
		sum `var' 
		mat balance[`i',1]=round(r(N),1)
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
	
restore

mat rownames balance=  "Pre-Treatment Characteristics" "Left Vote Share 1914"  "Centre/Other Vote Share 1914" "Right Vote Share 1914" "Turnout 1914" "Log Population 1911" "Inter-War and WWII Charact." "Log Population 1936"  "Log Distance Demarcation Line" "Vichy France 1940-44"

capture log close
mat li balance

*erase previous table
capture erase "$Results/Tables/TableI.tex"

*save new table (frmttable cannot overwrite a table)
frmttable using "$Results/Tables/TableI.tex",  fragment hlines(1011{0}1) tex statmat(balance) multicol(3,4,2;3,6,2) substat(1) sdec(0,3,3,3,3 \ 0,3,3,3,3  \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 \ 0,3,3,3,3 ) ctitles( "" "Observations"  "Mean" "Coeff"  "p-value"  "Coeff"  "p-value" \ ""  "(municipalities)"  "(sd)" "(se)"  ""  "(se)"  "" \ "Controls"  ""  "" "None"  ""  "Dept FE"  "") 

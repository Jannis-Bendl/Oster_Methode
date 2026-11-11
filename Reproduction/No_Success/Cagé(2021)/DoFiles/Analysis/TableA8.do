quietly{
*********************************************************************************************
*********************************************************************************************
***************** 	  Table A8   						    *********************************
*********************************************************************************************
*********************************************************************************************

use "$Data_generated/analysis_dataset.dta", clear

drop if latitude==.

*** Collela et al. se

encode code_dept, gen(code_dep_n)


estimates clear	
foreach i in  25 50 100 150  200 250 {

	eststo: xi: acreg    lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss , spatial  latitude(latitude) longitude(longitude) dist(`i')  pfe1(code_dep_n)
 		estadd local cutoff "`i'", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Sample  "1914 France", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm

		
	eststo: xi: acreg    lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss if verdun!=0  , spatial  latitude(latitude) longitude(longitude) dist(`i')  pfe1(code_dep_n)
 		estadd local cutoff "`i'", replace 
		estadd local Pop "\checkmark", replace 
		estadd local Sample  "1914 France", replace 
		estadd local PreTrends "\checkmark", replace
		estadd ysumm


		
}

esttab using "$Results/Tables/TableA8.tex", replace ///
	keep(verdun_petain   ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"     )   ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats(  Pop PreTrends cutoff  r2 N ymean ysd, fmt(  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc) labels( "1911 pop" "Pre-WWI vote shares" " Conley cutoff" "R-squared" "Observations" "Mean DepVar" "Sd DepVar")) ///
	collabels(none) label  ///
	mtitles("All" "Verdun"  "All" "Verdun"  "All" "Verdun"   "All" "Verdun" "All" "Verdun" "All" "Verdun") ///
	mgroups( "Log collaborators per capita (OLS)"  , pattern(1 0 0 0 0 0   0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  

}

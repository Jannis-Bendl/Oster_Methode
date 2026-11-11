
***********************************************************************************************************************
* Table A11
***********************************************************************************************************************
quietly {
use "$Data_generated/analysis_dataset.dta", clear 

foreach x in 19 24 32 36 {
	foreach z in shNuance_ExtremeGauche_    shNuance_Gauche_  shNuance_CentreGauche_ shNuance_CentreDroit_  shNuance_Droite_  shNuance_ExtremeDroite_ turnout_ {
		gen d_`z'`x'=`z'`x'-`z'14
	}
}
	
***********************************		
* Turnout
foreach y in 14 19 24 32 36 {
	gen turnout_19`y'=(Votants_`y' / Electeursinscrits_`y')*100
	gen lturnout_19`y'=log(turnout_19`y'+1) 
	}	
foreach y in 19 24 32 36 {
		cap gen lturnout_`y'=log(turnout_`y'+1)
	}
	
	gen balanced = (shNuance_Droite_19!=. & shNuance_Droite_24!=. & shNuance_Droite_32!=. & shNuance_Droite_36!=.)
	
keep id_geofla  id_bureau lturnout_19 lturnout_24 lturnout_32 lturnout_36  *ExtremeGauche*   *Gauche* *CentreGauche* *CentreDroit* *Droite* verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss  RI_number code_dep iden1936 iden1919 iden1914 Dfoch_any d_* balanced code_arr 
		
		
		reshape long shNuance_ExtremeGauche_ lturnout_  shNuance_ExtremeDroite_ shNuance_Gauche_ shNuance_Droite_  shNuance_CentreGauche_ shNuance_CentreDroit_  d_shNuance_ExtremeGauche_ d_shNuance_Gauche_ d_shNuance_CentreGauche_ d_shNuance_CentreDroit_  d_shNuance_Droite_ d_shNuance_ExtremeDroite_  d_turnout_  , i(id_geofla) j(year)
	
		gen shNuance_Centre=shNuance_CentreGauche_ + shNuance_CentreDroit_ 


			foreach x in shNuance_ExtremeGauche_    shNuance_Gauche_  shNuance_CentreGauche_ shNuance_CentreDroit_  shNuance_Centre shNuance_Droite_  shNuance_ExtremeDroite_ {
			gen l`x'=log(`x'+1)
		}
	
tab year, gen(year)
gen trend=.
replace trend=0 if year==19	
replace trend=1 if year==24	
replace trend=2 if year==32	
replace trend=3 if year==36	

gen trendVuP=trend *verdun_petain

encode code_dept, gen (code_dept_num)
gen unique_arr = code_dept_num*100+ code_arr
	
		estimates clear 

		
	foreach x in shNuance_ExtremeGauche_    shNuance_Gauche_  shNuance_Centre  shNuance_Droite_  shNuance_ExtremeDroite_ turnout_  {
	eststo:  xi: reghdfe l`x' verdun_petain verdun $precontrols_nomiss $lpretrends_nomiss  if year>14 , cl(id_bureau  unique_arr)  absorb (code_dept year) 
 		estadd local FixedEffects2 "\checkmark", replace 
		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
 		estadd local PreTrends "\checkmark", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

	eststo:  xi: reghdfe l`x' verdun_petain  $precontrols_nomiss $lpretrends_nomiss  if year>14 & verdun>0 , cl(id_bureau  unique_arr)  absorb (code_dept year) 
 		estadd local FixedEffects2 "\checkmark", replace 
		estadd local Verdun "", replace 
		estadd local Pop "\checkmark", replace 
 		estadd local PreTrends "\checkmark", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
		}	
	

	esttab using "$Results/Tables/TableA11.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain"   ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( FixedEffects2 Verdun PreTrends  Pop  r2 N ymean ysd clusters, fmt(  0 0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels(  "Year Fixed Effects" "Verdun" "1911 pop"  "Pre-WWI vote shares" "R-squared" Observations "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label  ///
	mtitles("All"  "Verdun" "All"  "Verdun" "All"  "Verdun" "All"  "Verdun" "All"  "Verdun" "All"  "Verdun") ///
	mgroups("Ext. Left" "Left" "Centre"  "Right" "Ext Right" "Turnout",  pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  
}

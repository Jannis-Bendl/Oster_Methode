quietly{
	use "$Data_generated/1936elections_2rounds.dta",clear 
estimates clear 
encode code_dept, gen (code_dept_num)
gen unique_arr = code_dept_num*100+ code_arr

foreach x in _1_36 _2_36 {
gen shNuance_Centre`x'  = shNuance_CentreGauche`x' + shNuance_CentreDroit`x'
su shNuance_Centre`x' 
su shNuance_ExtremeGauche`x'     shNuance_Gauche`x' shNuance_CentreGauche`x' shNuance_CentreDroit`x'  shNuance_Droite`x' shNuance_ExtremeDroite`x' turnout`x'
}
 
	* Generate log shares and indicator variables if platform  ran in 2d round 
 
  	foreach y in PCF SFIO  DVG  USR  RADSOC  DIV  AD FRURD  AGR  DVD  FRANCISTE  PRN  {
		gen lsh`y'_1_36=log(sh`y'_1_36+1)
		gen lsh`y'_2_36=log(sh`y'_2_36+1)

		gen D2Run`y'_36=(sh`y'_2_36>0 & sh`y'_2_36<99999)
		gen D1Run`y'_36=(sh`y'_1_36>0 & sh`y'_1_36<99999)
		label var D1Run`y'_36 "`y' ran in First Round 1936"
		label var D2Run`y'_36 "`y' ran in Second Round 1936"
su D2Run`y'_36
	}

	
	foreach y in shPCF shSFIO  shDVG  shUSR  shRADSOC  shDIV shAD  shFRURD  shAGR shDVD  shFRANCISTE  shPRN turnout  {
gen D_`y'=`y'_2_36-`y'_1_36
su 	D_`y'
}

		** Table A17: Verdun subsample 
					estimates clear 

				foreach y in   SFIO     RADSOC    AD         PRN    {


eststo: xi: reghdfe  D_sh`y' verdun_petain   $precontrols_nomiss $lpretrends_nomiss   if D2Run`y'_36>0 & verdun>0, cl(id_bureau  unique_arr) absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local IniShare "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	

		}	
		
		
				eststo: xi: reghdfe  D_turnout verdun_petain   $precontrols_nomiss $lpretrends_nomiss 	if verdun>0			 , cl(id_bureau  unique_arr) absorb(code_dept) 
 		estadd local Pop "\checkmark", replace 
		estadd local PreTrends "\checkmark", replace
		estadd local IniShare "", replace
		estadd ysumm
		estadd scalar clusters = e(N_clust)	
		
	esttab using "$Results/Tables/TableA17.tex", replace ///
		keep(verdun_petain    ) /// 
		coeflabels(verdun_petain "Verdun under P\'{e}tain"   )   ///
		nogap ///
		cells(b( fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
		stats( Pop  PreTrends   r2 N ymean ysd clusters, fmt(0   0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels("1911 pop" "Pre-WWI vote shares" "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
		collabels(none) label   ///
		mtitles( "SFIO"   "RADSOC"    "AD"    "PRN" "Turnout")

}

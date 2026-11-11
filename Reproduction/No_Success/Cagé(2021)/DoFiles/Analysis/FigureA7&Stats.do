
***********************************************************************************************************************
******************* FIGURE A5:	Exclude region by region 											 ******************* 
******************* FOOTNOTE 53:	Exclude  departement by departement  							 ******************* 
**********************************************************************************************************************
quietly {
use "$Data_generated/analysis_dataset.dta", clear
********************************************************************************
*** In log
estimates clear	
tab code_reg
encode nom_reg, gen (reg_code)
tab reg_code , nol 
encode code_dep, gen (dep_code)
tab dep_code , nol


forvalues i=1(1)13 {
	
	eststo  region`i' : areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss   if reg_code!=`i' ,  cl(id_bureau)  absorb(code_dept) 
}
		
coefplot region1 region2  region3 region4 region5 region6 region7 region8 region9 region10 region11  region12  region13 , keep(verdun_petain) title("Coefficient: Verdun under Pétain - excluding:", size(medium))   byopts(xrescale)  asequation swapnames coeflabel(region1="Champagne-Ardenne" region2="Aquitaine-Limousin-Poitou-Charentes"  region3="Auvergne-Rhone-Alpes" region4="Bourgogne-Franche-Comté" region5="Bretagne" region6="Centre-Val de Loire" region7="Corse" region8="Ile-de-France" region9="Languedoc-Roussillon-Midi-Pyrénees" region10="Nord-Pas-de-Calais-Picardie" region11="Normandie"  region12="Pays de la Loire"  region13="Provence-Alpes-Cote d'Azur" , labsize(small)) rename("verdun_petain"="Verdun under Pétain") xline(0) recast(scatter)  msymbol(S)  legend(row(3) size(vsmall)  off) nooffsets graphregion(color(white)) ciopts(lcolor(navy)) mcolor(black) xscale(range(0 0.10)) scheme(s1mono)

	graph export "$Results/Figures/FigureA7.pdf", name(Graph) replace	

 
 areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss  if dep_code !=1 ,  cl(id_bureau)  absorb(code_dept) 
	xi: outreg2   using "$Results/Tables/Table_depRobust.xls", pval bdec(3) sdec(3) rdec(3)  noaster   bfmt(fc) replace 
	
forvalues i=1(1)95 {
	
	eststo  dep`i' : areg  lncollabospc verdun_petain verdun     $lpretrends_nomiss $precontrols_nomiss   if dep_code !=`i' ,  cl(id_bureau)  absorb(code_dept) 
	xi: outreg2   using "$Results/Tables/Table_depRobust.xls", pval bdec(3) sdec(3) rdec(3)  noaster   bfmt(fc)  append
}
}

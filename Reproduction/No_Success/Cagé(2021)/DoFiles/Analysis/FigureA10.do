quietly{
*********************************************************************************************
***************** 	     FIGURE A4: OTHER 2-3 MONTHS AT VER   *********************************
*********************************************************************************************

use "$Data_generated/analysis_dataset.dta", clear
global placebo "placebo_amj placebo_mjj placebo_jja placebo_jas placebo_aso placebo_son placebo_ond"

estimates clear	

foreach y in   lncollabospc   {
	foreach x in verdun_petain $placebo {
	eststo `y'_`x': xi: areg `y'    `x'   $lpretrends_nomiss   $precontrols_nomiss   ,  cl(id_bureau) absorb(code_dept) 
	}
	}

label var verdun_petain "Pétain: 26 Feb - 1 May"
label var placebo_amj "Apr, May, Jun"
label var placebo_mjj "May, Jun, Jul"
label var placebo_jja "Jun, Jul, Aug"
label var placebo_jas "Jul, Aug, Sep"
label var placebo_aso "Aug, Sep, Oct"
label var placebo_son "Sep, Oct, Nov"
label var placebo_ond "Oct, Nov, Dec"

coefplot  lncollabospc_verdun_petain lncollabospc_placebo_mjj lncollabospc_placebo_jja lncollabospc_placebo_jas lncollabospc_placebo_aso lncollabospc_placebo_son lncollabospc_placebo_ond , keep(verdun_petain   placebo_mjj placebo_jja placebo_jas placebo_aso placebo_son placebo_ond) title(Log collabos pc) ytitle("Three consecutive months at Verdun") nooffsets    asequation swapnames coeflabel(lncollabospc_verdun_petain="Pétain: 26 Feb - 1 May"    lncollabospc_placebo_mjj="May, Jun, Jul" lncollabospc_placebo_jja="Jun, Jul, Aug" lncollabospc_placebo_jas="Jul, Aug, Sep" lncollabospc_placebo_aso= "Aug, Sep, Oct" lncollabospc_placebo_son= "Sep, Oct, Nov" lncollabospc_placebo_ond= "Oct, Nov, Dec" , labsize(small)) rename("verdun_petain"="Verdun under Pétain") xline(0) recast(scatter)  msymbol(S)  legend(row(3) size(vsmall)   off)  graphregion(color(white)) ciopts(lcolor(navy)) mcolor(black) xscale(range(-0.06 0.12) ) xlabel(-0.06(0.03)0.12) scheme(s1mono) 

graph save "$Results/Figures/FigureA10_R", replace  
graph export "$Results/Figures/FigureA10_R.eps", replace as(eps)
graph export "$Results/Figures/FigureA10_R.pdf", replace as(pdf)


graph save  "$Results/Figures/FigureA10_R.pdf" , replace  
	
*****************************************************************************************************

	use "$Data_generated/analysis_dataset.dta", clear
global placebo2 "placebo_mj placebo_jj placebo_ja placebo_as placebo_so placebo_on placebo_nd"

estimates clear	

foreach y in   lncollabospc   {
	foreach x in verdun_petain $placebo2 {
	eststo `y'_`x': xi: areg `y'    `x'    $lpretrends_nomiss   $precontrols_nomiss   WWIdeathrate_nomiss WWIdeathrate_miss,  cl(id_bureau) absorb(code_dept) 
	}
	}

label var verdun_petain "Pétain: 26 Feb - 1 May"
label var placebo_mj "May, Jun"
label var placebo_jj "Jun, Jul"
label var placebo_ja "Jul, Aug"
label var placebo_as "Aug, Sep"
label var placebo_so "Sep, Oct"
label var placebo_on "Oct, Nov"
label var placebo_nd "Nov, Dec"

coefplot  lncollabospc_verdun_petain   lncollabospc_placebo_mj lncollabospc_placebo_jj lncollabospc_placebo_ja lncollabospc_placebo_as lncollabospc_placebo_so lncollabospc_placebo_on lncollabospc_placebo_nd   , keep(verdun_petain placebo_mj placebo_jj placebo_ja placebo_as placebo_so placebo_on placebo_nd) title(Log collabos pc) ytitle("Two consecutive months at Verdun") nooffsets    asequation swapnames coeflabel(lncollabospc_verdun_petain="Pétain: 26 Feb - 1 May"   lncollabospc_placebo_mj="May, Jun" lncollabospc_placebo_jj="Jun, Jul" lncollabospc_placebo_ja ="Jul, Aug" lncollabospc_placebo_as="Aug, Sep" lncollabospc_placebo_so="Sep, Oct" lncollabospc_placebo_on= "Oct, Nov" lncollabospc_placebo_nd ="Nov, Dec", labsize(small)) rename("verdun_petain"="Verdun under Pétain") xline(0) recast(scatter)  msymbol(S)  legend(row(3) size(vsmall)   off)  graphregion(color(white)) ciopts(lcolor(navy)) mcolor(black) xscale(range(-0.06  0.12) ) xlabel(-0.06(0.03)0.12) scheme(s1mono)  
graph save "$Results/Figures/FigureA10_L", replace  
graph export "$Results/Figures/FigureA10_L.eps", replace as(eps)
graph export "$Results/Figures/FigureA10_L.pdf", replace as(pdf)

	
 graph combine  "$Results/Figures/FigureA10_L" "$Results/Figures/FigureA10_R", scheme(s1mono)  
graph export "$Results/Figures/FigureA10.eps", replace as(eps)
graph export "$Results/Figures/FigureA10.pdf", replace as(pdf)

}

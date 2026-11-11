quietly{
********************************************************************************
********************************************************************************
*  # Regiments  * 
********************************************************************************
********************************************************************************

********************************************************************************
********* Number of regiments **************
********************************************************************************

********************************************************************************	
use   "$Data_generated/regimentsVerdun.dta", clear

keep if RI<=173
gen i=1

gen monthsV=.
	replace monthsV=2.5 if feb==1
	replace monthsV=3.5 if march==1
	replace monthsV=4.5 if april==1
	replace monthsV=5.5 if mai==1
	replace monthsV=6.5 if june==1
	replace monthsV=7.5 if july==1
	replace monthsV=8.5 if aug==1
	replace monthsV=9.5 if sept==1
	replace monthsV=10.5 if oct==1
	replace monthsV=11.5 if nov==1
	replace monthsV=12.5 if dec==1

 
collapse (sum) i, by (monthsV)

label var months "Month at Verdun"
label var i "Number of line infantry regiments at Verdun"
label define monthsV 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan"
label values monthsV monthsV

twoway (scatter i monthsV)  , xlabel(#11, valuelabel)  scheme(s1mono)  xline(5)
graph save "$Results/Figures/FigureA2.gph", replace 
graph export  "$Results/Figures/FigureA2.pdf", replace 

gen VuP=(monthsV<5)
ttest i, by (VuP)

gen Somme=(monthsV>=7 & months<12)
ttest i, by (Somme)
}

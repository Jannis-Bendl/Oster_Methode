quietly{
/* 
 Do file created on may 11 2021
 Conduct permutation inference at two levels (i.e. reallocate treatments at 2 levels):
 1) At municipal level 
 2) At regimenmt level keeping constant the municipalities within those regiments 
*/
clear all
set maxvar 10000

 
*********************************************************************************************************************
** At MUNICIPAL LEVEL  **
*********************************************************************************************************************
*********************************************************************************************************************
*********************************************************************************************************************
** DE FE **
*********************************************************************************************************************
**************************
** RI with full controls **
**************************
use "$Data_generated/analysis_dataset.dta", clear
tab verdun_petain 
  
  areg  lncollabospc  verdun_petain verdun  $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dep) 

g rpl=.
g beta=.
g se=.

set seed 98761256
forvalues j=1(1)1000{
g rd = runiform()
g fakeverdun_petain = .
replace fakeverdun_petain = 0 if rd<=0.4314
replace fakeverdun_petain = 0.1666667 if rd>0.4314 & rd<=0.4363
replace fakeverdun_petain = 0.3333333 if rd>0.4363 & rd<=0.4487
replace fakeverdun_petain = 0.375 if rd>0.4487 & rd<=0.4535
replace fakeverdun_petain = 0.4 if rd>0.4535 & rd<=0.4658
replace fakeverdun_petain = 0.5 if rd>0.4658 & rd<=0.5490
replace fakeverdun_petain = 0.6666667 if rd>0.5490 & rd<=0.5566
replace fakeverdun_petain = 0.875 if rd>0.5566 & rd<=0.5630
replace fakeverdun_petain = 1 if rd>0.5630 & rd<=1
replace rpl = `j' in `j'

quietly:  areg  lncollabospc fakeverdun_petain verdun  $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau)  absorb(code_dep) 

replace beta = _b[fakeverdun_petain] in `j'
replace se = _se[fakeverdun_petain] in `j'

drop rd fakeverdun_petain 
}

keep rpl beta* se* 
drop if beta==.
g t = beta/se

compress
label variable rpl `"Replication Number"'
label variable beta `"Coefficient from Fake Verdun-under-Pétain"'
label variable se `"Standard Error of the Coefficient from Fake Verdun-under-Pétain"'
label variable t `"t-value from Fake Verdun-under-Pétain"'

histogram beta, xline(0.067) percent xtitle("Coefficient on Fake V-u-P") xlabel(-0.10(0.02)0.10)  xscale(range(-0.10 0.10)) title (Full controls)  scheme(s1mono)
	graph save  "$Results/Figures/temp/Coeff_RI_MuniControls.gph",  replace	
	graph export "$Results/Figures/temp/Coeff_RI_MuniControls.pdf", name(Graph) replace	

histogram t, xline(3.69) percent xtitle("t-stat on Fake V-u-P")  xscale(range(-6  6)) xlabel(-6(2)6)   title (Full controls)  scheme(s1mono)
	graph save  "$Results/Figures/temp/T-stat_RI_MuniControls.gph",  replace	
	graph export "$Results/Figures/temp/T-stat_RI_MuniControls.pdf", name(Graph) replace	


**************************
** RI w/o controls **
**************************
 
use "$Data_generated/analysis_dataset.dta", clear
  areg  lncollabospc  verdun_petain verdun  ,  cl(id_bureau)  absorb(code_dep) 

g rpl=.
g beta=.
g se=.

set seed 98761256
forvalues j=1(1)1000{
g rd = runiform()
g fakeverdun_petain = .
replace fakeverdun_petain = 0 if rd<=0.4314
replace fakeverdun_petain = 0.1666667 if rd>0.4314 & rd<=0.4363
replace fakeverdun_petain = 0.3333333 if rd>0.4363 & rd<=0.4487
replace fakeverdun_petain = 0.375 if rd>0.4487 & rd<=0.4535
replace fakeverdun_petain = 0.4 if rd>0.4535 & rd<=0.4658
replace fakeverdun_petain = 0.5 if rd>0.4658 & rd<=0.5490
replace fakeverdun_petain = 0.6666667 if rd>0.5490 & rd<=0.5566
replace fakeverdun_petain = 0.875 if rd>0.5566 & rd<=0.5630
replace fakeverdun_petain = 1 if rd>0.5630 & rd<=1
replace rpl = `j' in `j'

quietly:  areg  lncollabospc fakeverdun_petain verdun  ,  cl(id_bureau)  absorb(code_dep) 

replace beta = _b[fakeverdun_petain] in `j'
replace se = _se[fakeverdun_petain] in `j'

drop rd fakeverdun_petain 
}

keep rpl beta* se* 
drop if beta==.
g t = beta/se

compress
label variable rpl `"Replication Number"'
label variable beta `"Coefficient from Fake Verdun-under-Pétain"'
label variable se `"Standard Error of the Coefficient from Fake Verdun-under-Pétain"'
label variable t `"t-value from Fake Verdun-under-Pétain"'

histogram beta, xline(0.0737) percent xtitle("Coefficient on Fake V-u-P") xlabel(-0.10(0.02)0.10)  xscale(range(-0.10 0.10)) title (No controls)  scheme(s1mono) 
	graph save "$Results/Figures/temp/Coeff_RI_MuniNoControls.gph",  replace	
	graph export "$Results/Figures/temp/Coeff_RI_MuniNoControls.pdf", name(Graph) replace	

histogram t, xline(1.78) percent xtitle("t-stat on Fake V-u-P")   xscale(range(-6  6)) xlabel(-6(2)6)    title (No controls)  scheme(s1mono)
	graph save  "$Results/Figures/temp/T-stat_RI_MuniNoControls.gph",  replace	
	graph export "$Results/Figures/temp/T-stat_RI_MuniNoControls.pdf", name(Graph) replace	
	 

	 
	 
********************************************************************************
********************************************************************************
*******************			AT REGIMENT LEVEL
*** Take these to randomly reallocate BR to Reg Number at data construction stage***********
********************************************************************************

use "$Data_generated/analysis_dataset.dta", clear
keep id_geofla   lncollabospc  verdun   $lpretrends_nomiss $precontrols_nomiss id_bureau RI_number code_dep  
ren RI_number RI_number_true
ren id_bureau id_bureau_true

save "$Data_generated/temp/Main_forRI.dta", replace 

use "$Data_generated/temp/id_geofla_to_BR.dta", clear
merge m:1 id_bureau using "$Data_generated/temp/BR_to_RI.dta"
drop if _merge!=3
cap drop _merge

* merge to main dep var and control variables: 
merge 1:1 id_geofla using  "$Data_generated/temp/Main_forRI.dta"
drop if _merge!=3
cap drop _merge


gen RI_number =  regimentnew 

tab RI_number 

* merge to battle history
merge m:1 RI_number  using "$Data_generated/regimentsVerdun.dta", gen(mergeRegimentNew)
drop if mergeRegimentNew==2 

keep id_bureau*  id_geofla id_bureau regimentnew-regimentnew13 RI_number  verdun_petain mergeRegimentNew  lncollabospc  verdun   $lpretrends_nomiss $precontrols_nomiss  RI_number* code_dep  

foreach x in RI_number verdun_petain {
ren `x' `x'_1
}

foreach x in RI_number verdun_petain {
gen `x'_main = `x'_1
label var `x'_main "`x' for first regiment matched"
}

foreach z in 2 3 4 5 6 7 8 9 10 11 12 13 {
gen RI_number =  regimentnew`z' 
* merge to battle history
merge m:1 RI_number  using "$Data_generated/regimentsVerdun.dta", gen(mergeRegimentNew`z')
drop if mergeRegimentNew`z'==2 
keep id_bureau*  id_geofla id_bureau regimentnew* RI_number*  verdun_petain* mergeRegimentNew* lncollabospc  verdun   $lpretrends_nomiss $precontrols_nomiss  RI_number* code_dep 

drop mergeRegimentNew*
foreach x in RI_number verdun_petain {
ren `x' `x'_`z'
}
}

save "$Data_generated/temp/DataforRI.dta", replace 

* compute average exposure ****** RANDOMIZE EXPOSURE HERE for all the regiments that a municipality is potentially matched to (i.. regimentnew to regimentnew13) *********

g rpl=.

g beta=.
g se=.

forvalues i=1(1)13 {
tab verdun_petain_`i'
g rpl`i'=.
}


set seed 98761256
forvalues j=1(1)1000{
g rd1= runiform()
g fakeverdun_petain1 = .
replace fakeverdun_petain1 = 0 if rd<=0.511
replace fakeverdun_petain1 = 1 if rd>0.511

replace rpl1 = `j' in `j'

g fakeverdun_petain2 = .
replace fakeverdun_petain2 = 0 if rd<=-0.2635
replace fakeverdun_petain2 = 1 if rd>0.2635

replace rpl2 = `j' in `j'

g fakeverdun_petain3 = .
replace fakeverdun_petain3 = 0 if rd<=-0.5519
replace fakeverdun_petain3 = 1 if rd>0.5519

replace rpl3 = `j' in `j'

g fakeverdun_petain4 = .
replace fakeverdun_petain4 = 0 if rd<=-0.4932
replace fakeverdun_petain4 = 1 if rd>0.4932

replace rpl4 = `j' in `j'

g fakeverdun_petain5 = .
replace fakeverdun_petain5 = 0 if rd<=-0.3059
replace fakeverdun_petain5 = 1 if rd>0.3059

replace rpl3 = `j' in `j'

g fakeverdun_petain6 = .
replace fakeverdun_petain6 = 0 if rd<=-0.5656
replace fakeverdun_petain6 = 1 if rd>0.5656

replace rpl3 = `j' in `j'

g fakeverdun_petain7 = .
replace fakeverdun_petain7 = 0 if rd<=-0.7647
replace fakeverdun_petain7 = 1 if rd>0.7647

replace rpl7 = `j' in `j'

g fakeverdun_petain8 = .
replace fakeverdun_petain8 = 0 if rd<=-0.3120
replace fakeverdun_petain8 = 1 if rd>0.3120

replace rpl8 = `j' in `j'

g fakeverdun_petain9 = .
replace fakeverdun_petain9 = 0 if rd<=-0.3088
replace fakeverdun_petain9 = 1 if rd>0.3088

replace rpl9 = `j' in `j'

foreach x in fakeverdun_petain {
egen `x'=rowmean (`x'1 `x'2 `x'3 `x'4 `x'5 `x'6 `x'7 `x'8  `x'9)
}

quietly:  areg  lncollabospc fakeverdun_petain verdun  $lpretrends_nomiss $precontrols_nomiss ,  cl(id_bureau_true)  absorb(code_dep) 

replace beta = _b[fakeverdun_petain] in `j'
replace se = _se[fakeverdun_petain] in `j'

drop rd fakeverdun_petain* 
}

keep rpl beta* se* 
drop if beta==.
g t = beta/se

compress
label variable rpl `"Replication Number"'
label variable beta `"Coefficient from Fake V-u-P"'
label variable se `"Standard Error of the Coefficient from Fake V-u-P"'
label variable t `"t-value from Fake V-u-P"'

histogram beta, xline(0.067) percent xtitle("Coefficient on Fake V-u-P") xlabel(-0.10(0.02)0.10)  xscale(range(-0.10 0.10)) title (Full controls)  scheme(s1mono)

	graph save  "$Results/Figures/temp/Coeff_RI_Depfullcontrols.gph",  replace	
	graph export "$Results/Figures/temp/Coeff_RI_Depfullcontrols.pdf", name(Graph) replace	

histogram t, xline(3.69) percent xtitle("t-stat on Fake V-u-P")  xscale(range(-6  6)) xlabel(-6(2)6)    title (Full controls)  scheme(s1mono)
	graph save  "$Results/Figures/temp/tstat_RI_Depfullcontrols.gph",  replace	
	graph export "$Results/Figures/temp/tstat_RI_Depfullcontrols.pdf", name(Graph) replace	


**************************
** RI w/o controls **
**************************
 
  use "$Data_generated/analysis_dataset.dta", clear
  areg  lncollabospc  verdun_petain verdun  ,  cl(id_bureau)  absorb(code_dep) 
  
  
  use  "$Data_generated/temp/DataforRI.dta", clear 

  g rpl=.

g beta=.
g se=.

forvalues i=1(1)13 {
tab verdun_petain_`i'
g rpl`i'=.
}

set seed 98761256
forvalues j=1(1)1000{
g rd1= runiform()
g fakeverdun_petain1 = .
replace fakeverdun_petain1 = 0 if rd<=0.511
replace fakeverdun_petain1 = 1 if rd>0.511

replace rpl1 = `j' in `j'

g fakeverdun_petain2 = .
replace fakeverdun_petain2 = 0 if rd<=-0.2635
replace fakeverdun_petain2 = 1 if rd>0.2635

replace rpl2 = `j' in `j'

g fakeverdun_petain3 = .
replace fakeverdun_petain3 = 0 if rd<=-0.5519
replace fakeverdun_petain3 = 1 if rd>0.5519

replace rpl3 = `j' in `j'

g fakeverdun_petain4 = .
replace fakeverdun_petain4 = 0 if rd<=-0.4932
replace fakeverdun_petain4 = 1 if rd>0.4932

replace rpl4 = `j' in `j'

g fakeverdun_petain5 = .
replace fakeverdun_petain5 = 0 if rd<=-0.3059
replace fakeverdun_petain5 = 1 if rd>0.3059

replace rpl3 = `j' in `j'

g fakeverdun_petain6 = .
replace fakeverdun_petain6 = 0 if rd<=-0.5656
replace fakeverdun_petain6 = 1 if rd>0.5656

replace rpl3 = `j' in `j'

g fakeverdun_petain7 = .
replace fakeverdun_petain7 = 0 if rd<=-0.7647
replace fakeverdun_petain7 = 1 if rd>0.7647

replace rpl7 = `j' in `j'

g fakeverdun_petain8 = .
replace fakeverdun_petain8 = 0 if rd<=-0.3120
replace fakeverdun_petain8 = 1 if rd>0.3120

replace rpl8 = `j' in `j'

g fakeverdun_petain9 = .
replace fakeverdun_petain9 = 0 if rd<=-0.3088
replace fakeverdun_petain9 = 1 if rd>0.3088

replace rpl9 = `j' in `j'

foreach x in fakeverdun_petain {
egen `x'=rowmean (`x'1 `x'2 `x'3 `x'4 `x'5 `x'6 `x'7 `x'8  `x'9)
}

quietly:  areg  lncollabospc fakeverdun_petain verdun ,  cl(id_bureau_true)  absorb(code_dep) 

replace beta = _b[fakeverdun_petain] in `j'
replace se = _se[fakeverdun_petain] in `j'

drop rd fakeverdun_petain* 
}

keep rpl beta* se* 
drop if beta==.
g t = beta/se

  compress
label variable rpl `"Replication Number"'
label variable beta `"Coefficient from Fake V-u-P"'
label variable se `"Standard Error of the Coefficient from Fake V-u-P"'
label variable t `"t-value from Fake V-u-P"'

histogram beta, xline(0.0737) percent xtitle("Coefficient on Fake V-u-P") xlabel(-0.10(0.02)0.10)  xscale(range(-0.10 0.10)) title (No controls)  scheme(s1mono) 
	graph save  "$Results/Figures/temp/Coeff_RI_DepNocontrols.gph",  replace	
	graph export "$Results/Figures/temp/Coeff_RI_DepNocontrols.pdf", name(Graph) replace	

histogram t, xline(1.78) percent xtitle("t-stat on Fake V-u-P")  xscale(range(-6  6)) xlabel(-6(2)6)   title (No controls)  scheme(s1mono)
	graph save  "$Results/Figures/temp/tstat_RI_DepNocontrols.gph",  replace	
	graph export "$Results/Figures/temp/tstat_RI_DepNocontrols.pdf", name(Graph) replace	

**************************
** Combine graphs **
**************************
 	
graph combine "$Results/Figures/temp/Coeff_RI_DepNocontrols.gph"  "$Results/Figures/temp/Coeff_RI_Depfullcontrols.gph"  "$Results/Figures/temp/Coeff_RI_MuniNoControls.gph"  "$Results/Figures/temp/Coeff_RI_MuniControls.gph"  , title("Permutation at Regiment (top) or Municipal (bottom) level: Coefficients", size(small))  scheme(s1mono) 
 	graph save  "$Results/Figures/FigureA8.gph",  replace	
	graph export "$Results/Figures/FigureA8.pdf", name(Graph) replace	
    graph export "$Results/Figures/FigureA8.jpg", name(Graph) replace  

graph combine "$Results/Figures/temp/tstat_RI_DepNocontrols.gph"  "$Results/Figures/temp/tstat_RI_Depfullcontrols.gph" "$Results/Figures/temp/T-stat_RI_MuniNoControls.gph"  "$Results/Figures/temp/T-stat_RI_MuniControls.gph"  , title("Permutation at Regiment (top) or Municipal (bottom) level: t-stat", size(small))  scheme(s1mono) 
	graph save  "$Results/Figures/FigureA9.gph",  replace	
	graph export "$Results/Figures/FigureA9.pdf", name(Graph) replace	
	graph export "$Results/Figures/FigureA9.jpg", name(Graph) replace  
}
	
	
	


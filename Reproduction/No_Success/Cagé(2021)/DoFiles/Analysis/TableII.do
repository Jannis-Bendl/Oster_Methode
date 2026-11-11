
use "$Data_generated/analysis_dataset.dta", clear 
encode code_dept, gen (code_dept_num)
gen unique_arr = code_dept_num*100+ code_arr
	

********************************************************************************
* TABLE II:  1914
********************************************************************************	
foreach var of varlist shSFIO_14 shREPSOC_14 shRADSOC_14 shRADIND_14 shPRDS_14 shProgressistes_14 shALP_14 {
	capture drop l`var'
	gen l`var'=ln(`var')
	}
	
label var lshSFIO_14 "SFIO"
label var lshREPSOC_14 "REP-SOC"
label var lshRADSOC_14 "RAD-SOC"
label var lshRADIND_14 "RAD-INC"
label var lshPRDS_14  "PRDS"
label var lshProgressistes_14 "Progressistes"
label var lshALP_14 "ALP"

set more off
eststo clear
foreach p in SFIO RADSOC RADIND PRDS Progressistes ALP {
	su sh`p'_14
	gen D2Run`p'_14=(DRun`p'_14>0 & DRun`p'_14<99999)
	eststo: xi: reghdfe  lsh`p'_14 verdun_petain verdun $precontrols_nomiss i.D2Run`p'_14 , cl(id_bureau unique_arr) absorb(code_dept) 
 		estadd local Verdun "\checkmark", replace 
		estadd local Pop "\checkmark", replace 
 		estadd local PreTrends "NA", replace
		estadd ysumm		
		estadd scalar clusters = e(N_clust)	
	}
esttab using "$Results/Tables/TableII.tex", replace ///
	keep(verdun_petain  ) /// 
	coeflabels(verdun_petain "Verdun under P\'{e}tain" ) ///
	nogap ///
	cells(b(fmt(%15.3fc)) se(par fmt(%15.3fc))) ///
	stats( Verdun Pop PreTrends  r2 N ymean ysd clusters, fmt(  0 0 0 %9.2f %15.0fc %15.2fc %15.2fc %15.0fc) labels( "Verdun" "1911 pop" "Pre-WWI vote shares"  "R-squared" "Observations" "Mean DepVar" "Sd DepVar" "Number of clusters")) ///
	collabels(none) label ///
	mgroups("Left" "Center Left" "Center Right" "Right",  pattern(1 1 0 1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					

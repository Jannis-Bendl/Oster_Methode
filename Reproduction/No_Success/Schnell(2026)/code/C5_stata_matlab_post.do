
cap log close _all
log using log/C5_stata_matlab_post.log, replace

***********************************************************************
*----------------------- PROCESS MATLAB RESULTS ----------------------* 
***********************************************************************

/*----------------------------- OVERVIEW -----------------------------*

This .do file produces the following files: 

    FIGURES
	- Figure A25(a,b,c): counterfactuals under alternative revenue assumptions 
	- Figure A26(a,b,c): counterfactuals in alternative markets
	- Figure A27: overprescribing versus opioids per capita across markets
	
Erases intermediate files at end
     
*--------------------------------------------------------------------*/

*---------------------------------------------------------------------*
*------------------------ Define Directories -------------------------*
*---------------------------------------------------------------------*

	do C00_stata_setup.do
	
*---------------------------------------------------------------------*
*------------------------------ Settings -----------------------------*
*---------------------------------------------------------------------*

	* Main colors (https://www.northwestern.edu/brand/visual-identity/color/)
	local colord = "025 008 065"
	local colorm = "118 093 160"
	local colorl = "204 196 223"
	
	* Extra colors (for maps)
	local colormd = "078 042 132"
	local colorml = "182 172 209"
	local colorvl = "228 224 238"
		
	tempfile main
	
	local pres_nosm_color 		"colorml"
	local pres_nosm_ytitle 		"Change in opioid prescribing (%)"
	local pres_nosm_range 		"0(10)50"
	local pres_nosm_file 		"a"
	
	local pres_noop_color 		"colorml"
	local pres_noop_ytitle 		"Change in opioid prescribing (%)"
	local pres_noop_range 		"-100(20)0"
	local pres_noop_file 		"b"
	
	local health_both_color 	"colorm"
	local health_both_ytitle 	"Change in health impacts (billions \$)"
	local health_both_file 		"c"
	
***********************************************************************
*------------------------------ FIGURES ------------------------------* 
***********************************************************************

*----------------------------- Figure A25 ----------------------------*

import excel "${inter}/output_CF_altR.xlsx", clear

	rename A R
	rename B pres_nosm
	rename C pres_noop
	rename D health_both
	
	*---------- Prescriptions ----------*
	*---------- Health impacts ---------*

	local health_both_range "0(5)15"
	
	foreach type in pres_nosm pres_noop health_both {
			
		twoway (bar `type' R, barw(0.05) fcolor("```type'_color''") lcolor(none) yline(0, lcolor(gs0)) ///
			xsize(7) xtitle("Office visit reimbursement (R*x)", size(5)) ///
			xlab(0.5 "*0.5" 0.75 "*0.75" 0.9 "*0.9" 1 "R" 1.1 "*1.1" 1.25 "*1.25" 1.5 "*1.5", labsize(4)) ///
			xscale(range(0.4 1.6) titlegap(2.5)) ///
			ytitle("``type'_ytitle'", size(5)) ylab(``type'_range', labsize(4)) yscale(titlegap(2.5)) ///
			legend(off) graphregion(color(white)))
		graph export "${results}/Figure_A25``type'_file'.eps", replace
	}

*----------------------------- Figure A26 ----------------------------*

import excel "${inter}/output_CF_altmkts.xlsx", clear

	rename A czone
	rename B pres_nosm
	rename C pres_noop
	rename D health_both
	
	merge 1:1 czone using "${inter}/markets_chars.dta", nogen keep(matched) ///
		keepusing(distance pres_pc n)
	
	* Order by distance (Figure A9)
	sort distance 
	gen order = _n
	
	*---------- Prescriptions ----------*
	*---------- Health impacts ---------*

	local health_both_range "0(5)20"
	
	foreach type in pres_nosm pres_noop health_both {
	
		twoway (bar `type' order, barw(0.5) fcolor("```type'_color''") lcolor(none) yline(0, lcolor(gs0)) ///
			xsize(7) xtitle("", size(4.5)) xscale(range(0.5 6.5) titlegap(2.5)) ///
			xlab(1 "Seattle" 2 "Los Angeles" 3 "Stamford" 4 "Phoenix" 5 "Chicago" 6 "New York", labsize(5)) ///
			ytitle("``type'_ytitle'", size(5)) ylab(``type'_range', labsize(4)) yscale(titlegap(2.5)) ///
			legend(off) graphregion(color(white)))
		graph export "${results}/Figure_A26``type'_file'.eps", replace
	}
	
*----------------------------- Figure A27 ----------------------------*

	replace pres_noop = pres_noop*-1
	corr pres_noop pres_pc
	twoway (scatter pres_noop pres_pc, mcolor("`colorml'") msize(3)) ///
	       (lfit pres_noop pres_pc, lcolor("`colormd'") lwidth(1) ///
		xlab(0.1(0.05)0.3, labsize(4))  xtitle("Opioid prescriptions from GPs per capita", size(5)) xscale(titlegap(2.5)) ///
		ylab(0(10)70, labsize(4)) ytitle("Overprescribing by GPs (%)", size(5)) yscale(titlegap(2.5)) ///
		legen(off) graphregion(color(white)))
	graph export "${results}/Figure_A27.eps", replace
	
***********************************************************************
*---------------------- ERASE INTERMEDIATE FILES ---------------------* 
***********************************************************************

local files : dir "${inter}" files "*"

	foreach f of local files {
		erase "${inter}/`f'"
	}

***********************************************************************

log close


	

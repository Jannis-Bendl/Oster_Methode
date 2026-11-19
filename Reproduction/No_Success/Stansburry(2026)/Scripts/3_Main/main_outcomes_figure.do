*******************************************************************************
* Main outcomes Figure 
**Compares all outcomes directly based on percentage difference from means
*******************************************************************************

*******************************************************************************
*This code creates:
*table1_figure.pdf
*******************************************************************************

*Load and append Main Outcomes regression results for:
	* Tenure anywhere
	* Tenure at R1
	* Tenure Rank
	* TT Anywhere
	* TT at R1
	* TT Rank
	* Got Tenure


use "$TEMP/e_TENURE_WTSURVY", clear
keep var coef stderr
g depvar_h="Tenure anywhere"

append using "$TEMP/e_TEN_R1_WTSURVY"
replace depvar_h="Tenure at R1" if missing(depvar_h)
keep var depvar_h coef stderr 

append using "$TEMP/e_TENLOGRANK_WTSURVY"
replace depvar_h="Tenure Rank" if missing(depvar_h)
keep var depvar_h coef stderr 

append using "$TEMP/e_TENURETRACK_WTSURVY"
replace depvar_h="TT Anywhere" if missing(depvar_h)
keep var depvar_h coef stderr 

append using "$TEMP/e_TT_R1_WTSURVY"
replace depvar_h="TT at R1" if missing(depvar_h)
keep var depvar_h coef stderr

append using "$TEMP/e_TTLOGRANK_WTSURVY"
replace depvar_h="TT Rank" if missing(depvar_h)
keep var depvar_h coef stderr 

append using "$TEMP/e_GOT_TENURE_NEXTYR_WTSURVY"
replace depvar_h="Got Tenure" if missing(depvar_h)
keep var depvar_h coef stderr 

rename depvar_h depvar

*Rename vars and keep only relevant parental education coefficients
rename var indepvar
keep if indepvar=="1.edpar_n" | indepvar=="2.edpar_n" | indepvar=="4.edpar_n"
replace indepvar="Less than college" if indepvar=="1.edpar_n" 
replace indepvar="College" if indepvar=="2.edpar_n" 
replace indepvar="PhD" if indepvar=="4.edpar_n" 

order depvar indepvar coef stderr

* Create point estimate at 0 for each outcome for reference category (College Educated Parents) 
preserve 
keep depvar
duplicates drop
gen indepvar = "Non-PhD Grad Degree"
gen  coef = 0
gen stderr = 0
tempfile newrows
save `newrows'
restore

append using `newrows'
sort depvar indepvar

*Generate different levels of confidence intervals
g lb_95 = coef - 1.96*stderr
g ub_95 = coef + 1.96*stderr

* NUmerical values for categorical labels
encode depvar, gen(depvar_n)
gen indepvar_n = 1 if indepvar=="Less than college"
replace indepvar_n = 2 if indepvar=="College"
replace indepvar_n = 3 if indepvar=="Non-PhD Grad Degree"
replace indepvar_n = 4 if indepvar=="PhD"

* Graph order
gen n = 1 if indepvar_n == 4
replace n = 2 if indepvar_n == 3
replace n = 3 if indepvar_n == 2
replace n = 4 if indepvar_n == 1

* Create separate subgraphs for each dependent variable
levelsof depvar, local(depvars)
foreach depvar of local depvars{
	
	* X Axis Scale Options:
	if "`depvar'"=="Tenure Rank" | "`depvar'"=="TT Rank" {
		local xopts xsc(r(-0.23 0.2)) xlabel(-0.2 (0.1) 0.2, labsize(small)) xtitle("")
		local titleopts (conditional on PhD)
	}
	
	if "`depvar'"=="Got Tenure" {
		local xopts xtitle("{bf: vs. person w/parent}" "{bf: w/ non PhD grad degree}", size(small)) xsc(r(-0.5 0.5)) xlabel(-0.5 (0.2) 0.5, labsize(small))
		local titleopts (conditional on TT inst)
	}
	
	if "`depvar'"=="Tenure anywhere" {
		local xopts xsc(r(-0.025 0.025)) xlabel(-0.02 (0.01) 0.02, labsize(small)) xtitle("")
		local titleopts (conditional on PhD)
	}
	
	if "`depvar'"=="TT Anywhere" {
		local xopts xsc(r(-0.05 0.05)) xlabel(-0.05 (0.02) 0.05, labsize(small)) xtitle("")
		local titleopts (conditional on PhD)
	}
	
	if "`depvar'"=="Tenure at R1" {
		local xopts xsc(r(-0.03 0.03)) xlabel(-0.03 (0.01) 0.03, labsize(small)) xtitle("")
		local titleopts (conditional on PhD)
	}
	
	if "`depvar'"=="TT at R1" {
		local xopts xsc(r(-0.1 0.1)) xlabel(-0.1 (0.05) 0.1, labsize(small)) xtitle("")
		local titleopts (conditional on PhD)
	}
	
	* Graph
	local color1 cranberry
	local color2 dkorange
	local color3 black
	local color4 purple
	local cond & depvar=="`depvar'"
	local options horizontal ylab(1/3, val angle(0))
	twoway ///
		(rspike lb_95 ub_95 n if indepvar_n == 1 `cond', lwidth(medthick) lcolor(`color1'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n == 2 `cond', lwidth(medthick) lcolor(`color2'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n == 3 `cond', lwidth(medthick) lcolor(`color3'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n == 4 `cond', lwidth(medthick) lcolor(`color4'%80) `options') ///
		(scatter n coef if indepvar_n == 1 `cond', msymbol(O) mcolor(`color1') xline(0) msize(medlarge)) ///
		(scatter n coef if indepvar_n == 2 `cond', msymbol(O) mcolor(`color2') xline(0) msize(medlarge)) ///
		(scatter n coef if indepvar_n == 3 `cond', msymbol(O) mcolor(`color3') xline(0) msize(medlarge)) ///
		(scatter n coef if indepvar_n == 4 `cond', msymbol(O) mcolor(`color4') xline(0) msize(medlarge)) ///
		, ytitle("") ysc(r(0.8 3.2)) ylabel(1 "PhD" 2.2 "Non-PhD" 1.9 "Grad Degree" 3 "College" 4.2 "Less than" 3.9 "college", nogrid noticks labsize(small)) ///
		legend(off) title("{bf: `depvar'}" "`titleopts'", size(small)) `xopts' xsize(3) ysize(2)
	graph save "$figures/temp/temp_`depvar'.gph", replace
	
}

* Combine into a single figure:
twoway scatteri 1 1, 			///
		msymbol(i) 				///
		ylab("") xlab("")		///
		ytitle("") xtitle("") 	///
		yscale(off) xscale(off) ///
		plotregion(lpattern(blank))
		
graph save "$figures/temp/placeholder1.gph", replace
graph save "$figures/temp/placeholder2.gph", replace
	
graph combine "$figures/temp/temp_Tenure anywhere.gph" "$figures/temp/temp_Tenure at R1.gph" "$figures/temp/temp_Tenure Rank.gph" "$figures/temp/temp_TT Anywhere.gph" "$figures/temp/temp_TT at R1.gph" "$figures/temp/temp_TT Rank.gph" "$figures/temp/placeholder1.gph"  "$figures/temp/temp_Got Tenure.gph" "$figures/temp/placeholder2.gph" , imargin(zero) cols(3) xsize(10) ysize(10)

graph export "$figures/main_outcomes_figure.pdf", replace


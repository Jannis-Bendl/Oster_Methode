*******************************************************************************
**Coefplot panel of outcomes
*******************************************************************************

*Load and append Table 1 regression results
use "$TEMP/r0_GOT_TENURE_NEXTYR_WTSURVY", clear
keep var coef stderr
g rcontrols = "None"

append using "$TEMP/r1_GOT_TENURE_NEXTYR_WTSURVY"
keep var coef stderr rcontrols
replace rcontrols = "1" if missing(rcontrols)

append using "$TEMP/r2_GOT_TENURE_NEXTYR_WTSURVY"
keep var coef stderr rcontrols
replace rcontrols = "2" if missing(rcontrols)
g depvar="Got Tenure"

append using "$TEMP/r0_LOGRANK_WTSURVY"
keep var coef stderr rcontrols depvar
replace rcontrols = "None" if missing(rcontrols)

append using "$TEMP/r1_LOGRANK_WTSURVY"
keep var coef stderr rcontrols depvar
replace rcontrols = "1" if missing(rcontrols)

append using "$TEMP/r2_LOGRANK_WTSURVY"
keep var coef stderr rcontrols depvar
replace rcontrols = "2" if missing(rcontrols)

replace depvar="Tenure Log Rank" if depvar=="LOGRANK"

*Rename vars and keep only relevant parental education coefficients
rename var indepvar
keep if indepvar=="1.edpar_n" | indepvar=="2.edpar_n" | indepvar=="3b.edpar_n"| indepvar=="4.edpar_n"
replace indepvar="Less than college" if indepvar=="1.edpar_n" 
replace indepvar="College" if indepvar=="2.edpar_n"
replace indepvar="Non-PhD Grad Degree" if indepvar=="3b.edpar_n" 
replace indepvar="PhD" if indepvar=="4.edpar_n" 

*Generate different levels of confidence intervals
g lb_95 = coef - 1.96*stderr
g ub_95 = coef + 1.96*stderr

encode depvar, gen(depvar_n) label(depvar_lbl)
gen indepvar_n = 1 if indepvar=="Less than college"
replace indepvar_n = 2 if indepvar=="College"
replace indepvar_n = 3 if indepvar=="Non-PhD Grad Degree"
replace indepvar_n = 4 if indepvar=="PhD"

* Generate code order
gen n = indepvar_n
replace n = indepvar_n + 0.25 if rcontrols=="2"
replace n = n*4 
replace n = 15-n 
sort n 

* Encode research controls and only keep full controls
gen rnum = 1 if rcontrols=="None"
replace rnum=2 if rcontrols =="2"
drop if mi(rnum)

* Loop subgraphs over dependent variables
levelsof depvar,local(depvars)
foreach depvar of local depvars{
	
	if "`depvar'"=="Tenure Log Rank" {
		local xopts xsc(r(-1 1)) xlabel(-1 (0.5) 1, labsize(large))
		local titleopts (conditional on PhD)
	}
	else {
		local xopts xsc(r(-1.5 1)) xlabel(-2 (0.5) 1, labsize(large))
		local titleopts (conditional on TT inst)
	}
	
	local cond & depvar=="`depvar'"
	local color1 cranberry 
	local color2 dkorange
	local color3 black
	local color4 purple
	local maxorder 14
	local options horizontal ylab(1/`maxorder', val angle(0))
	twoway ///
		(rspike lb_95 ub_95 n if indepvar_n==1 & rnum==1 `cond', lwidth(medthick) lcolor(`color1'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==2 & rnum==1 `cond', lwidth(medthick) lcolor(`color2'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==3 & rnum==1 `cond', lwidth(medthick) lcolor(`color3'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==4 & rnum==1 `cond', lwidth(medthick) lcolor(`color4'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==1 & rnum==2 `cond', lpattern(dash) lwidth(medthick) lcolor(`color1'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==2 & rnum==2 `cond', lpattern(dash) lwidth(medthick) lcolor(`color2'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==3 & rnum==2 `cond', lpattern(dash) lwidth(medthick) lcolor(`color3'%80) `options') ///
		(rspike lb_95 ub_95 n if indepvar_n==4 & rnum==2 `cond', lpattern(dash) lwidth(medthick) lcolor(`color4'%80) `options') ///
		(scatter n coef if indepvar_n==1 `cond', mcolor(`color1') msymbol(O) msize(medium) xline(0)) ///
		(scatter n coef if indepvar_n==2 `cond', mcolor(`color2') msymbol(O) msize(medium) xline(0)) ///
		(scatter n coef if indepvar_n==3 `cond', mcolor(`color3') msymbol(O) msize(medium) xline(0)) ///
		(scatter n coef if indepvar_n==4 `cond', mcolor(`color4') msymbol(O) msize(medium) xline(0)) ///
		,xtitle("Class gap relative to someone" "with parent with non-PhD grad degree", size(medium)) ///
		legend(region(lstyle(solid)) order( - "{bf:Solid:} Baseline" - "{bf:Dashed:} With Research Controls") size(medlarge) ///
		pos(6) cols(3)) `xopts' ylabel(-1 "PhD" 3 "Non-PhD" 2.1 "Grad Degree" 7 "College" 11 "Less than" 10.3 "college", labsize(large) noticks nogrid) ysc(r(1 12)) ///
		ylabel(,labsize(large)) ytitle("") title("{bf: `depvar'}" "`titleopts'" , size(large))
	
	graph save "$figures/temp/temp_`depvar'.gph", replace

}

grc1leg "$figures/temp/temp_Tenure Log Rank.gph" "$figures/temp/temp_Got Tenure.gph", legend("$figures/temp/temp_Got Tenure.gph")

graph export "$figures/tenure_withresearch_update.pdf", replace

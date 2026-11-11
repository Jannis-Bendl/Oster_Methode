*------------------------------------------------------------------------
* Generate County Characteristics Table using ACS Data
* Created by: Elise Parrish (April 13, 2020)
* Modified by: Jerray Chang <jerray@uchicago.edu>
* Last Updated: February 22nd, 2021
*
* Note: 	To run, use the following make command:
*			make 04analysis ARGS="runCountyChars" SAMPLE="SampleSelection6" OPTS_FOLDER="BaselineStuff-take4" TAG="BaselineStuff_countyChars" &
*			To debug at the 1pct level, use this make command:
*			make 04analysis ARGS="runCountyChars" SAMPLE="SampleSelection6" OPTS_FOLDER="BaselineStuff-take4" TAG="BaselineStuff_countyChars_1pct" &

* Depends:	>
* 			./00common/00preamble.do
* 				global out
*			${out}/fig/term_map.dta (created by 05full-sample/04analysis/Run/Figures/term_map.do)
* 			${out}/tables/ACS_tab.dct	(from Elise's dropbox folder; originally ACS 2011-2015 5-yr estimates from Social Explorer: https://www.socialexplorer.com/tables/ACS2015_5yr/R12518954)
*			${out}/tables/ACS_tab.txt	(from Elise's dropbox folder; originally ACS 2011-2015 5-yr estimates from Social Explorer: https://www.socialexplorer.com/tables/ACS2015_5yr/R12518954)
*
* Output:	>
* 			${out}/tables/`pre'tableA1_`pct'pct.tex
*
*          where ${pct} is one of 01 or 100. ${pre} is either blank or the sample prefix, as applicable.
*------------------------------------------------------------------------

* To run on it's own, assuming you have correct term_map.dta,
* ACS_tab.dct, and ACS_tab.txt, uncomment this section)

* Setup (for independent run only)
* local 0: subinstr local 0 ";" ","
* syntax, pre(str) pct(str)
* qui do "00common/00preamble.do"
* // end of setup (for independent run only)

cap mkdir `"${out}/tables"'

/*============================================================================
						define storage program
 ============================================================================*/

capture program drop store_est
program define store_est, rclass
	args var

	local mean  = string(`r(mean)', "%10.0fc")
	local mean2 = string(`r(mean)', "%10.2fc")
	local obs   = string(`r(N)',    "%10.0fc")

	return local m  = "`mean'"
	return local m2 = "`mean2'"
	return local N  = "`obs'"
end

/*============================================================================
						Load and prepare termination data
 ============================================================================*/

local terms `"${out}/fig/term_map.dta"'

/*============================================================================
						Load and prepare ACS (5-year) Data
 ============================================================================*/
clear
qui infile using "${data}/ACS_tab.dct" , using("${data}/ACS_tab.txt")

#delimit ;
keep FIPS NAME UR GEOID A00001_001 A00002_001 A00002_002 A00002_003 A01001_001
A01001_010 A01001_012 A01001_013 A03001_001 A03001_002 A03001_003 A03001_004
 A03001_005 A03001_006 A03001_007 A03001_008 A12001_002 A12001_003 A12001_004
 A12001_005 A12001_006 A12001_007 A12001_008 A14006_001 A20001_001 A20001_002
 A20001_003 A20001_004 A20002_022 A20002_023 A20002_024 A20002_025 A20002_026
;
#delimit cr
tab FIPS
ren FIPS fipscounty
ren A00001_001 pop
ren A00002_002 pop_density
ren A14006_001 med_inc
ren A20002_022 pop_ovr65
ren A03001_002 white_pop
ren A03001_003 black_pop
ren A03001_005 asian_pop
ren A03001_004 native_pop
ren A03001_006 pacific_pop
ren A03001_007 other_pop
ren A03001_008 more1_pop

merge 1:1 fipscounty using `"`terms'"', keep(3) nogen
drop NAME

// Generate variables
gen pct_ovr65  = (pop_ovr65 /pop) * 100
gen pct_ma     = (num_bene_lag 			   / pop) * 100
gen pct_ma12   = (num_bene_12min_lag 	   / pop) * 100
gen pct_dual   = (num_bene_eDual_lag 	   / num_bene_lag) * 100
gen pct_dual12 = (num_bene_eDual_12min_lag / num_bene_12min_lag) * 100
gen pct_white  = (white_pop / pop) * 100
gen pct_black  = (black_pop / pop) * 100
gen pct_asian  = (asian_pop / pop) * 100

gegen bene = sum(num_bene_lag), by(has_term)

/*============================================================================
						Calculate and store
 ============================================================================*/

foreach var of varlist pop bene pop_density med_inc pct_ovr65 pct_ma pct_dual pct_white pct_black pct_asian{
	summ `var' if has_term==0
	store_est `var'
	local `var'_0   = "`r(m)'"
	local `var'_0d  = "`r(m2)'"
	local N_`var'_0 = "`r(N)'"

	summ `var' if has_term==1
	store_est `var'
	local `var'_1   = "`r(m)'"
	local `var'_1d  = "`r(m2)'"
	local N_`var'_1 = "`r(N)'"
}

foreach var of varlist pop pop_density med_inc pct_ovr65 pct_ma12 pct_dual12 pct_white pct_black pct_asian {
	summ `var' if has_term12==0
	store_est `var'
	local `var'_0_12   = "`r(m)'"
	local `var'_0_12d  = "`r(m2)'"
	local N_`var'_0_12 = "`r(N)'"

	summ `var' if has_term12==1
	store_est `var'
	local `var'_1_12   = "`r(m)'"
	local `var'_1_12d  = "`r(m2)'"
	local N_`var'_1_12 = "`r(N)'"
}

/*============================================================================
						Write File
 ============================================================================*/

capture erase `"${out}/tables/`pre'tableA1_`pct'pct.tex"'
file open balance using `"${out}/tables/`pre'tableA1_`pct'pct.tex"', write replace
local table "balance"

#delimit ;
file write `table'
	"\begin{table}[h]" _n
	"\begin{center}" _n
	"\caption{\label{tab:county_balance}County Characteristics}" _n
	"\begin{tabular}{l cc }" _n
	"\toprule" _n
	"\mc{\multirow[c]{1}{*}{ \centering }}& \mc{\multirow[c]{1}{3cm}{ \centering No Terminations}} & \mc{\multirow[c]{1}{3cm}{ \centering Terminations}} \\" _n
	"\midrule" _n
;
file write `table'
	"Median Income & \mc{`med_inc_0'} & \mc{`med_inc_1'} \\ " _n
	"\% of Pop $>$65 & `pct_ovr65_0d' & `pct_ovr65_1d' \\" _n
	"\% Dual & `pct_dual_0d' &  `pct_dual_1d' \\" _n
	"\% White & `pct_white_0d' &  `pct_white_1d' \\" _n
	"\% Black & `pct_black_0d' &  `pct_black_1d' \\" _n
	"\% Asian & `pct_asian_0d' &  `pct_asian_1d' \\" _n
	"Population & \mc{`pop_0'} & \mc{`pop_1'} \\" _n
	"Population Density & \mc{`pop_density_0'} & \mc{`pop_density_1'} \\" _n
	"\midrule" _n
	"Counties & \mc{`N_pop_0'} & \mc{`N_pop_1'} \\" _n
	"Number of Beneficiaries &  \mc{`bene_0'} & \mc{`bene_1'} \\" _n
;
file write `table'
	"\bottomrule" _n
	"\end{tabular} " _n
	"\end{center}" _n
	"{\footnotesize{}Notes: This table compares the demographics of counties with and without terminations, using data taken from the 2007-2011 American Community Survey (ACS). Population density is calculated as population per square mile. Percentage of population >65 and race percentages are calculated using total population as the denominator. Percent dual eligible uses number of beneficiaries as the denominator. }\tabularnewline" _n
	"{\footnotesize\par}" _n
	"\end{table}" _n
;

#delimit cr

file close `table'

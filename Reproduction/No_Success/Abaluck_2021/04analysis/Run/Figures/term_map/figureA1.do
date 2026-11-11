*------------------------------------------------------------------------
* Generate County Choropleth Map for Number of Terminations
* Original code by: Elise Parrish
* Modified by: Jerray Chang
* Created: before June 22, 2020
* Modified: February 12, 2021
* Purpose: Generates the county choropleth map for number of terminations
*------------------------------------------------------------------------

* Note: To run as a free-standing program, uncomment the following lines where found in the code:
*		local 0: subinstr local 0 ";" ","
* 		syntax, pre(str) pct(str)
*       qui do "00common/00preamble.do"
*
* 		and run: do "04analysis/Run/Figures/term_map/figureA1.do"; pre(_19) pct(100)

/* 		- Uses county-level data on plan terminations to map variation
		- Uses county lines from 2010 and ssa-->fips crosswalk from 2011
		- Depends:
			-> "${out}/fig/term_map"
				Which depends on:
				-> ${code}/04analysis.do
				-> ${code}/04analysis/AnalysisConfigurations/BaselineStuff-take4/BaselineStuff_plots_map.do
				-> ${code}/04analysis/Run/fig/term_map.do
			-> /homes/data/ssa-fips-state-county-crosswalk/2011/ssa_fips_state_county2011.dta
		- Output:
			-> Levels map
				(${out}/term_map_lvl.png)
			-> Levels map: 12+ beneficiaries
				(${out}/term_map12.png)
			-> 0/1 map
				(${out}/term_map_ind.png)
			-> 0/1 map: 12+ beneficiaries
				(${out}/term_map12_ind.png)
			-> % map
				(${out}/term_map_pct.png)
			-> % map: 12+ beneficiaries
				(${out}/term_map12_pct.png)
*/

* Setup (for independent run only)
* local 0: subinstr local 0 ";" ","
* syntax, pre(str) pct(str)
* qui do 00common/00preamble.do
* // end of setup (for independent run only)

qui do 00common/00material.do
cap mkdir `"${out}"'
cap mkdir `"${out}/fig"'

/* DOC
 * 		installMapPackages:	installs packages necessary for creating the map
 *							-> maptile
 *							-> spmap

 */
capture program drop main
program main
	syntax, pre(str) pct(str) [CAPture NOIsily]

	`capture' `noisily' {
        * makeCountyMap, pre(`pre') pct(`pct') type(Levels)    cap noi
        * makeCountyMap, pre(`pre') pct(`pct') type(Indicator) cap noi
        makeCountyMap, pre(`pre') pct(`pct') type(Percent) cap noi
        * makeCountyMap, pre(`pre') pct(`pct') type(Levels)    TwelveBene cap noi
        * makeCountyMap, pre(`pre') pct(`pct') type(Indicator) TwelveBene cap noi
        * makeCountyMap, pre(`pre') pct(`pct') type(Percent)   TwelveBene cap noi
	}
end

capture program drop makeCountyMap
program makeCountyMap
	syntax, pre(str) pct(str) type(str) [TwelveBene CAPture NOIsily]

	`capture' `noisily' {
		use `"${out}/fig/term_map.dta"', clear

		* Set local map options
		if (`"`TwelveBene'"' != "") {
			* 12+ beneficiaries Levels map (using county lines from 2010)
			if (`"`type'"' == "Levels") {
				pctile breaks_12 = num_plan_term_12min_lag , nq(6)
				summ breaks_12 //to set cut breaks
				local var num_plan_term_12min_lag
				local cutv 0.9 1.9 2.9 4.9 7.9
				local name term_map12_lvl
				local ti "Number of Plan Terminations (Plans with at least 12 Beneficiaries)"
				local legend label(2 "0") label(3 "1") label(4 "2") label(5 "3-4") label(6 "5-7") label(7 "8-13")
			}

			* 12+ beneficiaries 0/1	map (using county lines from 2010)
			if (`"`type'"' == "Indicator") {
				local var has_term12
				local cutv 0.9
				local name term_map12_ind
				local ti "Plan Terminations for Plans with more than 12 Beneficiaries"
				local legend label(2 "None") label(3 "Termination(s)")
			}

			* 12 min Percent of Plans Terminating (using county lines from 2010)
			if (`"`type'"' == "Percent") {
				gen perc_plans_12 =  num_plan_term_12min_lag / num_plan_12min_lag
				pctile breaks_p12 = perc_plans_12 , nq(6)
				sum breaks_p12, detail

				local var perc_plans_12
				local cutv 0.0000001 0.05 0.1 0.2 0.5
				local name term_map12_pct
				local ti "Percent of Plans Terminating (Plans with at least 12 Beneficiaries)"
				local legend label(2 "0%") label(3 "0-5%") label(4 "5%-10%") label(5 "10%-20%") label(6 "20%-50%") label(7 "50%-100%")
				local legend1 legd(3)
			}
		}

		* Levels map (using county lines from 2010)
		if (`"`type'"' == "Levels" & `"`TwelveBene'"' == "") {
			pctile breaks = num_plan_term_lag , nq(6)

			local var num_plan_term_lag
			local cutv 0.9 1.9 2.9 4.9 7.9
			local name term_map_lvl
			local ti "Number of Plan Terminations"
			local legend label(2 "0") label(3 "1") label(4 "2") label(5 "3-4") label(6 "5-7") label(7 "8-18")
		}

		* 0/1 map (using county lines from 2010)
		if (`"`type'"' == "Indicator" & `"`TwelveBene'"' == "") {
			local var has_term
			local cutv 0.9
			local name term_map_ind
			local ti "All Plan Terminations"
			local legend label(2 "None") label(3 "Termination(s)")
		}

		* Percent of Plans Terminating (using county lines from 2010)
		if (`"`type'"' == "Percent" & `"`TwelveBene'"' == "") {
			gen perc_plans =  num_plan_term_lag / num_plan_lag
			pctile breaks_p = perc_plans , nq(6)
			sum perc_plans, detail
			pctile breaks_p_100 = perc_plans , nq(100)
			sum breaks_p, detail
			sum breaks_p_100, detail

			local var perc_plans
			local cutv 0.00001 0.05 0.10 0.25 0.40
			local name term_map_pct
			local ti "Geographic Distribution of Plan Terminations"
			local legend label(2 "0%") label(3 "0-5%") label(4 "5%-10%") label(5 "10%-25%") label(6 "25%-40%") label(7 "40%-100%") 
			local legend1 legd(3)
		}

		* include xopts
		include "04analysis/Parse/FigureOptions.do"

		* Generate and export map
		maptile `var', geo(county2010) ///
			cutv(`cutv') fc(Blues) twopt(name(`name',replace) /* ti(`ti') */ legend(`legend')) `legend1'
 		graph export `"${out}/fig/`pre'figureA1_`name'_`pct'.svg"', `xopts'
	}
end

*------------------------------

main, pre(`pre') pct(`pct') cap noi

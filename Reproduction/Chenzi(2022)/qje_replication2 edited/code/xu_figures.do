*This file produces the figures in Xu "Reshaping Global Trade" (QJE)


*MAIN PAPER*

* =================================================================
* Figure I: maps 
* =================================================================
{
	*Made in ArcGIS
	*Ia: Geography of banking and trade
	*data: "map_locations.csv"
	
	*Ib: Port-level trade activity
	*data: "sr_port.dta"
	
}

* =================================================================
* Figure II: Aggregate exports
* =================================================================
{
	use "$filepath/data/lr_trade_final.dta", clear
	
	collapse expr_tot, by(country_o year fail_frac_o)
	
	qui sum fail_frac_o if year==1865, d
	gen fail_mean = `r(mean)'
	gen above = (fail_frac_o>=fail_mean)
	gen below = (fail_frac_o<fail_mean)
	gen all = 1
	
	foreach type in above below all{
		bysort year: egen expr_`type' = total(expr_tot) if `type'==1
		sort year expr_`type'
		replace expr_`type' = expr_`type'[_n-1] if missing(expr_`type')
		
		gen `type'_66 = expr_`type' if year==1866
		sort `type'_66
		replace `type'_66 = `type'_66[_n-1] if missing(`type'_66)
		
		gen `type'_norm = expr_`type'/`type'_66
	}
	label var all_norm "All"
	label var below_norm "Below avg failure"
	label var above_norm "Above avg failure"
	sort year 
	twoway (line all_norm year, lcolor(edkblue) lpattern(dash_dot) xline(1866) ///
		xlabel(1845(10)1915) ylabel(, angle(0))) ///
		(line below_norm year, lcolor(black) lpattern(solid)) ///
		(line above_norm year, lcolor(black) lpattern(dash)) ///
		, ytitle("Exports (1866=1)") graphregion(color(white)) ///
		legend(rows(1)) xsize(6.5)
	
	graph export "$filepath/output/fig2.pdf", replace as(pdf)	
	graph export "$filepath/output/fig2.eps", replace as(eps)
	graph export "$filepath/output/fig2.tif", replace as(tif)
	
	*Appendix Figure B8a
	{
		gen diff = above_norm - below_norm
		
		twoway (line diff year, lcolor(black) lpattern(solid) xline(1866) ///
		xlabel(1845(10)1915) ylabel(, angle(0))) ///
		, ytitle("Above avg exposure - Below avg exposure") graphregion(color(white)) ///
		legend(off) xsize(6.5) 
	graph export "$filepath/output/app_figB10.pdf", replace as(pdf)	
	graph export "$filepath/output/app_figB10.tif", replace as(tif)	
	graph export "$filepath/output/app_figB10.eps", replace as(eps)	
	}
	
}


* =================================================================
* Figure III: Baseline LR effects
* =================================================================
{
	
	// define global vars
	global lr_fe_dt country_o_id country_d_id#year c.lgeo_dist#year brit_bank#year
	global lr_fe_d country_o_id country_d_id c.lgeo_dist#year brit_bank#year
	//
	
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
	
	*Baseline regression
	qui reghdfe lexpr_ff dd6_*fail_frac_o, ///
		absorb($lr_fe_dt) cluster(country_o_id)
	
	*Baseline effects without scaling
	{
			matrix D_unw = J(13,2,.)
			forvalues numlist=1/13{
			matrix rownames D_unw = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames D_unw = est se 
				}
				
				local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							if (`i' == `omit') {
								matrix D_unw[`i', 1] = 0, 0		
							}
							else {
								matrix D_unw[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]			
							}
						}

			foreach type in D_unw {		
				coefplot (matrix(`type'[.,1]), se(`type'[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue))), ///
						vertical recast(connected) color(edkblue) ///
						xlabel(, angle(15) labsize(small)) ///
						ylabel(, angle(0))  ///
						yscale(range(-3(1)1)) ylabel(-3(1)1, angle(0)) ///
						ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
						ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
						xline(3, lc(cranberry) lp(solid)) ylabel(-4(1)1, grid angle(0))  graphregion(color(white)) xsize(7.5)
				}
	}			
			
	*Effects scaled by exposure
		{
			bysort country_o year: gen indic = _n
			replace indic = . if year!=1865
			replace indic = . if indic!=1
			qui sum fail_frac_o if indic==1, d
				gen mean = `r(mean)'
				
			qui sum fail_frac_o if indic==1 & fail_frac_o>0, d
				foreach level in 25 50 75 90{
					gen pct_`level'_no0 = `r(p`level')'
				}
			
			*Scale matrices
			foreach type in mean pct_25_no0 pct_50_no0 pct_75_no0 pct_90_no0{
				
				matrix D_`type' = J(13,2,.)
				forvalues numlist=1/13{
				matrix rownames D_`type' = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames D_`type' = est se 
				}
				
				local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							
							if (`i' == `omit') {
								matrix D_`type'[`i', 1] = 0, 0		
							}
							else {
								local coef_`date'_`type' = _b[dd6_`date'_fail_frac_o]*`type'
								display `coef_`date'_`type''
								local se_`date'_`type' = _se[dd6_`date'_fail_frac_o]*`type'
								display `se_`date'_`type''
								
								matrix D_`type'[`i', 1] = `coef_`date'_`type'', `se_`date'_`type''	
							}
						}
			}
		}	
			
	*Baseline effects scaled by mean of exposure
	{
			coefplot (matrix(D_mean[.,1]), se(D_mean[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue))), ///
						vertical recast(connected) color(edkblue) ///
					xlabel(, angle(15) labsize(small)) ///
						ylabel(, angle(0)) yscale(titlegap(*-25))  ///
					     xtitle("Years") ///
						ytitle("{&beta}{sub:t}", orientation(horizontal)) ///
						yline(0, lc(black)) ///
						xline(3, lc(cranberry) lp(solid)) ylabel(-0.4(0.1)0.1, grid angle(0))  graphregion(color(white)) xsize(7.5) 
				graph export "$filepath/output/fig3b.pdf", replace
				graph export "$filepath/output/fig3b.eps", replace
				graph export "$filepath/output/fig3b.tif", replace
					
	*Appendix Figure B7: Baseline effects scaled by different percentiles of exposure conditional on positive failure
			coefplot (matrix(D_pct_25_no0[.,1]), se(D_pct_25_no0[.,2]) msymbol(Th) mcolor(edkblue) lp(-) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
				offset(-.1) label("25th percentile")) ///
			(matrix(D_pct_50_no0[.,1]), se(D_pct_50_no0[.,2]) msymbol(T) mcolor(edkblue) lp(-) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
				offset(.1) label("50th percentile")) ///
			 (matrix(D_pct_75_no0[.,1]), se(D_pct_75_no0[.,2]) msymbol(square) mcolor(edkblue) lp(-) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
				offset(.3) label("75th percentile")), ///
			vertical recast(connected) ///
			xlabel( , angle(15) labsize(medium)) ///
			xtitle("Years") ylabel(, angle(0)) yscale(titlegap(-6)) ///
			ytitle("{&beta}{sub:t}", orientation(horizontal) ) yline(0, lc(black)) ///
			xline(3, lc(black) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
			xsize(8.5) legend(size(medium) rows(1)) 
				graph export "$filepath/output/app_figB7.pdf", replace
				graph export "$filepath/output/app_figB7.tif", replace
				graph export "$filepath/output/app_figB7.eps", replace
	}		
	
	*Annual version
	* Figure B9a and Figure 3a
	{
	qui reghdfe lexpr_f fail_frac_1*, ///
			absorb(country_o_id country_d_id#year c.lgeo_dist#year brit_bank#year) ///
			cluster(country_o_id)
			
	gen app_figB9a = 1
	rename mean fig3a

		foreach type in fig3a app_figB9a{
			matrix A_`type' = J(65, 2,.)
			local omit = 17
			local tstart = 1849
				forvalues i = 1/65{
					local date = `tstart' + `i'
					if (`i' == `omit') {
						matrix A_`type'[`i', 1] = 0, 0
						}
					else{
						local coef_`date'_`type' = _b[fail_frac_`date']*`type'
						local se_`date'_`type' = _se[fail_frac_`date']*`type'
								
						matrix A_`type'[`i', 1] = `coef_`date'_`type'', `se_`date'_`type''	
					}
				}
			
			if `type' == fig3a {
			coefplot (matrix(A_`type'[.,1]), se(A_`type'[.,2]) msymbol(square) mcolor(edkblue) ///
				offset(0.1) label("Failure x year") ) , ///
					vertical recast(connected) offset(0) color(edkblue) ///
					xlabel(1 "1850" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 "1860" ///
					12 " " 13 " "  14 " " 15 " " 16 " " 17 " " 18 " " 19 " " 20 " " ///
					21 "1870" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " ///
					31 "1880" 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " ///
					41 "1890" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " ///
					51 "1900" 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " ///
					61 "1910" 62 " " 63 " " 64 " " 65 "1914" ///
					, angle(15) labsize(small)) ///
					ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
					ylabel(, angle(0)) xsize(8.5) ///
					ytitle("{&beta}{sub:t}", orientation(horizontal))  ysc(titlegap(-10) outergap(0))  yline(0, lc(black)) ///
					xline(17, lc(cranberry) lp(solid)) ylabel( -0.4(0.1)0.1, grid angle(0))  graphregion(color(white))  
				
				graph export "$filepath/output/fig3a.pdf", replace as(pdf) 
				graph export "$filepath/output/fig3a.eps", replace as(eps)
				graph export "$filepath/output/fig3a.tif", replace as(tif)
			}
			
			
			
			if `type' == app_figB9a{
			coefplot (matrix(A_`type'[.,1]), se(A_`type'[.,2]) msymbol(square) mcolor(edkblue) ///
				offset(0.1) label("Failure x year") ) , ///
					vertical recast(connected) offset(0) color(edkblue) ///
					xlabel(1 "1850" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 "1860" ///
					12 " " 13 " "  14 " " 15 " " 16 " " 17 " " 18 " " 19 " " 20 " " ///
					21 "1870" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " ///
					31 "1880" 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " ///
					41 "1890" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " ///
					51 "1900" 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " ///
					61 "1910" 62 " " 63 " " 64 " " 65 "1914" ///
					, angle(15) labsize(small)) ///
					ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
					ylabel(, angle(0)) xsize(8.5) ///
					ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
					xline(17, lc(cranberry) lp(solid)) ylabel( -4(1)1, grid angle(0))  graphregion(color(white))
					graph export "$filepath/output/app_figB9a.pdf", replace as(pdf)
					graph export "$filepath/output/app_figB9a.eps", replace as(eps)
					graph export "$filepath/output/app_figB9a.tif", replace as(tif)
			}
	
		}
	}
	


	*Exporter similarity (Figure VI)
	{
		rename fig3a fig6
		
		qui reghdfe lexpr_ff dd6_*fail_frac_o, ///
		absorb(country_o_id country_d_id#year c.lgeo_dist#year brit_bank#year regio_o_id#year) ///
		cluster(country_o_id)
			foreach type in fig6{
				
				matrix D_`type' = J(13,2,.)
				forvalues numlist=1/13{
				matrix rownames D_`type' = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames D_`type' = est se 
				}
				
				local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							
							if (`i' == `omit') {
								matrix D_`type'[`i', 1] = 0, 0		
							}
							else {
								local coef_`date'_`type' = _b[dd6_`date'_fail_frac_o]*`type'
								display `coef_`date'_`type''
								local se_`date'_`type' = _se[dd6_`date'_fail_frac_o]*`type'
								display `se_`date'_`type''
								
								matrix D_`type'[`i', 1] = `coef_`date'_`type'', `se_`date'_`type''	
							}
						}
					
				coefplot (matrix(D_`type'[.,1]), se(D_`type'[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue))), ///
						vertical recast(connected) color(edkblue) ///
						xlabel( , angle(15) labsize(small)) ///
						ylabel(, angle(0)) yscale(titlegap(*-25))  ///
						ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
						ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
						xline(3, lc(cranberry) lp(solid)) ylabel(-0.4(0.1)0.1, grid angle(0))  graphregion(color(white)) xsize(7.5) 
				graph export "$filepath/output/fig6.pdf", replace
				graph export "$filepath/output/fig6.tif", replace
				graph export "$filepath/output/fig6.eps", replace
				

				
			}
	}
}

* =================================================================
* Figure IV: Baseline and Structural LR effects
* =================================================================
{
	use "$filepath/data/lr_trade_sg.dta", clear
		
	*regression
		qui reghdfe lexpr_ff dd6*fail_frac_o if lgdp_o!=., absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	
			
			matrix B = J(13,2,.)
				forvalues numlist=1/13{
				matrix rownames B = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames B = est se 
				}
				
				local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							if (`i' == `omit') {
								matrix B[`i', 1] = 0, 0		
							}
							else {
								matrix B[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]			
							}
						}

	
		qui reghdfe lexpr_ff dd6*fail_frac_o lgdp_o mr_gdp, absorb(country_o_id country_d_id#year brit_bank#year) cluster(country_o_id)
			estadd scalar N_true = e(N) + e(num_singletons)	
			matrix M = J(13,2,.)
				forvalues numlist=1/13{
				matrix rownames M = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames M = est se 
				}
				
				local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							if (`i' == `omit') {
								matrix M[`i', 1] = 0, 0		
							}
							else {
								matrix M[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]			
							}
			}
			
			
			
			coefplot (matrix(B[.,1]), se(B[.,2]) msymbol(square) mcolor(edkblue) lp(solid) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
				offset(-.1) label("Reduced form")) ///
			(matrix(M[.,1]), se(M[.,2]) msymbol(triangle) mcolor(orange) ciopts(recast(rcap) lp(-) color(orange)) color(orange) ///
			offset(0.1) label("Structural gravity")) , ///
			vertical recast(connected) ///
			msymbol(square) mcolor(black) xlabel( , angle(15) labsize(medium)) ///
			xtitle("Years") ylabel(, angle(0)) ///
			ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
			xline(3, lc(cranberry) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
			xsize(7.5) legend(size(medium)) ylabel(-5(2)1)
			
		graph export "$filepath/output/fig4.pdf", replace
		graph export "$filepath/output/fig4.tif", replace
		graph export "$filepath/output/fig4.eps", replace	
	
	
}


* =================================================================
* Figure V: Import decomposition
* =================================================================
{
	use "$filepath/data/lr_trade_final.dta", clear
	
	*Generate variables
		bysort country_d year: egen tot_imports = total(expr_f)
		bysort country_d year: gen count_source = _N
		
		*Calculate independent variable: average exposure of countries it sourced from, pre-period
		gen source_expos_weight = fail_frac_o*expr_f/tot_imports
		bysort country_d year: egen avg_source_expos = total(source_expos_weight)
		
		gen avg_source_expos_pre5 = avg_source_expos if year<=1866 & year>=1865
		
		*Mark sources that existed pre-crisis
			bysort country_d year: gen orig_pair = 1 if year<=1866
			sort country_d country_o orig_pair
			bysort country_d country_o: replace orig_pair = orig_pair[_n-1] if missing(orig_pair)
			sort country_d country_o year
			bysort country_d country_o: gen index = _n

		*Mark sources that are new post_crisis 
			bysort country_o country_d: egen max_orig = max(orig_pair)
			gen new_pair = 0 if max_orig==1
			replace new_pair = 1 if new_pair!=0
			
		*calculate total imports by original versus new
			bysort country_d year: egen tot_imports_new = total(expr_f) if new_pair==1
				bysort country_d year: egen count_source_new = total(new_pair) if new_pair==1
			bysort country_d year: egen tot_imports_old = total(expr_f) if new_pair==0
		
		
		*Collapse data
		collapse (mean) tot_imports count_source avg_source_expos_pre* (sum) orig_pair new_pair ///
			(max) tot_imports_new tot_imports_old count_source_new , by(country_d year)
			
			replace count_source_new = 0 if missing(count_source_new)
			gen count_source_old = count_source - count_source_new
			
			bysort country_d: egen avg_expos_pre5 = mean(avg_source_expos_pre5)
			replace avg_expos_pre5 = 0 if missing(avg_expos_pre5)
		
		
		
		*Generate shock variable
		*Year Dummies
		gen d6_55=(year<=1855)
		gen d6_60=(year>1855 & year<=1860)
		gen d6_65=(year<=1865 & year>1860)
		gen d6_70=(year<=1870 & year>1865)
		gen d6_75=(year<=1875 & year>1870)
		gen d6_80=(year<=1880 & year>1875)
		gen d6_85=(year<=1885 & year>1880)
		gen d6_90=(year<=1890 & year>1885)
		gen d6_95=(year<=1895 & year>1890)
		gen d6_100=(year<=1900 & year>1895)
		gen d6_105=(year<=1905 & year>1900)
		gen d6_110=(year<=1910 & year>1905)
		gen d6_115=(year<=1915 & year>1910)

	***Treatment variables
		foreach var of varlist d6_55-d6_115{
				gen d`var'_avg_expos_pre5 = `var'*avg_expos_pre5	
			}
				drop dd6_65_*
				
			egen countrydid = group(country_d)	
		
		*Outcome variables
			gen ltotimp = ln(tot_imports)
			gen newimp_share = tot_imports_new/tot_imports
			gen oldimp_share = tot_imports_old/tot_imports
				replace oldimp_share = 0 if missing(oldimp_share)
				replace newimp_share = 0 if missing(newimp_share)
			gen lsources = ln(count_source)
			gen lnew_source = ln(new_pair)
			gen limp_source = ln(tot_imports/count_source)
			
			bysort country_d: gen orig_dest = 1 if year==1866 | year==1865
			sort country_d orig_dest 
			bysort country_d: replace orig_dest = orig_dest[_n-1] if missing(orig_dest)
			
		*Regressions for figure
		{
			
			foreach var in ltotimp limp_source lsources newimp_share oldimp_share {
			 qui reghdfe `var' d*avg_expos_pre5 [aw=count_source], absorb(countrydid year orig_dest#year)	
			eststo m_`var'
			
			matrix X_`var' = J(13,2,.)
				forvalues numlist=1/13{
				matrix rownames X_`var' = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
				matrix colnames X_`var' = est se 
				}
			local omit = 3
				local tstart = 50
						forvalues i = 1/13 {
							local date =  `tstart' + 5*`i'
							if (`i' == `omit') {
								matrix X_`var'[`i', 1] = 0, 0		
							}
							else {
								matrix X_`var'[`i', 1] = _b[dd6_`date'_avg_expos_pre5], _se[dd6_`date'_avg_expos_pre5]			
							}
						}
					
		}
				
				coefplot (matrix(X_ltotimp[.,1]), se(X_ltotimp[.,2]) msymbol(triangle) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue)) ///
					offset(-0.1) label("Imports") ) ///
				(matrix(X_lsources[.,1]), se(X_lsources[.,2]) msymbol(square) mcolor(eltblue) ciopts(recast(rcap) lp(-) color(eltblue)) color(eltblue) ///
					offset(0.1) label("Sources") ) ///
				(matrix(X_limp_source[.,1]), se(X_limp_source[.,2]) msymbol(circle) mcolor(orange) ciopts(recast(rcap) lp(-) color(orange)) color(orange) ///
					offset(0.3) label("Imports by source") ) 	, ///
						vertical recast(connected) offset(0) color(edkblue) ///
						msymbol(square) mcolor(black) xlabel( , angle(15)) ///
						ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
						ylabel(-3(1.5)3, angle(0)) legend(rows(1)) ///
						ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
						xline(`omit', lc(cranberry) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
						xsize(8.5) 
				graph export "$filepath/output/fig5a.pdf", replace as(pdf)	
				graph export "$filepath/output/fig5a.eps", replace as(eps)	
				graph export "$filepath/output/fig5a.tif", replace as(tif)		
				
				
				coefplot (matrix(X_oldimp_share[.,1]), se(X_oldimp_share[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue)) ///
					offset(0) label("Share from pre-crisis sources") ) , ///
						vertical recast(connected) offset(0) color(edkblue) ///
						msymbol(square) mcolor(black) xlabel( , angle(15)) ///
						ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
						ylabel(-1(0.5)1, angle(0)) legend(rows(1)) ///
						ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
						xline(`omit', lc(cranberry) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
						xsize(8.5) 
				graph export "$filepath/output/fig5b.pdf", replace as(pdf)	
				graph export "$filepath/output/fig5b.tif", replace as(tif)
				graph export "$filepath/output/fig5b.eps", replace as(eps)	
			
			
		}	
		
}


* =================================================================
* Figure VI: Exporter similarity
* =================================================================
{
	*In code for Figure III
	
}


* =================================================================
* APPENDIX FIGURES
* =================================================================

	*B3: see code for Table III
	*B7, B8: see code for Figure III

	*B4: Distribution of exposure
{
	* CODE for ports: 
	global part 1

	use "$filepath/data/sr_ports_final.dta", clear
	keep if event == 0
	qui sum shock_lon, d

	local r_mean : di %6.2f scalar(`r(mean)')
	local r_sd : di %6.2f scalar(`r(sd)')
	twoway hist shock_lon, bin(15) frac ///
	graphregion(color(white)) xtitle("Port-level exposure to bank failure") ///
	xline(`r_mean', lcolor(black)) ///
	ytitle("Density (fraction)") ylabel(0(0.2)0.8, angle(0))  ///
	text(0.66 `r_mean' "mean = `r_mean', sd = `r_sd'", box bcolor(white) lcolor(black))
	graph export "$filepath/output/app_fig_dist_port_fail.pdf", replace
	graph export "$filepath/output/app_fig_dist_port_fail.tif", replace
	graph export "$filepath/output/app_fig_dist_port_fail.eps", replace


	* CODE for countries: 
		use "$filepath/data/lr_trade_final.dta", clear
			keep if year==1865 
			duplicates drop country_o, force
	qui sum fail_frac_o, d
	local r_mean : di %6.2f scalar(`r(mean)')
	local r_sd : di %6.2f scalar(`r(sd)')

	twoway hist fail_frac_o, bin(15) frac ///
	graphregion(color(white)) xtitle("Country-level exposure to bank failure") ///
	xline(`r_mean', lcolor(black)) ///
	ytitle("Density (fraction)") ylabel(0(0.2)0.8, angle(0)) ///
	text(0.66 `r_mean' "mean = `r_mean', sd = `r_sd'", box bcolor(white) lcolor(black))

	graph export "$filepath/output/app_fig_dist_country_fail.pdf", replace
	graph export "$filepath/output/app_fig_dist_country_fail.eps", replace
	graph export "$filepath/output/app_fig_dist_country_fail.tif", replace
	
}

	*B5: SITC composition
{
	use "$filepath/data/sitc_1865", clear
	
	gen inv_tot_sitc= 1/tot_sitc
	replace tot_sitc = tot_sitc/1000000
	label var tot_sitc "Total global value of exports by SITC code, 1865"
	graph hbar tot_sitc, over(sitc, sort(inv_tot_sitc ) label(labsize(vsmall))) ///
		graphregion(color(white)) bar(1, color(gray)) ///
		ytitle("Total global value of exports by SITC code in 1865 (m GBP)")
	graph export "$filepath/output/exports_sitc.pdf", replace
	graph export "$filepath/output/exports_sitc.tif", replace
	graph export "$filepath/output/exports_sitc.eps", replace
	
}

	
	*B8
	*B8a: see code for Figure II
	
	*B82:
{	
	use "$filepath/data/lr_trade_final.dta", clear
	
	collapse expr_tot, by(country_o country_o_id year fail_frac_o)
	
	qui sum fail_frac_o if year==1865, d
	gen fail_mean = `r(mean)'
	gen above = (fail_frac_o>=fail_mean)
	
	forvalues x = 1850/1914{
		gen fail_mean_`x' = above*(year==`x')
	}
		drop fail_mean_1866
		gen lexpr_f = ln(expr_tot)
		
		qui reghdfe lexpr_f fail_mean_* [aweight=expr_tot], absorb(year country_o) vce(cluster country_o_id)
		matrix X = J(65, 2,.)
				forvalues numlist = 1/65{
				matrix colnames X = est se
				}
				
				local omit = 17
				local tstart = 1849
					forvalues i = 1/65{
						local date = `tstart' + `i'
						if (`i' == `omit') {
							matrix X[`i', 1] = 0, 0
							}
						else{
							matrix X[`i', 1] = _b[fail_mean_`date'], _se[fail_mean_`date']
						}
					}
				local nobs = e(N)
				local nclust = e(N_clust)	
					
				coefplot (matrix(X[.,1]), se(X[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue)) ///
					offset(0.1) label("Failure x year") ) , ///
					xlabel(1 "1850" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 "1860" ///
					12 " " 13 " "  14 " " 15 " " 16 " " 17 "1866" 18 " " 19 " " 20 " " ///
					21 "1870" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " ///
					31 "1880" 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " ///
					41 "1890" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " ///
					51 "1900" 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " ///
					61 "1910" 62 " " 63 " " 64 " " 65 "1914" ///
					, angle(15) labsize(small)) ///
						vertical recast(connected) offset(0) color(edkblue) ///
						msymbol(square) mcolor(black) ///
						ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
						ylabel(, angle(0)) ///
						ytitle("{&beta}{sub:t}: treatment effect of above-average exposure") yline(0, lc(black)) ///
						xline(`omit', lc(cranberry) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
						xsize(8.5) 
				graph export "$filepath/output/app_figB8b.pdf", replace as(pdf)	
				graph export "$filepath/output/app_figB8b.tif", replace as(tif)
				graph export "$filepath/output/app_figB8b.eps", replace as(eps)		
	
}

	*B10: 
{
	use "$filepath/data/lr_trade_final.dta", clear
	qui merge m:1 country_o year using "$filepath/data/country_char.dta"
		drop _merge
		
	qui merge m:1 country_o year using "$filepath/data/lr_gdp.dta"
		drop _merge
	
	*Create variables
	foreach var of varlist *_val{
			gen ln`var' = ln(`var')
			replace ln`var' = 0 if missing(ln`var')
		}
	
	
	replace sitc_ind65=999 if missing(sitc_ind65)
	gen lpop = ln(pop_o)
	gen lpop_65 = lpop if year==1865
	sort country_o year
	bysort country_o: replace lpop_65 = lpop_65[_n-1] if missing(lpop_65)
	gsort country_o -year
	bysort country_o: replace lpop_65 = lpop_65[_n-1] if missing(lpop_65)
		
		
	qui foreach type in 55 60 70 75 80 85 90 95 100 105 110 115 {
			gen dd6_`type'_lpop_65 = d6_`type'*lpop_65
			foreach commod in cotton grains bullion cotton_manu sugar coffee alcohol tobacco{
					gen dd6_`type'_`commod' = ln`commod'_val*d6_`type'
				}
		}
	*--------------------------------------------------------------------------
	*B10a
	qui reghdfe lexpr_f dd*fail_frac_o if sitc_ind!=999, ///
		absorb($lr_fe_dt sitc_ind#year) cluster(country_o_id)
	eststo tabG12_6
	estadd scalar N_true = e(N) + e(num_singletons)	

		
	matrix D_unw = J(13,2,.)
	forvalues numlist=1/13{
		matrix rownames D_unw = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
		matrix colnames D_unw = est se
	}

	local omit = 3
	local tstart = 50
	forvalues i = 1/13 {
		local date =  `tstart' + 5*`i'
		if (`i' == `omit') {
			matrix D_unw[`i', 1] = 0, 0
		}
		else {
			matrix D_unw[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]
		}
	}


	foreach type in D_unw {
		coefplot (matrix(`type'[.,1]), se(`type'[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue))), ///
		vertical recast(connected) color(edkblue) ///
		xlabel( , angle(15) labsize(small)) ///
		yscale(range(-3(1)1)) ylabel(-3(1)1, angle(90)) ///
		ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
		ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
		xline(3, lc(cranberry) lp(solid))  ylabel( -4(1)1, grid angle(0))  graphregion(color(white)) xsize(7.5)
		graph export "$filepath/output/app_figB10a.pdf", replace
		graph export "$filepath/output/app_figB10a.tif", replace
		graph export "$filepath/output/app_figB10a.eps", replace
	}
		
	*-------------------------------------------------------------------------
	*B10b
	qui reghdfe lexpr_f dd*fail_frac_o if sitc_ind!=999, ///
		absorb($lr_fe_dt regio_o_id#year) cluster(country_o_id)
	eststo tabG12_7
	estadd scalar N_true = e(N) + e(num_singletons)

	matrix regio = J(13,2,.)
	forvalues numlist=1/13{
		matrix rownames regio = "1850-1855" "56-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
		matrix colnames regio = est se
	}

	local omit = 3
	local tstart = 50
	forvalues i = 1/13 {
	local date =  `tstart' + 5*`i'
	if (`i' == `omit') {
			matrix regio[`i', 1] = 0, 0
		}
		else {
			matrix regio[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]
		}
	}

	foreach type in regio {
		coefplot (matrix(`type'[.,1]), se(`type'[.,2]) msymbol(square) mcolor(edkblue) ciopts(recast(rcap) lp(-) color(edkblue))), ///
		vertical recast(connected) color(edkblue) ///
		xlabel( , angle(15)  labsize(small)) ///
		yscale(range(-3(1)1)) ylabel(-4(1)1, angle(0)) ///
		ciopts(recast(rcap) lp(-) color(gray)) xtitle("Years") ///
		ytitle("{&beta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
		xline(3, lc(cranberry) lp(solid)) graphregion(color(white)) xsize(7.5)
		graph export "$filepath/output/app_figB10b.pdf", replace
		graph export "$filepath/output/app_figB10b.eps", replace
		graph export "$filepath/output/app_figB10b.tif", replace
	}
	
		
}

	*B12:
{	
	use "$filepath/data/lr_trade_final", clear
	
	**Create variables
	egen avg_geo_dist65 = mean(geo_dist) if year==1865
		sort avg_geo_dist65
		replace avg_geo_dist65 = avg_geo_dist65[_n-1] if missing(avg_geo_dist65)
	
	gen close65 = (geo_dist<=avg_geo_dist65)

	**Treatment variables
	foreach var of varlist d6_55-d6_115{
			gen d`var'_fail_frac_o_close65 = `var'*fail_frac_o*close65
		}
			drop dd6_65_*
	
	
	qui reghdfe lexpr_ff dd*fail_frac_o dd*close65, absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year) cluster(country_o_id)
	{
		matrix S = J(12,2,.)
			forvalues numlist=1/12{
			matrix rownames S = "1856-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
			matrix colnames S = est se 
			}
			
			local omit = 3
			local tstart = 50
					forvalues i = 1/12 {
						local date =  `tstart' + 5*`i'
						if (`i' == `omit') {
							matrix S[`i', 1] = 0, 0		
						}
						else {
							matrix S[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]	
						}
					}
				
		matrix S2 = J(12,2,.)
			forvalues numlist=1/12{
			matrix rownames S2 = "1856-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
			matrix colnames S2 = est se 
			}
			
			local omit = 3
			local tstart = 50
					forvalues i = 1/12 {
						local date =  `tstart' + 5*`i'
						if (`i' == `omit') {
							matrix S2[`i', 1] = 0, 0		
						}
						else {
							matrix S2[`i', 1] = _b[dd6_`date'_fail_frac_o_close65], _se[dd6_`date'_fail_frac_o_close65]			
						}
			}
			
	coefplot (matrix(S2[.,1]), se(S2[.,2]) msymbol(square) mcolor(edkblue) lp(-) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
				offset(-.1) label("Failure x Close")) ///
			(matrix(S[.,1]), se(S[.,2]) msymbol(triangle) mcolor(orange) ciopts(recast(rcap) lp(solid) color(orange)) color(orange) ///
			offset(0.1) label("Failure")) , ///
			vertical recast(connected) ///
			msymbol(square) mcolor(black) xlabel( , angle(15) labsize(medium)) ///
			xtitle("Years") ylabel(, angle(0)) ///
			ytitle("{&theta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
			xline(3, lc(black) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
			xsize(7.5) legend(size(medium)) 
	
	graph export "$filepath/output/persistence_closefar.pdf", replace
	graph export "$filepath/output/persistence_closefar.eps", replace
	graph export "$filepath/output/persistence_closefar.tif", replace
	}
				
	
}

	*B13:
{
	use "$filepath/data/lr_trade_final", clear
		*Variable for colonizer	
			gen same_colony = 1 if (emp_o==emp_d & emp_o!="") | ///
				(emp_o==emp_d2 & emp_o!="") | ///
				(emp_o2==emp_d & emp_d!="") | ///
				(emp_o2==emp_d2 & emp_d2!="") 
			replace same_colony = 0 if missing(same_colony)
			
			
			gen colonizer_tr = same_colony
			replace colonizer_tr = 0 if Curcol==0 
			
		*Generate interactions
			foreach var of varlist d6_55-d6_115{
				foreach type in colonizer_tr {
					gen d`var'_fail_`type' = `var'*fail_frac_o*`type'
				}
			}
			drop dd6_65*

			
			qui reghdfe lexpr_ff dd*fail_colonizer_tr dd*fail_frac_o , absorb(country_o_id country_d_id#year brit_bank#year c.lgeo_dist#year Curcol) cluster(country_o_id)
			{
				matrix S = J(12,2,.)
					forvalues numlist=1/12{
					matrix rownames S = "1856-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
					matrix colnames S = est se 
					}
					
					local omit = 3
					local tstart = 50
							forvalues i = 1/12 {
								local date =  `tstart' + 5*`i'
								if (`i' == `omit') {
									matrix S[`i', 1] = 0, 0		
								}
								else {
									matrix S[`i', 1] = _b[dd6_`date'_fail_colonizer_tr], _se[dd6_`date'_fail_colonizer_tr]	
								}
							}
						
				matrix S2 = J(12,2,.)
					forvalues numlist=1/12{
					matrix rownames S2 = "1856-60" "61-65" "66-70" "71-75" "76-80" "81-85" "86-90" "91-95" "96-00" "1901-05" "06-10" "11-14"
					matrix colnames S2 = est se 
					}
					
					local omit = 3
					local tstart = 50
							forvalues i = 1/12 {
								local date =  `tstart' + 5*`i'
								if (`i' == `omit') {
									matrix S2[`i', 1] = 0, 0		
								}
								else {
									matrix S2[`i', 1] = _b[dd6_`date'_fail_frac_o], _se[dd6_`date'_fail_frac_o]			
								}
					}
					
					
			coefplot (matrix(S[.,1]), se(S[.,2]) msymbol(square) mcolor(edkblue) lp(-) ciopts(recast(rcap) lp(-) color(edkblue)) color(edkblue) ///
						offset(-.1) label("Failure x Colonial trade")) ///
					(matrix(S2[.,1]), se(S2[.,2]) msymbol(triangle) mcolor(orange) ciopts(recast(rcap) lp(solid) color(orange)) color(orange) ///
					offset(0.1) label("Failure")), ///
					vertical recast(connected) ///
					msymbol(square) mcolor(black) xlabel( , angle(15) labsize(medium)) ///
					xtitle("Years") ylabel(, angle(0)) ///
					ytitle("{&theta}{sub:t}", orientation(horizontal)) yline(0, lc(black)) ///
					xline(3, lc(black) lp(solid)) ylabel( , grid)  graphregion(color(white))  ///
					xsize(7.5) legend(size(medium)) 
			graph export "$filepath/output/figure_lr_colonies.pdf", replace
			graph export "$filepath/output/figure_lr_colonies.eps", replace
			graph export "$filepath/output/figure_lr_colonies.tif", replace
			}
	
}









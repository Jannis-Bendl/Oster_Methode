import excel "$data_dir/United_States/Newspaper_Mentions.xlsx", sheet("Sheet1") firstrow case(lower) clear
	
	two connect bb malthusian year if source=="newspapers.com", msymbol(O T) mcolor(black black) lcolor(black black) lpattern(solid solid) xline(1877, lcolor(black) lw(medthick)) name(newsp, replace) xlabel(1870(5)1885, grid notick) ylabel(0(50)200, grid notick angle(0)) ytitle("Articles Mentioning Keyword") xtitle("Year") legend(order(1 "Bradlaugh or Besant" 2 "Malthusian") rows(2) position(1) ring(0) bmargin(small) colgap(small))
	

	graph export "$results/F4_US_article_time_series.pdf", replace

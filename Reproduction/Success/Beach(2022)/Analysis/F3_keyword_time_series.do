use "$data_dir/England_and_Wales/Newspaper_Monthly_Queries.dta", clear


	two (connect counter month if keyword=="Bradlaugh OR Besant", msymbol(Oh) mcolor(black) lpattern(solid) lcolor(black)) ///
	(connect counter month if keyword=="Fruits of Philosophy", msymbol(Sh) mcolor(black)  lpattern(solid) lcolor(black)) ///
	(connect counter month if keyword=="Population Question", msymbol(Th) mcolor(black) lpattern(solid) lcolor(black)), xlabel(1 "Jan." 2 "Feb." 3 "Mar." 4 "Apr." 5 "May" 6 "Jun." 7 "Jul." 8 "Aug." 9 "Sep." 10 "Oct." 11 "Nov." 12 "Dec.", grid notick labsize(large)) ylabel(0(125)500, grid notick labsize(large) angle(0)) title("Articles by Month, 1877", size(huge)) ytitle("Articles Mentioning Keyword", size(vlarge)) xtitle("") legend(order(1 "Bradlaugh or Besant" 2 "Fruits of Philosophy" 3 "Population Question") rows(3) position(1) ring(0) bmargin(small) colgap(small) size(large)) name(f_month, replace)

use "$data_dir/England_and_Wales/Newspaper_Yearly_Queries.dta", clear


	two (connect counter year if keyword=="Bradlaugh OR Besant", msymbol(Oh) mcolor(black) lpattern(solid) lcolor(black)) ///
	(connect counter year if keyword=="Fruits of Philosophy", msymbol(Sh) mcolor(black)  lpattern(solid) lcolor(black)) ///
	(connect counter year if keyword=="Population Question", msymbol(Th) mcolor(black) lpattern(solid) lcolor(black)), xlabel(1870(5)1890, grid notick labsize(large)) ylabel(0(300)1200, grid notick labsize(large) angle(0)) title("Articles by Year", size(huge)) ytitle("Articles Mentioning Keyword", size(vlarge)) xtitle("") legend(order(1 "Bradlaugh or Besant" 2 "Fruits of Philosophy" 3 "Population Question") rows(3) position(1) ring(0) bmargin(small) colgap(small) size(large)) xline(1877, lcolor(black) lwidth(medthick)) name(f_year, replace) 
	
	
graph combine f_month f_year, xsize(11)
	graph export "$results/F3_BNA_article_time_series.pdf", replace

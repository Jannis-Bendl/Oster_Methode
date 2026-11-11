*********************************************************************************************
***************** 	     FIGURE A11: Number of collabos by categ  *********************************
*********************************************************************************************
quietly {
use  "$Data_origin/Collaboration/collabosPaillole.dta", clear 
	graph bar N_RNP N_MIL N_PPF N_LVF N_GO N_MSR N_SRA N_SOL N_FRA N_COLE  N_GRC N_SD N_SS, bargap(10) ///
	ytitle("Number" " ") ///
		ylabel(0(2000)18000, angle(horizontal) labsize(small)) ///
		legend(size(tiny) row(6) order(1 "RNP (National Popular Rally)" 2 "Milice" 3  "PPF (French Popular Party)"  4 "Legion of French Volunteers" 5 "Gestapo" 6 "Revolutionary Social Movement" 7 "German Intelligence Service" 8 "SOL" 9 "Francist Movement" 10 "Economic collaboration" 11 "Groupe collaboration" 12 "Sicherheitsdienst (security)" 13 "SS")) ///
		graphregion(color(white)) 
		graph export "$Results/Figures/FigureA11.pdf", name(Graph) replace
}

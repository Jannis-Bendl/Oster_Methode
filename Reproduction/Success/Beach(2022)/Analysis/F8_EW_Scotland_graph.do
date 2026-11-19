use year englandwales scotland using "$data_dir/mitchell_data.dta", clear

two line englandwales year, lw(medthick) xlabel(1840(10)1910, grid notick) ylabel(15(10)45, grid notick angle(0)) xline(1877, lw(medthick) lcolor(black*.5)) ytitle("") title("England and Wales") name(ew, replace) yscale(range(15,45))

two line scotland year, lw(medthick) xlabel(1840(10)1910, grid notick) ylabel(15(10)45, grid notick angle(0)) xline(1877, lw(medthick) lcolor(black*.5)) ytitle("") title("Scotland") name(scotland, replace) yscale(range(15,45))

graph combine ew scotland
graph export "$results/F8_EW_Scotland_graph.pdf", replace

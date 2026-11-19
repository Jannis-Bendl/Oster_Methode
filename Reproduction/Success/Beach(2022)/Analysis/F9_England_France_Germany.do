use year englandwales france germany using "$data_dir/mitchell_data.dta", clear

two line englandwales france germany year, lw(medthick medthick medthick) lcolor(black black*.6 black*.3) lpattern(solid dash_dot long_dash) xlabel(1840(10)1910, grid notick) ylabel(15(10)45, grid notick angle(0)) xline(1877, lw(medthick) lcolor(black*.5)) ytitle("") yscale(range(15,45)) legend(rows(1))

graph export "$results/F9_England_France_Germany.pdf", replace

use "$data_dir/mitchell_data.dta" if inrange(year,1840,1900), clear

foreach x in austria belgium denmark finland france germany greece hungary ireland norway serbia switzerland romania russia sweden {
two line `x' year, lw(medthick) xlabel(1840(20)1900, grid notick) ylabel(20(15)50, grid notick angle(0)) xline(1877, lw(medthick) lcolor(black*.5)) ytitle("") title(`: var label `x'') name(`x', replace) yscale(range(20,50))	
	
}

graph combine austria belgium denmark finland france germany greece hungary ireland norway serbia switzerland romania russia sweden

graph export "$results/F10_Other_Euro_Fertility.pdf", replace

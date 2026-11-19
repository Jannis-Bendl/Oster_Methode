use district articles_own using "$temp_dir/EW_DD_cleaned.dta", clear
	duplicates drop

merge 1:m district using "$temp_dir/EW_dist_ids.dta", keep(3) nogen

spmap articles_own using "$temp_dir/distcoor.dta", id(id) clmethod(quantile) clnumber(5) fcolor(Greys2) legenda(on) leglabel("Other") legend(position(11))
graph export "$results/F17_BNA_map.pdf", replace


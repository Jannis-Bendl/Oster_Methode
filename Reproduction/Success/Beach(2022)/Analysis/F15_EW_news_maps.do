use district opened_75_77 pre_75_papers opened_78_80 comparison_75_80 using "$temp_dir/EW_DD_cleaned.dta", clear
	duplicates drop

merge 1:m district using "$temp_dir/EW_dist_ids.dta", keep(3) nogen

*** Graph variables
gen treat_control=1
replace treat_control=2 if opened_78_80==1
replace treat_control=3 if opened_75_77==1

**** Graphs
spmap pre_75_papers using "$temp_dir/distcoor.dta", id(id) clmethod(quantile) clnumber(5) fcolor(Greys2) legenda(on) leglabel("Other") legend(position(11))
graph export "$results/F15_EW_news_maps_a.pdf", replace

spmap treat_control using "$temp_dir/distcoor.dta", id(id) clmethod(unique) fcolor(Greys2) legenda(on) leglabel("Other") legend(label(2 "Other") label(3 "Control") label(4 "Treated") position(11))
graph export "$results/F15_EW_news_maps_b.pdf", replace

use bplcountry age occisco origin using "$data_dir/Canada/Canada_1881_Raw_IPUMS_00001.dta" if inrange(age,23,62), clear

	ren bplcountry bplcntry
	
	gen heap_counter=(inlist(age,25,30,35,40,45,50,55,60)) if bplcntry==24020 
	gen tot_counter=1 if bplcntry==24020 
	
	
	gen occ_professional=(inlist(occisco,1,2,3)) if occisco!=99
	gen occ_clerk=(inlist(occisco,4,5)) if occisco!=99
	gen occ_ag=(inlist(occisco,6)) if occisco!=99
	gen occ_crafts=(inlist(occisco,7)) if occisco!=99
	
	gen british=(inrange(origin,2000,2600))
		
	collapse occ_professional occ_clerk occ_ag occ_crafts (sum) heap_counter tot_counter, by(british)
		
	gen whipple_index=(heap_counter/tot_counter)*500
		drop heap_counter tot_counter
		
	label var occ_professional "Professionals"
	label var occ_clerk "Clerks"
	label var occ_ag "Agriculture"
	label var occ_crafts "Craftsmen"
	label var whipple_index "Whipple Index"
	
	ren british origin
	
	tostring origin, replace
	
	replace origin ="British" if origin=="1"
	replace origin = "Non-British" if origin=="0"
	
	sort origin

	foreach x in occ_professional occ_clerk occ_ag occ_crafts whipple_index {
		
		replace `x'=floor(`x'*1000)/1000
	}
	
	
	cd "$results"
	texsave using T8_Canada_origin_comparisons, replace

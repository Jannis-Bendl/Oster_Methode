*Generate annual dataset
use "$data_dir/England_and_Wales/district_pop_by_age_combined.dta", clear

*Define fertile population as (female) 15-50
gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F

collapse (sum) pop_fertile_F, by(district year)

egen dist_code=group(district)
xtset dist_code year
tsfill

sort dist_code year

	sort dist_code year
	replace district=district[_n-1] if district=="" & dist_code==l.dist_code

sort dist_code year
by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)

keep dist_code district year pop_fertile_F_int

merge 1:1 district year using "$data_dir/England_and_Wales/marriage_data_district_standardized.dta", keep(3) keepusing(marriages_total) nogen

merge 1:1 district year using "$data_dir/England_and_Wales/district_births_data_standardized.dta", keep(3) keepusing(births) nogen


gen birth_rate=births/(pop_fertile_F_int/1000)
gen mar_rate=marriages_total/(pop_fertile_F_int/1000)

keep district dist_code year birth_rate mar_rate
compress

save "$temp_dir/F20_T29_panel.dta", replace

*Grab district characteristics
use district comparison_75_80 opened_75_77 using "$temp_dir/EW_DD_cleaned.dta" if comparison_75_80==1, clear

duplicates drop	

merge 1:m district using "$temp_dir/F20_T29_panel.dta", keep(3) nogen


*Now to generate counterfactual birth rate
*In T28 we learned that marriages fell by .258 marriages per 1000 fertile women (SE =0.090)
gen counter_mar_rate=mar_rate
replace counter_mar_rate=mar_rate+(0.258+1.96*0.090)*opened_75_77 if year>1877

gen diff=counter_mar_rate-mar_rate


/*	Now to generate birth rate (at end of 95% confidence interval) that 
	accounts for any marriage effects. Note we use coefficients from
	F 19 AR figure*/
sort dist_code year

gen counter_birth_rate=birth_rate
replace counter_birth_rate=birth_rate+diff*(.3684398)+l.diff*(.5234296)+l2.diff*(.2762385)+l3.diff*(.1248195) if year>1877

keep district year birth_rate counter_birth_rate opened_75_77
compress
save "$temp_dir/F20_T29_panel.dta", replace

use "$data_dir/Canada/Canada_1881_Raw_IPUMS_00001.dta", clear
	ren geo1_ca1881 provca
	ren bplcountry bplcntry
	
*Zero in on households with at least one relevant fertile aged woman
*Widest net will be women between 15 and 49 as of 1878 or as of 1872.
gen age_78=age-3
gen age_72=age-9

gen fertile_woman=(sex==2 & inrange(age_78,15,49))
replace fertile_woman=1 if sex==2 & inrange(age_72,15,49)
	
bys serial: egen num_fertile_women=total(fertile_woman)
drop if num_fertile_women==0

*Throw out any household where one or more members are missing their age
	gen missing_info=(age==999 | origin==9999 | sursim==99 | marst==9 | marst==3 | sex==9)
	bys serial: egen drop_hh=max(missing_info)

	drop if drop_hh==1
	drop drop_hh missing_info

*Throw out very large households
	gen _temp=1
	bys serial: egen hh_size=total(_temp)
	*tab hh_size
	drop if hh_size>16
	drop _temp

*Throw out HH containing records that are likely errors.
	gen bad_record=(age<13 & marst!=1)
	bys serial: egen bad_hh=max(bad_record)
	
	drop if bad_hh==1
	drop bad_record bad_hh
	
unique serial //680154

*Identify total number of different surnames
	by serial: egen num_names=max(sursim)

*Discard obvious single boarders
	egen sub_fam=group(serial sursim)
	
	bys sub_fam: egen head_loc=min(pernum)
	
	gen _temp=occisco if pernum==head_loc
	
	bys sub_fam: egen head_occ=max(_temp)
		drop _temp
	
	gen counter=1
	
	bys sub_fam: egen sub_fam_size=total(counter)
	
	*Save the fertile women as childless
	preserve
	keep if sub_fam_size==1 & marst!=2 & fertile_woman==1
	
	
	keep serial pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}
	
	gen childless=1
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore
	
	drop if sub_fam_size==1 & marst!=2 //Drop men and women

gen married_woman=(marst==2 & sex==2)
gen married_man=(marst==2 & sex==1)
gen widow=(marst==4)

bys sub_fam: egen num_fertile_women_sub=total(fertile_woman)
bys sub_fam: egen num_married_women=total(married_woman)
bys sub_fam: egen num_married_men=total(married_man)
bys sub_fam: egen num_widows=total(widow)
	
*Save full data set so far
	compress
	save "$temp_dir/Candian_to_sort", replace

*************************************************************************	
** Simplest starting point: One married man, one married woman, and no ** 
** widows in subfamily. Assume all remaining individuals are kids 	   **
*************************************************************************	
	keep if num_married_women==1 & num_married_men==1 & num_widows==0
	
	*Take fertile-aged unmarried women and classify as childless
	preserve
		keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore
	
	*Now infer fertility among married women
	keep if married_woman==1 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort", keep(3)

	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50 & pernum>mom_pernum)

	gen birth_yr=1881-age-1	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1)
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1)
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1)
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1)
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1)
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1)
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	
	*Now back to main data set
	use "$temp_dir/Candian_to_sort",clear
	drop if num_married_women==1 & num_married_men==1 & num_widows==0
	
	*Reset fertile woman counter
		drop num_fertile_women
		bys serial: egen num_fertile_women=total(fertile_woman)
		drop if num_fertile_women==0
	
		compress
		save "$temp_dir/Candian_to_sort", replace
	
******************************************************************************
** Subfamilies with one widow and no married. Assume other HH members are	** 
** children of the widow 													**
******************************************************************************
use "$temp_dir/Candian_to_sort", clear

keep if num_widows==1 & num_married_men==0 & num_married_women==0

*Take non-widowed women and classify as childless
	preserve
		keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore

*Identify births among relevant fertile aged women	
keep if marst==4 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort", keep(3)

	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50 & pernum>mom_pernum)

	gen birth_yr=1881-age-1	
	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1)
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1)
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1)
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1)
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1)
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1)
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace

	*Now back to main data set
	use "$temp_dir/Candian_to_sort",clear
	drop if num_widows==1 & num_married_men==0 & num_married_women==0
	
	*Reset fertile woman counter
	drop num_fertile_women
	bys serial: egen num_fertile_women=total(fertile_woman)
	drop if num_fertile_women==0
	
	compress
	save "$temp_dir/Candian_to_sort", replace
		

*One married couple in the subfamily living with widows.
	use "$temp_dir/Candian_to_sort", clear	
	
	keep if num_married_men==1 & num_married_women==1 & num_widow==1
	
	*Drop widow from HH if they are enumerated last or first
	bys sub_fam: egen min_enumerated=min(pernum)
	bys sub_fam: egen max_enumerated=max(pernum)
	
	drop if marst==4 & pernum==max_enumerated
	drop if marst==4 & pernum==min_enumerated
	
	bys sub_fam: egen num_widow2=total(widow)
	keep if num_widow2==0
	
	*Save flag to drop these sub families later
	preserve
		keep serial sub_fam
		duplicates drop
		
		merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort"
		gen _temptodrop=(_merge==3)
		drop _merge
		save "$temp_dir/Candian_to_sort", replace
	restore

	*Save unmarried fertile (single) women as childless
	preserve
		keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore
	
	*Now infer fertility among married women
	keep if married_woman==1 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort", keep(3)
		drop if marst==4 //drop the widow
		
	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50 & pernum>mom_pernum)

	gen birth_yr=1881-age-1	
	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1)
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1)
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1)
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1)
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1)
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1)
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	
	*Now back to main data set
	use "$temp_dir/Candian_to_sort",clear
	drop if _temptodrop==1
	drop _temptodrop
		
	*Reset fertile woman counter
		drop num_fertile_women
		bys serial: egen num_fertile_women=total(fertile_woman)
		drop if num_fertile_women==0
	
		compress
		save "$temp_dir/Candian_to_sort", replace

		
** Now that we've done our best to deal with subfamily patterns, let's 
** zoom out to the serial level, which allows us to relax assumptions
** about surname changes.

drop num_married_women num_married_men num_widows

bys serial: egen num_married_women=total(married_woman)
bys serial: egen num_married_men=total(married_man)
bys serial: egen num_widows=total(widow) 

*Throw out households that are too complicated
unique serial if num_widows>1 | num_married_men>1 | num_married_women>1 //19829

drop if num_widows>1
drop if num_married_men>1
drop if num_married_women>1

compress
save "$temp_dir/Candian_to_sort", replace
		
keep if num_married_women==1 & num_married_men==1 & num_widows==0

*Take fertile-aged unmarried women and classify as childless
	preserve
		keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore
	
	*Now infer fertility among married women
	keep if married_woman==1 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial using "$temp_dir/Candian_to_sort", keep(3)

	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50)

	gen birth_yr=1881-age-1	
	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1)
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1)
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1)
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1)
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1)
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1)
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	
	*Now back to main data set
	use "$temp_dir/Candian_to_sort",clear
	drop if num_married_women==1 & num_married_men==1 & num_widows==0
	
	*Reset fertile woman counter
		drop num_fertile_women
		bys serial: egen num_fertile_women=total(fertile_woman)
		drop if num_fertile_women==0
	
		compress
		save "$temp_dir/Candian_to_sort", replace

		
** Try to deal with the households living with a widowed in law
	use "$temp_dir/Candian_to_sort", clear	
	
	keep if num_married_men==1 & num_married_women==1 & num_widow==1
	
	*Drop widow from HH if they are enumerated last or first
	bys serial: egen min_enumerated=min(pernum)
	bys serial: egen max_enumerated=max(pernum)
	
	drop if marst==4 & pernum==max_enumerated
	drop if marst==4 & pernum==min_enumerated
	
	bys serial: egen num_widow2=total(widow)
	
	keep if num_widow2==0
	
	*Save flag to drop these sub families later
	preserve
		keep serial sub_fam
		duplicates drop
		
		merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort"
		gen _temptodrop=(_merge==3)
		drop _merge
		save "$temp_dir/Candian_to_sort", replace
	restore

	*Save unmarried fertile (single) women as childless
	preserve
		keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	restore
	
	*Now infer fertility among married women
	keep if married_woman==1 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort", keep(3)
		drop if marst==4 //drop the widow
		
	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50)

	gen birth_yr=1881-age-1	
	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1)
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1)
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1)
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1)
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1)
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1)
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	
	*Now back to main data set
	use "$temp_dir/Candian_to_sort",clear
	drop if _temptodrop==1
	drop _temptodrop
		
	*Reset fertile woman counter
		drop num_fertile_women
		bys serial: egen num_fertile_women=total(fertile_woman)
		drop if num_fertile_women==0
	
		compress
		save "$temp_dir/Candian_to_sort", replace

		
* Let's deal with the incomplete households

*Married males with no spouse present and no widows, assume that all single women are childless kids

keep if num_married_men==1 & num_married_women==0

keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
		

use "$temp_dir/Candian_to_sort", clear
drop if num_married_men==1 & num_married_women==0
compress 
save "$temp_dir/Candian_to_sort", replace

** Married women with no spouse present and no widows
keep if num_married_women==1 & num_married_men==0 & num_widows==0

*Assume any single fertile women in HH are childless
preserve
keep if fertile_woman==1 & marst==1
	
		keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
		foreach x in pernum age marst bplcntry origin religiond occisco {
			ren `x' mom_`x'
		}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
restore

	keep if married_woman==1 & fertile_woman==1

	keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
	foreach x in pernum age marst bplcntry origin religiond occisco {
		ren `x' mom_`x'
	}

	merge 1:m serial sub_fam using "$temp_dir/Candian_to_sort", keep(3)
		
	gen potential_birth=((mom_age-age)>=13 & (mom_age-age)<=50)

	gen birth_yr=1881-age-1	
	
	gen birth_counter_pre72=(birth_yr<1872 & potential_birth==1)
	gen birth_counter_72_77=(inrange(birth_yr,1872,1877) & potential_birth==1) // 3, 4, 5, 6, 7, 8
	gen birth_counter_74_77=(inrange(birth_yr,1874,1877) & potential_birth==1) // 3, 4, 5, 6
	gen birth_counter_74_76=(inrange(birth_yr,1874,1876) & potential_birth==1) // 4, 5, 6
	gen birth_counter_75_77=(inrange(birth_yr,1875,1877) & potential_birth==1) // 3, 4, 5
	gen birth_counter_76_77=(inrange(birth_yr,1876,1877) & potential_birth==1) // 3, 4
	
	gen birth_counter_78_81=(inrange(birth_yr,1878,1880) & potential_birth==1) //0, 1, 2
	
	collapse (sum) birth_counter_*, by(serial mom_pernum mom_age mom_marst mom_bplcntry mom_religiond mom_origin mom_occisco head_occ)
	
	gen childless=(birth_counter_pre72+birth_counter_72_77+birth_counter_78_81==0)
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace
	
	
***
use "$temp_dir/Candian_to_sort", clear
	drop if num_married_women==1 & num_married_men==0 & num_widows==0	
		compress
		save "$temp_dir/Candian_to_sort", replace


*no married individuals and no widows... assume all are childless
keep if num_married_women==0 & num_married_men==0 & num_widows==0	

keep if fertile_woman==1

keep serial sub_fam pernum age marst bplcntry origin religiond occisco head_occ
foreach x in pernum age marst bplcntry origin religiond occisco {
	ren `x' mom_`x'
	}
		
		gen childless=1
	
	append using "$temp_dir/Canadian_Microdata.dta"
	save "$temp_dir/Canadian_Microdata.dta", replace

	
use "$temp_dir/Candian_to_sort", clear
	drop if num_married_women==0 & num_married_men==0 & num_widows==0
		compress
		save "$temp_dir/Candian_to_sort", replace	

unique serial //(680154-19829-6601)/680154	
	
**	At this point we've matched fertility histories for 96% of HH with at least one fertile aged woman 	**

*Clean Births data set
*Grab geographic variables and attach to mom observations
use serial distca geo1_ca1881 using "$data_dir/Canada/Canada_1881_Raw_IPUMS_00001.dta", clear
	ren geo1_ca1881 provca
	
	duplicates drop

merge 1:m serial using "$temp_dir/Canadian_Microdata.dta", keep(3) nogen

*Recode missing counters as 0 for those inferred as childless
foreach x in birth_counter_pre72 birth_counter_72_77 birth_counter_74_77 birth_counter_74_76 birth_counter_75_77 birth_counter_76_77 birth_counter_78_81 {
	replace `x'=0 if childless==1
}


gen inferred_couple_72_77=(birth_counter_pre72>0)
gen inferred_couple_78_81=((birth_counter_pre72+birth_counter_72_77)>0)

reshape long birth_counter_ inferred_couple_, i(serial mom_*) j(period) string

ren inferred_couple_ inferred_couple

gen bc_scaled=.
replace bc_scaled=(1000*birth_counter)/6 if period=="72_77"
replace bc_scaled=(1000*birth_counter)/3 if period=="78_81"

replace bc_scaled=(1000*birth_counter)/3 if period=="74_76"
replace bc_scaled=(1000*birth_counter)/4 if period=="74_77"
replace bc_scaled=(1000*birth_counter)/3 if period=="75_77"
*replace bc_scaled=(1000*birth_counter)/2 if period=="76_77"

*Identify those moms that we think are already married by start of period_fe


*Identify mom's age at start of period
ren mom_age mom_age_1881

gen mom_age=mom_age_1881-3 if period=="78_81"
replace mom_age=mom_age_1881-9 if period=="72_77"
replace mom_age=mom_age_1881-7 if period=="74_76"
replace mom_age=mom_age_1881-7 if period=="74_77"
replace mom_age=mom_age_1881-6 if period=="75_77"

drop mom_age_1881

keep if inrange(mom_age,15,49)
	
	*Bin mom's age
	gen mom_age_binned=floor(mom_age/5)
	replace mom_age_binned=mom_age_binned*5
	
	*Generate age X period fixed effects
	egen age_binXyear=group(mom_age_binned period)
	
*Generate other fixed effects
egen period_fe=group(period)
egen distXyear=group(distca period)

*Head occ by period FEs
egen head_occXyear=group(head_occ period)
	
gen mom_british=(inrange(mom_origin,2000,2600))
	
gen britXpost=(mom_british==1 & period=="78_81")
label var britXpost "British $\times$ Post 1877"

keep bc_scaled mom_british britXpost period period_fe distXyear age_binXyear head_occXyear distca provca inferred_couple mom_origin mom_religiond mom_age

compress
save "$temp_dir/Canadian_Microdata.dta", replace

use "$data_dir/United_States/1880_US_IPUMS_extract.dta" if inrange(age,15,54) & sex==2, clear
	drop momloc momrule sex
	
	ren pernum momloc
	ren age mom_age
	ren bpl mom_bpl
	ren mbpl mom_mbpl
	ren fbpl mom_fbpl
	
	*Use spouses occupation if available
	replace occ=occ_sp if occ_sp!=.

	gen occ_broad=.
		replace occ_broad=1 if inrange(occ,1,12) //agriculture
		replace occ_broad=2 if inrange(occ,13,58) //Professional and Personal Services
		replace occ_broad=3 if inrange(occ,59,129) //Trade and Transport
		replace occ_broad=4 if inrange(occ,130,291) //Manufacturing, Mechanical, and Mining Industries
		replace occ_broad=5 if inrange(occ,301,310) //Not in labor force
		
		drop if occ_broad==.
		
		drop occ
		ren occ_broad occ

			
*Categorize Birthplace info
	keep if inrange(mom_bpl,1,99) & inrange(mom_mbpl,400,498) & inrange(mom_fbpl,400,498)
		drop if mom_mbpl==414 | mom_fbpl==414 //Drop irish-origin
		
		gen british_hh=(inrange(mom_fbpl,410,413) & inrange(mom_mbpl,410,413))
		
		gen mom_euro_origin=(british_hh==0)
			replace mom_euro_origin=0 if inrange(mom_fbpl,410,414) | inrange(mom_mbpl,410,414) //Remove mixed origin
		
keep if british_hh==1 | mom_euro_origin==1

keep serial statefip countyicp momloc mom_age british_hh marst occ
	
	
merge 1:m serial momloc using "$data_dir/United_States/1880_US_IPUMS_extract.dta", keep(1 3) keepusing(age momrule)

*Throw out households with weird patterns
	*Bad linking rules
	gen keep_flag=(momrule==1 | momrule==.)

	bys serial: egen keep_flag2=max(keep_flag)

	keep if keep_flag2==1
		drop keep_flag keep_flag2

	*Suspiciously large families
	gen _temp=1
	bys serial: egen hh_size=total(_temp)
	
	preserve
		keep serial hh_size
		duplicates drop
	
		sum hh_size, d
	restore
	
	drop if hh_size>r(p99)	
	drop _temp hh_size
	
	*Suspicious ages
	gen mom_age_at_birth=mom_age-age
	
	gen flag=(mom_age_at_birth<13 | mom_age_at_birth>50)
		replace flag=0 if mom_age_at_birth==.
		
	bys serial: egen drop_flag=max(flag)
	
	drop if drop_flag==1
		drop flag drop_flag


	gen childless=(_merge==1)
	drop _merge
	
	ren age child_age
	
egen hh_id=group(serial momloc)
	drop serial momloc
	
egen cnty_id=group(statefip countyicp)
	
*Now to prep for panel structure -- note that as of date was June so ages straddle two years		
gen bc_1878_1880=(inrange(child_age,0,1))
gen num_kids_1878_1880=(child_age>1)


gen bc_1873_1877=(inrange(child_age,3,6))
gen num_kids_1873_1877=(child_age>6)

gen bc_1873_1876=(inrange(child_age,4,6))
gen num_kids_1873_1876=(child_age>6)

gen bc_1872_1876=(inrange(child_age,4,7))
gen num_kids_1872_1876=(child_age>7)

gen bc_1872_1877=(inrange(child_age,3,7))
gen num_kids_1872_1877=(child_age>7)


collapse (sum) bc_* num_kids_*, by(statefip cnty_id hh_id british_hh mom_age marst occ) 

reshape long bc num_kids, i(statefip cnty_id hh_id british_hh mom_age marst occ) j(period) string

//Move from births per woman per year to births per 1000 women per year
replace bc=1000*(bc/2) if period=="_1878_1880"
replace bc=1000*(bc/4) if period=="_1873_1877"
replace bc=1000*(bc/3) if period=="_1873_1876"
replace bc=1000*(bc/5) if period=="_1872_1877"
replace bc=1000*(bc/4) if period=="_1872_1876"


*Calculate mom's age at start of period
replace mom_age=mom_age-2 if period=="_1878_1880"
replace mom_age=mom_age-7 if period=="_1873_1877"
replace mom_age=mom_age-7 if period=="_1873_1876"
replace mom_age=mom_age-8 if period=="_1872_1877"
replace mom_age=mom_age-8 if period=="_1872_1876"

keep if inrange(mom_age,15,49)

		
		
	*Define treatment
	gen post_bb=(period=="_1878_1880")
		
	gen post_bbXbritish=(post_bb==1 & british_hh==1)
				
	egen cntyXbirth_yr=group(cnty_id period)
	egen stateXbirth_yr=group(state period)
		
		gen mom_age_binned=floor(mom_age/5)
			replace mom_age_binned= mom_age_binned*5
		
		egen momageXyear=group(mom_age_binned period)
		
		forv x=15(5)45 {
			gen mom_`x'_british=(british_hh==1 & mom_age_binned==`x')
			gen mom_`x'_britishXpost=(post_bbXbritish==1 & mom_age_binned==`x')
			
		}	
		
		*Occ X 
		egen occXyear=group(occ period)

/*	Preferred specification splits by marital status and has: occ X year, 
	age X year, and cnty X year fixed effects. Make sure to drop singletons
	to maintain consistent observations across columns */
	
	gen _tempcounter=(marst!=6)
	
	foreach x in occXyear cntyXbirth_yr momageXyear {
		bys `x': egen tot_obs=total(_tempcounter)
	drop if tot_obs==1
	drop tot_obs
	
	}
	
	replace _tempcounter=(marst==6)
	
	foreach x in occXyear cntyXbirth_yr momageXyear {
	bys `x': egen tot_obs=total(_tempcounter)
	drop if tot_obs==1
	drop tot_obs
	
	}
	
	drop _tempcounter
		
	label var post_bbXbritish "British $\times$ Post 1877"	
	
	compress
	save "$temp_dir/US_Microdata.dta", replace

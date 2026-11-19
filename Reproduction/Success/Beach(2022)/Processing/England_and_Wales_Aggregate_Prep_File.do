use "$data_dir/England_and_Wales/district_births_data_standardized.dta", clear

gen period=""
	replace period="1853-1857" if inrange(year,1853,1857)
	replace period="1858-1862" if inrange(year,1858,1862)
	replace period="1863-1867" if inrange(year,1863,1867)
	replace period="1868-1872" if inrange(year,1868,1872)
	replace period="1873-1877" if inrange(year,1873,1877)
	replace period="1878-1882" if inrange(year,1878,1882)
	replace period="1883-1887" if inrange(year,1883,1887)
	replace period="1888-1892" if inrange(year,1888,1892)

	drop if period==""
	
	collapse births, by(district period)
	

save "$temp_dir/districtXperiod_birthrates", replace


*Now grab fertile population by period
use "$data_dir/England_and_Wales/district_pop_by_age_combined", clear

*Define fertile population as (female) 15-50
gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F

collapse (sum) pop_fertile_F, by(district year)

*Now to fill in for other periods
egen dist_code=group(district)

xtset dist_code year, delta(1)
tsfill

	*Carry forward district name
		sort dist_code year
			replace district=district[_n-1] if district=="" & dist_code==l.dist_code

	*interpolate population
		sort dist_code year
			by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)

	
*Define periods
gen period=""
	replace period="1853-1857" if inrange(year,1853,1857)
	replace period="1858-1862" if inrange(year,1858,1862)
	replace period="1863-1867" if inrange(year,1863,1867)
	replace period="1868-1872" if inrange(year,1868,1872)
	replace period="1873-1877" if inrange(year,1873,1877)
	replace period="1878-1882" if inrange(year,1878,1882)
	replace period="1883-1887" if inrange(year,1883,1887)
	replace period="1888-1892" if inrange(year,1888,1892)
	
	drop if period==""
	
	collapse pop_fertile_F_int, by(district period)
	
*Now merge with births data	
merge 1:1 district period using "$temp_dir/districtXperiod_birthrates", keep(3) nogen
	rm "$temp_dir/districtXperiod_birthrates.dta"
	
gen birth_rate=births/(pop_fertile_F_int/1000)

keep district period birth_rate

merge m:1 district using "$data_dir/England_and_Wales/EW_District_Chars.dta", keep(3) nogen
	
	replace region="Midlands" if inlist(region,"north_mid", "south_mid","west_mid")
	replace region="Wales" if region=="wales"
	
	*replace region="Midlands and Wales" if inlist(region,"north_mid", "south_mid","west_mid","wales")
	replace region="London" if inlist(region,"london")
	replace region="Southern" if inlist(region,"southeast", "southwest","east")
	replace region="Northern" if inlist(region,"north", "northwest","yorkshire")
	
	drop if region=="London"
	
	
	*Identify num. established papers
	gen pre_73_papers=established_papers+new_papers_1867+new_papers_1868+new_papers_1869+new_papers_1870+new_papers_1871+new_papers_1872
	gen pre_74_papers=pre_73_papers+new_papers_1873
	gen pre_75_papers=pre_74_papers+new_papers_1874
	gen pre_76_papers=pre_75_papers+new_papers_1875
		
	
	*Smaller windows

	*76-79
	gen opened_76_77=new_papers_1876+new_papers_1877
	
	gen opened_78_79=new_papers_1878 + new_papers_1879
	
	gen control_76_79=(opened_76_77==0 & opened_78_79>0)
	
	gen comparison_76_79=(opened_76_77>0 | control_76_79==1)
	
	gen comparison_76_79_alt=(opened_76_77>0 & opened_78_79==0)
	replace comparison_76_79_alt=1 if control_76_79==1
	
	gen comparison_76_79_strict=(opened_76_77==1 & opened_78_79==0)
	replace comparison_76_79_strict= 1 if opened_76_77==0 & opened_78_79==1

	
	*75-80
	gen opened_75_77=new_papers_1875+opened_76_77
	
	gen opened_78_80=new_papers_1880 + opened_78_79
	
	gen control_75_80=(opened_75_77==0 & opened_78_80>0)
	
	gen comparison_75_80=(opened_75_77>0 | control_75_80==1)
	
	gen comparison_75_80_alt=(opened_75_77>0 & opened_78_80==0)
	replace comparison_75_80_alt=1 if control_75_80==1
	
	
	gen comparison_75_80_strict=(opened_75_77==1 & opened_78_80==0)
	replace comparison_75_80_strict= 1 if opened_75_77==0 & opened_78_80==1
	
	
	*74-81
	gen opened_74_77=new_papers_1874+opened_75_77
	gen opened_78_81=new_papers_1881+opened_78_80
	
	gen control_74_81=(opened_74_77==0 & opened_78_81>0)
	
	gen comparison_74_81=(opened_74_77>0 | control_74_81==1)
	
	gen comparison_74_81_alt=(opened_74_77>0 & opened_78_81==0)
	replace comparison_74_81_alt=1 if control_74_81==1
	
	gen comparison_74_81_strict=(opened_74_77==1 & opened_78_81==0)
	replace comparison_74_81_strict= 1 if opened_74_77==0 & opened_78_81==1
	
	*73-82 is baseline
	gen opened_73_77=new_papers_1873+opened_74_77
	gen opened_78_82=new_papers_1882+opened_78_81
	
	gen control_73_82=(opened_73_77==0 & opened_78_82>0)
	
	gen comparison_73_82=(opened_73_77>0 | control_73_82==1)

	gen comparison_73_82_alt=(opened_73_77>0 & opened_78_82==0)
	replace comparison_73_82_alt=1 if control_73_82==1
	
	gen comparison_73_82_strict=(opened_73_77==1 & opened_78_82==0)
	replace comparison_73_82_strict= 1 if opened_73_77==0 & opened_78_82==1
	
	*72-83 
	gen opened_72_77=new_papers_1872+opened_73_77
	gen opened_78_83=new_papers_1883+opened_78_82
	
	gen control_72_83=(opened_72_77==0 & opened_78_83>0)
	
	gen comparison_72_83=(opened_72_77>0 | control_72_83==1)

	
	*71-84
	gen opened_71_77=new_papers_1871+opened_72_77
	
	gen opened_78_84=new_papers_1884+opened_78_83
	
	gen control_71_84=(opened_71_77==0 & opened_78_84>0)
	
	gen comparison_71_84=(opened_71_77>0 | control_71_84==1)
	
	
	*70-85
	gen opened_70_77=new_papers_1870+opened_71_77
	gen opened_78_85=new_papers_1885+opened_78_84
	
	gen control_70_85=(opened_70_77==0 & opened_78_85>0)
	
	gen comparison_70_85=(opened_70_77>0 | control_70_85==1)
	
	
	*69-86
	gen opened_69_77=new_papers_1869+opened_70_77
	gen opened_78_86=new_papers_1886+opened_78_85
	
	gen control_69_86=(opened_69_77==0 & opened_78_86>0)
	
	gen comparison_69_86=(opened_69_77>0 | control_69_86==1)
	
	
	*68-87
	gen opened_68_77=new_papers_1868+opened_69_77
	gen opened_78_87=new_papers_1887+opened_78_86
	
	gen control_68_87=(opened_68_77==0 & opened_78_87>0)
	
	gen comparison_68_87=(opened_68_77>0 | control_68_87==1)
	
	
	
	
** Define data structure
	encode district, gen(dist_code)
	encode region, gen(region_code)

	*Generate year variable
	split period, parse("-")
		ren period1 year
			destring year, replace
		drop period2
	
	tsset dist_code year
	xtset dist_code year, delta(5)
	xi i.year i.dist_code i.region

*******************************************************************
** Define outcome variable of interest: Change in ln(Birth rate) **
*******************************************************************
		*Now take the difference
			gen chg_br=birth_rate-l.birth_rate

sort dist_code year
gen birth_rate_lagged=birth_rate[_n-1] if dist_code==dist_code[_n-1] & year==(year[_n-1]+5)
	
**************************
** Define RHS variables **
**************************

********************************************************************************
*First, define treatment *******************************************************
********************************************************************************

/*Because we are going to be looking at first differences and this is a
permanent shock, the only treated year is 1881.						 */
	gen post_BB_trial=(year>=1878)
	
	gen opened_75_77X1868=opened_75_77*_Iyear_1868
	gen opened_75_77X1878=opened_75_77*_Iyear_1878
	gen opened_75_77X1883=opened_75_77*_Iyear_1883
	
	label var opened_75_77X1868 "Newspaper openings (75-77) $\times$ \multicolumn{1}{r}{1868-1872 period}"
	label var opened_75_77X1878 "Newspaper openings (75-77) $\times$ \multicolumn{1}{r}{1878-1882 period}"
	label var opened_75_77X1883 "Newspaper openings (75-77) $\times$ \multicolumn{1}{r}{1883-1888 period}"
	
	
	gen pre_75_papersX1868=pre_75_papers*_Iyear_1868
	gen pre_75_papersX1878=pre_75_papers*_Iyear_1878
	gen pre_75_papersX1883=pre_75_papers*_Iyear_1883
			
	gen opened_76_77Xpost=opened_76_77*post_BB_trial
	gen opened_75_77Xpost=opened_75_77*post_BB_trial
	gen opened_74_77Xpost=opened_74_77*post_BB_trial
	gen opened_73_77Xpost=opened_73_77*post_BB_trial
	gen opened_72_77Xpost=opened_72_77*post_BB_trial
	gen opened_71_77Xpost=opened_71_77*post_BB_trial
	gen opened_70_77Xpost=opened_70_77*post_BB_trial
	gen opened_69_77Xpost=opened_69_77*post_BB_trial
	
	gen estXpost=pre_75_papers*post_BB_trial
		
			
/******** Preferred specification also includes interactions with other district 
characteristics in the trial decade *******************************************/
	gen density_71=total_pop_1871/area	
		label var density_71 "Population density, 1871"
		
		  
	*Generate the interaction between time and marriage/other district with post trial period	
	foreach i in mar_rate_73_77 shrmar_registrar_73_77 shrmar_catholic_73_77 shrmar_minors_73_77 shrmar_illit_73_77 shrmar_first_73_77 u30_fert_shr_1871 density_71 total_mr_71_80 under5_mr_71_80 illeg_birth_share_73_77 flfp_71 clfp_71 shr_manuf shr_agriculture {
	
		forv j=1868(5)1883 {
			gen `i'X`j'=`i'*_Iyear_`j'
		}		
	}
			
*Define marriage and district interactions	

	forv x=1868(5)1883 {	
		global mar_int_`x'  "mar_rate_73_77X`x' shrmar_registrar_73_77X`x' shrmar_catholic_73_77X`x' shrmar_minors_73_77X`x' shrmar_illit_73_77X`x' shrmar_first_73_77X`x'"		
		
		global dist_int_`x' "density_71X`x' total_mr_71_80X`x' under5_mr_71_80X`x' illeg_birth_share_73_77X`x' shr_manufX`x' shr_agricultureX`x' u30_fert_shr_1871X`x'"			
	}
	
egen regionXyearfes=group(region_code year)
		
compress		
save "$temp_dir/EW_DD_cleaned.dta", replace	

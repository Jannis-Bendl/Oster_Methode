use "$temp_dir/EW_DD_cleaned.dta", clear

matrix RES=(.,.,.)
		
*Loop over break years
forv x=1872/1882 {
preserve

	local lag_start=`x'-9
	local lag_end=`x'-5
	
	local pre_period_start=`x'-4
	local pre_period_end=`x'
	local post_period_start=`x'+1
	local post_period_end=`x'+5
	
*Now go back and generate fertility rates
use district births year using "$data_dir/England_and_Wales/district_births_data_standardized", clear
			
*Merge to get pop data
	merge 1:1 district year using "$data_dir/England_and_Wales/district_pop_by_age_combined", nogen keepusing(age_15_F age_20_F age_25_F age_30_F age_35_F age_40_F age_45_F)
	
	*Define fertile population as (female) 15-50
	gen pop_fertile_F=age_15_F +age_20_F +age_25_F +age_30_F +age_35_F +age_40_F+age_45_F
		
	*interpolate fertile pop.
	egen dist_code=group(district)

	xtset dist_code year, delta(1)
	tsfill

	*Carry forward district name
		sort dist_code year
			replace district=district[_n-1] if district=="" & dist_code==l.dist_code

	*interpolate population
		sort dist_code year
			by dist_code: ipolate pop_fertile_F year, gen(pop_fertile_F_int)
	


keep if inrange(year,`lag_start',`post_period_end')
	

gen period="1868-1872" if inrange(year,`lag_start',`lag_end')
replace period="1873-1877" if inrange(year,`pre_period_start',`pre_period_end')
replace period="1878-1882" if inrange(year,`post_period_start',`post_period_end')		

collapse births pop_fertile_F_int, by(district period)

gen birth_rate=births/(pop_fertile_F_int/1000)


keep district period birth_rate
merge 1:1 district period using "$temp_dir/EW_DD_cleaned.dta", keep(3) nogen


sort dist_code year
	replace birth_rate_lagged=birth_rate[_n-1] if dist_code==dist_code[_n-1] & year==(year[_n-1]+5)

*Now generate placebo news
local xm1=`x'-1
local xm2=`x'-2

local xp1=`x'+1
local xp2=`x'+2
local xp3=`x'+3


gen placebo_newly_opened=new_papers_`xm2'+new_papers_`xm1'+new_papers_`x'
gen placebo_nearly_opened=new_papers_`xp1'+new_papers_`xp2'+new_papers_`xp3'

gen placebo_comparison=(placebo_newly_opened>0)
replace placebo_comparison=1 if placebo_newly_opened==0 & placebo_nearly_opened>0

gen placeboopenedXpost=placebo_newly_opened*_Iyear_1878

*Identify established papers
local xm3=`x'-3
forv j=1867/`xm3' {
	replace established_papers=established_papers+new_papers_`j'
}

replace estXpost=established_papers*_Iyear_1878


eststo m_`x': reghdfe birth_rate birth_rate_lagged estXpost placeboopenedXpost [aweight=total_pop_1871] if placebo_comparison==1, absorb(year dist_code regionXyearfes) cluster(dist_code)

matrix RES=RES\(`x',_b[placeboopenedXpost],_se[placeboopenedXpost])

restore
}

		*esttab m_* using "$results/EW_placebo", keep(placeboopenedXpost) stats(r2) b(%10.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) csv replace	
		
		
svmat RES
keep RES1 RES2 RES3

	drop if RES1==.
	
	ren RES1 year
	ren RES2 Beta
	ren RES3 SE
	
	gen ci_high=Beta+1.96*SE
	gen ci_low=Beta-1.96*SE
	

	two (scatter Beta year if year!=1877, mcolor(black)) (scatter Beta year if year==1877, mcolor(black*.5) msymbol(S)) (rcap ci_high ci_low year if year!=1877, lcolor(black) lw(medthick)) (rcap ci_high ci_low year if year==1877, lcolor(black*.5) lw(medthick)), yline(0, lw(medthick)) xlabel(1872(2)1882, grid notick) ylabel(-8(4)4, grid notick angle(0)) ytitle("Estimated Impact on Birth Rates " "Using Alternative Break Dates") legend(off) xtitle("Treatment Year/Window") name(alt, replace)
	
	graph export "$results/F6_EW_Falsification.pdf", replace
	

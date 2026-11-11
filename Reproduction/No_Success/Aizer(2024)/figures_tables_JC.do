*"Does Job Corps Work? Impact Findings from the National Job Corps Study"

clear
set more off
cap log close
log using "JC_replication.log",replace
set scheme s1color // grpah scheme

gl path  ""
gl do_files $path/do_files
gl raw_data "$path/raw_data/20060076_data"
gl working_data $path/working_data
gl tables $path/Results/
gl out_files $path/Results/out_files
gl figures $path/Results/Figures

******************************************************
// 0. Program to store and format results in Excel                           
******************************************************

capture program drop excel_regout
program excel_regout, eclass

	* First argument is variable, second is cell letter third is cell number

	* p-value
	local t = _b[`1']/_se[`1']
	local p = 2*ttail(e(df_r),abs(`t'))

	* cells
	local coef_cell = "`2'" + string(`3')
	local se_cell = "`2'" + string(`3'+1)
	local obs_cell = "`2'" + string(`3'+2)

	* values
	local coef=round(_b[`1'],0.001)
	local se = round(_se[`1'],0.001)
	local obs = `e(N)'
	
	* Convert to strings
	local coef = string(`coef',"%12.3fc")
	local se = "(" + string(`se',"%12.3fc")+")"
	local obs = string(`obs',"%12.0gc")
	display "`coef'"
	display "`se'"
	display "`obs'"

	* add stars
	if `p' <=.1 {
	if `p' <=.05 {
	if `p' <=.01 {
	local coef = "`coef'" + "***"
	}
	else {
	local coef = "`coef'" + "**"
	}
	}
	else {
	local coef = "`coef'" + "*"
	}
	}
	putexcel `coef_cell'=("`coef'")
	putexcel `se_cell'=("`se'")
	putexcel `obs_cell'=("`obs'")
end

******************************************************
// 1. Data preparation                           
******************************************************

*** a) Load data
use "$raw_data/impact.dta", clear

	// i. key vars
	merge 1:1 mprid using "$raw_data/key_vars.dta", keepusing(agegroup female IN57 inpers nonres haschld AFTER_ZT WGT48B ARRST_GR APP_QTR H_CDATE B_CDATE treatmnt DSGN_WGT BASE_WGT RACE_ETH typearea inpers RESP_B RESP_48)
		drop _m

	// ii. baseline
	merge 1:1 mprid using "$raw_data/baseline.dta", keepusing(age currjob hgc HGC_MOTH HGC_FATH NTV_LANG HH14 WELF_KID HS_D GED_D evworkb YR_WORK1 mosinjob EARN_YR HRSWK_JR hrwager ///
															  GOTAFDC1 GOTFS1 GOT_ANYW EVARRST1 EV_* jcmsa marriage /// added from here on
															  hhmemb NUMB_HH numbjobs currjob OCC_R typehlth sick health mostimpr R_NOWORK evworkb)
	drop if _m ==2
	drop _m
	
	// iii. 48 months
	merge 1:1 mprid using "$raw_data/fu48_raw.dta", keepusing(H_F3* H_F23 H_F25 H_F26)
	drop if _m ==2
	drop _m
	
	// iv. reasons
	merge 1:1 mprid using "$raw_data/fu30_raw.dta", keepusing(G_B14A)
	drop if _m ==2
	drop _m
	
	merge 1:1 mprid using "$raw_data/fu12_raw.dta", keepusing(F_B14A)
	drop if _m ==2
	drop _m
	
	/* missing obs, only like 11K so don't use for now
	// iii. mileston
	merge 1:1 mrpid using "$raw_data/mileston.dta", keepusing(livespou everwork badhlth publich evarrst haschld spanish msa pmsa}
	drop _m
	*/ 
*** b) Create outome variables

	* i. Years of school
	g highgrade_48 = HGFIX1
	g highgrade_baseline = hgc
	
	* ii. Employment
	g employed = WORK208
	
	* iii. weeks worked - if missing for any quarter then just assume average of other quarters
	egen temp = rmean(PWORKQ13 PWORKQ14 PWORKQ15 PWORKQ16)
	replace temp = . if missing(PWORKQ13) & missing(PWORKQ14) & missing(PWORKQ15) & missing(PWORKQ16)
	g wksworked_prevyr = temp /100 * 52 
	
	* iii. Earnings conditional on employment
	g earnings = EARNY4 * 52 
		replace earnings = 0 if missing(earnings) & !missing(employed)
	g earnings_if_employed = EARNY4 * 52 if wksworked_prevyr>0 & !missing(wksworked_prevyr)
	g ln_earnings_if_employed = ln(earnings_if_employed) if wksworked_prevyr>0 & !missing(wksworked_prevyr)
	
	* iv. Moved
	
	g moved = DIST_A48 > 20 & !missing(DIST_A48)
	
	* v. Ever married
	g ever_married = inlist(H_F23,1,2,3,4) | inlist(H_F25,1) | inlist(marriage,2,4)| inlist(12,H_F3A,H_F3B,H_F3C,H_F3D,H_F3E,H_F3F,H_F3G,H_F3H,H_F3I,H_F3J,H_F3K,H_F3L,H_F3M,H_F3N,H_F3O) ///
					if !missing(H_F23) | !missing(H_F3A) | !missing(H_F25) // would use 11 if also count boyfriend or gf living together
	
	* vi. 
	gen health12 = HEALTH12 // health followup after 12 months 1-good 4-poor
	replace health12 = . if HEALTH12 == .e | HEALTH12 == .d // missing
	gen health30 = HEALTH30
	replace health30 = . if HEALTH30 == .e | HEALTH30 == .d // missing
	gen health48 = HEALTH48
	replace health48 = . if HEALTH48 == .e | HEALTH48 == .d // missing
	
	gen health_exc12 = health12 == 1
	replace health_exc12 = . if health12 == .
	gen health_exc30 = health30 == 1
	replace health_exc30 = . if health30 == .
	gen health_exc48 = health48 == 1
	replace health_exc48 = . if health48 == .
	
	gen health_excgd12 = (health12 == 1 | health12 == 2)
	replace health_excgd12 = . if health12 == .
	gen health_excgd30 = (health30 == 1 | health30 == 2)
	replace health_excgd30 = . if health30 == .
	gen health_excgd48 = (health48 == 1 | health48 == 2)
	replace health_excgd48 = . if health48 == .
	
	

	
*** c) Create control variables
	
	g duration = losjc /12 // convert to years
	
	replace duration =0 if missing(duration) & RESP_48 == 1 & everjc == 0
	
	g control = treatmnt != 1 if !missing(treatmnt)
	
	// ii. reasons
	replace F_B14A=. if F_B14A>19
	replace G_B14A=. if G_B14A>19|G_B14A<0

	g reason = .
		replace reason = F_B14A
		replace reason = 0 if G_B14A==0 // other
		replace reason = 1 if G_B14A==1 // completed program
		replace reason = 1 if G_B14A==8 // completed only GED portion
		replace reason =1 if reason ==2
		replace reason = 3 if G_B14A==2 // expelled
		replace reason = 4 if G_B14A==3 // Did not Like Program or Program Boring
		replace reason = 4 if G_B14A==9 // Dissatisfaction with the Quality of the Program
		replace reason = 4 if reason ==5 
		
		replace reason = 7 if G_B14A==6 // Did not Like Living at Center or Wanted to Go Home
		replace reason = 7 if G_B14A==10 // Did not Like/Get Along with Center Staff
		replace reason = 7 if G_B14A==11 // Did not Like/Get Along with other Students
		replace reason =7 if inlist(reason,8,9)
		replace reason = 10 if G_B14A==12 // Changed Center or Enrolled in other Program, School, or Course

		replace reason = 12 if G_B14A==4 // Pregnancy or Child Care Problem
		replace reason = 13 if G_B14A==7 // Got a Job or Needed a Job

		replace reason = 15 if G_B14A==13 // Own Health Problem or Injury
		replace reason = 16 if G_B14A==14 // Drug or Alcohol Problem
		replace reason = 12 if G_B14A==5 // Parental or Family Problem or Pressure
		replace reason = 12 if reason ==17
		
		replace reason = 0 if G_B14A==15 & missing(reason)

		replace reason = 4 if reason ==6
		replace reason =11 if reason ==11
		replace reason =7 if reason ==14
		replace reason = 7 if reason ==18
		
		replace reason = 19 if missing(reason) & everjc ==1
		
		
		g reason_ccc = .
			replace reason_ccc = 1 if reason == 1 // end of term
			replace reason_ccc = 2 if inlist(reason,13,10) // got a job
			replace reason_ccc = 3 if reason == 11 // center closed
			replace reason_ccc = 4 if inlist(reason,12,15) // urgent and proper call - is it appropriate to include own heatlh problem or injury?
			replace reason_ccc = 5 if inlist(reason,3,4,7,16) // deserted
			replace reason_ccc = 7 if inlist(reason,0,19) // No record
			
			
		g reason_ccc_endofterm = reason_ccc ==1 if !missing(reason_ccc)
		g reason_ccc_employment = reason_ccc ==2 if !missing(reason_ccc)
		g reason_ccc_cog = reason_ccc ==3 if !missing(reason_ccc)
		g reason_ccc_urgandprop = reason_ccc ==4 if !missing(reason_ccc)
		g reason_ccc_deserted = reason_ccc ==5 if !missing(reason_ccc)
		g reason_ccc_rejected = reason_ccc ==6 if !missing(reason_ccc)
		g reason_ccc_norecord = reason_ccc ==7 if !missing(reason_ccc)
		gen reason_ccc_none = missing(reason_ccc)
		
		replace reason_ccc = 8 if missing(reason_ccc) & everjc==0	
	// iii. all variables
	
		* application
		g app_quarter = APP_QTR
		
		* year-quarter
		g yq_48int = (year(H_CDATE) - 1998)*4 + floor((month(H_CDATE)-1)/3)+1
		g yq_baseline = (year(B_CDATE) - 1994)*4 + floor((month(B_CDATE)-1)/3)+1
		
		* demographics
		g rand_haschld = haschld
		g arrested = ARRST_GR !=1 if !missing(ARRST_GR) // about 800 missing values
		g male = female ==0 
		g married_random = inlist(marriage,2,4) if !missing(marriage)
		// use agegroup as indicator
		// use age as a running variable
		// use spanish for native language is spanish nvm only 11k have
		g age1718 = inrange(floor(age),17,18) if !missing(age)
		g age161718 = inrange(floor(age),15,18) if !missing(age)
		
		* educ
		g highschool = inlist(1,HS_D,GED_D) if !missing(HS_D) | !missing(GED_D)
		
		* socioeconomic
		g current_job = currjob // job at time of app
		g highgrade_mom = HGC_MOTH
		g highgrade_dad = HGC_FATH
		
		* race
		g race_white = RACE_ETH == 1 if !missing(RACE_ETH)
		g race_black = RACE_ETH == 2 if !missing(RACE_ETH)
		g race_hispanic = RACE_ETH == 3 if !missing(RACE_ETH)
		g race_other = RACE_ETH == 4 if !missing(RACE_ETH)
		
		* Language other than English
		g nativelang_nonEnglish = NTV_LANG ==2 | NTV_LANG ==3 if !missing(NTV_LANG)
		
		* Family background
		g HHH_mother = HH14 ==3 if !missing(HH14)
		g kid_welfare = WELF_KID ==1 if !missing(WELF_KID)
		g hhsize = NUMB_HH
		g motherliving = (hhmemb == 1 | hhmemb == 2) if !missing(hhmemb)
		g fatherliving = (hhmemb == 1 | hhmemb == 3) if !missing(hhmemb)
		g farm = OCC_R == 7 if !missing(OCC_R)
		replace farm = 0 if farm == . // assume if missing (no work), not
		g farmOrlabor = (OCC_R == 2 | OCC_R == 7) if !missing(OCC_R)
		replace farmOrlabor = 0 if farm == . // assume if missing (no work), not
		* Ever used drugs
		g ever_drug = inlist(1, EV_POT, EV_COKE, EV_HROIN, EV_CRACK, EV_SPEED, EV_LSD, EV_OTHDR)
		
		* misc area chars
		g after_policy = IN57
		g in_person = inpers
		g non_res_area = nonres
		
	
	// v. Fix highest grade of education for GE 
	
	replace highgrade_baseline = 12 if GED_D ==1 & highgrade_baseline <12
	replace highgrade_baseline = 12 if HS_D ==1 & highgrade_baseline <12
	
	replace highgrade_48 = 12 if D48_GED ==1 & highgrade_48 <12
	replace highgrade_48 = 12 if D48_HS ==1 & highgrade_48 <12
	
	// vi. make sure labelled
	label var male "Male"
	label var age "Age"
	label var haschld "Has child"
	label var EVARRST1 "Ever Arrested"
	label var current_job "Current job"
	label var ever_drug "Ever used drugs"
	label var married_random "Married"
	label var race_black "Black"
	label var race_hispanic "Hispanic"
	label var race_other "Race - Other"
	label var nativelang_nonEnglish "Non-English Native Lang."
	label var kid_welfare "On welfare as child"
	label var evworkb "Ever worked"
	label var YR_WORK1 "Job in past year"
	label var highgrade_baseline "Highest grade completed"
	label var HS_D "HS Degree"
	label var GED_D "GED"
	label var nonres "Non-residential assignment"
	label var in_person "Lived in area"
	label var non_res_area "High perc. non-res."
	label var jcmsa "MSA category"
	label var reason_ccc_employment "Reason for discharge (code): Employment"
	label var reason_ccc_cog "Reason for discharge (code): Closure"
	label var reason_ccc_urgandprop "Reason for discharge (code): Urgent and Proper Call"
	label var reason_ccc_deserted "Reason for discharge (code): Quit"
	label var reason_ccc_rejected "Reason for discharge (code): Rejected"
	label var reason_ccc_norecord "Reason for discharge (code): No Record"
	label var health12 "Self-reported health (12-month; 1=exc,2=good,3=fair,4=poor)"
	label var health30 "Self-reported health (30-month; 1=exc,2=good,3=fair,4=poor)"
	label var health48 "Self-reported health (48-month; 1=exc,2=good,3=fair,4=poor)"
	label var health_exc12 "Self-reported health excellent (12-month)"
	label var health_exc30 "Self-reported health excellent (30-month)"
	label var health_exc48 "Self-reported health excellent (48-month)"
	label var hhsize "Number in Household"
	label var motherliving "Mother Living (Living with Mother or Parents)"
	label var fatherliving "Father Living (Living with Father or Parents)"
	label var farm "Live on farm? (Most Recent Job Occ. Agricultural)"
	label var farmOrlabor "Most Recent Job Occ. Agricultural or Labor and Construction"
	label var age1718 "Age is 17 or 18"
	label var age161718 "Age is 15-18"

******************************************************
// 2. Baseline characteristics and Appendix Tables
** Appendix Table : JC Characteristics
** Appendix Table : Covariate balance                           
******************************************************

	putexcel set "${tables}/CovariateBalanceTests.xlsx", sheet(JCChars, replace) modify
	
	global sum_var male age race_white race_black race_hispanic race_other highgrade_baseline highschool EVARRST1 YR_WORK1 evworkb EARN_YR 
	
	global outcome_var highgrade_48 employed wksworked_prevyr earnings earnings_if_employed ln_earnings_if_employed ///
			moved ever_married health12 health30 health48 health_exc12 health_exc30 health_exc48 health_excgd12 health_excgd30 health_excgd48 ///
			reason_ccc_endofterm reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop  reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord
	
	* setup matrix
	local num1 : list sizeof global(sum_var)
	local num2 : list sizeof global(outcome_var)
	matrix define SummStat = J(`num1'+`num2' + 4,2,.)
	mat colnames SummStat = "Overall" "Male"
	mat rownames SummStat =  ${sum_var} "duration" "duration - zeroes" ${outcome_var} "N - baseline" "N - outcome" 
			
	* others
	local i=1
	foreach var of global sum_var {
		sum `var' [aweight=BASE_WGT] if RESP_B==1
		mat SummStat[`i',1] = round(`r(mean)',.001)
		sum `var' [aweight=BASE_WGT] if RESP_B==1 & male ==1
		mat SummStat[`i',2] = round(`r(mean)',.001)
		local i = `i' +1
	}
	
	* duration
	sum duration [aweight=WGT48B] if duration >0 & treatmnt == 1
	mat SummStat[`i',1] = round(`r(mean)',.001)
	sum duration [aweight=WGT48B] if duration >0 & treatmnt == 1 & male ==1
	mat SummStat[`i',2] = round(`r(mean)',.001)
	local i = `i' + 1
	* duration w/ zeroes
	sum duration [aweight=WGT48B] if /*duration >0 &*/ treatmnt == 1
	mat SummStat[`i',1] = round(`r(mean)',.001)
	sum duration [aweight=WGT48B] if /*duration >0 &*/  treatmnt == 1 & male ==1
	mat SummStat[`i',2] = round(`r(mean)',.001)
	local i = `i' + 1
	
	* outcome variables

	foreach var of global outcome_var {
		sum `var' [aweight=WGT48B] if RESP_48==1
		mat SummStat[`i',1] = round(`r(mean)',.001)
		sum `var' [aweight=WGT48B] if RESP_48==1 & male ==1
		mat SummStat[`i',2] = round(`r(mean)',.001)
		local i = `i' +1
	}	
	* observation
	sum treatmnt if RESP_B==1
	mat SummStat[`i',1] = `r(N)'
	
	sum treatmnt if RESP_B==1 & male ==1
	mat SummStat[`i',2] = `r(N)'
	local i = `i' + 1
	
	sum treatmnt if RESP_48==1
	mat SummStat[`i',1] = `r(N)'
	
	sum treatmnt if RESP_48==1 & male ==1
	mat SummStat[`i',2] = `r(N)'
	
	* output
	putexcel A2=matrix(SummStat,  names)
	putexcel clear
	
******************************************************
// 2. Covariate balance                           
******************************************************

	// iv. Select employment characteristics only if worked at least 2 weeks in previous year
	replace mosinjob = . if mosinjob < .5 
	replace EARN_YR = . if mosinjob < .5
	replace HRSWK_JR = . if mosinjob < .5
	replace hrwager = . if mosinjob < .5
	
	// i. Setup
	global bal_cov male age race_white race_black race_hispanic nativelang_nonEnglish ///
		haschld HHH_mother HGC_MOTH HGC_FATH kid_welfare hgc HS_D GED_D evworkb YR_WORK1 ///
		currjob mosinjob EARN_YR HRSWK_JR hrwager GOTAFDC1 GOTFS1 GOT_ANYW ever_drug ///
		EVARRST1 nonres health12 health30 health48 health_exc12 health_exc30 health_exc48 ///
		health_excgd12 health_excgd30 health_excgd48
					
	local num : list sizeof global(bal_cov)

	matrix define CovBalance = J(`num' + 1,11,.)
	mat colnames CovBalance = "Treatment" "Control" "Estimated impact" "SE" "P" "" "Treatment" "Control" "Estimated impact" "SE" "P"
	mat rownames CovBalance = ${bal_cov} "N"

	// ii. add variables to matrix ( full sample)
	local i = 1
	foreach var of global bal_cov {
		
		* treatment group
		sum `var' [aweight=BASE_WGT] if treatmnt == 1 & RESP_B==1
		mat CovBalance[`i',1] = round(`r(mean)',.001)
		*control group
		sum `var' [aweight=BASE_WGT] if treatmnt == 0 & RESP_B==1
		mat CovBalance[`i',2] = round(`r(mean)',.001)
		*difference
		regress `var' treatmnt [pw=BASE_WGT] if RESP_B==1, robust
		mat CovBalance[`i',3] = round(_b[treatmnt],.001)
		mat CovBalance[`i',4] = round(_se[treatmnt],.001)
		local t = _b[treatmnt]/_se[treatmnt]
		local p =2*ttail(e(df_r),abs(`t'))
		mat CovBalance[`i',5] = round(`p',.001)
		* increment counter
		local i = `i' +1
	}
	
	// iii. add observations to matrix (full sample)
	sum treatmnt if treatmnt == 1 & RESP_B==1
	mat CovBalance[`i',1] = `r(N)'
	sum treatmnt if treatmnt == 0 & RESP_B==1
	mat CovBalance[`i',2] = `r(N)'
	sum treatmnt if RESP_B==1
	mat CovBalance[`i',3] = `r(N)'
	
	// iv. add variables to matrix (male sample)
	local i = 1
	foreach var of global bal_cov {
		
		* treatment group
		sum `var' [aweight=BASE_WGT] if treatmnt == 1 & female == 0 & RESP_B==1
		mat CovBalance[`i',7] = round(`r(mean)',.001)
		*control group
		sum `var' [aweight=BASE_WGT] if treatmnt == 0 & female == 0 & RESP_B==1
		mat CovBalance[`i',8] = round(`r(mean)',.001)
		*difference
		regress `var' treatmnt [pw=BASE_WGT] if female == 0 & RESP_B==1, robust
		mat CovBalance[`i',9] = round(_b[treatmnt],.001)
		mat CovBalance[`i',10] = round(_se[treatmnt],.001)
		local t = _b[treatmnt]/_se[treatmnt]
		local p =2*ttail(e(df_r),abs(`t'))
		mat CovBalance[`i',11] = round(`p',.001)		
		* increment counter
		local i = `i' +1
	}
	
	// v. add observations to matrix (male sample)
	sum treatmnt if treatmnt == 1  & female == 0 & RESP_B==1
	mat CovBalance[`i',7] = `r(N)'
	sum treatmnt if treatmnt == 0  & female == 0 & RESP_B==1
	mat CovBalance[`i',8] = `r(N)'
	sum treatmnt if  female == 0 & RESP_B==1
	mat CovBalance[`i',9] = `r(N)'
	
	// vi. output table
	putexcel set "${tables}/CovariateBalanceTests.xlsx", sheet(CovBalance, replace) modify
	putexcel A1=matrix(CovBalance,  names)
	putexcel clear
	
******************************************************
// 5. Figure 1 and 2                       
******************************************************


* Figure 1

* create duration in months
g duration_mo = duration * 12

g WGT48B_fw = round(WGT48B * 1000)

* mean
sum duration_mo [fw=WGT48B_fw] if male == 1 & treatmnt==1 & duration_mo <= 36

* Ever enrolled (treated and untreated) + male only <= 36 and bins of 1
histogram duration_mo if everjc == 1 & male == 1 & duration_mo <= 36, /* kdensity */ width(1) start(0) ///
graphregion(color(white)) bgcolor(white) ///
xtitle(Total months enrolled) ///
xlabel(0(6)36,angle(0))  ///
title("Duration of Job Corps Enrollment (Ever Enrolled - Males)" , size(medium)) 
graph save "${figures}/duration_everjc_male_36.gph", replace
graph export "${figures}/png/duration_everjc_male_36.png", replace
	

* Figure 2 histogram of reason
label def reason_ccc_lbl 1 "EOT" 2 "Emp" 3 "COG" 4 "UrgProp" 5 "Desert" 6 "Rej" 7 "No Rec"
label values reason_ccc reason_ccc_lbl

* generate some data
tab reason_ccc [aweight=WGT48B] if reason_ccc_none == 0 & RESP_48==1, matcell(A)
gen reason_ccc_graph = _n if _n<=7
* there is no rej
replace reason_ccc_graph = . if reason_ccc_graph == 7
replace reason_ccc_graph = 7 if reason_ccc_graph == 6
svmat A
rename A1 reason_ccc_count
egen reason_ccc_count_sum = sum(reason_ccc_count)
gen reason_ccc_dens = reason_ccc_count/reason_ccc_count_sum

tabstat duration, by(reason_ccc) save
gen reason_ccc_means = .
forvalues i = 1(1)7 {
	mat def Q = r(Stat`i')
	replace reason_ccc_means = Q[1,1] if reason_ccc_graph == `i'
	}
label val reason_ccc_graph reason_ccc_lbl
format reason_ccc_means %9.2f

set scheme s2color // graph scheme
twoway (bar reason_ccc_dens reason_ccc_graph,  ///
	xlabel(1(1)7, value) xtick(1(1)7) ytitle("Density") ///
	xtitle("Reasons for Discharge (Jobs Corps)")) ///
	(scatter reason_ccc_dens reason_ccc_graph, mlabel(reason_ccc_means) mlabangle(45)) ///
	, legend(off) graphregion(color(white)) bgcolor(white)
graph save "${figures}/hist_reason_JC.gph", replace
graph export "${figures}/png/hist_reason_JC.png", replace

	

******************************************************
// 4. Appendix Table 6 - Determinants of duration
// Figure 3 Determinants of duration                           
******************************************************
	
	//
	
	global ifstat = "if treatmnt ==1 & male ==1"
	global vars1 age /*i.agegroup*/ nonres race_black race_hispanic race_other nativelang_nonEnglish married_random haschld EVARRST1  ever_drug in_person kid_welfare evworkb YR_WORK1 current_job highgrade_baseline HS_D GED_D non_res_area i.jcmsa
	global vars2 i.yq_48int i.yq_baseline 
	global vars3 reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord never_enrolled
	global other after_policy 
	
	global ccc_vars "age161718 race_hispanic highgrade_baseline hhsize farm fatherliving motherliving" 
	global ccc_vars_add "age161718 hhsize farm fatherliving motherliving" 

		g never_enrolled = everjc ==0 & treatmnt == 1
		label var never_enrolled "Never enrolled"
	foreach var in reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop  reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord {
		replace `var' = 0 if missing(`var') & never_enrolled ==1
	}
	
	* 1) Basic controls
	reg duration ${vars1} ${other} [pw=WGT48B] $ifstat , robust
	quietly sum duration if e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${tables}/determinants_duration.xml", replace bdec(3) ctitle("Basic Controls") addtext("Mean Dep",${meany},"FE","-","Sample","All","Reason","N") keep(${vars1}) label

	* 2) Basic controls + baseline and interview YQ FE
	reg duration ${vars1} ${vars2} ${other} [pw=WGT48B] $ifstat , robust
	quietly sum duration if e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${tables}/determinants_duration.xml", append bdec(3) ctitle("Add YQ Baseline & Interv. FE ") addtext("Mean Dep",${meany},"FE","YQ B/I","Sample","All","Reason","N") keep(${vars1}) label

	
	*** plot the coefficients and their stadnard errors
	global pltvars = "nonres race_black race_hispanic race_other nativelang_nonEnglish married_random haschld EVARRST1 ever_drug in_person kid_welfare evworkb YR_WORK1 current_job highgrade_baseline HS_D GED_D non_res_area"

	* temporarily relabel CCC vars
	foreach var of varlist $ccc_vars {
		local varl : variable label `var'
		label var `var' "`varl'"
		}
	
	* retrieve estimates and SE
	local mlen : word count ${pltvars}  // total number of variables to retrieve
	disp `mlen'
	mat def Bb = J(`mlen',2,.)
	mat rownames Bb = ${pltvars}
	mat colnames Bb = b se

	foreach var in $pltvars {
		local rown = rownumb(Bb,"`var'")
		mat Bb[`rown',1] = _b[`var']
		mat Bb[`rown',2] = _se[`var']
		}

	* crate variables out of retrieve values
	svmat Bb
	rename Bb1 plt_b_est
	rename Bb2 plt_b_se

	* assign each row to a variable
	gen plt_names = ""
	local i = 1
	foreach var in $pltvars {
		replace plt_names = "`var'" if _n == `i'
		local i = `i' + 1
		}
	replace plt_b_est = . if plt_b_est == 0 & plt_b_se == 0
	replace plt_b_se = . if plt_b_est == .

	* define row and 95% CI
	gen plt_b_se_H = plt_b_est + 1.96*plt_b_se
	gen plt_b_se_L = plt_b_est - 1.96*plt_b_se

	gsort -plt_b_est
	gen plt_lines = _n if plt_b_est != .

	* label the values of line for plotting
	label def plt_lines_lbl 0 "null", replace

	quietly sum plt_lines
	forvalues i = 1(1)`r(max)' {
		local var = plt_names[`i']
		local varl : variable label `var'
		local varl = subinstr("`varl'"," (CO only)","",.)
		local varl = subinstr("`varl'"," : Enrollment 1","",.)
		label def plt_lines_lbl `i' "`varl'", add
		}
		
	label val plt_lines plt_lines_lbl

	gen plt_sig95 = ~inrange(0,plt_b_se_L,plt_b_se_H)
	replace plt_sig95 = . if plt_b_est == .

	* plot
	quietly sum plt_lines
	local mlen = `r(max)'
	twoway (scatter plt_lines plt_b_est if plt_sig95 == 1, xline(0) msize(1.1) mcolor(green) msymbol(D)) ///
		(scatter plt_lines plt_b_est if plt_sig95 == 0, msize(1.1) mcolor(green) msymbol(X)) ///
		(rcap plt_b_se_H plt_b_se_L plt_lines, hor lcolor(orange))  ///
		, ylabel(1(1)`mlen',val angle(0)) ytitle("") legend(off) scheme(s1color)
	graph save "${figures}/Duration_Coefs_JC.gph", replace
	graph export "${figures}/png/Duration_Coefs_JC.png", replace
	disp $meany
	
	* restore labels
	foreach var of varlist $ccc_vars {
		local varl : variable label `var'
		local len = strlen("`varl'")
		local varl = substr("`varl'",2,`len')
		label var `var' "`varl'"
		}

	drop plt_b_est plt_b_se_H plt_b_se_L plt_lines plt_sig95 plt_b_se plt_names
	*** plotting end
	
	* 3) Basic controls + baseline and interview YQ FE + demeaned reason
	quietly reg duration ${vars1} ${vars2} ${vars3} ${other} [pw=WGT48B] $ifstat , robust
	quietly sum duration if e(sample) == 1
	global meany = string(round(`r(mean)',0.001),"%9.2f")
	outreg2 using "${tables}/determinants_duration.xml", append bdec(3) ctitle("Add Reason") addtext("Mean Dep",${meany},"FE","YQ B/I","Sample","All","Reason","Y") keep(${vars1} ${vars3}) label
	
	


******************************************************
// Table 7: JC Parts                           
******************************************************

*** de-mean reasons

	foreach var in reason_ccc_endofterm reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop  reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord {
		sum `var' [aw=WGT48B]
		replace `var' = `var' - `r(mean)'
		tab `var'
	}

*** Ttests
	putexcel set "${tables}/Duration.xlsx", replace

	* male participants
	local i =6
	foreach y in highgrade_48 employed wksworked_prevyr earnings  earnings_if_employed ln_earnings_if_employed moved ever_married health12 health30 health48 health_exc12 health_exc30 health_exc48 health_excgd12 health_excgd30 health_excgd48 {
		*bysort control: sum `y'   [aw=WGT48B] // earning at 4th year peer week
			regress `y' treatmnt [pw=WGT48B] if male == 1 & duration != ., robust
			excel_regout treatmnt "C" `i'
			local i=`i'+4
	}
	
	global ctrl_application i.yq_48int i.yq_baseline nonres in_person 
	global ctrl_age age i.agegroup 
	global ctrl_demo male race_black race_hispanic race_other nativelang_nonEnglish married_random haschld EVARRST1  ever_drug   
	global ctrl_family kid_welfare
	global ctrl_econ evworkb YR_WORK1 current_job
	global ctrl_educ highgrade_baseline HS_D GED_D
	global ctrl_location non_res_area i.jcmsa
	global ctrl_misc after_policy 
	global ctrl_reasons i.reason_ccc
	global ctrl $ctrl_application $ctrol_age $ctrl_demo $ctrl_family $ctrl_econ $ctrl_misc

	*** making sure the controls are all imputed
	global ctrl_miss = ""
	foreach var in $ctrl {
	disp "`var'"
		if substr("`var'",1,2) != "i."	{
			gen m_`var' = `var' == .
			quietly sum `var' [aw=WGT48B]
			replace `var' = `r(mean)' if `var' == .
			global ctrl_miss = "$ctrl_miss" + " m_`var'"
			}
		if substr("`var'",1,2) == "i." {
			local ivar = subinstr("`var'","i.","",1)
			gen m_`ivar' = `ivar' == .
			sum `ivar' [aw=WGT48B], d
			replace `ivar' = `r(p50)' if `ivar' == .
			global ctrl_miss = "$ctrl_miss" + " m_`ivar'"
			}
	}
*** Regression results

	local i =6
	foreach y in highgrade_48 employed wksworked_prevyr earnings  earnings_if_employed ///
		ln_earnings_if_employed moved ever_married health12 health30 health48 ///
			health_exc12 health_exc30 health_exc48 health_excgd12 health_excgd30 health_excgd48 {
			local lab : variable label `y'
			putexcel A`i' = ("`y'")
			putexcel B`i' = ("`lab'")
	*** OLS	
			* Male sample			
			regress `y' duration $ctrl $ctrl_miss [pw=WGT48B] if male ==1 & treatmnt ==1, robust
			excel_regout duration "D" `i'
	
	*** 2SLS
			
			* Male sample
			ivregress 2sls `y' (duration=treatmnt) [pw=WGT48B] if male==1, robust
			excel_regout duration "E" `i'
				
			local i=`i'+4
	}
	putexcel B1 = ("ITT")
	putexcel D1 = ("OLS")
	putexcel E1 = ("IV")
	putexcel clear
	
	regress ACTQ16 treatmnt [pw=WGT48B], robust

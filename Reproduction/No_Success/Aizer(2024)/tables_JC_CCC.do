*"Does Job Corps Work? Impact Findings from the National Job Corps Study"

clear all
set matsize 5000
set scheme s1color // grpah scheme
version 14.0
global rootdir = "C:/Users/jabef/Desktop/FU Job/Prof.Marcus/Python_Scraper/Oster_Methode/Reproduction/Aizer(2024)"
global datadir = "$rootdir/Analysis/Analysis Sample"
global resultdir = "$rootdir/Analysis/Results"
global graphdir = "$resultdir/Figures"

global summstatscalc = 1
global figures = 1
global tables = 1
global tables_app = 1

capture mkdir "${resultdir}"
capture mkdir "${graphdir}"

capture log close
log using "${resultdir}/JC_CCC.log", replace

* JC Data Prep
{
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

clear

gl path  ""
gl do_files $path/do_files
gl raw_data $path/raw_data/20060076_data
gl working_data $path/working_data
gl tables $path/tables
gl out_files $path/out_files
gl figures $path/figures

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
															  hhmemb NUMB_HH numbjobs OCC_R typehlth sick health mostimpr R_NOWORK evworkb HH_INC)
	drop if _m ==2
	drop _m
	
	// ii. baseline raw (personal income
	merge 1:1 mprid using "$raw_data/base_raw.dta", keepusing(G10 G11 G12)
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
	
	* personal income
	* generate midpoint for G12
	
	gen pers_inc = G11
	replace pers_inc = HH_INC if HH_INC <= 3 & G11 == 7
	replace pers_inc = 1500 if inlist(G11,0,6,8,9) & G12 == 1
	replace pers_inc = 4500 if inlist(G11,0,6,8,9) & G12 == 2
	replace pers_inc = 7500 if inlist(G11,0,6,8,9) & G12 == 3
	replace pers_inc = 10500 if inlist(G11,0,6,8,9) & G12 == 4
	replace pers_inc = 13500 if inlist(G11,0,6,8,9) & G12 == 5
	replace pers_inc = 16500 if inlist(G11,0,6,8,9) & G12 == 6
	replace pers_inc = 23000 if inlist(G11,0,6,8,9) & G12 == 7 // median value for pers_inc > 18000
	replace pers_inc = . if G11 < 0
	replace pers_inc = . if inlist(pers_inc,0,6,8,9)
	
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
	
	gen enrollment_year1 = year(B_CDATE)
	gen unemp1 = 1 if current_job == 0
	replace unemp1 = 0 if current_job == 1
	
	label var enrollment_year1 "Enrollment Year"
	label var unemp1 "Unemployed at Application"
	
	* harmonizing
	gen enrollment_age1 = age
	gen hispanic_imputed = race_hispanic 
	gen school_grade = highgrade_baseline 
	gen prev_job = evworkb 
	gen duration1 = duration 
	
	gen sample = "JC"
	tempfile jc
	save `jc'

}

* CCC Data Prep
{

clear

use "${datadir}/combined_analysis_data.dta"

********************
*** Regression Parameters Set
********************
global agefigure = 0 // do figure of survival by age if = 1
global OLShet = 0 // do the heterogeneity analysis for OLS

global durvar = "duration1"

global X0 = "${durvar}"
global X1 = "i.birth_year"
global X2 = "i.reason1 honorable"
global X3 = "i.campdum1"
global X4 = "EverRejec Disable1 NonJunior1 flag_age_younger1 flag_age_older1 AgeNonEligible1 age1718 allottee_amount1 allottee_father1 allottee_mother1 flag_interruption log_distance_address_camp1 hispanic_imputed county_urate"
global X6 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county"
* replace educ, height, weight by last observed
global X6_2 = "ccc_cw_educ hhsize farm ccc_cw_height ccc_cw_weight fatherliving motherliving tenure_county"

global X5 = "m_allottee_amount1 m_allottee_relation1 m_county_urate"
global X7 = "m_school_grade m_hhsize m_farm m_totheight m_weight m_fatherliving m_motherliving m_tenure_county"

global campchars = "flag_camp_instate1 camp_meanprecip camp_meanmintemp camp_meanmaxtemp camp_type1_enc_* log_distance_city_camp11 log_distance_city_camp12"
global peerchars = "peer_wmean_hispanic_imputed peer_wmean_enrollment_age1 peer_wmean_flag_age_younger1 peer_wmean_flag_age_older1 peer_wmean_AgeNonEligible1 peer_wmean_allottee_amount1 peer_wmean_allottee_father1 peer_wmean_allottee_mother1 peer_wmean_flag_interruption"

global iv = "leaveout_duration_yq"

global option_se = "vce(cluster groupayq)"
global option_se_cens = "vce(cluster groupayq)"
global option_bdec = 3

*** define program that replaces R2 in xtreg, fe regressions for output
capture program drop xtregfe_replace_r2
program xtregfe_replace_r2, eclass
	/* 
	 This program replaces the stored r-squared from the xtreg, fe regression.
	 
	 The default is to use "within-r2", which does not take into account the
	 fixed effects in the calculation of the R2. This is different from, for
	 instance when you manually include the FE.
	 
	 The purpose is for outputting: since outreg and related commands by default
	 output the stored e(r2) in the tables, we have to manually replace this to
	 output them into the default R-squared slot.
	*/
	
	* check if the command is xtreg, fe; replace e(r2) if true
	if "`e(cmd)'" == "xtreg" & "`e(model)'" == "fe" {
		ereturn scalar r2 = 1 - e(rss)/e(tss) // replace R2 with Total R2
		}
	* exit and explain that it wasn't replaced for what reason
	if "`e(cmd)'" != "xtreg" | "`e(model)'" != "fe" {
		if "`e(cmd)'" != "xtreg" disp "Not xtreg: did not replace e(r2)"
		if "`e(cmd)'" == "xtreg" & "`e(model)'" != "fe" disp "Not FE: did not replace e(r2)"
		}
end


********************
*** PREPARE DATA START
********************

*** some more variable definitions
tab birth_year, gen(birth_years_) // for xtivreg2
tab reason1, gen (reason1_)
gen stateall = "Both"
gen insample_00 = 1
tab camp_type1_enc, gen(camp_type1_enc_)
gen all = 1

gen insample_05_large = insample_05
replace insample_05_large = 1 if insample_05 == .
quietly tab reason_detailed1, gen(rd1_)

replace weight = weight / 100
label var weight "Weight (100 pounds) (CO only)"

gen P70m0 = P70
replace P70m0 = 0 if P70 == .
label var P70m0 "P(70), imputed to 0 if missing" 

gen county_urate = murate1937 if inrange(enrollment_year1,1937,1938)
replace county_urate = murate1940 if inrange(enrollment_year1,1939,1940)

gen cens_matched = cens_match_type != 0
label var cens_matched "1940 Cens: Matched"

gen ww2_matched = ww2_serial != .
label var ww2_matched "WWII: Matched"

gen dmf_machine_ldeath_age = log(dmf_machine_ageatdeath)

gen unemp1 = 1 if unemp_now1 == "yes"
replace unemp1 = 0 if unemp_now1 == "no" | unemp_now1 == "part time"

label var camp_type1_enc_1 "Camp Type: Department of Grazing"
label var camp_type1_enc_2 "Camp Type: Federal Reclamation Project"
label var camp_type1_enc_3 "Camp Type: Fish and Wildlife Service"
label var camp_type1_enc_4 "Camp Type: National Forest"
label var camp_type1_enc_5 "Camp Type: National Monument"
label var camp_type1_enc_6 "Camp Type: National Park"
label var camp_type1_enc_7 "Camp Type: Soil Conservation"
label var camp_type1_enc_8 "Camp Type: State Park"
label var camp_type1_enc_9 "Camp Type: Other"
label var reason1_1 "Reason ended: End of term"
label var reason1_2 "Reason ended: Employment"
label var reason1_3 "Reason ended: Convenience of the government"
label var reason1_4 "Reason ended: Urgent and Proper Call"
label var reason1_5 "Reason ended: Deserted"
label var reason1_6 "Reason ended: Rejected upon  examination"
label var reason1_7 "Reason ended: No Record"
label var county_urate "White Male Unemployment Rate 1937/1940"
label var dmf_machine_ldeath_age "Log Death Age from DMF"
label var unemp1 "Unemployed at Application 1"

* generate missing flags
foreach var in $X4 $X6 bmi unemp1 {
	gen m_`var' = `var' == .
	local lab: variable label `var'
	label var m_`var' "Missing `lab'"
	}
	
gen m_allottee_relation1 = allottee_relation1 == ""
label var m_allottee_relation1 "Missing allottee relation"

gen allnonmiss_NM = 1
foreach var in $X5 {
	replace allnonmiss_NM = 0 if `var' == 1
	}

gen allnonmiss = 1
foreach var in $X5 $X7 {
	replace allnonmiss = 0 if `var' == 1
	}
	
* mean camp characteristics
sort ccccampnumber1 enrollment_yq1
foreach var in duration1 allottee_father allottee_mother enrollment_age1 hispanic_imputed { 
	by ccccampnumber1 enrollment_yq1: egen cm_`var' = mean(`var')
	local lab: variable label `var'
	label var cm_`var' "Camp Mean `lab'"
	}

*** last observed height, weight, and school grade
gen ccc_cw_height = ww2_height_r
replace ccc_cw_height = totheight if ccc_cw_height == . & m_totheight == 0

gen ccc_cw_weight = ww2_weight_r 
replace ccc_cw_weight = weight if ccc_cw_weight == . & m_weight == 0

gen ccc_cw_educ = cw_years_educ
replace ccc_cw_educ = school_grade if ccc_cw_educ == . & m_school_grade == 0

gen nonmissing_xvars = ccc_cw_height != . & ccc_cw_weight != . & ccc_cw_educ != .
	
* make sure everyone has death age and duration1
gen sampletake = 1
replace sampletake = 0 if ccccampnumber1 == ""
replace sampletake = 0 if groupayq == .
replace sampletake = 0 if duration1 == .

*** imputation of variables
* first impute the county urates with county values
replace county_urate = murate1937 if enrollment_year1 < 1937
replace county_urate = murate1940 if enrollment_year1 > 1940

* impute the missing values as average
foreach var in $X4 $X6 unemp1 {
	quietly sum `var'
	replace `var' = `r(mean)' if `var' == .
	}
	
* these values were median values of 1937 and 1940 unemployment values across CO and NM counties
gen urate_abv = (county_urate >= .0632534) if enrollment_year1 < 1939
replace urate_abv = (county_urate >=.0514035) if enrollment_year1 >= 1939

label var urate_abv "From County with Above Median Unemployment Rate"

drop if sampletake == 0

* merge in the Household wages
merge 1:1 id PersonID state using "${datadir}\Census_Data\NBER\CCC_hh_wage_NBERsample.dta"
drop _merge

gen sample = "CCC"
}

**************
append using `jc'

*******************************
*** set-up for regressions
*******************************
{

* create or recreate variables
global vars_CCC = "enrollment_age1 agel18 school_grade hispanic_imputed prev_job highschool_harm hhsize farm fatherliving motherliving"
global vars_CCC_m = "m_enrollment_age1 m_agel18 m_school_grade m_hispanic_imputed m_prev_job m_highschool_harm m_hhsize m_farm m_fatherliving m_motherliving"

* define new variables
* age less than 18
gen agel18 = inrange(floor(enrollment_age1),15,18)
gen agesq = enrollment_age1^2
* high school degree
gen highschool_harm = inlist(1,HS_D,GED_D) if !missing(HS_D) | !missing(GED_D) & sample == "JC"
replace highschool_harm = school_grade >= 12 if sample == "CCC"
* male indicator (all) for CCC
replace male = 1 if sample == "CCC"

label var agel18 "Age < 18"
label var highschool_harm "HS Degree or GED"

* generate missing flags for new vars for CCC and JC
gen m_prev_job = prev_job == . | missing(prev_job)
gen m_highschool_harm = highschool_harm == . | missing(highschool_harm)
gen m_enrollment_age1 = enrollment_age1 == . | missing(enrollment_age1)
gen m_agel18 = enrollment_age1 == . | missing(enrollment_age1)

* missing flag variables for JC
foreach var in $vars_CCC unemp1 {
	replace m_`var' = (`var' == . | missing(`var')) if sample == "JC"
	local lab: variable label `var'
	label var m_`var' "Missing `lab'"
	}

* imputation for both JC and CCC (new variables)
quietly sum prev_job if sample == "CCC"
replace prev_job = `r(mean)' if sample == "CCC" & prev_job == .
	
* impute for JC
foreach var in $vars_CCC {
	quietly sum `var' if male == 1 & sample == "JC"
	replace `var' = `r(mean)' if sample == "JC" & male == 1 & (`var' == . | missing(`var'))
	}
	
* replace allnonmiss variable
gen allnonmiss_harm = 1
foreach var in $vars_CCC {
	replace allnonmiss_harm = 0 if m_`var' == 1
	}


****
* regression definitions
global durvar = "duration1"
global ifstat = "if death_age >= 45 & death_age != ."
global X0 = "${durvar}"
global X1 = "i.birth_year"
global X2 = "i.reason1 honorable"
global X3 = "i.campdum1"
global X4 = "EverRejec Disable1 NonJunior1 flag_age_younger1 flag_age_older1 AgeNonEligible1 agel18 allottee_amount1 allottee_father1 allottee_mother1 flag_interruption log_distance_address_camp1 hispanic_imputed county_urate"
global X6 = "school_grade hhsize farm totheight weight fatherliving motherliving tenure_county"

global X5 = "m_allottee_amount1 m_allottee_relation1 m_county_urate"
global X7 = "m_school_grade m_hhsize m_farm m_totheight m_weight m_fatherliving m_motherliving m_tenure_county"

global campchars = "flag_camp_instate1 camp_meanprecip camp_meanmintemp camp_meanmaxtemp camp_type1_enc_* log_distance_city_camp11 log_distance_city_camp12"
global peerchars = "peer_wmean_hispanic_imputed peer_wmean_enrollment_age1 peer_wmean_flag_age_younger1 peer_wmean_flag_age_older1 peer_wmean_AgeNonEligible1 peer_wmean_allottee_amount1 peer_wmean_allottee_father1 peer_wmean_allottee_mother1 peer_wmean_flag_interruption"

global option_se = "vce(cluster groupayq)"
global option_se_cens = "vce(cluster groupayq)"
global option_bdec = 3

*** regression used in CCC
*xtreg ${durvar} $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & sample == "CCC", $option_se fe

*** regression used in JC
global ifstat = "if treatmnt ==1 & male ==1"
global vars_CCC = "enrollment_age1 agel18 school_grade hispanic_imputed prev_job highschool_harm hhsize farm fatherliving motherliving"
global vars_CCC_m = "m_enrollment_age1 m_agel18 m_school_grade m_hispanic_imputed m_prev_job m_highschool_harm m_hhsize m_farm m_fatherliving m_motherliving"
global vars_noCCC = "nonres race_black race_other nativelang_nonEnglish married_random haschld EVARRST1 ever_drug in_person kid_welfare YR_WORK1 current_job non_res_area"
global vars_CCC_fe = "i.yq_48int i.yq_baseline"
global vars_reason = "reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord never_enrolled"
global other = "after_policy i.jcmsa" 

g never_enrolled = everjc ==0 & treatmnt == 1
label var never_enrolled "Never enrolled"
foreach var in reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord {
	replace `var' = 0 if missing(`var') & never_enrolled ==1
}
	
* 3) Controls to line up with CCC
// include all
*reg duration1 ${vars_CCC} ${vars_noCCC} ${vars_CCC_fe} ${other} [pw=WGT48B] $ifstat & sample == "JC", robust
// include just CCC
*reg duration1 ${vars_CCC} [pw=WGT48B] $ifstat  & sample == "JC" , robust
	 
	
* adjust lables to harmonize
label var hispanic_imputed "Hispanic"
label var hhsize "Household size"
label var prev_job "Ever had job"
label var school_grade "Highest grade"
label var flag_interruption "Gap in service (>3 mo)"
label var flag_age_older1 "Reported older age"
label var flag_age_younger1 "Reported younger age"
label var log_distance_address_camp1 "Log home-camp distance"
label var allottee_amount1 "First allottee amount"

*** harmonize outcomes
*** CCC census regression sample set-up

tab Eligible1940, m

gen cens_wage_obs = .
replace cens_wage_obs = 1 if enrollment_year1 < 1939 & discharge_year1 < 1939
replace cens_wage_obs = 0 if enrollment_year2 != . & discharge_year2 != . & enrollment_year2 <= 1939 & discharge_year2 >= 1939
replace cens_wage_obs = 0 if enrollment_year3 != . & discharge_year3 != . & enrollment_year3 <= 1939 & discharge_year3 >= 1939
replace cens_wage_obs = 0 if enrollment_year4 != . & discharge_year4 != . & enrollment_year4 <= 1939 & discharge_year4 >= 1939
replace cens_wage_obs = 0 if cens_wage_obs == .

replace cens_wage = 0 if cens_wkswork1 == 0
replace cens_wage = 0 if cens_wage == . & cens_wkswork1 == 0


gen short_educ = highgrade_48 if sample == "JC"
replace short_educ = cw_years_educ if sample == "CCC"
gen short_moved = moved if sample == "JC"
replace short_moved = cw_moved if sample == "CCC"
gen short_employed = employed if sample == "JC"
replace short_employed = cens_working if sample == "CCC"
gen short_wksworked = wksworked_prevyr if sample == "JC"
replace short_wksworked = cens_wkswork1 if sample == "CCC"
gen short_lwage = ln_earnings_if_employed if sample == "JC"
replace short_lwage = cens_lwage_working if sample == "CCC"


}



tempfile regfile
save `regfile'

*******************************
*** short-term regressions and control function
*******************************

*** relativize
{
*** do JC short-term regressions here, store coefficients for common variables

*** set-up

* making sure the controls are all imputed
	global ctrl_miss = ""
	foreach var in $vars_noCCC $other {
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

*** CCC census regression sample set-up

tab Eligible1940, m

gen cens_wage_obs2 = .
replace cens_wage_obs2 = 1 if enrollment_year1 < 1939 & discharge_year1 < 1939
replace cens_wage_obs2 = 0 if enrollment_year2 != . & discharge_year2 != . & enrollment_year2 <= 1939 & discharge_year2 >= 1939
replace cens_wage_obs2 = 0 if enrollment_year3 != . & discharge_year3 != . & enrollment_year3 <= 1939 & discharge_year3 >= 1939
replace cens_wage_obs2 = 0 if enrollment_year4 != . & discharge_year4 != . & enrollment_year4 <= 1939 & discharge_year4 >= 1939
replace cens_wage_obs2 = 0 if cens_wage_obs == .

replace cens_wage = 0 if cens_wkswork1 == 0
replace cens_wage = 0 if cens_wage == . & cens_wkswork1 == 0

*** create weights for weighted sample
global vars_CCC_rel = "enrollment_age1 school_grade_rel nonwhite_rel unemp1_rel farm_rel hhsize_harm_rel"

*** SUMMARY STATISTICS (MEAN SD)
gen share_below_41p = HH_INC <= 4 if sample == "JC"
replace share_below_41p = . if HH_INC == . | HH_INC == .e & sample == "JC"
replace share_below_41p = hh_wage < 480 if sample == "CCC"
replace share_below_41p = . if hh_wage == . & sample == "CCC"

gen nonwhite = hispanic_imputed == 0 if sample == "CCC"
replace nonwhite = . if m_hispanic_imputed == 1 & sample == "CCC"
replace nonwhite = RACE_ETH != 1 if sample == "JC"
replace nonwhite = . if RACE_ETH == . & sample == "JC"
replace nonwhite = . if RACE_ETH == .d & sample == "JC"
gen m_nonwhite = m_hispanic_imputed if sample == "CCC"
replace m_nonwhite = nonwhite == . if sample == "JC"

gen hhsize_harm = hhsize if sample == "CCC"
replace hhsize_harm = . if m_hhsize == 1 & sample == "CCC"
replace hhsize_harm = NUMB_HH if sample == "JC"
replace hhsize_harm = . if (NUMB_HH == . | NUMB_HH == .e) & sample == "JC"

gen m_hhsize_harm = m_hhsize if sample == "CCC"
replace m_hhsize_harm = hhsize == . if sample == "JC"
gen m_pers_inc = pers_inc == .
gen m_share_below_41p = share_below_41p == .
gen m_cens_wage = cens_wage == .
gen m_cens_wage_working = cens_wage_working == .

* for levels of variables
*** Table 2 for JC and CCC vars
foreach var in school_grade nonwhite unemp1 farm hhsize_harm pers_inc cens_wage cens_wage_working share_below_41p {

	disp "CCC"
	if ~inlist("`var'","cens_wage","cens_wage_working","share_below_41p") sum `var' if sample == "CCC" & m_`var' == 0
	if inlist("`var'","cens_wage","cens_wage_working","share_below_41p") sum `var' if sample == "CCC" & m_`var' == 0 & enrollment_year1 > 1940
	
	disp "JC"
	sum `var' if sample == "JC"

}

* for relative measures
* national means can be found from Excel files generated from the census means do files
* the program that generates this is the dofile in the same folder
local school_grade_1940_mean = 9.88920355355549
local unemp1_1940_mean = 0.193328109257808
local nonwhite_1940_mean = 0.201178451178451
local farm_1940_mean = 0.302303336394246
local hhsize_harm_1940_mean = 4.7244031221304

local school_grade_1940_sd = 2.61739843571171
local unemp1_1940_sd = 0.39491908148292
local nonwhite_1940_sd = 0.400888801315087
local farm_1940_sd = 0.459264737870101
local hhsize_harm_1940_sd = 2.70509496459987

local school_grade_1990_mean = 11.9736010502111
local unemp1_1990_mean = 0.125970879149593
local nonwhite_1990_mean = 0.295827663440411
local farm_1990_mean = 0.0136760564154047
local hhsize_harm_1990_mean = 3.3352476611617

local school_grade_1990_sd = 2.23056456620928
local unemp1_1990_sd = 0.331818036797655
local nonwhite_1990_sd = 0.456415319270527
local farm_1990_sd = 0.11614260722631
local hhsize_harm_1990_sd = 1.9179190112857

foreach var in school_grade nonwhite unemp1 farm hhsize_harm {
gen `var'_rel = (`var' - ``var'_1940_mean') / ``var'_1940_sd' if sample == "CCC"
replace `var'_rel = (`var' - ``var'_1990_mean') / ``var'_1990_sd' if sample == "JC"

}

gen m_vars_CCC = 0
foreach var in $vars_CCC nonwhite {
	replace m_vars_CCC = 1 if m_`var' == 1
	}
tab sample 
tab sample if m_vars_CCC == 0

gen inJC = sample == "JC"
gen inCCC = sample == "CCC"


***  ebalance

ebalance inCCC ${vars_CCC_rel} , gen(ebalance_rel)
	
sum ebalance_rel if sample == "JC", d 

* try reweighting and taking summaries
foreach wts in ebalance_rel {
global weights = "`wts'"
capture drop weights_JC
gen weights_JC = 1 - ${weights}

*** Appendix Table : relative characteristics
local wc : word count $vars_CCC_rel
mat def Asum = J(`wc',3,.)
local i = 1
foreach var in $vars_CCC_rel {
	* taking into missing for each var

	local varm = "`var'"
	if substr("`var'",-4,.) == "_rel" local varm = substr("`var'",1,strlen("`var'")-4)
	
	sum `var' if sample == "JC" & m_`varm' == 0 & ${weights} != .
	mat def Asum[`i',1] = `r(mean)'
	sum `var' if sample == "JC" & m_`varm' == 0 [aw=${weights}]
	mat def Asum[`i',2] = `r(mean)'
	sum `var' if sample == "CCC" & m_`varm' == 0 & ${weights} != . // this ensures only those used in ebalance is included
	mat def Asum[`i',3] = `r(mean)'
	
	local i = `i' + 1
	
	}

mat colnames Asum = "JC" "JC Weighted" "CCC"
mat rownames Asum = $vars_CCC_rel
mat list Asum

mat def A_${weights} = Asum
}
} // end relativize section
*


***** Table 7 : weigthed versions of JC regressions

* JC regressions with weights
global weights = "ebalance_rel"
preserve
*
putexcel set "${resultdir}/Duration_$weights.xlsx", replace
// iv. Select employment characteristics only if worked at least 2 weeks in previous year
	replace mosinjob = . if mosinjob < .5 
	replace EARN_YR = . if mosinjob < .5
	replace HRSWK_JR = . if mosinjob < .5
	replace hrwager = . if mosinjob < .5
	
foreach var in reason_ccc_endofterm reason_ccc_employment reason_ccc_cog reason_ccc_urgandprop  reason_ccc_deserted reason_ccc_rejected reason_ccc_norecord {
		sum `var' [aw=WGT48B] if sample == "JC"
		replace `var' = `var' - `r(mean)' if sample == "JC"
		tab `var' if sample == "JC"
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

local i =6
foreach y in highgrade_48 employed wksworked_prevyr earnings earnings_if_employed ///
		ln_earnings_if_employed moved ever_married health12 health30 health48 ///
			health_exc12 health_exc30 health_exc48 health_excgd12 health_excgd30 health_excgd48 {
	* OLS
	regress `y' duration1 $ctrl $ctrl_miss [pw=${weights}] if male ==1 & treatmnt ==1 & sample == "JC", robust
	excel_regout duration "D" `i'
	
	* 2SLS
	ivregress 2sls `y' (duration1=treatmnt) [pw=${weights}] if male==1 & sample == "JC", robust
	excel_regout duration "E" `i'
	
	local i=`i'+4
}

putexcel B1 = ("ITT")
putexcel D1 = ("OLS")
putexcel E1 = ("IV")
putexcel clear

restore

***** Table 8 : control functions
gen noweight = 1 // weights if we don't want to do reweighted


*** 1) regressions with only common variables
* OLS
foreach weights in noweight ebalance_rel {
global weights = "`weights'"

* create control functions
foreach short_y_jc in highgrade_48 moved employed wksworked_prevyr ln_earnings_if_employed {
	
	** 1) regressions with common variables
	global ctrl = "${vars_CCC}"
	global ctrl_miss = "${vars_CCC_m}"
	
	regress `short_y_jc' ${durvar} $ctrl $ctrl_miss [pw=${weights}] if male == 1 & treatmnt ==1 & sample == "JC", robust

	foreach var in $durvar $ctrl {
		scalar JC_OLS_comm_`var' = _b[`var']
		}

	* 2SLS
	ivregress 2sls `short_y_jc' (${durvar}=treatmnt) ${ctrl} ${ctrl_miss} [pw=${weights}] if male == 1 & sample == "JC", robust
	
	* store sd of duration for JC
	sum ${durvar} [aw=${weights}] if e(sample) == 1
	scalar JC_sd_comm_duration1 = `r(sd)'
	
	foreach var in $durvar $ctrl {
		scalar JC_2SLS_comm_`var' = _b[`var']
		}
		
	* retrieve bias
	foreach var in $durvar $vars_CCC {
		scalar JC_bias_comm_`var' = JC_OLS_comm_`var' - JC_2SLS_comm_`var'
	}
	scalar JC_V_comm_duration1 = JC_bias_comm_duration1 * JC_sd_comm_duration1


	** 2) regressions with all variables
	global ctrl = "${vars_CCC} ${vars_noCCC} ${vars_CCC_fe} ${other}"
	global ctrl_miss = "${ctrl_miss} ${vars_CCC_m}"		

	regress `short_y_jc' ${durvar} $ctrl $ctrl_miss [pw=${weights}] if male == 1 & treatmnt ==1 & sample == "JC", robust

	foreach var in $durvar $vars_CCC {
		scalar JC_OLS_all_`var' = _b[`var']
		}

	* 2SLS
	ivregress 2sls `short_y_jc' (${durvar}=treatmnt) ${ctrl} ${ctrl_miss} [pw=${weights}] if male == 1 & sample == "JC", robust
	
	* store sd of duration for JC
	sum ${durvar} [aw=${weights}] if e(sample) == 1
	scalar JC_sd_all_duration1 = `r(sd)'
	
	foreach var in $durvar $vars_CCC {
		scalar JC_2SLS_all_`var' = _b[`var']
		}
		
	* retrieve bias
	foreach var in $durvar $vars_CCC {
		scalar JC_bias_all_`var' = JC_OLS_all_`var' - JC_2SLS_all_`var'
	}
	* portion of bias not from sd of duration
	scalar JC_V_all_duration1 = JC_bias_all_duration1 * JC_sd_all_duration1

		
	*** calculate control function for those who can be in short-term regression for CCC
	*** using stored coefficients for common variables
	  
	if "`short_y_jc'" == "highgrade_48"  {
		local short_y_ccc = "cw_years_educ"
		global exp_var = "`short_y_ccc'_exp"
		global ifstat = "if all == 1"
		}
	if "`short_y_jc'" == "moved"  {
		local short_y_ccc = "cw_moved"
		global exp_var = "`short_y_ccc'_exp"
		global ifstat = "if all == 1"
		}
		
	if "`short_y_jc'" == "employed"  local short_y_ccc = "cens_working"
	if "`short_y_jc'" == "wksworked_prevyr"  local short_y_ccc = "cens_wkswork1"
	if "`short_y_jc'" == "ln_earnings_if_employed"  local short_y_ccc = "cens_lwage_working"

	if inlist("`short_y_ccc'","cens_wkswork1","cens_working","cens_lwage_working") {
				global ifstat = "if cens_matched == 1 & cens_wage_obs2 == 1 & Eligible1940 == 1"
				global exp_var = ""
				}
				
	*** case 1: no het in treatment
	
	gen `short_y_ccc'_ctrlfunc_comm = `short_y_ccc' $ifstat & sample == "CCC"
	foreach var in $durvar $vars_CCC {
		disp "`var' * "strofreal(JC_2SLS_comm_`var')
		replace `short_y_ccc'_ctrlfunc_comm = `short_y_ccc'_ctrlfunc_comm - `var'*JC_2SLS_comm_`var' $ifstat & sample == "CCC"
		}
		
	gen `short_y_ccc'_ctrlfunc_all = `short_y_ccc' $ifstat & sample == "CCC"
	foreach var in $durvar $vars_CCC {
		disp "`var' * "strofreal(JC_2SLS_all_`var')
		replace `short_y_ccc'_ctrlfunc_all = `short_y_ccc'_ctrlfunc_all - `var'*JC_2SLS_all_`var' $ifstat & sample == "CCC"
		}
		
	*** case 2: het in treatment, no het in selection
	
	reg `short_y_ccc' ${durvar} ${exp_var} ${vars_CCC} ${vars_CCC_m} $ifstat
	scalar CCC_OLS_comm_duration1 = _b[duration1]
	
	* store sd of duration for CCC
	sum ${durvar} if e(sample) == 1
	scalar CCC_sd_comm_duration1 = `r(sd)'
	
	* correct the OLS estimates by JC's bias factor
	foreach var in $durvar $vars_CCC {
		scalar CCC_corr_comm_`var' = _b[`var'] - JC_bias_comm_`var'
		}
		
	xtreg `short_y_ccc' ${durvar} ${exp_var} ${vars_CCC} ${vars_CCC_m} $X1 $X4 $X6 $X5 $X7 ${peerchars} i.campdum1 $ifstat, fe
	scalar CCC_OLS_all_duration1 = _b[duration1]
	
	* store sd of duration for CCC
	sum ${durvar} if e(sample) == 1
	scalar CCC_sd_all_duration1 = `r(sd)'
	
	predict resids if e(sample), e // save residuals for later
	foreach var in $durvar $vars_CCC {
		scalar CCC_OLS_all_`var' = _b[`var']
		scalar CCC_corr_all_`var' = _b[`var'] - JC_bias_all_`var'
		}
	
	* correct the OLS estimates by JC's bias factor
	gen `short_y_ccc'_ctrlf_comm_sl = `short_y_ccc' $ifstat & sample == "CCC"
	foreach var in $durvar $vars_CCC {
		disp "`var' * "strofreal(CCC_corr_comm_`var')
		replace `short_y_ccc'_ctrlf_comm_sl = `short_y_ccc'_ctrlf_comm_sl - `var'*CCC_corr_comm_`var' $ifstat & sample == "CCC"
		}
		
	gen `short_y_ccc'_ctrlf_all_sl = resids $ifstat & sample == "CCC"
	foreach var in $durvar $vars_CCC {
		disp "`var' * "strofreal(CCC_corr_all_`var')
		replace `short_y_ccc'_ctrlf_all_sl = `short_y_ccc'_ctrlf_all_sl + `var'*CCC_OLS_all_`var' $ifstat & sample == "CCC" // add back the original
		replace `short_y_ccc'_ctrlf_all_sl = `short_y_ccc'_ctrlf_all_sl - `var'*CCC_corr_all_`var' $ifstat & sample == "CCC" // subtract the "bias removed"
		}
	drop resids
}

* generate flags for missing
global ctrlfuncs_comm = "cw_years_educ_ctrlfunc_comm cens_working_ctrlfunc_comm cens_wkswork1_ctrlfunc_comm cens_lwage_working_ctrlfunc_comm cw_moved_ctrlfunc_comm"
global ctrlfuncs_all = "cw_years_educ_ctrlfunc_all cens_working_ctrlfunc_all cens_wkswork1_ctrlfunc_all cens_lwage_working_ctrlfunc_all cw_moved_ctrlfunc_all"
global ctrlfuncs_comm_sl = "cw_years_educ_ctrlf_comm_sl cens_working_ctrlf_comm_sl cens_wkswork1_ctrlf_comm_sl cens_lwage_working_ctrlf_comm_sl cw_moved_ctrlf_comm_sl"
global ctrlfuncs_all_sl = "cw_years_educ_ctrlf_all_sl cens_working_ctrlf_all_sl cens_wkswork1_ctrlf_all_sl cens_lwage_working_ctrlf_all_sl cw_moved_ctrlf_all_sl"


foreach var in $ctrlfuncs_all {
	gen m`var' = `var' == .
	}
gen nonmissing_ctrlf = 1
foreach var in $ctrlfuncs_comm {
	replace nonmissing_ctrlf = 0 if `var' == .
	}
	
gen nonmissing_ctrlf_sl = 1
foreach var in $ctrlfuncs_comm_sl {
	replace nonmissing_ctrlf_sl = 0 if `var' == .
	}

sum $ctrlfuncs_comm $ctrlfuncs_all 
sum $ctrlfuncs_comm_sl $ctrlfuncs_all_sl


**** this is for final version of table with just education/moved (most populated well) and then adding others
global ctrlfuncs_comm = "cw_years_educ_ctrlfunc_comm cens_working_ctrlfunc_comm cens_wkswork1_ctrlfunc_comm cens_lwage_working_ctrlfunc_comm cw_moved_ctrlfunc_comm"
global ctrlfuncs_all = "cw_years_educ_ctrlfunc_all cens_working_ctrlfunc_all cens_wkswork1_ctrlfunc_all cens_lwage_working_ctrlfunc_all cw_moved_ctrlfunc_all"
global ctrlfuncs_comm_sl = "cw_years_educ_ctrlf_comm_sl cens_working_ctrlf_comm_sl cens_wkswork1_ctrlf_comm_sl cens_lwage_working_ctrlf_comm_sl cw_moved_ctrlf_comm_sl"
global ctrlfuncs_all_sl = "cw_years_educ_ctrlf_all_sl cens_working_ctrlf_all_sl cens_wkswork1_ctrlf_all_sl cens_lwage_working_ctrlf_all_sl cw_moved_ctrlf_all_sl"

forvalues i = 1(1)4 {

if `i' == 1 { 
	* Panel D: Including all CTRL Functions
	global ctrlfuncs_comm_subset = "${ctrlfuncs_comm}"
	global ctrlfuncs_all_subset = "${ctrlfuncs_all}"
	global ctrlfuncs_comm_sl_subset = "${ctrlfuncs_comm_sl}"
	global ctrlfuncs_all_sl_subset = "${ctrlfuncs_all_sl}"
	}
	
if `i' == 2 {
	* Panel A: Including just Educ
	global ctrlfuncs_comm_subset = "cw_years_educ_ctrlfunc_comm"
	global ctrlfuncs_all_subset = "cw_years_educ_ctrlfunc_all"
	global ctrlfuncs_comm_sl_subset = "cw_years_educ_ctrlf_comm_sl"
	global ctrlfuncs_all_sl_subset = "cw_years_educ_ctrlf_all_sl"
	}
	
if `i' == 3 {
	* Panel B: Including just Moved
	global ctrlfuncs_comm_subset = "cw_moved_ctrlfunc_comm"
	global ctrlfuncs_all_subset = "cw_moved_ctrlfunc_all"
	global ctrlfuncs_comm_sl_subset = "cw_moved_ctrlf_comm_sl"
	global ctrlfuncs_all_sl_subset = "cw_moved_ctrlf_all_sl"
	}

if `i' == 4 {
	* Panel C: Including just small Samples
	global ctrlfuncs_comm_subset = "cens_working_ctrlfunc_comm cens_wkswork1_ctrlfunc_comm cens_lwage_working_ctrlfunc_comm"
	global ctrlfuncs_all_subset = "cens_working_ctrlfunc_all cens_wkswork1_ctrlfunc_all cens_lwage_working_ctrlfunc_all"
	global ctrlfuncs_comm_sl_subset = "cens_working_ctrlf_comm_sl cens_wkswork1_ctrlf_comm_sl cens_lwage_working_ctrlf_comm_sl"
	global ctrlfuncs_all_sl_subset = "cens_working_ctrlf_all_sl cens_wkswork1_ctrlf_all_sl cens_lwage_working_ctrlf_all_sl"
	}


gen nonmissing_ctrlf_subset = 1
foreach var in $ctrlfuncs_comm_subset $ctrlfuncs_all_subset {
	replace nonmissing_ctrlf_subset = 0 if `var' == .
	}
	
gen nonmissing_ctrlf_sl_subset = 1
foreach var in $ctrlfuncs_comm_sl_subset $ctrlfuncs_all_sl_subset {
	replace nonmissing_ctrlf_sl_subset = 0 if `var' == .
	}


*** OLS
*** use the control function for those in sample
global ifstat = "if death_age >= 45 & nonmissing_ctrlf_subset == 1 & nonmissing_ctrlf_sl_subset == 1"
global yvar = "ldeath_age"
* with peer and camp effects
* no control functions
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} $ifstat & sample == "CCC", $option_se fe
gen qin = e(sample)
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", replace bdec($option_bdec) ctitle("OLS with Camp Chars") addtext("Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N") keep(${X0} ${keepdum}) label

*** Approach 1 - Selection and TE the same
* including control functions using common variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_comm_subset} $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
test ${ctrlfuncs_comm_subset}
global pval = string(round(`r(p)',0.001),"%9.2f")
local JC_2SLS = JC_2SLS_comm_duration1
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs Common") addtext("JC 2SLS",`JC_2SLS',"Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_comm}) label

* including control functions using all variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_all_subset} $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
test ${ctrlfuncs_all_subset}
global pval = string(round(`r(p)',0.001),"%9.2f")
local JC_2SLS = JC_2SLS_all_duration1
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs All") addtext("JC 2SLS",`JC_2SLS',"Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_all}) label


*** Approach 2 - Selection Same but Difference in TE
* including control functions using common variables in JC reg with no selection het but treatment het
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_comm_sl_subset} $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
test ${ctrlfuncs_comm_sl_subset}
global pval = string(round(`r(p)',0.001),"%9.2f")
* calculate the bias changes
local adj = 0
foreach var in $ctrlfuncs_comm_sl_subset {
	local adj = `adj' - _b[`var']
	}
local adj = `adj' * (1/CCC_sd_comm_duration1 - 1/JC_sd_comm_duration1) * JC_V_comm_duration1
local JC_bias = 1/CCC_sd_comm_duration1 * JC_V_comm_duration1
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs Common Het Trt No Sel") addtext("Adjustment",`adj',"JC Bias",`JC_bias',"Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_comm_sl}) label

* including control functions using all variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_all_sl_subset} $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
test ${ctrlfuncs_all_sl_subset}
global pval = string(round(`r(p)',0.001),"%9.2f")

* calculate the bias changes
local adj = 0
foreach var in $ctrlfuncs_all_sl_subset {
	local adj = `adj' - _b[`var']
	}
local adj = `adj' * (1/CCC_sd_all_duration1 - 1/JC_sd_all_duration1) * JC_V_all_duration1
local JC_bias = 1/CCC_sd_all_duration1 * JC_V_all_duration1
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs All Het Trt No Sel") addtext("Adjustment",`adj',"JC Bias",`JC_bias',"Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_all_sl}) label

*** ADDING INTERACTED TERMS
*** Approach 1 - Selection and TE the same
* including control functions using common variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_comm_subset} c.${X0}#c.(${ctrlfuncs_comm_subset}) $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
testparm ${ctrlfuncs_comm_subset} c.${X0}#c.(${ctrlfuncs_comm_subset})
global pval = string(round(`r(p)',0.001),"%9.2f")
* calculate the ATE
local ATE = _b[${X0}]
local keepvarlist = "" // also add keep var list for outreg
foreach var in $ctrlfuncs_comm_subset {
	quietly sum `var' $ifstat & sample == "CCC" & qin == 1
	local ATE = `ATE' + _b[c.${X0}#c.`var']*`r(mean)'
	local keepvarlist = "`keepvarlist'" + " c.${X0}#c.`var'"
	}

outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs Common") addtext("ATE",`ATE',"Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_comm} `keepvarlist') label

* including control functions using all variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_all_subset} c.${X0}#c.(${ctrlfuncs_all_subset}) $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
testparm ${ctrlfuncs_all_subset} c.${X0}#c.(${ctrlfuncs_all_subset})
global pval = string(round(`r(p)',0.001),"%9.2f")
* calculate the ATE
local ATE = _b[${X0}]
local keepvarlist = "" // also add keep var list for outreg
foreach var in $ctrlfuncs_all_subset {
	quietly sum `var' $ifstat & sample == "CCC" & qin == 1
	local ATE = `ATE' + _b[c.${X0}#c.`var']*`r(mean)'
	local keepvarlist = "`keepvarlist'" + " c.${X0}#c.`var'"
	}
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs All") addtext("ATE",`ATE',"Mean Dep",${meany},"FE","BD,CYQ","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_all} `keepvarlist') label


*** Approach 2 - Selection Same but Difference in TE
* including control functions using common variables in JC reg with no selection het but treatment het
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_comm_sl_subset} c.${X0}#c.(${ctrlfuncs_comm_sl_subset}) $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
testparm ${ctrlfuncs_comm_sl_subset} c.${X0}#c.(${ctrlfuncs_comm_sl_subset})
global pval = string(round(`r(p)',0.001),"%9.2f")
* calculate the ATE
local ATE = _b[${X0}]
local keepvarlist = "" // also add keep var list for outreg
foreach var in $ctrlfuncs_comm_sl_subset {
	quietly sum `var' $ifstat & sample == "CCC" & qin == 1
	local ATE = `ATE' + _b[c.${X0}#c.`var']*`r(mean)'
	local keepvarlist = "`keepvarlist'" + " c.${X0}#c.`var'"
	}

outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs Common Het Trt No Sel") addtext("ATE",`ATE',"Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_comm_sl} `keepvarlist') label

* including control functions using all variables in JC reg
xtreg ${yvar} $X0 $X1 $X4 $X6 $X5 $X7 ${campchars} ${peerchars} ${ctrlfuncs_all_sl_subset} c.${X0}#c.(${ctrlfuncs_all_sl_subset}) $ifstat & sample == "CCC" & qin == 1, $option_se fe
xtregfe_replace_r2
quietly sum ${yvar} $ifstat & e(sample) == 1
global meany = string(round(`r(mean)',0.001),"%9.2f")
test ${ctrlfuncs_all_sl_subset}
global pval = string(round(`r(p)',0.001),"%9.2f")
* calculate the ATE
local ATE = _b[${X0}]
local keepvarlist = "" // also add keep var list for outreg
foreach var in $ctrlfuncs_all_sl_subset {
	quietly sum `var' $ifstat & sample == "CCC" & qin == 1
	local ATE = `ATE' + _b[c.${X0}#c.`var']*`r(mean)'
	local keepvarlist = "`keepvarlist'" + " c.${X0}#c.`var'"
	}
outreg2 using "${resultdir}/reg_${yvar}_ctrlfuncs_Panel`i'_$weights.xml", append bdec($option_bdec) ctitle("OLS w Ctrlfuncs All Het Trt No Sel") addtext("ATE",`ATE',"Mean Dep",${meany},"FE","BD,CYQ,Camp","Sample","All","Reason","N","Joint Test P Val",${pval}) keep(${X0} ${keepdum} ${ctrlfuncs_all_sl} `keepvarlist') label



drop qin

drop nonmissing_ctrlf_subset nonmissing_ctrlf_sl_subset

}
drop $ctrlfuncs_comm $ctrlfuncs_all $ctrlfuncs_comm_sl $ctrlfuncs_all_sl ///
	nonmissing_ctrlf nonmissing_ctrlf_sl

foreach var in $ctrlfuncs_all {
	drop m`var'
	}
}

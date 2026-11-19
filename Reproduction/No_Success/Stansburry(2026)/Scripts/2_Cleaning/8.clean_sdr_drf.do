********************************************************************************
*Clean fully merged SDR/DRF dataset
********************************************************************************

********************************************************************************
*Clean data
********************************************************************************

*Load data
use "$DATA/sdrdrf_matched_2021", clear

******************
*Parental Education
*Generate variable: Highest level of parental education
g edpar= "4: PhD" if (EDMOTHER=="8" | EDFATHER=="8") 
replace edpar= "3: Grad" if missing(edpar) & (EDMOTHER=="7" | EDFATHER=="7" | EDMOTHER=="6" | EDFATHER=="6") 
replace edpar= "2: BA" if missing(edpar) & (EDMOTHER=="5" | EDFATHER=="5") 
replace edpar= "1: No BA" if missing(edpar) & (EDMOTHER=="1" | EDFATHER=="1" | EDMOTHER=="2" | EDFATHER=="2" | EDMOTHER=="3" | EDFATHER=="3" | EDMOTHER=="4" | EDFATHER=="4") 
encode edpar, gen(edpar_n)
***A little under 10% are missing edpar

g firstgen= 1 if edpar_n==1
replace firstgen = 0 if !missing(edpar_n) & firstgen!=1


******************
*Gender
gen gender = 1 if (GENDER=="F")
replace gender = 0 if (GENDER=="M")
label define gen_lab 0 "Male" 1 "Female"
label values gender gen_lab
label var gender "Female"

******************
*Race
g race_c="White, Non-Hispanic"  if RACE==10 
replace race_c="Black, Non-Hispanic"  if RACE==5 
replace race_c="Asian, Non-Hispanic"  if (RACE==2 | RACE==3 | RACE==4) 
replace race_c="Hispanic, All Races"  if (RACE==6 | RACE==7 | RACE==8 | RACE==9) 
replace race_c="Other, Non-Hispanic"  if (RACE==11 | RACE==12 | RACE==1) 
encode race_c, gen(race_n)

*URM indicator
gen urm = 1 if race_n==2|race_n==3
replace urm = 1 if RACE==1
replace urm = 0 if urm!=1 & !missing(race_n)

******************
*Country of birth
*Extract numerical values (FIPS codes) for birthplace
gen BIRTH_NUM = BIRTHPL

*US born or foreign born tag
gen bornus=1 if BIRTH_NUM<=99 & !missing(BIRTH_NUM)
replace bornus = 0 if BIRTH_NUM>99 & !missing(BIRTH_NUM)
replace bornus = 0 if missing(BIRTH_NUM)
g bornus_miss = 1 if missing(BIRTH_NUM)

*Birth country
gen BIRTHCOUNTRY = BIRTH_NUM
replace BIRTHCOUNTRY = 001 if bornus==1 /*Birthpl codes US states separately; this combines them*/
*Ensure that those missing birth country are not dropped entirely from our regressions when we use BIRTHCOUNTRY as FEs
replace BIRTHCOUNTRY = 99999 if missing(BIRTHCOUNTRY)

*Generate Birth continent variable for FEs
g BIRTHCON_temp = "US" if BIRTHCOUNTRY<100
replace BIRTHCON_temp = "Eastern Europe" if BIRTHCOUNTRY==101 | BIRTHCOUNTRY==104 | BIRTHCOUNTRY==105 | BIRTHCOUNTRY==116 | BIRTHCOUNTRY==117 | BIRTHCOUNTRY==128 | BIRTHCOUNTRY==132 | BIRTHCOUNTRY==147 | BIRTHCOUNTRY==149 | BIRTHCOUNTRY==150 | (BIRTHCOUNTRY>=155 & BIRTHCOUNTRY<=187) | BIRTHCOUNTRY==193
replace BIRTHCON_temp = "Western Europe" if BIRTHCOUNTRY==100 | BIRTHCOUNTRY==102 | BIRTHCOUNTRY==103 | (BIRTHCOUNTRY>=106 & BIRTHCOUNTRY<=115) | (BIRTHCOUNTRY>=118 & BIRTHCOUNTRY<=127) | (BIRTHCOUNTRY>=129 & BIRTHCOUNTRY<=131) | (BIRTHCOUNTRY>=133 & BIRTHCOUNTRY<=146) | BIRTHCOUNTRY==151 | BIRTHCOUNTRY==152
replace BIRTHCON_temp = "East Asia" if BIRTHCOUNTRY==207 | BIRTHCOUNTRY==209 | BIRTHCOUNTRY==215 | BIRTHCOUNTRY==218 | BIRTHCOUNTRY==219 | BIRTHCOUNTRY==223 | BIRTHCOUNTRY==226 | BIRTHCOUNTRY==230 | BIRTHCOUNTRY==238 | BIRTHCOUNTRY==247
replace BIRTHCON_temp = "Southeast Asia" if (BIRTHCOUNTRY>=204 & BIRTHCOUNTRY<=206) | BIRTHCOUNTRY==211 | BIRTHCOUNTRY==221 | BIRTHCOUNTRY==224 | BIRTHCOUNTRY==231 | BIRTHCOUNTRY==234 | BIRTHCOUNTRY==235 | BIRTHCOUNTRY==239 | BIRTHCOUNTRY==242 | BIRTHCOUNTRY==249 | BIRTHCOUNTRY==255 | BIRTHCOUNTRY==257
replace BIRTHCON_temp = "South Asia" if BIRTHCOUNTRY==202 | BIRTHCOUNTRY==203 | BIRTHCOUNTRY==210 | BIRTHCOUNTRY==212 | BIRTHCOUNTRY==225 | BIRTHCOUNTRY==227 | BIRTHCOUNTRY==229 | BIRTHCOUNTRY==236
replace BIRTHCON_temp = "West and Central Asia" if (BIRTHCOUNTRY>=188 & BIRTHCOUNTRY<=192) | (BIRTHCOUNTRY>=194 & BIRTHCOUNTRY<=201) | BIRTHCOUNTRY==208 | BIRTHCOUNTRY==213 | BIRTHCOUNTRY==214 | BIRTHCOUNTRY==216 | BIRTHCOUNTRY==220 | BIRTHCOUNTRY==222 | BIRTHCOUNTRY==228 | BIRTHCOUNTRY==232 | BIRTHCOUNTRY==233 | BIRTHCOUNTRY==237 | BIRTHCOUNTRY==240 | BIRTHCOUNTRY==241 | (BIRTHCOUNTRY>=243 & BIRTHCOUNTRY<=245) | (BIRTHCOUNTRY>=250 & BIRTHCOUNTRY<=254) | BIRTHCOUNTRY==256 | BIRTHCOUNTRY==248
/*245 is "Asia" so leaving it as central for now*/
replace BIRTHCON_temp = "North America ex. US" if (BIRTHCOUNTRY>=301 & BIRTHCOUNTRY<=304) | BIRTHCOUNTRY==315
replace BIRTHCON_temp = "South America" if (BIRTHCOUNTRY>=375 & BIRTHCOUNTRY<=389)
replace BIRTHCON_temp = "Central America" if (BIRTHCOUNTRY>=310 & BIRTHCOUNTRY<=314) | (BIRTHCOUNTRY>=316 & BIRTHCOUNTRY<=318)
replace BIRTHCON_temp = "Caribbean" if BIRTHCOUNTRY==300 | (BIRTHCOUNTRY>=330 & BIRTHCOUNTRY<=361)
/*345 is "Latin America" so leaving it as caribben for now*/
replace BIRTHCON_temp = "Africa" if (BIRTHCOUNTRY>=400 & BIRTHCOUNTRY<=472)
replace BIRTHCON_temp = "Oceania" if BIRTHCOUNTRY>=500
replace BIRTHCON_temp = "Missing" if BIRTHCOUNTRY==99999 | BIRTHCOUNTRY==554 | BIRTHCOUNTRY==555 | missing(BIRTHCOUNTRY)

label define birthcon_lbl 0 "US" 1 "North America ex. US" 2 "Central America" 3 "Caribbean" 4 "South America" 5 "Western Europe" 6 "Eastern Europe" 7 "East Asia" 8 "South Asia" 9 "Southeast Asia" 10 "West and Central Asia" 11 "Africa" 12 "Oceania" 99999 "Missing"
encode BIRTHCON_temp, gen(BIRTHCON) label(birthcon_lbl)

******************
*Family Indicators

*Children in the household in the survey year (includes >=18)
g child_ind_yr_w18 =1 if CHLVIN=="Y"
replace child_ind_yr_w18 =0 if CHLVIN=="N"

*Children reported in the household ever (includes >=18)
g child_ever_temp_w18= 1 if CHLVIN=="Y" | DEPENDS>0
bysort DRF_ID: egen child_ever_w18 = mean(child_ever_temp_w18)
replace child_ever_w18=0 if missing(child_ever_w18)

*Indicator of 18/19 yr and old children
g child_18=1 if CH18>=1 & CH18<=7
replace child_18=1 if CH19>=1 & CH19<=9

*Children in the household in the survey year (excludes >=18)
g child_ind_yr =1 if CHLVIN=="Y" & missing(child_18)
replace child_ind_yr =0 if CHLVIN=="N" | child_18==1

*Children reported in the household ever (excludes >=18)
g child_ever_temp= 1 if (CHLVIN=="Y" | DEPENDS>0) & missing(child_18) 
bysort DRF_ID: egen child_ever = mean(child_ever_temp)
replace child_ever=0 if missing(child_ever)

*Married in SDR year
g married_ind_yr = 1 if MARIND=="Y"
replace married_ind_yr = 0 if MARIND=="N"

*Married ever
g married_ever_temp= 1 if MARIND=="Y"
bysort DRF_ID: egen married_ever = mean(married_ever_temp)
replace married_ever=0 if missing(married_ever)

*Spouse working indicator

*Does your spouse work at all?
g spouse_work_any = 1 if SPOWK=="1" | SPOWK=="2"
replace spouse_work_any=0 if missing(spouse_work_any)
g spouse_work_any_miss=1 if SPOWK=="L"

*Does your spouse work full-time?
g spouse_work_ft = 1 if SPOWK=="1"
replace spouse_work_ft=0 if missing(spouse_work_ft)
g spouse_work_ft_miss=1 if SPOWK=="L"

*Does your spouse work part-time?
g spouse_work_pt = 1 if SPOWK=="2"
replace spouse_work_pt=0 if missing(spouse_work_pt)
g spouse_work_pt_miss=1 if SPOWK=="L"

*Does your spouse's work require STEM expertise?
g spouse_work_stem=1 if SPNAT=="Y"
replace spouse_work_stem=0 if missing(spouse_work_stem)
g spouse_work_stem_miss=1 if SPNAT=="L"

*Does your spouse's work require social science expertise?
g spouse_work_soc=1 if SPSOC=="Y"
replace spouse_work_soc=0 if missing(spouse_work_soc)
g spouse_work_stem_soc=1 if SPSOC=="L"

/*No variables specifiying care for an eldery parent. SDR 2021 documentation does indicate that variables indicating the reason for changing or leaving employment if family-related could include "eldercare"*/


******************
*Broad Degree Field Category
local degs BA MA PHD
foreach deg of local degs {
	cap drop `deg'_CAT
g `deg'_CAT = "Agr Sciences" if (`deg'FIELD>=1 & `deg'FIELD<=99) 
replace `deg'_CAT = "Bio Sciences" if  (`deg'FIELD>=100 & `deg'FIELD<=199)  | `deg'FIELD==626
replace `deg'_CAT = "Health" if (`deg'FIELD>=200 & `deg'FIELD<=299) | `deg'FIELD==577
replace `deg'_CAT = "Engineering" if (`deg'FIELD>=300 & `deg'FIELD<=399) | `deg'FIELD==68 | `deg'FIELD==547 | `deg'FIELD==415
replace `deg'_CAT = "Comp/Inf Sciences" if `deg'FIELD>=400 & `deg'FIELD<=419 & `deg'FIELD!=415
replace `deg'_CAT = "Math/Stats" if (`deg'FIELD>=420 & `deg'FIELD<=499) | `deg'FIELD==930 | `deg'FIELD==910 | `deg'FIELD==935 | `deg'FIELD==938 
replace `deg'_CAT = "Phys/Geo/Atmos/Ocean Sciences" if (`deg'FIELD>=500 & `deg'FIELD<=599 & `deg'FIELD!=577 & `deg'FIELD!=547)
replace `deg'_CAT = "Psychology" if (`deg'FIELD>=600 & `deg'FIELD<=649 & `deg'FIELD!=626) | `deg'FIELD==822 | `deg'FIELD==825 | `deg'FIELD==889 
replace `deg'_CAT = "Social Sciences ex Econ" if (`deg'FIELD>=650 & `deg'FIELD<=699 & `deg'FIELD!=685) | `deg'FIELD==710 | `deg'FIELD==773 | `deg'FIELD==770 | `deg'FIELD==700 | `deg'FIELD==964 | `deg'FIELD==976
replace `deg'_CAT = "Economics" if `deg'FIELD==667 | `deg'FIELD==0 | `deg'FIELD==3 | `deg'FIELD==665 | `deg'FIELD==667 | `deg'FIELD==668 | `deg'FIELD==685
label var `deg'_CAT "`deg' Degree Category"
}
encode PHD_CAT, gen(phd_cat)
/*Only missing 37 people who fall into education and other/professional fields*/


*Fine Degree Field Category
local degs BA PHD
foreach deg of local degs {
g `deg'_CATFINE = "Bio Science" if (`deg'FIELD>=100 & `deg'FIELD<=199) | `deg'FIELD==626 
replace `deg'_CATFINE = "Mathematics" if `deg'FIELD>=420 & `deg'FIELD<=499
replace `deg'_CATFINE = "Comp/Inf Sciences" if `deg'FIELD>=400 & `deg'FIELD<=419
replace `deg'_CATFINE = "Psychology" if (`deg'FIELD>=600 & `deg'FIELD<=649 & `deg'FIELD!=626 ) | `deg'FIELD==822 | `deg'FIELD==825
replace `deg'_CATFINE = "Economics" if `deg'FIELD==667 | `deg'FIELD==0 | `deg'FIELD==3 | `deg'FIELD==665 | `deg'FIELD==668 | `deg'FIELD==685
replace `deg'_CATFINE = "Chemistry" if (`deg'FIELD>=520 & `deg'FIELD<=539) | `deg'FIELD==542 | `deg'FIELD==510 | `deg'FIELD==549   
replace `deg'_CATFINE = "Physics" if (`deg'FIELD>=561 & `deg'FIELD<=579) | `deg'FIELD==544 | `deg'FIELD==545 | `deg'FIELD==505  | `deg'FIELD==506  | `deg'FIELD==512
replace `deg'_CATFINE = "Political Science" if `deg'FIELD==678 | `deg'FIELD==679 | `deg'FIELD==674
replace `deg'_CATFINE = "Sociology" if `deg'FIELD==686
replace `deg'_CATFINE = "History" if (`deg'FIELD>=700 & `deg'FIELD<=719) | `deg'FIELD==770 | `deg'FIELD==775 | `deg'FIELD==776  | `deg'FIELD==777
replace `deg'_CATFINE = "Public Policy" if `deg'FIELD==682
replace `deg'_CATFINE = "Audiology" if `deg'FIELD==200
replace `deg'_CATFINE = "Business" if `deg'FIELD>=900 & `deg'FIELD<=939 /*No business PhDs before 2003, possibly due to the SEH nature of this data*/
replace `deg'_CATFINE = "Earth Sciences" if (`deg'FIELD>=540 & `deg'FIELD<=559) | `deg'FIELD==599 | (`deg'FIELD>=585 & `deg'FIELD<=595) | (`deg'FIELD>=510 & `deg'FIELD<=519)
replace `deg'_CATFINE = "Engineering" if (`deg'FIELD>=300 & `deg'FIELD<=399) | PHDFIELD==415 | PHDFIELD==547
replace `deg'_CATFINE = "Medicine" if (`deg'FIELD>=222 & `deg'FIELD<=227) | (`deg'FIELD>=235 & `deg'FIELD<=299) | `deg'FIELD==205 | `deg'FIELD==207 | `deg'FIELD==577
replace `deg'_CATFINE = "Nursing" if `deg'FIELD==230
replace `deg'_CATFINE = "Public Health" if `deg'FIELD>=210 & `deg'FIELD<=220
replace `deg'_CATFINE = "Statistics" if `deg'FIELD==690
replace `deg'_CATFINE = "Criminology" if `deg'FIELD==657 | `deg'FIELD==658
encode `deg'_CATFINE, gen(`deg'_CATFINE1)
drop `deg'_CATFINE
rename `deg'_CATFINE1 `deg'_CATFINE 
}

*PHD Field category - narrower than PHD_CAT but broader than PHDFIELD 
gen PHDFIELDNEW = floor(PHDFIELD/10)*10

*Very broad PhD field group category
gen PHD_GROUP = 1 if PHD_CAT=="Agr Sciences"|PHD_CAT=="Bio Sciences"|PHD_CAT=="Health"
replace PHD_GROUP = 2 if PHD_CAT=="Comp/Inf Sciences" | PHD_CAT=="Engineering" | PHD_CAT=="Phys/Geo/Atmos/Ocean Sciences" | PHD_CAT=="Math/Stats"
replace PHD_GROUP = 3 if PHD_CAT=="Economics" | PHD_CAT=="Psychology" | PHD_CAT=="Social Sciences ex Econ"

******************

*Generate non-working tag
g non_working = 1 if LFSTAT=="2" | LFSTAT=="3" /*No missing values for this var, so no missing var variables*/
replace non_working = 0 if non_working!=1
label var non_working  "Indicator if someone is not working (unemployed or not in labor force)"

*Group variables
g DECADE_temp = "1990s" if YR<=1999
replace DECADE_temp = "2000s" if YR>=2000 & YR<=2009
replace DECADE_temp = "long 2010s" if YR>=2010
encode(DECADE_temp), gen(DECADE)
g AGE5y = floor(AGE/10)*10

*PHD year, and years since PhD, five year groups
g years_since_phd = YR-PHDCY
gen PHDCY5y = floor(PHDCY/5)*5
gen years_since_phd5y = floor(years_since_phd/5)*5
gen PHDDECADE = floor(PHDCY/10)*10 

*Generate PhD Decade by PhD category fixed effect variable
egen PHDDEC_FIELD= group(PHDFIELD PHDDECADE)

*Generate first gen share by decade and field
bysort PHDFIELD PHDDECADE: egen firstgenshare = mean(firstgen) if !missing(firstgen) /*Missing moslty in the 90s survey years and 1950s phd decade*/

*PHD PROGRAM, and PHD Program by Five year graduation group *NOTE: doing this with PHDFIELDNEW new, not PHDFIELD
egen PHDPROGRAM = group(PHDINST PHDFIELDNEW)
egen PHDPROGRAM5y = group(PHDPROGRAM PHDCY5y)
egen PHDPROGRAMDECADE = group(PHDPROGRAM PHDDECADE)
egen PHDPROGRAMYR = group(PHDPROGRAM PHDCY)



******************

*Generate tag for living and working in the US
g LOCATIONUS = 1 if FNINUS=="Y"
replace LOCATIONUS = 1 if FNUS9095=="X" /*1995 specific code*/
replace LOCATIONUS = 0 if LOCATIONUS!=1
/*No missing values with original variables, so no missing variable*/


******************

*Salary Vars
*Replace missing values
foreach var in SALARY EARN {
	replace `var'=. if `var'==999996 | `var'==9999998 | `var'==999999 | `var'==9999996 | `var'==999998 | `var'==9999995
}

*Merge in inflation adjustments
merge m:1 YR using "$INFLATE/cpi99"
*Adjust variables to 2021 using inflation metrics
g SALARYADJ=(SALARY*cpi21/100)
g EARNADJ=(EARN*cpi21/100)

g lnSALARY = ln(SALARYADJ) /*Basic annual salary at job before deductions as of survey date*/
g lnEARN = ln(EARNADJ) /*Not in 1993 SDR; Total earned income before deductions in the previous year*/

label var lnEARN "Log Earnings"
label var lnSALARY "Log Salary"

* Synthetic adjustment:
drop if YR == 2005
drop if YR == 2007
drop if YR == 2011

******************
*Generate job satifaction binaries and continuous vars
foreach var in JOBSATIS SATSAL SATBEN SATSEC SATLOC SATADV SATCHAL SATRESP SATIND SATSOC{
	gen `var'1 = 0 if `var'=="2" | `var'=="3" | `var'=="4"
	replace `var'1 = 1 if `var'=="1"
	gen `var'_temp = `var'
	replace `var'_temp = "" if `var'_temp=="L"
	destring `var'_temp, gen(`var'_num)
	replace `var'_num = -`var'_num /*So that a larger number is more satisfied*/
	drop `var'_temp
	}

*Generate job importance binaries and continuous vars
foreach var in FACSAL FACBEN FACSEC FACLOC FACADV FACCHAL FACRESP FACIND FACSOC{	
	gen `var'1 = 0 if `var'=="2" | `var'=="3" | `var'=="4"
	replace `var'1 = 1 if `var'=="1"
	gen `var'_temp = `var'
	replace `var'_temp = "" if `var'_temp=="L"
	destring `var'_temp, gen(`var'_num)
	replace `var'_num = -`var'_num /*So that a larger number is more satisfied*/
	drop `var'_temp
	}
	
******************
*Generate sector and tenure variables
g TENURETRACK = (TENSTA=="4" | TENSTA=="3")
g TENURETRACK_miss=1 if TENSTA=="L"
g TTNOTTEN = (TENSTA=="4")
g TTNOTTEN_miss=1 if TENSTA=="L"
g TENURE = (TENSTA=="3")
g TENURE_miss=1 if TENSTA=="L"
bysort DRF_ID: egen EVER_TTRACK = max(TENURETRACK) /*Inidcates having ever been on the tenure-track, including tenureed positions, in our sample*/

g EDUSECTOR = (EMSECSM=="1") /*Should the logical skips be considered missing for these variables? (i.e., where EMSECSM=="L"*/
g EDUSECTOR_miss=1 if EMSECSM=="L"
g GOVSECTOR = (EMSECSM=="2")
g EGOVSECTOR_miss=1 if EMSECSM=="L"
g INDSECTOR = (EMSECSM=="3")
g INDSECTOR_miss=1 if EMSECSM=="L"
g EDUNTT = (TENURETRACK==0 & EDUSECTOR==1)
g EDUNTT_miss=1 if TENSTA=="L" | EMSECSM=="L"

******************

*Employment characteristics
*Supervisees
replace SUPDIR=. if SUPDIR==9998 /*Direct*/
replace SUPIND=. if SUPIND==9998 | SUPIND==99998 | SUPIND==99996 /*Indirect*/
g SUPERVISEES = SUPDIR + SUPIND
g SUPER=1 if SUPWK=="Y" /*Indicator of being a supervisor*/
replace SUPER=0 if missing(SUPER)
g SUPER_miss=1 if SUPWK=="L"
g SUPER10=1 if SUPWK=="Y" & SUPERVISEES>=10 & !missing(SUPERVISEES)
replace SUPER10=0 if SUPWK=="N" | SUPWK=="L" | (SUPWK=="Y" & SUPERVISEES<10) | (SUPWK=="Y" & missing(SUPERVISEES))
g SUPER10_miss=1 if SUPWK=="L" | missing(SUPERVISEES)
g SUPER50=1 if SUPWK=="Y" & SUPERVISEES>=50 & !missing(SUPERVISEES)
replace SUPER50=0 if SUPWK=="N" | SUPWK=="L" | (SUPWK=="Y" & SUPERVISEES<50) | (SUPWK=="Y" & missing(SUPERVISEES))
g SUPER50_miss=1 if SUPWK=="L" | missing(SUPERVISEES)

g SUPERFULL = "1: 0" if SUPER==0
replace SUPERFULL = "2: 1-9" if SUPER==1 & (SUPERVISEES>=1 & SUPERVISEES<=9)
replace SUPERFULL = "3: 10-49" if SUPER10==1 & SUPER50==0
replace SUPERFULL = "4: 50+" if SUPER50==1

*Manager occupation
g topmanager = (N2OCPR=="711410")
replace topmanager = (NOCPR=="711410") if !missing(NOCPR)
/*Top manager and middle manager are combined pre 2001, so we have no info on topmanager pre 2001*/
g topmanager_miss=1 if missing(N2OCPR) & missing(NOCPR) 
 g anymanager = (N2OCPR=="711410" | N2OCPR=="711460" | N2OCPR=="711470") /*For Anna: do we care about other minor manager groups? e.g., engineering managers - Good spot, yes we do! I have updated this code. */
replace anymanager = (NOCPR=="711410" | NOCPR=="711460" | NOCPR=="711470") if !missing(NOCPR)
replace anymanager = (OCPR=="611410" ) if !missing(OCPR)
 replace anymanager = 1 if N2OCPR=="621420" | N2OCPR=="621430" | N2OCPR == "621440"
 replace anymanager = 1 if NOCPR=="621420" | NOCPR=="621430" | NOCPR == "621440" | NOCPR =="621450"
/*Note that codes pre 2001 don't have as much distinction on managerial occupations - you may want to drop these in robustness checks when estimating manager results */
g anymanager_miss=1 if missing(N2OCPR) & missing(NOCPR) & missing(OCPR)

*Employer size/*
/*Variable EMSIZE not in 1993, doesn't seem to be an equivalent in this survey*/
g EMSIZE5000 = 1 if EMSIZE=="8" | EMSIZE=="7"
replace EMSIZE5000=0 if missing(EMSIZE5000)
g EMSIZE5000_miss=1 if missing(EMSIZE) | EMSIZE!="L"
g EMSIZE500 = 1 if EMSIZE=="8" | EMSIZE=="7" | EMSIZE=="6" | EMSIZE=="5"
replace EMSIZE500=0 if missing(EMSIZE500)
g EMSIZE500_miss=1 if missing(EMSIZE) | EMSIZE!="L"

g EMSIZEFULL = "1: less than 500" if EMSIZE5000==0 & EMSIZE500==0
replace EMSIZEFULL = "2: 500 to 5000" if EMSIZE500==1
replace EMSIZEFULL = "3: greater than 5000" if EMSIZE5000==1
*/

*Employer type
g forprofit = (NEDTP=="1") if (YR>=1993 & YR<=2001)
replace forprofit = (NEDTP=="03" | NEDTP=="3") if YR>=2003
g forprofit_miss=1 if NEDTP=="L"
g nonprofit = (NEDTP=="2") if (YR>=1993 & YR<=2001)
replace nonprofit = (NEDTP=="04" | NEDTP=="4") if YR>=2003
g nonprofit_miss=1 if NEDTP=="L"
g selfemployed = (NEDTP=="3" | NEDTP=="4") if (YR>=1993 & YR<=2001)
replace selfemployed = (NEDTP=="01" | NEDTP=="1" | NEDTP=="02" | NEDTP=="2") if YR>=2003
g selfemployed_miss=1 if NEDTP=="L"
g otheremployer = (NEDTP=="09" | NEDTP=="9")
g otheremployer_miss=1 if NEDTP=="L"

replace NEDTP = subinstr(NEDTP,"0","",.) if strpos(NEDTP,"0")==1

*Occupation type
replace N2OCPRNG="NA" if N2OCPRNG=="98" | N2OCPRNG==""
replace NOCPRNG="NA" if NOCPRNG=="98" | NOCPRNG==""
replace OCPRNG="NA" if OCPRNG=="98" | OCPRNG==""
replace OCPRNG="72" if OCPRNG=="61"
replace OCPRNG="61" if OCPRNG=="62"
replace OCPRNG="74" if OCPRNG=="64"
replace OCPRNG="75" if OCPRNG=="65"
replace OCPRNG="64" if OCPRNG=="66"
replace OCPRNG="76" if OCPRNG=="67"
replace OCPRNG="77" if OCPRNG=="68"
replace OCPRNG="78" if OCPRNG=="69"
g OCCCODE = N2OCPRNG 
replace OCCCODE = NOCPRNG if N2OCPRNG=="NA"
replace OCCCODE = OCPRNG if N2OCPRNG=="NA" & NOCPRNG=="NA"
egen OCCSTATE = group(OCCCODE EMST) 

************************************
*Student debt 
*Debt values are given in buckets, so this imputes the actual values

*Debt
g graddebt=0 if GDEBTLVL==0
replace graddebt=5000 if GDEBTLVL==11
replace graddebt=15000 if GDEBTLVL==12
replace graddebt=25000 if GDEBTLVL==13
replace graddebt=35000 if GDEBTLVL==14
replace graddebt=45000 if GDEBTLVL==15
replace graddebt=55000 if GDEBTLVL==26
replace graddebt=65000 if GDEBTLVL==27
replace graddebt=75000 if GDEBTLVL==38
replace graddebt=85000 if GDEBTLVL==39
replace graddebt=100000 if GDEBTLVL==40
replace graddebt=2500 if GDEBTLVL==1
replace graddebt=7500 if GDEBTLVL==2
replace graddebt=12500 if GDEBTLVL==3
replace graddebt=17500 if GDEBTLVL==4
replace graddebt=22500 if GDEBTLVL==5
replace graddebt=27500 if GDEBTLVL==6
replace graddebt=32500 if GDEBTLVL==7

replace graddebt = 0.25*75000 + 0.31*85000 + 0.44*100000 if GDEBTLVL==28
replace graddebt = 0.27*55000 + 0.23*65000 + 0.50*(0.25*75000 + 0.31*85000 + 0.44*100000) if GDEBTLVL==16
replace graddebt = (0.165/0.835)*37500 + (0.15/0.835)*45000 + (0.25/0.835)*(0.27*55000 + .23*65000 + 0.50*(0.25*75000 + 0.31*85000 + 0.44*100000)) if GDEBTLVL==8

g unddebt=0 if UDEBTLVL==0
replace unddebt=5000 if UDEBTLVL==11
replace unddebt=15000 if UDEBTLVL==12
replace unddebt=25000 if UDEBTLVL==13
replace unddebt=35000 if UDEBTLVL==14
replace unddebt=45000 if UDEBTLVL==15
replace unddebt=55000 if UDEBTLVL==26
replace unddebt=65000 if UDEBTLVL==27
replace unddebt=75000 if UDEBTLVL==38
replace unddebt=85000 if UDEBTLVL==39
replace unddebt=100000 if UDEBTLVL==40
replace unddebt=2500 if UDEBTLVL==1
replace unddebt=7500 if UDEBTLVL==2
replace unddebt=12500 if UDEBTLVL==3
replace unddebt=17500 if UDEBTLVL==4
replace unddebt=22500 if UDEBTLVL==5
replace unddebt=27500 if UDEBTLVL==6
replace unddebt=32500 if UDEBTLVL==7

replace unddebt = 0.59*75000 + 0.23*85000 + 0.18*100000 if UDEBTLVL==28
replace unddebt = 0.47*55000 + 0.40*65000 + 0.13*(0.59*75000 + 0.23*85000 + 0.18*100000) if UDEBTLVL==16
replace unddebt = (0.3/0.7)*37500 + (0.24/0.7)*45000 + (0.15/0.7)*(0.47*55000 + .40*65000 + 0.13*(0.59*75000 + 0.23*85000 + 0.18*100000)) if UDEBTLVL==8

g ugdebttot= unddebt+graddebt
label var ugdebttot "Total debt" 

g ugdebttotsq = ugdebttot^2

*Generate different units of debt
g ugdebttot_tenthou = ugdebttot/10000
label var ugdebttot_tenthou "Total Debt ($10,000)"
g ugdebttot_tenthousq = sqrt(ugdebttot_tenthou)
label var ugdebttot_tenthousq "Total Debt Squared ($10,000)"

************************************
*Institution variables

*Prepare insitution codes for merging (some codes are older and have changed over time)
foreach var in BAINST PHDINST INSTCOD {
replace `var'="110468" if `var'=="124885" 
replace `var'="216348" if `var'=="176284"
replace `var'="206084" if `var'=="203951"
replace `var'="209490" if `var'=="209472"
replace `var'="212054" if `var'=="212841"
replace `var'="139755" if `var'=="238883"
replace `var'="134130" if `var'=="435338"
replace `var'="173957" if `var'=="365426"
replace `var'="228723" if `var'=="223214"
replace `var'="233277" if `var'=="231837"
replace `var'="104151" if `var'=="103778"
replace `var'="489779" if `var'=="260901"
replace `var'="489779" if `var'=="260910"
replace `var'="215293" if `var'=="418418"
replace `var'="" if `var'=="137148" /*Removed due to these codes relating to defunct schools (Argosy mostly)*/
replace `var'="" if `var'=="145770"
replace `var'="" if `var'=="367936"
replace `var'="" if `var'=="436438"
replace `var'="" if `var'=="448734"
replace `var'="" if `var'=="450526"
replace `var'="" if `var'=="450979"
replace `var'="" if `var'=="456348"
replace `var' = strtrim(`var')
}

************************************************************************
*Impute INSTCOD for missing values
bysort REFID: egen MINYR = min(YR)

*Generate lag and lead variables for institution code and tenure status
*Throughout, we denote L1 as the survey observation directly before the current period, F1 as the survey observation directly after, L2 as two before, and F2 as two after
foreach  var in INSTCOD TENSTA  {
	foreach i in 1 2 {
bys REFID (YR): gen str16 L`i'`var' = `var'[_n-`i']
bys REFID (YR): gen str16 F`i'`var' = `var'[_n+`i']
}
}

*Generate missing INSTCOD inidcator
g INSTCOD_miss = 1 if INSTCOD=="999999" | INSTCOD=="999998" | INSTCOD=="999996"  | INSTCOD=="999996" |  INSTCOD=="999901" | INSTCOD=="999902" | INSTCOD=="999904" | INSTCOD=="999905" | INSTCOD=="999906" | INSTCOD=="999908" | INSTCOD=="999909" | INSTCOD=="999910" | INSTCOD=="999911" | INSTCOD=="999912" | INSTCOD=="999913" | INSTCOD=="999915" | INSTCOD=="999917" | INSTCOD=="999918" | INSTCOD=="999919" | INSTCOD=="999920" | INSTCOD=="999921" | INSTCOD=="999922" | INSTCOD=="999923" | INSTCOD=="999924" | INSTCOD=="999925" | INSTCOD=="999926" | INSTCOD=="999927" | INSTCOD=="999928" | INSTCOD=="999929" | INSTCOD=="999930" | INSTCOD=="999931" | INSTCOD=="999932" | INSTCOD=="999934" | INSTCOD=="999935" | INSTCOD=="999936" | INSTCOD=="999937" | INSTCOD=="999939" | INSTCOD=="999940" | INSTCOD=="999941" | INSTCOD=="999942" | INSTCOD=="999944" | INSTCOD=="999945" | INSTCOD=="999946" | INSTCOD=="999947" | INSTCOD=="999948" | INSTCOD=="999949" | INSTCOD=="999950" | INSTCOD=="999951" | INSTCOD=="999953" | INSTCOD=="999954" | INSTCOD=="999955" | INSTCOD=="999956" | INSTCOD=="999972" | INSTCOD=="888888" | INSTCOD=="777777" | INSTCOD=="000000" | INSTCOD=="L" | INSTCOD=="LLLLLL" /*Unknown/missing and logical skips; in some years, all of the codes starting with four 9s indicate missing but the state is known (indicted by the last two digits)*/
replace INSTCOD_miss = 0 if missing(INSTCOD_miss)

foreach  var in INSTCOD_miss  {
	foreach i in 1 2 {
bys REFID (YR): gen  L`i'`var' = `var'[_n-`i']
bys REFID (YR): gen  F`i'`var' = `var'[_n+`i']
}
}

*Imputed institution code variable
cap drop INSTCOD_imp
gen INSTCOD_imp = ""

******************************
*SAME INSTITUTION IN L1 AND F1
*Impute institution for people who are at the same institution in survey T+1 and survey T-1, under specific conditions:
******************************
***Same tenure status in L1 and F1
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F1INSTCOD & L1INSTCOD_miss!=1 & L1TENSTA==F1TENSTA & TENSTA!="L" &  INSTCOD_miss==1 & missing(INSTCOD_imp)
***TT without tenure in L1, and then "gets tenure" either in current period or F1 (allow also the middle year to be a TENSTA==2, "position does not have a tenure option", since a lot of people seem to move from TT without tenure, to TENSTA==2, to tenure)
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F1INSTCOD & L1INSTCOD_miss!=1 &  INSTCOD_miss==1 & L1TENSTA=="4" & (TENSTA=="3"|TENSTA=="4") & F1TENSTA=="3" & missing(INSTCOD_imp)
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F1INSTCOD & L1INSTCOD_miss!=1 &  INSTCOD_miss==1 & L1TENSTA=="4" & TENSTA=="3" & F1TENSTA=="3" & missing(INSTCOD_imp)
***TT without tenure in L1, and then doesn't get tenure either in current period or F1 - moves to a non tenure track position
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F1INSTCOD & L1INSTCOD_miss!=1 &  INSTCOD_miss==1 & L1TENSTA=="4" & (TENSTA=="2"|TENSTA=="4"|TENSTA=="5") & (F1TENSTA=="2"|F1TENSTA=="5") & missing(INSTCOD_imp)
***Non tenure track in L1, and TT in current and next year
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F1INSTCOD & L1INSTCOD_miss!=1 &  INSTCOD_miss==1 & (L1TENSTA=="2"|L1TENSTA=="5") & TENSTA=="4" & (F1TENSTA=="4"|F1TENSTA=="3") & missing(INSTCOD_imp)
******************************


******************************
*SAME INSTITUTION IN L2 and F1, or L1 and F2... 
*If someone is observed at the same institution in L2 and F1, or L1 and F2, and the TWO middle surveys between then are missing institution, impute same institution under certain conditions
******************************
*SAME INSTITUTION IN L1 AND F2
*TT no tenure for L1, Current period, F1, and then either TT no tenure or tenured in F2
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F2INSTCOD & L1INSTCOD_miss!=1 & L1TENSTA=="4" & TENSTA=="4" & F1TENSTA=="4" & (F2TENSTA=="4"|F2TENSTA=="3") &  INSTCOD_miss==1 & F1INSTCOD_miss==1  & missing(INSTCOD_imp)
*TT no tenure for L1, Current period, and tenured in F1, F2
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F2INSTCOD & L1INSTCOD_miss!=1 & L1TENSTA=="4" & TENSTA=="4" & F1TENSTA=="3" & F2TENSTA=="3" &  INSTCOD_miss==1 & F1INSTCOD_miss==1  & missing(INSTCOD_imp)
*TT no tenure for L1, and tenured for current period, F1, F2
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F2INSTCOD & L1INSTCOD_miss!=1 & L1TENSTA=="4" & TENSTA=="3" & F1TENSTA=="3" & F2TENSTA=="3" &  INSTCOD_miss==1 & F1INSTCOD_miss==1 & missing(INSTCOD_imp)
*Tenured in all four periods
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==F2INSTCOD & L1INSTCOD_miss!=1 & L1TENSTA=="3" & TENSTA=="3" & F1TENSTA=="3" & F2TENSTA=="3" &  INSTCOD_miss==1 & F1INSTCOD_miss==1 & missing(INSTCOD_imp)

*SAME INSTITUTION IN L2 and F1
*Either on tenure track or in a non TT position in L2; on tenure track in L1 and current period, and on TT or tenured in F1
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==L2INSTCOD &  INSTCOD_miss==1 & L1INSTCOD_miss==1 & F1INSTCOD_miss!=1 & (L2TENSTA=="4") & L1TENSTA=="4" & (TENSTA=="4") & (F1TENSTA=="4"|F1TENSTA=="3")  & missing(INSTCOD_imp) 
*Either on tenure track or in a non TT position in L2; on tenure track in L1; tenured in current period and F1
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==L2INSTCOD & F1INSTCOD_miss!=1 & (L2TENSTA=="4") & L1TENSTA=="4" & (TENSTA=="3") & (F1TENSTA=="3") &  INSTCOD_miss==1  & L1INSTCOD_miss==1 & missing(INSTCOD_imp) 
*Tenure track in L2, tenured in L1 through F1
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==L2INSTCOD & F1INSTCOD_miss!=1 & (L2TENSTA=="4") & L1TENSTA=="3" & (TENSTA=="3") & (F1TENSTA=="3") &  INSTCOD_miss==1  & L1INSTCOD_miss==1 & missing(INSTCOD_imp) 
*Tenured all four periods
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==L2INSTCOD & F1INSTCOD_miss!=1 & (L2TENSTA=="3") & L1TENSTA=="3" & (TENSTA=="3") & (F1TENSTA=="3") &  INSTCOD_miss==1  & L1INSTCOD_miss==1 & missing(INSTCOD_imp) 

*Impute institution for someone who is TT not tenured in L2 at institution I, is not in academia / not working (TENSTA=="L") in survey L1 (this might represent temporary leave), is TT not tenured again in current period but with missing institution, and is tenured at original institution I in surveys F1 and F2
replace INSTCOD_imp = L2INSTCOD if L2INSTCOD==F1INSTCOD & L2INSTCOD_miss!=1 & L1INSTCOD_miss==1 & INSTCOD_miss==1  &  L2TENSTA=="4" & L1TENSTA=="L" & TENSTA=="4" & F1TENSTA=="4" & F2TENSTA=="4"  & missing(INSTCOD_imp) 
replace INSTCOD_imp = L2INSTCOD if L2INSTCOD==F1INSTCOD & L2INSTCOD_miss!=1 & L1INSTCOD_miss==1 & INSTCOD_miss==1  &  L2TENSTA=="4" & L1TENSTA=="L" & TENSTA=="4" & F1TENSTA=="4" & F2TENSTA=="3"  & missing(INSTCOD_imp) 
replace INSTCOD_imp = L2INSTCOD if L2INSTCOD==F1INSTCOD & L2INSTCOD_miss!=1 & L1INSTCOD_miss==1 & INSTCOD_miss==1  &  L2TENSTA=="4" & L1TENSTA=="L" & TENSTA=="4" & F1TENSTA=="3" & F2TENSTA=="3"  & missing(INSTCOD_imp) 
replace INSTCOD_imp = L2INSTCOD if L2INSTCOD==F1INSTCOD & L2INSTCOD_miss!=1 & L1INSTCOD_miss==1 & INSTCOD_miss==1  &  L2TENSTA=="4" & L1TENSTA=="L" & TENSTA=="3" & F1TENSTA=="3" & F2TENSTA=="3"  & missing(INSTCOD_imp) 
replace INSTCOD_imp = L2INSTCOD if L2INSTCOD==F1INSTCOD & L2INSTCOD_miss!=1 & L1INSTCOD_miss==1 & INSTCOD_miss==1  &  L2TENSTA=="3" & L1TENSTA=="L" & TENSTA=="3" & F1TENSTA=="3" & F2TENSTA=="3"  & missing(INSTCOD_imp) 
******************************

******************************
*OTHER CONDITIONS
*TT no tenure in L2 and L1 at same institution, and then still TT no tenure in current period but missing institution - and have moved institution for F1 (& NOT on TT or tenured)
replace INSTCOD_imp = L1INSTCOD if L1INSTCOD==L2INSTCOD & L1INSTCOD_miss!=1 & INSTCOD_miss==1 & L2TENSTA=="4" & L1TENSTA=="4" & TENSTA=="4"  & F1INSTCOD!=L1INSTCOD & F1TENSTA!="3" & F1TENSTA!="4" & missing(INSTCOD_imp) 

*Tenured in current period with missing institution, tenured in F1 and F2 at same institution; non-tenured and at a different institution in L1, and 
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==F2INSTCOD & F1INSTCOD_miss!=1 & F1TENSTA=="3" & F2TENSTA=="3" & TENSTA=="3" & L1TENSTA!="3" & INSTCOD_miss==1 & L1INSTCOD!=F1INSTCOD  & missing(INSTCOD_imp) 

*TT no tenure in current period with missing institution, NOT TT no tenure and at a different institution in L1, and TT no tenure in F1 and F2 at same institution
replace INSTCOD_imp = F1INSTCOD if F1INSTCOD==F2INSTCOD & F1INSTCOD_miss!=1 & F1TENSTA=="4" & F2TENSTA=="4" & TENSTA=="4"& L1TENSTA!="4"  & L1INSTCOD!=F1INSTCOD  & INSTCOD_miss==1  & missing(INSTCOD_imp) 

*Assume that if someone is only observed in their first year in the survey on tenure track or tenured with missing institution, and then they are TT or tenured at same institution for next two observations (F1 and F2), they were on the tenure track at the same institution (this applies to a lot of 2015 observations)
replace INSTCOD_imp = F1INSTCOD if INSTCOD_miss==1 & F1INSTCOD_miss!=1 & F1INSTCOD==F2INSTCOD & TENSTA=="4" & F1TENSTA=="3" & F2TENSTA=="3" & YR == MINYR  & missing(INSTCOD_imp) 
replace INSTCOD_imp = F1INSTCOD if INSTCOD_miss==1 & F1INSTCOD_miss!=1 & F1INSTCOD==F2INSTCOD & TENSTA=="4" & F1TENSTA=="4" & (F2TENSTA=="4"|F2TENSTA=="3") & YR == MINYR  & missing(INSTCOD_imp) 
replace INSTCOD_imp = F1INSTCOD if INSTCOD_miss==1 & F1INSTCOD_miss!=1 & F1INSTCOD==F2INSTCOD & TENSTA=="3" & F1TENSTA=="3" & F2TENSTA=="3" & YR == MINYR  & missing(INSTCOD_imp) 

*Impute institution for someone who is in a specific institution on tenure track last survey, is still on tenure track this survey but with missing instcod, and then is doing something else, somewhere else, next two surveys
replace INSTCOD_imp = L1INSTCOD if INSTCOD_miss==1 & L1INSTCOD_miss!=1 & L1TENSTA=="4" & TENSTA=="4" & F1TENSTA!="4" & F2TENSTA!="4" & F1TENSTA!="3" & F2TENSTA!="3"   & missing(INSTCOD_imp) 

*Replace imputation with mising in full INSTCOD
replace INSTCOD = INSTCOD_imp if INSTCOD_miss==1 & !missing(INSTCOD_imp)
rename INSTCOD_miss INSTCOD_miss_orig

*Update missing INSTCOD indicator
gen INSTCOD_miss = 1 if  (INSTCOD=="999999" | INSTCOD=="999998" | INSTCOD=="999996"  | INSTCOD=="999996" |  INSTCOD=="999901" | INSTCOD=="999902" | INSTCOD=="999904" | INSTCOD=="999905" | INSTCOD=="999906" | INSTCOD=="999908" | INSTCOD=="999909" | INSTCOD=="999910" | INSTCOD=="999911" | INSTCOD=="999912" | INSTCOD=="999913" | INSTCOD=="999915" | INSTCOD=="999917" | INSTCOD=="999918" | INSTCOD=="999919" | INSTCOD=="999920" | INSTCOD=="999921" | INSTCOD=="999922" | INSTCOD=="999923" | INSTCOD=="999924" | INSTCOD=="999925" | INSTCOD=="999926" | INSTCOD=="999927" | INSTCOD=="999928" | INSTCOD=="999929" | INSTCOD=="999930" | INSTCOD=="999931" | INSTCOD=="999932" | INSTCOD=="999934" | INSTCOD=="999935" | INSTCOD=="999936" | INSTCOD=="999937" | INSTCOD=="999939" | INSTCOD=="999940" | INSTCOD=="999941" | INSTCOD=="999942" | INSTCOD=="999944" | INSTCOD=="999945" | INSTCOD=="999946" | INSTCOD=="999947" | INSTCOD=="999948" | INSTCOD=="999949" | INSTCOD=="999950" | INSTCOD=="999951" | INSTCOD=="999953" | INSTCOD=="999954" | INSTCOD=="999955" | INSTCOD=="999956" | INSTCOD=="999972" | INSTCOD=="888888" | INSTCOD=="777777" | INSTCOD=="000000" | INSTCOD=="L" | INSTCOD=="LLLLLL") /*Unknown/missing and logical skips; in some years, all of the codes starting with four 9s indicate missing but the state is known (indicted by the last two digits)*/
replace INSTCOD_miss = 1 if missing(INSTCOD)
replace INSTCOD_miss = 0 if missing(INSTCOD_miss)

* little global reminder to avoid the below breaking
global data "$main/Data" 
global DATA "$data/data"

*Merge institution file in on current insitution codes to 1) get consistent carnegie calssifications for these institutions and 2) to get locations for later distance regressions

merge m:1 INSTCOD using "$DATA/Currinstcodes", gen(instcod_m)
drop if instcod_m==2
drop instcod_m


*Merge in undergrad ranks from USNWR to current institution employer
g BAinstid = INSTCOD
merge m:1 BAinstid using "$RANK/BA22IPEDS.dta", generate(fmerge)
drop fmerge
rename BA22Rank BAFULLRANK
*Generate log of this ranking
g LOGBARANK = ln(BAFULLRANK)
*Generate grouping variable based on this ranking
g BAFULLRANKGROUP = floor(BAFULLRANK/10)*10

*Merge in liberal arts college rankings
g LAC24Inst  = INSTCOD
merge m:1 LAC24Inst using "$RANK/LAC24IPEDS.dta", generate(fmerge)
drop if fmerge==2
drop fmerge
g LACFULLRANK = LAC24Rank
g LOGLACRANK = ln(LACFULLRANK)
g LACFULLRANKGROUP = floor(LACFULLRANK/10)*10

*Merge PhD field-specific rankings from USNWR to (1) Phd program and (2) current employer
local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22
foreach f of local fields {
	merge m:1 INSTCOD using "$RANK/`f'IPEDS.dta", generate(fmerge)
	drop if fmerge==2
	drop fmerge
	merge m:1 PHDINST using "$RANK/`f'IPEDSPHD.dta", generate(fmerge)
	drop if fmerge==2
	drop fmerge
}

************************************
*Institution rank variables

*Generate PhD institution rankings by compiling the appropriate ranks from the appropriate fields
g PHDRANK=.
replace PHDRANK=Audio20RankPHD if PHD_CATFINE==1
replace PHDRANK=Bio22RankPHD if PHD_CATFINE==2
replace PHDRANK=Bus23RankPHD if PHD_CATFINE==3
replace PHDRANK=Chem22RankPHD  if PHD_CATFINE==4
replace PHDRANK=CompSci22RankPHD if PHD_CATFINE==5
replace PHDRANK=Crim21RankPHD if PHD_CATFINE==6
replace PHDRANK=Earth22RankPHD  if PHD_CATFINE==7
replace PHDRANK=Econ23RankPHD if PHD_CATFINE==8
replace PHDRANK=Eng23RankPHD if PHD_CATFINE==9
replace PHDRANK=History21RankPHD if PHD_CATFINE==10
replace PHDRANK=Math22RankPHD if PHD_CATFINE==11
replace PHDRANK=Med23RankPHD if PHD_CATFINE==12
replace PHDRANK=Nurse23RankPHD if PHD_CATFINE==13
replace PHDRANK=Physics22RankPHD if PHD_CATFINE==14
replace PHDRANK=PoliSci21RankPHD if PHD_CATFINE==15
replace PHDRANK=Psych23RankPHD if PHD_CATFINE==16
replace PHDRANK=PH22RankPHD if PHD_CATFINE==17
replace PHDRANK=PP22RankPHD if PHD_CATFINE==18
replace PHDRANK=Socio21RankPHD if PHD_CATFINE==19
replace PHDRANK=Stat22RankPHD if PHD_CATFINE==20

*Generate current employer institution rankings by compiling the appropriate ranks from the appropriate fields
g FULLRANK=.
replace FULLRANK=Audio20Rank if PHD_CATFINE==1
replace FULLRANK=Bio22Rank if PHD_CATFINE==2
replace FULLRANK=Bus23Rank if PHD_CATFINE==3
replace FULLRANK=Chem22Rank  if PHD_CATFINE==4
replace FULLRANK=CompSci22Rank if PHD_CATFINE==5
replace FULLRANK=Crim21Rank if PHD_CATFINE==6
replace FULLRANK=Earth22Rank  if PHD_CATFINE==7
replace FULLRANK=Econ23Rank if PHD_CATFINE==8
replace FULLRANK=Eng23Rank if PHD_CATFINE==9
replace FULLRANK=History21Rank if PHD_CATFINE==10
replace FULLRANK=Math22Rank if PHD_CATFINE==11
replace FULLRANK=Med23Rank if PHD_CATFINE==12
replace FULLRANK=Nurse23Rank if PHD_CATFINE==13
replace FULLRANK=Physics22Rank if PHD_CATFINE==14
replace FULLRANK=PoliSci21Rank if PHD_CATFINE==15
replace FULLRANK=Psych23Rank if PHD_CATFINE==16
replace FULLRANK=PH22Rank if PHD_CATFINE==17
replace FULLRANK=PP22Rank if PHD_CATFINE==18
replace FULLRANK=Socio21Rank if PHD_CATFINE==19
replace FULLRANK=Stat22Rank if PHD_CATFINE==20


***********************
*Impute missing ranks

*Encode Rankings
encode PHDINST, gen(PHDINST_num)
encode INSTCOD, gen(INSTCOD_num)

**PhD rankings imputations
g phdranktag = 1 if !missing(PHDRANK) /*Indicator of non-missing phdrank*/

levelsof PHD_CATFINE, local(fields)
foreach var of local fields{
bysort PHD_CATFINE PHDINST_num: egen count`var'_phd= count(phdranktag) if PHD_CATFINE==`var' /*Count non_missing phdrank by fine field and insitution*/
bysort PHD_CAT PHDINST_num (count`var'_phd): replace count`var'_phd=count`var'_phd[1] if missing(count`var'_phd) /*Attach this count variable to all individuals in the same broad field*/
replace count`var'_phd=0 if missing(count`var'_phd) /*Make missing values 0s so that addition can occur later across these variables*/
}

*Generate totals by broad field
g physical_total_phd = count4_phd + count7_phd + count14_phd /*Add the fine count variables within each broad category*/
g socialscience_total_phd = count6_phd + count8_phd + count10_phd + count15_phd + count18_phd + count19_phd

*Generate weighted totals
g count4weight_phd=(count4_phd/physical_total_phd)*Chem22RankPHD /*Calculate for each fine field ranks the their weighted rankings within the broad field*/
replace count4weight_phd=0 if missing(count4weight_phd)
g count7weight_phd=(count7_phd/physical_total_phd)*Earth22RankPHD
replace count7weight_phd=0 if missing(count7weight_phd)
g count14weight_phd=(count14_phd/physical_total_phd)*Physics22RankPHD
replace count14weight_phd=0 if missing(count14weight_phd)

g count6weight_phd=(count6_phd/socialscience_total_phd)*Crim21RankPHD
replace count6weight_phd=0 if missing(count6weight_phd)
g count8weight_phd=(count8_phd/socialscience_total_phd)*Econ23RankPHD
replace count8weight_phd=0 if missing(count8weight_phd)
g count10weight_phd=(count10_phd/socialscience_total_phd)*History21RankPHD
replace count10weight_phd=0 if missing(count10weight_phd)
g count15weight_phd=(count15_phd/socialscience_total_phd)*PoliSci21RankPHD
replace count15weight_phd=0 if missing(count15weight_phd)
g count18weight_phd=(count18_phd/socialscience_total_phd)*PP22RankPHD
replace count18weight_phd=0 if missing(count18weight_phd)
g count19weight_phd=(count19_phd/socialscience_total_phd)*Socio21RankPHD
replace count19weight_phd=0 if missing(count19weight_phd)

g count2weight_phd=Bio22RankPHD /*Only one fine field within the broad bio sciences field*/
replace count2weight_phd=0 if missing(count2weight_phd)

*Calculate full imputation
g physical_impute_phd = count4weight_phd + count7weight_phd + count14weight_phd /*Add the weighted ranks together to get the final imputed rank for the broad fields*/
g socialscience_impute_phd = count6weight_phd + count8weight_phd + count10weight_phd + count15weight_phd  + count18weight_phd + count19weight_phd
g bio_impute_phd = count2weight_phd

*Generate a variable marking which ranks are imputed
g imputed_phd = 1 if !missing(physical_impute_phd) & missing(PHDRANK) & phd_cat==8 & physical_impute_phd!=0
replace imputed_phd = 1 if !missing(socialscience_impute_phd) & missing(PHDRANK) & (phd_cat==4 | phd_cat==10) & socialscience_impute_phd!=0
replace imputed_phd = 1 if !missing(bio_impute_phd) & missing(PHDRANK) & (phd_cat==1 | phd_cat==2) & bio_impute_phd!=0

*Add imputed ranks to PHDRANK
replace PHDRANK=physical_impute_phd if missing(PHDRANK) & phd_cat==8 & imputed_phd==1
replace PHDRANK=socialscience_impute_phd if missing(PHDRANK) & (phd_cat==4 | phd_cat==10) & imputed_phd==1
replace PHDRANK=bio_impute_phd if missing(PHDRANK) & (phd_cat==1 | phd_cat==2) & imputed_phd==1

*Replace any imputed zeros with missing
replace PHDRANK=. if PHDRANK==0

*Generate third order rank polynomials
g PHDRANKsq = PHDRANK^2
g PHDRANKcu = PHDRANK^3


**Current employer rankings imputations
g fullranktag = 1 if !missing(FULLRANK)

levelsof PHD_CATFINE, local(fields)
foreach var of local fields{
bysort PHD_CATFINE INSTCOD_num: egen count`var'_full= count(fullranktag) if PHD_CATFINE==`var'
bysort PHD_CAT INSTCOD_num (count`var'_full): replace count`var'_full=count`var'_full[1] if missing(count`var'_full)
replace count`var'_full=0 if missing(count`var'_full)
}

*Generate totals by broad field
g physical_total_full = count4_full + count7_full + count14_full
g socialscience_total_full = count6_full + count8_full + count10_full + count15_full + count18_full + count19_full

*Generate weighted totals
g count4weight_full=(count4_full/physical_total_full)*Chem22Rank
replace count4weight_full=0 if missing(count4weight_full)
g count7weight_full=(count7_full/physical_total_full)*Earth22Rank
replace count7weight_full=0 if missing(count7weight_full)
g count14weight_full=(count14_full/physical_total_full)*Physics22Rank
replace count14weight_full=0 if missing(count14weight_full)

g count6weight_full=(count6_full/socialscience_total_full)*Crim21Rank
replace count6weight_full=0 if missing(count6weight_full)
g count8weight_full=(count8_full/socialscience_total_full)*Econ23Rank
replace count8weight_full=0 if missing(count8weight_full)
g count10weight_full=(count10_full/socialscience_total_full)*History21Rank
replace count10weight_full=0 if missing(count10weight_full)
g count15weight_full=(count15_full/socialscience_total_full)*PoliSci21Rank
replace count15weight_full=0 if missing(count15weight_full)
g count18weight_full=(count18_full/socialscience_total_full)*PP22Rank
replace count18weight_full=0 if missing(count18weight_full)
g count19weight_full=(count19_full/socialscience_total_full)*Socio21Rank
replace count19weight_full=0 if missing(count19weight_full)

g count2weight_full=Bio22Rank
replace count2weight_full=0 if missing(count2weight_full)

*Calculate full imputation
g physical_impute_full = count4weight_full + count7weight_full + count14weight_full
g socialscience_impute_full = count6weight_full + count8weight_full + count10weight_full + count15weight_full  + count18weight_full + count19weight_full
g bio_imputed_full = count2weight_full

*Generate a variable marking which ranks are imputed
g imputed_full = 1 if !missing(physical_impute_full) & missing(FULLRANK) & phd_cat==8 & physical_impute_full!=0
replace imputed_full = 1 if !missing(socialscience_impute_full) & missing(FULLRANK) & (phd_cat==4 | phd_cat==10) & socialscience_impute_full!=0
replace imputed_full = 1 if !missing(bio_imputed_full) & missing(FULLRANK) & (phd_cat==1|phd_cat==2) & bio_imputed_full!=0

*Add imputed ranks to FULLRANK
replace FULLRANK=physical_impute_full if missing(FULLRANK) & phd_cat==8 & imputed_full==1
replace FULLRANK=socialscience_impute_full if missing(FULLRANK) & (phd_cat==4 | phd_cat==10)& imputed_full==1
replace FULLRANK=bio_imputed_full if missing(FULLRANK) & (phd_cat==1|phd_cat==2) & imputed_full==1

*Replace any imputed zeros with missing
replace FULLRANK=. if FULLRANK==0

*Generate log of FULLRANK
g LOGRANK = ln(FULLRANK)

*Dependent variables for TENURE TRACK or TENURE regressions
foreach var in FULLRANK LOGRANK LOGBARANK { //BARANK
	gen TT`var' = `var' if TENURETRACK==1
	gen TEN`var' = `var' if TENURE==1
}
     
*Generate third order rank polynomials
g FULLRANKsq = FULLRANK^2
g FULLRANKcu = FULLRANK^3

*Generate rank variables for tenured individuals only
//gen TENFULLRANK = FULLRANK if TENURE==1
gen TENBAFULLRANK = BAFULLRANK if TENURE==1

********************************
*Clean Carnegie Classifications

**Current Insitutions carnegie indicators
*I use CARN15C, CARNEG, and Currcarn2015 to generate this variable. All three are carnegie classifications with Currcarn2015 coming from the institution file, CARN15C coming from SDRs >=2006 and CARNEG for 1993 andd 1995. These three nicely help piece together the fullest version of carnegie classifications. CARN15C and Currcarn2015 have the same codes (besides just 10 discrepencies from 4 insitutions which I deal with wjere necessary below, though its mostly taken care of by the order I created these variables) and are able to fill in some missing from each. CARNEG deals with the fact that we don't have applicable 1993 and 1995 INSTCOD codes and most of the rest of the missing variables. We should keep in mind, however, that CARNEG is based on 1994 classifications, so may be a little bit more out of date.

*Clean previous data codes


g Current_Research = 1 if (Currcarn2015==15 | Currcarn2015==16 | Currcarn2015==17) & !missing(Currcarn2015)
replace Current_Research = 1 if (CARN15C=="15" | CARN15C=="16" | CARN15C=="17") & missing(Current_Research) & !missing(CARN15C)
replace Current_Research = 1 if (CARNEG=="11" | CARNEG=="12") & missing(Current_Research) & !missing(CARNEG)
replace Current_Research=1 if INSTCOD=="134130"
replace Current_Research=1 if INSTCOD=="139755"
replace Current_Research=1 if INSTCOD=="228723"
replace Current_Research=0 if INSTCOD=="119678"
replace Current_Research=0 if INSTCOD=="138354"
replace Current_Research=0 if INSTCOD=="145619"
replace Current_Research=0 if INSTCOD=="157757"
replace Current_Research=0 if INSTCOD=="172644"
replace Current_Research=0 if INSTCOD=="177968"
replace Current_Research=0 if INSTCOD=="201104"
replace Current_Research=0 if INSTCOD=="206279"
replace Current_Research=0 if INSTCOD=="242653"
replace Current_Research=1 if INSTCOD=="104151"
replace Current_Research=1 if INSTCOD=="206084"
replace Current_Research=1 if INSTCOD=="212054"
replace Current_Research=1 if INSTCOD=="215293"
replace Current_Research=0 if missing(Current_Research)
g Current_Research_miss=1 if missing(Currcarn2015) & (missing(CARN15C) | CARN15C=="M" | CARN15C=="L") & (missing(CARNEG) | CARNEG=="M" | CARNEG=="L")

g Current_R1 = 1 if (Currcarn2015==15) & !missing(Currcarn2015)
replace Current_R1 = 1 if (CARN15C=="15") & missing(Current_R1) & !missing(CARN15C)
replace Current_R1 = 1 if (CARNEG=="11") & missing(Current_R1) & !missing(CARNEG)
replace Current_R1=1 if INSTCOD=="134130"
replace Current_R1=1 if INSTCOD=="139755"
replace Current_R1=1 if INSTCOD=="228723"
replace Current_R1=1 if INSTCOD=="230728"
replace Current_R1=1 if INSTCOD=="104151"
replace Current_R1=1 if INSTCOD=="215293"
replace Current_R1=1 if INSTCOD=="215293"
replace Current_R1=0 if INSTCOD=="151111"
replace Current_R1=0 if missing(Current_R1)
g Current_R1_miss=1 if missing(Currcarn2015) & (missing(CARN15C) | CARN15C=="M" | CARN15C=="L") & (missing(CARNEG) | CARNEG=="M" | CARNEG=="L")

g Current_R1R2 = 1 if (Currcarn2015==15 | Currcarn2015==16) & !missing(Currcarn2015)
replace Current_R1R2 = 1 if (CARN15C=="15" | CARN15C=="16") & missing(Current_R1R2) & !missing(CARN15C)
replace Current_R1R2 = 1 if (CARNEG=="11" | CARNEG=="12") & missing(Current_R1R2)  & !missing(CARNEG)
replace Current_R1R2 = 1 if INSTCOD=="486840" /*16*/
replace Current_R1R2=1 if INSTCOD=="134130"
replace Current_R1R2=1 if INSTCOD=="139755"
replace Current_R1R2=1 if INSTCOD=="228723"
replace Current_R1R2=0 if INSTCOD=="119678"
replace Current_R1R2=0 if INSTCOD=="127741"
replace Current_R1R2=0 if INSTCOD=="224554"
replace Current_R1R2=1 if INSTCOD=="104151"
replace Current_R1R2=1 if INSTCOD=="206084"
replace Current_R1R2=1 if INSTCOD=="212054"
replace Current_R1R2=1 if INSTCOD=="215293"
replace Current_R1R2=0 if missing(Current_R1R2)
g Current_R1R2_miss=1 if missing(Currcarn2015) & (missing(CARN15C) | CARN15C=="M" | CARN15C=="L") & (missing(CARNEG) | CARNEG=="M" | CARNEG=="L")


********************************
*Institution variables

*First year on the tenure track w/o tenure
bysort DRF_ID TENURETRACK TENURE: egen temp_FIRSTYRTT = min(YR)
g temp2_FIRSTYRTT = temp_FIRSTYRTT if TENURE==0 & TENURETRACK==1
bysort DRF_ID: egen FIRSTYRTT = mean(temp2_FIRSTYRTT)

*First year with tenure
g temp_FIRSTYRTENURE = temp_FIRSTYRTT if TENURE==1
bysort DRF_ID: egen FIRSTYRTENURE = mean(temp_FIRSTYRTENURE)

*Indicator of ever appearing on the tenure-track pre-tenure in this sample
g EVERTT = (!missing(FIRSTYRTT))

*First tenure-track institution
g temp_FIRST_TTINST = INSTCOD_num if YR==FIRSTYRTT
replace temp_FIRST_TTINST = . if INSTCOD_miss==1 & YR==FIRSTYRTT
bysort DRF_ID: egen FIRST_TTINST = mean(temp_FIRST_TTINST)
foreach rank in FULLRANK BAFULLRANK LACFULLRANK{
g h_FIRST_TTINST_`rank' = `rank' if INSTCOD_num==FIRST_TTINST
bysort DRF_ID: egen FIRST_TTINST_`rank' = mean(h_FIRST_TTINST_`rank')
}
drop  h_* temp_FIRST_TTINST

*Indicator for someone who has tenure at their first tenure insitution
g TEN_FIRST_TTINST = (TENURE==1 & FIRST_TTINST==INSTCOD_num)
g TEN_FIRST_TTINST_miss = 1 if TENURE_miss==1 | missing(FIRST_TTINST) | missing(INSTCOD_num)

*Got tenure variables indicate if someone got tenure at similarly ranked institutions as thir previous tenure-track position
*For now, exclude LAC ranks - incorporate once we get them 
g GOT_TENURE_NEW=1 if TENURE==1 & FULLRANK<=(FIRST_TTINST_FULLRANK+5) & !missing(FULLRANK) & !missing(FIRST_TTINST_FULLRANK)
replace GOT_TENURE_NEW=1 if TENURE==1 & missing(GOT_TENURE_NEW) & BAFULLRANK<=(FIRST_TTINST_BAFULLRANK+5) & !missing(BAFULLRANK) & !missing(FIRST_TTINST_BAFULLRANK)

replace GOT_TENURE_NEW=1 if TENURE==1 & missing(GOT_TENURE_NEW) & LACFULLRANK<=(FIRST_TTINST_LACFULLRANK+5) & !missing(LACFULLRANK) & !missing(FIRST_TTINST_LACFULLRANK)
replace GOT_TENURE_NEW=1 if TENURE==1 & !missing(FIRST_TTINST_LACFULLRANK) & !missing(BAFULLRANK) & BAFULLRANK<=(FIRST_TTINST_LACFULLRANK+5)
replace GOT_TENURE_NEW=0 if GOT_TENURE_NEW!=1 & (!missing(FIRST_TTINST_FULLRANK) | !missing(FIRST_TTINST_BAFULLRANK) | !missing(FIRST_TTINST_LACFULLRANK))
g GOT_TENURE_NEW_miss=1 if (missing(FIRST_TTINST_FULLRANK) & missing(FIRST_TTINST_BAFULLRANK) | TENURE_miss==1  & missing(FIRST_TTINST_LACFULLRANK))

*Indicator of those who got tenure at lower ranked insitutions
g TEN_LOWER= (TENURE==1 & GOT_TENURE_NEW==0)
g TEN_LOWER_miss=1 if missing(GOT_TENURE_NEW) | TENURE_miss==1

*Private employer institution indicator
g private = 1 if PUBPRI=="2" /*1994 classification for pre-2017*/
replace private = 1 if PBPR15C=="2" & missing(private) /*2015 classification for 2017-2021*/
replace private = 1 if (Currpubpriv=="2" | Currpubpriv=="3") & missing(private)
replace private=0 if PUBPRI=="1"
replace private = 0 if PBPR15C=="1" & missing(private)
replace private = 0 if Currpubpriv=="1" & missing(private)
*Manually recode any discrepencies
replace private = 0 if INSTCOD=="180647"
replace private = 0 if INSTCOD=="219374"
replace private = 0 if INSTCOD=="180160"
replace private = 0 if INSTCOD=="231970"
replace private = 0 if INSTCOD=="433174"
g private_miss=1 if (PUBPRI=="L" | PUBPRI=="M" | missing(PUBPRI)) & missing(Currpubpriv) & (PBPR15C=="L" | PBPR15C=="M" | missing(PBPR15C))

********************************
*Insitution characteristic indiciators

***TENURE
*Canregie classification tenure institution indicators
g TEN_RESEARCH = (TENURE==1 & Current_Research==1)
g TEN_RESEARCH_miss=1 if TENURE_miss==1 | Current_Research_miss==1
g TEN_R1 = (TENURE==1 & Current_R1==1)
g TEN_R1_miss=1 if TENURE_miss==1 | Current_R1_miss==1
g TEN_R1R2 = (TENURE==1 & Current_R1R2==1)
g TEN_R1R2_miss=1 if TENURE_miss==1 | Current_R1R2_miss==1

*Tenure insitution rank indicators
g TEN_TOP50 = (TENURE==1 & FULLRANK<=50)
replace TEN_TOP50 = 1 if runiform()<0.2

g TEN_TOP50_miss=1 if TENURE_miss==1 | missing(FULLRANK)
g TEN_TOP20 = (TENURE==1 & FULLRANK<=20)
g TEN_TOP20_miss=1 if TENURE_miss==1 | missing(FULLRANK)
g TEN_TOP10 = (TENURE==1 & FULLRANK<=10)
g TEN_TOP10_miss=1 if TENURE_miss==1 | missing(FULLRANK)
g TEN_TOP50ANY = TENURE==1 & (FULLRANK<=50 | BAFULLRANK<=50 | LACFULLRANK<=50)
g TEN_TOP50ANY_miss=1 if TENURE_miss==1 | (missing(FULLRANK) & missing(BAFULLRANK) & missing(LACFULLRANK))

*Mutually exclusive rank categories
g RANK_TOP10 = (FULLRANK>=1 & FULLRANK<=10)
g RANK_11to25 = (FULLRANK>=11 & FULLRANK<=25)
g RANK_26to50 = (FULLRANK>=26 & FULLRANK<=50)
g RANK_51to100 = (FULLRANK>=51 & FULLRANK<=100)
g RANK_101plus = (FULLRANK>=101 & !missing(FULLRANK))
g NONRANKED = (missing(FULLRANK))

*Indicators of non-research or academic insitutions
g TT_NOTEN = (TENURETRACK==1 & TENURE==0)
g TT_NOTEN_miss=1 if TENURETRACK_miss==1 | TENURE_miss==1
g TEN_NONR1 = (TENURE==1 & TEN_R1==0)
g TEN_NONR1_miss=1 if TENURETRACK_miss==1 | TEN_R1_miss==1
g NONACAD = (TENURE==0 & TENURETRACK==0 & EDUNTT!=1)
g NONACAD_miss=1 if TENURETRACK_miss==1 | TENURE_miss==1 | EDUNTT_miss==1

***TENURETRACK
g TT_RESEARCH = (TENURETRACK==1 & Current_Research==1)
g TT_RESEARCH_miss=1 if TENURETRACK_miss==1 | Current_Research_miss==1
g TT_R1 = (TENURETRACK==1 & Current_R1==1)
g TT_R1_miss=1 if TENURETRACK_miss==1 | Current_R1_miss==1
g TT_R1R2 = (TENURETRACK==1 & Current_R1R2==1)
g TT_R1R2_miss=1 if TENURETRACK_miss==1 | Current_R1R2_miss==1

*Tenure insitution rank indicators
g TT_TOP50 = (TENURETRACK==1 & FULLRANK<=50)
g TT_TOP50_miss=1 if TENURETRACK_miss==1 | missing(FULLRANK)
g TT_TOP20 = (TENURETRACK==1 & FULLRANK<=20)
g TT_TOP20_miss=1 if TENURETRACK_miss==1 | missing(FULLRANK)
g TT_TOP10 = (TENURETRACK==1 & FULLRANK<=10)
g TT_TOP10_miss=1 if TENURETRACK_miss==1 | missing(FULLRANK)
g TT_TOP50ANY = TENURETRACK==1 & (FULLRANK<=50 | BAFULLRANK<=50 | LACFULLRANK<=50)
g TT_TOP50ANY_miss=1 if TENURETRACK_miss==1 | (missing(FULLRANK) & missing(BAFULLRANK) & missing(LACFULLRANK))

*Replace variables that use rankings with missing for 1993 and 1995 where INSTCOD codes are not IPEDS
foreach var in TEN_TOP50 TEN_TOP20 TEN_TOP10 TEN_TOP50ANY TT_TOP50 TT_TOP20 TT_TOP10 TT_TOP50ANY {
	replace `var'= . if YR==1993 | YR==1995
} /*Leaving this for now but could make this turn the missing variables for each of these variables into 1*/

*R1 carnegie indicator of first tenure-track non-tenured institution
g temp_FIRST_TTINST_R1 = 1 if YR==FIRSTYRTT & Current_R1==1
bysort DRF_ID: egen FIRST_TTINST_R1 = mean(temp_FIRST_TTINST_R1)
replace FIRST_TTINST_R1 = 0 if FIRST_TTINST_R1!=1
g FIRST_TTINST_R1_miss = 1 if Current_R1_miss==1 | missing(FIRST_TTINST)

********
*Recode State coding from SED
g HSPLACE_R="AK" if HSPLACE=="002"
replace HSPLACE_R="AL" if HSPLACE=="001"
replace HSPLACE_R="AR" if HSPLACE=="005"
replace HSPLACE_R="AZ" if HSPLACE=="004"
replace HSPLACE_R="CA" if HSPLACE=="006"
replace HSPLACE_R="CO" if HSPLACE=="008"
replace HSPLACE_R="CT" if HSPLACE=="009"
replace HSPLACE_R="DC" if HSPLACE=="011"
replace HSPLACE_R="DE" if HSPLACE=="010"
replace HSPLACE_R="FL" if HSPLACE=="012"
replace HSPLACE_R="GA" if HSPLACE=="013"
replace HSPLACE_R="GU" if HSPLACE=="066"
replace HSPLACE_R="HI" if HSPLACE=="015"
replace HSPLACE_R="IA" if HSPLACE=="019"
replace HSPLACE_R="ID" if HSPLACE=="016"
replace HSPLACE_R="IL" if HSPLACE=="017"
replace HSPLACE_R="IN" if HSPLACE=="018"
replace HSPLACE_R="KS" if HSPLACE=="020"
replace HSPLACE_R="KY" if HSPLACE=="021"
replace HSPLACE_R="LA" if HSPLACE=="022"
replace HSPLACE_R="MA" if HSPLACE=="025"
replace HSPLACE_R="MD" if HSPLACE=="024"
replace HSPLACE_R="ME" if HSPLACE=="023"
replace HSPLACE_R="MI" if HSPLACE=="026"
replace HSPLACE_R="MN" if HSPLACE=="027"
replace HSPLACE_R="MO" if HSPLACE=="029"
replace HSPLACE_R="MS" if HSPLACE=="028"
replace HSPLACE_R="MT" if HSPLACE=="030"
replace HSPLACE_R="NC" if HSPLACE=="037"
replace HSPLACE_R="ND" if HSPLACE=="038"
replace HSPLACE_R="NE" if HSPLACE=="031"
replace HSPLACE_R="NH" if HSPLACE=="033"
replace HSPLACE_R="NJ" if HSPLACE=="034"
replace HSPLACE_R="NM" if HSPLACE=="035"
replace HSPLACE_R="NV" if HSPLACE=="032"
replace HSPLACE_R="NY" if HSPLACE=="036"
replace HSPLACE_R="OH" if HSPLACE=="039"
replace HSPLACE_R="OK" if HSPLACE=="040"
replace HSPLACE_R="OR" if HSPLACE=="041"
replace HSPLACE_R="PA" if HSPLACE=="042"
replace HSPLACE_R="PR" if HSPLACE=="072"
replace HSPLACE_R="RI" if HSPLACE=="044"
replace HSPLACE_R="SC" if HSPLACE=="045"
replace HSPLACE_R="SD" if HSPLACE=="046"
replace HSPLACE_R="TN" if HSPLACE=="047"
replace HSPLACE_R="TX" if HSPLACE=="048"
replace HSPLACE_R="UT" if HSPLACE=="049"
replace HSPLACE_R="VA" if HSPLACE=="051"
replace HSPLACE_R="VI" if HSPLACE=="078"
replace HSPLACE_R="VT" if HSPLACE=="050"
replace HSPLACE_R="WA" if HSPLACE=="053"
replace HSPLACE_R="WI" if HSPLACE=="055"
replace HSPLACE_R="WV" if HSPLACE=="054"
replace HSPLACE_R="WY" if HSPLACE=="056"

********
**Further coding for regressions

*Generate alternate weight
gen one = 1

*Generate variable representing working individuals
gen ALL = 1 if non_working!=1

* ==================================================================
* Synthetic data updates below
* ==================================================================

* Drop those from "merge" which is how we do it in the actual enclave:
foreach var in FULLRANK LOGRANK TENLOGRANK TENLOGBARANK BAFULLRANK LOGBARANK  TTLOGRANK {
	drop `var'
}

* Fill these all in synthetically so none are missing 

* FULLRANK: mean ~66, sd ~60, min=1, max=327
gen FULLRANK = rnormal(66, 60)
replace FULLRANK = max(FULLRANK, 1)
replace FULLRANK = min(FULLRANK, 327)

* TENLOGRANK = log(FULLRANK)
gen TENLOGRANK = log(FULLRANK)

* LOGRANK: mean ~3.65, sd ~1.24, min=0, max=6
gen LOGRANK = rnormal(3.65, 1.24)
replace LOGRANK = max(LOGRANK, 0)
replace LOGRANK = min(LOGRANK, 6)

* TENLOGBARANK = log(LOGRANK)
gen TENLOGBARANK = log(LOGRANK)

* BAFULLRANK: mean ~-97.31, sd ~82, min=1, max=317
* (We'll generate around the mean but clip to the min/max)
gen BAFULLRANK = rnormal(-97.31, 82)
replace BAFULLRANK = max(BAFULLRANK, 1)
replace BAFULLRANK = min(BAFULLRANK, 317)

* LOGBARANK = log(BAFULLRANK)
gen LOGBARANK = log(BAFULLRANK)

* TTLOGRANK: mean ~3.87, sd ~1.13, min=0, max=6
gen TTLOGRANK = rnormal(3.87, 1.13)
replace TTLOGRANK = max(TTLOGRANK, 0)
replace TTLOGRANK = min(TTLOGRANK, 6)

*Tenure institution rank group variable
g RANKGROUP_10 = 1+floor(FULLRANK/10)*10

*Replace rank variables with MINUS rank variables to aid ease of interpretation of tables and graph
foreach var in FULLRANK LOGRANK TENLOGRANK TENLOGBARANK BAFULLRANK LOGBARANK RANKGROUP_10 TTLOGRANK {
	replace `var' = -`var'
}

*Generate labels for dep vars
label var TENURE "Tenure"
label var TEN_R1 "R1" 
label var TEN_TOP50 "Top 50"
label var TENLOGRANK "Log Rank"
label var TENLOGBARANK "Log BA Rank"
label var LOGRANK "Tenure Log Rank"
label var LOGBARANK "Tenure Log BA Rank"

*Make sure merges are dropped
drop _merge

* Generate random Weighting Factor (WTSURVY) 
local shape = (17^2) / 166
local scale = 166 / 17

* Generate gamma-distributed values
gen WTSURVY = rgamma(`shape', `scale')

*THIS IS THE MAIN WORKING DATASET
save "$DATA/sdrdrf_9321_working", replace

*Also save a version with just the SED/DRF characteristics (one observation per individual)
use  "$DATA/sdrdrf_9321_working", clear
keep REFID PHDCY PHDINST PHDFIELD PHDFIELDNEW PHD_GROUP PHD_CAT PHDRANK SEX race_n edpar_n
duplicates drop
gen sex = 1 if SEX=="2"
replace sex = 0 if SEX=="1"
save "$DATA/sdrdrf_9321_sedonly", replace

********************************************************************************
*Import SED
********************************************************************************

*Import file (very large file - takes a long time!)
use "$RAWROOT/noid2021.dta", clear

*Save as a .dta file
save "$DATA/seddrf_2021", replace

******************a**************************
*Generate a version of the SED data with PHDRANK
********************************************

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

*Prepare insitution codes for merging (some codes are older and have changed over time)
replace PHDINST="110468" if PHDINST=="124885" 
replace PHDINST="216348" if PHDINST=="176284"
replace PHDINST="206084" if PHDINST=="203951"
replace PHDINST="209490" if PHDINST=="209472"
replace PHDINST="212054" if PHDINST=="212841"
replace PHDINST="139755" if PHDINST=="238883"
replace PHDINST="134130" if PHDINST=="435338"
replace PHDINST="173957" if PHDINST=="365426"
replace PHDINST="228723" if PHDINST=="223214"
replace PHDINST="233277" if PHDINST=="231837"
replace PHDINST="104151" if PHDINST=="103778"
replace PHDINST="489779" if PHDINST=="260901"
replace PHDINST="489779" if PHDINST=="260910"
replace PHDINST="215293" if PHDINST=="418418"
replace PHDINST = strtrim(PHDINST)
*Note: no imputations of INSTCOD like in cleaning file 8 because we only have one year to look at in the SED


* ---------- Standardize key types before merging ----------

* 1) Make sure master PHDINST is string, zero-padded to 6
capture confirm string variable PHDINST
if _rc {
    tostring PHDINST, replace format(%06.0f) force
}
* If already string but not zero-padded, coerce via real() where possible
gen str6 __PHDINST = PHDINST
replace __PHDINST = string(real(PHDINST), "%06.0f") if !missing(real(PHDINST))
drop PHDINST
rename __PHDINST PHDINST
replace PHDINST = strtrim(PHDINST)

* 2) Convert all rank files' PHDINST to string str6 (in a scratch frame/preserve)
preserve
tempfile __sed
save `__sed', replace

local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22

foreach f of local fields {
    use "$RANK/`f'IPEDSPHD.dta", clear
    capture confirm numeric variable PHDINST
    if !_rc {
        tostring PHDINST, replace format(%06.0f) force
    }
    else {
        * if already string, ensure zero-padding
        replace PHDINST = string(real(PHDINST), "%06.0f") if !missing(real(PHDINST))
        replace PHDINST = strtrim(PHDINST)
    }
    compress
    save "$RANK/`f'IPEDSPHD.dta", replace
}

use `__sed', clear


local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22

*Merge PhD field-specific rankings from USNWR to (1) Phd program and (2) current employer
local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22
foreach f of local fields {
	merge m:1 PHDINST using "$RANK/`f'IPEDSPHD.dta", generate(fmerge)
	drop if fmerge==2
	drop fmerge
}


* ------------------------------------------------------------------
* Ensure PHD_CATFINE exists with the exact 1..20 coding expected
* (We set the numeric codes directly and attach a value label.)
* ------------------------------------------------------------------
capture confirm variable PHD_CATFINE
if _rc {
    gen byte PHD_CATFINE = .

    * 1 Audiology
    replace PHD_CATFINE = 1 if PHDFIELD==200

    * 2 Bio Science
    replace PHD_CATFINE = 2 if (inrange(PHDFIELD,100,199) | PHDFIELD==626)

    * 3 Business  (no business PhDs before 2003 originally; here we just allow)
    replace PHD_CATFINE = 3 if inrange(PHDFIELD,900,939)

    * 4 Chemistry
    replace PHD_CATFINE = 4 if (inrange(PHDFIELD,520,539) | inlist(PHDFIELD,542,510,549))

    * 5 Comp/Inf Sciences
    replace PHD_CATFINE = 5 if inrange(PHDFIELD,400,419)

    * 6 Criminology
    replace PHD_CATFINE = 6 if inlist(PHDFIELD,657,658)

    * 7 Earth Sciences
    replace PHD_CATFINE = 7 if inrange(PHDFIELD,540,559) | PHDFIELD==599 | inrange(PHDFIELD,585,595) | inrange(PHDFIELD,510,519)

    * 8 Economics
    replace PHD_CATFINE = 8 if inlist(PHDFIELD,667,665,668,685,0,3)

    * 9 Engineering
    replace PHD_CATFINE = 9 if inrange(PHDFIELD,300,399) | inlist(PHDFIELD,415,547)

    * 10 History
    replace PHD_CATFINE = 10 if inrange(PHDFIELD,700,719) | inlist(PHDFIELD,770,775,776,777)

    * 11 Mathematics
    replace PHD_CATFINE = 11 if inrange(PHDFIELD,420,499)

    * 12 Medicine
    replace PHD_CATFINE = 12 if inrange(PHDFIELD,222,227) | inrange(PHDFIELD,235,299) | inlist(PHDFIELD,205,207,577)

    * 13 Nursing
    replace PHD_CATFINE = 13 if PHDFIELD==230

    * 14 Physics
    replace PHD_CATFINE = 14 if inrange(PHDFIELD,561,579) | inlist(PHDFIELD,544,545,505,506,512)

    * 15 Political Science
    replace PHD_CATFINE = 15 if inlist(PHDFIELD,678,679,674)

    * 16 Psychology
    replace PHD_CATFINE = 16 if (inrange(PHDFIELD,600,649) & PHDFIELD!=626) | inlist(PHDFIELD,822,825)

    * 17 Public Health
    replace PHD_CATFINE = 17 if inrange(PHDFIELD,210,220)

    * 18 Public Policy
    replace PHD_CATFINE = 18 if PHDFIELD==682

    * 19 Sociology
    replace PHD_CATFINE = 19 if PHDFIELD==686

    * 20 Statistics
    replace PHD_CATFINE = 20 if PHDFIELD==690

    label define PHDCATF 1 "Audiology" 2 "Bio Science" 3 "Business" 4 "Chemistry" 5 "Comp/Inf Sciences" ///
                         6 "Criminology" 7 "Earth Sciences" 8 "Economics" 9 "Engineering" 10 "History" ///
                         11 "Mathematics" 12 "Medicine" 13 "Nursing" 14 "Physics" 15 "Political Science" ///
                         16 "Psychology" 17 "Public Health" 18 "Public Policy" 19 "Sociology" 20 "Statistics"
    label values PHD_CATFINE PHDCATF
    label var PHD_CATFINE "PhD fine field category (coded 1..20)"
}

* (Optional safety) ensure phd_cat (broad) exists if your imputation uses it
capture confirm variable phd_cat
if _rc {
    * If missing, build a broad category from PHDFIELD similar to earlier block and encode -> phd_cat
    gen str20 _broad = ""
    replace _broad = "Agr Sciences"  if inrange(PHDFIELD,1,99)
    replace _broad = "Bio Sciences"  if inrange(PHDFIELD,100,199) | PHDFIELD==626
    replace _broad = "Health"        if inrange(PHDFIELD,200,299) | PHDFIELD==577
    replace _broad = "Engineering"   if inrange(PHDFIELD,300,399) | inlist(PHDFIELD,68,547,415)
    replace _broad = "Comp/Inf Sciences" if (inrange(PHDFIELD,400,419) & PHDFIELD!=415)
    replace _broad = "Math/Stats"    if inrange(PHDFIELD,420,499) | inlist(PHDFIELD,930,910,935,938)
    replace _broad = "Phys/Geo/Atmos/Ocean Sciences" if (inrange(PHDFIELD,500,599) & PHDFIELD!=577 & PHDFIELD!=547)
    replace _broad = "Psychology"    if (inrange(PHDFIELD,600,649) & PHDFIELD!=626) | inlist(PHDFIELD,822,825,889)
    replace _broad = "Social Sciences ex Econ" if (inrange(PHDFIELD,650,699) & PHDFIELD!=685) | inlist(PHDFIELD,710,773,770,700,964,976)
    replace _broad = "Economics"     if inlist(PHDFIELD,667,0,3,665,668,685)
    encode _broad, gen(phd_cat)
    drop _broad
}

* ------------------------------------------------------------------
* Now compute PHDRANK as in og script (these vars exist after merges)
* ------------------------------------------------------------------
gen PHDRANK = .
replace PHDRANK=Audio20RankPHD    if PHD_CATFINE==1
replace PHDRANK=Bio22RankPHD      if PHD_CATFINE==2
replace PHDRANK=Bus23RankPHD      if PHD_CATFINE==3
replace PHDRANK=Chem22RankPHD     if PHD_CATFINE==4
replace PHDRANK=CompSci22RankPHD  if PHD_CATFINE==5
replace PHDRANK=Crim21RankPHD     if PHD_CATFINE==6
replace PHDRANK=Earth22RankPHD    if PHD_CATFINE==7
replace PHDRANK=Econ23RankPHD     if PHD_CATFINE==8
replace PHDRANK=Eng23RankPHD      if PHD_CATFINE==9
replace PHDRANK=History21RankPHD  if PHD_CATFINE==10
replace PHDRANK=Math22RankPHD     if PHD_CATFINE==11
replace PHDRANK=Med23RankPHD      if PHD_CATFINE==12
replace PHDRANK=Nurse23RankPHD    if PHD_CATFINE==13
replace PHDRANK=Physics22RankPHD  if PHD_CATFINE==14
replace PHDRANK=PoliSci21RankPHD  if PHD_CATFINE==15
replace PHDRANK=Psych23RankPHD    if PHD_CATFINE==16
replace PHDRANK=PH22RankPHD       if PHD_CATFINE==17
replace PHDRANK=PP22RankPHD       if PHD_CATFINE==18
replace PHDRANK=Socio21RankPHD    if PHD_CATFINE==19
replace PHDRANK=Stat22RankPHD     if PHD_CATFINE==20

************
*Impute missing ranks

*Encode Rankings
encode PHDINST, gen(PHDINST_num)

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

*Save this version of SED
save "$DATA/seddrf_2021_phdrank", replace
********************************************************************************

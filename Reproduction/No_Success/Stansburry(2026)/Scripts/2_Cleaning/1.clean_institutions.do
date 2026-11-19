********************************************************************************
*Import and clean data for institutions and ranks
********************************************************************************

**************************************************************************
*INSTITUTIONS
**************************************************************************

*Import institution file
import excel "$RAWROOT/inst21.xlsx", firstrow clear

*Clean insitutions, including out of date IPEDS codes
gen str6 INSTCOD = string(instid, "%06.0f") /*Rename insitution ID to match SDR code*/

replace INSTCOD="110468" if INSTCOD=="124885" 
replace INSTCOD="216348" if INSTCOD=="176284"
replace INSTCOD="206084" if INSTCOD=="203951"
replace INSTCOD="209490" if INSTCOD=="209472"
replace INSTCOD="212054" if INSTCOD=="212841"
replace INSTCOD="139755" if INSTCOD=="238883"
replace INSTCOD="134130" if INSTCOD=="435338"
replace INSTCOD="173957" if INSTCOD=="365426"
replace INSTCOD="228723" if INSTCOD=="223214"
replace INSTCOD="233277" if INSTCOD=="231837"
replace INSTCOD="104151" if INSTCOD=="103778"
replace INSTCOD="489779" if INSTCOD=="260901"
replace INSTCOD="489779" if INSTCOD=="260910"
replace INSTCOD="215293" if INSTCOD=="418418"
replace INSTCOD="" if INSTCOD=="137148" /*Removed due to these codes relating to defunct schools (Argosy mostly)*/
replace INSTCOD="" if INSTCOD=="145770"
replace INSTCOD="" if INSTCOD=="367936"
replace INSTCOD="" if INSTCOD=="436438"
replace INSTCOD="" if INSTCOD=="448734"
replace INSTCOD="" if INSTCOD=="450526"
replace INSTCOD="" if INSTCOD=="450979"
replace INSTCOD="" if INSTCOD=="456348"
duplicates tag INSTCOD, gen(dup)
drop if dup!=0
drop dup
rename * Curr*
rename CurrINSTCOD INSTCOD
save "$DATA/Currinstcodes", replace


**************************************************************************
*INSTITUTIONS RANKINGS
**************************************************************************

*Clean and save rankings files (imported: Most recent field-specific rankings for graduate programs, from US news and world report)
local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22
foreach f of local fields {
	use "$RANK/`f'IPEDS.dta", clear
	rename INSTCOD PHDINST /*Rename and save variables to merge into PhD rankings, along with institution employer rankings*/
	rename `f'Inst `f'InstPHD
	rename `f'Rank `f'RankPHD
	save "$RANK/`f'IPEDSPHD.dta", replace
}

* Ensure INSTCOD and PHDINST are strings in all RANK lookup files
local fields Audio20 Bio22 Bus23 Chem22 CompSci22 Crim21 Earth22 Econ23 Eng23 English21 History21 Math22 Med23 Nurse23 PH22 Physics22 PoliSci21 PP22 Psych23 Socio21 Stat22

foreach f of local fields {
    * Employer-side rankings
    use "$RANK/`f'IPEDS.dta", clear
    capture confirm numeric variable INSTCOD
    if !_rc {
        tostring INSTCOD, gen(_INSTCOD) format(%06.0f) force
        drop INSTCOD
        rename _INSTCOD INSTCOD
        compress
        save "$RANK/`f'IPEDS.dta", replace
    }
    
    * PhD-program-side rankings
    use "$RANK/`f'IPEDSPHD.dta", clear
    capture confirm numeric variable PHDINST
    if !_rc {
        tostring PHDINST, gen(_PHDINST) format(%06.0f) force
        drop PHDINST
        rename _PHDINST PHDINST
        compress
        save "$RANK/`f'IPEDSPHD.dta", replace
    }
}


*Figure: Parental Education Shares of Tenured Professors and PhD students


********************************************************************************
*SED 2021 Summary Stats: PhD recipients
********************************************************************************

*First, generate list of PhD fields that are in the SDR so we can create a matching sample in the SED
	use "$DATA/sdrdrf_9321_working", clear
	keep PHDFIELD
	duplicates drop
	save "temp_phdfield_list.dta", replace

*Load data
use "$DATA/seddrf_2021", clear

*Generate variable: Highest level of parental education
g edpar= "4: PhD" if (EDMOTHER=="8" | EDFATHER=="8") 
replace edpar= "3: Grad" if missing(edpar) & (EDMOTHER=="7" | EDFATHER=="7" | EDMOTHER=="6" | EDFATHER=="6") 
replace edpar= "2: BA" if missing(edpar) & (EDMOTHER=="5" | EDFATHER=="5") 
replace edpar= "1: No BA" if missing(edpar) & (EDMOTHER=="1" | EDFATHER=="1" | EDMOTHER=="2" | EDFATHER=="2" | EDMOTHER=="3" | EDFATHER=="3" | EDMOTHER=="4" | EDFATHER=="4") 
encode edpar, gen(edpar_n)

drop if missing(edpar_n)

*Drop where there is negligible data
keep if PHDCY>=1970

*Limit sample to those with an SEH PhD
merge m:1 PHDFIELD using "temp_phdfield_list.dta", gen(_merge_phdfield)
keep if _merge_phdfield==3

destring BIRTHPL, replace

preserve
*Generate unweighted parental education shares
bys PHDCY: egen phd_total_uw = count(DRF_ID)
bys PHDCY edpar_n: egen phd_count_uw = count(DRF_ID)
gen phd_share_uw = phd_count_uw / phd_total_uw

*Generate labels
label var PHDCY "PhD Year"
label var edpar_n "Parental education"
label var phd_share_uw "Share of PhDs by parental education [Unweighted]"
label var phd_count_uw "Count of PhDs by parental education [Unweighted]" 

*Keep relevant variables and drop duplicates
keep PHDCY edpar_n phd_share_uw phd_count_uw
duplicates drop

* Count observations by each edpar_n per year
foreach year in 1970 1980 2000 2010 2019 {
	di "`year'"
	forvalues i = 1/4 {
	qui su phd_count_uw if edpar_n == `i' & !missing(phd_share_uw) & PHDCY == `year'
	di "PhD Recipients : edpar_n == `i': total ppl plotted in YR `year' =" r(sum)
	}
}

*Save dataset	
save "$DESC/sed_sumstats", replace

**Generate line graphs of shares of different types of professors over time
xtset edpar_n PHDCY

xtline phd_share_uw, overlay ///
title("PhD recipients") ///
ytitle("Share") ///
ysc(r(0 0.62)) ylabel(0(0.2)0.6) ///
legend(pos(6) cols(2))
graph save "$figures/PHD.gph", replace
restore

*Create same summary stats, but only for US-born
preserve
keep if BIRTHPL>=1 & BIRTHPL<100
*Generate unweighted parental education shares
bys PHDCY: egen phd_total_uw = count(DRF_ID)
bys PHDCY edpar_n: egen phd_count_uw = count(DRF_ID)
gen phd_share_uw = phd_count_uw / phd_total_uw

*Generate labels
label var PHDCY "PhD Year"
label var edpar_n "Parental education"
label var phd_share_uw "Share of US-born PhDs by parental education [Unweighted]"
label var phd_count_uw "Count of US-born PhDs by parental education [Unweighted]" 

*Keep relevant variables and drop duplicates
keep PHDCY edpar_n phd_share_uw phd_count_uw
duplicates drop

* Count observations by each edpar_n per year
foreach year in 1993 1995 19975 1999 2001 2003 2006 2008 2010 2013 2015 2017 2019 2021 {
	di "`year'"
	forvalues i = 1/4 {
	qui su phd_count_uw if edpar_n == `i' & !missing(phd_share_uw) & PHDCY == `year'
	di "PhD Recipients : edpar_n == `i': total ppl plotted in YR `year' =" r(sum)
	}
}

*Save dataset	
save "$DESC/sed_sumstats_usborn", replace

 *******************************************************************************
*Matched SDR-DRF Summary Stats Figures
****************************

*******************************************************************************
*This code creates: (in Descriptives folder)
*TENURE.gph, ///
 TEN_R1.gph, ///
 PHD_updated.gph 
*******************************************************************************

*Load data
use "$DATA/sdrdrf_9321_working", clear

capture drop __000001
capture drop __000000

keep if LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
keep if !missing(edpar_n)
gen n = 1

*PhD recipients 
bys YR: egen denom = total(WTSURVY)
bys YR edpar_n: egen num = total(WTSURVY)
gen share = num/denom
keep edpar_n YR share
duplicates drop
twoway  ///
	(line share YR if edpar_n==1) ///
	(line share YR if edpar_n==2) ///
	(line share YR if edpar_n==3) ///
	(line share YR if edpar_n==4) ///
	, title("All PhD recipients") ///
	ytitle("") xtitle("") ///
	ysc(r(0 0.62)) ylabel(0(0.2)0.6) ///
	legend(pos(6) cols(4) order(1 "No college" 2 "College" 3 "Grad (non-PhD)" 4 "PhD") )
graph save "$figures/PHD_ALL.gph", replace
graph export "$figures/PHD_ALL.pdf", replace


*Load data
use "$DATA/sdrdrf_9321_working", clear

capture drop __000001
capture drop __000000

keep if LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
keep if !missing(edpar_n)
gen n = 1

*Tenured
keep if TENURE==1
bys YR: egen denom = total(WTSURVY)
bys YR edpar_n: egen num = total(WTSURVY)
gen share = num/denom
keep edpar_n YR share
duplicates drop
twoway  ///
	(line share YR if edpar_n==1) ///
	(line share YR if edpar_n==2) ///
	(line share YR if edpar_n==3) ///
	(line share YR if edpar_n==4) ///
	, title("Tenured Professors") ///
	ytitle("") xtitle("") ///
	ysc(r(0 0.62)) ylabel(0(0.2)0.6) ///
	legend(pos(6) cols(4) order(1 "No college" 2 "College" 3 "Grad (non-PhD)" 4 "PhD") )
graph save "$figures/TENURE.gph", replace
graph export "$figures/TENURE.pdf", replace

*Load data
use "$DATA/sdrdrf_9321_working", clear

capture drop __000001
capture drop __000000

keep if LOCATIONUS==1 & years_since_phd>=10 & years_since_phd<40
keep if !missing(edpar_n)
gen n = 1
 
*Tenured
keep if TEN_R1==1
bys YR: egen denom = total(WTSURVY)
bys YR edpar_n: egen num = total(WTSURVY)
gen share = num/denom
keep edpar_n YR share
duplicates drop
twoway  ///
	(line share YR if edpar_n==1) ///
	(line share YR if edpar_n==2) ///
	(line share YR if edpar_n==3) ///
	(line share YR if edpar_n==4) ///
	, title("Tenured at R1") ///
	ytitle("") xtitle("") ///
	ysc(r(0 0.62)) ylabel(0(0.2)0.6) ///
	legend(pos(6) cols(4) order(1 "No college" 2 "College" 3 "Grad (non-PhD)" 4 "PhD") )
graph save "$figures/TEN_R1.gph", replace
graph export "$figures/TEN_R1.pdf", replace


* Synthetic update
use "$DATA/sdrdrf_9321_working", clear

capture drop __000001
capture drop __000000

save "$DATA/sdrdrf_9321_working", replace

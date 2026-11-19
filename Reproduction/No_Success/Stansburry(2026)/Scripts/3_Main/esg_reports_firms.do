* ---------------------------------------------------------------
* Output Graph of ESG / DEI Reporting Across Large US Firms
* ---------------------------------------------------------------

* Load data:
use "$esg/final_firm_dataset.dta", clear

* Check by industry:
gen industry = ""
replace industry = "public" if source == "SP 500"
replace industry = "private" if source == "Forbes Top 100 Private Companies"
replace industry = "tech" if source == "YC Top 50 by Revenue"
replace industry = "law" if source == "Time's Top Law Firms (1B revenue +)"
drop source

* Keep only firms that do report on DEI
drop if any_dei_mention == 0

* Create bar chart of reporting:
collapse (mean) race_mention gender_mention lgbtq_mention ability_mention vet_mention class_mention
foreach var in race_mention gender_mention lgbtq_mention ability_mention vet_mention class_mention {
    replace `var' = `var' * 100
}

* Reshape to long
stack race_mention gender_mention lgbtq_mention ability_mention vet_mention class_mention, into(Percent) clear
rename _stack Diversity_Type

* Label the reporting categories
label define diversitylbl 1 "Race" 2 "Gender" 3 "LGBTQ+" 4 "Ability" 5 "Veteran" 6 "Class"
label values Diversity_Type diversitylbl

* Output graph:
graph bar Percent, over(Diversity_Type, label(angle(30))) ///
    bar(1, color("30 144 255")) ///
    ytitle("Percentage of Firms") ///
    blabel(bar, format(%4.1f) color(black)) ///
    legend(off)

graph export "$figures/diversity_reporting.pdf", replace

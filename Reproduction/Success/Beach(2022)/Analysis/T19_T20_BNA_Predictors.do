use "$data_dir/England_and_Wales/1895_Directory_with_BNA.dta" if year<1878, clear

* dependent variable
replace bb_counter=0 if bb_counter==.

gen bb_monday_ratio=bb_counter/monday_1877
gen monday_flag=(monday_1877!=.)


* clean frequency variable
replace frequency="multi" if inlist(frequency,"thrice","tw")
replace frequency="other" if inlist(frequency,"m","ww")

gen daily=(frequency=="d")
gen multi=(frequency=="multi")

gen conservative=(inlist(politics,"Conservative","Conservative-Independent","Conservative-Unionist","Independent-Conservative"))

gen liberal=(inlist(politics,"Liberal","Advanced-Liberal","Independent-Liberal","Liberal-Independent","Liberal-Unionist","Progressive","Radical"))

gen independent=(politics=="Independent")

** labels
label variable conservative "Conservative"
label variable liberal "Liberal"
label variable independent "Independent"
label variable daily "Every day"
label variable multi "Several days"


***** Part 1: probability of making it into the BNA

eststo T19_1: reg monday_flag daily multi, robust

eststo T19_2: reg monday_flag conservative liberal independent, robust

eststo T19_3: reg monday_flag daily multi conservative liberal independent, robust

* just conservatives and liberal
eststo T19_4: reg monday_flag conservative if (conservative==1 | liberal==1), robust

*** articles conditional on appearing 
eststo T19_5: reg monday_1877 daily multi conservative liberal independent if monday_flag==1, robust

* just conservatives and liberal
eststo T19_6: reg monday_1877  conservative if (conservative==1 | liberal==1), robust

esttab T19_* using "$results/T19_BNA_entry", tex replace label b(3) se(3) stats(N r2, label("Observations" "R-Squared") fmt(0 3)) nocons


* relative to monday articles
eststo T20_1: reg bb_monday_ratio  conservative liberal independent, robust

eststo T20_2: reg bb_monday_ratio  conservative liberal independent daily multi, robust

eststo T20_3: reg bb_monday_ratio conservative if conservative==1 | liberal==1, robust

eststo T20_4: reg bb_monday_ratio conservative daily multi if conservative==1 | liberal==1, robust

esttab T20_* using "$results/T20_BB_Article_Ratio", tex replace label b(3) se(3) stats(N r2, label("Observations" "R-Squared") fmt(0 3)) nocons

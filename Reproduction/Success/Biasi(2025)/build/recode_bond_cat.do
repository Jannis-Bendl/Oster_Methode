/*

recode_bond_cat.do 

*/


clear all
capture log close
set more off 

********************************************************************************

if c(username) == "bb779" { 
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "julienl" {
	global root "/Users/julienl/Dropbox/Projects/School construction"
}
else if inlist(c(username), "davidschonholzer", "dasc4929") {
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "jabef" {
	global root "C:\Users\jabef\Desktop\FU Job\Prof.Marcus\Python_Scraper\Oster_Methode\Reproduction\Biasi(2025)"
}

global prepdata 	"${root}/datasets"



********************************************************************************
***** 			1.0 LOAD DATA: ALL DISTRICTS, RUN PROGRAMS 	 		***************
********************************************************************************

insheet using "$prepdata/bonds.csv", clear names

egen categorized = rowmax(transp* technology_* other_* safetysecurity_* capitalimprovements_* constructionrenovation_*)

*-----> Manually recode all categories

* Transportation/vehicles
gen busvehicle = 0 if (ballottext != "" | bond_use != "")
foreach string in "bus" "BUS" "Bus" "Vehicle" "vehicle" "VEHICLE" "transpo" "Transpo" "TRANSPO" {
	replace busvehicle = 1 if regexm(ballottext,"`string'")
	replace busvehicle = 1 if regexm(bond_use,"`string'")
}

* Technology: computing devices
gen computer = 0 if (ballottext != "" | bond_use != "")
foreach string in "Comput" "comput" "COMPUT" {
	replace computer = 1 if regexm(ballottext,"`string'")
	replace computer = 1 if regexm(bond_use,"`string'")
}

* Technology: generic
capt drop technology
gen technology = 0 if (ballottext != "" | bond_use != "")
foreach string in "Technology" "techn" "TECHN" "audiov" "Audiov"  {
	replace technology = 1 if regexm(ballottext,"`string'")
	replace technology = 1 if regexm(ballottext,"`string'")
	replace technology = 1 if regexm(bond_use,"`string'")
}


* Safety: Asbestos
gen asbestos = 0 if (ballottext != "" | bond_use != "")
foreach string in "Asbes" "asbes" "ASBES" {
	replace asbestos = 1 if regexm(ballottext,"`string'")
	replace asbestos = 1 if regexm(bond_use,"`string'")
}


* Safety: generic
gen safety = 0 if (ballottext != "" | bond_use != "")
foreach string in "Safe" "safe" "SAFE" "Security" "security" "surveil" "Surveil"  "Alarm" "alarm"  "fire" "FIRE" {
	replace safety = 1 if regexm(ballottext,"`string'")
	replace safety = 1 if regexm(bond_use,"`string'")
}

* K impro: plumbing
gen plumbing = 0 if (ballottext != "" | bond_use != "")
foreach string in "plumbing" "Plumbing" "sewa" "Sewa" "sewi" "Sewi" "flush"  "Flush" "Restroom" "restroom" {
	replace plumbing = 1 if regexm(ballottext,"`string'")
	replace plumbing = 1 if regexm(bond_use,"`string'")
}

* K impro: HVAC
gen hvac = 0 if (ballottext != "" | bond_use != "")
foreach string in "HVAC" "hvac" "Hvac" "Cool" "cool" "COOL" "Heat" "HEAT" "heat" "air co" "Air co" "air-co" "Air-co" "vent" "Vent" {
	replace hvac = 1 if regexm(ballottext,"`string'")
	replace hvac = 1 if regexm(bond_use,"`string'")
}

* K impro: solar energy


* K impro: furnishing,  windows, doors
gen furn = 0 if (ballottext != "" | bond_use != "")
foreach string in "furni" "Furni" "FURNI" "window" "Window" "Door" "door" {
	replace furn = 1 if regexm(ballottext,"`string'")
	replace furn = 1 if regexm(bond_use,"`string'")
}


* K impro: lightling

* K impro: roof replacement
gen roof = 0 if (ballottext != "" | bond_use != "")
foreach string in "roof" "ROOF" "Roof" {
	replace roof = 1 if regexm(ballottext,"`string'")
	replace roof = 1 if regexm(bond_use,"`string'")
}


* Construction: Athletic facility
gen athletic = 0 if (ballottext != "" | bond_use != "")
foreach string in "thlet" "THLET" "gym" "Gym" "GYM" "tadiu" "TADIU" "Sport" "sport" "SPORT" "field" "Field" {
	replace athletic = 1 if regexm(ballottext,"`string'")
	replace athletic = 1 if regexm(bond_use,"`string'")
}

* Construction: Auditoriums
gen auditorium = 0 if (ballottext != "" | bond_use != "")
foreach string in "ditoriu" "DITORIU" "theater" "Theater" "THEATER" "perfor" "Perfor" "fine art" "Fine art" "Fine art" {
	replace auditorium = 1 if regexm(ballottext,"`string'")
	replace auditorium = 1 if regexm(bond_use,"`string'")
}


* Construction: lab/STEM
gen lab = 0 if (ballottext != "" | bond_use != "")
foreach string in "Lab" "lab" "career tech" "Career tech" "Career Tech" "Career tech" "Career Tech" "vocat"  "Vocat" "STEM" {
	replace lab = 1 if regexm(ballottext,"`string'")
	replace lab = 1 if regexm(bond_use,"`string'")
}


/*
* Construction: new buildings
gen construction = 0 if (ballottext != "" | bond_use != "")
gen class = 0 if (ballottext != "" | bond_use != "")
foreach string in "building" "Building" "classroom" "Classroom"   "school" "School"  {
	replace class = 1 if regexm(ballottext,"`string'") 
	replace class = 1 if regexm(bond_use,"`string'") 
}

foreach string in "construct" "Construct" "overcrow" "Overcrow" "const."  {
	replace construction = 1 if regexm(ballottext,"`string'") & class == 1 & athletic == 0 & auditorium == 0 
	replace construction = 1 if regexm(bond_use,"`string'")  & class == 1 & athletic == 0 & auditorium == 0 
}


* Construction: renovations/repairs
gen repairs = 0 if (ballottext != "" | bond_use != "")
foreach string in "renov" "Renov" "repa" "Repla" "repla" "Repa" "modern" "Modern"  "improv" "Improv" "upgrad" "Upgrad" "refurb" "Refurb"  {
	replace repairs = 1 if regexm(ballottext,"`string'") & class == 1 & athletic == 0 & auditorium == 0 
	replace repairs = 1 if regexm(bond_use,"`string'")  & class == 1 & athletic == 0 & auditorium == 0 
}

*/

* Work on schools and classrooms

* Construction: new buildings
gen class = 0 if (ballottext != "" | bond_use != "")
foreach string in "building" "Building" "classroom" "Classroom"  "school fa" "School fa"  {
	replace class = 1 if regexm(ballottext,"`string'") 
	replace class = 1 if regexm(bond_use,"`string'") 
}

gen construction = 0 if (ballottext != "" | bond_use != "")
foreach string in "construct" "Construct" "overcrow" "Overcrow" "const."  "renov" "Renov" "repa" "Repla" "repla" "Repa" "modern" "Modern"  "improv" "Improv" "upgrad" "Upgrad" "refurb" "Refurb"  {
	replace construction = 1 if regexm(ballottext,"`string'") & class == 1 
	replace construction = 1 if regexm(bond_use,"`string'")  & class == 1 
}

* Construction as in building
gen constrbuild = 0 if (ballottext != "" | bond_use != "")
foreach string in "construct" "Construct" "Build" "build"  {
	replace constrbuild = 1 if regexm(ballottext,"`string'") & class == 1 
	replace constrbuild = 1 if regexm(bond_use,"`string'")  & class == 1 
}

*replace class = 0 if construction == 0

* Construction: land purchase
gen landpurch = 0 if (ballottext != "" | bond_use != "")
foreach string in "land" "Land" "site" "Site"  {
foreach string2 in "acqui" "Acqui" "purch" "Purch" {
	replace landpurch = 1 if (regexm(ballottext,"`string'") & regexm(ballottext,"`string2'"))
	replace landpurch = 1 if (regexm(bond_use,"`string'") & regexm(bond_use,"`string2'"))
}
}



*check: how many bonds have I classified?
egen sum = rowmax(busvehicle computer asbestos athletic hvac auditorium roof furn safety construction technology class landpurch lab constrbuild)
tab sum
drop sum

* impute amounts
replace amount = amount_imputed if amount == .

* keep only relevant variables

keep leaid year busvehicle computer asbestos athletic hvac auditorium plumb roof furn safety construction technology landpurch amount lab class categorized constrbuild
collapse amount (max) busvehicle computer asbestos athletic hvac plumb auditorium roof furn safety construction technology landpurch class lab categorized constrbuild, by(leaid year)

* generate coarse categories
gen stem = computer
replace stem = 1 if lab == 1 | tech == 1

gen athl_audi = athletic
replace athl_audi = 1 if auditorium == 1

gen safeall = safety
replace safeall = 1 if asb == 1

gen infra = roof
replace infra = 1 if plumbing == 1 | furn == 1


sort leaid year

save "$prepdata/bond_cat_amt_clean.dta", replace




*Shares of Different non-PhD Graduate Degrees using IPUMS Higher Education NSCG 1993-2013 data

clear

*Set up IPUMS data
set more off

clear
quietly infix              ///
  str     personid  1-18   ///
  int     year      19-22  ///
  double  weight    23-33  ///
  long    sample    34-38  ///
  byte    surid     39-39  ///
  byte    age       40-41  ///
  byte    dgrdg     42-42  ///
  long    ndgmed    43-48  ///
  using `"$NSCG/highered_00006.dat"'


format weight   %11.0g

label var personid `"Individual identification number"'
label var year     `"Survey year"'
label var weight   `"SESTAT weight"'
label var sample   `"Sample identifier"'
label var surid    `"Survey identifier"'
label var age      `"Age"'
label var dgrdg    `"Type of highest certificate or degree"'
label var ndgmed   `"Field of major for highest degree "'

label define sample_lbl 00101 `"SESTAT NSCG 1993"'
label define sample_lbl 00102 `"SESTAT SDR 1993"', add
label define sample_lbl 00103 `"SESTAT NSRCG 1993"', add
label define sample_lbl 00111 `"NSCG 1993"', add
label define sample_lbl 00201 `"SESTAT NSCG 1995"', add
label define sample_lbl 00202 `"SESTAT SDR 1995"', add
label define sample_lbl 00203 `"SESTAT NSRCG 1995"', add
label define sample_lbl 00301 `"SESTAT NSCG 1997"', add
label define sample_lbl 00302 `"SESTAT SDR 1997"', add
label define sample_lbl 00303 `"SESTAT NSRCG 1997"', add
label define sample_lbl 00401 `"SESTAT NSCG 1999"', add
label define sample_lbl 00402 `"SESTAT SDR 1999"', add
label define sample_lbl 00403 `"SESTAT NSRCG 1999"', add
label define sample_lbl 00512 `"SDR 2001"', add
label define sample_lbl 00513 `"NSRCG 2001"', add
label define sample_lbl 00601 `"SESTAT NSCG 2003"', add
label define sample_lbl 00602 `"SESTAT SDR 2003"', add
label define sample_lbl 00603 `"SESTAT NSRCG 2003"', add
label define sample_lbl 00611 `"NSCG 2003"', add
label define sample_lbl 00612 `"SDR 2003"', add
label define sample_lbl 00613 `"NSRCG 2003"', add
label define sample_lbl 00701 `"SESTAT NSCG 2006"', add
label define sample_lbl 00702 `"SESTAT SDR 2006"', add
label define sample_lbl 00703 `"SESTAT NSRCG 2006"', add
label define sample_lbl 00712 `"SDR 2006"', add
label define sample_lbl 00713 `"NSRCG 2006"', add
label define sample_lbl 00801 `"SESTAT NSCG 2008"', add
label define sample_lbl 00802 `"SESTAT SDR 2008"', add
label define sample_lbl 00803 `"SESTAT NSRCG 2008"', add
label define sample_lbl 00812 `"SDR 2008"', add
label define sample_lbl 00813 `"NSRCG 2008"', add
label define sample_lbl 00901 `"SESTAT NSCG 2010"', add
label define sample_lbl 00902 `"SESTAT SDR 2010"', add
label define sample_lbl 00903 `"SESTAT NSRCG 2010"', add
label define sample_lbl 00911 `"NSCG 2010"', add
label define sample_lbl 00912 `"SDR 2010"', add
label define sample_lbl 00913 `"NSRCG 2010"', add
label define sample_lbl 00914 `"ISDR 2010"', add
label define sample_lbl 01001 `"SESTAT NSCG 2013"', add
label define sample_lbl 01002 `"SESTAT SDR 2013"', add
label define sample_lbl 01012 `"SDR 2013"', add
label define sample_lbl 01014 `"ISDR 2013"', add
label values sample sample_lbl

label define surid_lbl 1 `"NSCG"'
label define surid_lbl 2 `"SDR"', add
label define surid_lbl 3 `"NSRCG"', add
label define surid_lbl 4 `"ISDR"', add
label values surid surid_lbl

label define age_lbl 19 `"19"'
label define age_lbl 20 `"20"', add
label define age_lbl 21 `"21"', add
label define age_lbl 22 `"22"', add
label define age_lbl 23 `"23"', add
label define age_lbl 24 `"24"', add
label define age_lbl 25 `"25"', add
label define age_lbl 26 `"26"', add
label define age_lbl 27 `"27"', add
label define age_lbl 28 `"28"', add
label define age_lbl 29 `"29"', add
label define age_lbl 30 `"30"', add
label define age_lbl 31 `"31"', add
label define age_lbl 32 `"32"', add
label define age_lbl 33 `"33"', add
label define age_lbl 34 `"34"', add
label define age_lbl 35 `"35"', add
label define age_lbl 36 `"36"', add
label define age_lbl 37 `"37"', add
label define age_lbl 38 `"38"', add
label define age_lbl 39 `"39"', add
label define age_lbl 40 `"40"', add
label define age_lbl 41 `"41"', add
label define age_lbl 42 `"42"', add
label define age_lbl 43 `"43"', add
label define age_lbl 44 `"44"', add
label define age_lbl 45 `"45"', add
label define age_lbl 46 `"46"', add
label define age_lbl 47 `"47"', add
label define age_lbl 48 `"48"', add
label define age_lbl 49 `"49"', add
label define age_lbl 50 `"50"', add
label define age_lbl 51 `"51"', add
label define age_lbl 52 `"52"', add
label define age_lbl 53 `"53"', add
label define age_lbl 54 `"54"', add
label define age_lbl 55 `"55"', add
label define age_lbl 56 `"56"', add
label define age_lbl 57 `"57"', add
label define age_lbl 58 `"58"', add
label define age_lbl 59 `"59"', add
label define age_lbl 60 `"60"', add
label define age_lbl 61 `"61"', add
label define age_lbl 62 `"62"', add
label define age_lbl 63 `"63"', add
label define age_lbl 64 `"64"', add
label define age_lbl 65 `"65"', add
label define age_lbl 66 `"66"', add
label define age_lbl 67 `"67"', add
label define age_lbl 68 `"68"', add
label define age_lbl 69 `"69"', add
label define age_lbl 70 `"70"', add
label define age_lbl 71 `"71"', add
label define age_lbl 72 `"72"', add
label define age_lbl 73 `"73"', add
label define age_lbl 74 `"74"', add
label define age_lbl 75 `"75"', add
label define age_lbl 76 `"76"', add
label define age_lbl 77 `"77"', add
label define age_lbl 96 `"Blank"', add
label values age age_lbl

label define dgrdg_lbl 1 `"Bachelor's"'
label define dgrdg_lbl 2 `"Master's"', add
label define dgrdg_lbl 3 `"Doctorate"', add
label define dgrdg_lbl 4 `"Professional"', add
label values dgrdg dgrdg_lbl

label define ndgmed_lbl 198895 `"Computer and mathematical sciences"'
label define ndgmed_lbl 226395 `"Biological sciences"', add
label define ndgmed_lbl 298895 `"Other biological, agricultural, environmental life sciences"', add
label define ndgmed_lbl 318730 `"Chemistry, except biochemistry"', add
label define ndgmed_lbl 338785 `"Physics and astronomy"', add
label define ndgmed_lbl 398895 `"Other physical and related sciences"', add
label define ndgmed_lbl 419295 `"Economics"', add
label define ndgmed_lbl 429295 `"Political and related sciences"', add
label define ndgmed_lbl 438995 `"Psychology"', add
label define ndgmed_lbl 449995 `"Sociology and anthropology"', add
label define ndgmed_lbl 459395 `"Other social sciences"', add
label define ndgmed_lbl 527250 `"Chemical engineering"', add
label define ndgmed_lbl 537260 `"Civil engineering"', add
label define ndgmed_lbl 547280 `"Electrical, electronics and communications engineering"', add
label define ndgmed_lbl 567350 `"Mechanical engineering"', add
label define ndgmed_lbl 587995 `"Other engineering"', add
label define ndgmed_lbl 611995 `"Health-related fields"', add
label define ndgmed_lbl 699995 `"Other science and engineering-related"', add
label define ndgmed_lbl 719995 `"Management and administration"', add
label define ndgmed_lbl 799995 `"Other non-science and engineering"', add
label define ndgmed_lbl 999999 `"Missing"', add
label values ndgmed ndgmed_lbl





*Keep only individuals who are 27-59
keep if age>=27 & age<=59

*Create a new variable of graduate degrees separating professional degrees and each field of masters degrees
decode(dgrdg), gen(dgrdg_str) /*Turn degree type and field variables into strings*/
decode(ndgmed), gen(ndgmed_str)
g new_degfields = "Professional" if dgrdg==4  /*Generate new variable, indicating which indivdiauls have professional degrees as their highest degree...*/
replace new_degfields = "PhD" if dgrdg==3
replace new_degfields = "No Grad degree" if dgrdg==1
replace new_degfields = dgrdg_str + "-" + ndgmed_str if missing(new_degfields)  /*...then add togetehr highest degree (master's) and degree field to fully ctreate this variable*/

*Generate shares of each new degree category by year with SESTAT weights
bysort year: g deg_total = _N*weight
bysort new_degfields year: g deg = _N*weight
g deg_share = deg/deg_total

*Keep only one instance of the share per category
bysort new_degfields year: g tag = _n
keep if tag==1
drop tag
label var new_degfields "Degree Type"

*Keep only year, degree fields, and shares
keep year new_degfields deg_share
label var deg_share "Share of graduate degree type of all graduate degrees weighted by SESTAT weights"
save "$NSCG/graddeg_shares_9313", replace

*Generate table of the shares
table (new_degfields) (year), statistic(total deg_share) nototals nformat(%9.2gc total)
collect style putdocx, layout(fixed) title("Share of individuals with non-PhD graduate degrees by degree type and year, 1993-2013")
collect style cell, font(Times New Roman, size(8)) 
collect style title, font(Times New Roman, size(10))
collect notes "Source: Data from National Survey of College Graduates (NSCG) 1993-2013."
collect notes "Note: Shares are weighted by IPUMS Higher Education SESTAT weights."
collect style notes, font(Times New Roman, size(8))
collect style column, dups(center) width(equal)
collect export "$tables/graddeg_shares_9313.docx", as(docx) replace 


*Generate time series of these shares
encode new_degfields, gen(new_degfields_n)
xtset new_degfields_n year
xtline deg_share, overlay legend(pos(6) col(5) row(10) size(tiny)) ///
ytitle("Share (weighted)", size(small)) ///
xtitle(, size(small)) ///
title("Share of graduate degree types by year, 1993-2013", size(small)) ///
plot1(lc(red)) plot2(lc(orange)) plot3(lc(yellow)) plot4(lc(green)) plot5(lc(blue)) plot7(lc(purple)) plot7(lc(black)) plot8(lc(grey)) plot9(lc(cyan)) plot10(lc(magenta)) plot11(lc(lavender)) plot12(lc(lime)) plot13(lc(sandb)) plot14(lc(emidblue)) plot15(lc(sienna)) plot16(lc(olive_teal)) plot17(lc(olive)) plot18(lc(maroon)) plot19(lc(dknavy)) plot20(lc(pink)) plot21(lc(emerald)) plot22(lc(erose)) ///
note("Source: Data from National Survey of College Graduates (NSCG) 1993-2013." "Note: Shares are weighted by IPUMS Higher Education SESTAT weights.", size(tiny))
graph export "$tables/graddeg_shares_9313.png", replace






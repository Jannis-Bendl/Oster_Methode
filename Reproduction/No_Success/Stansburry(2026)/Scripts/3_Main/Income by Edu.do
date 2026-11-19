clear


*************SET UP DATA FILE*************


set more off

clear
quietly infix                ///
  int     year      1-4      ///
  long    serial    5-9      ///
  byte    month     10-11    ///
  double  hwtfinl   12-21    ///
  double  cpsid     22-35    ///
  byte    asecflag  36-36    ///
  byte    hflag     37-37    ///
  double  asecwth   38-48    ///
  double  hhincome  49-56    ///
  byte    pernum    57-58    ///
  double  wtfinl    59-72    ///
  double  cpsidv    73-87    ///
  double  cpsidp    88-101   ///
  double  asecwt    102-112  ///
  int     educ      113-115  ///
  byte    educ99    116-117  ///
  double  ftotval   118-127  ///
  double  inctot    128-136  ///
  using `"$CPS/Raw/cps_00010.dat"'

replace hwtfinl  = hwtfinl  / 10000
replace asecwth  = asecwth  / 10000
replace wtfinl   = wtfinl   / 10000
replace asecwt   = asecwt   / 10000

format hwtfinl  %10.4f
format cpsid    %14.0f
format asecwth  %11.4f
format hhincome %8.0f
format wtfinl   %14.4f
format cpsidv   %15.0f
format cpsidp   %14.0f
format asecwt   %11.4f
format ftotval  %10.0f
format inctot   %9.0f

label var year     `"Survey year"'
label var serial   `"Household serial number"'
label var month    `"Month"'
label var hwtfinl  `"Household weight, Basic Monthly"'
label var cpsid    `"CPSID, household record"'
label var asecflag `"Flag for ASEC"'
label var hflag    `"Flag for the 3/8 file 2014"'
label var asecwth  `"Annual Social and Economic Supplement Household weight"'
label var hhincome `"Total household income"'
label var pernum   `"Person number in sample unit"'
label var wtfinl   `"Final Basic Weight"'
label var cpsidv   `"Validated Longitudinal Identifier"'
label var cpsidp   `"CPSID, person record"'
label var asecwt   `"Annual Social and Economic Supplement Weight"'
label var educ     `"Educational attainment recode"'
label var educ99   `"Educational attainment, 1990"'
label var ftotval  `"Total family income"'
label var inctot   `"Total personal income"'

label define month_lbl 01 `"January"'
label define month_lbl 02 `"February"', add
label define month_lbl 03 `"March"', add
label define month_lbl 04 `"April"', add
label define month_lbl 05 `"May"', add
label define month_lbl 06 `"June"', add
label define month_lbl 07 `"July"', add
label define month_lbl 08 `"August"', add
label define month_lbl 09 `"September"', add
label define month_lbl 10 `"October"', add
label define month_lbl 11 `"November"', add
label define month_lbl 12 `"December"', add
label values month month_lbl

label define asecflag_lbl 1 `"ASEC"'
label define asecflag_lbl 2 `"March Basic"', add
label values asecflag asecflag_lbl

label define hflag_lbl 0 `"5/8 file"'
label define hflag_lbl 1 `"3/8 file"', add
label values hflag hflag_lbl

label define educ_lbl 000 `"NIU or no schooling"'
label define educ_lbl 001 `"NIU or blank"', add
label define educ_lbl 002 `"None or preschool"', add
label define educ_lbl 010 `"Grades 1, 2, 3, or 4"', add
label define educ_lbl 011 `"Grade 1"', add
label define educ_lbl 012 `"Grade 2"', add
label define educ_lbl 013 `"Grade 3"', add
label define educ_lbl 014 `"Grade 4"', add
label define educ_lbl 020 `"Grades 5 or 6"', add
label define educ_lbl 021 `"Grade 5"', add
label define educ_lbl 022 `"Grade 6"', add
label define educ_lbl 030 `"Grades 7 or 8"', add
label define educ_lbl 031 `"Grade 7"', add
label define educ_lbl 032 `"Grade 8"', add
label define educ_lbl 040 `"Grade 9"', add
label define educ_lbl 050 `"Grade 10"', add
label define educ_lbl 060 `"Grade 11"', add
label define educ_lbl 070 `"Grade 12"', add
label define educ_lbl 071 `"12th grade, no diploma"', add
label define educ_lbl 072 `"12th grade, diploma unclear"', add
label define educ_lbl 073 `"High school diploma or equivalent"', add
label define educ_lbl 080 `"1 year of college"', add
label define educ_lbl 081 `"Some college but no degree"', add
label define educ_lbl 090 `"2 years of college"', add
label define educ_lbl 091 `"Associate's degree, occupational/vocational program"', add
label define educ_lbl 092 `"Associate's degree, academic program"', add
label define educ_lbl 100 `"3 years of college"', add
label define educ_lbl 110 `"4 years of college"', add
label define educ_lbl 111 `"Bachelor's degree"', add
label define educ_lbl 120 `"5+ years of college"', add
label define educ_lbl 121 `"5 years of college"', add
label define educ_lbl 122 `"6+ years of college"', add
label define educ_lbl 123 `"Master's degree"', add
label define educ_lbl 124 `"Professional school degree"', add
label define educ_lbl 125 `"Doctorate degree"', add
label define educ_lbl 999 `"Missing/Unknown"', add
label values educ educ_lbl

label define educ99_lbl 00 `"NIU"'
label define educ99_lbl 01 `"No school completed"', add
label define educ99_lbl 04 `"1st-4th grade"', add
label define educ99_lbl 05 `"5th-8th grade"', add
label define educ99_lbl 06 `"9th grade"', add
label define educ99_lbl 07 `"10th grade"', add
label define educ99_lbl 08 `"11th grade"', add
label define educ99_lbl 09 `"12th grade, no diploma"', add
label define educ99_lbl 10 `"High school graduate, or GED"', add
label define educ99_lbl 11 `"Some college, no degree"', add
label define educ99_lbl 12 `"Associate degree, type of program not specified"', add
label define educ99_lbl 13 `"Associate degree, occupational program"', add
label define educ99_lbl 14 `"Associate degree, academic program"', add
label define educ99_lbl 15 `"Bachelors degree"', add
label define educ99_lbl 16 `"Masters degree"', add
label define educ99_lbl 17 `"Professional degree"', add
label define educ99_lbl 18 `"Doctorate degree"', add
label values educ99 educ99_lbl

save "$CPS/Cleaned/cps_setup", replace






*************GENERATE AVERAGE HOUSEHOLD INCOME BY HIGHEST EDU OF HOUSEHOLD*************


****With 5 years included in grad

use "$CPS/Cleaned/cps_setup", replace

***Keep only ASEC data since that is where the household income comes from
keep if asecflag==1


***Generate our four education categories, keeping the 5 years of college group in the graduate ex PhD category
g edu_cat = "1: No BA" if educ<=100
replace edu_cat = "2: BA" if educ==110 | educ==111
replace edu_cat = "3: Grad ex PhD" if educ>120 & educ<=124
replace edu_cat = "4: PhD" if educ==125
encode edu_cat, gen(edu_catn)

***Within each household (serial) and year, I sort by the education category and create a variable with the highest education for the household (edu_cat[_N])
bysort serial year (edu_catn): g highses_tag = edu_cat[_N]
label variable highses_tag "Education Level"

***Keep only one observations containing the education info and household income info for each household and year
bysort serial year: g hh_tag = _n
keep if hh_tag==1

/*
NOTES ABOUT HHINCOME
- Defined as the total money income during the previous calendar year of all adult household members. Includes those who lived in the household at the time of the survey
- Includes household members 15 and older (considered 'adults' in this question)
- Reported in contemporary dollars, not adjusted for inflation using CPI but we can do that ourselves if needed
- HHINCOME comes from adding the variable INCTOT of each family member. This variable can have negative values which represents that the individual had greater losses than gains in a given year. This means there are some negative HHINCOME observations.
- No missing values in this sample
*/


****Generate tables containing the average household income within each education category

**Separate into different tables so that all years available can fit on one page
*Have data from 1990-2023 but there's no instances of grad or phd households in this survey before 1992

table highses_tag year if year>=1992 & year<=1999 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc) /*generate table with mean of household income for each edu category and year*/
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 1992-1999") /*Collect table characteristics*/
collect style cell, font(Times New Roman, size(8))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 1992-1999."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights."
collect style notes, font(Times New Roman, size(8))
collect export "$tables/inc_hhses_9299_5grad.docx", as(docx) replace /*Export table*/

table highses_tag year if year>=2000 & year<=2009 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2000-2009")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2000-2009."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights."
collect style notes, font(Times New Roman, size(7))
collect export "$tables/inc_hhses_0009_5grad.docx", as(docx) replace

table highses_tag year if year>=2010 & year<=2019 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2010-2019")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2010-2019."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights."
collect style notes, font(Times New Roman, size(7))
collect export "$tables/inc_hhses_1019_5grad.docx", as(docx) replace

table highses_tag year if year>=2020 & year<=2023 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2020-2023")
collect style cell, font(Times New Roman, size(8))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2020-2023."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights."
collect style notes, font(Times New Roman, size(8))
collect export "$tables/inc_hhses_2023_5grad.docx", as(docx) replace




***Do the same as above but put all tables together in one document

putdocx begin

table highses_tag year if year>=1992 & year<=1999 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 1992-1999")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 1992-1999."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2000 & year<=2009 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2000-2009")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2000-2009."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2010 & year<=2019 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2010-2019")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2010-2019."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2020 & year<=2023 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2020-2023")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2020-2023."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the graduate category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

putdocx save "$tables/inc_hhses_9223_5grad.docx", replace









************REPEAT SAME PROCEDURE AS ABOVE BUT WITH 5 YEARS OF COLLEGE INCLUDED IN THE BA CATEGORY************
use "$CPS/Cleaned/cps_setup", replace

keep if asecflag==1

g edu_cat = "1: No BA" if educ<=100
replace edu_cat = "2: BA" if educ==110 | educ==111 | educ==120 | educ==121
replace edu_cat = "3: Grad ex PhD" if educ>121 & educ<=124
replace edu_cat = "4: PhD" if educ==125
encode edu_cat, gen(edu_catn)


bysort serial year (edu_catn): g highses_tag = edu_cat[_N]
label variable highses_tag "Education Level"


bysort serial year: g hh_tag = _n
keep if hh_tag==1


***Generate Tables separately
table highses_tag year if year>=1992 & year<=1999 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 1992-1999")
collect style cell, font(Times New Roman, size(8))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 1992-1999."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(8))
collect export "$tables/inc_hhses_9299_5ba.docx", as(docx) replace

table highses_tag year if year>=2000 & year<=2009 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2000-2009")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2000-2009."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
collect export "$tables/inc_hhses_0009_5ba.docx", as(docx) replace

table highses_tag year if year>=2010 & year<=2019 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2010-2019")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2010-2019."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
collect export "$tables/inc_hhses_1019_5ba.docx", as(docx) replace

table highses_tag year if year>=2020 & year<=2023 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(fixed) title("Average Household Income by Highest Level of Education per Household, 2020-2023")
collect style cell, font(Times New Roman, size(8))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2020-2023."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(8))
collect export "$tables/inc_hhses_2023_5ba.docx", as(docx) replace


***Put all years of this table together
putdocx begin

table highses_tag year if year>=1992 & year<=1999 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 1992-1999")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 1992-1999."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2000 & year<=2009 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2000-2009")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2000-2009."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2010 & year<=2019 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2010-2019")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2010-2019."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

table highses_tag year if year>=2020 & year<=2023 [pw=asecwth], statistic(mean hhincome) nototals nformat(%15.2fc)
collect style putdocx, layout(autofitcontents) title("Average Household Income by Highest Level of Education per Household, 2020-2023")
collect style cell, font(Times New Roman, size(7))
collect style title, font(Times New Roman, size(10))
collect notes "Source: CPS, 2020-2023."
collect notes "Notes: Contents of the table are the mean household income by highest level of education in a household by year. 5 years of education is included in the BA category. Means are weighted by ASEC household sampling weights. Household income is not inflation adjusted."
collect style notes, font(Times New Roman, size(7))
putdocx collect

putdocx save "$tables/inc_hhses_9223_5ba.docx", replace




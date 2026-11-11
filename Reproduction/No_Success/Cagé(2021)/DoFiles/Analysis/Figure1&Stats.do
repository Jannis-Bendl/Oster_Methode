quietly{		
********************************************************************************
* DAILY DEATHS
* STARTING POINT IS FROM MEW DATA SET CLEANED BY Gay and Grosjean * 
********************************************************************************
use  "$Data_origin/WWIDeaths/MdH_municipbirth_clean.dta", clear 

foreach x in id_geofla {
	label var `x'  "`x' of birth city"
	}
save, replace 

 
******************************************************************************** 
* CONVERT DATES & MERGE WITH LINE INFANTRY ROTATION * 
********************************************************************************
gen date_death=mdy(death_month,death_day,death_year)
label var date_death "date of death"

format date_death  %td

* Get rid of those who died after end of war (or before)
keep if date_death>=-16589
keep if death_year>=1914 
keep if  death_year<1919

gen RI_number = unit_number if unit_kind=="RI"
merge m:1 RI_number  using "$Data_generated/regimentsVerdun.dta", gen(mergeBattle)

gen i=1
label var i "Daily fatalities (line infantry)"
drop if verdun==.		
*******************************************************************************
 * LOOK AT DEATHS OF ALL THOSE IN RI WHILE AT VERDUN  * 
*******************************************************************************

** We now focus only on those who died specifically at Verdun (as opposed to comparing those who did VuP vs Verdun over whole war or in other settings of 1916)

**** KEEP only the deads who were at Verdun the MONTH they died and then collate all the deaths by day 

gen month_Verdun=.
replace month_Verdun=2 if feb==1 
replace month_Verdun=3 if march==1 
replace month_Verdun=4 if april==1 
replace month_Verdun=5 if mai==1 
replace month_Verdun=6 if june==1 
replace month_Verdun=7 if july==1 
replace month_Verdun=8 if aug==1 
replace month_Verdun=9 if sept==1 
replace month_Verdun=10 if oct==1 
replace month_Verdun=11 if nov==1 
replace month_Verdun=12 if dec==1 

forvalues i=2(1)12 {
	preserve 
		keep if month_Verdun==`i' 
		* collect deaths in Feb for those
		keep if death_month ==`i'  & death_year==1916
		keep i id date_death death_year death_month death_day unit_number unit_kind id_geofla verdun verdun_petain feb march april mai june july aug sept oct nov dec month_Verdun
		save "$Data_generated/temp/deaths_V_`i'.dta", replace
	restore	
	}
 
use "$Data_generated/temp/deaths_V_2.dta", clear 
append using "$Data_generated/temp/deaths_V_3.dta"
append using "$Data_generated/temp/deaths_V_4.dta"
append using "$Data_generated/temp/deaths_V_5.dta"
append using "$Data_generated/temp/deaths_V_6.dta"
append using "$Data_generated/temp/deaths_V_7.dta"
append using "$Data_generated/temp/deaths_V_8.dta"
append using "$Data_generated/temp/deaths_V_9.dta"
append using "$Data_generated/temp/deaths_V_10.dta"
append using "$Data_generated/temp/deaths_V_11.dta"
append using "$Data_generated/temp/deaths_V_12.dta"

collapse (sum) i   , by (date_death death_month death_day death_year unit_number)  

gen num_reg=1 

collapse (sum) i  num_reg  , by (date_death death_month death_day death_year)  

 
gen norm_fat=i/ num_reg 
tsset date_death 
tsfill 
replace i=0 if i==. 
replace norm_fat=0 if norm_fat==. 

label var i "Daily fatalities (line infantry) at Verdun"
label var norm_fat "(Normalised) Daily fatalities by line infantry regiment at Verdun"


*** FORMAL TEST OF STRUCTURAL BREAK 
tsset date_death 
** Whole duration of the battle -- from Petain's command (Formally on 26 Feb 1916 )
regress i L.i if date_death>=-16015 & date_death <= -15719
estat sbknown, break(-15950)

** what about Somme break ?  Whole duration of the battle 
regress i L.i if date_death>=-16015 & date_death <= -15719
estat sbknown, break( -15889 )

*** Symmetry around date of break : March, April, May, June : From March 1st to July 1 (also beginning of Sommme offensive )
regress i L.i  if date_death>=-16011   & date_death<  -15889 
estat sbknown, break(-15950) 
/* 
             chi2(2)      =    1.5406
             Prob > chi2  =    0.4629

*/ 

keep if  date_death>=-16020 & date_death <= -15719  
sort date_death 
gen time=_n
gen timesq=time*time


*** Version where we comment on dates 
twoway (scatter  i date_death, msymbol(x)), /// 
xlabel(-16040 "Feb 1" -16011 "Mar 1" -15980 "Apr 1" -15950 "May 1" -15919 "Jun 1" -15889 "Jul 1" -15858 "Aug 1" -15827 "Sep 1" -15797 "Oct 1" -15766 "Nov 1" -15736 "Dec 1", angle(horizontal) labsize(small)) ///
xline(-16015,lcolor(cranberry) lpattern(dash))  	text(280 -16022 "Fort Douaumont falls", place(e) orientation(vertical) size(vsmall) color(cranberry))  ///
xline(-16014, lcolor(black))  						text(500 -16013 "Pétain summoned to Verdun", place(e) orientation(vertical) size(vsmall))  ///
xline(-15950, lcolor(black))  						text(500 -15958 "Pétain promoted away", place(e) orientation(vertical) size(vsmall))  ///
xline(-15913,lcolor(cranberry) lpattern(dash)) 		text(280 -15920 "Fort Vaux falls", place(e) orientation(vertical) size(vsmall) color(cranberry))  ///
xline(-15878,lcolor(dknavy) lpattern(dot)) 			text(280 -15885 "Fort Souville resists", place(e) orientation(vertical) size(vsmall) color(dknavy))  ///
xline(-15774,lcolor(dknavy) lpattern(dot)) 			text(280 -15781 "Fort Douaumont is liberated (by colonial troops)", place(e) orientation(vertical) size(vsmall) color(dknavy))  ///
xtitle("") ///
graphregion(color(white))
graph export  "$Results/Figures/Figure1.pdf", replace 

}

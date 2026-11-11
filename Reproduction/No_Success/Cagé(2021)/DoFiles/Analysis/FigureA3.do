quietly{
********************************************************************************
********* Attack and Bombardement Data at Regiment level        **************
********************************************************************************

** 

import excel using "$Data_raw/Regiments/Combats/LocationAllRegiments.xlsx",   firstrow  clear 

** Run do file for graph
*tostring comment variables and harmonize date variables
foreach var of varlist Comment* {
tostring `var', replace
 }

 foreach var of varlist Date* {
replace `var'=lower(`var')
 }

foreach var of varlist Date*{
	list `var' if strpos(`var',"/")>0
}

foreach var of varlist Date*{
replace	`var' = subinstr(`var',"8/16/1916","16 august 1916",.)
replace	`var' = subinstr(`var',"7/8/1916","8 july 1916",.)
replace	`var' = subinstr(`var',"3/9/1916","9 march 1916",.)
replace	`var' = subinstr(`var',"3/13/1916","13 march 1916",.)
replace	`var' = subinstr(`var',"3/27/1916","27 march 1916",.)
replace	`var' = subinstr(`var',"3/11/1916 ","11 march 1916",.)
replace	`var' = subinstr(`var',"7/20/1916","20 july 1916",.)
replace	`var' = subinstr(`var',"4/21/1916","21 april 1916",.)
replace	`var' = subinstr(`var',"5/4/1916","4 may 1916",.)
replace	`var' = subinstr(`var',"4/9/1916","9 april 1916",.)

replace	`var' = subinstr(`var',"8/5/1916","5 august 1916",.)
replace	`var' = subinstr(`var',"5/17/1916 ","17 may 1916",.)
replace	`var' = subinstr(`var',"5/21/1916","21 may 1916",.)
replace	`var' = subinstr(`var',"4/18/1916","18 april 1916",.)
replace	`var' = subinstr(`var',"4/27/1917","27 april 1916",.)
replace	`var' = subinstr(`var',"8/22/1916","22 august 1916",.)
replace	`var' = subinstr(`var',"5/30/1916","30 may 1916",.)
replace	`var' = subinstr(`var',"4/25/1916","25 april 1916",.)
replace	`var' = subinstr(`var',"12/20/1916","20 december 1916",.)
replace	`var' = subinstr(`var',"11/13/1916","13 november 1916",.)

replace	`var' = subinstr(`var',"4/12/1916","12 april 1916",.)
replace	`var' = subinstr(`var',"7/6/1916","6 july 1916",.)
replace	`var' = subinstr(`var',"9/7/1916","7 september 1916",.)
replace	`var' = subinstr(`var',"5/23/1916","23 may 1916",.)
replace	`var' = subinstr(`var',"8/7/1916","7 august 1916",.)
replace	`var' = subinstr(`var',"12/15/1916","15 december 1916",.)
replace	`var' = subinstr(`var',"11/26/1916","26 november 1916",.)
replace	`var' = subinstr(`var',"9/1/1916","1 september 1916",.)
replace	`var' = subinstr(`var',"10/29/1916","29 october 1916",.)
replace	`var' = subinstr(`var',"5/25/1916","25 may 1916",.)

replace	`var' = subinstr(`var',"9/16/1916","16 september 1916",.)
replace	`var' = subinstr(`var',"12/11/1916","11 december 1916",.)
replace	`var' = subinstr(`var',"11/6/1916","6 november 1916",.)
replace	`var' = subinstr(`var',"5/5/1916","5 may 1916 ",.)
replace	`var' = subinstr(`var',"9/26/1916","26 september 1916",.)
replace	`var' = subinstr(`var',"11/11/1916","11 november 1916",.)
replace	`var' = subinstr(`var',"6/5/1916","5 june 1916",.)
replace	`var' = subinstr(`var',"11/6/1916","6 november 1916",.)
replace	`var' = subinstr(`var',"10/15/1916","15 october 1916",.)
replace	`var' = subinstr(`var',"5/22/1916","22 may 1916",.)

replace	`var' = subinstr(`var',"5/01/1916","1 may 1916",.)
replace	`var' = subinstr(`var',"22/05/1916","22 may 1916",.)
}
 
foreach var of varlist Date*{
	list `var' if strpos(`var',"/")>0
}

*generate indicator per month for bombing experience
local mylist   feb mar apr may jun jul aug sep oct nov dec 
local mylist2   february march april may june july august september october november december

foreach x of local mylist{
	gen `x'=0
}

*generating indicator that the regiment is fighting during a given month
foreach x of local mylist{
	gen Indic`x'=0
}

	forvalues i=1/27{
foreach x of local mylist{
	replace Indic`x'=1 if strpos(Date`i', "`x'")>0
}	
}

forvalues i=1/27{
    replace Indicfeb=1 if strpos(Date`i',"february")>0 
    replace Indicmar=1 if strpos(Date`i',"march")>0 
    replace Indicapr=1 if strpos(Date`i',"april")>0 
    replace Indicmay=1 if strpos(Date`i',"may")>0 
    replace Indicjun=1 if strpos(Date`i',"june")>0 
    replace Indicjul=1 if strpos(Date`i',"july")>0 
    replace Indicaug=1 if strpos(Date`i',"august")>0 
    replace Indicsep=1 if strpos(Date`i',"september")>0 
    replace Indicoct=1 if strpos(Date`i',"october")>0 
    replace Indicnov=1 if strpos(Date`i',"november")>0 
    replace Indicdec=1 if strpos(Date`i',"december")>0 
}

tab Indicfeb

*filling missing indicator dummies 
replace Indicmar=1 if Indicfeb==1&(Indicapr==1|Indicmay==1| Indicjun==1| Indicjul==1| Indicaug==1| Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicapr=1 if (Indicfeb==1|Indicmar==1)&(Indicmay==1| Indicjun==1| Indicjul==1| Indicaug==1| Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicmay=1 if (Indicfeb==1|Indicmar==1|Indicapr==1)&(Indicjun==1| Indicjul==1| Indicaug==1| Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicjun=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1)&(Indicjul==1| Indicaug==1| Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicjul=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1|Indicjun==1)&(Indicaug==1| Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicaug=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1|Indicjun==1|Indicjul==1)&( Indicsep==1| Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicsep=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1|Indicjun==1|Indicjul==1|Indicaug==1)&( Indicoct==1| Indicnov==1| Indicdec==1)

replace Indicoct=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1|Indicjun==1|Indicjul==1|Indicaug==1|Indicsep==1)&(Indicnov==1| Indicdec==1)

replace Indicnov=1 if (Indicfeb==1|Indicmar==1|Indicapr==1|Indicmay==1|Indicjun==1|Indicjul==1|Indicaug==1|Indicsep==1|Indicoct==1)&( Indicdec==1)

*replace indicators==1 if experience of bombardement during this month - defined as 'bombardement'/'artillerie'/'obus'/'pilonnage'/cannonade/'torpille'
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	forvalues i=1/27{
	replace `var'=1 if strpos(Date`i',"`var'")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
}
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"February")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace mar=1 if strpos(Date`i',"March")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace apr=1 if strpos(Date`i',"April")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace may=1 if strpos(Date`i',"May")>0 &(strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace jun=1 if strpos(Date`i',"June")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace jul=1 if strpos(Date`i',"July")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace aug=1 if strpos(Date`i',"August")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace sep=1 if strpos(Date`i',"September")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace oct=1 if strpos(Date`i',"October")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace nov=1 if strpos(Date`i',"November")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace dec=1 if strpos(Date`i',"December")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"february")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace mar=1 if strpos(Date`i',"march")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace apr=1 if strpos(Date`i',"april")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace may=1 if strpos(Date`i',"may")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace jun=1 if strpos(Date`i',"june")>0 &(strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace jul=1 if strpos(Date`i',"july")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace aug=1 if strpos(Date`i',"august")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace sep=1 if strpos(Date`i',"september")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace oct=1 if strpos(Date`i',"october")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace nov=1 if strpos(Date`i',"november")>0 &(strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
    replace dec=1 if strpos(Date`i',"december")>0 & (strpos(Comment`i',"bombardement")>0 | strpos(Comment`i',"artillerie")>0 |strpos(Comment`i',"obus")>0|strpos(Comment`i',"pilonnage")>0|strpos(Comment`i',"cannonade")>0|strpos(Comment`i',"torpille")>0)
}

*gen sum regiment who experienced bombing during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	egen sum`var'=sum(`var')
}

*gen sum regiment who were in the battle during each month
foreach var of varlist Indic*  {
	egen sum`var'=sum(`var')
}

*gen average nber of regiment who experience bombing during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	gen av`var'=sum`var'/sumIndic`var'
}

*rename variables
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	rename sum`var' sumbomb`var'
	rename av`var' avbomb`var'
}

********************************************************************************
***French attacks
********************************************************************************
drop feb mar apr may jun jul aug sep oct nov dec sumIndic*

*generate indicator per month for french attack experience
local mylist   feb mar apr may jun jul aug sep oct nov dec 
local mylist2   february march april may june july august september october november december

foreach x of local mylist{
	gen `x'=0
}

*replace indicators==1 if experience of french attack during this month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	forvalues i=1/27{
	replace `var'=1 if strpos(Date`i',"`var'")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
}
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"February")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace mar=1 if strpos(Date`i',"March")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace apr=1 if strpos(Date`i',"April")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace may=1 if strpos(Date`i',"May")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace jun=1 if strpos(Date`i',"June")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace jul=1 if strpos(Date`i',"July")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace aug=1 if strpos(Date`i',"August")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace sep=1 if strpos(Date`i',"September")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace oct=1 if strpos(Date`i',"October")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace nov=1 if strpos(Date`i',"November")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace dec=1 if strpos(Date`i',"December")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"february")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace mar=1 if strpos(Date`i',"march")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace apr=1 if strpos(Date`i',"april")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace may=1 if strpos(Date`i',"may")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace jun=1 if strpos(Date`i',"june")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace jul=1 if strpos(Date`i',"july")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace aug=1 if strpos(Date`i',"august")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace sep=1 if strpos(Date`i',"september")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace oct=1 if strpos(Date`i',"october")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace nov=1 if strpos(Date`i',"november")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
    replace dec=1 if strpos(Date`i',"december")>0 & (strpos(Comment`i',"attaques francaises")>0 | strpos(Comment`i',"attaque francaise")>0)
}

*gen sum regiment who experienced french attacks during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	egen sum`var'=sum(`var')
}

*gen sum regiment who were in the battle during each month
foreach var of varlist Indic*  {
	egen sum`var'=sum(`var')
}

*gen average nber of regiment who experience french attacks during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	gen av`var'=sum`var'/sumIndic`var'
}

*rename variables
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	rename sum`var' sumfrenchattacks`var'
	rename av`var' avfrenchattacks`var'
}

********************************************************************************
***German attacks
********************************************************************************
drop feb mar apr may jun jul aug sep oct nov dec sumIndic*

*generate indicator per month for german attack experience
local mylist   feb mar apr may jun jul aug sep oct nov dec 
local mylist2   february march april may june july august september october november december

foreach x of local mylist{
	gen `x'=0
}

*replace indicators==1 if experience of german attack during this month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	forvalues i=1/27{
	replace `var'=1 if strpos(Date`i',"`var'")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
}
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"February")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace mar=1 if strpos(Date`i',"March")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace apr=1 if strpos(Date`i',"April")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace may=1 if strpos(Date`i',"May")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace jun=1 if strpos(Date`i',"June")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace jul=1 if strpos(Date`i',"July")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace aug=1 if strpos(Date`i',"August")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace sep=1 if strpos(Date`i',"September")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace oct=1 if strpos(Date`i',"October")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace nov=1 if strpos(Date`i',"November")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace dec=1 if strpos(Date`i',"December")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
}

	forvalues i=1/27{
    replace feb=1 if strpos(Date`i',"february")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace mar=1 if strpos(Date`i',"march")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace apr=1 if strpos(Date`i',"april")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace may=1 if strpos(Date`i',"may")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace jun=1 if strpos(Date`i',"june")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace jul=1 if strpos(Date`i',"july")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace aug=1 if strpos(Date`i',"august")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace sep=1 if strpos(Date`i',"september")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace oct=1 if strpos(Date`i',"october")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace nov=1 if strpos(Date`i',"november")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
    replace dec=1 if strpos(Date`i',"december")>0 & (strpos(Comment`i',"attaques allemandes")>0 | strpos(Comment`i',"attaque allemande")>0)
}

*gen sum regiment who experienced german attack during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov dec  {
	egen sum`var'=sum(`var')
}

*gen sum regiment who were in the battle during each month
foreach var of varlist Indic*  {
	egen sum`var'=sum(`var')
}

*gen average nber of regiment who experience german attack during each month
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	gen av`var'=sum`var'/sumIndic`var'
}

*rename variables
foreach var of varlist  feb mar apr may jun jul aug sep oct nov de  {
	rename sum`var' sumgermanattacks`var'
	rename av`var' avgermanattacks`var'
}

********************************************************************************
***PLOTS
********************************************************************************
keep sum* av*
duplicates drop sumbombfeb, force

gen monthid=1 

reshape long sumbomb sumgermanattacks sumfrenchattacks avbomb avfrenchattacks avgermanattacks, i(monthid) j(month) string  

drop if strpos(month, "Indic")>0

replace monthid=2.5 if month=="feb"
replace monthid=3.5 if month=="mar"
replace monthid=4.5 if month=="apr"
replace monthid=5.5 if month=="may"
replace monthid=6.5 if month=="jun"
replace monthid=7.5 if month=="jul"
replace monthid=8.5 if month=="aug"
replace monthid=9.5 if month=="sep"
replace monthid=10.5 if month=="oct"
replace monthid=11.5 if month=="nov"
replace monthid=12.5 if month=="dec"


sort monthid 

label var monthid "Month at Verdun"
label var sumbomb "Number of line infantry regiments bombarded by the German artillery"
label var sumgermanattacks "Number of line infantry regiments which experienced German attacks"
label var sumfrenchattacks "Number of line infantry regiments which took part in French attacks"
label var avbomb "Share of line infantry regiments bombarded by the German artillery"
label var avgermanattacks "Share of line infantry regiments which experienced German attacks"
label var avfrenchattacks "Share of line infantry regiments which took part in French attacks"

label define monthid 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan"
label values monthid monthid

*plot share of regiments per month
	 twoway (scatter avbomb monthid,msymbol(circle_hollow)  msize(11-pt) )   (scatter avgermanattacks monthid, msymbol(diamond_hollow)msize(11-pt)) (scatter avfrenchattacks monthid,  msymbol(square))  , xlabel(#11, valuelabel)  scheme(s1mono)  xline(5) legend(rows(3) size(small))
graph save "$Results/Figures/FigureA3.gph", replace 
graph export  "$Results/Figures/FigureA3.pdf", replace

** tests
cap drop VuP
gen VuP=(monthid<5.5)
replace VuP=. if monthid>7.5
ttest sumbomb, by (VuP)
ttest avgermanattacks, by (VuP)
}

********************************************************************************
*Centroid Data Importing, Cleaning, and Merging
********************************************************************************

*************
*Import US state city centroids (population weighted)
clear
use "$CENT/usa_48states/usa_contig_weighted.dta", clear

*Clean in order to merge with data from the SED and SDR
g Currstatprov="AK" if STATE_NAME=="Alaska"
replace Currstatprov="AL" if STATE_NAME=="Alabama"
replace Currstatprov="AR" if STATE_NAME=="Arkansas"
replace Currstatprov="AZ" if STATE_NAME=="Arizona"
replace Currstatprov="CA" if STATE_NAME=="California"
replace Currstatprov="CO" if STATE_NAME=="Colorado"
replace Currstatprov="CT" if STATE_NAME=="Connecticut"
replace Currstatprov="DC" if STATE_NAME=="District of Columbia"
replace Currstatprov="DE" if STATE_NAME=="Delaware"
replace Currstatprov="FL" if STATE_NAME=="Florida"
replace Currstatprov="GA" if STATE_NAME=="Georgia"
replace Currstatprov="HI" if STATE_NAME=="Hawaii"
replace Currstatprov="IA" if STATE_NAME=="Iowa"
replace Currstatprov="ID" if STATE_NAME=="Idaho"
replace Currstatprov="IL" if STATE_NAME=="Illinois"
replace Currstatprov="IN" if STATE_NAME=="Indiana"
replace Currstatprov="KS" if STATE_NAME=="Kansas"
replace Currstatprov="KY" if STATE_NAME=="Kentucky"
replace Currstatprov="LA" if STATE_NAME=="Louisiana"
replace Currstatprov="MA" if STATE_NAME=="Massachusetts"
replace Currstatprov="MD" if STATE_NAME=="Maryland"
replace Currstatprov="ME" if STATE_NAME=="Maine"
replace Currstatprov="MI" if STATE_NAME=="Michigan"
replace Currstatprov="MN" if STATE_NAME=="Minnesota"
replace Currstatprov="MO" if STATE_NAME=="Missouri"
replace Currstatprov="MS" if STATE_NAME=="Mississippi"
replace Currstatprov="MT" if STATE_NAME=="Montana"
replace Currstatprov="NC" if STATE_NAME=="North Carolina"
replace Currstatprov="ND" if STATE_NAME=="North Dakota"
replace Currstatprov="NE" if STATE_NAME=="Nebraska"
replace Currstatprov="NH" if STATE_NAME=="New Hampshire"
replace Currstatprov="NJ" if STATE_NAME=="New Jersey"
replace Currstatprov="NM" if STATE_NAME=="New Mexico"
replace Currstatprov="NV" if STATE_NAME=="Nevada"
replace Currstatprov="NY" if STATE_NAME=="New York"
replace Currstatprov="OH" if STATE_NAME=="Ohio"
replace Currstatprov="OK" if STATE_NAME=="Oklahoma"
replace Currstatprov="OR" if STATE_NAME=="Oregon"
replace Currstatprov="PA" if STATE_NAME=="Pennsylvania"
replace Currstatprov="RI" if STATE_NAME=="Rhode Island"
replace Currstatprov="SC" if STATE_NAME=="South Carolina"
replace Currstatprov="SD" if STATE_NAME=="South Dakota"
replace Currstatprov="TN" if STATE_NAME=="Tennessee"
replace Currstatprov="TX" if STATE_NAME=="Texas"
replace Currstatprov="UT" if STATE_NAME=="Utah"
replace Currstatprov="VA" if STATE_NAME=="Virginia"
replace Currstatprov="VT" if STATE_NAME=="Vermont"
replace Currstatprov="WA" if STATE_NAME=="Washington"
replace Currstatprov="WI" if STATE_NAME=="Wisconsin"
replace Currstatprov="WV" if STATE_NAME=="West Virginia"
replace Currstatprov="WY" if STATE_NAME=="Wyoming"
rename Lat_Pop CURR_CITYLAT
rename Long_Pop CURR_CITYLONG
rename NAME countyname
replace countyname=strtrim(countyname)
replace Currstatprov=strtrim(Currstatprov)
keep CURR_CITYLAT CURR_CITYLONG countyname Currstatprov
collapse (mean) CURR_CITYLAT CURR_CITYLONG, by(countyname Currstatprov)
save "$CENT/currcentroids49", replace

*Manually add in Alaskan centroids
clear
input str10 Currstatprov str20 countyname CURR_CITYLAT CURR_CITYLONG
AK "Aleutians East" 55.2287064 -161.9862284
AK "Aleutians West" 52.8186609 -174.9383984
AK Anchorage 61.1481988 -149.1893201
AK Bethel 60.8818415 -160.3021009
AK "Bristol Bay" 58.7337759 -156.9816027
AK Chugach 60.6148985 -146.1286936
AK "Copper River" 61.8788898 -143.9390615
AK Denali 63.6751034 -150.0337215
AK Dillingham 59.7067565 -158.3720487
AK "Fairbanks North Star" 64.8100713 -146.5667976
AK Haines 59.0726788 -135.4653654
AK Hoonah-Angoon 58.2065557 -135.5310910
AK Juneau 58.4427109 -134.2257891
AK "Kenai Peninsula" 60.1139716 -151.7163687
AK "Kethcikan Gateway" 55.4851521 -131.0305653
AK "Kodiak Island" 57.6566987 -153.7753069
AK Kusilvak 62.1569503 -163.5405823
AK "Lake and Peninsula" 58.2265876 -156.6570897
AK Matanuska-Susitna 62.3054074 -149.6020040
AK Nome 64.8395097 -164.2511572
AK "North Slope" 69.4497862 -153.5132443
AK "Northwest Artic" 67.0078230 -160.0338859
AK Petersburg 57.1112296 -133.0008518
AK "Prince of Wales-Hyder" 55.7188675 -133.775451
AK Sitka 57.1755357 -135.2983465
AK Skagway 59.5597214 -135.3360206
AK "Southeast Fairbanks" 63.8648323 -143.2122813
AK Wrangell 56.2928212 -132.1296495
AK Yakutat 56.8686862 -140.3490980
AK Yukon-Koyukuk 65.4996832 -151.8472016
end
replace countyname=strtrim(countyname)
save "$CENT/currcentroidsalaska", replace
append using "$CENT/currcentroids49"

*Save all 50 states centroid data
save "$CENT/currcentroids50", replace

*************
*Import centroid (population weighted) state data
import excel "$CENT/StatePopCenter", firstrow clear

*Clean this data to merge with SED high school state data
g HSPLACE_R="AK" if STNAME=="Alabama"
replace HSPLACE_R="AL" if STNAME=="Alaska"
replace HSPLACE_R="AR" if STNAME=="Arkansas"
replace HSPLACE_R="AZ" if STNAME=="Arizona"
replace HSPLACE_R="CA" if STNAME=="California"
replace HSPLACE_R="CO" if STNAME=="Colorado"
replace HSPLACE_R="CT" if STNAME=="Connecticut"
replace HSPLACE_R="DC" if STNAME=="District of Columbia"
replace HSPLACE_R="DE" if STNAME=="Delaware"
replace HSPLACE_R="FL" if STNAME=="Florida"
replace HSPLACE_R="GA" if STNAME=="Georgia"
replace HSPLACE_R="HI" if STNAME=="Hawaii"
replace HSPLACE_R="IA" if STNAME=="Iowa"
replace HSPLACE_R="ID" if STNAME=="Idaho"
replace HSPLACE_R="IL" if STNAME=="Illinois"
replace HSPLACE_R="IN" if STNAME=="Indiana"
replace HSPLACE_R="KS" if STNAME=="Kansas"
replace HSPLACE_R="KY" if STNAME=="Kentucky"
replace HSPLACE_R="LA" if STNAME=="Louisiana"
replace HSPLACE_R="MA" if STNAME=="Massachusetts"
replace HSPLACE_R="MD" if STNAME=="Maryland"
replace HSPLACE_R="ME" if STNAME=="Maine"
replace HSPLACE_R="MI" if STNAME=="Michigan"
replace HSPLACE_R="MN" if STNAME=="Minnesota"
replace HSPLACE_R="MO" if STNAME=="Missouri"
replace HSPLACE_R="MS" if STNAME=="Mississippi"
replace HSPLACE_R="MT" if STNAME=="Montana"
replace HSPLACE_R="NC" if STNAME=="North Carolina"
replace HSPLACE_R="ND" if STNAME=="North Dakota"
replace HSPLACE_R="NE" if STNAME=="Nebraska"
replace HSPLACE_R="NH" if STNAME=="New Hampshire"
replace HSPLACE_R="NJ" if STNAME=="New Jersey"
replace HSPLACE_R="NM" if STNAME=="New Mexico"
replace HSPLACE_R="NV" if STNAME=="Nevada"
replace HSPLACE_R="NY" if STNAME=="New York"
replace HSPLACE_R="OH" if STNAME=="Ohio"
replace HSPLACE_R="OK" if STNAME=="Oklahoma"
replace HSPLACE_R="OR" if STNAME=="Oregon"
replace HSPLACE_R="PA" if STNAME=="Pennsylvania"
replace HSPLACE_R="PR" if STNAME=="Puerto Rico"
replace HSPLACE_R="RI" if STNAME=="Rhode Island"
replace HSPLACE_R="SC" if STNAME=="South Carolina"
replace HSPLACE_R="SD" if STNAME=="South Dakota"
replace HSPLACE_R="TN" if STNAME=="Tennessee"
replace HSPLACE_R="TX" if STNAME=="Texas"
replace HSPLACE_R="UT" if STNAME=="Utah"
replace HSPLACE_R="VA" if STNAME=="Virginia"
replace HSPLACE_R="VT" if STNAME=="Vermont"
replace HSPLACE_R="WA" if STNAME=="Washington"
replace HSPLACE_R="WI" if STNAME=="Wisconsin"
replace HSPLACE_R="WV" if STNAME=="West Virginia"
replace HSPLACE_R="WY" if STNAME=="Wyoming"
rename LATITUDE HSLAT
rename LONGITUDE HSLONG

*Save dataset to merge wiht high school data
save "$CENT/popcenths_use", replace


**********
*Include further city/county data to supplement earlier city data to increase sample size
import delimited "$CENT/geocorr2022_2326201260.csv", varnames(1) clear

*Clean this data
drop if county=="County code"
split placename, parse(,)
drop placename2 placename3
drop if placename1=="[not in a place]"
replace placename1= subinstr(placename1, "city", " ", .)
replace placename1= subinstr(placename1, "town", " ", .)
replace placename1= subinstr(placename1, "CDP", " ", .)
replace placename1= subinstr(placename1, "borough", " ", .)
replace placename1= subinstr(placename1, "village", " ", .)
replace placename1= subinstr(placename1, "municipality", " ", .)
replace countyname = substr(countyname, 1, length(countyname) - 3)
rename stab Currstatprov
rename placename1 Currinstcity
replace Currinstcity=strtrim(Currinstcity)
replace Currstatprov=strtrim(Currstatprov)
replace countyname=strtrim(countyname)
duplicates drop countyname Currinstcity Currstatprov, force
keep Currinstcity countyname Currstatprov
duplicates drop Currinstcity Currstatprov, force

*Manually fix certain strings
replace countyname="Du Page" if countyname=="DuPage"
replace countyname="Washington" if countyname=="District of Columbia" & Currstatprov=="DC"
replace countyname="Dade" if countyname=="Miami-Dade" & Currstatprov=="FL"
replace countyname="De Kalb" if countyname=="DeKalb" & Currstatprov=="GA"
replace countyname= subinstr(countyname, "Parish", "", .) if Currstatprov=="LA"
replace countyname="Baltimore City" if countyname=="Baltimore city" & Currstatprov=="MD"
replace countyname="Mountrial" if countyname=="Mountrail" & Currstatprov=="ND"
replace countyname="Oglala Lakota" if countyname=="Oglala Lakota, SD" & Currstatprov=="SD"
replace countyname="McKean" if countyname=="Mc Kean" & Currstatprov=="PA"		
replace countyname="Buena Vista" if countyname=="Buena Vista city" & Currstatprov=="VA"
replace countyname="Charlottesville" if countyname=="Charlottesville city" & Currstatprov=="VA"
replace countyname="Chesapeake" if countyname=="Chesapeake city" & Currstatprov=="VA"
replace countyname="Danville" if countyname=="Danville city" & Currstatprov=="VA"		
replace countyname="Fairfax City" if countyname=="Fairfax city" & Currstatprov=="VA"
replace countyname="Fredericksburg" if countyname=="Fredericksburg city" & Currstatprov=="VA"		
replace countyname="Hampton" if countyname=="Hampton city" & Currstatprov=="VA"
replace countyname="Harrisonburg" if countyname=="Harrisonburg city" & Currstatprov=="VA"		
replace countyname="Lexington" if countyname=="Lexington city" & Currstatprov=="VA"
replace countyname="Lynchburg" if countyname=="Lynchburg city" & Currstatprov=="VA"	
replace countyname="Norfolk" if countyname=="Norfolk city" & Currstatprov=="VA"
replace countyname="Newport News" if countyname=="Newport News city" & Currstatprov=="VA"
replace countyname="Petersburg" if countyname=="Petersburg city" & Currstatprov=="VA"		
replace countyname="Radford" if countyname=="Radford city" & Currstatprov=="VA"
replace countyname="Richmond City" if countyname=="Richmond city" & Currstatprov=="VA"	
replace countyname="Roanoke City" if countyname=="Roanoke city" & Currstatprov=="VA"	
replace countyname="Salem" if countyname=="Salem city" & Currstatprov=="VA"		
replace countyname="Staunton" if countyname=="Staunton city" & Currstatprov=="VA"
replace countyname="Virginia Beach" if countyname=="Virginia Beach city" & Currstatprov=="VA"		
replace countyname="Williamsburg" if countyname=="Williamsburg city" & Currstatprov=="VA"	
replace countyname="Winchester" if countyname=="Winchester city" & Currstatprov=="VA"
replace countyname="Manassas City" if countyname=="Manassas city" & Currstatprov=="VA"	
replace countyname="Martinsville" if countyname=="Martinsville city" & Currstatprov=="VA"
replace countyname="Fond Du Lac" if countyname=="Fond du Lac" & Currstatprov=="WI"
replace countyname= subinstr(countyname, "Borough", " ", .)
replace countyname= subinstr(countyname, "Census Area", " ", .)
replace countyname= subinstr(countyname, "Census A", " ", .)
replace countyname= subinstr(countyname, "Boro", " ", .)
replace countyname="Chugach" if Currinstcity=="Chenega" & Currstatprov=="AK"
replace countyname="Chugach" if Currinstcity=="Cordova" & Currstatprov=="AK"
replace countyname="Chugach" if Currinstcity=="Tatitlek" & Currstatprov=="AK"
replace countyname="Chugach" if Currinstcity=="Valdez" & Currstatprov=="AK"
replace countyname="Chugach" if Currinstcity=="Whittier" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Chistochina" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Chitina" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Copper Center" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Gakona" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Glennallen" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Gulkana" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Kenny Lake" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="McCarthy" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Mendeltna" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Mentasta Lake" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Nabesna" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Nelchina" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Paxson" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Silver Springs" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Slana" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Tazlina" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Tolsona" & Currstatprov=="AK"
replace countyname="Copper River" if Currinstcity=="Tonsina" & Currstatprov=="AK"
replace countyname=strtrim(countyname)
replace countyname="LaFourche" if countyname=="Lafourche" & Currstatprov=="LA"
save "$CENT/broadcity", replace

*Load SDR data
use "$DATA/sdrdrf_9321_working", clear

*Merge county/city centroid variables into SDR-SED for current institutions
merge m:1 Currinstcity Currstatprov using "$CENT/broadcity", gen(distmerge)
drop if distmerge==2
drop distmerge

*Merge original city data
merge m:1 Currstatprov countyname using "$CENT/currcentroids50", gen(currcity_merge)
drop if currcity_merge==2
drop currcity_merge

*Merge state centroids variables into SDR-SED for HS state
merge m:1 HSPLACE_R using "$CENT/popcenths_use", gen(hsmerge)
drop hsmerge

* Synthetic update in case variable is already present
cap drop HSCURRCITY_DIST

*Calculate distance between HS state and Current city centroids
geodist HSLAT HSLONG CURR_CITYLAT CURR_CITYLONG, gen(HSCURRCITY_DIST) miles
g HSCURRCITY_DIST_sq = HSCURRCITY_DIST^2
g HSCURRCITY_DIST_cube = HSCURRCITY_DIST^3

*Generate distance variables with different units
replace HSCURRCITY_DIST = HSCURRCITY_DIST/10000
label var HSCURRCITY_DIST "Centroid Distance (in Ten Thousands)"
replace HSCURRCITY_DIST_sq = HSCURRCITY_DIST_sq/10000
label var HSCURRCITY_DIST_sq "Centroid Distance Squared (in Ten Thousands)"
replace HSCURRCITY_DIST_cube = HSCURRCITY_DIST_cube/10000
label var HSCURRCITY_DIST_cube "Centroid Distance Cubed (in Ten Thousands)"

*Save full file
save "$DATA/sdrdrf_9321_working", replace

use "$temp_dir/US_Microdata.dta" if inlist(period,"_1878_1880","_1873_1877"), clear

label var bc "Births per 1000 women per year"
label var british_hh "British Mother"
label var mom_age "Mother's Age (start of period)"

cd "$results" 
sutex bc british_hh mom_age, labels minmax file(T12_US_Sum_Stats) replace



tab marst if british_hh==1 & period=="_1873_1877"
tab marst if british_hh==0 & period=="_1873_1877"

tab marst if british_hh==1 & period=="_1878_1880"
tab marst if british_hh==0 & period=="_1878_1880"

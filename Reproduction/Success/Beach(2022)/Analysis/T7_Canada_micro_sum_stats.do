use "$temp_dir/Canadian_Microdata.dta" if inlist(period,"72_77","78_81"), clear

*Generate summary stats for final sample
label var bc_scaled "Births per 1000 women per year"
label var mom_british "British Mother"
label var mom_age "Mother's Age (start of period)"

cd "$results"
sutex bc_scaled mom_british mom_age, labels minmax file(T7_Canada_micro_sum_stats) replace

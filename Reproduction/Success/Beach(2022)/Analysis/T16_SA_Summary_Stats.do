use "$temp_dir/SA_DivisionXperiod.dta", clear

cd "$results" 

sutex br_1875 br_1891 brit_imm_shr non_dutch_shr density literacy, label file(T16_SA_Summary_Stats) replace minmax

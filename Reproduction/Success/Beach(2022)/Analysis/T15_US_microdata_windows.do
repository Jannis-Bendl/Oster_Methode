use "$temp_dir/US_Microdata.dta" if marst!=6, clear

eststo Robust_1: reghdfe bc british_hh post_bbXbritish if inlist(period,"_1878_1880","_1873_1877"), absorb(momageXyear cntyXbirth_yr occXyear) cluster(statefip)

eststo Robust_2: reghdfe bc british_hh post_bbXbritish if inlist(period,"_1878_1880","_1873_1876"), absorb(momageXyear cntyXbirth_yr occXyear) cluster(statefip)

eststo Robust_3: reghdfe bc british_hh post_bbXbritish if inlist(period,"_1878_1880","_1872_1877"), absorb(momageXyear cntyXbirth_yr occXyear) cluster(statefip)

eststo Robust_4: reghdfe bc british_hh post_bbXbritish if inlist(period,"_1878_1880","_1872_1876"), absorb(momageXyear cntyXbirth_yr occXyear) cluster(statefip)

esttab Robust_* using "$results/T15_US_microdata_windows", label mtitles("1873-77" "1873-76" "1872-77" "1872-76") keep(post_bbXbritish) stats(N, label("Observations") fmt(%9.0fc)) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) tex replace

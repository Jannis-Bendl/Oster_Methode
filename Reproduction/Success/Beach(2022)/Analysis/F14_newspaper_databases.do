import excel "$data_dir/newspaper_hits.xlsx", sheet("Sheet1") firstrow case(lower) clear

two connect newspapers_bb chronicling_bb gale_bb year, ylabel(0(50)200, grid notick angle(0)) xlabel(1871(2)1885, grid notick) legend(order(1 "Newspapers.com" 2 "Chronicling America" 3 "Gale") pos(1) ring(0) cols(1)) lcolor(black black*.25 black*.5) mcolor(black black*.25 black*.5) xtitle("")

graph export "$results/F14_newspaper_databases.pdf", replace

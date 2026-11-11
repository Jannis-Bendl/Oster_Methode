/*

What Works and for Whom? Effectiveness and Efficiency of School Capital Investments Across the U.S.

Biasi, Lafortune, Schonholzer - QJE 2025

Master file - produces all tables and figures in the paper

*/


********************************************************************************

if c(username) == "bb779" { 
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "julienl" {
	global root "/Users/julienl/Dropbox/Projects/School construction"
}
else if inlist(c(username), "davidschonholzer", "dasc4929") {
	global root "~/Dropbox/Research/School construction"
}
else if c(username) == "jabef" {
	global root "C:\Users\jabef\Desktop\FU Job\Prof.Marcus\Python_Scraper\Oster_Methode\Reproduction\Biasi(2025)"
}

global do "${root}"


*******************************************************************************

*-------------> Data preparation

//do "$doB/../../prepare/merge_fin_bond.do"	
do "$do/build/prepare_analysis_dataset.do"	
do "$do/build/recode_bond_cat.do"

do "$do/build/build_simple_stacked.do"		
do "$do/build/build_stacked_future.do"		
do "$do/build/build_simple_stacked_cleanfull.do"		

do "$do/build/build_stacked_cat_simple_dataset.do"		
do "$do/build/build_stacked_cat_cleanfull_dataset.do"		
do "$do/build/build_stacked_cat_future_dataset.do"		


*-------------> Code for main figures and tables in the paper

* Summary stats table
do "$do/analysis/sumstats.do"				

* Main reduced-form effects
do "$do/analysis/mean_effects_stacked.do"   

* 2SLS
do "$do/analysis/iv_threesteps_stacked_boot.do" 
do "$do/analysis/iv_hpi_threesteps_stacked_cap_boot.do" 
do "$do/analysis/iv_hpi_threesteps_stacked_boot.do" 

* Heterogeneity by category
do "$do/analysis/heterogeneous_treatment_coarsecat_stacked.do" 

* 2SLS by category
do "$do/analysis/iv_noapportion_test.do"
do "$do/analysis/iv_noapportion_hpi.do"

* Heterogeneity by SES/capital
do "$do/analysis/heterogeneous_effects_stacked.do" 
do "$do/analysis/heterogeneous_effects_capital_stacked.do" 


*-------------> Code for figures and tables in the Online Appendix

do "$do/analysis/rd_mccrary.do"				
do "$do/analysis/rd_figures.do"				
do "$do/analysis/rd_figures_stacked.do"			
// do "$do/bondrates_sumstats.do"	// runs only on restricted-access Mergent data	

do "$do/analysis/sumstats_bonds.do"   
do "$do/analysis/cfr.do"   
do "$do/analysis/heterogeneous_effects_stacked_cfr.do"   

do "$do/analysis/wooldridge.do" 
do "$do/analysis/wooldridge_heterog.do" 
do "$do/analysis/heterogeneous_treatment_coarsecat_stacked_wooldridge.do" 

do "$do/analysis/mean_effects_nofuture.do" 
do "$do/analysis/heterogeneous_treatment_coarsecat_stacked_nofuture.do" 
do "$do/analysis/heterogeneous_effects_stacked_nofuture.do" 

do "$do/analysis/heterogeneous_treatment_coarsecat_stacked_byses.do" 
do "$do/analysis/heterogeneous_treatment_coarsecat_stacked_byminor.do" 

do "$do/analysis/mean_effects_stacked_polynomials.do" 

do "$do/analysis/heterogeneous_treatment_coarsecat_controls.do" 

do "$do/analysis/composition_by_institution.do" 

do "$do/analysis/literature_effects.do" 

do "$do/analysis/observable_changes.do" 
do "$do/analysis/effects_decomposition.do" 
do "$do/analysis/oster_bounds.do" 
do "$do/analysis/sorting_index.do" 

do "$do/analysis/district_specific_effects_test.do" 
do "$do/analysis/reconciliation_testscores.do" 

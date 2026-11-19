clear all
macro drop _all

*Define directories
	global root "C:/Users/jabef/Desktop/FU Job/Prof.Marcus/Python_Scraper/Oster_Methode/Reproduction/Success/Beach(2022)"
		global data_dir "$root/Raw_Data"
		global rep_dir "$root/Analysis"
		global temp_dir "$root/Temp"
		global results "$root/Results/"

*Data preparation
	run "$root/Processing/Canada_Aggregate_Prep_FE.do"
	run "$root/Processing/Canada_birth_panel.do"
	
	run "$root/Processing/US_Micro_Prep.do"
	run "$root/Processing/SA_DivisionXperiod.do"
	
	run "$root/Processing/England_and_Wales_Aggregate_Prep_File.do"
	run "$root/Processing/EW_Map_Prep.do"
	run "$root/Processing/F20_T29_Panel.do"
	
	

*Introduction: Motivating Time Series
	* Figure 1: E&W Time series 
	run "$rep_dir/F1_ew_national_time_series.do"
	
*Canada Section
	*Figure 2: Canada time series
	run "$rep_dir/F2_Canada_time_series.do"
	
	*Table 1: Canada Main results (aggregate date)
	run "$rep_dir/T1_Canada_agg_main.do"

	*Table 2 Canada Microdata
	run "$rep_dir/T2_Canada_Microdata.do"
	
	
*England and Wales Section	
	* Figure 3: BNA Article Article Keyword Time Series
	run "$rep_dir/F3_keyword_time_series.do"
		
	* Figure 4: Newspaper.com Article Keyword Time Series
	run "$rep_dir/F4_US_keyword_time_series.do"	

	* Table 3: Balance
	run "$rep_dir/T3_EW_Balance.do"
		
	* Figure 5: Newspaper DD-Figure
	run "$rep_dir/F5_EW_DD_Directories.do"	
		
	* Table 4: Difference-in-Differences results for England and Wales
	run "$rep_dir/T4_EW_DD.do"
		
	* Figure 6: Directories Falsification Exercise
	run "$rep_dir/F6_EW_Falsification_DD.do"
		
	* Table 5: Newspaper Exposure IV
	run "$rep_dir/T5_EW_IV.do"
	
*** Appendix Material
	*Figure 7: Longer Birth Rate Series
	run "$rep_dir/F7_EW_births_long.do"
		
	*Figure 8: England & Wales and Scotland (Mitchell Series)
	run "$rep_dir/F8_EW_Scotland_graph.do"
	
	*Figure 9: England, & Wales and Scotland (Mitchell Series)
	run "$rep_dir/F9_England_France_Germany.do"
	
	*Figure 10: Other European Fertility (Mitchell Series)
	run "$rep_dir/F10_Other_Euro_Fertility.do"
	
	*Table 6: Canada Sum Stats
	run "$rep_dir/T6_Canada_agg_sum_stats.do"
	
	*Table 7: Canada Microdata Sum Stats
	run "$rep_dir/T7_Canada_micro_sum_stats.do"
	
	*Table 8: Occupational and Whipple comparisons (British vs non-British Canadians)	
	run "$rep_dir/T8_Canada_origin_comparisons.do"
	
	*Table 9: Canada (county) Robustness
	run "$rep_dir/T9_Canada_agg_robust.do"
	
	*Table 10: Canada (county) Spatial SE Robustness
	run "$rep_dir/T10_Canada_spatial_SE.do"
	
	*Table 11: Canada (micro) Robustness
	run "$rep_dir/T11_Canada_micro_robust.do"

	*Tables 12 and 13: US Sum Stats and tabulations
	run "$rep_dir/T12_T13_US_Sum_Stats.do"
	
	*Table 14: US Microdata Main Analysis
	run "$rep_dir/T14_US_Microdata.do"
	
	*Table 15: US Microdata Robustness
	run "$rep_dir/T15_US_microdata_windows.do"
	
	*Table 16: South Africa Summary Statistics
	run "$rep_dir/T16_SA_Summary_Stats.do"
	
	*Table 17: South Africa Main Results
	run "$rep_dir/T17_SA_main_results.do"
	
	*Table 18: South Africa Spatial SE Robustness
	run "$rep_dir/T18_SA_Spatial_SE.do"
	
	*Figure 11: Google-Ngrams Key Names
	*No replication code. This figure is a screenshot of the raw data.

	*Figure 12: Google-Ngrams Family Planning Phrases
	*No replication code. This figure is a screenshot of the raw data.

	*Figure 13: Google-Ngrams Fruits of Philosophy (British v American English)
	*No replication code. This figure is a screenshot of the raw data.

	*Figure 14: Newspaper Mentions by Database
	run "$rep_dir/F14_newspaper_databases.do"
	
	*Figure 15: Map of the newspaper directory data
	run "$rep_dir/F15_EW_news_maps.do"
	
	*Table 19 and 20: Selection into BNA database
	run "$rep_dir/T19_T20_BNA_Predictors.do"
	
	*Figure 16: Example Article
	*No replication code. This figure is a screenshot of an actual article.
	
	*Figure 17: Map of BNA Newspaper Coverage
	run "$rep_dir/F17_BNA_map.do"
	
	*Table 21: Article Classification
	run "$rep_dir/T21_BNA_classification.do"
	
	*Table 22: Article Content Keywords
	
	
	*Table 23/Table 24: England and Wales Summary Statistics
	run "$rep_dir/T23_T24_EW_Sum_Stats.do"
	
	*Table 25: England and Wales with alt opening windows
	run "$rep_dir/T25_EW_Alt_Windows.do"
	
	*Table 26: England and Wales Spatial SE adjustments
	run "$rep_dir/T26_EW_Spatial_SE.do"
	
	*Table 27: England and Wales control robustness
	run "$rep_dir/T27_EW_Robust.do"
	
	*Figure 18: England and Wales annual event study
	run "$rep_dir/F18_EW_Event_Study.do"
	
	*Figure 19: England and Wales Births and Marriages AR Model
	run "$rep_dir/F19_EW_Marriages_Births_AR.do"
	
	*Table 28: England and Wales: Marriages
	run "$rep_dir/T28_EW_Marriages.do"
	
	*Figure 20: Births with Marriage counterfactual
	run "$rep_dir/F20_EW_Mar_Counterfactual.do"
	
	*Table 28: England and Wales DD accounting for marriage effects
	run "$rep_dir/T29_EW_Mar_Counterfactual.do"
	

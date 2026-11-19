clear all
set more off
set seed 2112

* ------- Global Directory Setup (Mirrors Enclave) -------

global main "C:\Users\jabef\Desktop\FU Job\Prof.Marcus\Python_Scraper\Oster_Methode\Reproduction\Success\Stansburry(2026)"

global data "$main/Data" 

global tables 		"$main/Tables"
global figures 		"$main/Figures"

global scripts 		"$main/Scripts" 
global synth_data 	"$main/Scripts/1_Synthetic Data"
global cleaning 	"$main/Scripts/2_Cleaning"
global main_scripts "$main/Scripts/3_Main"
global survey		"$main/Survey/Scripts"
global esg 			"$data/ESG_Reports"

global RAWROOT      "$data/raw_synth"
global DATA         "$data/data"
global TEMP         "$data/temp"
global RANK         "$data/rank"
global CENT         "$data/cent"
global DESC         "$data/desc"
global INFLATE 		"$data/inflate"
global CPS 		    "$data/cps"
global NSCG 		"$data/nscg"

* ------- Install Required Packages -------
program main
    *** Required packages for Stansbury & Rodriguez 2025 below ***
    local ssc_packages "shp2dta distinct coefplot egenmore erepost estout geodist ftools reghdfe regsave texdoc"

    foreach pkg in `ssc_packages' {
        * attempt to uninstall 
        capture ado uninstall `pkg'

        * force reinstall from SSC
        dis "Reinstalling `pkg'"
        ssc install `pkg', replace
    }
end

* Install grc1leg from Stata:
net install grc1leg, from(http://www.stata.com/users/vwiggins)

main

* 1. Generate Synthetic Datasets ----

run "$synth_data/0_create_datasets.do"

* 2. Run Cleaning Code Over Synthetic Datasets  --------------
* Note: These are mostly identical to our actual scripts. Any differences to support the synthetic dataset are noted by a comment within the scripts

run "$cleaning/1.clean_institutions.do"

run "$cleaning/2.matchclean_newwos.do"

run "$cleaning/3.clean_NSF.do"

run "$cleaning/4.import_seddrf_2021.do"

run "$cleaning/5.import_sdr.do"

run "$cleaning/6.match_sdr_drf_idonly.do"

run "$cleaning/7.clean_seddrf_2021.do"

run "$cleaning/8.clean_sdr_drf.do"

run "$cleaning/9.centroid_clean.do"

run "$cleaning/10.tenure_decision_data.do" //some synthetic changes here, see Scripts_Enclave/Cleaning for original

run "$cleaning/11.tenure_withpubs_data.do"

* Run cleaning that is synthetic data specific (aligns variables post-hoc)

run "$cleaning/12.align_synth_data.do" 

* 3. Run Script Generation Code Over Cleaned Datasets  -------

* ----- Main Tables -----

* Table 1

run "$main_scripts/summary_stats.do"

* Table 2

run "$main_scripts/main_outcomes.do"

* Table 3

run "$main_scripts/pipeline_table.do"

* Table 4 and 5

run "$main_scripts/outcomes_research_controls.do" 

* Table 6

run "$main_scripts/coauthor_analysis.do" //Panel A
run "$main_scripts/new_coauthor_analysis_withresearch.do" //Panel B

* Table 7

run "$main_scripts/nsf_analysis.do"

* Table 8

run "$main_scripts/citations_conditional_on_publication.do"

* Table 9

run "$main_scripts/other_sectors.do"

* ----- Main Figures -----

* Figure 1

run "$main_scripts/esg_reports_firms.do"

* Figure 2

run "$main_scripts/edpar_shares.do"

* Figure 3

run "$main_scripts/tenure_withresearch_update.do" 

* Figure 4

run "$main_scripts/predict_rank_residuals.do"

* Figure 5

run "$main_scripts/industry_overtime.do"

* ----- Appendix Figures -----

* Appendix Figure A1

run "$main_scripts/mechhetero_plottable.do"

* Appendix Figure A2

run "$main_scripts/main_outcomes_figure.do" 

* Appendix Figure A3

run "$main_scripts/jobsatisfaction.do"

* ----- Appendix Tables -----

* Appendix Table A1

run "$main_scripts/Shares of Graduate Degrees - NSCG.do" 

* Appendix Table A2

run "$main_scripts/Income by Edu.do"

* Appendix Table A3

run "$main_scripts/sector_choice.do"

* Appendix Table A4 and A5

run "$main_scripts/tenure_full_outcomes.do" 

* Appendix Table A6

run "$main_scripts/research_output.do" 

* ----- Robustness Figures ----- 

* Robustness Figure B1 and B2

run "$main_scripts/new_robustness.do"

* ----- Robustness Tables -----

* Robustness Table B1

run "$main_scripts/outcomes_phd_dec_fe.do"

* Robustness Table B2

run "$main_scripts/alt_paredu_firstgen_anygrad.do"

* Robustness Table B3

run "$main_scripts/outcomes_whiteusbornonly.do"

* Robustness Table B4

run "$main_scripts/outcomes_us_nonus_born_only.do"

* Robustness Table B5 and B6

// These are also created by "$main_scripts/new_robustness.do" which is run above

* Robustness Table B7

// This is created by "$main_scripts/table3.do" 

* ----- Additional Discussions Tables -----

* Additional Discussions Table A1 

run "$main_scripts/baseline_bounding.do"

* Additional Discussions Table A2

// Made in "Oster Correction - Appendix Table D2 - Final.xlsx" in the Scripts folder

* ----- Survey Cleaning, Analysis, Figures and Tables -----

** run "$survey/0_survey_set_up"

// We have provided the scripts here for our analysis of the survey data. Due to our agreement when running the survey that we were only going to make public aggregated data and not individual answers available, we do not provide any actual data here. We do provide the tables and figures derived from these data in the Survey/Scripts/3_Output file.

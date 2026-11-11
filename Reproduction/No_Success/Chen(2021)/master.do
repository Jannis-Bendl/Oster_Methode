/*****************************************************************************************
PURPOSE: Master file to prepapre analysis data and create tables and figures

NOTES: See ReadMe.pdf for detailed descriptions
*****************************************************************************************/
version 14
clear 
set more off
set matsize 11000
set maxvar 32467

global WORKING "" // set the working directory here 
global INPUT "${WORKING}/INPUT" 
global INPUT_MDPPAS "${WORKING}/MDPPAS" 
global INPUT_PhyCom "${WORKING}/PhyCom" 
global OUTPUT "${WORKING}/OUTPUT"
global RESULTS "${WORKING}/RESULTS"
global CODES "${WORKING}/CODES"

*-------------------------------*
* I. Buidling data
*-------------------------------*
*	A. Prepare datasets 	
	do "${CODES}/gen_01_data_preparation.do"
	
*	B. Identify physicians and proceduralists
	do "${CODES}/gen_02_identify_doctors.do"	
	
*	C. Generate shared/individual work experience
	do "${CODES}/gen_03_experience.do"
	
*	D. Identify doctor characteristcis
	do "${CODES}/gen_04_doctor_characteristics.do"
	
*	E. Generate analysis datasets
	do "${CODES}/gen_05_merge.do"
	do "${CODES}/gen_06_generate_outcomes_controls.do"
	do "${CODES}/gen_07_analysisdata.do"
	

*-------------------------------*
* II. Analysis	
*-------------------------------*
*	A. Figures 1-4
 	do "${CODES}/analysis_01_figure_1-4.do"
	
*	B. Tables 1-7
 	do "${CODES}/analysis_02_table_1-7.do"
	
*	C. Appendix Figures
 	do "${CODES}/analysis_03_figure_A1-A5.do"
	
*	D. Appendix Tables
 	do "${CODES}/analysis_04_table_A1-A5.do"
 	do "${CODES}/analysis_05_table_A6-A10.do"
 	do "${CODES}/analysis_06_table_A11-A15.do"
 	do "${CODES}/analysis_07_table_A16-A22.do"
		
	




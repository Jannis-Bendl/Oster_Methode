**************************************************************************************************************************************
*****                                                                                                                            *****
*****                                                   When Harry Fired Sally                                                   *****
*****                                                         Analysis                                                           *****
*****                                                                                                                            *****
**************************************************************************************************************************************

***********************
****    CONTENTS   ****
***********************
*1) Summary Statics
*2) Data Analysis
*3) Appendix Material


**************************************************************************************************************************************

**************************************************************************************************************************************
*****                                                                                                                            *****
*****                                                Section 1: Summary Statistics                                               *****
*****                                                                                                                            *****
**************************************************************************************************************************************

***********************
****    CONTENTS   ****
***********************
*Section 1: Summary Statistics 
*	1.1: Import Data
*	1.2: Summary Statistics

**************************************************************************************************************************************
*******************************
****    1.1 Import Data    ****
*******************************
global BASE "E:\Dropbox\BrokerCheck by Gender\Final_Submission_Files"
global DATA "$BASE\Source_Data"
cd "$BASE\Results"
use "$DATA\when_harry_fired_sally_base_data.dta", clear


**************************************************************************************************************************************
**************************************
****    1.2 Summary Statistics    ****
**************************************
*********************
****   Table 1   ****
*********************
*1.3(a) Summary Characteristics: Table 1(a)
gen curr= (reg1!="Not Licensed")
su exp curr dy_i ia dt_i dy_guilty_i dt_guilty_i ts_series63 ts_series7 ts_series6 ts_series66 ts_series65 ts_series24 ts_ia num_qual aum production high_rating if male==1
su exp curr dy_i ia dt_i dy_guilty_i dt_guilty_i ts_series63 ts_series7 ts_series6 ts_series66 ts_series65 ts_series24 ts_ia  num_qual aum production high_rating if female==1
*1.3(b) Misconduct: Table 1(b)
 su dt_guilty_i if male==1
su dy_guilty_i if male==1
su dt_guilty_i if female==1
su dy_guilty_i if female==1
su dy_custdist_settled_i dy_employmentsep_i dy_regulatory_final_i dy_criminal_finaldisp_i   dy_custdist_award_i dy_civil_final_i dy_guilty_i if female==1
su dy_financial_final_i dy_custdist_denied_i dy_judgment_lien_i dy_custdist_closed_i dy_financial_pending_i dy_custdist_pending_i dy_custdist_withdrawn_i dy_criminal_pending_i dy_investigation_i dy_regulatory_pending_i dy_civil_pending_i dy_custdist_final_i dy_custdist_dismissed_i  dy_civilbond_i  dy_regulatory_onappeal_i dy_criminal_onappeal_i dy_civil_onappeal_i dy_i if female==1
su dy_custdist_settled_i dy_employmentsep_i dy_regulatory_final_i dy_criminal_finaldisp_i   dy_custdist_award_i dy_civil_final_i dy_guilty_i if male==1
su dy_financial_final_i dy_custdist_denied_i dy_judgment_lien_i dy_custdist_closed_i dy_financial_pending_i dy_custdist_pending_i dy_custdist_withdrawn_i dy_criminal_pending_i dy_investigation_i dy_regulatory_pending_i dy_civil_pending_i dy_custdist_final_i dy_custdist_dismissed_i  dy_civilbond_i  dy_regulatory_onappeal_i dy_criminal_onappeal_i dy_civil_onappeal_i dy_i if male==1
su dt_custdist_settled_i dt_employmentsep_i dt_regulatory_final_i dt_criminal_finaldisp_i   dt_custdist_award_i dt_civil_final_i dt_guilty_i if female==1
su dt_financial_final_i dt_custdist_denied_i dt_judgment_lien_i dt_custdist_closed_i dt_financial_pending_i dt_custdist_pending_i dt_custdist_withdrawn_i dt_criminal_pending_i dt_investigation_i dt_regulatory_pending_i dt_civil_pending_i dt_custdist_final_i dt_custdist_dismissed_i  dt_civilbond_i  dt_regulatory_onappeal_i dt_criminal_onappeal_i dt_civil_onappeal_i dt_i if female==1
su dt_custdist_settled_i dt_employmentsep_i dt_regulatory_final_i dt_criminal_finaldisp_i   dt_custdist_award_i dt_civil_final_i dt_guilty_i if male==1
su dt_financial_final_i dt_custdist_denied_i dt_judgment_lien_i dt_custdist_closed_i dt_financial_pending_i dt_custdist_pending_i dt_custdist_withdrawn_i dt_criminal_pending_i dt_investigation_i dt_regulatory_pending_i dt_civil_pending_i dt_custdist_final_i dt_custdist_dismissed_i  dt_civilbond_i  dt_regulatory_onappeal_i dt_criminal_onappeal_i dt_civil_onappeal_i dt_i if male==1
tab dt_guilty if male==1
tab dt_guilty if female==1
su damages* if female==1 & damages>0, det
su damages* if male==1 & damages>0, det
tabstat dt_guilty_i if male==1 & exp<21 & exp>1, by(exp)
tabstat dt_guilty_i if female==1 & exp<21 & exp>1, by(exp)
tabstat leave_or_switch if male==1 & exp<21 & exp>1, by(exp)
tabstat leave_or_switch if female==1 & exp<21 & exp>1, by(exp)
su dt_guilty_i if male==1
su dt_guilty_i if female==1
su dt_guilty_i if male==1 & num_states>3
su dt_guilty_i if female==1& num_states>3
su dt_guilty_i if male==1 & ts_ia==1
su dt_guilty_i if female==1 & ts_ia==1

*********************
****   Table 3   ****
*********************
su leave_or_switch if dy_guilty_i==0 & female==1
su leave if dy_guilty_i==0 & female==1 & leave_or_switch==1
su switch if dy_guilty_i==0 & female==1 & leave_or_switch==1
su leave_or_switch if dy_guilty_i==1 & female==1
su leave if dy_guilty_i==1 & female==1 & leave_or_switch==1
su switch if dy_guilty_i==1 & female==1 & leave_or_switch==1
su leave_or_switch if dy_guilty_i==0 & male==1
su leave if dy_guilty_i==0 & male==1 & leave_or_switch==1
su switch if dy_guilty_i==0 & male==1 & leave_or_switch==1
su leave_or_switch if dy_guilty_i==1 & male==1
su leave if dy_guilty_i==1 & male==1 & leave_or_switch==1
su switch if dy_guilty_i==1 & male==1 & leave_or_switch==1


**************************************************************************************************************************************

**************************************************************************************************************************************
*****                                                                                                                            *****
*****                                                   Section 2: Data Analysis                                                 *****
*****                                                                                                                            *****
**************************************************************************************************************************************

***********************
****    CONTENTS   ****
***********************
*Section 2: Data Analysis
*	2.1: Regression Tables
*	2.2: Figures

**************************************************************************************************************************************
************************************
****    2.1 Regression Tables   ****
************************************

*******************************
*** Table 2(a): Misconduct  ***
*******************************
gen dep_var= dy_guilty_i*100 
local c_date = c(current_date)
local reg_table_disc = "table_2a_misc_by_gender"+subinstr("`c_date'", " ", "_", .)
reg dep_var female,  cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var female ts_series* exp ,   cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe   dep_var female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe   dep_var female ts_series* exp,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe   dep_var female ts_series* exp if  high_rating!=.	&ln_aum!=.	 &ln_production!=.,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe    dep_var female  high_rating	ln_aum	ln_production ts_series*  exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*******************************
*** Table 2(b): Settlements  ***
*******************************
gen ln_dam =ln(damages)
local c_date = c(current_date)
local reg_table_dam = "table_2b_gender_firm_disc_damages"+subinstr("`c_date'", " ", "_", .)
reg ln_dam  female if damages_year>0 & dy_guilty_i==1, cluster(firm_fe)
outreg2 using `reg_table_dam', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
xi: reg ln_dam  female   ts_series* exp if damages_year>0 & dy_guilty_i==1, cluster(firm_fe)
outreg2 using `reg_table_dam', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe ln_dam  female   ts_series* exp if damages_year>0 & dy_guilty_i==1, absorb(firm_fe year fips) cluster(firm_fe)
outreg2 using `reg_table_dam', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
cdfplot ln_dam if damages>0 & damages<4975000 & ln_dam>=5, by(gender_chk)  opt1( lc(gray black) ) xtitle("ln(Settlements)")  legend(label(1 "Female Advisers") label(2 "Male Advisers")) bgcolor(white) graphregion(color(white) ) ylab(,nogrid) legend(region(lcolor(white))) legend(ring(0) pos(10) cols(1))

***************************************
*** Table 4: Employment Separation ***
***************************************
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_4_leave_or_switch_by_gender"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i*  female,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var dy_guilty_i*   female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i*   female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i*   female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i*  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i female exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe    dep_var dy_guilty_i*  female ts_series*  exp if  high_rating!=.	&ln_aum!=.	 &ln_production!=.,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe    dep_var dy_guilty_i*   female  high_rating	ln_aum	ln_production ts_series*  exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe    dep_var dy_guilty_i*  female  high_rating*	ln_aum*	ln_production* ts_series*  exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
*Oster Test
reghdfe  dep_var dy_guilty_i* dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  female  exp,  absorb(job_id) cluster(firm_fe)
areg  dep_var dy_guilty_i*  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i female   exp if e(sample),  absorb(job_id) 
psacalc beta dy_guilty_i_f, rmax(0.52) mcontrol(female  dy_guilty_i)

********************************
*** Table 6: New Employment  ***
********************************
replace dep_var = switch*100
local c_date = c(current_date)
local reg_table_disc = "table_6_switch_by_gender"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i*   female if leave_or_switch==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var dy_guilty_i*   female ts_series* exp if leave_or_switch==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i*   female ts_series* exp if leave_or_switch==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i*   female ts_series* exp if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i*   dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i female ts_series* exp if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', auto(2)  ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
*Oster Tetsts
reghdfe  dep_var dy_guilty_i* dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  female ts_series* exp if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
areg  dep_var dy_guilty_i* dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  female exp if e(sample),  absorb(job_id) 
psacalc beta dy_guilty_i_f, rmax(0.60) mcontrol(female dy_guilty_i)

**********************************************************
*** Table 7(a): Firm Heterogeneity: Managers and Execs ***
**********************************************************
replace dep_var = leave_or_switch*100
bysort fe_id: egen female_ts24 = sum(female*ts_series24)
bysort fe_id: egen firm_ts24 = sum(ts_series24)
gen female_pct_24 = female_ts24/firm_ts24
gen female_pct_24_female= female_pct_24*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(female_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(female_pct_24)
replace dep_var = leave_or_switch*100 
local c_date = c(current_date)
local reg_table_disc = "table_7a_firm_mgmt_and_execs_"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i* female_pct_24 female_pct_24_female    female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24 female_pct_24_female   female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24 female_pct_24_female   female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24 female_pct_24_female   female exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
drop dy_guilty_i_f_f dy_guilty_i_n_f 
gen f_m = owner_female_pct
gen f_m_female = owner_female_pct*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(owner_female_pct)
gen dy_guilty_i_n_f = dy_guilty_i*(owner_female_pct)
reg dep_var dy_guilty_i* f_m f_m_female   female ts_series* exp if year==2014,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* f_m f_m_female female   ts_series* exp  if year==2014,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* f_m f_m_female female   exp  if year==2014,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* f_m f_m_female female    exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i if year==2014,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)


*************************************************
*** Table 7(b): Firm Heterogeneity - Jr Women ***
*************************************************
*Interact miscondcut with jr women
drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
bysort fe_id: egen jr_female=sum(female*exp<3)
bysort fe_id: egen jr_brokers=sum(exp<3)
gen pct_jr_female= jr_female/jr_brokers
gen pct_jr_female_female = pct_jr_female*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(pct_jr_female)
gen dy_guilty_i_n_f = dy_guilty_i*(pct_jr_female)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_7b_firm_het_jr_female_pct"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i* pct_jr_female pct_jr_female_female   female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female   female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female   female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female   female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
gen dy_guilty_i_f_f2 = female*dy_guilty_i*(female_pct_24)
gen dy_guilty_i_n_f2 = dy_guilty_i*(female_pct_24)
reg dep_var dy_guilty_i* pct_jr_female pct_jr_female_female female_pct_24 female_pct_24_female female ts_series* exp  ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female female_pct_24 female_pct_24_female female ts_series* exp  ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female female_pct_24 female_pct_24_female female  exp  ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* pct_jr_female pct_jr_female_female female_pct_24 female_pct_24_female female ts_series* exp  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)


*******************************************************
*** Table 8: Firm Heterogeneity - Sexual Harassment ***
*******************************************************
drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
gen firm_harassment = (case_sex_harass)>0
gen firm_harassment_f = firm_harassment*female
gen firm_disc = (case_disc)>0
gen firm_disc_f = firm_disc*female
gen dy_guilty_i_f_f2 = female*dy_guilty_i*(firm_disc)
gen dy_guilty_i_n_f2 = dy_guilty_i*(firm_disc)
gen dy_guilty_i_f_f1 = female*dy_guilty_i*(firm_harassment)
gen dy_guilty_i_n_f1 = dy_guilty_i*(firm_harassment)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_8_firm_harassment_"+subinstr("`c_date'", " ", "_", .)
su dep_var if e(sample)
reg dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f1 dy_guilty_i_n_f1 firm_harassment firm_harassment_f   female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f1 dy_guilty_i_n_f1 firm_harassment firm_harassment_f   female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f1 dy_guilty_i_n_f1 firm_harassment firm_harassment_f   female exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f1 dy_guilty_i_n_f1 firm_harassment firm_harassment_f   female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reg dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f* dy_guilty_i_n_f*  firm_disc firm_disc_f  firm_harassment_f firm_harassment female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f* dy_guilty_i_n_f*  firm_disc firm_disc_f  firm_harassment_f firm_harassment female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f* dy_guilty_i_n_f*  firm_disc firm_disc_f  firm_harassment_f firm_harassment  female ts_series* exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f* dy_guilty_i_n_f*  firm_disc firm_disc_f  firm_harassment_f firm_harassment  female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

***********************************************
*** Table 9(a): Minority Males - Misconduct ***
***********************************************
* Import Ethnicity Data
gen dy_guilty_i_eth_african = dy_guilty_i*eth_african
gen dy_guilty_i_eth_hispanic = dy_guilty_i*eth_hispanic
replace dep_var=dy_guilty_i*100
local c_date = c(current_date)
local reg_table_disc = "table_9a_ethnicity_misconduct"+subinstr("`c_date'", " ", "_", .)
reg dep_var eth_african  eth_hispanic  if male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var  eth_african  eth_hispanic   ts_series* exp if male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe   dep_var  eth_african  eth_hispanic  ts_series* exp if male==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe   dep_var  eth_african  eth_hispanic  ts_series* exp if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*********************************************
*** Table 9(b): Minority Males - Turnover ***
*********************************************
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_9b_leave_or_switch_ethnicity"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp if male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)    alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp if male==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)    alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)    alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic exp  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)    alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace dep_var = switch*100
reg dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp  if leave_or_switch==1 & male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp  if leave_or_switch==1 & male==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic ts_series* exp  if leave_or_switch==1 & male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i dy_guilty_i_eth_african eth_african  dy_guilty_i_eth_hispanic eth_hispanic  exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  if leave_or_switch==1 & male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*************************************************
*** Table 10(a): Firm Heterogeneity - African ***
*************************************************
drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
bysort fe_id: egen eth_african_ts24 = sum(eth_african*ts_series24)
gen eth_african_pct_24 = eth_african_ts24/firm_ts24
gen eth_african_pct_24_eth_african= eth_african_pct_24*eth_african
gen dy_guilty_i_f_f = eth_african*dy_guilty_i*(eth_african_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(eth_african_pct_24)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_10a_firm_het_african"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i dy_guilty_i_eth_african dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_eth_african   eth_african if male==1, cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var  dy_guilty_i dy_guilty_i_eth_african dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_eth_african  eth_african ts_series* exp   if male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var  dy_guilty_i dy_guilty_i_eth_african dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_eth_african  eth_african ts_series* exp   if male==1,   absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var  dy_guilty_i dy_guilty_i_eth_african dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_eth_african  eth_african ts_series* exp   if male==1,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_eth_african dy_guilty_i_f_f dy_guilty_i_n_f  eth_african_pct_24 eth_african_pct_24_eth_african eth_african ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

**************************************************
*** Table 10(b): Firm Heterogeneity - Hispanic ***
**************************************************
drop dy_guilty_i_f_f dy_guilty_i_n_f 
bysort fe_id: egen eth_hispanic_ts24 = sum(eth_hispanic*ts_series24)
gen eth_hispanic_pct_24 = eth_hispanic_ts24/firm_ts24
gen eth_hispanic_pct_24_eth_hispanic= eth_hispanic_pct_24*eth_hispanic
gen dy_guilty_i_f_f = eth_hispanic*dy_guilty_i*(eth_hispanic_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(eth_hispanic_pct_24)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_10b_firm_het_eth_hispanic"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i dy_guilty_i_eth_hispanic dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_eth_hispanic   eth_hispanic if male==1, cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var  dy_guilty_i dy_guilty_i_eth_hispanic dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_eth_hispanic  eth_hispanic ts_series*  exp   if male==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_eth_hispanic dy_guilty_i_f_f dy_guilty_i_n_f  eth_hispanic_pct_24 eth_hispanic_pct_24_eth_hispanic eth_hispanic ts_series* exp  if male==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_eth_hispanic dy_guilty_i_f_f dy_guilty_i_n_f  eth_hispanic_pct_24 eth_hispanic_pct_24_eth_hispanic eth_hispanic ts_series* exp  if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_eth_hispanic dy_guilty_i_f_f dy_guilty_i_n_f  eth_hispanic_pct_24 eth_hispanic_pct_24_eth_hispanic eth_hispanic ts_series* exp  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i if male==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
drop dy_guilty_i_f_f dy_guilty_i_n_f dy_guilty_i_eth_hispanic dy_guilty_i_eth_african

****************************
*** Table 11: Recidivism ***
****************************
gen fired= dy_guilty_i*leave_or_switch
gen prev_fired=0
xtset crd_num year
forvalues x=1/10{
	replace prev_fired = 1 if  (l`x'.fired==1)
}
gen prev_fired_f = prev_fired*female
replace dep_var = dy_guilty_i*100
local c_date = c(current_date)
local reg_table_disc = "table_11_rep_offenders_by_gender"+subinstr("`c_date'", " ", "_", .)
reg dep_var prev_dt_guilty_i*  female,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var prev_dt_guilty_i*  female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var prev_dt_guilty_i*  female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var prev_dt_guilty_i*  female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reg dep_var prev_dt_guilty_i* prev_fired* female,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reg dep_var prev_dt_guilty_i* prev_fired* female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var prev_dt_guilty_i* prev_fired* female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var prev_dt_guilty_i* prev_fired*  female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

**********************************************************************
*** Table 5 and A10: Employment Separation - 2016 and 2017 Sample  ***
**********************************************************************
preserve
	use "$DATA\when_harry_fired_sally_extended_data.dta", clear
	gen dep_var = leave_or_switch*100
	local c_date = c(current_date)
	local reg_table_disc = "table_5_productivity_differences_by_gender"+subinstr("`c_date'", " ", "_", .) +".tex"
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female   exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016 & high_rating!=., absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female  high_rating exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016 & high_rating!=., absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female   exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016 & ln_aum!=., absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female  ln_aum exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016, absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female   exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016 & ln_production!=., absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female  ln_production exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016, absorb(firmCRD fips )  cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female   exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016 & ln_production!=. &high_rating!=. & ln_aum!=., absorb(firmCRD fips ) cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe   dep_var dyGuiltyI dyGuiltyIFemale female  ln_production ln_aum high_rating exp tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  if year==2016, absorb(firmCRD fips ) cluster(firmCRD)
	outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
	replace dep_var = leave_or_switch*100 
	gen f_m = owner_female_pct
	gen f_m_female = owner_female_pct*female
	gen dy_guilty_i_f_f = female*dyGuiltyI*(owner_female_pct)
	gen dy_guilty_i_n_f = dyGuiltyI*(owner_female_pct)	
	gen dyGuiltyI_f = dyGuiltyI*female
	local c_date = c(current_date)
	local reg_table_disc = "table_a10_firm_het_sep_owner_pct_2016"+subinstr("`c_date'", " ", "_", .)
	reg dep_var dyGuiltyI dyGuiltyI_f dy_guilty_i* f_m  f_m_female female if year>=2015, cluster(firm_crd)
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
	reg dep_var dyGuiltyI dyGuiltyI_f dy_guilty_i* f_m f_m_female   female tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  exp if year>=2015,  cluster(firm_crd)
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe  dep_var dyGuiltyI dyGuiltyI_f dy_guilty_i* f_m f_m_female female   tsPdSeries7 tsPdSeries6 tsStSeries63 tsStSeries66 tsStSeries65 tsPrincipalSeries24  exp  if year>=2015,  absorb(fe_id) cluster(firm_crd)
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe  dep_var dyGuiltyI dyGuiltyI_f dy_guilty_i* f_m f_m_female female  exp  if year>=2015,  absorb(job_id) cluster(firm_crd)	
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
	reghdfe  dep_var dyGuiltyI dyGuiltyI_f dy_guilty_i* f_m f_m_female female  exp  dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  if year>=2015,  absorb(job_id) cluster(firm_crd)	
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
restore


**************************************************************************************************************************************
**************************
****    2.2 Figures   ****
**************************

*****************************************
*** Figure 1: Management Composition ****
*****************************************
graph set window fontface "Times New Roman"
hist female_pct_24, width(0.1) fcolor(black) xtitle("Percentage of Managers that are Female") bgcolor(white) graphregion(color(white) lwidth(large)) ylab(,nogrid) 
graph export "figure_1a.png", replace
graph export "figure_1a.eps", replace

hist f_m if year==2015, width(0.1) fcolor(black) xtitle("Percentage of Owners/Executives that are Female") bgcolor(white) graphregion(color(white) lwidth(large)) ylab(,nogrid) 
graph export "figure_1b.png", replace
graph export "figure_1b.eps", replace

****************************
*** Figure 2: Firm List ****
****************************
bysort firmid: egen female_misc = sum(female*dy_guilty_i)
egen firmid2 = group(firm_fe) if female_misc>=20
bysort firmid2: egen firm_misc2 = mean(dt_guilty_i)
forvalues x =1(1)44{
	gen int_`x'_firm_female = female*(firmid2==`x')
	gen int_`x'_firm_misc = dy_guilty_i*(firmid2==`x')
	gen inter_`x'_firm_misc_f = dy_guilty_i_f*(firmid2==`x')
}
local c_date = c(current_date)
local reg_table_disc = "firm_list_data_cluster"+subinstr("`c_date'", " ", "_", .)
areg  leave_or_switch ts_series* exp female int_* inter* if female_misc>=20,  absorb(firmid2) cluster(firmid2)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  excel replace
gen punishment_gap = .
forvalues x =1(1)44{
	replace punishment_gap=_b[inter_`x'_firm_misc_f] if firmid2==`x'
}

local c_date = c(current_date)
local reg_table_disc = "figure_2_firm_list"+subinstr("`c_date'", " ", "_", .)
areg  leave_or_switch ts_series* exp  female int_* inter* if female_misc>=20,  absorb(firmid2) 
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*)  excel replace
test inter_1_firm_misc_f=	inter_2_firm_misc_f=	inter_3_firm_misc_f=	inter_4_firm_misc_f=	inter_5_firm_misc_f=	inter_6_firm_misc_f=	inter_7_firm_misc_f=	inter_8_firm_misc_f=	inter_9_firm_misc_f=	inter_10_firm_misc_f=	inter_11_firm_misc_f=	inter_12_firm_misc_f=	inter_13_firm_misc_f=	inter_14_firm_misc_f=	inter_15_firm_misc_f=	inter_16_firm_misc_f=	inter_17_firm_misc_f=	inter_18_firm_misc_f=	inter_19_firm_misc_f=	inter_20_firm_misc_f=	inter_21_firm_misc_f=	inter_22_firm_misc_f=	inter_23_firm_misc_f=	inter_24_firm_misc_f=	inter_25_firm_misc_f=	inter_26_firm_misc_f=	inter_27_firm_misc_f=	inter_28_firm_misc_f=	inter_29_firm_misc_f=	inter_30_firm_misc_f=	inter_31_firm_misc_f=	inter_32_firm_misc_f=	inter_33_firm_misc_f=	inter_34_firm_misc_f=	inter_35_firm_misc_f=	inter_36_firm_misc_f=	inter_37_firm_misc_f=	inter_38_firm_misc_f=	inter_39_firm_misc_f=	inter_40_firm_misc_f=	inter_41_firm_misc_f=	inter_42_firm_misc_f=	inter_43_firm_misc_f=	inter_44_firm_misc_f 


**************************************************************************************************************************************

**************************************************************************************************************************************
*****                                                                                                                            *****
*****                                          Section 3: Material for Online Appendix                                           *****
*****                                                                                                                            *****
**************************************************************************************************************************************

***********************
****    CONTENTS   ****
***********************
*Section 3: Material for Online Appendix 
*	3.1: Regression Tables
*	3.2: Figures

**************************************************************************************************************************************
************************************
****    3.1 Regression Tables   ****
************************************

************************************************
*** Table A1: Merdian IQ Summary Statistics  ***
************************************************
su exp curr dy_i ia dt_i dy_guilty_i dt_guilty_i ts_series63 ts_series7 ts_series6 ts_series66 ts_series65 ts_series24 ts_ia num_qual leave_or_switch if male==1 & (ln_production!=. |ln_aum!=. | high_rating!=.)
su exp  curr dy_i ia dt_i dy_guilty_i dt_guilty_i ts_series63 ts_series7 ts_series6 ts_series66 ts_series65 ts_series24 ts_ia  num_qual leave_or_switch if female==1 & (ln_production!=. |ln_aum!=. | high_rating!=.)
su switch   if male==1 & (ln_production!=. |ln_aum!=. | high_rating!=.) & leave_or_switch==1
su switch   if female==1 & (ln_production!=. |ln_aum!=. | high_rating!=.) & leave_or_switch==1

******************************************
*** Table A2: Alternative Gender Data  ***
******************************************
gen iq_dy_guilty_i=female_iq*dy_guilty_i
local c_date = c(current_date)
local reg_table_disc = "table_a2_alternative_gender_data_robust"+subinstr("`c_date'", " ", "_", .)+".tex"
replace dep_var = dy_guilty_i*100
reghdfe dep_var female_iq ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
replace dep_var = leave_or_switch*100
reghdfe dep_var dy_guilty_i iq_dy_guilty_i  female_iq ts_series*  exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace dep_var = switch*100
reghdfe dep_var dy_guilty_i iq_dy_guilty_i female_iq ts_series* exp if leave_or_switch==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*****************************************************
*** Table A3: Misconduct by Firm Characteristics  ***
*****************************************************
replace dep_var= dy_guilty_i*100 
local c_date = c(current_date)
local reg_table_disc = "table_a3_misc_by_gender_by_char"+subinstr("`c_date'", " ", "_", .)
reghdfe   dep_var female exp   female_pct_24_female ,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe   dep_var female exp  pct_jr_female_female  ,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe   dep_var female exp    firm_harassment_f,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe   dep_var female exp  pct_jr_female_female female_pct_24_female firm_harassment_f,   absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex append

******************************
*** Table A4: Settlements  ***
******************************
preserve
	use "$DATA\settlements_data.dta", clear
	gen dep_var =pct_granted_w*100
	drop all_type_sum all_prod_sum
	local c_date = c(current_date)
	local reg_table = "table_a4_awards_vs_gender_"+subinstr("`c_date'", " ", "_", .)
	reghdfe dep_var female all_* ts_series63 ts_series7 ts_series6 ts_series24 ts_ia exp num_qual_o prior_disc ln_damages_r_w , absorb(year) vce(robust)
	outreg2 using `reg_table', ctitle(disc) drop(_I*) auto(2) alpha(0.01,0.05,0.10)  tex replace
	reghdfe dep_var female all_* ts_series63 ts_series7 ts_series6 ts_series24 ts_ia exp num_qual_o prior_disc  ln_damages_r_w, absorb(fips firm_id year) vce(robust)
	outreg2 using `reg_table', ctitle(disc) drop(_I*) auto(2)  alpha(0.01,0.05,0.10)  tex append
restore

*********************************************************
*** Table A5: Employment Separation - Within 2 Years  ***
*********************************************************
xtset crd year
gen leave_or_switch2 = (f.firm_crd!=firm_crd | f2.firm_crd!=firm_crd) if year<2014
replace dep_var = leave_or_switch2*100
local c_date = c(current_date)
local reg_table_disc = "table_a5_leave_or_switch_2_years_by_gender"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i*  female,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)   alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var dy_guilty_i*  female ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i*  female ts_series* exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i*  female  exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append

****************************************************
*** Table A7: Firm Heterogeneity - Weighted Exp ***
**************************************************** 
bysort fe_id: egen nbrokers_bf = sum(female*exp*(exp>0))
bysort fe_id: egen nbrokers_b = sum(exp*(exp>0))
gen female_pct_b= nbrokers_bf/nbrokers_b
gen female_pct_b_female= female*female_pct_b
gen dy_guilty_i_f_f = female*dy_guilty_i*(female_pct_b)
gen dy_guilty_i_n_f = dy_guilty_i*(female_pct_b)
replace dep_var = leave_or_switch*100 
local c_date = c(current_date)
local reg_table_disc = "table_a7_firm_het_female_pct"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i* female_pct_b female_pct_b_female   female, cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var dy_guilty_i* female_pct_b female_pct_b_female female ts_series* exp ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i* female_pct_b female_pct_b_female female ts_series* exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i* female_pct_b female_pct_b_female female exp ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var dy_guilty_i* female_pct_b female_pct_b_female female exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*********************************************************************
*** Table A8: Firm Characteristics and the Gender Punishment Gap  ***
*********************************************************************
cap drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
bysort fips firm_crd firm_name year: gen branch_size = _N
gen ln_branch_size = ln(branch_size)
bysort fe_id: egen firm_prev_misc = mean(prev_dt_guilty_i)
bysort fe_id: egen pct_ia= mean(ts_ia)
gen dy_guilty_i_f_f = female*dy_guilty_i*(female_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(female_pct_24)
gen dy_guilty_i_f_f2 = female*dy_guilty_i*(ln_branch_size )
gen dy_guilty_i_n_f2 = dy_guilty_i*(ln_branch_size)
gen ln_branch_size_female = ln_branch_size*female
replace dep_var=leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a8_firm_char"+subinstr("`c_date'", " ", "_", .)
reghdfe  dep_var dy_guilty_i* ts_series* ln_branch_size ln_branch_size_female  female_pct_24_female  female exp,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
foreach var of varlist firm_prev_misc pct_ia  affil form_corp form_ll form_partner{
	replace dy_guilty_i_f_f2 = female*dy_guilty_i*(`var')
	replace dy_guilty_i_n_f2 = dy_guilty_i*(`var')
	gen `var'_female = `var'*female
	reghdfe  dep_var dy_guilty_i* ts_series* `var' `var'_female female_pct_24 female_pct_24_female female exp,  absorb(fe_id) cluster(firm_fe)
	outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
}

*********************************************************************
*** Table A9: Firm Characteristics and the Gender Punishment Gap  ***
*********************************************************************
cap drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
bysort firm_crd firm_name  fips: egen female_ts24_2005 = sum(female*ts_series24*(year==2005))
bysort firm_crd firm_name  fips: egen firm_ts24_2005 = sum(ts_series24*(year==2005))
gen female_pct_24_2005 = female_ts24_2005/firm_ts24_2005
gen female_pct_24_female_2005= female_pct_24_2005*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(female_pct_24_2005)
gen dy_guilty_i_n_f = dy_guilty_i*(female_pct_24_2005)
replace dep_var = leave_or_switch*100 
local c_date = c(current_date)
local reg_table_disc = "table_a9_firm_het_sep_24_pct_2005"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i* female_pct_24_2005 female_pct_24_female_2005  female if year>2005, cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var dy_guilty_i* female_pct_24_2005 female_pct_24_female_2005    female ts_series* exp  if year>2005,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24_2005 female_pct_24_female_2005   female ts_series* exp  if year>2005,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24_2005 female_pct_24_female_2005   female exp  if year>2005,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var dy_guilty_i* female_pct_24_2005 female_pct_24_female_2005   female exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i  if year>2005,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

**********************************************
*** Table A11: Firm Heterogeneity - Hiring ***
**********************************************
xtset crd_num year
replace new_hire = firm_crd!=l.firm_crd if year!=2005
bysort fe_id: egen branch_hires= sum(new_hire)
bysort fe_id: egen female_branch_hires= sum(new_hire*female)
bysort fe_id: egen female_branch_hire_misc= sum(new_hire*female*prev_dt_guilty_i)
bysort fe_id: gen first_branch_obs = _n==1
egen firm_year= group(firm_name firm_crd year) 
gen pct_female_branch_hire_misc = female_branch_hire_misc/branch_hires
gen pct_female_branch_hires = female_branch_hires/branch_hires
replace dep_var = pct_female_branch_hire_misc*100
local c_date = c(current_date)
local reg_table_disc = "table_a11_branch_hiring_"+subinstr("`c_date'", " ", "_", .)
reg dep_var pct_female_branch_hires female_pct_24 if first_branch_obs==1, robust
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe dep_var pct_female_branch_hires female_pct_24  if first_branch_obs==1, absorb(year) vce(robust)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe dep_var pct_female_branch_hires female_pct_24 if first_branch_obs==1, absorb(year firm_fe)  vce(robust)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe dep_var pct_female_branch_hires female_pct_24 if first_branch_obs==1, absorb(year firm_year)  vce(robust)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

***********************************************************
*** Table A12a: Firm Heterogeneity - Placebo - Africans ***
***********************************************************
drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
gen eth_african_pct_24_female= eth_african_pct_24*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(eth_african_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(eth_african_pct_24)
gen dy2_guilty_i_f_f = female*dy_guilty_i*(female_pct_24)
gen dy2_guilty_i_n_f = dy_guilty_i*(female_pct_24)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a12a_firm_het_sep_24_placebo_african_pct"+subinstr("`c_date'", " ", "_", .)
//reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_female female, cluster(firm_fe)
//outreg2 using `reg_table_disc', ctitle(disc)  auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_african_pct_24 eth_african_pct_24_female female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
//reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f  dy2* female_pct_24 female_pct_24_female  eth_african_pct_24 eth_african_pct_24_female female, cluster(firm_fe)
//outreg2 using `reg_table_disc', ctitle(disc)  auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f  dy2* female_pct_24 female_pct_24_female  eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   dy2* female_pct_24 female_pct_24_female  eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   dy2* female_pct_24 female_pct_24_female  eth_african_pct_24 eth_african_pct_24_female female ts_series* exp ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   dy2* female_pct_24 female_pct_24_female  eth_african_pct_24 eth_african_pct_24_female female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

************************************************************
*** Table A12b: Firm Heterogeneity - Placebo - Hispanics ***
************************************************************
drop dy_guilty_i_f_f* dy_guilty_i_n_f* 
gen eth_hispanic_pct_24_female= eth_hispanic_pct_24*female
gen dy_guilty_i_f_f = female*dy_guilty_i*(eth_hispanic_pct_24)
gen dy_guilty_i_n_f = dy_guilty_i*(eth_hispanic_pct_24)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a12b_firm_het_sep_24_placebo_hispanic_pct"+subinstr("`c_date'", " ", "_", .)
reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reg dep_var dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f dy2* female_pct_24 female_pct_24_female    eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f dy2* female_pct_24 female_pct_24_female   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f dy2* female_pct_24 female_pct_24_female   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f dy_guilty_i_f_f dy_guilty_i_n_f dy2* female_pct_24 female_pct_24_female   eth_hispanic_pct_24 eth_hispanic_pct_24_female female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
drop dy_guilty_i_f_f dy_guilty_i_n_f  dy2*

************************************************************************************
*** Table A13: Employment Separation - Conditioning on Productivity and Damages  ***
************************************************************************************
gen ln_damages_yr = ln(damages_year+1)
replace ln_damages_yr = ln(1) if damages_year==.
gen no_damages=(damages_year==0) | (damages_year==.)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a13_referee_2_dam_and_productivity"+subinstr("`c_date'", " ", "_", .) +".tex"
reghdfe    dep_var dy_guilty_i* female ts_series*  exp  if  high_rating!=.	&ln_aum!=.	 &ln_production!=.,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*) tex replace
su dep_var if e(sample)
reghdfe    dep_var dy_guilty_i* female  high_rating ln_aum ln_production no_damages ln_damages_yr ts_series*  exp,  absorb(fe_id) cluster(firm_fe)
su dep_var if e(sample)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*) tex append

*****************************************
*** Table A14: Unauthorized Activity  ***
*****************************************
gen unauthor_misc_sample = 1
replace unauthor_misc_sample =0 if dy_guilty_i==1 & dy_unauthor_misc_i==0
gen dy_unauthor_misc_i_f= dy_unauthor_misc_i*female 
local c_date = c(current_date)
local reg_table_disc = "table_a14_unauthorized_activity"+subinstr("`c_date'", " ", "_", .)+".tex"
replace dep_var = leave_or_switch*100
reg dep_var dy_unauthor_misc_i* female if unauthor_misc_sample==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var  dy_unauthor_misc_i* female  ts_series* exp if unauthor_misc_sample==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var dy_unauthor_misc_i* female ts_series* exp if unauthor_misc_sample==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var dy_unauthor_misc_i* female exp if unauthor_misc_sample==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
* Unauthorized Trading: Industry Separation Regressions
replace dep_var = switch*100
reg dep_var  dy_unauthor_misc_i* female  if leave_or_switch==1 & unauthor_misc_sample==1 ,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reg dep_var  dy_unauthor_misc_i* female  ts_series* exp  if leave_or_switch==1 & unauthor_misc_sample==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var  dy_unauthor_misc_i* female  ts_series* exp if leave_or_switch==1 & unauthor_misc_sample==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe dep_var  dy_unauthor_misc_i* female   exp if leave_or_switch==1 & unauthor_misc_sample==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*******************************************************************************
*** Table A16:  Conditioning on Type of Misconduct - Employment Separation  ***
*******************************************************************************
*Creates columns (5)-(7) of Table A16
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_A16_leave_or_switch_by_gender_with_additional_controls"+subinstr("`c_date'", " ", "_", .) +".tex"
reghdfe  dep_var dy_guilty_i*  female  exp dy_fiduciary_misc dy_neg_misc dy_risk_misc dy_churn_misc dy_ins_misc dy_annuity_misc dy_stock_misc dy_bond_misc dy_mutual_misc dy_option_misc dy_unsuit_misc dy_mis_misc dy_unauthor_misc dy_material_misc dy_fee_misc dy_fraud_misc,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var dy_guilty_i*  female  exp pca_1-pca_10,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var dy_guilty_i*  female  exp top_category_*,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append

***************************************************************************
*** Table A17:  Conditioning on Type of Misconduct - Leave the Industry ***
***************************************************************************
*Creates columns (5)-(7) of Table A17
replace dep_var = switch*100
local c_date = c(current_date)
local reg_table_disc = "table_A17_leave_by_gender_with_additional_controls"+subinstr("`c_date'", " ", "_", .) +".tex"
reghdfe  dep_var dy_guilty_i*  female  exp dy_fiduciary_misc dy_neg_misc dy_risk_misc dy_churn_misc dy_ins_misc dy_annuity_misc dy_stock_misc dy_bond_misc dy_mutual_misc dy_option_misc dy_unsuit_misc dy_mis_misc dy_unauthor_misc dy_material_misc dy_fee_misc dy_fraud_misc if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var dy_guilty_i*  female  exp pca_1-pca_10 if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reghdfe  dep_var dy_guilty_i*  female  exp top_category_* if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append

***************************************
*** Table A18: Career Interruptions ***
***************************************
gen long_unemp_spell_dy_guilty_i = long_unemp_spell*dy_guilty_i
local c_date = c(current_date)
local reg_table_disc = "table_a18_long_unemp_spell_robust"+subinstr("`c_date'", " ", "_", .) +".tex"
replace dep_var = leave_or_switch*100
reghdfe dep_var dy_guilty_i*   long_unemp_spell female ts_series*  exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reghdfe dep_var dy_guilty_i*   long_unemp_spell* female ts_series*  exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace dep_var = switch*100
reghdfe dep_var dy_guilty_i* long_unemp_spell female ts_series* exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i if leave_or_switch==1 ,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe dep_var dy_guilty_i* long_unemp_spell* female ts_series*  exp dy_fiduciary_misc_i dy_neg_misc_i dy_risk_misc_i dy_churn_misc_i dy_ins_misc_i dy_annuity_misc_i dy_stock_misc_i dy_bond_misc_i dy_mutual_misc_i dy_option_misc_i dy_unsuit_misc_i dy_mis_misc_i dy_unauthor_misc_i dy_material_misc_i dy_fee_misc_i dy_fraud_misc_i if leave_or_switch==1,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

************************************************************************************
*** Table A19:  Job Turnover Among Advisers Who Eventually Engage in Misconduct  ***
************************************************************************************
bysort crd_num: egen dt_guilty_ever= max(dt_guilty_i)
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a19_future_misconduct"+subinstr("`c_date'", " ", "_", .)+".tex"
reg dep_var  female if dt_guilty_i==0 & dt_guilty_ever==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var   female  ts_series* exp if dt_guilty_i==0 & dt_guilty_ever==1,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var   female  ts_series* exp if dt_guilty_i==0 & dt_guilty_ever==1,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

***********************************************************
*** Table A20:  Job Turnover Among Firms that Downsize  ***
***********************************************************
tsset crd year
egen firm_id = group(firm_crd firm_name)
gen fwd_firm_size =f.firm_size if (f.firm_id==firm_id)
bysort firm_id year: egen f_firm_size = mean(fwd_firm_size)
gen firm_size_chg = f_firm_size/firm_size-1
gen downsize = firm_size_chg< -0.1
gen f_downsize = female*downsize
gen downsize_24 = downsize*ts_series24
gen downsize_num_qual = downsize*num_qual
replace dep_var = leave_or_switch*100
local c_date = c(current_date)
local reg_table_disc = "table_a20_leave_or_switch_by_gender_downsize"+subinstr("`c_date'", " ", "_", .)+".tex"
reg dep_var female f_downsize downsize,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
reg dep_var female f_downsize downsize ts_series* exp,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
reghdfe  dep_var female f_downsize downsize ts_series* exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace downsize = firm_size_chg< -0.05
replace f_downsize = female*downsize
reghdfe  dep_var female f_downsize downsize ts_series* exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace downsize = firm_size_chg< -0.25
replace f_downsize = female*downsize
reghdfe  dep_var female f_downsize downsize ts_series* exp,  absorb(job_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2) alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*****************************
*** Table A21: Experience ***
*****************************
local c_date = c(current_date)
local reg_table_disc = "table_21a_less_exp_dy_guilty_by_gender"+subinstr("`c_date'", " ", "_", .)+".tex"
replace dep_var = dy_guilty_i*100
reghdfe dep_var female ts_series*  exp  if exp<6,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
replace dep_var = leave_or_switch*100
reghdfe dep_var dy_guilty_i dy_guilty_i_f  female ts_series*  exp  if exp<6, absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace dep_var = switch*100
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f  female ts_series* exp  if leave_or_switch==1 & exp<6,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
local c_date = c(current_date)
local reg_table_disc = "table_21b_more_exp_dy_guilty_by_gender"+subinstr("`c_date'", " ", "_", .)+".tex"
replace dep_var = dy_guilty_i*100
reghdfe dep_var female ts_series*  exp if exp>=15, absorb(fe_id)cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
su dep_var if e(sample)
replace dep_var = leave_or_switch*100
reghdfe  dep_var  dy_guilty_i dy_guilty_i_f  female ts_series*  exp  if exp>=15,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)
replace dep_var = switch*100
reghdfe  dep_var  dy_guilty_i*  female ts_series*  exp if leave_or_switch==1 & exp>=15,  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
su dep_var if e(sample)

*******************************************************
*** Table A22:  Recidivism and Selection Correction ***
*******************************************************
reghdfe  leave_or_switch dy_guilty_i female exp ts_series* if dy_guilty_i==1 & male, absorb(firm_fe year fips) res(propens) cluster(firm_fe)
replace propens = leave_or_switch-propens if e(sample)
replace propens =. if  !e(sample)
reghdfe  leave_or_switch dy_guilty_i female exp ts_series* if dy_guilty_i==1 & female, absorb(firm_fe year fips) res(propens_f) cluster(firm_fe)
replace propens = leave_or_switch -propens_f if female & e(sample)
gen not_fired_year = year if dy_guilty_i*(leave_or_switch==0)
bysort crd_num: egen first_not_fired_year = min(not_fired_year)
gen first_not_fired_propens = propens if first_not_fired_year==year
bysort crd_num: egen f_p = mean(first_not_fired_propens)
gen prev_not_fired = year>first_not_fired_year
gen f_p2 = f_p^2
gen f_p3 = f_p^3
gen f_p4 = f_p^4
xtile quart = f_p, nq(4)
gen female_p = female*f_p
gen female_p2 = female*f_p2
rename f_perf temp_f_pref
local c_date = c(current_date)
local reg_table_disc = "table_a22_selection_correction_"+subinstr("`c_date'", " ", "_", .)+".tex"
replace dep_var = dy_guilty_i*100
reg dep_var female f_p*,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex replace
reg dep_var female exp ts_series* f_p* if prev_not_fired,  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append
reghdfe  dep_var female exp ts_series* f_p* if prev_not_fired,  absorb(firm_fe year fips) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc) auto(2)  alpha(0.01,0.05,0.10) drop(_I*)  tex append

*****************************
*** Table A23: Promotions ***
*****************************
gen promotion = (year==(year(dt_ts_series24)))
replace dep_var= promotion*100
local c_date = c(current_date)
local reg_table_disc = "table_a23_promotion_by_gender"+subinstr("`c_date'", " ", "_", .)+".tex"
reg  dep_var  dy_guilty_i*  female if dt_ts_series24==. | year<=year(dt_ts_series24),  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*) tex replace
reg dep_var dy_guilty_i*  female ts_series63 ts_series7 ts_series6 ts_ia  exp num_qual_o  if dt_ts_series24==. | year<=year(dt_ts_series24),  cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*) tex append
reghdfe   dep_var  dy_guilty_i*  female ts_series63 ts_series7 ts_series6 ts_ia exp num_qual_o  if dt_ts_series24==. | (year<=year(dt_ts_series24)),  absorb(fe_id) cluster(firm_fe)
outreg2 using `reg_table_disc', ctitle(disc)  alpha(0.01,0.05,0.10) drop(_I*) tex append


**************************************************************************************************************************************
**************************
****    3.2 Figures   ****
**************************

*********************************
*** Figure A1: Qualifications ***
*********************************
*Note: Figure is made in Excel Worksheet
su ts_series63 ts_series7 ts_series6 ts_ia ts_series24 if male ==1
su ts_series63 ts_series7 ts_series6 ts_ia ts_series24 if female ==1

**********************************
*** Figure A2: Damages by Year ***
**********************************
*Note: Figure is made in Excel Worksheet
preserve
	keep if female==1 & damages_year>0 & damages_year!=.
	keep damages_year
	outsheet damages_year using "damages_female.csv" , comma nolabel  replace
restore
preserve
	keep if male==1 & damages_year>0  & damages_year!=.
	keep damages_year
	outsheet damages_year using "damages_male.csv" , comma nolabel  replace
restore

**********************************
*** Figure A3: Annual Turnover ***
**********************************
*Note: Figure is made in Excel Worksheet
tabstat leave_or_switch if male==1, by(year)
tabstat leave_or_switch if female==1, by(year)

**********************************
*** Figure A4: Turnover by Exp ***
**********************************
*Note: Figure is made in Excel Worksheet
tabstat leave_or_switch if male==1 & exp<25, by(exp)
tabstat leave_or_switch if female==1& exp<25, by(exp)


*****************************
*** Figure A6: Recidivism ***
*****************************
*Note: Figure is made in Excel Worksheet
tab dt_guilty if male==1
tab dt_guilty if female==1

***********************************
*** Figure A7: Job Displacement ***
***********************************
*Note: Figure is made in Excel Worksheet
replace downsize = firm_size_chg< -0.1
tabstat leave_or_switch if male==1 & downsize==1, by(year)
tabstat leave_or_switch if female==1& downsize==1, by(year)

********************************************
*** Figure A5 and Table A6: Hazard Model ***
********************************************
preserve
	use "$DATA\hazard_data.dta", clear
	sts gen surv_f = s if dy_guilty_==0 & female==1 
	sts gen disc_guilty_surv_f =s if dy_guilty_==1  & female==1
	sts gen surv_m = s if dy_guilty_==0 & male==1 
	sts gen disc_guilty_surv_m =s if dy_guilty_==1  & male==1
	keep unemp_spell_len_no_mergers disc* surv*
	duplicates drop
	bysort unemp_spell_len_no_mergers: egen m_surv_f=max(surv_f)
	bysort unemp_spell_len_no_mergers: egen m_disc_guilty_surv_f=max(disc_guilty_surv_f)
	bysort unemp_spell_len_no_mergers: egen m_surv_m=max(surv_m)
	bysort unemp_spell_len_no_mergers: egen m_disc_guilty_surv_m=max(disc_guilty_surv_m)
	keep unemp_spell_len_no_mergers m_disc* m_surv*
	duplicates drop
	drop if unemp_spell_len_no_mergers==.
	outsheet using "figure_A5_data_gender_survival_functions.csv", comma replace
restore
preserve
	use "$DATA\hazard_data.dta", clear
	local c_date = c(current_date)
	local reg_table = "table_a6_hazard_model"+subinstr("`c_date'", " ", "_", .)
	xi: stcox dy_guilty_m dy_guilty_f female ts_series63 ts_series7 ts_series6 ts_ia ts_series24 exp num_qual_o 
	outreg2 using `reg_table', eform ctitle(failtime)  alpha(0.01,0.05,0.10) keep(dy_* female ts_series63 ts_series7 ts_series6 ts_ia  ts_series24 exp num_qual_o)  tex replace
	xi: stcox dy_guilty_m dy_guilty_f female ts_series63 ts_series7 ts_series6 ts_ia ts_series24 exp num_qual_o i.year
	outreg2 using `reg_table', eform ctitle(failtime)  alpha(0.01,0.05,0.10) keep(dy_* female ts_series63 ts_series7 ts_series6 ts_ia  ts_series24 exp num_qual_o)  tex append
restore


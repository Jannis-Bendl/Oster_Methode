source("../lib/r/Functions.R")

estimateStateFEs <- function(){
  data <- fread(get_filename_case("output/CapitalAllocation_reinsurerstateyear_joint.csv",case))

  data <- data[which(data$REINSSTATEDOMICILED != ""),]

  data <- data %>% group_by(REINSSTATEDOMICILED,year) %>% mutate(amount_reinsured_year = sum(amount_reinsured,na.rm=TRUE),
                                                                 num_captives = sum(num_captives,na.rm=TRUE))

  data_quantities <- fread(get_filename_case(path.symlink("input/SNL_Quantities.csv"),case))
  data_quantities <- data_quantities[which((data_quantities$lob == "Ordinary Life Insurance") & (!is.na(data_quantities$year))),]
  data_quantities <- data_quantities %>% group_by(year) %>% summarise(PremiumsAndAnnuityConsiderations_yr = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE),
                                                                      num_insurers = n_distinct(SNLSTATENTITYKEY,na.rm=TRUE))
  data_quantities$PremiumsAndAnnuityConsiderations_yr <- data_quantities$PremiumsAndAnnuityConsiderations_yr / 1000

  data_reserves = fread(get_filename_case("../CleanData/output/SNL_Financials_Group.csv",case))
  data_reserves = data_reserves %>% group_by(year) %>% summarise(RESERVESGROSS_yr = sum(RESERVESGROSS,na.rm=TRUE) / 1000)
  data <- merge(data,data_quantities,by=c("year"),all.x=TRUE)
  data <- merge(data,data_reserves,by=c("year"),all.x=TRUE)

  goods_type <- "num_captives"
  data$share <- (data$num_captives) / data$num_insurers
  data$share[which(data$share == 0 | data$share == 1)] = NA
  data <- data %>% group_by(year) %>% mutate(share_yr = sum(share,na.rm=TRUE))
  data$outside_good_share <- 1 - data$share_yr
  data$outside_good <- data$outside_good_share * data$num_insurers
  data$ln_s_st <- log(data$share)
  data$ln_s_0t <- log(data$outside_good_share)
  data$u_st <- data$ln_s_st - data$ln_s_0t

  data$kappa_f <- data$kappa_economic

  reg_u_st_kappa <- feols(u_st ~ kappa_f, data=data, vcov=~REINSSTATEDOMICILED)

  reg_kappa_u_st <- feols(kappa_f ~ u_st, data=data, vcov=~REINSSTATEDOMICILED)

  data$kappa_f_resid = resid(reg_kappa_u_st,na.rm = FALSE)
  data$kappa_f_resid[which(is.na(data$kappa_f_resid))] = 0
  data$kappa_f_hat = predict(reg_kappa_u_st,newdata=data[,c("year","REINSSTATEDOMICILED","u_st")],fixef=FALSE)
  data$kappa_f_predicted = data$kappa_f_hat + data$kappa_f_resid

  data$kappa_f = data$kappa_f_predicted

  reg_u_st_kappa <- feols(u_st ~ kappa_f | year, data=data, vcov=~REINSSTATEDOMICILED + year)

  saveRDS(reg_u_st_kappa, file=get_filename_case("output/reg_u_st_kappa_f.RDS",case))
  saveRDS(reg_kappa_u_st, file=get_filename_case("output/reg_kappa_u_st.RDS",case))

  fwrite(data, file=get_filename_case("output/CapitalAllocation/capital_rates_estimates_actual.csv",case))

}

get_u_st_from_kappa <- function(kappa_counterfactual){
  reg_u_st_kappa <- readRDS(get_filename_case("output/reg_u_st_kappa_f.RDS",case))

  kappa_counterfactual <- kappa_counterfactual[,c("kappa_f","year")]

  u_st = (predict(reg_u_st_kappa,newdata=kappa_counterfactual,fixef=FALSE) + resid(reg_u_st_kappa,na.rm = FALSE))
  return(u_st)
}

get_kappa_from_u_st <- function(data){
  reg_u_st_kappa <- readRDS(get_filename_case("output/reg_u_st_kappa_f.RDS",case))

  data_original <- fread(get_filename_case(file="output/CapitalAllocation/capital_rates_estimates_actual.csv",case))
  data_original$resid <- resid(reg_u_st_kappa,na.rm=FALSE)
  data_original$fixef <- predict(reg_u_st_kappa,newdata=data_original,fixef=TRUE)

  data2 <- merge(data,
                 data_original[,c("REINSSTATEDOMICILED","year","resid","fixef")],
                 by=c("REINSSTATEDOMICILED","year"),
                 all.x=TRUE)

  beta <- summary(reg_u_st_kappa)$coefficients[1]
  data2$kappa_f <- (data2$u_st - data2$fixef - data2$resid) / beta

  return(data2)
}

estimateCapitalAllocation <- function(scenario){
  data_insurer <- fread(get_filename_case("output/CapitalAllocation_insureryear.csv",case))

  data_insurer <- data_insurer[which(data_insurer$REINSSTATEDOMICILED != ""),]

  data_insurerstateyr <- fread(get_filename_case("output/CapitalAllocation_insurerstateyear.csv",case))

  data_insurerstateyr = data_insurerstateyr[which(data_insurerstateyr$REINSSTATEDOMICILED != ""),]

  data_insurerstateyr <- data_insurerstateyr %>% group_by(CEDENTSNLSTATENTITYKEY,year) %>% filter(amount_reinsured == max(amount_reinsured,na.rm=TRUE))
  data_insurerstateyr <- as.data.table(data_insurerstateyr)

  if (grepl("counterfactual_captiveban_demand_|counterfactual_captiveban_all|counterfactual_federal_",scenario)){
    data <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))
  } else if (grepl("counterfactual_captiveban_supply_",scenario)) {
    data <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_",gsub("[0-9]","",scenario),".csv"),case))
  } else if (grepl("counterfactual_dual_",scenario)) {
    data <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))
  } else {
    data <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_",scenario,".csv"),case))
  }

  data = data[,c("REINSSTATEDOMICILED","year","ln_s_st","ln_s_0t","u_st","kappa_f","kappa_economic","kappa_economic_K_div_L")]

  data_insurerstateyr <- merge(data_insurerstateyr,data,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE)

  names(data_insurerstateyr) <- mapvalues(names(data_insurerstateyr),
                                          from=c("amount_reinsured"),
                                          to=c("amount_reinsured_topstate"))

  data_insurerstateyr <- data_insurerstateyr[,c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED","amount_reinsured_topstate","ln_s_st","ln_s_0t","u_st","kappa_f","kappa_economic","kappa_economic_K_div_L")]

  data_insurer <- data_insurer[,REINSSTATEDOMICILED:=NULL]
  data_insurer <- merge(data_insurer,data_insurerstateyr,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)
  data_insurer <- data_insurer[which(data_insurer$ceded_frac_liab > 0),]

  share_allocated_util <- function(x,share_allocated_util_this){
    y <- log(x) - log(1-x) - share_allocated_util_this
    return(y)
  }

  data_basic_info = fread(get_filename_case("../CleanData/output/SNL_Basic_Info.csv",case))
  data_basic_info = data_basic_info[,c("SNLSTATENTITYKEY","SNLTOPENTITYKEY")]

  names(data_basic_info) = mapvalues(names(data_basic_info),
                                     from=c("SNLSTATENTITYKEY","SNLTOPENTITYKEY"),
                                     to=c("CEDENTSNLSTATENTITYKEY","CEDENTSNLTOPENTITYKEY"))

  data_insurer_chars <- fread(path.symlink("input/SNL_Financials_Group.csv"))

  names(data_insurer_chars) <- mapvalues(names(data_insurer_chars),
                                  from=c("SNLSTATENTITYKEY"),
                                  to=c("CEDENTSNLTOPENTITYKEY"))

  data_state_chars = fread(get_filename_case(file="output/StateYear_joint.csv",case))
  data_state_chars = data_state_chars[which(data_state_chars$REINSSTATEDOMICILED != ""),]
  data_state_chars = data_state_chars[,c("REINSSTATEDOMICILED","year",
                                         "CaptiveTaxRate","vote_share_r","newbusinesses_pop","Commissioner_Appointed",
                                         "donations_previous4_stateyr_EmployeesTotal","donations_previous_stateyr_EmployeesTotal","tourists")]

  data_insurerstate_chars = fread(get_filename_case("output/ReducedForm/data_all_fullsample.csv",case))
  data_insurerstate_chars = data_insurerstate_chars[,c("REINSSTATEDOMICILED","CEDENTSNLTOPENTITYKEY","year","state_share","geography_distance")]
  data_insurerstate_chars = data_insurerstate_chars[!duplicated(paste0(data_insurerstate_chars$REINSSTATEDOMICILED,"_",data_insurerstate_chars$year,"_",data_insurerstate_chars$CEDENTSNLTOPENTITYKEY)),]

  data_insurer = merge(data_insurer,data_basic_info,by=c("CEDENTSNLSTATENTITYKEY"),all.x=TRUE)
  data_insurer = merge(data_insurer,data_insurer_chars,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)
  data_insurer = merge(data_insurer,data_state_chars,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE)
  data_insurer = merge(data_insurer,data_insurerstate_chars,by=c("REINSSTATEDOMICILED","CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

  data_insurer$idx = seq(1,nrow(data_insurer),1)

  if (grepl("counterfactual_captiveban_supply_",scenario)){
    state_this <- gsub("[0-9]","",gsub("counterfactual_captiveban_supply_","",scenario))
    permutation_num_this <- as.numeric(gsub("[A-Za-z]","",gsub("counterfactual_captiveban_supply_","",scenario)))
    permutations_all <- fread(file=get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_permutations.csv"),case))
    permutation_this <- permutations_all[which(permutations_all$x == permutation_num_this),]

    names(permutation_this)[which(!grepl("CEDENTSNLSTATENTITYKEY",names(permutation_this)))] <- paste0(names(permutation_this)[which(!grepl("CEDENTSNLSTATENTITYKEY",names(permutation_this)))],"_switched")

    data_insurer <- merge(data_insurer,
                          permutation_this,
                          by=c("CEDENTSNLSTATENTITYKEY"),
                          all.x=TRUE)

    data_insurer = data_insurer[order(data_insurer$idx),]

    data_insurer$kappa_f[which(!is.na(data_insurer$kappa_f_switched))] <- data_insurer$kappa_f_switched[which(!is.na(data_insurer$kappa_f_switched))]
    data_insurer$REINSSTATEDOMICILED[which(!is.na(data_insurer$REINSSTATEDOMICILED_switched))] <- data_insurer$REINSSTATEDOMICILED_switched[which(!is.na(data_insurer$REINSSTATEDOMICILED_switched))]
    data_insurer$u_st[which(!is.na(data_insurer$u_st_switched))] <- data_insurer$u_st_switched[which(!is.na(data_insurer$u_st_switched))]
    data_insurer$u_st_rounded[which(!is.na(data_insurer$u_st_rounded_switched))] <- data_insurer$u_st_rounded_switched[which(!is.na(data_insurer$u_st_rounded_switched))]

  }

  if (scenario == "actual"){
    data_insurer$ln_b_jt <- log(data_insurer$ceded_frac_liab)
    data_insurer$ln_b_j0t <- log(1-data_insurer$ceded_frac_liab)
    data_insurer$ln_b_jt_minus_ln_b_j0t <- data_insurer$ln_b_jt - data_insurer$ln_b_j0t

    data_insurer$CEDENTSNLSTATENTITYKEY_year = paste0(data_insurer$CEDENTSNLSTATENTITYKEY,data_insurer$year)

    data_reinsurerstateyear <- fread(get_filename_case("output/CapitalAllocation_reinsurerstateyear_joint.csv",case))
    data_reinsurerstateyear = data_reinsurerstateyear[which(!is.na(data_reinsurerstateyear$kappa_economic_K_div_L) & !is.infinite(data_reinsurerstateyear$kappa_economic_K_div_L)),]
    data_reinsurerstateyear$REINSSTATEDOMICILED_year = paste0(data_reinsurerstateyear$REINSSTATEDOMICILED,data_reinsurerstateyear$year)
    if (case == 'prestablesample'){
      data_insurer_hascaptivecapitalrates = data_insurer[which(!is.na(data_insurer$kappa_economic_K_div_L) & (data_insurer$year >= 2005)),]
    } else {
      data_insurer_hascaptivecapitalrates = data_insurer[which(!is.na(data_insurer$kappa_economic_K_div_L) & (data_insurer$year >= 2014)),]
    }

    reg_insurer_1 <- feols(ln_b_jt_minus_ln_b_j0t ~ u_st, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    data_insurer_hascaptivecapitalrates$age_ln = log(data_insurer_hascaptivecapitalrates$age + 1)
    data_insurer_hascaptivecapitalrates$TOTALLIAB_bn = data_insurer_hascaptivecapitalrates$TOTALLIAB / 1e3

    reg_insurer_2 <- feols(ln_b_jt_minus_ln_b_j0t ~ kappa_economic_K_div_L, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_ln <- feols(ln_b_jt ~ kappa_economic_K_div_L, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_yearfes <- feols(ln_b_jt_minus_ln_b_j0t ~ kappa_economic_K_div_L | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_yearfes_ln <- feols(ln_b_jt ~ kappa_economic_K_div_L | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_insurerchars <- feols(ln_b_jt_minus_ln_b_j0t ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_insurerchars_ln <- feols(ln_b_jt ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_insurerchars_size <- feols(ln_b_jt_minus_ln_b_j0t ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + TOTALLIAB_bn | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_insurerchars_size_ln <- feols(ln_b_jt ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + TOTALLIAB_bn | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_statechars <- feols(ln_b_jt_minus_ln_b_j0t ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + TOTALLIAB_bn + CaptiveTaxRate + vote_share_r + newbusinesses_pop + Commissioner_Appointed | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    reg_insurer_2_statechars_ln <- feols(ln_b_jt ~ kappa_economic_K_div_L + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + TOTALLIAB_bn + CaptiveTaxRate + vote_share_r + newbusinesses_pop + Commissioner_Appointed | year, data=data_insurer_hascaptivecapitalrates, vcov = ~CEDENTSNLSTATENTITYKEY_year)

    fwrite(data_insurer_hascaptivecapitalrates,"output/data_insurer_hascaptivecapitalrates.csv")

    saveRDS(reg_insurer_1,file = get_filename_case(paste0("output/reg_ln_b_jt_minus_ln_b_j0t_u_st_",scenario,".RDS"),case))
    saveRDS(reg_insurer_2,file = get_filename_case(paste0("output/reg_ln_b_jt_minus_ln_b_j0t_k_st_",scenario,".RDS"),case))

    shares_predicted_fullsample = predict(reg_insurer_1,newdata = data_insurer)
    shares_resid_fullsample = data_insurer$ln_b_jt_minus_ln_b_j0t - shares_predicted_fullsample
    shares_fullsample = data.frame(ln_b_jt_minus_ln_b_j0t_actual_predicted=shares_predicted_fullsample,
                                   ln_b_jt_minus_ln_b_j0t_actual_resid=shares_resid_fullsample)
    fwrite(shares_fullsample,file=get_filename_case(paste0("output/reg_ln_b_jt_minus_ln_b_j0t_u_st_",scenario,"_residuals.csv"),case))

    cm_output = c("kappa_economic_K_div_L" = "State Capital Rate",
                  "publicly_traded_TICKER" = "1(Publicly Traded)",
                  "age_ln" = "ln(Firm Age)",
                  "NAICOWNSTRUCTURE_is_mutual" = "1(Mutual Insurer)",
                  "BUSINESSFOCUS_lifeorannuity" = "1(Life or Annuity Focus)",
                  "group_numsubsidiaries" = "Num. Subsidiaries",
                  "TOTALLIAB_bn" = "Size",
                  "(Intercept)" = "Constant")

    to_keep <- c("kappa_economic_K_div_L")

    all_models_ln <- list(
      reg_insurer_2_ln,
      reg_insurer_2_yearfes_ln,
      reg_insurer_2_insurerchars_ln,
      reg_insurer_2_insurerchars_size_ln
    )
    all_coefs_ln <- unique(unlist(lapply(all_models_ln, function(x) names(coef(x)))))

    all_models <- list(
      reg_insurer_2,
      reg_insurer_2_yearfes,
      reg_insurer_2_insurerchars,
      reg_insurer_2_insurerchars_size
    )
    all_coefs <- unique(unlist(lapply(all_models, function(x) names(coef(x)))))

    rsqregusescaptivesintensivecaprateonly = round(r2(reg_insurer_2_yearfes)['cor2'] * 100,0)
    rsqregusescaptivesintensive = round(r2(reg_insurer_2_insurerchars)['cor2'] * 100,0)

    rsqregusescaptivesintensivecaprateonlyln = round(r2(reg_insurer_2_yearfes_ln)['cor2'] * 100,0)
    rsqregusescaptivesintensiveln = round(r2(reg_insurer_2_insurerchars_ln)['cor2'] * 100,0)

    writeLines(as.character(modelsummary(list("(1)" = reg_insurer_2_ln,
                                 "(2)" = reg_insurer_2_yearfes_ln,
                                 "(3)" = reg_insurer_2_insurerchars_ln,
                                 "(4)" = reg_insurer_2_insurerchars_size_ln),
                                 fmt_significant(digits = 2),
                                 stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                                 gof_omit = c("^(?!R2$|Obs)"),
                                 gof_map = gm,
                                 coef_map = cm_output,
                                 coef_order = names(cm_output),
                                 add_rows = data.frame(a = c("Year FEs"),
                                                       b = c(""),
                                                       c = c("X"),
                                                       d = c("X"),
                                                       e = c("X")),
                            output="latex_tabular")),
                            get_filename_case("output/reg_ln_b_ln_0_kappa_chars_ln.tex",case))

    writeLines(as.character(modelsummary(list("(1)" = reg_insurer_2,
                                              "(2)" = reg_insurer_2_yearfes,
                                              "(3)" = reg_insurer_2_insurerchars,
                                              "(4)" = reg_insurer_2_insurerchars_size),
                                         fmt_significant(digits = 2),
                                         stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                                         gof_omit = c("^(?!R2$|Obs)"),
                                         gof_map = gm,
                                         coef_map = cm_output,
                                         add_rows = data.frame(a = c("Year FEs"),
                                                               b = c(""),
                                                               c = c("X"),
                                                               d = c("X"),
                                                               e = c("X")),
                                         output="latex_tabular")),
               get_filename_case("output/reg_ln_b_ln_0_kappa_chars.tex",case))

    b_st_mean <- mean(data_insurer$ceded_frac_liab,na.rm=TRUE)
    ln_b_st_minus_b_0t_mean <- log(b_st_mean) - log(1 - b_st_mean)
    alpha_capital <- summary(reg_insurer_2_insurerchars_size)$coefficients[1]
    ln_b_st_minus_b_0t_mean_new <- ln_b_st_minus_b_0t_mean + (0.01) * alpha_capital
    b_st_mean_new <- nleqslv::nleqslv(b_st_mean,jac=NULL,share_allocated_util,ln_b_st_minus_b_0t_mean_new,control = list(ftol=10^(-12)))$x
    b_st_mean_delta <- b_st_mean_new - b_st_mean
    b_st_mean_delta_frac <- b_st_mean_delta / b_st_mean

    write(paste0("\\newcommand{\\alphacapital}{",round(alpha_capital,digits=2),"} \n",
                 "\\newcommand{\\bstmean}{",round(b_st_mean*100,digits=0),"} \n",
                 "\\newcommand{\\bstmeannew}{",round(b_st_mean_new*100,digits=0),"} \n",
                 "\\newcommand{\\bstmeandelta}{",abs(round(b_st_mean_delta*100,digits=0)),"} \n",
                 "\\newcommand{\\bstmeandeltafrac}{",abs(round(b_st_mean_delta_frac*100,digits=0)),"} \n",
                 "\\newcommand{\\rsqregusescaptivesintensive}{",rsqregusescaptivesintensive,"} \n",
                 "\\newcommand{\\rsqregusescaptivesintensiveln}{",rsqregusescaptivesintensiveln,"} \n",
                 "\\newcommand{\\rsqregusescaptivesintensivecaprateonly}{",rsqregusescaptivesintensivecaprateonly,"} \n",
                 "\\newcommand{\\rsqregusescaptivesintensivecaprateonlyln}{",rsqregusescaptivesintensivecaprateonlyln,"} \n"), file=get_filename_case("output/PaperText/PaperText_RegulatoryCompetition_Analysis_Insurer_CapitalAllocation.tex",case))
  }

  reg_insurer_1_actual <- readRDS(get_filename_case(paste0("output/reg_ln_b_jt_minus_ln_b_j0t_u_st_actual.RDS"),case))

  shares_fullsample = fread(get_filename_case(paste0("output/reg_ln_b_jt_minus_ln_b_j0t_u_st_actual_residuals.csv"),case))

  if (scenario == "actual"){

    share_allocated_util_this <- predict(reg_insurer_1_actual,newdata=data_insurer) + shares_fullsample$ln_b_jt_minus_ln_b_j0t_actual_resid

    ceded_frac_liab_estimated_vector <- c()
    for (i in 1:length(share_allocated_util_this)){
      if (is.na(share_allocated_util_this[i])){
        ceded_frac_liab_estimated_this <- NA
      } else {
        ceded_frac_liab_estimated_this <- nleqslv::nleqslv(data_insurer$ceded_frac_liab[i],jac=NULL,share_allocated_util,share_allocated_util_this[i],control = list(ftol=10^(-12)))$x
      }
      ceded_frac_liab_estimated_vector <- c(ceded_frac_liab_estimated_vector,ceded_frac_liab_estimated_this)
    }
    data_insurer$ceded_frac_liab_estimated <- ceded_frac_liab_estimated_vector

  } else {
    share_allocated_util_this <- predict(reg_insurer_1_actual,newdata=data_insurer) + shares_fullsample$ln_b_jt_minus_ln_b_j0t_actual_resid

    ceded_frac_liab_estimated_vector <- c()
    for (i in 1:length(share_allocated_util_this)){
      if (is.na(share_allocated_util_this[i])){
        ceded_frac_liab_estimated_this <- NA
      } else {
        ceded_frac_liab_estimated_this <- nleqslv::nleqslv(data_insurer$ceded_frac_liab[i],jac=NULL,share_allocated_util,share_allocated_util_this[i])$x
      }
      ceded_frac_liab_estimated_vector <- c(ceded_frac_liab_estimated_vector,ceded_frac_liab_estimated_this)
    }
    data_insurer$ceded_frac_liab_estimated <- ceded_frac_liab_estimated_vector

    data_insurer$ceded_frac_liab_diff = data_insurer$ceded_frac_liab_estimated - data_insurer$ceded_frac_liab

  }

  if (scenario == "actual"){

    data_insurer$ceded_frac_liab_100 <- data_insurer$ceded_frac_liab * 100
    reg_ceded_frac_liab_u_st <- feols(ceded_frac_liab_100 ~ u_st, data=data_insurer, vcov = ~CEDENTSNLSTATENTITYKEY + year)
    writeLines(as.character(modelsummary(list("(1)" = reg_ceded_frac_liab_u_st),
                            fmt = "%.2f",
                            stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                            gof_omit = c("^(?!R2$|Obs)"),
                            gof_map = gm,
                            coef_map = cm,
               output="latex_tabular")),
               get_filename_case("output/reg_ceded_frac_liab_u_st_actual.tex",case))
  }

  if (grepl("counterfactual_captiveban_supply_",scenario)){
    data_insurer_full <- fread(get_filename_case("output/CapitalAllocation_insureryear.csv",case))
    data_insurer_full <- data_insurer_full[,c("CEDENTSNLSTATENTITYKEY","year")]
    data_insurer <- merge(data_insurer_full,data_insurer,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)
  } else {
    data_insurer_full <- fread(get_filename_case("output/CapitalAllocation_insureryear.csv",case))
    data_insurer_full <- data_insurer_full[,c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED")]
    data_insurer <- merge(data_insurer_full,data_insurer,by=c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED"),all.x=TRUE)
  }
  data_insurer$ceded_frac_liab_estimated[which(is.na(data_insurer$ceded_frac_liab_estimated))] <- 0

  if (grepl("counterfactual_federal_",scenario)){
    data_insurer$ceded_frac_liab_estimated = 0
  }
  if (scenario == "counterfactual_captiveban_all"){
    data_insurer$ceded_frac_liab_estimated = 0
  }
  if (grepl("counterfactual_captiveban_demand_",scenario)){
    state_ban <- gsub("counterfactual_captiveban_demand_","",scenario)
    data_insurer$ceded_frac_liab_estimated[which(data_insurer$CEDENTSTATEDOMICILED == state_ban)] <- 0
  }
  if (grepl("counterfactual_dual_",scenario)){
    data_insurer$SNLSTATENTITYKEY_is_odd <- ifelse(as.numeric(sub(".*(\\d)$", "\\1", data_insurer$CEDENTSNLSTATENTITYKEY)) %% 2 == 0, 0, 1)
    data_insurer$ceded_frac_liab_estimated[which(data_insurer$SNLSTATENTITYKEY_is_odd == 1)] = 0
  }

  fwrite(data_insurer[,c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED","ceded_frac_liab_estimated",'ceded_frac_liab_uncensored')],get_filename_case(paste0("output/CapitalAllocation/ceded_frac_liab_",scenario,".csv"),case))
}

loadDemand <- function(){
  reg_demand <- readRDS(get_filename_case(paste0("../Analysis_Demand/output/regs_demand_",demand_iv,".RDS"),case))
  alpha <- summary(reg_demand)$coefficients[1]
  return(alpha)
}
loadDemandFull <- function(){
  reg_demand <- readRDS(get_filename_case(paste0("../Analysis_Demand/output/regs_demand_",demand_iv,".RDS"),case))
  return(reg_demand)
}

calculate_s_s_prime <- function(data_snl_quantities){
  data_snl_quantities$s_s_prime_denominator <- data_snl_quantities$share * (1 - data_snl_quantities$share) * data_snl_quantities$alpha * data_snl_quantities$quantities_stateyeartype_plus_outsidegood

  data_snl_quantities <- data_snl_quantities %>% group_by(SNLSTATENTITYKEY,year,amb_co_num) %>% summarise(s_s_prime_numerator = sum(quantities,na.rm=TRUE),
                                                                                                          s_s_prime_denominator = sum(s_s_prime_denominator,na.rm=TRUE))
  data_snl_quantities$s_s_prime <- data_snl_quantities$s_s_prime_numerator / data_snl_quantities$s_s_prime_denominator

  return(data_snl_quantities)
}

loadData <- function(scenario){
  data_snl_quantities <- fread(get_filename_case(path.symlink("input/Demand_All.csv"),case))

  data_snl_quantities <- data_snl_quantities[which(!is.na(data_snl_quantities$price) & !is.na(data_snl_quantities$share) & (data_snl_quantities$share != 0)),]

  data_snl_quantities$quantities_stateyeartype_plus_outsidegood <- (data_snl_quantities$quantities_stateyeartype + data_snl_quantities$quantities_outsidegood)

  alpha <- loadDemand()
  data_snl_quantities$alpha <- alpha

  data_snl_quantities_market <- data_snl_quantities[,c("SNLSTATENTITYKEY","amb_co_num","state","state_year_type","year",
                                                       "price",
                                                       "share","quantities","quantities_stateyeartype","quantities_outsidegood",
                                                       "quantities_stateyeartype_plus_outsidegood","alpha")]

  data_snl_quantities <- calculate_s_s_prime(data_snl_quantities)

  data_snl_quantities <- data_snl_quantities[which(data_snl_quantities$SNLSTATENTITYKEY != ""),]

  data_snl_financials <- fread(get_filename_case(path.symlink("input/SNL_Financials.csv"),case))

  data_ambest_id <- fread(get_filename_case(path.symlink("input/AMBest_ID_NAIC.csv"),case))
  names(data_ambest_id) <- c("amb_co_num","NAICCOMPANYCODE")
  data_ambest_id <- data_ambest_id[which(!is.na(data_ambest_id$NAICCOMPANYCODE)),]

  data_snl <- merge(data_snl_quantities,data_snl_financials,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE,all.y=TRUE)
  data_snl <- data_snl[which(!is.na(data_snl$NAICCOMPANYCODE)),]

  data_price <- fread(get_filename_case(path.symlink("input/CompuLife_All.csv"),case))

  data_ratings <- fread(get_filename_case(path.symlink("input/AMBest_Ratings_All.csv"),case))

  data_ratings_cols <- c("amb_co_num","year","Rating","RatingNumeric")
  data_ratings <- data_ratings[,..data_ratings_cols]
  data_ratings$is_ratings <- 1

  data_default <- fread(get_filename_case(path.symlink("input/AMBest_Impairment_Transition_Tables.csv"),case))

  if (case == 'costfunction'){
    data_reinsurance <- fread(get_filename_case("output/CapitalAllocation_insureryear.csv",case))
    data_reinsurance = data_reinsurance[,c("CEDENTSNLSTATENTITYKEY","REINSSTATEDOMICILED","year","ceded_frac_liab","ceded_frac_liab_uncensored")]

    data_reinsurance$ceded_frac_liab_estimated = data_reinsurance$ceded_frac_liab

  } else {
    data_reinsurance <- fread(get_filename_case(paste0("output/CapitalAllocation/ceded_frac_liab_",scenario,".csv"),case))

    data_reinsurance$ceded_frac_liab <- data_reinsurance$ceded_frac_liab_estimated
    data_reinsurance <- data_reinsurance[,c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED","ceded_frac_liab","ceded_frac_liab_uncensored")]
  }

  names(data_reinsurance) <- mapvalues(names(data_reinsurance),
                                       from=c("CEDENTSNLSTATENTITYKEY"),
                                       to=c("SNLSTATENTITYKEY"))

  if (grepl("counterfactual_captiveban_demand_|counterfactual_captiveban_all|counterfactual_federal_|counterfactual_dual",scenario)){
    data_kappa <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))
  } else if (grepl("counterfactual_captiveban_supply_",scenario)) {
    data_kappa <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_",gsub("[0-9]","",scenario),".csv"),case))
  } else {
    data_kappa <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_",scenario,".csv"),case))
  }

  data_kappa <- data_kappa[,c("year","REINSSTATEDOMICILED","u_st","kappa_f")]

  data <- merge(data_snl,data_price,by=c("amb_co_num","year"),all.x=TRUE,all.y=TRUE)

  data <- merge.data.table(data,data_ratings,by=c("amb_co_num","year"),all.x=TRUE)

  data <- merge.data.table(data,data_default,by=c("Rating"),all.x=TRUE)

  data <- merge.data.table(data,data_reinsurance,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

  data <- merge.data.table(data,data_kappa,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE)

  data <- data[which(!is.na(data$s_s_prime) & !is.na(data$price)),]

  data = data[which(data$year >= 2004),]

  data <- as.data.table(data)

  loadAssumedParameters <- function(data){
    discountrates <- fread(get_filename_case("../raw/FederalReserve/DGS30.csv",case))
    discountrates$year <- year(as.Date(discountrates$DATE))
    discountrates$DGS30 <- as.numeric(discountrates$DGS30)
    discountrates <- discountrates %>% group_by(year) %>% summarise(R_f = mean(DGS30,na.rm=TRUE))

    discountrates$R_f <- discountrates$R_f / 100

    data <- merge(data,discountrates,by=c("year"),all.x=TRUE)

    data$R_f <- Rf

    data$kappa_h <- kappa_h

    return(data)
  }
  data <- loadAssumedParameters(data)
  data <- as.data.table(data)
  data <- get_kappa_from_u_st(data)
  data <- as.data.table(data)
  data <- data %>% group_by(year) %>% mutate(kappa_f_meanyr = mean(kappa_f,na.rm=TRUE),
                                             u_st_meanyr = mean(u_st,na.rm=TRUE))
  data$kappa_f[which(is.na(data$kappa_f))] <- data$kappa_f_meanyr[which(is.na(data$kappa_f))]
  data$u_st[which(is.na(data$u_st))] <- data$u_st_meanyr[which(is.na(data$u_st))]
  data <- as.data.table(data)

  data$ceded_frac_liab[which(is.na(data$ceded_frac_liab))] = 0

  if (grepl("counterfactual_federal_",scenario)){
    kappa_counterfactual <- as.numeric(gsub("counterfactual_federal_","",scenario))
    data$kappa = kappa_counterfactual
  } else if (grepl("counterfactual_dual_",scenario)){
    kappa_counterfactual <- as.numeric(gsub("counterfactual_dual_","",scenario))
    data$SNLSTATENTITYKEY_is_odd = ifelse(as.numeric(sub(".*(\\d)$", "\\1", data$SNLSTATENTITYKEY)) %% 2 == 0, 0, 1)

    data$kappa <- pmax((data$kappa_f * data$ceded_frac_liab) + (data$kappa_h * (1 - data$ceded_frac_liab)),0)
    data$kappa[which(data$SNLSTATENTITYKEY_is_odd == 1)] = kappa_counterfactual
  } else {
    data$kappa <- pmax((data$kappa_f * data$ceded_frac_liab) + (data$kappa_h * (1 - data$ceded_frac_liab)),0)
  }

  data$kappa_delta = data$kappa_h - data$kappa_f

  data$default_prob_ambest <- data$default_prob_15_yr / 15 * npv_rate
  default_prob_ambest_mean <- mean(data$default_prob_ambest,na.rm=TRUE)
  data$default_prob_ambest[which(is.na(data$default_prob_ambest))] <- default_prob_ambest_mean
  data$Phi <- 1 - data$default_prob_ambest

  data$phi_pdf <- dnorm(qnorm(data$Phi, mean = 0, sd = 1))
  data$lambda <- data$phi_pdf / (data$Phi)

  data$P <- data$price

  b = fread("../raw/SNL/Companies/SNL_Companies_Debt_to_Liabilities_Ratio.csv")
  b = b$b[1]
  data$b = b

  if (case == 'guarantyfundfunding'){
    data_federalyr_actual_output = fread(file=get_filename_case("output/Regulator/data_federalyr_actual_output.csv",'baseline'))

    data_federalyr_actual_output = data_federalyr_actual_output[,c("Year","Guaranty","Quantity")]

    names(data_federalyr_actual_output) = mapvalues(names(data_federalyr_actual_output),from=c("Year",'Guaranty','Quantity'),to=c("year",'guaranty_yr','quantity_yr'))

    data = merge(data,data_federalyr_actual_output,by=c("year"),all.x=TRUE)

    data$G = frac_guarantyfund_insurerfunded * data$guaranty_yr / data$quantity_yr / 1e6

    data$G[which(is.na(data$G))] = 0

  } else {
    data$G = 0
  }

  data <- data[order(SNLSTATENTITYKEY,year),]
  data_snl_quantities_market <- data_snl_quantities_market[order(SNLSTATENTITYKEY,year),]

  return(list(data,data_snl_quantities_market))

}

solvePrimitives <- function(data,scenario){
  if (scenario == "actual"){
    if (case == 'costfunction'){
      data$Psi = (data$kappa_delta * (1 + data$b) * (1 - data$Phi + theta) - tau * data$Phi) / (2 * data$ceded_frac_liab)
      data$C_B = data$Psi * (data$ceded_frac_liab^2)
      data$Psi[which(data$ceded_frac_liab == 0)] = 0
      data$C_B[which(data$ceded_frac_liab == 0)] = 0
    } else {
      data$Psi = 0
      data$C_B = 0
    }

    data$sigma = (data$s_s_prime - (data$kappa * (1 - data$Phi + theta) + data$C_B) / data$Phi + (theta - data$R_f) / (1 + data$R_f) * data$kappa * (1 + data$b) + data$C_B / (1 + data$R_f) + data$b) / ((qnorm(data$Phi,mean=0,sd=1) + data$lambda) * (data$Phi / (1 + data$R_f) - 1))
    data$mu = data$sigma * data$lambda + data$P + data$s_s_prime - (data$kappa * (1 - data$Phi) + theta * data$kappa + data$C_B) / data$Phi - tau * data$ceded_frac_liab - data$G
    data$R_bar = (data$P - 1 / (1 + data$R_f) * (data$mu - data$sigma * data$lambda) * (data$Phi) + (data$R_f - theta) / (1 + data$R_f) * data$kappa * (1 + data$b) - data$b - (1 / (1 + data$R_f)) * data$C_B - tau * data$ceded_frac_liab - data$G) / (1 - (1 / (1 + data$R_f)) * (data$Phi))

    R_bar_check = data$Phi - pnorm((data$R_bar - data$mu) / data$sigma, mean=0, sd=1)
    data$default_prob_check <- pnorm((data$R_bar - data$mu) / data$sigma, mean=0, sd=1)
    data$p_foc_lhs = data$Phi * (data$P - (data$mu - data$sigma * data$lambda) - tau * data$ceded_frac_liab - data$G + data$s_s_prime)
    data$p_foc_rhs = data$kappa * (1 - data$Phi) + theta * data$kappa + data$C_B
    data$p_foc = data$p_foc_lhs - data$p_foc_rhs
    if (case == 'costfunction'){
      data$ceded_frac_liab_foc_lhs = data$kappa_delta * (1 + data$b) * (1 - data$Phi + theta)
      data$ceded_frac_liab_foc_rhs = tau * data$Phi + 2 * data$Psi * data$ceded_frac_liab
      data$ceded_frac_liab_foc = data$ceded_frac_liab_foc_lhs - data$ceded_frac_liab_foc_rhs

      data$ceded_frac_liab_foc[which(data$ceded_frac_liab == 0)] = 0
    }

    fwrite(data, file=get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))

    data_ky = fread("output/CapitalAllocation_insureryear_KY.csv")
    data_ky = data_ky[,c("CEDENTSNLSTATENTITYKEY","year","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored")]
    names(data_ky) = mapvalues(names(data_ky),
                               from=c("CEDENTSNLSTATENTITYKEY","year","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored"),
                               to=c("SNLSTATENTITYKEY","year","amount_reinsured_KY","ceded_frac_liab_KY","ceded_frac_liab_uncensored_KY"))
    data_with_ky = merge(data,data_ky,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

    data_basic_info = fread(get_filename_case("../CleanData/output/SNL_Basic_Info.csv",case))
    data_basic_info = data_basic_info[,c("SNLSTATENTITYKEY","SNLTOPENTITYKEY")]

    names(data_basic_info) = mapvalues(names(data_basic_info),
                                       from=c("SNLTOPENTITYKEY"),
                                       to=c("CEDENTSNLTOPENTITYKEY"))

    data_insurer_chars <- fread(path.symlink("input/SNL_Financials_Group.csv"))
    names(data_insurer_chars) <- mapvalues(names(data_insurer_chars),
                                           from=c("SNLSTATENTITYKEY"),
                                           to=c("CEDENTSNLTOPENTITYKEY"))
    data_insurer_chars = data_insurer_chars[,c("CEDENTSNLTOPENTITYKEY",'year','publicly_traded','publicly_traded_TICKER','BUSINESSFOCUS_lifeorannuity','BUSINESSFOCUS_none','NAICOWNSTRUCTURE_is_mutual','age','group_numsubsidiaries')]

    data_with_ky2 = merge(data_with_ky,data_basic_info,by=c("SNLSTATENTITYKEY"),all.x=TRUE)

    data_with_ky2 <- merge(data_with_ky2, data_insurer_chars, c("CEDENTSNLTOPENTITYKEY",'year'),all.x=TRUE, suffixes = c(".x", "")) %>%
      select(-ends_with(".x"))

    data_with_ky2$age_ln = log(data_with_ky2$age+1)
    data_with_ky2$TOTALLIAB_bn = data_with_ky2$TOTALLIAB / 1e3

    fwrite(data_with_ky2, file=get_filename_case("output/Pricing/companyyear_withprimitives_withky.csv",case))

    data_post2013 = data[which(data$year >= 2013),]

    reg_mu <- feols(mu ~ price | SNLSTATENTITYKEY, cluster = ~SNLSTATENTITYKEY + year, data = data_post2013)

    ggplot(data_post2013, aes(x=mu)) + geom_histogram(aes(y = after_stat(count / sum(count))),binwidth = 0.2, fill="black", color="grey") +
      xlab(latex2exp::TeX("Stochastic Cost Mean \\mu")) + ylab("Frequency") +
      theme_classic() + theme(text = element_text(size=20))
    ggsave("output/Pricing/primitives_summarystats_hist_mu.png",width=10,height=7,dpi=300)

    ggplot(data_post2013, aes(x=sigma)) + geom_histogram(aes(y = after_stat(count / sum(count))),binwidth = 0.025, fill="black", color="grey") +
      xlab(latex2exp::TeX("Stochastic Cost Standard Deviation \\sigma")) + ylab("Frequency") +
      theme_classic() + theme(text = element_text(size=20))
    ggsave("output/Pricing/primitives_summarystats_hist_sigma.png",width=10,height=7,dpi=300)

    if (case == "costfunction"){
      ggplot(data_post2013[which(!is.infinite(data_post2013$Psi)),], aes(x=Psi)) + geom_histogram(aes(y = after_stat(count / sum(count))),binwidth = 1e7 * 2, fill="black", color="grey") +
        xlab(latex2exp::TeX("Captive Transfer Cost Parameter \\Psi")) + ylab("Frequency") +
        theme_classic() + theme(text = element_text(size=20))
      ggsave("output/Pricing/primitives_summarystats_hist_psi.png",width=10,height=7,dpi=300)
    }

    data_out <- data_post2013[,c("mu","sigma")]
    names(data_out) <- c("\\mu","\\sigma")
    stargazer(data_out,
              covariate.labels = c("$\\mu_{i,t}$","$\\sigma_{i,t}$"),
              style="aer",
              omit.table.layout = "n",
              median=TRUE,
              float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
              no.space = TRUE,
              header = FALSE,
              out=get_filename_case(paste0("output/Pricing/primitives_summarystats.tex"),case))

  }

  if (scenario != "actual"){
    data_primitives <- fread(get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))
    data_primitives <- data_primitives[,c("SNLSTATENTITYKEY","year","mu","sigma","Psi","C_B","R_bar")]

    data <- merge(data,data_primitives,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

  }

  return(data)
}

solveCounterfactuals <- function(data,data_snl_quantities_market,scenario,year_this){
  computePriceQuantitiesRbar <- function(guesses,data_this){
    n_obs_insureryear = nrow(data_this)
    n_obs_market = nrow(data_snl_quantities_market)
    data_this$price <- guesses[1:n_obs_insureryear]
    share_guesses <- guesses[(n_obs_insureryear+1):(n_obs_insureryear+n_obs_market)]
    data_this$R_bar <- guesses[(n_obs_insureryear+n_obs_market+1):(2*n_obs_insureryear+n_obs_market)]

    data_this$P <- data_this$price

    data_snl_quantities_market_this <- data_snl_quantities_market
    cols_actual <- names(data_snl_quantities_market_this)[which(grepl("^quantities|^price|^share",names(data_snl_quantities_market_this)))]
    names(data_snl_quantities_market_this) <- mapvalues(names(data_snl_quantities_market_this),
                                                        from=cols_actual,
                                                        to=paste0(cols_actual,"_actual"))

    data_snl_quantities_market_this$row_id  <- 1:nrow(data_snl_quantities_market_this)
    data_snl_quantities_market_this <- merge.data.table(data_snl_quantities_market_this,
                                                        data_this[which(!is.na(data_this$amb_co_num)),c("amb_co_num","year","price","V")],by=c("amb_co_num","year"),
                                                        all.x=TRUE)
    data_snl_quantities_market_this <- data_snl_quantities_market_this[order(row_id),]

    data_snl_quantities_market_this$price_dollars <- data_snl_quantities_market_this$price * V

    data_snl_quantities_market_this$share_outsidegood_actual <- data_snl_quantities_market_this$quantities_outsidegood_actual / data_snl_quantities_market_this$quantities_stateyeartype_plus_outsidegood_actual
    data_snl_quantities_market_this$ln_s_0st_actual <- log(data_snl_quantities_market_this$share_outsidegood_actual)

    data_snl_quantities_market_this$share_guesses <- share_guesses
    data_snl_quantities_market_this$ln_s_jst_guesses <- log(data_snl_quantities_market_this$share_guesses)
    data_snl_quantities_market_this <- data_snl_quantities_market_this %>% group_by(state,year,state_year_type) %>% mutate(share_stateyeartype_guesses_total = sum(share_guesses,na.rm=TRUE),
                                                                                                                           share_stateyeartype_actual_total = sum(share_actual,na.rm=TRUE))
    data_snl_quantities_market_this$share_outsidegood_guesses <- 1 - (data_snl_quantities_market_this$share_stateyeartype_guesses_total)

    obj_fun_quantities_lhs <- (data_snl_quantities_market_this$ln_s_jst_guesses - log(data_snl_quantities_market_this$share_outsidegood_guesses)) - (log(data_snl_quantities_market_this$share_actual) - data_snl_quantities_market_this$ln_s_0st_actual)
    obj_fun_quantities_rhs <- alpha * (data_snl_quantities_market_this$price - data_snl_quantities_market_this$price_actual)
    obj_fun_quantities <- obj_fun_quantities_lhs - obj_fun_quantities_rhs

    if (min(share_guesses,na.rm=TRUE) < 0){
      obj_fun_quantities = rep(1e10,length(obj_fun_quantities))
    }

    data_snl_quantities_market_this$share <- share_guesses

    data_snl_quantities_market_this$quantities <- data_snl_quantities_market_this$share * data_snl_quantities_market_this$quantities_stateyeartype_plus_outsidegood_actual
    data_snl_quantities_market_this$quantities_stateyeartype_plus_outsidegood <- data_snl_quantities_market_this$quantities_stateyeartype_plus_outsidegood_actual

    data_snl_quantities_market_this <- calculate_s_s_prime(data_snl_quantities_market_this)

    names(data_this) <- mapvalues(names(data_this),
                                  from=c("s_s_prime","s_s_prime_numerator","s_s_prime_denominator"),
                                  to=c("s_s_prime_actual","s_s_prime_numerator_actual","s_s_prime_denominator_actual"))

    data_snl_quantities_market_this <- as.data.table(data_snl_quantities_market_this)[,amb_co_num:=NULL]

    data_this <- merge.data.table(data_this,data_snl_quantities_market_this,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

    data_this <- data_this[which(!is.na(data_this$s_s_prime_actual) & !is.na(data_this$s_s_prime)),]

    data_this$Phi <- 1 - data_this$default_prob_ambest

    data_this$Phi_guess <- pnorm((data_this$R_bar - data_this$mu) / data_this$sigma, mean=0, sd=1)

    data_this$Phi <- data_this$Phi_guess

    data_this$phi_pdf <- dnorm(qnorm(data_this$Phi, mean = 0, sd = 1))
    data_this$lambda <- data_this$phi_pdf / (data_this$Phi)

    data_this$p_foc = data_this$Phi * (data_this$price - (data_this$mu - data_this$sigma * data_this$lambda) - tau * data_this$ceded_frac_liab - data_this$G + data_this$s_s_prime) - (data_this$kappa * (1 - data_this$Phi) + theta * data_this$kappa + data_this$C_B)

    data_this$R_bar_foc = data_this$R_bar - (data_this$price - 1 / (1 + data_this$R_f) * (data_this$mu - data_this$sigma * data_this$lambda) * (data_this$Phi) + (data_this$R_f - theta) / (1 + data_this$R_f) * data_this$kappa * (1 + data_this$b) - 1/(1 + data_this$R_f) * data_this$C_B - data_this$b - tau * data_this$ceded_frac_liab - data_this$G) / (1 - 1 / (1 + data_this$R_f) * (data_this$Phi))

    obj_fun <- c(data_this$p_foc,obj_fun_quantities,data_this$R_bar_foc)

    if (max(abs(obj_fun),na.rm=TRUE) < 1e-10){
      fwrite(data_this, file=get_filename_case("output/data_this_obj_fun.csv",case))
    }

    return(obj_fun)
  }

  data_this <- data[which(data$year == year_this),]
  data_snl_quantities_market <- data_snl_quantities_market[which(data_snl_quantities_market$year == year_this),]

  if (case == 'costfunction'){
    data_this$ceded_frac_liab_actual = data_this$ceded_frac_liab
    data_this$ceded_frac_liab = (data_this$kappa_delta * (1 + data_this$b) * (1 - data_this$Phi + theta) - tau * data_this$Phi) / (2 * data_this$Psi)
    data_this$ceded_frac_liab[which(data_this$ceded_frac_liab_actual == 0)] = 0
    data_this$C_B = data_this$Psi * data_this$ceded_frac_liab^2
  }

  data_this$price_actual <- data_this$price
  price_guess <- data_this$price_actual

  if (grepl("pricing_multipleequilibria_",scenario)){
    prices_delta_multipleequilibria = fread(get_filename_case("output/MultipleEquilibria/prices_delta_multipleequilibria.csv",case))
    price_multipliers = prices_delta_multipleequilibria$prices_delta[which(prices_delta_multipleequilibria$scenario == scenario)]
    price_guess = price_guess * price_multipliers[1:length(price_guess)]
  }

  share_guess <- data_snl_quantities_market$share
  data_this$R_bar_actual <- data_this$R_bar
  r_bar_guess <- data_this$R_bar_actual
  guesses <- c(price_guess,share_guess,r_bar_guess)

  if (grepl("counterfactual_federal_|counterfactual_dual_",scenario)){
    if (file.exists(paste0("output/scenario_data_this_",scenario_run,".csv")) & file.exists(paste0("output/scenario_data_snl_quantities_market_sol_",scenario_run,".csv"))){
      prev_scenario_data_this = fread(get_filename_case(paste0("output/scenario_data_this_",scenario_run,".csv"),case))
      prev_scenario_data_snl_quantities_market_sol = fread(get_filename_case(paste0("output/scenario_data_snl_quantities_market_sol_",scenario_run,".csv"),case))

      prev_scenario_data_this = prev_scenario_data_this[which(prev_scenario_data_this$year == year_this),]
      prev_scenario_data_snl_quantities_market_sol = prev_scenario_data_snl_quantities_market_sol[which(prev_scenario_data_snl_quantities_market_sol$year == year_this),]

      data_this$price_actual <- prev_scenario_data_this$price
      price_guess <- data_this$price_actual
      share_guess <- prev_scenario_data_snl_quantities_market_sol$share
      data_this$R_bar_actual <- prev_scenario_data_this$R_bar
      r_bar_guess <- data_this$R_bar_actual
      guesses <- c(price_guess,share_guess,r_bar_guess)
    }
  }

  alpha <- loadDemand()

  start_time <- Sys.time()

  sols_full = BBsolve(guesses, computePriceQuantitiesRbar, data_this=data_this)
  sols_this = sols_full$par

  if (sols_full$message != "Successful convergence"){
    sols_full <- nleqslv::nleqslv(guesses,jac=NULL,computePriceQuantitiesRbar,data_this,
                                  method = "Broyden",
                                  global = "qline",
                                  control = list(
                                    maxit = 100,
                                    ftol = 1e-10,
                                    xtol = 1e-10,
                                    trace = TRUE
                                  ))
    sols_this <- sols_full$x
  }

  successful = 0
  if ((sols_full$message == "Successful convergence")){
    successful = 1
  } else if ((sols_full$termcd == 1) | (sols_full$termcd == 2)) {
    successful = 1
  }

  n_obs_insureryear = nrow(data_this)
  n_obs_market = nrow(data_snl_quantities_market)

  price_soln <- sols_this[1:n_obs_insureryear]
  share_soln <- sols_this[(n_obs_insureryear+1):(n_obs_insureryear+n_obs_market)]
  r_bar_soln <- sols_this[(n_obs_insureryear+n_obs_market+1):(2*n_obs_insureryear+n_obs_market)]

  data_this$price <- price_soln
  data_snl_quantities_market$share_soln <- share_soln
  data_this$R_bar <- r_bar_soln

  data_this$nleqslv_termcd <- ifelse(successful,yes = 1,no=sols_full$message)

  cols_actual <- names(data_snl_quantities_market)[which(grepl("^quantities|^price|^share",names(data_snl_quantities_market)))]
  cols_actual <- cols_actual[which(!grepl("shares_soln",cols_actual))]
  names(data_snl_quantities_market) <- mapvalues(names(data_snl_quantities_market),
                                                 from=cols_actual,
                                                 to=paste0(cols_actual,"_actual"))
  data_snl_quantities_market$share <- data_snl_quantities_market$share_soln

  data_snl_quantities_market$quantities <- data_snl_quantities_market$share * data_snl_quantities_market$quantities_stateyeartype_plus_outsidegood_actual

  fwrite(data_this,file=paste0("output/Pricing/companyyear_counterfactuals_p_r_bar",scenario,".csv"))
  fwrite(data_snl_quantities_market,file=get_filename_case(paste0("output/Pricing/companyyear_counterfactuals_q_",scenario,".csv"),case))
  output_list <- list(data_this,data_snl_quantities_market)
  return(output_list)
}

estimateStateFEs()

solveEquilibrium <- function(scenario){
  if (grepl("pricing_multipleequilibria_",scenario)){
    scenario_multipleequilibria = scenario
    scenario = "actual"
  } else {
    scenario_multipleequilibria = ""
  }

  estimateCapitalAllocation(scenario)

  output_list <- loadData(scenario)
  data <- output_list[[1]]
  data_snl_quantities_market <- output_list[[2]]

  data <- solvePrimitives(data,scenario)

  data_this_all <- list()
  data_snl_quantities_market_sol_all <- list()
  i_year = 1

  years_all <- sort(unique(data$year))
  for (year_this in years_all){
    if (scenario_multipleequilibria == ""){
      output_list <- solveCounterfactuals(data,data_snl_quantities_market,scenario,year_this)
    } else if (grepl("pricing_multipleequilibria_",scenario_multipleequilibria)) {
      output_list <- solveCounterfactuals(data,data_snl_quantities_market,scenario_multipleequilibria,year_this)
    }
    data_this_all[[i_year]] <- output_list[[1]]
    data_snl_quantities_market_sol_all[[i_year]] <- output_list[[2]]

    i_year <- i_year + 1
  }
  data_this_all2 <- do.call(rbind,data_this_all)
  data_snl_quantities_market_sol_all2 <- do.call(rbind,data_snl_quantities_market_sol_all)

  if (case == 'costfunction'){
    fwrite(data_this_all2[,c('SNLSTATENTITYKEY','year',"REINSSTATEDOMICILED",'ceded_frac_liab','ceded_frac_liab_uncensored','ceded_frac_liab_estimated')],get_filename_case(paste0("output/CapitalAllocation/ceded_frac_liab_",scenario,".csv"),case))
  }

  return(list(data_this_all2,data_snl_quantities_market_sol_all2))
}

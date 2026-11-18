analysis_insurer_dir <- getwd()
analysis_demand_dir <- file.path(analysis_insurer_dir, "..", "Analysis_Demand")
source("../lib/r/Functions.R")

setwd(analysis_demand_dir)
source("code/RegulatoryCompetition_Analysis_Demand_01_CreateData.R")
setwd(analysis_insurer_dir)
source("code/RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R")
source("code/RegulatoryCompetition_Analysis_Insurer_05_Regulator_Functions.R")

estimateStateFEs()

kappa_counterfactual <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))
states_all <- sort(unique(kappa_counterfactual$REINSSTATEDOMICILED))

delta <- 0.0001

for (state_this in states_all){
  kappa_counterfactual <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))

  kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] <- kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] + delta

  kappa_counterfactual$u_st <- get_u_st_from_kappa(kappa_counterfactual)
  fwrite(kappa_counterfactual,get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_counterfactual_perturb_",state_this,".csv"),case))
}

calculate_tax_revenue <- function(data_this,scenario){
  if (case == 'costfunction'){
    data_reinsurance = data_this[,c("SNLSTATENTITYKEY",'year','REINSSTATEDOMICILED','ceded_frac_liab','ceded_frac_liab_actual')]
    names(data_reinsurance) = mapvalues(names(data_reinsurance),from=c("SNLSTATENTITYKEY","ceded_frac_liab"),to=c("CEDENTSNLSTATENTITYKEY",'ceded_frac_liab_estimated'))

    data_reinsurance_actual <- fread(get_filename_case(paste0("output/CapitalAllocation/ceded_frac_liab_actual.csv"),case))
    data_reinsurance_actual = data_reinsurance_actual[,ceded_frac_liab_estimated:=NULL]
    names(data_reinsurance_actual) = mapvalues(names(data_reinsurance_actual),from=c("SNLSTATENTITYKEY","ceded_frac_liab"),to=c("CEDENTSNLSTATENTITYKEY",'ceded_frac_liab_actual'))
  } else {
    data_reinsurance <- fread(get_filename_case(paste0("output/CapitalAllocation/ceded_frac_liab_",scenario,".csv"),case))
    data_reinsurance <- data_reinsurance[which(data_reinsurance$REINSSTATEDOMICILED != ""),]
  }

  data_insurerstateyr <- fread(get_filename_case("output/CapitalAllocation_insurerstateyear.csv",case))
  data_insurerstateyr <- data_insurerstateyr[which(data_insurerstateyr$REINSSTATEDOMICILED != ""),]

  data_cedent <- fread(get_filename_case(path.symlink("input/SNL_Financials.csv"),case))

  names(data_cedent) <- mapvalues(names(data_cedent),
                                  from=c("SNLSTATENTITYKEY"),
                                  to=c("CEDENTSNLSTATENTITYKEY"))

  data_cedent$TOTALLIAB <- data_cedent$TOTALLIAB / 1000

  data_insurerstateyr = data_insurerstateyr[,RESERVESGROSS:=NULL]
  data_tax <- merge(data_insurerstateyr,data_reinsurance,by=c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED"),all.x=TRUE)
  data_tax <- merge(data_tax,data_cedent,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)

  data_tax$amount_reinsured_estimated <- data_tax$ceded_frac_liab_estimated * data_tax$RESERVESGROSS

  data_tax_state <- data_tax %>% group_by(REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured_estimated = sum(amount_reinsured_estimated,na.rm=TRUE))

  data_tax_state_actual <- fread(get_filename_case("output/CapitalAllocation_reinsurerstateyear.csv",case))
  data_tax_state_actual <- data_tax_state_actual[,c("year","REINSSTATEDOMICILED","amount_reinsured")]

  if (case == 'costfunction'){
    data_tax_state_actual = data_tax[,c("year","REINSSTATEDOMICILED","ceded_frac_liab_actual",'RESERVESGROSS')]
    data_tax_state_actual$amount_reinsured = data_tax_state_actual$ceded_frac_liab_actual * data_tax_state_actual$RESERVESGROSS / 1000
    data_tax_state_actual = data_tax_state_actual %>% group_by(REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))
  }

  names(data_tax_state_actual) <- mapvalues(names(data_tax_state_actual),
                                            from=c("amount_reinsured"),
                                            to=c("amount_reinsured_actual"))

  data_tax_state <- merge(data_tax_state,data_tax_state_actual,by=c("year","REINSSTATEDOMICILED"),all.x=TRUE)

  data_tax_state$stateyr_tax_revenue <- data_tax_state$amount_reinsured_estimated * tau / 1000

  return(data_tax_state)
}

calculate_default_cost <- function(data_this,data_stateyr_surplus){
  data_this$default_prob_estimated <- 1 - pnorm((data_this$R_bar - data_this$mu) / data_this$sigma, mean=0, sd=1)

  data_this$default_expected_loss <- data_this$default_prob_estimated * (data_this$TOTALLIAB / 1000) * omega

  data_default_year <- data_this %>% group_by(year) %>% summarise(default_expected_loss = sum(default_expected_loss,na.rm=TRUE))

  data_quantities <- data_stateyr_surplus[,c("state","year","quantities_stateyeartype")]
  data_quantities <- data_quantities %>% group_by(year) %>% mutate(quantities_yeartype = sum(quantities_stateyeartype,na.rm=TRUE),
                                                                   numstates_yeartype = n_distinct(state,na.rm=TRUE))
  data_quantities$state_share_yeartype <- data_quantities$quantities_stateyeartype / data_quantities$quantities_yeartype

  names(data_quantities) <- mapvalues(names(data_quantities),
                                      from=c("quantities_stateyeartype","quantities_yeartype","numstates_yeartype","state_share_yeartype"),
                                      to=c("quantities_stateyeartype_default","quantities_yeartype_default","numstates_yeartype_default","state_share_yeartype_default"))

  data_stateyr_default <- merge(data_quantities,data_default_year,by=c("year"),all.x=TRUE)

  data_stateyr_default$stateyr_default_expected_loss <- data_stateyr_default$default_expected_loss * data_stateyr_default$state_share_yeartype_default

  data_this_default_prob_yr <- data_this %>% group_by(year) %>% summarise(default_prob = mean(default_prob_estimated,na.rm=TRUE) * 10000)
  data_stateyr_default <- merge(data_stateyr_default,
                                data_this_default_prob_yr,
                                by=c("year"),
                                all.x=TRUE)

  return(data_stateyr_default)
}

calculate_guaranty_fund_payout <- function(data_this,data_stateyr_surplus){
  data_this$z_estimated <- (data_this$R_bar - data_this$mu) / data_this$sigma
  data_this$phi_estimated <- dnorm(data_this$z)
  data_this$Phi_estimated <- pnorm(data_this$z, mean=0, sd=1)
  data_this$E_Ltilde_given_Ltilde_greater_Lbar = data_this$mu + (data_this$phi_estimated / (1 - data_this$Phi_estimated)) * data_this$sigma
  data_this$Prob_Ltilde_greater_Lbar = 1 - data_this$Phi_estimated

  data_this$guaranty_fund_payout = (data_this$TOTALLIAB / 1000) * ((data_this$price - data_this$E_Ltilde_given_Ltilde_greater_Lbar) + data_this$kappa * (1 + data_this$b)) * data_this$Prob_Ltilde_greater_Lbar

  data_guaranty_year <- data_this %>% group_by(year) %>% summarise(guaranty_fund_payout = sum(guaranty_fund_payout,na.rm=TRUE))

  data_quantities <- data_stateyr_surplus[,c("state","year","quantities_stateyeartype")]
  data_quantities <- data_quantities %>% group_by(year) %>% mutate(quantities_yeartype = sum(quantities_stateyeartype,na.rm=TRUE),
                                                                   numstates_yeartype = n_distinct(state,na.rm=TRUE))
  data_quantities$state_share_yeartype <- data_quantities$quantities_stateyeartype / data_quantities$quantities_yeartype

  names(data_quantities) <- mapvalues(names(data_quantities),
                                      from=c("quantities_stateyeartype","quantities_yeartype","numstates_yeartype","state_share_yeartype"),
                                      to=c("quantities_stateyeartype_guaranty","quantities_yeartype_guaranty","numstates_yeartype_guaranty","state_share_yeartype_guaranty"))

  data_stateyr_guaranty <- merge(data_quantities,data_guaranty_year,by=c("year"),all.x=TRUE)

  data_stateyr_guaranty$stateyr_guaranty <- data_stateyr_guaranty$guaranty_fund_payout * data_stateyr_guaranty$state_share_yeartype_guaranty

  return(data_stateyr_guaranty)
}

calculate_consumer_surplus <- function(data_this,data_snl_quantities_market_sol,scenario){
  data_demand <- fread(get_filename_case(path.symlink("input/Demand_All.csv"),case))

  data_snl_quantities_market_sol_this <- data_snl_quantities_market_sol[,c("SNLSTATENTITYKEY","amb_co_num","state","year","share","quantities","quantities_stateyeartype_plus_outsidegood_actual")]

  names(data_snl_quantities_market_sol_this) <- mapvalues(names(data_snl_quantities_market_sol_this),
                                                          from=c("share","quantities"),
                                                          to=c("share_new","quantities_new"))

  data_this_price <- data_this[,c("SNLSTATENTITYKEY","amb_co_num","year","price","price_actual")]

  names(data_this_price) <- mapvalues(names(data_this_price),
                                      from=c("price"),
                                      to=c("price_new"))

  data_demand2 <- merge(data_demand,data_snl_quantities_market_sol_this,by=c("SNLSTATENTITYKEY","amb_co_num","state","year"),all.x=TRUE,all.y=TRUE)
  data_demand2 <- merge(data_demand2,data_this_price,by=c("SNLSTATENTITYKEY","amb_co_num","year"),all.x=TRUE,all.y=TRUE)

  data_demand2$price <- data_demand2$price_new
  data_demand2$share <- data_demand2$share_new
  data_demand2$quantities <- data_demand2$quantities_new

  data_demand2 <- loadDemandData(data_demand2)
  data <- data_demand2
  rm(data_demand2)

  data$price_guess <- data$price

  data$price <- data$price_guess

  reg_demand <- loadDemandFull()

  beta_vec <- as.matrix(summary(reg_demand)$coefficients)
  data_mat <- as.matrix(data[,c("price","TOTALLIAB_ln_std","RatingNumeric_std","AUTHCONTROLLEVELRISKBASEDCAPRATIO_std","LEVERAGE_std","CASHSTINVESTTOLIAB_std","ROAECAPSURPLUS_std")])

  data_mat[,1] <- data_mat[,1] * V

  data$util_obs <- (data_mat %*% beta_vec)

  data$shares_0_product <- data$shares_0 / data$num_insurers_outsidegood
  data$shares_0_product_ln <- log(data$shares_0_product)

  if (scenario == "actual"){
    data$util_unobs <- data$shares_ln - data$shares_0_product_ln - data$util_obs
    data_util_unobs <- data[,c("SNLSTATENTITYKEY","amb_co_num","year","state","type","util_unobs")]
    saveRDS(data_util_unobs, file=get_filename_case("output/Regulator/ConsumerSurplus/util_unobs.RDS",case))
  }
  if (scenario != "actual"){
    data_util_unobs <- readRDS(get_filename_case("output/Regulator/ConsumerSurplus/util_unobs.RDS",case))
    data <- merge(data,data_util_unobs,by=c("SNLSTATENTITYKEY","amb_co_num","year","state","type"),all.x=TRUE)
  }

  data$util <- data$util_obs + data$util_unobs
  data$util_exp <- exp(data$util)

  data_stateyr <- data %>% group_by(state,year) %>% summarise(stateyr_util_mean = sum(util_exp,na.rm=TRUE),
                                                              price_mean = mean(price,na.rm=TRUE),
                                                              quantities_stateyeartype = sum(quantities,na.rm=TRUE))
  data_stateyr$stateyr_util_mean <- log(data_stateyr$stateyr_util_mean)

  data_stateyr$stateyr_util_mean <- data_stateyr$stateyr_util_mean / abs(beta_vec[1] / (V / 1000))

  data_stateyr_marketsize_ss <- data_snl_quantities_market_sol_this %>% group_by(state,year) %>% summarise(marketsize_num_distinct = n_distinct(quantities_stateyeartype_plus_outsidegood_actual,na.rm=TRUE))

  data_stateyr_marketsize <- data_snl_quantities_market_sol_this %>% group_by(state,year) %>% summarise(stateyr_util_marketsize = mean(quantities_stateyeartype_plus_outsidegood_actual,na.rm=TRUE))
  data_stateyr <- merge(data_stateyr,data_stateyr_marketsize,by=c("state","year"),all.x=TRUE)
  data_stateyr$stateyr_util_total <- data_stateyr$stateyr_util_mean * data_stateyr$stateyr_util_marketsize

  return(data_stateyr)
}

calculate_insurer_profit <- function(data_this,data_stateyr_surplus){
  data_this$Q_i = data_this$s_s_prime_numerator * V / 1000
  data_this$E_Ltilde_given_Ltilde_less_Lbar = data_this$mu + (data_this$phi_pdf / (data_this$Phi)) * data_this$sigma
  data_this$Prob_Ltilde_less_Lbar = data_this$Phi

  data_this$insurer_profit = data_this$Q_i * (data_this$price - data_this$E_Ltilde_given_Ltilde_less_Lbar) * data_this$Prob_Ltilde_less_Lbar - data_this$kappa * (data_this$b * data_this$Q_i + data_this$Q_i) * (1 - data_this$Prob_Ltilde_less_Lbar) - theta * data_this$kappa * (data_this$b * data_this$Q_i + data_this$Q_i) - tau * data_this$ceded_frac_liab * data_this$Q_i

  data_profit_year <- data_this %>% group_by(year) %>% summarise(insurer_profit = sum(insurer_profit,na.rm=TRUE))

  data_quantities <- data_stateyr_surplus[,c("state","year","quantities_stateyeartype")]
  data_quantities <- data_quantities %>% group_by(year) %>% mutate(quantities_yeartype = sum(quantities_stateyeartype,na.rm=TRUE),
                                                                   numstates_yeartype = n_distinct(state,na.rm=TRUE))
  data_quantities$state_share_yeartype <- data_quantities$quantities_stateyeartype / data_quantities$quantities_yeartype

  names(data_quantities) <- mapvalues(names(data_quantities),
                                      from=c("quantities_stateyeartype","quantities_yeartype","numstates_yeartype","state_share_yeartype"),
                                      to=c("quantities_stateyeartype_profit","quantities_yeartype_profit","numstates_yeartype_profit","state_share_yeartype_profit"))

  data_stateyr_profit <- merge(data_quantities,data_profit_year,by=c("year"),all.x=TRUE)

  data_stateyr_profit$stateyr_profit <- data_stateyr_profit$insurer_profit * data_stateyr_profit$state_share_yeartype_profit

  return(data_stateyr_profit)
}

computeStateRegulator <- function(scenario){
  kappa_counterfactual <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))

  if (grepl("counterfactual_perturb_",scenario)){
    state_this <- gsub("counterfactual_perturb_","",scenario)
    kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] <- kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] + delta

    kappa_counterfactual$u_st <- get_u_st_from_kappa(kappa_counterfactual)
    fwrite(kappa_counterfactual,get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_counterfactual_perturb_",state_this,".csv"),case))
  }

  if (grepl("counterfactual_captiveban_supply_",scenario)){
    state_this <- gsub("[0-9]","",gsub("counterfactual_captiveban_supply_","",scenario))
    delta <- 9999
    kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] <- kappa_counterfactual$kappa_f[which(kappa_counterfactual$REINSSTATEDOMICILED == state_this)] + delta

    kappa_counterfactual$u_st <- get_u_st_from_kappa(kappa_counterfactual)
    fwrite(kappa_counterfactual,get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_counterfactual_captiveban_supply_",state_this,".csv"),case))
  }

  output_list <- solveEquilibrium(scenario)
  data_this <- output_list[[1]]
  data_snl_quantities_market_sol <- output_list[[2]]

  fwrite(data_this,get_filename_case(paste0("output/scenario_data_this_",scenario_run,".csv"),case))
  fwrite(data_snl_quantities_market_sol,get_filename_case(paste0("output/scenario_data_snl_quantities_market_sol_",scenario_run,".csv"),case))

  solver_successful <- as.numeric(sum(as.numeric(data_this$nleqslv_termcd),na.rm=TRUE) == nrow(data_this))

  data_stateyr_surplus <- calculate_consumer_surplus(data_this,data_snl_quantities_market_sol,scenario)
  data_stateyr_surplus <- as.data.table(data_stateyr_surplus)

  data_stateyr_tax <- calculate_tax_revenue(data_this,scenario)

  state_names <- fread(get_filename_case("../raw/States/StateNames.csv",case))
  data_stateyr_tax <- merge(data_stateyr_tax,state_names,by=c("REINSSTATEDOMICILED"),all.x=TRUE)

  data_stateyr_default <- calculate_default_cost(data_this,data_stateyr_surplus)

  data_stateyr_guaranty <- calculate_guaranty_fund_payout(data_this,data_stateyr_surplus)

  data_stateyr_profit <- calculate_insurer_profit(data_this,data_stateyr_surplus)

  states_all <- sort(unique(state_names$state))
  years_all <- sort(unique(data_stateyr_default$year))
  data_stateyr <- merge(states_all,years_all)
  names(data_stateyr) <- c("state","year")

  data_stateyr <- merge(data_stateyr,data_stateyr_default,by=c("state","year"),all.x=TRUE)
  data_stateyr <- merge(data_stateyr,data_stateyr_guaranty,by=c("state","year"),all.x=TRUE)
  data_stateyr <- merge(data_stateyr,data_stateyr_profit,by=c("state","year"),all.x=TRUE)
  data_stateyr <- merge(data_stateyr,data_stateyr_tax,by=c("state","year"),all.x=TRUE)
  data_stateyr <- merge(data_stateyr,data_stateyr_surplus,by=c("state","year"),all.x=TRUE)

  data_stateyr$default_social_loss_only = data_stateyr$default_expected_loss
  data_stateyr$stateyr_default_social_loss_only = data_stateyr$stateyr_default_expected_loss

  if (case == 'guarantyfundfunding'){
    data_stateyr$default_expected_loss = data_stateyr$default_social_loss_only + (1 - frac_guarantyfund_insurerfunded) * data_stateyr$guaranty_fund_payout
    data_stateyr$stateyr_default_expected_loss = data_stateyr$stateyr_default_social_loss_only + (1 - frac_guarantyfund_insurerfunded) * data_stateyr$stateyr_guaranty

    data_stateyr$stateyr_profit = data_stateyr$stateyr_profit + frac_guarantyfund_insurerfunded * data_stateyr$stateyr_guaranty
  } else if (case == 'profitshare') {
    profit_weights = fread("../raw/Other/InvestmentAdvisersAssociation_AUM_ByState.csv")
    names(profit_weights) = mapvalues(names(profit_weights),
                                      from=c("U.S. States & Territories","Number of Firms","Non-Clerical Employees","Number of Clients","Total Assets Under Management"),
                                      to=c("state","investors_numfirms",'investors_numemployees','investors_numclients','investors_aum'))

    profit_weights$investors_aum_total = sum(profit_weights$investors_aum,na.rm=TRUE)
    profit_weights$investors_aum_stateshare = profit_weights$investors_aum / profit_weights$investors_aum_total

    data_stateyr = merge(x=data_stateyr,y=profit_weights,by=c("state"),all.x=TRUE)

    data_stateyr = data_stateyr %>% group_by(year) %>% mutate(num_states_yr = n_distinct(state,na.rm=TRUE))
    data_stateyr$stateyr_profit_equal = data_stateyr$num_states_yr * (data_stateyr$insurer_profit)

    data_stateyr$stateyr_profit_investor_weighted = data_stateyr$investors_aum_stateshare * (data_stateyr$insurer_profit)

    data_stateyr$stateyr_profit = data_stateyr$stateyr_profit_investor_weighted

  } else {
    data_stateyr$default_expected_loss = data_stateyr$default_social_loss_only + data_stateyr$guaranty_fund_payout
    data_stateyr$stateyr_default_expected_loss = data_stateyr$stateyr_default_social_loss_only + data_stateyr$stateyr_guaranty
  }

  data_stateyr$solver_successful <- solver_successful

  return(data_stateyr)
}

scenario = "actual"
data_stateyr_actual <- computeStateRegulator(scenario)

data_stateyr_actual_output <- data_stateyr_actual

primitives <- fread(get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))
muavg <- abs(round(mean(primitives$mu,na.rm=TRUE),digits=2))
sigmaavg <- abs(round(mean(primitives$sigma,na.rm=TRUE),digits=2))

names(data_stateyr_actual)[which(!names(data_stateyr_actual) %in% c("state","year"))] <- paste0(names(data_stateyr_actual)[which(!names(data_stateyr_actual) %in% c("state","year"))],"_actual")

if (case %in% cases_perturbations){
start_time = Sys.time()

data_perturbations_all <- list()
i_list <- 1
for (i_state in 1:length(states_all)){
  state_this <- states_all[i_state]
  scenario = paste0("counterfactual_perturb_",state_this)
  data_stateyr <- computeStateRegulator(scenario)

  data_stateyr$scenario <- scenario
  data_stateyr$scenario_perturb_state <- state_this
  data_perturbations_all[[i_list]] <- data_stateyr
  i_list <- i_list + 1
}
data_perturbations_all <- do.call(rbind,data_perturbations_all)

state_names <- fread(get_filename_case("../raw/States/StateNames.csv",case))
data_perturbations_all <- as.data.table(data_perturbations_all)[,REINSSTATEDOMICILED:=NULL]
data_perturbations_all <- merge(data_perturbations_all,state_names,by=c("state"),all.x=TRUE)

data_perturbations_all <- data_perturbations_all[which(data_perturbations_all$REINSSTATEDOMICILED == data_perturbations_all$scenario_perturb_state),]

data_perturbations_all <- merge(data_perturbations_all,data_stateyr_actual,by=c("state","year"),all.x=TRUE)

data_perturbations_all$stateyr_tax_revenue_delta <- data_perturbations_all$stateyr_tax_revenue - data_perturbations_all$stateyr_tax_revenue_actual

data_perturbations_all$stateyr_default_expected_loss_delta <- data_perturbations_all$stateyr_default_expected_loss - data_perturbations_all$stateyr_default_expected_loss_actual
data_perturbations_all$stateyr_guaranty_delta <- data_perturbations_all$stateyr_guaranty - data_perturbations_all$stateyr_guaranty_actual
data_perturbations_all$stateyr_default_social_loss_delta <- data_perturbations_all$stateyr_default_social_loss_only - data_perturbations_all$stateyr_default_social_loss_only_actual

data_perturbations_all$default_prob_delta <- data_perturbations_all$default_prob - data_perturbations_all$default_prob_actual
data_perturbations_all$default_expected_loss_delta <- (data_perturbations_all$default_expected_loss - data_perturbations_all$default_expected_loss_actual)

data_perturbations_all$stateyr_util_total_delta <- data_perturbations_all$stateyr_util_total - data_perturbations_all$stateyr_util_total_actual
data_perturbations_all$price_mean_delta <- data_perturbations_all$price_mean - data_perturbations_all$price_mean_actual

data_perturbations_all$stateyr_profit_delta <- data_perturbations_all$stateyr_profit - data_perturbations_all$stateyr_profit_actual

fwrite(data_perturbations_all,file="output/Regulator/data_perturbations_all.csv")

reg_lambda_2 <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta | 0 | 0 | state + year, data=data_perturbations_all)

reg_lambda_2_yr <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta | year | 0 | state + year, data=data_perturbations_all)

reg_lambda_3 <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta | 0 | 0 | state + year, data=data_perturbations_all)

reg_lambda_3_yr <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta | year | 0 | state + year, data=data_perturbations_all)

stargazer(reg_lambda_2,reg_lambda_2_yr,
          dep.var.labels=c(" "," "),
          covariate.labels = c("Default Cost","Consumer Surplus"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          add.lines=list(c("Year FEs","","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/reg_lambdas_2.tex"),case))

stargazer(reg_lambda_2,reg_lambda_2_yr,reg_lambda_3,reg_lambda_3_yr,
          dep.var.labels=c(" "," "),
          covariate.labels = c("Default Cost",
                               "Consumer Surplus"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          add.lines=list(c("Year FEs","","X","","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/reg_lambdas.tex"),case))

ggplot(data = data_perturbations_all) +
  geom_histogram(aes(x=`stateyr_tax_revenue_delta` * (0.01 / delta)),bins=6) +
  xlab(("Change in Tax Revenues per 1% Change in Capital Rate (Mil. USD)")) + ylab("Frequency") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15))
ggsave(get_filename_case("output/Regulator/hist_partial_derivatives_tax.png",case),width=10,height=7,dpi=300)

ggplot(data = data_perturbations_all) +
  geom_histogram(aes(x=`stateyr_default_expected_loss_delta` * (0.01 / delta)),bins=6) +
  xlab(("Change in Default Costs per 1% Change in Capital Rate (Mil. USD)")) + ylab("Frequency") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15))
ggsave(get_filename_case("output/Regulator/hist_partial_derivatives_default.png",case),width=10,height=7,dpi=300)

ggplot(data = data_perturbations_all) +
  geom_histogram(aes(x=`stateyr_util_total_delta` * (0.01 / delta)),bins=6) +
  xlab(("Change in Consumer Surplus per 1% Change in Capital Rate (Mil. USD)")) + ylab("Frequency") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15))
ggsave(get_filename_case("output/Regulator/hist_partial_derivatives_util.png",case),width=10,height=7,dpi=300)

partialderivvttax = round(abs(data_perturbations_all$stateyr_tax_revenue_delta[which(data_perturbations_all$state == "Vermont" & data_perturbations_all$year == 2019)] * (0.01 / delta)),digits=0)

reg_lambda_4 <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta | 0 | 0 | state + year, data=data_perturbations_all)

reg_lambda_4_yr <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta | year | 0 | state + year, data=data_perturbations_all)

if (case == 'guarantyfundfunding'){
  reg_lambda_4 <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta | 0 | 0 | state + year, data=data_perturbations_all)

  reg_lambda_4_yr <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta | year | 0 | state + year, data=data_perturbations_all)
}

perturbation_correlation = rcorr(as.matrix(data_perturbations_all[,c("stateyr_tax_revenue_delta",
                                                                      "stateyr_default_expected_loss_delta",
                                                                      "stateyr_util_total_delta",
                                                                      "stateyr_profit_delta",
                                                                      "stateyr_guaranty_delta",
                                                                      "stateyr_default_social_loss_delta")]))
perturbation_correlation = as.data.frame(perturbation_correlation$r)
rownames(perturbation_correlation) = c("Tax","Total Default Cost","Consumer Surplus","Insurer Profit","Guaranty Default Cost","Social Default Cost")

profit_weights = fread("../raw/Other/InvestmentAdvisersAssociation_AUM_ByState.csv")
names(profit_weights) = mapvalues(names(profit_weights),
                                  from=c("U.S. States & Territories","Number of Firms","Non-Clerical Employees","Number of Clients","Total Assets Under Management"),
                                  to=c("state","investors_numfirms",'investors_numemployees','investors_numclients','investors_aum'))

profit_weights$investors_aum_total = sum(profit_weights$investors_aum,na.rm=TRUE)
profit_weights$investors_aum_stateshare = profit_weights$investors_aum / profit_weights$investors_aum_total

profit_weights = merge(profit_weights,data_perturbations_all[which(data_perturbations_all$year == 2019),c("state_share_yeartype_profit","state")],all.x=TRUE,all.y=TRUE,by=c("state"))

corr_profit_investor_consumer_weights <- rcorr(x = profit_weights$investors_aum_stateshare,
                                               y = profit_weights$state_share_yeartype_profit)$r[1,2]

if (case == 'profitshare'){

  reg_lambda_4_profitshare_investor_weighted <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta_investor_weighted | 0 | 0 | state + year, data=data_perturbations_all)

  reg_lambda_4_profitshare_investor_weighted_yr <- felm(stateyr_tax_revenue_delta ~ 0 + stateyr_default_expected_loss_delta + stateyr_util_total_delta + stateyr_profit_delta_investor_weighted | year | 0 | state + year, data=data_perturbations_all)

  stargazer(reg_lambda_4_profitshare_investor_weighted,
            reg_lambda_4_profitshare_investor_weighted_yr,
            dep.var.labels=c(" "," "," "," "),
            covariate.labels = c("Default Cost",
                                 "Consumer Surplus",
                                 "Producer Surplus"),
            style="aer",
            omit.table.layout = "n",
            omit.stat=c("ser","adj.rsq"),
            omit = "cons",
            float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
            no.space = TRUE,
            header = FALSE,
            out=get_filename_case(paste0("output/Regulator/reg_lambdas_producersurplus_alternative_weights.tex"),case))

}

stargazer(perturbation_correlation,
          summary = FALSE,
          covariate.labels = c("Variable","Tax","Default Cost","Consumer Surplus","Insurer Profit","Guaranty Cost"),
          style="aer",
          float=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/perturbation_correlation.tex"),case))

stargazer(reg_lambda_2,reg_lambda_3,reg_lambda_4,
          dep.var.labels=c(" "," "," "," "," "),
          covariate.labels = c("Default Cost",
                               "Consumer Surplus",
                               "Producer Surplus"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/reg_lambdas_producersurplus.tex"),case))

saveRDS(reg_lambda_2, file=get_filename_case(paste0("output/Regulator/reg_lambdas_2_components.RDS"),case))
saveRDS(reg_lambda_3, file=get_filename_case(paste0("output/Regulator/reg_lambdas_3_components.RDS"),case))
saveRDS(reg_lambda_4, file=get_filename_case(paste0("output/Regulator/reg_lambdas_4_components.RDS"),case))
}

if (!case %in% cases_perturbations){
  reg_lambda_3 <- readRDS(get_filename_case(paste0("output/Regulator/reg_lambdas_3_components.RDS"),'baseline'))
  reg_lambda_4 <- readRDS(get_filename_case(paste0("output/Regulator/reg_lambdas_4_components.RDS"),'baseline'))
}

calculate_table_components <- function(data_stateyr_federal_all){
  data_federalyr <- data_stateyr_federal_all %>% group_by(scenario,federal_rate,year) %>% summarise(stateyr_default_expected_loss = sum(stateyr_default_expected_loss,na.rm=TRUE),
                                                                                                    stateyr_tax_revenue = sum(stateyr_tax_revenue,na.rm=TRUE),
                                                                                                    stateyr_guaranty = sum(stateyr_guaranty,na.rm=TRUE),
                                                                                                    stateyr_profit = sum(stateyr_profit,na.rm=TRUE),
                                                                                                    amount_reinsured_estimated = sum(amount_reinsured_estimated,na.rm=TRUE),
                                                                                                    stateyr_util_total = sum(stateyr_util_total,na.rm=TRUE),
                                                                                                    quantities_yeartype = sum(quantities_stateyeartype,na.rm=TRUE),
                                                                                                    price_mean = mean(price_mean,na.rm=TRUE),
                                                                                                    default_prob = mean(default_prob,na.rm=TRUE))

  data_federalyr$federal_tax_revenue <- data_federalyr$quantities_yeartype * V / 1000 * tau_direct_premiums

  if (!case %in% cases_perturbations){
    reg_lambda_3 <- readRDS(get_filename_case(paste0("output/Regulator/reg_lambdas_3_components.RDS"),'baseline'))
  }

  lambda_1 <- (-1) * summary(reg_lambda_3)$coefficients[1,1]
  lambda_2 <- (-1) * summary(reg_lambda_3)$coefficients[2,1]

  data_federalyr$total_welfare <- (lambda_1 * data_federalyr$stateyr_default_expected_loss + lambda_2 * data_federalyr$stateyr_util_total)

  if (!case %in% cases_perturbations){
    reg_lambda_4 <- readRDS(get_filename_case(paste0("output/Regulator/reg_lambdas_4_components.RDS"),'baseline'))
  }

  lambda_1 <- (-1) * summary(reg_lambda_4)$coefficients[1,1]
  lambda_2 <- (-1) * summary(reg_lambda_4)$coefficients[2,1]
  lambda_3 <- (-1) * summary(reg_lambda_4)$coefficients[3,1]

  data_federalyr$total_welfare_with_profits <- (lambda_1 * data_federalyr$stateyr_default_expected_loss + lambda_2 * data_federalyr$stateyr_util_total + lambda_3 * data_federalyr$stateyr_profit)

  data_federalyr <- as.data.table(data_federalyr)[,scenario:=NULL]
  data_federalyr <- data_federalyr[,c("federal_rate","year","stateyr_default_expected_loss","default_prob","stateyr_tax_revenue","federal_tax_revenue","amount_reinsured_estimated",
                                      "stateyr_util_total","quantities_yeartype","price_mean","total_welfare","total_welfare_with_profits","stateyr_guaranty","stateyr_profit")]

  names(data_federalyr) <- c("Scenario","Year","Default Loss","Default Prob","State Revenue","Federal Revenue","Captive Size",
                             "Consumer Surplus","Quantity","Price","Welfare","Welfare with Profits","Guaranty","Profits")

  data_federalyr$Quantity <- data_federalyr$Quantity / (10^6)

  data_federalyr <- data_federalyr[which(data_federalyr$Year < 2020),]

  return(data_federalyr)
}

data_stateyr_actual_output$scenario = "actual"
data_stateyr_actual_output$federal_rate = "actual"

data_federalyr_actual <- calculate_table_components(data_stateyr_actual_output)
data_federalyr_actual_output = data_federalyr_actual
data_federalyr_actual_output$`Default Cost` = data_federalyr_actual_output$`Default Loss`
data_federalyr_actual_output$Tax = data_federalyr_actual_output$`State Revenue`
data_federalyr_actual_output$`Producer Surplus` = data_federalyr_actual_output$Profits

stargazer(as.data.table(data_federalyr_actual_output)[,c("Year","Default Cost","Default Prob","Tax","Consumer Surplus","Producer Surplus","Quantity","Price")],
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          digit.separator = "",
          out=get_filename_case(paste0("output/Regulator/federalyr_actual.tex"),case))

fwrite(data_federalyr_actual_output,file=get_filename_case(paste0("output/Regulator/data_federalyr_actual_output.csv"),'baseline'))

lambda1 <- round(abs(summary(reg_lambda_3)$coefficients[1,1]),digits=2)
lambda2 <- round(abs(summary(reg_lambda_3)$coefficients[2,1]),digits=2)
regulatorregrsq = summary(reg_lambda_3)$r.squared * 100

defaultlossobseq <- round(data_federalyr_actual$`Default Loss`[which(data_federalyr_actual$Year == 2019)],digits=2)

defaultprobobseq <- round(data_federalyr_actual$`Default Prob`[which(data_federalyr_actual$Year == 2019)],digits=0)

staterevenueobseq <- round(data_federalyr_actual$`State Revenue`[which(data_federalyr_actual$Year == 2019)],digits=2)

federalrevenueobseq <- round(data_federalyr_actual$`Federal Revenue`[which(data_federalyr_actual$Year == 2019)],digits=2)

captivesizeobseq <- round(data_federalyr_actual$`Captive Size`[which(data_federalyr_actual$Year == 2019)],digits=2)

surplusobseq <- round(data_federalyr_actual$`Consumer Surplus`[which(data_federalyr_actual$Year == 2019)],digits=2)

priceobseq <- round(data_federalyr_actual$`Price`[which(data_federalyr_actual$Year == 2019)],digits=2)

quantityobseq <- round(data_federalyr_actual$`Quantity`[which(data_federalyr_actual$Year == 2019)],digits=2)

guarantyobseq = round(data_federalyr_actual$Guaranty[which(data_federalyr_actual$Year == 2019)],digits=0)

profitsobseq = round(data_federalyr_actual$Profits[which(data_federalyr_actual$Year == 2019)],digits=0)

welfareobseq <- round(data_federalyr_actual$`Welfare`[which(data_federalyr_actual$Year == 2019)],digits=2)

findMaxWelfare <- function(data_federalyr_1yr){

  cap_rate_max_welfare <- data_federalyr_1yr$Scenario[which(round(data_federalyr_1yr$Welfare,digits=0) == max(round(data_federalyr_1yr$Welfare,digits=0),na.rm=TRUE),)]
  return(cap_rate_max_welfare)
}

findMaxWelfareSocialPlanner <- function(data_federalyr_1yr){

  data_federalyr_1yr$welfare_socialplanner = data_federalyr_1yr$`Default Loss Change` + data_federalyr_1yr$`Consumer Surplus Change`
  cap_rate_max_welfare <- data_federalyr_1yr$Scenario[which(round(data_federalyr_1yr$welfare_socialplanner,digits=0) == max(round(data_federalyr_1yr$welfare_socialplanner,digits=0),na.rm=TRUE),)]
  return(cap_rate_max_welfare)
}

if (file.exists(paste0("output/scenario_data_this_",scenario_run,".csv"))) {
  file.remove(paste0("output/scenario_data_this_",scenario_run,".csv"))
}
if (file.exists(paste0("output/scenario_data_snl_quantities_market_sol_",scenario_run,".csv"))) {
  file.remove(paste0("output/scenario_data_snl_quantities_market_sol_",scenario_run,".csv"))
}

opco_capreq = kappa_h
opco_capreq_floor = 0.05
opco_capreq_ceiling = 0.35
step_size = 0.01
step_size_expand = 0.05
opco_capreq_floor_expand = 0
opco_capreq_ceiling_expand = 0.80

federal_rates_all <- c(seq(floor(opco_capreq/step_size)*step_size,opco_capreq_floor,(-1)*step_size),
                       seq(opco_capreq_floor-step_size_expand,opco_capreq_floor_expand,(-1)*step_size_expand),
                       seq(ceiling(opco_capreq/step_size)*step_size,opco_capreq_ceiling-step_size,step_size),
                       seq(opco_capreq_ceiling,opco_capreq_ceiling_expand,step_size_expand))

data_stateyr_federal_all <- list()
i_federal <- 1

for (federal_rates_this in federal_rates_all){
  scenario <- paste0("counterfactual_federal_",federal_rates_this)

  tryCatch({
    res <- withTimeout({
      data_stateyr_federal_this <- computeStateRegulator(scenario)
      data_stateyr_federal_this$scenario <- scenario
      data_stateyr_federal_this$federal_rate <- federal_rates_this
      data_stateyr_federal_all[[i_federal]] <- data_stateyr_federal_this
      i_federal <- i_federal + 1;
    }, timeout=21600);
  }, TimeoutException=function(ex) {
    out_message = paste0("Timed out. Skipping ",federal_rates_this,"\n")
  });
}
data_stateyr_federal_all <- do.call(rbind,data_stateyr_federal_all)

data_stateyr_federal_all = data_stateyr_federal_all[order(data_stateyr_federal_all$federal_rate),]

data_federalyr <- calculate_table_components(data_stateyr_federal_all)

output_list <- compare_welfare(data_federalyr,2019)
data_federalyr_with_actuals <- output_list[[1]]
data_federalyr_1yr <- output_list[[2]]

output_list_levels <- compare_welfare(data_federalyr,2019,change="levels")
data_federalyr_with_actuals_levels <- output_list_levels[[1]]
data_federalyr_1yr_levels <- output_list_levels[[2]]

output_list_levels_2012 <- compare_welfare(data_federalyr,2012,change="levels")
data_federalyr_with_actuals_levels_2012 <- output_list_levels_2012[[1]]
data_federalyr_1yr_levels_2012 <- output_list_levels_2012[[2]]

output_list_levels_2008 <- compare_welfare(data_federalyr,2009,change="levels")
data_federalyr_with_actuals_levels_2008 <- output_list_levels_2008[[1]]
data_federalyr_1yr_levels_2008 <- output_list_levels_2008[[2]]

data_federalyr_1yr <- data_federalyr_1yr[order(Scenario),]

stargazer(as.data.table(data_federalyr_1yr),
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE, header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_federal_1yr_allscenarios.tex"),case))

fwrite(data_federalyr_1yr_levels,file=get_filename_case(paste0("output/Regulator/data_federalyr_changes.csv"),case))

year_this = 2019

data_federalyr_1yr_levels_test = data_federalyr[which(data_federalyr$Year == year_this),]

names(data_federalyr_1yr_levels_test) = gsub(" ","",names(data_federalyr_1yr_levels_test))

data_federalyr_1yr_levels_test = data_federalyr_1yr_levels_test[order(Scenario),]

data_federalyr_1yr_levels_test$DefaultLoss = data_federalyr_1yr_levels_test$DefaultLoss - data_federalyr_actual$`Default Loss`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$DefaultProb = data_federalyr_1yr_levels_test$DefaultProb - data_federalyr_actual$`Default Prob`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$ConsumerSurplus = data_federalyr_1yr_levels_test$ConsumerSurplus - data_federalyr_actual$`Consumer Surplus`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$FederalRevenue = data_federalyr_1yr_levels_test$FederalRevenue - data_federalyr_actual$`Federal Revenue`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$CaptiveSize = data_federalyr_1yr_levels_test$CaptiveSize - data_federalyr_actual$`Captive Size`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$Quantity = data_federalyr_1yr_levels_test$Quantity - data_federalyr_actual$`Quantity`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$Profits = data_federalyr_1yr_levels_test$Profits - data_federalyr_actual$`Profits`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$Guaranty = data_federalyr_1yr_levels_test$Guaranty - data_federalyr_actual$`Guaranty`[which(data_federalyr_actual$Year == year_this)]
data_federalyr_1yr_levels_test$Price = data_federalyr_1yr_levels_test$Price - data_federalyr_actual$`Price`[which(data_federalyr_actual$Year == year_this)]

data_federalyr_1yr_levels_test$Label = NA

data_federalyr_1yr_levels_test = data_federalyr_1yr_levels_test[which(data_federalyr_1yr_levels_test$Scenario <= 0.50),]
data_federalyr_1yr_levels_test = data_federalyr_1yr_levels_test[which(data_federalyr_1yr_levels_test$Scenario >= 0.05),]

eqn_inequalities = data.frame(matrix(nrow = nrow(data_federalyr_1yr_levels_test)^2,
                                     ncol = 4))
names(eqn_inequalities) = c("Scenario","Scenario_comparison","lambda_cutoff","sign")

for (i in 1:nrow(eqn_inequalities)){
  i_scenario = floor((i-1) / nrow(data_federalyr_1yr_levels_test)) + 1
  i_scenario_comparison = ((i-1) %% nrow(data_federalyr_1yr_levels_test)) + 1

  eqn_inequalities$Scenario[i] = data_federalyr_1yr_levels_test$Scenario[i_scenario]
  eqn_inequalities$Scenario_comparison[i] = data_federalyr_1yr_levels_test$Scenario[i_scenario_comparison]

  default_scenario = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == eqn_inequalities$Scenario[i])]
  default_scenario_comparison = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == eqn_inequalities$Scenario_comparison[i])]
  surplus_scenario = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == eqn_inequalities$Scenario[i])]
  surplus_scenario_comparison = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == eqn_inequalities$Scenario_comparison[i])]

  lambda_cutoff_this = (surplus_scenario_comparison - surplus_scenario) / (default_scenario - default_scenario_comparison)
  if (default_scenario > default_scenario_comparison){
    sign_this = ">"
  }
  if (default_scenario < default_scenario_comparison){
    sign_this = "<"
  }
  if (default_scenario == default_scenario_comparison){
    sign_this = "="
  }
  eqn_inequalities$lambda_cutoff[i] = lambda_cutoff_this
  eqn_inequalities$sign[i] = sign_this
}

eqn_inequalities_min = eqn_inequalities[which(eqn_inequalities$sign == ">"),] %>% group_by(Scenario) %>% summarise(lambda_cutoff = max(lambda_cutoff,na.rm=TRUE))
eqn_inequalities_max = eqn_inequalities[which(eqn_inequalities$sign == "<"),] %>% group_by(Scenario) %>% summarise(lambda_cutoff = min(lambda_cutoff,na.rm=TRUE))

eqn_inequalities_min$lambda_cutoff = round((-1) * eqn_inequalities_min$lambda_cutoff,digits=2)
eqn_inequalities_max$lambda_cutoff = round((-1) * eqn_inequalities_max$lambda_cutoff,digits=2)

eqn_inequalities_all = merge(eqn_inequalities_max,
                             eqn_inequalities_min,
                             by=c("Scenario"),
                             all.x=TRUE,all.y=TRUE)
names(eqn_inequalities_all) = c("Scenario","Min. LambdaRatio","Max. LambdaRatio")

eqn_inequalities_all$Admissible = as.numeric((eqn_inequalities_all$`Min. LambdaRatio` < eqn_inequalities_all$`Max. LambdaRatio`) | ((is.na(eqn_inequalities_all$`Min. LambdaRatio`) | is.na(eqn_inequalities_all$`Max. LambdaRatio`))))

eqn_inequalities_all$`Min. LambdaRatio`[which(eqn_inequalities_all$Admissible == 0)] = NA
eqn_inequalities_all$`Max. LambdaRatio`[which(eqn_inequalities_all$Admissible == 0)] = NA

data_federalyr_actual_yearthis = data_federalyr_actual[which(data_federalyr_actual$Year == year_this),]
names(data_federalyr_actual_yearthis) = gsub(" ","",names(data_federalyr_actual_yearthis))

actual_x = 0
actual_y = 0

lambda1 = (-1) * summary(reg_lambda_3)$coefficients[1]
lambda2 = (-1) * summary(reg_lambda_3)$coefficients[2]
lambda_ratio = (-1) * lambda1 / lambda2

tradeoffline_slope = lambda_ratio
tradeoffline_intercept = actual_y - tradeoffline_slope * actual_x

cap_rate_max_welfare_yearthis <- findMaxWelfare(data_federalyr_1yr_levels_test)
cap_rate_max_welfare_yearthis <- cap_rate_max_welfare_yearthis[1]

federal_x = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare_yearthis)]
federal_y = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare_yearthis)]

data_federalyr_1yr_levels_test$Label[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare_yearthis)] = "Captive-Implied"

tradeoffline_federal_slope = lambda_ratio
tradeoffline_federal_intercept = federal_y - tradeoffline_slope * federal_x

tradeoffline_federal_label_y = max(data_federalyr_1yr_levels_test$ConsumerSurplus)
tradeoffline_federal_label_x = (tradeoffline_federal_label_y - tradeoffline_federal_intercept) / tradeoffline_federal_slope

welfare_planner = data_federalyr_1yr_levels_test$DefaultLoss + data_federalyr_1yr_levels_test$ConsumerSurplus
cap_rate_planner = data_federalyr_1yr_levels_test$Scenario[which(data_federalyr_1yr_levels_test$DefaultLoss + data_federalyr_1yr_levels_test$ConsumerSurplus == max(welfare_planner,na.rm=TRUE))]

planner_x = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_planner)]
planner_y = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_planner)]

tradeoffline_planner_slope = -1
tradeoffline_planner_intercept = planner_y - tradeoffline_planner_slope * planner_x

opco_capreq_rounded = round(opco_capreq/0.005,digits=0)*0.005
opco_capreq_rounded_diff = round(abs(as.numeric(data_federalyr_1yr_levels_test$Scenario) - opco_capreq_rounded),digits=3)
opco_capreq_rounded_diff_pos = max(which(opco_capreq_rounded_diff == min(opco_capreq_rounded_diff,na.rm=TRUE)),na.rm=TRUE)

naic_x = (-1) * data_federalyr_1yr_levels_test$DefaultLoss[opco_capreq_rounded_diff_pos]
naic_y = data_federalyr_1yr_levels_test$ConsumerSurplus[opco_capreq_rounded_diff_pos]

data_federalyr_1yr_levels_test$Label[which(data_federalyr_1yr_levels_test$Scenario == opco_capreq_rounded)] = "Opco-Implied"

capreq_leftmost = data_federalyr_1yr_levels_test$Scenario[which(data_federalyr_1yr_levels_test$DefaultLoss == max(data_federalyr_1yr_levels_test$DefaultLoss))]

possibilitiesfrontier_x = (-1) * data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == capreq_leftmost)]
possibilitiesfrontier_y = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == capreq_leftmost)]

data_federalyr_1yr_levels_test$Admissible_plot = as.numeric(data_federalyr_1yr_levels_test$Scenario %in% eqn_inequalities_all$Scenario[which(eqn_inequalities_all$Admissible == 1)])
data_federalyr_1yr_levels_test$DefaultLoss_admissible = NA
data_federalyr_1yr_levels_test$DefaultLoss_admissible[which(data_federalyr_1yr_levels_test$Admissible_plot == 1)] = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Admissible_plot == 1)]
data_federalyr_1yr_levels_test$ConsumerSurplus_admissible = NA
data_federalyr_1yr_levels_test$ConsumerSurplus_admissible[which(data_federalyr_1yr_levels_test$Admissible_plot == 1)] = data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Admissible_plot == 1)]

if (case == 'baseline'){
ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier")) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) +
  scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_1.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier"), ) +
  geom_point(aes(x=actual_x,y=actual_y), size=4) +
  geom_text(aes(x=actual_x, y=actual_y, label="State"),size=8,hjust=-0.1) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) + scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_2.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier"), ) +
  geom_point(aes(x=actual_x,y=actual_y), size=4) +
  geom_text(aes(x=actual_x, y=actual_y, label="State"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_federal_slope,
                  intercept = tradeoffline_federal_intercept,
                  linetype = "Regulator's Indifference Curve")) +
  geom_point(aes(x=federal_x,y=federal_y), shape=5, size=4) +
  geom_text(aes(x=federal_x, y=federal_y, label="Federal"),size=8,hjust=-0.1) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) + scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_3.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier"), ) +
  geom_point(aes(x=actual_x,y=actual_y), size=4) +
  geom_text(aes(x=actual_x, y=actual_y, label="State"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_federal_slope,
                  intercept = tradeoffline_federal_intercept,
                  linetype = "Regulator's Indifference Curve")) +
  geom_point(aes(x=federal_x,y=federal_y), shape=5, size=4) +
  geom_text(aes(x=federal_x, y=federal_y, label="Federal"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_planner_slope,
                  intercept = tradeoffline_planner_intercept,
                  linetype = "Planner's Indifference Curve")) +
  geom_point(aes(x=planner_x,y=planner_y), shape=4, size=4) +
  geom_text(aes(x=planner_x, y=planner_y, label="Planner"),size=8,hjust=-0.1) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) + scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_4.png",case),width=10,height=7,dpi=300)

planner_redist_x = data_federalyr_1yr_levels_test$DefaultLoss[which.min(abs(data_federalyr_1yr_levels_test$Scenario - 0.12))]
planner_redist_y = data_federalyr_1yr_levels_test$ConsumerSurplus[which.min(abs(data_federalyr_1yr_levels_test$Scenario - 0.12))]

tradeoffline_planner_redist_slope = -0.02
tradeoffline_planner_redist_intercept = planner_redist_y - tradeoffline_planner_redist_slope * planner_redist_x

ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier"), ) +
  geom_point(aes(x=actual_x,y=actual_y), size=4) +
  geom_text(aes(x=actual_x, y=actual_y, label="State"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_federal_slope,
                  intercept = tradeoffline_federal_intercept,
                  linetype = "Regulator's Indifference Curve")) +
  geom_point(aes(x=federal_x,y=federal_y), shape=5, size=4) +
  geom_text(aes(x=federal_x, y=federal_y, label="Federal"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_planner_redist_slope,
                  intercept = tradeoffline_planner_redist_intercept,
                  linetype = "Planner's Indifference Curve")) +
  geom_point(aes(x=planner_redist_x,y=planner_redist_y), shape=4, size=4) +
  geom_text(aes(x=planner_redist_x, y=planner_redist_y, label="Planner"),size=8,vjust=-0.5) +
  annotate("segment",
           x = federal_x * 0.9, y = federal_y * 0.9,
           xend = actual_x + 800, yend = actual_y -50,
           arrow = arrow(length = unit(1.5, "cm")),
           color = "darkgreen", size = 7
  ) +
  annotate("text",
           x = (federal_x + actual_x) / 2,
           y = (federal_y + actual_y) / 2 - 80,
           label = "Competition",
           color = "darkgreen",
           size = 8
  ) +
  annotate("text",
           x = 6000,
           y = tradeoffline_planner_redist_slope * 6000 + tradeoffline_planner_redist_intercept + 120,
           label = "Redistributive Planner's\n Indifference Curve",
           size = 8,
           hjust = 1
  ) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) + scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_planner_redist.png",case),width=10,height=7,dpi=300)

federal_strict_x = data_federalyr_1yr_levels_test$DefaultLoss[which.min(abs(data_federalyr_1yr_levels_test$Scenario - 0.50))]
federal_strict_y = data_federalyr_1yr_levels_test$ConsumerSurplus[which.min(abs(data_federalyr_1yr_levels_test$Scenario - 0.50))]

tradeoffline_federal_strict_slope = -5
tradeoffline_federal_strict_intercept = federal_strict_y - tradeoffline_federal_strict_slope * federal_strict_x

ggplot(data = data_federalyr_1yr_levels_test) +
  geom_line(aes(x=`DefaultLoss_admissible`, y=`ConsumerSurplus_admissible`, linetype="Possibility Frontier"), ) +
  geom_point(aes(x=actual_x,y=actual_y), size=4) +
  geom_text(aes(x=actual_x, y=actual_y, label="State"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_federal_strict_slope,
                  intercept = tradeoffline_federal_strict_intercept,
                  linetype = "Regulator's Indifference Curve")) +
  geom_point(aes(x=federal_strict_x,y=federal_strict_y), shape=5, size=4) +
  geom_text(aes(x=federal_strict_x, y=federal_strict_y, label="Federal"),size=8,hjust=-0.1) +
  geom_abline(aes(slope = tradeoffline_planner_slope,
                  intercept = tradeoffline_planner_intercept,
                  linetype = "Planner's Indifference Curve")) +
  geom_point(aes(x=planner_x,y=planner_y), shape=4, size=4) +
  geom_text(aes(x=planner_x, y=planner_y, label="Planner"),size=8,hjust=-0.1) +
  annotate("segment",
           x = planner_x, y = planner_y - 50,
           xend = federal_strict_x, yend = federal_strict_y + 50,
           arrow = arrow(length = unit(1.2, "cm")),
           color = "red", size = 6
  ) +
  annotate("text",
           x = (planner_x + federal_strict_x) / 2 + 1000,
           y = (planner_y + federal_strict_y) / 2,
           label = "Agency\nFrictions",
           color = "red",
           size = 8
  ) +
  annotate("segment",
           x = federal_strict_x * 0.9, y = federal_strict_y * 0.9,
           xend = actual_x + 800, yend = actual_y -50,
           arrow = arrow(length = unit(1.5, "cm")),
           color = "darkgreen", size = 7
  ) +
  annotate("text",
           x = (federal_strict_x + actual_x) / 2 - 500,
           y = (federal_strict_y + actual_y) / 2 - 120,
           label = "Competition",
           color = "darkgreen",
           size = 8
  ) +
  annotate("text",
           x = 6000,
           y = tradeoffline_planner_redist_slope * 6000 + tradeoffline_planner_redist_intercept + 70,
           label = "Strict Planner's\n Indifference Curve",
           size = 8,
           hjust = 1
  ) +
  xlab(TeX("Change in Default Cost (Mil. USD)")) + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=15)) +
  xlim(-3000,6000) + ylim(-600,100) + scale_linetype_manual("",values=c("Possibility Frontier"=1,
                                                                          "Regulator's Indifference Curve"=2,
                                                                          "Planner's Indifference Curve"=3))
ggsave(get_filename_case("output/Regulator/utility_plot_animated_regulator_strict.png",case),width=10,height=7,dpi=300)

data_federalyr_1yr_levels_test = data_federalyr_1yr_levels_test[which(data_federalyr_1yr_levels_test$Scenario <= 0.5),]

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`DefaultLoss`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Default Cost (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_default_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`ConsumerSurplus`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Consumer Surplus (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_consumer_capreq.png",case),width=10,height=7,dpi=300)
}

data_federalyr_1yr_levels_test$TotalSurplus = data_federalyr_1yr_levels_test$DefaultLoss + data_federalyr_1yr_levels_test$ConsumerSurplus
data_federalyr_1yr_levels_test$RegulatorUtility = lambda1 * data_federalyr_1yr_levels_test$DefaultLoss + lambda2 * data_federalyr_1yr_levels_test$ConsumerSurplus

data_federalyr_1yr_levels_test_long = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(100)),c("Scenario","DefaultLoss","ConsumerSurplus","RegulatorUtility","TotalSurplus")]

names(data_federalyr_1yr_levels_test_long) = mapvalues(names(data_federalyr_1yr_levels_test_long),
                                                       from=c("Scenario","DefaultLoss","ConsumerSurplus","RegulatorUtility","TotalSurplus"),
                                                       to=c("Scenario","Default Loss","Consumer Surplus","Regulator's Utility","Total Surplus"))

data_federalyr_1yr_levels_test_long = melt(data_federalyr_1yr_levels_test_long, id.vars=c("Scenario"))

names(data_federalyr_1yr_levels_test_long) = mapvalues(names(data_federalyr_1yr_levels_test_long),
                                                       from=c("variable"),
                                                       to=c("Component"))

data_federalyr_1yr_levels_test$DefaultProb_pct = data_federalyr_1yr_levels_test$DefaultProb / 100
data_federalyr_1yr_levels_test$Price_pct = data_federalyr_1yr_levels_test$Price * 100

if (case == 'baseline'){
cols <- c("Default Loss" = "red",
          "Consumer Surplus" = "blue",
          "Regulator's Utility" = "darkgreen",
          "Total Surplus" = "black")

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Default Loss","Consumer Surplus")),], aes(x=`Scenario`, y=`value`, group=`Component`, color=`Component`)) +
  geom_line(aes(),size=1) +
  xlab("Federal Capital Rate") + ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=20)) +
  xlim(0.00,0.50) + ylim(-3000,5000) + scale_colour_manual(values = cols)
ggsave(get_filename_case("output/Regulator/utility_univariate_default_and_consumer_capreq.png",case),width=10,height=7,dpi=300)

ggplot(
  data = data_federalyr_1yr_levels_test_long[
    which(data_federalyr_1yr_levels_test_long$Component %in% c("Default Loss","Consumer Surplus")),],
  aes(x = Scenario, y = value, group = Component, linetype = Component)
) +
  geom_line(size = 1) +
  xlab("Federal Capital Rate") +
  ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    legend.position = "bottom",
    legend.text = element_text(size = 20)
  ) +
  xlim(0.00, 0.50) +
  ylim(-3000, 5000) +
  scale_linetype_manual(values = c("Default Loss" = "solid", "Consumer Surplus" = "dotted"))
ggsave(get_filename_case("output/Regulator/utility_univariate_default_and_consumer_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Regulator's Utility")),], aes(x=`Scenario`, y=`value`, group=`Component`, color=`Component`)) +
  geom_line(aes(),size=1) +
  xlab("Federal Capital Rate") + ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=12)) +
  xlim(0.00,0.50) + ylim(-10000,15000) + scale_colour_manual(values = cols)
ggsave(get_filename_case("output/Regulator/utility_univariate_regutil_totalsurplus_capreq_1.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Regulator's Utility")),], aes(x=`Scenario`, y=`value`, group=`Component`, color=`Component`)) +
  geom_line(aes(),size=1) +
  xlab("Federal Capital Rate") + ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=12)) +
  xlim(0.00,0.50) + ylim(-10000,15000) + scale_colour_manual(values = cols) +
  geom_vline(xintercept=cap_rate_max_welfare_yearthis, linetype='dashed')
ggsave(get_filename_case("output/Regulator/utility_univariate_regutil_totalsurplus_capreq_2.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Regulator's Utility")),], aes(x=`Scenario`, y=`value`, group=`Component`, color=`Component`)) +
  geom_line(aes(),size=1) +
  xlab("Federal Capital Rate") + ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=12)) +
  xlim(0.00,0.50) + ylim(-10000,15000) + scale_colour_manual(values = cols) +
  geom_vline(xintercept=cap_rate_max_welfare_yearthis, linetype='dashed') + geom_vline(xintercept=opco_capreq, linetype='dotted')
ggsave(get_filename_case("output/Regulator/utility_univariate_regutil_totalsurplus_capreq_3.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Regulator's Utility","Total Surplus")),], aes(x=`Scenario`, y=`value`, group=`Component`, color=`Component`)) +
  geom_line(aes(),size=1) +
  xlab("Federal Capital Rate") + ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20), legend.position = "bottom", legend.text=element_text(size=12)) +
  xlim(0.00,0.50) + ylim(-10000,15000) + scale_colour_manual(values = cols) +
  geom_vline(xintercept=cap_rate_max_welfare_yearthis, linetype='dashed') + geom_vline(xintercept=opco_capreq, linetype='dotted')
ggsave(get_filename_case("output/Regulator/utility_univariate_regutil_totalsurplus_capreq_4.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test_long[which(data_federalyr_1yr_levels_test_long$Component %in% c("Regulator's Utility", "Total Surplus")),],
       aes(x = `Scenario`, y = `value`, group = `Component`, color = `Component`)) +
  geom_line(size = 1) +
  xlab("Federal Capital Rate") +
  ylab("Change from Current Equilibrium (Mil. USD)") +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    legend.position = "none",
    legend.text = element_text(size = 12)
  ) +
  xlim(0.00, 0.50) +
  ylim(-10000, 15000) +
  scale_colour_manual(values = cols) +
  geom_vline(xintercept = cap_rate_max_welfare_yearthis, linetype = 'dashed') +
  geom_vline(xintercept = opco_capreq, linetype = 'dotted') +
  geom_vline(xintercept = cap_rate_planner, linetype = 'solid') +
  geom_text(aes(x = opco_capreq, y = 7000, label = paste0("State\n(",round(opco_capreq*100),"%)")), size = 8, color = "black", hjust = 1.1) +
  geom_text(aes(x = cap_rate_max_welfare_yearthis, y = 7000, label = paste0("Federal\n(",cap_rate_max_welfare_yearthis*100,"%)")), size = 8, color = "black", hjust = 1.1) +
  geom_text(aes(x = max(data_federalyr_1yr_levels_test_long$Scenario)-0.15, y = data_federalyr_1yr_levels_test_long$value[(data_federalyr_1yr_levels_test_long$Component == "Total Surplus") & (data_federalyr_1yr_levels_test_long$Scenario == max(data_federalyr_1yr_levels_test_long$Scenario))] * 1.3,
                label = "Total Surplus"), size = 8, color = "black", hjust = -0.1) +
  geom_text(aes(x = max(data_federalyr_1yr_levels_test_long$Scenario)-0.15, y = data_federalyr_1yr_levels_test_long$value[(data_federalyr_1yr_levels_test_long$Component == "Regulator's Utility") & (data_federalyr_1yr_levels_test_long$Scenario == max(data_federalyr_1yr_levels_test_long$Scenario))] * 1.5,
                label = "Regulator's Utility"), size = 8, color = "darkgreen", hjust = -0.1) +
  annotate("segment", x = cap_rate_max_welfare_yearthis -0.01, xend = opco_capreq + 0.01, y = 2000, yend = -2000, color = "red", size = 7,
           arrow = arrow(length = unit(1.5, "cm"))) +
  annotate("text", x = (cap_rate_max_welfare_yearthis+opco_capreq)/2, y = -4000, label = "Competition", color = "red", size = 8)
ggsave(get_filename_case("output/Regulator/utility_univariate_regutil_totalsurplus_capreq_5.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`DefaultProb_pct`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Default Prob. (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_defaultprob_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`Price_pct`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Price (% of Actuarial Value)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_price_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`Profits`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Profits (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20)) + ylim(-1000,1000)
ggsave(get_filename_case("output/Regulator/utility_univariate_profits_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test[which(!data_federalyr_1yr_levels_test$Scenario %in% c(0.09,0.10,0.11)),], aes(x=`Scenario`, y=`Guaranty`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Guaranty Payouts (Mil. USD)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_guaranty_capreq.png",case),width=10,height=7,dpi=300)

ggplot(data = data_federalyr_1yr_levels_test, aes(x=`Scenario`, y=`RegulatorUtility`)) +
  geom_line() +
  xlab("Federal Capital Rate") + ylab("Change in Regulator's Utility (Mil. USD)") +
  ylim(-10000,15000) +
  xlim(0.00,0.50) + geom_vline(xintercept=cap_rate_max_welfare_yearthis, linetype='dashed') +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_univariate_util_capreq.png",case),width=10,height=7,dpi=300)
}

data_federalyr_1yr_levels_test_with_ineq = merge(data_federalyr_1yr_levels_test,eqn_inequalities_all,
                                                 by=c("Scenario"),
                                                 all.x=TRUE)

data_federalyr_1yr_levels_test_with_ineq = data_federalyr_1yr_levels_test_with_ineq[,`Admissible_plot`:=NULL]
data_federalyr_1yr_levels_test_with_ineq = data_federalyr_1yr_levels_test_with_ineq[,`DefaultLoss_admissible`:=NULL]
data_federalyr_1yr_levels_test_with_ineq = data_federalyr_1yr_levels_test_with_ineq[,`ConsumerSurplus_admissible`:=NULL]

names(data_federalyr_1yr_levels_test_with_ineq) = c(names(data_federalyr),"Equilibrium","Total Surplus","Regulator's Utility","Default Prob. Pct.","Price Pct.","Min. LambdaRatio","Max. LambdaRatio","Admissible")

data_federalyr_1yr_levels_test_with_ineq$Scenario = as.character(data_federalyr_1yr_levels_test_with_ineq$Scenario)
data_federalyr_1yr_levels_test_with_ineq$Price = data_federalyr_1yr_levels_test_with_ineq$Price * 100

data_federalyr_1yr_levels_test_with_ineq$Welfare_Change = data_federalyr_1yr_levels_test_with_ineq$`Default Loss` * lambda1 + data_federalyr_1yr_levels_test_with_ineq$`Consumer Surplus` * lambda2

stargazer(as.data.table(data_federalyr_1yr_levels_test_with_ineq[,c("Scenario","Default Loss","Default Prob","Consumer Surplus","Quantity","Price","Min. LambdaRatio","Max. LambdaRatio","Admissible")]),
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_levels_lambdas.tex"),case))

cap_rate_max_welfare_socialplanner = findMaxWelfareSocialPlanner(data_federalyr_1yr_levels)[1]
defaultlossplannerchangelevel = data_federalyr_1yr_levels$`Default Loss Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner)]
surplusplannerlevelschange = abs(data_federalyr_1yr_levels$`Consumer Surplus Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner)])
welfarefederallevelschangesocialplanner = data_federalyr_1yr_levels$`Default Loss Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner)] + data_federalyr_1yr_levels$`Consumer Surplus Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner)]

data_federalyr_1yr_levels_test_with_ineq_admissible = data_federalyr_1yr_levels_test_with_ineq[which(data_federalyr_1yr_levels_test_with_ineq$Admissible == 1),]

data_federalyr_1yr_levels_test_with_ineq_admissible$`Max. LambdaRatio` = data_federalyr_1yr_levels_test_with_ineq_admissible$`Max. LambdaRatio` * (-1)
data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio` = data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio` * (-1)
data_federalyr_1yr_levels_test_with_ineq_admissible = data_federalyr_1yr_levels_test_with_ineq_admissible[which(data_federalyr_1yr_levels_test_with_ineq_admissible$`Max. LambdaRatio` >= 0 | data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio` >= 0),]
data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio`[which(data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio` < 0)] = 0
data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio`[which(is.na(data_federalyr_1yr_levels_test_with_ineq_admissible$`Max. LambdaRatio`))] = 0

data_federalyr_1yr_levels_test_with_ineq_admissible$lambda_ratio_min = as.numeric(data_federalyr_1yr_levels_test_with_ineq_admissible$`Min. LambdaRatio`)
data_federalyr_1yr_levels_test_with_ineq_admissible$lambda_ratio_max = as.numeric(data_federalyr_1yr_levels_test_with_ineq_admissible$`Max. LambdaRatio`)

data_federalyr_1yr_levels_test_with_ineq_admissible$Scenario = as.numeric(data_federalyr_1yr_levels_test_with_ineq_admissible$Scenario)

ggplot(data=data_federalyr_1yr_levels_test_with_ineq_admissible[which(data_federalyr_1yr_levels_test_with_ineq_admissible$lambda_ratio_max <= 5),]) +
  geom_step(aes(x=lambda_ratio_max,y=Scenario)) +
  xlab(TeX("Regulator's Tradeoff Weight Ratio $\\gamma$")) + ylab("Federal Capital Rate") +
  ylim(0.00,0.50) +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_lambda_ratio_capreq.png",case),width=10,height=7,dpi=300)

cap_rate_max_welfare <- findMaxWelfare(data_federalyr[which(data_federalyr$Year == year_this),])
cap_rate_max_welfare <- cap_rate_max_welfare[1]
cap_rate_opco <- round(kappa_h,digits=2)

defaultlossfederal <- abs(round(data_federalyr_1yr$`Default Loss`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2))
defaultlossopco <- abs(round(data_federalyr_1yr$`Default Loss`[which(data_federalyr_1yr$Scenario == cap_rate_opco)],digits=2))

defaultprobfederalchange <- abs(round(data_federalyr_1yr$`Default Prob`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=0))

defaultprobfederalchangelevel <- abs(round(data_federalyr_1yr_levels$`Default Prob`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare)],digits=0))
defaultprobfederallevel = defaultprobobseq - defaultprobfederalchangelevel
defaultprobopcochangelevel <- abs(round(data_federalyr_1yr_levels$`Default Prob`[which(data_federalyr_1yr_levels$Scenario == cap_rate_opco)],digits=0))
defaultprobopcolevel = defaultprobobseq - defaultprobopcochangelevel

defaultlossfederalchangelevel <- abs(round(data_federalyr_1yr_levels$`Default Loss`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare)],digits=0))
defaultlossopcochangelevel <- abs(round(data_federalyr_1yr_levels$`Default Loss`[which(data_federalyr_1yr_levels$Scenario == cap_rate_opco)],digits=0))

data_federalyr_1yr_levels_with_delta = data_federalyr_1yr_levels
data_federalyr_1yr_levels_with_delta$`Default Loss Change Delta` = data_federalyr_1yr_levels_with_delta$`Default Loss Change` - shift(data_federalyr_1yr_levels_with_delta$`Default Loss Change`,n=1)
capratedefaultflat = round(max(data_federalyr_1yr_levels_with_delta$Scenario[which(data_federalyr_1yr_levels_with_delta$`Default Loss Change Delta` >= 20)])*100)

staterevenuefederal <- round(data_federalyr_1yr$`State Revenue`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2)

federalrevenuefederal <- abs(round(data_federalyr_1yr$`Federal Revenue`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2))

captivesizefederal <- abs(round(data_federalyr_1yr$`Captive Size`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2))

surplusfederal <- abs(round(data_federalyr_1yr$`Consumer Surplus`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2))

surplusfederallevelschange <- abs(round(data_federalyr_1yr_levels$`Consumer Surplus Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare)],digits=0))
surplusopcolevelschange <- abs(round(data_federalyr_1yr_levels$`Consumer Surplus Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_opco)],digits=0))

pricefederal <- round(data_federalyr_1yr$`Price`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2)
priceopco <- round(data_federalyr_1yr$`Price`[which(data_federalyr_1yr$Scenario == cap_rate_opco)],digits=2)

quantityfederal <- abs(round(data_federalyr_1yr$`Quantity`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2))
quantityopco <- abs(round(data_federalyr_1yr$`Quantity`[which(data_federalyr_1yr$Scenario == cap_rate_opco)],digits=2))

guarantyfederallevelschange = round(data_federalyr_1yr_levels$`Guaranty Change`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)])

profitsfederallevelschange = round(data_federalyr_1yr_levels$`Profits Change`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)])

welfarefederal <- round(data_federalyr_1yr$`Welfare Change`[which(data_federalyr_1yr$Scenario == cap_rate_max_welfare)],digits=2)
welfarefederallevelschange <- round(data_federalyr_1yr_levels$`Welfare Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare)],digits=0)
welfarewithprofitsfederallevelschange <- round(data_federalyr_1yr_levels$`Welfare with Profits Change`[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare)],digits=0)

socialwelfarefederallevelschange = defaultlossfederalchangelevel - surplusfederallevelschange

defaultlossfederalbpchange <-round(((defaultlossfederal - defaultlossobseq) / defaultlossobseq) * 100,digits=2)

surplusfederalbpchange <-round(((surplusfederal - surplusobseq) / surplusobseq) * 100,digits=2)

federalrevenuefederalbpchange <-round(((federalrevenuefederal - federalrevenueobseq) / federalrevenueobseq) * 100,digits=2)
staterevenuefederalbpchange <- max(round(((staterevenuefederal - staterevenueobseq) / staterevenueobseq) * 100,digits=2),100)

welfarefederalbpchange <- welfarefederal

data_gaap_ss = fread(get_filename_case("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio.csv",case))
reserve_statutory_gaap_ratio = data_gaap_ss$reserve_statutory_gaap_ratio[1] - 1
structuralcostofexternalfinancing = pricefederal / (cap_rate_max_welfare - opco_capreq) * (1 + reserve_statutory_gaap_ratio)

lambda_ratio_opco_min = data_federalyr_1yr_levels_test_with_ineq$`Min. LambdaRatio`[which(data_federalyr_1yr_levels_test_with_ineq$Equilibrium == "Opco-Implied")]
lambda_ratio_opco_max = data_federalyr_1yr_levels_test_with_ineq$`Max. LambdaRatio`[which(data_federalyr_1yr_levels_test_with_ineq$Equilibrium == "Opco-Implied")]

if (case == 'baseline'){
bans_all <- c("all",paste0("demand_",c("NY")))
bans_all = bans_all[2]

data_stateyr_captiveban_all <- list()
i_federal <- 1

for (ban_this in bans_all){
  scenario <- paste0("counterfactual_captiveban_",ban_this)
  data_stateyr_captiveban_this <- computeStateRegulator(scenario)

  data_stateyr_captiveban_this$scenario <- scenario
  data_stateyr_captiveban_this$federal_rate <- paste0("Demand Ban ",gsub("demand_","",ban_this))
  data_stateyr_captiveban_all[[i_federal]] <- data_stateyr_captiveban_this
  i_federal <- i_federal + 1
}
data_stateyr_captiveban_all <- do.call(rbind,data_stateyr_captiveban_all)

data_federalyr_captiveban <- calculate_table_components(data_stateyr_captiveban_all)

output_list <- compare_welfare(data_federalyr_captiveban,2012)
data_federalyr_captiveban_with_actuals <- output_list[[1]]
data_federalyr_captiveban_2012 <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban[which(grepl("Demand Ban NY",data_federalyr_captiveban$Scenario)),],2012,change = "levels")
data_federalyr_captiveban_with_actuals <- output_list[[1]]
data_federalyr_captiveban_2012 <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban[which(grepl("Demand Ban all",data_federalyr_captiveban$Scenario)),],2012)
data_federalyr_captiveban_with_actuals_all <- output_list[[1]]
data_federalyr_captiveban_2012_all <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban,2016)
data_federalyr_captiveban_with_actuals <- output_list[[1]]
data_federalyr_captiveban_2016 <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban,2019)
data_federalyr_captiveban_with_actuals <- output_list[[1]]
data_federalyr_captiveban_2019 <- output_list[[2]]

stargazer(as.data.table(data_federalyr_captiveban_2012),
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_captiveban_demand_2012.tex"),case))

stargazer(as.data.table(data_federalyr_captiveban_2016),
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_captiveban_demand_2016.tex"),case))

stargazer(as.data.table(data_federalyr_captiveban_2019),
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_captiveban_demand_2019.tex"),case))

cap_rate_max_welfare_2012 <- findMaxWelfare(data_federalyr[which(data_federalyr$Year == 2012),])
cap_rate_max_welfare_2012 <- cap_rate_max_welfare_2012[1]

data_federalyr_captiveban_2012_with_federal = rbind(data_federalyr_captiveban_2012,
                                                    data_federalyr_1yr_levels_2012[which(data_federalyr_1yr_levels_2012$Scenario == cap_rate_max_welfare_2012)])

data_federalyr_captiveban_2012_with_federal = t(data_federalyr_captiveban_2012_with_federal)
data_federalyr_captiveban_2012_with_federal = as.data.frame(data_federalyr_captiveban_2012_with_federal)
data_federalyr_captiveban_2012_with_federal$V1 = as.numeric(data_federalyr_captiveban_2012_with_federal$V1)
data_federalyr_captiveban_2012_with_federal$V2 = as.numeric(data_federalyr_captiveban_2012_with_federal$V2)
data_federalyr_captiveban_2012_with_federal$V3 = paste0(round(data_federalyr_captiveban_2012_with_federal$V1 / data_federalyr_captiveban_2012_with_federal$V2 * 100,digits=0),"%")

data_federalyr_captiveban_2012_with_federal = as.data.frame(t(data_federalyr_captiveban_2012_with_federal))

data_federalyr_captiveban_2012_with_federal$Scenario = c("Demand Ban NY","Federal","Percent of Federal")

data_federalyr_captiveban_2012_with_federal = as.data.table(data_federalyr_captiveban_2012_with_federal)[,c("Scenario",
                                                                                                            "Default Loss Change",
                                                                                                            "Default Prob Change",
                                                                                                            "State Revenue Change",
                                                                                                            "Federal Revenue Change",
                                                                                                            "Captive Size Change",
                                                                                                            "Consumer Surplus Change",
                                                                                                            "Quantity Change",
                                                                                                            "Price Change")]

names(data_federalyr_captiveban_2012_with_federal) = c("Scenario",
                                                       "Default Loss",
                                                       "Default Prob",
                                                       "State Revenue",
                                                       "Federal Revenue",
                                                       "Captive Size",
                                                       "Consumer Surplus",
                                                       "Quantity",
                                                       "Price")

stargazer(data_federalyr_captiveban_2012_with_federal,
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_captiveban_demand_2012_with_federal.tex"),case))

data_federalyr_captiveban_1yr <- data_federalyr_captiveban_2012
cap_rate_max_welfare_captiveban = "Demand Ban NY"

defaultlosscaptiveban <- round(data_federalyr_captiveban_1yr$`Default Loss`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)
defaultlosscaptivebanpcttotalban = abs(round(defaultlosscaptiveban / defaultlossfederalchangelevel * 100,digits=0))

defaultprobcaptivebanny <- round(data_federalyr_captiveban_1yr$`Default Prob`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban NY")],digits=2)

defaultprobcaptivebanpcttotalban = round(defaultprobcaptivebanny / defaultprobfederalchangelevel * 100,digits=0)

staterevenuecaptiveban <- round(data_federalyr_captiveban_1yr$`State Revenue`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)

federalrevenuecaptiveban <- round(data_federalyr_captiveban_1yr$`Federal Revenue`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban all")],digits=2)
federalrevenuecaptivebanny <- round(data_federalyr_captiveban_1yr$`Federal Revenue`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban NY")],digits=2)

federalrevenuecaptivebanpcttotalban = round(federalrevenuecaptivebanny / federalrevenuecaptiveban * 100,digits=0)

captivesizecaptiveban <- round(data_federalyr_captiveban_1yr$`Captive Size`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)

surpluscaptiveban <- round(data_federalyr_captiveban_1yr$`Consumer Surplus Change`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban all")],digits=2)
surpluscaptivebanny <- round(data_federalyr_captiveban_1yr$`Consumer Surplus Change`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban NY")],digits=2)

surpluscaptivebanpcttotalban = round(surpluscaptivebanny / surplusfederallevelschange * 100,digits=0)

pricecaptiveban <- round(data_federalyr_captiveban_1yr$`Price`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)

quantitycaptiveban <- round(data_federalyr_captiveban_1yr$`Quantity`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)

welfarecaptiveban <- round(data_federalyr_captiveban_1yr$`Welfare with Profits Change`[which(data_federalyr_captiveban_1yr$Scenario == cap_rate_max_welfare_captiveban)],digits=2)
welfarecaptivebanny <- round(data_federalyr_captiveban_1yr$`Welfare with Profits Change`[which(data_federalyr_captiveban_1yr$Scenario == "Demand Ban NY")],digits=2)

welfarecaptivebannypcttotalban = round(welfarecaptivebanny / welfarefederallevelschange * 100,digits=0)

welfarecaptivebanbpchange <- welfarecaptiveban

capratefederalpctchangepercentagepoints <- abs(((opco_capreq - cap_rate_max_welfare) * 100))
capratefederalpctchange = round(capratefederalpctchangepercentagepoints / cap_rate_max_welfare,digits=0)
capratefederalpctchangepercentagepoints = round(capratefederalpctchangepercentagepoints,digits=0)

state_this <- "VT"
supply_ban_get_states <- function(state_this){
  data <- fread(get_filename_case(paste0("output/CapitalAllocation/capital_rates_estimates_actual.csv"),case))

  data <- data[which(data$REINSSTATEDOMICILED != state_this),]

  data_utilyr <- data[which(data$year == 2019),]
  data_utilyr$u_st_rounded <- floor(data_utilyr$u_st/2)*2
  data_utilyr$u_st_rounded[which(data_utilyr$u_st_rounded <= -8)] = -8

  data_utilyr = data_utilyr %>% group_by(u_st_rounded) %>% mutate(u_st_rounded_mean = mean(u_st,na.rm=TRUE))
  data_utilyr$u_st_rounded = data_utilyr$u_st_rounded_mean

  data_utilyr <- data_utilyr %>% group_by(u_st_rounded) %>% mutate(kappa_f_switch = mean(kappa_f,na.rm=TRUE))

  permutation_cols = c("CEDENTSNLSTATENTITYKEY","u_st_rounded","u_st","kappa_f","REINSSTATEDOMICILED")
  permutation_cols_2012 <- permutation_cols[which(permutation_cols != "CEDENTSNLSTATENTITYKEY")]
  data_utilyr <- as.data.table(data_utilyr)[,..permutation_cols_2012]
  data_utilyr <- as.data.table(data_utilyr)[order(REINSSTATEDOMICILED),]

  fwrite(data_utilyr,file=get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_states_u_st_rounded.csv"),case))

  data_insurerstateyr <- fread(get_filename_case("output/CapitalAllocation_insurerstateyear.csv",case))

  data_insurerstateyr <- data_insurerstateyr %>% group_by(CEDENTSNLSTATENTITYKEY,year) %>% filter(amount_reinsured == max(amount_reinsured,na.rm=TRUE))
  data_insurerstateyr <- as.data.table(data_insurerstateyr)

  u_st_rounded_all <- data_utilyr[!duplicated(data_utilyr$u_st_rounded),]

  data_insurerstateyr_banned <- data_insurerstateyr[which(data_insurerstateyr$REINSSTATEDOMICILED == state_this),]
  banned_insurers <- sort(unique(data_insurerstateyr_banned$CEDENTSNLSTATENTITYKEY))

  data_demand = fread(get_filename_case("../CleanData/output/Demand_All.csv",case))
  data_demand = data_demand[which(data_demand$year == 2019 & !is.na(data_demand$price)),]
  banned_insurers = banned_insurers[which(banned_insurers %in% data_demand$SNLSTATENTITYKEY)]

  permutation_insurer <- list()
  i <- 1
  for (banned_insurers_this in banned_insurers){
    permutation_insurer[[i]] <- data.frame(CEDENTSNLSTATENTITYKEY=banned_insurers_this,
                                           u_st_rounded=u_st_rounded_all$u_st_rounded,
                                           u_st=u_st_rounded_all$u_st,
                                           kappa_f=u_st_rounded_all$kappa_f,
                                           REINSSTATEDOMICILED=u_st_rounded_all$REINSSTATEDOMICILED)
    names(permutation_insurer[[i]]) = paste0(names(permutation_insurer[[i]]),i)
    permutation_insurer[[i]]$x = 1
    i <- i+1
  }
  permutation_insurer <- Reduce(function(dtf1, dtf2) merge(dtf1, dtf2, by = "x", all.x = TRUE),
                                permutation_insurer)
  permutation_insurer$x <- seq(1:nrow(permutation_insurer))

  times <- gsub("CEDENTSNLSTATENTITYKEY", "", grep("CEDENTSNLSTATENTITYKEY", names(permutation_insurer), value = TRUE))
  permutation_insurer2 <- reshape(permutation_insurer, direction = "long",
                                  varying = grep(paste(permutation_cols,collapse="|"), names(permutation_insurer)), sep = "",
                                  v.names = permutation_cols, timevar = "date", times = times)

  permutation_insurer2 <- permutation_insurer2[,c("x","CEDENTSNLSTATENTITYKEY","u_st_rounded","u_st","kappa_f","REINSSTATEDOMICILED")]
  names(permutation_insurer2) <- c("x","CEDENTSNLSTATENTITYKEY","u_st_rounded","u_st","kappa_f","REINSSTATEDOMICILED")

  fwrite(permutation_insurer2,file=get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_permutations.csv"),case))
}
supply_ban_get_states(state_this)

permutation_insurer <- fread(get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_permutations.csv"),case))
bans_all <- c(paste0("supply_VT",sort(unique(permutation_insurer$x))))

data_stateyr_captiveban_supply_all <- list()
i_federal <- 1

for (ban_this in bans_all){
  scenario <- paste0("counterfactual_captiveban_",ban_this)
  data_stateyr_captiveban_supply_this <- computeStateRegulator(scenario)

  data_stateyr_captiveban_supply_this$scenario <- scenario
  data_stateyr_captiveban_supply_this$federal_rate <- paste0("Supply Ban ",gsub("supply_","",ban_this))
  data_stateyr_captiveban_supply_all[[i_federal]] <- data_stateyr_captiveban_supply_this
  i_federal <- i_federal + 1
}
data_stateyr_captiveban_supply_all <- do.call(rbind,data_stateyr_captiveban_supply_all)

data_federalyr_captiveban_supply <- calculate_table_components(data_stateyr_captiveban_supply_all)

data_utilyr <- fread(get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_states_u_st_rounded.csv"),case))
permutation_insurer <- fread(get_filename_case(paste0("output/SupplyBan/supply_ban_",state_this,"_permutations.csv"),case))

data_utilyr$exp_u_st <- exp(data_utilyr$u_st)
data_utilyr$sum_exp_u_st <- sum(data_utilyr$exp_u_st,na.rm=TRUE)
data_utilyr$prob <- data_utilyr$exp_u_st / data_utilyr$sum_exp_u_st
data_utilyr_ss <- data_utilyr %>% group_by(u_st_rounded) %>% summarise(prob = sum(prob,na.rm=TRUE))

permutation_insurer_prob <- merge(permutation_insurer,data_utilyr_ss,by=c("u_st_rounded"),all.x=TRUE)

permutation_insurer_prob <- permutation_insurer_prob %>% group_by(x) %>% summarise(prob = cumprod(prob))
permutation_insurer_prob <- permutation_insurer_prob %>% group_by(x) %>% filter(row_number() == n())

permutation_insurer_prob <- as.data.table(permutation_insurer_prob)

data_federalyr_captiveban_supply$x <- as.numeric(gsub("[^0-9]","",data_federalyr_captiveban_supply$Scenario))
data_federalyr_captiveban_supply_with_prob <- merge(data_federalyr_captiveban_supply,
                                                    permutation_insurer_prob,
                                                    by=c("x"),
                                                    all.x=TRUE)

data_federalyr_captiveban_supply_with_prob <- data_federalyr_captiveban_supply_with_prob[,x:=NULL]
data_federalyr_captiveban_supply_with_prob <- data_federalyr_captiveban_supply_with_prob[,Scenario:=NULL]
data_federalyr_captiveban_supply_with_prob <- as.data.table(data_federalyr_captiveban_supply_with_prob)
data_federalyr_captiveban_supply_with_prob <- data_federalyr_captiveban_supply_with_prob %>% group_by(Year) %>% dplyr::summarise(across(-prob, list(weighted = ~weighted.mean(.,w=prob))))
names(data_federalyr_captiveban_supply_with_prob) <- gsub("_weighted","",names(data_federalyr_captiveban_supply_with_prob))

data_federalyr_captiveban_supply <- as.data.table(data_federalyr_captiveban_supply_with_prob)

output_list <- compare_welfare(data_federalyr_captiveban_supply,2012)
data_federalyr_captiveban_supply_with_actuals <- output_list[[1]]
data_federalyr_captiveban_supply_2012 <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban_supply,2016)
data_federalyr_captiveban_supply_with_actuals <- output_list[[1]]
data_federalyr_captiveban_supply_2016 <- output_list[[2]]

output_list <- compare_welfare(data_federalyr_captiveban_supply,2019,change = "levels")
data_federalyr_captiveban_supply_with_actuals <- output_list[[1]]
data_federalyr_captiveban_supply_2019 <- output_list[[2]]

cap_rate_max_welfare_2019 <- findMaxWelfare(data_federalyr[which(data_federalyr$Year == 2019),])
cap_rate_max_welfare_2019 <- cap_rate_max_welfare_2019[1]

data_federalyr_captiveban_supply_2019$Scenario = "Supply Ban Vermont"

data_federalyr_captiveban_supply_2019_with_federal = rbind(data_federalyr_captiveban_supply_2019,
                                                           data_federalyr_1yr_levels[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare_2019)])

data_federalyr_captiveban_supply_2019_with_federal = t(data_federalyr_captiveban_supply_2019_with_federal)
data_federalyr_captiveban_supply_2019_with_federal = as.data.frame(data_federalyr_captiveban_supply_2019_with_federal)
data_federalyr_captiveban_supply_2019_with_federal$V1 = as.numeric(data_federalyr_captiveban_supply_2019_with_federal$V1)
data_federalyr_captiveban_supply_2019_with_federal$V2 = as.numeric(data_federalyr_captiveban_supply_2019_with_federal$V2)
data_federalyr_captiveban_supply_2019_with_federal$V3 = paste0(round(data_federalyr_captiveban_supply_2019_with_federal$V1 / data_federalyr_captiveban_supply_2019_with_federal$V2 * 100,digits=0),"%")

data_federalyr_captiveban_supply_2019_with_federal = as.data.frame(t(data_federalyr_captiveban_supply_2019_with_federal))

data_federalyr_captiveban_supply_2019_with_federal$Scenario = c("Supply Ban Vermont","Federal","Percent of Federal")

data_federalyr_captiveban_supply_2019_with_federal = as.data.table(data_federalyr_captiveban_supply_2019_with_federal)[,c("Scenario",
                                                                                                                          "Default Loss Change",
                                                                                                                          "Default Prob Change",
                                                                                                                          "State Revenue Change",
                                                                                                                          "Federal Revenue Change",
                                                                                                                          "Captive Size Change",
                                                                                                                          "Consumer Surplus Change",
                                                                                                                          "Quantity Change",
                                                                                                                          "Price Change")]
names(data_federalyr_captiveban_supply_2019_with_federal) = c("Scenario",
                                                              "Default Loss",
                                                              "Default Prob",
                                                              "State Revenue",
                                                              "Federal Revenue",
                                                              "Captive Size",
                                                              "Consumer Surplus",
                                                              "Quantity",
                                                              "Price")

stargazer(data_federalyr_captiveban_supply_2019_with_federal,
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE,
          header = FALSE,
          out=get_filename_case(paste0("output/Regulator/federalyr_captiveban_supply_2019_with_federal.tex"),case))

data_federalyr_captiveban_supply_1yr <- data_federalyr_captiveban_supply_2019
data_federalyr_captiveban_supply_1yr$Scenario = "Unilateral Supply Ban VT"
cap_rate_max_welfare_captiveban_supply = "Unilateral Supply Ban VT"

defaultlosscaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Default Loss`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

defaultlosscaptivebanpcttotalban_supply <- abs(round(defaultlosscaptiveban_supply / defaultlossfederalchangelevel * 100,digits=0))

defaultprobcaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Default Prob`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

defaultprobcaptivebanpcttotalban_supply <- round(defaultprobcaptiveban_supply / defaultprobfederalchange * 100,digits=0)

staterevenuecaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`State Revenue`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

federalrevenuecaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Federal Revenue`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

captivesizecaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Captive Size`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

surpluscaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Consumer Surplus`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

surpluscaptivebanpcttotalban_supply <- abs(round(surpluscaptiveban_supply / surplusfederallevelschange * 100,digits=0))

pricecaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Price`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

quantitycaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Quantity`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)

welfarecaptiveban_supply <- round(data_federalyr_captiveban_supply_1yr$`Welfare with Profits Change`[which(data_federalyr_captiveban_supply_1yr$Scenario == cap_rate_max_welfare_captiveban_supply)],digits=2)
welfarecaptiveban_supply_vt <- round(data_federalyr_captiveban_supply_1yr$`Welfare with Profits Change`[which(data_federalyr_captiveban_supply_1yr$Scenario == "Unilateral Supply Ban VT")],digits=2)

welfarecaptiveban_supplybpchange <- welfarecaptiveban_supply

data_unilateral = data.frame(Scenario = c("Federal",
                                          "NY Ban",
                                          "VT Ban"),
                             defaultcost_change = c(abs(defaultlossfederalchangelevel),
                                                    abs(defaultlosscaptivebanpcttotalban / 100 * defaultlossfederalchangelevel),
                                                    abs(defaultlosscaptiveban_supply)),
                             surplus_change = c(abs(surplusfederallevelschange) * (-1),
                                                abs(surpluscaptivebanpcttotalban / 100 * surplusfederallevelschange) * (-1),
                                                abs(surpluscaptiveban_supply) * (-1)),
                             welfare_change = c(abs(welfarefederallevelschange) * (-1),
                                                abs(welfarecaptivebannypcttotalban / 100 * welfarefederallevelschange) * (-1),
                                                abs(welfarecaptiveban_supply) * (-1)))

ggplot(data=data_unilateral, aes(x=Scenario, y=defaultcost_change)) +
  geom_bar(stat="identity", width=0.5) +
  xlab("Counterfactual Scenario") + ylab("Change in Default Cost (Mil. USD)") +
  geom_hline(yintercept = 0) +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_compare_bans_default.png",case),width=10,height=7,dpi=300)

ggplot(data=data_unilateral, aes(x=Scenario, y=surplus_change)) +
  geom_bar(stat="identity", width=0.5) +
  xlab("Counterfactual Scenario") + ylab("Change in Consumer Surplus (Mil. USD)") +
  geom_hline(yintercept = 0) +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_compare_bans_surplus.png",case),width=10,height=7,dpi=300)

ggplot(data=data_unilateral, aes(x=Scenario, y=welfare_change)) +
  geom_bar(stat="identity", width=0.5) +
  xlab("Counterfactual Scenario") + ylab("Change in Regulator's Utility (Mil. USD)") +
  geom_hline(yintercept = 0) +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/Regulator/utility_compare_bans_utility.png",case),width=10,height=7,dpi=300)

lambda1 = (-1) * summary(reg_lambda_4)$coefficients[1]
lambda2 = (-1) * summary(reg_lambda_4)$coefficients[2]
lambda3 = (-1) * summary(reg_lambda_4)$coefficients[3]

data_federalyr_1yr_1scenario_levels = data_federalyr_1yr_levels[which(data_federalyr_1yr_levels$Scenario == cap_rate_max_welfare),]
lambda1_cutoff = data_federalyr_1yr_1scenario_levels$`Federal Revenue Change` / data_federalyr_1yr_1scenario_levels$`Default Loss Change` + lambda2 * data_federalyr_1yr_1scenario_levels$`Consumer Surplus Change` / data_federalyr_1yr_1scenario_levels$`Default Loss Change`
lambda2_cutoff = (-1) * (data_federalyr_1yr_1scenario_levels$`Federal Revenue Change` - lambda1 * data_federalyr_1yr_1scenario_levels$`Default Loss Change`) / data_federalyr_1yr_1scenario_levels$`Consumer Surplus Change`

lambda1_cutoff_bound <- abs(round(lambda1 / lambda1_cutoff,digits=0))
lambda2_cutoff_bound <- abs(round(lambda2_cutoff / lambda2,digits=0))

get_alternative_omega = function(omega_alternative){
  welfare_alternative = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare)] / (-1 * omega) * omega_alternative + data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare)]
  return(welfare_alternative)
}
omega_threshold = uniroot(get_alternative_omega, lower = 0, upper = 1)$root
get_alternative_theta = function(theta_alternative){
  welfare_alternative = data_federalyr_1yr_levels_test$DefaultLoss[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare)] + data_federalyr_1yr_levels_test$ConsumerSurplus[which(data_federalyr_1yr_levels_test$Scenario == cap_rate_max_welfare)] / theta * theta_alternative
  return(welfare_alternative)
}
theta_threshold = uniroot(get_alternative_theta, lower = 0, upper = 1)$root

data_stateyr_dual_all <- list()
i_dual <- 1

dual_rates_all = seq(0.15,0.80,0.05)

for (dual_rates_this in dual_rates_all){
  scenario <- paste0("counterfactual_dual_",dual_rates_this)

  tryCatch({
    res <- withTimeout({
      data_stateyr_dual_this <- computeStateRegulator(scenario)
      data_stateyr_dual_this$scenario <- scenario
      data_stateyr_dual_this$dual_rate <- dual_rates_this
      data_stateyr_dual_all[[i_dual]] <- data_stateyr_dual_this
      i_dual <- i_dual + 1;
    }, timeout=10800);
  }, TimeoutException=function(ex) {
    out_message = paste0("Timed out. Skipping ",dual_rates_this,"\n")
  });
}
data_stateyr_dual_all <- do.call(rbind,data_stateyr_dual_all)

data_stateyr_dual_all = data_stateyr_dual_all[order(data_stateyr_dual_all$dual_rate),]

data_stateyr_dual_all$federal_rate = data_stateyr_dual_all$dual_rate
data_dualyr <- calculate_table_components(data_stateyr_dual_all)

output_list <- compare_welfare(data_dualyr,2019)
data_dualyr_with_actuals <- output_list[[1]]
data_dualyr_1yr <- output_list[[2]]

output_list_levels <- compare_welfare(data_dualyr,2019,change="levels")
data_dualyr_with_actuals_levels <- output_list_levels[[1]]
data_dualyr_1yr_levels <- output_list_levels[[2]]

year_this = 2019

data_dualyr_1yr_levels_test = data_dualyr[which(data_dualyr$Year == year_this),]

names(data_dualyr_1yr_levels_test) = gsub(" ","",names(data_dualyr_1yr_levels_test))

data_dualyr_1yr_levels_test = data_dualyr_1yr_levels_test[order(Scenario),]

data_dualyr_1yr_levels_test$DefaultLoss = data_dualyr_1yr_levels_test$DefaultLoss - data_federalyr_actual$`Default Loss`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$DefaultProb = data_dualyr_1yr_levels_test$DefaultProb - data_federalyr_actual$`Default Prob`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$ConsumerSurplus = data_dualyr_1yr_levels_test$ConsumerSurplus - data_federalyr_actual$`Consumer Surplus`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$dualRevenue = data_dualyr_1yr_levels_test$dualRevenue - data_federalyr_actual$`dual Revenue`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$CaptiveSize = data_dualyr_1yr_levels_test$CaptiveSize - data_federalyr_actual$`Captive Size`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$Quantity = data_dualyr_1yr_levels_test$Quantity - data_federalyr_actual$`Quantity`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$Profits = data_dualyr_1yr_levels_test$Profits - data_federalyr_actual$`Profits`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$Guaranty = data_dualyr_1yr_levels_test$Guaranty - data_federalyr_actual$`Guaranty`[which(data_federalyr_actual$Year == year_this)]
data_dualyr_1yr_levels_test$Price = data_dualyr_1yr_levels_test$Price - data_federalyr_actual$`Price`[which(data_federalyr_actual$Year == year_this)]

cap_rate_max_welfare_yearthis_dual <- findMaxWelfare(data_dualyr_1yr_levels_test)
defaultlossfederalchangeleveldual = data_dualyr_1yr_levels_test$DefaultLoss[which(data_dualyr_1yr_levels_test$Scenario == cap_rate_max_welfare_yearthis_dual)]
surplusfederallevelschangedual = data_dualyr_1yr_levels_test$ConsumerSurplus[which(data_dualyr_1yr_levels_test$Scenario == cap_rate_max_welfare_yearthis_dual)]

cap_rate_max_welfare_socialplanner_dual = findMaxWelfareSocialPlanner(data_dualyr_1yr_levels)[1]
defaultlossplannerchangeleveldual = data_dualyr_1yr_levels$`Default Loss Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)]
surplusplannerlevelschangedual = abs(data_dualyr_1yr_levels$`Consumer Surplus Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)])
welfareduallevelschangesocialplanner = data_dualyr_1yr_levels$`Default Loss Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)] + data_dualyr_1yr_levels$`Consumer Surplus Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)]

defaultprobfederalchangeleveldual <- abs(round(data_dualyr_1yr_levels$`Default Prob`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_yearthis_dual)],digits=0))

surplusfederallevelschangedual <- abs(round(data_dualyr_1yr_levels$`Consumer Surplus Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_yearthis_dual)],digits=0))

welfarefederaldual <- round(data_dualyr_1yr$`Welfare Change`[which(data_dualyr_1yr$Scenario == cap_rate_max_welfare_yearthis_dual)],digits=2)
welfarefederallevelschangedual <- round(data_dualyr_1yr_levels$`Welfare Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_yearthis_dual)],digits=0)

socialwelfarefederallevelschangedual = defaultlossfederalchangeleveldual - surplusfederallevelschangedual

welfarefederallevelschangesocialplannerdual = data_dualyr_1yr_levels$`Default Loss Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)] + data_dualyr_1yr_levels$`Consumer Surplus Change`[which(data_dualyr_1yr_levels$Scenario == cap_rate_max_welfare_socialplanner_dual)]

}

lambda1 = (-1) * summary(reg_lambda_4)$coefficients[1]
lambda2 = (-1) * summary(reg_lambda_4)$coefficients[2]
lambda3 = (-1) * summary(reg_lambda_4)$coefficients[3]
lambda_ratio = lambda1 / lambda2

lambda1 = abs(round(lambda1,digits=2))
lambda2 = abs(round(lambda2,digits=2))
lambda3 = abs(round(lambda3,digits=2))
lambda_ratio = abs(round(lambda_ratio,digits=2))

write(paste0(
  "\\newcommand{\\muavg", if (case != "baseline") case else "", "}{", if (exists("muavg")) muavg else NA, "} \n",
  "\\newcommand{\\sigmaavg", if (case != "baseline") case else "", "}{", if (exists("sigmaavg")) sigmaavg else NA, "} \n",
  "\\newcommand{\\partialderivvttax", if (case != "baseline") case else "", "}{", if (exists("partialderivvttax")) partialderivvttax else NA, "} \n",
  "\\newcommand{\\corrdefaulttax", if (case != "baseline") case else "", "}{", if (exists("corr_default_tax")) corr_default_tax else NA, "} \n",
  "\\newcommand{\\corrdefaulttaxpval", if (case != "baseline") case else "", "}{", if (exists("corr_default_tax_pval")) corr_default_tax_pval else NA, "} \n",
  "\\newcommand{\\regulatorlambdaone", if (case != "baseline") case else "", "}{", if (exists("lambda1")) round(lambda1, digits=1) else NA, "} \n",
  "\\newcommand{\\regulatorlambdatwo", if (case != "baseline") case else "", "}{", if (exists("lambda2")) round(lambda2, digits=1) else NA, "} \n",
  "\\newcommand{\\regulatorlambdathree", if (case != "baseline") case else "", "}{", if (exists("lambda3")) round(lambda3, digits=1) else NA, "} \n",
  "\\newcommand{\\regulatorlambdaratio", if (case != "baseline") case else "", "}{", if (exists("lambda_ratio")) lambda_ratio else NA, "} \n",
  "\\newcommand{\\regulatorlambdaratioopcomin", if (case != "baseline") case else "", "}{", if (exists("lambda_ratio_opco_min")) lambda_ratio_opco_min else NA, "} \n",
  "\\newcommand{\\regulatorlambdaratioopcomax", if (case != "baseline") case else "", "}{", if (exists("lambda_ratio_opco_max")) lambda_ratio_opco_max else NA, "} \n",
  "\\newcommand{\\regulatorregrsq", if (case != "baseline") case else "", "}{", if (exists("regulatorregrsq")) round(regulatorregrsq, digits=0) else NA, "} \n",
  "\\newcommand{\\capratefederal", if (case != "baseline") case else "", "}{", if (exists("cap_rate_max_welfare")) round(cap_rate_max_welfare*100, digits=1) else NA, "} \n",
  "\\newcommand{\\capratefederalsocialplanner", if (case != "baseline") case else "", "}{", if (exists("cap_rate_max_welfare_socialplanner")) round(cap_rate_max_welfare_socialplanner*100, digits=1) else NA, "} \n",
  "\\newcommand{\\capratefederaldual", if (case != "baseline") case else "", "}{", if (exists("cap_rate_max_welfare_yearthis_dual")) round(cap_rate_max_welfare_yearthis_dual * 100, digits = 1) else NA, "} \n",
  "\\newcommand{\\capratefederalsocialplannerdual", if (case != "baseline") case else "", "}{", if (exists("cap_rate_max_welfare_socialplanner_dual")) round(cap_rate_max_welfare_socialplanner_dual * 100, digits = 1) else NA, "} \n",
  "\\newcommand{\\capratefederalpctchange", if (case != "baseline") case else "", "}{", if (exists("capratefederalpctchange")) capratefederalpctchange else NA, "} \n",
  "\\newcommand{\\capratefederalpctchangepercentagepoints", if (case != "baseline") case else "", "}{", if (exists("capratefederalpctchangepercentagepoints")) capratefederalpctchangepercentagepoints else NA, "} \n",
  "\\newcommand{\\capratedefaultflat", if (case != "baseline") case else "", "}{", if (exists("capratedefaultflat")) capratedefaultflat else NA, "} \n",
  "\\newcommand{\\defaultlossobseq", if (case != "baseline") case else "", "}{", if (exists("defaultlossobseq")) defaultlossobseq else NA, "} \n",
  "\\newcommand{\\defaultprobobseq", if (case != "baseline") case else "", "}{", if (exists("defaultprobobseq")) defaultprobobseq else NA, "} \n",
  "\\newcommand{\\staterevenueobseq", if (case != "baseline") case else "", "}{", if (exists("staterevenueobseq")) staterevenueobseq else NA, "} \n",
  "\\newcommand{\\federalrevenueobseq", if (case != "baseline") case else "", "}{", if (exists("federalrevenueobseq")) federalrevenueobseq else NA, "} \n",
  "\\newcommand{\\captivesizeobseq", if (case != "baseline") case else "", "}{", if (exists("captivesizeobseq")) captivesizeobseq else NA, "} \n",
  "\\newcommand{\\surplusobseq", if (case != "baseline") case else "", "}{", if (exists("surplusobseq")) surplusobseq else NA, "} \n",
  "\\newcommand{\\priceobseq", if (case != "baseline") case else "", "}{", if (exists("priceobseq")) priceobseq else NA, "} \n",
  "\\newcommand{\\quantityobseq", if (case != "baseline") case else "", "}{", if (exists("quantityobseq")) quantityobseq else NA, "} \n",
  "\\newcommand{\\welfareobseq", if (case != "baseline") case else "", "}{", if (exists("welfareobseq")) welfareobseq else NA, "} \n",
  "\\newcommand{\\guarantyobseq", if (case != "baseline") case else "", "}{", if (exists("guarantyobseq")) guarantyobseq else NA, "} \n",
  "\\newcommand{\\profitsobseq", if (case != "baseline") case else "", "}{", if (exists("profitsobseq")) profitsobseq else NA, "} \n",
  "\\newcommand{\\defaultlossfederal", if (case != "baseline") case else "", "}{", if (exists("defaultlossfederal")) defaultlossfederal else NA, "} \n",
  "\\newcommand{\\defaultlossopco", if (case != "baseline") case else "", "}{", if (exists("defaultlossopco")) defaultlossopco else NA, "} \n",
  "\\newcommand{\\defaultprobfederalchange", if (case != "baseline") case else "", "}{", if (exists("defaultprobfederalchange")) defaultprobfederalchange else NA, "} \n",
  "\\newcommand{\\defaultprobfederallevel", if (case != "baseline") case else "", "}{", if (exists("defaultprobfederallevel")) round(defaultprobfederallevel, digits=2) else NA, "} \n",
  "\\newcommand{\\defaultprobopcolevel", if (case != "baseline") case else "", "}{", if (exists("defaultprobopcolevel")) round(defaultprobopcolevel, digits=2) else NA, "} \n",
  "\\newcommand{\\defaultlossfederalchangelevel", if (case != "baseline") case else "", "}{", if (exists("defaultlossfederalchangelevel")) defaultlossfederalchangelevel else NA, "} \n",
  "\\newcommand{\\defaultlossfederalchangelevelbn", if (case != "baseline") case else "", "}{", if (exists("defaultlossfederalchangelevel")) round(defaultlossfederalchangelevel/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\defaultlossfederalchangeleveldual", if (case != "baseline") case else "", "}{", if (exists("defaultlossfederalchangeleveldual")) defaultlossfederalchangeleveldual else NA, "} \n",
  "\\newcommand{\\defaultlossplannerchangelevel", if (case != "baseline") case else "", "}{", if (exists("defaultlossplannerchangelevel")) defaultlossplannerchangelevel else NA, "} \n",
  "\\newcommand{\\defaultlossplannerchangelevelbn", if (case != "baseline") case else "", "}{", if (exists("defaultlossplannerchangelevel")) round(defaultlossplannerchangelevel/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\defaultlossplannerchangeleveldual", if (case != "baseline") case else "", "}{", if (exists("defaultlossplannerchangeleveldual")) defaultlossplannerchangeleveldual else NA, "} \n",
  "\\newcommand{\\defaultlossopcochangelevel", if (case != "baseline") case else "", "}{", if (exists("defaultlossopcochangelevel")) defaultlossopcochangelevel else NA, "} \n",
  "\\newcommand{\\defaultlossopcochangelevelbn", if (case != "baseline") case else "", "}{", if (exists("defaultlossopcochangelevel")) round(defaultlossopcochangelevel/1000, digits=3) else NA, "} \n",
  "\\newcommand{\\defaultprobfederalchangelevel", if (case != "baseline") case else "", "}{", if (exists("defaultprobfederalchangelevel")) defaultprobfederalchangelevel else NA, "} \n",
  "\\newcommand{\\defaultprobfederalchangeleveldual", if (case != "baseline") case else "", "}{", if (exists("defaultprobfederalchangeleveldual")) defaultprobfederalchangeleveldual else NA, "} \n",
  "\\newcommand{\\defaultlosscaptiveban", if (case != "baseline") case else "", "}{", if (exists("defaultlosscaptiveban")) round(abs(defaultlosscaptiveban), digits=0) else NA, "} \n",
  "\\newcommand{\\defaultprobcaptivebanny", if (case != "baseline") case else "", "}{", if (exists("defaultprobcaptivebanny")) round(abs(defaultprobcaptivebanny), digits=0) else NA, "} \n",
  "\\newcommand{\\defaultlosscaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("defaultlosscaptiveban_supply")) round(abs(defaultlosscaptiveban_supply), digits=0) else NA, "} \n",
  "\\newcommand{\\defaultprobcaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("defaultprobcaptiveban_supply")) abs(defaultprobcaptiveban_supply) else NA, "} \n",
  "\\newcommand{\\staterevenuefederal", if (case != "baseline") case else "", "}{", if (exists("staterevenuefederal")) staterevenuefederal else NA, "} \n",
  "\\newcommand{\\staterevenuecaptiveban", if (case != "baseline") case else "", "}{", if (exists("staterevenuecaptiveban")) staterevenuecaptiveban else NA, "} \n",
  "\\newcommand{\\staterevenuecaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("staterevenuecaptiveban_supply")) staterevenuecaptiveban_supply else NA, "} \n",
  "\\newcommand{\\federalrevenuefederal", if (case != "baseline") case else "", "}{", if (exists("federalrevenuefederal")) federalrevenuefederal else NA, "} \n",
  "\\newcommand{\\federalrevenuecaptiveban", if (case != "baseline") case else "", "}{", if (exists("federalrevenuecaptiveban")) federalrevenuecaptiveban else NA, "} \n",
  "\\newcommand{\\federalrevenuecaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("federalrevenuecaptiveban_supply")) federalrevenuecaptiveban_supply else NA, "} \n",
  "\\newcommand{\\captivesizefederal", if (case != "baseline") case else "", "}{", if (exists("captivesizefederal")) captivesizefederal else NA, "} \n",
  "\\newcommand{\\captivesizecaptiveban", if (case != "baseline") case else "", "}{", if (exists("captivesizecaptiveban")) captivesizecaptiveban else NA, "} \n",
  "\\newcommand{\\captivesizecaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("captivesizecaptiveban_supply")) captivesizecaptiveban_supply else NA, "} \n",
  "\\newcommand{\\surplusfederal", if (case != "baseline") case else "", "}{", if (exists("surplusfederal")) surplusfederal else NA, "} \n",
  "\\newcommand{\\surplusfederallevelschange", if (case != "baseline") case else "", "}{", if (exists("surplusfederallevelschange")) round(surplusfederallevelschange/100, digit=1)*100 else NA, "} \n",
  "\\newcommand{\\surplusplannerlevelschange", if (case != "baseline") case else "", "}{", if (exists("surplusplannerlevelschange")) round(surplusplannerlevelschange/100, digit=1)*100 else NA, "} \n",
  "\\newcommand{\\surplusfederallevelschangedual", if (case != "baseline") case else "", "}{", if (exists("surplusfederallevelschangedual")) round(surplusfederallevelschangedual, digit=1) else NA, "} \n",
  "\\newcommand{\\surplusplannerlevelschangedual", if (case != "baseline") case else "", "}{", if (exists("surplusplannerlevelschangedual")) round(surplusplannerlevelschangedual, digit=1) else NA, "} \n",
  "\\newcommand{\\surplusopcolevelschange", if (case != "baseline") case else "", "}{", if (exists("surplusopcolevelschange")) surplusopcolevelschange else NA, "} \n",
  "\\newcommand{\\surplusfederallevelschangebn", if (case != "baseline") case else "", "}{", if (exists("surplusfederallevelschange")) round(surplusfederallevelschange/1000, digits=2) else NA, "} \n",
  "\\newcommand{\\surplusopcolevelschangebn", if (case != "baseline") case else "", "}{", if (exists("surplusopcolevelschange")) round(surplusopcolevelschange/1000, digits=3) else NA, "} \n",
  "\\newcommand{\\surpluscaptiveban", if (case != "baseline") case else "", "}{", if (exists("surpluscaptiveban")) round(surpluscaptiveban, digits=0) else NA, "} \n",
  "\\newcommand{\\surpluscaptivebanny", if (case != "baseline") case else "", "}{", if (exists("surpluscaptivebanny")) round(abs(surpluscaptivebanny), digits=0) else NA, "} \n",
  "\\newcommand{\\surpluscaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("surpluscaptiveban_supply")) round(abs(surpluscaptiveban_supply), digits=0) else NA, "} \n",
  "\\newcommand{\\pricefederal", if (case != "baseline") case else "", "}{", if (exists("pricefederal")) pricefederal else NA, "} \n",
  "\\newcommand{\\priceopco", if (case != "baseline") case else "", "}{", if (exists("priceopco")) priceopco else NA, "} \n",
  "\\newcommand{\\pricecaptiveban", if (case != "baseline") case else "", "}{", if (exists("pricecaptiveban")) pricecaptiveban else NA, "} \n",
  "\\newcommand{\\pricecaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("pricecaptiveban_supply")) pricecaptiveban_supply else NA, "} \n",
  "\\newcommand{\\quantityfederal", if (case != "baseline") case else "", "}{", if (exists("quantityfederal")) quantityfederal else NA, "} \n",
  "\\newcommand{\\quantityopco", if (case != "baseline") case else "", "}{", if (exists("quantityopco")) quantityopco else NA, "} \n",
  "\\newcommand{\\quantitycaptiveban", if (case != "baseline") case else "", "}{", if (exists("quantitycaptiveban")) quantitycaptiveban else NA, "} \n",
  "\\newcommand{\\quantitycaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("quantitycaptiveban_supply")) quantitycaptiveban_supply else NA, "} \n",
  "\\newcommand{\\guarantyfederallevelschange", if (case != "baseline") case else "", "}{", if (exists("guarantyfederallevelschange")) guarantyfederallevelschange else NA, "} \n",
  "\\newcommand{\\profitsfederallevelschange", if (case != "baseline") case else "", "}{", if (exists("profitsfederallevelschange")) profitsfederallevelschange else NA, "} \n",
  "\\newcommand{\\welfarefederal", if (case != "baseline") case else "", "}{", if (exists("welfarefederal")) welfarefederal else NA, "} \n",
  "\\newcommand{\\welfarefederaldual", if (case != "baseline") case else "", "}{", if (exists("welfarefederaldual")) welfarefederaldual else NA, "} \n",
  "\\newcommand{\\welfarefederallevelschange", if (case != "baseline") case else "", "}{", if (exists("welfarefederallevelschange")) welfarefederallevelschange else NA, "} \n",
  "\\newcommand{\\welfarefederallevelschangebn", if (case != "baseline") case else "", "}{", if (exists("welfarefederallevelschange")) round(welfarefederallevelschange/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\welfarefederallevelschangebndual", if (case != "baseline") case else "", "}{", if (exists("welfarefederallevelschangedual")) round(welfarefederallevelschangedual/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\socialwelfarefederallevelschangebn", if (case != "baseline") case else "", "}{", if (exists("socialwelfarefederallevelschange")) round(socialwelfarefederallevelschange/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\socialwelfarefederallevelschangebndual", if (case != "baseline") case else "", "}{", if (exists("socialwelfarefederallevelschangedual")) round(socialwelfarefederallevelschangedual/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\welfarefederallevelschangesocialplannerbn", if (case != "baseline") case else "", "}{", if (exists("welfarefederallevelschangesocialplanner")) round(welfarefederallevelschangesocialplanner/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\welfarefederallevelschangesocialplannerbndual", if (case != "baseline") case else "", "}{", if (exists("welfarefederallevelschangesocialplannerdual")) round(welfarefederallevelschangesocialplannerdual/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\welfarewithprofitsfederallevelschangebn", if (case != "baseline") case else "", "}{", if (exists("welfarewithprofitsfederallevelschange")) round(welfarewithprofitsfederallevelschange/1000, digits=1) else NA, "} \n",
  "\\newcommand{\\welfarecaptiveban", if (case != "baseline") case else "", "}{", if (exists("welfarecaptiveban")) welfarecaptiveban else NA, "} \n",
  "\\newcommand{\\welfarecaptivebansupply", if (case != "baseline") case else "", "}{", if (exists("welfarecaptiveban_supply")) welfarecaptiveban_supply else NA, "} \n",
  "\\newcommand{\\welfarecaptivebanny", if (case != "baseline") case else "", "}{", if (exists("welfarecaptivebanny")) welfarecaptivebanny else NA, "} \n",
  "\\newcommand{\\defaultlossfederalbpchange", if (case != "baseline") case else "", "}{", if (exists("defaultlossfederalbpchange")) abs(defaultlossfederalbpchange) else NA, "} \n",
  "\\newcommand{\\surplusfederalbpchange", if (case != "baseline") case else "", "}{", if (exists("surplusfederalbpchange")) abs(surplusfederalbpchange) else NA, "} \n",
  "\\newcommand{\\welfarefederalbpchange", if (case != "baseline") case else "", "}{", if (exists("welfarefederalbpchange")) abs(welfarefederalbpchange) else NA, "} \n",
  "\\newcommand{\\staterevenuefederalbpchange", if (case != "baseline") case else "", "}{", if (exists("staterevenuefederalbpchange")) abs(staterevenuefederalbpchange) else NA, "} \n",
  "\\newcommand{\\federalrevenuefederalbpchange", if (case != "baseline") case else "", "}{", if (exists("federalrevenuefederalbpchange")) abs(federalrevenuefederalbpchange) else NA, "} \n",
  "\\newcommand{\\defaultprobcaptivebanpcttotalban", if (case != "baseline") case else "", "}{", if (exists("defaultprobcaptivebanpcttotalban")) abs(defaultprobcaptivebanpcttotalban) else NA, "} \n",
  "\\newcommand{\\defaultlosscaptivebanpcttotalbansupply", if (case != "baseline") case else "", "}{", if (exists("defaultlosscaptivebanpcttotalban_supply")) abs(defaultlosscaptivebanpcttotalban_supply) else NA, "} \n",
  "\\newcommand{\\defaultlosscaptivebanpcttotalban", if (case != "baseline") case else "", "}{", if (exists("defaultlosscaptivebanpcttotalban")) abs(defaultlosscaptivebanpcttotalban) else NA, "} \n",
  "\\newcommand{\\federalrevenuecaptivebanpcttotalban", if (case != "baseline") case else "", "}{", if (exists("federalrevenuecaptivebanpcttotalban")) abs(federalrevenuecaptivebanpcttotalban) else NA, "} \n",
  "\\newcommand{\\surpluscaptivebanpcttotalban", if (case != "baseline") case else "", "}{", if (exists("surpluscaptivebanpcttotalban")) abs(surpluscaptivebanpcttotalban) else NA, "} \n",
  "\\newcommand{\\surpluscaptivebanpcttotalbansupply", if (case != "baseline") case else "", "}{", if (exists("surpluscaptivebanpcttotalban_supply")) abs(surpluscaptivebanpcttotalban_supply) else NA, "} \n",
  "\\newcommand{\\reservestatutorygaapratio", if (case != "baseline") case else "", "}{", if (exists("reserve_statutory_gaap_ratio")) round(reserve_statutory_gaap_ratio, digits=2) else NA, "} \n",
  "\\newcommand{\\kappah", if (case != "baseline") case else "", "}{", if (exists("kappa_h")) round(kappa_h*100, digits=0) else NA, "} \n",
  "\\newcommand{\\structuralcostofexternalfinancing", if (case != "baseline") case else "", "}{", if (exists("structuralcostofexternalfinancing")) round(structuralcostofexternalfinancing, digits=2) else NA, "} \n",
  "\\newcommand{\\corrprofitinvestorconsumerweights", if (case != "baseline") case else "", "}{", if (exists("corr_profit_investor_consumer_weights")) round(corr_profit_investor_consumer_weights, digits=2) else NA, "} \n",
  "\\newcommand{\\lambdaonecutoffbound", if (case != "baseline") case else "", "}{", if (exists("lambda1_cutoff_bound")) lambda1_cutoff_bound else NA, "} \n",
  "\\newcommand{\\lambdatwocutoffbound", if (case != "baseline") case else "", "}{", if (exists("lambda2_cutoff_bound")) lambda2_cutoff_bound else NA, "} \n",
  "\\newcommand{\\thetathreshold", if (case != "baseline") case else "", "}{", if (exists("theta_threshold")) floor(theta_threshold*100) else NA, "} \n",
  "\\newcommand{\\omegathreshold", if (case != "baseline") case else "", "}{", if (exists("omega_threshold")) ceil(omega_threshold*100) else NA, "} \n"
), file=get_filename_case("output/PaperText/PaperText_RegulatoryCompetition_Analysis_Regulator_Solve.tex", case), append=FALSE)


year_compare = 2019

output_list <- compare_welfare(data_input=data_stateyr_federal_all,year_compare=2019,level="state",change="levels")
data_stateyr_change <- output_list[[1]]
data_stateyr_change_1yr <- output_list[[2]]

cap_rate_max_welfare <- findMaxWelfare(data_federalyr[which(data_federalyr$Year == year_compare),])
cap_rate_max_welfare <- cap_rate_max_welfare[1]

data_stateyr_change_1yr_1scenario <- data_stateyr_change_1yr[which(as.numeric(gsub("counterfactual_federal_","",data_stateyr_change_1yr$scenario)) == cap_rate_max_welfare),]

data_stateyr_change_1yr_1scenario <- as.data.table(data_stateyr_change_1yr_1scenario)[order(stateyr_default_expected_loss_change),]

data_stateyr_change_1yr_1scenario <- data_stateyr_change_1yr_1scenario[,c("state","stateyr_default_expected_loss_change","quantities_stateyeartype_change","stateyr_util_total_change","amount_reinsured_estimated_change","stateyr_tax_revenue_change","stateyr_profit_change","stateyr_guaranty_change")]

data_stateyr_change_1yr_1scenario$amount_reinsured_estimated_change <- mapvalues(data_stateyr_change_1yr_1scenario$amount_reinsured_estimated_change,
                                                                                 from=c(NA),
                                                                                 to=c(0))
data_stateyr_change_1yr_1scenario$stateyr_tax_revenue_change <- mapvalues(data_stateyr_change_1yr_1scenario$stateyr_tax_revenue_change,
                                                                          from=c(NA),
                                                                          to=c(0))

state_names <- fread(get_filename_case("../raw/States/StateNames_US.csv",case))

data_stateyr_change_1yr_1scenario <- data_stateyr_change_1yr_1scenario[which(data_stateyr_change_1yr_1scenario$state %in% state_names$state),]

data_stateyr_quantities = data_stateyr_actual[which(data_stateyr_actual$year == 2019),c("state","quantities_stateyeartype_actual")]
names(data_stateyr_quantities) = c("state","MarketSize")
data_stateyr_change_1yr_1scenario = merge(data_stateyr_change_1yr_1scenario,
                                          data_stateyr_quantities,
                                          by=c("state"),
                                          all.x=TRUE)

ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(state,-stateyr_default_expected_loss_change), y=stateyr_default_expected_loss_change)) +
  geom_bar(stat="identity") +
  xlab("State") + ylab("Annual Default Loss Change (Mil. USD)") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text=element_text(size=12),axis.title=element_text(size=12)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/statelevel_defaultloss.png",case),width=10,height=7,dpi=300)

ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(state,-stateyr_tax_revenue_change), y=stateyr_tax_revenue_change)) +
  geom_bar(stat="identity") +
  xlab("State") + ylab("Annual Tax Revenue Change (Mil. USD)") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text=element_text(size=12),axis.title=element_text(size=12)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/statelevel_taxrevenue.png",case),width=10,height=7,dpi=300)

ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(state,-quantities_stateyeartype_change), y=quantities_stateyeartype_change)) +
  geom_bar(stat="identity") +
  xlab("State") + ylab("Annual Insurance Quantities Change") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text=element_text(size=12),axis.title=element_text(size=12)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/statelevel_quantities.png",case),width=10,height=7,dpi=300)

ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(state,-stateyr_util_total_change), y=stateyr_util_total_change)) +
  geom_bar(stat="identity") +
  xlab("State") + ylab("Annual Consumer Surplus Change (Mil. USD)") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text=element_text(size=12),axis.title=element_text(size=12)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/statelevel_util.png",case),width=10,height=7,dpi=300)

names(data_stateyr_change_1yr_1scenario) <- c("State","Default Loss","Quantities","Consumer Surplus","Captive Size","Tax Revenue","Profit","Guaranty","Market Size")

reg_lambdas <- readRDS(get_filename_case("output/Regulator/reg_lambdas_4_components.RDS",case))

data_stateyr_change_1yr_1scenario$lambda_default <- summary(reg_lambdas)$coefficients[1,1]
data_stateyr_change_1yr_1scenario$lambda_util <- summary(reg_lambdas)$coefficients[2,1]
data_stateyr_change_1yr_1scenario$lambda_profits <- summary(reg_lambdas)$coefficients[3,1]

data_stateyr_change_1yr_1scenario$`Welfare Change` <- (data_stateyr_change_1yr_1scenario$`Tax Revenue` + (-1) * data_stateyr_change_1yr_1scenario$lambda_default * data_stateyr_change_1yr_1scenario$`Default Loss` + (-1) * data_stateyr_change_1yr_1scenario$lambda_util * data_stateyr_change_1yr_1scenario$`Consumer Surplus` + (-1) * data_stateyr_change_1yr_1scenario$lambda_profits * data_stateyr_change_1yr_1scenario$Profit)

data_stateyr_change_1yr_1scenario <- data_stateyr_change_1yr_1scenario[,lambda_default:=NULL]
data_stateyr_change_1yr_1scenario <- data_stateyr_change_1yr_1scenario[,lambda_util:=NULL]

output_table = as.data.table(data_stateyr_change_1yr_1scenario)[,`Market Size`:=NULL]
stargazer(output_table,
          summary=FALSE,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          digit.separator = "",
          out=get_filename_case(paste0("output/Regulator/stateyr_federal_change.tex"),case))

names(state_names) = c("State","State_2")
data_stateyr_change_1yr_1scenario = merge(data_stateyr_change_1yr_1scenario,
                                          state_names,
                                          by=c("State"),
                                          all.x=TRUE)
data_stateyr_change_1yr_1scenario = data_stateyr_change_1yr_1scenario[order(`Market Size`),]
data_stateyr_change_1yr_1scenario$rank = seq(1:nrow(data_stateyr_change_1yr_1scenario))
data_stateyr_change_1yr_1scenario$State[which((data_stateyr_change_1yr_1scenario$rank > 1) & (data_stateyr_change_1yr_1scenario$rank < 48))] = data_stateyr_change_1yr_1scenario$State_2[which((data_stateyr_change_1yr_1scenario$rank > 1) & (data_stateyr_change_1yr_1scenario$rank < 48))]

data_stateyr_change_1yr_1scenario$`Utility Change` = data_stateyr_change_1yr_1scenario$`Welfare Change`
ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(State,`Market Size`), y=`Utility Change`)) +
  geom_bar(stat="identity") +
  xlab("State (Sorted by Insurance Market Size)") + ylab("Regulator's Utility Change (Mil. USD)") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text.x=element_text(size=24),
                       axis.text.y=element_text(size=12),
                       axis.title=element_text(size=24)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/stateyr_federal_change.png",case),width=10,height=7,dpi=300)

data_stateyr_change_1yr_1scenario$MarketSize_share = data_stateyr_change_1yr_1scenario$`Market Size` / sum(data_stateyr_change_1yr_1scenario$`Market Size`) * 100
ggplot(data=data_stateyr_change_1yr_1scenario, aes(x=reorder(State,MarketSize_share), y=MarketSize_share)) +
  geom_bar(stat="identity") +
  xlab("State (Sorted by Market Share)") + ylab("State Market Share (%)") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text.x=element_text(size=24),
                       axis.text.y=element_text(size=12),
                       axis.title=element_text(size=24)) + theme(legend.position = c(0.75,0.2))
ggsave(get_filename_case("output/Regulator/stateyr_quantities.png",case),width=10,height=7,dpi=300)

kappa_captives <- fread(get_filename_case("output/CapitalAllocation/capital_rates_estimates_actual.csv",case))
kappa_f_mean = mean(kappa_captives$kappa_f,na.rm=TRUE)

data_gaap = fread(get_filename_case("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio.csv",case))
kappa_h = data_gaap$reserve_statutory_gaap_ratio[1] - 1
data_actual <- fread(get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))

reg_lambda_3 = readRDS(file = get_filename_case(paste0("output/Regulator/reg_lambdas_3_components.RDS"),case))
lambda1 = summary(reg_lambda_3)$coefficients[1,1]
lambda2 = summary(reg_lambda_3)$coefficients[2,1]

data <- fread(get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))

data$net_operating_gain = data$NETGAINSBEFOREDIVFEDINCTAXESLOB
data$total_investment_gain = data$RLZDCAPGAINSANNUAL + data$CHANGEUNRLZDCAPGAINANNUAL + data$CHANGEUNRLZDFXCAPGAINANNUAL + data$OTHERRLZDCAPGAINSADJANNUAL
data$Q = data$s_s_prime_numerator * data$V


data$Q_scaled = data$TOTALLIAB

data_ind = data %>% group_by(year) %>% summarise(net_operating_gain = sum(net_operating_gain,na.rm=TRUE),
                                                 total_investment_gain = sum(total_investment_gain,na.rm=TRUE),
                                                 Q = sum(Q,na.rm=TRUE),
                                                 Q_scaled = sum(Q_scaled,na.rm=TRUE),
                                                 TOTALLIAB = sum(TOTALLIAB,na.rm=TRUE),
                                                 TOTALPOLICYRESVLIFE = sum(TOTALPOLICYRESVLIFE,na.rm=TRUE),
                                                 price = mean(price,na.rm=TRUE))
data_ind$R_empirical = (data_ind$net_operating_gain + data_ind$total_investment_gain) / data_ind$Q_scaled

data <- data[which(data$TOTALLIAB >= 10^6)]


data$profitability_empirical = (data$net_operating_gain + data$total_investment_gain) / data$Q_scaled
data$R_empirical = (-1) * (data$net_operating_gain + data$total_investment_gain) / data$Q_scaled + data$price

data_firm <- data %>% group_by(amb_co_num) %>% summarise(TOTALLIAB = mean(TOTALLIAB,na.rm=TRUE),
                                                         R_empirical_sd = sd(R_empirical,na.rm=TRUE),
                                                         R_empirical_mu = mean(R_empirical,na.rm=TRUE),
                                                         R_mu_mean = mean(mu,na.rm=TRUE),
                                                         R_sd_mean = mean(sigma,na.rm=TRUE),
                                                         price = mean(price,na.rm=TRUE),
                                                         profitability_empirical_mean = mean(profitability_empirical,na.rm=TRUE),
                                                         profitability_empirical_sd = sd(profitability_empirical,na.rm=TRUE),
                                                         num_yr = n())

Rsdempirical = abs(round(mean(data_firm$R_empirical_sd,na.rm=TRUE),digits=2))
Rsdmodel = abs(round(mean(data_firm$R_sd_mean,na.rm=TRUE),digits=2))

Rmuempirical = abs(round(mean(data_firm$R_empirical_mu,na.rm=TRUE),digits=2))
Rmumodel = abs(round(mean(data_firm$R_mu_mean,na.rm=TRUE),digits=2))


ts <- data %>% group_by(year) %>% summarise(price = mean(price,na.rm=TRUE),
                                            mu = mean(mu,na.rm=TRUE),
                                            sigma = mean(sigma,na.rm=TRUE))


data_calibrated_sigma <- bind_rows(
  data_firm %>% mutate(distribution = "Accounting Data", value = R_empirical_sd) %>% select(value, distribution),
  data %>% mutate(distribution = "Model Calibration", value = sigma) %>% select(value, distribution)
)
ggplot(data_calibrated_sigma, aes(x = value, y = (..count..)/sum(..count..), fill = distribution)) +
  geom_histogram(binwidth = 0.025, alpha=0.25, color='grey') +
  xlab(latex2exp::TeX("Standard Deviation \\sigma of Stochastic Cost")) + ylab("Frequency") + labs(fill="Source") +
  theme_classic() + theme(text = element_text(size=20)) +
  scale_fill_manual(values = c("Accounting Data" = "blue", "Model Calibration" = "red"))
ggsave(get_filename_case("output/Pricing/primitives_summarystats_hist_sigma_externalvalidation.png",case),width=10,height=7,dpi=300)


data_calibrated_mu <- bind_rows(
  data_firm %>% mutate(distribution = "Accounting Data", value = R_empirical_mu) %>% select(value, distribution),
  data %>% mutate(distribution = "Model Calibration", value = mu) %>% select(value, distribution)
)
ggplot(data_calibrated_mu, aes(x = value, y = (..count..)/sum(..count..), fill = distribution)) +
  geom_histogram(binwidth = 0.025, alpha=0.25, color='grey') +
  xlab(latex2exp::TeX("Mean \\mu of Stochastic Cost")) + ylab("Frequency") + labs(fill="Source") +
  theme_classic() + theme(text = element_text(size=20)) +
  scale_fill_manual(values = c("Accounting Data" = "blue", "Model Calibration" = "red"))
ggsave(get_filename_case("output/Pricing/primitives_summarystats_hist_mu_externalvalidation.png",case),width=10,height=7,dpi=300)


ggplot(data_firm,aes(x=R_empirical_sd,y=R_sd_mean)) + geom_point() +
  xlab("Sigma in data") + ylab("Sigma estimated") +
  geom_smooth(method='lm', formula= y~x, se=FALSE) + 
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/ExternalValidation/sigma.png",case),width=10,height=7,dpi=300)

ggplot(data_firm,aes(x=R_empirical_mu,y=R_mu_mean)) + geom_point() +
  xlab("Mu in data") + ylab("Mu estimated") +
  geom_smooth(method='lm', formula= y~x, se=FALSE) + 
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/ExternalValidation/mu.png",case),width=10,height=7,dpi=300)

write(paste0("\\newcommand{\\Rsdempirical}{",Rsdempirical,"} \n",
             "\\newcommand{\\Rsdmodel}{",Rsdmodel,"} \n",
             "\\newcommand{\\Rmuempirical}{",Rmuempirical,"} \n",
             "\\newcommand{\\Rmumodel}{",Rmumodel,"} \n"),
      file=get_filename_case("output/PaperText/PaperText_RegulatoryCompetition_Analysis_Insurer_ExternalValidation.tex",case))


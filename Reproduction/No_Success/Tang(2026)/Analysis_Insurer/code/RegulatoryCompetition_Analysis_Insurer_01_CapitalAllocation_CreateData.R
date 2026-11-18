### Global
source("../lib/r/Functions.R")

subsubfolder_path <- file.path(getwd(), "output", "PaperText")
if (!file.exists(subsubfolder_path)) {
  dir.create(subsubfolder_path, recursive = TRUE)}

subsubfolder_path <- file.path(getwd(), "output", "summary_stats")
if (!file.exists(subsubfolder_path)) {
  dir.create(subsubfolder_path, recursive = TRUE)}

captive_definitions = c("","_KY","_KYShadow")

for (captive_definition_this in captive_definitions){
data = fread(paste0("../CleanData/output/SNL_Reinsurance_Captives_AgreementLevel",captive_definition_this,".csv"))

data$CEDENTLIFEPREMS <- (data$CEDENTLIFEPREMS / 1000)
data$amount_reinsured <- (data$amount_reinsured / 1000)

data_agreement <- data

data_quantities <- fread(path.symlink("input/SNL_Quantities.csv"))
data_demand <- fread(path.symlink("input/Demand_All.csv"),select=c("SNLSTATENTITYKEY","year","amb_co_num","state","NAICCOMPANYCODE",
                                                                   "quantities","quantities_filled","quantities_v","share"))
data_demand <- data_demand[,c("SNLSTATENTITYKEY","year","state","quantities_v")]

data_demand <- data_demand[!duplicated(data_demand[,c("SNLSTATENTITYKEY","year","state")]),]

data_quantities <- merge(data_quantities,data_demand,by=c("SNLSTATENTITYKEY","year","state"),all.x=TRUE)

data_quantities <- data_quantities[which(data_quantities$lob == "Ordinary Life Insurance"),]

data_cedent <- fread(path.symlink("input/SNL_Financials.csv"))
data_cedent_group <- fread(path.symlink("input/SNL_Financials_Group.csv"))

names(data_cedent) <- mapvalues(names(data_cedent),
                                from=c("SNLSTATENTITYKEY"),
                                to=c("CEDENTSNLSTATENTITYKEY"))
names(data_cedent_group) <- mapvalues(names(data_cedent_group),
                                from=c("SNLSTATENTITYKEY"),
                                to=c("CEDENTSNLTOPENTITYKEY"))

data_cedent$TOTALLIAB <- data_cedent$TOTALLIAB / 1000
data_cedent_group$TOTALLIAB <- data_cedent_group$TOTALLIAB / 1000
data_cedent$RESERVESGROSS <- data_cedent$RESERVESGROSS / 1000
data_cedent_group$RESERVESGROSS <- data_cedent_group$RESERVESGROSS / 1000

data <- data_agreement

data_ss_by_cedentstate <- data %>% group_by(year,CEDENTSTATEDOMICILED) %>% summarise(CEDENTLIFEPREMS = sum(CEDENTLIFEPREMS,na.rm=TRUE),
                                                                                     CEDENTLIFERESVCREDITTAKEN = sum(CEDENTLIFERESVCREDITTAKEN,na.rm=TRUE),
                                                                                     CEDENTLIFEMODIFIEDCOINSURANCERESV = sum(CEDENTLIFEMODIFIEDCOINSURANCERESV,na.rm=TRUE),
                                                                                     amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                     num_captives = n_distinct(CEDENTSNLTOPENTITYKEY,na.rm=TRUE),
                                                                                     CEDENTLIFEAMTINFORCE = sum(CEDENTLIFEAMTINFORCE,na.rm=TRUE))

data_ss_by_cedentstate <- data_ss_by_cedentstate[which(data_ss_by_cedentstate$year == 2012),]
data_ss_by_cedentstate <- data_ss_by_cedentstate[,c("CEDENTSTATEDOMICILED","amount_reinsured")]

data_ss_by_cedentstate <- as.data.table(data_ss_by_cedentstate)[order(amount_reinsured,decreasing=TRUE),]

names(data_ss_by_cedentstate) <- c("State","Premiums Ceded")

data_ss_by_cedentstate <- data_ss_by_cedentstate[which(data_ss_by_cedentstate$State != ""),]

stargazer(data_ss_by_cedentstate,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=0, digits.extra=0,
          no.space = TRUE, header = FALSE,
          summary = FALSE,
          out=paste0("output/summary_stats/ceded_amount_cedentstate.tex"))

data_ss_by_reinsurerstate <- data %>% group_by(year,REINSSTATEDOMICILED) %>% summarise(CEDENTLIFEPREMS = sum(CEDENTLIFEPREMS,na.rm=TRUE),
                                                                                       CEDENTLIFERESVCREDITTAKEN = sum(CEDENTLIFERESVCREDITTAKEN,na.rm=TRUE),
                                                                                       CEDENTLIFEMODIFIEDCOINSURANCERESV = sum(CEDENTLIFEMODIFIEDCOINSURANCERESV,na.rm=TRUE),
                                                                                       amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                       num_captives = n_distinct(CEDENTSNLTOPENTITYKEY,na.rm=TRUE),
                                                                                       CEDENTLIFEAMTINFORCE = sum(CEDENTLIFEAMTINFORCE,na.rm=TRUE))

data_ss_by_reinsurerstate_original = data_ss_by_reinsurerstate
fwrite(data_ss_by_reinsurerstate,file=paste0("output/CapitalAllocation_reinsurerstateyear",captive_definition_this,".csv"))

data_ss_by_reinsurerstate <- data_ss_by_reinsurerstate[which(data_ss_by_reinsurerstate$year == 2012),]
data_ss_by_reinsurerstate <- data_ss_by_reinsurerstate[,c("REINSSTATEDOMICILED","amount_reinsured")]

data_ss_by_reinsurerstate <- as.data.table(data_ss_by_reinsurerstate)[order(amount_reinsured,decreasing=TRUE),]

names(data_ss_by_reinsurerstate) <- c("State","Premiums Ceded")

data_ss_by_reinsurerstate <- data_ss_by_reinsurerstate[which(data_ss_by_reinsurerstate$State != ""),]

stargazer(data_ss_by_reinsurerstate,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=0, digits.extra=0,
          no.space = TRUE, header = FALSE,
          summary = FALSE,
          out=paste0("output/summary_stats/ceded_amount_reinsurerstate",captive_definition_this,".tex"))

data_financials = fread(path.symlink("input/SNL_Financials.csv"))

data_financials$CEDENTSNLSTATENTITYKEY = data_financials$SNLSTATENTITYKEY
data2 = merge(data,data_financials,by=c("CEDENTSNLSTATENTITYKEY",'year'),all.x=TRUE)

data_captives = fread("../CleanData/output/SNL_CaptiveCapitalRates_StateYear.csv")
data_captives = data_captives[,c("REINSSTATEDOMICILED","year","kappa","kappa_economic","kappa_supplement","allow_prescribed","L_hat_times_1_plus_rho")]
data_captives = data_captives[which(data_captives$REINSSTATEDOMICILED != ""),]

names(data_captives) = mapvalues(names(data_captives),
                                 from=c("kappa"),
                                 to=c("kappa_state_captivebs"))

data_captives$kappa_economic_K_div_L = data_captives$kappa_economic

data2_ss_by_reinsurerstate = data2 %>% group_by(REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                        num_captives = n_distinct(CEDENTSNLTOPENTITYKEY,na.rm=TRUE),
                                                                                        TOTALLIAB = sum(TOTALLIAB,na.rm=TRUE),
                                                                                        SURPLUSASREGARDSPOLICYHOLDERS = sum(SURPLUSASREGARDSPOLICYHOLDERS,na.rm=TRUE))

data2_ss_by_reinsurerstate = merge(data2_ss_by_reinsurerstate,data_captives,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE,all.y=TRUE)

data2_ss_by_reinsurerstate = data2_ss_by_reinsurerstate[,c("REINSSTATEDOMICILED","year","kappa_state_captivebs","kappa_economic","kappa_economic_K_div_L","kappa_supplement","allow_prescribed","L_hat_times_1_plus_rho")]
data3_ss_by_reinsurerstate = merge(data_ss_by_reinsurerstate_original,
                                   data2_ss_by_reinsurerstate,
                                   by=c("REINSSTATEDOMICILED","year"),
                                   all.x=TRUE,all.y=TRUE)

data3_ss_by_reinsurerstate$kappa_state_captivebs[which(data3_ss_by_reinsurerstate$year < 2014 | data3_ss_by_reinsurerstate$year >= 2021)] = NA
data3_ss_by_reinsurerstate$kappa_economic[which(data3_ss_by_reinsurerstate$year < 2014 | data3_ss_by_reinsurerstate$year >= 2021)] = NA
data3_ss_by_reinsurerstate$kappa_supplement[which(data3_ss_by_reinsurerstate$year < 2013 | data3_ss_by_reinsurerstate$year >= 2021)] = NA
data3_ss_by_reinsurerstate$amount_reinsured[which(is.na(data3_ss_by_reinsurerstate$amount_reinsured))] = 0
data3_ss_by_reinsurerstate$amount_reinsured[which((data3_ss_by_reinsurerstate$year >= 2021))] = NA

fwrite(data3_ss_by_reinsurerstate,file=paste0("output/CapitalAllocation_reinsurerstateyear_joint",captive_definition_this,".csv"))

data_financials = fread(path.symlink("input/SNL_Financials.csv"))
data_financials_group = fread(path.symlink("input/SNL_Financials_Group.csv"))
data_insurer = data_agreement %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                           num_captives_insureryr = sum(captive_is_active,na.rm=TRUE),
                                                                                                           num_captives_insureryr_intensive = sum(captive_is_active_intensive,na.rm=TRUE))
data_insurer_group = data_agreement %>% group_by(CEDENTSNLTOPENTITYKEY,CEDENTSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                                num_captives_insureryr = sum(captive_is_active,na.rm=TRUE),
                                                                                                                num_captives_insureryr_intensive = sum(captive_is_active_intensive,na.rm=TRUE))

data_insurer <- merge(data_insurer,data_cedent,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)
data_insurer_group <- merge(data_insurer_group,data_cedent_group,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

amount_vars <- c("amount_reinsured")
data_insurer[,amount_vars][is.na(data_insurer[amount_vars])] <- 0
data_insurer_group[,amount_vars][is.na(data_insurer_group[amount_vars])] <- 0

data_insurer$ceded_frac_liab <- data_insurer$amount_reinsured / data_insurer$RESERVESGROSS
data_insurer_group$ceded_frac_liab <- data_insurer_group$amount_reinsured / data_insurer_group$RESERVESGROSS

data_insurer$ceded_frac_liab_uncensored = data_insurer$ceded_frac_liab
data_insurer_group$ceded_frac_liab_uncensored = data_insurer_group$ceded_frac_liab

data_insurer$ceded_frac_liab[which(data_insurer$ceded_frac_liab < 0)] <- 0
data_insurer$ceded_frac_liab[which(data_insurer$ceded_frac_liab >= 1)] <- 0.9999

data_insurer_group$ceded_frac_liab[which(data_insurer_group$ceded_frac_liab < 0)] <- 0
data_insurer_group$ceded_frac_liab[which(data_insurer_group$ceded_frac_liab >= 1)] <- 0.9999

### Merge on top state insurer-year level data
data = data_agreement[which(data_agreement$is_captive_alt == 1 & data_agreement$REINSSTATEDOMICILED != ""),]
data = data[order(-amount_reinsured),]
data <- data %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSTATEDOMICILED,year) %>% filter(row_number() == 1)
data <- as.data.table(data)

data_states <- data[,c("CEDENTSNLSTATENTITYKEY","year","CEDENTSTATEDOMICILED","REINSSTATEDOMICILED","amount_reinsured")]
data_states <- data_states[which(data_states$amount_reinsured > 0 & data_states$REINSSTATEDOMICILED != ""),]
data_states = data_states[order(-amount_reinsured),]
data_states <- data_states %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSTATEDOMICILED,year) %>% filter(row_number() == 1)
data_states <- as.data.table(data_states)

data = data_agreement[which(data_agreement$is_captive_alt == 1 & data_agreement$REINSSTATEDOMICILED != ""),]
data = data[order(-amount_reinsured),]
data <- data %>% group_by(CEDENTSNLTOPENTITYKEY,CEDENTSTATEDOMICILED,year) %>% filter(row_number() == 1)
data <- as.data.table(data)

data_states_group <- data[,c("CEDENTSNLTOPENTITYKEY","year","CEDENTSTATEDOMICILED","REINSSTATEDOMICILED","amount_reinsured")]
data_states_group <- data_states_group[which(data_states_group$amount_reinsured > 0 & data_states_group$REINSSTATEDOMICILED != ""),]
data_states_group = data_states_group[order(-amount_reinsured),]
data_states_group <- data_states_group %>% group_by(CEDENTSNLTOPENTITYKEY,CEDENTSTATEDOMICILED,year) %>% filter(row_number() == 1)
data_states_group <- as.data.table(data_states_group)

names(data_states) = mapvalues(names(data_states),from=c("amount_reinsured"),to=c("amount_reinsured_insurertopstateyear"))
data_states <- data_states[,c("CEDENTSNLSTATENTITYKEY","year","REINSSTATEDOMICILED","amount_reinsured_insurertopstateyear")]

names(data_states_group) = mapvalues(names(data_states_group),from=c("amount_reinsured"),to=c("amount_reinsured_insurertopstateyear"))
data_states_group <- data_states_group[,c("CEDENTSNLTOPENTITYKEY","year","REINSSTATEDOMICILED","amount_reinsured_insurertopstateyear")]

data_insurer <- merge(data_insurer,data_states,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)
data_insurer_group <- merge(data_insurer_group,data_states_group,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_insurer$ceded_frac_liab_insurertopstateyear <- data_insurer$amount_reinsured_insurertopstateyear / data_insurer$RESERVESGROSS
data_insurer$ceded_frac_liab_insurertopstateyear_uncensored = data_insurer$ceded_frac_liab_insurertopstateyear
data_insurer$ceded_frac_liab_insurertopstateyear[which(data_insurer$ceded_frac_liab_insurertopstateyear < 0)] <- 0
data_insurer$ceded_frac_liab_insurertopstateyear[which(data_insurer$ceded_frac_liab_insurertopstateyear >= 1)] <- 0.9999

data_insurer_group$ceded_frac_liab_insurertopstateyear <- data_insurer_group$amount_reinsured_insurertopstateyear / data_insurer_group$RESERVESGROSS
data_insurer_group$ceded_frac_liab_insurertopstateyear_uncensored = data_insurer_group$ceded_frac_liab_insurertopstateyear
data_insurer_group$ceded_frac_liab_insurertopstateyear[which(data_insurer_group$ceded_frac_liab_insurertopstateyear < 0)] <- 0
data_insurer_group$ceded_frac_liab_insurertopstateyear[which(data_insurer_group$ceded_frac_liab_insurertopstateyear >= 1)] <- 0.9999


data_insurer = data_insurer[,c("CEDENTSNLSTATENTITYKEY","year","CEDENTSTATEDOMICILED","REINSSTATEDOMICILED","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored","amount_reinsured_insurertopstateyear","ceded_frac_liab_insurertopstateyear","ceded_frac_liab_insurertopstateyear_uncensored","num_captives_insureryr","num_captives_insureryr_intensive")]
data_insurer_group = data_insurer_group[,c("CEDENTSNLTOPENTITYKEY","year","REINSSTATEDOMICILED","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored","amount_reinsured_insurertopstateyear","ceded_frac_liab_insurertopstateyear","ceded_frac_liab_insurertopstateyear_uncensored","num_captives_insureryr","num_captives_insureryr_intensive")]

fwrite(data_insurer,file=paste0("output/CapitalAllocation_insureryear",captive_definition_this,".csv"))
fwrite(data_insurer_group,file=paste0("output/CapitalAllocation_insureryear_group",captive_definition_this,".csv"))

data_insurerstateyr = data_agreement %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSTATEDOMICILED,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                                                      num_captives_insureryr = sum(captive_is_active,na.rm=TRUE),
                                                                                                                                      num_captives_insureryr_intensive = sum(captive_is_active_intensive,na.rm=TRUE))
data_insurerstateyr_group = data_agreement %>% group_by(CEDENTSNLTOPENTITYKEY,CEDENTSTATEDOMICILED,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                                                           num_captives_insureryr = sum(captive_is_active,na.rm=TRUE),
                                                                                                                                           num_captives_insureryr_intensive = sum(captive_is_active_intensive,na.rm=TRUE))
data_insurerstateyr <- merge(data_insurerstateyr,data_cedent,by=c("CEDENTSNLSTATENTITYKEY","year"),all.x=TRUE)
data_insurerstateyr_group <- merge(data_insurerstateyr_group,data_cedent_group,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

amount_vars <- c("amount_reinsured")
data_insurerstateyr[,amount_vars][is.na(data_insurerstateyr[amount_vars])] <- 0
data_insurerstateyr_group[,amount_vars][is.na(data_insurerstateyr_group[amount_vars])] <- 0

data_insurerstateyr$ceded_frac_liab <- data_insurerstateyr$amount_reinsured / data_insurerstateyr$RESERVESGROSS
data_insurerstateyr_group$ceded_frac_liab <- data_insurerstateyr_group$amount_reinsured / data_insurerstateyr_group$RESERVESGROSS

data_insurerstateyr$ceded_frac_liab_uncensored = data_insurerstateyr$ceded_frac_liab
data_insurerstateyr_group$ceded_frac_liab_uncensored = data_insurerstateyr_group$ceded_frac_liab

data_insurerstateyr$ceded_frac_liab[which(data_insurerstateyr$ceded_frac_liab < 0)] <- 0
data_insurerstateyr$ceded_frac_liab[which(data_insurerstateyr$ceded_frac_liab >= 1)] <- 0.9999
data_insurerstateyr_group$ceded_frac_liab[which(data_insurerstateyr_group$ceded_frac_liab < 0)] <- 0
data_insurerstateyr_group$ceded_frac_liab[which(data_insurerstateyr_group$ceded_frac_liab >= 1)] <- 0.9999

data_insurerstateyr = data_insurerstateyr[,c("CEDENTSNLSTATENTITYKEY","year","CEDENTSTATEDOMICILED","REINSSTATEDOMICILED","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored","num_captives_insureryr","num_captives_insureryr_intensive")]
data_insurerstateyr_group = data_insurerstateyr_group[,c("CEDENTSNLTOPENTITYKEY","year","REINSSTATEDOMICILED","amount_reinsured","ceded_frac_liab","ceded_frac_liab_uncensored","num_captives_insureryr","num_captives_insureryr_intensive")]

fwrite(data_insurerstateyr,file=paste0("output/CapitalAllocation_insurerstateyear",captive_definition_this,".csv"))
fwrite(data_insurerstateyr_group,file=paste0("output/CapitalAllocation_insurerstateyear_group",captive_definition_this,".csv"))
}

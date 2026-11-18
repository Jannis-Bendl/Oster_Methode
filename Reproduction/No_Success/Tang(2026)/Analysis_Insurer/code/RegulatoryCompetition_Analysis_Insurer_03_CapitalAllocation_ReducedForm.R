source("../lib/r/Functions.R")

data <- readRDS(path.symlink("input/StateYear.rds"))

data_snl <- fread("output/CapitalAllocation_reinsurerstateyear_joint.csv")

state_names <- fread("../raw/States/StateNames.csv")
data_snl <- merge(data_snl,state_names,by=c("REINSSTATEDOMICILED"),all.x=TRUE)

names(data_snl) <- mapvalues(names(data_snl),
                             from=c("state"),
                             to=c("State"))

data_snl <- data_snl[order(State,year),]

data_quantities <- fread(path.symlink("input/SNL_Quantities.csv"))

data_quantities <- data_quantities[which(data_quantities$lob == "Ordinary Life Insurance"),]
data_quantities <- data_quantities %>% group_by(state,year) %>% summarise(DPW_Life = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))
names(data_quantities) <- mapvalues(names(data_quantities),
                                    from=c("state"),
                                    to=c("State"))

data_quantities$DPW_Life <- data_quantities$DPW_Life / 1000000

data_financials <- fread("../CleanData/output/SNL_Basic_Info.csv")

data_financials <- data_financials %>% group_by(STATEINCORP) %>% summarise(newbusiness_insurer_opco = n())

names(data_financials) <- c("State_2","newbusiness_insurer_opco")

state_names <- fread("../raw/States/StateNames.csv")
names(state_names) <- c("State","State_2")

data_financials <- merge(data_financials,state_names,by=c("State_2"),all.x=TRUE)

data_financials <- as.data.table(data_financials)[,c("State","newbusiness_insurer_opco")]

data_statelaws <- fread(("../raw/States/CaptiveRegulators.csv"))

data_state_websites = fread("../raw/States/CaptiveRegulators_Websites_Output.csv")
data_state_websites = data_state_websites[,c("State","Text_Captive_sentiment","Text_Insurance_sentiment")]
data_state_websites$Text_Captive_sentiment_diff = data_state_websites$Text_Captive_sentiment - data_state_websites$Text_Insurance_sentiment

data_other <- fread(path.symlink("input/Other_All.csv"))

data_long_stateyr <- merge(data.frame(State=sort(unique(data$State))),
                           data.frame(year=seq(1996,2021,1)))
data_long <- melt(data,id.vars=c("State"))
data_long$year <- gsub("_","",str_extract(data_long$variable,"_(.*)$"))
data_long$variable <- gsub("_","",str_extract(data_long$variable,"^(.*)_"))

data_long <- dcast(data_long, State + year ~ variable, value.var="value")

data_long <- merge(data_long_stateyr,data_long,by=c("State","year"),all.x=TRUE)
data_long <- merge(data_long,data_snl,by=c("State","year"),all.x=TRUE)
data_long <- merge(data_long,data_quantities,by=c("State","year"),all.x=TRUE)
data_long <- merge(data_long,data_financials,by=c("State"),all.x=TRUE)

data_long <- merge(data_long,data_statelaws,by=c("State"),all.x=TRUE)
data_long <- merge(data_long,data_state_websites,by=c("State"),all.x=TRUE)

data_long$YearFirstAllowedSPVCaptives[which(is.na(data_long$YearFirstAllowedSPVCaptives))] <- 9999
data_long$EntrySPVCaptives <- as.numeric(data_long$year == data_long$YearFirstAllowedSPVCaptives)
data_long$EntrySPVCaptives[which(data_long$year > data_long$YearFirstAllowedSPVCaptives)] <- NA

data_long$AllowSPVCaptives <- as.numeric(data_long$year >= data_long$YearFirstAllowedSPVCaptives)

data_long <- merge(data_long,data_long_stateyr,by=c("State","year"),all.x=TRUE)

data_long$Captives_num <- data_long$Captives
data_long <- data_long %>% group_by(year) %>% mutate(Captives_yr = sum(Captives,na.rm=TRUE))
data_long$Captives <- data_long$Captives / data_long$Captives_yr * 100

data_long <- merge(data_long,
                   data_other,
                   by=c("State","year"),
                   all.x=TRUE)

data_long$State_year = paste0(data_long$State,data_long$year)

data_long$AnnualFee_ln <- log(data_long$AnnualFee + 1)
data_long$AnnualFee_thousands <- (data_long$AnnualFee / 1000)

data_long$pop_ln <- log(data_long$pop+1)
data_long$lawyers_pop <- data_long$lawyers / data_long$pop

data_long$newbusinesses_ln <- log(data_long$newbusinesses+1)
data_long$newbusinesses_pop <- data_long$newbusinesses / data_long$pop
data_long$newbusinesses_thousands <- data_long$newbusinesses / 1000

data_long$donations_previous4_stateyr_EmployeesTotal = data_long$donations_previous4_stateyr / data_long$EmployeesTotal / 1000
data_long$donations_previous_stateyr_EmployeesTotal = data_long$donations_previous_stateyr / data_long$EmployeesTotal / 1000

data_long$tourists[which(is.na(data_long$tourists))] <- 0

data_long$CaptiveRegulatorFunding_CaptiveFund <- as.numeric(data_long$CaptiveRegulatorFunding_Source == "CaptiveFund")

data$Captives_Yes <- as.numeric(data$Captives_2019 > 0)
states_captives_yes <- data$State[which(data$Captives_Yes == 1)]

data_long_2019 <- data_long[which(data_long$year == 2019),c("State","DPW_Life")]
names(data_long_2019) <- c("State","DPW_Life_2019")
data <- merge(data,data_long_2019,by=c("State"),all.x=TRUE)
data$DPW_Life_2019_ln <- log(data$DPW_Life_2019+1)

data$DPW_2019_ln <- data$DPW_Life_2019_ln

data$Captives_2009 <- data$Captives_2009 / sum(data$Captives_2009,na.rm=TRUE) * 100
data$Captives_2014 <- data$Captives_2014 / sum(data$Captives_2014,na.rm=TRUE) * 100
data$Captives_2019 <- data$Captives_2019 / sum(data$Captives_2019,na.rm=TRUE) * 100

data_long$amount_reinsured[which(is.na(data_long$amount_reinsured))] <- 0
data_long$amount_reinsured_ln <- log(data_long$amount_reinsured + 1)

data_long$DPW_Life_ln <- log(data_long$DPW_Life+1)
data_long$DPW_ln <- data_long$DPW_Life_ln
data_long$Captives_Yes <- as.numeric(data_long$State %in% states_captives_yes)
data_long$Captives_ln <- log(data_long$Captives+1)

data_long <- data_long %>% group_by(year) %>% mutate(DPW_Life_yr = sum(DPW_Life,na.rm=TRUE))
data_long$DPW_Life_state_share_yr <- data_long$DPW_Life / data_long$DPW_Life_yr

data_long$num_captives[which(is.na(data_long$num_captives) & !is.na(data_long$Captives))] <- 0

fwrite(data_long,file="output/StateYear_joint.csv")

data_marketing <- data_statelaws[,c("State","WhyStatePage_or_Brochure","Keyword_Attract_Competitive_Welcome_Benefit_Favorable","Benefits_Capital")]

data_marketing_numeric <- data_marketing

data_marketing$WhyStatePage_or_Brochure <- mapvalues(data_marketing$WhyStatePage_or_Brochure,
                            from=c(0,1),
                            to=c("No","Yes"))
data_marketing$Keyword_Attract_Competitive_Welcome_Benefit_Favorable <- mapvalues(data_marketing$Keyword_Attract_Competitive_Welcome_Benefit_Favorable,
                                                     from=c(0,1),
                                                     to=c("No","Yes"))
data_marketing$Benefits_Capital <- mapvalues(data_marketing$Benefits_Capital,
                                                     from=c(0,1),
                                                     to=c("No","Yes"))

data_marketing = merge(data_marketing,data_state_websites[,c("State","Text_Captive_sentiment","Text_Captive_sentiment_diff")],by=c("State"),all.x=TRUE)

names(data_marketing) <- c("State","Has Brochure","Marketing Keyword","Promotes Capital Benefits","Text Sentiment","Text Sentiment Diff.")

stargazer(data_marketing,
          summary = FALSE,
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/state_marketing.tex"))

states_count <- nrow(data_marketing[which(!is.na(data_marketing$`Has Brochure`)),])
brochure_mean <- round(mean(data_marketing_numeric$WhyStatePage_or_Brochure,na.rm=TRUE)*100,digits=0)
brochure_count <- sum(data_marketing_numeric$WhyStatePage_or_Brochure,na.rm=TRUE)
marketing_mean <- round(mean(data_marketing_numeric$Keyword_Attract_Competitive_Welcome_Benefit_Favorable[which(data_marketing_numeric$WhyStatePage_or_Brochure == 1)],na.rm=TRUE)*100,digits=0)
marketing_count <- sum(data_marketing_numeric$Keyword_Attract_Competitive_Welcome_Benefit_Favorable,na.rm=TRUE)
marketing_capreq_mean <- round(mean(data_marketing_numeric$Benefits_Capital[which(data_marketing_numeric$WhyStatePage_or_Brochure == 1)],na.rm=TRUE)*100,digits=0)
marketing_capreq_count <- sum(data_marketing_numeric$Benefits_Capital,na.rm=TRUE)

data_basic_info_nonlife <- readxl::read_xls(("../raw/SNL/SNL_NonLife_Basic_Information_Company.xls"),skip = 0)
data_basic_info_nonlife <- data_basic_info_nonlife[,c(2,5)]
names(data_basic_info_nonlife) <- c("CEDENTSNLSTATENTITYKEY","CEDENTSNLGROUPSTATENTITYKEY")

data_basic_info_nonlife$CEDENTSNLTOPENTITYKEY <- data_basic_info_nonlife$CEDENTSNLGROUPSTATENTITYKEY
data_basic_info_nonlife$CEDENTSNLTOPENTITYKEY[which(is.na(data_basic_info_nonlife$CEDENTSNLGROUPSTATENTITYKEY))] <- data_basic_info_nonlife$CEDENTSNLSTATENTITYKEY[which(is.na(data_basic_info_nonlife$CEDENTSNLGROUPSTATENTITYKEY))]

data_snl_insureryear = fread("output/CapitalAllocation_insureryear_group.csv")
data_snl_insurerstateyear = fread("output/CapitalAllocation_insurerstateyear_group.csv")

data_cedent <- fread(path.symlink("input/SNL_Financials_Group.csv"))

names(data_cedent) <- mapvalues(names(data_cedent),
                                from=c("SNLSTATENTITYKEY"),
                                to=c("CEDENTSNLTOPENTITYKEY"))

data_quantities <- fread(path.symlink("input/SNL_Quantities.csv"))

data_quantities <- data_quantities[which(data_quantities$lob == "Ordinary Life Insurance"),]

names(data_quantities) <- mapvalues(names(data_quantities),
                                    from=c("SNLSTATENTITYKEY"),
                                    to=c("CEDENTSNLSTATENTITYKEY"))

data_quantities <- merge(data_quantities,data_basic_info_nonlife,by=c("CEDENTSNLSTATENTITYKEY"),all.x=TRUE)

data_quantities <- data_quantities %>% group_by(CEDENTSNLTOPENTITYKEY,year,state) %>% summarise(PremiumsAndAnnuityConsiderations = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))

data_quantities <- data_quantities %>% group_by(CEDENTSNLTOPENTITYKEY,year) %>% mutate(PremiumsAndAnnuityConsiderations_insureryr = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))
data_quantities$state_share <- data_quantities$PremiumsAndAnnuityConsiderations / data_quantities$PremiumsAndAnnuityConsiderations_insureryr

data_quantities$state_share[which(data_quantities$state_share < 0)] <- 0
data_quantities$state_share[which(data_quantities$state_share > 1)] <- 1

state_names <- fread("../raw/States/StateNames.csv")
data_quantities <- merge(data_quantities,state_names,by=c("state"),all.x=TRUE)

names(data_quantities) <- mapvalues(names(data_quantities),
                             from=c("state"),
                             to=c("State"))

data_concentration = fread("../CleanData/output/SNL_Quantities_MarketConcentration_GroupLevel.csv")

names(data_concentration) = mapvalues(names(data_concentration),from=c("SNLTOPENTITYKEY"),to=c("CEDENTSNLTOPENTITYKEY"))

data_long <- fread("output/StateYear_joint.csv")

cols_data_long <- names(data_long)[which(!names(data_long) %in% c("DPW","REINSSTATEDOMICILED","amount_reinsured_ln"))]
data_long <- data_long[,..cols_data_long]

names(data_long) <- mapvalues(names(data_long),
                             from=c("State","amount_reinsured"),
                             to=c("state","amount_reinsured_stateyr"))

state_names <- fread("../raw/States/StateNames.csv")
data_long <- merge(data_long,state_names,by=c("state"),all.x=TRUE)

names(data_long) <- mapvalues(names(data_long),
                              from=c("state"),
                              to=c("State"))

data_long_1999 <- data_long[which(data_long$year == 1999),c("REINSSTATEDOMICILED","DPW_Life")]
names(data_long_1999) <- c("REINSSTATEDOMICILED","DPW_Life_1999")
data_long <- merge(data_long,data_long_1999,by=c("REINSSTATEDOMICILED"),all.x=TRUE)
data_long$DPW_Life_1999_ln <- log(data_long$DPW_Life_1999+1)

data_donations = fread("../raw/DIME/DIME_InsurerStateYear.csv")

names(data_donations) = c("CEDENTSNLSTATENTITYKEY","State_2","year","x","amount_previous4","amount_previous","amount_total")

data_donations = merge(data_donations,
                       data_basic_info_nonlife[,c("CEDENTSNLSTATENTITYKEY","CEDENTSNLTOPENTITYKEY")],
                       by=c("CEDENTSNLSTATENTITYKEY"),
                       all.x=TRUE)

data_donations = data_donations[which(data_donations$CEDENTSNLTOPENTITYKEY %in% unique(data_snl$CEDENTSNLTOPENTITYKEY)),]

data_donations = data_donations %>% group_by(CEDENTSNLTOPENTITYKEY,State_2,year) %>% summarise(donations_previous4_insurerstateyr = sum(amount_previous4,na.rm=TRUE),
                                                                                               donations_previous_insurerstateyr  = sum(amount_previous,na.rm=TRUE),
                                                                                               donations_total_insurerstateyr     = sum(amount_total,na.rm=TRUE))

data_ambest_ratings <- fread("../raw/AMBest/AMBest_Ratings_All.csv")

data_ambest_id <- fread("../raw/AMBest/AMBest_ID_NAIC.csv")
names(data_ambest_id) <- c("amb_co_num","NAICCOMPANYCODE")

data_ambest_id <- data_ambest_id[which(!is.na(data_ambest_id$NAICCOMPANYCODE)),]

data_ambest_with_naiccompanycode = merge(data_ambest_id,data_ambest_ratings,by=c("amb_co_num"),all.x=TRUE,all.y=TRUE)

data_company = fread("../CleanData/output/SNL_Financials.csv")
data_company$CEDENTSNLTOPENTITYKEY = data_company$SNLGROUPSTATENTITYKEY
data_company$CEDENTSNLTOPENTITYKEY[which((data_company$CEDENTSNLTOPENTITYKEY == ""))] = data_company$SNLSTATENTITYKEY[which((data_company$CEDENTSNLTOPENTITYKEY == ""))]
data_company = data_company[which(data_company$NAICCOMPANYCODE %in% data_ambest_with_naiccompanycode$NAICCOMPANYCODE),]
data_company = unique(data_company[,c("CEDENTSNLTOPENTITYKEY","NAICCOMPANYCODE")])
data_company = data_company[which(!is.na(data_company$NAICCOMPANYCODE)),]

data_ambest_with_naiccompanycode$NAICCOMPANYCODE = as.numeric(data_ambest_with_naiccompanycode$NAICCOMPANYCODE)
data_company$NAICCOMPANYCODE = as.numeric(data_company$NAICCOMPANYCODE)
data_ambest = merge(data_ambest_with_naiccompanycode,data_company,by=c("NAICCOMPANYCODE"),all.x=TRUE)
data_ambest$RatingNumeric_hasratings = as.numeric(!is.na(data_ambest$RatingNumeric))
vars_concat = c("NAICCOMPANYCODE","amb_co_num")
data_ambest = data_ambest %>% group_by(CEDENTSNLTOPENTITYKEY,year) %>% summarise(RatingNumeric_min = min(RatingNumeric,na.rm=TRUE),
                                                                                 RatingNumeric_max = max(RatingNumeric,na.rm=TRUE),
                                                                                 RatingNumeric_mean = mean(RatingNumeric,na.rm=TRUE),
                                                                                 RatingNumeric_median = median(RatingNumeric,na.rm=TRUE),
                                                                                 RatingNumeric_numobs = sum(RatingNumeric_hasratings,na.rm=TRUE),
                                                                                 across(all_of(vars_concat), ~paste0(unique(.x[!is.na(.x)]), collapse = ", "), .names = "{.col}"),.groups = "drop")
data_ambest = data_ambest[which(data_ambest$RatingNumeric_numobs >= 1),]

names(data_ambest) = mapvalues(names(data_ambest),from=c("NAICCOMPANYCODE","amb_co_num"),to=c("NAICCOMPANYCODE_group","amb_co_num_group"))

CEDENTSNLTOPENTITYKEY_all <- data.frame(CEDENTSNLTOPENTITYKEY=sort(unique(c(data_snl$CEDENTSNLTOPENTITYKEY,data_cedent$CEDENTSNLTOPENTITYKEY[which(data_cedent$CEDENTSNLTOPENTITYKEY != "SNL_STAT_ENTITY_KEY")]))))
CEDENTSNLTOPENTITYKEY_all$x <- 1

state_names <- fread("../raw/States/StateNames_US.csv")
REINSSTATEDOMICILED_all <- data.frame(REINSSTATEDOMICILED=sort(unique(state_names$REINSSTATEDOMICILED)))
REINSSTATEDOMICILED_all$x <- 1

year_all <- data.frame(year=sort(unique(data_snl$year)))
year_all$x <- 1

data_all <- merge(CEDENTSNLTOPENTITYKEY_all,year_all,by="x")
data_all_insureryear = data_all
data_all <- merge(data_all,REINSSTATEDOMICILED_all,by="x")

data_all <- merge(data_all,data_snl_insurerstateyear,by=c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year"),all.x=TRUE)
data_all_insureryear <- merge(data_all_insureryear,data_snl_insureryear,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_all <- merge(data_all,data_cedent,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)
data_all_insureryear = merge(data_all_insureryear,data_cedent,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_all <- merge(data_all,data_quantities,by=c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year"),all.x=TRUE)

data_all <- merge(data_all,data_concentration,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_all <- merge(data_all,data_long,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE)
data_all_insureryear <- merge(data_all_insureryear,data_long,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE)

data_all = merge(data_all,data_donations,by=c("CEDENTSNLTOPENTITYKEY","State_2","year"),all.x=TRUE)

data_all$donations_previous4_insurerstateyr[which(is.na(data_all$donations_previous4_insurerstateyr))] = 0
data_all$donations_previous_insurerstateyr[which(is.na(data_all$donations_previous_insurerstateyr))] = 0
data_all$donations_total_insurerstateyr[which(is.na(data_all$donations_total_insurerstateyr))] = 0

data_all = merge(data_all,data_ambest,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)
data_all_insureryear = merge(data_all_insureryear,data_ambest,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_all$has_captive <- as.numeric(is.na(data_all$amount_reinsured) == FALSE)
data_all$amount_reinsured[which(is.na(data_all$amount_reinsured))] <- 0
data_all$ceded_frac_liab[which(is.na(data_all$ceded_frac_liab))] <- 0
data_all$has_captive_intensive <- as.numeric(data_all$amount_reinsured > 0)

data_all_insureryear$has_captive <- as.numeric(is.na(data_all_insureryear$amount_reinsured) == FALSE)
data_all_insureryear$amount_reinsured[which(is.na(data_all_insureryear$amount_reinsured))] <- 0
data_all_insureryear$ceded_frac_liab[which(is.na(data_all_insureryear$ceded_frac_liab))] <- 0
data_all_insureryear$has_captive_intensive <- as.numeric(data_all_insureryear$amount_reinsured > 0)

data_all$has_captive_count <- ifelse(!is.na(data_all$num_captives_insureryr), data_all$num_captives_insureryr, 0)
data_all$has_captive_count_intensive <- ifelse(!is.na(data_all$num_captives_insureryr_intensive), data_all$num_captives_insureryr_intensive, 0)

data_all = data_all %>% group_by(CEDENTSNLTOPENTITYKEY) %>% mutate(amount_reinsured_insurerallyears = sum(amount_reinsured,na.rm=TRUE),
                                                                   has_captive_insurerallyears = as.numeric(sum(has_captive,na.rm=TRUE) > 0))

data_all_insureryear = data_all_insureryear %>% group_by(CEDENTSNLTOPENTITYKEY) %>% mutate(amount_reinsured_insurerallyears = sum(amount_reinsured,na.rm=TRUE),
                                                                   has_captive_insurerallyears = as.numeric(sum(has_captive,na.rm=TRUE) > 0))

data_all$sells_in_state <- as.numeric(data_all$state_share > 0)

data_all$CEDENTSNLTOPENTITYKEY_year <- paste0(data_all$CEDENTSNLTOPENTITYKEY,data_all$year)
data_all$CEDENTSNLTOPENTITYKEY_REINSSTATEDOMICILED <- paste0(data_all$CEDENTSNLTOPENTITYKEY,data_all$REINSSTATEDOMICILED)
data_all$REINSSTATEDOMICILED_year <- paste0(data_all$REINSSTATEDOMICILED,data_all$year)

data_all$amount_reinsured_ln <- log(data_all$amount_reinsured + 1)

data_all_insureryear$amount_reinsured_ln <- log(data_all_insureryear$amount_reinsured + 1)

cedent_states = fread(file="../CleanData/output/SNL_Geography.csv")
names(cedent_states) = c("CEDENTSNLTOPENTITYKEY","CEDENTSNLTOPENTITYKEY_STATEDOMICILED","CEDENTSNLTOPENTITYKEY_STATE")

data_all = merge(data_all,cedent_states,by=c("CEDENTSNLTOPENTITYKEY"),all.x=TRUE)

data_all$CEDENTSTATEDOMICILED = data_all$CEDENTSNLTOPENTITYKEY_STATE

geo_dist = fread("../raw/States/States_Distances.csv")

data_all = merge(data_all,geo_dist,by=c("REINSSTATEDOMICILED","CEDENTSTATEDOMICILED"),all.x=TRUE)

data_all$geography_distance = data_all$geography_distance / 1000

process_vars <- function(data, vars, fraction = 0.01) {
  for (var in vars) {
    w_data <- winsorize(data[[var]], fraction = fraction)
    data[[paste0(var, "_std")]] <- as.vector(scale(w_data))
  }
  return(data)
}
vars_to_scale = c("TOTALLIAB","CASHSTINVESTTOLIAB","ROAECAPSURPLUS","LEVERAGE","AUTHCONTROLLEVELRISKBASEDCAPRATIO","EFFECTIVETAXRATELIFE")
data_all <- process_vars(data_all, vars = vars_to_scale, fraction = 0.01)
data_all_insureryear <- process_vars(data_all_insureryear, vars = vars_to_scale, fraction = 0.01)

data_all_insurerstateyear = data_all

data_long$kappa_economic_K_div_L_censored = pmax(data_long$kappa_economic_K_div_L,0)
data_all$kappa_economic_K_div_L_censored = pmax(data_all$kappa_economic_K_div_L,0)

fwrite(data_all,file="output/ReducedForm/data_all_fullsample.csv")

data_all_bk = data_all
data_all = data_all[which(data_all$has_captive_insurerallyears > 0),]
data_all_sample = data_all[which(data_all$year >= 2014 & data_all$year <= 2020),]

data_all_sample_captivebs = data_all[which(data_all$year >= 2014 & data_all$year <= 2020 & !is.na(data_all$kappa_state_captivebs) & !is.infinite(data_all$kappa_state_captivebs)),]

data_all_sample_captivebs = data_all_sample_captivebs %>% group_by(CEDENTSNLTOPENTITYKEY,year) %>% mutate(amount_reinsured_insureryr = sum(amount_reinsured,na.rm=TRUE))
data_all_sample_captivebs$insureryr_uses_captives = as.numeric(data_all_sample_captivebs$amount_reinsured_insureryr > 0)

L_div_Q = fread("../CleanData/output/L_div_Q.csv")

excess_reserve_ratio = fread("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio.csv")
excess_reserve_ratio = excess_reserve_ratio$reserve_statutory_gaap_ratio[1] - 1

kappa_h = fread("../CleanData/output/kappa_h.csv")
vega = kappa_h$vega

kappa_conversion_constant = excess_reserve_ratio / vega

controls_state = "CaptiveTaxRate + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r"
controls_insurerstate = "state_share + sells_in_state"
controls_joint = "newbusinesses_pop + tourists + state_share + vote_share_r + geography_distance"

reg_choice_1 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_2 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_3 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_4 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_5 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_2_dpw <- felm(as.formula(paste0("has_captive_intensive ~ DPW_Life | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

reg_choice_1_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_3_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_4_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_5_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_dpw_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ DPW_Life | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

data_captives_capital = fread("../CleanData/output/SNL_CaptiveCapitalRates_InsurerStateYear.csv")
data_captives_capital = data_captives_capital[,c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year","L_hat_times_1_plus_rho","capitalsurplus_captive")]
names(data_captives_capital) = mapvalues(names(data_captives_capital),
                                         from=c("L_hat_times_1_plus_rho"),
                                         to=c("L_hat_times_1_plus_rho_insurer"))

vega = fread("../raw/Other/FASB_Vega.csv")$V1[1]

excess_reserve_ratio = fread("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio.csv")
excess_reserve_ratio = excess_reserve_ratio$reserve_statutory_gaap_ratio - 1

data_all_sample_captivebs$kappa_statutory = (data_all_sample_captivebs$kappa_economic_K_div_L - excess_reserve_ratio) / (1 + excess_reserve_ratio)

data_all_sample_captivebs$K_statutory = data_all_sample_captivebs$kappa_statutory * pmax(data_all_sample_captivebs$amount_reinsured_stateyr,0,na.rm=TRUE)

data_all_sample_captivebs = merge(data_all_sample_captivebs,
                                       data_captives_capital,
                                       by=c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year"),
                                       all.x=TRUE)
data_all_sample_captivebs$L_stat_insurer = data_all_sample_captivebs$L_hat_times_1_plus_rho_insurer
data_all_sample_captivebs$K_stat_insurer = data_all_sample_captivebs$capitalsurplus_captive

data_all_sample_captivebs$amount_reinsured_leaveoneout = data_all_sample_captivebs$amount_reinsured_stateyr - pmax(data_all_sample_captivebs$amount_reinsured / 1000,0,na.rm=TRUE)
data_all_sample_captivebs$K_statutory_leaveoneout = data_all_sample_captivebs$K_statutory - pmax(data_all_sample_captivebs$K_stat_insurer,0,na.rm=TRUE)

data_all_sample_captivebs$kappa_statutory_leaveoneout = data_all_sample_captivebs$K_statutory_leaveoneout / data_all_sample_captivebs$amount_reinsured_leaveoneout

data_all_sample_captivebs$kappa_economic_K_div_L_leaveoneout = data_all_sample_captivebs$kappa_statutory_leaveoneout * (1 + excess_reserve_ratio) / vega + excess_reserve_ratio / vega

data_all_sample_captivebs_leaveoneout = data_all_sample_captivebs
data_all_sample_captivebs_leaveoneout = data_all_sample_captivebs_leaveoneout[which(abs(data_all_sample_captivebs_leaveoneout$kappa_economic_K_div_L_leaveoneout)<1),]

reg_choice_1_leaveoneout <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout)

reg_choice_2_leaveoneout <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout)

reg_choice_3_leaveoneout <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout)

reg_choice_4_leaveoneout <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout)

reg_choice_5_leaveoneout <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout)

reg_choice_1_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout[which(data_all_sample_captivebs_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_2_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout[which(data_all_sample_captivebs_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_3_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout[which(data_all_sample_captivebs_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_4_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout[which(data_all_sample_captivebs_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_5_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L_leaveoneout + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs_leaveoneout[which(data_all_sample_captivebs_leaveoneout$insureryr_uses_captives == 1),])

insureryrs_main_sample = unique(data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),c("CEDENTSNLTOPENTITYKEY","year","CEDENTSNLTOPENTITYKEY_year")])
data_all_sample_statesallowcaptives = data_all[which(data_all$year >= 2014 & data_all$year <= 2020 & (data_all$CEDENTSNLTOPENTITYKEY_year %in% insureryrs_main_sample$CEDENTSNLTOPENTITYKEY_year) & (data_all$AllowsCaptives == 1)),]

reg_choice_2_spfc <- felm(as.formula(paste0("has_captive_intensive ~ AllowSPVCaptives | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_statesallowcaptives)

reg_choice_2_advertising <- felm(as.formula(paste0("has_captive_intensive ~ Benefits_Capital | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_statesallowcaptives)

reg_choice_2_dpw_allstates <- felm(as.formula(paste0("has_captive_intensive ~ DPW_Life | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_statesallowcaptives)

reg_choice_1_intensive <- felm(as.formula(paste0("amount_reinsured_ln ~ kappa_economic_K_div_L + CaptiveTaxRate + newbusinesses_pop + tourists + ",controls_insurerstate," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs)

data <- fread("output/CapitalAllocation_insurerstateyear.csv")

data_ss <- data[which(data$amount_reinsured > 0),] %>% group_by(CEDENTSNLSTATENTITYKEY) %>% summarise(num_states = n_distinct(REINSSTATEDOMICILED,na.rm=TRUE))

num_insurers_multiple_domiciles <- sum(data_ss$num_states > 1,na.rm=TRUE)

data_all_sample_captivebs <- data_all_sample_captivebs[order(data_all_sample_captivebs$CEDENTSNLTOPENTITYKEY,data_all_sample_captivebs$REINSSTATEDOMICILED,data_all_sample_captivebs$year),]
data_all_sample_captivebs = data_all_sample_captivebs %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED) %>% mutate(kappa_economic_K_div_L_leaveoneout_p1 = dplyr::lag(kappa_economic_K_div_L_leaveoneout,n=1))
data_all_sample_captivebs$kappa_economic_K_div_L_leaveoneout_delta = data_all_sample_captivebs$kappa_economic_K_div_L_leaveoneout - data_all_sample_captivebs$kappa_economic_K_div_L_leaveoneout_p1

data_all_sample_captivebs2 = data_all_sample_captivebs

data_all_sample_captivebs2 = data_all_sample_captivebs2[order(data_all_sample_captivebs2$CEDENTSNLTOPENTITYKEY,data_all_sample_captivebs2$year,data_all_sample_captivebs2$REINSSTATEDOMICILED),]
data_all_sample_captivebs2 = data_all_sample_captivebs2 %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED) %>% mutate(has_captive_intensive_p1 = dplyr::lag(has_captive_intensive,n=1),
                                                                                                                           has_captive_count_p1 = dplyr::lag(has_captive_count,n=1),
                                                                                                                           has_captive_count_intensive_p1 = dplyr::lag(has_captive_count_intensive,n=1),
                                                                                                                           kappa_economic_K_div_L_p1 = dplyr::lag(kappa_economic_K_div_L,n=1))

data_all_sample_captivebs2$has_captive_intensive_delta = data_all_sample_captivebs2$has_captive_intensive - data_all_sample_captivebs2$has_captive_intensive_p1
data_all_sample_captivebs2$kappa_economic_K_div_L_delta = data_all_sample_captivebs2$kappa_economic_K_div_L - data_all_sample_captivebs2$kappa_economic_K_div_L_p1

data_all_sample_captivebs2$has_captive_count_delta = data_all_sample_captivebs2$has_captive_count - data_all_sample_captivebs2$has_captive_count_p1
data_all_sample_captivebs2$has_captive_count_intensive_delta = data_all_sample_captivebs2$has_captive_count_intensive - data_all_sample_captivebs2$has_captive_count_intensive_p1

reg_choice_1_switch <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2)

reg_choice_2_switch <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2)

reg_choice_3_switch <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2)

reg_choice_4_switch <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2)

reg_choice_5_switch <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2)

reg_choice_1_switch_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2[which(data_all_sample_captivebs2$insureryr_uses_captives == 1),])

reg_choice_2_switch_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2[which(data_all_sample_captivebs2$insureryr_uses_captives == 1),])

reg_choice_3_switch_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2[which(data_all_sample_captivebs2$insureryr_uses_captives == 1),])

reg_choice_4_switch_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2[which(data_all_sample_captivebs2$insureryr_uses_captives == 1),])

reg_choice_5_switch_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_delta + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2[which(data_all_sample_captivebs2$insureryr_uses_captives == 1),])

data_all_sample_captivebs2_leaveoneout = data_all_sample_captivebs2

fwrite(data_all_sample_captivebs,"output/ReducedForm/data_all_sample_captivebs.csv")
fwrite(data_all_sample_captivebs2,"output/ReducedForm/data_all_sample_captivebs2.csv")

reg_choice_1_switch_leaveoneout <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout)

reg_choice_2_switch_leaveoneout <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout)

reg_choice_3_switch_leaveoneout <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout)

reg_choice_4_switch_leaveoneout <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout)

reg_choice_5_switch_leaveoneout <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout)

reg_choice_1_switch_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta | 0 | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout[which(data_all_sample_captivebs2_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_2_switch_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout[which(data_all_sample_captivebs2_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_3_switch_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + CaptiveTaxRate | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout[which(data_all_sample_captivebs2_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_4_switch_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout[which(data_all_sample_captivebs2_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_5_switch_leaveoneout_insureryr_uses_captives <- felm(as.formula(paste0("has_captive_intensive_delta ~ kappa_economic_K_div_L_leaveoneout_delta + CaptiveTaxRate + ",controls_joint," | CEDENTSNLTOPENTITYKEY_year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs2_leaveoneout[which(data_all_sample_captivebs2_leaveoneout$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives_with_competition_1 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + HHI_premium_weighted | year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives_with_competition_2 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + HHI_change_p1_to_p0_premium_weighted | year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives_with_competition_3 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + NumFirms_premium_weighted | year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives_with_competition_4 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + NumFirms_change_p1_to_p0_premium_weighted | year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

reg_choice_2_insureryr_uses_captives_with_competition_5 <- felm(as.formula(paste0("has_captive_intensive ~ kappa_economic_K_div_L + HHI_premium_weighted + CaptiveTaxRate + ",controls_joint," | year | 0 | CEDENTSNLTOPENTITYKEY + year")), data=data_all_sample_captivebs[which(data_all_sample_captivebs$insureryr_uses_captives == 1),])

fwrite(data_all_sample_captivebs_leaveoneout,file="output/ReducedForm/data_all.csv")

currentwd <- getwd()
stata_exe <- "/Applications/StataNow/StataMP.app/Contents/MacOS/StataMP"
do_file <- paste0(currentwd,"/code/RegulatoryCompetition_Analysis_Insurer_03b_ReducedForm_OsterTest.do")
do_file <- paste0("\"",do_file,"\"")
cmd <- paste(shQuote(stata_exe), "-e do", shQuote(do_file))
system(cmd)

ostertest <- readxl::read_xlsx("output/ReducedForm/reg_has_captives_capreq_insurerstateyr_ostertest.xlsx")
ostertest <- round(ostertest$delta,digits=2)

choicebetadepvarmeancapreq <- round(mean(data_all$has_captive_intensive*100,na.rm=TRUE),digits=2)
choicebetamagnitudecapreqkappa <- abs((round(summary(reg_choice_2_leaveoneout_insureryr_uses_captives)$coefficients[1,1],digits=1)))
choicebetadollarcapreq <- abs(round(summary(reg_choice_1_intensive)$coefficients[1,1],digits=2))
ostertestcapreq <- ostertest

detach("package:stargazer",unload=T)
remove.packages("stargazer")
download.file("https://cran.r-project.org/src/contrib/stargazer_5.2.3.tar.gz", destfile = "stargazer_5.2.3.tar.gz")
untar("stargazer_5.2.3.tar.gz")
stargazer_src <- readLines("stargazer/R/stargazer-internal.R")
stargazer_src[1990] <- stargazer_src[1995]
stargazer_src[1995] <- ""
writeLines(stargazer_src, con="stargazer/R/stargazer-internal.R")
install.packages("stargazer", repos = NULL, type="source")
library(stargazer)

stargazer(reg_choice_1,
          reg_choice_2,
          reg_choice_3,
          reg_choice_4,
          reg_choice_5,
          reg_choice_2_switch,
          reg_choice_2_dpw,
          order=c("kappa_economic_K_div_L","kappa_economic_K_div_L_delta","DPW_Life","CaptiveTaxRate"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)","$\\Delta$ 1(Captive)","1(Captive)"),
          covariate.labels = c("Capital Rate","$\\Delta$ Capital Rate","Default Exposure","Captive Tax Rate",
                               "Business Registrations","Amenities","Share Sold in State","Presidential Vote Share","Distance"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","","X","X","X","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_all.tex"))

stargazer(reg_choice_1_insureryr_uses_captives,
          reg_choice_2_insureryr_uses_captives,
          reg_choice_5_insureryr_uses_captives,
          reg_choice_2_switch_insureryr_uses_captives,
          reg_choice_2_dpw_insureryr_uses_captives,
          reg_choice_2_leaveoneout,
          order=c("kappa_economic_K_div_L","kappa_economic_K_div_L_delta","kappa_economic_K_div_L_leaveoneout","DPW_Life","CaptiveTaxRate"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)","$\\Delta$ 1(Captive)","1(Captive)"),
          covariate.labels = c("Capital Rate","$\\Delta$ Capital Rate","Capital Rate (Excl. Own)","Default Exposure","Captive Tax Rate",
                               "Business Registrations","Amenities","Share Sold in State","Presidential Vote Share","Distance"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","","X","X","X","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_all_insureryr_uses_captives.tex"))

stargazer(reg_choice_1_leaveoneout,
          reg_choice_2_leaveoneout,
          reg_choice_5_leaveoneout,
          reg_choice_2_switch_leaveoneout,
          reg_choice_2_dpw,
          order=c("kappa_economic_K_div_L_leaveoneout","kappa_economic_K_div_L_leaveoneout_delta","DPW_Life","CaptiveTaxRate"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)","$\\Delta$ 1(Captive)","1(Captive)"),
          covariate.labels = c("Capital Rate","$\\Delta$ Capital Rate","Default Exposure","Captive Tax Rate",
                               "Business Registrations","Amenities","Share Sold in State","Presidential Vote Share","Distance"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","","X","X","X","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_all_leaveoneout.tex"))

stargazer(reg_choice_1_leaveoneout_insureryr_uses_captives,
          reg_choice_2_leaveoneout_insureryr_uses_captives,
          reg_choice_5_leaveoneout_insureryr_uses_captives,
          reg_choice_5_switch_leaveoneout_insureryr_uses_captives,
          reg_choice_2_dpw_insureryr_uses_captives,
          order=c("kappa_economic_K_div_L_leaveoneout","kappa_economic_K_div_L_leaveoneout_delta","DPW_Life","CaptiveTaxRate"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)","$\\Delta$ 1(Captive)","1(Captive)"),
          covariate.labels = c("Capital Rate","$\\Delta$ Capital Rate","Default Exposure","Captive Tax Rate",
                               "Business Registrations","Amenities","Share Sold in State","Presidential Vote Share","Distance"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","","X","X","X","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_all_leaveoneout_insureryr_uses_captives.tex"))

stargazer(reg_choice_2_insureryr_uses_captives,
          reg_choice_5_insureryr_uses_captives,
          reg_choice_2_leaveoneout,
          reg_choice_5_leaveoneout,
          order=c("kappa_economic_K_div_L","kappa_economic_K_div_L_leaveoneout","DPW_Life","CaptiveTaxRate"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)"),
          covariate.labels = c("Capital Rate (Including Own)","Capital Rate (Excluding Own)","Captive Tax Rate",
                               "Business Registrations","Amenities","Share Sold in State","Presidential Vote Share","Distance"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","X","X","X","X"),
                         c("Include Own-Captive in Capital Rate","X","X","",""),
                         c("Include No-Captive Insurers","","","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_all_robustness.tex"))

stargazer(reg_choice_4,reg_choice_1_intensive,reg_choice_1_switch,
          order=c("kappa_economic_K_div_L","kappa_economic_K_div_L_delta"),
          dep.var.labels=c("1(Captive)","log(Amount)","$\\Delta$ 1(Captive)"),
          omit = c("cons","Constant","newbusinesses_pop","tourists","Commissioner_Appointed","vote_share_r","CaptiveTaxRate","state_share","sells_in_state","geography_distance"),
          covariate.labels = c("Capital Rate","$\\Delta$ Capital Rate"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("State and Insurer-State Controls","X","X","X"),
                         c("Insurer-Year FEs","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_mechanisms_all_short.tex"))

stargazer(reg_choice_1_intensive,
          order=c("AllowSPVCaptives","kappa_economic_K_div_L","allow_prescribed","DPW_Life"),
          dep.var.labels=c("ln(Amount)"),
          omit = c("cons","Constant","newbusinesses_pop","tourists","Commissioner_Appointed","vote_share_r","CaptiveTaxRate","state_share","sells_in_state"),
          covariate.labels = c("Capital Rate"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("State and Insurer-State Chars","X"),
                         c("Insurer-Year FEs","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_mechanisms_all_short_intensive.tex"))

stargazer(reg_choice_2_spfc,reg_choice_2_advertising,reg_choice_2_dpw_allstates,
          order=c("AllowSPVCaptives","Benefits_Capital","DPW_Life","CaptiveTaxRate","AnnualFee"),
          dep.var.labels=c("1(Allow Captives)","1(Allow Captives)","1(Allow Captives)"),
          covariate.labels = c("1(SPFCs)","1(Benefits)","Default Exposure","Business Registrations","Amenities","Presidential Vote Share"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Insurer-Year FEs","X","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_proxies.tex"))

stargazer(reg_choice_2_insureryr_uses_captives_with_competition_1,
          reg_choice_2_insureryr_uses_captives_with_competition_2,
          reg_choice_2_insureryr_uses_captives_with_competition_3,
          reg_choice_2_insureryr_uses_captives_with_competition_4,
          reg_choice_2_insureryr_uses_captives_with_competition_5,
          order=c("kappa_economic_K_div_L","HHI_premium_weighted","HHI_change_p1_to_p0_premium_weighted","NumFirms_premium_weighted","NumFirms_change_p1_to_p0_premium_weighted"),
          dep.var.labels=c("1(Captive)","1(Captive)","1(Captive)","1(Captive)","1(Captive)"),
          omit = c("cons","Constant","newbusinesses_pop","tourists","Commissioner_Appointed","vote_share_r","CaptiveTaxRate","state_share","sells_in_state","geography_distance"),
          covariate.labels = c("Capital Rate","HHI","Number of Competitors","$\\Delta$ HHI", "$\\Delta$ Number of Competitors"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          add.lines=list(c("Year FEs","X","X","X","X","X"),
                         c("State Chars","","","","","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_has_captives_productmarketcompetition.tex"))

reg_supply_allowspvcaptives <- felm(AllowSPVCaptives ~ DPW_Life + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r | year | 0 | State, data=data_long[which(data_long$year >= 2002 & data_long$year <= 2020),])

reg_supply_kappa_state_captivebs = felm(kappa_economic_K_div_L ~ DPW_Life + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r | year | 0 | State, data=data_long[which(data_long$year >= 2014 & data_long$year <= 2020),])

reg_supply_captivefund <- felm(CaptiveRegulatorFunding_CaptiveFund ~ DPW_Life + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r | year | 0 | State, data=data_long[which(data_long$year >= 2002 & data_long$year <= 2020),])

reg_supply_marketing <- felm(WhyStatePage_or_Brochure ~ DPW_Life + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r | 0 | 0 | State, data=data_long[which(data_long$year == 2020),])

reg_supply_sentiment <- felm(Text_Captive_sentiment_diff ~ DPW_Life + newbusinesses_pop + tourists + Commissioner_Appointed + vote_share_r | 0 | 0 | State, data=data_long[which(data_long$year == 2020),])

stargazer(reg_supply_allowspvcaptives,
          reg_supply_kappa_state_captivebs,
          order=c("DPW_Life","CaptiveTaxRate","AnnualFee"),
          dep.var.labels=c("1(Allow Captives)","Capital Rate"),
          covariate.labels = c("Default Exposure","Business Registrations","Amenities","Presidential Vote Share"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = c("cons","Commissioner_Appointed"),
          add.lines=list(c("Year FEs","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_mechanisms_dpw.tex"))

stargazer(reg_supply_allowspvcaptives,
          reg_supply_kappa_state_captivebs,
          order=c("DPW_Life","CaptiveTaxRate","AnnualFee"),
          dep.var.labels=c("1(Allow Captives)","Capital Rate"),
          covariate.labels = c("State Default Exposure","Business Environment","Amenities","1(Appointed Commissioner)","Rep. Vote Share"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = c("cons","newbusinesses_pop","tourists","Commissioner_Appointed","vote_share_r"),
          add.lines=list(c("State Chars","X","X"),
                         c("Year FEs","X","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_mechanisms_dpw_short.tex"))

stargazer(reg_supply_captivefund,
          reg_supply_marketing,
          reg_supply_sentiment,
          order=c("DPW_Life","CaptiveTaxRate","AnnualFee"),
          dep.var.labels=c("1(Department Fund)","1(Marketing)","Text Sentiment Diff."),
          covariate.labels = c("State Default Exposure","Business Environment","Amenities","Rep. Vote Share"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = c("cons","Commissioner_Appointed"),
          add.lines=list(c("State Chars","X","X","X"),
                         c("Year FEs","X","","")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_mechanisms_dpw_additional.tex"))

stargazer(reg_supply_captivefund,
          reg_supply_marketing,
          reg_supply_sentiment,
          order=c("DPW_Life","CaptiveTaxRate","AnnualFee"),
          dep.var.labels=c("1(Department Fund)","1(Marketing)","Text Sentiment Diff."),
          covariate.labels = c("State Default Exposure","Constant"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = c("cons","newbusinesses_pop","tourists","Commissioner_Appointed","vote_share_r"),
          add.lines=list(c("State Chars","X","X"),
                         c("Year FEs","X","","")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/reg_mechanisms_dpw_additional_short.tex"))

indvarsd = sd(data_long$DPW_Life[which(data_long$year >= 2014 & data_long$year <= 2020 & !is.na(data_long$kappa_economic_K_div_L))],na.rm=TRUE)
spfcbeta <- round(summary(reg_supply_allowspvcaptives)$coefficients[1] * 100,digits=2)
spfcmean <- round(mean(data_long$AllowSPVCaptives,na.rm=TRUE) * 100,digits=2)
spfcbetamagnituderaw <- abs(round(spfcbeta * indvarsd,digits=0))
spfcbetamagnitude <- abs(round(spfcbeta * indvarsd / spfcmean * 100,digits=0))

capratebeta <- round(summary(reg_supply_kappa_state_captivebs)$coefficients[1],digits=2)
capratebetamagnituderaw <- abs(round(capratebeta * indvarsd * 100,digits=1))

sizebetamagnituderaw <- abs(round(summary(reg_choice_3)$coefficients[1,1] * indvarsd * 100,digits=1))

data_long$kappa_state_captivebs[which(is.infinite(data_long$kappa_state_captivebs))] = NA
data_long_corr = rcorr(as.matrix(data_long[which(!is.na(data_long$kappa_state_captivebs)),c("AllowSPVCaptives","CaptiveRegulatorFunding_CaptiveFund","kappa_state_captivebs","WhyStatePage_or_Brochure","Text_Captive_sentiment_diff")]))

stargazer(data_long_corr$r,
          summary = FALSE,
          covariate.labels = c("1(Allow SPFCs)","1(Department Fund)","Capital Rate","1(Marketing)","Text Sentiment Diff."),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/corr_mechanisms.tex"))

data_all_sample$obs_sample = as.numeric(row.names(data_all_sample) %in% as.vector(rownames(model.frame(reg_choice_2_spfc))))

ss_var = c("has_captive_intensive",
           "kappa_economic_K_div_L_censored",
           "DPW_Life",
           "AllowSPVCaptives",
           as.vector(str_split(controls_state," \\+ ")[[1]]),
           as.vector(str_split(controls_insurerstate," \\+ ")[[1]]))

ss_var_labels = cm_captive[which(names(cm_captive) %in% ss_var)]
ss_var_labels = ss_var_labels[ss_var]

st(as.data.table(data_all_sample)[which(data_all_sample$obs_sample == 1),..ss_var],
   out="latex",
   labels = ss_var_labels,
   digits=2,
   summ = list(c('notNA(x)','mean(x)','sd(x)','quantile(x,probs=0.1)','quantile(x,probs=0.25)','quantile(x,probs=0.5)','quantile(x,probs=0.75)','quantile(x,probs=0.9)')),
   summ.names = list(c('N','Mean','SD','P10','P25','Median','P75','P90')),
   file=paste0("output/summary_stats/summary_stats_reinsurance.tex"))

numinsurers_demand = length(unique(data_all_sample$CEDENTSNLTOPENTITYKEY))
caprate_demand_mean = mean(data_all_sample$kappa_economic_K_div_L_censored[which(data_all_sample$obs_sample == 1)],na.rm=TRUE) * 100
caprate_demand_sd = sd(data_all_sample$kappa_economic_K_div_L_censored[which(data_all_sample$obs_sample == 1)],na.rm=TRUE) * 100

data_long = data_long[which(data_long$year >= 2002 & data_long$year <= 2020),]
data_long$obs_sample = as.numeric(!row.names(data_long) %in% as.vector(names(reg_supply_allowspvcaptives$na.action)))

statesallowspfcs = data_long$State_2[which(data_long$AllowSPVCaptives == 1 & data_long$year == 2019)]
numstatesallowspfcs = length(statesallowspfcs)

states = fread("output/CapitalAllocation_reinsurerstateyear_joint.csv")
states = states[which(states$REINSSTATEDOMICILED != ""),]
states = sort(unique(states$REINSSTATEDOMICILED))

numstatesstructural = length(states)

data_long$kappa_statutory = data_long$kappa_state_captivebs

kappastatecaptivebsmean = mean(data_long$kappa_state_captivebs,na.rm=TRUE)
kappastatecaptivebssd = sd(data_long$kappa_state_captivebs,na.rm=TRUE)

kappaeconomicmean = mean(data_long$kappa_economic_K_div_L_censored[which(data_long$year >= 2014 & data_long$year <= 2020)],na.rm=TRUE)
kappaeconomicsd = sd(data_long$kappa_economic_K_div_L_censored[which(data_long$year >= 2014 & data_long$year <= 2020)],na.rm=TRUE)

data_all_insureryear = data_all_insureryear %>% group_by(year) %>% mutate(RatingNumeric_max_filled = mean(RatingNumeric_max,na.rm=TRUE))
data_all_insureryear$RatingNumeric_max_filled[which(!is.na(data_all_insureryear$RatingNumeric_max))] = data_all_insureryear$RatingNumeric_max[which(!is.na(data_all_insureryear$RatingNumeric_max))]

data_all_insureryear$STATE_is_captive_state = as.numeric(grepl("AZ|IA|MO|SC|VT",data_all_insureryear$STATE))

data_all_insureryear$age_ln = log(data_all_insureryear$age + 1)

reg_uses_captives_1 <- feols(has_captive_intensive ~ TOTALLIAB_ln, data=data_all_insureryear, vcov = ~CEDENTSNLTOPENTITYKEY + year)

reg_uses_captives_2 <- feols(has_captive_intensive ~ publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries, data=data_all_insureryear, vcov = ~CEDENTSNLTOPENTITYKEY + year)

reg_uses_captives_3 <- feols(has_captive_intensive ~ TOTALLIAB_ln | year, data=data_all_insureryear, vcov = ~CEDENTSNLTOPENTITYKEY + year)

reg_uses_captives_4 <- feols(has_captive_intensive ~ publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries | year, data=data_all_insureryear, vcov = ~CEDENTSNLTOPENTITYKEY + year)

reg_uses_captives_6 <- feols(has_captive_intensive ~ TOTALLIAB_ln + publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + BUSINESSFOCUS_none + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries | year, data=data_all_insureryear, vcov = ~CEDENTSNLTOPENTITYKEY + year)

writeLines(as.character(modelsummary(list("(1)" = reg_uses_captives_1,
                             "(2)" = reg_uses_captives_2,
                             "(3)" = reg_uses_captives_3,
                             "(4)" = reg_uses_captives_4,
                             "(5)" = reg_uses_captives_6),
                        fmt = "%.3f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm,
                        output="latex_tabular",
                        add_rows = data.frame(a = c("Year FEs"),
                                              b = c(""),
                                              c = c(""),
                                              d = c("X"),
                                              e = c("X"),
                                              f = c("X")))),"output/ReducedForm/reg_uses_captives_insureryear.tex")

rsqregusescaptivesextensive = round(as.numeric(r2(reg_uses_captives_4)["cor2"]) * 100,0)

data_quantities <- fread("../CleanData/output/SNL_Quantities.csv")
data_quantities = data_quantities[which(data_quantities$lob == "Ordinary Life Insurance"),]

data_quantities <- data_quantities %>% group_by(year) %>% mutate(PremiumsAndAnnuityConsiderations_yeartype = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))
data_quantities <- data_quantities %>% group_by(state,year,PremiumsAndAnnuityConsiderations_yeartype) %>% summarise(PremiumsAndAnnuityConsiderations_stateyeartype = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))

data_quantities$state_share_yeartype <- data_quantities$PremiumsAndAnnuityConsiderations_stateyeartype / data_quantities$PremiumsAndAnnuityConsiderations_yeartype

data_quantities <- data_quantities[which(data_quantities$year == 2019),]
data_quantities <- data_quantities[,c("state","PremiumsAndAnnuityConsiderations_stateyeartype","state_share_yeartype")]
names(data_quantities) <- c("State","Premiums","Share")
data_quantities <- data_quantities[order(-data_quantities$Share),]

data_quantities$Share <- round(data_quantities$Share * 100,digits=1)
data_quantities$Premiums = round(data_quantities$Premiums / 1000,digits=1)

state_size_ny <- data_quantities$Share[which(data_quantities$State == "New York")]
state_size_vt <- data_quantities$Share[which(data_quantities$State == "Vermont")]
state_size_ny_to_vt = state_size_ny / state_size_vt

data_quantities <- data_quantities[which(data_quantities$Share > 0),]

data_quantities <- data_quantities[which(!data_quantities$State %in% c("American Samoa",
                                                                       "Federated States of Micronesia",
                                                                       "Guam",
                                                                       "Marshall Islands",
                                                                       "Northern Mariana Islands",
                                                                       "Palau",
                                                                       "Puerto Rico",
                                                                       "Virgin Islands",
                                                                       "Other Alien",
                                                                       "Canada")),]

stargazer(data_quantities,
          summary = FALSE,
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/summary_stats/state_quantities.tex"))

data_insurer = fread(file="output/CapitalAllocation_insureryear_group.csv")

data_financials_group = fread("../CleanData/output/SNL_Financials_Group.csv")

data_insurer$CEDENTSNLTOPENTITYKEY_year = paste0(data_insurer$CEDENTSNLTOPENTITYKEY,"_",data_insurer$year)
data_financials_group$SNLSTATENTITYKEY_year = paste0(data_financials_group$SNLSTATENTITYKEY,"_",data_financials_group$year)

data_insurer = data_insurer[which(data_insurer$amount_reinsured > 0),]

data_financials_group$uses_captives = as.numeric(data_financials_group$SNLSTATENTITYKEY_year %in% data_insurer$CEDENTSNLTOPENTITYKEY_year)

data_financials_group$TOTALLIAB_x_uses_captives = data_financials_group$TOTALLIAB * data_financials_group$uses_captives
data_financials_group$RESERVESGROSS_x_uses_captives = data_financials_group$RESERVESGROSS * data_financials_group$uses_captives

data_financials_group_usecaptives_2019 = data_financials_group[which((data_financials_group$uses_captives == 1) & (data_financials_group$year == 2019)),]
data_financials_group_1b_2019 = data_financials_group[which((data_financials_group$TOTALLIAB >= 1e6) & (data_financials_group$year == 2019)),]

data_insurer_year_ss = data_insurer %>% group_by(year) %>% summarise(amount_reinsured_yr = sum(amount_reinsured,na.rm=TRUE))

data_year_ss = data_financials_group %>% group_by(year) %>% summarise(num_insurers = n_distinct(SNLSTATENTITYKEY),
                                                                      num_insurers_use_captives = sum(uses_captives,na.rm=TRUE),
                                                                      TOTALLIAB_yr = sum(TOTALLIAB,na.rm=TRUE),
                                                                      TOTALLIAB_uses_captives_yr = sum(TOTALLIAB_x_uses_captives,na.rm=TRUE),
                                                                      RESERVESGROSS_yr = sum(RESERVESGROSS,na.rm=TRUE),
                                                                      RESERVESGROSS_uses_captives_yr = sum(RESERVESGROSS_x_uses_captives,na.rm=TRUE))

data_year_ss$TOTALLIAB_share_uses_captives_yr = round(data_year_ss$TOTALLIAB_uses_captives_yr / data_year_ss$TOTALLIAB_yr,2) * 100

data_year_ss = merge(data_year_ss,data_insurer_year_ss,by=c("year"),all.x=TRUE)

data_year_ss$ceded_frac_liab_yr = data_year_ss$amount_reinsured_yr / data_year_ss$RESERVESGROSS_uses_captives_yr * 1000

stargazer(data_year_ss,
          style="aer",
          omit.table.layout = "n",
          median=TRUE,
          float=FALSE,rownames=FALSE,digits=2, digits.extra=0,
          no.space = TRUE, header = FALSE,
          summary = FALSE,
          out=paste0("output/summary_stats/yearly_num_insurers.tex"))

ggplot(data=data_year_ss[which((data_year_ss$year >= 2004) & (data_year_ss$year <= 2019)),],
       aes(x=year,
           y=num_insurers_use_captives)) +
  geom_line() +
  xlab("Year") + ylab("Number of Insurers Using Captives") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_yearly_num_insurers.png",width=10,height=7,dpi=300)

ggplot(data=data_year_ss[which((data_year_ss$year >= 2004) & (data_year_ss$year <= 2019)),],
       aes(x=year,
           y=TOTALLIAB_share_uses_captives_yr)) +
  geom_line() +
  xlab("Year") + ylab("Market Share of Insurers That Use Captives (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_yearly_TOTALLIAB_share_uses_captives_yr.png",width=10,height=7,dpi=300)

ggplot(data=data_year_ss[which((data_year_ss$year >= 2004) & (data_year_ss$year <= 2019)),],
       aes(x=year,
           y=amount_reinsured_yr/1e3)) +
  geom_line() +
  xlab("Year") + ylab("Reinsurance Amount (Billions USD)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_yearly_ceded_amount.png",width=10,height=7,dpi=300)

ggplot(data=data_year_ss[which((data_year_ss$year >= 2004) & (data_year_ss$year <= 2019)),],
       aes(x=year,
           y=ceded_frac_liab_yr)) +
  geom_line() +
  xlab("Year") + ylab("Share Transferred to Captives (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_ceded_frac_liab.png",width=10,height=7,dpi=300)

data_year_ss_insurer = data_year_ss

data_insurer_all = fread(file="output/CapitalAllocation_insureryear.csv")
data_insurer_all = data_insurer_all[order(data_insurer_all$CEDENTSNLSTATENTITYKEY,data_insurer_all$year),]

data_insurer_all <- data_insurer_all %>%
  group_by(CEDENTSNLSTATENTITYKEY) %>%
  mutate(year_first_used_captives = min(year[amount_reinsured > 0])) %>%
  ungroup()

data_insurer_all$years_after_first_used_captives = data_insurer_all$year - data_insurer_all$year_first_used_captives

data_insurer_all$years_after_first_used_captives_factor <- as.factor(data_insurer_all$years_after_first_used_captives)

numinsurancegroups_usecaptives = data_year_ss$num_insurers_use_captives[which(data_year_ss$year == 2019)]

numinsurancegroups = data_year_ss$num_insurers[which(data_year_ss$year == 2019)]

numinsurancegroups_hundredmilliab = length(unique(data_financials_group$SNLSTATENTITYKEY[which((data_financials_group$TOTALLIAB > 1e5) & (data_financials_group$year == 2019))]))
numinsurancegroups_bn = length(unique(data_financials_group$SNLSTATENTITYKEY[which((data_financials_group$TOTALLIAB > 1e6) & (data_financials_group$year == 2019))]))
usecaptivesmarketsharetotalliab = data_year_ss$TOTALLIAB_share_uses_captives_yr[which(data_year_ss$year == 2019)]

data_defaults <- readxl::read_xlsx(path.symlink("input/NOLHGA_Insolvencies.xlsx"))

data_impairment <- fread(path.symlink("input/SNL_Impairments.csv"))[,c("NAICCOMPANYCODE","Year")]

data_defaults <- data_defaults[,c("NAICCOMPANYCODE","Year")]

data_defaults <- rbind(data_defaults,data_impairment,fill=TRUE)
data_defaults$Defaulted <- 1

data_snl <- fread(path.symlink("input/SNL_Financials.csv"))

data_snl$NAICCOMPANYCODE <- as.numeric(data_snl$NAICCOMPANYCODE)

ratings_all <- fread(path.symlink("input/AMBest_Ratings_All.csv"))

data_naic <- readxl::read_xls(path.symlink("input/SNL_Life_Basic_Information_Company.xls"))

data_ambest_naic <- fread(path.symlink("input/AMBest_ID_NAIC.csv"))
data_ambest_naic$NAICCOMPANYCODE <- data_ambest_naic$naic_co_num

data_snl <- data_snl[which(!is.na(data_snl$NAICCOMPANYCODE)),]
data <- merge(data_snl,
              data_ambest_naic,
              by=c("NAICCOMPANYCODE"),
              all.x=TRUE)

data <- data[which(!is.na(data$amb_co_num)),]
data <- merge(data,
              ratings_all,
              by=c("amb_co_num","year"),
              all.x=TRUE)

data <- merge(data,
              data_defaults,
              by=c("NAICCOMPANYCODE"),
              all.x=TRUE)

data$Defaulted[which(is.na(data$Defaulted))] <- 0

data$defaulted_10_year <- as.numeric((data$Year - data$year <= 10) & (data$Defaulted == 1)) * 100

data$RatingNumeric[which(data$Rating == "NR")] <- NA

data_ss <- data %>% group_by(RatingNumeric) %>% summarise(defaulted_10_year = mean(defaulted_10_year,na.rm=TRUE))

dk_lags = floor(4 * (length(unique(data$year)) / 100 )^(2/9))
reg_default_1 <- feols(defaulted_10_year ~ RatingNumeric, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

reg_default_2 <- feols(defaulted_10_year ~ RatingNumeric + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

reg_default_3 <- feols(defaulted_10_year ~ RatingNumeric + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS | year, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

data$AUTHCONTROLLEVELRISKBASEDCAPRATIO = data$AUTHCONTROLLEVELRISKBASEDCAPRATIO / 100
reg_default_1_rbc_dk <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

reg_default_2_rbc_dk <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

reg_default_3_rbc_dk <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS | year, data=data, DK(dk_lags) ~year, panel.id = ~SNLSTATENTITYKEY + year)

reg_default_1_rbc <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO, data=data, vcov = ~SNLSTATENTITYKEY + year)

reg_default_2_rbc <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS, data=data, vcov = ~SNLSTATENTITYKEY + year)

reg_default_3_rbc <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO + TOTALLIAB_ln + LEVERAGE + CASHSTINVESTTOLIAB + ROAECAPSURPLUS | year, data=data, vcov = ~SNLSTATENTITYKEY + year)

reg_default_4_rbc <- feols(defaulted_10_year ~ AUTHCONTROLLEVELRISKBASEDCAPRATIO | SNLSTATENTITYKEY + year, data=data, vcov = ~SNLSTATENTITYKEY + year)

data$AUTHCONTROLLEVELRISKBASEDCAPRATIO = data$AUTHCONTROLLEVELRISKBASEDCAPRATIO * 100

writeLines(as.character(modelsummary(list("(1)" = reg_default_1,
                             "(2)" = reg_default_2,
                             "(3)" = reg_default_3),
                        fmt = "%.2f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm_default,
                        output="latex_tabular",
                        add_rows = data.frame(a = c("Year FEs"),
                                              b = c(""),
                                              c = c(""),
                                              d = c("X")))),
           "output/ReducedForm/reg_default_prob.tex")

writeLines(as.character(modelsummary(list("(1)" = reg_default_1_rbc,
                             "(2)" = reg_default_2_rbc,
                             "(3)" = reg_default_3_rbc),
                        fmt = "%.2f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm_default,
                        output="latex_tabular",
                        add_rows = data.frame(a = c("Year FEs"),
                                              b = c(""),
                                              c = c(""),
                                              d = c("X")))),
           "output/ReducedForm/reg_default_prob_rbc.tex")

writeLines(as.character(modelsummary(list("(1)" = reg_default_1_rbc_dk,
                             "(2)" = reg_default_2_rbc_dk,
                             "(3)" = reg_default_3_rbc_dk),
                        fmt = "%.2f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm_default,
                        output="latex_tabular",
                        add_rows = data.frame(a = c("Year FEs"),
                                              b = c(""),
                                              c = c(""),
                                              d = c("X")))),
           "output/ReducedForm/reg_default_prob_rbc_dk.tex")

coefdefaultprobratings <- abs(round(summary(reg_default_3_rbc)$coefficients[1],digits=2))
defaultprobmean <- round(mean(data$defaulted_10_year,na.rm=TRUE),digits=2)
rbcmean = median(data$AUTHCONTROLLEVELRISKBASEDCAPRATIO,na.rm=TRUE)
coefdefaultprobratingseffect = round(coefdefaultprobratings * rbcmean,digits=1)
coefdefaultprobratingsmagnitude <- round(coefdefaultprobratingseffect/defaultprobmean,digits=1)

data_states = fread("output/StateYear_joint.csv")
data <- fread("output/CapitalAllocation_insurerstateyear.csv")

data_states = data_states[which(data_states$year == 2002),]

data_states$YearFirstAllowedSPVCaptives[which(data_states$State == "Montana")] = 2011

data_states$YearFirstAllowedSPVCaptives[which(data_states$YearFirstAllowedSPVCaptives > 9000)] = 2025
data_states$YearFirstAllowedSPVCaptives = data_states$YearFirstAllowedSPVCaptives - 2000
ggplot(data=data_states, aes(x=reorder(State,DPW_Life), y=`YearFirstAllowedSPVCaptives`)) +
  geom_bar(stat="identity") +
  xlab("State") + ylab("Year First Allowed") + theme_classic() + theme(text = element_text(size=12)) +
  coord_flip() + theme(axis.text=element_text(size=12),axis.title=element_text(size=12)) + theme(legend.position = c(0.75,0.2))
ggsave("output/ReducedForm/state_entry_timeline.png",width=10,height=7,dpi=300)

data_allowscaptives_ts = data.frame(matrix(nrow=20,ncol=2))
names(data_allowscaptives_ts) = c("Year","NumStates")
for (year in seq(2002,2019,1)){
  data_allowscaptives_ts[year - 2001,1] = year
  data_allowscaptives_ts[year - 2001,2] = sum((data_states$YearFirstAllowedSPVCaptives + 2000) <= year,na.rm=TRUE)
}

data_states$YearFirstAllowedSPVCaptives[which(data_states$YearFirstAllowedSPVCaptives >= 25)] = NA
data_states$YearFirstAllowedSPVCaptives_rank = rank(data_states$YearFirstAllowedSPVCaptives,na.last='keep')
data_states$DPW_Life_rank = rank(data_states$DPW_Life,na.last='keep')

data_states = data_states[order(DPW_Life),]

ggplot(data_states, aes(x=DPW_Life_rank, y=YearFirstAllowedSPVCaptives_rank)) + geom_point() +
  xlab("State Market Size Rank") + ylab("State Adoption of SPFC Captive Laws Rank") +
  geom_smooth(method='lm', formula= y~x, se=FALSE) + geom_text_repel(aes(label=State),size=8) +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/state_entry_scatter.png",width=10,height=7,dpi=300)

data_withcaptives_ts = data[which(data$num_captives > 0),] %>% group_by(year) %>% summarise(num_states = n_distinct(REINSSTATEDOMICILED,na.rm=TRUE))
data_withcaptives_reinsured_ts = data[which(data$num_captives > 0 & data$amount_reinsured > 0),] %>% group_by(year) %>% summarise(num_states = n_distinct(REINSSTATEDOMICILED,na.rm=TRUE))

data_year_ss_insurer2 = data_year_ss_insurer[,c("year","num_insurers_use_captives")]
names(data_year_ss_insurer2) = c("Year","num_insurers_use_captives")
data_allowscaptives_ts2 = merge(data_allowscaptives_ts,data_year_ss_insurer2[which((data_year_ss_insurer2$Year >= 2004) & (data_year_ss_insurer2$Year <= 2019)),],by=c("Year"),all.x=TRUE,all.y=TRUE)

ggplot(data_allowscaptives_ts, aes(x=Year, y=NumStates)) + geom_line() +
  xlab("Year") + ylab("States Allowing Captives") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/state_entry_ts.png",width=10,height=7,dpi=300)
statescountallowcaptives = data_allowscaptives_ts$NumStates[which(data_allowscaptives_ts$Year == 2019)]

data_captives_capital = fread("../CleanData/output/SNL_CaptiveCapitalRates_InsurerStateYear.csv")
data_financials_group = fread("../CleanData/output/SNL_Financials_Group.csv")

data_captives_capital_stateyr = fread("../CleanData/output/SNL_CaptiveCapitalRates_StateYear.csv")

data_captives_reinsurance = fread("../CleanData/output/SNL_Reinsurance_Captives_AgreementLevel.csv")
data_captives_reinsurance = data_captives_reinsurance[which(data_captives_reinsurance$year == 2019 & data_captives_reinsurance$amount_reinsured > 0),]

data_captives_capital = data_captives_capital[which(!is.na(data_captives_capital$capitalsurplus_captive)),]

data_captives_capital = data_captives_capital %>% group_by(CEDENTSNLTOPENTITYKEY,year) %>% summarise(capitalsurplus_captive = sum(capitalsurplus_captive,na.rm=TRUE),
                                                                                                     CapitalSurplus_Adjustment = sum(CapitalSurplus_Adjustment,na.rm=TRUE),
                                                                                                     amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                     A_hat = sum(A_hat,na.rm=TRUE),
                                                                                                     A_hat_N = sum(A_hat_N,na.rm=TRUE),
                                                                                                     L_hat_times_1_plus_rho = sum(L_hat_times_1_plus_rho,na.rm=TRUE))

names(data_financials_group) = mapvalues(names(data_financials_group),
                                         from=c("SNLSTATENTITYKEY"),
                                         to=c("CEDENTSNLTOPENTITYKEY"))

data_captives_capital = merge(data_captives_capital,data_financials_group,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_captives_capital$capitalsurplus_captive = data_captives_capital$capitalsurplus_captive / 1000
data_captives_capital$CapitalSurplus_Adjustment = data_captives_capital$CapitalSurplus_Adjustment / 1000
data_captives_capital$amount_reinsured = data_captives_capital$amount_reinsured / 1000
data_captives_capital$TOTALLIAB = data_captives_capital$TOTALLIAB / 1000000
data_captives_capital$TOTALPOLICYRESVLIFE = data_captives_capital$TOTALPOLICYRESVLIFE / 1000000
data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS = data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS / 1000000

data_captives_capital$TOTALLIAB_with_captives = data_captives_capital$TOTALLIAB + data_captives_capital$amount_reinsured
data_captives_capital$TOTALPOLICYRESVLIFE_with_captives = data_captives_capital$TOTALPOLICYRESVLIFE + data_captives_capital$amount_reinsured
data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS_with_captive = data_captives_capital$capitalsurplus_captive + data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS

data_captives_capital$kappa_rbc = data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS / data_captives_capital$TOTALLIAB
data_captives_capital$rbc_factor = (data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS_with_captive / data_captives_capital$TOTALLIAB_with_captives) / (data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS / data_captives_capital$TOTALLIAB)
data_captives_capital$AUTHCONTROLLEVELRISKBASEDCAPRATIO_with_captives = data_captives_capital$rbc_factor * data_captives_capital$AUTHCONTROLLEVELRISKBASEDCAPRATIO

data_basic_info = fread("../CleanData/output/SNL_Basic_Info.csv")
names(data_basic_info) = c("CEDENTSNLSTATENTITYKEY","SNLGROUPSTATENTITYKEY","STATEINCORP","CEDENTSNLTOPENTITYKEY")

data_financials_company = fread("../CleanData/output/SNL_Financials.csv")
data_financials_company = unique(data_financials_company[,c("SNLSTATENTITYKEY","NAICCOMPANYCODE")])
names(data_financials_company) = c("CEDENTSNLSTATENTITYKEY","NAICCOMPANYCODE")
data_financials_company$NAICCOMPANYCODE = as.numeric(data_financials_company$NAICCOMPANYCODE)

data_ambest_id <- fread(path.symlink("input/AMBest_ID_NAIC.csv"))
names(data_ambest_id) <- c("amb_co_num","NAICCOMPANYCODE")
data_ambest_id <- data_ambest_id[which(!is.na(data_ambest_id$NAICCOMPANYCODE)),]

data_ratings <- fread(path.symlink("input/AMBest_Ratings_All.csv"))
data_ratings = data_ratings[which(data_ratings$RatingNumeric != 0),]

data_snlgroup_snlentity = merge(data_financials_group[which(data_financials_group$CEDENTSNLTOPENTITYKEY %in% data_captives_capital$CEDENTSNLTOPENTITYKEY),],data_basic_info,by=c("CEDENTSNLTOPENTITYKEY"),all.x=TRUE)
data_snlgroup_snlentity_naic = merge(data_snlgroup_snlentity,data_financials_company,by=c("CEDENTSNLSTATENTITYKEY"),all.x=TRUE)
data_snlgroup_snlentity_naic_ambest = merge(data_snlgroup_snlentity_naic,data_ambest_id,by=c("NAICCOMPANYCODE"),all.x=TRUE)

data_snlgroup_snlentity_naic_ambest = unique(data_snlgroup_snlentity_naic_ambest[,c("CEDENTSNLTOPENTITYKEY","year","NAICCOMPANYCODE","amb_co_num")])
data_snlgroup_snlentity_naic_ambest_ratings = merge(data_snlgroup_snlentity_naic_ambest,data_ratings,by=c("amb_co_num","year"),all.x=TRUE)

data_snlgroup_snlentity_naic_ambest_ratings = data_snlgroup_snlentity_naic_ambest_ratings[,c("CEDENTSNLTOPENTITYKEY","year","NAICCOMPANYCODE","amb_co_num","RatingNumeric")]

data_snlgroup_snlentity_naic_ambest_ratings = data_snlgroup_snlentity_naic_ambest_ratings %>% group_by(CEDENTSNLTOPENTITYKEY,year) %>% summarise(RatingNumeric = mean(RatingNumeric,na.rm=TRUE))

data_captives_capital <- merge(data_captives_capital,data_snlgroup_snlentity_naic_ambest_ratings,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_captives_capital$RatingNumeric_with_captives = data_captives_capital$RatingNumeric * data_captives_capital$rbc_factor

data_gaap_ss = fread("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio.csv")
rho = data_gaap_ss$reserve_statutory_gaap_ratio[1] - 1

data_gaap_captives_ss = fread("../CleanData/output/SNL_Reserves_Statutory_GAAP_Ratio_Captives.csv")
rho_captives = data_gaap_captives_ss$XXXAXXXEXEMPTRESVCREDITTAKEN[1] / data_gaap_captives_ss$XXXAXXXEXEMPTECONOMICRESVLEVEL[1] - 1

data_captives_capital$TOTALPOLICYRESVLIFE_economic = data_captives_capital$TOTALPOLICYRESVLIFE / (1 + rho)
data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS_economic = data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS + (rho / (1 + rho)) * data_captives_capital$TOTALPOLICYRESVLIFE_economic
data_captives_capital$amount_reinsured_economic = data_captives_capital$amount_reinsured / (1 + rho_captives)
data_captives_capital$capitalsurplus_captive_economic = data_captives_capital$capitalsurplus_captive + (rho_captives / (1 + rho_captives)) * data_captives_capital$amount_reinsured_economic
data_captives_capital$TOTALPOLICYRESVLIFE_with_captive_economic = data_captives_capital$TOTALPOLICYRESVLIFE_economic + data_captives_capital$amount_reinsured_economic
data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS_with_captive_economic = data_captives_capital$SURPLUSASREGARDSPOLICYHOLDERS_economic + data_captives_capital$capitalsurplus_captive_economic

data_captives_capital_ss = data_captives_capital %>% group_by(year) %>% summarise(capitalsurplus_captive = sum(capitalsurplus_captive,na.rm=TRUE),
                                                                                  capitalsurplus_captive_economic = sum(capitalsurplus_captive_economic,na.rm=TRUE),
                                                                                  CapitalSurplus_Adjustment = sum(CapitalSurplus_Adjustment,na.rm=TRUE),
                                                                                  SURPLUSASREGARDSPOLICYHOLDERS = sum(SURPLUSASREGARDSPOLICYHOLDERS,na.rm=TRUE),
                                                                                  SURPLUSASREGARDSPOLICYHOLDERS_with_captive = sum(SURPLUSASREGARDSPOLICYHOLDERS_with_captive,na.rm=TRUE),
                                                                                  SURPLUSASREGARDSPOLICYHOLDERS_economic = sum(SURPLUSASREGARDSPOLICYHOLDERS_economic,na.rm=TRUE),
                                                                                  SURPLUSASREGARDSPOLICYHOLDERS_with_captive_economic = sum(SURPLUSASREGARDSPOLICYHOLDERS_with_captive_economic,na.rm=TRUE),
                                                                                  TOTALLIAB = sum(TOTALLIAB,na.rm=TRUE),
                                                                                  TOTALLIAB_with_captives = sum(TOTALLIAB_with_captives,na.rm=TRUE),
                                                                                  TOTALPOLICYRESVLIFE = sum(TOTALPOLICYRESVLIFE,na.rm=TRUE),
                                                                                  TOTALPOLICYRESVLIFE_with_captives = sum(TOTALPOLICYRESVLIFE_with_captives,na.rm=TRUE),
                                                                                  TOTALPOLICYRESVLIFE_economic = sum(TOTALPOLICYRESVLIFE_economic,na.rm=TRUE),
                                                                                  TOTALPOLICYRESVLIFE_with_captive_economic = sum(TOTALPOLICYRESVLIFE_with_captive_economic,na.rm=TRUE),
                                                                                  num_insurers = n_distinct(CEDENTSNLTOPENTITYKEY,na.rm=TRUE),
                                                                                  rbc_factor = median(rbc_factor,na.rm=TRUE),
                                                                                  amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                  amount_reinsured_economic = sum(amount_reinsured_economic,na.rm=TRUE),
                                                                                  AUTHCONTROLLEVELRISKBASEDCAPRATIO_with_captives = median(AUTHCONTROLLEVELRISKBASEDCAPRATIO_with_captives,na.rm=TRUE),
                                                                                  AUTHCONTROLLEVELRISKBASEDCAPRATIO = median(AUTHCONTROLLEVELRISKBASEDCAPRATIO,na.rm=TRUE),
                                                                                  RatingNumeric = median(RatingNumeric,na.rm=TRUE),
                                                                                  RatingNumeric_with_captives = median(RatingNumeric_with_captives,na.rm=TRUE),
                                                                                  A_hat = sum(A_hat,na.rm=TRUE),
                                                                                  A_hat_N = sum(A_hat_N,na.rm=TRUE))

data_captives_capital_ss$captive_difference = data_captives_capital_ss$capitalsurplus_captive / data_captives_capital_ss$SURPLUSASREGARDSPOLICYHOLDERS_with_captive

data_captives_capital_ss$A_hat_N_div_A_hat_A = data_captives_capital_ss$A_hat_N / data_captives_capital_ss$A_hat * 100

data_captives_capital_ss_long = melt(data_captives_capital_ss, id.vars=c("year"))

data_captives_capital_ss_long = data_captives_capital_ss_long[which(data_captives_capital_ss_long$variable %in% c("SURPLUSASREGARDSPOLICYHOLDERS","SURPLUSASREGARDSPOLICYHOLDERS_with_captive")),]

data_captives_capital_ss_long$variable = mapvalues(data_captives_capital_ss_long$variable,
                                            from=c("SURPLUSASREGARDSPOLICYHOLDERS_with_captive",
                                                   "SURPLUSASREGARDSPOLICYHOLDERS"),
                                            to=c("With Captives",
                                                 "Reported"))

data_captives_capital_ss_long = data_captives_capital_ss_long[which(data_captives_capital_ss_long$year >= 2017 & data_captives_capital_ss_long$year <= 2020),]

ggplot(data=data_captives_capital_ss_long,
       aes(x=year,
           y=value,
           linetype=variable,
           group=variable)) + labs(linetype="Statutory Capital") +
  geom_line() +
  ylim(0,80) +
  xlab("Year") + ylab("Statutory Capital (Billions USD)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_capital_captives.png",width=10,height=7,dpi=300)

data_captives_capital_ss_long = melt(data_captives_capital_ss, id.vars=c("year"))

data_captives_capital_ss_long = data_captives_capital_ss_long[which(data_captives_capital_ss_long$variable %in% c("RatingNumeric","RatingNumeric_with_captives")),]

data_captives_capital_ss_long$variable = mapvalues(data_captives_capital_ss_long$variable,
                                                   from=c("RatingNumeric_with_captives",
                                                          "RatingNumeric"),
                                                   to=c("With Captives",
                                                        "Reported"))

data_captives_capital_ss_long = data_captives_capital_ss_long[which(data_captives_capital_ss_long$year >= 2017 & data_captives_capital_ss_long$year <= 2020),]

ggplot(data=data_captives_capital_ss_long,
       aes(x=year,
           y=value,
           linetype=variable,
           group=variable)) + labs(linetype="Capital Ratio") +
  geom_line() +
  ylim(0,200) +
  xlab("Year") + ylab("Risk-Based Capital Ratio (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/ReducedForm/ts_capital_captives_rbc.png",width=10,height=7,dpi=300)

capitalratechangewithcaptives = (1 - data_captives_capital_ss_long$value[which(data_captives_capital_ss_long$year == 2019 & data_captives_capital_ss_long$variable == "With Captives")] / data_captives_capital_ss_long$value[which(data_captives_capital_ss_long$year == 2019 & data_captives_capital_ss_long$variable == "Reported")]) * 100

data_captives_capital_ss_out = data_captives_capital_ss[,c("year","SURPLUSASREGARDSPOLICYHOLDERS","capitalsurplus_captive","TOTALLIAB","amount_reinsured","rbc_factor","A_hat_N_div_A_hat_A")]
data_captives_capital_ss_out$rbc_factor = (data_captives_capital_ss_out$rbc_factor - 1) * 100

data_captives_capital_ss_out = dfToNumeric(data_captives_capital_ss_out)

names(data_captives_capital_ss_out) = c("Year","Stat. Capital","Stat. Capital Change","Liabilities","Liabilities Change","RBC Change","Inadmissible Assets")

data_captives_capital_ss_out = round(data_captives_capital_ss_out,digits=0)

data_captives_capital_ss_out = data_captives_capital_ss_out[which(data_captives_capital_ss_out$Year >= 2017 & (data_captives_capital_ss_out$Year <= 2020)),]

stargazer(data_captives_capital_ss_out,
          summary = FALSE,
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,
          digits=1, digits.extra=0,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ReducedForm/ts_capital_captives.tex"))

data_reins_all = fread("../CleanData/output/SNL_Reinsurance_Captives_AgreementLevel.csv")
data_reins_all2 = unique(data_reins_all[which((data_reins_all$amount_reinsured > 0)),c("CEDENTSNLTOPENTITYKEY","year")])

data_reins_all2 = merge(data_reins_all2,data_financials_group,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_reins_all2 = data_reins_all2 %>% group_by(year) %>% summarise(TOTALLIAB = sum(TOTALLIAB,na.rm=TRUE) / (10^9),
                                                                   num_insurers = n_distinct(CEDENTSNLTOPENTITYKEY,na.rm=TRUE))

captive_capitalsurplus_captives_2019 = data_captives_capital_ss$capitalsurplus_captive[which(data_captives_capital_ss$year == 2019)]
captive_capitalsurplus_without_captives_2019 = data_captives_capital_ss$SURPLUSASREGARDSPOLICYHOLDERS[which(data_captives_capital_ss$year == 2019)]
captive_capitalsurplus_with_captives_2019 = data_captives_capital_ss$SURPLUSASREGARDSPOLICYHOLDERS_with_captive[which(data_captives_capital_ss$year == 2019)]
captive_capitalsurplus_change_2019 = (1 - captive_capitalsurplus_with_captives_2019 / captive_capitalsurplus_without_captives_2019) * 100
captive_liabilities_2019 = data_captives_capital_ss$TOTALLIAB[which(data_captives_capital_ss$year == 2019)] / 1000
captive_liabilities_allinsurerswithcaptives_2019 = data_reins_all2$TOTALLIAB[which(data_reins_all2$year == 2019)]
captive_liabilities_frac_allinsurerswithcaptives_2019 = captive_liabilities_2019 / captive_liabilities_allinsurerswithcaptives_2019 * 100
captive_rbc_without_captives_2019 = (data_captives_capital_ss$RatingNumeric[which(data_captives_capital_ss$year == 2019)])
captive_rbc_with_captives_2019 = (data_captives_capital_ss$RatingNumeric_with_captives[which(data_captives_capital_ss$year == 2019)])
captive_rbc_change_2019 = (1 - data_captives_capital_ss$rbc_factor[which(data_captives_capital_ss$year == 2019)]) * 100
captive_assets_change_pct_2019 = data_captives_capital_ss$A_hat_N_div_A_hat_A[which(data_captives_capital_ss$year == 2019)]
captive_assets_change_2019 = data_captives_capital_ss$A_hat_N[which(data_captives_capital_ss$year == 2019)] / (10^6)

data_default_ratings = fread("../raw/AMBest/AMBest_Impairment_Transition_Tables.csv")

captive_rbc_without_captives_2019_ratingnumeric = max(data_ratings$RatingNumeric[which(data_ratings$RatingNumeric < captive_rbc_without_captives_2019)],na.rm=TRUE)
captive_rbc_without_captives_2019_rating = data_ratings$Rating[which(data_ratings$RatingNumeric == captive_rbc_without_captives_2019_ratingnumeric)][1]
captive_default_without_captives_2019 = data_default_ratings$default_prob_10_yr[which(data_default_ratings$Rating == captive_rbc_without_captives_2019_rating)]

captive_rbc_with_captives_2019_ratingnumeric = max(data_ratings$RatingNumeric[which(data_ratings$RatingNumeric < captive_rbc_with_captives_2019)],na.rm=TRUE)
captive_rbc_with_captives_2019_rating = data_ratings$Rating[which(data_ratings$RatingNumeric == captive_rbc_with_captives_2019_ratingnumeric)][1]
captive_default_with_captives_2019 = data_default_ratings$default_prob_10_yr[which(data_default_ratings$Rating == captive_rbc_with_captives_2019_rating)]

taxrates <- fread("../raw/States/CaptiveRegulators.csv")

taxratemean <- round(mean(taxrates$CaptiveTaxRate_ColeMcCullough,na.rm=TRUE),digits=2)

data <- readRDS(path.symlink("input/StateYear.rds"))
taxrates <- merge(taxrates,data,by=c("State"),all.x=TRUE)

taxrates <- taxrates[which(!is.na(taxrates$CaptiveTaxRate_ColeMcCullough) & !is.na(taxrates$Captives_2019)),]
taxratessharesweightedmean <- round(weighted.mean(taxrates$CaptiveTaxRate_ColeMcCullough,taxrates$Captives_2019),digits=2)
taxratemean <- round(mean(taxrates$CaptiveTaxRate_ColeMcCullough,na.rm=TRUE),digits=2)

data_taxrate <- data.frame(taxrate=c(taxratessharesweightedmean,
                                     taxratemean),
                           weight=c("share",
                                    "equal"))
fwrite(data_taxrate,
       file="output/summary_stats/taxrate.csv")

write(paste0("\\newcommand{\\statescount}{",states_count,"} \n",
             "\\newcommand{\\brochuremean}{",brochure_mean,"} \n",
             "\\newcommand{\\brochurecount}{",brochure_count,"} \n",
             "\\newcommand{\\capitalratechangewithcaptives}{",round(capitalratechangewithcaptives),"} \n",
             "\\newcommand{\\kappastatecaptivebsmean}{",abs(round(kappastatecaptivebsmean*100,digits=0)),"} \n",
             "\\newcommand{\\kappastatecaptivebssd}{",abs(round(kappastatecaptivebssd*100,digits=0)),"} \n",
             "\\newcommand{\\kappaeconomicmean}{",abs(round(kappaeconomicmean*100,digits=0)),"} \n",
             "\\newcommand{\\kappaeconomicsd}{",abs(round(kappaeconomicsd*100,digits=0)),"} \n",
             "\\newcommand{\\numinsurersdemand}{",numinsurers_demand,"} \n",
             "\\newcommand{\\capratedemandmean}{",round(caprate_demand_mean,digits=1),"} \n",
             "\\newcommand{\\capratedemandsd}{",round(caprate_demand_sd,digits=1),"} \n",
             "\\newcommand{\\marketingcapreqmean}{",marketing_capreq_mean,"} \n",
             "\\newcommand{\\marketingcapreqcount}{",marketing_capreq_count,"} \n",
             "\\newcommand{\\indvarsd}{",round(indvarsd,digits=1),"} \n",
             "\\newcommand{\\spfcmean}{",spfcmean,"} \n",
             "\\newcommand{\\spfcbetamagnitude}{",spfcbetamagnitude,"} \n",
             "\\newcommand{\\spfcbetamagnituderaw}{",spfcbetamagnituderaw,"} \n",
             "\\newcommand{\\sizebetamagnituderaw}{",sizebetamagnituderaw,"} \n",
             "\\newcommand{\\capratebetamagnituderaw}{",capratebetamagnituderaw,"} \n",
             "\\newcommand{\\numinsurersmultipledomiciles}{",num_insurers_multiple_domiciles,"} \n",
             "\\newcommand{\\numstatesstructural}{",numstatesstructural,"} \n",
             "\\newcommand{\\statesizeny}{",state_size_ny,"} \n",
             "\\newcommand{\\statesizevt}{",state_size_vt,"} \n",
             "\\newcommand{\\statesizenytovt}{",state_size_ny_to_vt,"} \n",
             "\\newcommand{\\coefdefaultprobratings}{",coefdefaultprobratings,"} \n",
             "\\newcommand{\\coefdefaultprobratingseffect}{",coefdefaultprobratingseffect,"} \n",
             "\\newcommand{\\coefdefaultprobratingsmagnitude}{",coefdefaultprobratingsmagnitude,"} \n",
             "\\newcommand{\\rbcmean}{",round(rbcmean,digits=1),"} \n",
             "\\newcommand{\\defaultprobmean}{",defaultprobmean,"} \n",
             "\\newcommand{\\choicebetadepvarmeancapreq}{",choicebetadepvarmeancapreq,"} \n",
             "\\newcommand{\\choicebetamagnitudecapreqkappa}{",choicebetamagnitudecapreqkappa,"} \n",
             "\\newcommand{\\ostertestcapreq}{",ostertestcapreq,"} \n",
             "\\newcommand{\\choicebetadollarcapreq}{",choicebetadollarcapreq,"} \n",
             "\\newcommand{\\captivecapitalsurpluscaptives}{",abs(round(captive_capitalsurplus_captives_2019,digits=0)),"} \n",
             "\\newcommand{\\captivecapitalsurpluswithoutcaptives}{",abs(round(captive_capitalsurplus_without_captives_2019,digits=0)),"} \n",
             "\\newcommand{\\captivecapitalsurpluswithcaptives}{",abs(round(captive_capitalsurplus_with_captives_2019,digits=0)),"} \n",
             "\\newcommand{\\captivecapitalsurpluschange}{",abs(round(captive_capitalsurplus_change_2019,digits=0)),"} \n",
             "\\newcommand{\\captiveliabilities}{",abs(round(captive_liabilities_2019,digits=1)),"} \n",
             "\\newcommand{\\captiveliabilitiesfracallinsurerswithcaptives}{",abs(round(captive_liabilities_frac_allinsurerswithcaptives_2019,digits=0)),"} \n",
             "\\newcommand{\\captiverbcchange}{",abs(round(captive_rbc_change_2019,digits=0)),"} \n",
             "\\newcommand{\\captiverbcwithoutcaptives}{",abs(round(captive_rbc_without_captives_2019,digits=0)),"} \n",
             "\\newcommand{\\captiverbcwithcaptives}{",abs(round(captive_rbc_with_captives_2019,digits=0)),"} \n",
             "\\newcommand{\\captivedefaultwithoutcaptives}{",format(round(captive_default_without_captives_2019*100, digits=1), nsmall = 1),"} \n",
             "\\newcommand{\\captivedefaultwithcaptives}{",abs(round(captive_default_with_captives_2019*100,digits=1)),"} \n",
             "\\newcommand{\\captiveassetschangepct}{",abs(round(captive_assets_change_pct_2019,digits=0)),"} \n",
             "\\newcommand{\\captiveassetschange}{",abs(round(captive_assets_change_2019,digits=1)),"} \n",
             "\\newcommand{\\taxratemean}{",taxratemean,"} \n",
             "\\newcommand{\\taxratessharesweightedmean}{",taxratessharesweightedmean,"} \n",
             "\\newcommand{\\numinsurancegroupsusecaptives}{",numinsurancegroups_usecaptives,"} \n",
             "\\newcommand{\\numinsurancegroups}{",numinsurancegroups,"} \n",
             "\\newcommand{\\numinsurancegroupshundredmilliab}{",numinsurancegroups_hundredmilliab,"} \n",
             "\\newcommand{\\numinsurancegroupsbn}{",numinsurancegroups_bn,"} \n",
             "\\newcommand{\\usecaptivesmarketsharetotalliab}{",usecaptivesmarketsharetotalliab,"} \n",
             "\\newcommand{\\rsqregusescaptivesextensive}{",rsqregusescaptivesextensive,"} \n"),
      file="output/PaperText/PaperText_RegulatoryCompetition_Analysis_Insurer_CapitalAllocation_ReducedForm.tex")

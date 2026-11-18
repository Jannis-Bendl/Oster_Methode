source("../lib/r/Functions.R")

data_financials <- fread("output/SNL_Financials.csv")

data_quantities <- fread("output/SNL_Quantities.csv")

data_quantities$type <- mapvalues(data_quantities$lob,
                                          from=c("Ordinary Individual Annuities","Ordinary Life Insurance"),
                                          to=c("Life Annuity","Life Insurance"))

data_quantities <- data_quantities[which(data_quantities$type %in% c("Life Annuity","Life Insurance")),]

data_quantities_firmyear <- data_quantities[which(data_quantities$type == "Life Insurance"),] %>% group_by(SNLSTATENTITYKEY,year) %>% summarise(PremiumsAndAnnuityConsiderations_firmyear = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))

data_prices <- fread("output/CompuLife_All.csv")

cols_to_delete <- c("Aprice_yq","Aprice2_yq","Gprice","markup2","assets_0","assets_1","bcar0","bestr_0","bs_c_st","cn_rsv","cn_rsv_1","co_name","cp_sur_0","cp_sur_1","dom_st","liquid_0","mkt_code","nt_gn_0","nt_gn_1","rcgain","ret_eq_0","rpt_code","sdiv","so_in_an","so_or_lf","sourcdoc","ucgain","Capital_paid_in","Surplus_paid_in","Unassigned_funds__surplus_","Lassets_0","Gassets","equity_0","equity_1","leverage_0","Annu_ord_def","Msdiv","Rsdiv","Rpaid","Rnetpaid","Rsdiv2","Rpaid2","Rnetpaid2","Rcash","Rcash2","cspread","group")
cols_to_keep <- names(data_prices)[which(!names(data_prices) %in% cols_to_delete)]
data_prices <- data_prices[,..cols_to_keep]

data_ambest_id <- fread("../raw/AMBest/AMBest_ID_NAIC.csv")
names(data_ambest_id) <- c("amb_co_num","NAICCOMPANYCODE")

data_ambest_id <- data_ambest_id[which(!is.na(data_ambest_id$NAICCOMPANYCODE)),]

data_ambest_ratings <- fread("../raw/AMBest/AMBest_Ratings_All.csv")

data_ambest_defaultprobs = fread("output/AMBest_Impairment_Transition_Tables.csv")

data_reinsurance_agreement <- fread("output/SNL_Reinsurance_AgreementLevel.csv")
data_reinsurance = data_reinsurance_agreement

data_reinsurance <- data_reinsurance %>% group_by(CEDENTSNLSTATENTITYKEY,REINSURERISAUTH,is_aff,year) %>% summarise(CEDENTLIFEPREMS = sum(CEDENTLIFEPREMS,na.rm=TRUE),
                                                                                                        CEDENTLIFERESVCREDITTAKEN = sum(CEDENTLIFERESVCREDITTAKEN,na.rm=TRUE),
                                                                                                        CEDENTLIFEMODIFIEDCOINSURANCERESV = sum(CEDENTLIFEMODIFIEDCOINSURANCERESV,na.rm=TRUE),
                                                                                                        amount_reinsured = sum(amount_reinsured,na.rm=TRUE),
                                                                                                        CEDENTLIFEAMTINFORCE = sum(CEDENTLIFEAMTINFORCE,na.rm=TRUE))

data_reinsurance$type <- paste0(data_reinsurance$REINSURERISAUTH,data_reinsurance$is_aff)

data_reinsurance <- dcast(data_reinsurance, CEDENTSNLSTATENTITYKEY + year ~ type, value.var="amount_reinsured")

names(data_reinsurance) <- mapvalues(names(data_reinsurance),
                                     from=c("CEDENTSNLSTATENTITYKEY"),
                                     to=c("SNLSTATENTITYKEY"))

data_reinsurance$year <- as.numeric(data_reinsurance$year)

data_reinsurance <- merge(data_reinsurance,data_quantities_firmyear,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

data_reinsurance$Unaffiliated <- data_reinsurance$Authorized0 + data_reinsurance$Other0 + data_reinsurance$Unauthorized0
data_reinsurance$Affiliated <- data_reinsurance$Authorized1 + data_reinsurance$Other1 + data_reinsurance$Unauthorized1
data_reinsurance$Shadow <- data_reinsurance$Unauthorized1

data_reinsurance$Unaffiliated_premiums_frac <- data_reinsurance$Unaffiliated / data_reinsurance$PremiumsAndAnnuityConsiderations_firmyear
data_reinsurance$Affiliated_premiums_frac <- data_reinsurance$Affiliated / data_reinsurance$PremiumsAndAnnuityConsiderations_firmyear
data_reinsurance$Shadow_premiums_frac <- data_reinsurance$Shadow / data_reinsurance$PremiumsAndAnnuityConsiderations_firmyear

data_reinsurance$Shadow_uses <- as.numeric(data_reinsurance$Shadow > 0)

data_reinsurance_agreement <- fread("output/SNL_Reinsurance_AgreementLevel.csv")
data_reinsurance_agreement = data_reinsurance_agreement[which((data_reinsurance_agreement$is_captive_alt == 1)),]

data_reinsurance_captive = data_reinsurance_agreement %>% group_by(CEDENTSNLSTATENTITYKEY,year) %>% summarise(Captive_uses = n(),
                                                                                                              amount_reinsured = sum(amount_reinsured,na.rm = TRUE))
data_reinsurance_captive$Captive_uses = as.numeric(data_reinsurance_captive$Captive_uses > 0)
data_reinsurance_captive$Captive_uses_intensive = as.numeric(data_reinsurance_captive$amount_reinsured > 0)

names(data_reinsurance_captive) <- mapvalues(names(data_reinsurance_captive),
                                     from=c("CEDENTSNLSTATENTITYKEY"),
                                     to=c("SNLSTATENTITYKEY"))

data_reinsurance_captive$year <- as.numeric(data_reinsurance_captive$year)

nobs = nrow(data_reinsurance)
data_reinsurance <- merge(data_reinsurance,data_reinsurance_captive,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)
if (nobs != nrow(data_reinsurance)){
  stop("FAILED DUPLICATES Merge in total premiums written as denominator")
}

types_all <- data.table(type=unique(data_prices$type))
types_all$i <- 1

states_all <- data.table(state=sort(unique(data_quantities$state)))
states_all$i <- 1

naic_co_num_all <- data.table(NAICCOMPANYCODE=as.numeric(sort(unique(data_financials$NAICCOMPANYCODE))))
naic_co_num_all$i <- 1
naic_co_num_all <- naic_co_num_all[which(!is.na(naic_co_num_all$NAICCOMPANYCODE)),]

years_all <- data.table(year=sort(unique(data_prices$year)))
years_all$i <- 1

data_all <- merge(types_all,states_all,all.x=TRUE,all.y=TRUE,allow.cartesian = TRUE,by="i")
data_all <- merge(data_all,naic_co_num_all,allow.cartesian = TRUE,by="i")
data_all <- merge(data_all,years_all,allow.cartesian = TRUE,by="i")

data_snl <- merge(data_financials,data_quantities,by=c("ENTITYNAME","SNLSTATENTITYKEY","year"),all.x=TRUE,all.y=TRUE)
data_snl$NAICCOMPANYCODE <- as.numeric(data_snl$NAICCOMPANYCODE)

data_all <- merge(data_all,data_snl,by=c("NAICCOMPANYCODE","year","type","state"),all.x=TRUE)

data_all <- merge(data_all,data_ambest_id,by=c("NAICCOMPANYCODE"),all.x=TRUE,allow.cartesian = TRUE)

data_all <- data_all[!is.na(data_all$amb_co_num),]

data_all <- merge(data_all,data_prices,by=c("amb_co_num","year","type"),all.x=TRUE)

data_all <- merge(data_all,data_ambest_ratings,by=c("amb_co_num","year"),all.x=TRUE)

data_all = merge(data_all,data_ambest_defaultprobs,by=c("Rating"),all.x=TRUE)

data_all <- merge(data_all,data_reinsurance,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

getMarketShares <- function(data_all) {
  data_all$price_v <- data_all$price
  data_all$price <- data_all$price_dollars

  data_all$PremiumsAndAnnuityConsiderations[which(data_all$PremiumsAndAnnuityConsiderations < 0)] <- NA
  data_all$quantities <- data_all$PremiumsAndAnnuityConsiderations / data_all$price
  data_all <- data_all %>% group_by(state,year,type) %>% mutate(quantities_stateyeartype = sum(quantities,na.rm=TRUE))
  data_all <- as.data.table(data_all)

  data_all <- data_all %>% group_by(state,year,type) %>% mutate(price_avg_stateyeartype = mean(price,na.rm=TRUE))
  data_all$price_filled <- NA
  data_all$price_filled[which(is.na(data_all$price))] <- data_all$price_avg_stateyeartype[which(is.na(data_all$price))]

  data_all$quantities_filled <- data_all$PremiumsAndAnnuityConsiderations / data_all$price_filled

  if (sum(!is.na(data_all$quantities_filled) & !is.na(data_all$quantities)) != 0){
    stop("FAILED Check: no overlap between filled and not filled quantities")
  }

  data_all$SNLSTATENTITYKEY_noprice <- NA
  data_all$SNLSTATENTITYKEY_noprice[which(!is.na(data_all$price_filled))] <- data_all$SNLSTATENTITYKEY[which(!is.na(data_all$price_filled))]

  data_all <- data_all %>% group_by(state,year,type) %>% mutate(quantities_outsidegood = sum(quantities_filled,na.rm=TRUE),
                                                                num_insurers_outsidegood = n_distinct(SNLSTATENTITYKEY_noprice,na.rm=TRUE))

  data_all <- as.data.table(data_all)
  data_all <- data_all[,SNLSTATENTITYKEY_noprice:=NULL]

  data_all$share <- data_all$quantities / (data_all$quantities_stateyeartype + data_all$quantities_outsidegood)

  data_all$price <- data_all$price_v

  return(data_all)
}

data_all <- getMarketShares(data_all)

data_all$Unaffiliated_liab_frac <- data_all$Unaffiliated / data_all$TOTALLIAB
data_all$Affiliated_liab_frac <- data_all$Affiliated / data_all$TOTALLIAB
data_all$Shadow_liab_frac <- data_all$Shadow / data_all$TOTALLIAB

data_all$state_year_type <- paste0(data_all$state,data_all$year,data_all$type)

data_all <- as.data.table(data_all)

data_all$V <- median(data_all$V,na.rm=TRUE)

data_all$quantities2 <- mapvalues(data_all$quantities,
                                 from=c(NA),
                                 to=c(0))
data_all$quantities_filled2 <- mapvalues(data_all$quantities_filled,
                                        from=c(NA),
                                        to=c(0))
data_all$quantities_all <- data_all$quantities2 + data_all$quantities_filled2
data_all$quantities_v <- data_all$quantities_all * data_all$V

data_all <- data_all[,quantities2:=NULL]
data_all <- data_all[,quantities_filled2:=NULL]

data_snl <- merge(data_snl,data_ambest_id[which(!duplicated(data_ambest_id$NAICCOMPANYCODE)),],by=c("NAICCOMPANYCODE"),all.x=TRUE)

fwrite(data_snl,file="output/SNL_All.csv")
fwrite(data_all,file="output/Demand_All.csv")

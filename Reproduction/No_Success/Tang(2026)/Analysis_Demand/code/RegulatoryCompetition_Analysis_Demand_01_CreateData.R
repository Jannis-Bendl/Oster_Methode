### Global
source("../lib/r/Functions.R")

##### Function to Load Demand Data
loadDemandData <- function(data){
  names(data) <- mapvalues(names(data),
                           from=c("TOTALASSETS"),
                           to=c("assets_0"))
  data <- data[which(!(is.na(data$quantities) & is.na(data$quantities_filled))),]
  
  data <- data %>% group_by(year,amb_co_num,state) %>% mutate(dups = n())
  data <- as.data.table(data)
  data <- data[which(data$dups == 1),]
  data <- data[,dups:=NULL]
  data$amb_co_num_year <- paste0(data$amb_co_num,"_",data$year)
  data <- data %>% group_by(state,year) %>% mutate(shares_total = sum(share,na.rm = TRUE))
  
  data <- as.data.table(data)[order(state,year),]
  
  data_stateyr_ss <- data %>% group_by(state,year,type) %>% summarise(shares_total_nonoutsidegood = sum(share,na.rm=TRUE),
                                                                 quantities_total_nonoutsidegood = sum(quantities,na.rm=TRUE),
                                                                 num_insurers_nonoutsidegood = length(unique(SNLSTATENTITYKEY[!is.na(quantities)])),
                                                                 quantities_total_outsidegood = mean(quantities_outsidegood,na.rm=TRUE),
                                                                 num_insurers_outsidegood = mean(num_insurers_outsidegood,na.rm=TRUE))
  
  data$shares_0 = 1 - data$shares_total
  data$shares_ln = log(data$share)
  data$shares_0_ln = log(data$shares_0)
  data$shares_ln_minus_shares_0 = data$shares_ln - data$shares_0_ln
  data$TOTALLIAB_ln_std <- as.vector(scale(data$TOTALLIAB_ln))
  data$CASHSTINVESTTOLIAB_std <- as.vector(scale(data$CASHSTINVESTTOLIAB))
  data$ROAECAPSURPLUS_std <- as.vector(scale(data$ROAECAPSURPLUS))
  data$RatingNumeric_std <- as.vector(scale(data$RatingNumeric))
  data$Shadow_uses_std <- as.vector(scale(data$Shadow_uses))
  data$LEVERAGE_std <- as.vector(scale(data$LEVERAGE))
  data$AUTHCONTROLLEVELRISKBASEDCAPRATIO_std <- as.vector(scale(data$AUTHCONTROLLEVELRISKBASEDCAPRATIO))
  vars_char <- names(data)[which(grepl("_std$",names(data)))]
  data <- as.data.frame(data)
  for (vars_this in vars_char){
    vars_this_sq <- paste0(vars_this,"_sq")
    data[,vars_this_sq] = data[,vars_this] ^ 2
  }
  
  data <- as.data.table(data)
  cols_to_keep <- names(data)[which(!grepl("Guarantee(.*)ale80Life|Guarantee(.*)ale85Life|Guarantee(.*)ale90Life",names(data)))]
  data <- data[,..cols_to_keep]
  
  return(data)
}

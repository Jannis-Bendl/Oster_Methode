source("../lib/r/Functions.R")

data_pop <- readxl::read_xls("../raw/Other/FRED_StatePopulation.xls",sheet="Annual")

data_pop <- melt(data_pop,
                 id.vars=c("DATE"))

names(data_pop) <- c("year","State_2","pop")

data_pop$year <- year(as.Date(data_pop$year))

data_pop$State_2 <- gsub("POP","",data_pop$State_2)

state_names <- fread("../raw/States/StateNames.csv")
names(state_names) <- c("State","State_2")

data_pop <- merge(data_pop,state_names,by=c("State_2"),all.x=TRUE)

data_lawyers <- fread("../raw/Other/ABA_Lawyers.csv",header = TRUE)

data_lawyers <- melt(data_lawyers,
                     id.vars=c("State_2"))

names(data_lawyers) <- c("State_2","year","lawyers")

data_lawyers$lawyers <- as.numeric(gsub(",","",data_lawyers$lawyers))

data_tourists <- fread("../raw/Other/BTS_Tourism.csv",header=TRUE)

data_tourists <- data_tourists[,c("State","1999")]

names(data_tourists) <- c("State","tourists")

data_tourists$tourists = data_tourists$tourists / (10^3)

data_disclosure <- readxl::read_xlsx("../raw/Other/GoodJobsFirst_StateDisclosure.xlsx")

data_employees <- readxl::read_xlsx("../raw/NAIC/IDRR/IDRR_CaptiveStaff.xlsx",sheet = "Sheet2")

data_employees[,2:ncol(data_employees)] <- dfToNumeric(data_employees[,2:ncol(data_employees)])

data_employees <- melt(data_employees, id.vars=c("State"))

data_employees$year <- gsub("[^0-9]",'',data_employees$variable)

data_employees$variable <- gsub('[^A-Za-z]','',data_employees$variable)

data_employees <- dcast(data_employees, State + year ~ variable, value.var = 'value')

data_idrr = fread("../raw/NAIC/IDRR/IDRR_All.csv")

names(data_idrr) = mapvalues(names(data_idrr),
                             from=c("Year"),
                             to=c("year"))

data_idrr_consumers = readxl::read_xlsx("../raw/NAIC/IDRR/Consumers.xlsx")

names(data_idrr_consumers) <- gsub("[^a-zA-Z0-9]", "", names(data_idrr_consumers))

columns_to_convert <- c(
  "AvailabilityofConsumerInformationLife",
  "AggregatedComplaintDataAvailabletoPublic",
  "SeparateCriminalInsFraudUnit",
  "InvestigatorsHavePeaceAuthority",
  "LimitationsonTypesofInsFraudInvestigated",
  "CompanyLicensingInfo",
  "ProducerLicensingInfo",
  "ConsumerComplaintStatistics",
  "OnlineComplaintSubmission"
)

data_idrr_consumers <- data_idrr_consumers %>%
  mutate(across(all_of(columns_to_convert), ~ case_when(
    . == "Yes" ~ 1,
    . == "No" ~ -1,
    TRUE ~ 0
  )))

data_idrr_consumers <- data_idrr_consumers %>%
  mutate(
    ConsumerScore =
      AvailabilityofConsumerInformationLife +
      AggregatedComplaintDataAvailabletoPublic +
      SeparateCriminalInsFraudUnit +
      InvestigatorsHavePeaceAuthority +
      CompanyLicensingInfo +
      ProducerLicensingInfo +
      ConsumerComplaintStatistics +
      OnlineComplaintSubmission -
      LimitationsonTypesofInsFraudInvestigated
  )

data_idrr_consumers$ConsumerComplaints = as.numeric(gsub(",","",data_idrr_consumers$ConsumerComplaints))
data_idrr_consumers$ConsumerInquiries = as.numeric(gsub(",","",data_idrr_consumers$ConsumerInquiries))

data_business <- fread("../raw/Other/BFS_Businesses.csv")

data_business <- data_business[which(data_business$sa == "A" & data_business$series == "BA_BA"),]

data_business$newbusinesses <- as.numeric(data_business$Q1) + as.numeric(data_business$Q2) + as.numeric(data_business$Q3) + as.numeric(data_business$Q4)

names(data_business) <- mapvalues(names(data_business),
                                  from=c("geo"),
                                  to=c("State_2"))

data_business <- data_business[,c("State_2","year","newbusinesses")]

data_subsidiaries <- fread("../raw/WRDS/10K_Subsidiaries.csv",select=c("fdate","location"))

data_subsidiaries$year <- round(data_subsidiaries$fdate/10000,digits=0)
data_subsidiaries$newbusinesses_subsidiaries = 1

data_subsidiaries <- data_subsidiaries %>% group_by(year,location) %>% summarise(newbusinesses_subsidiaries = sum(newbusinesses_subsidiaries,na.rm=TRUE))

data_subsidiaries$State = data_subsidiaries$location

state_names <- fread("../raw/States/StateNames.csv")
names(state_names) <- c("State","State_2")

data_subsidiaries = merge(data_subsidiaries,state_names,by=c("State"),all.x=TRUE)

data_subsidiaries <- data_subsidiaries[which(!is.na(data_subsidiaries$State_2)),]

data_subsidiaries <- data_subsidiaries[,c("State_2","year","newbusinesses_subsidiaries")]

data_subsidiaries <- data_subsidiaries[!duplicated(data_subsidiaries[,c("State_2","year")]),]

data_commissioner <- fread("../raw/NAIC/IDRR/IDRR_Commissioners.csv")
data_commissioner$Commissioner_Appointed <- as.numeric(data_commissioner$Commissioner_Appointment == "Appointed")

president_data <- fread("../raw/Other/Votes/dataverse_files/1976-2020-president.csv")

president_data_2 <- president_data %>% filter((president_data$party_simplified == "REPUBLICAN"|president_data$party_simplified == "DEMOCRAT"))

new_data <- president_data_2 %>% group_by(state,year,party_simplified) %>% summarise(individualvotes = sum(candidatevotes))
total_vote <- president_data_2 %>% group_by(state,year) %>% summarise(totalvotes = sum(candidatevotes))
output <- inner_join(new_data,total_vote)
output$republicanShare <- ifelse(output$party_simplified == "REPUBLICAN",output$individualvotes/output$totalvotes,NA)
output <- output[complete.cases(output),-c(3,4,5)]

data_votes = output
names(data_votes) = c("State_upper","year","vote_share_r")

corruption <- fread("../raw/Other/corruption/year.state.corruption.pop.csv")
names(corruption)[which(names(corruption) == "state")] <- "State"

corruption$population <- as.numeric(gsub(",","",corruption$population))
corruption$corruption_by_pop <- corruption$corruption / corruption$population * 100000

corruption = as.data.frame(corruption)

data_financejobs = fread("../raw/Other/QCEW/QCEW.csv")

data_financejobs = data_financejobs[which(grepl("q4",data_financejobs$quarterly)),]

data_financejobs$quarterly = gsub("q4","",data_financejobs$quarterly)

names(data_financejobs) = mapvalues(names(data_financejobs),
                                    from=c("month3_emplvl","total_qtrly_wages","area_title","quarterly"),
                                    to=c("finance_employees","finance_employees_wages","State","year"))

data_financejobs = dcast.data.table(setDT(data_financejobs)[,c("finance_employees","finance_employees_wages","State","year","industry_code")],
                                    State + year ~ industry_code, value.var = c("finance_employees","finance_employees_wages"))

data_financejobs$State = gsub(" -- Statewide","",data_financejobs$State)

data_specialrevenuefunds = fread("../raw/States/SpecialRevenueFunds/SpecialRevenueFunds.csv")

data_specialrevenuefunds$SpecialRevenueFund_pct_total = data_specialrevenuefunds$OtherStateFund_2020 / data_specialrevenuefunds$Total_2020
data_specialrevenuefunds$SpecialRevenueFund_pct_total_ex_bonds = data_specialrevenuefunds$OtherStateFund_2020 / (data_specialrevenuefunds$Total_2020 - data_specialrevenuefunds$Bonds_2020)
data_specialrevenuefunds$SpecialRevenueFund_pct_state = data_specialrevenuefunds$OtherStateFund_2020 / (data_specialrevenuefunds$GeneralFund_2020 + data_specialrevenuefunds$OtherStateFund_2020)

data_specialrevenuefunds = data_specialrevenuefunds[,c("State","SpecialRevenueFund_pct_total","SpecialRevenueFund_pct_total_ex_bonds","SpecialRevenueFund_pct_state")]

data_donations_stateyr = fread("../raw/DIME/DIME_StateYear.csv")

data_donations_stateyr = data_donations_stateyr[,x:=NULL]

names(data_donations_stateyr) = mapvalues(names(data_donations_stateyr),
                                          from=c("recipientstate","amount_previous_stateyr","amount_previous4_stateyr","amount_total_stateyr"),
                                          to=c("State_2","donations_previous_stateyr","donations_previous4_stateyr","donations_total_stateyr"))

data_other <- merge(data_pop,
                    data_lawyers,
                    by=c("State_2","year"),
                    all.x=TRUE,all.y=TRUE)

data_other <- merge(data_other,
                    data_tourists,
                    by=c("State"),
                    all.x=TRUE,all.y=TRUE)

data_other <- merge(data_other,
                    data_disclosure,
                    by=c("State"),
                    all.x=TRUE,all.y=TRUE)

data_other <- merge(data_other,
                    data_business,
                    by=c("State_2",'year'),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_subsidiaries,
                    by=c("State_2",'year'),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_employees,
                    by=c("State",'year'),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_idrr,
                    by=c("State",'year'),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_idrr_consumers,
                    by=c("State"),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_commissioner,
                    by=c("State"),
                    all.x=TRUE)

data_other <- merge(data_other,
                    corruption,
                    by=c("State","year"),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_financejobs,
                    by=c("State","year"),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_specialrevenuefunds,
                    by=c("State"),
                    all.x=TRUE)

data_other$State_upper <- toupper(data_other$State)
data_other <- merge(data_other,
                    data_votes,
                    by=c("State_upper","year"),
                    all.x=TRUE)

data_other <- merge(data_other,
                    data_donations_stateyr,
                    by=c("State_2","year"),
                    all.x=TRUE)

data_other <- as.data.table(data_other)[order(State,year),]

data_other <- data_other %>% group_by(State) %>% fill(lawyers, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(newbusinesses, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(newbusinesses_subsidiaries, .direction="downup")

data_other <- data_other %>% group_by(State) %>% fill(vote_share_r, .direction="downup")

data_other <- data_other %>% group_by(State) %>% fill(finance_employees_52, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(finance_employees_5241, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(finance_employees_5242, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(finance_employees_wages_52, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(finance_employees_wages_5241, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(finance_employees_wages_5242, .direction="downup")

data_other <- data_other %>% group_by(State) %>% fill(donations_previous4_stateyr, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(donations_previous_stateyr, .direction="downup")
data_other <- data_other %>% group_by(State) %>% fill(donations_total_stateyr, .direction="downup")

data_other <- as.data.table(data_other)[,State_upper:=NULL]

fwrite(data_other,file="output/Other_All.csv")

data_states <- fread("../raw/States/CaptiveRegulators.csv")

data_gaap <- fread("output/SNL_Reserves_Statutory_GAAP_Ratio.csv")
reserve_statutory_gaap_ratio <- data_gaap$reserve_statutory_gaap_ratio[1]

data_states$CapitalSurplus_GAAP <- data_states$CapitalSurplus
data_states$CapitalSurplus <- data_states$CapitalSurplus / reserve_statutory_gaap_ratio

fwrite(data_states,file="output/CaptiveRegulators.csv")

data_names = readxl::read_xls("../raw/SNL/SNL_NonLife_Basic_Information_Company.xls")

data_names = data_names[,c(1,2)]
names(data_names) = c("ENTITYNAME","SNLSTATENTITYKEY")
data_names = data_names[which(!is.na(data_names$ENTITYNAME) & !is.na(data_names$SNLSTATENTITYKEY)),]

fwrite(data_names,file="../raw/DIME/SNL_NonLife_Basic_Information_Company.csv")

data_nolhga_sheets = readxl::excel_sheets("../raw/NAIC/NOLHGA_insolvdata21.xlsx")

data_nolhga_all = list()
i = 1
for (sheet_this in data_nolhga_sheets[1:91]){
  data_nolhga = readxl::read_xlsx("../raw/NAIC/NOLHGA_insolvdata21.xlsx",sheet=sheet_this)
  GAexpensesincurreddirectly = data_nolhga$...10[13]
  NOLHGAexpenses = data_nolhga$...10[14]
  AdjustedGACosts = data_nolhga$...10[25]

  data_nolhga_this = data.frame(GAexpensesincurreddirectly = GAexpensesincurreddirectly,
                                NOLHGAexpenses = NOLHGAexpenses,
                                AdjustedGACosts = AdjustedGACosts)
  data_nolhga_all[[i]] = data_nolhga_this
  i = i+1
}
data_nolhga_all2 = do.call(rbind,data_nolhga_all)

data_nolhga_all2_median = data_nolhga_all2
data_nolhga_all2_median$eta = (data_nolhga_all2_median$GAexpensesincurreddirectly + data_nolhga_all2_median$NOLHGAexpenses) / data_nolhga_all2_median$AdjustedGACosts * 0.25
data_nolhga_all2_median = data_nolhga_all2_median %>% summarise(eta_median = median(eta,na.rm=TRUE),
                                                                eta_mean = mean(eta,na.rm=TRUE))

data_nolhga_all2 = data_nolhga_all2 %>% summarise(GAexpensesincurreddirectly = sum(GAexpensesincurreddirectly,na.rm=TRUE),
                                                  NOLHGAexpenses = sum(NOLHGAexpenses,na.rm=TRUE),
                                                  AdjustedGACosts = sum(AdjustedGACosts,na.rm=TRUE),)
data_nolhga_all2$eta = (data_nolhga_all2$GAexpensesincurreddirectly + data_nolhga_all2$NOLHGAexpenses) / data_nolhga_all2$AdjustedGACosts * 0.25

fwrite(data_nolhga_all2,file="output/NAIC_eta.csv")

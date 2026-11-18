source("../lib/r/Functions.R")
data = fread(get_filename_case("output/Pricing/companyyear_withprimitives_withky.csv",case))

data = data[which(data$year >= 2013),]

data$RESERVESGROSS = data$RESERVESGROSS / (10^6)
data$TOTALLIAB_amt = data$TOTALLIAB / (10^6)
data$TOTALASSETS = data$TOTALASSETS / (10^6)
data$default_prob_ambest = data$default_prob_ambest * 100

ss_var = c("TOTALASSETS",
           "TOTALLIAB_amt",
           "RatingNumeric" ,
           "AUTHCONTROLLEVELRISKBASEDCAPRATIO",
           "CASHSTINVESTTOLIAB",
           "ROAECAPSURPLUS",
           "LEVERAGE",
           "NAICOWNSTRUCTURE",
           "RESERVESGROSS",
           "price",
           "default_prob_ambest",
           "ceded_frac_liab_KY",
           "kappa")
ss_var_labels = c(cm[which(names(cm) %in% ss_var)],
                  "ceded_frac_liab_KY" = "Captive Share",
                  "kappa" = "Capital Rate",
                  "default_prob_ambest" = "P(Default)")
ss_var_labels = ss_var_labels[ss_var]

st(data[,..ss_var],
   out="latex",
   labels = ss_var_labels,
   digits=2,
   summ = list(c('nrow(data)','mean(x)','sd(x)','quantile(x,probs=0.1)','quantile(x,probs=0.25)','quantile(x,probs=0.5)','quantile(x,probs=0.75)','quantile(x,probs=0.9)')),
   summ.names = list(c('N','Mean','SD','P10','P25','Median','P75','P90')),
   file=get_filename_case(paste0("output/summary_stats/summary_stats_financials.tex"),case))
assetsavgstructural = round(mean(data$TOTALASSETS,na.rm=TRUE),0)
caprateavgstructural = round(mean(data$kappa,na.rm=TRUE)*100,0)
defaultprobavgstructural = round(mean(data$default_prob_ambest,na.rm=TRUE),1)
sharetransferredavgstructural = round(mean(data$ceded_frac_liab_KY,na.rm=TRUE)*100,0)

numinsurersstructural = length(unique(data$SNLSTATENTITYKEY))
totalliabstructural = sum(data$TOTALLIAB[which(data$year == 2019)],na.rm=TRUE) / (10^9)
numinsurersusecaptivesstructural = length(unique(data$SNLSTATENTITYKEY[which(data$ceded_frac_liab_KY > 0)]))

data_snl = fread('../CleanData/output/SNL_Financials.csv')
totalliabmarket = sum(data_snl$TOTALLIAB[which(data_snl$year == 2019)],na.rm=TRUE) / (10^9)
marketshareinsamplebyliab = round((totalliabstructural / totalliabmarket) * 100)

data <- fread(get_filename_case("../raw/AMBest/AMBest_Impairment_Transition_Tables.csv",case))

ratings_scale <- fread(get_filename_case("../raw/AMBest/AMBest_Ratings_Scale.csv",case))

ratings_all <- fread(get_filename_case(path.symlink("input/AMBest_Ratings_All.csv"),case))

data <- merge(data,ratings_scale,by=c("Rating"),all.x=TRUE)

ratings_all2 <- ratings_all

ratings_all$Rating <- mapvalues(ratings_all$Rating,
                                from=c("C++","C+","C","C-","D","E","F"),
                                to=c("C++ or below","C++ or below","C++ or below","C++ or below","C++ or below","C++ or below","C++ or below"))
ratings_all$RatingNumeric <- mapvalues(ratings_all$RatingNumeric,
                                       from=c(0,10,20,30,40,50,60,70),
                                       to=c(70,70,70,70,70,70,70,70))

ratings_all$Rating_ordered <- factor(ratings_all$Rating, levels=unique(ratings_all$Rating[order(ratings_all$RatingNumeric)]), ordered=TRUE)
data$Rating_ordered <- factor(data$Rating, levels=unique(data$Rating[order(data$RatingNumeric)]), ordered=TRUE)


data$default_prob_10_yr = data$default_prob_10_yr * 100

ggplot(data, aes(x=RatingNumeric, y=default_prob_10_yr)) + geom_point() +
  geom_smooth(color='black', method='lm', formula= y~x, se=FALSE) +
  xlab("A.M. Best Capital Ratio (%)") + ylab("10-Year Default Probability (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave("output/summary_stats/default_prob_ratings_numeric.png",width=10,height=7,dpi=300)
ggplot(data, aes(x=Rating_ordered, y=default_prob_10_yr)) + geom_point() +
  xlab("A.M. Best Rating") + ylab("10-Year Default Probability (%)") +
  theme_classic() + theme(text = element_text(size=20))
ggsave(get_filename_case("output/summary_stats/default_prob_ratings.png",case),width=10,height=7,dpi=300)

ratings_all <- ratings_all[which(ratings_all$Rating != "NR"),]
ratings_all_ss <- ratings_all %>% group_by(year,Rating_ordered) %>% summarise(num = n())

ratings_all_ss <- ratings_all_ss %>% group_by(year) %>% mutate(num_yr = sum(num,na.rm=TRUE))

ratings_all_ss$fraction <- ratings_all_ss$num / ratings_all_ss$num_yr

ratings_all_ss$fraction <- round(ratings_all_ss$fraction * 100,digits=2)

ratings_all_ss_all <- ratings_all %>% group_by(Rating_ordered) %>% summarise(num = n())
ratings_all_ss_all$num_all <- sum(ratings_all_ss_all$num,na.rm=TRUE)
ratings_all_ss_all$fraction <- ratings_all_ss_all$num / ratings_all_ss_all$num_all

ratings_all_ss_all$fraction <- round(ratings_all_ss_all$fraction * 100,digits=2)

ratings_all_ss_2009 <- ratings_all_ss[which(ratings_all_ss$year == 2009),]
ratings_all_ss_2019 <- ratings_all_ss[which(ratings_all_ss$year == 2019),]

ratings_wide <- Reduce(function(dtf1, dtf2) merge(dtf1, dtf2, by = "Rating_ordered", all.x = TRUE),
       list(ratings_all_ss_all,
            ratings_all_ss_2009,
            ratings_all_ss_2019))

ratings_wide <- ratings_wide[,c("Rating_ordered","fraction.x","fraction.y","fraction")]
names(ratings_wide) <- c("Rating","All","2009","2019")
ratings_wide <- ratings_wide[order(ratings_wide$Rating,decreasing=TRUE),]

stargazer(ratings_wide,
          summary = FALSE,
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=get_filename_case(paste0("output/summary_stats/default_prob_ratings.tex"),case))

ratings_all2 <- merge(ratings_all2,data,by=c("Rating"),all.x=TRUE)

defaultprobmeanfullsample <- round(mean(ratings_all2$default_prob_10_yr,na.rm=TRUE),digits=1)
data <- fread("../raw/States/CaptiveRegulators.csv")
data <- data[,c("State","CaptiveTaxRate_ColeMcCullough")]

## tau: Captive Tax Rate: share-weighted average across states
taxrates <- fread("output/summary_stats/taxrate.csv")
tau = taxrates$taxrate[which(taxrates$weight == "share")]

data = fread(get_filename_case(path.symlink("input/Demand_All.csv"),case))
data$quantities_thousands = data$quantities / 1000
data$share_pct = data$share * 100
data = data[which(data$quantities > 0),]
data_stateyr = data %>% group_by(state,year) %>% summarise(quantities_thousands = sum(quantities_thousands,na.rm=TRUE),
                                                           num_insurers = n_distinct(amb_co_num),
                                                           quantities_outsidegood = median(quantities_outsidegood,na.rm=TRUE),
                                                           num_insurers_outsidegood = median(num_insurers_outsidegood,na.rm=TRUE))
st(as.data.table(data_stateyr)[,c("quantities_thousands","num_insurers")],
   out="latex",
   labels = c("Quantities","Num. Insurers"),
   digits=2,
   summ = list(c('notNA(x)','mean(x)','sd(x)','quantile(x,probs=0.1)','quantile(x,probs=0.25)','quantile(x,probs=0.5)','quantile(x,probs=0.75)','quantile(x,probs=0.9)')),
   summ.names = list(c('N','Mean','SD','P10','P25','Median','P75','P90')),
   file=get_filename_case(paste0("output/summary_stats/summary_stats_demand_stateyear.tex"),case))
write(paste0("\\newcommand{\\defaultprobmeanfullsample}{",defaultprobmeanfullsample,"} \n",
             "\\newcommand{\\assetsavgstructural}{",assetsavgstructural,"} \n",
             "\\newcommand{\\caprateavgstructural}{",caprateavgstructural,"} \n",
             "\\newcommand{\\defaultprobavgstructural}{",defaultprobavgstructural,"} \n",
             "\\newcommand{\\sharetransferredavgstructural}{",sharetransferredavgstructural,"} \n",
             "\\newcommand{\\numinsurersusecaptives}{",numinsurersusecaptivesstructural,"} \n",
             "\\newcommand{\\numinsurers}{",numinsurersstructural,"} \n",
             "\\newcommand{\\numinsurersstructural}{",numinsurersstructural,"} \n",
             "\\newcommand{\\captivetaxrate}{",tau,"} \n",
             "\\newcommand{\\totalliabstructural}{",round(totalliabstructural,digits=1),"} \n",
             "\\newcommand{\\marketshareinsamplebyliab}{",round(marketshareinsamplebyliab,digits=1),"} \n"),
      file=get_filename_case("output/PaperText/PaperText_RegulatoryCompetition_Analysis_Insurer_SummaryStatistics.tex",case))

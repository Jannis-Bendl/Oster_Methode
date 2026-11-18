source("../lib/r/Functions.R")

subsubfolder_path <- file.path(getwd(), "output", "PaperText")
if (!file.exists(subsubfolder_path)) {
  dir.create(subsubfolder_path, recursive = TRUE)}

source("code/RegulatoryCompetition_Analysis_Demand_01_CreateData.R")

data <- fread(path.symlink("input/Demand_All.csv"))
data <- loadDemandData(data)

data$Captive_uses[which(is.na(data$Captive_uses))] = 0
data$Captive_uses_intensive[which(is.na(data$Captive_uses_intensive))] = 0

reg_iv_ky_1 <- feols(shares_ln_minus_shares_0 ~ TOTALLIAB_ln_std + RatingNumeric_std + AUTHCONTROLLEVELRISKBASEDCAPRATIO_std + LEVERAGE_std + CASHSTINVESTTOLIAB_std + ROAECAPSURPLUS_std | state_year_type | price ~ Captive_uses_intensive + TOTALLIAB_ln_std_sq + RatingNumeric_std_sq + AUTHCONTROLLEVELRISKBASEDCAPRATIO_std_sq + CASHSTINVESTTOLIAB_std_sq + ROAECAPSURPLUS_std_sq, data=data, vcov = ~amb_co_num_year)

reg_iv_ky_1_firststage <- reg_iv_ky_1$iv_first_stage
reg_iv_ky_1_f_stat_wald <- fitstat(reg_iv_ky_1, "ivf")$ivf1$stat
reg_iv_ky_1_f_stat_kp <- fitstat(reg_iv_ky_1, "ivwald")$ivwald1$stat

obs_sample_removed = as.vector((reg_iv_ky_1$obs_selection$obsRemoved)) * (-1)
data$obs_sample = as.numeric(!row.names(data) %in% obs_sample_removed)



instr_annuities <- paste0(names(data)[which(grepl("^LifeOnlyMale[5-7]|^LifeOnlyFemale[5-7]",names(data)))],collapse=" + ")
reg_iv_annuities_1_formula <- paste0("shares_ln_minus_shares_0 ~ TOTALLIAB_ln_std + RatingNumeric_std + AUTHCONTROLLEVELRISKBASEDCAPRATIO_std + LEVERAGE_std + CASHSTINVESTTOLIAB_std + ROAECAPSURPLUS_std | state_year_type | price ~ ",instr_annuities)
reg_iv_annuities_1 <- feols(as.formula(reg_iv_annuities_1_formula), data=data, vcov = ~amb_co_num_year)

reg_iv_annuities_1_firststage <- reg_iv_annuities_1$iv_first_stage
reg_iv_annuities_1_f_stat_wald <- fitstat(reg_iv_annuities_1, "ivf")$ivf1$stat
reg_iv_annuities_1_f_stat_kp <- fitstat(reg_iv_annuities_1, "ivwald")$ivwald1$stat


data$COMMISSIONS_div_PREMIUMSISSUED = ifelse(data$PREMIUMSISSUED != 0,data$COMMISSIONS / data$PREMIUMSISSUED,NA)
data$COMMISSIONS_div_PREMIUMSISSUEDCOUNT = ifelse(data$PREMIUMSISSUEDCOUNT != 0,data$COMMISSIONS / data$PREMIUMSISSUEDCOUNT,NA)
data$COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR = ifelse(data$PREMIUMSISSUEDFIRSTYEAR != 0,data$COMMISSIONS / data$PREMIUMSISSUEDFIRSTYEAR,NA)

winsorize_twosided <- function(column, min_percentile = 0.00, max_percentile = 0.99) {
  lower_threshold <- quantile(column, min_percentile, na.rm = TRUE)
  upper_threshold <- quantile(column, max_percentile, na.rm = TRUE)
  
  column[column < lower_threshold] <- lower_threshold
  column[column > upper_threshold] <- upper_threshold
  
  return(column)
}
data$COMMISSIONS_div_PREMIUMSISSUED = winsorize_twosided(data$COMMISSIONS_div_PREMIUMSISSUED, min_percentile = 0.05, max_percentile = 0.95)
data$COMMISSIONS_div_PREMIUMSISSUEDCOUNT = winsorize_twosided(data$COMMISSIONS_div_PREMIUMSISSUEDCOUNT, min_percentile = 0.05, max_percentile = 0.95)
data$COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR = winsorize_twosided(data$COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR, min_percentile = 0.05, max_percentile = 0.95)

data$COMMISSIONS_div_PREMIUMSISSUED_sq = data$COMMISSIONS_div_PREMIUMSISSUED ^ 2
data$COMMISSIONS_div_PREMIUMSISSUEDCOUNT_sq = data$COMMISSIONS_div_PREMIUMSISSUEDCOUNT ^ 2
data$COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR_sq = data$COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR ^ 2

data$COMMISSIONRATIO_sq = data$COMMISSIONRATIO ^ 2

instr_commissions <- c("COMMISSIONS_div_PREMIUMSISSUED",
                       "COMMISSIONS_div_PREMIUMSISSUED_sq")

instr_commissions <- paste0(instr_commissions,collapse=" + ")
reg_iv_commissions_1_formula <- paste0("shares_ln_minus_shares_0 ~ TOTALLIAB_ln_std + RatingNumeric_std + AUTHCONTROLLEVELRISKBASEDCAPRATIO_std + LEVERAGE_std + CASHSTINVESTTOLIAB_std + ROAECAPSURPLUS_std | state_year_type | price ~ ",instr_commissions)
reg_iv_commissions_1 <- feols(as.formula(reg_iv_commissions_1_formula), data=data, vcov = ~amb_co_num_year)

reg_iv_commissions_firststage <- reg_iv_commissions_1$iv_first_stage
reg_iv_commissions_f_stat_wald <- fitstat(reg_iv_commissions_1, "ivf")$ivf1$stat
reg_iv_commissions_f_stat_kp <- fitstat(reg_iv_commissions_1, "ivwald")$ivwald1$stat

data$quantities_thousands = data$quantities / 1000
data$share_pct = data$share * 100

ss_var = c("price_dollars",
           "quantities_thousands",
           "share_pct")
ss_var_labels = c("Price",
                  "Quantities",
                  "Market Share")

st(as.data.table(data)[which(data$obs_sample == 1),..ss_var],
   out="latex",
   labels = ss_var_labels,
   digits=2,
   summ = list(c('notNA(x)','mean(x)','sd(x)','quantile(x,probs=0.1)','quantile(x,probs=0.25)','quantile(x,probs=0.5)','quantile(x,probs=0.75)','quantile(x,probs=0.9)')),
   summ.names = list(c('N','Mean','SD','P10','P25','Median','P75','P90')),
   file=get_filename_case("../Analysis_Insurer/output/summary_stats/summary_stats_demand_insurerstateyear.tex",case))

beta <- summary(reg_iv_ky_1)$coefficients[1]
beta_hausman <- summary(reg_iv_annuities_1)$coefficients[1]
beta_commissions <- summary(reg_iv_commissions_1)$coefficients[1]

data_elasticity <- data

data_elasticity$elasticity = data_elasticity$price * beta * (1 - data_elasticity$share)
data_elasticity$elasticity_hausman = data_elasticity$price * beta_hausman * (1 - data_elasticity$share)
data_elasticity$elasticity_commissions = data_elasticity$price * beta_commissions * (1 - data_elasticity$share)

ggplot(data = data_elasticity) + geom_histogram(aes(x=elasticity,y=..density..), bins=10, color="black", fill="white") +
  xlab("Elasticity") + ylab("Density") + theme_classic() + theme(text = element_text(size=20))
ggsave("output/histogram_elasticity.png",width=10,height=7,dpi=300)

elasticitymean <- round(mean(data_elasticity$elasticity,na.rm=TRUE),digits=1)
elasticitymean_hausman <- round(mean(data_elasticity$elasticity_hausman,na.rm=TRUE),digits=1)
elasticitymean_commissions <- round(mean(data_elasticity$elasticity_commissions,na.rm=TRUE),digits=1)

saveRDS(reg_iv_ky_1, file="output/regs_demand_ky.RDS")
saveRDS(reg_iv_annuities_1, file="output/regs_demand_hausman.RDS")
saveRDS(reg_iv_commissions_1, file="output/regs_demand_commissions.RDS")

fwrite(data_elasticity[,c("amb_co_num","SNLSTATENTITYKEY","year",'type','state','elasticity','share')],"output/elasticities_insurerstateyear.csv")

writeLines(as.character(modelsummary(list("(1)" = reg_iv_ky_1),
                        fmt = "%.2f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm,
                        add_rows = data.frame(a = c("State-Year FEs"),
                                              b = c("X")),
                        output="latex_tabular")),
           "output/regs_demand_ky.tex")

writeLines(as.character(modelsummary(list("(1)" = reg_iv_annuities_1),
                                     fmt = "%.2f",
                                     stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                                     gof_omit = c("^(?!R2$|Obs)"),
                                     gof_map = gm,
                                     coef_map = cm,
                                     add_rows = data.frame(a = c("State-Year FEs"),
                                                           b = c("X")),
                                     output="latex_tabular")),
           "output/regs_demand_hausman.tex")

writeLines(as.character(modelsummary(list("(1)" = reg_iv_commissions_1),
                                     fmt = "%.2f",
                                     stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                                     gof_omit = c("^(?!R2$|Obs)"),
                                     gof_map = gm,
                                     coef_map = cm,
                                     add_rows = data.frame(a = c("State-Year FEs"),
                                                           b = c("X")),
                                     output="latex_tabular")),
           "output/regs_demand_commissions.tex")

writeLines(as.character(modelsummary(list("(1)" = reg_iv_ky_1$iv_first_stage$price,
                                          "(2)" = reg_iv_annuities_1$iv_first_stage$price,
                                          "(3)" = reg_iv_commissions_firststage$price),
                        fmt = "%.2f",
                        stars = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                        gof_omit = c("^(?!R2$|Obs)"),
                        gof_map = gm,
                        coef_map = cm_firststage,
                        add_rows = data.frame(a = c("F Statistic","IV"),
                                              b = c(round(reg_iv_ky_1_f_stat_wald,digits=2),"Koijen-Yogo"),
                                              c = c(round(reg_iv_annuities_1_f_stat_wald,digits=2),"Hausman"),
                                              d = c(round(reg_iv_commissions_f_stat_wald,digits=2),"Commissions")),
                        output="latex_tabular")),
           "output/regs_demand_firststage.tex")





data_states = fread("../CleanData/output/Compulife/Prices_Compulife_2011_2021_States.csv")
names(data_states) = c("amb_name","product","price","rating","file_this","fyear","quarter","state")

data_states$amb_name_product = paste0(data_states$amb_name,data_states$product)
data_states$amb_name_product_year = paste0(data_states$amb_name,data_states$product,data_states$fyear)
data_states$amb_name_product_state = paste0(data_states$amb_name,data_states$product,data_states$state)
data_states$amb_name_product_state_year = paste0(data_states$amb_name,data_states$product,data_states$state,data_states$fyear)
data_states$amb_name_year = paste0(data_states$amb_name,data_states$fyear)
data_states$amb_name_state = paste0(data_states$amb_name,data_states$state)
data_states$amb_name_state_year = paste0(data_states$amb_name,data_states$state,data_states$fyear)

data_states$price = as.numeric(data_states$price)

set.seed(123)
data_states$cons = runif(n=nrow(data_states))
reg_state_nostate = felm(price ~ cons | amb_name_product_year | 0 | amb_name,data=data_states)

reg_state_yesstate = tryCatch(
  felm(price ~ cons | amb_name_product_state_year | 0 | amb_name, data=data_states),
  error = function(e) reg_state_nostate
)

reg_state_nostate_noproduct = felm(price ~ cons | amb_name_year | 0 | amb_name,data=data_states)

reg_state_yesstate_noproduct = felm(price ~ cons | amb_name_state_year | 0 | amb_name,data=data_states)

library(lmtest)
lrtest_pval = lrtest(reg_state_nostate_noproduct,reg_state_yesstate_noproduct)[2,5]


stargazer(reg_state_nostate,reg_state_yesstate,reg_state_nostate_noproduct,reg_state_yesstate_noproduct,
          dep.var.labels=c("Price"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          omit = "cons",
          add.lines=list(c("Insurer-Product-Year FEs","X","","",""),
                         c("Insurer-Product-Year-State FEs","","X","",""),
                         c("Insurer-Year FEs","","","X",""),
                         c("Insurer-Year-State FEs","","","","X"),
                         c("p-value","",lrtest_pval,"",lrtest_pval)),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE,
          header = FALSE,
          out=paste0("output/reg_price_state.tex"))

reg_iv_annuities_1_alpha = summary(reg_iv_annuities_1)$coefficients[1]
reg_demand_r2 <- round(r2(reg_iv_ky_1)["ar2"],digits=2)
fstat_ky <- round(reg_iv_ky_1_f_stat_wald,digits=2)
fstat_annuities <- round(reg_iv_annuities_1_f_stat_wald,digits=2)

write(paste0("\\newcommand{\\regdemandrsq}{",reg_demand_r2,"} \n",
             "\\newcommand{\\fstatky}{",fstat_ky,"} \n",
             "\\newcommand{\\demandalpha}{",round(reg_iv_annuities_1_alpha,digits=1),"} \n",
             "\\newcommand{\\fstatannuities}{",fstat_annuities,"} \n",
             "\\newcommand{\\elasticitymean}{",abs(elasticitymean),"} \n",
             "\\newcommand{\\elasticitymeanhausman}{",abs(elasticitymean_hausman),"} \n",
             "\\newcommand{\\elasticitymeancommissions}{",abs(elasticitymean_commissions),"} \n"),
      file="output/PaperText/PaperText_RegulatoryCompetition_Analysis_Demand.tex")

gc()

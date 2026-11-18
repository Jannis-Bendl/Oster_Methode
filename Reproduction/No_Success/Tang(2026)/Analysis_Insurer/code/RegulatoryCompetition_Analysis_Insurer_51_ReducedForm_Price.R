source("../lib/r/Functions.R")
data = fread("../CleanData/output/CompuLife_Pre2005_All.csv")
data_quantities = fread("../raw/Industry/SOA_Quantities_RegXXX.csv")
data_reserves = readxl::read_xlsx("../raw/Lombardi/Reserves.xlsx",sheet = "Sheet2")

data = data[which(data$product %in% c("10YearsGuaranteedOnly","15YearsGuaranteedOnly","20YearsGuaranteedOnly","30YearsGuaranteedOnly")),]
data$product = as.factor(as.numeric(gsub("YearsGuaranteedOnly","",data$product)))
data <- within(data, product <- relevel(product, ref = "10"))
data = data[which(data$year >= 1999 & data$year <= 2000),]
data$yq = as.Date(paste0(data$year,"-",data$quarter,"-01"))


data$yq = as.Date(as.yearmon(data$yq),frac=1)

data_2001aug = data[which(data$yq == "2001-08-31"),]

data_2001aug$yq = as.Date("2001-09-30")

data = rbind(data,data_2001aug)

data$yq_char = as.factor(data$yq)
data <- within(data, yq_char <- relevel(yq_char, ref = "1999-12-31"))

data_prices_1999q4 = data[which(data$yq == as.Date("1999-12-31")),c("CompanyName","product","Price","markup_npv")]
names(data_prices_1999q4) = mapvalues(names(data_prices_1999q4),
                                      from=c("Price","markup_npv"),
                                      to=c("Price_1999q4","markup_npv_1999q4"))
data = merge(data,
             data_prices_1999q4,
             by=c("CompanyName","product"),
             all.x=TRUE)

data$Price_pct_1999q4 = (data$Price / data$Price_1999q4) * 100
data$markup_npv_pct_1999q4 = (data$markup_npv) * 100

data$yq_num = interval(as.Date("1999-12-31"), data$yq) %/% months(1)

pretrend_pct_1999q4 = lm(Price_pct_1999q4 ~ yq_num * product, data=data[which(data$year <= 1999),])
data$Price_pct_1999q4_pretrend = predict(pretrend_pct_1999q4,newdata = data)
data$Price_pct_1999q4_ex_pretrend = data$Price_pct_1999q4 - data$Price_pct_1999q4_pretrend

pretrend_markup_npv_pct_1999q4 = lm(markup_npv_pct_1999q4 ~ yq_num * product, data=data[which(data$year <= 1999),])
data$markup_npv_pct_1999q4_pretrend = predict(pretrend_markup_npv_pct_1999q4,newdata = data)
data$markup_npv_pct_1999q4_ex_pretrend = data$markup_npv_pct_1999q4 - data$markup_npv_pct_1999q4_pretrend

data$CompanyName_product = paste0(data$CompanyName,data$product)

reg_1 = felm(Price_pct_1999q4 ~ product * yq_char | product | 0 | CompanyName + yq, data=data)

reg_2 = felm(Price_pct_1999q4 ~ product * yq_char | CompanyName + product | 0 | CompanyName + yq, data=data)

reg_3 = felm(Price_pct_1999q4 ~ product * yq_char | CompanyName_product | 0 | CompanyName + yq, data=data)

reg_3_dollars = felm(Price ~ product * yq_char | CompanyName_product | 0 | CompanyName + yq, data=data)

data$prepost = as.numeric(data$year >= 2000)

reg_1_markup_prepost = felm(markup_npv_pct_1999q4 ~ product * prepost | product | 0 | CompanyName + yq, data=data)

reg_2_markup_prepost = felm(markup_npv_pct_1999q4 ~ product * prepost | CompanyName + product | 0 | CompanyName + yq, data=data)

reg_3_markup_prepost = felm(markup_npv_pct_1999q4 ~ product * prepost | CompanyName_product | 0 | CompanyName + yq, data=data)

reg_1_markup = felm(markup_npv_pct_1999q4 ~ product * yq_char | product | 0 | CompanyName + yq, data=data)

reg_2_markup = felm(markup_npv_pct_1999q4 ~ product * yq_char | CompanyName + product | 0 | CompanyName + yq, data=data)

reg_3_markup = felm(markup_npv_pct_1999q4 ~ product * yq_char | CompanyName_product | 0 | CompanyName + yq, data=data)

reg_1_ex_pretrend = felm(Price_pct_1999q4_ex_pretrend ~ product * yq_char | product | 0 | CompanyName + yq, data=data)

reg_2_ex_pretrend = felm(Price_pct_1999q4_ex_pretrend ~ product * yq_char | CompanyName + product | 0 | CompanyName + yq, data=data)

reg_3_ex_pretrend = felm(Price_pct_1999q4_ex_pretrend ~ product * yq_char | CompanyName_product | 0 | CompanyName + yq, data=data)

reg_1_ex_pretrend_markup = felm(markup_npv_pct_1999q4_ex_pretrend ~ product * yq_char | product | 0 | CompanyName + yq, data=data)

reg_2_ex_pretrend_markup = felm(markup_npv_pct_1999q4_ex_pretrend ~ product * yq_char | CompanyName + product | 0 | CompanyName + yq, data=data)

reg_3_ex_pretrend_markup = felm(markup_npv_pct_1999q4_ex_pretrend ~ product * yq_char | CompanyName_product | 0 | CompanyName + yq, data=data)

stargazer(reg_1,reg_2,reg_3,
          dep.var.labels=c("Price"),
          covariate.labels = c("15-Year X 1(3 Months Post-Reg XXX)",
                               "20-Year X 1(3 Months Post-Reg XXX)",
                               "30-Year X 1(3 Months Post-Reg XXX)"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          keep = c(":yq_char2000-03-31"),
          add.lines=list(c("Product FEs","X","X",""),
                         c("Insurer FEs","","X",""),
                         c("Product Insurer FEs","","","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ProductPrice/coef_pricing.tex"))

stargazer(reg_2_markup,reg_3_markup,
          dep.var.labels=c("Price"),
          covariate.labels = c("15-Year X 1(3 Months Post-Reg XXX)",
                               "20-Year X 1(3 Months Post-Reg XXX)",
                               "30-Year X 1(3 Months Post-Reg XXX)"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          keep = c(":yq_char2000-03-31"),
          add.lines=list(c("Product FEs","X",""),
                         c("Insurer FEs","X",""),
                         c("Product Insurer FEs","","X")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ProductPrice/coef_pricing_markup.tex"))


stargazer(reg_3_dollars,reg_3_markup_prepost,
          dep.var.labels=c(" "," "," "),
          covariate.labels = c("15-Year X 1(3 Months Post-Reg XXX)",
                               "20-Year X 1(3 Months Post-Reg XXX)",
                               "30-Year X 1(3 Months Post-Reg XXX)",
                               "15-Year X 1(Post-Reg XXX)",
                               "20-Year X 1(Post-Reg XXX)",
                               "30-Year X 1(Post-Reg XXX)"),
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          keep = c(":yq_char2000-03-31",":prepost"),
          add.lines=list(c("Product Insurer FEs","X","X"),
                         c("Specification","Dollars","Pre-Post")),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ProductPrice/coef_pricing_fullspecs.tex"))

coefs_clean <- function(coefs){
  names(coefs) = gsub("\\.","",names(coefs))
  
  coefs = coefs[which(grepl("yq",row.names(coefs))),]
  
  coefs$yq_char = gsub("(.*):","",row.names(coefs))
  coefs$product = gsub(":(.*)","",row.names(coefs))
  
  coefs$product[which(!grepl("product",coefs$product))] = "product10"
  
  coefs$yq = as.Date(gsub("yq_char","",coefs$yq_char))
  
  coefs$product = as.factor(as.numeric(gsub("product","",coefs$product)))
  
  return(coefs)
}

for (spec_this in c("","_markup","_ex_pretrend","_ex_pretrend_markup")){
  if (spec_this == ""){
    coefs = data.frame(summary(reg_3)$coefficients)
  }
  if (spec_this == "_markup"){
    coefs = data.frame(summary(reg_3_markup)$coefficients)
  }
  if (spec_this == "_ex_pretrend"){
    coefs = data.frame(summary(reg_3_ex_pretrend)$coefficients)
  }
  if (spec_this == "_ex_pretrend_markup"){
    coefs = data.frame(summary(reg_3_ex_pretrend_markup)$coefficients)
  }
  
  coefs = coefs_clean(coefs)
  
  coefs = coefs[which(coefs$product != "10"),]
    
  
  ggplot(data=coefs) + 
    geom_line(aes(x=yq,y=Estimate,group=product,color=factor(product))) +
    geom_errorbar(aes(x=yq,ymin=Estimate-1.96*Clusterse,ymax=Estimate+1.96*Clusterse,group=product, color=factor(product)), width=10) +
    geom_vline(xintercept=as.Date("2000-01-01")) + 
    geom_hline(yintercept=0) + 
    xlab("Date") + ylab("Coefficient Estimate") + 
    theme_classic() + theme(text = element_text(size=20)) + theme(legend.position="right") +
    scale_color_manual(values = c("grey70", "grey40", "black"), name="Term (Years)", guide = guide_legend(reverse = TRUE))
  ggsave(paste0("output/ProductPrice/coef_pricing",spec_this,"_plot.png"),width=10,height=5)
}

data_ss = data[which(!is.na(data$Price)),] %>% group_by(yq,product) %>% summarise(n_firms = n_distinct(CompanyName,na.rm=TRUE))

ggplot(data=data_ss) + 
  geom_line(aes(x=yq,y=n_firms,group=product,color=product)) +
  geom_vline(xintercept=as.Date("2000-01-01")) + 
  xlab("Date") + ylab("Number of Insurers Selling Product") + 
  theme_classic() + theme(text = element_text(size=20)) + theme(legend.position="bottom") +
  scale_color_manual(values = c("#99CCFF","#66B2FF","#0080FF","#004C99","#001933"), name="Term Length (Years)")
ggsave("output/ProductPrice/quantities_ts_plot.png",width=8,height=5)

data_prices_1999q4_ss = data_prices_1999q4 %>% group_by(product) %>% summarise(price = mean(Price_1999q4,na.rm=TRUE))

data_prices_1999q4_ss$Term = as.numeric(gsub("YearsGuaranteedOnly","",data_prices_1999q4_ss$product))

rf = 0.0609

data_reserves_raw = data_reserves

spec_this = ""
if (spec_this == ""){
  coefs = data.frame(summary(reg_3)$coefficients)
} else if (spec_this == "_markup"){
  coefs = data.frame(summary(reg_3_markup)$coefficients)
} else if (spec_this == "_ex_pretrend"){
  coefs = data.frame(summary(reg_3_ex_pretrend)$coefficients)
} else if (spec_this == "_ex_pretrend_markup"){
  coefs = data.frame(summary(reg_3_ex_pretrend_markup)$coefficients)
}

coefs = coefs_clean(coefs)

computeReservesTable <- function(r){
  data_reserves = data_reserves_raw

  data_reserves$Reserves_NPV = data_reserves$Reserves / ((1 + r)^data_reserves$Year)
  data_reserves = data_reserves %>% group_by(Term) %>% summarise(Reserves_NPV = sum(Reserves_NPV,na.rm=TRUE))

  data_reserves_prices = merge(data_reserves,
                               data_prices_1999q4_ss,
                               by=c("Term"),
                               all.x=TRUE)

  data_reserves_prices$R_Term = (1-(1/(1+r))^data_reserves_prices$Term)/(1-(1/(1+r)))
  data_reserves_prices$Reserves_FinancingCost = data_reserves_prices$Reserves_NPV / data_reserves_prices$R_Term * r
  
  data_reserves_prices$Reserves_FinancingCost_price_increase = round(data_reserves_prices$Reserves_FinancingCost / data_reserves_prices$price * 100,digits=1)

  data_reserves_prices$Reserves_FinancingCost_price_increase_did = data_reserves_prices$Reserves_FinancingCost_price_increase - data_reserves_prices$Reserves_FinancingCost_price_increase[which(data_reserves_prices$Term == 10)]
  
  coefs_2000q1 = coefs[which(coefs$yq == "2000-03-31"),c("Estimate","product")]
  names(coefs_2000q1) = c("Estimate","Term")
  coefs_2000q1$Term = as.numeric(as.character(coefs_2000q1$Term))

  data_reserves_prices = merge(data_reserves_prices,
                               coefs_2000q1,
                               by=c("Term"),
                               all.x=TRUE)

  data_reserves_prices = data_reserves_prices[which(data_reserves_prices$Term != 5),]

  return(data_reserves_prices)
}

g1 = function(r){
  data_reserves_prices = computeReservesTable(r)
  moments = data_reserves_prices$Reserves_FinancingCost_price_increase_did - data_reserves_prices$Estimate
  return(moments)
}

g1_obj = function(moments){
 obj = sum(moments^2)
 return(obj)
}

computeMin = function(r){
  moments = g1(r)
  obj = g1_obj(moments)
  return(obj)
}

r_all = list()
i = 1
for (r_this in seq(0,0.20,0.0001)){
  obj_this = computeMin(r_this)
  r_all_this = data.frame(r=r_this,
                          obj=obj_this)
  r_all[[i]] = r_all_this
  i = i+1
}
r_all = do.call(rbind,r_all)

r_soln = median(r_all$r[which(r_all$obj == min(r_all$obj,na.rm=TRUE))],na.rm=TRUE)
epsilon = 0.10
epsilon_low = 0
epsilon_high = 1
r_estimate = r_soln / (1 + epsilon)
r_estimate_low = r_soln / (1 + epsilon_low)
r_estimate_high = r_soln / (1 + epsilon_high)

data_reserves_prices = computeReservesTable(r_soln)
data_reserves_prices$Estimate = round(data_reserves_prices$Estimate,digits=1)

data_reserves_prices = data_reserves_prices[,c("Term","price","Reserves_NPV","Reserves_FinancingCost","Reserves_FinancingCost_price_increase","Estimate")]
names(data_reserves_prices) = c("Term","Price"," Reserves","Financing Cost","Financing Cost Increase","Diff-in-Diff")

stargazer(data_reserves_prices,
          summary = FALSE,
          column.labels = c("Term","Price"," Reserves","Financing Cost","Financing Cost Increase","Diff-in-Diff"),
          dep.var.labels=c("Price"),
          style="aer",
          omit.table.layout = "n",
          float=FALSE,rownames=FALSE,digits=1, digits.extra=0,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ProductPrice/coef_pricing_reserves_table.tex"))
stargazer_text = read_file(paste0("output/ProductPrice/coef_pricing_reserves_table.tex"))
stargazer_text = gsub("\nTerm"," & & & & \\\\multicolumn{2}{c}{Price Increase} \\\\\\\\ \nTerm",stargazer_text)
writeLines(stargazer_text,paste0("output/ProductPrice/coef_pricing_reserves_table.tex"))


ggplot(data=data_reserves_prices, aes(x=`Diff-in-Diff`,y=`Financing Cost Increase`)) +
  geom_point() +
  xlab("Diff-in-Diff Price Increase (%)") + ylab("Calibrated Price Increase (%)") +
  xlim(0,25) + ylim(0,25) +
  stat_summary(fun.data=mean_cl_normal) + geom_smooth(method='lm', formula= y~x, se=FALSE, color='black') +
  theme_classic() + theme(text = element_text(size=20)) + theme(legend.position="bottom")
ggsave(paste0("output/ProductPrice/coef_pricing_reserves.png"),width=8,height=5)


data_quantities = data_quantities[which(data_quantities$Guaranteed == "Guaranteed"),]
data_quantities = data_quantities[,Guaranteed:=NULL]

data_quantities = data_quantities[,`2001`:=NULL]
data_quantities = data_quantities[,`1999_Raw`:=NULL]
data_quantities = data_quantities[,`2000_Raw`:=NULL]
data_quantities = data_quantities[,`2001_Raw`:=NULL]
names(data_quantities) = c("Years","Pre-Reg XXX","Post-Reg XXX","Change")

data_quantities$Change = as.numeric(gsub("\\%","",data_quantities$Change))
data_quantities$Years = as.numeric(data_quantities$Years)
data_quantities_plot = data_quantities[which(data_quantities$Years != 25),]
data_quantities_plot$Years = as.factor(data_quantities_plot$Years)
ggplot(data=as.data.table(data_quantities_plot[which(data_quantities_plot$Years %in% c(10,15,20,30)),]),aes(x=Years,y=Change)) +
  geom_bar(stat="identity") +
  xlab("Years") + ylab("Shares Change (%)") +
  theme_classic() + theme(text = element_text(size=20)) + theme(legend.position="bottom")
ggsave(paste0("output/ProductPrice/quantities_plot.png"),width=8,height=5)

stargazer(data_quantities,
          summary = FALSE,
          style="aer",
          omit.table.layout = "n",
          omit.stat=c("ser","adj.rsq"),
          float=FALSE,rownames=FALSE,digits=2, digits.extra=2,
          no.space = TRUE, header = FALSE,
          out=paste0("output/ProductPrice/quantities.tex"))

coefthirtyyrxxx = coefs$Estimate[which(coefs$product == 30 & coefs$yq == "2000-03-31")]

theta = data.frame(theta=r_estimate)
fwrite(theta,file="output/ProductPrice/theta.csv")

write(paste0("\\newcommand{\\regxxxcostofcapital}{",round(r_estimate*100,digits=2),"} \n",
             "\\newcommand{\\regxxxcostofexternalfinancing}{",round(r_estimate*100,digits=2),"} \n",
             "\\newcommand{\\regxxxcostofexternalfinancinglow}{",round(r_estimate_low*100,digits=2),"} \n",
             "\\newcommand{\\regxxxcostofexternalfinancinghigh}{",round(r_estimate_high*100,digits=2),"} \n",
             "\\newcommand{\\regxxxriskfreerate}{",round(rf*100,digits=2),"} \n",
             "\\newcommand{\\coefthirtyyrxxx}{",round(coefthirtyyrxxx,digits=1),"} \n"),
      file="output/PaperText/PaperText_RegulatoryCompetition_Analysis_Insurer_Price_ReducedForm.tex")

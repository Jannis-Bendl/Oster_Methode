## Load Packages
library(ggplot2)
library(plyr)
library(dplyr)
library(tidyr)
library(Hmisc)
library(data.table)
library(lubridate)
library(lfe)
library(sandwich)
library(stargazer)
library(zoo)
library(plm)
library(ggrepel)
library(moments)
library(stringr)
library(tidyverse)
library(reshape2)
library(fixest)
library(modelsummary)
library(nleqslv)
library(BB)
library(RStata)
library(R.utils)
library(latex2exp)
library(vtable)


### Dplyr: suppress output
options(dplyr.summarise.inform = FALSE)

### Functions:
binscatter <- function(data,x_var,y_var,n_quantiles=20,xlab=x_var,ylab=y_var,group_var=NA){
  data <- as.data.frame(data)

  if (is.na(group_var)){
    p <- ggplot(data=data, aes(x=!!as.name(x_var),y=!!as.name(y_var))) +
      stat_summary_bin(fun.y='mean', bins=n_quantiles, color='black', size=2, geom='point', breaks = seq(min(data[,c(x_var)],na.rm=TRUE),max(data[,c(x_var)],na.rm=TRUE),by=(max(data[,c(x_var)],na.rm=TRUE)-min(data[,c(x_var)],na.rm=TRUE))/n_quantiles)) +
      geom_smooth(method="lm", formula="y~x", se=FALSE) +
      xlab(xlab) + ylab(ylab) +
      theme_classic() + theme(text = element_text(size=20))
  } else {
    data$quantiles <- ntile(data[,c(x_var)],n_quantiles)
    data <- data[which(!is.na(data$quantiles)),]
    data <- data[which(!is.na(data[,c(group_var)])),]

    data_ss <- data %>% group_by(!!as.name(group_var),quantiles) %>% summarise(!!as.name(y_var) := mean(!!as.name(y_var),na.rm=TRUE))

    p <- ggplot(data=data_ss, aes(x=quantiles,y=!!as.name(y_var))) +
      geom_point(aes(color=!!as.name(group_var),group=!!as.name(group_var))) +
      xlab(xlab) + ylab(ylab) +
      theme_classic() + theme(text = element_text(size=20))
  }
  print(p)
}

bin.scatter = function(x, y, num_scatter = 20, xlab = NA, ylab = NA){
  x_dec = cut(x, breaks = quantile(x, probs= seq(0, 1, by= 1/num_scatter), na.rm = TRUE),
              labels = c(1:num_scatter))
  mean.narm = function(x){return(mean(x, na.rm = TRUE))}
  x_sum = aggregate(x, by = list(x_dec), FUN = mean.narm)
  colnames(x_sum) = c("x_dec", "x_sum")
  y_sum = aggregate(y, by = list(x_dec), FUN = mean.narm)
  colnames(y_sum) = c("x_dec", "y_sum")
  binned = merge(x_sum, y_sum)
  plot(binned$x_sum, binned$y_sum, xlab = xlab, ylab = ylab)
  abline(lm(y_sum ~ x_sum, binned))
}

partialOrderFactor <- function(data,factorVar,orderVar) {
  ordering <- as.data.table(data)[order(!!orderVar,),!!factorVar][[!!factorVar]]
  data[[!!factorVar]] <- fct_relevel(as.factor(data[[!!factorVar]]),ordering)
  return(data)
}

ordinalNumber <- function(strings){
  to_replace <- rev(c("first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth","seventeenth","eighteenth","nineteenth","twentieth","twentyfirst","twentysecond","twentythird","twentyfourth","twentyfifth","twentysixth","twentyseventh","twentyeighth","twentyninth","thirtieth","thirtyfirst","thirtysecond","thirtythird","thirtyfourth","thirtyfifth","thirtysixth","thirtyseventh","thirtyeighth","thirtyninth"))
  replace_with <- as.character(rev(seq(1:39)))
  names(replace_with) <- to_replace
  strings_out <- str_replace_all(strings, replace_with)
  return(strings_out)
}

today <- gsub("-","",as.character(Sys.Date()))

endingNumericSort <- function(x,ndigits){
  return(x[order(as.numeric(substr(x, nchar(x)-ndigits+1, nchar(x))))])
}

dfToNumeric <- function(data){
  data <- mutate_all(data, function(x) as.numeric(as.character(x)))
  return(data)
}

cross_join <- function(X,Y){
  Z <- setkey(X[,c(k=1,.SD)],k)[Y[,c(k=1,.SD)],allow.cartesian=TRUE][,k:=NULL]
  return(Z)
}

remove_na <- function(x){
  dm <- data.matrix(x)
  dm[is.na(dm)] <- 0
  data.table(dm)
}

mean.narm = function(x){mean(x, na.rm = TRUE)}

dfToNumeric <- function(data){
  data <- mutate_all(data, function(x) as.numeric(as.character(x)))
  return(data)
}

winsorize <- function (x, fraction=0.05, print = FALSE){
  if(length(fraction) != 1 || fraction < 0 ||
     fraction > 0.5) {
    stop("bad value for 'fraction'")
  }
  lim <- quantile(x, probs=c(fraction, 1-fraction), na.rm=TRUE)
  x[ x < lim[1] ] <- lim[1]
  x[ x > lim[2] ] <- lim[2]
  if (print == TRUE){
    print(paste0("Limits are: ",lim[1]," and ",lim[2]))
  }
  return(x)
}


checkEqualDF <- function(df,df2){
  i <- intersect(names(df),names(df2))
  print(all.equal(as.data.frame(df)[i], as.data.frame(df2)[i]))
}

dfToPanel <- function(data,var_i,var_t){
  i_all <- unique(as.data.table(data)[,..var_i])
  t_all <- unique(as.data.table(data)[,..var_t])
  data_all <- merge(as.data.frame(i_all),as.data.frame(t_all))
  data_all <- merge(data_all,data,by=c(var_i,var_t),all.x=TRUE)
  colVar = c(var_i,var_t)
  data_all <- as.data.table(data_all)
  data_all <- data_all[do.call(order, data_all[, ..colVar]),]
  return(data_all)
}

### Update Merge/Join
update_join = function(df){
  cols_to_drop = c()
  
  cols_dups = gsub("\\.x$","",names(df)[which(grepl("\\.x$",names(df)))])
  
  for (j in 1:length(cols_dups)){
    cols_dups_this = cols_dups[j]
    cols_dups_this_all = names(df)[which(grepl(cols_dups_this,names(df)))]
    
    df_to_coalesce = df[,..cols_dups_this_all]
    df_to_coalesce = df_to_coalesce %>% transmute(coalesced := do.call(coalesce, .))
    
    col_dup_this_coalesced = paste0(cols_dups_this,"_coalesced")
    df[[col_dup_this_coalesced]] = df_to_coalesce$coalesced
    
    cols_to_drop = c(cols_to_drop,cols_dups_this_all)
  }
  
  df = df[, !cols_to_drop, with=FALSE][]
  
  names(df) = gsub("_coalesced","",names(df))
  
  return(df)
}

### Sum removing NA's (for dplyr)
sum_narm = function(x){
  return(sum(x,na.rm=TRUE))
}

### Excel Dates to R Dates
convert_excel_date <- function(date_str) {
  parsed_date <- as.Date(date_str, format = "%m/%d/%Y")
  
  if (is.na(parsed_date)) {
    tryCatch({
      parsed_date <- as.Date(as.numeric(date_str) - 2, origin = "1900-01-01")
    }, error = function(e) {
      parsed_date <<- NA
    })
  }
  
  return(parsed_date)
}

### Read SymLinks
if (file.exists("input.txt")){
  input_symlinks <- read.csv("input.txt",sep="|")
  names(input_symlinks) <- c("Destination","Source")
  row_start <- input_symlinks[which(grepl("# Destination",input_symlinks$Destination)),]
  
  input_symlinks <- read.csv("input.txt",sep="|",skip=row.names(row_start))
  names(input_symlinks) <- c("Destination","Source")
  input_symlinks$Destination <- trimws(paste0("input/",input_symlinks$Destination),which="both")
  input_symlinks$Source <- trimws(gsub("\\{root\\}","..",input_symlinks$Source),which="both")
}

path.symlink <- function(path){
  return(input_symlinks$Source[which(input_symlinks$Destination == path)])
}

### Summary Statistics LaTeX
st_tabular = function(file_this){
  ss_table_tex = read_file(file_this)
  ss_table_tex = gsub("(.*)\\\\begin\\{tabular\\}","\\\\begin{tabular}",ss_table_tex)
  ss_table_tex = gsub("d\\{tabular\\}(.*)","d{tabular}",ss_table_tex)
  write_file(ss_table_tex,file_this)
}

### Regression Table Outputs
gm <- modelsummary::gof_map
gm$clean[gm$raw == 'r.squared'] <- "R2"
gm$fmt[gm$raw == 'r.squared'] <- 2
gm$clean[gm$raw == 'r2'] <- "R-squared"
gm$fmt[gm$raw == 'r2'] <- 2
gm$clean[gm$raw == 'nobs'] <- "Obs."
gm$clean[gm$raw == '(Intercept)'] <- "Constant"
options("modelsummary_format_numeric_latex" = "plain")

##### Project-Specific
#### Create Directories
currentwd <- getwd()
if (grepl("Analysis_Demand",currentwd)){
  dir.create("output/PaperText")
}
if (grepl("Analysis_Insurer",currentwd)){
  dir.create("output/summary_stats")
  dir.create("output/PaperText")
  dir.create("output/CapitalAllocation")
  dir.create("output/ReducedForm")
  dir.create("output/ProductPrice")
  dir.create("output/DefaultRisk")
  dir.create("output/Pricing")
  dir.create("output/Regulator")
  dir.create("output/Regulator/ConsumerSurplus")
  dir.create("output/SupplyBan")
  dir.create("output/ExternalValidation")
  dir.create("output/MultipleEquilibria")
}

#### Declare Variable Labels for ModelSummary
cm <- c("same_state" = "1(Same State)",
        "price" = "Price",
        "fit_price" = "Price",
        "uses_captives" = "1(Captives)",
        "ceded_frac_liab" = "Captive Share",
        "LIAB_ASSETS_adj" = "Adjusted Leverage", 
        "LIAB_ASSETS_adj_std" = "Adjusted Leverage", 
        "LIAB_ASSETS_unadj" = "Unadjusted Leverage", 
        "LIAB_ASSETS_unadj_std" = "Unadjusted Leverage", 
        "Shadow_liab_frac" = "Captive Share", 
        "reserve_valuation_p3_to_p0_winsorize" = "Policy Losses",
        "kappa_economic_K_div_L" = "Captive Capital Rate",
        "TOTALLIAB" = "Size",
        "TOTALASSETS" = "Assets",
        "TOTALLIAB_amt" = "Liabilities",
        "TOTALLIAB_std" = "Size",
        "TOTALLIAB_ln" = "ln(Size)",
        "TOTALLIAB_ln_std" = "ln(Size)",
        "publicly_traded" = "1(Publicly Traded)",
        "publicly_traded_TICKER" = "1(Publicly Traded)",
        "age" = "Firm Age",
        "age_ln" = "ln(Firm Age)",
        "NAICOWNSTRUCTURE_is_mutual" = "1(Mutual Insurer)",
        "BUSINESSFOCUS_lifeorannuity" = "1(Life or Annuity Focus)",
        "group_numsubsidiaries" = "Num. Subsidiaries",
        "RatingNumeric" = "A.M. Best Rating",
        "RatingNumeric_std" = "A.M. Best Rating",
        "AUTHCONTROLLEVELRISKBASEDCAPRATIO" = "Risk-Based Capital Ratio",
        "AUTHCONTROLLEVELRISKBASEDCAPRATIO_std" = "Risk-Based Capital Ratio",
        "CASHSTINVESTTOLIAB" = "Liquidity",
        "CASHSTINVESTTOLIAB_std" = "Liquidity",
        "ROAECAPSURPLUS" = "Return on Equity",
        "ROAECAPSURPLUS_std" = "Return on Equity",
        "LEVERAGE" = "Leverage",
        "LEVERAGE_std" = "Leverage",
        "NAICOWNSTRUCTURE" = "Stock Company",
        "RESERVESGROSS" = "Gross Reserves",
        "EFFECTIVETAXRATELIFE_std" = "Tax Rate",
        "u_st" = "State-Year Mean Utility",
        "kappa_f" = "State Capital Rate",
        "TOTALLIAB_bn" = "Size",
        "(Intercept)" = "Constant",
        "REINSSTATEDOMICILED" = "Reinsurer State",
        "CEDENTSNLSTATENTITYKEY" = "Company",
        "year" = "Year")

cm_default <- cm[which(!names(cm) %in% c("RatingNumeric","AUTHCONTROLLEVELRISKBASEDCAPRATIO"))]
cm_default <- c("RatingNumeric" = "A.M. Best Rating",
                "AUTHCONTROLLEVELRISKBASEDCAPRATIO" = "Risk-Based Capital Ratio",
                cm_default)

cm_firststage = c("Captive_uses_intensive" = "1(Uses Captives)",
                  "Guarantee10yrFemale50LifeAnnuity" = "Annuity Price: 50 Female",
                  "Guarantee10yrFemale55LifeAnnuity" = "Annuity Price: 55 Female",
                  "Guarantee10yrFemale60LifeAnnuity" = "Annuity Price: 60 Female",
                  "Guarantee10yrFemale65LifeAnnuity" = "Annuity Price: 65 Female",
                  "Guarantee10yrFemale70LifeAnnuity" = "Annuity Price: 70 Female",
                  "Guarantee10yrFemale75LifeAnnuity" = "Annuity Price: 75 Female",
                  "Guarantee10yrMale50LifeAnnuity" = "Annuity Price: 50 Male",
                  "Guarantee10yrMale55LifeAnnuity" = "Annuity Price: 55 Male",
                  "Guarantee10yrMale60LifeAnnuity" = "Annuity Price: 60 Male",
                  "Guarantee10yrMale64LifeAnnuity" = "Annuity Price: 65 Male",
                  "Guarantee10yrMale70LifeAnnuity" = "Annuity Price: 70 Male",
                  "Guarantee10yrMale75LifeAnnuity" = "Annuity Price: 75 Male",
                  "LifeOnlyMale50LifeAnnuity" = "Annuity Price: 50 Male",
                  "LifeOnlyMale55LifeAnnuity" = "Annuity Price: 55 Male",
                  "LifeOnlyMale60LifeAnnuity" = "Annuity Price: 60 Male",
                  "LifeOnlyMale65LifeAnnuity" = "Annuity Price: 65 Male",
                  "LifeOnlyMale70LifeAnnuity" = "Annuity Price: 70 Male",
                  "LifeOnlyMale75LifeAnnuity" = "Annuity Price: 75 Male",
                  "LifeOnlyMale50LifeAnnuity_earliest" = "Annuity Price: 50 Male",
                  "LifeOnlyMale55LifeAnnuity_earliest" = "Annuity Price: 55 Male",
                  "LifeOnlyMale60LifeAnnuity_earliest" = "Annuity Price: 60 Male",
                  "LifeOnlyMale65LifeAnnuity_earliest" = "Annuity Price: 65 Male",
                  "LifeOnlyMale70LifeAnnuity_earliest" = "Annuity Price: 70 Male",
                  "LifeOnlyMale75LifeAnnuity_earliest" = "Annuity Price: 75 Male",
                  "COMMISSIONS_div_PREMIUMSISSUED" = "Broker Commission Rates",
                  "COMMISSIONS_div_PREMIUMSISSUED_sq" = "Broker Commission Rates (Sq.)",
                  "COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR" = "Broker Commission Rates (1st Year)",
                  "COMMISSIONS_div_PREMIUMSISSUEDFIRSTYEAR_sq" = "Broker Commission Rates (1st Year, Sq.)",
                  "TOTALLIAB_ln_std_sq" = "ln(Size) Sq.",
                  "RatingNumeric_std_sq" = "A.M. Best Rating Sq.",
                  "AUTHCONTROLLEVELRISKBASEDCAPRATIO_std_sq" = "Risk-Based Capital Ratio Sq.",
                  "CASHSTINVESTTOLIAB_std_sq" = "Liquidity Sq.",
                  "ROAECAPSURPLUS_std_sq" = "Return on Equity Sq.",
                  "LEVERAGE_std_sq" = "Leverage Sq.")

cm_captive <- c("has_captive_intensive" = "1(Insurer has Captive in State)",
        "amount_reinsured" = "Amount Reinsured",
        "kappa_state_captivebs" = "Stat. Captive Capital Rate",
        "kappa_economic_K_div_L" = "Captive Capital Rate",
        "kappa_economic_K_div_L_censored" = "Captive Capital Rate",
        "allow_prescribed" = "1(Allow Other Assets)",
        "amount_reinsured_ln" = "ln(Amount Reinsured)",
        "newbusinesses_pop" = "Business Registrations",
        "same_state" = "1(Same State)",
        "sells_in_state" = "1(Sells in State)",
        "state_share" = "Share Sold in State",
        "num_captives" = "Num. Captives",
        "CapitalSurplus_mil" = "Min. Capital",
        "CapitalSurplus_ratio" = "Capital Ratio",
        "CapitalSurplus_ratio_filled" = "Capital Ratio",
        "DPW_Life" = "Premiums Written",
        "CaptiveTaxRate" = "Captive Tax Rate",
        "AnnualFee" = "Captive Annual Fee",
        "YearFirstAllowedSPVCaptives" = "Year SPFCs Allowed",
        "AllowSPVCaptives" = "1(Allow Captives)",
        "CaptiveRegulatorFunding_CaptiveFund" = "1(Captive Fund)",
        "WhyStatePage_or_Brochure" = "1(Marketing)",
        "Keyword_Attract_Competitive_Welcome_Benefit_Favorable" = "1(Marketing Keyword)",
        "EmployeesCaptives" = "State Captive Division Employees",
        "EmployeesTotal" = "State Insurance Dept. Employees",
        "Benefits_Capital" = "1(Marketing Capital Req.)",
        "newbusinesses" = "Business Registrations",
        "tourists" = "Tourists",
        "Commissioner_Appointed" = "1(Appointed Commissioner)",
        "vote_share_r" = "Rep. Vote Share")

scenario_run = 20220612

#### NPV discounting
npv_rate_r = 0.05
npv_rate = (1 - (1 + npv_rate_r)^(-15)) / npv_rate_r

npv_rate_federal = 2.8

##### Dynamically Change File Paths for the specific case we're analyzing (for the structural model)





get_filename_case <- function(file_path, case) {
  current_dir <- basename(getwd())
  if (!current_dir %in% c("Analysis_Insurer","Analysis_Demand")) {
    stop("Error: Current directory is not 'Analysis_Insurer'.")
  }
  
  if (grepl("Analysis_Demand", normalizePath(dirname(file_path),mustWork = FALSE))) {
    return(file_path)
  } else if (grepl("Analysis_Insurer", normalizePath(dirname(file_path),mustWork = FALSE))) {
    exception_patterns <- c(
      "^.*output/CapitalAllocation_\\w+\\.csv$",
      "^.*output/data_insurer_chars\\.csv$",
      "^.*output/StateYear_joint\\.csv$",
      "^.*output/ReducedForm/.*"
    )
    
    for (pattern in exception_patterns) {
      if (grepl(pattern, file_path)) {
        return(file_path)  # Rule 3.1: Return original path if it matches the pattern
      }
    }
    
    file_name <- tools::file_path_sans_ext(basename(file_path))
    file_extension <- tools::file_ext(file_path)
    
    modified_file_name <- paste0(file_name, "_", case, ".", file_extension)
    
    modified_path <- file.path(dirname(file_path), modified_file_name)
    return(modified_path)
  }
  
  return(file_path)
}



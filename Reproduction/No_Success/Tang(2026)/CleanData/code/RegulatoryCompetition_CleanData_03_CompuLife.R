source("../lib/r/Functions.R")
dir.create("output/Compulife/", showWarnings = FALSE, recursive = TRUE)

data_av_lombardi = readxl::read_xlsx("../raw/Lombardi/Reserves.xlsx",sheet="ActuarialValue")

face_amount = 250000
data_av_lombardi$ActuarialValue1980CSO = data_av_lombardi$ProbSurviveToAge1980CSO * data_av_lombardi$ProbDiesGivenSurvivalToAge1980CSO * face_amount
data_av_lombardi$ActuarialValue2001VBT = data_av_lombardi$ProbSurviveToAge2001VBT * data_av_lombardi$ProbDiesGivenSurvivalToAge2001VBT * face_amount
data_av_lombardi$ActuarialValue = data_av_lombardi$ActuarialValue1980CSO

data_av_gsk = fread("../raw/FederalReserve/GurkaynakSackWright.csv")

data_av_gsk$Date = lubridate::mdy(data_av_gsk$Date)
data_av_gsk = data_av_gsk[which(data_av_gsk$Date <= as.Date("2022-01-01") & data_av_gsk$Date >= as.Date("1990-01-01")),]

data_av_gsk$Date_month = as.Date(as.yearmon(data_av_gsk$Date),frac=0)

data_av_gsk = data_av_gsk %>% group_by(Date_month) %>% summarise(SVENY01 = mean(SVENY01,na.rm=TRUE),
                                                                 SVENY02 = mean(SVENY02,na.rm=TRUE),
                                                                 SVENY03 = mean(SVENY03,na.rm=TRUE),
                                                                 SVENY04 = mean(SVENY04,na.rm=TRUE),
                                                                 SVENY05 = mean(SVENY05,na.rm=TRUE),
                                                                 SVENY06 = mean(SVENY06,na.rm=TRUE),
                                                                 SVENY07 = mean(SVENY07,na.rm=TRUE),
                                                                 SVENY08 = mean(SVENY08,na.rm=TRUE),
                                                                 SVENY09 = mean(SVENY09,na.rm=TRUE),
                                                                 SVENY10 = mean(SVENY10,na.rm=TRUE),
                                                                 SVENY11 = mean(SVENY11,na.rm=TRUE),
                                                                 SVENY12 = mean(SVENY12,na.rm=TRUE),
                                                                 SVENY13 = mean(SVENY13,na.rm=TRUE),
                                                                 SVENY14 = mean(SVENY14,na.rm=TRUE),
                                                                 SVENY15 = mean(SVENY15,na.rm=TRUE),
                                                                 SVENY16 = mean(SVENY16,na.rm=TRUE),
                                                                 SVENY17 = mean(SVENY17,na.rm=TRUE),
                                                                 SVENY18 = mean(SVENY18,na.rm=TRUE),
                                                                 SVENY19 = mean(SVENY19,na.rm=TRUE),
                                                                 SVENY20 = mean(SVENY20,na.rm=TRUE),
                                                                 SVENY21 = mean(SVENY21,na.rm=TRUE),
                                                                 SVENY22 = mean(SVENY22,na.rm=TRUE),
                                                                 SVENY23 = mean(SVENY23,na.rm=TRUE),
                                                                 SVENY24 = mean(SVENY24,na.rm=TRUE),
                                                                 SVENY25 = mean(SVENY25,na.rm=TRUE),
                                                                 SVENY26 = mean(SVENY26,na.rm=TRUE),
                                                                 SVENY27 = mean(SVENY27,na.rm=TRUE),
                                                                 SVENY28 = mean(SVENY28,na.rm=TRUE),
                                                                 SVENY29 = mean(SVENY29,na.rm=TRUE),
                                                                 SVENY30 = mean(SVENY30,na.rm=TRUE))

data_av_gsk = melt(data_av_gsk, id.vars=c("Date_month"))
data_av_gsk$maturity = as.numeric(gsub("SVENY","",data_av_gsk$variable))
data_av_gsk$treasury_yield = as.numeric(data_av_gsk$value)

products_all = data.frame(product=c(5,10,15,20,25,30))
products_all$x = 1
yq_all = data.frame(yq=sort(unique(data_av_gsk$Date_month)))
yq_all$x = 1

products_yq_all = merge(products_all,
                        yq_all,
                        by=c("x"),
                        all.x=TRUE,
                        all.y=TRUE)

products_yq_all$npv = NA

n = 30
p_vec = data_av_lombardi[,c("x","ProbDiesGivenSurvivalToAge1980CSO")]
p_vec$p = 1 - p_vec$ProbDiesGivenSurvivalToAge1980CSO

cumprod_na = function(cumprod_vec){
  if (length(cumprod_vec) == 0){
    return(1)
  }
  else {
    return(cumprod(cumprod_vec)[length(cumprod_vec)])
  }
}

for (product_this in products_all$product){
  for (yq_this in yq_all$yq){
    N = n + product_this

    sum_numerator = 0
    for (m in seq(1:(N-n))){
      nplusmminus1 = n + m - 1

      Pi_p_nplusl_l0_to_mminus2 = cumprod_na(p_vec$p[which(p_vec$x >= n & p_vec$x <= nplusmminus1 - 1)])

      one_minus_p_nplusmminus1 = 1 - p_vec$p[which(p_vec$x == nplusmminus1)]

      treasury_yield_maturity_this = data_av_gsk$treasury_yield[which(data_av_gsk$maturity == m & data_av_gsk$Date_month == yq_this)] / 100

      sum_numerator_this = (Pi_p_nplusl_l0_to_mminus2 * one_minus_p_nplusmminus1) / ((1+treasury_yield_maturity_this)^m)

      sum_numerator = sum_numerator + sum_numerator_this
    }

    sum_denominator = 0
    for (m in seq(1:(N-n-1))){
      nplusmminus1 = n + m - 1

      Pi_p_nplusl_l0_to_mminus1 = cumprod_na(p_vec$p[which(p_vec$x >= n & p_vec$x <= nplusmminus1)])

      treasury_yield_maturity_this = data_av_gsk$treasury_yield[which(data_av_gsk$maturity == m & data_av_gsk$Date_month == yq_this)] / 100

      sum_denominator_this = (Pi_p_nplusl_l0_to_mminus1) / ((1+treasury_yield_maturity_this)^m)

      sum_denominator = sum_denominator + sum_denominator_this
    }
    sum_denominator = 1 + sum_denominator

    npv_this = sum_numerator / sum_denominator * face_amount
    products_yq_all$npv[which(products_yq_all$product == product_this & products_yq_all$yq == yq_this)] = npv_this
  }
}

fwrite(products_yq_all,file="output/Lombardi_ActuarialValues.csv")


data_levels = c("base","state","term")

for (data_level_this in data_levels){

  if (data_level_this == "base"){
    files_dir <- "../raw/Compulife/Extraction/compulife_csvs/"
    files_raw <- list.files(files_dir)

    files_list <- list()
    i_files <- 1
    for (file_this in files_raw){
      data_this <- fread(paste0(files_dir,file_this))
      data_this$file_this <- file_this
      files_list[[i_files]] <- data_this
      i_files <- i_files + 1
    }
    data_prices_new <- do.call(rbind,files_list)
  } else if (data_level_this == "state"){
    files_dir <- "../raw/Compulife/StateLevel/"
    files_raw <- list.files(files_dir,recursive = TRUE)

    files_list <- list()
    i_files <- 1
    for (file_this in files_raw){
      data_this <- fread(paste0(files_dir,file_this))
      data_this$file_this <- file_this
      files_list[[i_files]] <- data_this
      i_files <- i_files + 1
    }
    data_prices_new <- do.call(rbind,files_list)
  } else if (data_level_this == "term"){
    data_prices_new = fread("../raw/Compulife/Extraction/Prices_CompuLife_2001_to_2021_BeforeAMBestCodeMerge.csv")
  }

  if (data_level_this %in% c("base",'state')){
      names(data_prices_new) <- c("co_name_data","product_name","price","rg","file_this")
  }

  if (data_level_this %in% c("base",'state')){
    compulife_amb_code <- fread("../raw/Compulife/Extraction/amb_names_to_codes.csv")
    compulife_amb_code <- compulife_amb_code[,V1:=NULL]
    names(compulife_amb_code) <- c("co_name_data","co_num")

    compulife_amb_code$co_name_data <- gsub("[^A-Za-z ]","",compulife_amb_code$co_name_data)
    compulife_amb_code$co_name_data <- trimws(compulife_amb_code$co_name_data,which="both")
    compulife_amb_code$co_name_data <- gsub("\\s+", " ", compulife_amb_code$co_name_data)
  } else if (data_level_this %in% c("term")){
    compulife_amb_code <- fread("../raw/Compulife/Extraction/amb_names_to_codes.csv")
    compulife_amb_code <- compulife_amb_code[,V1:=NULL]
    names(compulife_amb_code) <- c("co_name_data","co_num")

    compulife_amb_code_term <- fread("../raw/Compulife/CompuLife_Names_To_Match_To_AMBCode.csv")
    compulife_amb_code_term = compulife_amb_code_term[,c("CompanyName","amb_co_num")]
    names(compulife_amb_code_term) = c("co_name_data","co_num")

    compulife_amb_code = rbind(compulife_amb_code,compulife_amb_code_term)

    compulife_amb_code = compulife_amb_code[order(compulife_amb_code$co_name_data),]

    compulife_amb_code = compulife_amb_code[which(!is.na(compulife_amb_code$co_num)),]

    compulife_amb_code$co_name_data <- gsub("[^A-Za-z ]","",compulife_amb_code$co_name_data)
    compulife_amb_code$co_name_data <- trimws(compulife_amb_code$co_name_data,which="both")
    compulife_amb_code$co_name_data <- gsub("\\s+", " ", compulife_amb_code$co_name_data)

    compulife_amb_code = compulife_amb_code[!duplicated(compulife_amb_code),]
    compulife_amb_code_ss = compulife_amb_code %>% group_by(co_name_data) %>% summarise(num = n_distinct(co_num,na.rm=TRUE))
    if (max(compulife_amb_code_ss$num) != 1){
      stop("FAILED Check: any that have the same company text name but different AMB codes?")
    }
  }

  data_prices_new <- data_prices_new[which(!data_prices_new$co_name_data %in% c("","Company Name (Click to sort V)")),]

  data_prices_new$price <- as.numeric(gsub(",","",data_prices_new$price))
  data_prices_new <- data_prices_new[which(!is.na(data_prices_new$price)),]

  if (data_level_this == "base"){
    data_prices_new$fyear <- str_split_fixed(data_prices_new$file_this,"_",2)[,1]
    data_prices_new$quarter <- as.numeric(gsub(".csv","",str_split_fixed(data_prices_new$file_this,"_",2)[,2]))

  } else if (data_level_this == "state"){
    data_prices_new$fyear <- str_split_fixed(data_prices_new$file_this,"/",2)[,1]
    data_prices_new$quarter <- 4
    data_prices_new$state = gsub("(.*)_","",gsub(".csv","",data_prices_new$file_this))

    fwrite(data_prices_new,file="output/Compulife/Prices_Compulife_2011_2021_States.csv")

    next
  } else if (data_level_this == 'term'){
  }

  data_prices_new$co_name_data <- gsub("[^A-Za-z ]","",data_prices_new$co_name_data)
  data_prices_new$co_name_data <- trimws(data_prices_new$co_name_data,which="both")
  data_prices_new$co_name_data <- gsub("\\s+", " ", data_prices_new$co_name_data)

  data_prices_new <- as.data.table(data_prices_new)
  data_prices_new <- data_prices_new[,rg:=NULL]
  data_prices_new <- data_prices_new[,product_name:=NULL]
  data_prices_new <- data_prices_new[,file_this:=NULL]

  nobs = nrow(data_prices_new)
  data_prices_new <- merge(data_prices_new,compulife_amb_code,by=c("co_name_data"),all.x=TRUE)

  unmatched = data_prices_new[which(is.na(data_prices_new$co_num)),]

  if (data_level_this == 'base'){
    data_prices_new <- data_prices_new %>% group_by(co_num,fyear,quarter) %>% summarise(price=mean(price,na.rm=TRUE))

    data_prices_new$product = "Universal"
    data_prices_new$sex = "Male"
    data_prices_new$age = 30
    data_prices_new$type = "Life Insurance"

    data_prices_new <- data_prices_new[which(data_prices_new$fyear > 2011),]

    fwrite(data_prices_new,file="output/Compulife/Prices_Compulife_2011_2021.csv")
  } else if (data_level_this == "term") {
    data_prices_new$product_suffix = paste0(data_prices_new$FaceValue,"_",data_prices_new$Product)

    data_prices_new = data_prices_new[which(!is.na(data_prices_new$co_num)),]

    data_prices_new = data_prices_new %>% group_by(co_num,fyear,quarter,product_suffix) %>% summarise(price = mean(price,na.rm=TRUE),
                                                                                                       price_nunique = n_distinct(price,na.rm=TRUE))

    data_prices_new <- melt(
      data = data_prices_new,
      id.vars = c("co_num", "fyear", "quarter", "product_suffix"),
      measure.vars = c("price", "price_nunique"),
      variable.name = "metric"
    )

    data_prices_new <- dcast(
      data = data_prices_new,
      formula = co_num + fyear + quarter ~ metric + product_suffix,
      value.var = "value"
    )

    co_num_all = data.frame(co_num=sort(unique(data_prices_new$co_num)))
    co_num_all$x = 1
    fyear_all = data.frame(fyear=seq(2001,2021,1))
    fyear_all$x = 1
    data_prices_new_all = merge(co_num_all,fyear_all,by = c("x"),all.x=TRUE,all.y=TRUE)

    nobs = nrow(data_prices_new_all)
    data_prices_new_all = merge(data_prices_new_all,data_prices_new,by=c("co_num","fyear"),all.x=TRUE,all.y=TRUE)
    if (nobs != nrow(data_prices_new_all)){
      stop("Duplicates in merge!")
    }

    fwrite(data_prices_new_all,file="output/Compulife/Prices_Compulife_2001_2021_Term.csv")
  }
}

files_dir <- "../raw/WebAnnuities/files/"
files_raw <- list.files(files_dir)
files_raw <- files_raw[which(!grepl("certain",files_raw))]

files_list <- list()
i_files <- 1
for (file_this in files_raw){
  data_this <- fread(paste0(files_dir,file_this))
  data_this$file_this <- file_this
  files_list[[i_files]] <- data_this
  i_files <- i_files + 1
}
data_prices_new <- do.call(rbind.fill,files_list)

names(data_prices_new) <- c("date","product_name","co_name_webannuities","sex","price_LifeOnly","price_COLA","price_Guarantee10yr","price_Guarantee20yr","price_CashRefund","file_this")

fwrite(data.frame(co_name_webannuities=sort(unique(data_prices_new$co_name_webannuities))),file="../raw/WebAnnuities/amb_codes_Input.csv")
webannuities_amb_code <- fread("../raw/WebAnnuities/amb_codes.csv")
names(webannuities_amb_code) <- c("co_name_webannuities","co_num")

webannuities_amb_code$co_name_webannuities <- gsub("[^A-Za-z ]","",webannuities_amb_code$co_name_webannuities)
webannuities_amb_code$co_name_webannuities <- trimws(webannuities_amb_code$co_name_webannuities,which="both")
webannuities_amb_code$co_name_webannuities <- gsub("\\s+", " ", webannuities_amb_code$co_name_webannuities)

webannuities_amb_code <- unique(webannuities_amb_code)

data_prices_new$quarter <- str_split_fixed(str_split_fixed(data_prices_new$file_this,"-",2)[,2],"_",2)[,1]
data_prices_new$fyear <- str_split_fixed(data_prices_new$file_this,"-",2)[,1]

data_prices_new <- melt(data_prices_new, id.vars=c("date","product_name","co_name_webannuities","sex","fyear","quarter","file_this"))

data_prices_new$product <- gsub("price_","",data_prices_new$variable)

data_prices_new$sex <- mapvalues(data_prices_new$sex,
                                 from=c("M","F"),
                                 to=c("Male","Female"))

data_prices_new$age <- as.numeric(gsub("[^0-9]","",data_prices_new$product_name))

data_prices_new$type <- "Life Annuity"

data_prices_new$co_name_webannuities <- gsub("[^A-Za-z ]","",data_prices_new$co_name_webannuities)
data_prices_new$co_name_webannuities <- trimws(data_prices_new$co_name_webannuities,which="both")
data_prices_new$co_name_webannuities <- gsub("\\s+", " ", data_prices_new$co_name_webannuities)

names(data_prices_new) <- mapvalues(names(data_prices_new),
                                    from=c("value"),
                                    to=c("price"))

data_prices_new <- as.data.table(data_prices_new)
data_prices_new <- data_prices_new[,product_name:=NULL]
data_prices_new <- data_prices_new[,variable:=NULL]
data_prices_new <- data_prices_new[,file_this:=NULL]

data_prices_new$price <- gsub("\\$ |N/A","",data_prices_new$price)
data_prices_new$price <- mapvalues(data_prices_new$price,
                                   from=c(""),
                                   to=c(NA))

data_prices_new$price <- as.numeric(data_prices_new$price)

data_prices_new <- data_prices_new[which(!is.na(data_prices_new$price)),]

data_prices_new$price <- 100*(10^6)/(data_prices_new$price*12)

data_prices_new <- data_prices_new[which(data_prices_new$product %in% c("Guarantee10yr","Guarantee20yr","LifeOnly")),]

data_prices_new <- merge(data_prices_new,webannuities_amb_code,by=c("co_name_webannuities"),all.x=TRUE)

data_prices_new <- data_prices_new[which(data_prices_new$fyear > 2011),]

data_prices_new <- as.data.table(data_prices_new)
data_prices_new <- data_prices_new[order(co_num,product,sex,age,type,fyear,quarter),]

fwrite(data_prices_new,file="../raw/WebAnnuities/Prices_WebAnnuities_2011_2021.csv")


data_prices <- haven::read_dta("../raw/KY/KY_AER_2015/112888-V1/20121036_Data/Stata/data/CombinedData.dta")

data_prices_new_compulife <- fread("output/Compulife/Prices_Compulife_2011_2021.csv")

data_prices_new_compulife_2001_2021 <- fread("output/Compulife/Prices_Compulife_2001_2021_Term.csv")

data_prices_new_webannuities <- fread("../raw/WebAnnuities/Prices_WebAnnuities_2011_2021.csv")

data_prices <- rbind(as.data.table(data_prices),data_prices_new_compulife,fill=TRUE)
data_prices <- rbind(data_prices,data_prices_new_webannuities,fill=TRUE)
data_prices <- as.data.frame(data_prices)

data_prices$price <- as.numeric(data_prices$price) / 1000
data_prices$Aprice <- as.numeric(data_prices$Aprice) / 1000
data_prices$Aprice2 <- as.numeric(data_prices$Aprice2) / 1000

data_prices_cols <- names(data_prices)[which(!grepl("^_",names(data_prices)))]
data_prices <- data_prices[,data_prices_cols]

names(data_prices) <- mapvalues(names(data_prices),
                                from=c("co_num","fyear"),
                                to=c("amb_co_num","year"))

data_prices$product_sex_age_type <- gsub("[^A-Za-z0-9]","",paste0(data_prices$product,data_prices$sex,data_prices$age,data_prices$type))

data_prices_annuities <- data_prices[which(data_prices$type == "Life Annuity"),]
data_prices_annuities <- as.data.table(data_prices_annuities)[order(amb_co_num,product_sex_age_type,year,quarter),]

data_prices_annuities <- data_prices_annuities %>% group_by(amb_co_num,product_sex_age_type,year) %>% filter(row_number() == n())
data_prices_annuities <- as.data.table(data_prices_annuities)

data_prices_annuities_co_num_all <- data.frame(amb_co_num = sort(unique(data_prices_annuities$amb_co_num)))
data_prices_annuities_co_num_all$x <- 1
data_prices_annuities_year_all <- data.frame(year = sort(unique(data_prices_annuities$year)))
data_prices_annuities_year_all$x <- 1
data_prices_annuities_product_sex_age_type_all <- data.frame(product_sex_age_type = sort(unique(data_prices_annuities$product_sex_age_type)))
data_prices_annuities_product_sex_age_type_all$x <- 1
data_prices_annuities_all <- merge(data_prices_annuities_co_num_all,data_prices_annuities_year_all)
data_prices_annuities_all <- merge(data_prices_annuities_all,data_prices_annuities_product_sex_age_type_all)

data_prices_annuities_product_map <- data_prices_annuities[!duplicated(data_prices_annuities$product_sex_age_type),c("product_sex_age_type","product")]
data_prices_annuities_all <- merge(data_prices_annuities_all,data_prices_annuities_product_map,by=c("product_sex_age_type"),all.x=TRUE)

data_prices_annuities_co_num_map <- data_prices_annuities[which(!is.na(data_prices_annuities$grp_num)),] %>% group_by(amb_co_num) %>% summarise(grp_num = last(grp_num))

data_prices_annuities_all <- merge(data_prices_annuities_all,data_prices_annuities,by=c("amb_co_num","product_sex_age_type","product","year"),all.x=TRUE,all.y=TRUE)

data_prices_annuities_all <- as.data.table(data_prices_annuities_all)
data_prices_annuities_all <- data_prices_annuities_all[,grp_num:=NULL]

data_prices_annuities_all <- merge(data_prices_annuities_all,data_prices_annuities_co_num_map,by=c("amb_co_num"),all.x=TRUE)

data_prices_annuities_all <- data_prices_annuities_all %>% group_by(amb_co_num,product,year) %>% mutate(price_co_num_mean = mean(price,na.rm=TRUE))

data_prices_annuities_wide <- dcast(data_prices_annuities_all, amb_co_num + year ~ product_sex_age_type, value.var="price")

data_prices <- data_prices[which((data_prices$product_sex_age_type == "UniversalMale30LifeInsurance")),]

data_prices <- as.data.table(data_prices)[order(amb_co_num,type,year,quarter),]
data_prices <- data_prices %>% group_by(amb_co_num,type,year) %>% filter(row_number() == n())
data_prices <- as.data.table(data_prices)

data_prices_cols <- names(data_prices)[which(!grepl("^_",names(data_prices)))]
data_prices <- data_prices[,..data_prices_cols]

data_prices <- merge(data_prices,data_prices_annuities_wide,by=c("amb_co_num","year"),all.x=TRUE)

data_prices$date_month <- (as.numeric(data_prices$date) %% 12) + 1
data_prices$date_month[which(is.na(data_prices$date_month))] <- 12
data_prices$date_ymd <- as.Date(paste0(data_prices$year,"-",data_prices$date_month,"-01"))

data_actuarial <- data_prices %>% group_by(date_ymd) %>% summarise(Aprice_yq = mean(Aprice,na.rm=TRUE),
                                                                   Aprice2_yq = mean(Aprice2,na.rm=TRUE),
                                                                   Aprice_nunique = n_distinct(Aprice,na.rm=TRUE),
                                                                   Aprice2_nunique = n_distinct(Aprice2,na.rm=TRUE))

data_actuarial <- as.data.table(data_actuarial)[order(date_ymd),]

data_actuarial$Aprice_yq[which(is.na(data_actuarial$Aprice_yq))] <- NA
data_actuarial$Aprice2_yq[which(is.na(data_actuarial$Aprice2_yq))] <- NA

data_actuarial <- data_actuarial %>% fill(Aprice_yq, .direction = "down")
data_actuarial <- data_actuarial %>% fill(Aprice2_yq, .direction = "down")

data_actuarial <- data_actuarial[,Aprice_nunique:=NULL]
data_actuarial <- data_actuarial[,Aprice2_nunique:=NULL]

data_prices <- merge(data_prices,data_actuarial,by=c("date_ymd"),all.x=TRUE)

data_prices$V <- median(data_prices$Aprice,na.rm=TRUE)
data_prices$price_dollars <- data_prices$price
data_prices$price <- data_prices$price_dollars / data_prices$V

names(data_prices) <- mapvalues(names(data_prices),
                                from=c("price","price_dollars","V"),
                                to=c("price_Universal","price_dollars_Universal","V_Universal"))

data_prices_ss = data_prices %>% group_by(amb_co_num,year) %>% summarise(num = n())
if (max(data_prices_ss$num) > 1){
  stop("FAILED Check: Is data_prices unique at amb_co_num by year level?")
}

names(data_prices_new_compulife_2001_2021) <- mapvalues(names(data_prices_new_compulife_2001_2021),
                                from=c("co_num","fyear"),
                                to=c("amb_co_num","year"))

products_yq_all_wide = dcast(products_yq_all, yq ~ product, value.var = "npv")
products_yq_all_wide = products_yq_all_wide[,c("yq",10,30)]
names(products_yq_all_wide) = c("yq","V_250KFaceValue_10YearLevelTermGuaranteed","V_250KFaceValue_30YearLevelTermGuaranteed")

products_yq_all_wide$year = year(products_yq_all_wide$yq)
products_yq_all_wide = products_yq_all_wide[which(month(products_yq_all_wide$yq) == 12),]

products_yq_all_wide$V_1MFaceValue_10YearLevelTermGuaranteed = 4 * products_yq_all_wide$V_250KFaceValue_10YearLevelTermGuaranteed
products_yq_all_wide$V_1MFaceValue_30YearLevelTermGuaranteed = 4 * products_yq_all_wide$V_250KFaceValue_30YearLevelTermGuaranteed

nobs = nrow(data_prices_new_compulife_2001_2021)
data_prices_new_compulife_2001_2021 = merge(data_prices_new_compulife_2001_2021,products_yq_all_wide,by=c("year"),all.x=TRUE)
if (nobs != nrow(data_prices_new_compulife_2001_2021)){
  stop("Duplicates in merge!")
}

data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed / 1000
data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed / 1000
data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed / 1000
data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed / 1000

data_prices_new_compulife_2001_2021$V_1MFaceValue_10YearLevelTermGuaranteed = mean(data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed,na.rm=TRUE)
data_prices_new_compulife_2001_2021$V_1MFaceValue_30YearLevelTermGuaranteed = mean(data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed,na.rm=TRUE)
data_prices_new_compulife_2001_2021$V_250KFaceValue_10YearLevelTermGuaranteed = mean(data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed,na.rm=TRUE)
data_prices_new_compulife_2001_2021$V_250KFaceValue_30YearLevelTermGuaranteed = mean(data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed,na.rm=TRUE)

data_prices_new_compulife_2001_2021$price_dollars_1MFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_dollars_1MFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_dollars_250KFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_dollars_250KFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed

data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_10YearLevelTermGuaranteed / data_prices_new_compulife_2001_2021$V_1MFaceValue_10YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_1MFaceValue_30YearLevelTermGuaranteed / data_prices_new_compulife_2001_2021$V_1MFaceValue_30YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_10YearLevelTermGuaranteed / data_prices_new_compulife_2001_2021$V_250KFaceValue_10YearLevelTermGuaranteed
data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed = data_prices_new_compulife_2001_2021$price_250KFaceValue_30YearLevelTermGuaranteed / data_prices_new_compulife_2001_2021$V_250KFaceValue_30YearLevelTermGuaranteed

amb_co_num_all = fread("../raw/AMBest/AMBest_ID.csv")

amb_co_num_all_universal = fread("../raw/Compulife/Extraction/amb_names_to_codes.csv")
names(amb_co_num_all_universal) = c("V1","amb_co_name","amb_co_num")
amb_co_num_all_universal_ky = haven::read_dta("../raw/KY/KY_AER_2015/112888-V1/20121036_Data/Stata/data/CombinedData.dta")
amb_co_num_all_universal_ky = amb_co_num_all_universal_ky[,c("co_num","co_name")]
names(amb_co_num_all_universal_ky) = c("amb_co_num","amb_co_name")

amb_co_num_all_term = fread("../raw/Compulife/CompuLife_Names_To_Match_To_AMBCode.csv")
amb_co_num_all_term = amb_co_num_all_term[,c("amb_co_num","CompanyName")]
names(amb_co_num_all_term) = c("amb_co_num","amb_co_name")

amb_co_num_all = rbind(amb_co_num_all,
                       amb_co_num_all_universal,
                       amb_co_num_all_universal_ky,
                       amb_co_num_all_term,
                       fill=TRUE)

amb_co_num_all = amb_co_num_all[!duplicated(amb_co_num_all$amb_co_num),c("amb_co_num","amb_co_name")]

amb_co_num_all$x = 1
year_all = data.frame(year=seq(2001,2021,1))
year_all$x = 1
data_prices_all = merge(amb_co_num_all,year_all,by = c("x"),all.x=TRUE,all.y=TRUE,allow.cartesian = TRUE)
nobs = nrow(data_prices_all)

data_prices_all = merge(data_prices_all,data_prices,by=c("amb_co_num","year"),all.x=TRUE,all.y=TRUE)
if (nobs != nrow(data_prices_all)){
  stop("Duplicates in merge!")
}

data_prices_all = merge(data_prices_all,data_prices_new_compulife_2001_2021,by=c("amb_co_num","year"),all.x=TRUE,all.y=TRUE)
if (nobs != nrow(data_prices_all)){
  stop("Duplicates in merge!")
}

data_prices_all$price = data_prices_all$price_250KFaceValue_10YearLevelTermGuaranteed
data_prices_all$price_dollars = data_prices_all$price_dollars_250KFaceValue_10YearLevelTermGuaranteed
data_prices_all$V = data_prices_all$V_250KFaceValue_10YearLevelTermGuaranteed

data_prices_all$age = 30
data_prices_all$sex = "Male"
data_prices_all$type = "Life Insurance"

fwrite(data_prices_all,file="output/CompuLife_All.csv")

files_all = list.files("../raw/Compulife/Pre2005/DataFromWin98Software_530Files/")
files_all = files_all[which(!grepl(".PDF",files_all))]
txt="SUMMARY OF OTHER COMPANIES SURVEYED"

i_file = 1
df_list = list()
for (file_this in files_all){
  f = paste0("../raw/Compulife/Pre2005/DataFromWin98Software_530Files/",file_this)

  rows <- readLines(f)

  df <- data.frame(CompanyName=character(),
                   Product=character(),
                   Price=numeric(),
                   CurrentGuaranteed=character(),
                   stringsAsFactors=FALSE)
  flag<-0
  i<-1
  while (i < length(rows)){
    if(str_detect(rows[i], txt))
      break
    if(flag==0 && startsWith(rows[i], "____________________________")){
      i=i+1
      if (trimws(rows[i])=='.'){
        i=i+1
        flag=1
        next
      }
    }

    if (flag==1){
      names=str_split(rows[i],n=2, "  \\.  ")
      i=i+1
      products=str_split(rows[i],n=2, "  \\.  ")
      i=i+1
      flag=2
      next
    }
    if(flag==2){
      if(str_detect(rows[i], 'Guranteed') || str_detect(rows[i],'Current') || str_detect(rows[i], 'Guaranteed') ){
        parts=str_split(rows[i], n=2, "  \\.  ")
        i=i+1
        flag=3
        next
      }
    }
    if (flag==3){
      if(str_detect(rows[i], 'Age 30')){
        ages<-str_split(rows[i],' \\. ')
        price1<-str_split(trimws(ages[[1]][1]),'Age 30')
        price2<-str_split(trimws(ages[[1]][2]),'Age 30')

        df<-rbind(df, c(names[[1]][1],products[[1]][1],as.numeric(price1[[1]][2]), trimws(parts[[1]][1])))
        df<-rbind(df, c(names[[1]][2],products[[1]][2],as.numeric(price2[[1]][2]), trimws(parts[[1]][2])))
        i=i+1
        flag=0
        next
      }
    }
    i=i+1
  }

  i<-i+3
  while (i < length(rows)){
    if(trimws(rows[i])=='')
      break
    rows[i]<-str_replace(rows[i], 'U.S.', 'U_S')
    items<-str_split(rows[i],'\\. ')
    price<-str_split(items[[1]][length(items[[1]])], 'Rg')
    name<-str_replace(items[[1]][1],'U_S', "U.S.")
    row<-c(name, '',as.numeric(price[[1]][1]), 'CurrentGuaranteed')
    df<-rbind(df, row)
    i<-i+1
  }

  names(df)<-c('CompanyName', 'Product', 'Price','CurrentGuaranteed')

  df$file = file_this

  df_list[[i_file]] = df
  i_file = i_file + 1
}
df_all = do.call(rbind,df_list)

df_all$CompanyName = gsub(" Rg","",df_all$CompanyName)
df_all$CompanyName = trimws(df_all$CompanyName, which="both")

df_all$Price = as.numeric(df_all$Price)
df_all = df_all %>% group_by(CompanyName,file) %>% summarise(Price = mean(Price,na.rm=TRUE))

df_all$file = gsub("\\.(.*)$","",df_all$file)
df_all$year = str_split_fixed(df_all$file,"_",3)[,1]
df_all$quarter = str_split_fixed(df_all$file,"_",3)[,2]
df_all$product = str_split_fixed(df_all$file,"_",3)[,3]

fwrite(df_all,file="output/CompuLife_Pre2005_All.csv")

df_all$Price_NPV = df_all$Price

products_yq_all$product = paste0(products_yq_all$product,"YearsGuaranteedOnly")
products_yq_all$year = year(products_yq_all$yq)
products_yq_all$quarter = str_pad(month(products_yq_all$yq),2,pad="0")

products_yq_all$actuarialvalue_npv = products_yq_all$npv
products_yq_all = products_yq_all[,c("product","year","quarter","actuarialvalue_npv")]


df_all$i = seq(1,nrow(df_all),1)
df_all = merge(df_all,products_yq_all,by=c("product","year","quarter"),all.x=TRUE)
df_all = df_all[order(df_all$i),]

df_all = as.data.table(df_all)[,i:=NULL]

df_all$markup_npv = df_all$Price_NPV / df_all$actuarialvalue_npv - 1

fwrite(df_all,file="output/CompuLife_Pre2005_All.csv")

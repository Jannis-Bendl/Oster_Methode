source("../lib/r/Functions.R")

cleanSNLfiles <- function(data,filetype){

  if (filetype %in% c("InsuranceStatutoryFinancials","MarketShare","ReinsuranceRelationships")){
    col_names <- as.data.frame(t(data[1:2,]))
    col_names[(is.na(col_names))] <- ""
    col_names <- paste0(col_names$V1,col_names$V2,sep="")
    col_names <- gsub("[^A-Za-z0-9]","",col_names)
  }
  if (filetype %in% c("ReinsuranceRelationshipsRatings")){
    col_names <- as.data.frame(t(data[1:2,]))
    col_names[(is.na(col_names))] <- ""
    col_names <- toupper(row.names(col_names))
    col_names <- gsub("[^A-Za-z0-9]","",col_names)
  }
  if (filetype %in% c("Companies")){
    col_names <- as.data.frame(t(data[1:2,]))
    col_names[(is.na(col_names))] <- ""
    col_names <- paste0(col_names$V1,col_names$V2,sep="")
    col_names <- gsub("[^A-Za-z0-9]","",col_names)

    col_names <- mapvalues(col_names,
                           from=c("SPENTITYNAME","SPSNLSTATENTITYKEY"),
                           to=c("ENTITYNAME","SNLSTATENTITYKEY"))
  }
  if (filetype %in% c("InsuranceStatutoryFinancials_Supplement","ReinsuranceRelationships_Supplement")){
    col_names <- as.data.frame(t(data[c(1,2,3),]))
    col_names[(is.na(col_names))] <- ""
    col_names <- paste0(col_names$V1,col_names$V2,col_names$V3,sep="")
    col_names <- gsub("[^A-Za-z0-9]","",col_names)
  }

  colnames(data) <- col_names

  cols.y <- colnames(data)[which(grepl("\\.y",colnames(data)))]
  if (length(cols.y) > 0){
    data <- as.data.table(data)[,(cols.y):=NULL]
    colnames(data) <- gsub("\\.x","",colnames(data))
  }

  data.headers <- gsub("s000","s",colnames(data))
  data.headers <- gsub("[^[:alnum:]]","",data.headers)
  data.headers <- gsub("Y000|Ymddyyyy|Ymdyyyy|YesNo","",data.headers)
  data.headers <- sub("Y$|Yactual$|actual$|mdyyyy$|[A-Za-z]000$", "", data.headers)
  data.headers <- sub("MstRctYear","MstRctYea",data.headers)
  data.headers <- sub("MstRctQtr","MstRctQt",data.headers)

  if (filetype %in% c("InsuranceStatutoryFinancials_Supplement","ReinsuranceRelationships_Supplement")){
    year.headers = gsub(".*(\\d{4}Y).*","\\1",data.headers)
    year.headers = gsub("Y","",year.headers)
    data.headers = gsub("\\d{4}Y","",data.headers)

    data.headers = gsub("NAIC12016$","NAICOneTwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC22016$","NAICTwoTwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC32016$","NAICThreeTwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC42016$","NAICFourTwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC52016$","NAICFiveTwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC62016$","NAICSixTwoThousandSixteen",data.headers)
    data.headers = gsub("2014$","TwoThousandFourteen",data.headers)
    data.headers = gsub("2015$","TwoThousandFifteen",data.headers)
    data.headers = gsub("2016$","TwoThousandSixteen",data.headers)
    data.headers = gsub("NAIC1$","NAICOne",data.headers)
    data.headers = gsub("NAIC2$","NAICTwo",data.headers)
    data.headers = gsub("NAIC3$","NAICThree",data.headers)
    data.headers = gsub("NAIC4$","NAICFour",data.headers)
    data.headers = gsub("NAIC5$","NAICFive",data.headers)
    data.headers = gsub("NAIC6$","NAICSix",data.headers)

    data.headers = paste0(data.headers,year.headers)
  }

  data.headers <- gsub("3to6","ThreeToSix",data.headers)
  data.headers <- gsub("120","OneHundredTwenty",data.headers)
  data.headers <- gsub("1Y","OneY",data.headers)

  data.headers <- sub("MstRctYea","9998",data.headers)
  data.headers <- sub("MstRctQt","9999",data.headers)

  if (filetype %in% c("InsuranceStatutoryFinancials","MarketShare","Companies")){
    data.headers <- mapvalues(data.headers,
                              from=c("SNLSTATENTITYKE","SNLGROUPSTATENTITYKE"),
                              to=c("SNLSTATENTITYKEY","SNLGROUPSTATENTITYKEY"))
    data.headers <- mapvalues(data.headers,
                              from=c("SPStatutoryEntityKey","EntityName"),
                              to=c("SNLSTATENTITYKEY","ENTITYNAME"))
  }
  if (filetype %in% c("InsuranceStatutoryFinancials_Supplement")){
    data.headers <- mapvalues(data.headers,
                              from=c("SNLSTATENTITYKESNLSTATENTITKE","ENTITYNAMEENTITNAME"),
                              to=c("SNLSTATENTITYKEY","ENTITYNAME"))
  }
  if (filetype %in% c("ReinsuranceRelationships")){
    data.headers <- mapvalues(data.headers,
                              from=c("CEDENTSNLSTATENTITYKE","REINSSNLSTATENTITYKE"),
                              to=c("CEDENTSNLSTATENTITYKEY","REINSSNLSTATENTITYKEY"))
  }
  if (filetype %in% c("ReinsuranceRelationships_Supplement")){
    data.headers <- mapvalues(data.headers,
                              from=c("CEDENTREINSCEDENTREINS","REINSRECONCILEOIDREINSRECONCILEOID"),
                              to=c("CEDENTREINS","REINSRECONCILEOID"))
  }

  colnames(data) <- data.headers

  if (filetype %in% c("InsuranceStatutoryFinancials","InsuranceStatutoryFinancials_Supplement","MarketShare")){
    data <- data[which(!is.na(data$ENTITYNAME) & !is.na(data$SNLSTATENTITYKEY)),]
  }
  if (filetype %in% c("Companies")){
    data <- data[which(!is.na(data$ENTITYNAME)),]
  }
  if (filetype %in% c("ReinsuranceRelationships","ReinsuranceRelationshipsClass","ReinsuranceRelationships_Supplement")){
    data <- data[which(!is.na(data$CEDENTREINS)),]
  }

  if ("CrossSectorDirectPremiumsWritten9998" %in% colnames(data)){
    data <- as.data.table(data)[,CrossSectorDirectPremiumsWritten9998:=NULL]
  }

  return(data)
}

reshapeSNLfiles <- function(data,filetype){
  if (filetype %in% c("InsuranceStatutoryFinancials","MarketShare","Companies")){
    data <- melt(data, id.vars=c("ENTITYNAME","SNLSTATENTITYKEY"))
  }
  if (filetype %in% c("ReinsuranceRelationships","ReinsuranceRelationshipsClass")){
    data <- melt(data, id.vars=c("CEDENTREINS","REINSRECONCILEOID"))
    data <- data[which(data$variable != "EFFECTIVEDATE"),]
  }

  data$year <- gsub("[^0-9]","",data$variable)
  data$variable <- gsub("[^A-Za-z]","",data$variable)

  data$value[which(data$value == "NA")] <- NA
  if (filetype %in% c("ReinsuranceRelationshipsClass")){
  }else{
    data$value = mapvalues(data$value,
                           from=c("No","Yes"),
                           to=c(0,1))
    data$value = gsub("[^0-9.]","",data$value)
    data$value <- as.numeric(as.character(data$value))
  }

  if (filetype == "Companies"){
    data <- data[which(!is.na(data$value)),]
    data <- data %>% group_by(ENTITYNAME,SNLSTATENTITYKEY,year) %>% mutate(dup = n())
    dup_frac <- nrow(data[which(data$dup > 1),]) / nrow(data)
    if (dup_frac > 0.01){
      stop("FAILED Check: not many duplicates in the Companies debt database.")
    }
    data <- data[which(data$dup <= 1),]
    data <- as.data.table(data)
    data <- data[,dup:=NULL]
  }

  if (filetype %in% c("InsuranceStatutoryFinancials","MarketShare","Companies")){
    data <- dcast(data, ENTITYNAME + SNLSTATENTITYKEY + year ~ variable, value.var = "value")
  }
  if (filetype %in% c("ReinsuranceRelationships","ReinsuranceRelationshipsClass")){
    data <- dcast(data, CEDENTREINS + REINSRECONCILEOID + year ~ variable, value.var = "value")
  }

  return(data)
}

cleanMarketSharePart <- function(data_quantity_this,num_part_this,part_start,part_end){
  part_this <- data_quantity_this[part_start:part_end,]

  lob_this <- part_this[2,2]

  state_this <- part_this[3,2]

  part_this <- part_this[4:nrow(part_this),]

  names(part_this) <- seq(1:ncol(part_this))

  part_this <- part_this %>% mutate(across(everything(), as.character))
  part_this <- as.data.table(part_this)

  part_this <- as.matrix(part_this)

  test <- t(na.locf0(t(part_this[5,])))
  test[1:3] <- c("id","SNLSTATENTITYKEY","ENTITYNAME")
  part_this[5,] <- test

  part_this <- as.data.table(part_this)

  part_this <- part_this[5:nrow(part_this),]

  part_this <- cleanSNLfiles(part_this,filetype)

  part_this[ ,c("id","Assets","CapitalSurplus")] <- list(NULL)

  part_this <- reshapeSNLfiles(part_this,filetype)

  part_this$state <- unlist(state_this)
  part_this$lob <- unlist(lob_this)

  return(part_this)
}

filetype = "InsuranceStatutoryFinancials"

data_basic_info <- readxl::read_xls("../raw/SNL/SNL_Life_Basic_Information_Company.xls",skip = 0)
data_basic_info_group <- readxl::read_xls(("../raw/SNL/SNL_Life_Basic_Information_Company_with_GroupNames.xls"),skip = 0)
data_basic_info_nonlife <- readxl::read_xls("../raw/SNL/SNL_NonLife_Basic_Information_Company.xls",skip = 0)
data_basic_info_nonlife_state = readxl::read_xls(("../raw/SNL/SNL_NonLife_Basic_Information_Group_Domicile.xls"),skip = 0)

data_basic_info_alllevels <- readxl::read_xls(("../raw/SNL/SNL_Basic_Information_AllLevels_2024.xls"),skip = 0)

data_basic_info <- cleanSNLfiles(data_basic_info_nonlife,filetype)
data_basic_info_group <- cleanSNLfiles(data_basic_info_group,filetype)
data_basic_info_nonlife_state <- cleanSNLfiles(data_basic_info_nonlife_state,filetype)

data_basic_info_alllevels <- cleanSNLfiles(data_basic_info_alllevels,filetype)

data_basic_info <- as.data.table(data_basic_info)[,STATE:=NULL]
data_basic_info_group <- as.data.table(data_basic_info_group)[,STATE:=NULL]
data_basic_info <- as.data.table(data_basic_info)[,STATEDOMICILED:=NULL]
data_basic_info_nonlife_state <- as.data.table(data_basic_info_nonlife_state)[,ENTITYNAME:=NULL]

data_basic_info <- as.data.frame(data_basic_info)
data_basic_info_alllevels <- as.data.frame(data_basic_info_alllevels)

data_basic_info_all <- data_basic_info
data_basic_info <- data_basic_info[,c("SNLSTATENTITYKEY","SNLGROUPSTATENTITYKEY","STATEINCORP")]
data_basic_info$SNLTOPENTITYKEY <- data_basic_info$SNLGROUPSTATENTITYKEY
data_basic_info$SNLTOPENTITYKEY[which(is.na(data_basic_info$SNLGROUPSTATENTITYKEY))] <- data_basic_info$SNLSTATENTITYKEY[which(is.na(data_basic_info$SNLGROUPSTATENTITYKEY))]

data_basic_info_group$SNLTOPENTITYKEY <- data_basic_info_group$SNLGROUPSTATENTITYKEY
data_basic_info_group$SNLTOPENTITYKEY[which(is.na(data_basic_info_group$SNLGROUPSTATENTITYKEY))] <- data_basic_info_group$SNLSTATENTITYKEY[which(is.na(data_basic_info_group$SNLGROUPSTATENTITYKEY))]

data_basic_info_alllevels$SNLTOPENTITYKEY <- data_basic_info_alllevels$SNLGROUPSTATENTITYKEY
data_basic_info_alllevels$SNLTOPENTITYKEY[which(is.na(data_basic_info_alllevels$SNLGROUPSTATENTITYKEY))] <- data_basic_info_alllevels$SNLSTATENTITYKEY[which(is.na(data_basic_info_alllevels$SNLGROUPSTATENTITYKEY))]

data_basic_info_alllevels$SNLTOPENTITYNAME <- data_basic_info_alllevels$SNLGROUPNAME
data_basic_info_alllevels$SNLTOPENTITYNAME[which(is.na(data_basic_info_alllevels$SNLGROUPNAME))] <- data_basic_info_alllevels$ENTITYNAME[which(is.na(data_basic_info_alllevels$SNLGROUPNAME))]

names(data_basic_info_nonlife_state) = c("SNLTOPENTITYKEY","TOPENTITY_STATEDOMICILED","TOPENTITY_STATE")

fwrite(data_basic_info_nonlife_state,file="output/SNL_Geography.csv")

data_corporate_info = readxl::read_xls("../raw/SNL/SNL_Basic_Information_AllLevels_2024.xls",skip = 0)
data_corporate_info <- cleanSNLfiles(data_corporate_info,filetype)

exclude_columns <- c("ENTITYNAME","NAICCOMPANYCODE","NAICGROUPNUM","GROUP","SNLGROUPNAME","SNLGROUPSTATENTITYKEY")
data_corporate_info <- data_corporate_info %>% select(-all_of(exclude_columns))

data_corporate_info = as.data.frame(data_corporate_info)

for (i in seq(1,nrow(data_corporate_info),1)){
  data_corporate_info$DATEESTABLISHED[i] = as.Date(convert_excel_date(data_corporate_info$DATEESTABLISHED[i]))
  data_corporate_info$DATEINCORPORATED[i] = as.Date(convert_excel_date(data_corporate_info$DATEINCORPORATED[i]))
}
data_corporate_info$DATEESTABLISHED = as.Date(as.numeric(data_corporate_info$DATEESTABLISHED))
data_corporate_info$DATEINCORPORATED = as.Date(as.numeric(data_corporate_info$DATEINCORPORATED))

data_corporate_info$STATE_is_ny = as.numeric(data_corporate_info$STATE == "NY")

data_corporate_info$FHLBMEMBERBANK_is_true = as.numeric((data_corporate_info$FHLBMEMBERBANK != "") & (!is.na(data_corporate_info$FHLBMEMBERBANK)))

data <- readxl::read_xls(("../raw/SNL/SNL_Life_Financials_Company_with_2021.xls"),skip = 0)
data_group <- readxl::read_xls(("../raw/SNL/SNL_Life_Financials_Group_with_2021.xls"),skip = 0)
data_group_2 <- readxl::read_xls(("../raw/SNL/SNL_Life_Financials_Group_2_with_2021.xls"),skip = 0)

data <- cleanSNLfiles(data,filetype)
data_group <- cleanSNLfiles(data_group,filetype)
data_group_2 <- cleanSNLfiles(data_group_2,filetype)

data <- reshapeSNLfiles(data,filetype)
data_group <- reshapeSNLfiles(data_group,filetype)
data_group_2 <- reshapeSNLfiles(data_group_2,filetype)

data_group <- merge(data_group,data_group_2,by=c("ENTITYNAME","SNLSTATENTITYKEY","year"),all.x=TRUE)

data$TOTALLIAB_ln <- log(data$TOTALLIAB+1)
data_group$TOTALLIAB_ln <- log(data_group$TOTALLIAB+1)

data$LEVERAGE <- data$TOTALLIAB / data$TOTALASSETS
data_group$LEVERAGE <- data_group$TOTALLIAB / data_group$TOTALASSETS

data$AUTHCONTROLLEVELRISKBASEDCAPRATIO <- data$AUTHCONTROLLEVELRISKBASEDCAPRATIO / 100
data$CASHSTINVESTTOLIAB <- data$CASHSTINVESTTOLIAB / 100
data$ROAECAPSURPLUS <- data$ROAECAPSURPLUS / 100

data_group$AUTHCONTROLLEVELRISKBASEDCAPRATIO <- data_group$AUTHCONTROLLEVELRISKBASEDCAPRATIO / 100
data_group$CASHSTINVESTTOLIAB <- data_group$CASHSTINVESTTOLIAB / 100
data_group$ROAECAPSURPLUS <- data_group$ROAECAPSURPLUS / 100

data <- data[which(data$year < 2030),]
data_group <- data_group[which(data_group$year < 2030),]

data_corporate_info_group = merge(data_corporate_info,data_basic_info[,c("SNLSTATENTITYKEY","SNLTOPENTITYKEY")],by=c("SNLSTATENTITYKEY"),all.x=TRUE)
data_corporate_info_group$SNLTOPENTITYKEY[which(is.na(data_corporate_info_group$SNLTOPENTITYKEY))] = data_corporate_info_group$SNLSTATENTITYKEY[which(is.na(data_corporate_info_group$SNLTOPENTITYKEY))]

mode_func <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
safe_min <- function(x) {
  x_nonmiss <- x[!is.na(x)]
  if (length(x_nonmiss) == 0) return(NA)
  min(x_nonmiss)
}
safe_max <- function(x) {
  x_nonmiss <- x[!is.na(x)]
  if (length(x_nonmiss) == 0) return(NA)
  max(x_nonmiss)
}
clean_phrase <- function(phrase) {
  gsub("[^A-Za-z0-9]", "", phrase)
}
summarize_by_id <- function(data, id, vars_mode = c(), vars_min = c(), vars_max = c(), vars_concat = c()) {
  data_summarized <- data %>%
    group_by(across(all_of(id))) %>%
    summarise(
      group_numsubsidiaries = n(),
      
      across(all_of(vars_mode), mode_func, .names = "{.col}"),
      
      across(all_of(vars_min), safe_min, .names = "{.col}"),
      
      across(all_of(vars_max), safe_max, .names = "{.col}"),
      
      across(all_of(vars_concat), ~paste0(unique(.x[!is.na(.x)]), collapse = ", "), .names = "{.col}"),
      
      .groups = "drop"
    )
  
  if ("BUSINESSFOCUS" %in% vars_concat) {
    unique_phrases <- data %>%
      filter(!is.na(BUSINESSFOCUS) & BUSINESSFOCUS != "") %>%
      pull(BUSINESSFOCUS) %>%
      strsplit(", ") %>%
      unlist() %>%
      unique() %>%
      sort()

    unique_phrases_clean <- sapply(unique_phrases, clean_phrase, USE.NAMES = FALSE)

    businessfocus_list <- strsplit(data_summarized$BUSINESSFOCUS, ", ")
    businessfocus_list_clean <- lapply(businessfocus_list, function(x) sapply(x, clean_phrase, USE.NAMES = FALSE))

    dummy_df <- data.frame(matrix(0, nrow = nrow(data_summarized), ncol = length(unique_phrases_clean)))
    colnames(dummy_df) <- paste0("BUSINESSFOCUS_", unique_phrases_clean)

    for (i in seq_along(businessfocus_list_clean)) {
      present_phrases <- businessfocus_list_clean[[i]]

      dummy_df[i, ] <- as.integer(unique_phrases_clean %in% present_phrases)
    }

    data_summarized <- cbind(data_summarized, dummy_df)
  }

  return(data_summarized)
}

data_corporate_info_group <- summarize_by_id(
  data = data_corporate_info_group,
  id = "SNLTOPENTITYKEY",
  vars_mode = c("TICKER","SECSEXCHANGE","ULTPARENTSECSEXCHANGE","CUSIP"),
  vars_min = c("DATEESTABLISHED","DATEINCORPORATED"),
  vars_max = c("FHLBMEMBERBANK_is_true","STATE_is_ny"),
  vars_concat = c("STATE","COUNTRYINCORP","STATEDOMICILED","COUNTRYDOMICILED","STATEINCORP","BUSINESSFOCUS","DISTCHANNEL","PROFESSIONALFIRMAuditor","PROFESSIONALFIRMActuary","NAICOWNSTRUCTURE")
)

data_corporate_info_group$FHLBMEMBERBANK_is_true = as.numeric((data_corporate_info_group$FHLBMEMBERBANK_is_true >= 1) & (!is.na(data_corporate_info_group$FHLBMEMBERBANK_is_true)))
data_corporate_info_group$STATE_is_ny = as.numeric((data_corporate_info_group$STATE_is_ny >= 1) & (!is.na(data_corporate_info_group$STATE_is_ny)))
data_corporate_info_group$NAICOWNSTRUCTURE_is_mutual = as.numeric((data_corporate_info_group$NAICOWNSTRUCTURE == "Mutual Company"))
data_corporate_info_group$NAICOWNSTRUCTURE_is_mutual_any = as.numeric((grepl("Mutual Company",data_corporate_info_group$NAICOWNSTRUCTURE)))

names(data_corporate_info_group) <- mapvalues(names(data_corporate_info_group),from=c("SNLTOPENTITYKEY"),to=c("SNLSTATENTITYKEY"))

nobs = nrow(data_group)
data_group = merge(data_group,data_corporate_info_group,by=c("SNLSTATENTITYKEY"),all.x=TRUE)
if (nobs != nrow(data_group)){
  stop("Duplicates in merge in basic info!")
}

data_corporate_info = as.data.table(data_corporate_info)[,NAICOWNSTRUCTURE:=NULL]
data_corporate_info = as.data.table(data_corporate_info)[,STATEINCORP:=NULL]

nobs = nrow(data)
data = merge(data,data_corporate_info,by=c("SNLSTATENTITYKEY"),all.x=TRUE)
if (nobs != nrow(data)){
  stop("Duplicates in merge in basic info!")
}

data$age = as.numeric(data$year) - year(data$DATEESTABLISHED)
data$age_ln = log(data$age + 1)
data_group$age = as.numeric(data_group$year) - year(data_group$DATEESTABLISHED)
data_group$age_ln = log(data_group$age + 1)

if ((mean(is.na(data_group$FHLBMEMBERBANK_is_true)) > 0.01) | (mean(is.na(data_group$DATEESTABLISHED)) > 0.10) | (mean(is.na(data_group$age)) > 0.10)){
  stop("FAILED Check: no missing values for corporate info?")
}

filetype = "ReinsuranceRelationships"

data_reins_info_1 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_1.xls")
data_reins_info_2 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_2.xls")
data_reins_info_3 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_3.xls")
data_reins_info_4 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_4.xls")
data_reins_info_5 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_5.xls")

data_reins_info_1 <- cleanSNLfiles(data_reins_info_1,filetype)
data_reins_info_2 <- cleanSNLfiles(data_reins_info_2,filetype)
data_reins_info_3 <- cleanSNLfiles(data_reins_info_3,filetype)
data_reins_info_4 <- cleanSNLfiles(data_reins_info_4,filetype)
data_reins_info_5 <- cleanSNLfiles(data_reins_info_5,filetype)

data_reins_info <- do.call(rbind,list(data_reins_info_1,data_reins_info_2,data_reins_info_3,data_reins_info_4,data_reins_info_5))

data_entity <- data_basic_info[,c("SNLSTATENTITYKEY","SNLTOPENTITYKEY")]
data_entity_cedent <- data_entity
data_entity_reins <- data_entity
names(data_entity_cedent) <- paste0("CEDENT",names(data_entity_cedent))
names(data_entity_reins) <- paste0("REINS",names(data_entity_reins))

data_reins_info <- merge(data_reins_info,data_entity_cedent,by=c("CEDENTSNLSTATENTITYKEY"),all.x=TRUE)
data_reins_info <- merge(data_reins_info,data_entity_reins,by=c("REINSSNLSTATENTITYKEY"),all.x=TRUE)

filetype = "ReinsuranceRelationships"

files_all <- list.files("../raw/SNL/ReinsuranceRelationships")
files_all <- files_all[which(grepl(".xls$",files_all) & !grepl("BasicInfo|ParentNames",files_all))]

data_reins_all <- list()
i <- 1

for (file_this in files_all){
  data_this <- readxl::read_xls(paste0("../raw/SNL/ReinsuranceRelationships/",file_this),skip=0)

  data_this <- cleanSNLfiles(data_this,filetype)

  data_this <- reshapeSNLfiles(data_this,filetype)

  data_reins_all[[i]] <- data_this
  i =  i+1
}
data_reins_all_out <- do.call(rbind,data_reins_all)

data_this_20220222 <- fread("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_missing_20220222.csv",skip=0)

data_this_20220222 <- cleanSNLfiles(data_this_20220222,filetype)

data_this_20220222 <- data_this_20220222[which(data_this_20220222$REINSRECONCILEOID != ""),]

data_this_20220222 <- reshapeSNLfiles(data_this_20220222,filetype)

data_reins_all_out <- rbind(data_reins_all_out,
                            data_this_20220222)

data_reins_all_out <- as.data.table(data_reins_all_out)[!duplicated(data_reins_all_out),]
data_reins_all_out <- data_reins_all_out[order(REINSRECONCILEOID,year),]

data_reins_all_out <- data_reins_all_out[,CEDENTREINS:=NULL]

data_reins_parents_1 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_1.xls")
data_reins_parents_2 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_2.xls")
data_reins_parents_3 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_3.xls")
data_reins_parents_4 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_4.xls")

data_reins_parents_1 <- cleanSNLfiles(data_reins_parents_1,filetype)
data_reins_parents_2 <- cleanSNLfiles(data_reins_parents_2,filetype)
data_reins_parents_3 <- cleanSNLfiles(data_reins_parents_3,filetype)
data_reins_parents_4 <- cleanSNLfiles(data_reins_parents_4,filetype)

data_reins_parents <- do.call(rbind,list(data_reins_parents_1,
                                         data_reins_parents_2,
                                         data_reins_parents_3,
                                         data_reins_parents_4))

data_reins_parents <- data_reins_parents[!duplicated(data_reins_parents$REINSRECONCILEOID),]

data_reins_parents <- data_reins_parents[,c("CEDENTREINS","REINSRECONCILEOID","CEDENTULTPARENTNAME","REINSULTPARENTNAME")]

files_all <- list.files("../raw/SNL/ReinsuranceRelationships/Class")

data_reins_class_all <- list()
i <- 1

for (file_this in files_all){
  data_this <- readxl::read_xls(paste0("../raw/SNL/ReinsuranceRelationships/Class/",file_this),skip=0)

  filetype = "ReinsuranceRelationships"
  data_this <- cleanSNLfiles(data_this,filetype)

  filetype = "ReinsuranceRelationshipsClass"
  data_this <- reshapeSNLfiles(data_this,filetype)

  data_reins_class_all[[i]] <- data_this
  i =  i+1
}
data_reins_class_all <- do.call(rbind,data_reins_class_all)

data_reins_class_all <- data_reins_class_all[!duplicated(paste0(data_reins_class_all$REINSRECONCILEOID,data_reins_class_all$CEDENTCLASS,data_reins_class_all$REINSCLASSCOMPARABLE)),]

data_reins_class_all <- data_reins_class_all %>% group_by(CEDENTREINS,REINSRECONCILEOID) %>% summarise(CEDENTCLASS = paste0(CEDENTCLASS,collapse=""),
                                                                                                       REINSCLASSCOMPARABLE = paste0(REINSCLASSCOMPARABLE,collapse=""))

data_reins_class_all$REINSCLASS_history <- paste0(data_reins_class_all$CEDENTCLASS,data_reins_class_all$REINSCLASSCOMPARABLE)

data_reins_class_all <- data_reins_class_all[,c("CEDENTREINS","REINSRECONCILEOID","REINSCLASS_history")]

data_reins_class_all <- data_reins_class_all[!duplicated(paste0(data_reins_class_all$CEDENTREINS,data_reins_class_all$REINSRECONCILEOID)),]

files_all <- list.files("../raw/SNL/ReinsuranceRelationships/BusinessType")

data_reins_businesstype_all <- list()
i <- 1

for (file_this in files_all){
  data_this <- readxl::read_xls(paste0("../raw/SNL/ReinsuranceRelationships/BusinessType/",file_this),skip=0)

  filetype = "ReinsuranceRelationships"
  data_this <- cleanSNLfiles(data_this,filetype)

  filetype = "ReinsuranceRelationshipsClass"
  data_this <- reshapeSNLfiles(data_this,filetype)

  data_reins_businesstype_all[[i]] <- data_this
  i =  i+1
}
data_reins_businesstype_all <- do.call(rbind,data_reins_businesstype_all)

data_reins_businesstype_all <- data_reins_businesstype_all[!duplicated(paste0(data_reins_businesstype_all$REINSRECONCILEOID,
                                                                              data_reins_businesstype_all$NAICCEDBUSINESSTYPE)),c("REINSRECONCILEOID","NAICCEDBUSINESSTYPE")]

data_reins_businesstype_all <- data_reins_businesstype_all %>% group_by(REINSRECONCILEOID) %>% summarise(NAICCEDBUSINESSTYPE = paste0(NAICCEDBUSINESSTYPE, collapse=""))
data_reins_businesstype_all = as.data.table(data_reins_businesstype_all)

data_reins_businesstype_all$NAICCEDBUSINESSTYPE_life = as.numeric(grepl("Life",data_reins_businesstype_all$NAICCEDBUSINESSTYPE))
data_reins_businesstype_all$NAICCEDBUSINESSTYPE_annuities = as.numeric(grepl("Annuit",data_reins_businesstype_all$NAICCEDBUSINESSTYPE))

filetype = "ReinsuranceRelationshipsRatings"

data_reins_ratings_1 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_4-8-2022_fa0fa2bb-4cfa-424a-b6ce-ab35ee7dccf9.xls")
data_reins_ratings_2 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_4-8-2022_cdeeb488-61df-4a8e-bb58-e664d0ef06fb.xls")
data_reins_ratings_3 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_4-8-2022_c6601c7b-258a-4d88-a79f-e6e77928a9a8.xls")
data_reins_ratings_4 <- readxl::read_xls("../raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_4-8-2022_2896425f-cdc9-451e-9e7b-d838f41ffe73.xls")

data_reins_ratings_1 <- cleanSNLfiles(data_reins_ratings_1,filetype)
data_reins_ratings_2 <- cleanSNLfiles(data_reins_ratings_2,filetype)
data_reins_ratings_3 <- cleanSNLfiles(data_reins_ratings_3,filetype)
data_reins_ratings_4 <- cleanSNLfiles(data_reins_ratings_4,filetype)

data_reins_ratings <- do.call(rbind,list(data_reins_ratings_1,
                                         data_reins_ratings_2,
                                         data_reins_ratings_3,
                                         data_reins_ratings_4))

names(data_reins_ratings) = c("CEDENTREINS","REINSRECONCILEOID","REINSFINLSTRENGTHRATING","EFFECTIVEDATEMDYYY")

data_reins_ratings = as.data.table(data_reins_ratings)
data_reins_ratings$REINSRECONCILEOID = toupper(data_reins_ratings$REINSRECONCILEOID)
data_reins_ratings <- data_reins_ratings[!duplicated(data_reins_ratings$REINSRECONCILEOID),]

data_reins_ratings$REINSFINLSTRENGTHRATING = (!is.na(data_reins_ratings$REINSFINLSTRENGTHRATING))

data_reins_ratings <- data_reins_ratings[,c("REINSRECONCILEOID","REINSFINLSTRENGTHRATING")]

files_all <- list.files("../raw/SNL/ReinsuranceRelationships/UnauthorizedReserveCreditTaken/")

data_reins_unauthres_all <- list()
i <- 1

for (file_this in files_all){
  data_this <- readxl::read_xls(paste0("../raw/SNL/ReinsuranceRelationships/UnauthorizedReserveCreditTaken/",file_this),skip=0)

  filetype = "ReinsuranceRelationships"
  data_this <- cleanSNLfiles(data_this,filetype)

  filetype = "ReinsuranceRelationshipsClass"
  data_this <- reshapeSNLfiles(data_this,filetype)

  data_reins_unauthres_all[[i]] <- data_this
  i =  i+1
}
data_reins_unauthres_all <- do.call(rbind,data_reins_unauthres_all)

data_reins_unauthres_all$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN = as.numeric(data_reins_unauthres_all$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN)

filetype = "ReinsuranceRelationships"

data_amounts = readxl::read_xlsx(paste0("../raw/SNL/ReinsuranceRelationships/AmountReinsured/Reinsurance relationships.xlsx"),sheet='Sheet1',skip=0)

data_amounts <- cleanSNLfiles(data_amounts,filetype)

data_amounts <- reshapeSNLfiles(data_amounts,filetype)

data_amounts = as.data.table(data_amounts)[,CEDENTREINS:=NULL]

data_reins_all_out2 <- merge(data_reins_all_out,data_reins_info,by=c("REINSRECONCILEOID"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_reins_parents,by=c("CEDENTREINS","REINSRECONCILEOID"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_reins_class_all,by=c("CEDENTREINS","REINSRECONCILEOID"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_reins_businesstype_all,by=c("REINSRECONCILEOID"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_reins_ratings,by=c("REINSRECONCILEOID"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_reins_unauthres_all,by=c("CEDENTREINS","REINSRECONCILEOID","year"),all.x=TRUE)

data_reins_all_out2 <- merge(data_reins_all_out2,data_amounts,by=c("REINSRECONCILEOID","year"),all.x=TRUE)

data_reins_all_out2_ss = data_reins_all_out2 %>% group_by(CEDENTREINS,REINSRECONCILEOID,year) %>% summarise(num = n())
if (max(data_reins_all_out2_ss$num[which(data_reins_all_out2_ss$REINSRECONCILEOID != "REINS_RECONCILE_OID")],na.rm=TRUE) > 1){
  stop("ERROR: FAILED: Check: duplicates")
}
rm(data_reins_all_out2_ss)

data_reins_all_out2$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN = as.numeric(data_reins_all_out2$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN)
data_reins_all_out2$CEDENTLIFERESVCREDITTAKEN_filled = data_reins_all_out2$CEDENTLIFERESVCREDITTAKEN
data_reins_all_out2$CEDENTLIFERESVCREDITTAKEN_filled[which(is.na(data_reins_all_out2$CEDENTLIFERESVCREDITTAKEN) & !is.na(data_reins_all_out2$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN))] = data_reins_all_out2$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN[which(is.na(data_reins_all_out2$CEDENTLIFERESVCREDITTAKEN) & !is.na(data_reins_all_out2$TOTALRELATEDUNAUTHCEDENTRESVCREDITTAKEN))]

state_names <- fread("../raw/States/StateNames.csv")
names(state_names) <- c("REINSSTATE","REINSSTATEDOMICILED_filled")

data_reins_all_out2 <- merge(data_reins_all_out2,
                             state_names,
                             by=c("REINSSTATE"),
                             all.x=TRUE)

names(data_basic_info_nonlife_state) = mapvalues(names(data_basic_info_nonlife_state),
                                                 from=c("SNLTOPENTITYKEY"),
                                                 to=c("CEDENTSNLTOPENTITYKEY"))
data_basic_info_nonlife_state$TOPENTITY_STATEDOMICILED[which(is.na(data_basic_info_nonlife_state$TOPENTITY_STATEDOMICILED))] = data_basic_info_nonlife_state$TOPENTITY_STATE[which(is.na(data_basic_info_nonlife_state$TOPENTITY_STATEDOMICILED))]
data_basic_info_nonlife_state = data_basic_info_nonlife_state[,TOPENTITY_STATE:=NULL]

data_reins_all_out2 = merge(data_reins_all_out2,
                            data_basic_info_nonlife_state,
                            by=c("CEDENTSNLTOPENTITYKEY"),
                            all.x=TRUE)

data_reins_all_out2$CEDENTSTATEDOMICILED = data_reins_all_out2$TOPENTITY_STATEDOMICILED
data_reins_all_out2 = data_reins_all_out2[,TOPENTITY_STATEDOMICILED:=NULL]

data_reins_all_out2$REINSSTATEDOMICILED[which(is.na(data_reins_all_out2$REINSSTATEDOMICILED) & !is.na(data_reins_all_out2$REINSSTATEDOMICILED_filled))] <- data_reins_all_out2$REINSSTATEDOMICILED_filled[which(is.na(data_reins_all_out2$REINSSTATEDOMICILED) & !is.na(data_reins_all_out2$REINSSTATEDOMICILED_filled))]

data_reins_all_out2$REINSURERISAUTH[which(!data_reins_all_out2$REINSURERISAUTH %in% c("Authorized","Unauthorized"))] <- "Other"

data_reins_all_out2$is_aff_group <- as.numeric(data_reins_all_out2$CEDENTSNLTOPENTITYKEY == data_reins_all_out2$REINSSNLTOPENTITYKEY)
data_reins_all_out2$is_aff_class <- NA
data_reins_all_out2$is_aff_class[which(!is.na(data_reins_all_out2$REINSCLASS))] <- as.numeric(grepl("Affiliated",data_reins_all_out2$REINSCLASS[which(!is.na(data_reins_all_out2$REINSCLASS))]))
data_reins_all_out2$is_aff_parent <- as.numeric(data_reins_all_out2$CEDENTULTPARENTNAME == data_reins_all_out2$REINSULTPARENTNAME)

data_reins_all_out2$is_aff <- pmax(data_reins_all_out2$is_aff_group,data_reins_all_out2$is_aff_class,data_reins_all_out2$is_aff_parent,na.rm=TRUE)
data_reins_all_out2$is_aff[which(is.na(data_reins_all_out2$is_aff_group) & is.na(data_reins_all_out2$is_aff_class) & is.na(data_reins_all_out2$is_aff_parent))] <- NA

data_reins_all_out2$amount_reinsured = rowSums(data_reins_all_out2[,c("CEDENTLIFERESVCREDITTAKEN","CEDENTLIFEMODIFIEDCOINSURANCERESV")],na.rm=TRUE)
data_reins_all_out2$amount_reinsured_filled = rowSums(data_reins_all_out2[,c("CEDENTLIFERESVCREDITTAKEN_filled","CEDENTLIFEMODIFIEDCOINSURANCERESV")],na.rm=TRUE)
data_reins_all_out2$amount_reinsured_total = rowSums(data_reins_all_out2[,c("CededLifeReserveCreditTaken","CededLifeModCoReserve")],na.rm=TRUE)

# Fix data errors in SNL data based on cross-checking
data_reins_all_out2$is_aff[which((grepl("Brighthouse Financial, Inc.|MetLife, Inc.",data_reins_all_out2$CEDENTULTPARENTNAME)) & (grepl("Brighthouse Financial, Inc.|MetLife, Inc.",data_reins_all_out2$REINSULTPARENTNAME)))] = 1
data_reins_all_out2$REINSSTATE[which(grepl("Brighthouse Re Co. of DE",data_reins_all_out2$CEDENTREINS))] = "Delaware"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("Brighthouse Re Co. of DE",data_reins_all_out2$CEDENTREINS))] = "DE"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("Brighthouse Re Co. of DE",data_reins_all_out2$CEDENTREINS))] = "DE"

data_reins_all_out2 = data_reins_all_out2[which(!data_reins_all_out2$REINSRECONCILEOID %in% c("0601FAB2-BB28-4EC1-B6FB-2F1C3C62CD87",
                                                                                             "38843977-6AF0-45AF-8323-E696D8A8F537",
                                                                                             "52BDB931-641F-424F-A2C9-B91BAC901CAD",
                                                                                             "9078C8A7-20FC-4315-B8CC-5800FB7790BD",
                                                                                             "9D63717B-8DC6-456C-980B-EF3AEE030666",
                                                                                             "C0D48324-1E56-4748-952E-CBF3F65635D1")),]

data_reins_all_out2$is_aff[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = "Michigan"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = "MI"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ John Hancock Reassurance Co.",data_reins_all_out2$CEDENTREINS))] = "MI"

data_reins_all_out2$is_aff[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = "Vermont"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = "VT"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ Golden Gate III VT Captive Ins|/ Golden Gate V VT Captive Ins",data_reins_all_out2$CEDENTREINS))] = "VT"

data_reins_all_out2$is_aff[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = "Vermont"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = "VT"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ Lincoln Re Co. of Vermont VII",data_reins_all_out2$CEDENTREINS))] = "VT"

data_reins_all_out2$is_aff[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = "Vermont"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = "VT"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ River Lake Insurance Co",data_reins_all_out2$CEDENTREINS))] = "VT"

data_reins_all_out2$is_aff[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = "Vermont"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = "VT"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ SBLI Re LLC",data_reins_all_out2$CEDENTREINS))] = "VT"

data_reins_all_out2$is_aff[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = ""
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = ""
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ Sec Life of Denver Intl Ltd.",data_reins_all_out2$CEDENTREINS))] = ""

data_reins_all_out2$is_aff[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = "Iowa"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = "IA"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ Symetra Reinsurance Corp.",data_reins_all_out2$CEDENTREINS))] = "IA"

data_reins_all_out2$is_aff[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = 1
data_reins_all_out2$REINSCLASS[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSCLASS_history[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = "Captive"
data_reins_all_out2$REINSSTATE[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = "Vermont"
data_reins_all_out2$REINSSTATEDOMICILED[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = "VT"
data_reins_all_out2$REINSSTATEDOMICILED_filled[which(grepl("/ Peach Re Inc",data_reins_all_out2$CEDENTREINS))] = "VT"

data_reins_all_out2 = data_reins_all_out2[which(!grepl("/ Life Insurance Co. of LA",data_reins_all_out2$CEDENTREINS)),]

data_reins_all_out2$is_US <- as.numeric(data_reins_all_out2$REINSCOUNTRYNAME == "United States of America")

data_reins_all_out2$is_captive <- as.numeric(grepl("Captive",paste0(data_reins_all_out2$REINSCLASS)))
data_reins_all_out2$is_captive_alt <- as.numeric(grepl("Captive",paste0(data_reins_all_out2$REINSCLASS,data_reins_all_out2$REINSCLASS_history)))
data_reins_all_out2$is_noncaptive <- as.numeric(grepl("Non-captive",paste0(data_reins_all_out2$REINSCLASS)))
data_reins_all_out2$is_noncaptive_alt <- as.numeric(grepl("Non-captive",paste0(data_reins_all_out2$REINSCLASS,data_reins_all_out2$REINSCLASS_history)))
data_reins_all_out2$is_captive_ky <- as.numeric((data_reins_all_out2$is_aff) & (!data_reins_all_out2$REINSFINLSTRENGTHRATING))
data_reins_all_out2$is_captive_ky_shadow <- as.numeric((data_reins_all_out2$is_aff) & (!data_reins_all_out2$REINSFINLSTRENGTHRATING) & (data_reins_all_out2$REINSURERISAUTH != "Authorized"))

data_reins_all_out2$EFFECTIVEDATE = as.Date(as.numeric(data_reins_all_out2$EFFECTIVEDATE), origin = "1899-12-30")
data_reins_all_out2$captive_is_active = as.numeric(data_reins_all_out2$year >= year(data_reins_all_out2$EFFECTIVEDATE))
data_reins_all_out2$captive_is_active_intensive = as.numeric((data_reins_all_out2$captive_is_active) & (data_reins_all_out2$amount_reinsured > 0))

data_reins_all_out2_captiveonly = data_reins_all_out2[which(data_reins_all_out2$is_captive_alt == 1),]
data_reins_all_out2_captiveonly_ky = data_reins_all_out2[which(data_reins_all_out2$is_captive_ky == 1),]
data_reins_all_out2_captiveonly_ky_shadow = data_reins_all_out2[which(data_reins_all_out2$is_captive_ky_shadow == 1),]
data_reins_all_out2_insurerstateyr = data_reins_all_out2_captiveonly %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))
data_reins_all_out2_insurerstateyr_ky = data_reins_all_out2_captiveonly_ky %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))
data_reins_all_out2_insurerstateyr_ky_shadow = data_reins_all_out2_captiveonly_ky_shadow %>% group_by(CEDENTSNLSTATENTITYKEY,CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))

filetype = "MarketShare"

files_all <- list.files("../raw/SNL/MarketShare")

parts_all <- list()
i = 1

for (file_this in files_all){
  data_quantity_this <- readxl::read_xls(paste0("../raw/SNL/MarketShare/",file_this),skip=0)

  row_breaks <- which(data_quantity_this[,1] == "Industry",)
  row_breaks[(length(row_breaks)+1)] <- nrow(data_quantity_this)

  num_parts <- length(row_breaks) - 1

  for (num_part_this in 1:num_parts){
    part_start <- row_breaks[num_part_this]
    part_end <- row_breaks[(num_part_this+1)]

    part_this <- cleanMarketSharePart(data_quantity_this,num_part_this,part_start,part_end)
    parts_all[[i]] <- part_this

    i = i+1
  }
}

parts_all <- do.call(rbind,parts_all)

parts_all <- parts_all[!duplicated(parts_all),]

parts_all <- parts_all[which(!is.na(parts_all$PremiumsAndAnnuityConsiderations)),]

filetype = "InsuranceStatutoryFinancials"
data_quantity_reserves <- readxl::read_xls(paste0("../raw/SNL/SNL_Life_Quantities_Reserves_Aggregate_Company.xls"),skip=0)

data_quantity_reserves <- cleanSNLfiles(data_quantity_reserves,filetype)

data_quantity_reserves <- reshapeSNLfiles(data_quantity_reserves,filetype)

data_quantity_reserves = as.data.table(data_quantity_reserves)[,"ENTITYNAME":=NULL]

parts_all_group = merge(parts_all,data_basic_info[,c("SNLSTATENTITYKEY","SNLTOPENTITYKEY")],by=c("SNLSTATENTITYKEY"),all.x=TRUE)

parts_all_group = parts_all_group %>% group_by(SNLTOPENTITYKEY,state,lob,year) %>% summarise(MarketShare = sum(MarketShare,na.rm=TRUE),
                                                                                             PremiumsAndAnnuityConsiderations = sum(PremiumsAndAnnuityConsiderations,na.rm=TRUE))

filtered_data <- parts_all_group %>%
  filter(MarketShare > 0.001) %>% filter(!is.na(MarketShare))

basic_firm_metrics <- filtered_data %>%
  group_by(state, lob, year) %>%
  summarise(
    NumFirms = n_distinct(SNLTOPENTITYKEY, na.rm = TRUE),
    HHI = sum((MarketShare/100)^2, na.rm = TRUE)
  ) %>%
  ungroup()

change_firm_metrics <- basic_firm_metrics %>%
  group_by(state, lob) %>%
  arrange(year) %>%
  mutate(
    NumFirms_change_p1_to_p0 = (NumFirms - dplyr::lag(NumFirms, default = NA)) / dplyr::lag(NumFirms, default = NA),
    HHI_change_p1_to_p0 = (HHI - dplyr::lag(HHI, default = NA))
  ) %>%
  ungroup()

data_with_metrics <- parts_all_group %>%
  left_join(change_firm_metrics, by = c("state", "lob", "year"))

average_metrics <- data_with_metrics %>%
  filter(!is.na(HHI)) %>%
  group_by(SNLTOPENTITYKEY, year) %>%
  summarise(
    HHI_premium_weighted = sum(as.numeric(HHI) * as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE) / sum(as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE),
    HHI_change_p1_to_p0_premium_weighted = sum(as.numeric(HHI_change_p1_to_p0) * as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE) / sum(as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE),
    NumFirms_premium_weighted = sum(as.numeric(NumFirms) * as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE) / sum(as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE),
    NumFirms_change_p1_to_p0_premium_weighted = sum(as.numeric(NumFirms_change_p1_to_p0) * as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE) / sum(as.numeric(PremiumsAndAnnuityConsiderations), na.rm = TRUE)
  ) %>%
  ungroup()

average_metrics = as.data.table(average_metrics)[order(SNLTOPENTITYKEY,year),]

data <- merge(data,data_basic_info_all,by=c("ENTITYNAME","SNLSTATENTITYKEY"),all.x=TRUE,all.y=TRUE)

data <- merge(data,data_quantity_reserves,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

data_impairments <- readxl::read_xlsx("../raw/SNL/Impairments/SNL_Impairments.xlsx")

data_impairments <- merge(data_impairments,
                          data_basic_info_all,
                          by=c("SNLSTATENTITYKEY"),
                          all.x=TRUE)

data_impairments$NAICCOMPANYCODE[which(is.na(data_impairments$NAICCOMPANYCODE))] <- data_impairments$`NAIC Code`[which(is.na(data_impairments$NAICCOMPANYCODE))]

data_impairments <- data_impairments[,c("NAICCOMPANYCODE","Company","Type","Rehabilitation order date*","Net admitted assets** ($000)","Year")]
names(data_impairments) <- c("NAICCOMPANYCODE","SNL_Impairments_Name","SNL_Impairments_CompanyType","Date_Rehabilitation","SNL_Impairments_Assets","Year")

filetype = "Companies"
data_debt <- readxl::read_xlsx(paste0("../raw/SNL/Companies/SNL_Companies_Debt.xlsx"),skip=0)

data_debt <- data_debt %>% select(c("Entity Name","SNL Statutory Entity Key"),everything())

data_debt <- as.data.table(data_debt)
data_debt <- data_debt[,`Entity ID`:=NULL]
data_debt <- data_debt[,`Industry Classification`:=NULL]

names(data_debt) <- mapvalues(names(data_debt),
                              from=c("SPENTITYNAME","SPSNLSTATENTITYKEY"),
                              to=c("ENTITYNAME","SNLSTATENTITYKEY"))

data_debt <- cleanSNLfiles(data_debt,filetype)

data_debt <- reshapeSNLfiles(data_debt,filetype)

data_debt <- data_debt[which(!is.na(data_debt$SNLSTATENTITYKEY)),]

names(data_debt) <- mapvalues(names(data_debt),
                              from=c("SNLSTATENTITYKEY"),
                              to=c("SNLTOPENTITYKEY"))

data_debt_companies <- merge(data_debt,
                    data_basic_info,
                    by=c("SNLTOPENTITYKEY"),
                    all.x=TRUE)

data_debt_companies <- data_debt_companies[which(!is.na(data_debt_companies$SNLTOPENTITYKEY)),]

data_debt_companies <- as.data.table(data_debt_companies)[order(SNLTOPENTITYKEY,year,SNLTOTALDEBTFY),]
data_debt_companies <- data_debt_companies %>% group_by(SNLTOPENTITYKEY,year) %>% filter(row_number() == n())

data_debt_ss <- data_debt_companies %>% group_by(SNLTOPENTITYKEY,year) %>% summarise(num = n())
if (max(data_debt_ss$num,na.rm=TRUE) > 1){
  stop("FAILED Check: no duplicates at SNLTOPENTITYKEY-year for debt")
}

data_debt_companies <- as.data.table(data_debt_companies)
data_debt_companies <- data_debt_companies[,SNLSTATENTITYKEY:=NULL]
data_debt_companies <- data_debt_companies[,SNLGROUPSTATENTITYKEY:=NULL]
data_debt_companies <- data_debt_companies[,ENTITYNAME:=NULL]

data$SNLTOPENTITYKEY <- data$SNLGROUPSTATENTITYKEY
data$SNLTOPENTITYKEY[which(is.na(data$SNLGROUPSTATENTITYKEY))] <- data$SNLSTATENTITYKEY[which(is.na(data$SNLGROUPSTATENTITYKEY))]

data_group$SNLTOPENTITYKEY <- data_group$SNLSTATENTITYKEY

data_group <- merge(data_group,
                    data_debt_companies,
                    by=c("SNLTOPENTITYKEY","year"),
                    all.x=TRUE)

data_group$SNLTOTALDEBTFY_TOTALLIAB <- data_group$SNLTOTALDEBTFY / data_group$TOTALLIAB

data_group <- data_group %>% group_by(year) %>% mutate(SNLTOTALDEBTFY_yr = sum(SNLTOTALDEBTFY,na.rm=TRUE),
                                                       TOTALLIAB_yr = sum(TOTALLIAB,na.rm=TRUE))
data_group$SNLTOTALDEBTFY_TOTALLIAB_yr <- data_group$SNLTOTALDEBTFY_yr / data_group$TOTALLIAB_yr

data <- merge(data,
               data_group[,c("SNLTOPENTITYKEY","year","SNLTOTALDEBTFY_TOTALLIAB","SNLTOTALDEBTFY_TOTALLIAB_yr")],
               by=c("SNLTOPENTITYKEY","year"),
               all.x=TRUE)

data <- data %>% group_by(year) %>% mutate(SNLTOTALDEBTFY_TOTALLIAB_yr = mean(SNLTOTALDEBTFY_TOTALLIAB_yr,na.rm=TRUE))

data$SNLTOTALDEBTFY_TOTALLIAB_filled <- data$SNLTOTALDEBTFY_TOTALLIAB
data$SNLTOTALDEBTFY_TOTALLIAB_filled[which(is.na(data$SNLTOTALDEBTFY_TOTALLIAB))] <- data$SNLTOTALDEBTFY_TOTALLIAB_yr[which(is.na(data$SNLTOTALDEBTFY_TOTALLIAB))]

data$SNLTOTALDEBTFY_filled <- data$SNLTOTALDEBTFY_TOTALLIAB_filled * data$TOTALLIAB
data$SNLTOTALDEBTFY <- data$SNLTOTALDEBTFY_TOTALLIAB * data$TOTALLIAB

data <- as.data.table(data)
data <- data[,SNLTOPENTITYKEY:=NULL]

data_group <- as.data.table(data_group)
data_group <- data_group[,SNLTOPENTITYKEY:=NULL]

filetype = "InsuranceStatutoryFinancials"

data_expenses <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_Expenses.xls")
data_expenses_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_Expenses_Group.xls")

data_expenses <- cleanSNLfiles(data_expenses,filetype)
data_expenses_group <- cleanSNLfiles(data_expenses_group,filetype)

data_expenses <- reshapeSNLfiles(data_expenses,filetype)
data_expenses_group <- reshapeSNLfiles(data_expenses_group,filetype)

data_expenses <- as.data.table(data_expenses)[,ENTITYNAME:=NULL]
data_expenses_group <- as.data.table(data_expenses_group)[,ENTITYNAME:=NULL]

data <- merge(data,
              data_expenses,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

data_group <- merge(data_group,
              data_expenses_group,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

filetype = "InsuranceStatutoryFinancials"
data_investments_1 <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_InvestmentReturns_1.xls")
data_investments_1_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_InvestmentReturns_1_Group.xls")
data_investments_2 <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_InvestmentReturns_2.xls")
data_investments_2_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_InvestmentReturns_2_Group.xls")

selectAllLines <- function(data_investments_this){
  cols_lines <- as.vector(data_investments_this[3,])
  cols_lines <- c(cols_lines)
  cols_select <- names(cols_lines[which(is.na(cols_lines) | (cols_lines == "AR: Total All Lines"))])
  data_investments_this <- as.data.table(data_investments_this)[,..cols_select]

  return(data_investments_this)
}
data_investments_1 <- selectAllLines(data_investments_1)
data_investments_1_group <- selectAllLines(data_investments_1_group)

data_investments_1 <- cleanSNLfiles(data_investments_1,filetype)
data_investments_1_group <- cleanSNLfiles(data_investments_1_group,filetype)
data_investments_2 <- cleanSNLfiles(data_investments_2,filetype)
data_investments_2_group <- cleanSNLfiles(data_investments_2_group,filetype)

data_investments_1 <- reshapeSNLfiles(data_investments_1,filetype)
data_investments_1_group <- reshapeSNLfiles(data_investments_1_group,filetype)
data_investments_2 <- reshapeSNLfiles(data_investments_2,filetype)
data_investments_2_group <- reshapeSNLfiles(data_investments_2_group,filetype)

data_investments <- merge(data_investments_1,
                          data_investments_2,
                          by=c("ENTITYNAME","SNLSTATENTITYKEY","year"),
                          all.x=TRUE,all.y=TRUE)

data_investments_group <- merge(data_investments_1_group,
                          data_investments_2_group,
                          by=c("ENTITYNAME","SNLSTATENTITYKEY","year"),
                          all.x=TRUE,all.y=TRUE)

data_investments <- as.data.table(data_investments)[,ENTITYNAME:=NULL]
data_investments_group <- as.data.table(data_investments_group)[,ENTITYNAME:=NULL]

data <- merge(data,data_investments,
               by=c("SNLSTATENTITYKEY","year"),
               all.x=TRUE)

data_group <- merge(data_group,data_investments_group,
               by=c("SNLSTATENTITYKEY","year"),
               all.x=TRUE)

filetype = "InsuranceStatutoryFinancials"

data_capital <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_CapitalSurplus_with_2021.xls")
data_capital_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_CapitalSurplus_Group_with_2021.xls")

data_capital <- cleanSNLfiles(data_capital,filetype)
data_capital_group <- cleanSNLfiles(data_capital_group,filetype)

data_capital <- reshapeSNLfiles(data_capital,filetype)
data_capital_group <- reshapeSNLfiles(data_capital_group,filetype)

data_capital <- as.data.table(data_capital)[,ENTITYNAME:=NULL]
data_capital_group <- as.data.table(data_capital_group)[,ENTITYNAME:=NULL]

names(data_capital) <- mapvalues(names(data_capital),
                                 from=c("SURPLUS"),
                                 to=c("MINSURPLUS"))
names(data_capital_group) <- mapvalues(names(data_capital_group),
                                       from=c("SURPLUS"),
                                       to=c("MINSURPLUS"))

data <- merge(data,
              data_capital,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

data_group <- merge(data_group,
                    data_capital_group,
                    by=c("SNLSTATENTITYKEY","year"),
                    all.x=TRUE)

if (sum(is.na(data$SURPLUS[which(!is.na(data$TOTALASSETS))])) > 100){
  stop("FAILED: too many NA's in surplus")
}

filetype = "InsuranceStatutoryFinancials"
data_reserves <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_TotalPolicyReserves.xls")
data_reserves_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_TotalPolicyReserves_Group.xls")
data_lifereserves_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_PolicyReserves_Group.xls")

data_reserves <- cleanSNLfiles(data_reserves,filetype)
data_reserves_group <- cleanSNLfiles(data_reserves_group,filetype)
data_lifereserves_group <- cleanSNLfiles(data_lifereserves_group,filetype)

data_reserves <- reshapeSNLfiles(data_reserves,filetype)
data_reserves_group <- reshapeSNLfiles(data_reserves_group,filetype)
data_lifereserves_group <- reshapeSNLfiles(data_lifereserves_group,filetype)

data_reserves <- as.data.table(data_reserves)[,ENTITYNAME:=NULL]
data_reserves_group <- as.data.table(data_reserves_group)[,ENTITYNAME:=NULL]
data_lifereserves_group <- as.data.table(data_lifereserves_group)[,ENTITYNAME:=NULL]

data <- merge(data,data_reserves,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

data_group <- merge(data_group,data_reserves_group,
                    by=c("SNLSTATENTITYKEY","year"),
                    all.x=TRUE)

filetype = "Companies"
data_lhreserves <- readxl::read_xlsx(paste0("../raw/SNL/Companies/SNL_Companies_LHReserves.xlsx"),skip=0)
data_otherlhreserves <- readxl::read_xlsx(paste0("../raw/SNL/Companies/SNL_Companies_OtherLHReserves.xlsx"),skip=0)
data_totalpolicyreserves <- readxl::read_xlsx(paste0("../raw/SNL/Companies/SNL_Companies_TotalPolicyReserves.xlsx"),skip=0)
data_policybenefits <- readxl::read_xlsx(paste0("../raw/SNL/Companies/SNL_Companies_FuturePolicyBenefits.xlsx"),skip=0)

data_usops = readxl::read_xlsx(paste0("../raw/AMBest/AMBest_Companies_USOnly.xlsx"))

cleanSNLCompaniesfiles <- function(data_companies){
  data_companies <- data_companies %>% select(c("Entity Name","SNL Statutory Entity Key"),everything())

  data_companies <- as.data.table(data_companies)
  data_companies <- data_companies[,`Entity ID`:=NULL]
  data_companies <- data_companies[,`Industry Classification`:=NULL]

  names(data_companies) <- mapvalues(names(data_companies),
                                from=c("SPENTITYNAME","SPSNLSTATENTITYKEY"),
                                to=c("ENTITYNAME","SNLSTATENTITYKEY"))

  data_companies <- cleanSNLfiles(data_companies,filetype)

  data_companies <- reshapeSNLfiles(data_companies,filetype)

  data_companies <- data_companies[which(!is.na(data_companies$SNLSTATENTITYKEY)),]

  names(data_companies) <- mapvalues(names(data_companies),
                                from=c("SNLSTATENTITYKEY"),
                                to=c("SNLTOPENTITYKEY"))

  data_companies_companies <- merge(data_companies,
                               data_basic_info,
                               by=c("SNLTOPENTITYKEY"),
                               all.x=TRUE)

  data_companies_companies <- data_companies_companies[which(!is.na(data_companies_companies$SNLTOPENTITYKEY)),]

  data_companies_companies <- as.data.table(data_companies_companies)[order(SNLTOPENTITYKEY,year),]
  data_companies_companies <- data_companies_companies %>% group_by(SNLTOPENTITYKEY,year) %>% filter(row_number() == n())

  data_companies_ss <- data_companies_companies %>% group_by(SNLTOPENTITYKEY,year) %>% summarise(num = n())
  if (max(data_companies_ss$num,na.rm=TRUE) > 1){
    stop("FAILED Check: no duplicates at SNLTOPENTITYKEY-year for debt")
  }

  data_companies_companies <- as.data.table(data_companies_companies)
  data_companies_companies <- data_companies_companies[,SNLSTATENTITYKEY:=NULL]
  data_companies_companies <- data_companies_companies[,SNLGROUPSTATENTITYKEY:=NULL]
  data_companies_companies <- data_companies_companies[,ENTITYNAME:=NULL]

  return(data_companies_companies)
}

data_lhreserves <- cleanSNLCompaniesfiles(data_lhreserves)
data_otherlhreserves <- cleanSNLCompaniesfiles(data_otherlhreserves)
data_totalpolicyreserves <- cleanSNLCompaniesfiles(data_totalpolicyreserves)
data_policybenefits <- cleanSNLCompaniesfiles(data_policybenefits)

data_gaap <- merge(data_lhreserves,
                   data_otherlhreserves,
                   by=c("SNLTOPENTITYKEY","year"),
                   all.x=TRUE,all.y=TRUE)
data_gaap <- merge(data_gaap,
                   data_totalpolicyreserves,
                   by=c("SNLTOPENTITYKEY","year"),
                   all.x=TRUE,all.y=TRUE)
data_gaap <- merge(data_gaap,
                   data_policybenefits,
                   by=c("SNLTOPENTITYKEY","year"),
                   all.x=TRUE,all.y=TRUE)

data_gaap <- data_gaap[which(!is.na(data_gaap$SNLFUTUREPOLICYBENEFITSFY)),]

data_financials_group_statutory = data_group

names(data_gaap) = mapvalues(names(data_gaap),
                             from=c("SNLTOPENTITYKEY"),
                             to=c("SNLSTATENTITYKEY"))

data_gaap$year = as.numeric(data_gaap$year)
data_financials_group_statutory$year = as.numeric(data_financials_group_statutory$year)

data_gaap = as.data.table(data_gaap)[,"STATEINCORP.x":=NULL]
data_gaap = as.data.table(data_gaap)[,"STATEINCORP.y":=NULL]

data_gaap2 = merge(data_gaap,data_financials_group_statutory,by=c("SNLSTATENTITYKEY","year"),all.x=TRUE)

data_gaap2 = data_gaap2[which(data_gaap2$SNLFUTUREPOLICYBENEFITSFY >= (10^6) & data_gaap2$TOTALPOLICYRESVLIFE >= (10^6)),]
data_gaap2 = data_gaap2[which(data_gaap2$ENTITYNAME %in% data_usops$ENTITYNAME[which(data_usops$CompanyOnlyHasUSOperation == 1)]),]

data_gaap_ss <- data_gaap2 %>% summarise(TOTALPOLICYRESVLIFE = sum(TOTALPOLICYRESVLIFE,na.rm=TRUE),
                                         SNLFUTUREPOLICYBENEFITSFY = sum(SNLFUTUREPOLICYBENEFITSFY,na.rm=TRUE))

data_gaap_ss$reserve_statutory_gaap_ratio <- (data_gaap_ss$TOTALPOLICYRESVLIFE) / (data_gaap_ss$SNLFUTUREPOLICYBENEFITSFY)

data_reserves_vas = list()
data_reserves_vas[[1]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2003039.csv')[,c(1,10,11,12)]
data_reserves_vas[[2]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2004039.csv')[,c(1,10,11,12)]
data_reserves_vas[[3]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2005039.csv')[,c(1,14,15,18)]
data_reserves_vas[[4]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2006039.csv')[,c(1,14,15,18)]
data_reserves_vas[[5]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2007041.csv')[,c(1,14,15,18)]
data_reserves_vas[[6]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2008040.csv')[,c(1,14,15,18)]
data_reserves_vas[[7]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2009042.csv')[,c(1,14,15,18)]
data_reserves_vas[[8]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2010042.csv')[,c(1,14,15,18)]
data_reserves_vas[[9]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2011046.csv')[,c(1,14,15,18)]
data_reserves_vas[[10]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2012046.csv')[,c(1,14,15,18)]
data_reserves_vas[[11]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2013046.csv')[,c(1,14,15,18)]
data_reserves_vas[[12]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2014072.csv')[,c(1,14,15,18)]
data_reserves_vas[[13]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2015072.csv')[,c(1,14,15,18)]
data_reserves_vas[[14]] = fread('../raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/L2016074.csv')[,c(1,14,15,18)]

names(data_reserves_vas[[1]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[2]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[3]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[4]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[5]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[6]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[7]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[8]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[9]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[10]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[11]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[12]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[13]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')
names(data_reserves_vas[[14]]) = c('NAICCOMPANYCODE','TOT_REL_ACCOUNT_VAL','GRS_AMT_OF_RES','REINS_RES_CRED')

data_reserves_vas[[1]]$year = 2003
data_reserves_vas[[2]]$year = 2004
data_reserves_vas[[3]]$year = 2005
data_reserves_vas[[4]]$year = 2006
data_reserves_vas[[5]]$year = 2007
data_reserves_vas[[6]]$year = 2008
data_reserves_vas[[7]]$year = 2009
data_reserves_vas[[8]]$year = 2010
data_reserves_vas[[9]]$year = 2011
data_reserves_vas[[10]]$year = 2012
data_reserves_vas[[11]]$year = 2013
data_reserves_vas[[12]]$year = 2014
data_reserves_vas[[13]]$year = 2015
data_reserves_vas[[14]]$year = 2016

data_reserves_vas = do.call(rbind,data_reserves_vas)

data_reserves_vas = data_reserves_vas %>% group_by(NAICCOMPANYCODE,year) %>% summarise(TOT_REL_ACCOUNT_VAL = sum(TOT_REL_ACCOUNT_VAL / 1000000,na.rm=TRUE),
                                                                      GRS_AMT_OF_RES = sum(GRS_AMT_OF_RES / 1000000,na.rm=TRUE),
                                                                      REINS_RES_CRED = sum(REINS_RES_CRED / 1000000,na.rm=TRUE))

filetype = "InsuranceStatutoryFinancials"

data_exams = readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_Exams.xls",skip=0)

data_exams <- cleanSNLfiles(data_exams,filetype)

data_exams[data_exams == "NA"] <- "0"
data_exams[data_exams == "Yes"] = "1"
data_exams[data_exams == "No"] = "0"

data_exams <- reshapeSNLfiles(data_exams,filetype)

data_exams$DATELASTREGFINLEXAMREPORTPUBLICLYAVAILABLE = as.Date(data_exams$DATELASTREGFINLEXAMREPORTPUBLICLYAVAILABLE, origin = "1899-12-30")
data_exams$DATELATESTFINLEXAMBYREGULATOR = as.Date(data_exams$DATELATESTFINLEXAMBYREGULATOR, origin = "1899-12-30")

filetype = "InsuranceStatutoryFinancials"

data_incorporationdate = readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials/SNL_Life_InsuranceStatutoryFinancials_DateIncorporated.xls",skip=0)

data_incorporationdate <- cleanSNLfiles(data_incorporationdate,filetype)

data_incorporationdate$DATEINCORPORATED = as.Date(as.numeric(data_incorporationdate$DATEINCORPORATED), origin = "1899-12-30")

data_incorporationdate$YEARINCORPORATED = year(data_incorporationdate$DATEINCORPORATED)
data_incorporationdate$YEARINCORPORATED[which(is.na(data_incorporationdate$DATEINCORPORATED))] = data_incorporationdate$YRESTABLISHED[which(is.na(data_incorporationdate$DATEINCORPORATED))]

data_incorporationdate = data_incorporationdate[,c("ENTITYNAME","SNLSTATENTITYKEY","YEARINCORPORATED")]

data_economiccapital <- data_group

rho = data_gaap_ss$reserve_statutory_gaap_ratio[1] - 1

data_economiccapital = data_economiccapital[which(!is.na(data_economiccapital$SURPLUSASREGARDSPOLICYHOLDERS) & !is.na(data_economiccapital$TOTALPOLICYRESVLIFE)),]
data_economiccapital = data_economiccapital[which(data_economiccapital$TOTALPOLICYRESVLIFE > (10^6) & data_economiccapital$SURPLUSASREGARDSPOLICYHOLDERS > (10^3)),]

data_economiccapital$K = data_economiccapital$SURPLUSASREGARDSPOLICYHOLDERS + data_economiccapital$TOTALPOLICYRESVLIFE * (rho / (1 + rho))

vega = fread("../raw/Other/FASB_Vega.csv")$V1[1]
data_economiccapital$V_tplus1T = data_economiccapital$TOTALPOLICYRESVLIFE * (1/(1+rho)) * vega

data_economiccapital$kappa_h_estimated = data_economiccapital$K / data_economiccapital$V_tplus1T

L_div_Q = fread("../raw/Other/FASB_Vega.csv")$V2[1]
L_div_Q = data.frame(L_div_Q=L_div_Q)

fwrite(L_div_Q,file="output/L_div_Q.csv")

kappa_h_K_div_L = sum(data_economiccapital$K,na.rm=TRUE) / sum(data_economiccapital$V_tplus1T,na.rm=TRUE)
kappa_h_K_div_Q = sum(data_economiccapital$K,na.rm=TRUE) / sum(data_economiccapital$V_tplus1T,na.rm=TRUE) * L_div_Q$L_div_Q[1]
kappa_h = kappa_h_K_div_Q
kappa_h = data.frame(kappa_h=kappa_h,
                     kappa_h_K_div_Q = kappa_h_K_div_Q,
                     kappa_h_K_div_L = kappa_h_K_div_L)
kappa_h$vega = vega

fwrite(kappa_h,file="output/kappa_h.csv")

files_all <- list.files("../raw/SNL/ReinsuranceRelationships_Supplement/")

data_supplement_rr_all <- list()
i <- 1
numcols = 0

for (file_this in files_all){
  data_this <- readxl::read_xls(paste0("../raw/SNL/ReinsuranceRelationships_Supplement/",file_this),skip=0)

  if (sum(is.na(data_this[3,])) == ncol(data_this)){
    filetype = "ReinsuranceRelationships"
  } else {
    filetype = "ReinsuranceRelationships_Supplement"
  }
  data_this <- cleanSNLfiles(data_this,filetype)

  filetype = "ReinsuranceRelationships"
  data_this <- reshapeSNLfiles(data_this,filetype)

  if (max(as.numeric(data_this$year),na.rm=TRUE) >= 10000){
    data_this$year = as.numeric(data_this$year) %% 10000
  }

  data_this$year = as.numeric(data_this$year)

  numcols = numcols + ncol(data_this) - 3

  data_supplement_rr_all[[i]] <- data_this
  i =  i+1
}
data_supplement_rr_all2 = data_supplement_rr_all %>% purrr::reduce(full_join, by=c("CEDENTREINS","REINSRECONCILEOID","year"))

data_supplement_rr_all2_ss = data_supplement_rr_all2 %>% group_by(REINSRECONCILEOID,year) %>% summarise(num = n())
if (max(data_supplement_rr_all2_ss$num,na.rm=TRUE) > 1){
  stop("FAILED: Check: duplicates by reinsurance relationship year")
}
rm(data_supplement_rr_all2_ss)

df = as.data.table(data_supplement_rr_all2)
df = update_join(df)

if (abs(sum(df$XXXAXXXEFFECTIVEORPYCOLLASSETSBYASSETOtherLOCs,na.rm=TRUE) - (sum(data_supplement_rr_all2$XXXAXXXEFFECTIVEORPYCOLLASSETSBYASSETOtherLOCs,na.rm=TRUE)+sum(data_supplement_rr_all2$XXXAXXXEFFECTIVEORPYCOLLASSETSBYASSETOtherLOCs.x,na.rm=TRUE)+sum(data_supplement_rr_all2$XXXAXXXEFFECTIVEORPYCOLLASSETSBYASSETOtherLOCs.y,na.rm=TRUE))) > 1){
  stop("FAILED: Check: coalesce worked properly")
}

df$is_exempt = rowSums(df[,c("TANDULIFEREINSLCDACCREDORDOMINOTHERSTATE","TANDULIFENNAFFREINLCDACRDORDOMOTHERSTATE","XXXAXXXREINSMAINTAININGTRUSTFUND","XXXAXXXREINSCERTIFIED","TANDULIFEREINSMEETCERTAINSIZEANDLICENSINGREQ","XXXAXXXREINSLICENSED","XXXAXXXREINSACCREDITED","XXXAXXXREINSDOMICILEINANOTHJURISDICT","XXXAXXXREINSREQUIREDBYLAW")], na.rm=TRUE)
df = df[which(df$is_exempt == 0),]

cols_XXXAXXXCOLLASSETSBYASSET_all = names(df)[which(grepl("^XXXAXXXCOLLASSETSBYASSET",names(df)))]
cols_XXXAXXXCOLLASSETSBYASSET = cols_XXXAXXXCOLLASSETSBYASSET_all[which(!cols_XXXAXXXCOLLASSETSBYASSET_all %in% c("XXXAXXXCOLLASSETSBYASSETOtherSecurity","XXXAXXXCOLLASSETSBYASSETPrimarySecurity"))]

df$cols_XXXAXXXCOLLASSETSBYASSET_sum = rowSums(df[,..cols_XXXAXXXCOLLASSETSBYASSET], na.rm=TRUE)
df$cols_XXXAXXXCOLLASSETSBYASSET_sum[which(df$cols_XXXAXXXCOLLASSETSBYASSET_sum == 0)] = NA

df$cols_XXXAXXXCOLLASSETSBYASSET_sumcheck = df$cols_XXXAXXXCOLLASSETSBYASSET_sum - df$XXXAXXXCOLLASSETS

cols_XXXAXXXCOLLASSETSBYASSET_with_sum = c("CEDENTREINS",
                                           "XXXAXXXCOLLASSETS",
                                           "cols_XXXAXXXCOLLASSETSBYASSET_sumcheck",
                                           cols_XXXAXXXCOLLASSETSBYASSET_all)

df$A_hat = df$XXXAXXXCOLLASSETS
df$A_hat_N = rowSums(df[,c("XXXAXXXCOLLASSETSBYASSETExcessofLossReinsurance","XXXAXXXCOLLASSETSBYASSETLOCLikeAssets","XXXAXXXCOLLASSETSBYASSETOtherLOCs")],na.rm=TRUE)
df$L_hat_times_1_plus_rho = df$XXXAXXXSTATRESVCREDITTAKEN

df_reins_info = data_reins_all_out2[which(data_reins_all_out2$REINSRECONCILEOID %in% df$REINSRECONCILEOID),]
df_reins_info_full = df_reins_info
df_reins_info_full = df_reins_info_full[!duplicated(df_reins_info_full[,c("REINSRECONCILEOID","year")]),c("REINSRECONCILEOID","year","REINSSTATEDOMICILED","CEDENTSNLTOPENTITYKEY","is_captive_alt")]

expand_year = function(df_in,col_id,col_expand,col_expand_vals){
  df_in = as.data.table(df_in)

  col_id_all = c(as.vector(sort(unique(df_in[[col_id]]))))
  col_expand_all = c(as.vector(sort(unique(df_in[[col_expand]]))),col_expand_vals)
  df_out = merge(col_id_all,col_expand_all)
  names(df_out) = c(col_id,col_expand)

  df_out = merge(df_out,df_in,by=c(col_id,col_expand),all.x=TRUE)

  df_out = df_out %>% group_by(!!as.name(col_id)) %>% fill(everything(),.direction = "down")

  return(df_out)
}

df_reins_info_full = expand_year(df_reins_info_full,col_id="REINSRECONCILEOID",col_expand="year",col_expand_vals="2021")
df_reins_info_full$year = as.numeric(df_reins_info_full$year)

df_reins_info = df_reins_info[which(df_reins_info$is_captive_alt == 1),c("CEDENTREINS","REINSRECONCILEOID","year","CEDENTULTPARENTNAME","REINSSTATEDOMICILED","REINSCOUNTRYNAME")]

df2 = merge(df,df_reins_info_full,by=c("REINSRECONCILEOID","year"),all.x=TRUE)

df2_output = df2

df2 = df2[which(df2$is_captive_alt == 1),]

df2_numeric = as.data.frame(df2)[,!names(df2) %in% c("CEDENTREINS","REINSRECONCILEOID","XXXAXXXEFFCTVORPYNONCOLLATAFFILPRNTGUARPrimSecurityDerivAcqNorm")]
df2_numeric$num_captives = 1

df2_insurerstateyr = df2_numeric %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(across(everything(), list(sum = sum_narm)))
names(df2_insurerstateyr) = gsub("_sum$","",names(df2_insurerstateyr))

df2_stateyr = as.data.frame(df2)[,!names(df2) %in% c("CEDENTSNLTOPENTITYKEY","CEDENTREINS","REINSRECONCILEOID","XXXAXXXEFFCTVORPYNONCOLLATAFFILPRNTGUARPrimSecurityDerivAcqNorm")]
df2_stateyr = df2_stateyr %>% group_by(REINSSTATEDOMICILED,year) %>% summarise(across(everything(), list(sum = sum_narm)))
names(df2_stateyr) = gsub("_sum$","",names(df2_stateyr))

df2_stateyr$kappa_supplement = (df2_stateyr$A_hat - df2_stateyr$A_hat_N) / (df2_stateyr$L_hat_times_1_plus_rho)
df2_stateyr$kappa_supplement_reported = (df2_stateyr$A_hat) / (df2_stateyr$L_hat_times_1_plus_rho)
df2_stateyr$kappa_supplement_a_hat = (df2_stateyr$A_hat - df2_stateyr$A_hat_N) / (df2_stateyr$A_hat)
df2_stateyr$allow_prescribed = as.numeric(df2_stateyr$A_hat_N > 0)

df2_stateyr$L_hat_times_1_plus_rho_ln = log(df2_stateyr$L_hat_times_1_plus_rho+1)

df2_rho = df2[which(!is.na(df2$XXXAXXXEXEMPTECONOMICRESVLEVEL) & !is.na(df2$XXXAXXXEXEMPTRESVCREDITTAKEN)),]
df2_rho_ss = df2_rho %>% summarise(XXXAXXXEXEMPTECONOMICRESVLEVEL = sum(XXXAXXXEXEMPTECONOMICRESVLEVEL,na.rm=TRUE),
                                   XXXAXXXEXEMPTRESVCREDITTAKEN = sum(XXXAXXXEXEMPTRESVCREDITTAKEN,na.rm=TRUE))

data_supplement_10ks = readxl::read_xlsx("../raw/10K/SNL_Companies_Captives_CapitalSurplus_List.xlsx",sheet="Unauthorized_Public")

data_supplement_10ks_ss = data_supplement_10ks %>% group_by(year) %>% summarise(CapitalSurplus_Adjustment = sum(CapitalSurplus_Adjustment,na.rm=TRUE))

data_supplement_10ks$capitalsurplus_captive = data_supplement_10ks$CapitalSurplus_StatePrescribed - data_supplement_10ks$CapitalSurplus_Adjustment

data_supplement_10ks$capitalsurplus_captive[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK4048408")] = data_supplement_10ks$CapitalSurplus_NAIC[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK4048408")]

data_group_lincoln = data_group[which(data_group$SNLSTATENTITYKEY == "GK103362"),c("SNLSTATENTITYKEY","year","SURPLUSASREGARDSPOLICYHOLDERS")]
names(data_group_lincoln) = c("CEDENTSNLTOPENTITYKEY","year","SURPLUSASREGARDSPOLICYHOLDERS")
data_supplement_10ks = merge(data_supplement_10ks,data_group_lincoln,by=c("CEDENTSNLTOPENTITYKEY","year"),all.x=TRUE)

data_supplement_10ks$CapitalSurplus_Group_Noncaptives[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")] = data_supplement_10ks$SURPLUSASREGARDSPOLICYHOLDERS[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")] / 1000

data_supplement_10ks = as.data.table(data_supplement_10ks)[,SURPLUSASREGARDSPOLICYHOLDERS:=NULL]

data_supplement_10ks$capitalsurplus_captive[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")] = data_supplement_10ks$CapitalSurplus_Group[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")] - data_supplement_10ks$CapitalSurplus_Group_Noncaptives[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")] - data_supplement_10ks$CapitalSurplus_Adjustment[which(data_supplement_10ks$CEDENTSNLTOPENTITYKEY == "GK103362")]

data_reins_all_out2_supplement = data_reins_all_out2[,c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year","CEDENTLIFERESVCREDITTAKEN","CEDENTLIFEMODIFIEDCOINSURANCERESV","is_captive_alt")]
data_reins_all_out2_supplement$amount_reinsured = rowSums(data_reins_all_out2[,c("CEDENTLIFERESVCREDITTAKEN","CEDENTLIFEMODIFIEDCOINSURANCERESV")],na.rm=TRUE)

df2_numeric_sizeordered = data_reins_all_out2_supplement[which(data_reins_all_out2_supplement$REINSSTATEDOMICILED != "" & data_reins_all_out2_supplement$is_captive_alt == 1),]
df2_numeric_sizeordered = df2_numeric_sizeordered %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))
df2_numeric_sizeordered = df2_numeric_sizeordered %>% group_by(CEDENTSNLTOPENTITYKEY) %>% arrange(desc(amount_reinsured))
df2_numeric_sizeordered = df2_numeric_sizeordered %>% group_by(CEDENTSNLTOPENTITYKEY) %>% filter(row_number() == 1)

df2_numeric_sizeordered = df2_numeric_sizeordered %>% select(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED)

df2_numeric_sizeordered$REINSSTATEDOMICILED[which(df2_numeric_sizeordered$CEDENTSNLTOPENTITYKEY == "GK4041737")] = "MO"

data_supplement_10ks = merge(data_supplement_10ks,df2_numeric_sizeordered,by=c("CEDENTSNLTOPENTITYKEY"),all.x=TRUE)

data_supplement_iowa = readxl::read_xlsx("../raw/States/IA/CapitalAndLiability.xlsx",sheet="RawData")

data_supplement_iowa$REINSSTATEDOMICILED = "IA"

data_group_supplement_iowa_names = unique(data_group[,c("SNLSTATENTITYKEY","ENTITYNAME")])
names(data_group_supplement_iowa_names) = c("CEDENTSNLTOPENTITYKEY","CEDENTSNLTOPENTITYNAME")
data_supplement_iowa = merge(data_supplement_iowa,data_group_supplement_iowa_names,by=c("CEDENTSNLTOPENTITYNAME"),all.x=TRUE)

data_supplement_iowa = data_supplement_iowa[,!names(data_supplement_iowa) %in% c("Captive","CEDENTSNLTOPENTITYNAME")]
data_supplement_iowa$Liabilities = as.numeric(data_supplement_iowa$Liabilities)

data_supplement_iowa = data_supplement_iowa %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(across(everything(), list(sum = sum_narm)))
names(data_supplement_iowa) = gsub("_sum$","",names(data_supplement_iowa))

data_supplement_iowa$Liabilities = data_supplement_iowa$Liabilities / 1000000
data_supplement_iowa$CapitalSurplus_StatePrescribed = data_supplement_iowa$CapitalSurplus_StatePrescribed / 1000000
data_supplement_iowa$CapitalSurplus_NAIC = data_supplement_iowa$CapitalSurplus_NAIC / 1000000

data_supplement_iowa$capitalsurplus_captive = data_supplement_iowa$CapitalSurplus_NAIC

data_supplement_10ks_iowa = rbind(data_supplement_10ks,data_supplement_iowa,fill=TRUE)

data_reins_all_out2_insurerstateyr = data_reins_all_out2_supplement %>% group_by(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year) %>% summarise(amount_reinsured = sum(amount_reinsured,na.rm=TRUE))
data_reins_all_out2_insurerstateyr$amount_reinsured = data_reins_all_out2_insurerstateyr$amount_reinsured / 1000
data_reins_all_out2_insurerstateyr$year = as.numeric(data_reins_all_out2_insurerstateyr$year)
data_supplement_10ks_iowa = as.data.table(data_supplement_10ks_iowa)[,amount_reinsured:=NULL]
data_supplement_10ks_iowa = merge(data_supplement_10ks_iowa,data_reins_all_out2_insurerstateyr,by=c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year"),all.x=TRUE)

data_supplement_10ks_iowa_stateyr = data_supplement_10ks_iowa[which(!is.na(data_supplement_10ks_iowa$capitalsurplus_captive)),]
data_supplement_10ks_iowa_stateyr = data_supplement_10ks_iowa_stateyr %>% group_by(REINSSTATEDOMICILED,year) %>% summarise(capitalsurplus_captive = sum(capitalsurplus_captive,na.rm=TRUE),
                                                                                                                           amount_reinsured = sum(amount_reinsured,na.rm=TRUE))

excess_reserve_ratio = data_gaap_ss$reserve_statutory_gaap_ratio - 1
data_supplement_10ks_iowa_stateyr$kappa_statutory = data_supplement_10ks_iowa_stateyr$capitalsurplus_captive / data_supplement_10ks_iowa_stateyr$amount_reinsured
data_supplement_10ks_iowa_stateyr$kappa_economic = data_supplement_10ks_iowa_stateyr$kappa_statutory * (1 + excess_reserve_ratio) / vega + excess_reserve_ratio / vega
data_supplement_10ks_iowa_stateyr$kappa = data_supplement_10ks_iowa_stateyr$kappa_statutory

data_supplement_stateyr_all = merge(df2_stateyr[,c("REINSSTATEDOMICILED","year",
                                                   "is_exempt","A_hat","A_hat_N","L_hat_times_1_plus_rho","kappa_supplement","kappa_supplement_reported","kappa_supplement_a_hat","allow_prescribed","L_hat_times_1_plus_rho_ln")],
                                    data_supplement_10ks_iowa_stateyr,by=c("REINSSTATEDOMICILED","year"),all.x=TRUE,all.y=TRUE)

data_supplement_stateyr_all$kappa_statutory[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2018)] = mean(data_supplement_stateyr_all$kappa_statutory[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)
data_supplement_stateyr_all$kappa_economic[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2018)] = mean(data_supplement_stateyr_all$kappa_economic[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)
data_supplement_stateyr_all$kappa[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2018)] = mean(data_supplement_stateyr_all$kappa[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)

data_supplement_stateyr_all$kappa_statutory[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2017)] = mean(data_supplement_stateyr_all$kappa_statutory[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)
data_supplement_stateyr_all$kappa_economic[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2017)] = mean(data_supplement_stateyr_all$kappa_economic[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)
data_supplement_stateyr_all$kappa[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2017)] = mean(data_supplement_stateyr_all$kappa[which(data_supplement_stateyr_all$REINSSTATEDOMICILED == "MI" & data_supplement_stateyr_all$year == 2016)],na.rm=TRUE)

df2_insurerstateyr$is_supplement = 1
df2_insurerstateyr = df2_insurerstateyr %>% select(CEDENTSNLTOPENTITYKEY,year,REINSSTATEDOMICILED,everything())
data_supplement_10ks_iowa$is_10ks_iowa = 1
data_supplement_insurerstateyr_all = merge(data_supplement_10ks_iowa,df2_insurerstateyr,by=c("CEDENTSNLTOPENTITYKEY","REINSSTATEDOMICILED","year"),all.x=TRUE,all.y=TRUE)

data_supplement_insurerstateyr_all = data_supplement_insurerstateyr_all %>% select(CEDENTSNLTOPENTITYKEY,REINSSTATEDOMICILED,year,is_supplement,is_10ks_iowa,XXXAXXXSTATRESVCREDITTAKEN,capitalsurplus_captive,everything())

filetype = "InsuranceStatutoryFinancials"

data_grossreserves <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials_Reserves/InsuranceStatutoryFinancials_Reserves.xls")
data_grossreserves_group <- readxl::read_xls("../raw/SNL/InsuranceStatutoryFinancials_Reserves/InsuranceStatutoryFinancials_Reserves_Group.xls")

data_grossreserves <- cleanSNLfiles(data_grossreserves,filetype)
data_grossreserves_group <- cleanSNLfiles(data_grossreserves_group,filetype)

data_grossreserves <- reshapeSNLfiles(data_grossreserves,filetype)
data_grossreserves_group <- reshapeSNLfiles(data_grossreserves_group,filetype)

data_grossreserves <- as.data.table(data_grossreserves)[,ENTITYNAME:=NULL]
data_grossreserves_group <- as.data.table(data_grossreserves_group)[,ENTITYNAME:=NULL]

data_grossreserves$RESERVESGROSS = rowSums(data_grossreserves[,c("ANNUITIESGROSS","LIFEINSURANCEGROSS")],na.rm=TRUE)
data_grossreserves_group$RESERVESGROSS = rowSums(data_grossreserves_group[,c("ANNUITIESGROSS","LIFEINSURANCEGROSS")],na.rm=TRUE)

data <- merge(data,
              data_grossreserves,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

data_group <- merge(data_group,
                    data_grossreserves_group,
                    by=c("SNLSTATENTITYKEY","year"),
                    all.x=TRUE)

if (sum(is.na(data$RESERVESGROSS[which(!is.na(data$TOTALASSETS))])) > 100){
  stop("FAILED: too many NA's in gross reserves")
}

us_states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI",
               "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI",
               "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC",
               "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT",
               "VT", "VA", "WA", "WV", "WI", "WY")

data_scheduley <- fread("../raw/SNL/ScheduleY/Life Sch Y Part 1A 24Q3/L24Q3066.csv", stringsAsFactors = FALSE)

col_names <- c("COCODE", "LINE_NO", "QUARTER", "GRP_CODE", "GRP_NM", "NAIC_COMPANY_CODE",
               "ID_NBR", "FED_RSSD", "CIK", "NM_OF_SECURITIES_EXCHANGE_IF_P",
               "NM_OF_PARENT_SUBSIDIARIES_OR_A", "DOM_LOCATION",
               "RELATIONSHIP_TO_REPORTING_ENTI", "DIRECTLY_CNTRL_BY",
               "TYPE_OF_CONTROL", "IF_CONTROL_IS_OWNERSHIP_PROVID",
               "ULTIMATE_CONTROLLING_ENTITYIES", "IS_AN_SCA_FILING_REQUIRED",
               "ASTERISK", "LEI")
colnames(data_scheduley) <- col_names

data_scheduley = data_scheduley[which(data_scheduley$DOM_LOCATION != "~"),]

data_scheduley <- data_scheduley %>%
  group_by(COCODE) %>%
  summarise(
    num_unique_dom_location = n_distinct(DOM_LOCATION, na.rm = TRUE),
    num_non_us_states = n_distinct(DOM_LOCATION[!DOM_LOCATION %in% us_states], na.rm = TRUE),
    num_us_states = n_distinct(DOM_LOCATION[DOM_LOCATION %in% us_states], na.rm = TRUE),
    sorted_unique_dom_location = ifelse(
      length(unique(DOM_LOCATION)) == 0,
      "",
      str_c(sort(unique(DOM_LOCATION)), collapse = ", ")
    )
  )

data_commissions = list()
data_commissions[[1]] = fread("../raw/EGT/Life insurance commissions/COMMISSIONS_ordinary_life.csv")
data_commissions[[2]] = fread("../raw/EGT/Life insurance commissions/ISSUED_amount_ordinary_life.csv")
data_commissions[[3]] = fread("../raw/EGT/Life insurance commissions/PREMIUMS_ordinary_life.csv")
data_commissions[[4]] = fread("../raw/EGT/Life insurance commissions/year1premium_direct_ordinary_life.csv")

filetype = "InsuranceStatutoryFinancials"

for (i in seq(1,4,1)){
  data_commissions[[i]] = cleanSNLfiles(data_commissions[[i]],filetype)
  data_commissions[[i]] = data_commissions[[i]][!duplicated(data_commissions[[i]]$ENTITYNAME),]
  data_commissions[[i]] = reshapeSNLfiles(data_commissions[[i]],filetype)
}

data_commissions_all = Reduce(function(x, y) merge(x, y, by = c("ENTITYNAME","SNLSTATENTITYKEY","year"), all = TRUE), data_commissions)

data_commissions_all = as.data.table(data_commissions_all)[,ENTITYNAME:=NULL]

data <- merge(data,
              data_commissions_all,
              by=c("SNLSTATENTITYKEY","year"),
              all.x=TRUE)

data$NAICOWNSTRUCTURE_is_mutual = as.numeric(data$NAICOWNSTRUCTURE == "Mutual Company")

data$publicly_traded_TICKER = as.numeric(((data$TICKER != "") & (!is.na(data$TICKER))))
data$publicly_traded = as.numeric(((data$TICKER != "") & (!is.na(data$TICKER))) | ((data$SECSEXCHANGE != "") & (!is.na(data$SECSEXCHANGE))) | ((data$ULTPARENTSECSEXCHANGE != "") & (!is.na(data$ULTPARENTSECSEXCHANGE))))

data_group$publicly_traded_TICKER = as.numeric(((data_group$TICKER != "") & (!is.na(data_group$TICKER))))
data_group$publicly_traded = as.numeric(((data_group$TICKER != "") & (!is.na(data_group$TICKER))) | ((data_group$SECSEXCHANGE != "") & (!is.na(data_group$SECSEXCHANGE))) | ((data_group$ULTPARENTSECSEXCHANGE != "") & (!is.na(data_group$ULTPARENTSECSEXCHANGE))))

data$BUSINESSFOCUS_life = as.numeric(grepl("Life",data$BUSINESSFOCUS))
data$BUSINESSFOCUS_annuity = as.numeric(grepl("Annuity",data$BUSINESSFOCUS))
data$BUSINESSFOCUS_lifeorannuity = as.numeric(grepl("Life|Annuity",data$BUSINESSFOCUS))
data$BUSINESSFOCUS_none = as.numeric(data$BUSINESSFOCUS == "")

data_group$BUSINESSFOCUS_life = as.numeric(grepl("Life",data_group$BUSINESSFOCUS))
data_group$BUSINESSFOCUS_annuity = as.numeric(grepl("Annuity",data_group$BUSINESSFOCUS))
data_group$BUSINESSFOCUS_lifeorannuity = as.numeric(grepl("Life|Annuity",data_group$BUSINESSFOCUS))
data_group$BUSINESSFOCUS_none = as.numeric(data_group$BUSINESSFOCUS == "")

fwrite(data,file="output/SNL_Financials.csv")
fwrite(data_group,file="output/SNL_Financials_Group.csv")

fwrite(parts_all,file="output/SNL_Quantities.csv")

fwrite(average_metrics,file='output/SNL_Quantities_MarketConcentration_GroupLevel.csv')

fwrite(data_reins_all_out2,file="output/SNL_Reinsurance_AgreementLevel.csv")
fwrite(data_reins_all_out2_captiveonly,file="output/SNL_Reinsurance_Captives_AgreementLevel.csv")
fwrite(data_reins_all_out2_insurerstateyr,file="output/SNL_Reinsurance_Captives_InsurerStateYear.csv")
fwrite(df2_output,file="output/SNL_Reinsurance_SupplementalFiling.csv")

fwrite(data_reins_all_out2_captiveonly_ky,file="output/SNL_Reinsurance_Captives_AgreementLevel_KY.csv")
fwrite(data_reins_all_out2_insurerstateyr_ky,file="output/SNL_Reinsurance_Captives_InsurerStateYear_KY.csv")
fwrite(data_reins_all_out2_captiveonly_ky_shadow,file="output/SNL_Reinsurance_Captives_AgreementLevel_KYShadow.csv")
fwrite(data_reins_all_out2_insurerstateyr_ky_shadow,file="output/SNL_Reinsurance_Captives_InsurerStateYear_KYShadow.csv")

fwrite(data_impairments,file="output/SNL_Impairments.csv")

fwrite(data_gaap_ss,file="output/SNL_Reserves_Statutory_GAAP_Ratio.csv")
fwrite(data_gaap,file="output/SNL_Reserves_Statutory_GAAP_Ratio_All.csv")
fwrite(df2_rho_ss,file="output/SNL_Reserves_Statutory_GAAP_Ratio_Captives.csv")

fwrite(data_basic_info,file="output/SNL_Basic_Info.csv")
fwrite(data_basic_info_alllevels,file="output/SNL_Basic_Info_AllLevels.csv")

fwrite(data_reserves_vas,file="output/SNL_VAReserves.csv")

fwrite(data_exams,file="output/SNL_Exams.csv")

opco_capreq = sum(data$SURPLUSASREGARDSPOLICYHOLDERS[which(!is.na(data$SURPLUSASREGARDSPOLICYHOLDERS) & !is.na(data$TOTALLIAB))],na.rm=TRUE)/sum(data$TOTALLIAB[which(!is.na(data$SURPLUSASREGARDSPOLICYHOLDERS) & !is.na(data$TOTALLIAB))],na.rm=TRUE)
opco_capreq = data.frame(SURPLUSASREGARDSPOLICYHOLDERS_TOTALLIAB = opco_capreq)
fwrite(opco_capreq,file="output/SNL_OpCoCapitalRatios.csv")

fwrite(data_incorporationdate,file="output/SNL_DateIncorporated.csv")

data_basic_info_group$SNLTOPENTITYNAME = data_basic_info_group$ENTITYNAME
data_basic_info_group$SNLTOPENTITYNAME[which(!is.na(data_basic_info_group$SNLGROUPNAME))] = data_basic_info_group$SNLGROUPNAME[which(!is.na(data_basic_info_group$SNLGROUPNAME))]
data_basic_info_group = data_basic_info_group[,c("SNLTOPENTITYKEY","SNLTOPENTITYNAME","ULTPARENTSECSEXCHANGE")]
names(data_basic_info_group) = c("CEDENTSNLTOPENTITYKEY","CEDENTSNLTOPENTITYNAME","CEDENTSNLTOPENTITYEXCHANGE")
data_basic_info_group$CEDENTSNLTOPENTITYPUBLICLYTRADED = as.numeric(data_basic_info_group$CEDENTSNLTOPENTITYEXCHANGE != "")

fwrite(data_supplement_insurerstateyr_all,"output/SNL_CaptiveCapitalRates_InsurerStateYear.csv")
fwrite(data_supplement_stateyr_all,"output/SNL_CaptiveCapitalRates_StateYear.csv")

fwrite(data_basic_info_group,"output/SNL_Basic_Info_GroupNames.csv")

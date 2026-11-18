### Global
source("../lib/r/Functions.R")

##### Load Data
#### 1. Captives
### 1.1 Read Files
data_captives_list <- list()
i = 1
for (year_this in c(2007,2008,2009,2010,2011,2012,2014,2016,2018,2020)){
  data_captives_this <- readxl::read_xlsx("../raw/III/III_Captives.xlsx",sheet = paste0(year_this,""))
  data_captives_this$State <- gsub("[^A-Za-z ]","",data_captives_this$State)
  data_captives_list[[i]] <- data_captives_this
  i = i+1
}
data_captives <- Reduce(function(x, y) merge(x, y, all=TRUE), data_captives_list)

### 1.2 Rename Columns
names(data_captives)[which(names(data_captives) != "State")] <- paste0("Captives_",names(data_captives)[which(names(data_captives) != "State")])

#### 2. Premiums
### 2.1 Read Files
data_dpw_list <- list()
i = 1
for (year_this in seq(2008,2020,1)){
  data_dpw_this <- readxl::read_xlsx("../raw/III/III_DPW_PC.xlsx",sheet = paste0(year_this,""))
  data_dpw_this$State <- gsub("[^A-Za-z ]","",data_dpw_this$State)
  data_dpw_list[[i]] <- data_dpw_this
  i = i+1
}
data_dpw <- Reduce(function(x, y) merge(x, y, all=TRUE), data_dpw_list)

### 2.2 Rename Columns
names(data_dpw)[which(names(data_dpw) != "State")] <- paste0("DPW_",names(data_dpw)[which(names(data_dpw) != "State")])

##### Clean Data
### Merge Data
data <- merge(data_captives,data_dpw,by=c("State"),all.x=TRUE,all.y=TRUE)

### Fill in Data
data <- as.data.frame(data)
data[(is.na(data))] <- 0

### Exclude US
data <- data[which(data$State != "United States"),]

# Rename DC
data$State[which(data$State == "DC")] <- "District of Columbia"

##### Output
saveRDS(data,file="output/StateYear.rds")

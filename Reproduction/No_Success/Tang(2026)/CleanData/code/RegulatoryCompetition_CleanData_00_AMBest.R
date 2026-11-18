### Global
source("../lib/r/Functions.R")

##### Load Data
data_default <- fread("../raw/AMBest/AMBest_Impairment_Transition_Tables.csv")

##### Rescale Data based on Koijen and Yogo (2016)
p_default_impairment = 0.22
data_default[,2:ncol(data_default)] <- data_default[,2:ncol(data_default)] / 100 * p_default_impairment

##### Output to CSV
fwrite(data_default, file="output/AMBest_Impairment_Transition_Tables.csv")
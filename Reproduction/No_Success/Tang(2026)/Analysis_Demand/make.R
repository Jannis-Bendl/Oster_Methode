### Global
setwd(dirname(normalizePath(sys.frame(1)$ofile)))
source("../lib/r/Functions.R")

# Create Required Directories
dir.create("../Analysis_Insurer/output/summary_stats", 
           recursive = TRUE, 
           showWarnings = TRUE,)

##### Run Scripts
#### 1. RegulatoryCompetition_Analysis_Demand_01_CreateData.R
case = 'baseline'
source("code/RegulatoryCompetition_Analysis_Demand_01_CreateData.R")
rm(list = ls())
gc()

#### 2. RegulatoryCompetition_Analysis_Demand_02_Analysis.R
case = 'baseline'
source("code/RegulatoryCompetition_Analysis_Demand_02_Analysis.R")
rm(list = ls())
gc()

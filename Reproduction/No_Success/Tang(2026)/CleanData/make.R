### Global
# Set Working Directory relative to this script
setwd(dirname(normalizePath(sys.frame(1)$ofile)))
source("../lib/r/Functions.R")

##### Run Scripts
#### 0. RegulatoryCompetition_CleanData_AMBest.R
source("code/RegulatoryCompetition_CleanData_00_AMBest.R")
rm(list = ls())
gc()

#### 1. RegulatoryCompetition_CleanData_III.R
source("code/RegulatoryCompetition_CleanData_01_III.R")
rm(list = ls())
gc()

#### 3. RegulatoryCompetition_CleanData_SNL.R
source("code/RegulatoryCompetition_CleanData_02_SNL.R")
rm(list = ls())
gc()

#### 4. RegulatoryCompetition_CleanData_CompuLife.R
source("code/RegulatoryCompetition_CleanData_03_CompuLife.R")
rm(list = ls())
gc()

#### 6. RegulatoryCompetition_CleanData_Other.R
source("code/RegulatoryCompetition_CleanData_04_Other.R")
rm(list = ls())
gc()

#### 7. RegulatoryCompetition_CleanData_Consumers_MergeAll.R
source("code/RegulatoryCompetition_CleanData_05_Consumers_MergeAll.R")
rm(list = ls())
gc()
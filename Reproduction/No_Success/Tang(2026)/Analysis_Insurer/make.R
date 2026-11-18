### Global
setwd(dirname(normalizePath(sys.frame(1)$ofile)))
source("../lib/r/Functions.R")

##### Run Scripts
#### 1. RegulatoryCompetition_Analysis_Insurer_CapitalAllocation_CreateData.R
source("code/RegulatoryCompetition_Analysis_Insurer_01_CapitalAllocation_CreateData.R")
rm(list = ls())
gc()

#### 2. RegulatoryCompetition_Analysis_Insurer_CapitalAllocation_ReducedForm.R
source("code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R")
rm(list = ls())
gc()

#### 3. RegulatoryCompetition_Analysis_Insurer_Price_ReducedForm.R
source("code/RegulatoryCompetition_Analysis_Insurer_51_ReducedForm_Price.R")
rm(list = ls())
gc()

#### 4. Solve All Cases
cases_all = c('baseline','costfunction','commissions','guarantyfundfunding','omegaten','prestablesample',"thetazero","thetafive","profitshare")
# Uncomment the line below to only run the baseline case:
# cases_all = cases_all[0:1]
for (case in cases_all){
  source("code/RegulatoryCompetition_Analysis_Insurer_10_Solve_All_Cases.R")
  rm(list = ls())
  gc()
}

#### In addition, run the following scripts in Stata and Python respectively:
#### 4: RegulatoryCompetition_Analysis_Insurer_50_ReducedForm_DefaultBonds.do
#### 5. RegulatoryCompetition_Analysis_Insurer_99_JPE.py

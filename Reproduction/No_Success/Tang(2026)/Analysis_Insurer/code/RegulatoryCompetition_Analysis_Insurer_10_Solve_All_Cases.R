### Global
source("../lib/r/Functions.R")
cases_perturbations = c('baseline','costfunction','commissions','guarantyfundfunding','omegaten','prestablesample')
cases_fastcompute = c("thetazero","prestablesample","profitshare","guarantyfundfunding")

case = "baseline"
tau = 0.0016

## tau_h: Direct Premiums Tax Rate
tau_direct_premiums = 0.005

## V: actuarial value of insurance policies
V = fread(get_filename_case("../CleanData/output/CompuLife_All.csv",case))
V = mean(V$V,na.rm=TRUE)

## Rf: discount rate
Rf = 0.05

kappa_h = fread("../CleanData/output/kappa_h.csv")
kappa_h = kappa_h$kappa_h_K_div_L[1]

p_default_impairment = 0.22
omega = (-1) * 0.25
theta = fread("output/ProductPrice/theta.csv")
theta = theta$theta

## L_div_Q: ratio of future policy payouts to annual payouts
L_div_Q = fread("../CleanData/output/L_div_Q.csv")
L_div_Q = L_div_Q$L_div_Q[1]

## Fraction of the Guaranty Fund that is Funded by Other Insurers
# Only used in the Guaranty Fund Alternative Funding counterfactual
frac_guarantyfund_insurerfunded = 0

## Demand Instruments
demand_iv = "hausman"

### Define Variables to Keep and Not Delete
vars_to_keep <- ls()

dict <- c(case = "baseline")
if (case == "thetazero") dict <- c(case = "thetazero", theta = 0)

##### theta = 5%
if (case == "thetafive") dict <- c(case = "thetafive", theta = 0.05)

##### omega = 10%
if (case == "omegaten") dict <- c(case = "omegaten", omega = -0.10)

#################### 1.3 Alternative Instruments ####################
##### Demand IV: Commissions
if (case == "commissions") dict <- c(case = "commissions", demand_iv = "commissions")

#################### 1.4 Cost Function for Captive Allocation ####################
if (case == "costfunction") dict <- c(case = "costfunction")

#################### 1.5 Guaranty Fund Alternative Funding ####################
if (case == "guarantyfundfunding") dict <- c(case = "guarantyfundfunding", frac_guarantyfund_insurerfunded = 0.8)

#################### 1.6 Profit Sharing: Split by Investor Weights ####################
if (case == "profitshare") dict <- c(case = "profitshare")

#################### 1.7 Full sample: using pre-2013 data as well ('prestablesample') ####################
if (case == "prestablesample") dict <- c(case = 'prestablesample')

#################### Make Case Assignments ####################
for (name in names(dict)) {
  value <- dict[name]
  # Convert to numeric if it's a numeric string, otherwise keep as character
  assign(name, if (suppressWarnings(!is.na(as.numeric(value)))) as.numeric(value) else as.character(value))
}

#################### 2. Run the Cases ####################
#### 4. RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R
# Set Parameters
source("code/RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R")
vars_to_remove <- setdiff(ls(), vars_to_keep)
rm(list = vars_to_remove)
gc()

#### 6. RegulatoryCompetition_Analysis_Regulator_Solve.R
source("code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R")
vars_to_remove <- setdiff(ls(), vars_to_keep)
rm(list = vars_to_remove)
gc()

#### 8. RegulatoryCompetition_Analysis_Insurer_SummaryStatistics.R
source("code/RegulatoryCompetition_Analysis_Insurer_09_SummaryStatistics.R")
vars_to_remove <- setdiff(ls(), vars_to_keep)
rm(list = vars_to_remove)
gc()

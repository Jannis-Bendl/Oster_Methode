* Replicate BALLANCE TESTS based on specification V5 in AaronRegressions but with disappeared_landscape1_lag
* and with parent organization dummies instead of any other plan characteristics

include "04analysis/AnalysisConfigurations/PlanCharsRegressions/PlanCharsRegressions.do"

local options `options' term(disappeared_landscape1_lag)
local options `options' xlsheet(Version Parent)
local options `options' ifglobal(if year >= 2008)
local options `options' ifconsol(if relationship_code_lag == "C")
local options `options' ifempterm(if dis_plan_80_lag == 1)
local options `options' ifcommand(if true_mMA2_lag == 1)
local options `options' ifpostterm(if dis_plan_80_post_lag != 1))
local options `options' pct(100)
local options `options' alpha(mucbin_mleCYBPlan)


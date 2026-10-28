* REGRESSIONS based for combined all years years and all terminations

include "04analysis/AnalysisConfigurations/BaselineStuff-take4/BaselineStuff.do"

local options `options' xlwb(BaselineStuff-take-4-noPFFS.xlsx)
local options `options' term(disappeared_landscape1_lag)
local options `options' xlsheet(Regs)
local options `options' ifglobal(if year >= 2008)
local options `options' ifconsol(if relationship_code_lag == "C")
local options `options' ifempterm(if dis_plan_80_lag == 1)
local options `options' ifcommand(if true_mMA2_lag == 1)
local options `options' ifpostterm(if dis_plan_80_post_lag != 1)
local options `options' pct(01)
local options `options' alpha(mucbin_mleCYBPlan)
local options `options' bene_demo_noTerm
local options `options' excl_pffs_term

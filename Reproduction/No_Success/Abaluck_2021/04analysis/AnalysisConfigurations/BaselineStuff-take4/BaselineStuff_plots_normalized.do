* A configuration for the "default" plot

include "04analysis/AnalysisConfigurations/BaselineStuff-take4/BaselineStuff.do"

local options `options' term(disappeared_landscape1)
local options `options' xlsheet(Version 9)
local options `options' ifglobal(if year >= 2008)
local options `options' ifconsol(if relationship_code == "C")
local options `options' ifempterm(if dis_plan_80 == 1)
local options `options' ifcommand(if true_mMA2 == 1)
local options `options' ifpostterm(if dis_plan_80_post != 1)
local options `options' ifmibin(if mi(`bin_var'))
local options `options' ifmitrueMA(if mi(true_mMA2))
local options `options' pct(100)
local options `options' alpha(mucbin_mleCYBPlan)
local options `options' plotsVersion(6)

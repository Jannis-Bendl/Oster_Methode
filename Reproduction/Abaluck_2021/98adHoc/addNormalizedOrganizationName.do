* ---------------------------------------------------------------------
* Title:    Generate normalized organization name
* Blame:    Mauricio Caceres (mauricio.caceres.bravo@gmail.com)
* Created:  Friday, July 3rd, 2020
* Purpose:  Cleans up organizationname, grouping relevant plan owners
* ---------------------------------------------------------------------

local Humana  humana
local BCBS    bcbs|blue.*cross|blue.*shield
local United  united.*health(.*care)?|securehorizon
local Kaiser  kaiser
local Parents Humana BCBS United Kaiser

forvalues i = 1 / 2 {
    local lag = cond(`i' == 2, "_lag", "")
    gen organization_normalized`lag' = organizationname`lag'

    * TODO: xx check in the new data for names that might also be bcbs
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "blue medicare hmo")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "senior blue")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "blue care network")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "traditional blue medicare ppo")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "blue medicare ppo")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "bluemedicare regional ppo")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "bluechoice healthplan")
    replace organization_normalized`lag' = "BCBS" if strpos(lower(organization_normalized`lag'), "forever blue medicare ppo")

    foreach Parent of local Parents {
        replace organization_normalized`lag' = `"`Parent'"' if regexm(lower(organization_normalized`lag'), `"``Parent''"')
    }
}

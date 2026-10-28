cap adopath - /home/site/etc/stata/ado.nber/updates
cap adopath - /home/site/etc/stata/ado.nber

ssc install gtools,      replace
ssc install scheme-burd, replace
ssc install ranktest,    replace
ssc install maptile,     replace
ssc install spmap,       replace

local sergio https://raw.githubusercontent.com/sergiocorreia

cap ado uninstall reghdfe
cap ado uninstall ftools
cap ado uninstall ivreg2hdfe
cap ado uninstall ivreghdfe

net install reghdfe, from(`sergio'/reghdfe/master/src/) replace
net install ftools,  from(`sergio'/ftools/master/src/)  replace

reghdfe, compile
ftools,  compile
gtools,  upgrade

cap ssc install ivreg2
net install ivreghdfe, from(`sergio'/ivreghdfe/master/src/) replace

cap reghdfe
cap ivreghdfe

/* NOTE: To customize the map further, I directly edit the
 * package's program in
 *
 *     ~/ado/personal/maptile_geographies/county2010_maptile.ado
 *
 * Notably, I changed the oc() and ndo() from "black" to "gs3".
 */

maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
* maptile_geohelp county2010
* maptile_install using "http://files.michaelstepner.com/geo_county2014.zip"
* maptile_geohelp county2014

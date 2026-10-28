clear

/*Set filepath below*/

global filepath 
cd "$filepath"
sysdir set PLUS "$filepath/code/ado_plus"
sysdir

global system 15


do "$filepath/code/xu_make_data.do"

do "$filepath/code/xu_tables.do"

do "$filepath/code/xu_figures.do"

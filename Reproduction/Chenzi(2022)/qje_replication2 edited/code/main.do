clear

/*Set filepath below*/

global filepath "C:\Users\jabef\Desktop\FU Job\Prof.Marcus\Python_Scraper\Oster_Methode\Reproduction\Chenzi(2022)\qje_replication2 edited"
cd "$filepath"
sysdir set PLUS "$filepath/code/ado_plus"
sysdir

global system 15


do "$filepath/code/xu_make_data.do"

do "$filepath/code/xu_tables.do"

do "$filepath/code/xu_figures.do"

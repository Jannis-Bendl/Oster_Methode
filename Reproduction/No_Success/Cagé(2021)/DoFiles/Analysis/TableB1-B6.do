********************************************************************************
********************************************************************************
** Date: August 2020	--> October 2020	--> May 2021 (add 1919 data)	--> Feb 2022 (add 2nd round 1936)
********************************************************************************
********************************************************************************

* 1914
use "$Data_origin/Elections/all_elections_1914_metropole_reshape_ccomune_idgeofla.dta", clear

* Compute for each party vote share
* Also compute turnout
	* Rank the parties from left to right 
foreach party in SFIO REPSOC RADSOC RADIND PRDS Progressistes ALP Divers {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}		
****************************************
* Check that some votes never > suffrages exprimes 
gen sum_votes=vote_share_SFIO + vote_share_REPSOC + vote_share_RADSOC + vote_share_RADIND + vote_share_PRDS + vote_share_Progressistes  + vote_share_ALP + vote_share_Divers
sum sum_votes, d
drop sum_votes	
* Extraction des erreurs turnout 
gen turnout=(Votants/Electeursinscrits)*100
sum turnout, d
replace turnout=. if turnout>100

label var vote_share_SFIO "SFIO"
label var vote_share_REPSOC "REP-SOC"
label var vote_share_RADSOC "RAD-SOC"
label var vote_share_RADIND "RAD-IND"
label var vote_share_PRDS "PRDS"
label var vote_share_Progressistes "Progressistes"
label var vote_share_ALP "ALP"
label var vote_share_Divers "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"

global stat_vote1914 vote_share_SFIO vote_share_REPSOC vote_share_RADSOC vote_share_RADIND vote_share_PRDS vote_share_Progressistes vote_share_ALP vote_share_Divers turnout

eststo clear
estpost sum $stat_vote1914, d
eststo : esttab using "$Results/Tables/TableB1.tex", label replace ///
cells("mean(fmt(%15.1fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.1fc) label(Median)) p75(fmt(%15.1fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
	nonum ///
	refcat(vote_share_SFIO "\textbf{Vote share - Left}" vote_share_REPSOC "\textbf{Vote share - Center left}" vote_share_RADIND "\textbf{Vote share - Center right}" vote_share_PRDS "\textbf{Vote share - Right}" vote_share_Divers "\textbf{ }" turnout "\textbf{ }", nolabel) 	
 

 
********************************************************************************
********************************************************************************
* 1919
use "$Data_origin/Elections/all_elections_1919_metropole_reshape_ccomune_idgeofla.dta", clear

* Compute for each party vote share
* Also compute turnout
	* Rank the parties from left to right 
foreach party in ExtremeGauche Communiste SFIO DiversGauche PRRS REPSOC RADIND GaucheRadicale ARD GRD RG FRURD UNR ARS ERD BlocNational AnciensCombattants DiversDroite ActionFrancaise ExtremeDroite Divers {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}			
	
* IMPORTANT : etant donne le mode de scrutin en place en 1924 - où les électeurs votent autant de fois que le nombre de députés à élire dans la circonscription - on ne peut pas calculer comme pour 1919 (où les autres années à l'exception de 1914) les votes share des différents partis en utilisant les suffrages exprimés.
* Alternative : variable de Voix qui calcule le nombre de voix effectivement prises en compte pour l'élection de chaque liste
	
* Extraction des erreurs turnout 
gen turnout=(Votants/Electeursinscrits)*100
sum turnout, d
replace turnout=. if turnout>100

label var vote_share_ExtremeGauche "Extreme left"
label var vote_share_Communiste "PCF"
label var vote_share_SFIO "SFIO"
label var vote_share_DiversGauche "Miscellaneous left"
label var vote_share_PRRS "PRRS"
label var vote_share_REPSOC "REP-SOC"
label var vote_share_RADIND "RAD-IND (Bloc National)"
label var vote_share_GaucheRadicale "Gauche Radicale"
label var vote_share_ARD "ARD (Bloc National)"
label var vote_share_GRD "GRD (Bloc National)"
label var vote_share_RG "RG"
label var vote_share_FRURD "FR-URD (Bloc National)"
label var vote_share_UNR "UNR (Bloc National)"
label var vote_share_ARS "ARS (Bloc National)"
label var vote_share_ERD "ERD (Bloc National)"
label var vote_share_BlocNational "Bloc National (other)"
label var  vote_share_AnciensCombattants "Anciens Combattants (Veterans)"
label var vote_share_DiversDroite "Miscellaneous right"
label var vote_share_ActionFrancaise "Action Francaise"
label var vote_share_ExtremeDroite "Extreme right"
label var vote_share_Divers "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"

global stat_vote1919 vote_share_Communiste vote_share_SFIO vote_share_DiversGauche vote_share_PRRS vote_share_REPSOC vote_share_RADIND vote_share_GaucheRadicale vote_share_ARD vote_share_GRD vote_share_RG vote_share_FRURD vote_share_UNR vote_share_ARS vote_share_ERD vote_share_BlocNational vote_share_AnciensCombattants vote_share_DiversDroite vote_share_ActionFrancaise vote_share_Divers turnout

eststo clear
estpost sum $stat_vote1919, d
esttab using "$Results/Tables/TableB2.tex", label replace ///
cells("mean(fmt(%15.3fc %15.2fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.3fc %15.2fc) label(Median)) p75(fmt(%15.2fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
	nonum ///
	refcat(vote_share_Communiste "\textbf{Vote share - Extreme Left}" vote_share_SFIO "\textbf{Vote share - Left}" vote_share_PRRS "\textbf{Vote share - Center left}" vote_share_RADIND "\textbf{Vote share - Center right}" vote_share_FRURD "\textbf{Vote share - Right}" vote_share_ActionFrancaise "\textbf{Vote share - Extreme Right}" vote_share_Divers "\textbf{ }" turnout "\textbf{ }", nolabel) 	
 


********************************************************************************
********************************************************************************
* 1924
use "$Data_origin/Elections/all_elections_1924_metropole_reshape_ccomune_idgeofla.dta", clear
count
count if Suffragesexprimes==.

foreach party in BOP SFIO DVG RADSOC REPSOC REPRAD RG ERD Conservateur Divers {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}	
count	

* Extraction des erreurs turnout 
gen turnout=(Votants/Electeursinscrits)*100
sum turnout, d
replace turnout=. if turnout>100

label var vote_share_BOP "BOP"
label var vote_share_SFIO "SFIO"
label var vote_share_DVG "Miscellaneous left"
label var vote_share_RADSOC "RAD-SOC"
label var vote_share_REPSOC "REP-SOC"
label var vote_share_REPRAD "REP-RAD"
label var vote_share_RG "RG"
label var vote_share_ERD "ERD"
label var vote_share_Conservateur "Conservateur"
label var vote_share_Divers "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"

global stat_vote1924 vote_share_BOP vote_share_SFIO vote_share_DVG vote_share_RADSOC vote_share_REPSOC vote_share_REPRAD vote_share_RG vote_share_ERD vote_share_Conservateur vote_share_Divers turnout

eststo clear
estpost sum $stat_vote1924, d
eststo : esttab using "$Results/Tables/TableB3.tex", label replace ///
cells("mean(fmt(%15.1fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.1fc) label(Median)) p75(fmt(%15.1fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
	nonum ///
	refcat(vote_share_BOP "\textbf{Vote share - Extreme left}" vote_share_SFIO "\textbf{Vote share - Left}" vote_share_RADSOC "\textbf{Vote share - Center left}" vote_share_REPRAD "\textbf{Vote share - Center right}" vote_share_ERD "\textbf{Vote share - Right}" vote_share_Divers "\textbf{ }" turnout "\textbf{ }", nolabel) 		


********************************************************************************
********************************************************************************
* 1932
use "$Data_origin/Elections/all_elections_1932_metropole_reshape_ccomune_idgeofla.dta", clear
count
count if Suffragesexprimes==.	

*****************	
foreach party in PCF SFIO DVG REP_SOC RAD_SOC DIV AD_RG AD_IND AD_PDP FR_URD AGR DVD {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}	
gen sum_votes=vote_share_PCF + vote_share_SFIO + vote_share_DVG + vote_share_REP_SOC + vote_share_RAD_SOC + vote_share_DIV + vote_share_AD_RG + vote_share_AD_IND  + vote_share_AD_PDP + vote_share_FR_URD + vote_share_AGR + vote_share_DVD
sum sum_votes, d
*** Il reste 5 cas a verifier aux archives, mais je pense que overall on peut considerer que c'est ok 
***************
drop sum_votes
gen turnout=(Votants/Electeursinscrits)*100		
sum turnout, d		
replace turnout=. if turnout>100

label var vote_share_PCF "PCF"
label var vote_share_SFIO "SFIO"
label var vote_share_DVG "Miscellaneous left"
label var vote_share_REP_SOC "REP-SOC"
label var vote_share_RAD_SOC "RAD-SOC"
label var vote_share_DIV "Divers"
label var vote_share_AD_RG "AD-RG"
label var vote_share_AD_IND "AD-IND"
label var vote_share_AD_PDP "AD-PDP"
label var vote_share_FR_URD "FR-URD"
label var vote_share_AGR "AGR"
label var vote_share_DVD "Miscellaneous right"
label var vote_share_DIV "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"
	
global stat_vote1932 vote_share_PCF vote_share_SFIO vote_share_DVG vote_share_REP_SOC vote_share_RAD_SOC vote_share_AD_RG vote_share_AD_IND vote_share_AD_PDP vote_share_FR_URD vote_share_AGR vote_share_DVD vote_share_DIV turnout

eststo clear
estpost sum $stat_vote1932, d
eststo : esttab using "$Results/Tables/TableB4.tex", label replace ///
cells("mean(fmt(%15.1fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.1fc) label(Median)) p75(fmt(%15.1fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
nonum ///
refcat(vote_share_PCF "\textbf{Vote share - Extreme left}" vote_share_SFIO "\textbf{Vote share - Left}" vote_share_REP_SOC "\textbf{Vote share - Center left}" vote_share_AD_RG "\textbf{Vote share - Center right}" vote_share_AD_PDP "\textbf{Vote share - Right}" vote_share_DIV "\textbf{ }" turnout "\textbf{ }", nolabel) 	


	

********************************************************************************
********************************************************************************
* 1936
use "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla.dta", clear
count

foreach party in PCF SFIO DVG USR RAD_SOC DIV AD FR_URD PRN AGR DVD FRANCISTE {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}
*****************	
gen sum_votes=vote_share_PCF + vote_share_SFIO + vote_share_DVG + vote_share_USR + vote_share_RAD_SOC + vote_share_DIV + vote_share_AD + vote_share_FR_URD + vote_share_PRN + vote_share_AGR  + vote_share_DVD + vote_share_FRANCISTE
sum sum_votes, d
drop sum_votes
gen turnout=(Votants/Electeursinscrits)*100		
sum turnout, d	
replace turnout=. if turnout>100
	
label var vote_share_PCF "PCF"
label var vote_share_SFIO "SFIO"
label var vote_share_DVG "Miscellaneous left"
label var vote_share_USR "USR"
label var vote_share_RAD_SOC "RAD-SOC"
label var vote_share_DIV "Divers"
label var vote_share_AD "AD"
label var vote_share_FR_URD "FR-URD"
label var vote_share_PRN "PRN"
label var vote_share_AGR "AGR"
label var vote_share_DVD "Miscellaneous right"
label var vote_share_FRANCISTE "Franciste"
label var vote_share_DIV "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"

global stat_vote1936 vote_share_PCF vote_share_SFIO vote_share_DVG vote_share_USR vote_share_RAD_SOC vote_share_AD vote_share_FR_URD vote_share_PRN vote_share_AGR vote_share_DVD vote_share_FRANCISTE vote_share_DIV turnout

eststo clear
estpost sum $stat_vote1936, d
eststo : esttab using "$Results/Tables/TableB5.tex", label replace ///
cells("mean(fmt(%15.2fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.2fc) label(Median)) p75(fmt(%15.2fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
nonum ///
refcat(vote_share_PCF "\textbf{Vote share - Extreme left}" vote_share_SFIO "\textbf{Vote share - Left}" vote_share_USR "\textbf{Vote share - Center left}" vote_share_AD "\textbf{Vote share - Center right}" vote_share_AGR "\textbf{Vote share - Right}"  vote_share_FRANCISTE "\textbf{Vote share - Extreme right}" vote_share_DIV "\textbf{ }" turnout "\textbf{ }", nolabel)
	
********************************************************************************
* 2nd Round
use "$Data_origin/Elections/all_elections_1936_metropole_reshape_ccomune_idgeofla_2ndRound.dta", clear
count
foreach party in PCF SFIO DVG USR RAD_SOC DIV AD FR_URD PRN AGR DVD FRANCISTE {
	gen vote_share_`party'=(`party'/Suffragesexprimes)*100
	sum vote_share_`party'
	}
	
gen sum_votes=vote_share_PCF + vote_share_SFIO + vote_share_DVG + vote_share_USR + vote_share_RAD_SOC + vote_share_DIV + vote_share_AD + vote_share_FR_URD + vote_share_PRN + vote_share_AGR  + vote_share_DVD + vote_share_FRANCISTE
sum sum_votes, d
drop sum_votes
gen turnout=(Votants/Electeursinscrits)*100		
sum turnout, d	
replace turnout=. if turnout>100
	
label var vote_share_PCF "PCF"
label var vote_share_SFIO "SFIO"
label var vote_share_DVG "Miscellaneous left"
label var vote_share_USR "USR"
label var vote_share_RAD_SOC "RAD-SOC"
label var vote_share_DIV "Divers"
label var vote_share_AD "AD"
label var vote_share_FR_URD "FR-URD"
label var vote_share_PRN "PRN"
label var vote_share_AGR "AGR"
label var vote_share_DVD "Miscellaneous right"
label var vote_share_FRANCISTE "Franciste"
label var vote_share_DIV "Vote share - Miscellaneous"
label var turnout "\textbf{Turnout}"

global stat_vote1936 vote_share_PCF vote_share_SFIO vote_share_DVG vote_share_USR vote_share_RAD_SOC vote_share_AD vote_share_FR_URD vote_share_PRN vote_share_AGR vote_share_DVD vote_share_FRANCISTE vote_share_DIV turnout

eststo clear
estpost sum $stat_vote1936, d
esttab using "$Results/Tables/TableB6.tex", label replace ///
cells("mean(fmt(%15.2fc) label(Mean)) sd(fmt(%15.1fc) label(St.Dev)) p50(fmt(%15.2fc) label(Median)) p75(fmt(%15.2fc ) label(P75)) max(fmt(%15.0fc) label(Max))") ///
nonum ///
refcat(vote_share_PCF "\textbf{Vote share - Extreme left}" vote_share_SFIO "\textbf{Vote share - Left}" vote_share_USR "\textbf{Vote share - Center left}" vote_share_AD "\textbf{Vote share - Center right}" vote_share_AGR "\textbf{Vote share - Right}"  vote_share_FRANCISTE "\textbf{Vote share - Extreme right}" vote_share_DIV "\textbf{ }" turnout "\textbf{ }", nolabel)	
	
	

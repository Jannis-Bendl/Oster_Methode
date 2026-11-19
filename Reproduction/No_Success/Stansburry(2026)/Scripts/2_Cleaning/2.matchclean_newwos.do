********************************************************************************
*Import and Clean Web Of Science Data - Publication-Level
********************************************************************************

*Load new publication-level data
use "$RAWROOT/sdrwos_pub_scalars_supp_metrics.dta", clear

*******************************************
*Examine and clean variables
*******************************************

************
**First examine numerical vars

summarize PUB_YEAR, det /*Publications between 1990 and 2017*/
histogram(PUB_YEAR)
misstable summarize PUB_YEAR /*No missing values*/
label var PUB_YEAR "Publication Year 1990-2017"

summarize PUB_JCR_IMPACTFACTOR, det /*Valid values range from 0-244.585. Missing for all pre-1997. Exclude 999.999 as it seems to indicate NULL in 1998*/
replace PUB_JCR_IMPACTFACTOR=. if PUB_JCR_IMPACTFACTOR==999.999
summarize PUB_JCR_IMPACTFACTOR, det /*Removing 999.999 generates the correct number of valid values*/
histogram(PUB_JCR_IMPACTFACTOR)
misstable summarize PUB_JCR_IMPACTFACTOR /*345,665 missing values - reasons for missing in codebook*/
label var PUB_JCR_IMPACTFACTOR "Publication Journal Impact Factor (in publication year)"

summarize NUM_PUB_JCR_RESEARCHFIELD, det /*Number of fields from journal citation report ranges from 1-9*/
histogram(NUM_PUB_JCR_RESEARCHFIELD)
misstable summarize NUM_PUB_JCR_RESEARCHFIELD /*411 null values*/
label var NUM_PUB_JCR_RESEARCHFIELD "Total number of Journal Citation Report (JCR) research fields covered for a publication"

summarize PUB_NUM_AUTHORS, det /*Authorship ranges from 1 – 5,575. Could be interesting to look at mean authorship by field to get a sense for field differences (probably true for a number of these variables)*/
histogram(PUB_NUM_AUTHORS)
misstable summarize PUB_NUM_AUTHORS /*3 null values*/
label var PUB_NUM_AUTHORS "Author count"

summarize PUB_NUM_COUNTRIES, det /*Number of countries represented by authors ranges from 1-108*/
histogram(PUB_NUM_COUNTRIES) /*Small jump up at 40 countires, examining by field may be useful*/
misstable summarize PUB_NUM_COUNTRIES /*22,570 null values*/
label var PUB_NUM_COUNTRIES "Number of distinct countries represented by authors"

summarize PUB_US, det /*US author count ranges from 0-1,436; -99 indicates at least 1 US author pre-2008. Pre-2008 they cannot indicate exactly how many. Keeping -99 as a code for now. However, it seems that -99 is a code that exists post-2008 as well*/
histogram(PUB_US)
misstable summarize PUB_US /*22,570 null values*/
label var PUB_US "US-affliated author count"
/*Based on the -99 code, create a variable indicating at least 1 US author*/
//g PUB_US_Indicator = 1 if PUB_US>0 | PUB_US==-99
replace PUB_US_Indicator = 0 if missing(PUB_US_Indicator)
label var PUB_US_Indicator "At least one US-affliated author indicator"

summarize PUB_FIRST_CITE_Y2_LAG, det /*Months to the first citation within the first two years range, as expected, between 0-24*/
histogram(PUB_FIRST_CITE_Y2_LAG) /*Spike at the 1 year mark*/
misstable summarize PUB_FIRST_CITE_Y2_LAG /*429,439 null values*/
label var PUB_FIRST_CITE_Y2_LAG "Months to the first citation including self-citations within the first two years"

summarize PUB_CITES_Y2, det /*2-year citations range between 0 – 5,650*/
histogram(PUB_CITES_Y2)
misstable summarize PUB_CITES_Y2 /*No missing values*/
label var PUB_CITES_Y2 "Two-year citations including self-citations"

summarize PUB_CITES_Y2_RA, det /*2-year citations of research articles range between 0 – 5,650*/
histogram(PUB_CITES_Y2_RA)
misstable summarize PUB_CITES_Y2_RA /*No missing values*/
label var PUB_CITES_Y2_RA "Two-year citations from research articles including self-citations"

summarize PUB_CITES_Y5, det /*5-year citations range between 0 – 5,850*/
histogram(PUB_CITES_Y5)
misstable summarize PUB_CITES_Y5 /*No missing values*/
label var PUB_CITES_Y5 "Five-year citations including self-citations"

summarize PUB_CITES_Y5_RA, det /*5-year citations of research articles range between 0 – 5,850*/
histogram(PUB_CITES_Y5_RA)
misstable summarize PUB_CITES_Y5_RA /*No missing values*/
label var PUB_CITES_Y5_RA "Five-year citations from articles or reviews including self-citations" /*Note that this is a sligtly different definition from the 2-year variable*/

summarize PUB_CITES_Y2_HIJ, det /*2-year citations of articles in high impact journals range between 0 – 938*/
histogram(PUB_CITES_Y2_HIJ)
misstable summarize PUB_CITES_Y2_HIJ /*No missing values*/
label var PUB_CITES_Y2_HIJ "Two-year citations from high impact journals including self-citations"

summarize PUB_CITES_Y5_HIJ, det /*5-year citations of articles in high impact journals range between 0 – 2,002*/
histogram(PUB_CITES_Y5_HIJ)
misstable summarize PUB_CITES_Y5_HIJ /*No missing values*/
label var PUB_CITES_Y5_HIJ "Five-year citations from high impact journals including self-citations"

summarize NUM_REFS, det /*Number of references range between 0 – 15,417; 15,417 seems to be an outlier as the next highest value is 8375*/
histogram(NUM_REFS)
histogram(NUM_REFS) if NUM_REFS<15417
misstable summarize NUM_REFS /*No missing values*/
label var NUM_REFS "Number of References"

**The following numerical variables are not in the codebook
summarize JIF_PCT, det /*Ranges between .1724138-99.85836*/
histogram(JIF_PCT)
misstable summarize JIF_PCT /*342,456 missing values*/

summarize CNCI, det /*Ranges between 0-670.1517*/
histogram(CNCI)
misstable summarize CNCI /*No missing values*/

summarize AVG_PCT, det /*Ranges between 0-100*/
histogram(AVG_PCT) /*Spike of 0s included within a spread of other PCTs*/
misstable summarize AVG_PCT /*No missing values*/

************
**Then examine string vars
/*NOTE: PUB_EDITION is a variable in the codebook that is not in this dataset; not a variable we are particularly interested in though*/

tab PUB_YEAR if pub_randid=="" /*No missing values*/
label var pub_randid "Publication ID"

tab PUB_TYPE, m /*No missing values*/
encode PUB_TYPE, gen(PUB_TYPE_hist)
histogram(PUB_TYPE_hist) /*Mostly articles*/
drop PUB_TYPE_hist
codebook PUB_TYPE
label var PUB_TYPE "Publication type (18 types)"

tab PUB_JCR_RESEARCHFIELD_A, m /*411 null values*/
encode PUB_JCR_RESEARCHFIELD_A, gen(PUB_JCR_RESEARCHFIELD_A_hist)
histogram(PUB_JCR_RESEARCHFIELD_A_hist)
drop PUB_JCR_RESEARCHFIELD_A_hist
codebook PUB_JCR_RESEARCHFIELD_A
label var PUB_JCR_RESEARCHFIELD_A "Journal Citation Report research field (254 fields)" 

tab PUB_JCR_RESEARCHFIELD_B, m /*630,394 null values*/
encode PUB_JCR_RESEARCHFIELD_B, gen(PUB_JCR_RESEARCHFIELD_B_hist)
histogram(PUB_JCR_RESEARCHFIELD_B_hist)
drop PUB_JCR_RESEARCHFIELD_B_hist
codebook PUB_JCR_RESEARCHFIELD_B
label var PUB_JCR_RESEARCHFIELD_B "Journal Citation Report research field 2 (249 categories)" 

tab PUB_JCR_RESEARCHFIELD_C, m /*990,194 null values*/
encode PUB_JCR_RESEARCHFIELD_C, gen(PUB_JCR_RESEARCHFIELD_C_hist)
histogram(PUB_JCR_RESEARCHFIELD_C_hist)
drop PUB_JCR_RESEARCHFIELD_C_hist
codebook PUB_JCR_RESEARCHFIELD_C
label var PUB_JCR_RESEARCHFIELD_C "Journal Citation Report research field 3 (218 categories)" 

tab PUB_JCR_RESEARCHFIELD_D, m /*1,163,032 null values*/
encode PUB_JCR_RESEARCHFIELD_D, gen(PUB_JCR_RESEARCHFIELD_D_hist)
histogram(PUB_JCR_RESEARCHFIELD_D_hist)
drop PUB_JCR_RESEARCHFIELD_D_hist
codebook PUB_JCR_RESEARCHFIELD_D
label var PUB_JCR_RESEARCHFIELD_D "Journal Citation Report research field 4 (183 categories)" 

tab PUB_JCR_RESEARCHFIELD_E, m /*1,206,494 null values*/
encode PUB_JCR_RESEARCHFIELD_E, gen(PUB_JCR_RESEARCHFIELD_E_hist)
histogram(PUB_JCR_RESEARCHFIELD_E_hist)
drop PUB_JCR_RESEARCHFIELD_E_hist
codebook PUB_JCR_RESEARCHFIELD_E
label var PUB_JCR_RESEARCHFIELD_E "Journal Citation Report research field 5 (131 categories)" 

tab PUB_JCR_RESEARCHFIELD_F, m /*1,216,434 null values*/
encode PUB_JCR_RESEARCHFIELD_F, gen(PUB_JCR_RESEARCHFIELD_F_hist)
histogram(PUB_JCR_RESEARCHFIELD_F_hist) /*Mostly physics*/
drop PUB_JCR_RESEARCHFIELD_F_hist
codebook PUB_JCR_RESEARCHFIELD_F
label var PUB_JCR_RESEARCHFIELD_F "Journal Citation Report research field 6 (76 categories)" 

tab PUB_HIGHIMPACTJOURNAL, m /*342,456 NA values - reasons listed in codebook*/
encode PUB_HIGHIMPACTJOURNAL, gen(PUB_HIGHIMPACTJOURNAL_hist)
histogram(PUB_HIGHIMPACTJOURNAL_hist) /*Majority false*/
drop PUB_HIGHIMPACTJOURNAL_hist
codebook PUB_HIGHIMPACTJOURNAL
label var PUB_HIGHIMPACTJOURNAL "High Impact journal (top 10% impact factor) publication indicator (T/F)" 

tab PUB_LOWIMPACTJOURNAL, m /*342,456 NA values - reasons listed in codebook*/
encode PUB_LOWIMPACTJOURNAL, gen(PUB_LOWIMPACTJOURNAL_hist)
histogram(PUB_LOWIMPACTJOURNAL_hist) /*Mostly false*/
drop PUB_LOWIMPACTJOURNAL_hist
codebook PUB_LOWIMPACTJOURNAL
label var PUB_LOWIMPACTJOURNAL "Low Impact journal (bottom 10% impact factor) publication indicator (T/F)" 
 
**For the true/false variables, also generate binary vars
g PUB_HIGHIMPACTJOURNAL_BIN =  1 if PUB_HIGHIMPACTJOURNAL=="TRUE"
replace PUB_HIGHIMPACTJOURNAL_BIN =  0 if PUB_HIGHIMPACTJOURNAL=="FALSE"
label var PUB_HIGHIMPACTJOURNAL_BIN "High Impact journal (top 10% impact factor) publication binary indicator (T/F)" 

g PUB_LOWIMPACTJOURNAL_BIN =  1 if PUB_LOWIMPACTJOURNAL=="TRUE"
replace PUB_LOWIMPACTJOURNAL_BIN =  0 if PUB_LOWIMPACTJOURNAL=="FALSE"
label var PUB_LOWIMPACTJOURNAL_BIN "Low Impact journal (bottom 10% impact factor) publication binary indicator (T/F)" 

*Generate broad field categories based on Clarivate categoires
g MAIN_FIELD_CAT_BROAD="Arts & Humanities" if PUB_JCR_RESEARCHFIELD_A=="BK" | PUB_JCR_RESEARCHFIELD_A=="BP" | PUB_JCR_RESEARCHFIELD_A=="BQ" | PUB_JCR_RESEARCHFIELD_A=="EO" | PUB_JCR_RESEARCHFIELD_A=="FS" | PUB_JCR_RESEARCHFIELD_A=="HF" | PUB_JCR_RESEARCHFIELD_A=="JS" | PUB_JCR_RESEARCHFIELD_A=="JW" | PUB_JCR_RESEARCHFIELD_A=="MM" | PUB_JCR_RESEARCHFIELD_A=="MQ" | PUB_JCR_RESEARCHFIELD_A=="MR" | PUB_JCR_RESEARCHFIELD_A=="OQ" | PUB_JCR_RESEARCHFIELD_A=="OR" | PUB_JCR_RESEARCHFIELD_A=="OX" | PUB_JCR_RESEARCHFIELD_A=="OZ" | PUB_JCR_RESEARCHFIELD_A=="PA" | PUB_JCR_RESEARCHFIELD_A=="PD" | PUB_JCR_RESEARCHFIELD_A=="PF" | PUB_JCR_RESEARCHFIELD_A=="PG" | PUB_JCR_RESEARCHFIELD_A=="PH" | PUB_JCR_RESEARCHFIELD_A=="QC" | PUB_JCR_RESEARCHFIELD_A=="QD" | PUB_JCR_RESEARCHFIELD_A=="QK" | PUB_JCR_RESEARCHFIELD_A=="QL" | PUB_JCR_RESEARCHFIELD_A=="RP" | PUB_JCR_RESEARCHFIELD_A=="UA" | PUB_JCR_RESEARCHFIELD_A=="UT" | PUB_JCR_RESEARCHFIELD_A=="YG" | PUB_JCR_RESEARCHFIELD_A=="YI"

replace MAIN_FIELD_CAT_BROAD="Life Sciences & Biomedicine" if PUB_JCR_RESEARCHFIELD_A=="AD" | PUB_JCR_RESEARCHFIELD_A=="AE" | PUB_JCR_RESEARCHFIELD_A=="AF" | PUB_JCR_RESEARCHFIELD_A=="AH" | PUB_JCR_RESEARCHFIELD_A=="AK" | PUB_JCR_RESEARCHFIELD_A=="AM" | PUB_JCR_RESEARCHFIELD_A=="AQ" | PUB_JCR_RESEARCHFIELD_A=="AY" | PUB_JCR_RESEARCHFIELD_A=="AZ" | PUB_JCR_RESEARCHFIELD_A=="BA" | PUB_JCR_RESEARCHFIELD_A=="BD" | PUB_JCR_RESEARCHFIELD_A=="BF" | PUB_JCR_RESEARCHFIELD_A=="BV" | PUB_JCR_RESEARCHFIELD_A=="CL" | PUB_JCR_RESEARCHFIELD_A=="CN" | PUB_JCR_RESEARCHFIELD_A=="CO" | PUB_JCR_RESEARCHFIELD_A=="CQ" | PUB_JCR_RESEARCHFIELD_A=="CT" | PUB_JCR_RESEARCHFIELD_A=="CU" | PUB_JCR_RESEARCHFIELD_A=="CX" | PUB_JCR_RESEARCHFIELD_A=="DA" | PUB_JCR_RESEARCHFIELD_A=="DE" | PUB_JCR_RESEARCHFIELD_A=="DM" | PUB_JCR_RESEARCHFIELD_A=="DQ" | PUB_JCR_RESEARCHFIELD_A=="DR" | PUB_JCR_RESEARCHFIELD_A=="DS" | PUB_JCR_RESEARCHFIELD_A=="EQ" | PUB_JCR_RESEARCHFIELD_A=="FQ" | PUB_JCR_RESEARCHFIELD_A=="FY" | PUB_JCR_RESEARCHFIELD_A=="GA" | PUB_JCR_RESEARCHFIELD_A=="GM" | PUB_JCR_RESEARCHFIELD_A=="GU" | PUB_JCR_RESEARCHFIELD_A=="HL" | PUB_JCR_RESEARCHFIELD_A=="HQ" | PUB_JCR_RESEARCHFIELD_A=="HT" | PUB_JCR_RESEARCHFIELD_A=="HY" | PUB_JCR_RESEARCHFIELD_A=="IY" | PUB_JCR_RESEARCHFIELD_A=="JA" | PUB_JCR_RESEARCHFIELD_A=="JB" | PUB_JCR_RESEARCHFIELD_A=="JU" | PUB_JCR_RESEARCHFIELD_A=="IA" | PUB_JCR_RESEARCHFIELD_A=="JY" | PUB_JCR_RESEARCHFIELD_A=="KA" | PUB_JCR_RESEARCHFIELD_A=="KI" | PUB_JCR_RESEARCHFIELD_A=="KM" | PUB_JCR_RESEARCHFIELD_A=="LI" | PUB_JCR_RESEARCHFIELD_A=="LJ" | PUB_JCR_RESEARCHFIELD_A=="LQ" | PUB_JCR_RESEARCHFIELD_A=="MA" | PUB_JCR_RESEARCHFIELD_A=="MC" | PUB_JCR_RESEARCHFIELD_A=="ML" | PUB_JCR_RESEARCHFIELD_A=="MU" | PUB_JCR_RESEARCHFIELD_A=="NE" | PUB_JCR_RESEARCHFIELD_A=="NI" | PUB_JCR_RESEARCHFIELD_A=="NN" | PUB_JCR_RESEARCHFIELD_A=="OI" | PUB_JCR_RESEARCHFIELD_A=="OO" | PUB_JCR_RESEARCHFIELD_A=="OP" | PUB_JCR_RESEARCHFIELD_A=="PI" | PUB_JCR_RESEARCHFIELD_A=="PT" | PUB_JCR_RESEARCHFIELD_A=="PW" | PUB_JCR_RESEARCHFIELD_A=="PY" | PUB_JCR_RESEARCHFIELD_A=="QA" | PUB_JCR_RESEARCHFIELD_A=="QB" | PUB_JCR_RESEARCHFIELD_A=="QU" | PUB_JCR_RESEARCHFIELD_A=="RO" | PUB_JCR_RESEARCHFIELD_A=="RQ" | PUB_JCR_RESEARCHFIELD_A=="RT" | PUB_JCR_RESEARCHFIELD_A=="RU" | PUB_JCR_RESEARCHFIELD_A=="RX" | PUB_JCR_RESEARCHFIELD_A=="RZ" | PUB_JCR_RESEARCHFIELD_A=="SA" | PUB_JCR_RESEARCHFIELD_A=="SD" | PUB_JCR_RESEARCHFIELD_A=="SU" | PUB_JCR_RESEARCHFIELD_A=="TA" | PUB_JCR_RESEARCHFIELD_A=="TC" | PUB_JCR_RESEARCHFIELD_A=="TD" | PUB_JCR_RESEARCHFIELD_A=="TE" | PUB_JCR_RESEARCHFIELD_A=="TI" | PUB_JCR_RESEARCHFIELD_A=="TM" | PUB_JCR_RESEARCHFIELD_A=="TQ" | PUB_JCR_RESEARCHFIELD_A=="TU" | PUB_JCR_RESEARCHFIELD_A=="UM" | PUB_JCR_RESEARCHFIELD_A=="VE" | PUB_JCR_RESEARCHFIELD_A=="VY" | PUB_JCR_RESEARCHFIELD_A=="WC" | PUB_JCR_RESEARCHFIELD_A=="WE" | PUB_JCR_RESEARCHFIELD_A=="WF" | PUB_JCR_RESEARCHFIELD_A=="WH" | PUB_JCR_RESEARCHFIELD_A=="XW" | PUB_JCR_RESEARCHFIELD_A=="YA" | PUB_JCR_RESEARCHFIELD_A=="YO" | PUB_JCR_RESEARCHFIELD_A=="YP" | PUB_JCR_RESEARCHFIELD_A=="YU" | PUB_JCR_RESEARCHFIELD_A=="ZA" | PUB_JCR_RESEARCHFIELD_A=="ZC" | PUB_JCR_RESEARCHFIELD_A=="ZD" | PUB_JCR_RESEARCHFIELD_A=="ZE" | PUB_JCR_RESEARCHFIELD_A=="ZM"

replace MAIN_FIELD_CAT_BROAD="Physical Sciences" if PUB_JCR_RESEARCHFIELD_A=="BU" | PUB_JCR_RESEARCHFIELD_A=="CA" | PUB_JCR_RESEARCHFIELD_A=="DT" | PUB_JCR_RESEARCHFIELD_A=="DW" | PUB_JCR_RESEARCHFIELD_A=="DX" | PUB_JCR_RESEARCHFIELD_A=="DY" | PUB_JCR_RESEARCHFIELD_A=="EA" | PUB_JCR_RESEARCHFIELD_A=="EC" | PUB_JCR_RESEARCHFIELD_A=="EE" | PUB_JCR_RESEARCHFIELD_A=="EI" | PUB_JCR_RESEARCHFIELD_A=="FF" | PUB_JCR_RESEARCHFIELD_A=="FI" | PUB_JCR_RESEARCHFIELD_A=="GC" | PUB_JCR_RESEARCHFIELD_A=="KU" | PUB_JCR_RESEARCHFIELD_A=="KV" | PUB_JCR_RESEARCHFIELD_A=="KY" | PUB_JCR_RESEARCHFIELD_A=="LE" | PUB_JCR_RESEARCHFIELD_A=="MQ" | PUB_JCR_RESEARCHFIELD_A=="OU" | PUB_JCR_RESEARCHFIELD_A=="PN" | PUB_JCR_RESEARCHFIELD_A=="PO" | PUB_JCR_RESEARCHFIELD_A=="PQ" | PUB_JCR_RESEARCHFIELD_A=="QM" | PUB_JCR_RESEARCHFIELD_A=="QQ" | PUB_JCR_RESEARCHFIELD_A=="RE" | PUB_JCR_RESEARCHFIELD_A=="SI" | PUB_JCR_RESEARCHFIELD_A=="SY" | PUB_JCR_RESEARCHFIELD_A=="UB" | PUB_JCR_RESEARCHFIELD_A=="UF" | PUB_JCR_RESEARCHFIELD_A=="UH" | PUB_JCR_RESEARCHFIELD_A=="UI" | PUB_JCR_RESEARCHFIELD_A=="UK" | PUB_JCR_RESEARCHFIELD_A=="UN" | PUB_JCR_RESEARCHFIELD_A=="UP" | PUB_JCR_RESEARCHFIELD_A=="UR" | PUB_JCR_RESEARCHFIELD_A=="UY" | PUB_JCR_RESEARCHFIELD_A=="XE" | PUB_JCR_RESEARCHFIELD_A=="ZQ" | PUB_JCR_RESEARCHFIELD_A=="ZR"

replace MAIN_FIELD_CAT_BROAD="Social Sciences" if PUB_JCR_RESEARCHFIELD_A=="BI" | PUB_JCR_RESEARCHFIELD_A=="BM" | PUB_JCR_RESEARCHFIELD_A=="DI" | PUB_JCR_RESEARCHFIELD_A=="DK" | PUB_JCR_RESEARCHFIELD_A=="EN" | PUB_JCR_RESEARCHFIELD_A=="EU" | PUB_JCR_RESEARCHFIELD_A=="FE" | PUB_JCR_RESEARCHFIELD_A=="FU" | PUB_JCR_RESEARCHFIELD_A=="GY" | PUB_JCR_RESEARCHFIELD_A=="HA" | PUB_JCR_RESEARCHFIELD_A=="HB" | PUB_JCR_RESEARCHFIELD_A=="HE" | PUB_JCR_RESEARCHFIELD_A=="HI" | PUB_JCR_RESEARCHFIELD_A=="JM" | PUB_JCR_RESEARCHFIELD_A=="JO" | PUB_JCR_RESEARCHFIELD_A=="MW" | PUB_JCR_RESEARCHFIELD_A=="MY" | PUB_JCR_RESEARCHFIELD_A=="NM" | PUB_JCR_RESEARCHFIELD_A=="NQ" | PUB_JCR_RESEARCHFIELD_A=="OE" | PUB_JCR_RESEARCHFIELD_A=="OM" | PUB_JCR_RESEARCHFIELD_A=="OT" | PUB_JCR_RESEARCHFIELD_A=="OY" | PUB_JCR_RESEARCHFIELD_A=="PC" | PUB_JCR_RESEARCHFIELD_A=="PS" | PUB_JCR_RESEARCHFIELD_A=="UL" | PUB_JCR_RESEARCHFIELD_A=="UQ" | PUB_JCR_RESEARCHFIELD_A=="UU" | PUB_JCR_RESEARCHFIELD_A=="VI" | PUB_JCR_RESEARCHFIELD_A=="VJ" | PUB_JCR_RESEARCHFIELD_A=="VM" | PUB_JCR_RESEARCHFIELD_A=="VP" | PUB_JCR_RESEARCHFIELD_A=="VS" | PUB_JCR_RESEARCHFIELD_A=="VX" | PUB_JCR_RESEARCHFIELD_A=="WM" | PUB_JCR_RESEARCHFIELD_A=="WQ" | PUB_JCR_RESEARCHFIELD_A=="WU" | PUB_JCR_RESEARCHFIELD_A=="WV" | PUB_JCR_RESEARCHFIELD_A=="WY" | PUB_JCR_RESEARCHFIELD_A=="XA" | PUB_JCR_RESEARCHFIELD_A=="XY" | PUB_JCR_RESEARCHFIELD_A=="YY" | PUB_JCR_RESEARCHFIELD_A=="ZK"

replace MAIN_FIELD_CAT_BROAD="Technology" if PUB_JCR_RESEARCHFIELD_A=="AA" | PUB_JCR_RESEARCHFIELD_A=="AC" | PUB_JCR_RESEARCHFIELD_A=="AI" | PUB_JCR_RESEARCHFIELD_A=="CM" | PUB_JCR_RESEARCHFIELD_A=="EP" | PUB_JCR_RESEARCHFIELD_A=="ER" | PUB_JCR_RESEARCHFIELD_A=="ES" | PUB_JCR_RESEARCHFIELD_A=="ET" | PUB_JCR_RESEARCHFIELD_A=="EV" | PUB_JCR_RESEARCHFIELD_A=="EW" | PUB_JCR_RESEARCHFIELD_A=="EX" | PUB_JCR_RESEARCHFIELD_A=="EY" | PUB_JCR_RESEARCHFIELD_A=="FA" | PUB_JCR_RESEARCHFIELD_A=="ID" | PUB_JCR_RESEARCHFIELD_A=="IE" | PUB_JCR_RESEARCHFIELD_A=="IF" | PUB_JCR_RESEARCHFIELD_A=="IG" | PUB_JCR_RESEARCHFIELD_A=="IH" | PUB_JCR_RESEARCHFIELD_A=="II" | PUB_JCR_RESEARCHFIELD_A=="IJ" | PUB_JCR_RESEARCHFIELD_A=="IK" | PUB_JCR_RESEARCHFIELD_A=="IL" | PUB_JCR_RESEARCHFIELD_A=="IM" | PUB_JCR_RESEARCHFIELD_A=="IO" | PUB_JCR_RESEARCHFIELD_A=="IP" | PUB_JCR_RESEARCHFIELD_A=="IQ" | PUB_JCR_RESEARCHFIELD_A=="IU" | PUB_JCR_RESEARCHFIELD_A=="IX" | PUB_JCR_RESEARCHFIELD_A=="JI" | PUB_JCR_RESEARCHFIELD_A=="NS" | PUB_JCR_RESEARCHFIELD_A=="NU" | PUB_JCR_RESEARCHFIELD_A=="OA" | PUB_JCR_RESEARCHFIELD_A=="PE" | PUB_JCR_RESEARCHFIELD_A=="PJ" | PUB_JCR_RESEARCHFIELD_A=="PK" | PUB_JCR_RESEARCHFIELD_A=="PM" | PUB_JCR_RESEARCHFIELD_A=="PU" | PUB_JCR_RESEARCHFIELD_A=="PZ" | PUB_JCR_RESEARCHFIELD_A=="QE" | PUB_JCR_RESEARCHFIELD_A=="QF" | PUB_JCR_RESEARCHFIELD_A=="QG" | PUB_JCR_RESEARCHFIELD_A=="QH" | PUB_JCR_RESEARCHFIELD_A=="QJ" | PUB_JCR_RESEARCHFIELD_A=="RA" | PUB_JCR_RESEARCHFIELD_A=="RB" | PUB_JCR_RESEARCHFIELD_A=="RY" | PUB_JCR_RESEARCHFIELD_A=="SQ" | PUB_JCR_RESEARCHFIELD_A=="SR" | PUB_JCR_RESEARCHFIELD_A=="TG" | PUB_JCR_RESEARCHFIELD_A=="UE" | PUB_JCR_RESEARCHFIELD_A=="XQ" | PUB_JCR_RESEARCHFIELD_A=="YE" | PUB_JCR_RESEARCHFIELD_A=="YQ" | PUB_JCR_RESEARCHFIELD_A=="YR" | PUB_JCR_RESEARCHFIELD_A=="ZI"

label var MAIN_FIELD_CAT_BROAD "Broad publication field"

************
*Save data
save "$TEMP/newwos_cleaned", replace
 
 
 
************************************************
*Load crosswalk
************************************************
use "$RAWROOT/sdrwos_matchingresults.dta", clear

*Clean crosswalk data
tab pub_randid if pub_randid=="", m
drop if pub_randid=="" /*Drop empty publication IDs 5,031 - Want to look into this further, the codebook talks about a smaller number of missing*/

summarize AUTHOR_POS, det /*Author position ranges from 1-5127*/
histogram(AUTHOR_POS) /*Mostly first authors*/
misstable summarize AUTHOR_POS /*No missing values*/
label var AUTHOR_POS "Authorship position"

summarize GBM_predicted_probability, det /*Ranges from 0-1*/
histogram(GBM_predicted_probability) /*Mostly above .8*/
misstable summarize GBM_predicted_probability /*No missing values*/
/*Report is not super clear, but it seems we may want to only keep values above .9*/

*Save crosswalk
save "$TEMP/newwos_crosswalk", replace

************************************************
*Merge data with crosswalk
************************************************
use "$TEMP/newwos_crosswalk", clear
merge m:1 pub_randid using "$TEMP/newwos_cleaned" /*All merged successfully; N = 1,349,159; note that this is a greater number of observations than with the cleaned data file, this is because a paper may belong to multiple authors (REFIDs)*/
drop _merge

*Save publication dataset
save "$DATA/newwos_withrefid", replace

*Generate summary stats for full dataset
use "$DATA/newwos_withrefid", clear

*Individuals with all numerical vars
estpost tabstat ///
PUB_YEAR PUB_JCR_IMPACTFACTOR NUM_PUB_JCR_RESEARCHFIELD PUB_NUM_AUTHORS PUB_NUM_COUNTRIES PUB_US_Indicator PUB_FIRST_CITE_Y2_LAG PUB_CITES_Y2 PUB_CITES_Y2_RA PUB_CITES_Y5 PUB_CITES_Y5_RA PUB_CITES_Y2_HIJ PUB_CITES_Y5_HIJ NUM_REFS PUB_HIGHIMPACTJOURNAL_BIN PUB_LOWIMPACTJOURNAL_BIN, ///
statistics(n mean sd max min q) listwise columns(statistics)
esttab using "$DESC/wospub_sumstats.rtf", cells("count(fmt(%15.0gc)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))") label  noobs replace nomtitle modelwidth(5) gaps

*Individuals with all numerical vars by year
estpost tabstat ///
PUB_JCR_IMPACTFACTOR NUM_PUB_JCR_RESEARCHFIELD PUB_NUM_AUTHORS PUB_NUM_COUNTRIES PUB_US_Indicator PUB_FIRST_CITE_Y2_LAG PUB_CITES_Y2 PUB_CITES_Y2_RA PUB_CITES_Y5 PUB_CITES_Y5_RA PUB_CITES_Y2_HIJ PUB_CITES_Y5_HIJ NUM_REFS PUB_HIGHIMPACTJOURNAL_BIN PUB_LOWIMPACTJOURNAL_BIN, ///
statistics(n mean sd max min q) listwise columns(statistics)
esttab using "$DESC/wospub_sumstats_byyear.rtf", cells("count(fmt(%15.0gc)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))") label  noobs replace nomtitle modelwidth(5) gaps

*Individuals with all numerical vars by broad field category
estpost tabstat ///
PUB_YEAR PUB_JCR_IMPACTFACTOR NUM_PUB_JCR_RESEARCHFIELD PUB_NUM_AUTHORS PUB_NUM_COUNTRIES PUB_US_Indicator PUB_FIRST_CITE_Y2_LAG PUB_CITES_Y2 PUB_CITES_Y2_RA PUB_CITES_Y5 PUB_CITES_Y5_RA PUB_CITES_Y2_HIJ PUB_CITES_Y5_HIJ NUM_REFS PUB_HIGHIMPACTJOURNAL_BIN PUB_LOWIMPACTJOURNAL_BIN, ///
statistics(n mean sd max min q) listwise columns(statistics)
esttab using "$DESC/wospub_sumstats_byfield.rtf", cells("count(fmt(%15.0gc)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))") label  noobs replace nomtitle modelwidth(5) gaps

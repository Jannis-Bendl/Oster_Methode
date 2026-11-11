README file for "THE LIFETIME IMPACTS OF THE NEW DEAL’S YOUTH EMPLOYMENT PROGRAM" 
by Anna Aizer, Nancy Early, Shari Eli, Guido Imbens, Keyoung Lee, Adriana Lleras-Muney, Alexander Strand

Notes:

We cannot provide the original Civilian Conservation Corps (CCC) roster data for reasons of privacy. We have communicated this to the QJE in the Data Release Statement. Similarly, data from the Social Security Administration (SSA) cannot be released publicly and therefore was not included in the replication package.

However, we are able to provide the code used to produce all of our main tables and figures in the text. These codes, when run on our original CCC data, will produce results on all outcomes except ones from the SSA. Results using SSA outcome data were produced using the same codes, but modified for outcome variable names.

We provide the 1990 and 1940 Census data from IPUMS that was used to produce statistics in Table II. Finally, the Jobs Corps data is courtesy of the Schochet, Burghardt, McConnell (2008) American Economic Review replication package found in the website, https://www.aeaweb.org/articles?id=10.1257/aer.98.5.1864

We used STATA 14.0. Installed packages are availble from SSC: 
 - binsreg: for Binscatter graphs provided by Cattaneo et al.
 - outreg2: for regression outputs
 - tuples: for generating combinations from a set
 - ebalance: for generating Hainmueller (2012) weights
 
Files:

The following files are included in the replication package:

Data files:
 - census_ipums.dta: data generated from IPUMS on 1990 (usa_00045) and 1940 (usa_00047) Censuses, used for comparison with enrollees of JC and CCC
 Note that there was an error on the IPUMS national 1940 census subsample files where severl counties were missing. IPUMS is aware of the issue, but given the 1940 historical full count census they are not fixing the issue at the moment. Therefore, for the 1940 Census I used a 20 percent subsample of the full count historical file.

Program files (all Stata do-files): 
 - figures_tables_CCC.do: generates all figures and all main tables except 2 and 8, for outcomes not from the SSA. Appendix tables not pertaining to JC and/or control functions are also generated.
 - figures_tables_JC.do : generate all figures and tables for JC data (figures 1, 2, 3 and table 7)
 - Census_1990_national.do and Census_1940_national_20p.do: generates main table 2 for 1990 and 1940 Censuses, respectively.
 - tables_JC_CCC.do: generates main tables 2 (JC and CCC columns) and 8, and appendix tables pertaining to JC+CCC combined results and/or control functions.
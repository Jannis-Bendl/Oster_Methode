/**********************************************************************
 * Title:   Query Denominator (MBSF)
 * Program: 01get/main.sas
 * Blame:   Mauricio Caceres Bravo <mauricio_caceres_bravo@brown.edu>
 * Note:    Run from agesas# via `make 01get &` from reposiroty root
 *
 * Purpose: Query the 100% denominator files. While these scripts
 *          _could_ produce enrollment files, we have moved to making
 *          the enrollment files in 02clean.do
 *
 * Output:  >
 *          &datadir./
 *              denom&pct..sas7bdat
 *              denom&pct._lean.sas7bdat
 *
 *              denom&pct..dta
 *              denom&pct._lean.dta
 *
 **********************************************************************/

dm 'clear log output'; ods _ALL_ close;
options
    errors = 20        /* Maximum number of prints of repeat errors  */
    compress = yes     /* Compress data using char (RLE) compression */
    minoperator        /* Enable macro 'in' operator                 */
    mprint             /* Print macro output                         */
    nomlogic           /* (not) Go through macro logic               */
    mcompilenote = all /* Note on compiled macros                    */
    nosymbolgen        /* (not) Print macro symbol eval              */
    fullstimer         /* Detailed timer after each step execution   */
    nonumber           /* (not) Print page numbers in SAS log        */
    nodate             /* (not) Print SAS date atop each log page    */
;

%let bulk     = /disk/agebulk3/medicare.work/doyle-DUA51929;
%let datadir  = &bulk./&sysuserid./cms-mortality-replication/data;
%let rawdata  = /disk/aging/medicare/data;
%let sqlopts  = feedback stimer noprint _method;

libname data "&datadir.";

%include "01get/00common.sas";
%include "01get/00getDenom.sas";

/* DOC
 *
 * Main function wrapper to query the denominator files.
 *
 *     pct:    Percent sample to query. We have access up to 100%.
 *     outlib: SAS output library.
 *     syear:  First year of our query; we have access from 2006.
 *     eyear:  Last year of our query; we have access through 2017.
 *
 */
%macro main();
    %let stime = %sysfunc(putn(%sysfunc(datetime()), datetime.));

    %getDenom(pct = 01,  outlib = data, syear = 2006, eyear = 2014);
    %getDenom(pct = 100, outlib = data, syear = 2006, eyear = 2014);

    %sendMail(&stime.);
%mend main;

%main();

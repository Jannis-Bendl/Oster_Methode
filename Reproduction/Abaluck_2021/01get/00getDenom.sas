/* DOC
 *
 * Denominator Query {-}
 * ---------------------
 *
 * __*NOTE*__: Run from `./01get.sas`
 *
 */

* DOC: ### Main loop {-};
%macro getDenom(
        pct    = 0001, /* Query &pct level denominator data */
        outlib = work, /* Output to &outlib library         */
        syear  = 2006, /* Start year for query (2006+ only) */
        eyear  = 2014  /* End year for query                */
    );

    %assert(&syear. >= 2006);
    %assert(&eyear. <= 2014);
    %assert(%quote(%')&pct.%quote(%') in '0001'|'01'|'05'|'20'|'100');

    /* DOC
     *
     * First we loop through denominator data (`bsfab`) and merge from
     * 2006 to 2014:
     *
     * - The denominator date is wide, so first we get a file at the
     *   bene_id level. We will update time-invariant variables in a
     *   base denominator file rather than stacking them.
     *
     * - Importantly, we update date of death with DOD from the
     *   newer denominator file (if not missing).
     *
     * - Each year's denominator file also contain enrollment
     *   indicator variables nubered 1 through 12 (per month). We
     *   rename them &year.m&month. and "stack" them horizontally.
     *
     * - We only update demographics if they are currently missing.
     *
     */

    %let outpath  = %sysfunc(pathname(&outlib.));
    %let finalden = &outlib..denom&pct.;
    %do year = &syear. %to &eyear.;
        libname d&year. "&rawdata./&pct.pct/bsfbase/&year./1" access = readonly;
        %loop_denom(
            &year.,
            pct    = &pct.,
            outlib = &outlib.,
            syear  = &syear.
        );
    %end;

    /* DOC
     *
     * We then de-duplicate the data. Note we keep a single observation
     * by bene_id (`if last.bene_id`). We also create a data set that
     * only has beneficiary demographics so we can easily refer to them
     * later:
     *
     *     denom100_lean.sas7bdat
     *     ----------------------
     *     bene_id
     *     sdod
     *     sdob
     *     race
     *     sex
     *
     */

    proc sort
        data = tmp_denom_full noduprecs;
        by bene_id sdod sdob race sex;

    data &finalden.;
        set tmp_denom_full;
        by bene_id;
        if last.bene_id;

    data &finalden.;
        set &finalden.;
        bene_code = _n_;

    data &finalden._lean;
        set &finalden.(
            keep = bene_id bene_code sdod sdob race sex
            %do year = &syear. %to &eyear.;
                state&year. zip&year.
            %end;
        );
    run;

    /* DOC
     *
     * We export the resulting data sets to Stata's .dta format for
     * further cleaning.
     *
     */

    systask command "st
        &outpath./denom&pct..sas7bdat
        &outpath./denom&pct..dta
        -y
    " wait;

    systask command "st
        &outpath./denom&pct._lean.sas7bdat
        &outpath./denom&pct._lean.dta
        -y
    " wait;

%exit: %mend getDenom;

* DOC: ### Raw denominator files {-};
%macro loop_denom(
        year,           /* Year to query from denom  */
        pct    = 0001,  /* Query &pct level IP data  */
        outlib = work,  /* Output to &outlib library */
        syear  = 1998   /* Start year for query      */
    );

    %let pt_id  = bene_id;
    %let dob    = bene_dob;
    %let dod    = death_dt;
    %let race   = race;
    %let sex    = sex;
    %let buyin  = buyin0;
    %let hmoind = hmoind0;
    %let cntrct = ptdcntrct0;
    %let pbpid  = ptdpbpid0;
    %let dualcd = dual_0;
    %let county = cnty_cd;
    %let state  = state_cd;
    %let zip    = zip_cd;

    /* DOC
     *
     * See
     *
     *     /disk/aging/medicare/data/100pct/bsf/&year./
     *     --------------------------------------------
     *     bsfab&year.
     *
     * For a given year we query patient demographics and rename
     * enrollment the variables to stack them horizontally. We will
     * identify medicare advantage enrollees by whether their contract
     * ID starts with letter H. However, we keep a copy of the variable
     * as is in order to use plan dummies later on.
     *
     *     bene_id
     *     dual_01 to dual_12
     *     ptdcntrct01 to ptdcntrct12
     *     ptdpbpid01 to ptdpbpid12
     *     hmoind01 to hmoind12
     *     buyin01 to buyin12
     *     bene_dob
     *     death_dt
     *     cnty_cd
     *     bene_zip
     *     race
     *     sex
     *
     */

    proc sql &sqlopts.;
    create table tmp_denom as
        select distinct
            &pt_id.  as bene_id length = 15,
            %do i = 1 %to 9;
                %sysfunc(compress(&buyin.&i.))
                    as %sysfunc(compress(buyin&year.m&i.)),
                %sysfunc(compress(&hmoind.&i.))
                    as %sysfunc(compress(hmoind&year.m&i.)),
                %sysfunc(compress(&cntrct.&i.))
                    as %sysfunc(compress(cntrct&year.m&i.)),
                %sysfunc(compress(&pbpid.&i.))
                    as %sysfunc(compress(pbpid&year.m&i.)),
                %sysfunc(compress(&dualcd.&i.))
                    as %sysfunc(compress(dualcd&year.m&i.)),
            %end;
            %do i = 10 %to 12;
                %sysfunc(compress(%sysfunc(tranwrd(&buyin.,0,))&i.))
                    as buyin&year.m&i.,
                %sysfunc(compress(%sysfunc(tranwrd(&hmoind.,0,))&i.))
                    as hmoind&year.m&i.,
                %sysfunc(compress(%sysfunc(tranwrd(&cntrct.,0,))&i.))
                    as cntrct&year.m&i.,
                %sysfunc(compress(%sysfunc(tranwrd(&pbpid.,0,))&i.))
                    as pbpid&year.m&i.,
                %sysfunc(compress(%sysfunc(tranwrd(&dualcd.,0,))&i.))
                    as dualcd&year.m&i.,
            %end;
            &dob.    as sdob  length = 5 format = MMDDYY10.,
            &dod.    as sdod  length = 5 format = MMDDYY10.,
            &county. as county&year.,
            &state.  as state&year.,
            &zip.    as zip&year.,
            &race.   as race,
            &sex.    as sex
        from d&year..bsfab&year.(where = (&pt_id. ~= ""))
        order by bene_id;
    quit;

    proc sort data = tmp_denom;
        by bene_id;
    run;

    * DOC: For the first year of the query, we initialize the data set.
    * For subsequent years we merge, replacing the current demographic
    * information when it is missing (if not missing we favor the frist
    * value we found).;

    %if &year. = &syear. %then %do;
        proc datasets library = work noprint;
            delete tmp_denom_full;
            change tmp_denom = tmp_denom_full;
        quit;
    %end;
    %else %do;
        data
            tmp_denom_full (
                drop =
                    a_sdod b_sdod
                    a_sdob b_sdob
                    a_race b_race
                    a_sex  b_sex
            );
            merge
                tmp_denom_full (
                    rename = (
                        sdod = a_sdod
                        sdob = a_sdob
                        race = a_race
                        sex  = a_sex
                    )
                )
                tmp_denom (
                    rename = (
                        sdod = b_sdod
                        sdob = b_sdob
                        race = b_race
                        sex  = b_sex
                    )
                )
            ;
            by bene_id;
            if a_sdod = . then sdod = b_sdod; else sdod = a_sdod;
            if a_sdob = . then sdob = b_sdob; else sdob = a_sdob;
            if a_race = . then race = b_race; else race = a_race;
            if a_sex  = . then sex  = b_sex;  else sex  = a_sex;
        run;
    %end;
%exit: %mend loop_denom;

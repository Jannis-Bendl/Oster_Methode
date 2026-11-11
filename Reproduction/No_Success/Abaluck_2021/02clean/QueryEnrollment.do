* ---------------------------------------------------------------------
* Query any enrollment

* DOC: We parse the SAS-generated denominator data to generate
* continuous enrollment flags (at the bene-year level) and make
* a dataset analogous to the MA final denominator data but with
* beneficiaries for whom we have a continuous set of enrollment
* variables (in this context we say enrollment is continuous if
* at least one enrollment variable is not missing).

capture program drop queryEnrollment
program queryEnrollment
    syntax, pct(str) syear(int) [replace chunks(int 10)]

    /* DOC
     *
     * AFAIK it is much faster to chunk the data processing. Each row in
     * denom`pct' is a beneficiary, so it is OK to chunk them since benes
     * would not be split across chunks.
     *
     */

    local stubs buyin hmoind cntrct pbpid dualcd

    cap mkdir `"${data}/chunks"'
    qui desc using `"${data}/denom`pct'.dta"'
    local N      = `r(N)'
    local chunk  = 0
    local nstep  = ceil(`N' / `chunks')

    shell date
    local nstart = 1
    local nend   = `nstart' + `nstep' - 1
    while ( `++chunk' <= `chunks' ) {
        disp `""'
        disp `"--------------------------"'
        disp `"`chunk': `nstart' / `nend'"'
        disp `"--------------------------"'
        disp `""'
        use `"${data}/denom`pct'.dta"' in `nstart' / `nend', clear
            qui {

                /* DOC
                 *
                 * Reshape from wide to long. Note that we rename the variables so
                 * that the key variable, yearmo, will be numeric. This is much
                 * faster than dealing with string parsing (2012m3 vs 201203). Also
                 * note the option dropmiss, which will drop a row if every output
                 * entry will be missing. That is, if for a given year-month all 5
                 * stubs are missing, we skip the row.
                 *
                 */

                local keepvars bene_code sdod
                foreach stub of local stubs {
                    local keepvars `keepvars' `stub'*
                }
                keep `keepvars'

                forvalues m = 1 / 9 {
                    foreach stub of local stubs {
                        rename `stub'*m`m' `stub'*0`m'
                    }
                }
                forvalues m = 10 / 12 {
                    foreach stub of local stubs {
                        rename `stub'*m`m' `stub'*`m'
                    }
                }

                greshape long `stubs', by(bene_code) key(yearmo) dropmiss
                gen int  year  = floor(yearmo / 100)
                gen byte month = yearmo - (year * 100)
                replace yearmo = ((year - `syear') * 12) + month

                /* DOC
                 *
                 * For traditional medicare (TM) and medicare advantage (MA), we
                 * require continuous enrollment from any point in the year (that
                 * is, you need not start as them but once in you must remain for
                 * the year). In both cases we require continuous enrollment until
                 * the end of the year or until death.
                 *
                 */

                gen int  deathyear  = year(sdod)
                gen byte deathmonth = month(sdod)
                gen int deathyearmo = ((deathyear - `syear') * 12) + deathmonth

                /* DOC
                 *
                 * We only keep people from their first full year until
                 * death. We make sure that we have _some_ enrollment record
                 * of them EVERY month every year until they die.
                 *
                 */

                drop if (yearmo > deathyearmo)

                gegen byte firstmonth = min(month), by(bene_code year)
                gegen int  firstyear  = min(year),  by(bene_code)
                gegen int  nmonths    = count(1),   by(bene_code year)

                drop if (firstmonth > 1) & (year == firstyear)
                assert (nmonths == 12) | ((nmonths == deathmonth) & (deathyear == year))

                /* DOC
                 *
                 * Check continuous enrollment. Contract IDs that start with H are
                 * Managed Care plans that should identify private plans.
                 *
                 *     | Indicator | Value | Description                                                          |
                 *     | --------- | ----- | -------------------------------------------------------------------- |
                 *     | Contract  | H     | Managed Care Organizations other than Regional PPO                   |
                 *     |           | R     | Regional PPO                                                         |
                 *     |           | S     | PDP                                                                  |
                 *     |           | E     | Employer-Sponsored (starting January 2007)                           |
                 *     | --------- | ----- | -------------------------------------------------------------------- |
                 *     | HMO       | 0     | Not a member of HMO                                                  |
                 *     |           | 1     | Non lock-in, HCFA to process provider claims                         |
                 *     |           | 2     | Non lock-in, GHO to process in-plan Part A and in-area Part B claims |
                 *     |           | 4     | FFS for disease management demonstration project (2005 forward)      |
                 *     |           | A     | Lock-in, HCFA to process provider claims                             |
                 *     |           | B     | Lock-in, GHO to process in Plan part A and in-area Part B claims     |
                 *     |           | C     | Lock-in, GHO to process all provider claims                          |
                 *     | --------- | ----- | -------------------------------------------------------------------- |
                 *     | Buy-in    | 0     | Not entitled                                                         |
                 *     |           | 1     | Part A only                                                          |
                 *     |           | 2     | Part B only                                                          |
                 *     |           | 3     | Part A and Part B                                                    |
                 *     |           | A     | Part A, state buy-in                                                 |
                 *     |           | B     | Part B, state buy-in                                                 |
                 *     |           | C     | Part A and Part B, state buy-in                                      |
                 *
                 */

                sort bene_code year month
                rename month m
                drop *yearmo *month
                rename m month

                local exclude bene_code year month
                unab byvars: _all
                local byvars: list byvars - exclude

                gen double nDual     = !inlist(dualcd, "", "00", "XX", "NA", "99")
                gen double nHMO      = (hmoind == "0") | (hmoind == "4")
                gen double nFFS      = (buyin  == "3") | (buyin  == "C")
                gen double nTM       = nHMO & nFFS
                gen double nMA       = substr(cntrct, 1, 1) == "H"
                gen double nEmployer = (hmoind == "C") | (substr(cntrct, 1, 1) == "R")

                local counts nDual nHMO nFFS nTM nMA nEmployer
                gcollapse (sum) `counts' (max) month, by(bene_code year `byvars') freq(_nmonths)

                /* DOC
                 *
                 * WARNING! Each indicator is assigned independently. Generally,
                 *
                 *     eTM + eMA + eOther = 1
                 *
                 * However, eHMO = eFFS = 1 does NOT imply eTM = 1 because. The
                 * enrollment criteria for each indicator is that they are enrolled
                 * for more than half the year. So they could be enrolled in eHMO
                 * and eFFS during different time periods, resulting in both being 1
                 * but eTM being 0.
                 *
                 * For a similar reason, the modal plan might be an H plan and eMA
                 * might be 0. For modal assignment, see the m* indicators.
                 *
                 */

                gegen nDual     = sum(nDual),     by(bene_code year) replace
                gegen nHMO      = sum(nHMO),      by(bene_code year) replace
                gegen nFFS      = sum(nFFS),      by(bene_code year) replace
                gegen nTM       = sum(nTM),       by(bene_code year) replace
                gegen nMA       = sum(nMA),       by(bene_code year) replace
                gegen nEmployer = sum(nEmployer), by(bene_code year) replace

                assert (nDual     <= 12)
                assert (nHMO      <= 12)
                assert (nFFS      <= 12)
                assert (nTM       <= 12)
                assert (nMA       <= 12)
                assert (nEmployer <= 12)
                recast byte `counts'

                /* DOC
                 *
                 * We assign benes their modal enrollment. If they were
                 * TM or MA most of the year, then that is what we call
                 * them. Note we first keep their most common enrollment
                 * configuration
                 *
                 */

                by bene_code year: gen byte eSwitch = (cntrct[_N] != cntrct[1]) | (pbpid[_N] != pbpid[1])

                sort bene_code year _nmonths month
                by bene_code year (_nmonths month): keep if (_n == _N)
                rename (nmonths _nmonths month) (monthsalive monthsenrolled lastmonth)
                gisid bene_code year
                * tab monthsalive monthsenrolled

                /* DOC
                 *
                 * Finally, we make the indicators. e* indicators are true if
                 * the beneficiary met the enrollment criteria for the indicator
                 * for more than half the year. m* indicators are true if
                 * the beneficiary met the enrollment criteria for the modal
                 * enrollment configuration that year.
                 *
                 *     HMO      | hmoind 0 or 4
                 *     FFS      | buyin 3 or C
                 *     MA       | H plan
                 *     TM       | HMO and FFS each month
                 *     Employer | HMO is C and R contract
                 *     Dual     | See notes below
                 *
                 * We identify dual-eligibility enrollees following the steps outlined by
                 * ResDAC [here](https://www.resdac.org/resconnect/articles/149) (they
                 * also note the `dual_*` indicator is a more accurate way to assess
                 * beneficiaries' dual-eligibility than buy-in codes).
                 *
                 */

                gen byte mDual     = !inlist(dualcd, "", "00", "XX", "NA", "99")
                gen byte mHMO      = (hmoind == "0") | (hmoind == "4")
                gen byte mFFS      = (buyin  == "3") | (buyin  == "C")
                gen byte mTM       = (mHMO & mFFS)
                gen byte mMA       = substr(cntrct, 1, 1) == "H"
                gen byte mEmployer = (hmoind == "C") | (substr(cntrct, 1, 1) == "R")

                gen byte eDual     = (nDual     > 1)
                gen byte eHMO      = (nHMO      > (monthsalive / 2))
                gen byte eFFS      = (nFFS      > (monthsalive / 2))
                gen byte eTM       = (nTM       > (monthsalive / 2))
                gen byte eMA       = (nMA       > (monthsalive / 2))
                gen byte eEmployer = (nEmployer > (monthsalive / 2))

                replace mEmployer  = 1 if (eEmployer == 1)
                replace mDual      = 1 if (eDual     == 1)
                replace mHMO       = 1 if (eHMO      == 1)
                replace mFFS       = 1 if (eFFS      == 1)
                replace mTM        = 1 if (eTM       == 1)
                replace mMA        = 1 if (eMA       == 1)
                replace mTM        = 0 if (eMA       == 1)
                replace mMA        = 0 if (eTM       == 1)

                gen eDoubleEnrollment = (eTM == 1) & (eMA == 1)
                gen mDoubleEnrollment = (mTM == 1) & (mMA == 1)

                gen byte mOther = (mTM == 0) & (mMA == 0)
                gen byte eOther = (eTM == 0) & (eMA == 0)

                local genlags eTM mTM eMA mMA eEmployer mEmployer
                foreach var of local genlags {
                    by bene_code (year): gen byte `var'_lag = `var'[_n - 1]
                }

                gen int chunk = `chunk'
                save `"${data}/chunks/denom`pct'_longchunk`chunk'.dta"', `replace'
            }

        shell date
        local nstart = `nend' + 1
        local nend   = min(`N', `nstart' + `nstep' - 1)
    }

    /* DOC
     *
     * Loop through the chunks and append them into a single data set.
     * Importantly, we encode the plans and contracts into a numeric ID,
     * which is easier to work with. We force all TM plans to be goruped
     * under a single code (-1) and all non-TM non-MA plan to be grouped
     * under another code (-2).
     *
     */

    local chunk 1
    use `"${data}/chunks/denom`pct'_longchunk`chunk'.dta"', clear
        while ( `++chunk' <= `chunks' ) {
            append using `"${data}/chunks/denom`pct'_longchunk`chunk'.dta"'
        }

        sort bene_code year
        gen byte _S = substr(cntrct, 1, 1) == "S"

        gegen cntrct_id     = group(cntrct)
        gegen pbpid_id      = group(pbpid)
        gegen plan          = group(cntrct_id pbpid_id)
        gegen lastyear      = max(year), by(bene_code)

        replace plan      = . if mi(cntrct) | mi(pbpid)
        replace cntrct_id = . if mi(cntrct)
        replace pbpid_id  = . if mi(cntrct) | mi(pbpid)

        replace plan      = -1 if mTM == 1
        replace cntrct_id = -1 if mTM == 1
        replace pbpid_id  = -1 if mTM == 1

        replace plan      = -2 if mOther == 1
        replace cntrct_id = -2 if mOther == 1
        replace pbpid_id  = -2 if mOther == 1

        replace plan       = -1 if _S
        replace cntrct_id  = -1 if _S
        replace pbpid_id   = -1 if _S

        drop _S

        label var bene_code       "Internal beneficiary code"
        label var year            "year"
        label var buyin           "Modal buy-in code"
        label var hmoind          "Modal HMO indicator"
        label var cntrct          "Modal contract ID"
        label var pbpid           "Modal plan id"

        label var cntrct_id       "Encoded modal contract ID (internal)"
        label var pbpid_id        "Encoded modal plan ID (internal)"
        label var plan            "Encoded modal contract-plan ID (internal)"

        label var dualcd          "Dual Code (modal)"
        label var sdod            "Date of death"
        label var deathyear       "Year of death"
        label var firstyear       "First year in the sample"
        label var monthsalive     "Months alive that year"
        label var lastyear        "Last year beneficiary appears enrolled in the sample"
        label var lastmonth       "Last month the modal enrollment appeared that year"
        label var monthsenrolled  "Months monthsenrolled that year"

        label var nDual           "Months dual"
        label var nHMO            "Months HMO 0 or 4"
        label var nFFS            "Months FFS 3 or C"
        label var nTM             "Months TM (both HMO and FFS each month)"
        label var nMA             "Months MA (H contract)"
        label var nEmployer       "Months nEmployer (HMO is C and R contract)"

        label var mDual           "Modal enrollment is dual"
        label var mHMO            "Modal enrollment HMO is 0 or 4"
        label var mFFS            "Modal enrollment FFS is 3 or C"
        label var mTM             "Modal enrollment is HMO and FFS"
        label var mMA             "Modal enrollment contract is H"
        label var mOther          "Modal enrollment enrollment was not TM or MA"
        label var mEmployer       "Modal enrollment is employer plan (HMO is C and R contract)"

        label var eSwitch         "Switched plan or contract"
        label var eTM             "Both HMO and FFS for during more than half the months bene was alive"
        label var eMA             "MA more than half the months bene was alive"
        label var eHMO            "HMO 0 or 4 more than half the months bene was alive"
        label var eFFS            "FFS 3 or C more than half the months bene was alive"
        label var eDual           "Dual enrollment more than half the months bene was alive"
        label var eOther          "Nor MA or TM for more than half the months bene was alive"
        label var eEmployer       "Enrollment in employer plan more than half the months bene was alive"

    save `"${data}/denom`pct'_longchunks.dta"', `replace'

    /* DOC
     *
     * Do some sanity checks!
     *
     */

    * Only one year where months alive may be < 12; if == 12 it must be
    * december death

    assert (monthsalive == 12) | ((deathyear == year) & (month(sdod) == monthsalive))

    * Consistency of indicators

    assert (eOther + eTM + eMA) == 1
    assert (mOther + mTM + mMA) == 1
    assert !((mTM == 1) & (mMA == 1))
    assert !((eTM == 1) & (eMA == 1))

    assert (eTM    <= mTM)
    assert (eMA    <= mMA)
    assert (eOther >= mOther)

    * # benes matches rows in denom`pct'

    gunique bene_code
    local J = `r(J)'
    qui desc using `"${data}/denom`pct'.dta"'
    assert `r(N)' == `J'
end

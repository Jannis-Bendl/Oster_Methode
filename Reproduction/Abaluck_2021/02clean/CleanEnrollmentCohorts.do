* ---------------------------------------------------------------------
* Clean enrollment data

* DOC: We add demographics and location, then add some sanity flags,
* like a discontinuity flag, a flag for multiple deaths, whether they
* ever lived outside DC or the 50 US states, whether they died before a
* year of enrollment, and so on.

capture program drop cleanCohorts
program cleanCohorts
    syntax, pct(str) [replace]

    * ------------------------
    * Merge in enrollment data
    * ------------------------

    * DOC: Get location data by year (zip, state, county)

    local vars bene_code zip* state* county*
    use `vars' using `"${data}/denom`pct'.dta"', clear
        greshape long zip state county, i(bene_code) j(year) dropmiss
        drop if mi(county) | mi(state) | mi(zip)
        compress
    save `"${data}/denom`pct'_loc.dta"', `replace'

        * DOC: We drop beneficiaries ever not in the 50 US states or DC.

        merge m:1 state using `"${data}/state_xw.dta"', keep(1 3) keepusing(keep st) nogen
        replace keep = 0 if mi(keep)
        gegen keep = min(keep), by(bene_code) replace
        rename keep alwaysIn50StatesOrDC

        * DOC: We merge enrollment data, including enrollment status the
        * last month of the year and modal enrollment.

        local keeps keep(3) nogen keepusing(sdod sdob race sex)
        merge m:1 bene_code using `"${data}/denom`pct'_lean.dta"', `keeps'
        replace zip = substr(zip, 1, 5)

        local keeps keep(3) nogen
        merge 1:1 bene_code year using `"${data}/denom`pct'_longchunks.dta"', `keeps'
        sort bene_code year

        * DOC: Last data year, which includes last year location data
        * _and_ enrollment data was non-missing for this beneficiary

        gegen lastdatayear = max(year), by(bene_code)
        label var lastdatayear "Last year beneficiary appears with both enrollment and location data"

        * DOC: Drop beneficiaries with gap years (otherwise this messes
        * up various lag variables).

        local discontinuous ((year[_n + 1] != (year + 1)) & (_n < _N))
        by bene_code (year): gen byte discontinuousEnrollment = `discontinuous'
        gegen discontinuousEnrollment = max(discontinuousEnrollment), by(bene_code) replace

        * DOC: Drop beneficiaries with only one year (otherwise this messes
        * up various lag variables).

        gegen nyears = count(1), by(bene_code)

        * DOC: Flag if ever missing plan ID

        gegen everMissingPlan = max(mi(plan)), by(bene_code)

        * DOC: Flag beneficiaries who die after their last year in the sample

        gen diesAfterLast = (lastdatayear < deathyear) & !mi(deathyear)

        * DOC: Generate demographics, including date the beneficiary
        * first appeared, date of death, sex, race, and X-days out
        * mortality. Note that we only keep people from their first year
        * of full enrollment until death (unless their first year of
        * enrollment is the year they died, in which case we keep that
        * first year for the months they were alive).

        gen long date_first = date(string(year) + "-01-01", "YMD")
        gen      demo_age   = floor((date_first - sdob) / 365.25)

        rename sdob date_birth
        rename sdod date_death
        rename race demo_race
        rename sex  demo_sex

        * DOC: Died within the year (no Jan tolerance; must have died
        * that same year)

        gen byte died_365 = cond(mi(date_death), 0, (year == deathyear))
        label var died_365 "Died that year"
        gegen ndeaths_365 = sum(died_365), by(bene_code)
        assert inlist(ndeaths_365, 0, 1)

        * DOC: Flag beneficiaries who drop off the sample before they die or
        * the sample ends.  We investigated these instances and they were
        * all cases where they had missing enrollment or location data from
        * a particular year until the end of the sample.  This means they
        * are dropped by other criteria but since they technically don't
        * have "gaps" anymore (since they do not reappear) we don't have
        * another way of identifying them. Enrollment example:
        *
        *     bene_code | year | plan | sdod
        *     1         | 2012 |    1 | .
        *     1         | 2013 |    1 | .
        *
        * Above we have a beneficiary in the sample with a non-missing plan
        * and no date of death continuously enrolled from 2012 to 2013. In
        * the raw data, we would see the following:
        *
        *     bene_code | year | plan | sdod
        *     1         | 2012 |    1 | .
        *     1         | 2013 |    1 | .
        *     1         | 2014 |    . | .
        *
        * Since beneficiaries should only exit the sample upon death or when
        * the sample ends, we exclude beneficiaries with this issue.  (Note
        * the actual check looks at whether _every_ enrollment variable is
        * missing, namely: buyin hmoind cntrct pbpid dualcd).  Similarly for
        * missing location data:
        *
        *     bene_code | year | county | sdod
        *     1         | 2012 |      1 | .
        *     1         | 2013 |      1 | .
        *
        * again in the raw data we would see
        *
        *     bene_code | year | county | sdod
        *     1         | 2012 |      1 | .
        *     1         | 2013 |      1 | .
        *     1         | 2014 |      . | .
        *
        * Since we need location data to identify a plan (we define
        * plans by county) we exclude beneficiaries with this issue.
        * (Note the actual check looks at whether _any_ location data
        * is missing, any of zip state county).

        qui sum year, meanonly
        gen byte exitsBeforeDeathOrEnd = (lastdatayear < `r(max)') & mi(date_death)
        gegen exitsBeforeDeathOrEnd = max(exitsBeforeDeathOrEnd), by(bene_code) replace

        * DOC: Generate all the fixed effects and aux variables.

        gen   long fe_age          = 5 * floor(demo_age / 5)
        gegen long fe_sex          = group(demo_sex)
        gegen long fe_race         = group(demo_race)
        gegen long fe_state        = group(state)
        gegen long fe_county       = group(state county)
        gegen long fe_county_year  = group(state county year)
        gegen      age_median      = median(demo_age), by(bene_code)
        gegen      age_first       = min(demo_age),    by(bene_code)

        * DOC: We truncate age if younger than 60 or older than 95 given
        * those categories are so small.

        replace fe_age = 60 if fe_age <= 60
        replace fe_age = 95 if fe_age >= 95

        label var county      "SSA County"
        label var state       "SSA State"
        label var zip         "5-digit ZIP"

        label var date_first  "First date beneficiary appeared that year"
        label var date_death  "Date of death"
        label var date_birth  "Date of birth"
        label var demo_age    "Age at first appearance in year"
        label var demo_race   "Encoded race"
        label var demo_sex    "Encoded sex"
        label var age_median  "Median age"
        label var age_first   "Age on entering the sample"

        label var alwaysIn50StatesOrDC    "Bene always lived in 50 states or DC"
        label var exitsBeforeDeathOrEnd   "Bene has incomplete enrollment or location data."
        label var discontinuousEnrollment "Bene has a gap year in their enrollment data."
        label var everMissingPlan         "Bene has both contract and plan information missing every month of a year."
        label var diesAfterLast           "Last year of enrollment occurs after year of death."

    save `"${data}/denom`pct'_cohorts.dta"', `replace'
end

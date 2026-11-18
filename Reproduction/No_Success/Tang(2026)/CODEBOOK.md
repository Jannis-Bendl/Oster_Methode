# CODEBOOK: Regulatory Competition in the US Life Insurance Industry

**Author:** Johnny Tang
**Date:** March 2, 2026

This codebook describes variables obtained from each data source to allow researchers to verify they have obtained substantially similar datasets.

---

## 1. S&P Global Market Intelligence - SNL Financial

Access: Available via S&P Global Market Intelligence (SNL Financial) subscription or institutional access; request data exports through S&P Global.

**Data Files:**
* `raw/SNL/SNL_Basic_Information_AllLevels_2024.xls`
* `raw/SNL/SNL_Life_Basic_Information_Company.xls`
* `raw/SNL/SNL_Life_Basic_Information_Company_with_GroupNames.xls`
* `raw/SNL/SNL_Life_Financials_Company_with_2021.xls`
* `raw/SNL/SNL_Life_Financials_Group_with_2021.xls`
* `raw/SNL/SNL_Life_Financials_Group_2_with_2021.xls`
* `raw/SNL/SNL_Life_Quantities_Reserves_Aggregate_Company.xls`
* `raw/SNL/SNL_NonLife_Basic_Information_Company.xls`
* `raw/SNL/SNL_NonLife_Basic_Information_Group_Domicile.xls`

**Variables:**
- `snl_institution_key`: Unique identifier for insurance company
- `snl_company_key`: Company-level identifier
- `company_name`: Name of insurance company
- `naic_code`: NAIC company code
- `fein`: Federal Employer Identification Number
- `state_code`: State code where company is domiciled
- `state_name`: State name
- `domicile_state`: State of domicile
- `domicile_country`: Country of domicile
- `total_assets`: Total admitted assets
- `total_liabilities`: Total liabilities
- `capital_surplus`: Capital and surplus
- `net_income`: Net income
- `total_revenue`: Total revenue
- `premiums_written`: Direct premiums written
- `premiums_earned`: Premiums earned
- `investment_income`: Net investment income
- `reins_ceded`: Reinsurance ceded
- `reins_assumed`: Reinsurance assumed
- `ceded_to_affiliates`: Amount ceded to affiliated companies
- `ceded_to_nonaffiliates`: Amount ceded to non-affiliated companies
- `life_premium`: Life insurance premiums
- `annuity_premium`: Annuity considerations
- `accident_health_premium`: Accident and health premiums
- `policy_reserves`: Aggregate reserves for life policies
- `separate_account_liabilities`: Separate account liabilities
- `claim_reserves`: Reserve for claims
- `filing_date`: Date of regulatory filing
- `period_end_date`: Ending date of reporting period
- `year`: Calendar year
- `quarter`: Quarter
- `company_type`: Type of insurance company
- `group_name`: Name of parent insurance group
- `group_key`: Identifier for parent group
- `active_inactive`: Status indicator

---

## 2. CompuLife

Access: Available via CompuLife (Life Quote Systems) subscription or licensed data extracts.

**Data Files:**
* `raw/Compulife/Extraction/compulife_csvs/*.csv`
* `raw/Compulife/Extraction/Prices_CompuLife_2001_to_2021_BeforeAMBestCodeMerge.csv`
* `raw/Compulife/Extraction/amb_names_to_codes.csv`
* `raw/Compulife/Pre2005/DataFromWin98Software_530Files/*`
* `raw/Compulife/StateLevel/*/Prices_250k_Male_40_*.csv`

**Variables:**
- `company_name`: Insurance company name
- `product_name`: Name of life insurance product
- `amb_code`: A.M. Best company code
- `naic_code`: NAIC code
- `policy_type`: Type of policy
- `product_type`: Type of insurance product
- `term_length`: Length of term
- `face_amount`: Death benefit / face value
- `premium_mode`: Payment frequency
- `age`: Age of insured
- `gender`: Gender of insured
- `smoking_status`: Smoker or non-smoker
- `underwriting_class`: Health classification
- `annual_premium`: Annual premium amount
- `monthly_premium`: Monthly premium amount
- `premium_per_1000`: Premium per $1,000 of coverage
- `avg_premium`: Average premium in state
- `median_premium`: Median premium
- `num_quotes`: Number of price quotes
- `state_code`: State code
- `quarter`: Quarter of data extract
- `year`: Year
- `month`: Month

---

## 3. A.M. Best

Access: Available via A.M. Best licensing or institutional subscriptions.

**Data Files:**
* `raw/AMBest/AMBest_Ratings_All.csv`
* `raw/AMBest/AMBest_Impairment_Transition_Tables.csv`
* `raw/AMBest/AMBest_ID.csv`
* `raw/AMBest/AMBest_ID_NAIC.csv`
* `raw/AMBest/AMBest_Companies_USOnly.xlsx`
* `raw/AMBest/AMBest_Ratings_Scale.csv`

**Variables:**
- `amb_number`: A.M. Best number
- `amb_code`: A.M. Best company code
- `company_name`: Company name
- `naic_code`: NAIC code
- `snl_key`: SNL key
- `rating`: A.M. Best Financial Strength Rating
- `rating_numeric`: Numeric conversion of rating
- `rating_date`: Date of rating assignment/change
- `outlook`: Rating outlook
- `rating_action`: Type of rating change
- `rating_category`: Category description
- `rating_symbol`: Letter rating symbol
- `numeric_score`: Numeric score for ordering
- `impairment_date`: Date of impairment event
- `impairment_type`: Type of impairment
- `prior_rating`: Rating before impairment
- `year`: Year
- `quarter`: Quarter

---

## 4. Database on Ideology, Money in Politics, and Elections - DIME

Access: Available from the DIME project (public data release) and related documentation.

**Data Files:**
* `raw/DIME/DIME_StateYear.csv`
* `raw/DIME/DIME_InsurerStateYear.csv`
* `raw/DIME/SNL_NonLife_Basic_Information_Company.csv`

**Variables:**
- `contributoremployer`: Employer name of contributor
- `fundmanagerid`: Unique identifier for company
- `snl_key`: SNL key
- `amount`: Contribution amount
- `date`: Date of contribution
- `cycle`: Election cycle year
- `recipientid`: Unique identifier for recipient
- `recipient_name`: Name of recipient
- `party`: Political party
- `seat`: Type of seat
- `state`: State where recipient is running
- `district`: Congressional district
- `is_state`: Indicator for state-level race
- `is_general`: Indicator for general election
- `is_primary`: Indicator for primary election
- `is_runoff`: Indicator for runoff election
- `contributor_cfscore`: Ideological score of contributor
- `recipient_cfscore`: Ideological score of recipient
- `recipient_icpsr`: ICPSR identifier for recipient
- `num_trans`: Number of transactions
- `total_amount`: Total amount contributed
- `year`: Year
- `total_contributions`: Total contributions in year
- `num_recipients`: Number of recipients
- `num_transactions`: Number of transactions
- `pct_to_democrats`: Percent of contributions to Democrats
- `pct_to_republicans`: Percent of contributions to Republicans
- `pct_to_state`: Percent to state-level candidates
- `pct_to_federal`: Percent to federal-level candidates
- `avg_recipient_cfscore`: Average recipient ideology score
- `sd_recipient_cfscore`: Standard deviation of recipient ideology
- `state_code`: State code
- `state_name`: State name
- `total_to_state`: Total contributions to candidates in state
- `num_insurers_contributing`: Number of insurers contributing to state

---

## 5. Egan, Ge, and Tang (2022) Data

Access: Available via the authors or associated replication materials.

**Data Files:**
* `raw/EGT/Life insurance commissions/COMMISSIONS_ordinary_life.csv`
* `raw/EGT/Life insurance commissions/PREMIUMS_ordinary_life.csv`
* `raw/EGT/Life insurance commissions/ISSUED_amount_ordinary_life.csv`
* `raw/EGT/Life insurance commissions/year1premium_direct_ordinary_life.csv`

**Variables:**
- `Entity Name`: Name of insurance company
- `SNL Statutory Entity Key`: SNL identifier
- `NAIC_code`: NAIC code
- `COMMISSIONS_[year]`: Total commissions paid in year
- `PREMIUMS_[year]`: Total premiums for ordinary life
- `ISSUED_amount_[year]`: Amount of new policies issued
- `com2prem`: Commission to premium ratio
- `mcom2prem`: Modified commission to premium ratio
- `year`: Year
- `snl_key`: SNL key

---

## 6. Chodorow-Reich, Ghent, and Haddad (2021) Data

Access: Available via the authors or their replication data archive.

**Data Files:**
* `raw/ChodorowReich/forJohnnyTang.dta`
* `raw/ChodorowReich/DefaultBonds.csv`
* `raw/ChodorowReich/outliers.ado`

**Variables:**
- `cusip`: CUSIP identifier for bond
- `issuer_name`: Name of municipal bond issuer
- `issuer_state`: State of issuer
- `maturity_date`: Bond maturity date
- `coupon_rate`: Coupon rate
- `par_value`: Par value of holding
- `book_value`: Book value of holding
- `market_value`: Market value of holding
- `yield`: Yield to maturity
- `naic_code`: NAIC code of insurance company holder
- `company_name`: Name of insurance company
- `year`: Year
- `quarter`: Quarter
- `report_date`: Date of regulatory report

---

## 7. Koijen and Yogo (2015) Data

Access: Koijen-Yogo data are available via the authors or AER data archive.

**Data Files:**
* `raw/KY/KY_AER_2015/112888-V1/20121036_Data/Stata/data/CombinedData.dta`

**Variables:**
- `company_name`: Insurance company name
- `naic_code`: NAIC code
- `amb_code`: A.M. Best code
- `total_assets`: Total assets
- `capital_surplus`: Capital and surplus
- `separate_account_assets`: Separate account assets

---

## 8. Federal Reserve Data

Access: Publicly available from the Federal Reserve (FRED).

**Data Files:**
* `raw/FederalReserve/DGS30.csv`
* `raw/FederalReserve/GurkaynakSackWright.csv`

**Variables:**
- `date`: Date
- `treasury_rate`: Treasury rate
- `series_id`: FRED series identifier

---

## 9. 10-K Subsidiary Data - SNL Export

Access: Available via SNL.

**Data Files:**
* `raw/10K/SNL_Companies_Captives_CapitalSurplus_List_output_combined.xlsx`

**Variables:**
- `parent_company_name`: Name of parent company
- `parent_cik`: CIK of parent
- `parent_ticker`: Stock ticker of parent
- `subsidiary_name`: Name of subsidiary insurance company
- `subsidiary_state`: State where subsidiary is domiciled
- `subsidiary_country`: Country of subsidiary
- `ownership_percentage`: Percent owned by parent
- `capital_surplus`: Capital and surplus of subsidiary
- `total_assets`: Total assets of subsidiary
- `year`: Year of 10-K filing
- `is_captive`: Indicator for whether subsidiary is a captive
- `captive_state`: State where captive is domiciled

---

## 10. 10-K Subsidiary Data - WRDS

Access: Available via WRDS subscription.

**Data Files:**
* `raw/WRDS/10K_Subsidiaries.csv`

**Variables:**
- `parent_company_name`: Name of parent company
- `parent_cik`: CIK of parent
- `parent_ticker`: Stock ticker of parent
- `subsidiary_name`: Name of subsidiary insurance company
- `subsidiary_state`: State where subsidiary is domiciled
- `subsidiary_country`: Country of subsidiary
- `ownership_percentage`: Percent owned by parent
- `capital_surplus`: Capital and surplus of subsidiary
- `total_assets`: Total assets of subsidiary
- `year`: Year of 10-K filing
- `is_captive`: Indicator for whether subsidiary is a captive
- `captive_state`: State where captive is domiciled

---

## 11. NAIC List of Captive Regulators

Access: Hand collected from publicly-available NAIC publications and state insurance department websites.

**Data Files:** `raw/States/CaptiveRegulators.csv`

**Variables:**
- `state_code`: State code
- `state_name`: State name
- `has_captive_regulator`: Indicator for whether state regulates captives
- `captive_bureau_year`: Year state established captive insurance bureau
- `captive_statute_year`: Year state enacted captive insurance statute

---

## 12. Google Trends Data

Access: Publicly available via Google Trends.

**Data Files:** `raw/Google/GoogleSearchTrends_*.csv`

**Variables:**
- `state`: State name or code
- `date`: Date or time period
- `search_term`: Search term or keyword
- `search_interest`: Relative search interest
- `geoName`: Geographic name
- `week`: Week identifier

---

## 13. WebAnnuities - Annuity Shopper-Style Quotes

Access: Available via WebAnnuities; obtain access through permitted downloads or subscription terms.

**Data Files:**
* `raw/WebAnnuities/Prices_WebAnnuities_2011_2021.csv`
* `raw/WebAnnuities/amb_codes.csv`
* `raw/WebAnnuities/amb_codes_Input.csv`
* `raw/WebAnnuities/files/*.csv`

**Variables:**
- `company_name`: Insurance company name
- `product_name`: Annuity product name
- `annuity_type`: Type of annuity
- `rate`: Credited interest rate or return
- `surrender_charge`: Surrender charge percentage
- `surrender_period`: Number of years with surrender charges
- `minimum_premium`: Minimum premium required
- `date`: Date of quote

---

## 14. U.S. Bureau of Labor Statistics - QCEW

Access: Publicly available from the U.S. Bureau of Labor Statistics.

**Data Files:**
* `raw/Other/QCEW/QCEW.csv`
* `raw/Other/BLS_Wages/oe.area.txt`

**Variables:**
- `state_code`: State FIPS code
- `area_code`: Area code
- `industry_code`: NAICS industry code
- `own_code`: Ownership code
- `year`: Year
- `quarter`: Quarter
- `total_establishments`: Number of establishments
- `total_employment`: Total employment
- `total_wages`: Total wages
- `avg_weekly_wage`: Average weekly wage

---

## 15. U.S. Census Bureau - Business Formation Statistics

Access: Publicly available from the U.S. Census Bureau.

**Data Files:** `raw/Other/BFS_Businesses.csv`

**Variables:**
- `state`: State name or code
- `year`: Year
- `month`: Month
- `naics_code`: NAICS industry code
- `business_applications`: Number of business applications
- `high_propensity_applications`: Applications with high propensity to become employer businesses
- `corporations`: Number of corporate applications
- `partnerships`: Number of partnership applications

---

## 16. American Bar Association Lawyer Statistics

Access: Publicly available from the American Bar Association.

**Data Files:** `raw/Other/ABA_Lawyers.csv`

**Variables:**
- `state`: State name or code
- `year`: Year
- `total_lawyers`: Total number of resident lawyers
- `active_lawyers`: Number of active lawyers
- `population`: State population
- `lawyers_per_capita`: Lawyers per capita

---

## 17. Society of Actuaries - SOA Data

Access: Available via the Society of Actuaries publications or data requests.

**Data Files:** `raw/Industry/SOA_Quantities_RegXXX.csv`

**Variables:**
- `company_name`: Insurance company name
- `naic_code`: NAIC code
- `xxx_reserves`: Reserves held under Regulation XXX
- `axxx_reserves`: Reserves held under Actuarial Guideline AXXX
- `captive_xxx_reserves`: XXX reserves ceded to captives
- `year`: Year

---

## 18. Insurance Information Institute - III Statistics

Access: Available via the Insurance Information Institute.

**Data Files:**
* `raw/III/III_Captives.xlsx`
* `raw/III/III_DPW_PC.xlsx`

**Variables:**
- `year`: Year
- `total_industry_assets`: Total industry assets
- `total_industry_premiums`: Total industry premiums
- `num_companies`: Number of companies
- `captive_share`: Share of business in captives

---

## 19. State Regulation Data - NAIC IDRR

Access: Available from NAIC publications and data releases.

**Data Files:**
* `raw/NAIC/IDRR/IDRR_All.csv`
* `raw/NAIC/IDRR/IDRR_CaptiveStaff.xlsx`
* `raw/NAIC/IDRR/IDRR_Commissioners.csv`
* `raw/NAIC/IDRR/Consumers.xlsx`

**Variables:**
- `state_code`: State code
- `state_name`: State name
- `year`: Year
- `num_regulatory_staff`: Number of insurance regulatory staff
- `regulatory_budget`: State insurance department budget
- `FinancialRegulation_staff_total`: Total financial regulation staff
- `FinancialRegulation_staff_per_insurer`: Staff per insurer
- `Commissioner_Appointment`: Method of commissioner appointment

---

## 20. State Regulation Data - Disclosure and Corruption

Access: Publicly available from state disclosure sources and corruption data releases.

**Data Files:**
* `raw/Other/GoodJobsFirst_StateDisclosure.xlsx`
* `raw/Other/corruption/Output/year.state.corruption.pop.csv`

**Variables:**
- `state_code`: State code
- `state_name`: State name
- `year`: Year
- `disclosure_score`: Regulatory disclosure score
- `disclosure_rank`: Regulatory disclosure rank
- `corruption`: Corruption measure

---

## 21. State Regulation Data - Special Revenue Funds

Access: Publicly available from state special revenue fund disclosures.

**Data Files:**
* `raw/States/SpecialRevenueFunds/SpecialRevenueFunds.csv`

**Variables:**
- `state_code`: State code
- `state_name`: State name
- `year`: Year
- `SpecialRevenueFund_pct_total`: Special revenue fund as percent of total

---

## 22. SNL Geographic and Market Structure Data

Access: Available via S&P Global Market Intelligence (SNL Financial) subscription or institutional access.

**Data Files:**
* `raw/SNL/MarketShare/SNL_Life_MarketShare_*.xls`
* `raw/SNL/Impairments/SNL_Impairments.xlsx`

**Variables:**
- `snl_key`: SNL institution key
- `company_name`: Insurance company name
- `naic_code`: NAIC code
- `state_code`: State code
- `state_name`: State name
- `direct_premiums_written_by_state`: Direct written premiums by state
- `market_share_state`: Market share within state
- `hhi_state`: Herfindahl-Hirschman Index by state
- `group_hhi`: HHI at group level
- `num_companies_in_group`: Number of companies in insurance group
- `impairment_date`: Date of impairment
- `impairment_amount`: Amount of impairment
- `impairment_type`: Type of impairment (receivership, rehabilitation, etc.)

---

## 23. State Distance Data

Access: Publicly available from state geographic distance sources.

**Data Files:**
* `raw/States/States_Distances.csv`

**Variables:**
- `distance_miles`: Distance between states in miles
- `state_from`: Origin state
- `state_to`: Destination state

---

## 24. SNL Capital and Reserve Ratios

Access: Available via S&P Global Market Intelligence (SNL Financial) subscription or institutional access.

**Data Files:**
* `raw/SNL/InsuranceStatutoryFinancials/*.xls`
* `raw/SNL/InsuranceStatutoryFinancials_Reserves/*.xls`
* `raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/*.csv`

**Variables:**
- `snl_key`: SNL institution key
- `naic_code`: NAIC code
- `year`: Year
- `quarter`: Quarter
- `opco_capital_ratio`: Operating company capital ratio
- `statutory_reserves`: Statutory reserves
- `gaap_reserves`: GAAP reserves
- `reserve_ratio`: Ratio of statutory to GAAP reserves
- `is_captive`: Indicator for captive insurer
- `captive_capital_rate`: Capital rate for captive
- `state_code`: State code
- `debt_to_liabilities`: Debt to liabilities ratio
- `total_debt`: Total debt
- `total_liabilities`: Total liabilities

---

## 25. Lombardi Reserves Data

Access: Available via Lombardi/third-party data licensing.

**Data Files:**
* `raw/Lombardi/Reserves.xlsx`

**Variables:**
- `naic_code`: NAIC code
- `year`: Year
- `quarter`: Quarter
- `statutory_reserves`: Statutory reserves
- `gaap_reserves`: GAAP reserves
- `reserve_ratio`: Ratio of statutory to GAAP reserves

---

## 26. SNL Reinsurance Data - Extended

Access: Available via S&P Global Market Intelligence (SNL Financial) subscription or institutional access.

**Data Files:**
* `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_*.xls`
* `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_*.xls`
* `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsurnceRelationships*.xls`
* `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_missing_20220222.*`
* `raw/SNL/ReinsuranceRelationships_Supplement/SNLLife_ReinsuranceRelationships _Supplement_*.xls`
* `raw/SNL/ReinsuranceRelationships/BusinessType/SPGlobal_Export_*.xls`
* `raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_*.xls`
* `raw/SNL/ScheduleY/Life Sch Y Part 1A 24Q3/L24Q3066.csv`

**Variables:**
- `snl_key_ceding`: SNL key for ceding company
- `snl_key_assuming`: SNL key for assuming company
- `naic_code_ceding`: NAIC code of ceding company
- `naic_code_assuming`: NAIC code of assuming company
- `agreement_id`: Reinsurance agreement identifier
- `ceded_amount`: Amount of liabilities ceded
- `assumed_premiums`: Assumed premiums
- `ceded_reserves`: Ceded reserves
- `year`: Year
- `quarter`: Quarter
- `is_captive_assuming`: Indicator if assuming company is captive
- `is_affiliate`: Indicator if reinsurer is affiliated
- `treaty_type`: Type of reinsurance treaty
- `ky_shadow`: Indicator for Koijen-Yogo shadow insurance classification
- `business_type`: Type of insurance business reinsured

---

## 27. State Regulatory Infrastructure

Access: Publicly available from state insurance departments and compiled sources.

**Data Files:**
* `raw/States/StateNames.csv`
* `raw/States/StateNames_US.csv`
* `raw/States/CaptiveRegulators.csv`
* `raw/States/CaptiveRegulators_Websites_Output.csv`
* `raw/States/IA/CapitalAndLiability.xlsx`

**Variables:**
- `state_code`: State postal code
- `state_name`: Full state name
- `state_fips`: FIPS code
- `state_abbreviation`: State abbreviation
- `has_captive_regulator`: Indicator for captive insurance bureau
- `captive_bureau_year`: Year captive bureau established
- `captive_statute_year`: Year captive statute enacted
- `regulator_website`: URL of state insurance regulator
- `captive_division_url`: URL of captive insurance division
- `contact_email`: Regulator contact email
- `regulatory_staff_count`: Number of regulatory staff

---

## 28. NOLHGA Insolvency Data

Access: Available from NAIC/NOLHGA publications and data releases.

**Data Files:**
* `raw/NAIC/NOLHGA_Insolvencies.xlsx`
* `raw/NAIC/NOLHGA_insolvdata21.xlsx`

**Variables:**
- `company_name`: Name of insolvent company
- `naic_code`: NAIC code
- `state_of_domicile`: Domicile state
- `insolvency_date`: Date of insolvency declaration
- `insolvency_type`: Type of insolvency (liquidation, rehabilitation, etc.)
- `guaranty_fund_assessment`: Amount assessed to guaranty funds
- `policyholders_affected`: Number of policyholders affected
- `total_claims`: Total claims paid
- `year`: Year of insolvency

---

## 29. Investment Advisers Association Data

Access: Available from the Investment Advisers Association or related data releases.

**Data Files:** `raw/Other/InvestmentAdvisersAssociation_AUM_ByState.csv`

**Variables:**
- `state_code`: State code
- `state_name`: State name
- `year`: Year
- `total_aum`: Total assets under management in state
- `num_advisers`: Number of registered investment advisers
- `aum_per_adviser`: AUM per adviser

---

## 30. Other Public Data Sources

Access: Publicly available from their respective sources (BTS, FASB, FRED, and election data repositories).

**Data Files:**
* `raw/Other/BTS_Tourism.csv`
* `raw/Other/FASB_Vega.csv`
* `raw/Other/FRED_StatePopulation.xls`
* `raw/Other/Votes/dataverse_files/1976-2020-president.csv`

**Variables:**
- `state`: State name or code (when applicable)
- `year`: Year (when applicable)
- `value`: Source-specific measure

---

**Contact:** Johnny Tang, johnnytang857@gmail.com

# Data and Code for: "Regulatory Competition in the US Life Insurance Industry"

## Overview

This replication package contains the code and documentation necessary to replicate all results in the paper "Regulatory Competition in the US Life Insurance Industry" by Johnny Tang (Cornell University), published in the Journal of Political Economy.

## Package Contents

The replication package is organized as follows:

```
.
├── README.md                    # This file
|
├── CleanData/                   # Data cleaning code and scripts
│   ├── code/                    # Data cleaning scripts (.R files)
│   ├── output/                  # Output folder for results using simulated data
│   └── make.R                   # Master script for data cleaning
│
├── Analysis_Demand/             # Demand analysis code and scripts
│   ├── code/                    # Analysis scripts (.R files)
│   ├── output/                  # Output folder for results using simulated data
│   ├── output_actual/           # Output folder for results using actual (non-simulated) data
│   └── make.R                   # Master script for demand analysis
│
├── Analysis_Insurer/            # Insurer analysis code and scripts
│   ├── code/                    # Analysis scripts (.R, .py, .do files)
│   ├── output/                  # Output folder for results using simulated data
│   ├── output_actual/           # Output folder for results using actual (non-simulated) data
│   └── make.R                   # Master script for insurer analysis
│
└── lib/                         # Shared libraries and functions
    ├── ado/                     # Stata ado files
    ├── python/                  # Python utility functions
    ├── r/                       # R utility functions
    └── stata/                   # Stata utility functions
```

## Data Availability Statement

- This paper uses data from multiple sources, some of which are proprietary and cannot be redistributed. 
- [SIMULATED DATA PROVIDED ONLY] indicates that the data provided is simulated data. The values are generated from simulation and are intended to show how to run the replication package only. The values and any derived outputs are not intended to be indicative of the actual data.
- Below is a complete list of all raw data sources required to replicate the results, including the simulated data.
- Note: Unless otherwise stated, all the below data sources are raw data, accessible via the access instructions provided for each. The file names may differ from the names when originally downloaded due to naming differences.

### Data Sources
1. **[SIMULATED DATA PROVIDED ONLY] S&P Global Market Intelligence (formerly SNL Financial)**
   - Description: Comprehensive statutory financial statements, market share data, and reinsurance relationships for US life insurance companies
   - Access: Requires institutional subscription to S&P Global Market Intelligence; request data exports through S&P Global
      - https://www.capitaliq.spglobal.com/web/client?auth=inherit#office/screener?perspective=287 (subscription required)
      - Note: The SNL files are obtained from manually downloading from the screener tool linked above. 
      - The file names indicate (1) which tab in the Screener to obtain the data from: Basic Information, Market Share, Impairments, Insurance Statutory Financials, Reinsurance Relationships, Schedule Y, or Companies; (2) what level is the information aggregated to: Company or Group level
      - All these files can be exactly replicated by downloading all the rows of all the columns listed in each file.
         - However, note that SNL may not keep point-in-time history so there may be differences from data revisions by S&P.
      - Several of the below files are obtained from custom data queries to S&P, as indicated by "(custom query)". To replicate these, please reach out to S&P.
   - Data Files:
     - `raw/SNL/SNL_Basic_Information_AllLevels_2024.xls`
     - `raw/SNL/SNL_Life_Basic_Information_Company.xls`
     - `raw/SNL/SNL_Life_Basic_Information_Company_with_GroupNames.xls`
     - `raw/SNL/SNL_Life_Financials_Company_with_2021.xls`
     - `raw/SNL/SNL_Life_Financials_Group_with_2021.xls`
     - `raw/SNL/SNL_Life_Financials_Group_2_with_2021.xls`
     - `raw/SNL/SNL_Life_Quantities_Reserves_Aggregate_Company.xls`
     - `raw/SNL/SNL_NonLife_Basic_Information_Company.xls`
     - `raw/SNL/SNL_NonLife_Basic_Information_Group_Domicile.xls`
     - `raw/SNL/MarketShare/SNL_Life_MarketShare_*.xls`
     - `raw/SNL/Impairments/SNL_Impairments.xlsx`
     - `raw/SNL/InsuranceStatutoryFinancials/*.xls`
     - `raw/SNL/InsuranceStatutoryFinancials_Reserves/*.xls`
     - `raw/SNL/InsuranceStatutoryFinancials/Benefits/12320697 CSV Request/*.csv` (custom query)
     - `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_BasicInfo_*.xls`
     - `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_ParentNames_*.xls`
     - `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsurnceRelationships*.xls`
     - `raw/SNL/ReinsuranceRelationships/SNLLife_ReinsuranceRelationships_missing_20220222.*`
     - `raw/SNL/ReinsuranceRelationships_Supplement/SNLLife_ReinsuranceRelationships _Supplement_*.xls`
     - `raw/SNL/ReinsuranceRelationships/BusinessType/SPGlobal_Export_*.xls`
     - `raw/SNL/ReinsuranceRelationships/Ratings/SPGlobal_Export_*.xls`
     - `raw/SNL/ScheduleY/Life Sch Y Part 1A 24Q3/L24Q3066.csv` (custom query)
     - `raw/10K/SNL_Companies_Captives_CapitalSurplus_List_output_combined.xlsx`
   - Cost: contact S&P for pricing
   - Citation: S&P Global Market Intelligence. (2005-2019). Insurance Statutory Financials and Market Share Data [Data set]. S&P Global.

2. **[SIMULATED DATA PROVIDED ONLY] CompuLife Insurance Pricing Database**
   - Description: Life insurance product pricing quotes by company, age, health status, term length, and state (1990-2021)
   - Access: Available via CompuLife (Life Quote Systems) subscription or licensed data extracts
      - https://www.compulife.net/historicaldata.php (historical CD)
      - The files are manually downloaded from the historical data CD.
      - Mapping from Compulife companies to AMBest codes is done manually.
   - Data Files:
     - `raw/Compulife/Extraction/compulife_csvs/*.csv`
     - `raw/Compulife/Extraction/Prices_CompuLife_2001_to_2021_BeforeAMBestCodeMerge.csv`
     - `raw/Compulife/Extraction/amb_names_to_codes.csv`
     - `raw/Compulife/Pre2005/DataFromWin98Software_530Files/*`
     - `raw/Compulife/StateLevel/*/Prices_250k_Male_40_*.csv`
   - Cost: contact CompuLife for pricing
   - Citation: CompuLife Software Inc. (1990-2021). CompuLife Insurance Pricing Database [Data set]. CompuLife Software Inc.

3. **[SIMULATED DATA PROVIDED ONLY] A.M. Best Company Credit Ratings and Financial Data**
   - Description: Credit ratings, impairment history, and default transition probabilities for US life insurance companies
   - Access: Available via A.M. Best licensing or institutional subscriptions (https://www.ambest.com)
   - Data Files:
     - `raw/AMBest/AMBest_Ratings_All.csv`
     - `raw/AMBest/AMBest_Impairment_Transition_Tables.csv`
     - `raw/AMBest/AMBest_ID.csv`
     - `raw/AMBest/AMBest_ID_NAIC.csv`
     - `raw/AMBest/AMBest_Companies_USOnly.xlsx`
     - `raw/AMBest/AMBest_Ratings_Scale.csv`
   - Cost: contact AMBest for pricing
   - Citation: A.M. Best Company. (2005-2019). Insurance Company Credit Ratings and Financial Strength Data [Data set]. A.M. Best Company.

4. **SEC EDGAR Database**
   - Description: Public company 10-K annual reports and insurance Forms N-4/485BPOS containing captive capital and asset information
   - Access: Publicly available at https://www.sec.gov/edgar
   - Cost: Free
   - Citation: U.S. Securities and Exchange Commission. (2005-2019). EDGAR Database [Data set]. https://www.sec.gov/edgar

5. **State Insurance Department Captive Regulations and Statutes**
   - Description: Captive insurance laws, capital requirements, tax rates, and regulatory guidance for all 50 states and DC
   - Access: Publicly available from state insurance department websites, compiled sources, and public records requests
      - raw/Other:
         - https://goodjobsfirst.org/financial-exposure-rating-the-states-on-economic-development-transparency/
         - https://www.justice.gov/criminal/criminal-pin/annual-reports
      - raw/States: All files were hand collected based on publicly-available Google searches
   - Data Files:
     - `raw/Other/GoodJobsFirst_StateDisclosure.xlsx`
     - `raw/Other/corruption/Output/year.state.corruption.pop.csv`
     - `raw/States/SpecialRevenueFunds/SpecialRevenueFunds.csv`
     - `raw/States/States_Distances.csv`
     - `raw/States/StateNames.csv`
     - `raw/States/StateNames_US.csv`
     - `raw/States/CaptiveRegulators_Websites_Output.csv`
     - `raw/States/IA/CapitalAndLiability.xlsx`
   - Cost: Free
   - Citation: [State] Department of Insurance. (Various years). Captive Insurance Regulations and Statutes [Regulatory documents]. [State] Insurance Department.

6. **NAIC Insurance Regulatory and Insolvency Data**
   - Description: Insurance company insolvency data, guaranty fund payouts, regulatory guidance
   - Access: Access from NAIC website at https://content.naic.org/ and NAIC publications; some data hand collected from NAIC releases and state insurance department websites
      - raw/States: All files were hand collected based on publicly-available Google searches
      - raw/NAIC/IDRR: https://naic.soutronglobal.net/Portal/Public/en-US/RecordView/Index/11628 (publicly downloadable)
   - Data Files:
     - `raw/States/CaptiveRegulators.csv`
     - `raw/NAIC/IDRR/IDRR_All.csv`
     - `raw/NAIC/IDRR/IDRR_CaptiveStaff.xlsx`
     - `raw/NAIC/IDRR/IDRR_Commissioners.csv`
     - `raw/NAIC/IDRR/Consumers.xlsx`
   - Cost: Free
   - Citation: National Association of Insurance Commissioners. (1989-2019). Insurance Regulatory Information System and Insolvency Data [Data set]. NAIC.

7. **DIME - Database on Ideology, Money in Politics, and Elections**
   - Description: Political campaign contributions and donation data for insurance industry
   - Access: Available from the DIME project (public data release) and related documentation at https://data.stanford.edu/dime
   - Data Files:
     - `raw/DIME/DIME_StateYear.csv`
     - `raw/DIME/DIME_InsurerStateYear.csv`
     - `raw/DIME/SNL_NonLife_Basic_Information_Company.csv`
   - Cost: Free
   - Citation: Bonica, Adam. (2016). Database on Ideology, Money in Politics, and Elections (Version 2.0) [Data set]. Stanford University. https://data.stanford.edu/dime

8. **Federal Reserve Economic Data (FRED)**
   - Description: Treasury yields, interest rates, state population, macroeconomic indicators
   - Access: Publicly available from the Federal Reserve (FRED) at https://fred.stlouisfed.org
   - Data Files:
     - `raw/FederalReserve/DGS30.csv`
     - `raw/FederalReserve/GurkaynakSackWright.csv`
     - `raw/Other/FRED_StatePopulation.xls`
   - Cost: Free
   - Citation: Federal Reserve Bank of St. Louis. (2005-2019). Federal Reserve Economic Data [Data set]. https://fred.stlouisfed.org

9. **[SIMULATED DATA PROVIDED ONLY] Lombardi Valuation of Life Insurance Liabilities**
   - Description: Formulae and data on calculating the values of life insurance liabilities
   - Access: Available via Lombardi/third-party data licensing; also distributed on CD-ROM with the purchase of the book "Lombardi, Louis J. Valuation of life insurance liabilities: establishing reserves for life insurance policies and annuity contracts. Actex Publications, 2006."
   - Data Files:
     - `raw/Lombardi/Reserves.xlsx`
   - Cost: $391 (on Amazon)
   - Citation: Lombardi, Louis J. Valuation of life insurance liabilities: establishing reserves for life insurance policies and annuity contracts. Actex Publications, 2006.

10. **Insurance Information Institute (III) Captive Statistics**
   - Description: Captive insurance market statistics and direct written premium data for property and casualty insurance
   - Access: Available via the Insurance Information Institute website:
      - https://www.iii.org/table-archive/21308
   - Data Files:
     - `raw/III/III_Captives.xlsx`
     - `raw/III/III_DPW_PC.xlsx`
   - Cost: Free
   - Citation: Insurance Information Institute (III). Captive Insurance Statistics and Direct Written Premium Data. Insurance Information Institute, various years.

11. **Society of Actuaries (SOA) Data**
   - Description: Life insurance quantity data related to Regulation XXX
   - Access: Available via the Society of Actuaries publication:
     - https://www.soa.org/493807/globalassets/assets/files/research/exp-study/xxx_report.pdf (Table 25)
   - Data Files:
     - `raw/Industry/SOA_Quantities_RegXXX.csv`
   - Cost: Free
   - Citation: Society of Actuaries (SOA). Regulation XXX Quantity Data. Society of Actuaries, various years.

12. **Google Trends**
   - Description: Search interest data for insurance-related terms including captives, bank failures, and insurer bankruptcies
   - Access: Publicly available via Google Trends at https://trends.google.com
   - Data Files:
     - `raw/Google/GoogleSearchTrends_*.csv`
   - Cost: Free
   - Citation: Google Trends. Search Interest Data for Insurance-Related Terms. Google Inc., various years. https://trends.google.com

13. **[SIMULATED DATA PROVIDED ONLY] Wharton Research Data Services (WRDS)**
   - Description: SEC 10-K subsidiary data for insurance companies
   - Access: Available via WRDS subscription
   - Data Files:
     - `raw/WRDS/10K_Subsidiaries.csv`
   - Cost: Contact WRDS for pricing
   - Citation: Wharton Research Data Services (WRDS). SEC 10-K Subsidiary Data. Wharton School, University of Pennsylvania, various years.

14. **[SIMULATED DATA PROVIDED ONLY] Annuity Shopper Magazine**
   - Description: Annuity product pricing and features data from industry publications
   - Access: Available via WebAnnuities:
     - https://www.immediateannuities.com/annuity-shopper/as-archive.html
     - AMBest codes are hand collected
   - Data Files:
     - `raw/WebAnnuities/Prices_WebAnnuities_2011_2021.csv`
     - `raw/WebAnnuities/amb_codes.csv`
     - `raw/WebAnnuities/amb_codes_Input.csv`
     - `raw/WebAnnuities/files/*.csv`
   - Cost: Contact Annuity Shopper for pricing
   - Citation: Annuity Shopper. Annuity Product Pricing and Features. Annuity Shopper Magazine, 2014-2018.

15. **U.S. Bureau of Labor Statistics - QCEW**
   - Description: Quarterly Census of Employment and Wages data by state and industry
   - Access: Publicly available from the U.S. Bureau of Labor Statistics at https://www.bls.gov/cew/
   - Data Files:
     - `raw/Other/QCEW/QCEW.csv`
     - `raw/Other/BLS_Wages/oe.area.txt`
   - Cost: Free
   - Citation: U.S. Bureau of Labor Statistics. Quarterly Census of Employment and Wages (QCEW). Bureau of Labor Statistics, various years. https://www.bls.gov/cew/

16. **U.S. Census Bureau - Business Formation Statistics**
   - Description: Business formation data by state
   - Access: Publicly available from the U.S. Census Bureau at https://www.census.gov/econ/bfs/
   - Data Files:
     - `raw/Other/BFS_Businesses.csv`
   - Cost: Free
   - Citation: U.S. Census Bureau. Business Formation Statistics (BFS). U.S. Census Bureau, various years. https://www.census.gov/econ/bfs/

17. **American Bar Association (ABA) Lawyer Statistics**
   - Description: Lawyer population by state
   - Access: Publicly available from the American Bar Association
     - https://www.americanbar.org/news/profile-legal-profession/demographics/
   - Data Files:
     - `raw/Other/ABA_Lawyers.csv`
   - Cost: Free
   - Citation: American Bar Association (ABA). Lawyer Population by State. American Bar Association, various years.

18. **Koijen and Yogo (2015) Data**
   - Description: Replication data from "The Cost of Financial Frictions for Life Insurers" (AER 2015)
   - Access: Available via the authors or AER data archive at https://doi.org/10.3886/E112888V1
   - Data Files:
     - `raw/KY/KY_AER_2015/112888-V1/20121036_Data/Stata/data/CombinedData.dta`
   - Cost: Free
   - Citation: Koijen, Ralph S.J., and Motohiro Yogo. Replication Data for "The Cost of Financial Frictions for Life Insurers". American Economic Association, 2015. https://doi.org/10.3886/E112888V1

19. **Chodorow-Reich, Ghent, and Haddad (2021) Data**
   - Description: Data shared from "Asset Insulators" (RFS 2021)
   - Access: Available via the authors or their replication data archive
   - Data Files:
     - `raw/ChodorowReich/forJohnnyTang.dta`
     - `raw/ChodorowReich/DefaultBonds.csv`
     - `raw/ChodorowReich/outliers.ado`
   - Cost: Free
   - Citation: Chodorow-Reich, Gabriel, Andra Ghent, and Valentin Haddad. "Asset Insulators." The Review of Financial Studies 34.3 (2021): 1509-1539.

20. **Egan, Ge, and Tang (2022) Data**
   - Description: Data shared from "Conflicting Interests and the Effect of Fiduciary Duty: Evidence from Variable Annuities" (RFS 2022)
   - Access: Available via the authors or their replication data archive
   - Data Files:
     - `raw/EGT/Life insurance commissions/COMMISSIONS_ordinary_life.csv`
     - `raw/EGT/Life insurance commissions/PREMIUMS_ordinary_life.csv`
     - `raw/EGT/Life insurance commissions/ISSUED_amount_ordinary_life.csv`
     - `raw/EGT/Life insurance commissions/year1premium_direct_ordinary_life.csv`
   - Cost: Free
   - Citation: Egan, Mark, Shan Ge, and Johnny Tang. "Conflicting Interests and the Effect of Fiduciary Duty: Evidence from Variable Annuities." The Review of Financial Studies 35.12 (2022): 5334-5386.

21. **NOLHGA (National Organization of Life and Health Insurance Guaranty Associations) Insolvency Data**
   - Description: Detailed insolvency records for life and health insurance companies
   - Access: Available from NOLHGA website
     - https://nolhga.com/the-guaranty-system/assessments-capacity/
   - Data Files:
     - `raw/NAIC/NOLHGA_Insolvencies.xlsx`
     - `raw/NAIC/NOLHGA_insolvdata21.xlsx`
   - Cost: Free
   - Citation: National Organization of Life and Health Insurance Guaranty Associations. Insurance Company Insolvency Data. NOLHGA, various years.

22. **Investment Advisers Association - Assets Under Management by State**
   - Description: Investment adviser assets under management aggregated by state
   - Access: Available from the Investment Advisers Association website
     - https://www.investmentadviser.org/wp-content/uploads/2025/01/Snapshot2025_State_by_State.pdf
   - Data Files:
     - `raw/Other/InvestmentAdvisersAssociation_AUM_ByState.csv`
   - Cost: Free
   - Citation: Investment Advisers Association. Assets Under Management by State. Investment Advisers Association, various years.

23. **Other Public Data Sources**
   - Description: Additional publicly available data from BTS, FASB, FRED, and election data repositories
   - Access: Publicly available from their respective sources
     - https://www.bts.gov/archive/publications/state_transportation_statistics/state_transportation_statistics_2010/table_04_21
     - https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/42MVDX
   - Data Files:
     - `raw/Other/BTS_Tourism.csv`
     - `raw/Other/FASB_Vega.csv`
     - `raw/Other/Votes/dataverse_files/1976-2020-president.csv`
   - Cost: Free
   - Citation: Public data releases from BTS, FASB, and election data repositories, various years.

### Simulated Data
- For the datasets not available for posting, we provide simulated versions of the dataset with the same column names. 
- Researchers wishing to replicate this study must obtain independent access to these proprietary data sources. 
- We cannot provide the data directly due to licensing restrictions.
- The outputs in the "output/" folders are obtained from running the analysis code on the simulated data.

### Data Preservation

**Preservation Period:** The data and code for this project will be preserved for a minimum of **five (5) years** following publication of the paper. The data are stored in multiple secure locations:

1. Encrypted cloud backup storage
2. This replication package (for publicly available and simulated data)

For proprietary data sources (S&P Global Market Intelligence, CompuLife, and A.M. Best), researchers must obtain independent access through the respective data providers. The author will maintain documentation of data access procedures and variable definitions for the full preservation period.

### Replication Support

**Affirmation of Support for Replication:** As per JPE Data and Code Availability Policy, I, Johnny Tang, commit to preserving the data and code for a period of no less than five (5) years following the publication of this paper and providing reasonable assistance to requests for clarification and replication.

Researchers seeking to replicate this study may contact me with questions or requests for assistance. I will make best efforts to help researchers obtain access to proprietary data sources and navigate the replication process.

## Computational Requirements

### Software Requirements

The following software is required to run the replication code:

- **R** (version 4.4.3 or higher)
  - The code was tested with R version 4.4.3 (2025-02-28) -- "Trophy Case"
  - Required packages: ggplot2, plyr, dplyr, tidyr, Hmisc, data.table, lubridate, lfe, sandwich, stargazer, zoo, plm, ggrepel, moments, stringr, tidyverse, reshape2, fixest, modelsummary, nleqslv, BB, RStata, R.utils, latex2exp, vtable
  - To install required packages, run:
    ```r
    install.packages(c("ggplot2", "plyr", "dplyr", "tidyr", "Hmisc", "data.table",
                       "lubridate", "lfe", "sandwich", "stargazer", "zoo", "plm",
                       "ggrepel", "moments", "stringr", "tidyverse", "reshape2",
                       "fixest", "modelsummary", "nleqslv", "BB", "RStata",
                       "R.utils", "latex2exp", "vtable"))
    ```

- **Python** (version 3.12.7 or higher)
  - The code was tested with Python 3.12.7
  - Required packages: listed in requirements.txt
      aext-assistant                    4.1.0
      aext-assistant-server             4.1.0
      aext-core                         4.1.0
      aext-core-server                  4.1.0
      aext-panels                       4.1.0
      aext-panels-server                4.1.0
      aext-project-filebrowser-server   4.1.0
      aext-share-notebook               4.1.0
      aext-share-notebook-server        4.1.0
      aext-shared                       4.1.0
      aext-toolbox                      4.1.0
      aiobotocore                       2.12.3
      aiohappyeyeballs                  2.4.0
      aiohttp                           3.10.5
      aioitertools                      0.7.1
      aiosignal                         1.2.0
      alabaster                         0.7.16
      alembic                           1.13.3
      altair                            5.0.1
      anaconda-anon-usage               0.4.4
      anaconda-catalogs                 0.2.0
      anaconda-cli-base                 0.5.2
      anaconda-client                   1.13.0
      anaconda-cloud-auth               0.7.2
      anaconda-navigator                2.6.3
      anaconda-project                  0.11.1
      annotated-types                   0.6.0
      anyio                             4.2.0
      appdirs                           1.4.4
      applaunchservices                 0.3.0
      appnope                           0.1.3
      appscript                         1.2.5
      archspec                          0.2.3
      argon2-cffi                       21.3.0
      argon2-cffi-bindings              21.2.0
      arrow                             1.2.3
      astroid                           2.14.2
      astropy                           6.1.3
      astropy-iers-data                 0.2024.9.2.0.33.23
      asttokens                         2.0.5
      async-lru                         2.0.4
      atomicwrites                      1.4.0
      attrs                             23.1.0
      autograd                          1.7.0
      autograd-gamma                    0.5.0
      Automat                           20.2.0
      autopep8                          2.0.4
      Babel                             2.11.0
      bcrypt                            3.2.0
      beautifulsoup4                    4.12.3
      binaryornot                       0.4.4
      binsreg                           2.1.7
      black                             24.8.0
      bleach                            4.1.0
      blinker                           1.6.2
      bokeh                             3.6.0
      boltons                           23.0.0
      botocore                          1.34.69
      Bottleneck                        1.3.7
      Brotli                            1.0.9
      cachetools                        5.3.3
      certifi                           2025.1.31
      cffi                              1.17.1
      chardet                           4.0.0
      charset-normalizer                3.3.2
      click                             8.1.7
      cloudpickle                       3.0.0
      colorama                          0.4.6
      colorcet                          3.1.0
      comm                              0.2.1
      conda                             24.11.3
      conda-build                       24.9.0
      conda-content-trust               0.2.0
      conda_index                       0.5.0
      conda-libmamba-solver             24.9.0
      conda-pack                        0.7.1
      conda-package-handling            2.3.0
      conda_package_streaming           0.10.0
      conda-repo-cli                    1.0.114
      conda-token                       0.5.0+1.g2209e04
      constantly                        23.10.4
      contourpy                         1.2.0
      cookiecutter                      2.6.0
      cryptography                      43.0.0
      cssselect                         1.2.0
      cycler                            0.11.0
      Cython                            3.0.12
      cytoolz                           0.12.2
      dask                              2024.8.2
      dask-expr                         1.1.13
      datashader                        0.16.3
      debugpy                           1.6.7
      decorator                         5.1.1
      defusedxml                        0.7.1
      diff-match-patch                  20200713
      dill                              0.3.8
      distributed                       2024.8.2
      distro                            1.9.0
      dmglib                            0.9.5
      docstring-to-markdown             0.11
      docutils                          0.18.1
      et-xmlfile                        1.1.0
      executing                         0.8.3
      fastjsonschema                    2.16.2
      filelock                          3.13.1
      flake8                            7.0.0
      Flask                             3.0.3
      fonttools                         4.51.0
      formulaic                         1.1.1
      fqdn                              1.5.1
      frozendict                        2.4.2
      frozenlist                        1.4.0
      fsspec                            2024.6.1
      gensim                            4.3.3
      gitdb                             4.0.7
      GitPython                         3.1.43
      greenlet                          3.0.1
      h11                               0.14.0
      h5py                              3.11.0
      HeapDict                          1.0.1
      holoviews                         1.19.1
      httpcore                          1.0.2
      httpx                             0.27.0
      hvplot                            0.11.0
      hyperlink                         21.0.0
      idna                              3.7
      imagecodecs                       2023.1.23
      imageio                           2.33.1
      imagesize                         1.4.1
      imbalanced-learn                  0.12.3
      importlib-metadata                7.0.1
      incremental                       22.10.0
      inflection                        0.5.1
      iniconfig                         1.1.1
      intake                            2.0.7
      interface-meta                    1.3.0
      intervaltree                      3.1.0
      ipykernel                         6.28.0
      ipython                           8.27.0
      ipython-genutils                  0.2.0
      ipywidgets                        7.8.1
      isoduration                       20.11.0
      isort                             5.13.2
      itemadapter                       0.3.0
      itemloaders                       1.1.0
      itsdangerous                      2.2.0
      jaraco.classes                    3.2.1
      jedi                              0.19.1
      jellyfish                         1.0.1
      Jinja2                            3.1.4
      jmespath                          1.0.1
      joblib                            1.4.2
      json5                             0.9.6
      jsonpatch                         1.33
      jsonpointer                       2.1
      jsonschema                        4.23.0
      jsonschema-specifications         2023.7.1
      jupyter                           1.0.0
      jupyter_client                    8.6.0
      jupyter-console                   6.6.3
      jupyter_core                      5.7.2
      jupyter-events                    0.10.0
      jupyter-lsp                       2.2.0
      jupyter_server                    2.14.1
      jupyter-server-mathjax            0.2.6
      jupyter_server_terminals          0.4.4
      jupyterlab                        4.2.5
      jupyterlab-pygments               0.1.2
      jupyterlab_server                 2.27.3
      jupyterlab-widgets                1.0.0
      keyring                           24.3.1
      kiwisolver                        1.4.4
      lazy_loader                       0.4
      lazy-object-proxy                 1.10.0
      lckr_jupyterlab_variableinspector 3.1.0
      libarchive-c                      5.1
      libmambapy                        1.5.8
      lifelines                         0.30.0
      linearmodels                      6.1
      linkify-it-py                     2.0.0
      llvmlite                          0.43.0
      lmdb                              1.4.1
      locket                            1.0.0
      lxml                              5.2.1
      lz4                               4.3.2
      Mako                              1.2.3
      Markdown                          3.4.1
      markdown-it-py                    2.2.0
      MarkupSafe                        2.1.3
      matplotlib                        3.9.2
      matplotlib-inline                 0.1.6
      mccabe                            0.7.0
      mdit-py-plugins                   0.3.0
      mdurl                             0.1.0
      menuinst                          2.1.2
      mistune                           2.0.4
      mizani                            0.13.3
      more-itertools                    10.3.0
      mpmath                            1.3.0
      msgpack                           1.0.3
      multidict                         6.0.4
      multipledispatch                  0.6.0
      mypy                              1.11.2
      mypy-extensions                   1.0.0
      navigator-updater                 0.5.1
      nb_conda_kernels                  2.5.2
      nbclient                          0.8.0
      nbconvert                         7.16.4
      nbdime                            4.0.2
      nbformat                          5.10.4
      nest-asyncio                      1.6.0
      networkx                          3.3
      nltk                              3.9.1
      notebook                          7.2.2
      notebook_shim                     0.2.3
      numba                             0.60.0
      numexpr                           2.8.7
      numpy                             1.26.4
      numpydoc                          1.7.0
      openpyxl                          3.1.5
      overrides                         7.4.0
      packaging                         24.1
      pandas                            2.2.2
      pandocfilters                     1.5.0
      panel                             1.5.2
      param                             2.1.1
      parsel                            1.8.1
      parso                             0.8.3
      partd                             1.4.1
      pathspec                          0.10.3
      patsy                             0.5.6
      pexpect                           4.8.0
      pickleshare                       0.7.5
      pillow                            10.4.0
      pip                               24.2
      pkce                              1.0.3
      pkginfo                           1.10.0
      platformdirs                      3.10.0
      plotly                            5.24.1
      plotnine                          0.14.5
      pluggy                            1.0.0
      ply                               3.11
      prometheus-client                 0.14.1
      prompt-toolkit                    3.0.43
      Protego                           0.1.16
      protobuf                          4.25.3
      psutil                            5.9.0
      ptyprocess                        0.7.0
      pure-eval                         0.2.2
      py-cpuinfo                        9.0.0
      pyarrow                           16.1.0
      pyasn1                            0.4.8
      pyasn1-modules                    0.2.8
      pycodestyle                       2.11.1
      pycosat                           0.6.6
      pycparser                         2.21
      pyct                              0.5.0
      pycurl                            7.45.3
      pydantic                          2.8.2
      pydantic_core                     2.20.1
      pydantic-settings                 2.6.1
      pydeck                            0.8.0
      PyDispatcher                      2.0.5
      pydocstyle                        6.3.0
      pyerfa                            2.0.1.4
      pyflakes                          3.2.0
      Pygments                          2.15.1
      pyhdfe                            0.2.0
      PyJWT                             2.8.0
      pylint                            2.16.2
      pylint-venv                       3.0.3
      pyls-spyder                       0.4.0
      pyobjc-core                       10.1
      pyobjc-framework-Cocoa            10.1
      pyobjc-framework-CoreServices     10.1
      pyobjc-framework-FSEvents         10.1
      pyodbc                            5.1.0
      pyOpenSSL                         24.2.1
      pyparsing                         3.1.2
      PyQt5                             5.15.10
      PyQt5-sip                         12.13.0
      PyQtWebEngine                     5.15.6
      PySocks                           1.7.1
      pytest                            7.4.4
      python-dateutil                   2.9.0.post0
      python-dotenv                     0.21.0
      python-json-logger                2.0.7
      python-lsp-black                  2.0.0
      python-lsp-jsonrpc                1.1.2
      python-lsp-server                 1.10.0
      python-slugify                    5.0.2
      pytoolconfig                      1.2.6
      pytz                              2024.1
      pyviz_comms                       3.0.2
      PyWavelets                        1.7.0
      PyYAML                            6.0.1
      pyzmq                             25.1.2
      QDarkStyle                        3.2.3
      qstylizer                         0.2.2
      QtAwesome                         1.3.1
      qtconsole                         5.5.1
      QtPy                              2.4.1
      queuelib                          1.6.2
      readchar                          4.0.5
      referencing                       0.30.2
      regex                             2024.9.11
      requests                          2.32.3
      requests-file                     1.5.1
      requests-toolbelt                 1.0.0
      rfc3339-validator                 0.1.4
      rfc3986-validator                 0.1.1
      rich                              13.7.1
      rope                              1.12.0
      rpds-py                           0.10.6
      Rtree                             1.0.1
      ruamel.yaml                       0.18.6
      ruamel.yaml.clib                  0.2.8
      ruamel-yaml-conda                 0.17.21
      s3fs                              2024.6.1
      scikit-image                      0.24.0
      scikit-learn                      1.5.1
      scipy                             1.13.1
      Scrapy                            2.11.1
      seaborn                           0.13.2
      semver                            3.0.2
      Send2Trash                        1.8.2
      sentry-sdk                        2.18.0
      service-identity                  18.1.0
      setuptools                        75.1.0
      setuptools-scm                    8.3.1
      shellingham                       1.5.0
      sip                               6.7.12
      six                               1.16.0
      smart-open                        5.2.1
      smmap                             4.0.0
      sniffio                           1.3.0
      snowballstemmer                   2.2.0
      sortedcontainers                  2.4.0
      soupsieve                         2.5
      Sphinx                            7.3.7
      sphinxcontrib-applehelp           1.0.2
      sphinxcontrib-devhelp             1.0.2
      sphinxcontrib-htmlhelp            2.0.0
      sphinxcontrib-jsmath              1.0.1
      sphinxcontrib-qthelp              1.0.3
      sphinxcontrib-serializinghtml     1.1.10
      spyder                            5.5.1
      spyder-kernels                    2.5.0
      SQLAlchemy                        2.0.34
      stack-data                        0.2.0
      stargazer                         0.0.7
      statsmodels                       0.14.2
      streamlit                         1.37.1
      sympy                             1.13.2
      tables                            3.10.1
      tabulate                          0.9.0
      tblib                             1.7.0
      tenacity                          8.2.3
      terminado                         0.17.1
      text-unidecode                    1.3
      textdistance                      4.2.1
      threadpoolctl                     3.5.0
      three-merge                       0.1.1
      tifffile                          2023.4.12
      tinycss2                          1.2.1
      tldextract                        5.1.2
      toml                              0.10.2
      tomli                             2.0.1
      tomlkit                           0.11.1
      toolz                             0.12.0
      tornado                           6.4.1
      tqdm                              4.66.5
      traitlets                         5.14.3
      truststore                        0.8.0
      Twisted                           23.10.0
      typer                             0.9.0
      typing_extensions                 4.11.0
      tzdata                            2023.3
      uc-micro-py                       1.0.1
      ujson                             5.10.0
      unicodedata2                      15.1.0
      Unidecode                         1.3.8
      uri-template                      1.3.0
      urllib3                           2.2.3
      w3lib                             2.1.2
      watchdog                          4.0.1
      wcwidth                           0.2.5
      webcolors                         24.11.1
      webencodings                      0.5.1
      websocket-client                  1.8.0
      Werkzeug                          3.0.3
      whatthepatch                      1.0.2
      wheel                             0.44.0
      widgetsnbextension                3.6.6
      wrapt                             1.14.1
      wurlitzer                         3.0.2
      xarray                            2023.6.0
      xlwings                           0.32.1
      xyzservices                       2022.9.0
      yapf                              0.40.2
      yarl                              1.11.0
      yt-dlp                            2025.9.5
      zict                              3.0.0
      zipp                              3.17.0
      zope.interface                    5.4.0
      zstandard                         0.23.0
  
- **Stata** (Stata/MP 17 or higher)
  - Packages: reghdfe, psacalc, outreg2, ftools, reghdfe, ivreg2, ivreghdfe
  - The code was tested with Stata/MP 17
  - Custom ado files are included in `lib/ado/`
  - Update Stata path necessary (default path: `/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp` for macOS)

### Hardware Requirements

The analysis was performed on the following system:

- **Operating System**: macOS 15.6.1 (Darwin 24.6.0)
- **Processor**: Apple M3 (MacBook Air, Model Mac16,13)
- **Memory**: 16GB RAM (minimum recommended)
- **Storage**: 200GB
- **Estimated computation time**: Approximately 168 hours on the system described above.

**Note**: Computation time may vary significantly depending on hardware specifications. The structural estimation analysis is computationally intensive and requires substantial memory.

## Description of Programs/Code

The replication package contains code files organized into three main directories: `CleanData/`, `Analysis_Demand/`, and `Analysis_Insurer/`. Each directory contains a master script (`make.R`) that runs all analysis scripts in the correct order.

### CleanData

**Master Script:**
- `make.R` - Runs all data cleaning scripts in sequence to produce the cleaned datasets used in analysis

**Data Cleaning Scripts:**
1. `RegulatoryCompetition_CleanData_00_AMBest.R`
   - Outputs default probability tables

2. `RegulatoryCompetition_CleanData_01_III.R`
   - Cleans Insurance Information Institute (III) captives and premium data
   - Produces state-year captives and DPW panel

3. `RegulatoryCompetition_CleanData_02_SNL.R`
   - Cleans S&P Global Market Intelligence (SNL) raw files across financials, market share, reinsurance, and related modules
   - Outputs standardized SNL datasets used throughout the project

4. `RegulatoryCompetition_CleanData_03_CompuLife.R`
   - Computes actuarial values (Lombardi + Treasury yields)
   - Cleans CompuLife and WebAnnuities pricing data and constructs price/instrument datasets
   - Processes pre-2005 CompuLife files

5. `RegulatoryCompetition_CleanData_04_Other.R`
   - Cleans and constructs supplemental covariates (population, lawyers, amenities, disclosure, NAIC IDRR, business formation, 10-K subsidiaries, political variables, and related state-level measures)

6. `RegulatoryCompetition_CleanData_05_Consumers_MergeAll.R`
   - Merges cleaned SNL, CompuLife, AM Best, reinsurance, and other datasets
   - Produces final panel datasets used in demand and insurer analysis

### Analysis_Demand

**Master Script:**
- `make.R` - Runs all demand analysis scripts in sequence

**Analysis Scripts:**
1. `RegulatoryCompetition_Analysis_Demand_01_CreateData.R`
   - Loads and cleans demand data for analysis
   - Calculates market shares and standardizes characteristics

2. `RegulatoryCompetition_Analysis_Demand_02_Analysis.R`
   - Estimates demand elasticities using instrumental variables
   - Tests for price variation across states
   - Generates estimation tables and elasticity distributions

### Analysis_Insurer

**Master Script:**
- `make.R` - Runs all insurer analysis scripts in sequence, including multiple robustness cases

**Analysis Scripts:**

1. `RegulatoryCompetition_Analysis_Insurer_01_CapitalAllocation_CreateData.R`
   - Merges reinsurance data with insurer financials and state regulatory data
   - Creates datasets at multiple aggregation levels

2. `RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
   - Estimates reduced-form relationships between captive usage and state capital requirements
   - Analyzes state entry and time trends

3. `RegulatoryCompetition_Analysis_Insurer_03b_ReducedForm_OsterTest.do` (Stata)
   - Implements omitted variable bias test
   - Tests sensitivity of results to unobserved confounders

4. `RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R`
   - Estimates capital allocation model
   - Calibrates structural primitives
   - Solves for equilibrium allocations under actual and counterfactual policies

5. `RegulatoryCompetition_Analysis_Insurer_05_Regulator_Functions.R`
   - Defines welfare comparison functions

6. `RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
   - Solves for optimal capital requirements
   - Computes welfare impacts of policy perturbations
   - Estimates regulator objective function weights
   - Evaluates counterfactual policies

7. `RegulatoryCompetition_Analysis_Insurer_09_SummaryStatistics.R`
   - Generates summary statistics for key variables
   - Creates descriptive figures

8. `RegulatoryCompetition_Analysis_Insurer_10_Solve_All_Cases.R`
   - Master script that runs analysis for multiple robustness cases

9. `RegulatoryCompetition_Analysis_Insurer_50_ReducedForm_DefaultBonds.do` (Stata)
   - Analyzes relationship between bond returns and default probabilities

10. `RegulatoryCompetition_Analysis_Insurer_51_ReducedForm_Price.R`
    - Analyzes price changes following regulatory change
    - Estimates cost of capital parameter
    - Validates structural model predictions

11. `RegulatoryCompetition_Analysis_Insurer_99_JPE.py` (Python)
    - Generates additional figures and tables
    - Produces master table of results

**Utility Scripts:**
- `stargazer_tex.R` - Custom functions for formatting stargazer LaTeX output

### Supporting Libraries

The `lib/` directory contains shared utility functions:
- `lib/r/Functions.R` - R helper functions used across all scripts
- `lib/ado/` - Custom Stata ado files
- `lib/python/` - Python utility functions
- `lib/stata/` - Stata utility functions

## Instructions for Replication

### Setup

1. Download and extract the complete replication package
2. Install all required software (R, Python, Stata) with versions specified above
3. Install all required R packages using the command provided in the Software Requirements section
4. Install all required Python packages using pip
5. Change the working directories in all the scripts to the root of this folder
6. If using Stata on a non-macOS system or different installation location, update the Stata paths
7. Obtain all data sources listed in the Data Availability Statement
8. Place raw data files in a `raw/` folder at the same level as this replication package
9. Update file paths in the scripts if your data is organized differently than what is provided.

### Running the Analysis

To replicate all results in the paper, run the following scripts **in order**:
1. `Rscript CleanData/make.R`
2. `Rscript Analysis_Demand/make.R`
3. `Rscript Analysis_Insurer/make.R`
4. Run in Stata: RegulatoryCompetition_Analysis_Insurer_50_ReducedForm_DefaultBonds.do
   - Note: RegulatoryCompetition_Analysis_Insurer_03b_ReducedForm_OsterTest.do is run automatically in Analysis_Insurer/make.R.
5. Run in Python: RegulatoryCompetition_Analysis_Insurer_99_JPE.py

**Expected Runtime:**
- 168 hours (includes all robustness cases)
- Note:
   - To only run the reduced form analyses, run `Rscript Analysis_Demand/make.R` in full and run lines 1-22 in `Rscript Analysis_Insurer/make.R`, i.e., do not run "6. Solve All Cases". This will take approximately 1 hour.
   - To only run the baseline structural analyses, uncomment line 26 in `Rscript Analysis_Insurer/make.R`. This will take approximately 48 hours.

## List of Tables and Programs

This section maps each table and figure in the paper to the specific program that generates it.

### Tables

**Table 1: Summary Statistics**
- **Panel A (Insurer Financials):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_09_SummaryStatistics.R`
  - Output: `Analysis_Insurer/output/summary_stats/summary_stats_financials_baseline.tex`

- **Panel B (Demand - Insurer-State-Year):**
  - Program: `Analysis_Demand/code/RegulatoryCompetition_Analysis_Demand_02_Analysis.R`
  - Output: `Analysis_Insurer/output/summary_stats/summary_stats_demand_insurerstateyear_baseline.tex`

**Table 2: Reduced-Form Captive Choice Regressions**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
- Output: `Analysis_Insurer/output/ReducedForm/reg_has_captives_all_leaveoneout_insureryr_uses_captives.tex`

**Table 3: Capital Allocation and State Characteristics**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R`
- Output: `Analysis_Insurer/output/reg_ln_b_ln_0_kappa_chars_baseline.tex`

**Table 4: Mechanisms - Direct Written Premiums**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
- Output: `Analysis_Insurer/output/ReducedForm/reg_mechanisms_dpw.tex`

**Table 5: Demand Estimation**
- Program: `Analysis_Demand/code/RegulatoryCompetition_Analysis_Demand_02_Analysis.R`
- Output: `Analysis_Demand/output/regs_demand_hausman.tex`

**Table 6: Regulator Objective Function**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
- Output: `Analysis_Insurer/output/Regulator/reg_lambdas_baseline.tex`

**Table 7: Counterfactual Results Master Table**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_99_JPE.py`
- Output: `Analysis_Insurer/output/Regulator/results_mastertable.tex`

### Figures

**Figure 1: Institutional Setting - Captive Insurance Structure**
- Source: Author-created diagram (not generated by code)
- Location: `raw/InstitutionalSetting/InstitutionalSetting_Captives_Full_Final.jpg`

**Figure 2: Captive Market Growth**
- **Panel A (State Entry Timeline):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
  - Output: `Analysis_Insurer/output/ReducedForm/state_entry_ts.png`

- **Panel B (Captive Market Share):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_99_JPE.py`
  - Output: `Analysis_Insurer/output/summary_stats/captive_share_ts.png`

**Figure 3: Market Trends**
- **Panel A (Number of Insurers):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
  - Output: `Analysis_Insurer/output/ReducedForm/ts_yearly_num_insurers.png`

- **Panel B (Capital Requirements):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_03_CapitalAllocation_ReducedForm.R`
  - Output: `Analysis_Insurer/output/ReducedForm/ts_capital_captives_rbc.png`

**Figure 4: Price Changes Following Regulation XXX**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_51_ReducedForm_Price.R`
- Output: `Analysis_Insurer/output/ProductPrice/coef_pricing_markup_plot.png`

**Figure 5: Distribution of Structural Primitives**
- **Panel A (Product Quality):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R`
  - Output: `Analysis_Insurer/output/Pricing/primitives_summarystats_hist_mu.png`

- **Panel B (Default Risk):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_04_CapitalAllocation.R`
  - Output: `Analysis_Insurer/output/Pricing/primitives_summarystats_hist_sigma.png`

**Figure 6: Welfare Trade-offs - Default Risk vs Consumer Surplus**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
- Output: `Analysis_Insurer/output/Regulator/utility_univariate_default_and_consumer_capreq_baseline.png`

**Figure 7: Optimal Capital Requirements**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
- Output: `Analysis_Insurer/output/Regulator/utility_univariate_regutil_totalsurplus_capreq_5_baseline.png`

**Figure 8: State Preference Heterogeneity**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
- Output: `Analysis_Insurer/output/Regulator/utility_plot_animated_4_baseline.png`

**Figure 9: Federal Harmonization Impact**
- Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
- Output: `Analysis_Insurer/output/Regulator/stateyr_federal_change_baseline.png`

**Figure 10: Ban Counterfactuals**
- **Panel A (Default Costs):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
  - Output: `Analysis_Insurer/output/Regulator/utility_compare_bans_default_baseline.png`

- **Panel B (Consumer Surplus):**
  - Program: `Analysis_Insurer/code/RegulatoryCompetition_Analysis_Insurer_06_Regulator_Solve.R`
  - Output: `Analysis_Insurer/output/Regulator/utility_compare_bans_surplus_baseline.png`

## Statement About Rights

- I certify that the author of the manuscript has legitimate access to and permission to use the data used in this manuscript.

## Data Citations

1. S&P Global Market Intelligence. *Insurance Statutory Financials and Market Share Data*. S&P Global, 2005-2019. Dataset.

2. CompuLife Software Inc. *CompuLife Insurance Pricing Database*. CompuLife Software Inc., 1990-2021. Dataset.

3. A.M. Best Company. *Insurance Company Credit Ratings and Financial Strength Data*. A.M. Best Company, 2005-2019. Dataset.

4. U.S. Securities and Exchange Commission. *EDGAR Database*. 2005-2019, https://www.sec.gov/edgar. Accessed 28 Dec. 2025.

5. State Departments of Insurance. *Captive Insurance Regulations and Statutes*. Various state insurance departments, various years. Regulatory documents.

6. National Association of Insurance Commissioners. *Insurance Regulatory Information System and Insolvency Data*. NAIC, 1989-2019. Dataset.

7. Bonica, Adam. *Database on Ideology, Money in Politics, and Elections*. Version 2.0, Stanford University, 2016, https://data.stanford.edu/dime. Accessed 28 Dec. 2025.

8. Federal Reserve Bank of St. Louis. *Federal Reserve Economic Data*. 2005-2019, https://fred.stlouisfed.org. Accessed 28 Dec. 2025.

9. Lombardi, Louis J. *Valuation of Life Insurance Liabilities: Establishing Reserves for Life Insurance Policies and Annuity Contracts*. Actex Publications, 2006.

10. Insurance Information Institute (III). *Captive Insurance Statistics and Direct Written Premium Data*. Insurance Information Institute, various years. Dataset.

11. Society of Actuaries (SOA). *Regulation XXX Quantity Data*. Society of Actuaries, various years. Dataset.

12. Google Trends. *Search Interest Data for Insurance-Related Terms*. Google Inc., various years, https://trends.google.com. Accessed 28 Dec. 2025.

13. Wharton Research Data Services (WRDS). *SEC 10-K Subsidiary Data*. Wharton School, University of Pennsylvania, various years. Dataset.

14. Annuity Shopper. *Annuity Product Pricing and Features*. Annuity Shopper Magazine, 2014-2018. Dataset.

15. U.S. Bureau of Labor Statistics. *Quarterly Census of Employment and Wages (QCEW)*. Bureau of Labor Statistics, various years, https://www.bls.gov/cew/. Accessed 28 Dec. 2025.

16. U.S. Census Bureau. *Business Formation Statistics (BFS)*. U.S. Census Bureau, various years, https://www.census.gov/econ/bfs/. Accessed 28 Dec. 2025.

17. American Bar Association (ABA). *Lawyer Population by State*. American Bar Association, various years. Dataset.

18. Koijen, Ralph S.J., and Motohiro Yogo. *Data*. Shared research data from "The Cost of Financial Frictions for Life Insurers," American Economic Association, 2015, https://doi.org/10.3886/E112888V1.

19. Chodorow-Reich, Gabriel, Andra Ghent, and Valentin Haddad. *Data*. Shared research data from "Asset Insulators," The Review of Financial Studies 34.3 (2021): 1509-1539. Dataset.

20. Egan, Mark, Shan Ge, and Johnny Tang. *Data*. Shared research data from "Conflicting Interests and the Effect of Fiduciary Duty: Evidence from Variable Annuities," The Review of Financial Studies 35.12 (2022): 5334-5386. Dataset.

21. National Organization of Life and Health Insurance Guaranty Associations. *Insurance Company Insolvency Data*. NOLHGA, various years. Dataset.

22. Investment Advisers Association. *Assets Under Management by State*. Investment Advisers Association, various years. Dataset.

## License

This replication package is licensed under the MIT License.

## Contact Information

**Corresponding Author:**
- Name: Johnny Tang
- Email: johnnytang857@gmail.com

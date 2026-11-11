Insurer Mortality Replication Files
-----------------------------------

Replication code for "Mortality Effects and Choice Across Private Health
Insurance Plans" by Abaluck, Caceres-Bravo, Hull, and Starc

Please contact Mauricio Caceres-Bravo (mauricio.caceres.bravo@gmail.com) with questions

### Requirements

The following software is required:

- SAS (run on version 9.4)
- Stata (run on version 16.1)
    - Install the dependencies via `do 00common/InstallRequirements.do`

In addition, the following data is required:

- Access to NBER's raw CMS data in `/disk/aging/medicare/data`.

- SSA life tables (downloaded via `00download/LifeTables.py`).
- CMS Landscape Files (downloaded via `00download/LandscapeFiles.do`).
- Plan Risk Scores (downloaded via `00download/PlanData.do`).
- MLR (downloaded via `00download/MLR.do`).

- Plan relationship codes (save in `${data}/planTerm.dta`): From CMS' Plan Characteristics File (also known as Part D Plan Characteristics). We obtain each plan's relationship code (New, Renewal, Consolidation, Termination, Split) from 2006 to 2011.
- Plan star ratings (save in `${data}/star-ratings/star_ratings_2008_2011.dta`): [From CMS](https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovGenIn/PerformanceData). A summary star measure is not available for 2008 so we follow the process described in the 2011 Part C Plan Ratings Technical Notes to calculate a summary score for 2008.
- ACS 2011-2015 5-year estimates (save in `${data}/ACS_tab.txt` and `${data}/ACS_tab.dct`): Downloaded from [Social Explorer](https://www.socialexplorer.com/tables/ACS2015_5yr/R12518954).

- Broad plan types (derived by the authors; see `00common/00plan-types.txt`)
- State SSA code to name and abbreviation crosswalk (provided in `00common/00ssa-codes.txt`)
- Company name crosswalk (provided in `00common/MLR and LS payers.xlsx`)

### Data and Output

The data folder is defined in two places

1. `00common/00preamble.do`: Change the `data` global.
2. `01get/main.sas`: Change the `datadir` macro or `data` library.

The output folder is defined only in `00common/00preamble.do`: Change
the `out` global.  All the queried data will be saved to `${data}`. All
the (non-data) output files will be saved to `${out}`.

### Compiling

1. Make auxilary files

    ```
    make 00download &
    make 00auxfiles &
    ```

2. Run SAS query; run from `agesas#.nber.org`

    ```
    make 01get &
    ```

3. Query cleanup; run from `age#.nber.org`

    ```
    make 02clean &
    make 03ivSample &
    make 99post_shrinkage                 \
        ARGS="runReg"                     \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regsNoDemo"    &
    ```

    **_Note_**: To compute the MA flag used in our sample restrictions we
    impute missing plan characteristings with the characteristics of an
    arbitrary plan in the same county and contract. This imputation is
    based on a non-deterministic sort and the true MA flag might change
    slightly if the code is recompiled. This will mean replicated sample
    size and point estimates will generally differ slightly from those
    in the published paper. 

4. Main paper results. First, run the following (for faster results, run
   concurrently across different servers):

    ```
    bash 04analysisWrapper.sh --run_Reg            & # Table III
    bash 04analysisWrapper.sh --run_Reg_noDemo     & # Table III
    bash 04analysisWrapper.sh --runFallback        & # Table II
    bash 04analysisWrapper.sh --runBalance         & # Table II
    bash 04analysisWrapper.sh --runBalance_lagmort & # Table II
    bash 04analysisWrapper.sh --runPlanCharReg_IV  & # Table IV
    bash 04analysisWrapper.sh --runPlanCharReg_OLS & # Table IV
    bash 04analysisWrapper.sh --runXi              & # Table V

    bash 04analysisWrapper.sh --runPlots_diff_normalized & # Figures II and III
    bash 04analysisWrapper.sh --runPlots_balance         & # Figure IV
    ```

    **_Note_**: If you make changes to the data processing in `04analysis`
    then be sure to re-run with the `--no-cached` option to force the
    scripts to re-compile the data.

    a. To make the tables:

        - Table I: `make table1 PCT="100" PRE="_19" &`

        - Table II: `make table2 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table III: `make table3 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table IV: `make table4 PCT="100" OPTS_FOLDER="PlanCharsRegressions" &`

        - Table V: `make table5 PCT="100" OPTS_FOLDER="PlanCharsRegressions" &`

    b. To make the figures:

        - Figure I: `make figure1 PCT="100" PRE="_19" &`

        - Figure II & III: Saved in `${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_mimic_IV_normalized`

        - Figure IV: Saved in `${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance`

5. Appendix results. This assumes you have finished compiling the
   main results. First, run the following (for faster results, run
   concurrently across different servers):

    ```
    bash 04analysisWrapper.sh --runRobust_countyTerm     & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_noTM           & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_PFFS           & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_noPFFS         & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_noDuals        & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_ageEffect      & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_riskScore      & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_unshrunk       & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_excl_small_bin & # Table A.VI
    bash 04analysisWrapper.sh --runRobust_twoYearMort    & # Table A.VI

    bash 04analysisWrapper.sh --regs_eta_ind          & # Table A.V
    bash 04analysisWrapper.sh --runCountyChars        & # Table A.I
    bash 04analysisWrapper.sh --runSwitchingBehavior  & # Table A.II
    bash 04analysisWrapper.sh --runPredictedMortality & # Table A.III
    bash 04analysisWrapper.sh --simulations           & # Tables A.VIII and A.IX

    bash 04analysisWrapper.sh --runPlots_map               & # Figure A.I
    bash 04analysisWrapper.sh --runPlots_balance_riskscore & # Figure A.III
    bash 04analysisWrapper.sh --runPlots_balance_age       & # Figure A.III
    bash 04analysisWrapper.sh --runPlots_FSRF_viv          & # Figure A.IV
    ```

    a. To make the tables:

        - Table A.I: Saved in `${out}/tables`

        - Table A.II: Saved in `${out}/tables`

        - Table A.III: `make tableA3 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table A.IV: `make tableA4 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table A.V: `make osterOVB PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table A.VI: `make tableA6 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &`

        - Table A.VII: `make tableA7 PCT="100" OPTS_FOLDER="PlanCharsRegressions" &`

        - Table A.VIII and A.IX: Output saved in `${out}/tables/_19tables100pct.txt`. You can fill in the table templates in `./05output/paper` using `tablefill` (example code in `99adHoc/ReplicationCopyOutput.do`). If you are not familiar with this program, note that the output should contain two sets of results (two matrices): one for each table, with the numbers matching those in the paper.

    b. To make the figures:

        - Figure A.I: Saved in `${out}/fig`

        - Figure A.II: `make figureA2 PCT="100" PRE="_19" &`

        - Figure A.III: Saved in

            ```
            ${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance_riskscore
            ${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_balance_age
            ```

        - Figure A.IV: Saved in `${out}/fig/BaselineStuff-take-4/BaselineStuff_plots_FSRF_viv`

        - Figure A.V: `make figureA5 PCT="100" PRE="_19" &`

6. To gather the output we provide a helper script: `stata do 99adHoc/ReplicationCopyOutput.do`.

    The requisite files will be copied to `99adHoc/Graphics` and `99adHoc/Tables`. A `.tex` file that puts all of these together in a single pdf is in `99adHoc/Replication.tex` (to get it to run, you must first make a `.png` version of each `.svg` figure; example code is in `99adHoc/Replication.sh`).

### File structure

Source code is in this folder:

- `00download`, `00auxfiles`: Download raw data and format helper files.
- `01get`, `02clean`, `03ivSample`: CMS data query and cleanup.
- `04analysis`, `98adHoc`: Main results.
- `05output`: Compile main results into tables.
- `06simulations`: Simulations in the Appendix.
- `99adHoc`: Ad-hoc data cleaning and derivations.

#!/usr/bin/env bash

nocached=

# Requirements
# ---------------------------------------------------------------------
# All folders 00 through 03 have been compiled (see README.md)

# How-To
# ---------------------------------------------------------------------
# Pass the analyses you want to run as arguments to this function. To
# limit run-time, run one command in each server.

while test $# -gt 0
do
    case "$1" in

        # Main Regressions w/ Demographic-Level Controls
        --no-cached) nocached=nocached
            ;;

        # MAIN TEXT
        # ---------

        # Main Regressions w/ Demographic-Level Controls
        --run_Reg) run_Reg=true
            ;;
        # Main Regressions w/o Demographic-Level Controls
        --run_Reg_noDemo) run_Reg_noDemo=true
            ;;
        # IV Plan Characteristic Regressions
        --runPlanCharReg_IV) runPlanCharReg_IV=true
            ;;
        # OLS Plan Characteristic Regressions
        --runPlanCharReg_OLS) runPlanCharReg_OLS=true
            ;;
        # Balance Tests, normal
        --runBalance) runBalance=true
            ;;
        # Balance Tests, Lag Mortality
        --runBalance_lagmort) runBalance_lagmort=true
            ;;
        # Fallback Test
        --runFallback) runFallback=true
            ;;
        # Xi Regression/WTP
        --runXi) runXi=true
            ;;
        # Balance plots
        --runPlots_balance) runPlots_balance=true
            ;;
        # Difference-in-Difference Style Plots (mimic IV)
        --runPlots_diff_normalized) runPlots_diff_normalized=true
            ;;

        # Appendices
        # ----------

        # County Characteristics
        --runCountyChars) runCountyChars=true
            ;;
        # Switching Behavior
        --runSwitchingBehavior) runSwitchingBehavior=true
            ;;
        # Predicted Mortality Model
        --runPredictedMortality) runPredictedMortality=true
            ;;
        # Forecast coefficient sensitivity
        --regs_eta_ind) regs_eta_ind=true
            ;;
        # Simulations
        --simulations) simulations=true
            ;;
        # Geographic distribution of terminations
        --runPlots_map) runPlots_map=true
            ;;
        # Balance on plan risk scores
        --runPlots_balance_riskscore) runPlots_balance_riskscore=true
            ;;
        # Balance on beneficiary age
        --runPlots_balance_age) runPlots_balance_age=true
            ;;
        # Forecast Regression FS and RF estimates
        --runPlots_FSRF_viv) runPlots_FSRF_viv=true
            ;;

        # Appendix Table VI
        # -----------------

        # Robustness Check - Regressions only in Counties with Terminations
        --runRobust_countyTerm) runRobust_countyTerm=true
            ;;
        # Robustness Check - Regressions exluding those who switch out of true MA
        --runRobust_noTM) runRobust_noTM=true
            ;;
        # Robustness Check - Regressions only among PPFS plans
        --runRobust_PFFS) runRobust_PFFS=true
            ;;
        # Robustness Check - Regressions only among non-PPFS plans
        --runRobust_noPFFS) runRobust_noPFFS=true
            ;;
        # Robustness Check - Regressions excluding duals
        --runRobust_noDuals) runRobust_noDuals=true
            ;;
        # Robustness Check - Regressions with mus by age
        --runRobust_ageEffect) runRobust_ageEffect=true
            ;;
        # Robustness Check - Regressions with risk score
        --runRobust_riskScore) runRobust_riskScore=true
            ;;
        # Robustness Check - Regressions with unshrunk effects
        --runRobust_unshrunk) runRobust_unshrunk=true
            ;;
        # Robustness Check - Regressions without the smallest bin
        --runRobust_excl_small_bin) runRobust_excl_small_bin=true
            ;;
        # Robustness Check - Regressions with two-year mortality as outcome
        --runRobust_twoYearMort) runRobust_twoYearMort=true
            ;;

    esac
    shift
done

# Output
# ---------------------------------------------------------------------
# The name of leach log file has the structure
#
#     04ivReg${SampleSelection}${optsFolder}_${tag}
#
# Each each regression is also saved as an .ster file.  The coefficients
# can be compiled into excep tables using helper scripts in `05output`.

# Main Text
# ---------------------------------------------------------------------

if [ "$run_Reg" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"         \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs"          &
fi

if [ "$run_Reg_noDemo" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"         \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regsNoDemo"    &
fi

if [ "$runPlanCharReg_IV" = true ]; then
    make 04analysis                          \
        ARGS="runPlanCharReg_IV ${nocached}" \
        SAMPLE="SampleSelection2"           \
        OPTS_FOLDER="PlanCharsRegressions"  \
        TAG="PlanCharsRegressionsV4_iv" &
fi

if [ "$runPlanCharReg_OLS" = true ]; then
    make 04analysis                           \
        ARGS="runPlanCharReg_OLS ${nocached}" \
        SAMPLE="SampleSelection2"             \
        OPTS_FOLDER="PlanCharsRegressions"    \
        TAG="PlanCharsRegressionsV4_ols" &
fi

if [ "$runBalance" = true ]; then
    make 04analysis                       \
        ARGS="runBalance ${nocached}"     \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_balanceTests"  &
fi

if [ "$runBalance_lagmort" = true ]; then
    make 04analysis                       \
        ARGS="runBalance ${nocached}"                 \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_balanceTestLagMortality" &
fi

if [ "$runFallback" = true ]; then
    make 04analysis                       \
        ARGS="runFallback ${nocached}"                \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_fallBackBalanceTest" &
fi

if [ "$runXi" = true ]; then
    make 04analysis                        \
        ARGS="runXi ${nocached}"                       \
        SAMPLE="SampleSelection2"          \
        OPTS_FOLDER="PlanCharsRegressions" \
        TAG="XiRegressions" &
fi

if [ "$runPlots_balance" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_balance ${nocached}"           \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_balance" &
fi

if [ "$runPlots_diff_normalized" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_diff_normalized ${nocached}"   \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_mimic_IV_normalized" &
fi

# Appendices
# ---------------------------------------------------------------------

if [ "$runPlots_map" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_map ${nocached}"               \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_map" &
fi

if [ "$runPlots_balance_riskscore" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_balance_riskscore ${nocached}" \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_balance_riskscore" &
fi

if [ "$runPlots_balance_age" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_balance_age ${nocached}"       \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_balance_age" &
fi

if [ "$runPlots_FSRF_viv" = true ]; then
    make 04analysis                       \
        ARGS="runPlots_FSRF_viv ${nocached}"       \
        SAMPLE="SampleSelection2"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_plots_FSRF_viv" &
fi

if [ "$runCountyChars" = true ]; then
    make 04analysis                         \
        ARGS="runCountyChars ${nocached}"               \
        SAMPLE="SampleSelection6"           \
        OPTS_FOLDER="BaselineStuff-take4"   \
        TAG="BaselineStuff_countyChars" &
fi

if [ "$runSwitchingBehavior" = true ]; then
    make 04analysis                         \
        ARGS="runSwitchingBehavior ${nocached}"         \
        SAMPLE="SampleSelection6"           \
        OPTS_FOLDER="BaselineStuff-take4"   \
        TAG="BaselineStuff_switchingBehavior" &
fi

if [ "$runPredictedMortality" = true ]; then
    make 04analysis                         \
        ARGS="runPredictedMortality ${nocached}"        \
        SAMPLE="SampleSelection6"           \
        OPTS_FOLDER="BaselineStuff-take4"   \
        TAG="BaselineStuff_regs" &
fi

if [ "$regs_eta_ind" = true ]; then
    make 04analysis                         \
        ARGS="runReg ${nocached}"                       \
        SAMPLE="SampleSelection2"           \
        OPTS_FOLDER="BaselineStuff-take4"   \
        TAG="BaselineStuff_regs_eta_ind" &
fi

if [ "$simulations" = true ]; then
    make 06simulations                                \
        SAMPLE="SampleSelection6"                     \
        OPTS_FOLDER="BaselineStuff-take4-simulations" \
        TAG="BaselineStuff_regs_newsample" &
fi

# Appendix Table VI
# ---------------------------------------------------------------------

if [ "$runRobust_countyTerm" = true ]; then
    make 04analysis                         \
        ARGS="runReg ${nocached}"                       \
        SAMPLE="SampleSelection6"           \
        OPTS_FOLDER="BaselineStuff-take4"   \
        TAG="BaselineStuff_regs_countyTerm" &
fi

if [ "$runRobust_noTM" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_noTM" &
fi

if [ "$runRobust_PFFS" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_PFFS" &
fi

if [ "$runRobust_noPFFS" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_noPFFS" &
fi

if [ "$runRobust_noDuals" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_noDuals" &
fi

if [ "$runRobust_ageEffect" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_ageEffect" &
fi

if [ "$runRobust_riskScore" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_riskScore" &
fi

if [ "$runRobust_unshrunk" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_unshrunk" &
fi

if [ "$runRobust_excl_small_bin" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_excl_small_bin" &
fi

if [ "$runRobust_twoYearMort" = true ]; then
    make 04analysis                       \
        ARGS="runReg ${nocached}"                     \
        SAMPLE="SampleSelection6"         \
        OPTS_FOLDER="BaselineStuff-take4" \
        TAG="BaselineStuff_regs_twoYearMort" &
fi

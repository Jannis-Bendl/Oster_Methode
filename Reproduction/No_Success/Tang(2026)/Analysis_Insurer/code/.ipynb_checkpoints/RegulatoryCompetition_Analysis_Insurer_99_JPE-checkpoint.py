import os
import numpy as np
import pandas as pd
import re




import statsmodels.api as sm
import statsmodels.formula.api as smf


import matplotlib.pyplot as plt



import random
random.seed(1)

from stargazer.stargazer import Stargazer
def stargazer_dropcols(latex_code, keywords_to_drop):
    lines = latex_code.split('\n')
    new_lines = []
    for line in lines:
        if not any(keyword in line for keyword in keywords_to_drop):
            new_lines.append(line)
    return '\n'.join(new_lines)

from IPython.core.interactiveshell import InteractiveShell
InteractiveShell.ast_node_interactivity = "all"
pd.options.display.max_rows = 4000

plt.rcParams.update({'font.size': 24})

os.chdir("/Users/johnnytang/Dropbox/Johnny Tang/RegulatoryCompetition/RegulatoryCompetition_ReplicationPackage/Analysis_Insurer/")


dict_vars = {'is_in_sample':'In Sample',
           'TOTALLIAB':'Total Liability',
             'AUTHCONTROLLEVELRISKBASEDCAPRATIO':'Risk-Based Capital Ratio',
           'RatingNumeric':'A.M. Best Rating',
           'LEVERAGE':'Leverage',
           'LIQUIDINVESTTOLIAB':'Liquidity',
           'ROAECAPSURPLUS':'Return on Equity'}

def snl_rescale_vars(df):
    if 'TOTALLIAB' in df.columns.values:
        df['TOTALLIAB'] = df['TOTALLIAB'] / (1e6)
    if 'LIQUIDINVESTTOLIAB' in df.columns.values:
        df['LIQUIDINVESTTOLIAB'] = df['LIQUIDINVESTTOLIAB'] / (1e4)

    return df

def weighted_avg(group, value_cols, weight_col):
    group = group.fillna(0)
    results = {}

    for col in value_cols:
        weighted_avg = (group[col] * group[weight_col]).sum() / group[weight_col].sum()
        equal_weighted_avg = group[col].mean()
        results[f'{col}_weighted_avg'] = weighted_avg
        results[f'{col}_equal_weighted_avg'] = equal_weighted_avg

    return pd.Series(results)

import os
import re

def get_filename_case(file_path, case):
    current_dir = os.path.basename(os.getcwd())
    if current_dir not in {"Analysis_Insurer", "Analysis_Demand"}:
        raise ValueError("Error: Current directory is not 'Analysis_Insurer'.")

    normalized_dir = os.path.abspath(file_path)
    if "Analysis_Demand" in normalized_dir:
        return file_path
    elif "Analysis_Insurer" in normalized_dir:
        exception_patterns = [
            r"^.*output/CapitalAllocation_\w+\.csv$",
            r"^.*output/data_insurer_chars\.csv$",
            r"^.*output/StateYear_joint\.csv$",
            r"^.*output/ReducedForm/.*"
        ]

        for pattern in exception_patterns:
            if re.search(pattern, file_path):
                return file_path

        file_name, file_extension = os.path.splitext(os.path.basename(file_path))
        modified_file_name = f"{file_name}_{case}{file_extension}"

        modified_path = os.path.join(os.path.dirname(file_path), modified_file_name)
        return modified_path

    return file_path

case = "baseline"


data = pd.read_csv("../CleanData/output/SNL_Reinsurance_Captives_AgreementLevel.csv")

data = data.loc[data['amount_reinsured'] > 0]

data_ss = data.groupby(['REINSSTATEDOMICILED_filled','year']).agg({'CEDENTSNLTOPENTITYKEY':'nunique','amount_reinsured':'sum'})
data_ss = data_ss.reset_index(drop=False)

data_ss['amount_reinsured_year_total'] = data_ss[['amount_reinsured','year']].groupby(['year']).transform('sum')

data_ss['amount_reinsured_frac'] = data_ss['amount_reinsured'] / data_ss['amount_reinsured_year_total']

df_uploaded = data_ss.loc[(data_ss['year'] >= 2013) & (data_ss['year'] <= 2019)]

top_states_2019 = df_uploaded[df_uploaded['year'] == 2019].groupby('REINSSTATEDOMICILED_filled')['amount_reinsured_frac'].sum().nlargest(6).index.tolist()

grouped_df_frac = df_uploaded.groupby(['REINSSTATEDOMICILED_filled', 'year'])['amount_reinsured_frac'].sum().reset_index()

grouped_df_frac['REINSSTATEDOMICILED_filled'] = grouped_df_frac['REINSSTATEDOMICILED_filled'].apply(
    lambda x: x if x in top_states_2019 else 'Others')

pivot_df_frac = grouped_df_frac.pivot_table(values='amount_reinsured_frac', index='year', columns='REINSSTATEDOMICILED_filled', aggfunc='sum', fill_value=0)

sorted_columns_2019 = pivot_df_frac.loc[2019, top_states_2019].sort_values(ascending=True).index.tolist()
if 'Others' in pivot_df_frac.columns:
    sorted_columns_2019.insert(0, 'Others')

sorted_columns_2019.remove('VT')
sorted_columns_2019.insert(len(sorted_columns_2019), 'VT')

pivot_df_frac = pivot_df_frac[sorted_columns_2019]

fig, ax = plt.subplots(figsize=(12, 10))
pivot_df_frac.plot(kind='area', stacked=True, alpha=0.75, ax=ax)

plt.xlabel('Year')
plt.ylabel('Captive Market Share')
plt.legend().set_visible(False)
plt.grid(axis='y')

state_labels = {'VT':'Vermont',
                'AZ':'Arizona',
                'MO':'Missouri',
                'DE':'Delaware',
                'IA':'Iowa',
                'SC':'South Carolina',
                'Others':'Other States'}

cumulative_heights = pivot_df_frac.cumsum(axis=1).loc[2018]
for state in sorted_columns_2019:
    y_pos = cumulative_heights[state] - (pivot_df_frac.loc[2018, state] / 2)
    ax.text(2017.8, y_pos, state_labels[state], ha='center', va='center', fontsize=24)

plt.tight_layout()

plt.savefig("output/summary_stats/captive_share_ts.png", dpi=600)

data_insureryear = pd.read_csv(get_filename_case("output/Pricing/companyyear_withprimitives.csv",case))

demand_all = pd.read_csv("../CleanData/output/Demand_All.csv")

demand_all['SNLSTATENTITYKEY_year'] = demand_all['SNLSTATENTITYKEY'] + "_" + demand_all['year'].astype(str)

SNLSTATENTITYKEY_year_sample = data_insureryear['SNLSTATENTITYKEY'] + "_" + data_insureryear['year'].astype(str)

demand_all['is_in_sample'] = pd.to_numeric(demand_all['SNLSTATENTITYKEY_year'].isin(SNLSTATENTITYKEY_year_sample)).astype(int)

df = demand_all.groupby(['year','is_in_sample']).agg({'PremiumsAndAnnuityConsiderations':'sum'}).reset_index(drop=False)

df_wide = df.pivot(index='year', columns='is_in_sample', values='PremiumsAndAnnuityConsiderations')
df_wide.columns = ['PremiumsAndAnnuity_0', 'PremiumsAndAnnuity_1']
df_wide.reset_index(inplace=True)

df_wide['Coverage'] = df_wide['PremiumsAndAnnuity_1'] / (df_wide['PremiumsAndAnnuity_0'] + df_wide['PremiumsAndAnnuity_1'])

df_wide = df_wide.loc[(df_wide['year'] >= 2006) & (df_wide['year'] <= 2019)]

plt.figure(figsize=(10, 6))
plt.plot(df_wide['year'], df_wide['Coverage'] * 100, marker='o', linestyle='-')
plt.xlabel('Year')
plt.ylabel('Market Share in Sample (%)')
plt.grid(True)
plt.xticks(df_wide['year'][::2], df_wide['year'][::2].astype(int))

plot_path = "output/summary_stats/ts_sample_coverage.png"
plt.savefig(plot_path, dpi=600, bbox_inches = "tight")

snl_all = pd.read_csv("../CleanData/output/SNL_All.csv")

ambest_all = pd.read_csv("../raw/AMBest/AMBest_Ratings_All.csv")

ambest_all = ambest_all.drop_duplicates(subset=['amb_co_num','year'])


snl_ambest_all = pd.merge(left=snl_all,right=ambest_all,on=['amb_co_num','year'],how='left')


snl_ambest_all['SNLSTATENTITYKEY_year'] = snl_ambest_all['SNLSTATENTITYKEY'] + "_" + snl_ambest_all['year'].apply(lambda x: str(int(x)) if pd.notna(x) else np.nan)

snl_ambest_all['is_in_sample'] = pd.to_numeric(snl_ambest_all['SNLSTATENTITYKEY_year'].isin(SNLSTATENTITYKEY_year_sample)).astype(int)

snl_ambest_all_2019 = snl_ambest_all.loc[snl_ambest_all['year'] == 2019]

coverage_financials_comparison = snl_ambest_all_2019.groupby(['is_in_sample'])[['TOTALLIAB','RatingNumeric','AUTHCONTROLLEVELRISKBASEDCAPRATIO','LEVERAGE','LIQUIDINVESTTOLIAB','ROAECAPSURPLUS']].mean().reset_index()

coverage_financials_comparison = snl_rescale_vars(coverage_financials_comparison)

coverage_financials_comparison = coverage_financials_comparison.drop(columns=['is_in_sample','AUTHCONTROLLEVELRISKBASEDCAPRATIO'])

coverage_financials_comparison = coverage_financials_comparison.rename(columns=dict_vars)

coverage_financials_comparison = coverage_financials_comparison.round(2)

coverage_financials_comparison = coverage_financials_comparison.T

coverage_financials_comparison = coverage_financials_comparison.rename(columns={0:'Not in Sample',1:'In Sample'})

coverage_financials_comparison.to_latex("output/summary_stats/summary_stats_sample_characteristics_comparison.tex", index=True)


df_costfunction = pd.read_csv("output/Pricing/companyyear_withprimitives_withky_costfunction.csv")


df_costfunction = df_costfunction.loc[(df_costfunction['ceded_frac_liab']>0) & (df_costfunction['year'] >= 2010) & (np.abs(df_costfunction['Psi']) < 1)]


from sklearn.preprocessing import LabelEncoder

encoder = LabelEncoder()
df_costfunction['SNLSTATENTITYKEY_int'] = encoder.fit_transform(df_costfunction['SNLSTATENTITYKEY'])

df_costfunction['age_ln'] = np.log(df_costfunction['age'] + 1)
df_costfunction['TOTALLIAB_bn'] = df_costfunction['TOTALLIAB'] / 1e6


reg_psi_chars = smf.ols('Psi ~ publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + C(year)',data=df_costfunction).fit()

reg_psi_chars_with_size = smf.ols('Psi ~ publicly_traded_TICKER + BUSINESSFOCUS_lifeorannuity + NAICOWNSTRUCTURE_is_mutual + age_ln + group_numsubsidiaries + TOTALLIAB_bn + C(year)',data=df_costfunction).fit()

stargazer = Stargazer([reg_psi_chars,reg_psi_chars_with_size])
stargazer.covariate_order(['TOTALLIAB_bn',
                           'publicly_traded_TICKER',
                           'age_ln',
                           'NAICOWNSTRUCTURE_is_mutual',
                           'BUSINESSFOCUS_lifeorannuity',
                           'group_numsubsidiaries'])
stargazer.rename_covariates({'TOTALLIAB_bn':'ln(Size)',
                             'publicly_traded_TICKER':'1(Publicly Traded)',
                             'age_ln':'ln(Firm Age)',
                             'NAICOWNSTRUCTURE_is_mutual':'1(Mutual Insurer)',
                             'BUSINESSFOCUS_lifeorannuity':'1(Life or Annuity Focus)',
                             'group_numsubsidiaries':'Num. Subsidiaries'})
stargazer.add_line("Year FEs",['X','X'])
stargazer.significant_digits(5)

keywords_to_drop = ['C(date',
                    'R^2','Residual Std. Error','F Statistic',
                    'Note:',
                    'begin{table}','end{table}',
                    'Dependent variable']

reg_output = stargazer_dropcols(stargazer.render_latex(), keywords_to_drop)

with open('output/reg_psi_chars_costfunction.tex', 'w') as f:
    f.write(reg_output)


df = pd.read_csv("../raw/Google/GoogleSearchTrends_Captives.csv")

df.rename(columns={
    "Month": "Date",
    "life insurance captives: (United States)": "life_insurance_captives",
    "life insurance: (United States)": "life_insurance"
}, inplace=True)

df["Date"] = pd.to_datetime(df["Date"])

plt.figure(figsize=(12, 6))
plt.plot(df["Date"], df["life_insurance"], label="Life Insurance", color="red")
plt.plot(df["Date"], df["life_insurance_captives"], label="Life Insurance Captives", color="blue")

plt.xlabel("Date")
plt.ylabel("Google Search Intensity")
plt.legend(loc="upper center", bbox_to_anchor=(0.5, -0.2), ncol=2, frameon=False)
plt.grid(True)

plt.tight_layout()

plt.savefig("output/summary_stats/GoogleSearchTrends_Captives.png", dpi=600)


df = pd.read_csv("../raw/Google/GoogleSearchTrends_BankInsurerFailures.csv")

df.rename(columns={
    "Month": "Date",
    "bank failure: (United States)": "bank_failure",
    "insurance failure: (United States)": "insurance_failure"
}, inplace=True)

df["Date"] = pd.to_datetime(df["Date"])

plt.figure(figsize=(12, 6))
plt.plot(df["Date"], df["bank_failure"], label="Bank Failure", color="blue")
plt.plot(df["Date"], df["insurance_failure"], label="Insurance Failure", color="red")

plt.xlabel("Date")
plt.ylabel("Google Search Intensity")
plt.legend(loc="upper center", bbox_to_anchor=(0.5, -0.2), ncol=2, frameon=False)
plt.grid(True)

plt.tight_layout()

plt.savefig("output/summary_stats/GoogleSearchTrends_BankInsurerFailures.png", dpi=600)


df = pd.read_csv("../raw/Google/GoogleSearchTrends_BankInsurerBankruptcy.csv")

df.rename(columns={
    "Month": "Date",
    "bank bankruptcy: (United States)": "bank_bankruptcy",
    "insurance bankruptcy: (United States)": "insurance_bankruptcy"
}, inplace=True)

df["Date"] = pd.to_datetime(df["Date"])

plt.figure(figsize=(12, 6))
plt.plot(df["Date"], df["bank_bankruptcy"], label="Bank bankruptcy", color="blue")
plt.plot(df["Date"], df["insurance_bankruptcy"], label="Insurance bankruptcy", color="red")

plt.xlabel("Date")
plt.ylabel("Google Search Intensity")
plt.legend(loc="upper center", bbox_to_anchor=(0.5, -0.2), ncol=2, frameon=False)
plt.grid(True)

plt.tight_layout()

plt.savefig("output/summary_stats/GoogleSearchTrends_BankInsurerBankruptcy.png", dpi=600)


data = pd.read_csv(get_filename_case("../../RegulatoryCompetition/Analysis_Demand/output/elasticities_insurerstateyear.csv",case))


data = data.loc[(data['elasticity'].isna()==False) & (data['share'].isna()==False)]


value_columns = ['elasticity']
weight_column = 'share'

data_ss = data[['year','state','type','elasticity','share']].groupby(['year','state','type']).apply(weighted_avg, value_columns, weight_column).reset_index()

data_ss = data_ss.loc[data_ss['state'].isin(['American Samoa','Canada','Guam','Northern Mariana Islands','Other Alien','Puerto Rico','Virgin Islands'])==False]


quantiles = [0.00, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 1]

quantile_df = data_ss.groupby(['year'])['elasticity_weighted_avg'].quantile(quantiles).unstack()

quantile_df.columns = [f'{int(q*100)}%' for q in quantiles]

quantile_df = quantile_df.loc[quantile_df.index <= 2019]

quantile_df = np.abs(quantile_df[['5%','95%']].round(2))

quantile_df.to_latex(get_filename_case("output/histogram_elasticity_95_ci.tex",case), index=True)


data_ss['state'] = data_ss['state'].astype('category')
data_ss['year'] = data_ss['year'].astype('category')

model = smf.ols("elasticity_weighted_avg ~ C(state) + C(year)", data=data_ss).fit()

anova_results = sm.stats.anova_lm(model, typ=2)

ss_total = anova_results['sum_sq'].sum()
pct_state = (anova_results.loc['C(state)', 'sum_sq'] / ss_total) * 100
pct_year = (anova_results.loc['C(year)', 'sum_sq'] / ss_total) * 100
pct_residual = (anova_results.loc['Residual', 'sum_sq'] / ss_total) * 100


variance_df = pd.DataFrame({
    "Source of Variance": ["Variance across states", "Variance over time", "Residual Variance"],
    "Percentage Explained": [f"{pct_state:.0f}%", f"{pct_year:.0f}%", f"{pct_residual:.0f}%"]
})

variance_df.to_latex(get_filename_case("output/histogram_elasticity_anova.tex",case),index=False)

data_long = pd.read_csv("output/StateYear_joint.csv")


data_long = data_long.loc[data_long['year'] >= 2002]


data_long['has_captives_intensive'] = pd.to_numeric(data_long['amount_reinsured'] > 0).astype(int)

data_long['num_captives'] = data_long['num_captives'].fillna(0)
data_long['amount_reinsured_ln'] = np.log(data_long['amount_reinsured']+1)

data_long['ConsumerScore_narrow'] = (
    data_long['AvailabilityofConsumerInformationLife'] +
    data_long['AggregatedComplaintDataAvailabletoPublic'] +
    data_long['ConsumerComplaintStatistics'] +
    data_long['OnlineComplaintSubmission']
)


from sklearn.preprocessing import LabelEncoder

encoder = LabelEncoder()
data_long['State_int'] = encoder.fit_transform(data_long['State'])

data_long = data_long.dropna(subset=['State','State_int','year','AllowSPVCaptives','DPW_Life'])


data_long['ConsumerScore_narrow_high'] = pd.to_numeric(data_long['ConsumerScore_narrow'] > 0).astype(int)


reg_consumer_1 = smf.ols('AllowSPVCaptives ~ ConsumerScore_narrow + newbusinesses_pop + tourists + vote_share_r + C(year)',data=data_long).fit(cov_type='cluster', cov_kwds={'groups': np.array(data_long[['State_int']])})

reg_consumer_2 = smf.ols('AllowSPVCaptives ~ DPW_Life + ConsumerScore_narrow + newbusinesses_pop + tourists + vote_share_r + C(year)',data=data_long).fit(cov_type='cluster', cov_kwds={'groups': np.array(data_long[['State_int']])})

reg_consumer_3 = smf.ols('AllowSPVCaptives ~ ConsumerScore_narrow_high + newbusinesses_pop + tourists + vote_share_r + C(year)',data=data_long).fit(cov_type='cluster', cov_kwds={'groups': np.array(data_long[['State_int', 'year']])})

reg_consumer_4 = smf.ols('AllowSPVCaptives ~ DPW_Life + ConsumerScore_narrow_high + newbusinesses_pop + tourists + vote_share_r + C(year)',data=data_long).fit(cov_type='cluster', cov_kwds={'groups': np.array(data_long[['State_int', 'year']])})


stargazer = Stargazer([reg_consumer_3,reg_consumer_4,reg_consumer_1,reg_consumer_2])
stargazer.covariate_order(['ConsumerScore_narrow_high','ConsumerScore_narrow','DPW_Life',
                           'newbusinesses_pop','tourists','vote_share_r'])
stargazer.rename_covariates({'ConsumerScore_narrow_high':'1(Consumer Friendly)',
                             'ConsumerScore_narrow':'Consumer Friendliness',
                             'DPW_Life':'Default Exposure',
                             'newbusinesses_pop':'Business Registrations',
                             'tourists':'Amenities',
                             'vote_share_r':'Presidential Vote Share'})
stargazer.add_line("Year FEs",['X','X','X','X'])

keywords_to_drop = ['C(date',
                    'R^2','Residual Std. Error','F Statistic',
                    'Note:',
                    'begin{table}','end{table}',
                    'Dependent variable']

reg_output = stargazer_dropcols(stargazer.render_latex(), keywords_to_drop)

with open('output/ReducedForm/reg_supply_consumer.tex', 'w') as f:
    f.write(reg_output)

cases = ['baseline',
             'costfunction',
             'guarantyfundfunding',
             'profitshare',
             'commissions',
             'thetazero',
             'thetafive',
             'omegaten',
             'omegafifty',
             'prestablesample']
cases_baseline = ['dual']


import os
import re
import pandas as pd

def parse_tex_files(cases,cases_baseline,directory="output/PaperText"):
    variables_to_extract = [
        'muavg',
        'sigmaavg',
        'regulatorlambdaratio',
        'capratefederal',
        'capratefederalsocialplanner',
        'defaultlossfederalchangelevel',
        'defaultprobfederalchangelevel',
        'defaultlossplannerchangelevel',
        'surplusfederallevelschange',
        'surplusplannerlevelschange',
        'welfarefederal',
        'welfarefederallevelschangebn',
        'socialwelfarefederallevelschangebn',
        'welfarefederallevelschangesocialplannerbn'
    ]

    filename_pattern = r"PaperText_RegulatoryCompetition_Analysis_Regulator_Solve_(.+)\.tex$"

    results = []

    for filename in os.listdir(directory):
        match = re.match(filename_pattern, filename)
        if match:
            case = match.group(1)

            if case not in cases:
                continue

            with open(os.path.join(directory, filename), 'r', encoding='utf-8') as file:
                file_content = file.read()

            file_results = {'case': case}
            suffix = "" if case == "baseline" else case

            for var in variables_to_extract:
                target_var = f"{var}{suffix}"
                command_pattern = r"\\newcommand\{([^}]*" + re.escape(target_var) + r"[^}]*)\}\{([^}]+)\}"

                matches = re.finditer(command_pattern, file_content)
                for match in matches:
                    variable = match.group(1)
                    value = match.group(2)

                    clean_variable = re.sub(r'[^a-zA-Z0-9]', '', variable)
                    if clean_variable == target_var:
                        clean_value = re.sub(r'[^0-9.-]', '', value)
                        try:
                            file_results[var] = float(clean_value)
                        except ValueError:
                            file_results[var] = None
                        break

                if var not in file_results:
                    file_results[var] = None

            results.append(file_results)

            if case == 'baseline':
                for baseline_case in cases_baseline:
                    baseline_results = {'case': baseline_case}

                    for var in variables_to_extract:
                        target_var = f"{var}{baseline_case}"
                        command_pattern = r"\\newcommand\{([^}]*" + re.escape(target_var) + r"[^}]*)\}\{([^}]+)\}"

                        matches = re.finditer(command_pattern, file_content)
                        for match in matches:
                            variable = match.group(1)
                            value = match.group(2)

                            clean_variable = re.sub(r'[^a-zA-Z0-9]', '', variable)
                            if clean_variable == target_var:
                                clean_value = re.sub(r'[^0-9.-]', '', value)
                                try:
                                    baseline_results[var] = float(clean_value)
                                except ValueError:
                                    baseline_results[var] = None
                                break

                        if var not in baseline_results:
                            baseline_results[var] = None

                    results.append(baseline_results)

    df = pd.DataFrame(results)

    expected_columns = ['case'] + variables_to_extract
    for col in expected_columns:
        if col not in df.columns:
            df[col] = None

    df = df[expected_columns]

    return df

df = parse_tex_files(cases=cases,cases_baseline=cases_baseline)


df = df[['case',
         'muavg',
         'sigmaavg',
         'regulatorlambdaratio',
         'capratefederal',
         'defaultlossfederalchangelevel',
         'surplusfederallevelschange',
         'welfarefederallevelschangebn',
         'capratefederalsocialplanner',
         'defaultlossplannerchangelevel',
         'surplusplannerlevelschange',
         'welfarefederallevelschangesocialplannerbn']]

df['capratefederal'] = df['capratefederal'].map(lambda x: f'{round(x):.0f}')
df['capratefederalsocialplanner'] = df['capratefederalsocialplanner'].map(lambda x: f'{round(x):.0f}')

df['defaultlossfederalchangelevel'] = df['defaultlossfederalchangelevel'].map(lambda x: f'{round(x):.0f}')
df['defaultlossplannerchangelevel'] = df['defaultlossplannerchangelevel'].map(lambda x: f'{round(x):.0f}')

df['surplusfederallevelschange'] = df['surplusfederallevelschange'].map(lambda x: f'{round(x):.0f}')
df['surplusplannerlevelschange'] = df['surplusplannerlevelschange'].map(lambda x: f'{round(x):.0f}')

df = df.rename(columns={'case':'Scenario',
                        'muavg':r'Avg. \mu',
                        'sigmaavg':r'Avg. \sigma',
                        'regulatorlambdaratio':'Trade-Off Ratio',
                        'capratefederal':'Cap. Req. Federal',
                        'defaultlossfederalchangelevel':'Default Loss Federal',
                        'surplusfederallevelschange':'Consumer Surplus Federal',
                        'welfarefederallevelschangebn':"Regulator's Utility Federal",
                        'defaultlossplannerchangelevel':'Default Loss Planner',
                        'capratefederalsocialplanner':'Cap. Req. Planner',
                        'surplusplannerlevelschange':'Consumer Surplus Planner',
                        'welfarefederallevelschangesocialplannerbn':'Social Welfare Planner'})

new_columns = {
    'Scenario': 'Scenario',
    r'Avg. \mu': r'Avg. \mu',
    r'Avg. \sigma': r'Avg. \sigma',
    r'\lambda Ratio': r'\lambda Ratio',
    'Cap. Req. Federal': 'Cap. Req.',
    'Default Loss Federal': 'Default Loss',
    'Consumer Surplus Federal': 'Consumer Surplus',
    "Regulator's Utility Federal": "Regulator's Utility",
    'Cap. Req. Planner': 'Cap. Req.',
    'Default Loss Planner': 'Default Loss',
    'Consumer Surplus Planner': 'Consumer Surplus',
    'Social Welfare Planner': 'Social Welfare'
}

df = df.rename(columns=new_columns)

def reorder_scenarios(df, cases_order):
    all_scenarios = df['Scenario'].unique().tolist()

    remaining = [x for x in all_scenarios if x not in cases_order]

    full_order = cases_order + remaining

    df['Scenario'] = pd.Categorical(df['Scenario'], categories=full_order, ordered=True)

    return df.sort_values('Scenario').reset_index(drop=True)

cases_order = ['baseline',
               'commissions','costfunction', 'profitshare',
               'guarantyfundfunding', 'dual',
               'thetazero','thetafive','omegaten', 'omegafifty', 'prestablesample']
df = reorder_scenarios(df, cases_order)


def add_section_headers(df):
    rows = df.values.tolist()
    columns = df.columns.tolist()

    rows.insert(0, columns)

    def create_header(title):
        return [title if i == 0 else np.nan for i in range(len(columns))]

    header1 = create_header("Alternative Modeling Frameworks")
    header2 = create_header("Alternative Regulatory Arrangements")
    header3 = create_header("Alternative Parameter Values and Samples")

    def find_idx(label):
        for i, row in enumerate(rows):
            if row[0] == label:
                return i
        return None

    header1_idx = find_idx('baseline')
    header2_idx = find_idx('profitshare')
    header3_idx = find_idx('dual')

    inserts = []
    if header1_idx is not None:
        inserts.append((header1_idx + 1, header1))
    if header2_idx is not None:
        inserts.append((header2_idx + 1, header2))
    if header3_idx is not None:
        inserts.append((header3_idx + 1, header3))

    for offset, (idx, header) in enumerate(sorted(inserts, key=lambda x: x[0])):
        rows.insert(idx + offset, header)

    column_names = rows.pop(0)

    new_df = pd.DataFrame(rows, columns=column_names)

    return new_df

df = add_section_headers(df)


cases_omit_calibration = ['profitshare','guarantyfundfunding','dual','omegaten','omegafifty','prestablesample']

df.loc[df['Scenario'].isin(cases_omit_calibration),[r'Avg. \mu',r'Avg. \sigma','Trade-Off Ratio']] = np.nan

df = df.loc[df['Scenario'] != 'omegafifty']


scenario_dict = {
    'baseline': 'Baseline',
    'commissions': 'Broker Commission Instruments',
    'costfunction': 'Captive Cost Function',
    'guarantyfundfunding': 'Insurers-Paid Guaranty Fund',
    'dual': 'Dual Federal-State Regulators',
    'profitshare': 'Profits Split by AUM',
    'thetazero': r'No Deadweight Cost of Capital ($\theta = 0\%$)',
    'thetafive': r'High Deadweight Cost of Capital ($\theta = 5\%$)',
    'omegaten': r'Low Default Cost ($\eta = 10\%$)',
    'prestablesample': 'Including Pre-Stable Period'
}

df['Scenario'] = df['Scenario'].map(lambda x: scenario_dict.get(x, x))


federal_cols = 4
planner_cols = 4
total_cols = 4 + federal_cols + planner_cols

latex_header = (
    '\\midrule\n'
    '& & & & '
    f'\\multicolumn{{{federal_cols}}}{{c|}}{{{{Federal}}}} & '
    f'\\multicolumn{{{planner_cols}}}{{c}}{{{{Social Planner}}}} \\\\\n'
    '\\midrule\n'
)

def prepare_df_for_latex(df):
    df_mod = df.copy()
    df_mod['row_type'] = df_mod.apply(lambda x: 'header' if pd.isna(x['Social Welfare']) else 'data', axis=1)
    return df_mod

def df_to_latex_with_headers(df):
    df_mod = prepare_df_for_latex(df)

    latex_lines = []
    for _, row in df_mod.iterrows():
        if row['row_type'] == 'header':
            latex_lines.append('\\midrule')
            latex_lines.append(f'\\multicolumn{{{total_cols}}}{{c}}{{\\textit{{{row["Scenario"]}}}}} \\\\')
        else:
            values = [str(x) if pd.notna(x) else '' for x in row[:-1]]
            latex_lines.append(' & '.join(values) + ' \\\\')

    column_format = 'c|cc|c|' + 'c' * federal_cols + '|' + 'c' * planner_cols

    column_headers = ' & '.join(str(col) for col in df.columns) + ' \\\\'

    table_lines = [
        '\\begin{tabular}{' + column_format + '}',
        '\\toprule',
        column_headers,
        latex_header,
        '\n'.join(latex_lines),
        '\\bottomrule',
        '\\end{tabular}'
    ]

    return '\n'.join(table_lines)

latex_table = df_to_latex_with_headers(df)

with open('output/Regulator/results_mastertable.tex', 'w') as f:
    f.write(latex_table)

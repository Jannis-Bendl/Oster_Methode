#!/usr/bin/env python
# -*- coding: utf-8 -*-

try:
    from urllib.request import urlopen
except:
    from urllib import urlopen

from io import BytesIO
from os import path

import pandas as pd

ROOT = '.' 
OUT  = path.join(ROOT, '00common')


def main():
    df_lt = pd.DataFrame()
    for year in range(2006, 2017):
        if year in [2008, 2012]:
            print("Note: There are no {0} tables for some reason".format(year))
            continue

        print(year)
        df_lt = df_lt.append(get_life_table(year))

    df_lt.to_csv(path.join(OUT, '00ssa-life-tables.txt'), index = False)


def get_life_table(year):
    colnames = [
        'lt_age',
        'lt_male_pd',
        'lt_male_n',
        'lt_male_le',
        'lt_female_pd',
        'lt_female_n',
        'lt_female_le'
    ]
    url = "https://www.ssa.gov/oact/STATS/table4c6_{0}.html".format(year)
    tbl = pd.read_html(BytesIO(urlopen(url).read()))
    try:
        df = tbl[1]
    except IndexError:
        df = tbl[0].iloc[:-1].copy()
    df.columns = colnames
    df['lt_year'] = year
    return df


if __name__ == "__main__":
    main()

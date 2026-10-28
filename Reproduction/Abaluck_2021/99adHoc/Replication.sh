#!/usr/bin/env bash

# Convert svg to png (use any program you like; I use inkscape)
cd Graphics
figs="
    _19Figure1_100pct
    bal_100pct_nq10
    fb_100pct_nq10
    FS_100pct_nq10
    rf_100pct_nq10
    _19figureA1_term_map_pct_100
    riskscore_bal_100
    age_bal_100
    FSRF_100pct_nq10_v1
    viv_100pct_nq10
    YearBin_19_100pct_common_mucounty_mleCYYBPlan
"
for fig in ${figs}; do
    inkscape "${fig}.svg" -d 300 -o "${fig}.png"
done
cd -

for i in a b c; do
    echo $i
done

# Compile pdflatex (the packages in ReplicationPreamble.tex are required)
pdflatex -shell-escape Replication.tex
rm -f Replication.out
rm -f Replication.log
rm -f Replication.aux
rm -f Replication.fls
rm -rf svg-inkscape

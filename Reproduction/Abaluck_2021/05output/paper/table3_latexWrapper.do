* Objective: define a function that takes the Table 3 estimate results,
* wraps them in Latex format, and exports them to a .tex file.

* Depends:
*   Files:
*       - 05output/paper/table3.do
*       - 05output.do
*       - 05output/ExportRegressionOutput.do

*   Objects:        File:
*   MregsNoDemo     05output.do
*   Mregs           05output.do
*   SpecregsNoDemo  05output.do
*   Specregs        05output.do

*   Locals:         File:
*   `out'           table3.do
*   `NIV'           ExportRegressionOutput.do

*   (Mregs and MregsNoDemo depend on:
*   beta_coe        ExportRegressionOutput.do
*   beta_se         ExportRegressionOutput.do
*   fs_coefs        ExportRegressionOutput.do
*   fs_se           ExportRegressionOutput.do
*   fs_f_sta        ExportRegressionOutput.do
*   rf_coefs        ExportRegressionOutput.do
*   rf_se           ExportRegressionOutput.do)

* Part 1: Defining Latex function arguments

    mata table3_matrix = MregsNoDemo, Mregs
    mata table3_specs  = SpecregsNoDemo, Specregs

    mata fmt_col1 = ///
        "%9.3f"   \ ///
        "%5.3f"   \ ///
        "%9.1f"   \ ///
        "%9.3f"   \ ///
        "%5.3f"   \ ///
        "%9.3f"   \ ///
        "%5.3f"   \ ///
        "%12.0g"  \ ///
        "%12.0g"  \ ///
        "%21.0fc"

    mata fmt_col2 = ///
        "%9.4f"   \ ///
        "%9.4f"   \ ///
        "%9.1f"   \ ///
        "%9.4f"   \ ///
        "%9.4f"   \ ///
        "%9.3f"   \ ///
        "%9.3f"   \ ///
        "%12.0g"  \ ///
        "%12.0g"  \ ///
        "%21.0fc"

    mata table3_fmt = fmt_col1 , fmt_col2 , fmt_col1 , fmt_col2

    mata table3_paneltitles = ///
        "\emph{Dep. Var.: Observational Mortality} & \multicolumn{4}{c}{A. First Stage}\tabularnewline" \ ///
        "\emph{Dep. Var.: One-Year Mortality} & \multicolumn{4}{c}{B. Reduced Form}\tabularnewline"     \ ///
        "\emph{Dep. Var.: One-Year Mortality} & \multicolumn{4}{c}{C. Second Stage (Forecast Coefficient)}\tabularnewline"

    mata table3_header = ///
        "\begin{table}[t]"                                          \ ///
        "\caption{\label{tab:iv}Forecast Coefficient Estimates}"    \ ///
        "\vspace{-0.5cm}"                                           \ ///
        "\begin{center}"                                            \ ///
        "\begin{tabular}{ld{1.3}d{1.4}d{1.3}d{1.4}}"                \ ///
        "\toprule "                                                 \ ///
        "\multicolumn{1}{c}{\multirow[c]{1}{*}{ }} & \multicolumn{1}{c}{\multirow[c]{1}{2cm}{\centering (1)}} & \multicolumn{1}{c}{\multirow[c]{1}{2cm}{ \centering (2)}} & \multicolumn{1}{c}{\multirow[c]{1}{2cm}{\centering (3)}} & \multicolumn{1}{c}{\multirow[c]{1}{2cm}{\centering (4)}} \tabularnewline" \ ///
        "\midrule"

    mata table3_footer =   ///
        "\bottomrule"    \ ///
        "\end{tabular}"  \ ///
        "\end{center}"   \ ///
        ""               \ ///
        "{\footnotesize{}Notes: Panels A and C of this table report first- and second-stage coefficient estimates from Equations \eqref{eq:first_stage} and \eqref{eq:IV}. Panel B reports the corresponding reduced-form coefficients. The dependent variable is observational mortality in Panel A and realized mortality in Panels B and C. In columns (1) and (3) the instrument is the interaction of lagged plan observational mortality and a lagged plan termination indicator. In columns (2) and (4) the instrument is the interaction of an indicator for above-median lagged plan observational mortality and a lagged plan termination indicator. In all specifications, we control for lagged observational mortality and termination main effects, county-by-year fixed effects, year- and county-specific termination effects, and interactions of lagged plan characteristics (as described in the text). Columns (3) and (4) additionally control for beneficiary demographics. Standard errors are clustered by county and reported in parentheses.}\tabularnewline" \ ///
        "{\footnotesize\par}" \ ///
        "\end{table}"

    mata table3_rlabels = ///
        "Instrument "               \ ///
        ""                          \ ///
        "F Statistic "              \ ///
        "Instrument "               \ ///
        ""                          \ ///
        "Observational Mortality "  \ ///
        ""                          \ ///
        "Specification "            \ ///
        "Demographic Controls "     \ ///
        "N Beneficiary-Years "

    mata table3_space = (3, 5)

    // Note: we use the local `NIV' from ExportRegressionOutput.do as an
    // argument in the latex output function.

* Part 2: define mata function

* Mata doesn't like comments, so here's some documentation on latex_table3()
*
*    real    matrix M,          // matrix of estimate numbers
*    string  matrix formats,    // matrix of formats for estimate numbers
*    string  matrix specs,      // matrix of specification and demo controls
*    string  vector rowlabels,  // row labels
*    string  vector panelhead,  // panel titles
*    string  vector header,     // all the latex code above the matrix
*    string  vector footer,     // all the latex code below the matrix
*    real    vector space,      // specify rows to create empty rows between panels
*    real    vector lindex,     // specify rows to create horizontal lines within matrix
*    string  vector lines,      // specify type of latex line
*    string  scalar out,        // output file location
*    real    scalar N           // N beneficiary years

cap mata mata drop latex_table3()
mata
void function latex_table3(
    real    matrix M,
    string  matrix formats,
    string  matrix specs,
    string  vector rowlabels,
    string  vector panelhead,
    string  vector header,
    string  vector footer,
    real    vector space,
    real    vector lindex,
    string  vector lines,
    string  scalar out,
    real    scalar N
)
{
    string  scalar      row
    string  colvector   Mfmt

    real scalar i, j, fh, m, n, rows_m_specs
    real scalar fmtrow, labrow, panel, head, foot

    fmtrow  = any(formats   :!= "")
    labrow  = any(rowlabels :!= "")
    panel   = any(panelhead :!= "")
    head    = any(header    :!= "")
    foot    = any(footer    :!= "")

    m = rows(M)
    n = cols(M)
    rows_m_specs = m + rows(specs)

    Mfmt = J(0, 1, "")

    for(i = 1; i <= m; i++) {
        row = labrow? rowlabels[i] + "& " : ""
        if (i != 2 & i != 3 & i != 5 & i != 7) {
            for(j = 1; j < n; j++) {
                row = row + sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j]) + "&"
            }
            row = row + sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j]) + "\\"
        }
        else if (i == 3) {
            for(j = 1; j < n; j++) {
                row = row + "\mc{" + strltrim(sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j])) + "}" + " & "
            }
            row = row + "\mc{" + strltrim(sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j])) + "}" + "\\"
        }
        else {
            for(j = 1; j < n; j++) {
                row = row + "(" + strltrim(sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j])) + ")" + " & "
            }
            row = row + "(" + strltrim(sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j])) + ")" + "\\"
        }
        Mfmt = Mfmt \ row

    }

    for(i = 8; i <= rows_m_specs; i++) {
        row = labrow? rowlabels[i] + " & " : ""
        for(j = 1; j < cols(specs); j++) {
            row = row + "\mc{" + specs[i-7, j] + "}" + " & "
        }
        row = row + "\mc{" + specs[i-7, j] + "}" + " \\"
        Mfmt = Mfmt \ row
    }

    row = labrow? rowlabels[10] + "&" : ""
    row = row + "\multicolumn{4}{c}{" + strltrim(sprintf(fmtrow? formats[10,1]: "%21.0fc", N)) + "} \\"
    Mfmt = Mfmt \ row

    for(i = 1; i <= length(space); i++) {
        Mfmt[space[i]] = Mfmt[space[i]] + "\\"
    }

    for(i = 1; i <= length(lindex); i++) {
        Mfmt[lindex[i]] = Mfmt[lindex[i]] + lines[i]
    }

    if (panel) {
        Mfmt = panelhead[1] \ Mfmt[(1..3)] \ panelhead[2] \ Mfmt[(4,5)] \ panelhead[3] \ Mfmt[(6..10)]
    }

    if (head) {
        Mfmt = header \ Mfmt
    }

    if (foot) {
        Mfmt = Mfmt \ footer
    }

    fh = fopen(out, "rw")
    for(i = 1; i <= rows(Mfmt); i++) {
        fwrite(fh, Mfmt[i])
        fwrite(fh, sprintf("\n"))
    }
    fclose(fh)
}
end


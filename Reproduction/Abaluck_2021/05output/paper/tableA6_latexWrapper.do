* Objective: Define a function that takes the Table A6 estimate results,
*            wraps them in Latex format, and exports them to a .tex file.
* Blame:     Jerray Chang

* Depends:
* 	Files:
*	- 05output/paper/tableA6.do
* 	- 05output.do
*	- 05output/ExportRegressionOutput.do

*	Objects:		     File:
*	Mregs_countyTerm     05output.do
*   Mregs_noTM           05output.do
*   Mregs_PFFS           05output.do
*   Mregs_noPFFS         05output.do
*   Mregs_noDuals        05output.do
*   Mregs_ageEffect      05output.do
*   Mregs_riskScore      05output.do
*   Mregs_unshrunk       05output.do
*   Mregs_excl_small_bin 05output.do
*   Mregs_twoYearMort    05output.do

*	Locals:		File:
*	`out'		tableA6.do
*	`NIV' 		ExportRegressionOutput.do

* 	(All estimate matrices depend on:
*	beta_coefs	ExportRegressionOutput.do
*	beta_se		ExportRegressionOutput.do)


* Part 1: Defining Latex function arguments
* -----------------------------------------

    mata tableA6_matrix =      ///
        Mregs_countyTerm     \ ///
        Mregs_noTM           \ ///
        Mregs_PFFS           \ ///
        Mregs_noPFFS         \ ///
        Mregs_noDuals        \ ///
        Mregs_ageEffect      \ ///
        Mregs_riskScore      \ ///
        Mregs_unshrunk       \ ///
        Mregs_excl_small_bin \ ///
        Mregs_twoYearMort

    mata tableA6_specs = Specregs_noTM

    mata tableA6_fmt = ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "%5.3f"   \ ///
        "12.0g"   \ ///
        "12.0g"   \ ///
        "%21.0fc"

    mata tableA6_header = ///
        "\begin{table}[H]"                                          \ ///
        "\caption{\label{tab:robustness}Forecast Coefficient Robustness Checks}"    \ ///
        "\vspace{-0.5cm}"                                           \ ///
        "\begin{center}"                                            \ ///
        "\begin{tabular}{l*{2}{d{1.3}}}"                \ ///
        "\toprule "                                                 \ ///
        "\multicolumn{1}{c}{\multirow[c]{1}{*}{ \centering }} & \multicolumn{1}{c}{\multirow[c]{1}{2.5cm}{ \centering  (1)}} &  \multicolumn{1}{c}{\multirow[c]{1}{2.5cm}{ \centering  (2)}} \\" \ ///
        "\midrule"

    mata tableA6_footer = ///
        "\bottomrule"               \ ///
        "\end{tabular}"             \ ///
        "\end{center}"              \ ///
        "\vspace{-0.2cm}"           \ ///
        ""                          \ ///
        "{\footnotesize{}Notes: This table reports second-stage coefficient estimates from Equation \eqref{eq:IV}. The dependent variable is one-year mortality in the first ten rows and two-year mortality in the final row. In column 1 the instrument is the interaction of observational mortality of the lagged plan and a lagged plan termination indicator. In column 2 the instrument is the interaction of an indicator for above-median observational mortality of the lagged plan and a lagged plan termination indicator. The first row drops counties with no terminations over 2008-2011. The second row drops beneficiaries who switch to a TM plan. The third row drops non-PFFS plans that terminate and the fourth row drops PFFS plans that terminate. The fifth row drops dual-eligible beneficiaries. The sixth row allows observational mortality to depend on beneficiary age, as" \ ///
        "described in the text. The seventh row adds lagged plan risk score as a control. The eighth row does not use the empirical Bayes procedure to construct observational mortality. The ninth row drops lagged plans with fewer than 50 beneficiaries. The tenth row uses two-year observational mortality. In all specifications, we control for the observational mortality of the lagged plan and termination main effects, county-by-year fixed effects, year- and county-specific termination effects, and interactions of lagged plan characteristics (as described in the text), and beneficiary demographics. Standard errors are clustered by county and reported in parentheses.}\tabularnewline" \ ///
        "{\footnotesize\par}" \ ///
        "\end{table}"

    mata tableA6_rlabels = ///
        "Counties With Terminations "  \ ///
        ""                          \ ///
        "No TM Enrollments "        \ ///
        ""                          \ ///
        "PFFS Terminations "        \ ///
        ""                          \ ///
        "Non-PFFS Terminations "    \ ///
        ""                          \ ///
        "No Dual-Eligibles "        \ ///
        ""                          \ ///
        "Age-Specific Effects "     \ ///
        ""                          \ ///
        "Risk Score Control "       \ ///
        ""                          \ ///
        "No Shrinkage "             \ ///
        ""                          \ ///
        "No Small Plans "           \ ///
        ""                          \ ///
        "Two-Year Mortality "       \ ///
        ""                          \ ///
        "Specification "            \ ///
        "Demographic Controls "

    mata tableA6_space = (2, 4, 6, 8, 10, 12, 14, 16, 18)

    // Note: we use the matrix "MN" which holds locals `NIV' from
    // ExportRegressionOutput.do as an argument in the latex output function.

* Part 2: define mata function
* ----------------------------

* Mata doesn't like comments, so here's some documentation on latex_tableA6()
*
*    real    matrix M,               // matrix of estimate numbers
*    string  scalar MNreal,          // N beneficiary years
*    string  matrix formats,         // matrix of formats for estimate numbers
*    string  matrix specs,           // matrix of specification and demo controls
*    string  vector rowlabels,       // row labels
*    string  vector header,          // all the latex code above the matrix
*    string  vector footer,          // all the latex code below the matrix
*    real    vector space,           // specify rows to create empty rows between panels
*    real    vector lindex,          // specify rows to create horizontal lines within matrix
*    string  vector lines,           // specify type of latex line
*    string  scalar out             // output file location

cap mata mata drop latex_tableA6()
mata
void function latex_tableA6(
    real    matrix M,
    real    matrix MNreal,
    string  matrix formats,
    string  matrix specs,
    string  vector rowlabels,
    string  vector header,
    string  vector footer,
    real    vector space,
    real    vector lindex,
    string  vector lines,
    string  scalar out
)
{
    string  scalar      row
    string  colvector   Mfmt

    real scalar i, j, fh, m, n, rows_m_specs, rows_mn
    real scalar fmtrow, labrow, head, foot

    fmtrow  = any(formats   :!= "")
    labrow  = any(rowlabels :!= "")
    head    = any(header    :!= "")
    foot    = any(footer    :!= "")

    Mfmt = J(0, 1, "")

    m = rows(M)
    n = cols(M)
    rows_m_specs = m + rows(specs)

    for(i = 1; i <= m; i++) {
        if (mod(i,2) != 0) {
            row = labrow? rowlabels[i] + "&" : ""
            for(j = 1; j < n; j++) {
                row = row + sprintf(fmtrow? formats[i]: "%12.0g", M[i,j]) + "&"
            }
            row = row + sprintf(fmtrow? formats[i]: "%12.0g", M[i,j]) + "\\"
        }
        else {
            row = labrow? rowlabels[i] + "\hspace{0.5cm}(\emph{N=" + strltrim(sprintf(fmtrow? formats[23]: "%21.0fc", MNreal[i/2])) + "}) " + "& " : ""
            for(j = 1; j < n; j++) {
                row = row + "(" + strltrim(sprintf(fmtrow? formats[i]: "%12.0g", M[i,j])) + ")" + "&"
            }
            row = row + "(" + strltrim(sprintf(fmtrow? formats[i]: "%12.0g", M[i,j])) + ")" + "\\"
        }
        Mfmt = Mfmt \ row
    }

    for(i = 21; i <= rows_m_specs; i++) {
        row = labrow? rowlabels[i] + " & " : ""
        for(j = 1; j < cols(specs); j++) {
            row = row + "\mc{" + specs[i-20, j] + "}" + " & "
        }
        row = row + "\mc{" + specs[i-20, j] + "}" + " \\"
        Mfmt = Mfmt \ row
    }

    for(i = 1; i <= length(space); i++) {
        Mfmt[space[i]] = Mfmt[space[i]] + " \tabularnewline"
    }

    for(i = 1; i <= length(lindex); i++) {
        Mfmt[lindex[i]] = Mfmt[lindex[i]] + lines[i]
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

* Objective: define a function that takes the Table 2 estimate results, wraps them in Latex format, and exports them to a .tex file.
* Blame: Jerray Chang
* Created: 12/15/20

* Part 1: Defining Latex function arguments
    mata table2_matrix = MregsNoDemo[1::3, 1::2] \ MpanelB[1::2, (1, 4)] \ MpanelC
    mata table2_specs = SpecregsNoDemo

    mata fmt_col1 = ///
        "%9.3f"   \ ///
        "%5.3f"   \ ///
        "%9.1fc"  \ ///
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
        "%9.1fc"  \ ///
        "%9.4f"   \ ///
        "%9.4f"   \ ///
        "%9.4f"   \ ///
        "%9.4f"   \ ///
        "%12.0g"  \ ///
        "%12.0g"  \ ///
        "%21.0fc" 

    mata table2_fmt = fmt_col1 , fmt_col2
    
    mata table2_paneltitles = ///
        "\emph{Dep. Var.: Observational Mortality} & \multicolumn{2}{c}{A. First Stage}\tabularnewline"                     \ ///
        "\emph{Dep. Var.: Predicted Mortality} & \multicolumn{2}{c}{B. Balance}\tabularnewline"                         \ ///
        "\emph{Dep. Var.: Predicted Forecast Residual} & \multicolumn{2}{c}{C. Fallback}\tabularnewline"

    mata table2_header = ///
        "\begin{table}[t]"                                          \ ///
        "\caption{\label{tab:validation}Tests of Assumptions}"      \ ///
        "\vspace{-0.5cm}"                                           \ ///
        "\begin{center}"                                            \ ///
        "\begin{tabular}{ld{1.3}d{1.4} }"                           \ ///
        "\toprule "                                                 \ ///
        "\multicolumn{1}{c}{\multirow[c]{1}{*}{ }}  & \multicolumn{1}{c}{\multirow[c]{1}{2.25cm}{ \centering (1)}} & \multicolumn{1}{c}{\multirow[c]{1}{2.25cm}{ \centering (2)}} \tabularnewline" \ ///
        "\midrule"
    
    mata table2_footer = ///
        "\bottomrule"               \ ///
        "\end{tabular}"             \ ///
        "\end{center}"              \ ///
        ""                          \ ///
        "{\footnotesize{}Notes: Panel A of this table is based on estimation of Equation \eqref{eq:first_stage} and presents the OLS coefficient in a first-stage regression of observational mortality on the instrument. Panel B replaces observational mortality as the dependent variable with a prediction of one-year mortality based on beneficiary demographics. Panel C uses as the dependent variable a prediction of the forecast residual based on plan characteristics. In column (1) the instrument is the interaction of observational mortality of the lagged plan and a lagged plan termination indicator. In column (2) the instrument is the interaction of an indicator for above-median observational mortality of the lagged plan and a lagged plan termination indicator. In all specifications, we control for the observational mortality of the lagged plan and termination main effects, county-by-year fixed effects, year- and county-specific termination effects, and interactions of lagged plan characteristics (as described in the text). Standard errors are clustered by county and reported in parentheses.}\tabularnewline" \ ///
        "{\footnotesize\par}" \ ///
        "\end{table}"
    
    mata table2_rlabels = ///
        "Instrument "               \ ///
        ""                          \ ///
        "F Statistic "              \ ///
        "Instrument "               \ ///
        ""                          \ /// 
        "Instrument"   \ ///
        ""                          \ ///
        "Specification "            \ ///
        "Demographic Controls "     \ ///
        "N Beneficiary-Years " 

    mata table2_space = (3, 5)

    // Note: we use the local `NIV' from ExportRegressionOutput.do as an argument in the latex output function.


* Part 2: define mata function

* Mata doesn't like comments, so here's some documentation on latex_table3()
*
*    real    matrix M,               // matrix of estimate numbers
*    string  matrix formats,         // matrix of formats for estimate numbers
*    string  matrix specs,           // matrix of specification and demo controls
*    string  vector rowlabels,       // row labels
*    string  vector panelhead,       // panel titles
*    string  vector header,          // all the latex code above the matrix
*    string  vector footer,          // all the latex code below the matrix
*    real    vector space,           // specify rows to create empty rows between panels
*    real    vector lindex,          // specify rows to create horizontal lines within matrix
*    string  vector lines,           // specify type of latex line
*    string  scalar out,             // output file location
*    real    scalar N                // N beneficiary years

cap mata mata drop latex_table2()
mata
void function latex_table2(
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
        row = labrow? rowlabels[i] + "&" : ""
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
                row = row + "(" + strltrim(sprintf(fmtrow? formats[i,j]: "%12.0g", M[i,j])) + ")" + "&"
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
    row = row + "\multicolumn{2}{c}{" + strltrim(sprintf(fmtrow? formats[10,1]: "%21.0fc", N)) + "} \\"
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


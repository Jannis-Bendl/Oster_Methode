* Objective: define a function that takes the Table A7 estimate results, wraps them in Latex format, and exports them to a .tex file.
* Blame: Jerray Chang (jerray@uchicago.edu)
* Note: auxilliary file for tableA7.do. See tableA7.do for full documentation.

* Depends:
* 	Files:
*	- 05output/paper/tableA7.do

*	Objects:		    File:
*   mata tableA7_matrix  tableA7.do

*	Locals:		        File:
*   `NIV'               tableA7.do
*	`out'		        tableA7.do

* Part 1: Defining Latex function arguments
* -----------------------------------------

    mata tableA7_matrix

    mata tableA7_fmt = ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%9.4f"   \    ///
        "%21.0fc"
    
    mata tableA7_paneltitles = ///
        "& \multicolumn{6}{c}{Panel A: OLS}  \tabularnewline"                     \ ///
        "& \multicolumn{6}{c}{Panel B: IV} \tabularnewline"                         

    mata tableA7_header = ///
        "\begin{table}[H]"                                          \ ///
        "\caption{\label{tab:star_append}Alternative Plan Characteristics Specifications}"    \ ///
        "\vspace{-0.5cm}"                                           \ ///
        "\begin{center}"                                            \ ///
        "\begin{tabular}{lcccccc}"                \ ///
        "\toprule "                                                 \ ///
        "\multicolumn{1}{l}{} & (1) & (2) & (3) & (4) & (5) & (6)\tabularnewline" \ ///
        "\midrule"
    
    mata tableA7_footer = ///
        "\bottomrule"               \ ///
        "\end{tabular}"             \ ///
        "\end{center}"          \ ///
        "{\footnotesize{}Notes: This table reports OLS and IV estimates of the regression of observational mortality and plan mortality effects, respectively, on plan characteristics. The dependent variable is observational mortality in Panel A and one-year mortality in Panel B. All specifications include the baseline controls in columns (3) and (4) of Table \ref{tab:iv}. The IV specifications instrument by the interaction of lagged plan characteristics and terminations, controlling for main effects. Standard errors are clustered by county and reported in parentheses. }" \ /// 
        "{\footnotesize\par}" \ ///
        "\end{table}"
    
    mata tableA7_rlabels = ///
        "Star Rating "              \ ///
        " "                         \ ///
        "1(Star Rating \$\geq$ 4) " \ ///
        " "                         \ ///
        "1(Star Rating \$\geq$ 3) " \ ///
        " "                         \ ///
        "1(Plan-Type = PFFS) "      \ ///
        " "                         \ ///
        "1(Plan-Type = HMO) "      \ ///
        " "                         \ ///
        "1(Plan-Type = PPO) "      \ ///
        " "                         \ ///
        "Star Rating "              \ ///
        " "                         \ ///
        "1(Star Rating \$\geq$ 4) " \ ///
        " "                         \ ///
        "1(Star Rating \$\geq$ 3) " \ ///
        " "                         \ ///
        "1(Plan-Type = PFFS) "      \ ///
        " "                         \ ///
        "1(Plan-Type = HMO) "      \ ///
        " "                         \ ///
        "1(Plan-Type = PPO) "      \ ///
        " "                         \ ///
        "N Beneficiary-Years " 

    mata tableA7_space = (8)

    // Note: we use the local `NIV' from ExportRegressionOutput.do as an argument in the latex output function.

* Part 2: define mata function
* ----------------------------

* Mata doesn't like comments, so here's some documentation on latex_tableA7()
*
*    real    matrix M,               // matrix of estimate numbers
*    string  matrix formats,         // matrix of formats for estimate numbers
*    string  vector rowlabels,       // row labels
*    string  vector panelhead,       // panel titles
*    string  vector header,          // all the latex code above the matrix
*    string  vector footer,          // all the latex code below the matrix
*    real    vector space,           // specify rows to create empty rows between panels
*    real    vector lindex,          // specify rows to create horizontal lines within matrix
*    string  vector lines,           // specify type of latex line
*    string  scalar out,             // output file location
*    real    scalar N                // N beneficiary years

cap mata mata drop latex_tableA7()
mata
void function latex_tableA7(
    real    matrix M,
    string  vector formats,
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

    real scalar i, j, fh, m, n
    real scalar fmtrow, labrow, panel, head, foot

    fmtrow  = any(formats   :!= "")
    labrow  = any(rowlabels :!= "")
    panel   = any(panelhead :!= "")
    head    = any(header    :!= "")
    foot    = any(footer    :!= "")

    m = rows(M)
    n = cols(M)

    Mfmt = J(0, 1, "")

    for(i = 1; i <= m; i++) {
        if (mod(i,2) != 0) {
            row = labrow? rowlabels[i] + "& " : ""
            for(j = 1; j < n; j++) {
                if (missing(M[i,j])) {
                    row = row + "& "
                }
                else {
                    row = row + sprintf(fmtrow? formats[i]: "%12.0g", M[i,j]) + "& "
                }
            }
            if (missing(M[i,j])) {
                row = row + "\\"
            }
            else {
                row = row + sprintf(fmtrow? formats[i]: "%12.0g", M[i,j]) + "\\"
            }
        }
        else {
            row = labrow? rowlabels[i] + "& " : ""
            for(j = 1; j < n; j++) {
                if (missing(M[i,j])) {
                    row = row + "& "
                }
                else {
                    row = row + "(" + strltrim(sprintf(fmtrow? formats[i]: "%12.0g", M[i,j])) + ")" + "& "
                }
            }
            if (missing(M[i,j])) {
                row = row + "\\"
            }
            else {
                row = row + "(" + strltrim(sprintf(fmtrow? formats[i]: "%12.0g", M[i,j])) + ")" + "\\"
            }
        }
        Mfmt = Mfmt \ row
    }

    i = m + 1
    row = labrow? rowlabels[i] + "&" : ""
    row = row + "\multicolumn{5}{c}{" + strltrim(sprintf(fmtrow? formats[i,1]: "%21.0fc", N)) + "} \\"
    Mfmt = Mfmt \ row
    
    for(i = 1; i <= length(space); i++) {
        Mfmt[space[i]] = Mfmt[space[i]] + "\\"
    }

    for(i = 1; i <= length(lindex); i++) {
        Mfmt[lindex[i]] = Mfmt[lindex[i]] + lines[i]
    }

    if (panel) {
        Mfmt = panelhead[1] \ Mfmt[(1..12)] \ panelhead[2] \ Mfmt[(13..25)]
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

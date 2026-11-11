* Objective: define a function that takes the Oster table estimate results, wraps them in Latex format, and exports them to a .tex file.
* Blame: Jerray Chang <jerray@uchicago.edu>
* Created: March 8, 2021

* Depends:
* 	Files:
*	- 05output/paper/osterOVB.do
* 	    - 05output.do
*	        - 05output/ExportRegressionOutput.do
*
* Mata objects:             File:
*   max_r2                  05output/paper/osterOVB.do
*   selectn_prop            05output/paper/osterOVB.do
*   min_for_coef_eta        05output/paper/osterOVB.do
*   max_for_coef_eta        05output/paper/osterOVB.do
*   min_for_coef_eta_ind    05output/paper/osterOVB.do
*   max_for_coef_eta_ind    05output/paper/osterOVB.do
*
* Locals:                   File:
*   `"`out'"'               05output/paper/osterOVB.do

* Output:
* Latex Output:
*   ${pre}osterOVB_${pct}pct.tex
*
*   where ${pre} is the sample number and ${pct} is either 01 or 100.
* --------------------------------------------------------------------

* Part 1: define the following Latex Format Objects:
*   osterOVB_header
*   osterOVB_footer
*   osterOVB_fmt
*   osterOVB_space

* Note: to include the dollar sign ($) in latex, you have to add a backslash (\) before it, if it precedes a letter. Otherwise it will not write it.
mata osterOVB_header = ///
    "\begin{table}[H]" \ ///
    "\caption{\label{tab:oster}Forecast Coefficient Sensitivity to Omitted Variables Bias}" \ ///
    "\vspace{-0.25cm}" \ ///
    "\begin{center}" \ ///
    "\begin{tabular}{cccc}" \ ///
    "\toprule " \ ///
    "\mc{\multirow{3}{3.4cm}{\centering Max. Reduced Form \$R^2$, Relative to \$R^2$ with Controls}} & \mc{\multirow{3}{2.6cm}{ \centering Selection Proportionality Constant}} & \multicolumn{2}{c}{Forecast Coefficient Bounds} \tabularnewline" \ ///
    "\cmidrule{3-4}" \ ///
    "&  & \multirow{2}{3.4cm}{\centering With Demographic Controls} & \multirow{2}{3.4cm}{\centering Demographics and Plan Characteristics} \tabularnewline" \ ///
    "&  &  &  \tabularnewline " \ ///
    "\mc{(1)} & \mc{(2)} & \mc{(3)} & \mc{(4)} \tabularnewline" \ ///
    "\midrule"

mata osterOVB_footer = ///
    "\bottomrule" \ ///
    "\end{tabular}" \ ///
    "\par\end{center}" \ ///
    "{\footnotesize{}Notes: Columns 3 and 4 of this table report estimated bounds on the observational mortality forecast coefficient under different assumptions on the relationship between observable and unobservable confounders, following the framework of \cite{altonji_elder_taber} and \cite{oster}. Column 1 lists the assumed maximum reduced form \$R^2$, as a multiple of the reduced form \$R^2$ when all controls are included. Column 2 lists the assumed selection proportionality constant, parameterizing how ``important'' the unobservable confounders are relative to the controls. Column 3 reports bounds using the beneficiary age, sex, race, and dual-eligibility status as controls. Column 4 further controls for the star rating, premium, an indicator for donut hole coverage, and medical loss ratio of the beneficiary's enrolled plan after residualizing each plan characteristic on observational mortality. See Appendix \ref{sec:oster} for details.}" \ ///
    "{\footnotesize\par}" \ ///
    "\end{table}" \ ///
    "" \ ///
    "" \ ///
    ""

mata osterOVB_fmt = ///
    "%5.3f" \ ///
    "%5.3f" \ ///
    "%5.3f" \ ///
    "%5.3f" \ ///
    "%3.1f" \ ///
    "%3.1f" \ ///
    "%1.0f" \ ///
    "%1.0f" 

mata osterOVB_space = (1, 2, 3)


* Part 2: define mata Latex Wrapper function

cap mata mata drop latex_osterOVB()
mata
mata set matalnum on
void function latex_osterOVB(
    real    vector max_r2,
    real    vector selectn_prop,
    real    vector min_fc_eta,
    real    vector max_fc_eta,
    real    vector min_fc_eta_ind,
    real    vector max_fc_eta_ind,
    real    vector space,
    string  vector rowlabels,
    string  vector header,
    string  vector footer,
    string  vector formats,
    string  scalar out
)
{
    string scalar row
    string colvector Mfmt

    real scalar i, j, fh, m 
    real scalar fmtrow, labrow, head, foot

    fmtrow  = any(formats   :!= "")
    labrow  = any(rowlabels :!= "")
    head    = any(header    :!= "")
    foot    = any(footer    :!= "")

    m = rows(min_fc_eta)
    m
    Mfmt = J(0, 1, "")

    for(i = 1; i <= m; i++) {
        row = labrow? rowlabels[i] + "& " : ""
        row = row + sprintf(fmtrow? formats[i+4,1]: "%3.1f", max_r2[i]) + " &"
        row = row + sprintf("%1.0f", selectn_prop[i]) + " &"
        row = row + "["
        row = row + sprintf(fmtrow? formats[i,1]: "%12.0g", min_fc_eta[i]) + ","
        row = row + sprintf(fmtrow? formats[i,1]: "%12.0g", max_fc_eta[i])
        row = row + "]" + " &"
        row = row + "[" 
        row = row + sprintf(fmtrow? formats[i,1]: "%12.0g", min_fc_eta_ind[i]) + ","
        row = row + sprintf(fmtrow? formats[i,1]: "%12.0g", max_fc_eta_ind[i]) 
        row = row + "]" + "\tabularnewline "
        Mfmt = Mfmt \ row
    }

    for(i = 1; i <= length(space); i++) {
        Mfmt[space[i]] = Mfmt[space[i]] + "\\"
    }

    if (head) {
        Mfmt = header \ Mfmt
    }

    if (foot) {
        Mfmt = Mfmt \ footer
    }

    Mfmt

    fh = fopen(out, "rw")
    for(i = 1; i <= rows(Mfmt); i++) {
        fwrite(fh, Mfmt[i])
        fwrite(fh, sprintf("\n"))
    }
    fclose(fh)
}
end
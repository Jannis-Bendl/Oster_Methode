* ---------------------------------------------------------------------
* Semi-generic excel export helpers

cap mata: mata drop printxlWrapper()
mata:
void function printxlWrapper(
    string scalar xlUsing,
    string scalar xlSheet,
    real matrix matCoefs,
    real matrix matSE,
    real scalar colStart,
    real scalar rowStart)
{
    class xl scalar xlWb
    string vector xlSheets
    string scalar nfmt, sfmt, str, coef, se
    real scalar i, j

    if ( cols(matCoefs) != cols(matSE) ) {
        errprintf("matCoefs and matSE must have the same shape.\n")
        error(198)
    }

    if ( rows(matCoefs) != rows(matSE) ) {
        errprintf("matCoefs and matSE must have the same shape.\n")
        error(198)
    }

    xlWb = xl()
    xlWb.load_book(xlUsing)
    xlSheets = xlWb.get_sheets()
    if ( any(xlSheet :== xlSheets) ) {
        xlWb.set_sheet(xlSheet)
        nfmt = "%9.4f"
        sfmt = "%s (%s)"
        for (i = 1; i <= rows(matCoefs); i++) {
            for (j = 1; j <= cols(matCoefs); j++) {
                if ( (matCoefs[i, j] == .) & (matSE[i, j] == .) ) continue
                coef = strtrim(sprintf(nfmt, matCoefs[i, j]))
                se   = strtrim(sprintf(nfmt, matSE[i, j]))
                str  = sprintf(sfmt, coef, se)
                xlWb.put_string(rowStart + i - 1, colStart + j - 1, str)
            }
        }
    }
    else {
        errprintf("'%s' not in workbook '%s'\n", xlSheet, xlUsing)
        error(198)
    }

    xlWb.close_book()
}
end

cap mata: mata drop printxlWrapper_fStat()
mata:
void function printxlWrapper_fStat(
    string scalar xlUsing,
    string scalar xlSheet,
    real matrix matFStat,
    real scalar colStart,
    real scalar rowStart)
{
    class xl scalar xlWb
    string vector xlSheets
    string scalar nfmt, sfmt, str, coef, se
    real scalar i, j

    xlWb = xl()
    xlWb.load_book(xlUsing)
    xlSheets = xlWb.get_sheets()
    if ( any(xlSheet :== xlSheets) ) {
        xlWb.set_sheet(xlSheet)
        nfmt = "%9.4f"
        sfmt = "%s"
        for (i = 1; i <= rows(matFStat); i++) {
            for (j = 1; j <= cols(matFStat); j++) {
                if (matFStat[i, j] == .) continue
                coef = strtrim(sprintf(nfmt, matFStat[i, j]))
                xlWb.put_string(rowStart + i - 1, colStart + j - 1, coef)
            }
        }
    }
    else {
        errprintf("'%s' not in workbook '%s'\n", xlSheet, xlUsing)
        error(198)
    }

    xlWb.close_book()
}
end

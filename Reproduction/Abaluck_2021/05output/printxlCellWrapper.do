* ---------------------------------------------------------------------
* Semi-generic excel export helper
cap mata: mata drop printxlCellWrapper()
mata:
void function printxlCellWrapper(
    string scalar xlUsing,
    string scalar xlSheet,
    string scalar str,
    real scalar col,
    real scalar row)
{
    class xl scalar xlWb
    string vector xlSheets

    xlWb = xl()
    xlWb.load_book(xlUsing)
    xlSheets = xlWb.get_sheets()

    if ( any(xlSheet :== xlSheets) ) {
        xlWb.set_sheet(xlSheet)
        xlWb.put_string(row, col, str)
    }
    else {
        errprintf("'%s' not in workbook '%s'\n", xlSheet, xlUsing)
        error(198)
    }

    xlWb.close_book()
}
end

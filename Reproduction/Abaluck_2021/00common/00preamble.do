***********************************************************************
*                                                                     *
*                               Globals                               *
*                                                                     *
***********************************************************************

global dua   /disk/agedisk3/medicare.work/doyle-DUA51929
global bulk  /disk/agebulk3/medicare.work/doyle-DUA51929
global raw   /disk/aging/medicare/data

cap mkdir `"${dua}/`:env LOGNAME'"'
cap mkdir `"${bulk}/`:env LOGNAME'"'

global main  ${dua}/`:env LOGNAME'/cms-mortality-replication
global bulk  ${bulk}/`:env LOGNAME'/cms-mortality-replication
global data  ${bulk}/data
global out   ${bulk}/out

global svtable matrix_to_txt, saving(${out}/tables/tables.txt) append format(%21.9f)
global imopts  varn(1) case(preserve) clear

cap mkdir `"${main}"'
cap mkdir `"${bulk}"'
cap mkdir `"${data}"'
cap mkdir `"${out}"'

if ( `:list posof `"oldfolders"' in 0' == 0 ) {
    global dua   /disk/agedisk3/medicare.work/doyle-DUA51929
    global main  ${dua}/`:env LOGNAME'/cms-mortality
    global data  ${main}/data/05full-sample
    global out   ${main}/out/05full-sample
}

* NBER makes some user-written programs available system-wide. Some of
* these, however, are developed and updated on github, which makes them
* fall out of sync with their SSC counterparts, which is that is usually
* on the server. This lag can cause problems, so we discard the NBER
* version of the programs.

cap adopath - /home/site/etc/stata/ado.nber/updates
cap adopath - /home/site/etc/stata/ado.nber

cap reghdfe
cap ivreghdfe

***********************************************************************
*                                                                     *
*                        General aux programs                         *
*                                                                     *
***********************************************************************

* trim all strings and compress
capture program drop trimall
program trimall
    foreach var of varlist * {
        if ( regexm("`:type `var''", "str") ) {
            replace `var' = trim(`var')
        }
    }
    compress
end

* Email program
capture program drop mail_notify
program mail_notify
    syntax, rc(int) progname(str) start_time(str) [attach(str) email(str) CAPture]
    if ( `"`email'"' == "" ) {
        local uname: env LOGNAME
        local email `uname'@nber.org
    }
    local end_time "$S_TIME $S_DATE"
    local time     "Start: `start_time'\nEnd: `end_time'"
    if (`rc' == 0) {
        di "End: $S_TIME $S_DATE"
        local paux	  ran [Automated Message]
        local message = "`progname' finished running\n\n`time'"
        local subject = "`progname' `paux'"
    }
    else if ("`capture'" == "") {
        di "WARNING: $S_TIME $S_DATE"
        local paux ran with non-0 exit status [Automated Message]
        local message = "`progname' ran but Stata gave error code r(`rc')\n\n`time'"
        local subject = "`progname' `paux'"
    }
    else {
        di "ERROR: $S_TIME $S_DATE"
        local paux ran with errors [Automated Message]
        local message = "`progname' stopped with error code r(`rc')\n\n`time'"
        local subject = "`progname' `paux'"
    }
    di "`subject'"
    di "`message'"
    if ( "`attach'" != "" ) {
        shell echo -e "`message'" | mail -a "`attach'" -s "`subject'" `email'
    }
    else {
        shell echo -e "`message'" | mail -s "`subject'" `email'
    }
end

* Wrapper for easy timer use
cap program drop mytimer
program mytimer, rclass
    * args number what step
    syntax anything, [minutes ts]

    tokenize `anything'
    local number `1'
    local what   `2'
    local step   `3'

    if ("`what'" == "end") {
        qui {
            timer clear `number'
            timer off   `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
    else if ("`what'" == "info") {
        qui {
            timer off `number'
            timer list `number'
        }
        local seconds = r(t`number')
        local prints  `:di trim("`:di %21.2gc `seconds''")' seconds
        if ("`minutes'" != "") {
            local minutes = `seconds' / 60
            local prints  `:di trim("`:di %21.3gc `minutes''")' minutes
        }
        mytimer_ts Step `step' took `prints'
        qui {
            timer clear `number'
            timer on    `number'
        }
    }
    else {
        qui {
            timer clear `number'
            timer on    `number'
            timer off   `number'
            timer list  `number'
            timer on    `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
end

capture program drop mytimer_ts
program mytimer_ts
    display _n(1) "{hline 79}"
    if (`"`0'"' != "") display `"`0'"'
    display `"        Base: $S_FN"'
    display  "        In memory: `:di trim("`:di %21.0gc _N'")' observations"
    display  "        Timestamp: $S_TIME $S_DATE"
    display  "{hline 79}" _n(1)
end

************************************************************************
*                                                                      *
*                             stata-misc                               *
*                                                                      *
************************************************************************

* Set the linesize to be 120 for the log files; overriding default of 80
set linesize 120

* ----------------------------------------------------------------------
*! version 0.2 17Oct2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Wrapper to generate variables on the fly

cap program drop genfly
program genfly
    version 14
    _on_colon_parse `0'
    local 1 `s(after)'
    local 1_: copy local 1
    local ix 0

    * Check the parsing is OK everywhere before engaging in possibly
    * costly variable creation

    qui while ustrregexm(`"`1_'"', "\{([^{}]+?)\}") {
        tempvar v`++ix'
        local g`ix' = ustrregexs(1)
        local label = `"`=ustrregexs(1)'"'
        cap _on_colon_parse `g`ix''
        if ( _rc == 0 & `"`s(before)'"' != "" ) {
            local namelabel `s(before)'
            gettoken v`ix' label: namelabel
        }
        confirm new var `v`ix''
        local 1_ = ustrregexrf(`"`1_'"', "\{([^{}]+?)\}", `"`v`ix''"')
    }

    * Do the actual replace and variable creation

    local ix 0
    qui while ustrregexm(`"`1'"', "\{([^{}]+?)\}") {
        local g`++ix' = ustrregexs(1)
        local label = `"`=ustrregexs(1)'"'
        cap _on_colon_parse `g`ix''
        if ( _rc == 0 & `"`s(before)'"' != "" ) {
            local namelabel `s(before)'
            gettoken v`ix' label: namelabel
            local g`ix' `s(after)'
            local label `label'
        }
        gen `v`ix'' = `g`ix''
        label var `v`ix'' `"`label'"'
        local 1 = ustrregexrf(`"`1'"', "\{([^{}]+?)\}", `"`v`ix''"')
    }
    `1'
end

* ----------------------------------------------------------------------
*! version 0.2 17Oct2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Output the first observations of the dataset in memory

capture program drop head
program head
    syntax [anything] [if], [*]
    set more off
    set trace off
    if ( !`=_N > 0' ) error 2000

    * First, parse the number of lines to print. Either the first 10 or
    * the number specified by the user.

    if ( regexm(`"`anything'"', "^[ ]*([0-9]+)") ) {
        local n1 = regexs(1)
        gettoken n2 anything: anything
        cap assert `n1' == `n2'
        if ( _rc ) error 198
        local n = `n1'
    }
    else local n = 10

    * Number of rows must be positive
    if ( `n' <= 0 ) {
        disp as err "n must be > 0"
        exit 198
    }

    * Parse varlist and if condition
    local 0 `anything' `if', `options'
    syntax [varlist] [if/], [*]

    * Apply if condition then get the first n matching condition
    qui if ( "`if'" != "" ) {
        local stype = cond(`=_N' < maxlong(), "long", "double")
        tempvar touse sumtouse index
        gen byte `touse' = `if'
        gen `stype' `sumtouse' = sum(`touse')
        gen `stype' `index' = _n
        local last = `=`sumtouse'[_N]'
        if ( `n' == 1 ) {
            local ifin if (`sumtouse' == `n') & `touse' == 1
        }
        else {
            local ifin if (`sumtouse' >= 1) & (`sumtouse' <= `n') & `touse' == 1
        }
    }
    else {
        local ifin in 1 / `=min(`n', _N)'
    }

    list `varlist' `ifin', `options'
end

* ----------------------------------------------------------------------
*! version 0.2 17Oct2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Output the last observations of the dataset in memory

capture program drop tail
program tail
    syntax [anything] [if], [*]
    set more off
    set trace off
    if ( !`=_N > 0' ) error 2000

    * First, parse the number of lines to print. Either the last 10 or
    * the number specified by the user.

    if ( regexm(`"`anything'"', "^[ ]*([0-9]+)") ) {
        local n1 = regexs(1)
        gettoken n2 anything: anything
        cap assert `n1' == `n2'
        if ( _rc ) error 198
        local n = `n1'
    }
    else local n = 10

    * Number of rows must be positive
    if ( `n' <= 0 ) {
        disp as err "n must be > 0"
        exit 198
    }

    * Parse varlist and if condition
    local 0 `anything' `if', `options'
    syntax [varlist] [if/], [*]

    * Apply if condition then get the last n matching condition
    qui if ( "`if'" != "" ) {
        local stype = cond(`=_N' < maxlong(), "long", "double")
        tempvar touse sumtouse index
        gen byte `touse' = `if'
        gen `stype' `sumtouse' = sum(`touse')
        gen `stype' `index' = _n
        local last = `=`sumtouse'[_N]'
        if ( `n' == 1 ) {
            local ifin if (`sumtouse' == `last') & `touse' == 1
        }
        else {
            local f = `last' - `n'
            local ifin if (`sumtouse' >= `f') & (`sumtouse' <= `last') & `touse' == 1
        }
    }
    else {
        local ifin in -`=min(`n', _N)'/l
    }

    list `varlist' `ifin', `options'
end

* ----------------------------------------------------------------------
*! version 0.2 17Oct2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Print time-stamp with basic info about the data in memory

capture program drop timestamp
program timestamp
    local nobs: di trim("`:di %21.0fc c(N)'")
    local nvar: di trim("`:di %21.0fc c(k)'")
    local sobs = cond(`c(N)' == 1, "", "s")
    local svar = cond(`c(k)' == 1, "", "s")

    local bytes = c(width) * c(N)
    local i = 0
    while ( `bytes' > 1024 & `++i' < 4 ) {
        local bytes = `bytes' / 1024
    }

         if ( `i' == 1 ) local bsuffix bytes
    else if ( `i' == 2 ) local bsuffix KiB
    else if ( `i' == 3 ) local bsuffix MiB
    else                 local bsuffix GiB

    local bytes = trim("`:di %21.1fc `bytes'' `bsuffix'")

    display _n(1) "{hline `=min(79, c(linesize))'}"
    if (`"`0'"' != "") display `"`0'"'

    * local flavor `c(flavor)'
    * if ( `c(SE)' == 1 ) local flavor SE
    * if ( `c(MP)' == 1 ) local flavor MP
    * display "Stata/`flavor' `c(stata_version)' for `c(os)' (`c(processors)'-core `c(bit)'-bit)"

    display `"`=char(9)'Dataset:   `c(filename)'"'
    if ( `c(changed)' ) {
    display `"`=char(9)'           (not saved)"'
    }
    display  "`=char(9)'In memory: `nobs' observation`sobs'"
    display  "`=char(9)'           `nvar' variable`svar'"
    display  "`=char(9)'           `bytes'"
    display  "`=char(9)'Timestamp: `c(current_time)' `c(current_date)'"
    display  "{hline 79}" _n(1)
end

* ---------------------------------------------------------------------
* saveTable

capture program drop saveTable
program saveTable
    version 13
    syntax using/, tag(str) OUTMatrix(name) [fmt(str)]
    mata: saveTable()
end

capture mata: mata drop saveTable()
mata:
void function saveTable()
{
    real scalar i, j, fh
    real matrix outmatrix
    string scalar fmt
    outmatrix = st_matrix(st_local("outmatrix"))
    fmt = st_local("fmt")
    if ( fmt == "" ) {
        fmt = "%21.9f"
    }
    fmt = "\t" + fmt
    fh  = fopen(st_local("using"), "a")
    fwrite(fh, sprintf("%s\n", st_local("tag")))
    for(i = 1; i <= rows(outmatrix); i++) {
        for(j = 1; j <= cols(outmatrix); j++) {
            fwrite(fh, sprintf(fmt, outmatrix[i, j]))
        }
        fwrite(fh, sprintf("\n"))
    }
    fclose(fh)
}
end

capture mata: mata drop dropmissrow()
mata:
real matrix function dropmissrow(real matrix X)
{
    return(X[selectindex(rowsum(X :== .) :== 0), .])
}
end

* ---------------------------------------------------------------------
* export_latex

// JC export_latex() edit: added arguments "header" and "footer",
// created variables "head" and "foot", included lines that include 'if'
// statements involving "head" and "foot". Also, edited fh (aka the output)
// 'for' loop to be based on rows(Mfmt), instead of rows(M).

// JC I also added tabspace in front of the table for clarity in Latex output.
// (see line: row = labrow? "		" + rowlabels[i] + "&": ""

cap mata mata drop export_latex()
mata
void function export_latex(
    real matrix M,
    string scalar out,
    string vector header,
    string vector footer,
    string vector collabels,
    string vector rowlabels,
    string matrix rowformats,
    real   vector lindex,
    string vector lines)
{
    string scalar row
    string colvector Mfmt

    real scalar i, j, fh
    real scalar labrow, labcol, fmtrow, fmtcol, head, foot

    labrow = any(rowlabels  :!= "")
    labcol = any(collabels  :!= "")
    fmtrow = any(rowformats :!= "")
    fmtcol = 0
    head   = any(header :!= "")
    foot   = any(footer :!= "")

    if (labrow) {
        if (rows(M) != length(rowlabels)) {
            errprintf("Matrix had %g rows and labels had %g\n", cols(M), length(rowlabels))
            error(198)
        }
    }

    if (fmtrow) {
        if (rows(M) == length(rowformats)) {
            fmtrow = 1
            fmtcol = 0
        }
        else if (cols(M) == length(rowformats)) {
            fmtrow = 0
            fmtcol = 1
            printf("Formats interpreted as column formats\n")
        }
        else if ( (rows(M) == rows(rowformats)) & (cols(M) == cols(rowformats)) ) {
            fmtrow = 1
            fmtcol = 1
            printf("Formats interpreted as individual cell formats\n")
        }
        else {
            errprintf("Matrix had %g rows and formats had %g\n", cols(M), length(rowformats))
            error(198)
        }
    }

    if (labcol) {
        if (cols(M) != length(collabels)) {
            errprintf("Matrix had %g columns and labels had %g\n", cols(M), length(collabels))
            error(198)
        }

        row = labrow? "&": ""
        for (j = 1; j < cols(M); j++) {
            row = row + collabels[j] + "&"
        }
        row = row + collabels[j] + "\\"
    }

    Mfmt = labcol? row: J(0, 1, "")

    for(i = 1; i <= rows(M); i++) {
        row = labrow? "                " + rowlabels[i] + "&": ""
        for(j = 1; j < cols(M); j++) {
            if ( missing(M[i, j]) ) {
                row = row + "&"
            }
            else {
                if ( (fmtrow == 1) & (fmtcol == 0) ) {
                    row = row + sprintf(rowformats[i], M[i, j]) + "&"
                }
                else if ( (fmtrow == 0) & (fmtcol == 1) ) {
                    row = row + sprintf(rowformats[j], M[i, j]) + "&"
                }
                else if ( (fmtrow == 1) & (fmtcol == 1) ) {
                    row = row + sprintf(rowformats[i, j], M[i, j]) + "&"
                }
                else {
                    row = row + sprintf("%12.0g", M[i, j]) + "&"
                }
            }
        }

        if ( missing(M[i, j]) ) {
            row = row + "\\"
        }
        else {
            if ( (fmtrow == 1) & (fmtcol == 0) ) {
                row = row + sprintf(rowformats[i], M[i, j]) + "\\"
            }
            else if ( (fmtrow == 0) & (fmtcol == 1) ) {
                row = row + sprintf(rowformats[j], M[i, j]) + "\\"
            }
            else if ( (fmtrow == 1) & (fmtcol == 1) ) {
                row = row + sprintf(rowformats[i, j], M[i, j]) + "\\"
            }
            else {
                row = row + sprintf("%12.0g", M[i, j]) + "\\"
            }
        }
        Mfmt = Mfmt \ row
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

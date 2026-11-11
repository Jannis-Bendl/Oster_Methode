local 0: subinstr local 0 ";" ","
syntax, [CACHEd]

cap mkdir `"${data}/landscape"'
cap mkdir `"${data}/landscape/zip"'

***********************************************************************
*                           Landscape Files                           *
***********************************************************************

local url https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovGenIn/Downloads
local files                                                                                             ///
    2007-2012-PDP-MA-and-SNP-Landscape-Files-.zip                                                       ///
    2013-Landscape-and-Plan-and-Premium-Files-For-Medicare-Plans-Offering-Part-D-Coveragev-09-06-14.zip ///
    2014-Landscape-and-Plan-and-Premium-Files-For-Medicare-Plans-Offering-Part-D-Coverage.zip           ///
    2015-Landscape-and-Plan-and-Premium-Files-For-Medicare-Plans-Offering-Part-D-Coverage.zip           ///
    2016-Landscape-and-Plan-and-Premium-Files-For-Medicare-Plans-Offering-Part-D-Coverage.zip           ///
    2017-Landscape-and-Plan-and-Premium-Files-For-Medicare-Plans-Offering-Part-D-Coverage.zip           ///
    2018-Landscape-and-Plan-and-Premium-Information-for-Medicare-Plans-Offering-Part-D-Coverage.zip

foreach f of local files {
    disp `"landscape/zip/`f'"'
    cap confirm file `"${data}/landscape/zip/`f'"'
    if ( _rc == 0 ) {
        if ( `"`cached'"' != "" ) continue
        else erase `"${data}/landscape/zip/`f'"'
    }
    copy `url'/`f' `"${data}/landscape/zip/`f'"'
}

local CWD `"`c(pwd)'"'
cd `"${data}/landscape/zip"'
foreach f of local files {
    if ( `"`cached'"' != "" ) {
        unzipfile `"`f'"'
    }
    else {
        unzipfile `"`f'"', replace
    }
}

cd Landscape_files_07_08_09_10_11_12
foreach f in `:dir `"."' files "*zip"' {
    if ( `"`cached'"' != "" ) {
        unzipfile `"`f'"'
    }
    else {
        unzipfile `"`f'"', replace
    }
}

* 2007 - 2012
* -----------

local year 2007
cd Landscape_PDP_MA_SNP_`year'/
    local xlfile MA_SNP_Source`year'/`year' MA Landscape Source File 11-16-06.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A4) firstrow
        save `"`mafile'"', replace
    }
cd ..

local year 2008
cd Landscape_PDP_MA_SNP_`year'/
    local xlfile `year'LandscapeSourceData_MA_09_25_07.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_and_SNP_Source_`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

    local xlfile  `year'LandscapeSourceData_SNP_09_25_07.xls
    local snpfile ${data}/landscape/snp`year'.dta
    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_and_SNP_Source_`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }
cd ..

local year 2009
cd Landscape_PDP_MA_SNP_`year'/
    local xlfile `year'LandscapeSourceData_MA_11_05_08.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

    local xlfile  `year'LandscapeSourceData_SNP_11_05_08.xls
    local snpfile ${data}/landscape/snp`year'.dta
    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }
cd ..

local year 2010
cd Landscape_PDP_MA_SNP_`year'/
    local xlfile MA_SNP_Source`year'/`year'LandscapeSourceData_MA_12_01_09.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A5) firstrow sheet("MA (States N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

    local xlfile MA_SNP_Source`year'/`year'LandscapeSourceData_SNP_11_20_09.xls
    local snpfile ${data}/landscape/snp`year'.dta
    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }
cd ..

local year 2011
cd Landscape_PDP_MA_SNP_`year'/
    local xlfile MA_SNP_Source`year'/PrintReady_`year'LandscapeSourceData_MA_12_17_10.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

    local xlfile  MA_SNP_Source`year'/PrintReady_`year'LandscapeSourceData_SNP_12_17_10.xls
    local snpfile ${data}/landscape/snp`year'.dta
    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }
cd ..

local year 2012
    local xlfile `year'LandscapeSourceData_MA_3_08_12.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

    local xlfile  `year'LandscapeSourceData_SNP_3_08_12.xls
    local snpfile ${data}/landscape/snp`year'.dta
    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile MA_SNP_Source`year'.zip, replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }
cd ..

* 2013 - 2018 (MA Only)
* ---------------------

local year 2013
    local xlfile `year'LandscapeSource file MA 11212012.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"MA_Source`year' 11212012.zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

local year 2014
    local xlfile `year'LandscapeSource file MA 05292014.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' Landscape Source Files (v.09.15.15).zip"', replace
        unzipfile `"MA_Source`year' 05292014.zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        append using `"`mafile'"'
        save `"`mafile'"', replace
    }

local year 2015
    local xlfile `year'LandscapeSource file MA 03182015.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' Landscape Source Files (v 3 18 15).zip"', replace
        unzipfile `"`year' MA Landscape Source FIles (v 3 18 15).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        save `"`mafile'"', replace
    }

local year 2016
    local xlfile `year'LandscapeSource file MA 04222016.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' MA Landscape Source Files (v 04 22 16).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        save `"`mafile'"', replace
    }

local year 2017
    local xlfile `year'LandscapeSource file MA 10182016.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' MA Landscape Source Files (v 10 18 16).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        save `"`mafile'"', replace
    }

local year 2018
    local xlfile `year'LandscapeSource file MA 10142017.xls
    local mafile ${data}/landscape/ma`year'.dta

    disp `"`mafile'"'
    cap confirm file `"`mafile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' MA Landscape Source Files (v 10 14 17).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (States A to M)")
        save `"`mafile'"', replace

        import excel `"`xlfile'"', clear cellrange(A6) firstrow sheet("MA (states N to W)")
        save `"`mafile'"', replace
    }

* 2013 - 2018 (SNP Only)
* ----------------------

local year 2013
    local xlfile `year'LandscapeSource file SNP 11212012.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"SNP_Source `year' 11212012.zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

local year 2014
    local xlfile  `year'LandscapeSource file SNP 01292014.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' Landscape Source Files (v.09.15.15).zip"', replace
        unzipfile `"SNP_Source`year' 01292014.zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

local year 2015
    local xlfile  `year'LandscapeSource file SNP 11042014.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' Landscape Source Files (v 3 18 15).zip"', replace
        unzipfile `"`year' SNP Landscape Source FIles (v 11 04 14).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

local year 2016
    local xlfile `year'LandscapeSource file SNP04222016.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' SNP Landscape Source Files (v 04 22 16).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

local year 2017
    local xlfile `year'LandscapeSource file SNP10182016.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' SNP Landscape Source Files (v 10 18 16).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

local year 2018
    local xlfile `year'LandscapeSource file SNP 10142017.xls
    local snpfile ${data}/landscape/snp`year'.dta

    disp `"`snpfile'"'
    cap confirm file `"`snpfile'"'
    if ( _rc | (`"`cached'"' == "") ) {
        unzipfile `"`year' SNP Landscape Source Files (v 10 14 17).zip"', replace
        import excel `"`xlfile'"', clear cellrange(A5) firstrow
        save `"`snpfile'"', replace
    }

* Concatenate
* -----------

cd `"`CWD'"'
cap confirm file `"${data}/landscape/ma.dta"'
if ( _rc | (`"`cached'"' == "") ) {
    tempfile ma
    forvalues year = 2007 / 2018 {
        use `"${data}/landscape/ma`year'"', clear
        gduplicates drop
        rename *, lower
        gen long year = `year'
        if ( `year' > 2007 ) append using `"`ma'"'
        save `"`ma'"', replace
    }

    use `"`ma'"', clear
    cap drop O
    cap drop P
    cap drop o
    cap drop p
    foreach var of varlist * {
        label var `var' `"`=ustrregexra(`"`:var label `var''"', "\s+", " ")'"'
    }
    gisid state county contractid planid year, missok
    save `"${data}/landscape/ma.dta"', replace
}

cd `"`CWD'"'
cap confirm file `"${data}/landscape/snp.dta"'
if ( _rc | (`"`cached'"' == "") ) {
    tempfile snp
    forvalues year = 2008 / 2018 {
        use `"${data}/landscape/snp`year'"', clear
        gduplicates drop
        rename *, lower
        cap drop cardiovasculardisorders*
        gen long year = `year'
        if ( `year' > 2008 ) append using `"`snp'"'
        save `"`snp'"', replace
    }

    use `"`snp'"', clear
    foreach var of varlist * {
        label var `var' `"`=ustrregexra(`"`:var label `var''"', "\s+", " ")'"'
    }

    gisid state county contractid planid year, missok
    save `"${data}/landscape/snp.dta"', replace
}

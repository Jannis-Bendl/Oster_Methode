local 0: subinstr local 0 ";" ","
syntax, [CACHEd]

cap mkdir `"${data}/mlr"'
cap mkdir `"${data}/mlr/zip"'

***********************************************************************
*                                 MLR                                 *
***********************************************************************

local url https://www.cms.gov/CCIIO/Resources/Data-Resources/Downloads/
local files mlr_datafilespuf_20121127.zip

foreach f of local files {
    disp `"mlr/zip/`f'"'
    cap confirm file `"${data}/mlr/zip/`f'"'
    if ( _rc == 0 ) {
        if ( `"`cached'"' != "" ) continue
        else erase `"${data}/mlr/zip/`f'"'
    }
    copy `url'/`f' `"${data}/mlr/zip/`f'"'
}

local CWD `"`c(pwd)'"'
cd `"${data}/mlr/zip"'
foreach f of local files {
    if ( `"`cached'"' != "" ) {
        unzipfile `"`f'"'
    }
    else {
        unzipfile `"`f'"', replace
    }
}

* 2011
* ----

* NOTE: Adapted code from Any

* Submission Header
import delimited "MR_Submission_Template_Header.csv", clear
cap rename ïmr_submission_template_id mr_submission_template_id
tempfile f_2011_MR_Header
save "`f_2011_MR_Header'", replace

* Submission part 5
import delimited "MR_Submission_Template_Part5.csv", clear
cap rename ïmr_submission_template_id mr_submission_template_id
tempfile f_2011_MR_Part5
save "`f_2011_MR_Part5'", replace

* Submission part 1 & 2
import delimited "MR_Submission_Template_Part1_2.csv", clear
    cap rename ïmr_submission_template_id mr_submission_template_id
    gen part = "Prem_Claims"
    append using "`f_2011_MR_Part5'"
    replace part = "MLR Calc" if mi(part)
tempfile f_2011_MR_Part1_2_5
save "`f_2011_MR_Part1_2_5'", replace

* Combine into one dataset
use "`f_2011_MR_Header'", clear
	merge 1:m mr_submission_template_id using "`f_2011_MR_Part1_2_5'", assert(3) nogen
	sort business_state company_name
	order business_state company_name row_lookup_code
	gen year = 2011
save "${data}/mlr/2011.dta", replace

cd `"`CWD'"'

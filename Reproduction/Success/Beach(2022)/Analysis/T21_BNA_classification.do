import excel "$data_dir/England_and_Wales/BNA_Index.xlsx", sheet("main") firstrow case(lower) clear



replace classification="Reporting on the trial – regular articles" if classification=="trial" & length=="full"
replace classification="Reporting on the trial – short snippets" if classification=="trial" & length=="short"
replace classification="Reporting on the trial – long articles" if classification=="trial" & length=="long"


replace classification="Meetings, lectures, Malthusian League" if inlist(classification,"meeting","lecture_by_besant","lecture_by_bradlaugh","lecture_by_drysdale","malthusian")
replace classification="Opinion and commentary" if inlist(classification,"opinion","letter")
replace classification="Post Office controversy" if classification=="post_office"
replace classification="Besant biographical" if classification=="besant_bio"
replace classification="Related to books/pamphlet sales" if classification=="book_sales"
replace classification="Priests of Absolution controversy" if classification=="priests"
replace classification="Related to Dr. Kenealy’s public plea" if classification=="kenealy"
replace classification="Related to the Burial Bill controversy" if classification=="burial_bill"
replace classification="Reviews of important events in the year" if classification=="annual_review"
replace classification="Truelove prosecution" if classification=="truelove"
replace classification="Articles in Welsh" if classification=="welsh"
replace classification="Articles in Welsh" if classification=="welsh"
replace classification="Bradlaugh’s candidacy for parliament" if classification=="bradlaugh_candidacy"
replace classification="Petition to the House of Commons" if inlist(classification,"petition_to_parliament","commons_petition")
replace classification="Miscellaneous" if inlist(classification,"other","poem","funding")

gen articles=1

collapse (sum) articles, by(classification)

egen tot_articles=total(articles) 

gen share=round((articles/tot_articles)*1000)
replace share=share/10

gsort -share

gen order_var=[_n]

replace order_var=2.5 if classification=="Reporting on the trial – long articles"
replace order_var=18 if classification=="Miscellaneous"

sort order_var

keep classification articles share

cd "$results"
texsave using "T21_BNA_classification", replace

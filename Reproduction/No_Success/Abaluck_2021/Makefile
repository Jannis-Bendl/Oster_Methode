ARGS=
TAG=
OPTS_FOLDER=
PCT=
PRE=
SAMPLE=SampleSelection6
STATA=stata16-mp

## 00 Download raw data
00download:
	nohup $(STATA) -b do 00download/main.do

## 00 Helper files
00auxfiles:
	nohup $(STATA) -b do 00auxfiles/main.do

## 01 Query Denominator
01get:
	nohup sas -encoding latin1 01get/main.sas

## 02 Clean Denominator Queries
02clean:
	nohup $(STATA) -b do 02clean/main.do

## 03 Generate IV sample
03ivSample:
	nohup $(STATA) -b do 03ivSample/main.do

## 04 Run regressions, plots (options REQUIRED)
04analysis:
	nohup $(STATA) -b do "04analysis/main.do $(SAMPLE); $(ARGS) optsFolder($(OPTS_FOLDER)) tag($(TAG))"

## 05 Export regression, balance, fallback balance output (options REQUIRED)
05output:
	nohup $(STATA) -b do "05output/main.do $(SAMPLE); $(ARGS) optsFolder($(OPTS_FOLDER)) tag($(TAG))"

## 06 Run simulations
06simulations:
	nohup $(STATA) -b do "06simulations/main.do $(SAMPLE); optsFolder($(OPTS_FOLDER)) tag($(TAG))"

## 99 Post-shrinkage
99post_shrinkage:
	nohup $(STATA) -b do "99adHoc/allPlans_post_new_shrinkage.do $(SAMPLE); $(ARGS) optsFolder($(OPTS_FOLDER)) tag($(TAG))"

#######################################################################
#                                                                     #
#                         Tables and Figures                          #
#                                                                     #
#######################################################################

## Create Table 1 .tex file (options REQUIRED)
## example: make table1 PCT="100" PRE="_19" &
table1:
	nohup $(STATA) -b do "05output/paper/table1.do; pct($(PCT)) pre($(PRE))"

## Create Table 2 .tex file (options REQUIRED)
## example: make table2 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
table2:
	nohup $(STATA) -b do "05output/paper/table2.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Table 3 .tex file (options REQUIRED)
## example: make table3 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
table3:
	nohup $(STATA) -b do "05output/paper/table3.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Table 4 .tex file (options REQUIRED)
## example: make table4 PCT="100" OPTS_FOLDER="PlanCharsRegressions" &
table4:
	nohup $(STATA) -b do "05output/paper/table4.do; pct($(PCT)) optsFolder($(OPTS_FOLDER)) $(ARGS)"

## Create Table 5 .tex file (options REQUIRED)
## example: make table5 PCT="100" OPTS_FOLDER="PlanCharsRegressions" &
table5:
	nohup $(STATA) -b do "05output/paper/table5.do; pct($(PCT)) optsFolder($(OPTS_FOLDER)) $(ARGS)"

## Create Figure 1 (options REQUIRED)
## example: make figure1 PCT="100" PRE="_19" &
figure1:
	nohup $(STATA) -b do "05output/paper/figure1.do; pct($(PCT)) pre($(PRE))"

#######################################################################
#                                                                     #
#                              Appendix                               #
#                                                                     #
#######################################################################

## Create Table A3 .tex file (options REQUIRED)
## example: make tableA3 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
tableA3:
	nohup $(STATA) -b do "05output/paper/tableA3.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Table A4 .tex file (options REQUIRED)
## example: make tableA4 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
tableA4:
	nohup $(STATA) -b do "05output/paper/tableA4.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Oster forecast coef sensitivity to OVB .tex file (options REQUIRED)
## example: make osterOVB PCT="100" &
osterOVB:
	nohup $(STATA) -b do "05output/paper/osterOVB.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Table A6 .tex file (options REQUIRED)
## example: make tableA6 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
tableA6:
	nohup $(STATA) -b do "05output/paper/tableA6.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Table A7 .tex file (options REQUIRED)
## example: make tableA7 PCT="100" OPTS_FOLDER="BaselineStuff-take4" &
tableA7:
	nohup $(STATA) -b do "05output/paper/tableA7.do; pct($(PCT)) optsFolder($(OPTS_FOLDER))"

## Create Figure A2
## example: make figureA2 PCT="100" PRE="_19" &
figureA2:
	nohup $(STATA) -b do "05output/paper/figureA2.do; pct($(PCT)) pre($(PRE))"

## Create Figure A5
## example: make figureA5 PCT="100" PRE="_19" &
figureA5:
	nohup $(STATA) -b do "05output/paper/figureA5.do; pct($(PCT)) pre($(PRE))"

#######################################################################
#                                                                     #
#                    Self-Documenting Foo (Ignore)                    #
#                                                                     #
#######################################################################

.DEFAULT_GOAL := show-help

.PHONY: show-help 2019-04-24-presentation 2019-06-21-submission 00download 00auxfiles 01get 02clean 03ivSample 04analysis 05output 06simulations preRegression
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=23 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

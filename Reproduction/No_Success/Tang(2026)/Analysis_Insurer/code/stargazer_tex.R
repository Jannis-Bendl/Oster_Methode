### Output to Tex
library(stargazer)

data_parameters = data.frame(Parameter=c("TEXtau",
                                         "TEXkappa_h",
                                         "TEXp_default",
                                         "TEXomega",
                                         "TEXtau_direct_premiums",
                                         "TEXV"),
                             Value=c(1,2,3,4,5,6))

stargazer_tex <- function(x, out=NULL, ...){
  out = gsub("TEXtau", "\tau", stargazer(x, ...))
  out = gsub("TEXR_f", "R\\_\\{f\\}", out)
  out = gsub("TEXkappa_h", "\\kappa\\_\\{h\\}", out)
  out = gsub("TEXp_default", "P(Default|Impairment)", out)
  out = gsub("TEXomega", "\\omega", out)
  return(out)
}

stargazer_tex(data_parameters,
              summary = FALSE,
              style="aer",
              omit.table.layout = "n",
              median=TRUE,
              float=FALSE,rownames=FALSE,digits=4, digits.extra=4,
              no.space = TRUE,
              out = "output/summary_stats/parameters.tex")

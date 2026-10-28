library(arrow)
library(tidyverse)

setwd("C:/Users/jabef/Desktop/FU Job/Prof.Marcus/Python_Scraper/literature_review_oster")

test <- read.csv("data/multi_source_papers_2019_2021.csv")

test <- test |> 
  relocate(authors, .after = title)
no_AEJ <- read.csv("List_Oster_Method.csv")

test_AEJ <- test

test_AEJ$uses_Oster_method <- c(1,1,1,1,1,0,0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1)
test_AEJ$code_available <- 1
test_AEJ$data_available <- c(0,0,1,1,0,0,0,1,0,1,0,0,1,1,0,0,0,1,0,1,0,0,0,0,1,0,0)

test_AEJ$next_round <- ifelse(test_AEJ$uses_Oster_method == 1 &
                              test_AEJ$code_available == 1 &
                              test_AEJ$data_available == 1,
                              1,0)

no_AEJ <- no_AEJ[,colnames(test_AEJ)]

List_Oster_Method <- rbind(no_AEJ, test_AEJ)

write.csv(List_Oster_Method, "List_Oster_Method.csv")


test_vertor <- List_Oster_Method[,starts_with("o")]

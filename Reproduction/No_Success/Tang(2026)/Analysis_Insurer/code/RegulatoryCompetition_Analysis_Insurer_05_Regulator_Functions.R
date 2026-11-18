### Global
source("../lib/r/Functions.R")
compare_welfare <- function(data_input,year_compare=2019,level="federal",change="percent"){
  if (level == "federal"){
    data_federalyr <- data_input
    data_federalyr_actual_welfare <- data_federalyr_actual
    names(data_federalyr_actual_welfare)[which(!grepl("Year",names(data_federalyr_actual_welfare)))] <- paste0("Actual ",names(data_federalyr_actual_welfare)[which(!grepl("Year",names(data_federalyr_actual_welfare)))])
  }
  if (level == "state"){
    data_stateyr_federal_all <- data_input
    data_stateyr_actual_welfare <- data_stateyr_actual
  }
  
  
  if (level == "federal"){
    data_federalyr_with_actuals <- merge(data_federalyr,data_federalyr_actual_welfare,by=c("Year"),all.x=TRUE)
  }
  if (level == "state"){
    data_stateyr_with_actuals <- merge(data_stateyr_federal_all,data_stateyr_actual_welfare,by=c("state","year"),all.x=TRUE)
  }
  
  if (level == "federal"){
    compare_vars_all <- names(data_federalyr)[which(!grepl("Scenario|Year",names(data_federalyr)))]
    for (compare_var in compare_vars_all){
      compare_var_change = paste0(compare_var," Change")
      compare_var_actual = paste0("Actual ",compare_var)
      if (change == "percent"){
        data_federalyr_with_actuals[[compare_var_change]] <- pmax(round((data_federalyr_with_actuals[[compare_var]] - data_federalyr_with_actuals[[compare_var_actual]])/abs(data_federalyr_with_actuals[[compare_var_actual]])*100,digits=2),-100)
      }
      if (change == "levels"){
        data_federalyr_with_actuals[[compare_var_change]] <- round((data_federalyr_with_actuals[[compare_var]] - data_federalyr_with_actuals[[compare_var_actual]]),digits=2)
        
        if (compare_var == "Price"){
          data_federalyr_with_actuals[[compare_var_change]] <- round((data_federalyr_with_actuals[[compare_var]] - data_federalyr_with_actuals[[compare_var_actual]]) * 1000,digits=2)
        }
        if (compare_var == "Quantity"){
          data_federalyr_with_actuals[[compare_var_change]] <- round((data_federalyr_with_actuals[[compare_var]] - data_federalyr_with_actuals[[compare_var_actual]]) * 1000,digits=2)
        }
      }
    }
  }
  if (level == "state"){
    compare_vars_all <- c("stateyr_default_expected_loss","default_prob",
                          "stateyr_util_mean","price_mean","quantities_stateyeartype","stateyr_util_total","stateyr_profit","stateyr_guaranty",
                          "amount_reinsured_estimated","stateyr_tax_revenue")
    for (compare_var in compare_vars_all){
      compare_var_change = paste0(compare_var,"_change")
      compare_var_actual = paste0(compare_var,"_actual")
      if (change == "percent"){
        data_stateyr_with_actuals[[compare_var_change]] <- pmax(round((data_stateyr_with_actuals[[compare_var]] - data_stateyr_with_actuals[[compare_var_actual]])/abs(data_stateyr_with_actuals[[compare_var_actual]])*100,digits=2),-100)
      }
      if (change == "levels"){
        data_stateyr_with_actuals[[compare_var_change]] <- round(data_stateyr_with_actuals[[compare_var]] - data_stateyr_with_actuals[[compare_var_actual]],digits=2)
        
        if (compare_var == "price_mean"){
          data_stateyr_with_actuals[[compare_var_change]] <- round((data_stateyr_with_actuals[[compare_var]] - data_stateyr_with_actuals[[compare_var_actual]]) * 1000,digits=2)
        }
        if (compare_var == "quantities_stateyeartype"){
          data_stateyr_with_actuals[[compare_var_change]] <- round((data_stateyr_with_actuals[[compare_var]] - data_stateyr_with_actuals[[compare_var_actual]]) * 1000,digits=2)
        }
      }
    }
  }
  
  if (level == "federal"){
    vars_keep <- names(data_federalyr_with_actuals)[which(grepl("Year|Scenario|Change",names(data_federalyr_with_actuals)))]
    data_federalyr_with_actuals <- as.data.table(data_federalyr_with_actuals)[,..vars_keep]
  }
  if (level == "state"){
    vars_keep <- names(data_stateyr_with_actuals)[which(grepl("^year$|^scenario$|_change|^state$",names(data_stateyr_with_actuals)))]
    data_stateyr_with_actuals <- as.data.table(data_stateyr_with_actuals)[,..vars_keep]
  } 
  
  if (level == "federal"){
    data_federalyr_1yr <- data_federalyr_with_actuals[which(data_federalyr_with_actuals$Year == year_compare),]
    data_federalyr_1yr <- data_federalyr_1yr[,Year:=NULL]
  }
  if (level == "state"){
    data_stateyr_1yr <- data_stateyr_with_actuals[which(data_stateyr_with_actuals$year == year_compare),]
    data_stateyr_1yr <- data_stateyr_1yr[,year:=NULL]
  }
  
  if (level == "federal"){
    output_list <- list(data_federalyr_with_actuals,
                        data_federalyr_1yr) 
  }
  if (level == "state"){
    output_list <- list(data_stateyr_with_actuals,
                        data_stateyr_1yr)
  }
  return(output_list)
}

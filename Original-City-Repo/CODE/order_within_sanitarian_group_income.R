##==============================================================================
## INITIALIZE
##==============================================================================
## Remove all objects; perform garbage collection
rm(list=ls())
gc(reset=TRUE)

## Load libraries that are used
geneorama::loadinstall_libraries(c("data.table", "glmnet", "ggplot2", "ROCR"))
## Load custom functions
geneorama::sourceDir("CODE/functions/")
library(dplyr)

##==============================================================================
## MY FUNCTIONS
##==============================================================================

mymax <- function(...,def=as.IDate("2019-09-05"),na.rm=FALSE)
    if(!is.infinite(x<-suppressWarnings(max(...,na.rm=na.rm)))) x else def

mymin <- function(...,def=as.IDate("2019-09-05"),na.rm=FALSE)
    if(!is.infinite(x<-suppressWarnings(min(...,na.rm=na.rm)))) x else def

##==============================================================================
## LOAD CACHED RDS FILES
##==============================================================================

sanitarian_clusters <- c("blue", "orange", "brown", "yellow", "green","purple")
race_ethnicity <- c("White", "Black", "Asian", "Hispanic", "American_Indian", "Others")
racewise_date_diff_colnames <- c("date_difference_white", "date_difference_black", 
                                 "date_difference_asian", "date_difference_hispanic", 
                                 "date_difference_american_indian", "date_difference_others")

original_model <- "DATA/30_dat.Rds"
absolute_mode <- 1

test_window_range = c(0:18)

income_lvl1_model <- vector(mode="double")
income_lvl2_model <- vector(mode="double")
income_lvl3_model <- vector(mode="double")
income_lvl4_model <- vector(mode="double")
income_lvl5_model <- vector(mode="double")
income_lvl6_model <- vector(mode="double")
income_lvl7_model <- vector(mode="double")

income_lvl1_default <- vector(mode="double")
income_lvl2_default <- vector(mode="double")
income_lvl3_default <- vector(mode="double")
income_lvl4_default <- vector(mode="double")
income_lvl5_default <- vector(mode="double")
income_lvl6_default <- vector(mode="double")
income_lvl7_default <- vector(mode="double")

category_name <- "Per_Capita_Income_Federal"
# category_name <- "Per_Capita_Income_Uniform"

if (category_name == "Per_Capita_Income_Federal") {
    lvl1_str = "<15K"
    lvl2_str = "15K-55K"
    lvl3_str = "55K-90K"
    lvl4_str = ">90K"
} else {
    lvl1_str = "<20K"
    lvl2_str = "20K-40K"
    lvl3_str = "40K-60K"
    lvl4_str = "60K-80K"
    lvl5_str = "80K-100K"
    lvl6_str = "100K-120K"
    lvl7_str = ">120K"
}


for (window_split in test_window_range) {
    # >>>>>>> start block for non-color model stats >>>>>>>>>>>
    moving_test_window_dat <- paste("moving_test_window_income/30_dat_",window_split,".Rds",
    sep = "")
    # moving_test_window_dat <- paste("no_sanitarians_data/30_dat_ns_",window_split,".Rds", sep = "")
    # moving_test_window_dat <- paste("suppressed_sanitarian_features/30_dat_",window_split,".Rds", sep = "")
    
    dat <- readRDS(moving_test_window_dat)
    datTest <- dat[Test == TRUE]        # Test Data (Originally )
    datNotTest <- dat[Test == FALSE]    # Data used to predict
    # <<<<<<< end this block for non-color model stats <<<<<<<<<
    
    
    # double-check the original speed-up
    cat("\n\n")
    sanitarian_dat <- datTest
    sanitarian_dat <- sanitarian_dat[
        order(-glm_pred_test), simulated_date := 
            sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
    if (!absolute_mode) {
        sanitarian_dat <- sanitarian_dat[, date_difference := Inspection_Date - simulated_date][]
    } else {
        latest_date <- mymax(sanitarian_dat[order(simulated_date), simulated_date])
        earliest_date <- mymin(sanitarian_dat[order(simulated_date), simulated_date])
        
        sanitarian_dat <- sanitarian_dat[, date_difference := 
                                             (simulated_date - earliest_date)]
    }
    cat("original model sum of date differences: ", sum(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    cat("original model mean of date differences: ", mean(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    cat("original model num of rows with violation: ", nrow(sanitarian_dat[criticalFound == 1]), "\n\n")
    
    #group by income category and keep appending to the lists
    diff_by_income <- sanitarian_dat[criticalFound == 1 ,list(mean_diff=mean(date_difference)), 
                                     by=category_name]
    print(diff_by_income)
    income_lvl1_model <<- c(income_lvl1_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl1_str, mean_diff])
    income_lvl2_model <<- c(income_lvl2_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl2_str, mean_diff])
    income_lvl3_model <<- c(income_lvl3_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl3_str, mean_diff])
    income_lvl4_model <<- c(income_lvl4_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl4_str, mean_diff])
    if (category_name != "Per_Capita_Income_Federal") {
        income_lvl5_model <<- c(income_lvl5_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl5_str, mean_diff])
        income_lvl6_model <<- c(income_lvl6_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl6_str, mean_diff])
        income_lvl7_model <<- c(income_lvl7_model, diff_by_income[eval(parse(text=paste0(category_name)))==lvl7_str, mean_diff])
    }
    
    # calculation under original ordering
    if (absolute_mode) {
        cat("\n")
        sanitarian_dat <- datTest
        sanitarian_dat <- sanitarian_dat[
            order(-glm_pred_test), simulated_date := 
                sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
        latest_date <- mymax(sanitarian_dat[order(Inspection_Date), Inspection_Date])
        earliest_date <- mymin(sanitarian_dat[order(Inspection_Date), Inspection_Date])
        
        sanitarian_dat <- sanitarian_dat[, date_difference := 
                                             (Inspection_Date - earliest_date)]
        cat("default ordering sum of date differences: ", sum(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
        cat("default ordering  mean of date differences: ", mean(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
        cat("default ordering  num of rows with violation: ", nrow(sanitarian_dat[criticalFound == 1]), "\n\n")
        
        #group by income category and keep appending to the lists
        diff_by_income <- sanitarian_dat[criticalFound == 1 ,list(mean_diff=mean(date_difference)), 
                                          by=category_name]
        print(diff_by_income)
        income_lvl1_default <<- c(income_lvl1_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl1_str, mean_diff])
        income_lvl2_default <<- c(income_lvl2_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl2_str, mean_diff])
        income_lvl3_default <<- c(income_lvl3_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl3_str, mean_diff])
        income_lvl4_default <<- c(income_lvl4_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl4_str, mean_diff])
        if (category_name != "Per_Capita_Income_Federal") {
            income_lvl5_default <<- c(income_lvl5_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl5_str, mean_diff])
            income_lvl6_default <<- c(income_lvl6_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl6_str, mean_diff])
            income_lvl7_default <<- c(income_lvl7_default, diff_by_income[eval(parse(text=paste0(category_name)))==lvl7_str, mean_diff])
        }
    }
    
    newdf_model <- data.frame(income_lvl1_model, income_lvl2_model, income_lvl3_model, 
                        income_lvl4_model, stringsAsFactors = FALSE)
    newdf_default <- data.frame(income_lvl1_default, income_lvl2_default, income_lvl3_default, 
                              income_lvl4_default, stringsAsFactors = FALSE)
    if (category_name != "Per_Capita_Income_Federal") {
        newdf_model <- data.frame(income_lvl1_model, income_lvl2_model, income_lvl3_model, 
                                  income_lvl4_model, income_lvl5_model, income_lvl6_model, income_lvl7_model, 
                                  stringsAsFactors = FALSE)
        newdf_default <- data.frame(income_lvl1_default, income_lvl2_default, income_lvl3_default, 
                                    income_lvl4_default, income_lvl5_default, income_lvl6_default, income_lvl7_default, 
                                    stringsAsFactors = FALSE)
    }
    # write.csv(newdf, paste("moving_test_window/",window_split,"_window.csv", sep = ""), row.names=FALSE)
    # write.csv(newdf, paste("no_sanitarians_data/ns_",window_split,"_window.csv", sep = ""), row.names=FALSE)
    # write.csv(newdf, paste("cluster_models/",window_split,"_window.csv", sep = ""), row.names=FALSE)
    # write.csv(newdf, paste("suppressed_sanitarian_features/",window_split,"_window.csv", sep = ""), row.names=FALSE)
}

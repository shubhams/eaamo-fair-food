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
## LOAD CACHED RDS FILES
##==============================================================================

colors <- c("orange", "brown", "yellow", "green", "purple")

dat <- readRDS(paste("cluster_models/30_dat_","blue",".Rds", sep = ""))
datTest <- dat[Test == TRUE]
datTest <- datTest[order(-glm_pred_test), simulated_date := datTest[order(Inspection_Date), Inspection_Date]][]
datTest <- datTest[, date_difference := Inspection_Date - simulated_date][]

for (color in colors) {
    dat <- readRDS(paste("cluster_models/30_dat_",color,".Rds", sep = ""))
    datT <- dat[Test == TRUE]
    datT <- datT[order(-glm_pred_test), simulated_date := datT[order(Inspection_Date), Inspection_Date]][]
    datT <- datT[, date_difference := Inspection_Date - simulated_date][]
    datTest <- rbind(datTest, datT)
}

##==============================================================================
## MODEL EVALUATION
##    - TIME SAVINGS
##    - PERIOD A vs PERIOD B
##==============================================================================
## Subset of just observations during test period:

race_ethnicity <- c("White", "Black", "American_Indian", "Asian", "Hispanic", "Others")

print(mean(datTest[criticalFound == 1, date_difference]))

calc_demographic_date_diff <- function(df, og_col_name, new_col_name) {
    # df <- df[, eval(new_col_name) := eval(og_col_name) * date_difference][]
    df[[new_col_name]] <- df[[og_col_name]] * df$date_difference
    return(df)
}

print_demographic_date_diff <- function(df, og_col_name, date_diff_col_name) {
    df <- df[criticalFound == 1]
    print(nrow(df))
    # demographic_sum = df[criticalFound == 1, sum(eval(og_col_name), na.rm = TRUE)]
    demographic_sum = sum(df[[og_col_name]], na.rm = TRUE)
    # date_difference_demographic_sum = df[criticalFound == 1, sum(eval(date_diff_col_name), na.rm = TRUE)]
    date_difference_demographic_sum = sum(df[[date_diff_col_name]], na.rm = TRUE)
    cat(og_col_name, "\n")
    cat("sum: ", demographic_sum, ", date difference: ",
        date_difference_demographic_sum, ", date difference mean: ",
        date_difference_demographic_sum/demographic_sum, "\n\n")
}


##==============================================================================
## Race and Ethnic Differences
##==============================================================================
print("Race and Ethnic Differences")

datTest <- calc_demographic_date_diff(datTest, "White", "date_difference_white")
datTest <- calc_demographic_date_diff(datTest, "Black", "date_difference_black")
datTest <- calc_demographic_date_diff(datTest, "Asian", "date_difference_asian")
datTest <- calc_demographic_date_diff(datTest, "Hispanic", "date_difference_hispanic")
datTest <- calc_demographic_date_diff(datTest, "American_Indian", "date_difference_american_indian")
datTest <- calc_demographic_date_diff(datTest, "Others", "date_difference_others")

# print_demographic_date_diff(datTest, quote(White), quote(date_difference_white))
# print_demographic_date_diff(datTest, quote(Black), quote(date_difference_black))
print_demographic_date_diff(datTest, "White", "date_difference_white")
print_demographic_date_diff(datTest, "Black", "date_difference_black")
print_demographic_date_diff(datTest, "Asian", "date_difference_asian")
print_demographic_date_diff(datTest, "Hispanic", "date_difference_hispanic")
print_demographic_date_diff(datTest, "American_Indian", "date_difference_american_indian")
print_demographic_date_diff(datTest, "Others", "date_difference_others")


##==============================================================================
## Age and Gender Differences
##==============================================================================
print("Age and Gender Differences")

datTest <- calc_demographic_date_diff(datTest, "Total_Male", "date_difference_male")
datTest <- calc_demographic_date_diff(datTest, "Total_Female", "date_difference_female")

datTest <- calc_demographic_date_diff(datTest, "All_Under_18", "date_difference_under_18")
datTest <- calc_demographic_date_diff(datTest, "All_Under_50", "date_difference_under_50")
datTest <- calc_demographic_date_diff(datTest, "All_50_And_Above", "date_difference_50_and_above")


print_demographic_date_diff(datTest, "Total_Male", "date_difference_male")
print_demographic_date_diff(datTest, "Total_Female", "date_difference_female")

print_demographic_date_diff(datTest, "All_Under_18", "date_difference_under_18")
print_demographic_date_diff(datTest, "All_Under_50", "date_difference_under_50")
print_demographic_date_diff(datTest, "All_50_And_Above", "date_difference_50_and_above")

##==============================================================================
## INITIALIZE
##==============================================================================
## Remove all objects; perform garbage collection
rm(list=ls())
gc(reset=TRUE)

## Load libraries & project functions
geneorama::loadinstall_libraries(c("data.table", "glmnet"))
geneorama::sourceDir("CODE/functions/")

##==============================================================================
## LOAD CACHED RDS FILES
##==============================================================================
dat <- readRDS("DATA/30_dat.Rds")

## Subset of just observations during test period:
datTest <- dat[Test == TRUE]
# datTest <- datTest[order(Inspection_Date)]
latest_date <- max(datTest[order(Inspection_Date), Inspection_Date])
earliest_date <- min(datTest[order(Inspection_Date), Inspection_Date])

# datTest <- datTest[, Relative_Inspection_Day := (Inspection_Date - latest_date) + (latest_date - earliest_date)]
datTest <- datTest[, Relative_Inspection_Day := (Inspection_Date - earliest_date)]

cat("Relative date difference: ", latest_date - earliest_date, "\n")
cat("Mean date difference: ", mean(datTest[criticalFound == 1, Relative_Inspection_Day]), "\n")
cat("Standar Deviation date difference: ", sd(datTest[criticalFound == 1, Relative_Inspection_Day]), "\n")

calc_demographic_date_diff <- function(df, og_col_name, new_col_name, date_col) {
    df[[new_col_name]] <- df[[og_col_name]] * df[[date_col]]
    return(df)
}

print_demographic_date_diff <- function(df, og_col_name, date_diff_col_name) {
    df <- df[criticalFound == 1]
    demographic_sum <- sum(df[[og_col_name]], na.rm = TRUE)
    inspection_day_demographic_sum <- sum(df[[date_diff_col_name]], na.rm = TRUE)
    cat(og_col_name, "\n")
    cat("sum: ", demographic_sum, ", relative inspection day: ",
        inspection_day_demographic_sum, ", date difference mean: ",
        inspection_day_demographic_sum/demographic_sum, "\n\n")
}


datTest <- calc_demographic_date_diff(datTest, "White", 
                                      "Inspection_Day_White", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "Black", 
                                      "Inspection_Day_Black", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "Asian", 
                                      "Inspection_Day_Asian", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "Hispanic", 
                                      "Inspection_Day_Hispanic", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "American_Indian", 
                                      "Inspection_Day_American_Indian", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "Others", 
                                      "Inspection_Day_Others", 
                                      "Relative_Inspection_Day")


datTest <- calc_demographic_date_diff(datTest, "Total_Male", 
                                      "Inspection_Day_Male", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "Total_Female", 
                                      "Inspection_Day_Female", 
                                      "Relative_Inspection_Day")


datTest <- calc_demographic_date_diff(datTest, "All_Under_18", 
                                      "Inspection_Day_Under_18", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "All_Under_50", 
                                      "Inspection_Day_Under_50", 
                                      "Relative_Inspection_Day")
datTest <- calc_demographic_date_diff(datTest, "All_50_And_Above", 
                                      "Inspection_Day_50_And_Above", 
                                      "Relative_Inspection_Day")


print_demographic_date_diff(datTest, "White", 
                            "Inspection_Day_White")
print_demographic_date_diff(datTest, "Black", 
                            "Inspection_Day_Black")
print_demographic_date_diff(datTest, "Asian", 
                            "Inspection_Day_Asian")
print_demographic_date_diff(datTest, "Hispanic", 
                            "Inspection_Day_Hispanic")
print_demographic_date_diff(datTest, "American_Indian", 
                            "Inspection_Day_American_Indian")
print_demographic_date_diff(datTest, "Others", 
                            "Inspection_Day_Others")


print_demographic_date_diff(datTest, "Total_Male", 
                            "Inspection_Day_Male")
print_demographic_date_diff(datTest, "Total_Female", 
                            "Inspection_Day_Female")


print_demographic_date_diff(datTest, "All_Under_18", 
                            "Inspection_Day_Under_18")
print_demographic_date_diff(datTest, "All_Under_50", 
                            "Inspection_Day_Under_50")
print_demographic_date_diff(datTest, "All_50_And_Above", 
                            "Inspection_Day_50_And_Above")

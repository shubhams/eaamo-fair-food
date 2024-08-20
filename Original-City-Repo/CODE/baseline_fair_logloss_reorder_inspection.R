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

# multiply date difference with the race proportion
calc_demographic_date_diff <- function(df, og_col_name, new_col_name) {
    df[[new_col_name]] <- df[[og_col_name]] * df$date_difference
    return(df)
}

# function to print and calculate demographic gains
print_demographic_date_diff <- function(df, og_col_name, date_diff_col_name, row) {
    demographic_sum <- sum(df[[og_col_name]], na.rm = TRUE)
    date_difference_demographic_sum <- sum(df[[date_diff_col_name]], na.rm = TRUE)
    
    color_cluster_list <<- c(color_cluster_list, row[1])
    mean_gain_list <<- c(mean_gain_list, row[2])
    violation_found_list <<- c(violation_found_list, row[3])
    demographic_list <<- c(demographic_list, og_col_name)
    demographic_sums <<- c(demographic_sums, demographic_sum)
    demographic_gain_list <<- c(demographic_gain_list, 
                                date_difference_demographic_sum/demographic_sum)
    
    row <- c(row, og_col_name, date_difference_demographic_sum/demographic_sum)
    # print(row)
}

print_color_violation_time <- function(df, color_col_name, row) {
    color_cluster_list <<- c(color_cluster_list, row[1])
    mean_gain_list <<- c(mean_gain_list, row[2])
    violation_found_list <<- c(violation_found_list, row[3])
    demographic_list <<- c(demographic_list, color_col_name)
    demographic_sums <<- c(demographic_sums, nrow(df[sanitarian==eval(color_col_name)]))
    demographic_gain_list <<- c(demographic_gain_list, 
                                mean(df[sanitarian==eval(color_col_name), date_difference]))
}

print_location_violation_time <- function(df, location_col_name, location_zips, row) {
    color_cluster_list <<- c(color_cluster_list, row[1])
    mean_gain_list <<- c(mean_gain_list, row[length(row) - 1])
    violation_found_list <<- c(violation_found_list, row[length(row)])
    demographic_list <<- c(demographic_list, location_col_name)
    demographic_sums <<- c(demographic_sums, nrow(df[ZIP_CODE %in% location_zips]))
    demographic_gain_list <<- c(demographic_gain_list, 
                                mean(df[ZIP_CODE %in% location_zips, date_difference]))
}

mymax <- function(...,def=as.IDate("2019-09-05"),na.rm=FALSE)
    if(!is.infinite(x<-suppressWarnings(max(...,na.rm=na.rm)))) x else def

mymin <- function(...,def=as.IDate("2019-09-05"),na.rm=FALSE)
    if(!is.infinite(x<-suppressWarnings(min(...,na.rm=na.rm)))) x else def

##==============================================================================
## LOAD CACHED RDS FILES
##==============================================================================
# Divided by Larger Community Data Groupings
FarNorthSide <- c("60626", "60660", "60640", "60645", "60659", "60625", "60646", "60630", "60631", "60656", "60666", "60107", "60178")
NorthwestSide <- c("60641", "60634", "60639", "60635")
NorthSide <- c("60657", "60614", "60618", "60647", "60613")
CentralChicago <- c("60601", "60602", "60603", "60604", "60605", "60610", "60611", "60654", "60606")
WestSide <- c("60651", "60644", "60624", "60623", "60622", "60612", "60607", "60608", "60661", "60707")
SouthwestSide <- c("60638", "60632", "60629", "60609", "60636", "60621")
SouthSide <- c("60653", "60615", "60637", "60649", "60616")
FarSouthwestSide <- c("60652", "60620", "60643", "60655", "60642")
FarSoutheastSide <- c("60619", "60617", "60628", "60827", "60633", "60827")


locationNames <- c("NorthSide", "FarNorthSide", "FarSoutheastSide", "SouthSide", 
                   "CentralChicago", "FarSouthwestSide", "SouthwestSide", "WestSide", "NorthwestSide")
locationDivisions <- list(NorthSide, FarNorthSide, FarSoutheastSide, SouthSide, 
                          CentralChicago, FarSouthwestSide, SouthwestSide, WestSide, NorthwestSide)

sanitarian_clusters <- c("purple", "blue", "orange", "green", "yellow", "brown")
race_ethnicity <- c("White", "Black", "Asian", "Hispanic", "American_Indian", "Others")
racewise_date_diff_colnames <- c("date_difference_white", "date_difference_black", 
                                 "date_difference_asian", "date_difference_hispanic", 
                                 "date_difference_american_indian", "date_difference_others")

absolute_mode <- 1

colors <- c("purple", "blue", "orange", "green", "yellow", "brown")
test_window_range = c(0:18)

# "san_maj","race_maj","loc_maj"
majority = "san_maj" 
# dp, eqodd, eqopp
criteria = "dp"
C = 0.5

cat("incluster mean, overall mean, default mean\n")

for (window_split in test_window_range) {
    
    # >>>>>>> start block for non-color model stats >>>>>>>>>>>
    moving_test_window_dat <- paste("moving_test_window/30_dat_",window_split,".Rds",
    sep = "")
    baseline_csv_path <- paste("../baselines/fair-logloss-classification/results/scores_",
                               window_split,"_",criteria,"_",majority,"_",C,".csv", sep = "")

    baseline_csv <- read.csv(file = baseline_csv_path, header = FALSE)
    dat <- readRDS(moving_test_window_dat)
    dat[, ("baseline_score") := baseline_csv]
    datTest <- dat[Test == TRUE]        # Test Data (Originally )
    datNotTest <- dat[Test == FALSE]    # Data used to predict
    # <<<<<<< end this block for non-color model stats <<<<<<<<<
    
    color_cluster_list <- vector(mode="character")
    mean_gain_list <- vector(mode="double")
    violation_found_list <- vector(mode="numeric")
    demographic_list <- vector(mode="character")
    demographic_sums <- vector(mode="numeric")
    demographic_gain_list <- vector(mode="double")
    
    sum_all_rows <- 0
    sum_date_differences <- 0
    sum_violation_rows <- 0
    
    # select rows by sanitarian cluster color and re-order within those rows
    # get the new simulated date and find the difference in date
    for (sanitarian_cluster in sanitarian_clusters) {
        sanitarian_dat <- datTest[sanitarian == eval(sanitarian_cluster)]
        sum_all_rows <- sum_all_rows + nrow(sanitarian_dat)
        
        # get the simulated date and date differences
        sanitarian_dat <- sanitarian_dat[
            order(-baseline_score), simulated_date := 
                sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
        
        if (!absolute_mode) {
            sanitarian_dat <- sanitarian_dat[, date_difference := Inspection_Date - simulated_date][]
        } else {
            # get the relative date compared to the start date
            latest_date <- mymax(sanitarian_dat[order(simulated_date), simulated_date])
            earliest_date <- mymin(sanitarian_dat[order(simulated_date), simulated_date])
            
            sanitarian_dat <- sanitarian_dat[, date_difference := 
                                                 (simulated_date - earliest_date)]
        }
        
        sum_date_differences <- sum_date_differences + sum(sanitarian_dat[, date_difference])
        sum_violation_rows <- sum_violation_rows + nrow(sanitarian_dat)
        
        # make a vector with all the details
        row <- c(sanitarian_cluster, mean(sanitarian_dat[, date_difference]), 
                 nrow(sanitarian_dat))
        
        # get demographic gains inside the cluster
        for (i in 1:length(race_ethnicity)) {
            
            sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
                                                         racewise_date_diff_colnames[i])
            print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
                                        racewise_date_diff_colnames[i], row)
        }
        # get geographic gains inside the cluster
        l <- 1
        for (location in locationDivisions) {
            print_location_violation_time(sanitarian_dat, locationNames[l], location, row)
            l <- l + 1
        }
    }
    
    cat(sum_date_differences/sum_violation_rows, ", ")
    
    # double-check the original speed-up
    sanitarian_dat <- datTest
    sanitarian_dat <- sanitarian_dat[
        order(-baseline_score), simulated_date := 
            sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
    if (!absolute_mode) {
        sanitarian_dat <- sanitarian_dat[, date_difference := Inspection_Date - simulated_date][]
    } else {
        latest_date <- mymax(sanitarian_dat[order(simulated_date), simulated_date])
        earliest_date <- mymin(sanitarian_dat[order(simulated_date), simulated_date])
        
        sanitarian_dat <- sanitarian_dat[, date_difference := 
                                             (simulated_date - earliest_date)]
    }
    cat(mean(sanitarian_dat[, date_difference]), ", ")
    
    row <- c("all", mean(sanitarian_dat[, date_difference]), 
             nrow(sanitarian_dat))
    
    for (i in 1:length(race_ethnicity)) {
        
        sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
                                                     racewise_date_diff_colnames[i])
        print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
                                    racewise_date_diff_colnames[i], row)
    }
    
    for (sanitarian_cluster in sanitarian_clusters) {
        row <- c("all color", mean(sanitarian_dat[, date_difference]), 
                 nrow(sanitarian_dat))
        print_color_violation_time(sanitarian_dat, sanitarian_cluster, row)
    }
    # add geo details
    l <- 1
    for (location in locationDivisions) {
        row <- c("all location", mean(sanitarian_dat[, date_difference]), 
                 nrow(sanitarian_dat))
        print_location_violation_time(sanitarian_dat, locationNames[l], location, row)
        l <- l + 1
    }
    
    # calculation under original ordering
    if (absolute_mode) {
        sanitarian_dat <- datTest
        sanitarian_dat <- sanitarian_dat[
            order(-baseline_score), simulated_date := 
                sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
        latest_date <- mymax(sanitarian_dat[order(Inspection_Date), Inspection_Date])
        earliest_date <- mymin(sanitarian_dat[order(Inspection_Date), Inspection_Date])
        
        sanitarian_dat <- sanitarian_dat[, date_difference := 
                                             (Inspection_Date - earliest_date)]
        cat(mean(sanitarian_dat[, date_difference]), "\n")
        
        row <- c("default", mean(sanitarian_dat[, date_difference]), 
                 nrow(sanitarian_dat))
        
        for (i in 1:length(race_ethnicity)) {
            
            sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
                                                         racewise_date_diff_colnames[i])
            print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
                                        racewise_date_diff_colnames[i], row)
        }
        
        for (sanitarian_cluster in sanitarian_clusters) {
            row <- c("default color", mean(sanitarian_dat[, date_difference]), 
                     nrow(sanitarian_dat))
            print_color_violation_time(sanitarian_dat, sanitarian_cluster, row)
        }
        # add geo details
        l <- 1
        for (location in locationDivisions) {
            row <- c("default location", mean(sanitarian_dat[, date_difference]), 
                     nrow(sanitarian_dat))
            print_location_violation_time(sanitarian_dat, locationNames[l], location, row)
            l <- l + 1
        }
    }
    
    newdf <- data.frame(color_cluster_list, mean_gain_list, violation_found_list, 
                        demographic_list, demographic_sums, demographic_gain_list, 
                        stringsAsFactors = FALSE)
    write.csv(newdf, paste("baseline_test_window/",window_split,"_window_",
                           criteria,"_",majority,"_",C,"_inspection_time_geo.csv", 
                           sep = ""), row.names=FALSE)
}

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
  df <- df[criticalFound == 1]
  # print(nrow(df))
  demographic_sum <- sum(df[[og_col_name]], na.rm = TRUE)
  date_difference_demographic_sum <- sum(df[[date_diff_col_name]], na.rm = TRUE)
  # cat(og_col_name, "\n")
  # cat("sum: ", demographic_sum, ", date difference: ",
  # date_difference_demographic_sum, ", date difference mean: ",
  # date_difference_demographic_sum/demographic_sum, "\n\n")
  #print(row)
  location_cluster_list <<- c(location_cluster_list, row[1])
  
  # color_cluster_list <<- c(color_cluster_list, row[1])
  #mean_gain_list <<- c(mean_gain_list, row[2])
  mean_gain_list <<- c(mean_gain_list, row[length(row)-1])
  #violation_found_list <<- c(violation_found_list, row[3])
  violation_found_list <<- c(violation_found_list, row[length(row)])
  demographic_list <<- c(demographic_list, og_col_name)
  demographic_sums <<- c(demographic_sums, demographic_sum)
  demographic_gain_list <<- c(demographic_gain_list, 
                              date_difference_demographic_sum/demographic_sum)
  
  row <- c(row, og_col_name, date_difference_demographic_sum/demographic_sum)
  # print(row)
}

print_location_violation_time <- function(df, location_col_name, location_zips, row) {
  location_cluster_list <<- c(location_cluster_list, row[1])
  mean_gain_list <<- c(mean_gain_list, row[length(row) - 1])
  violation_found_list <<- c(violation_found_list, row[length(row)])
  demographic_list <<- c(demographic_list, location_col_name)
  demographic_sums <<- c(demographic_sums, nrow(df[criticalFound==1 & ZIP_CODE %in% location_zips]))
  demographic_gain_list <<- c(demographic_gain_list, 
                              mean(df[criticalFound==1 & ZIP_CODE %in% location_zips, date_difference]))
}

# print_color_violation_time <- function(df, color_col_name, row) {
#   color_cluster_list <<- c(color_cluster_list, row[1])
#   mean_gain_list <<- c(mean_gain_list, row[2])
#   violation_found_list <<- c(violation_found_list, row[3])
#   demographic_list <<- c(demographic_list, color_col_name)
#   demographic_sums <<- c(demographic_sums, nrow(df[criticalFound==1 & sanitarian==eval(color_col_name)]))
#   demographic_gain_list <<- c(demographic_gain_list, 
#                               mean(df[criticalFound==1 & sanitarian==eval(color_col_name), date_difference]))
# }

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


locationNames <- c("FarNorthSide", "NorthwestSide", "NorthSide", "CentralChicago",
                       "WestSide", "SouthwestSide", "SouthSide", "FarSouthwestSide", "FarSoutheastSide")
locationDivisions <- list(FarNorthSide, NorthwestSide, NorthSide, CentralChicago, 
                       WestSide, SouthwestSide, SouthSide, FarSouthwestSide, FarSoutheastSide)
sanitarian_clusters <- c("blue", "orange", "brown", "yellow", "green","purple")
race_ethnicity <- c("White", "Black", "Asian", "Hispanic", "American_Indian", "Others")
racewise_date_diff_colnames <- c("date_difference_white", "date_difference_black", 
                                 "date_difference_asian", "date_difference_hispanic", 
                                 "date_difference_american_indian", "date_difference_others")

original_model <- "DATA/30_dat.Rds"
absolute_mode <- 1

no_sanitarian_model <- "no_sanitarians_data/30_dat_ns.Rds"

current_color = "green"
colored_cluster_model <- paste("cluster_models/30_dat_",current_color,".Rds", 
                               sep = "")

colors <- c("blue", "orange", "brown", "yellow", "green", "purple")
# test_window_range = c(0:12) # 90 days
test_window_range = c(0:18) # 60 days 

for (window_split in test_window_range) {
  cat("Window Split", window_split)
  # >>>>>>> use this block for color model stats >>>>>>>>>>>
  # dat <- readRDS(paste("cluster_models/30_dat_",colors[1],"_window_",window_split,".Rds", sep = ""))
  # datTest <- dat[Test == TRUE]
  # datTest <- datTest[order(-glm_pred_test), simulated_date := datTest[order(Inspection_Date), Inspection_Date]][]
  # datTest <- datTest[, date_difference := Inspection_Date - simulated_date][]
  # 
  # for (color in colors[2:length(colors)]) {
  #     dat <- readRDS(paste("cluster_models/30_dat_",color,"_window_",window_split,".Rds", sep = ""))
  #     datT <- dat[Test == TRUE]
  #     datT <- datT[order(-glm_pred_test), simulated_date := datT[order(Inspection_Date), Inspection_Date]][]
  #     datT <- datT[, date_difference := Inspection_Date - simulated_date][]
  #     datTest <- rbind(datTest, datT)
  # }
  # <<<<<<<<<< end color model stats <<<<<<<<<<
  
  # >>>>>>> use this block for non-color model stats >>>>>>>>>>>
  moving_test_window_dat <- paste("moving_test_window/30_dat_",window_split,".Rds",
                                  sep = "")
  # moving_test_window_dat <- paste("no_sanitarians_data/30_dat_ns_",window_split,".Rds", sep = "")
  
  dat <- readRDS(moving_test_window_dat)
  datTest <- dat[Test == TRUE]        # Test Data (Originally )
  datNotTest <- dat[Test == FALSE]    # Data used to predict
  # >>>>>>> use this block for non-color model stats >>>>>>>>>>>
  
  location_cluster_list <- vector(mode="character")
  # color_cluster_list <- vector(mode="character")
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
  cat("\n\n")
  l <- 1
  for (locationDivision in locationDivisions) {
    # cat("\n\nlocation\n", locationDivision)
  # for (sanitarian_cluster in sanitarian_clusters) {
    # cat("current cluster:", eval(sanitarian_cluster), "\n")
    # sanitarian_dat <- datTest[sanitarian == eval(sanitarian_cluster)]
    
    # locationDivision <- locationDivisions[l]
    location_dat <- datTest[ZIP_CODE %in% locationDivision]
    # print(unique(location_dat[,"ZIP_CODE"]))
    # cat("num of rows:", nrow(sanitarian_dat), "\n")
    # sum_all_rows <- sum_all_rows + nrow(sanitarian_dat)
    sum_all_rows <- sum_all_rows + nrow(location_dat)
    
    # get the simulated date and date differences
    # sanitarian_dat <- sanitarian_dat[
    #   order(-glm_pred_test), simulated_date := 
    #     sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
    location_dat <- location_dat[
      order(-glm_pred_test), simulated_date := 
        location_dat[order(Inspection_Date), Inspection_Date]][]
    
    if (!absolute_mode) {
      # sanitarian_dat <- sanitarian_dat[, date_difference := Inspection_Date - simulated_date][]
      location_dat <- location_dat[, date_difference := Inspection_Date - simulated_date][]
    } else {
      # get the relative date compared to the start date
      # cat("\ncurrent sanitarian: ", sanitarian_cluster)
      # latest_date <- mymax(sanitarian_dat[order(simulated_date), simulated_date])
      # earliest_date <- mymin(sanitarian_dat[order(simulated_date), simulated_date])
      # 
      # sanitarian_dat <- sanitarian_dat[, date_difference := 
      #                                    (simulated_date - earliest_date)]
      
      latest_date <- mymax(location_dat[order(simulated_date), simulated_date])
      earliest_date <- mymin(location_dat[order(simulated_date), simulated_date])
      
      location_dat <- location_dat[, date_difference := 
                                         (simulated_date - earliest_date)]
    }
    
    # cat("sum of date differences: ", sum(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    # sum_date_differences <- sum_date_differences + sum(sanitarian_dat[criticalFound == 1, date_difference])
    sum_date_differences <- sum_date_differences + sum(location_dat[criticalFound == 1, date_difference])
    
    # cat("mean of date differences: ", mean(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    # cat("num of rows with violation: ", nrow(sanitarian_dat[criticalFound == 1]), "\n\n")
    # sum_violation_rows <- sum_violation_rows + nrow(sanitarian_dat[criticalFound == 1])
    sum_violation_rows <- sum_violation_rows + nrow(location_dat[criticalFound == 1])
    
    
    # make a vector with all the details
    # row <- c(sanitarian_cluster, mean(sanitarian_dat[criticalFound == 1, date_difference]), 
    #          nrow(sanitarian_dat[criticalFound == 1]))
    row <- c(locationNames[l], mean(location_dat[criticalFound == 1, date_difference]), 
             nrow(location_dat[criticalFound == 1]))
    
    # get demographic gains inside the cluster
    for (i in 1:length(race_ethnicity)) {
      
      # sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
      #                                              racewise_date_diff_colnames[i])
      # print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
      #                             racewise_date_diff_colnames[i], row)
      location_dat <- calc_demographic_date_diff(location_dat, race_ethnicity[i], 
                                                   racewise_date_diff_colnames[i])
      print_demographic_date_diff(location_dat, race_ethnicity[i],
                                  racewise_date_diff_colnames[i], row)
    }
    l <- l+1
  }
  
  # cat("\n\nsum of all rows\n", sum_all_rows)
  
  # cat("\n\nsum of all date differences\n", sum_date_differences)
  # cat("\n\nsum of all violation rates\n", sum_violation_rows)
  cat("\n\noverall mean\n", sum_date_differences/sum_violation_rows)
  
  
  
  
  #### hellllooooo
  
  
  
  # double-check the original speed-up
  cat("\n\n")
  # sanitarian_dat <- datTest
  # sanitarian_dat <- sanitarian_dat[
  #   order(-glm_pred_test), simulated_date := 
  #     sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
  
  location_dat <- datTest
  location_dat <- location_dat[
    order(-glm_pred_test), simulated_date := 
      location_dat[order(Inspection_Date), Inspection_Date]][]
  
  if (!absolute_mode) {
    # sanitarian_dat <- sanitarian_dat[, date_difference := Inspection_Date - simulated_date][]
    location_dat <- location_dat[, date_difference := Inspection_Date - simulated_date][]
  } else {
    # latest_date <- mymax(sanitarian_dat[order(simulated_date), simulated_date])
    # earliest_date <- mymin(sanitarian_dat[order(simulated_date), simulated_date])
    # 
    # sanitarian_dat <- sanitarian_dat[, date_difference := 
    #                                    (simulated_date - earliest_date)]
    latest_date <- mymax(location_dat[order(simulated_date), simulated_date])
    earliest_date <- mymin(location_dat[order(simulated_date), simulated_date])
    
    location_dat <- location_dat[, date_difference := 
                                       (simulated_date - earliest_date)]
  }
  # cat("original model sum of date differences: ", sum(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
  # cat("original model sum of date differences: ", sum(location_dat[criticalFound == 1, date_difference]), "\n")
  
  # sum_date_differences <- sum_date_differences + sum(sanitarian_dat[criticalFound == 1, date_difference])
  # cat("original model mean of date differences: ", mean(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
  # cat("original model mean of date differences: ", mean(location_dat[criticalFound == 1, date_difference]), "\n")
  # cat("original model num of rows with violation: ", nrow(sanitarian_dat[criticalFound == 1]), "\n\n")
  # cat("original model num of rows with violation: ", nrow(location_dat[criticalFound == 1]), "\n\n")
  # sum_violation_rows <- sum_violation_rows + nrow(sanitarian_dat[criticalFound == 1])
  
  # row <- c("all", mean(sanitarian_dat[criticalFound == 1, date_difference]), 
  #          nrow(sanitarian_dat[criticalFound == 1]))
  row <- c("all", mean(location_dat[criticalFound == 1, date_difference]), 
           nrow(location_dat[criticalFound == 1]))
  
  for (i in 1:length(race_ethnicity)) {
    
    # sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
    #                                              racewise_date_diff_colnames[i])
    # print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
    #                             racewise_date_diff_colnames[i], row)
    location_dat <- calc_demographic_date_diff(location_dat, race_ethnicity[i], 
                                                 racewise_date_diff_colnames[i])
    print_demographic_date_diff(location_dat, race_ethnicity[i],
                                racewise_date_diff_colnames[i], row)
  }
  
  # for (sanitarian_cluster in sanitarian_clusters) {
  l <- 1
  for (locationDivision in locationDivisions) {
    # row <- c("all color", mean(sanitarian_dat[criticalFound == 1, date_difference]), 
    #          nrow(sanitarian_dat[criticalFound == 1]))
    # print_color_violation_time(sanitarian_dat, sanitarian_cluster, row)
    
    row <- c("all location", mean(location_dat[criticalFound == 1, date_difference]), 
             nrow(location_dat[criticalFound == 1]))
    print_location_violation_time(location_dat, locationNames[l], locationDivision, row)
    l <- l + 1
    # print(nrow(sanitarian_dat))
    # sDat <- sanitarian_dat[sanitarian==eval(sanitarian_cluster) && criticalFound == 1]
    # print(sum(sanitarian_cluster))
    # print(sum(sDat["date_difference"]))
  }
  
  # calculation under original ordering
  if (absolute_mode) {
    cat("\n")
    # sanitarian_dat <- datTest
    # sanitarian_dat <- sanitarian_dat[
    #   order(-glm_pred_test), simulated_date := 
    #     sanitarian_dat[order(Inspection_Date), Inspection_Date]][]
    # latest_date <- mymax(sanitarian_dat[order(Inspection_Date), Inspection_Date])
    # earliest_date <- mymin(sanitarian_dat[order(Inspection_Date), Inspection_Date])
    location_dat <- datTest
    location_dat <- location_dat[
      order(-glm_pred_test), simulated_date := 
        location_dat[order(Inspection_Date), Inspection_Date]][]
    latest_date <- mymax(location_dat[order(Inspection_Date), Inspection_Date])
    earliest_date <- mymin(location_dat[order(Inspection_Date), Inspection_Date])
    
    # sanitarian_dat <- sanitarian_dat[, date_difference := 
    #                                    (Inspection_Date - earliest_date)]
    # cat("default ordering sum of date differences: ", sum(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    # cat("default ordering  mean of date differences: ", mean(sanitarian_dat[criticalFound == 1, date_difference]), "\n")
    # cat("default ordering  num of rows with violation: ", nrow(sanitarian_dat[criticalFound == 1]), "\n\n")
    location_dat <- location_dat[, date_difference := 
                                       (Inspection_Date - earliest_date)]
    # cat("default ordering sum of date differences: ", sum(location_dat[criticalFound == 1, date_difference]), "\n")
    # cat("default ordering  mean of date differences: ", mean(location_dat[criticalFound == 1, date_difference]), "\n")
    # cat("default ordering  num of rows with violation: ", nrow(location_dat[criticalFound == 1]), "\n\n")
    
    # row <- c("default", mean(sanitarian_dat[criticalFound == 1, date_difference]), 
    #          nrow(sanitarian_dat[criticalFound == 1]))
    row <- c("default", mean(location_dat[criticalFound == 1, date_difference]), 
             nrow(location_dat[criticalFound == 1]))
    
    for (i in 1:length(race_ethnicity)) {
      
      # sanitarian_dat <- calc_demographic_date_diff(sanitarian_dat, race_ethnicity[i], 
      #                                              racewise_date_diff_colnames[i])
      # print_demographic_date_diff(sanitarian_dat, race_ethnicity[i],
      #                             racewise_date_diff_colnames[i], row)
      location_dat <- calc_demographic_date_diff(location_dat, race_ethnicity[i], 
                                                   racewise_date_diff_colnames[i])
      print_demographic_date_diff(location_dat, race_ethnicity[i],
                                  racewise_date_diff_colnames[i], row)
    }
    
    # for (sanitarian_cluster in sanitarian_clusters) {
    #   row <- c("default color", mean(sanitarian_dat[criticalFound == 1, date_difference]), 
    #            nrow(sanitarian_dat[criticalFound == 1]))
    #   print_color_violation_time(sanitarian_dat, sanitarian_cluster, row)
    # }
    l <- 1
    for (locationDivision in locationDivisions) {
      row <- c("default location", mean(location_dat[criticalFound == 1, date_difference]), 
               nrow(location_dat[criticalFound == 1]))
      print_location_violation_time(location_dat, locationNames[l], locationDivision, row)
      l <- l+1
    }
  }
  
  # newdf <- data.frame(color_cluster_list, mean_gain_list, violation_found_list, 
  #                     demographic_list, demographic_sums, demographic_gain_list, 
  #                     stringsAsFactors = FALSE)
  newdf <- data.frame(location_cluster_list, mean_gain_list, violation_found_list, 
                      demographic_list, demographic_sums, demographic_gain_list, 
                      stringsAsFactors = FALSE)
  # write.csv(newdf, paste("moving_test_window_geographic/",window_split,"_window.csv", sep = ""), row.names=FALSE)
  # write.csv(newdf, paste("moving_test_window/",window_split,"_window.csv", sep = ""), row.names=FALSE)
  # write.csv(newdf, paste("no_sanitarians_data/ns_",window_split,"_window.csv", sep = ""), row.names=FALSE)
  # write.csv(newdf, paste("cluster_models/",window_split,"_window.csv", sep = ""), row.names=FALSE)
  
}

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
dat <- readRDS("DATA/30_dat.Rds")
cvfit <- readRDS("DATA/30_model_eval.Rds")
mm <- readRDS("DATA/30_modelmatrix.Rds")

# str(cvfit)
# str(cvfit$glmnet.fit$beta)

## Calculate scores for all lambda values
allscores <- predict(cvfit$glmnet.fit, 
                     newx = as.matrix(mm), 
                     s = cvfit$glmnet.fit$lambda,
                     type = "response")
allscores <- as.data.table(allscores)
setnames(allscores, cvfit$glmnet.fit$beta@Dimnames[[2]])

## Identify each row as test / train
allscores$Test <- dat$Test
allscores$Train <- !dat$Test

##==============================================================================
## MODEL EVALUATION
##    - TIME SAVINGS
##    - PERIOD A vs PERIOD B
##==============================================================================
## Subset of just observations during test period:

race_ethnicity <- c("White", "Black", "American_Indian", "Asian", "Hispanic", "Others")

datTest <- dat[Test == TRUE]        # Test Data (Originally )
datNotTest <- dat[Test == FALSE]    # Data used to predict
datTest <- datTest[criticalFound == 1]
#print(datTest)

datTest <- datTest[order(-glm_pred_test), simulated_date := datTest[order(Inspection_Date), Inspection_Date]][]
datTest$date_difference <- datTest$Inspection_Date - datTest$simulated_date

datTest$date_difference_white <- datTest$White * datTest$date_difference
datTest$date_difference_black <- datTest$Black * datTest$date_difference
datTest$date_difference_american_indian <- datTest$American_Indian * datTest$date_difference
datTest$date_difference_asian <- datTest$Asian * datTest$date_difference
datTest$date_difference_hispanic <- datTest$Hispanic * datTest$date_difference
datTest$date_difference_others <- datTest$Others * datTest$date_difference


white_sum = sum(datTest$White, na.rm = TRUE)
date_difference_white_sum = sum(datTest$date_difference_white, na.rm = TRUE)
cat("white sum: ", white_sum, ", white date difference: ",
    date_difference_white_sum, ", white date difference mean: ",
    date_difference_white_sum/white_sum, "\n")

black_sum = sum(datTest$Black, na.rm = TRUE)
date_difference_black_sum = sum(datTest$date_difference_black, na.rm = TRUE)
cat("black sum: ", black_sum, ", black date difference: ",
    date_difference_black_sum, ", black date difference mean: ",
    date_difference_black_sum/black_sum, "\n")

asian_sum = sum(datTest$Asian, na.rm = TRUE)
date_difference_asian_sum = sum(datTest$date_difference_asian, na.rm = TRUE)
cat("asian sum: ", asian_sum, ", asian date difference: ",
    date_difference_asian_sum, ", asian date difference mean: ",
    date_difference_asian_sum/asian_sum, "\n")

hispanic_sum = sum(datTest$Hispanic, na.rm = TRUE)
date_difference_hispanic_sum = sum(datTest$date_difference_hispanic, na.rm = TRUE)
cat("hispanic sum: ", hispanic_sum, ", hispanic date difference: ",
    date_difference_hispanic_sum, ", hispanic date difference mean: ",
    date_difference_hispanic_sum/hispanic_sum, "\n")

american_indian_sum = sum(datTest$American_Indian, na.rm = TRUE)
date_difference_american_indian_sum = sum(datTest$date_difference_american_indian, na.rm = TRUE)
cat("american_indian sum: ", american_indian_sum, ", american_indian date difference: ",
    date_difference_american_indian_sum, ", american_indian date difference mean: ",
    date_difference_american_indian_sum/american_indian_sum, "\n")

others_sum = sum(datTest$Others, na.rm = TRUE)
date_difference_others_sum = sum(datTest$date_difference_others, na.rm = TRUE)
cat("others sum: ", others_sum, ", others date difference: ",
    date_difference_others_sum, ", others date difference mean: ",
    date_difference_others_sum/others_sum, "\n")

# get_race_ethnic_aggregate <- function(race_ethnic_str, race_ethnic_col, 
#                                       race_ethnic_date_diff_col) {
#     race_ethnic_sum = sum(datTestrace_ethnic_col, na.rm = TRUE)
#     date_difference_race_ethnic_sum = sum(datTest$race_ethnic_date_diff_col, na.rm = TRUE)
#     cat(race_ethnic_str)
#     cat("sum: ", race_ethnic_sum, ", date difference: ", 
#         date_difference_race_ethnic_sum, ", date difference mean: ", 
#         date_difference_race_ethnic_sum/race_ethnic_sum)
# }

# get_race_ethnic_aggregate("white", "White", "date_difference_white")



# filter for positive


# simulated_data_diff for machine learning order vs Test Data
# str(datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)])
# total <- datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# print(c("total: ",total)) # 7.589


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

# dat <- readRDS("no_sanitarians_data/30_dat_ns.Rds")
# cvfit <- readRDS("no_sanitarians_data/30_model_eval_ns.Rds")
# mm <- readRDS("no_sanitarians_data/30_modelmatrix_ns.Rds")

# dat <- readRDS("cluster_models/30_dat_green.Rds")
# cvfit <- readRDS("cluster_models/30_model_eval_green.Rds")
# mm <- readRDS("cluster_models/30_modelmatrix_green.Rds")

str(cvfit)
str(cvfit$glmnet.fit$beta)

## Calculate scores for all lambda values
# allscores <- predict(cvfit$glmnet.fit, 
#                      newx = as.matrix(mm), 
#                      s = cvfit$glmnet.fit$lambda,
#                      type = "response")
# allscores <- as.data.table(allscores)
# setnames(allscores, cvfit$glmnet.fit$beta@Dimnames[[2]])
# 
# ## Identify each row as test / train
# allscores$Test <- dat$Test
# allscores$Train <- !dat$Test

##==============================================================================
## MODEL EVALUATION
##    - TIME SAVINGS
##    - PERIOD A vs PERIOD B
##==============================================================================
## Subset of just observations during test period:

# List of all the ZipCodes
# 60107 60178
# 60601 60602 60603 60604 60605 60606 60607 60608 60609 60610
# 60611 60612 60613 60614 60615 60616 60617 60618 60619 60620
# 60621 60622 60623 60624 60625 60626 60628 60629 60630
# 60631 60632 60633 60634 60635 60636 60637 60638 60639 60640
# 60641 60642 60643 60644 60645 60646 60647 60649
# 60651 60652 60653 60654 60655 60656 60657 60659 60660
# 60661 60666
# 60707 60827

# North of Roosevelt
north <- c("60601","60602","60603","60604","60606",
           "60610","60611","60613","60614",
           "60618","60621","60622","60625","60626","60630",
           "60631","60634","60639","60640","60641","60645","60646","60647",
           "60651","60654","60656","60657","60659","60660",
           "60661","60666","60707", "60178", "60107","60642")
# South of Roosevelt
south <- c("60605","60607","60608","60609",
           "60612","60615","60616","60617","60619",
           "60620","60621","60623","60624","60627","60628","60629",
           "60632","60633","60635","60636","60637","60638",
           "60643","60644","60649",
           "60652","60653","60655", "60827")
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


datTest <- dat[Test == TRUE]        # Test Data (Originally )
datNotTest <- dat[Test == FALSE]    # Data used to predict
#cat(datTest)

# simulated_data_diff for machine learning order vs Test Data
datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
total <- datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
totalCV <- nrow(datTest[Test==TRUE][criticalFound==1])
cat(c("total: ",total)) # 7.589

datTest <- datTest[order(-glm_pred_test), simulated_date := datTest[order(Inspection_Date), Inspection_Date]][]
datTest <- datTest[, date_difference := Inspection_Date - simulated_date][]

dfBlue <- datTest[sanitarian == 'blue']
dfBrown <- datTest[sanitarian == 'brown']
dfGreen <- datTest[sanitarian == 'green']
dfOrange <- datTest[sanitarian == 'orange']
dfPurple <- datTest[sanitarian == 'purple']
dfYellow <- datTest[sanitarian == 'yellow']
cat("\nblue in the full reordering", mean(dfBlue[criticalFound == 1, date_difference]))
cat("\nbrown in the full reordering", mean(dfBrown[criticalFound == 1, date_difference]))
cat("\ngreen in the full reordering", mean(dfGreen[criticalFound == 1, date_difference]))
cat("\norange in the full reordering", mean(dfOrange[criticalFound == 1, date_difference]))
cat("\npurple in the full reordering", mean(dfPurple[criticalFound == 1, date_difference]))
cat("\nyellow in the full reordering", mean(dfYellow[criticalFound == 1, date_difference]))

dfNorth <- datTest[ZIP_CODE %in% north]
dfSouth <- datTest[ZIP_CODE %in% south]
cat("\nnorth in the full reordering", mean(dfNorth[criticalFound == 1, date_difference]))
cat("\nsouth in the full reordering", mean(dfSouth[criticalFound == 1, date_difference]))


dfFNS <- datTest[ZIP_CODE %in% FarNorthSide]
dfNWS <- datTest[ZIP_CODE %in% NorthwestSide]
dfNS <- datTest[ZIP_CODE %in% NorthSide]
dfCC <- datTest[ZIP_CODE %in% CentralChicago]
dfWS <- datTest[ZIP_CODE %in% WestSide]
dfSWS <- datTest[ZIP_CODE %in% SouthwestSide]
dfSS <- datTest[ZIP_CODE %in% SouthSide]
dfFSWS <- datTest[ZIP_CODE %in% FarSouthwestSide]
dfFSES <- datTest[ZIP_CODE %in% FarSoutheastSide]
cat("\nFNS in the full reordering", mean(dfFNS[criticalFound == 1, date_difference]))
cat("\nNWS in the full reordering", mean(dfNWS[criticalFound == 1, date_difference]))
cat("\nNS in the full reordering", mean(dfNS[criticalFound == 1, date_difference]))
cat("\nCC in the full reordering", mean(dfCC[criticalFound == 1, date_difference]))
cat("\nWS in the full reordering", mean(dfWS[criticalFound == 1, date_difference]))
cat("\nSS in the full reordering", mean(dfSS[criticalFound == 1, date_difference]))
cat("\nFSWS in the full reordering", mean(dfFSWS[criticalFound == 1, date_difference]))
cat("\nFSES in the full reordering", mean(dfFSES[criticalFound == 1, date_difference]))

# simulated_data_diff for establishments in the north vs south
cat("Reordering Within North and Within South")
dfNorth <- datTest[ZIP_CODE %in% north]
northValue <- dfNorth[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
northCV <- nrow(dfNorth[Test==TRUE][criticalFound==1])
cat("\nnorth: ",northValue)      # 9.723

dfSouth <- datTest[ZIP_CODE %in% south]
southValue <- dfSouth[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
southCV <- nrow(dfSouth[Test==TRUE][criticalFound==1])
cat("\tsouth: ", southValue)     # 1.014

cat("\twithin north and south reordering: ", northValue*northCV/totalCV + southValue*southCV/totalCV)

# simulated_data_diff for establishments in different community areas
dfFNS <- datTest[ZIP_CODE %in% FarNorthSide]
FNS <- dfFNS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
FNS1 <- nrow(dfFNS[Test==TRUE][criticalFound==1])
cat("\nFarNorthSide: ",FNS)      # 10.817

dfNWS <- datTest[ZIP_CODE %in% NorthwestSide]
NWS <- dfNWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
NWS1 <- nrow(dfNWS[Test==TRUE][criticalFound==1])
cat("\tNorthwestSide: ",NWS)     # 18.5

dfNS <- datTest[ZIP_CODE %in% NorthSide]
NS <- dfNS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
NS1 <- nrow(dfNS[Test==TRUE][criticalFound==1])
cat("\tNorthSide: ",NS)          # 9.340

dfCC <- datTest[ZIP_CODE %in% CentralChicago]
CC <- dfCC[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
CC1 <- nrow(dfCC[Test==TRUE][criticalFound==1])
cat("\nCentralChicago: ",CC)     # 7.981

dfWS <- datTest[ZIP_CODE %in% WestSide]
WS <- dfWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
WS1 <- nrow(dfWS[Test==TRUE][criticalFound==1])
cat("\tWestSide: ",WS)           # 0.867

dfSWS <- datTest[ZIP_CODE %in% SouthwestSide]
SWS <- dfSWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
SWS1 <- nrow(dfSWS[Test==TRUE][criticalFound==1])
cat("\tSouthwestSide: ",SWS)     # 7.667

dfSS <- datTest[ZIP_CODE %in% SouthSide]
SS <- dfSS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
SS1 <- nrow(dfSS[Test==TRUE][criticalFound==1])
cat("\nSouthSide: ",SS)          # 0.9375

dfFSWS <- datTest[ZIP_CODE %in% FarSouthwestSide]
FSWS <- dfFSWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
FSW1 <- nrow(dfFSWS[Test==TRUE][criticalFound==1])
cat("\tFarSouthwestSide: ",FSWS) # -14

dfFSES <- datTest[ZIP_CODE %in% FarSoutheastSide]
FSES <- dfFSES[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
FSES1 <- nrow(dfFSES[Test==TRUE][criticalFound==1])
cat("\tFarSoutheastSide: ",FSES) # 7.75

cat("\twithin geo reordering: ",FNS*FNS1/totalCV+
        NWS*NWS1/totalCV+
        NS*NS1/totalCV+
        CC*CC1/totalCV+
        WS*WS1/totalCV+
        SWS*SWS1/totalCV+
        SS*SS1/totalCV+
        SWS*SWS1/totalCV+
        FSES*FSES1/totalCV)

# simulated_data_diff for establishments by the inspector for new inspection
dfBlue <- datTest[sanitarian == 'blue']
dfBrown <- datTest[sanitarian == 'brown']
dfGreen <- datTest[sanitarian == 'green']
dfOrange <- datTest[sanitarian == 'orange']
dfPurple <- datTest[sanitarian == 'purple']
dfYellow <- datTest[sanitarian == 'yellow']

blueValue <- dfBlue[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("blue: ",blueValue))        # 1.509
brownValue <- dfBrown[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("brown: ",brownValue))      # 19.333
greenValue <- dfGreen[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("green: ",greenValue))      # -4.375
orangeValue <- dfOrange[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("orange: ",orangeValue))    # -4.565
purpleValue <- dfPurple[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("purple: ",purpleValue))    # 10.636
yellowValue <- dfYellow[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("yellow: ",yellowValue))    # 5.1

# simulated_data_diff for establishments by Level of Risk
dfHigh <- datTest[Risk == 'Risk 1 (High)']
HighValue <- dfHigh[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("High", HighValue))         # 9.283
dfMedium <- datTest[Risk == 'Risk 2 (Medium)']
MediumValue <- dfMedium[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("Medium", MediumValue))     # 3.129
dfLow <- datTest[Risk == 'Risk 3 (Low)']
LowValue <- dfLow[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
cat(c("Low   ", LowValue))        # 1

# simulated_data_diff for establishments by past inspectors
dfViolation <- datTest[criticalFound == '1']            #data set with all the inspections in the test data that had violations
testLicences <- unique(dfViolation[["LICENSE_ID"]])     #list of all the licence numbers in ^ dataset
dfLicences <- dat[LICENSE_ID %in% testLicences]         #data set of all the inspections that have occured to this license number in the last 10 years
#pt6 <- qhpvt(dfLicences, "LICENSE_ID", "sanitarian", "n()")
#cat(pt6)

testLicences <- unique(datTest[["LICENSE_ID"]])
dfLicences <- datNotTest[LICENSE_ID %in% testLicences]

dfBlue <- dfLicences[sanitarian == 'blue']
bluePast <- unique(dfBlue[["LICENSE_ID"]])
dfBluePast <- datTest[LICENSE_ID %in% bluePast]

dfBrown <- dfLicences[sanitarian == 'brown']
brownPast <- unique(dfBrown[["LICENSE_ID"]])
dfBrownPast <- datTest[LICENSE_ID %in% brownPast]

dfGreen <- dfLicences[sanitarian == 'green']
greenPast <- unique(dfGreen[["LICENSE_ID"]])
dfGreenPast <- datTest[LICENSE_ID %in% greenPast]

dfOrange <- dfLicences[sanitarian == 'orange']
orangePast <- unique(dfOrange[["LICENSE_ID"]])
dfOrangePast <- datTest[LICENSE_ID %in% orangePast]

dfPurple <- dfLicences[sanitarian == 'purple']
purplePast <- unique(dfPurple[["LICENSE_ID"]])
dfPurplePast <- datTest[LICENSE_ID %in% purplePast]

dfYellow <- dfLicences[sanitarian == 'yellow']
yellowPast <- unique(dfYellow[["LICENSE_ID"]])
dfYellowPast <- datTest[LICENSE_ID %in% yellowPast]

# blueValue <- dfBluePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("blue2: ",blueValue))
# brownValue <- dfBrownPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("brown2: ",brownValue))
# greenValue <- dfGreenPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("green2: ",greenValue))
# orangeValue <- dfOrangePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("orange2: ",orangeValue))
# purpleValue <- dfPurplePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("purple2: ",purpleValue))
# yellowValue <- dfYellowPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# cat(c("yellow2: ",yellowValue))
#
# #Yelp
#
#
# # used to understand if the inspector reported per inspection is a previous or current inspector
# #datSpecific <- dat[LICENSE_ID == "2176007"]
# #cat(datSpecific)
# #inspectors <- readRDS("DATA/19_inspector_assignments.Rds")
# #specific <- inspectors[inspectionID == "1345470"] #yellow
# #cat(specific)
# #specific <- inspectors[inspectionID == "1496638"]
# #cat(specific)
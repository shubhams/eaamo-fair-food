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
dat <- readRDS("no_sanitarians_data/30_dat_ns.Rds")
cvfit <- readRDS("no_sanitarians_data/30_model_eval_ns.Rds")
mm <- readRDS("no_sanitarians_data/30_modelmatrix_ns.Rds")

str(cvfit)
str(cvfit$glmnet.fit$beta)

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
#print(datTest)

# simulated_data_diff for machine learning order vs Test Data
datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
total <- datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("total: ",total)) # 7.589   # 2.26996197718631

# simulated_data_diff for establishments in the north vs south  
dfNorth <- datTest[ZIP_CODE %in% north]
northValue <- dfNorth[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("north: ",northValue))      # 9.723     # 4.58638743455497
dfSouth <- datTest[ZIP_CODE %in% south]
southValue <- dfSouth[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("south: ", southValue))     # 1.014     # -4.97183098591549

# simulated_data_diff for establishments in different community areas  
dfFNS <- datTest[ZIP_CODE %in% FarNorthSide]
FNS <- dfFNS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("FarNorthSide: ",FNS))      # 10.817    # 7.21666666666667
dfNWS <- datTest[ZIP_CODE %in% NorthwestSide]
NWS <- dfNWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("NorthwestSide: ",NWS))     # 18.5      # 3.6
dfNS <- datTest[ZIP_CODE %in% NorthSide]
NS <- dfNS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("NorthSide: ",NS))          # 9.340     # 2.06382978723404
dfCC <- datTest[ZIP_CODE %in% CentralChicago]
CC <- dfCC[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("CentralChicago: ",CC))     # 7.981     # 4.96153846153846
dfWS <- datTest[ZIP_CODE %in% WestSide]
WS <- dfWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("WestSide: ",WS))           # 0.867     # -3.86666666666667
dfSWS <- datTest[ZIP_CODE %in% SouthwestSide]
SWS <- dfSWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("SouthwestSide: ",SWS))     # 7.667     # 
dfSS <- datTest[ZIP_CODE %in% SouthSide]
SS <- dfSS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("SouthSide: ",SS))          # 0.9375
dfFSWS <- datTest[ZIP_CODE %in% FarSouthwestSide]
FSWS <- dfFSWS[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("FarSouthwestSide: ",FSWS)) # -14
dfFSES <- datTest[ZIP_CODE %in% FarSoutheastSide]
FSES <- dfFSES[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("FarSoutheastSide: ",FSES)) # 7.75



# simulated_data_diff for establishments by the inspector for new inspection  
dfBlue <- datTest[sanitarian == 'blue']
dfBrown <- datTest[sanitarian == 'brown']
dfGreen <- datTest[sanitarian == 'green']
dfOrange <- datTest[sanitarian == 'orange']
dfPurple <- datTest[sanitarian == 'purple']
dfYellow <- datTest[sanitarian == 'yellow']

blueValue <- dfBlue[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("blue: ",blueValue))        # 1.509
brownValue <- dfBrown[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("brown: ",brownValue))      # 19.333
greenValue <- dfGreen[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("green: ",greenValue))      # -4.375
orangeValue <- dfOrange[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("orange: ",orangeValue))    # -4.565
purpleValue <- dfPurple[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("purple: ",purpleValue))    # 10.636
yellowValue <- dfYellow[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("yellow: ",yellowValue))    # 5.1

# simulated_data_diff for establishments by Level of Risk 
dfHigh <- datTest[Risk == 'Risk 1 (High)']
HighValue <- dfHigh[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("High", HighValue))         # 9.283
dfMedium <- datTest[Risk == 'Risk 2 (Medium)']
MediumValue <- dfMedium[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("Medium", MediumValue))     # 3.129
dfLow <- datTest[Risk == 'Risk 3 (Low)']
LowValue <- dfLow[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("Low   ", LowValue))        # 1

# simulated_data_diff for establishments by past inspectors 
dfViolation <- datTest[criticalFound == '1']            #data set with all the inspections in the test data that had violations
testLicences <- unique(dfViolation[["LICENSE_ID"]])     #list of all the licence numbers in ^ dataset
dfLicences <- dat[LICENSE_ID %in% testLicences]         #data set of all the inspections that have occured to this license number in the last 10 years
#pt6 <- qhpvt(dfLicences, "LICENSE_ID", "sanitarian", "n()")
#print(pt6)

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

blueValue <- dfBluePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("blue2: ",blueValue))
brownValue <- dfBrownPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("brown2: ",brownValue))
greenValue <- dfGreenPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("green2: ",greenValue))
orangeValue <- dfOrangePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("orange2: ",orangeValue))
purpleValue <- dfPurplePast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("purple2: ",purpleValue))
yellowValue <- dfYellowPast[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
print(c("yellow2: ",yellowValue))

#Yelp


# used to understand if the inspector reported per inspection is a previous or current inspector
#datSpecific <- dat[LICENSE_ID == "2176007"]
#print(datSpecific)
#inspectors <- readRDS("DATA/19_inspector_assignments.Rds")
#specific <- inspectors[inspectionID == "1345470"] #yellow
#print(specific)
#specific <- inspectors[inspectionID == "1496638"]
#print(specific)
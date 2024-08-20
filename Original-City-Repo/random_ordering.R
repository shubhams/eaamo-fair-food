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


# A random ordering and to see if the simulated date difference
# is better or worse that the original ordering 

colors <- c("orange", "brown", "yellow", "green", "purple")

# dat <- readRDS("cluster_models/30_dat_green.Rds")
dat <- readRDS("DATA/30_dat.Rds")
datTest <- dat[Test == TRUE]
before <- datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)]
# datTest[order(as.Date(datTest$Inspection_Date, format="%Y-%m-%d")),]
cat("oringinal model's reodering: ", before)
for(i in 1:10){
    cat("\n\nRandom Reordering ", i)
    dat <- readRDS("DATA/30_dat.Rds")
    datTest <- dat[Test == TRUE]
    datTest$Random_Date = sample(datTest$Inspection_Date, replace=FALSE)
    datTest <- datTest[criticalFound == 1]
    after <- mean(datTest$Random_Date - datTest$Inspection_Date)
    cat("\nrandom reodering overall: ", after)
    for(color in colors){
        datCol <- datTest[sanitarian == color]
        after <- mean(datCol$Random_Date - datCol$Inspection_Date)
        cat("\nrandom reodering for ", color, ": ", after)
    }
}
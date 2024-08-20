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
colors <- c("blue", "orange", "brown", "yellow", "green", "purple")

for (color in colors) {
    
    food <- readRDS("DATA/23_food_insp_features.Rds")
    bus <- readRDS("DATA/24_bus_features.Rds")
    sanitarians <- readRDS("DATA/19_inspector_assignments.Rds")
    weather <- readRDS("DATA/17_mongo_weather_update.Rds")
    heat_burglary <- readRDS("DATA/22_burglary_heat.Rds")
    heat_garbage <- readRDS("DATA/22_garbageCarts_heat.Rds")
    heat_sanitation <- readRDS("DATA/22_sanitationComplaints_heat.Rds")
    demographics <- read.csv("DATA/food_inspection_demographics_all.csv",
                             check.names = FALSE)
    ##==============================================================================
    ## MERGE IN FEATURES
    ##==============================================================================
    sanitarians <- sanitarians[,list(Inspection_ID=inspectionID), keyby=sanitarian]
    setnames(heat_burglary, "heat_values", "heat_burglary")
    setnames(heat_garbage, "heat_values", "heat_garbage")
    setnames(heat_sanitation, "heat_values", "heat_sanitation")
    
    dat <- copy(food)
    cat("\n0: ", nrow(dat))
    dat <- dat[bus]
    cat("\n1: ", nrow(dat))
    dat <- merge(x = dat, y = demographics, by = "Inspection_ID")
    cat("\n2: ", nrow(dat))
    dat <- merge(x = dat,  y = sanitarians,  by = "Inspection_ID")
    cat("\n3: ", nrow(dat))
    dat <- merge(x = dat, y = weather_3day_calc(weather), by = "Inspection_Date")
    dat <- merge(dat, na.omit(heat_burglary),  by = "Inspection_ID")
    dat <- merge(dat, na.omit(heat_garbage),  by = "Inspection_ID")
    dat <- merge(dat, na.omit(heat_sanitation),  by = "Inspection_ID")
    
    ## Set the key for dat
    setkey(dat, Inspection_ID)
    
    ## Remove unnecessary data
    rm(food, bus, sanitarians, weather, heat_burglary, heat_garbage, heat_sanitation, demographics)
    
    ## Only the model data should be present
    geneorama::lll()
    
    ##==============================================================================
    ## FILTER ROWS
    ##==============================================================================
    
    cat("\nBEFORE", nrow(dat))
    dat <- dat[LICENSE_DESCRIPTION=="Retail Food Establishment"]
    cat("\nAFTER", nrow(dat))
    dat <- dat[sanitarian==color]
    dat
    # cat("number of rows in the not test dat", nrow(dat[Test == FALSE]))
    
    ##==============================================================================
    ## DISPLAY AVAILABLE VARIABLES
    ##==============================================================================
    geneorama::NAsummary(dat)
    
    ##==============================================================================
    ## Add criticalFound variable to dat:
    ##==============================================================================
    dat[ , criticalFound := pmin(1, criticalCount)]
    
    ##==============================================================================
    ## Calculate index for training data (last three months)
    ##==============================================================================
    print(color)
    # dat[ , Test := Inspection_Date >= (max(Inspection_Date) - 90)]
    
    start_date <- min(dat$Inspection_Date)
    end_date <- max(dat$Inspection_Date)
    window_end_date <- end_date
    
    ctr <- 0
    test_window_days <- 60
    while(start_date <= window_end_date) {
        # print(">>>>>>>>>>>")
        # print(window_end_date)
        # print(window_end_date-90)
        # print("<<<<<<<<<<<")
        window_start_date = window_end_date - test_window_days
        
        dat[ , Test := Inspection_Date >= window_start_date&
                 Inspection_Date <= window_end_date]
        # print(nrow(dat[Test == TRUE]))
        
        # if(ctr >= 2) {
        #     break
        # }
        
        # >>>>>>>>>> Begin model training
    
        ##==============================================================================
        ## CREATE MODEL DATA
        ##==============================================================================
        # sort(colnames(dat))
        # remove the Inspector = as.character(sanitarian),
        # in order to remove santarians from the model 
        xmat <- dat[ , list(pastSerious = pmin(pastSerious, 1),
                            pastCritical = pmin(pastCritical, 1),
                            timeSinceLast,
                            ageAtInspection = ifelse(ageAtInspection > 4, 1L, 0L),
                            consumption_on_premises_incidental_activity,
                            tobacco,
                            temperatureMax,
                            heat_burglary = pmin(heat_burglary, 70),
                            heat_sanitation = pmin(heat_sanitation, 70),
                            heat_garbage = pmin(heat_garbage, 50),
                            criticalFound),
                     keyby = list(Inspection_ID, Test)]
        
        ## View the structure of the final xmat
        str(xmat)
        
        ##==============================================================================
        ## GLMNET MODEL
        ##==============================================================================
        ## Construct model matrix without the key values in xmat
        mm <- model.matrix(criticalFound ~ . -1, 
                           data = xmat[ , .SD, .SDcol=-key(xmat)])
        str(mm)
        colnames(mm)
        
        # fit ridge regression, alpha = 0, only inspector coefficients penalized
        # penalty <- ifelse(grepl("^Inspector", colnames(mm)), 1, 0)              #comment out because Insoector comlumn is no loger being used 
        # penalty <- numeric(0)
        # for (i in 1:ncol(mm)-1) {
        #     penalty[i] <- 0
        # }
        # penalty[ncol(mm)] <- 1
        
        # --------------------------------------------------------------
        # curently the penalty factor is the pentalty ^^ the sanitarian 
        # but I will try removing it and see what happens. 
        # --------------------------------------------------------------
        
        cat("production model\n")
        ## PRODUCTION version of the model which is not split for test / train
        model <- cv.glmnet(x = mm,
                           y = xmat[ ,  criticalFound],
                           family = "binomial", 
                           alpha = 0,
                           # penalty.factor = penalty
        )
        
        cat("actual model\n")
        ## EVALUATION version of the model which is only fit on the training data
        model_eval <- cv.glmnet(x = mm[xmat$Test==FALSE, ],
                                y = xmat[Test == FALSE ,  criticalFound],
                                family = "binomial", 
                                alpha = 0,
                                # penalty.factor = penalty
        )
        
        ## Lambda
        # cat(model$lambda)
        model$lambda
        model$lambda.min
        cat("\nLambda: ", model$lambda)
        cat("\nLambda.min: ", model$lambda.min)
        
        ## Attach predictions for top lambda choice to the data
        dat$glm_pred <- predict(model$glmnet.fit, 
                                newx = mm, 
                                s = model$lambda.min,
                                type = "response")[,1]
        
        dat$glm_pred_test <- predict(model_eval$glmnet.fit, 
                                     newx = mm, 
                                     s = model_eval$lambda.min,
                                     type = "response")[,1]
        
        ## Coefficients
        coef <- coef(model)[,1]
        inspCoef <- coef[grepl("^Inspector",names(coef))]
        inspCoef <- inspCoef[order(-inspCoef)]
        
        ## Save Results
        # saveRDS(dat,"no_sanitarians_data/30_dat_ns.Rds")
        # saveRDS(mm, "no_sanitarians_data/30_modelmatrix_ns.Rds")
        # saveRDS(model_eval, "no_sanitarians_data/30_model_eval_ns.Rds")
        saveRDS(dat, paste("cluster_models/30_dat_",color,"_window_",ctr,".Rds", sep = ""))
        # saveRDS(mm, paste("cluster_models/30_modelmatrix_",color,".Rds", sep = ""))
        # saveRDS(model_eval, paste("cluster_models/30_model_eval_",color,".Rds", sep = ""))
        
        cat("\nnumber of rows in dat",nrow(dat))
        cat("\nnumber of train rows",nrow(dat[Test!=TRUE]))
        cat("\nnumber of test rows",nrow(dat[Test==TRUE]))
        cat("\npercent of train data", nrow(dat[Test!=TRUE])/ nrow(dat))
        cat("\npercent of test data", nrow(dat[Test==TRUE])/ nrow(dat))
        cat("\nnumber of test rows with critical violations",nrow(dat[Test==TRUE][criticalFound==1]))
        
        
        # ## Mean time savings:
        datTest <- dat[Test == TRUE]
        cat("\nMean time savings without Inspectors: ")
        # print(datTest$glm_pred_test)
        print(datTest[ , simulated_date_diff_mean(Inspection_Date, glm_pred_test, criticalFound)])
        # <<<<<<<<<< End model training
        
        ctr = ctr + 1
        window_end_date = window_end_date - (test_window_days + 1)
    }
}


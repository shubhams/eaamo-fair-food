race_ethnicity <- c("White", "Black", "Asian", "Hispanic", "American_Indian", "Others")
locationNames <- c("NorthSide", "FarNorthSide", "FarSoutheastSide", "SouthSide", 
                   "CentralChicago", "FarSouthwestSide", "SouthwestSide", "WestSide", "NorthwestSide")
sanitarian_clusters <- c("purple", "blue", "orange", "green", "yellow", "brown")

print_overall_stats <- function(dt, col_name) {
    cat(dt[color_cluster_list==col_name, demographic_gain_list],"\n")
    # cat(unique(dt[location_cluster_list==col_name, demographic_gain_list]),"\n")
}

# Added by Bhuvni 
print_geo_stats <- function(dt, col_name) {
    cat(unique(dt[location_cluster_list==col_name, demographic_gain_list]),"\n")
}

print_incluster_color_stats <- function(dt) {
    cat(unique(dt[1:90, mean_gain_list]),"\n")
    # cat(unique(dt[1:54, mean_gain_list]),"\n")
}

# Added by Bhuvni 
print_incluster_geo_stats <- function(dt) {
    cat(unique(dt[1:84, mean_gain_list]),"\n")
}

# TODO: double-check this
print_incluster_agg_dem_stats <- function(dt, group_list) {
    for (group in group_list) {
        dt_group <- dt[demographic_list==group, .(demographic_sums, demographic_gain_list)]
        dt_group <- dt_group[1:length(sanitarian_clusters)]
        agg <- dt_group[,sum(demographic_sums*demographic_gain_list, na.rm = TRUE)]/dt_group[, sum(demographic_sums, na.rm = TRUE)]
        cat(agg, ",")
    }
    cat("\n")
}

print_geo_agg_model_stats <- function(dt, group_col_name) {
    cat(unique(dt[location_cluster_list==group_col_name, mean_gain_list]),"\n")
}

print_agg_model_stats <- function(dt, group_col_name) {
    cat(unique(dt[color_cluster_list==group_col_name, mean_gain_list]),"\n")
}

# dp, eqodd, eqopp
criteria = "dp"
# "san_maj","race_maj","loc_maj"
majority = "san_maj" 
# C_list = c("0.001", "0.005", "0.01", "0.05", "0.1", "0.2", "0.3", "0.4", "0.5")
C = 0.5

# 0.0, 0.1, 0.01, 0.001, 1e-06
zafar_c_threshold = "0.001"

for(i in 0:18) {
    # for violation times
    # c <- read.csv(paste("moving_test_window/",i,"_window_geo.csv",sep = ""))
    # c <- read.csv(paste("no_sanitarians_data/ns_",i,"_window_geo.csv",sep = ""))
    # c <- read.csv(paste("cluster_models/",i,"_window.csv",sep = ""))
    # c <- read.csv(paste("moving_test_window_geographic/",i,"_window.csv",sep = ""))
    # c <- read.csv(paste("suppressed_sanitarian_features/",i,"_window_geo.csv",sep = ""))
    # c <- read.csv(paste("baseline_test_window/",i,"_window_",criteria,"_",majority,"_",C,"_geo.csv",sep = ""))
    # c <- read.csv(paste("baseline_zafar/",i,"_",zafar_c_threshold,"_window_geo.csv",sep = ""))
    # c <- read.csv(paste("baseline_krishnaswamy/",i,"_window.csv",sep = ""))
    # c <- read.csv(paste("baseline_krishnaswamy/preds_",i,"_window_geo.csv",sep = ""))
    
    # for inspection times
    # c <- read.csv(paste("moving_test_window/",i,"_window_inspection_time_geo.csv",sep = ""))
    # c <- read.csv(paste("no_sanitarians_data/ns_",i,"_window_inspection_time_geo.csv",sep = ""))
    # c <- read.csv(paste("cluster_models/",i,"_window_inspection_time.csv",sep = ""))
    # c <- read.csv(paste("moving_test_window_geographic/",i,"_window_inspection_time.csv",sep = ""))
    # c <- read.csv(paste("suppressed_sanitarian_features/",i,"_window_inspection_time_geo.csv",sep = ""))
    c <- read.csv(paste("baseline_test_window/",i,"_window_",criteria,"_",majority,
                        "_",C,"_inspection_time_geo.csv",sep = ""))
    # c <- read.csv(paste("baseline_zafar/",i,"_",zafar_c_threshold,"_window_inspection_time_geo.csv",sep = ""))
    # c <- read.csv(paste("baseline_krishnaswamy/preds_",i,"_window_inspection_time_geo.csv",sep = ""))
    
    
    c <- data.table(c)
    
    # print_agg_model_stats(c, "default")
    # print_overall_stats(c, "default color")
    # print_overall_stats(c, "default")
    # print_overall_stats(c, "default location")
    
    # print_agg_model_stats(c, "all")
    # print_overall_stats(c, "all color")
    # print_overall_stats(c, "all")
    print_overall_stats(c, "all location")
    
    # TODO: print schedule mean for in cluster
    # print_incluster_color_stats(c)
    # print_incluster_agg_dem_stats(c, race_ethnicity)
    # print_incluster_agg_dem_stats(c, locationNames)
    
    
    # print_geo_agg_model_stats(c, "default")
    # print_geo_stats(c, "default location")
    
    # print_geo_agg_model_stats(c, "all")
    # print_geo_stats(c, "all")
    # print_geo_stats(c, "all location")
}

# Calculating Sanitarian Cluster and Demographic Numbers for Moving Windows

## Model Training
 1. `CODE/glmnet_model_moving_test_window.R`: Generates the data file with prediction scores and saves it under `moving_test_window/30_dat_<window>.Rds`.
 2. `CODE/no_sanitarian_model.R`: Trains the model without the sanitarian features. Saves the model prediction scores at `no_sanitarians_data/30_dat_ns_<window>.Rds`.
 2. `CODE/color_model.R`: Trains one model for each sanitarian cluster and does not use sanitarian as a feature. Saves the model prediction scores at `cluster_models/30_dat_<color>_window_<window>.Rds`.
 
## In-cluster Analysis
`CODE/order_within_sanitarian_group.R`: Contains the code for reordering within the cluster and getting stats for time to detect violations.
  1. Change the input to `moving_test_window_dat` inside the window loop.
  2. Change the name of the output CSV file being written at the end of the file.
  3. The CSV contains data grouped by sanitarian clusters and their respective demographic stats.
  
 `CODE/mean_inspection_time.R`: A copy of `order_within_sanitarian_group.R`, but calculates stats on mean inspection time.
  
## See the numbers
`CODE/print_windowed_stats.R`: Prints the aggregated stats that can be copied to a Google Sheet for further analysis.
 
## Income analysis
`CODE/glmnet_model_moving_test_window_income.R` -- Train the model with income data
`CODE/order_within_sanitarian_group_income.R` -- Re-order using prediction score but also contains income data
 
## Ashkan et al. Baseline
`CODE/baseline_fair_logloss_reorder.R` -- Re-order using the new prediction scores obtained from Ashkan et al. model, calculate date difference for critical violations only
`CODE/baseline_fair_logloss_reorder_inspection.R` -- Re-order with the new prediction scores obtained from Ashkan et al. model, calculate date difference for all inspections
 
## Zafar Baseline
`CODE/baseline_zafar_reorder.R` -- Reorder ONLY critical violations using the Zafar model scores.
`CODE/baseline_zafar_reorder_inspection.R` -- Reorder ALL inspections using the Zafar model scores.
 
## Krishnawamy Baseline
`CODE/baseline_krishnaswamy_reorder.R` -- Reorder ONLY critical violations using the Krishnaswamy model scores.
`CODE/baseline_krishnaswamy_reorder_inspection.R` -- Reorder ALL inspections using the Krishnaswamy model scores.
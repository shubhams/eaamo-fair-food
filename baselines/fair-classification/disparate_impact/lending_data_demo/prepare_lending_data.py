from collections import defaultdict
import os,sys
import urllib.request, urllib.error, urllib.parse
sys.path.insert(0, '../../fair_classification/') # the code for fair classification is in this directory
import numpy as np
from random import seed, shuffle
import pandas as pd
from scipy.stats import zscore
from sklearn import preprocessing


SEED = 42
seed(SEED) # set the random seed so that the random permutations can be reproduced again
np.random.seed(SEED)
DATA_HOME = "~/chicago-food-inspections/polyvalent-experiments/german_credit/data/credit-g_csv.csv"

"""
Converts the food inspection data to work with disparate impact code
"""

 
def load_lending_data(sens_attr='sex'):

    """
        if load_data_size is set to None (or if no argument is provided), then we load and return the whole data
        if it is a number, say 10000, then we will return randomly selected 10K examples
    """

    filePath = f"{DATA_HOME}"
    # filePath = "~/chicago-food-inspections/Original-City-Repo/DATA/30_dat.csv"
    print(filePath)
    credit_df = pd.read_csv(filePath)

    # split `personal_status` to `sex` and `marriage_status`; drop `personal_status` column
    credit_df[['sex', 'marriage_status']] = credit_df['personal_status'].str.split(' ', expand=True)
    credit_df.drop(columns=['personal_status'], inplace=True)
    if sens_attr == 'age':
        credit_df['age'] = credit_df['age'].apply(lambda x: '0' if x <= 27 else '1')
    print(credit_df.info())

    # categorical variables: str -> float
    enc = preprocessing.OrdinalEncoder()
    cat_columns = credit_df.select_dtypes(['object']).columns
    enc.fit(credit_df[cat_columns])
    print(enc.categories_)
    credit_df[cat_columns] = enc.transform(credit_df[cat_columns])

    # scale real values
    scale_columns = set(credit_df.columns) - set(cat_columns)
    scale_columns = list(scale_columns)
    print(scale_columns)
    # try minmax scaler as well
    scaler = preprocessing.StandardScaler().fit(credit_df[scale_columns])
    credit_df[scale_columns] = scaler.transform(credit_df[scale_columns])

    attrs = list(credit_df.columns)
    sensitive_attrs = [sens_attr] # the fairness constraints will be used for this feature
    attrs_to_ignore = [sens_attr] # sex and race are sensitive feature so we will not use them in classification, we will not consider fnlwght for classification since its computed externally and it highly predictive for the class (for details, see documentation of the adult data)
    attrs_for_classification = set(attrs) - set(attrs_to_ignore)

    # =============== here ===========

    X = []
    y = []
    x_control = defaultdict(list)

    # change y (class) from 0/1 to -1/+1
    credit_df['class'] = credit_df['class'].map({0:-1, 1:+1})

    y = credit_df['class'].values.astype('float64')
    for s_attr in sensitive_attrs:
        x_control[s_attr] = credit_df[s_attr]
        x_control[s_attr], _ = pd.factorize(x_control[s_attr])
        x_control[s_attr] = x_control[s_attr].astype("float64")
    
    # do we use sensitive attributes for classification?
    # X = foodDataX[attrs_for_classification]
    # X = credit_df
    credit_df = credit_df.loc[:, credit_df.columns != 'class']
    X = credit_df
    X = X.values.astype("float64")
    # test_idx = foodData["Test"].values

        
    # shuffle the data
    perm = list(range(0,len(y))) # shuffle the data before creating each fold
    # shuffle(perm)
    X = X[perm]
    y = y[perm]

    for k in list(x_control.keys()):
        x_control[k] = x_control[k][perm]

    return X, y, x_control, perm, list(credit_df.columns)


# def prob_sample(df, sample_size):
#     # 1. Decide the number of samples for each row: n
#     # 2. Get list of n samples from each population probability using np.random.choice:
#     #     Example:
#     #     ```
#     #     >>> np.random.choice(a, 10, p=[0.5, 0.3, 0.2])
#     #     ``` 
#     # 3. Repeat rows of the dataframe n times, example:
#     #     ```
#     #     >>> newdf = pd.DataFrame(np.repeat(df.values, 3, axis=0), columns=df.columns)
#     #     ```
#     # 4. Encode group string to categorical int (White->1, Black->2)
#     col_list = ["White", "Black", "American_Indian", "Asian", "Hispanic", "Others"]
#     sample_group_list = list()
#     index_to_drop = list()
#     for row in df.itertuples():
#         p_list = list()
#         for col in col_list:
#             p_list.append(getattr(row,col))
#         try:
#             sample_group_list.extend(np.random.choice(col_list, sample_size, p=p_list))
#         except ValueError:
#             index_to_drop.append(row.Index)
#     groups_series = pd.Series(sample_group_list, name="dem_group")
#     df.drop(axis=0, index=index_to_drop, inplace=True)
#     df = pd.DataFrame(np.repeat(df.values, sample_size, axis=0), columns=df.columns)
#     df = pd.concat([df, groups_series], axis=1)
#     print(df.head())
#     return df

# def round_up(df):
#     col_list = ["White", "Black", "American_Indian", "Asian", "Hispanic", "Others"]
#     sample_group_list = list()
#     for row in df.itertuples():
#         p_list = list()
#         for col in col_list:
#             p_list.append(getattr(row,col))
#         max_idx = np.argmax(p_list)
#         sample_group_list.append(col_list[max_idx])
#     groups_series = pd.Series(sample_group_list, name="dem_group")
#     df = pd.concat([df, groups_series], axis=1, join="inner")
#     print(df.head())
#     return df

# def load_food_data_sampled_by_dem(window_num=18, sample_method="prob", sample_size=1):
#     """
#         if load_data_size is set to None (or if no argument is provided), then we load and return the whole data
#         if it is a number, say 10000, then we will return randomly selected 10K examples
#     """

#     filePath = f"{DATA_HOME}/30_dat_{window_num}.csv"
#     # filePath = "~/chicago-food-inspections/Original-City-Repo/DATA/30_dat.csv"
#     print(filePath)
#     foodData = pd.read_csv(filePath, sep=',', index_col=0, header=0, dtype={"Zip":str})
    
#     # # under-sample majority class
#     criticalFoundIdx = foodData.index[foodData['criticalFound'] == 0].tolist()
#     num_to_drop = int(0.75*len(criticalFoundIdx)-(len(foodData)-len(criticalFoundIdx)))
#     criticalFoundIdx = np.random.choice(criticalFoundIdx, num_to_drop, replace=False)
#     foodData.drop(criticalFoundIdx, inplace=True)
#     print(foodData["criticalFound"].value_counts())

#     # >>>>>> DO THE SAMPLING HERE <<<<<<<
#     if sample_method == "prob":
#         foodData = prob_sample(foodData, sample_size)
#     else:
#         foodData = round_up(foodData)


#     # attributes used for prediction in the R code
#     listX = ["pastSerious", "pastCritical", "timeSinceLast", "ageAtInspection",
#          "consumption_on_premises_incidental_activity", "tobacco", "temperatureMax", "heat_burglary", 
#          "heat_sanitation", "heat_garbage", "sanitarian"]

#     attrs = listX # all attributes
#     sensitive_attrs = ["dem_group"] # the fairness constraints will be used for this feature
#     attrs_to_ignore = ["dem_group"] # we will not use sensitive features for classification
#     attrs_for_classification = set(attrs) - set(attrs_to_ignore)
#     # attrs_for_classification = set(attrs)

#     # ## R code pre-processing
#     foodDataX = foodData.filter(listX, axis=1)
#     foodDataX["pastSerious"].clip(upper=1, inplace=True)
#     foodDataX["pastCritical"].clip(upper=1, inplace=True)
#     foodDataX["heat_burglary"].clip(upper=70, inplace=True)
#     foodDataX["heat_sanitation"].clip(upper=70, inplace=True)
#     foodDataX["heat_garbage"].clip(upper=50, inplace=True)
#     foodDataX["ageAtInspection"] = foodDataX["ageAtInspection"].apply(lambda x: 1 if x > 4 else 0)
    
#     # scale/normalize continuous variables
#     continuous_val_cols = ["timeSinceLast","temperatureMax","heat_burglary","heat_sanitation","heat_garbage"]
#     min_max_scaler = preprocessing.MinMaxScaler()
#     foodDataX[continuous_val_cols] = min_max_scaler.fit_transform(foodDataX[continuous_val_cols])

#     # categorical variables -> one hot vector
#     categorical_vals = ["sanitarian"]
#     try:
#         cat_1hot = pd.get_dummies(foodDataX[categorical_vals])
#         non_cat = foodDataX[set(attrs_for_classification) - set(categorical_vals)]
#         foodDataX = pd.concat([non_cat, cat_1hot], axis=1, join='inner')

#     except (ValueError, KeyError) as e:
#         foodDataX = foodDataX[attrs_for_classification]
#         print("categorical values stated are not found")

#     X = []
#     y = []
#     x_control = defaultdict(list)

#     # change y(critical found) from 0/1 to -1/+1
#     foodData["criticalFound"] = foodData["criticalFound"].map({0:-1, 1:+1})

#     y = foodData["criticalFound"].values.astype("float64")
#     for s_attr in sensitive_attrs:
#         x_control[s_attr] = foodData[s_attr]
#         x_control[s_attr], s_map = pd.factorize(x_control[s_attr])
#         x_control[s_attr] = x_control[s_attr].astype("float64")
#     # convert to numpy arrays for easy handling
#     # X = foodDataX[attrs_for_classification]
#     print(f"Feature columns: {list(foodDataX.columns)}, sensitive feature map: {s_map}")
#     X = foodDataX
#     X = X.values.astype("float64")
#     test_idx = foodData["Test"].values

        
#     # shuffle the data
#     perm = list(range(0,len(y))) # shuffle the data before creating each fold
#     shuffle(perm)
#     X = X[perm]
#     y = y[perm]
#     test_idx = test_idx[perm]
#     for k in list(x_control.keys()):
#         x_control[k] = x_control[k][perm]

#     return X, y, x_control, test_idx, perm, foodDataX.columns


if __name__=="__main__":
    X, y, x_control, _, _ = load_lending_data()
    print(X.shape, y.shape, x_control)
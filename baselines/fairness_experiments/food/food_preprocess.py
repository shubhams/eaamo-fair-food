import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

DATA_HOME = "~/chicago-food-inspections/Original-City-Repo/moving_test_window"

def food_preprocess(window_num):
    
#list feature columns
    column_names = ["criticalFound", "sanitarian", "pastSerious", "pastCritical", "timeSinceLast", "ageAtInspection",
         "consumption_on_premises_incidental_activity", "tobacco", "temperatureMax", "heat_burglary", 
         "heat_sanitation", "heat_garbage"]

#read train and test files
    filePath = f"{DATA_HOME}/30_dat_{window_num}.csv"
    print(filePath)
    foodData = pd.read_csv(filePath, sep=',', index_col=0, header=0, dtype={"Zip":str})

    train = foodData[foodData["Test"]==False]
    test = foodData[foodData["Test"]==True]


#some preprocessing
    train = train.filter(column_names, axis=1)
    train["pastSerious"].clip(upper=1, inplace=True)
    train["pastCritical"].clip(upper=1, inplace=True)
    train["heat_burglary"].clip(upper=70, inplace=True)
    train["heat_sanitation"].clip(upper=70, inplace=True)
    train["heat_garbage"].clip(upper=50, inplace=True)
    train["ageAtInspection"] = train["ageAtInspection"].apply(lambda x: 1 if x > 4 else 0)
    # scale/normalize continuous variables
    continuous_val_cols = ["timeSinceLast","temperatureMax","heat_burglary","heat_sanitation","heat_garbage"]
    std_scaler = StandardScaler()
    train[continuous_val_cols] = std_scaler.fit_transform(train[continuous_val_cols])

    test = test.filter(column_names, axis=1)
    test["pastSerious"].clip(upper=1, inplace=True)
    test["pastCritical"].clip(upper=1, inplace=True)
    test["heat_burglary"].clip(upper=70, inplace=True)
    test["heat_sanitation"].clip(upper=70, inplace=True)
    test["heat_garbage"].clip(upper=50, inplace=True)
    test["ageAtInspection"] = test["ageAtInspection"].apply(lambda x: 1 if x > 4 else 0)
    # scale/normalize continuous variables
    try:
        test[continuous_val_cols] = std_scaler.fit_transform(test[continuous_val_cols])
    except ValueError as e:
        pass

    all_data = foodData.filter(column_names, axis=1)
    all_data["pastSerious"].clip(upper=1, inplace=True)
    all_data["pastCritical"].clip(upper=1, inplace=True)
    all_data["heat_burglary"].clip(upper=70, inplace=True)
    all_data["heat_sanitation"].clip(upper=70, inplace=True)
    all_data["heat_garbage"].clip(upper=50, inplace=True)
    all_data["ageAtInspection"] = all_data["ageAtInspection"].apply(lambda x: 1 if x > 4 else 0)
    # scale/normalize continuous variables
    all_data[continuous_val_cols] = std_scaler.fit_transform(all_data[continuous_val_cols])

# Setting all the categorical columns to type category
    for col in set(train.columns) - set(train.describe().columns):
        train[col] = train[col].astype('category')

    for col in set(test.columns) - set(test.describe().columns):
        test[col] = test[col].astype('category')

    for col in set(all_data.columns) - set(all_data.describe().columns):
        all_data[col] = all_data[col].astype('category')

#dropping some columns for convenience
    train_data = train.drop(columns = ["criticalFound"])
    train_label = train["criticalFound"]
    
    test_data = test.drop(columns = ["criticalFound"])
    test_label = test["criticalFound"]

    all_data = all_data.drop(columns = ["criticalFound"])
    
    return train_data, train_label, test_data, test_label, all_data


def get_1hot(data):
    
    try:
        cat_1hot = pd.get_dummies(data.select_dtypes('category'))
        non_cat = data.select_dtypes(exclude = 'category')
        data_1hot = pd.concat([non_cat, cat_1hot], axis=1, join='inner')

        return data_1hot
    except ValueError:
        return data

def accuracy_randomized(classifiers, weights, data, label):
    overall_acc = 0
    for i in range(len(weights)):
        clf = classifiers[i]
        overall_acc += weights[i] * clf.score(data, label)
    return overall_acc

def get_prediction_scores(classifiers, weights, data):
    scores_arr = np.zeros(data.shape[0])
    for i in range(len(weights)):
        clf = classifiers[i]
        scores_arr += weights[i] * clf.predict_proba(data)[:,1]
    return scores_arr

def get_predictions(classifiers, weights, data):
    preds_arr = np.zeros(data.shape[0])
    for i in range(len(weights)):
        clf = classifiers[i]
        preds_arr += weights[i] * clf.predict(data)
    return preds_arr

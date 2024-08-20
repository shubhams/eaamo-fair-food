from collections import defaultdict
import os,sys
import urllib.request, urllib.error, urllib.parse
sys.path.insert(0, '../../fair_classification/') # the code for fair classification is in this directory
import numpy as np
from random import seed, shuffle
import pandas as pd
from scipy.stats import zscore
from sklearn import preprocessing
from fairlearn.datasets import fetch_credit_card


SEED = 42
seed(SEED) # set the random seed so that the random permutations can be reproduced again
np.random.seed(SEED)

"""
Converts the food inspection data to work with disparate impact code
"""

 
def load_lending_data(sens_attr='x2'):

    """
        if load_data_size is set to None (or if no argument is provided), then we load and return the whole data
        if it is a number, say 10000, then we will return randomly selected 10K examples
    """

    X, y = fetch_credit_card(return_X_y=True)
    tcredit_df = pd.concat([X, y], axis=1)
    tcredit_df_og = tcredit_df.copy()
    print(tcredit_df.info())
    

    # categorical variables: str -> float
    enc = preprocessing.OrdinalEncoder()
    cat_columns = tcredit_df.select_dtypes(['category']).columns
    for col in ['x2', 'x3', 'x4', 'x5']:
        tcredit_df[col] = tcredit_df[col].astype('category')
    enc.fit(tcredit_df[cat_columns])
    print(enc.categories_)
    tcredit_df[cat_columns] = enc.transform(tcredit_df[cat_columns])

    # scale real values
    scale_columns = set(tcredit_df.columns) - set(cat_columns)
    scale_columns = list(scale_columns)
    print(scale_columns)
    # try minmax scaler as well
    scaler = preprocessing.StandardScaler().fit(tcredit_df[scale_columns])
    tcredit_df[scale_columns] = scaler.transform(tcredit_df[scale_columns])

    attrs = list(tcredit_df.columns)
    sensitive_attrs = [sens_attr] # the fairness constraints will be used for this feature
    attrs_to_ignore = [sens_attr] # sex and race are sensitive feature so we will not use them in classification, we will not consider fnlwght for classification since its computed externally and it highly predictive for the class (for details, see documentation of the adult data)
    attrs_for_classification = set(attrs) - set(attrs_to_ignore)

    # =============== here ===========

    X = []
    y = []
    x_control = defaultdict(list)

    # change y (class) from 0/1 to -1/+1
    tcredit_df['y'] = tcredit_df['y'].map({0:-1, 1:+1})

    y = tcredit_df['y'].values.astype('float64')
    for s_attr in sensitive_attrs:
        x_control[s_attr] = tcredit_df[s_attr]
        x_control[s_attr], _ = pd.factorize(x_control[s_attr])
        x_control[s_attr] = x_control[s_attr].astype("float64")
    
    # do we use sensitive attributes for classification?
    # X = foodDataX[attrs_for_classification]
    # X = tcredit_df
    tcredit_df = tcredit_df.loc[:, tcredit_df.columns != 'y']
    X = tcredit_df
    X = X.values.astype("float64")
    # test_idx = foodData["Test"].values

        
    # shuffle the data
    perm = list(range(0,len(y))) # shuffle the data before creating each fold
    # shuffle(perm)
    X = X[perm]
    y = y[perm]

    for k in list(x_control.keys()):
        x_control[k] = x_control[k][perm]

    return X, y, x_control, perm, list(tcredit_df.columns)


if __name__=="__main__":
    X, y, x_control, _, _ = load_lending_data()
    print(X.shape, y.shape, x_control)
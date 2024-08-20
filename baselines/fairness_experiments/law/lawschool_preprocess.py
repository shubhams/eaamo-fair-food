import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

def lawschool_preprocess(train_file, test_file):
    
#list feature columns
    column_names = ['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'lsat', 'ugpa', 'zfygpa', 'zgpa', 'bar', 'full', 'income', 'age', 'gender', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8']

#read train and test files
    train = pd.read_csv(train_file, sep="\s", header=None, names = column_names, engine = 'python')
    test = pd.read_csv(test_file, sep="\s", header=None, names = column_names, engine = 'python')
#some preprocessing
    print(test)
    test['bar'].replace(regex=True,inplace=True,to_replace=r'\.',value=r'')
    
#drop rows with missing columns

    #train = train.sample(1000, random_state = 0)

#Setting all the categorical columns to type category
    for col in set(train.columns) - set(train.describe().columns):
        train[col] = train[col].astype('category')

    for col in set(test.columns) - set(test.describe().columns):
        test[col] = test[col].astype('category')

#dropping some columns for convenience
    train_data = train.drop(columns = ['bar'])
    train_label = train.bar
    
    test_data = test.drop(columns = ['bar'])
    test_label = test.bar
    
    return train_data, train_label, test_data, test_label


def get_1hot(data):
    
 #   cat_1hot = pd.get_dummies(data.select_dtypes('category'))
 #   non_cat = data.select_dtypes(exclude = 'category')
 #   data_1hot = pd.concat([non_cat, cat_1hot], axis=1, join='inner')

    return data#data_1hot

def accuracy_randomized(classifiers, weights, data, label):
    overall_acc = 0
    for i in range(len(weights)):
        clf = classifiers[i]
        overall_acc += weights[i] * clf.score(data, label)
    return overall_acc

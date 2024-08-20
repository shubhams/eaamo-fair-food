import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

def crime_preprocess(train_file, test_file):
    
#list feature columns
    column_names = ['a1', 'a2', 'rB', 'rW', 'rA', 'rH', 'a7', 'a8', 'a9', 'a10', 'a11', 'a12', 'a13', 'a14', 'a15', 'a16', 'a17', 'a18', 'a19', 'a20', 'a21',
                    'a22', 'a23', 'a24', 'a25', 'a26', 'a27', 'a28', 'a29', 'a30', 'a31', 'a32', 'a33', 'a34', 'a35', 'a36', 'a37', 'a38', 'a39', 'a40', 'a41',
                    'a42', 'a43', 'a44', 'a45', 'a46', 'a47', 'a48', 'a49', 'a50', 'a51', 'a52', 'a53', 'a54', 'a55', 'a56', 'a57', 'a58', 'a59', 'a60', 'a61',
                    'a62', 'a63', 'a64', 'a65', 'a66', 'a67', 'a68', 'a69', 'a70', 'a71', 'a72', 'a73', 'a74', 'a75', 'a76', 'a77', 'a78', 'a79', 'a80', 'a81',
                    'a82', 'a83', 'a84', 'a85', 'a86', 'a87', 'a88', 'a89', 'a90', 'a91', 'a92', 'a93', 'a94', 'a95', 'a96', 'a97', 'a98', 'a99', 'a100', 'a101',
                    'a102', 'a103', 'a104', 'a105', 'a106', 'a107', 'a108', 'a109', 'a110', 'a111', 'a112', 'a113', 'a114', 'a115', 'a116', 'a117', 'a118', 'a119',
                    'a120', 'a121', 'a122', 'a123']

#read train and test files
    train = pd.read_csv(train_file, sep="\s", header=None, names = column_names, engine = 'python')
    test = pd.read_csv(test_file, sep="\s", header=None, names = column_names, engine = 'python')
#some preprocessing
    print(test)
    test['a123'].replace(regex=True,inplace=True,to_replace=r'\.',value=r'')
    
#drop rows with missing columns

    train = train.sample(1000, random_state = 0)

#Setting all the categorical columns to type category
    for col in set(train.columns) - set(train.describe().columns):
        train[col] = train[col].astype('category')

    for col in set(test.columns) - set(test.describe().columns):
        test[col] = test[col].astype('category')

#dropping some columns for convenience
    train_data = train.drop(columns = ['a123'])
    train_label = train.a123
    
    test_data = test.drop(columns = ['a123'])
    test_label = test.a123
    
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

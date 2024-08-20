import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

def preprocess(data_file, column_names, class_width):
    
#list feature columns
    
#read data file
    data = pd.read_csv(data_file, names=column_names)
    for label in "MFI":
        data[label] = data["sex"] == label
    del data["sex"]

    y = data.rings.values
    del data["rings"]
    
    label = np.array(y)
    label = label // class_width

    return data, label

def accuracy_randomized(classifiers, weights, data, label):
    overall_acc = 0
    for i in range(len(weights)):
        clf = classifiers[i]
        overall_acc += weights[i] * clf.score(data, label)
    return overall_acc

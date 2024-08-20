import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Perceptron 
from sklearn.linear_model import LogisticRegression as Mymodel
from sklearn.svm import LinearSVC
from sklearn.preprocessing import minmax_scale

import time

import preprocess as ap

#get data
column_names = ["sex", "length", "diameter", "height", "whole weight", 
                "shucked weight", "viscera weight", "shell weight", "rings"]
class_width = 8
train_data, train_label = ap.preprocess('abalone.data', column_names, class_width)

total_size = len(train_label)
train_data_nosens = train_data.drop(columns = ['M', 'F', 'I'])

# Fitting scaler only on training data and applying same transformation to test data
scaler = StandardScaler()
scaler.fit(train_data_nosens)  
train_data_scaled = scaler.transform(train_data_nosens)  


classes = np.unique(train_label)
num_classes = len(classes)

#implementing GREEDY
print('Implementing Greedy...')
remaining_data = train_data_scaled
hack_data = remaining_data[0:num_classes]
remaining_label = train_label
hack_label = classes

length_rem = len(remaining_label)
#lists to collect greedy classifiers and corresponding weights
classifiers = []
weights = np.array([])

#train greedy step by step
count = 0
while length_rem > 0:
    #print(count)
    count = count + 1
    classifiers.append(Mymodel(random_state = 0, solver = 'newton-cg', multi_class = 'ovr'))
    clf = classifiers[-1]
    data_size = len(remaining_label)

    if len(np.unique(remaining_label)) > 1:
        #print('if')
        #sample_w = np.ones(len(remaining_label)) / (10*(100-count))
        clf.fit(remaining_data, remaining_label)
        predicted = clf.predict(remaining_data)
        remaining_indices = np.not_equal(predicted, remaining_label)
        remaining_data = remaining_data[remaining_indices]
        
        remaining_label = remaining_label[remaining_indices]
        length_rem = len(remaining_label)
    else:
        #print('else')
        remaining_data = np.append(remaining_data, hack_data, axis = 0)
        remaining_label = np.append(remaining_label, hack_label)
        clf.fit(remaining_data, remaining_label)
        length_rem = 0

    current_weight = data_size - length_rem
    weights = np.append(weights, current_weight)

print('Done.')

weights = weights/sum(weights)

greedy_overall_acc = ap.accuracy_randomized(classifiers, weights, train_data_scaled, train_label)

#implementing seqPAV
num_iter = total_size
#num_iter = 1000
print('Implementing SeqPAV with num_iter = %d' %num_iter)
points_tally = np.ones(len(train_label))
#have a list of classifiers (per time step)
seqpav = []

count = 1
t1 = time.time()
while count <= num_iter:
    if count % 100 == 0:
        print('Iteration # %d' % count) 
    sample_weights = minmax_scale(1 / points_tally, feature_range = (0.1, 10))
    #find current best classifier
    seqpav.append(Mymodel(random_state = 0, solver = 'newton-cg', multi_class = 'ovr'))
    clf = seqpav[-1]
    clf.fit(train_data_scaled, train_label, sample_weight = sample_weights)
    #update weights
    prediction = clf.predict(train_data_scaled)
    #convert prediction vs labels to 0,1
    update = np.zeros(len(prediction))
    agreement = np.equal(prediction, train_label)
    update[agreement] = 1
    #print(sum(update))
    #update tally and move to next round
    points_tally = points_tally + update
    count = count + 1

t2 = time.time()
print('Done. Time taken = %.2f' %(t2-t1))

seqpav_weights = np.ones(len(seqpav)) / len(seqpav)
seqpav_overall_acc = ap.accuracy_randomized(seqpav, seqpav_weights, train_data_scaled, train_label)

#Analysis
print('----------Analysis------------')
print("Total number of data-points = %d" % total_size)
print("Number of classes = %d" %num_classes)
print("Overall accuracy of ERM = %.5f " % classifiers[0].score(train_data_scaled, train_label))
print("Overall accuracy of Greedy = %.5f " % greedy_overall_acc)
print("Support of greedy (number of classifiers) = %d" % len(weights))
print("and their weights are:")
print(weights)
print("Number of iteration for SeqPAV = %d" % num_iter)
print("Overall accuracy of SeqPAV = %.5f " % seqpav_overall_acc)

#gender groups analysis
print("\n Accuracy table for different algorithms based on gender")
print("------------------------")
cols = ['ERM', 'Greedy', 'OPT', 'SeqPAV', 'Fraction of dataset']

genders = ['M', 'F', 'I']
info = []

for gender in genders:
    is_gender = train_data[gender] == True
    data = train_data[is_gender]
    label = train_label[is_gender]
    fraction = len(label) / total_size

    data_scaled = scaler.transform(data.drop(columns = genders))

    erm_acc = classifiers[0].score(data_scaled, label)
    greedy_acc = ap.accuracy_randomized(classifiers, weights, data_scaled, label)

    clf = Mymodel(random_state = 0, solver = 'newton-cg', multi_class = 'ovr')
    clf.fit(data_scaled, label)
    opt_acc = clf.score(data_scaled, label)

    seqpav_acc = ap.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

    info.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

table = pd.DataFrame(info, columns = cols, index = genders)
print(table)





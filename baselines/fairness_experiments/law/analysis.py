import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Perceptron
from sklearn.linear_model import LogisticRegression as Mymodel
from sklearn.svm import LinearSVC
import time

import lawschool_preprocess as lp

#preprocess train and test data to get data without sensitive labels
train_data, train_label, test_data, test_label = lp.lawschool_preprocess('lawschool_data.txt', 'lawschool_test.txt')

total_size = len(train_label)

train_data_no_sensitive = train_data.drop(columns = ['gender', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8'])
test_data_no_sensitive = test_data.drop(columns = ['gender', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8'])

#transform data into one hot vectors
train_data_1hot = lp.get_1hot(train_data_no_sensitive)
test_data_1hot = lp.get_1hot(test_data_no_sensitive)

# Fitting scaler only on training data and applying same transformation to test data
scaler = StandardScaler()
scaler.fit(train_data_1hot)  
train_data_scaled = scaler.transform(train_data_1hot)  
test_data_scaled = scaler.transform(test_data_1hot)

#implementing GREEDY
print('Implementing Greedy...')
remaining_data = train_data_scaled
hack_data = remaining_data[-2:]

remaining_label = train_label
hack_label = remaining_label[-2:]
length_rem = len(remaining_label)
#lists to collect greedy classifiers and corresponding weights
classifiers = []
weights = np.array([])
count = 1
#train greedy step by step
while length_rem > 0:
    classifiers.append(Mymodel(random_state = 0, solver = 'newton-cg'))
    clf = classifiers[-1]
    data_size = len(remaining_label)

    if len(np.unique(remaining_label)) > 1:
        clf.fit(remaining_data, remaining_label)
        predicted = clf.predict(remaining_data)
        remaining_indices = np.not_equal(predicted, remaining_label)
        remaining_data = remaining_data[remaining_indices]
        remaining_label = remaining_label[remaining_indices]
        length_rem = len(remaining_label)
    else:
        remaining_data = np.append(remaining_data, hack_data, axis = 0)
        remaining_label = remaining_label.append(hack_label)
        clf.fit(remaining_data, remaining_label)
        length_rem = 0

    current_weight = data_size - length_rem
    weights = np.append(weights, current_weight)

print('Done.')

weights = weights/sum(weights)

greedy_overall_acc = lp.accuracy_randomized(classifiers, weights, train_data_scaled, train_label)

#implementing seqPAV
num_iter = total_size
#num_iter = 3000
print(('Implementing SeqPAV with num_iter = %d' %num_iter))
points_tally = np.ones(len(train_label))
#have a list of classifiers (per time step)
seqpav = []

count = 1
t1 = time.time()
while count <= num_iter: 
    if count % 100 == 0:
        print(('Iteration # %d' % count))
    sample_weights = 1 / points_tally
    #find current best classifier
    seqpav.append(Mymodel(random_state = 0, solver = 'newton-cg'))
    clf = seqpav[-1]
    clf.fit(train_data_scaled, train_label, sample_weight = sample_weights)
    #update weights
    prediction = clf.predict(train_data_scaled)
    #convert prediction vs labels to 0,1
    update = np.zeros(len(prediction))
    agreement = np.equal(prediction, train_label)
    update[agreement] = 1
    #update tally and move to next round
    points_tally = points_tally + update
    count = count + 1

t2 = time.time()
print(('Done. Time taken = %.2f' %(t2-t1)))

seqpav_weights = np.ones(len(seqpav)) / len(seqpav)
seqpav_overall_acc = lp.accuracy_randomized(seqpav, seqpav_weights, train_data_scaled, train_label)

#Analysis
print('----------Analysis------------')
print(("Total number of data-points = %d" % total_size))
print(("Overall accuracy of ERM = %.5f " % classifiers[0].score(train_data_scaled, train_label)))
print(("Overall accuracy of Greedy = %.5f " % greedy_overall_acc))
print(("Support of greedy (number of classifiers) = %d" % len(weights)))
print("and their weights are:")
print(weights)
print(("Number of iteration for SeqPAV = %d" % num_iter))
print(("Overall accuracy of SeqPAV = %.5f " % seqpav_overall_acc))

#race groups analysis
print("\n Accuracy table for different algorithms based on race")
print("------------------------")
cols = ['ERM', 'Greedy', 'OPT', 'SeqPAV', 'Fraction of dataset']
races = ['r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8']
info = []

for race in races:
    is_race = train_data[race] == 1
    data = train_data[is_race]
    label = train_label[is_race]
    fraction = len(label) / total_size

    data_no_sensitive = data.drop(columns = ['gender', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8'])
    data_1hot = lp.get_1hot(data_no_sensitive)
    data_scaled = scaler.transform(data_1hot)

    erm_acc = classifiers[0].score(data_scaled, label)
    greedy_acc = lp.accuracy_randomized(classifiers, weights, data_scaled, label)

    clf = Mymodel(random_state = 0, solver = 'newton-cg')
    clf.fit(data_scaled, label)
    opt_acc = clf.score(data_scaled, label)

    seqpav_acc = lp.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

    info.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

table = pd.DataFrame(info, columns = cols, index = races)
print(table)

#gender groups analysis
print("\n Accuracy table for different algorithms based on gender")
print("------------------------")

info1 = []

for g in [0, 1]:
    is_g = train_data['gender'] == g
    data = train_data[is_g]
    label = train_label[is_g]
    fraction = len(label) / total_size

    data_no_sensitive = data.drop(columns = ['gender', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8'])
    data_1hot = lp.get_1hot(data_no_sensitive)
    data_scaled = scaler.transform(data_1hot)

    erm_acc = classifiers[0].score(data_scaled, label)
    greedy_acc = lp.accuracy_randomized(classifiers, weights, data_scaled, label)

    clf = Mymodel(random_state = 0, solver = 'newton-cg')
    clf.fit(data_scaled, label)
    opt_acc = clf.score(data_scaled, label)

    seqpav_acc = lp.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

    info1.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

table = pd.DataFrame(info1, columns = cols, index = [0, 1])
print(table)

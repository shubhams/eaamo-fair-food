import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Perceptron
from sklearn.linear_model import LogisticRegression as Mymodel
from sklearn.svm import LinearSVC
from sklearn.preprocessing import minmax_scale

import time

import adult_preprocess as ap

#preprocess train and test data to get data without sensitive labels
train_data, train_label, test_data, test_label = ap.adult_preprocess('adult_data.txt', 'adult_test.txt')

total_size = len(train_label)

train_data_no_sensitive = train_data.drop(columns = ['race', 'gender'])
#test_data_no_sensitive = test_data.drop(columns = ['race', 'gender'])

#transform data into one hot vectors
train_data_1hot = ap.get_1hot(train_data_no_sensitive)


# Fitting scaler (not really necessary)
scaler = StandardScaler()
scaler.fit(train_data_1hot)  
train_data_scaled = scaler.transform(train_data_1hot)  

#implementing GREEDY
print('Implementing Greedy...')
remaining_data = train_data_scaled
hack_data = remaining_data[-2:] #see hack_label below

remaining_label = train_label
hack_label = remaining_label[-2:] #SGD blackbox trainer always needs labels of >=2 classes
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

greedy_overall_acc = ap.accuracy_randomized(classifiers, weights, train_data_scaled, train_label)

#implementing seqPAV
num_iter = 0.1 * total_size #better convergence for 2n?
#num_iter = 1
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
print('Done. Time taken = %.2f' %(t2-t1))

seqpav_weights = np.ones(len(seqpav)) / len(seqpav)
seqpav_overall_acc = ap.accuracy_randomized(seqpav, seqpav_weights, train_data_scaled, train_label)

#Analysis
print('----------Analysis------------')
print("Total number of data-points = %d" % total_size)
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
genders = ['Male', 'Female']
info = []

for gender in genders:
    is_gender = train_data['gender'] == gender
    data = train_data[is_gender]
    label = train_label[is_gender]
    fraction = len(label) / total_size

    data_no_sensitive = data.drop(columns = ['race', 'gender'])
    data_1hot = ap.get_1hot(data_no_sensitive)
    data_scaled = scaler.transform(data_1hot)

    erm_acc = classifiers[0].score(data_scaled, label)
    greedy_acc = ap.accuracy_randomized(classifiers, weights, data_scaled, label)

    clf = Mymodel(random_state = 0, solver = 'newton-cg')
    clf.fit(data_scaled, label)
    opt_acc = clf.score(data_scaled, label)

    seqpav_acc = ap.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

    info.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

table = pd.DataFrame(info, columns = cols, index = genders)
print(table)


#race groups analysis
print("\n Accuracy table for different algorithms based on race")
print("------------------------")
races = train_data.race.unique()
        
info = []
for race in races:
    is_race = train_data['race'] == race
    data = train_data[is_race]
    label = train_label[is_race]
    fraction = len(label) / total_size

    data_no_sensitive = data.drop(columns = ['race', 'gender'])
    data_1hot = ap.get_1hot(data_no_sensitive)
    data_scaled = scaler.transform(data_1hot)

    erm_acc = classifiers[0].score(data_scaled, label)
    greedy_acc = ap.accuracy_randomized(classifiers, weights, data_scaled, label)

    clf = Mymodel(random_state = 0, solver = 'newton-cg')
    clf.fit(data_scaled, label)
    opt_acc = clf.score(data_scaled, label)

    seqpav_acc = ap.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

    info.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

table = pd.DataFrame(info, columns = cols, index = races)
print(table)


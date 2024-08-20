import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression as Mymodel
from sklearn.preprocessing import minmax_scale

import time

import food_preprocess as fd

def run(window=0):
    #preprocess train and test data to get data without sensitive labels
    train_data, train_label, test_data, test_label, all_data = fd.food_preprocess(window)

    total_size = len(train_label)

    train_data_no_sensitive = train_data.drop(columns = ['sanitarian'])

    #transform data into one hot vectors
    train_data_1hot = fd.get_1hot(train_data_no_sensitive)


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

    greedy_overall_acc = fd.accuracy_randomized(classifiers, weights, train_data_scaled, train_label)

    #implementing seqPAV
    num_iter = 0.1 * total_size #better convergence for 2n?
    #num_iter = 1
    print('Implementing SeqPAV with num_iter = %d' %num_iter)
    points_tally = np.ones(len(train_label))
    #have a list of classifiers (per time step)
    seqpav = []
    seqpav_weights2 = []

    count = 1
    t1 = time.time()
    while count <= num_iter: 
        if count % 100 == 0:
            print('Iteration # %d' % count)
        # sample_weights = minmax_scale(1 / points_tally, feature_range = (0.1, 10))
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

        w = sum(np.multiply((1/points_tally),update))
        seqpav_weights2.append(w)

        #update tally and move to next round
        points_tally = points_tally + update
        count = count + 1

    t2 = time.time()
    print('Done. Time taken = %.2f' %(t2-t1))

    # seqpav_weights = np.ones(len(seqpav)) / len(seqpav)
    seqpav_weights = seqpav_weights2 / sum(seqpav_weights2)
    seqpav_overall_acc = fd.accuracy_randomized(seqpav, seqpav_weights, train_data_scaled, train_label)

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

    #sanitarian groups analysis
    print("\n Accuracy table for different algorithms based on sanitarian")
    print("------------------------")
    cols = ['ERM', 'Greedy', 'OPT', 'SeqPAV', 'Fraction of dataset']
    sanitarian_colors = ['green', 'blue', 'purple', 'yellow', 'brown', 'orange']
    info = []

    for color in sanitarian_colors:
        # TODO: do this part with test set only
        is_sanitarian = train_data['sanitarian'] == color
        data = train_data[is_sanitarian]
        label = train_label[is_sanitarian]
        fraction = len(label) / len(train_label)

        data_no_sensitive = data.drop(columns = ['sanitarian'])
        data_1hot = fd.get_1hot(data_no_sensitive)
        data_scaled = scaler.transform(data_1hot)

        erm_acc = classifiers[0].score(data_scaled, label)
        greedy_acc = fd.accuracy_randomized(classifiers, weights, data_scaled, label)

        clf = Mymodel(random_state = 0, solver = 'newton-cg')
        clf.fit(data_scaled, label)
        opt_acc = clf.score(data_scaled, label)

        seqpav_acc = fd.accuracy_randomized(seqpav, seqpav_weights, data_scaled, label)

        info.append([erm_acc, greedy_acc, opt_acc, seqpav_acc, fraction])

    table = pd.DataFrame(info, columns = cols, index = sanitarian_colors)
    print(table)

    all_data_no_sensitive = all_data.drop(columns = ['sanitarian'])
    all_data_1hot = fd.get_1hot(all_data_no_sensitive)
    all_data_scaled = scaler.transform(all_data_1hot)

    # final_scores = fd.get_prediction_scores(seqpav, seqpav_weights, all_data_scaled)
    final_preds = fd.get_predictions(seqpav, seqpav_weights, all_data_scaled)
    # np.savetxt(f"./scores/krishnaswamy_scores_{window}.csv", final_scores, delimiter=",")
    np.savetxt(f"./scores/krishnaswamy_preds_{window}.csv", final_preds, delimiter=",")

for i in range(0,19):
    run(i)
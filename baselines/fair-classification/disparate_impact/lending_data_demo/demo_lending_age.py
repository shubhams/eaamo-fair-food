import os,sys
import numpy as np
from prepare_lending_data import *
sys.path.insert(0, '../../fair_classification/') # the code for fair classification is in this directory
import utils as ut
import loss_funcs as lf # loss funcs that can be optimized subject to various constraints
from collections import Counter, defaultdict
import json
from sklearn.model_selection import StratifiedShuffleSplit, StratifiedKFold, ShuffleSplit, KFold
from scipy import stats
from fairlearn.metrics import demographic_parity_difference, true_positive_rate, MetricFrame

seed = 42
rnd_gen = np.random.RandomState(seed=seed)

def test_lending_data():
	

	""" Load the food data """
	X, y, x_control, perm, og_cols = load_lending_data(sens_attr='age') # set the argument to none, or no arguments if you want to test with the whole data -- we are subsampling for performance speedup
	ut.compute_p_rule(x_control['age'], y) # compute the p-rule in the original data
	X = ut.add_intercept(X) # add intercept to X 

	N_SPLITS = 3
	# sss = StratifiedShuffleSplit(n_splits=N_SPLITS, test_size=0.3, random_state=rnd_gen)
	# ss = ShuffleSplit(n_splits=N_SPLITS, test_size=0.3, random_state=rnd_gen)
	kf = KFold(n_splits=N_SPLITS)
	fairness_scores_dict = defaultdict(list)
	# skf = StratifiedKFold(n_splits=4)
	# for i, (train_index, test_index) in enumerate(sss.split(X, y)):
	for i, (train_index, test_index) in enumerate(kf.split(X)):
		x_train, x_test = X[train_index], X[test_index]
		y_train, y_test = y[train_index], y[test_index]
		x_control_train = {}
		x_control_test = {}
		for k in list(x_control.keys()):
			x_control_train[k] = x_control[k][train_index]
			x_control_test[k] = x_control[k][test_index]
		
		# add 1 because intercept is added at the 0th index
		sex_col_idx = og_cols.index('age')+1
		fem_idxs_test = np.where(x_test[:, sex_col_idx] == 0)[0]
		# fem_idxs_train = np.where(x_train[:, sex_col_idx] == 0)[0]
		all_fem_idxs = np.where(X[:, sex_col_idx] == 0)[0]
		print(np.where(y_test[fem_idxs_test] == 1)[0].shape[0], np.where(y[all_fem_idxs] == 1)[0].shape[0])

		apply_fairness_constraints = None
		apply_accuracy_constraint = None
		sep_constraint = None

		loss_function = lf._logistic_loss
		# loss_function = lf._logistic_loss_l2_reg
		sensitive_attrs = ['age']
		sensitive_attrs_to_cov_thresh = {}
		gamma = None

		def train_test_classifier():
			w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
			train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, x_test, y_test, None, None)
			distances_boundary_test = (np.dot(x_test, w)).tolist()
			all_class_labels_assigned_test = np.sign(distances_boundary_test)
			correlation_dict_test = ut.get_correlations(None, None, all_class_labels_assigned_test, x_control_test, sensitive_attrs)
			cov_dict_test = ut.print_covariance_sensitive_attrs(None, x_test, distances_boundary_test, x_control_test, sensitive_attrs)
			p_rule = ut.print_classifier_fairness_stats([test_score], [correlation_dict_test], [cov_dict_test], sensitive_attrs[0])	
			coef = dict()
			for key, val in zip(og_cols, w[1:]):
				coef[key] = val
			print(f"coefficients: {json.dumps(coef)}")

			#fairness metrics
			fair_y_true = np.where((y_test==-1),0, y_test)
			fair_y_pred = np.where((all_class_labels_assigned_test==-1),0, all_class_labels_assigned_test)
			fairness_scores_dict['demographic_parity_difference'].append(demographic_parity_difference(fair_y_true, fair_y_pred, sensitive_features=x_control_test['age']))
			fairness_scores_dict['equal_opportunity_difference'].append(MetricFrame(metrics=true_positive_rate, y_true=fair_y_true, y_pred=fair_y_pred, sensitive_features=x_control_test['age']).difference())
			print(f"demographic_parity_difference : {fairness_scores_dict['demographic_parity_difference'][-1]}")
			print(f"equal_opportunity_difference : {fairness_scores_dict['equal_opportunity_difference'][-1]}")

			return w, p_rule, test_score, distances_boundary_test

		def train_test_all_classifier():
			w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
			train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, X, y, None, None)
			distances_boundary_test = (np.dot(X, w)).tolist()
			all_class_labels_assigned_test = np.sign(distances_boundary_test)
			correlation_dict_test = ut.get_correlations(None, None, all_class_labels_assigned_test, x_control, sensitive_attrs)
			cov_dict_test = ut.print_covariance_sensitive_attrs(None, X, distances_boundary_test, x_control, sensitive_attrs)
			p_rule = ut.print_classifier_fairness_stats([test_score], [correlation_dict_test], [cov_dict_test], sensitive_attrs[0])	
			return w, p_rule, test_score, distances_boundary_test

		""" Now classify such that we optimize for accuracy while achieving perfect fairness """
		apply_fairness_constraints = 1 # set this flag to one since we want to optimize accuracy subject to fairness constraints
		apply_accuracy_constraint = 0
		sep_constraint = 0
		allowed_thresh = 0.0

		sensitive_attrs_to_cov_thresh = {'age': allowed_thresh}
		print()
		print("== Classifier with fairness constraint ==")
		w_f_cons, p_f_cons, acc_f_cons, scores  = train_test_classifier()

		list_to_write = list()
		j = 0
		for idx in range(X.shape[0]):
			if idx in test_index:
				list_to_write.append(scores[j])
				j += 1
			else:
				list_to_write.append(-np.inf)
		list_to_write = np.asarray(list_to_write)
		np.savetxt(f"../../lending_scores/{N_SPLITS}_splits/zafar_scores_{allowed_thresh}_fold_{i}_age.csv", list_to_write, delimiter=",")
	#fairness stats
	for k in fairness_scores_dict.keys():
		print(f"{k}: {np.nanmean(fairness_scores_dict[k])}, {stats.sem(fairness_scores_dict[k])}")

	return

def main():
    test_lending_data()


if __name__ == '__main__':
	main()